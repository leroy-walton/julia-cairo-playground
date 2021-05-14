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
        print(" (", m.year, ")", " [", m.genre, "] ", m.rating )
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
    
    movie = Movie()
    cast = Cast()
    movie.id = id
    cast.movie_id = id
    
    url = getUrlMainFromTitleId(id)
    doc = parsehtml(String(HTTP.get(url).body))
    head = doc.root[1]
    body = doc.root[2]
    
    # movie
    movie.id = eachmatch(sel"[property=pageId]", head)[1].attributes["content"]
    movie.title = strip(eachmatch(sel".title_wrapper > h1", body)[1][1].text)
    movie.year =  eachmatch(sel".title_wrapper > h1", body)[1][2][2][1].text
    movie.rating = eachmatch(sel"[itemprop=ratingValue]", body)[1][1].text
    movie.genre =  eachmatch(sel".subtext", body)[1][5][1].text
    movie.time = strip(eachmatch(sel"[datetime]", body)[1][1].text)

    url = getUrlCastFromTitleId(id)
    doc = parsehtml(String(HTTP.get(url).body))
    body = doc.root[2]

    # director
    fullcredits_content = eachmatch(sel"#fullcredits_content", body)
    director_name = strip(fullcredits_content[1][2][2][1][1][1][1].text)
    director_id = getNameIdFromImdbUrl(fullcredits_content[1][2][2][1][1][1].attributes["href"])
    cast_director = Person()
    cast_director.name = director_name
    cast_director.id = director_id

    # writers
    cast_writers = Set{Person}()
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
            println("skipping an entry in actor casting")
        end
    end

    #producers
    cast_producers = Set{Person}()
    for i in 1:size(fullcredits_content[1][8][2].children)[1]
        try
            producer_name = strip(fullcredits_content[1][8][2][i][1][1][1].text)
            producer_id = getNameIdFromImdbUrl(fullcredits_content[1][8][2][i][1][1].attributes["href"])
            producer = Person()
            producer.name = producer_name
            producer.id = producer_id
            push!(cast_producers, producer)
        catch e
            println("skipping an entry for producers")
        end
    end
    
    cast.director = cast_director
    cast.producers = cast_producers
    cast.writers = cast_writers
    cast.actors = cast_actors
    movie.cast = cast
    movie
end

function fetch_person(id)
    person = Person()
    person.id = id
    url="https://www.imdb.com/name/$id/"
    body = parsehtml(String(HTTP.get(url).body)).root[2]
    
    # name
    name_widget = eachmatch(sel"#name-overview-widget", body)
    name = name_widget[1][1][1][1][1][1][1][1].text
    person.name = name

    # birthday
    overview_top = eachmatch(sel"#overview-top", body)
    birthday = overview_top[1][3][2].attributes["datetime"]
    person.birthday = birthday

    # movies
    filmo = eachmatch(sel".filmo-category-section", body)
    movie_ids = Set{String}()
    for i in 1:size(filmo[1].children)[1]
        try
            movie_id = getTitleIdFromImdbUrl(filmo[1][i][2][1].attributes["href"])
            push!(movie_ids, movie_id)
        catch e
            prinlnt("skipped an entry for movies")
        end
    end

    # job_categories ( "actor" | "producer" | "writer" ...)
    job_categories_html = eachmatch(sel"#name-job-categories", body)
    job_categories = Set{String}()
    for i in 1:size(job_categories_html[1].children)[1]
        try
            job_category = lowercase(strip(job_categories_html[1][i][1][1].text))
            push!(job_categories, job_category)
        catch e
            println("skipped an entry for job_categories")
        end
    end

    person.movie_ids = movie_ids
    person.job_categories = job_categories
    person
    
end

function test_fetch(id::String)
    url = "https://www.imdb.com/title/$id/fullcredits/"
    doc = parsehtml(String(HTTP.get(url).body))
    body = doc.root[2]

    #fullcredits_content = eachmatch(sel"#fullcredits_content", body)
    #fullcredits_content = eachmatch(sel"#fullcredits_content", body)
    eachmatch(sel".cast_list", body)[1][1]
end
#==================================================================================================#

movies = Set{Movie}()
persons = Set{Person}()
edward_norton_id = "nm0001570"

movid1 = "tt0120586" #american history x
movid2 = "tt0114814" #the usual suspects
movid3 = "tt0083944" # rambo

#serialize("/julia/serialised.test", movie1)
#movieb = deserialize("/julia/serialised.test")

movie = fetch_movie(movid2)

ed = fetch_person(edward_norton_id)

# movies_of_edward_norton = Set{Movie}()
# for mov_id in ed.movie_ids
#     push!(movies_of_edward_norton, fetch_movie(mov_id))
# end


