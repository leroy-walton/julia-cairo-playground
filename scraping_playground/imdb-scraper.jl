using Cascadia
using Gumbo
using HTTP
using Serialization
using SQLite
using ConfParser
import Mongoc
#using AbstractTrees
using DataFrames

println("---")

mutable struct Person
    id::String
    name::String
    birthday::String
    movie_ids::Set{String}
    job_categories::Set{String}
    Person() = new()
end

function Base.:(==)(x::Person, y::Person) 
    (x.name == y.name)
end

function Base.hash(x::Person, h::UInt )
    hash(x.name)
end

mutable struct Cast
    movie_id::String
    director::Person
    writers::Set{Person}
    actors::Dict{Int,Person}   # casting_rank::Int  => actor::Person     #Set{Person}
    producers::Set{Person}
    Cast() = new()
end
function Base.:(==)(x::Cast, y::Cast) 
    (x.movie_id == y.movie_id)
end

function Base.hash(x::Cast, h::UInt )
    hash(x.movie_id * "Cast")
end

function Base.show(io::IO, cast::Cast)
    for person in values(cast.actors)
        print(io, person.name, "|")
    end
end

mutable struct Movie
    id::String
    title::String
    year::String
    rating::String
    genre::String
    time::String
    cast::Cast
    Movie() = new()
end
function Base.:(==)(x::Movie, y::Movie) 
    (x.id == y.id)
end

function Base.hash(x::Movie, h::UInt )
    hash(x.id)
end

function Base.show(io::IO, m::Movie)
    print(io, m.id)
    try
        print(io, " => ", m.title, " (", m.year, ")", " [", m.genre, "] ", m.rating )
        println(io,"")
        print(io, "    \\_: ", m.cast)
    catch
    end
end

function get_person_ids(movie::Movie)
    persons = []
    cast = movie.cast

    persons = union(persons, [cast.director])
    persons = union(persons, cast.writers)
    persons = union(persons, values(cast.actors))
    persons = union(persons, cast.producers)
    map( p -> p.id , persons)
end

function getMovieIdFromImdbUrl(url::String)
    string(match(r"tt\d*",url).match)
end

function getPersonIdFromImdbUrl(url::String)
    match(r"nm\d*",url).match
end

function getUrlMainFromMovieId(id::String)
    "https://www.imdb.com/title/$id"
end

function getUrlCastFromMovieId(id::String)
    "https://www.imdb.com/title/$id/fullcredits/"
end

