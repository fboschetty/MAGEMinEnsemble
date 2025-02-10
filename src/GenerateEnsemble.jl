
module GenerateEnsemble

using MAGEMin_C
using IterTools

include("FractionalCrystallisation.jl")
include("InputValidation.jl")
using .FractionalCrystallisation
using .InputValidation


"""
    run_simulations(T_array, constant_inputs, variable_inputs, sys_in)

Generates and runs simulation ensembles from intensive variable grid.
Extracts inputs from constant and variable_inputs, performs simulations, and saves the outputs to appropriately named .csv and metadata files.

Inputs:
    - T_array (Vector{Float64}): Array of descending temperatures to perform fractional crystallisation simulations in Celsius.
    - constant_inputs (Dict): Intensive variables, excluding T, that remain constant across simulation ensemble.
    - variable_inputs (Dict): Intensive variables, excluding T, that vary across the simulation ensemble.
    - sys_int (String): Indicate units for input bulk composition. E.g., "wt" for weight percent, "mol" for mole percent.
"""
function run_simulations(T_array::Vector{Float64}, constant_inputs::Dict{Any, Any}, variable_inputs::Dict{Any, Any}, sys_in::String)
    # Prepare the inputs
    max_steps = length(T_array)
    combined_inputs = InputValidation.prepare_inputs(constant_inputs, variable_inputs)

    # Setup combinations for variable inputs
    n_sim = prod(length(v) for v in values(variable_inputs))
    combinations = IterTools.product(values(variable_inputs)...)

    println("Performing $n_sim fractional crystallisation simulations...")

    for combination in combinations
        # Update combined inputs with the current combination of variable inputs
        for (i, input) in enumerate(keys(variable_inputs))
            combined_inputs[input] = combination[i]
        end

        # Combine variable bulk into vectors for MAGEMin
        if "bulk" in keys(variable_inputs)
            max_length = maximum(length(v) for v in values(variable_inputs["bulk"]))
            bulk_init = [
                [isa(values, AbstractVector) ? values[i] : values for (oxide, values) in variable_inputs["bulk"]]
                for i in 1:max_length
            ]
            Xoxides = collect(keys(variable_inputs["bulk"]))

        else
            bulk_init = collect(values(combined_inputs["bulk"]))
            Xoxides = collect(keys(combined_inputs["bulk"]))
        end

        buffer_offset = get(combined_inputs, "buffer_offset", 0)

        # Setup database
        local database = Initialize_MAGEMin("ig", verbose=false, buffer=combined_inputs["buffer"])

        # Run fractional crystallisation
        output = FractionalCrystallisation.fractional_crystallisation(T_array, combined_inputs["P"], bulk_init, database, Xoxides, max_steps, sys_in, buffer_offset)

        # Generate output filename
        output_file = join([string(collect(keys(variable_inputs))[i], "=", combination[i]) for i in eachindex(combination)], "_")

        # Save simulation data
        MAGEMin_data2dataframe(output, "ig", output_file)
    end

    println("Done!")
end

export run_simulations

end