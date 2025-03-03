module MonteCarloBulk

using Distributions
using OrderedCollections
using MAGEMinEnsemble
using MAGEMin_C
using IterTools

export generate_bulk_mc, run_simulations_mc

"""
    bulk_mc = generate_bulk_mc(bulk, abs_unc, n_samples; replace_negatives=true)

Randomly sample normal distributions for each oxide defined by a bulk composition and its absolute uncertainty, n_samples times.

## Inputs
- `bulk` (OrderedDict): Bulk composition with keys as oxide strings, e.g. SiO2.
- `abs_unc` (OrderedDict): Absolute uncertainties with keys that correspond to those in bulk.
- `n_samples` (Int): number of times to sample normal distributions.
- `replace_negatives` (Bool): Flag to control whether negative values should be replaced with zero. Defaults to true.

## Outputs
- `bulk_mc` (OrderedDict): Ordered dictionary with keys:
    - "oxides": Vector of oxide names (keys from `bulk` input)
    - "bulk": Vector of vectors, where each inner vector is a sampled bulk composition.
"""
function generate_bulk_mc(
    bulk::OrderedDict,
    abs_unc::OrderedDict,
    n_samples::Int;
    replace_negatives::Bool=true
    )::OrderedDict

    oxides = collect(keys(bulk))

    # Check for non-matching keys and raise an error if missing
    missing_keys = setdiff(oxides, keys(abs_unc))
    if !isempty(missing_keys)
        error("Missing uncertainty values for oxides: $(join(missing_keys, ", "))")
    end

    extra_keys = setdiff(keys(abs_unc), oxides)
    if !isempty(extra_keys)
        error("Extra uncertainty values found for unlisted oxides: $(join(extra_keys, ", "))")
    end

    locations = [bulk[oxide] for oxide in oxides]
    uncertainties = [abs_unc[oxide] for oxide in oxides]

    # Generate samples using broadcasting
    samples = [rand.(Normal.(locations, uncertainties)) for _ in 1:n_samples]

    # Replace negative values with zero and transpose to get a vector of vectors
    if replace_negatives
        bulk_samples = [max.(s, 0.0) for s in samples]
        if any(any(s .< 0.0) for s in samples)
            @warn "Negative values replaced by zero."
        end
    else
        bulk_samples = samples
    end

    return OrderedDict(
        "oxides" => oxides,
        "bulk" => bulk_samples
    )
end


"""
    validate_bulk_mc_keys(bulk_mc) -> nothing

    Ensures that the given `bulk_mc` contains **only** the keys `"bulk"` and `"oxides"`.
Throws an error if any key is missing or if there are extra keys.

## Inputs:
- `bulk_mc` (OrderedDict): The dictionary to check.

## Errors:
- Throws an `ArgumentError` if the dictionary does not contain exactly the keys `"bulk"` and `"oxides"`.
"""
function validate_bulk_mc_keys(bulk_mc::OrderedDict)::Nothing
    required_keys = Set(["bulk", "oxides"])
    bulk_mc_keys = Set(keys(bulk_mc))

    if bulk_mc_keys != required_keys
        throw(ArgumentError("bulk_mc must contain exactly the keys 'bulk' and 'oxides', but found: $(join(bulk_mc_keys, ", "))"))
    end
end


"""
    validate_bulk_mc_structure(bulk_mc::OrderedDict) -> nothing

Ensures that the given `OrderedDict` follows the expected structure:
- `"oxides"` → `Vector{String}`
- `"bulk"` → `Vector{Vector{Float64}}`

## Inputs:
- `bulk_mc` (OrderedDict): The dictionary to check.

## Errors:
- Throws an `ArgumentError` if `bulk_mc` does not contain **exactly** the required keys or if the values are of the wrong type.
"""
function validate_bulk_mc_structure(bulk_mc::OrderedDict)::Nothing

    validate_bulk_mc_keys(bulk_mc)

    # Check that "oxides" is a Vector{String}
    if !(bulk_mc["oxides"] isa Vector{String})
        throw(ArgumentError("'oxides' must be a Vector{String}, but got $(typeof(bulk_mc["oxides"]))"))
    end

    # Check that "bulk" is a Vector of Vector{Float64}
    if !(bulk_mc["bulk"] isa Vector{Vector{Float64}})
        throw(ArgumentError("'bulk' must be a Vector{Vector{Float64}}, but got $(typeof(bulk_mc["bulk"]))"))
    end
