push!(LOAD_PATH, joinpath(@__DIR__, "../src"))
using Documenter, MAGEMinEnsemble

makedocs(
    sitename="MAGEMinEnsemble",
    modules = [MAGEMinEnsemble],
    authors = "Felix Boschetty",
    format = Documenter.HTML(),
    pages = [
        "Home" => "index.md",
        "Basic Usage" => "basic_usage.md",
        "Intensive Variables" => "intensive_variables.md",
        "Functions" => "functions.md"
    ]
)

deploydocs(
    repo = "https://github.com/fboschetty/MAGEMinEnsemble.git",
    devbranch = "main"
)