function scrape_movie(id::String)
    print("scrape_movie($id)-")
    movie = Movie()
    cast = Cast()
    movie.id = id
    cast.movie_id = id
    
    url = getUrlMainFromMovieId(id)
    doc = parsehtml(String(HTTP.get(url).body))
    head = doc.root[1]
    body = doc.root[2]
    
    print("Main-")

    # movie
    movie.title = strip(eachmatch(sel".title_wrapper > h1", body)[1][1].text)
    try
        movie.year =  eachmatch(sel".title_wrapper > h1", body)[1][2][2][1].text        
    catch
        movie.year = "n/a"
    end
    try
        movie.rating = eachmatch(sel"[itemprop=ratingValue]", body)[1][1].text    
    catch
        movie.rating ="n/a"
    end
    movie.genre =  strip(eachmatch(sel".subtext", body)[1][5][1].text)
    try
        movie.time = strip(eachmatch(sel"[datetime]", body)[1][1].text)    
    catch
        movie.time = "n/a"
    end
    
    url = getUrlCastFromMovieId(id)
    doc = parsehtml(String(HTTP.get(url).body))
    body = doc.root[2]

    print("Director-")
    # director
    fullcredits_content = eachmatch(sel"#fullcredits_content", body)
    director_name = strip(fullcredits_content[1][2][2][1][1][1][1].text)
    director_id = getPersonIdFromImdbUrl(fullcredits_content[1][2][2][1][1][1].attributes["href"])
    cast_director = Person()
    cast_director.name = director_name
    cast_director.id = director_id
    
    print("Writers-")
    # writers
    cast_writers = Set{Person}()
    
    try        
        for i in 1:size(fullcredits_content[1][4][2].children)[1]
            try
                writer_name = strip(fullcredits_content[1][4][2][i][1][1][1].text)
                writer_id = getPersonIdFromImdbUrl(fullcredits_content[1][4][2][1][1][1].attributes["href"])
                writer = Person()
                writer.name = writer_name
                writer.id = writer_id
                push!(cast_writers, writer)
            catch e
                println("*skipping an entry for writers")
            end
        end
    catch
        println("*writers not found")
    end

    print("Actors-")
    # actors
    table_rows  = eachmatch(sel".cast_list", body)[1].children[1]
    cast_actors = Dict{Int,Person}()    # cast_rank::Int => actor::Person
    s = size(table_rows.children)[1]
    cast_rank = 1
    for i in 2:s
        try
            actor = Person()
            actor.name = strip(table_rows[i][2][1][1].text)
            actor.id = getPersonIdFromImdbUrl(table_rows[i][2][1].attributes["href"])
            push!(cast_actors, cast_rank => actor)
            cast_rank +=1
        catch e
            println("*skipping an entry in actor casting")
        end
    end
    
    println("Producers|")
    #producers
    cast_producers = Set{Person}()
    try
        for i in 1:size(fullcredits_content[1][8][2].children)[1]
            try
                producer_name = strip(fullcredits_content[1][8][2][i][1][1][1].text)
                producer_id = getPersonIdFromImdbUrl(fullcredits_content[1][8][2][i][1][1].attributes["href"])
                producer = Person()
                producer.name = producer_name
                producer.id = producer_id
                push!(cast_producers, producer)
            catch e
                println("*skipping an entry for producers")
            end
        end
    catch
        println("*no producers found")
    end

    cast.director = cast_director
    cast.producers = cast_producers
    cast.writers = cast_writers
    cast.actors = cast_actors
    movie.cast = cast
    movie
end

function scrape_movies(movie_ids) ::Dict{String,Movie}
    movie_ids_to_scrape = copy(movie_ids)
    movie_ids_stored = []
    count = 1
    result = Dict{String,Movie}()

    while length(movie_ids_to_scrape)!=0
        for id in movie_ids_to_scrape
            try 
                println("count : $count")
                movie = scrape_movie(id)
                push!(result, movie.id => movie)
                push!(movie_ids_stored, movie.id)
                count +=1
                #sleep(1.2)  # let's be gentle with the server
            catch e
                println("**** scraping error for $id")
                println(string(e) * " => @line ~225")
            end
        end

        movie_ids_to_scrape=[]
        for id in movie_ids
            if !(id in movie_ids_stored)
                push!(movie_ids_to_scrape, id)
            end
        end
    end
    result
end

function scrape_person(id)
    print("scrape_person($id)-")
    person = Person()
    person.id = id
    url="https://www.imdb.com/name/$id/"
    body = parsehtml(String(HTTP.get(url).body)).root[2]
    
    # name
    print("name-")
    name_widget = eachmatch(sel"#name-overview-widget", body)
    name = "n/a"
    try
        name = name_widget[1][1][1][1][1][1][1][1].text    
    catch
        try 
           name = name_widget[1][1][1][1][2][2][1][1].text
        catch
            print("*name not found*")
        end
    end
    person.name = name

    # birthday
    print("birthday-")
    #overview_top = eachmatch(sel"#overview-top", body)
    born_info = eachmatch(sel"#name-born-info > time", body)
    birthday = "n/a"
    try
        birthday = born_info[1].attributes["datetime"]
    catch
        print("*birthday not found*")
    end
    
    person.birthday = birthday

    # movies
    print("movies-")
    filmo = eachmatch(sel".filmo-category-section", body)
    movie_ids = Set{String}()
    for i in 1:size(filmo[1].children)[1]
        try
            movie_id = getMovieIdFromImdbUrl(filmo[1][i][2][1].attributes["href"])
            push!(movie_ids, movie_id)
        catch
            println("skipped an entry for movies")
        end
    end

    # job_categories ( "actor" | "producer" | "writer" ...)
    print("job_cat-")
    job_categories_html = eachmatch(sel"#name-job-categories", body)
    job_categories = Set{String}()
    for i in 1:size(job_categories_html[1].children)[1]
        try
            job_category = lowercase(strip(job_categories_html[1][i][1][1].text))
            push!(job_categories, job_category)
        catch
            print("*skipped an entry for job_categories*")
        end
    end
    println("\n|> $(person.name)\n")
    person.movie_ids = movie_ids
    person.job_categories = job_categories
    person