end


"""
    check_required_inputs_mc(constant_inputs, variable_inputs) -> nothing

Check that list of required inputs is defined in either constant_inputs or variable_inputs
"""
function check_required_inputs_mc(constant_inputs::OrderedDict, variable_inputs::OrderedDict)::Nothing
    required_inputs = ["P", "T_start", "T_stop", "T_step", "bulk_mc"]

    # Check if each required input is present in either constant_inputs or variable_inputs
    for input in required_inputs
        if !(haskey(constant_inputs, input) || haskey(variable_inputs, input))
            error("Required input '$input' is not present in either constant_inputs or variable_inputs.")
        end
    end
end


"""
    check_variable_inputs_vectors_mc(variable_inputs) -> nothing

Check that variable inputs are Vectors.
"""
function check_variable_inputs_vectors_mc(variable_inputs::OrderedDict)::Nothing
    for (key, value) in variable_inputs

        if !isa(value, Vector) && key != "bulk_mc"
            throw(ArgumentError("Non-vector value found for key: $key in variable_inputs"))
        end
    end
end


"""
    validate_oxides_mc(variable_inputs)

Ensure that the defined bulk composition has the correct oxides included. Provides error messages that identify missing or extraneous oxides.
"""
function validate_oxides_mc(variable_inputs::OrderedDict)::Nothing
    # Define the accepted oxides for MAGEMin
    accepted_oxides = ["SiO2", "TiO2", "Al2O3", "Cr2O3", "FeO", "MgO", "CaO", "Na2O", "K2O", "H2O", "O", "Fe2O3"]

    # Extract bulk compositions & get oxides
    defined_oxides = variable_inputs["bulk_mc"]["oxides"]

    # Ensure all oxides in bulk composition are from the accepted list
    invalid_oxides = setdiff(defined_oxides, accepted_oxides)
    if !isempty(invalid_oxides)
        invalid_str = join(sort(collect(invalid_oxides)), ", ")
        error("Invalid defined oxide: $invalid_str. Allowed oxides are: $(join(accepted_oxides, ", ")).")
    end

    # Ensure that "O" and "Fe2O3" are not both present
    if "O" in defined_oxides && "Fe2O3" in defined_oxides
        error("Invalid input bulk composition: The composition cannot contain both 'O' and 'Fe2O3'. Please choose only one.")
    end

    # Ensure that either "Fe2O3" or "O" is defined
    if !("Fe2O3" in defined_oxides || "O" in defined_oxides)
        error("Invalid input bulk composition: At least one of 'Fe2O3' or 'O' must be defined.")
    end

    # Ensure that no missing oxides are present (except for "O" and "Fe2O3" which are excluded)
    missing_oxides = setdiff(setdiff(accepted_oxides, defined_oxides), ["O", "Fe2O3"])
    if !isempty(missing_oxides)
        missing_str = join(sort(collect(missing_oxides)), ", ")
        error("Missing oxides in bulk composition: $missing_str.")
    end
end


"""
    validate_positive_oxides_mc(variable_inputs) -> Nothing

Ensures that all oxide values in "bulk_mc" are positive.
Throws an error if negative values are found.

## Inputs:
- `variable_inputs` (OrderedDict): A dictionary containing "bulk_mc", which must include:
  - `"oxides"` → `Vector{String}` of oxide names.
  - `"bulk"` → `Vector{Vector{Float64}}` of compositions.

## Errors:
- Throws an `ArgumentError` if any value in `"bulk"` is negative.
"""
function validate_positive_oxides_mc(variable_inputs::OrderedDict)::Nothing
    mc_oxides = variable_inputs["bulk_mc"]["oxides"]  # Vector of oxide names
    mc_bulk = variable_inputs["bulk_mc"]["bulk"]      # Vector of bulk compositions

    # Ensure mc_bulk contains only non-negative values
    for (sample_idx, sample) in enumerate(mc_bulk)  # Loop over each composition sample
        for (oxide_idx, value) in enumerate(sample)  # Loop over oxide values in the sample
            if value < 0.0
                error("Negative oxide value found in 'bulk_mc': $(mc_oxides[oxide_idx]) = $value at sample index $sample_idx.")
            end
        end
    end
