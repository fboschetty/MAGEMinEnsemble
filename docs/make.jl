using Pkg
using Documenter
using DocumenterCitations
using MAGEMinEnsemble

bib = CitationBibliography(
    joinpath(@__DIR__, "src", "oxygen_fugacity.bib");
    style=:authoryear
)

makedocs(
    sitename="MAGEMinEnsemble",
    modules = [MAGEMinEnsemble],
    authors = "Felix Boschetty",
    format = Documenter.HTML(
        prettyurls=true
    ),
    pages = [
        "Home" => "index.md",
        "Basic Usage" => "basic_usage.md",
        "Intensive Variables" => "intensive_variables.md",
        "Controlling Oxygen Fugacity" => "oxygen_fugacity.md",
        "Monte Carlo Bulk Composition" => "monte_carlo.md",
        "Functions" => "functions.md",
    ],
    plugins = [bib]
)

deploydocs(;
    repo = "https://github.com/fboschetty/MAGEMinEnsemble.git",
)