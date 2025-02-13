
module GenerateEnsemble

using MAGEMin_C
using IterTools
using OrderedCollections
using FileIO

include("FractionalCrystallisation.jl")
include("InputValidation.jl")
using .FractionalCrystallisation
using .InputValidation


"""
    all_inputs = update_all_inputs(all_inputs, variable_inputs, combination)

Helper function to update the all inputs for each combination of variable_inputs.
"""
function update_all_inputs(all_inputs, variable_inputs::OrderedDict, combination::Tuple{Vararg{Float64}} )
    for (i, input) in enumerate(keys(variable_inputs))
        all_inputs[input] = combination[i]
    end
    return all_inputs
end

"""
    output_dir = setup_output_directory(output_dir)

Function to check whether specified output directory exists.
If not, creates directory. If it does, checks for .csv files.
If directory contains .csv files throws and error and tells the user to choose another new/empty directory.
"""
function setup_output_directory(output_dir::Union{String, Nothing})::String
    # if output_dir isn't specified, use current directory
    output_dir = output_dir == "" || output_dir == nothing ? pwd() : output_dir

    # Check if the output directory exists, if not, create it
    if !isdir(output_dir)
        println("The specified output directory does not exist. Creating: $output_dir")
        mkdir(output_dir)
        return output_dir
    else
        # If directory exists, check if it contains any .csv files
        csv_files = filter(f -> endswith(f, ".csv"), readdir(output_dir))

        if !isempty(csv_files)
            # Prompt the user if there are existing .csv files
            error("""
                The specified output directory ($output_dir) may already contain simulation output .csv files:
                    $(join(csv_files, ", "))
                Make sure the output directory doesn't contain any .csv files..
                """
            )
        else
            return output_dir
        end
    end
end

 """
    bulk_init, Xoxides = prepare_constant_bulk(constant_inputs)

Extract a bulk composition and matching oxide strings from a constant bulk composition.
 """
function prepare_constant_bulk(constant_inputs::OrderedDict)
    Xoxides = collect(keys(constant_inputs["bulk"]))
    bulk_init = collect(values(constant_inputs["bulk"]))

    return bulk_init, Xoxides
end


"""
bulk_init, Xoxides = prepare_variable_bulk(variable_inputs)

Extract a vector of bulk compositions and matching oxide strings from a variable bulk composition.
"""
function prepare_variable_bulk(variable_inputs::OrderedDict)
    max_length = maximum(length(v) for v in values(variable_inputs["bulk"]))
    bulk_init = [
        [isa(values, AbstractVector) ? values[i] : values for (oxide, values) in variable_inputs["bulk"]]
        for i in 1:max_length
    ]
    Xoxides = collect(keys(variable_inputs["bulk"]))

    return bulk_init, Xoxides
end


"""
    bulk_init, Xoxides = prepare_bulk_and_oxides(updated_inputs, variable_inputs)

Helper function to prepare bulk and oxides. Deals with constant and variable bulk compositions.
If there is only a constant bulk composition, the oxides and corresponding values are extracted for use by MAGEMin.
If there is only a variable bulk composition, the vectors of oxide values are reshaped into vectors containing compositions.
If there is a combination of variable and constant oxides, these are all.
"""
function prepare_bulk_and_oxides(constant_inputs::OrderedDict, variable_inputs::OrderedDict)

    # If only constant bulk is available
    if haskey(constant_inputs, "bulk") && !haskey(variable_inputs, "bulk")
        bulk_init, Xoxides = prepare_constant_bulk(constant_inputs)

    # If only variable bulk is available
    elseif haskey(variable_inputs, "bulk") && !haskey(constant_inputs, "bulk")
        bulk_init, Xoxides = prepare_variable_bulk(variable_inputs)

    end

    return bulk_init, Xoxides
end


# function extract_variable_bulk_oxides(variable_inputs::OrderedDict)
#     # Check if "bulk" key exists in the dictionary
#     if haskey(variable_inputs, "bulk")
#         # Extract keys from "bulk" and add them as top-level keys in variable_inputs
#         for (key, value) in variable_inputs["bulk"]
#             variable_inputs[key] = value
#         end
#         # Remove the "bulk" key after extraction
#         delete!(variable_inputs, "bulk")
#     end
#     return variable_inputs
# end


