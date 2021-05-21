using TOML
using ConfParser
import Mongoc

mutable struct MetaPackage
    name
    git_url
    dependencies
    function MetaPackage(path::String)
        package_path = "$(homedir())/.julia/registries/General/$path/"
        deps_file = package_path * "Deps.toml"
        package_file = package_path * "Package.toml"
        fh = open(package_file, "r")
        package_info = TOML.parse(fh)
        close(fh) 

        git_url = package_info["repo"]
        name = package_info["name"]

        dependencies = []
        if isfile(deps_file)
            fh = open(deps_file, "r")
            deps = TOML.parse(fh)
            close(fh)
            for key in keys(deps)
                dict = deps[key]
                for key in keys(dict)
                    push!(dependencies, key)
                end
            end
        end
        new(name, git_url, dependencies)
    end
end

function db_package_save(collection, meta)
    document = Mongoc.BSON()
    document["name"] = meta.name
    document["git_url"] = meta.git_url
    document["dependencies"] = meta.dependencies
    push!(collection, document)   
end

conf = ConfParse("$(homedir())/.config/julia-package-registry-tool.jl.conf")
parse_conf!(conf)
user     = retrieve(conf, "database", "user")
password = retrieve(conf, "database", "password")
url      = retrieve(conf, "database", "url")

connect_string = "mongodb+srv://$user:$password@$url"
client = Mongoc.Client(connect_string)
db = client["julia_pakages_regitry"]

# load julia package registry file
registry_file_path = "$(@__DIR__)/resources/julia_registry.toml"
fh = open(registry_file_path, "r")
registry = TOML.parse(fh)
close(fh)

# building MetaPackage Dict
packages = registry["packages"]
metas = Dict{String,MetaPackage}()
for package in values(packages)
    path = package["path"]
    meta = MetaPackage(path)
    metas[meta.name] = meta
end

# save registry to db
collection = db["packages"]
for meta in values(metas)
    db_package_save(collection, meta)
end