end

# return an array of movie ids from the imdb top 250
function scrape_top250()
    url = "https://www.imdb.com/chart/top"
    doc = parsehtml(String(HTTP.get(url).body))
    body = doc.root[2]
    movie_ids = []
    elem_array = eachmatch(sel"tbody.lister-list > tr > td.titleColumn > a", body)
    for e in elem_array
        push!(movie_ids, getMovieIdFromImdbUrl(e.attributes["href"]) )
    end
    movie_ids
end

function test_scrape(id::String)
    url = "https://www.imdb.com/title/$id/fullcredits/"
    doc = parsehtml(String(HTTP.get(url).body))
    body = doc.root[2]
    
    #fullcredits_content = eachmatch(sel"#fullcredits_content", body)
    fullcredits_content = eachmatch(sel"#fullcredits_content", body)
    writers_table = eachmatch(sel"div.header > h4#writer", body)
end

function db_movies_all_ids(collection, criteria::Dict=Dict()) :: Vector{String}
    result = Vector{String}()
    let
        bson_filter = Mongoc.BSON(criteria)
        bson_options = Mongoc.BSON("""
                { 
                    "projection" : 
                        { 
                            "id" : 1, 
                            "title" : 1, 
                            "year" : 1
                        },
                    "sort" : 
                        {
                            "year" : 1
                        }
                }
            """)
        for bson_document in Mongoc.find(collection, bson_filter, options=bson_options)
            str = bson_document["id"] 
            push!(result, str) 
        end
    end
    return result
end

function db_persons_all_ids(collection, criteria::Dict=Dict()) ::Vector{String}
    result = Vector{String}()
    let
        bson_filter = Mongoc.BSON(criteria)
        bson_options = Mongoc.BSON("""
                { 
                    "projection" : 
                        { 
                            "id" : 1
                        }
                }
            """)
        for bson_document in Mongoc.find(collection, bson_filter, options=bson_options)
            str = bson_document["id"]
            push!(result, str) 
        end
    end
    return result
end


function db_movie_save(collection, movie::Movie)
    try
        writers_ids = []
        for p in movie.cast.writers
            push!(writers_ids, p.id)
        end
        
        actors_ids = Dict{String,String}()
        for p in movie.cast.actors
            push!(actors_ids, string(p[1]) => p[2].id )
        end

        producers_ids = []
        for p in movie.cast.producers
            push!(producers_ids, p.id)
        end

        document2 = Mongoc.BSON(Dict(
            "id" => movie.id,
            "title" => movie.title,
            "year" => movie.year,
            "rating" => movie.rating,
            "genre" => movie.genre,
            "time" => movie.time,
            "cast" => Dict(
                "director" => movie.cast.director.id,
                "writers"  => writers_ids,
                "actors"   => actors_ids,
                "producers"=> producers_ids
            )
        ))
        push!(collection, document2)
    catch e
        println(string(e) * " => function movie_save() @line ~360" )
    end
end

function db_movies_save(collection, movies::Dict{String,Movie} )
        movie_ids = db_movies_all_ids(collection)
        for id in keys(movies)
            if !(id in movie_ids)
                movie = movies[id]
                db_movie_save(collection, movie)
            end
        end
end

function db_person_save(collection, person::Person)
    try
        document = Mongoc.BSON()
        document["id"] = person.id
        document["name"] = person.name
        document["birthday"] = person.birthday
        document["movie_ids"] = collect(person.movie_ids)
        document["job_categories"] = collect(person.job_categories)
        push!(collection, document)
    catch e
        println(string(e) * " => person_save() @line ~425")
    end
end

