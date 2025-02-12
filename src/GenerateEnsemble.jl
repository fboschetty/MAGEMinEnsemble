
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

Helper function to update the all inputs.
"""
function update_all_inputs(all_inputs, variable_inputs, combination)
    for (i, input) in enumerate(keys(variable_inputs))
        all_inputs[input] = combination[i]
    end
    return all_inputs
end


function setup_output_directory(output_dir)
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


function prepare_constant_bulk(constant_inputs)
    Xoxides = collect(keys(constant_inputs["bulk"]))
    bulk_init = collect(values(constant_inputs["bulk"]))

    return bulk_init, Xoxides
end


function prepare_variable_bulk(variable_inputs)
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
function prepare_bulk_and_oxides(constant_inputs, variable_inputs)

    # If only constant bulk is available
    if haskey(constant_inputs, "bulk") && !haskey(variable_inputs, "bulk")
        bulk_init, Xoxides = prepare_constant_bulk(constant_inputs)

    # If only variable bulk is available
    elseif haskey(variable_inputs, "bulk") && !haskey(constant_inputs, "bulk")
        bulk_init, Xoxides = prepare_variable_bulk(variable_inputs)

    end

    return bulk_init, Xoxides
end


function extract_variable_bulk_oxides(variable_inputs)
    # Check if "bulk" key exists in the dictionary
    if haskey(variable_inputs, "bulk")
        # Extract keys from "bulk" and add them as top-level keys in variable_inputs
        for (key, value) in variable_inputs["bulk"]
            variable_inputs[key] = value
        end
        # Remove the "bulk" key after extraction
        delete!(variable_inputs, "bulk")
    end
    return variable_inputs
end


"""
    multi_var_oxides = check_number_variable_oxides(variable_inputs)

Warn if there are more than three variable_input["bulk"] oxides. Returns a flag to be used by generate_output_filename.
"""
function check_number_variable_oxides(variable_inputs::AbstractDict)
    multi_var_oxides = false

    if "bulk" in keys(variable_inputs)
        if length(keys(variable_inputs["bulk"])) > 3
            @warn """
                You have provided more than 3 variable oxides in variable_inputs['bulk'].
                Output files will contain bulk1, bulk2, bulk3 etc. to prevent overly complex file names.
                """
            multi_var_oxides = true
        end
    end
    return multi_var_oxides
end


"""
    output_file = generate_output_filename(variable_inputs)

Helper function to generate the output filename. Has different behaviour dependant on the number of oxides in variable_inputs.
"""
function generate_output_filename(variable_inputs, combination)

    multi_var_oxides = check_number_variable_oxides(variable_inputs)
    filename_parts = []

    if "bulk" in keys(variable_inputs)
        # If there are more than 3 variable oxides, use bulkX
        if multi_var_oxides
            # Get the number of bulk compositions (length of any vector in "bulk")
            vector_length = length(first(values(variable_inputs["bulk"])))
            for i in 1:vector_length
                push!(filename_parts, "bulk$(i)")
            end
        else
            # Otherwise, use oxide names and their values (from variable_inputs["bulk"])
            for (oxide, values) in variable_inputs["bulk"]
                push!(filename_parts, "$(oxide)=$(values[i])")
            end
        end
    end

    # Add other variables from variable_inputs except for "bulk"
    append!(filename_parts, [string(collect(keys(variable_inputs))[i], "=", combination[i]) for i in eachindex(combination)])

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
function run_simulations(T_array::Vector{Float64}, constant_inputs::Dict{Any, Any}, variable_inputs::Dict{Any, Any}, sys_in::String, output_dir::String = nothing) :: Dict

    all_inputs = InputValidation.prepare_inputs(constant_inputs, variable_inputs)

    # Setup combinations for variable inputs
    n_sim = prod(length(v) for v in values(variable_inputs))  # Total number of simulations
    combinations = IterTools.product(values(variable_inputs)...)  # All combinations of variable_inputs

    println("Performing $n_sim fractional crystallisation simulations...")

    output_dir = setup_output_directory(output_dir)

    # Dictionary to store simulation results
    results = Dict{String, Any}()

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