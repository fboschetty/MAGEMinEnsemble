push!(LOAD_PATH, joinpath(@__DIR__, "../src"))
using FCEnsemble

import Documenter

makedocs(
    sitename="My Documentation",
    repo = "https://github.com/fboschetty/FCEnsemble",
    modules = [FCEnsemble]
    )
