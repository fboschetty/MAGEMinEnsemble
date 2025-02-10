push!(LOAD_PATH, joinpath(@__DIR__, "../src"))

using Documenter, FCEnsemble

makedocs(sitename="My Documentation")
