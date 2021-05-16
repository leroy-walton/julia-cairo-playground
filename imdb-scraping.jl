using Cascadia
using Gumbo
using HTTP
using Serialization

#using AbstractTrees
#using DataFrames

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
    actors::Set{Person}
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
    for person in cast.actors
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
    print(io, m.title)
    try
        print(io, " (", m.year, ")", " [", m.genre, "] ", m.rating )
        println(io,"")
        print(io, "    \\_: ", m.cast)
    catch e
    end
end

function getTitleIdFromImdbUrl(url::String)
    match(r"tt\d*",url).match
end

function getNameIdFromImdbUrl(url::String)
    match(r"nm\d*",url).match
end

function getUrlMainFromTitleId(id::String)
    "https://www.imdb.com/title/$id"
end

function getUrlCastFromTitleId(id::String)
    "https://www.imdb.com/title/$id/fullcredits/"
end

function fetch_movie(id::String)
    print("fetch_movie($id)-")
    movie = Movie()
    cast = Cast()
    movie.id = id
    cast.movie_id = id
    
    url = getUrlMainFromTitleId(id)
    doc = parsehtml(String(HTTP.get(url).body))
    head = doc.root[1]
    body = doc.root[2]
    
    print("Main-")

    # movie
    movie.id = eachmatch(sel"[property=pageId]", head)[1].attributes["content"]
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
    
    url = getUrlCastFromTitleId(id)
    doc = parsehtml(String(HTTP.get(url).body))
    body = doc.root[2]

    print("Director-")
    # director
    fullcredits_content = eachmatch(sel"#fullcredits_content", body)
    director_name = strip(fullcredits_content[1][2][2][1][1][1][1].text)
    director_id = getNameIdFromImdbUrl(fullcredits_content[1][2][2][1][1][1].attributes["href"])
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
                writer_id = getNameIdFromImdbUrl(fullcredits_content[1][4][2][1][1][1].attributes["href"])
                writer = Person()
                writer.name = writer_name
                writer.id = writer_id
                push!(cast_writers, writer)
            catch e
                println("skipping an entry for writers")
            end
        end
    catch
        println("*writers not found")
    end

    print("Actors-")
    # actors
    table_rows  = eachmatch(sel".cast_list", body)[1].children[1]
    cast_actors = Set{Person}()
    s = size(table_rows.children)[1]
    for i in 2:s
        try
            actor = Person()
            actor.name = strip(table_rows[i][2][1][1].text)
            actor.id = getNameIdFromImdbUrl(table_rows[i][2][1].attributes["href"])
            push!(cast_actors, actor)
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
                producer_id = getNameIdFromImdbUrl(fullcredits_content[1][8][2][i][1][1].attributes["href"])
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

function fetch_person(id)
    print("fetch_person($id)-")
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
    #println("\n\n$(born_info[1][2])\n\n")
    #birthday = overview_top[1][3][2].attributes["datetime"]
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
            movie_id = getTitleIdFromImdbUrl(filmo[1][i][2][1].attributes["href"])
            push!(movie_ids, movie_id)
        catch e
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
        catch e
            print("*skipped an entry for job_categories*")
        end
    end
    println("\n|> $(person.name)\n")
    person.movie_ids = movie_ids
    person.job_categories = job_categories
    person
end

function test_fetch(id::String)
    url = "https://www.imdb.com/title/$id/fullcredits/"
    doc = parsehtml(String(HTTP.get(url).body))
    body = doc.root[2]
    
    #fullcredits_content = eachmatch(sel"#fullcredits_content", body)
    fullcredits_content = eachmatch(sel"#fullcredits_content", body)
    writers_table=eachmatch(sel"div.header > h4#writer", body)
end
#==================================================================================================#

const MOVIES_DATA_FILE_PATH = "/julia/movies.serialized"
const PERSONS_DATA_FILE_PATH = "/julia/persons.serialized"

# movid1 = "tt0120586" #american history x
# movid2 = "tt0114814" #the usual suspects
# movid3 = "tt0083944" # rambo

#movies = Set{Movie}()
movies = Dict{String,Movie}()       # {movie.id, movie}
persons = Dict{String,Person}()     # {person.id, person}

edward_norton_id = "nm0001570"

if isfile(MOVIES_DATA_FILE_PATH)
    println("Loading movies data from -> $MOVIES_DATA_FILE_PATH")
    movies = deserialize(MOVIES_DATA_FILE_PATH)
else
    println("No Movies data file found. fetching some movies to create one.")
    ed = fetch_person(edward_norton_id)
    for mov_id in ed.movie_ids
        movie = fetch_movie(mov_id)
        #push!(movies, movie)
        movies[movie.id] = movie
        println("\n\n>$(movie.title) ($(movie.year)) $(movie.rating)\n\n")
        println()
    end
    serialize(MOVIES_DATA_FILE_PATH, movies)
    println("movies data serialized to $MOVIES_DATA_FILE_PATH")
end

elem = 0
for elem in movies
    movie = elem[2]
    println("$(movie.id) $(movie.title) ($(movie.year))   $(movie.rating) ")
end

if isfile(PERSONS_DATA_FILE_PATH)
    println("Loading persons data from -> $PERSONS_DATA_FILE_PATH")
    persons = deserialize(PERSONS_DATA_FILE_PATH)
else
    println("No persons data file found. fetching some persons to create one.")
    m = movies["tt0137523"]     # Fight Club

    persons_id_to_fetch = []
    push!(persons_id_to_fetch, m.cast.director.id)
    for p in m.cast.writers
        push!(persons_id_to_fetch, p.id)
    end
    for p in m.cast.actors
        push!(persons_id_to_fetch, p.id)
    end
    for p in m.cast.producers
        push!(persons_id_to_fetch, p.id)
    end

    for id in persons_id_to_fetch
        person = fetch_person(id)
        persons[person.id] = person
    end
    serialize(PERSONS_DATA_FILE_PATH, persons)
end

for elem in persons
    p = elem[2]
    println("$(p.id) $(p.name) $(p.birthday)")
end
