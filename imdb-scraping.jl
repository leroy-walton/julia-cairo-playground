using Cascadia
using Gumbo
using HTTP
#using AbstractTrees
#using DataFrames

mutable struct Movie
    id
    title
    year
    rating
    genre
    time
    director
    writer
    cast
    Movie() = new()
end


println("---")

id = "tt0120586"

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