#==================================================================================================#
#=

                                ███▄ ▄███▓ ▄▄▄       ██▓ ███▄    █ 
                                ▓██▒▀█▀ ██▒▒████▄    ▓██▒ ██ ▀█   █ 
                                ▓██    ▓██░▒██  ▀█▄  ▒██▒▓██  ▀█ ██▒
                                ▒██    ▒██ ░██▄▄▄▄██ ░██░▓██▒  ▐▌██▒
                                ▒██▒   ░██▒ ▓█   ▓██▒░██░▒██░   ▓██░
                                ░ ▒░   ░  ░ ▒▒   ▓▒█░░▓  ░ ▒░   ▒ ▒ 
                                ░  ░      ░  ▒   ▒▒ ░ ▒ ░░ ░░   ░ ▒░
                                ░      ░     ░   ▒    ▒ ░   ░   ░ ░ 
                                    ░         ░  ░ ░           ░ 
=#
#==================================================================================================#

const MOVIES_DATA_FILE_PATH = "/julia/resources/movies.serialized"
const PERSONS_DATA_FILE_PATH = "/julia/resources/persons.serialized"
const PERSONS_FAILED_SCRAPE = "/julia/resources/failed-persons.serialized"

# movid1 = "tt0120586" #american history x
# movid2 = "tt0114814" #the usual suspects
# movid3 = "tt0083944" # rambo

#movies = Set{Movie}()
movies = Dict{String,Movie}()       # {movie.id, movie}
persons = Dict{String,Person}()     # {person.id, person}

#===Serialization==================================================================================#

if isfile(MOVIES_DATA_FILE_PATH)
    println("Loading movies data from -> $MOVIES_DATA_FILE_PATH")
    movies = deserialize(MOVIES_DATA_FILE_PATH)
else
    println("No Movies data file found. fetching some movies to create one.")
    movie_ids_to_scrape = scrape_top250()
    movies = scrape_movies(movie_ids_to_scrape)   
    serialize(MOVIES_DATA_FILE_PATH, movies)
    println("movies data serialized to $MOVIES_DATA_FILE_PATH")
end

# elem = 0
# for elem in movies
#     movie = elem[2]
#     println("$(movie.id) $(movie.title) ($(movie.year))   $(movie.rating) ")
# end

if isfile(PERSONS_DATA_FILE_PATH)
    println("Loading persons data from -> $PERSONS_DATA_FILE_PATH")
    persons = deserialize(PERSONS_DATA_FILE_PATH)
end

#===MongoDB=========================================================================================#

conf = ConfParse("$(homedir())/.config/imdb-scraper.jl.conf")
parse_conf!(conf)
user     = retrieve(conf, "database", "user")
password = retrieve(conf, "database", "password")
url      = retrieve(conf, "database", "url")

connect_string = "mongodb+srv://$user:$password@$url"
client = Mongoc.Client(connect_string)
db = client["movie_industry"]

# save movies in mongodb
println("inserting movies to db")
collection = db["movies"]
db_movies_save(collection, movies)
println("done.")



# save persons in mongodb
db_collection = db["persons"]
println("fetching some persons.")

person_ids_scrape_failed = []
if isfile(PERSONS_FAILED_SCRAPE)
    println("Loading failed person scrape ids -> $PERSONS_FAILED_SCRAPE")
    person_ids_scrape_failed = deserialize(PERSONS_FAILED_SCRAPE)
end

total_persons = 0
movie_count = 1
person_count = 1
stored_ids = db_persons_all_ids(db_collection)
persons=Dict{String,Person}()
for movie in values(movies)
    person_ids_to_scrape = get_person_ids(movie)
    for id in person_ids_to_scrape
        if !( id in stored_ids) && !(id in person_ids_scrape_failed)
            try        
                person = scrape_person(id)
                persons[person.id] = person
                if person.name != "n/a"
                    db_person_save(db_collection, person)
                else
                    push!(person_ids_scrape_failed, id)
                end
                push!(stored_ids, person.id)
            catch
                push!(person_ids_scrape_failed, id)
            end
        end
        #println("person_count = $person_count")
        #println("#failed ids : $(length(person_ids_scrape_failed))")
        person_count += 1
    end
    println("movie_count = $movie_count")
    movie_count += 1
    total_persons = total_persons + person_count - 1
    serialize(PERSONS_FAILED_SCRAPE, person_ids_scrape_failed)
end
println("total_persons : $total_persons")
println("Failed scrape : $(length(person_ids_scrape_failed))")