end


"""
    new_variable_inputs = replace_zero_oxides_mc(variable_inputs)

Replaces oxides, except H2O, defined as 0.0 with 0.001.
"""
function replace_zero_oxides_mc(variable_inputs::OrderedDict)::OrderedDict
    # Create a copy of the input dictionary to avoid modifying the original
    new_variable_inputs = deepcopy(variable_inputs)

    # Extract oxides and bulk data
    mc_oxides = new_variable_inputs["bulk_mc"]["oxides"]  # Vector{String}
    mc_bulk = new_variable_inputs["bulk_mc"]["bulk"]      # Vector{Vector{Float64}}

    # Iterate over oxides and replace 0.0 with 0.001 (except H2O)
    for (oxide_idx, oxide) in enumerate(mc_oxides)
        if oxide == "H2O"
            continue  # Skip H2O
        end
        # Replace zeros in each sample
        for sample in mc_bulk
            if sample[oxide_idx] == 0.0
                sample[oxide_idx] = 0.001
            end
        end
    end

    return new_variable_inputs
end


"""
    new_constant_inputs, new_variable_inputs = extract_bulk_mc(constant_inputs, variable_inputs)

Extract `"oxides"` and `"bulk"` compositions from `variable_inputs["bulk_mc"]`.
Place `"oxides"` in `new_constant_inputs` and `"bulk"` in `new_variable_inputs`.

## Inputs:
- `constant_inputs` (OrderedDict): constant_inputs ordered dictionary.
- `variable_inputs` (OrderedDict): variable_inputs containing `"bulk_mc"` ordered dictionary.

## Returns:
- `new_constant_inputs` (OrderedDict): constant_inputs with `"oxides"` key
- `new_variable_inputs` (OrderedDict): variable_inputs with `"bulk"` key. No longer contains `"bulk_mc"` key.
"""
function extract_bulk_mc(constant_inputs::OrderedDict, variable_inputs::OrderedDict)::Tuple{OrderedDict, OrderedDict}
    new_constant_inputs = convert(OrderedDict{String, Any}, deepcopy(constant_inputs))  # Enforce typing.
    new_variable_inputs = convert(OrderedDict{String, Any}, deepcopy(variable_inputs))  # Enforce typing.

    new_constant_inputs["oxides"] = variable_inputs["bulk_mc"]["oxides"]
    new_variable_inputs["bulk"] = variable_inputs["bulk_mc"]["bulk"]
    delete!(new_variable_inputs, "bulk_mc")

    return new_constant_inputs, new_variable_inputs
end


"""
    prepare_inputs_mc(constant_inputs, variable_inputs)

Prepare and validate both constant_inputs and variable_inputs prior to ensure they are suitable for MAGEMin.

## Inputs:
- `constant_inputs` (OrderedDict): inputs that will remain unchanged between MAGEMin simulations.
- `variable_inputs` (OrderedDict): inputs that vary across MAGEMin simulations.

## Outputs:
- `updated_constant_inputs` (OrderedDict): inputs that will remain unchanged between MAGEMin simulations.
- `updated_variable_inputs` (OrderedDict): inputs that vary across MAGEMin simulations.
"""
function prepare_inputs_mc(constant_inputs::OrderedDict, variable_inputs::OrderedDict, bulk_frac::String, td_database::String)::Tuple{OrderedDict, OrderedDict}
    MAGEMinEnsemble.InputValidation.check_bulk_frac(bulk_frac)
    MAGEMinEnsemble.InputValidation.check_td_database(td_database)
    MAGEMinEnsemble.InputValidation.check_constant_inputs_values(constant_inputs)
    MAGEMinEnsemble.InputValidation.check_matching_keys(constant_inputs, variable_inputs)
    MAGEMinEnsemble.InputValidation.validate_buffer(constant_inputs, variable_inputs)
    MAGEMinEnsemble.InputValidation.check_buffer_if_offset(constant_inputs, variable_inputs)
    MAGEMinEnsemble.InputValidation.validate_positive_pressure(constant_inputs, variable_inputs)
    new_constant_inputs, new_variable_inputs = MAGEMinEnsemble.InputValidation.replace_zero_pressure(constant_inputs, variable_inputs)

    # Monte Carlo Specific Inputs
    check_required_inputs_mc(new_constant_inputs, new_variable_inputs)
    check_variable_inputs_vectors_mc(new_variable_inputs)
    validate_positive_oxides_mc(new_variable_inputs)
    validate_bulk_mc_structure(new_variable_inputs["bulk_mc"])
    validate_oxides_mc(new_variable_inputs)
    new_variable_inputs = replace_zero_oxides_mc(new_variable_inputs)
    new_constant_inputs, new_variable_inputs = extract_bulk_mc(new_constant_inputs, new_variable_inputs)

    return new_constant_inputs, new_variable_inputs
