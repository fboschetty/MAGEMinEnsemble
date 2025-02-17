"""
Main module for `MAGEMinEnsemble.jl`.
"""
module MAGEMinEnsemble

include("FractionalCrystallisation.jl")
include("InputValidation.jl")
include("GenerateEnsemble.jl")
include("MonteCarloBulk.jl")

# Declare submodules
using .FractionalCrystallisation
using .InputValidation
using .GenerateEnsemble
using .MonteCarloBulk

export
    FractionalCrystallisation
    InputValidation
    GenerateEnsemble
    MonteCarloBulk

end