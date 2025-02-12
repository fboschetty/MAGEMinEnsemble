push!(LOAD_PATH, joinpath(@__DIR__, "../src"))
using MAGEMinEnsemble

import Documenter

makedocs(
    sitename="My Documentation",
    repo = "https://github.com/fboschetty/MAGEMinEnsemble",
    modules = [MAGEMinEnsemble]
    )
