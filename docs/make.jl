
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
        "Controlling Oxygen Fugacity" => "oxygen_fugacity.md",
        "Functions" => "functions.md",
    ]
)

deploydocs(
    repo = "https://github.com/fboschetty/MAGEMinEnsemble.git",
)