"""
    variable_oxides = check_variable_oxides(variable_inputs)

Return oxides in variable_inputs. Used by generate_output_filename.
"""
function check_variable_oxides(variable_inputs::OrderedDict)
    accepted_oxides = ["SiO2", "TiO2", "Al2O3", "Cr2O3", "FeO", "MgO", "CaO", "Na2O", "K2O", "H2O", "O", "Fe2O3"]
    return Set(intersect(accepted_oxides, keys(variable_inputs)))
end


"""
    output_file = generate_output_filename(variable_inputs)

Helper function to generate the output filename. Has different behaviour dependant on the number of oxides in variable_inputs.
"""
function generate_output_filename(variable_inputs::OrderedDict, combination::Tuple{Vararg{Float64}})

    variable_oxides = check_variable_oxides(variable_inputs)
    filename_parts = []

    # Generate filename_parts
    append!(filename_parts, [string(collect(keys(variable_inputs))[i], "=", combination[i]) for i in eachindex(combination)])

    if length(variable_oxides) > 3
        @warn """ You have provided more than 3 variable oxides in variable_inputs['bulk'].
        Output files will contain bulk instead of the oxides and their values to prevent overly complex file names.
        """

        # Remove oxides and their values from filename_parts
        filename_parts = filter(x -> !any(occursin(oxide, x) for oxide in variable_oxides), filename_parts)

        # Add bulk1, bulk2, etc. for each composition (only one bulk identifier for the combination)
        push!(filename_parts, "bulk")
    end

    # Join parts with underscores
    output_file = join(filename_parts, "_")
    return output_file
end


"""
    results = run_simulations(T_array, constant_inputs, variable_inputs, sys_in)

Generates and runs simulation ensembles from intensive variable grid.
Extracts inputs from constant and variable_inputs, performs simulations, and saves the outputs to appropriately named .csv and metadata files.

Inputs:
    - T_array (Vector{Float64}): Array of descending temperatures to perform fractional crystallisation simulations in Celsius.
    - constant_inputs (Dict): Intensive variables, excluding T, that remain constant across simulation ensemble.
    - variable_inputs (Dict): Intensive variables, excluding T, that vary across the simulation ensemble.
    - sys_int (String): Indicate units for input bulk composition. E.g., "wt" for weight percent, "mol" for mole percent.
    - output_dir (String): Path to save output directory to (defaults to current directory).
"""
function run_simulations(T_array::Vector{Float64}, constant_inputs::OrderedDict{Any, Any}, variable_inputs::OrderedDict{Any, Any}, sys_in::String, output_dir::String = nothing) :: Dict

    output_dir = setup_output_directory(output_dir)

    results = Dict{String, Any}()  # Dictionary to store simulation results

    all_inputs = InputValidation.prepare_inputs(constant_inputs, variable_inputs)

    # Setup combinations for variable inputs
    combinations = IterTools.product(values(variable_inputs)...)  # All combinations of variable_inputs
    println("Performing $(length(combinations)) fractional crystallisation simulations...")

    # Iterate through each combination of variable inputs
    for combination in combinations
        # Update all inputs with the current combination of variable inputs
        updated_inputs = update_all_inputs(all_inputs, variable_inputs, combination)

        bulk_init, Xoxides = prepare_bulk_and_oxides(updated_inputs, variable_inputs)

        # Initialize database and extract buffer
        if "buffer" in keys(updated_inputs)
            database = Initialize_MAGEMin("ig", verbose=false, buffer=updated_inputs["buffer"])
            offset = get(updated_inputs, "offset", 0)
        else
            database = Initialize_MAGEMin("ig", verbose=false)
            offset = nothing
        end

        # Run fractional crystallisation simulation
        output = FractionalCrystallisation.fractional_crystallisation(T_array, updated_inputs["P"], bulk_init, database, Xoxides, sys_in, offset)

        # Generate output filename
        output_file = generate_output_filename(variable_inputs, combination)

        # Save simulation data to CSV file
        output_file_path = joinpath(output_dir, "$output_file")
        MAGEMin_data2dataframe(output, "ig", output_file_path)

        # Store result
        results[output_file] = output
    end

    println("Done!")

    return results
end

export run_simulations

end