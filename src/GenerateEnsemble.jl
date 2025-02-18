
module GenerateEnsemble

using MAGEMin_C
using IterTools
using OrderedCollections
using FileIO
using MAGEMinEnsemble

export run_simulations

"""
    T_array = create_T_array(all_inputs)

Construct an array of temperatures from an initial temperature (T_start),
final temperature (T_stop) and temperature increment (T_step).
Ensure that the T_step is the correct sign.
"""
function create_T_array(all_inputs::OrderedDict)::Vector{Float64}
    T_start = all_inputs["T_start"]
    T_stop = all_inputs["T_stop"]
    T_step = all_inputs["T_step"]

    if T_step == 0.
        error("The temperature step cannot be zero.")

    elseif T_step > 0. && T_start > T_stop
        T_step *= -1
    end

    return collect(range(start=T_start, stop=T_stop, step=T_step))
end


"""
    output_dir = setup_output_directory(output_dir)

Function to check whether specified output directory exists.
If not, creates directory. If it does, checks for .csv files.
If directory contains .csv files throws and error and tells the user to choose another new/empty directory.
"""
function setup_output_directory(output_dir::Union{String, Nothing})::String
    # if output_dir isn't specified, use current directory
    output_dir = output_dir == "" || output_dir == nothing ? joinpath(pwd()) : output_dir

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
    bulk_init, Xoxides = get_bulk_oxides(all_inputs)

Extract a bulk composition and matching oxide strings from all_inputs.
 """
 function get_bulk_oxides(all_inputs::OrderedDict)::Tuple{Vector{Float64}, Vector{String}}
    # Define the accepted oxides for MAGEMin
    accepted_oxides = ["SiO2", "TiO2", "Al2O3", "Cr2O3", "FeO", "MgO", "CaO", "Na2O", "K2O", "H2O", "O", "Fe2O3"]

    # Initialize lists to store bulk composition and matching oxides
    Xoxides = []
    bulk_init = []

    # Iterate through the keys of all_inputs and check if they are in accepted_oxides
    for (key, value) in all_inputs
        if key in accepted_oxides
            push!(Xoxides, key)   # Store the oxide string
            push!(bulk_init, value)  # Store the corresponding value
        end
    end

    return bulk_init, Xoxides
end


"""
    output_file = generate_output_filename(variable_inputs)

Helper function to generate the output filename. Has different behaviour dependant on the number of oxides in variable_inputs.
"""
function generate_output_filename(variable_inputs::OrderedDict, combination::Tuple{Vararg{Float64}})::String

    # variable_oxides = check_variable_oxides(variable_inputs)
    filename_parts = []

    # Generate filename_parts
    append!(filename_parts, [string(collect(keys(variable_inputs))[i], "=", combination[i]) for i in eachindex(combination)])

    # if length(variable_oxides) > 3
    #     @warn """ You have provided more than 3 variable oxides in variable_inputs['bulk'].
    #     Output files will contain bulk instead of the oxides and their values to prevent overly complex file names.
    #     """

    #     # Remove oxides and their values from filename_parts
    #     filename_parts = filter(x -> !any(occursin(oxide, x) for oxide in variable_oxides), filename_parts)

    #     # Add bulk1, bulk2, etc. for each composition (only one bulk identifier for the combination)
    #     push!(filename_parts, "bulk")
    # end

    # Join parts with underscores
    output_file = join(filename_parts, "_")
    return output_file
end


"""
    run_simulations(
    constant_inputs::OrderedDict{String, T},
    variable_inputs::OrderedDict{String, Vector{T}},
    bulk_frac::String,
    sys_in::String="wt",
    output_dir::Union{String, Nothing}=nothing,
    td_database::String="ig"
    ) where T <: Union{Float64, String}

Generates and runs simulation ensembles from intensive variable grid.
Extracts inputs from constant and variable_inputs, performs simulations, and saves the outputs to appropriately named .csv and metadata files.

## Inputs
- `constant_inputs` (OrderedDict): Intensive variables, excluding T, that remain constant across simulation ensemble.
- `variable_inputs` (OrderedDict): Intensive variables, excluding T, that vary across the simulation ensemble.
- `bulk_frac` (String): Flag to indicate whether bulk or fractional crystallisation simulations should be run. "bulk" indicates bulk crystallisation, "frac" indicates fractional crystallisation.

## Keyword Arguments
- `sys_in` (String): Indicate units for input bulk composition (defaults to "wt", wt.%). "mol" for mol.%.
- `output_dir` (String): Path to save output directory to (defaults to current directory).
- `td_database` (String): Flag indicating thermodynamic database to use (defaults to "ig": Green et al., 2025). See the [MAGEMin github](https://github.com/ComputationalThermodynamics/MAGEMin) for options.

## Outputs
- `results` (Dict{String, Any}): simulation results, where keys are variable_input combinations.
"""
function run_simulations(
    constant_inputs::OrderedDict,
    variable_inputs::OrderedDict,
    bulk_frac::String,
    td_database::String="ig",
    sys_in::String="wt",
    output_dir::Union{String, Nothing}=nothing,
    )

    output_dir = setup_output_directory(output_dir)

    results = Dict{String, Any}()  # Dictionary to store simulation results

    new_constant_inputs, new_variable_inputs = MAGEMinEnsemble.InputValidation.prepare_inputs(constant_inputs, variable_inputs, bulk_frac, td_database)

    # Setup combinations for variable inputs
    combinations = IterTools.product(values(new_variable_inputs)...)  # All combinations of variable_inputs

    if bulk_frac == "bulk"
        println("Performing $(length(combinations)) bulk crystallisation simulations...")
    elseif bulk_frac == "frac"
        println("Performing $(length(combinations)) fractional crystallisation simulations...")
    end

    # Iterate through each combination of variable inputs
    for combination in combinations

        # Map the combination values to their respective keys in variable_inputs
        updated_variable_inputs = Dict(
            key => value for (key, value) in zip(keys(new_variable_inputs), combination)
        )

        # Update all_inputs with the constant_inputs and the updated variable_inputs
        all_inputs = merge(new_constant_inputs, updated_variable_inputs)

        # Extract bulk comp and oxides, create array of temperatures
        bulk_init, Xoxides = get_bulk_oxides(all_inputs)
        T_array = create_T_array(all_inputs)

        # Initialize database and extract buffer
        if "buffer" in keys(all_inputs)
            database = Initialize_MAGEMin(td_database, verbose=false, buffer=all_inputs["buffer"])
            offset = get(all_inputs, "offset", 0.0)
        else
            database = Initialize_MAGEMin(td_database, verbose=false)
            offset = nothing
        end

        # Run crystallisation simulation
        if bulk_frac == "bulk"
            output = Crystallisation.bulk_crystallisation(T_array, all_inputs["P"], bulk_init, database, Xoxides, sys_in, offset)

        elseif bulk_frac == "frac"
            output = Crystallisation.fractional_crystallisation(T_array, all_inputs["P"], bulk_init, database, Xoxides, sys_in, offset)

        end

        println("boo")
        # Generate output filename
        output_file = generate_output_filename(new_variable_inputs, combination)

        # Save simulation data to CSV file
        output_file_path = joinpath(output_dir, "$output_file")
        MAGEMin_data2dataframe(output, td_database, output_file_path)

        # Store result
        results[output_file] = output
    end

    println("Done!")

    return results
end

end