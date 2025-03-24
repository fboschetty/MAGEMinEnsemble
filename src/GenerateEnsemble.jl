
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
    database, offset, exclude_oxygen = initialize_database(td_database, all_inputs)

Initializes the MAGEMin database and extracts the offset value while determining whether to exclude oxygen from the bulk composition conversion.

# Arguments
- `td_database::String`: The name of the thermodynamic database to be used.
- `all_inputs::Dict{String, Any}`: A dictionary of input parameters, which may include:
  - `"buffer"`: Specifies a buffer condition for database initialization.
  - `"offset"`: A numerical offset value (default is `0.0` if not provided).

# Returns
- `database::Any`: The initialized MAGEMin database object.
- `offset::Float64`: The extracted offset value (default is `0.0`).
- `exclude_oxygen::Bool`: `true` if `"buffer"` is present (meaning oxygen should be excluded), otherwise `false`.
"""
function initialize_database(td_database::String, all_inputs::OrderedDict)
    if "buffer" in keys(all_inputs)
        database = Initialize_MAGEMin(td_database, verbose=false, buffer=all_inputs["buffer"])
        offset = get(all_inputs, "offset", 0.0)
        exclude_oxygen = true
    else
        database = Initialize_MAGEMin(td_database, verbose=false)
        offset = 0.0
        exclude_oxygen = false
    end
    return database, offset, exclude_oxygen
end


"""
   bulk_init, Xoxides = convert_bulk2mol(bulk_init, Xoxides, sys_in, td_database, exclude_oxygen)

Converts a bulk oxide composition from weight percent (`"wt"`) to mol percent (`"mol"`).
Deals with excess oxygen if a buffer is set to prevent excess oxygen skewing normalised compositions.

### Arguments
- `bulk_init::Vector{Float64}`: Initial bulk composition values.
- `Xoxides::Vector{String}`: Corresponding oxide names.
- `sys_in::String`: The input system, either `"wt"` (weight percent) or `"mol"` (molar percent).
- `td_database::String`: The thermodynamic database to use for conversion.
- `exclude_oxygen::Bool`: A flag for whether oxygen should be included in the normalisation or not.

### Returns
- A tuple `(bulk_converted, Xoxides_converted)`, where:
  - `bulk_converted::Vector{Float64}`: The converted bulk composition in mol percent.
  - `Xoxides_converted::Vector{String}`: The corresponding oxide names.

### Behaviour
- If oxygen (`"O"`) is present in `Xoxides`, its contribution is temporarily removed, the remaining composition is converted, and then oxygen is reassigned correctly.
- If `"wt"` is given as input, oxygen is converted from weight to mol fraction.
- If `"mol"` is given, the function ensures correct assignment of `"O"` in the MAGEMinEnsemble.Output.
- If `"O"` is not found in `Xoxides`, the function returns the input unchanged.
"""
function convert_bulk_composition(
    bulk_init::Vector{Float64},
    Xoxides::Vector{String},
    sys_in::String,
    td_database::String,
    exclude_oxygen::Bool
) :: Tuple{Vector{Float64}, Vector{String}}

    bulk_init, Xoxides = copy(bulk_init), copy(Xoxides)

    # Locate "O" in the list of oxides
    ind_O = findfirst(==("O"), Xoxides)

    if exclude_oxygen && ind_O !== nothing
        # Temporarily remove oxygen for conversion
        oxygen_mass = bulk_init[ind_O]
        bulk_init[ind_O] = 0.0

        # Convert without O
        bulk_converted, Xoxides_converted = convertBulk4MAGEMin(bulk_init, Xoxides, sys_in, td_database)

        # Restore oxygen correctly
        oxygen_mol = sys_in == "wt" ? oxygen_mass / 15.9999 : oxygen_mass
        bulk_converted[findfirst(==("O"), Xoxides_converted)] = oxygen_mol
    else
        # Convert normally
        bulk_converted, Xoxides_converted = convertBulk4MAGEMin(bulk_init, Xoxides, sys_in, td_database)
    end

    return bulk_converted, Xoxides_converted
end


"""
    Output = run_simulations(constant_inputs, variable_inputs, bulk_frac)

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

    output_dir = MAGEMinEnsemble.Output.setup_output_directory(output_dir)

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
        database, offset, exclude_oxygen = initialize_database(td_database, all_inputs)

        # Convert bulk comp to mol% for MAGEMin, and deal with excess O correctly
        bulk_converted, Xoxides_converted = convert_bulk_composition(bulk_init, Xoxides, sys_in, td_database, exclude_oxygen)

        # Run crystallisation simulation
        if bulk_frac == "bulk"
            output = Crystallisation.bulk_crystallisation(T_array, all_inputs["P"], bulk_converted, database, Xoxides_converted, "mol", offset)

        elseif bulk_frac == "frac"
            output = Crystallisation.fractional_crystallisation(T_array, all_inputs["P"], bulk_converted, database, Xoxides_converted, "mol", offset)

        end

        # Generate output filename
        output_file = MAGEMinEnsemble.Output.generate_output_filename(new_variable_inputs, combination)

        # Save simulation data to CSV file
        println(output_file)
        output_file_path = joinpath(output_dir, "$output_file")
        MAGEMin_data2dataframe(output, td_database, output_file_path)

        # Store result
        results[output_file] = output
    end

    println("Done!")

    return results
end

end