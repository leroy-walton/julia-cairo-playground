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

function getMovie(id::String)
    
end

#==================================================================================================#

movies = Set{Movie}()
persons = Set{Person}()

#id = "tt0120586" #american history x
#id = "tt0114814" #the usual suspects
id = "tt0083944" # rambo

url = "https://www.imdb.com/title/$id"
doc = parsehtml(String(HTTP.get(url).body))
head = doc.root[1]
body = doc.root[2]

movie = Movie()
movie.id = eachmatch(sel"[property=pageId]", head)[1].attributes["content"]
movie.title = strip(eachmatch(sel".title_wrapper > h1", body)[1][1].text)
movie.year =  eachmatch(sel".title_wrapper > h1", body)[1][2][2][1].text
movie.rating = eachmatch(sel"[itemprop=ratingValue]", body)[1][1].text
movie.genre =  eachmatch(sel".subtext", body)[1][5][1].text
movie.time = strip(eachmatch(sel"[datetime]", body)[1][1].text)

println(movie)

url = "https://www.imdb.com/title/$id/fullcredits/"

doc = parsehtml(String(HTTP.get(url).body))
body = doc.root[2]

cast = Cast()

table_rows  = eachmatch(sel".cast_list", body)[1].children[1]
#cast_persons = []
cast_persons = Set()
s = size(table_rows.children)[1]
println(s)
for i in 2:s
    try
        print("$i ") 
        person = Person()
        person.name = strip(table_rows[i][2][1][1].text)
        push!(cast_persons, person)
        println(person.name)
    catch e
        println(" /!\\ no name found in this children")
    end
    
end
cast.actors = cast_persons

movie.cast = cast
movie

serialize("/julia/serialised.test", movie)

movieb = deserialize("/julia/serialised.test")