end


"""
    bulk_init, Xoxides = get_bulk_oxides_mc(all_inputs)

Extract a bulk composition and matching oxide strings from all_inputs.
 """
 function get_bulk_oxides_mc(all_inputs::OrderedDict)::Tuple{Vector{Float64}, Vector{String}}

    # Initialize lists to store bulk composition and matching oxides
    Xoxides = all_inputs["oxides"]
    bulk_init = all_inputs["bulk"]

    return bulk_init, Xoxides
end


"""
    output_file = generate_output_filename_mc(variable_inputs)

Helper function to generate the output filename. Has different behaviour dependant on the number of oxides in variable_inputs.
"""
function generate_output_filename_mc(variable_inputs::OrderedDict, combination::Tuple)::String
    filename_parts = []

    # Calculate the number of digits required for zero padding
    num_digits = floor(Int, log10(length(variable_inputs["bulk"]))) + 1

    for (i, key) in enumerate(keys(variable_inputs))
        if key == "bulk"
            # Find the index of the bulk composition in variable_inputs["bulk"]
            bulk_values = variable_inputs["bulk"]
            bulk_index = findfirst(==(combination[i]), bulk_values)

            if isnothing(bulk_index)
                error("Bulk composition not found in variable_inputs[\"bulk\"]")
            end

            padded_index = string("0"^(num_digits - length(string(bulk_index))) * string(bulk_index))
            push!(filename_parts, "bulk=$padded_index")
        else
            push!(filename_parts, string(key, "=", combination[i]))
        end
    end

    # Join parts with underscores
    return join(filename_parts, "_")
end


"""
    Output = run_simulations_mc(constant_inputs, variable_inputs, bulk_frac)

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
- `results` (OrderedDict): simulation results, where keys are variable_input combinations.
"""
function run_simulations_mc(
    constant_inputs::OrderedDict,
    variable_inputs::OrderedDict,
    bulk_frac::String,
    td_database::String="ig",
    sys_in::String="wt",
    output_dir::Union{String, Nothing}=nothing,
    )::OrderedDict{String, Any}

    output_dir = MAGEMinEnsemble.GenerateEnsemble.setup_output_directory(output_dir)

    results = OrderedDict{String, Any}()  # Dictionary to store simulation results

    new_constant_inputs, new_variable_inputs = prepare_inputs_mc(constant_inputs, variable_inputs, bulk_frac, td_database)

    # All combinations of variable_inputs
    combinations = IterTools.product(values(new_variable_inputs)...)

    if bulk_frac == "bulk"
        println("Performing $(length(combinations)) Monte Carlo bulk crystallisation simulations...")
    elseif bulk_frac == "frac"
        println("Performing $(length(combinations)) Monte Carlo fractional crystallisation simulations...")
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
        bulk_init, Xoxides = get_bulk_oxides_mc(all_inputs)
        T_array = MAGEMinEnsemble.GenerateEnsemble.create_T_array(all_inputs)

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

        # Generate output filename
        output_file = generate_output_filename_mc(new_variable_inputs, combination)

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