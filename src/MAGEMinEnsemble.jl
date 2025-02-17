"""
Main module for `MAGEMinEnsemble.jl`.
"""
module MAGEMinEnsemble

include("Crystallisation.jl")
include("InputValidation.jl")
include("GenerateEnsemble.jl")
include("MonteCarloBulk.jl")

# Declare submodules
using .Crystallisation
using .InputValidation
using .GenerateEnsemble
using .MonteCarloBulk

export
    Crystallisation
    InputValidation
    GenerateEnsemble
    MonteCarloBulk

end