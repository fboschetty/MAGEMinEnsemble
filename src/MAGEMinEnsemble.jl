"""
Main module for `MAGEMinEnsemble.jl`.
"""
module MAGEMinEnsemble

include("Crystallisation.jl")
include("InputValidation.jl")
include("GenerateEnsemble.jl")
include("MonteCarloBulk.jl")
include("Output.jl")

# Declare submodules
using .Crystallisation
using .InputValidation
using .GenerateEnsemble
using .MonteCarloBulk
using .Output

export
    Crystallisation
    InputValidation
    GenerateEnsemble
    MonteCarloBulk
    Output
end