module InputValidation

using OrderedCollections


"""
    check_constant_inputs_dict(constant_inputs)

Check that constant_inputs is a dictionary.
"""
function check_constant_inputs_dict(constant_inputs::AbstractDict)
    if !(isa(constant_inputs, Dict) || isa(constant_inputs, OrderedDict))
        throw(ArgumentError("constant_inputs must be a dictionary or an ordered dictionary."))
    end
end

"""
    check_variable_inputs_dict(constant_inputs)

Check that variable_inputs is a dictionary.
"""
function check_variable_inputs_dict(variable_inputs::AbstractDict)
    if !(isa(variable_inputs, Dict) || isa(variable_inputs, OrderedDict))
        throw(ArgumentError("variable_inputs must be a dictionary or an ordered dictionary."))
    end
end


"""
    check_constant_inputs_values(constant_inputs)

Check the contents of constant_inputs for typing, ensure that numeric values are Float64.
"""
function check_constant_inputs_values(constant_inputs::AbstractDict)
    for (key, value) in constant_inputs
        if key == "bulk" && (isa(value, OrderedDict) || isa(value, Dict))
            # Ensure that "bulk" contains only numeric values
            for (oxide, oxide_value) in value
                if !isa(oxide_value, Number)
                    throw(ArgumentError("Non-numeric value found for oxide: $oxide in 'bulk'"))
                end
            end

        elseif key == "buffer"
            # "buffer" must be a string
            if !isa(value, String)
                throw(ArgumentError("'buffer' must be a string"))
            end

        elseif !isa(value, Number)
            # For all other keys, they should be numeric
            throw(ArgumentError("Non-numeric value found for key: $key"))
        end
    end
end


"""
    check_bulk_in_constant_inputs(constant_inputs)

If "bulk" is a constant_input, check typing and that oxides are numeric.
"""
function check_bulk_in_constant_inputs(constant_inputs::AbstractDict)
    if haskey(constant_inputs, "bulk")
        if !(isa(constant_inputs["bulk"], Dict) || isa(constant_inputs["bulk"], OrderedDict))
            throw(ArgumentError("The key 'bulk' should be a dictionary or ordered dictionary"))
        end

        for (oxide, oxide_value) in constant_inputs["bulk"]
            if !isa(oxide_value, Number)
                throw(ArgumentError("Non-numeric value found for oxide: $oxide in 'bulk'"))
            end
        end
    end
end


"""
    check_variable_inputs_values(variable_inputs)

Check that variable inputs are Vectors.
"""
function check_variable_inputs_values(variable_inputs::AbstractDict)
    for (key, value) in variable_inputs
        if key == "bulk" && (isa(value, Dict) || isa(value, OrderedDict))
            # "bulk" can contain a dictionary or ordered dictionary, so continue
            continue
        elseif !isa(value, AbstractVector)
            throw(ArgumentError("Non-vector value found for key: $key in variable_inputs"))
        end
    end
end


"""
    check_bulk_in_variable_input(constant_inputs)

If "bulk" is a variable input, check that it is a dictionary and that it contains Vectors of Numeric values.
"""
function check_bulk_in_variable_inputs(variable_inputs::AbstractDict)
    if haskey(variable_inputs, "bulk")
        bulk = variable_inputs["bulk"]
        if !(isa(bulk, Dict) || isa(bulk, OrderedDict))
            throw(ArgumentError("The key 'bulk' should be a dictionary or ordered dictionary"))
        end

        for (oxide, oxide_value) in bulk
            if !(isa(oxide_value, AbstractVector) && all(x -> isa(x, Number), oxide_value))
                throw(ArgumentError("Non-numeric value found in vector for oxide: $oxide in 'bulk'"))
            end
        end
    end
end

"""
    check_matching_bulk_oxides(constant_inputs, variable_inputs)

Check if constant_inputs["bulk"] and variable_inputs["bulk"] have the same oxide strings as keys.
"""
function check_matching_bulk_oxides(constant_inputs::AbstractDict, variable_inputs::AbstractDict)
    if "bulk" in keys(constant_inputs) && "bulk" in keys(variable_inputs)
        matching_oxides = intersect(keys(constant_inputs["bulk"]), keys(variable_inputs["bulk"]))
        if !isempty(matching_oxides)
            matching_oxides_str = join(sort(collect(matching_oxides)), ", ")
            error("$(matching_oxides_str) are defined in both variable_inputs['bulk'] and constant_inputs['bulk']")
        end
    end
end


"""
    validate_inputs(constant_inputs, variable_inputs)

Combine the above validation functions into a single function for ease of use.
"""
function validate_inputs(constant_inputs::AbstractDict, variable_inputs::AbstractDict)
    check_constant_inputs_dict(constant_inputs)
    check_variable_inputs_dict(variable_inputs)
    check_constant_inputs_values(constant_inputs)
    check_variable_inputs_values(variable_inputs)
    check_bulk_in_constant_inputs(constant_inputs)
    check_bulk_in_variable_inputs(variable_inputs)
    check_matching_bulk_oxides(constant_inputs, variable_inputs)
end


"""
    constant_inputs, variable_inputs = combine_bulk_compositions!(constant_inputs, variable_inputs)

Function to combine variable and constant bulk compositions into a single variable bulk composition.
"""
function combine_bulk_compositions!(constant_inputs::Dict, variable_inputs::Dict)
    # Check if both constant_inputs and variable_inputs have the "bulk" key
    if "bulk" in keys(constant_inputs) && "bulk" in keys(variable_inputs)
        combined_bulk = OrderedDict()

        # Process constant bulk and variable bulk
        for (oxide, constant_value) in constant_inputs["bulk"]
            # Get the length of the first vector in variable_inputs["bulk"], these should be all be the same length.
            vector_length = length(first(values(variable_inputs["bulk"])))
            # Repeat the constant value to match the vector length
            combined_bulk[oxide] = fill(constant_value, vector_length)
        end

        for (oxide, variable_values) in variable_inputs["bulk"]
            combined_bulk[oxide] = variable_values
        end

        # Update variable_inputs to include the combined bulk composition
        variable_inputs["bulk"] = combined_bulk

        # Remove "bulk" from constant_inputs as it has been transferred to variable_inputs
        delete!(constant_inputs, "bulk")
    end

    return constant_inputs, variable_inputs
end


"""
    validate_keys(constant_inputs, variable_inputs)

Check no keys are defined in both constant and variable inputs.
"""
function validate_keys(constant_inputs::Dict, variable_inputs::Dict)
    # Check for matching keys between constant and variable inputs
    common_keys = intersect(keys(variable_inputs), keys(constant_inputs))
    if !isempty(common_keys)
        common_str = join(sort(collect(common_keys)), ", ")
        error("Matching keys in constant_inputs and variable_inputs ($common_str). Inputs must be either constant or variable, not both.")
    end
end


"""
    validate_compositions_and_pressure(all_inputs)

Check that both "bulk" and "P" are defined in either variable or constant inputs.
"""
function validate_compositions_and_pressure(all_inputs::AbstractDict)
    # Ensure bulk composition and pressure are defined
    if !haskey(all_inputs, "bulk")
        error("No bulk composition (bulk) defined in constant or variable_inputs.")
    end

    if !haskey(all_inputs, "P")
        error("No pressure (P) defined in constant or variable_inputs.")
    end
end


"""
    validate_oxides(all_inputs)

Ensure that the defined bulk composition has the correct oxides included. Provides error messages that identify missing or extraneous oxides.
"""
function validate_oxides(all_inputs::AbstractDict)
    # Define the accepted oxides for MAGEMin
    accepted_oxides = ["SiO2", "TiO2", "Al2O3", "Cr2O3", "FeO", "MgO", "CaO", "Na2O", "K2O", "H2O", "O", "Fe2O3"]

    # Ensure "bulk" is present in the input
    if !haskey(all_inputs, "bulk")
        error("No bulk composition (bulk) defined in inputs.")
    end

    # Extract bulk composition
    bulk = all_inputs["bulk"]

    # Ensure all oxides in bulk composition are from the accepted list
    invalid_oxides = setdiff(keys(bulk), accepted_oxides)
    if !isempty(invalid_oxides)
        invalid_str = join(sort(collect(invalid_oxides)), ", ")
        error("Invalid oxides found in bulk composition: $invalid_str. Allowed oxides are: $(join(accepted_oxides, ", ")).")
    end

    # Ensure that "O" and "Fe2O3" are not both present
    if "O" in keys(bulk) && "Fe2O3" in keys(bulk)
        error("Invalid input bulk composition: The composition cannot contain both 'O' and 'Fe2O3'. Please choose only one.")
    end

    # Ensure that no missing oxides are present (except for "O" and "Fe2O3" which are excluded)
    missing_oxides = setdiff(setdiff(accepted_oxides, keys(bulk)), ["O", "Fe2O3"])
    if !isempty(missing_oxides)
        missing_str = join(sort(collect(missing_oxides)), ", ")
        error("Missing oxides in bulk composition: $missing_str.")
    end
end

"""
    validate_bulk_and_pressure(all_inputs)

Check that the provided bulk and pressure values are correct, e.g., non negative or missing.
Replace 0 values with small values to prevent MAGEMin behaving unexpectedly.
"""
function validate_bulk_and_pressure(all_inputs::AbstractDict)
    # Ensure no missing values in the bulk composition
    for (oxide, value) in all_inputs["bulk"]
        if isnan(value) || ismissing(value)
            error("Missing or NaN value found for oxide: $oxide")
        end
    end

    # Ensure non-negative pressures
    P = all_inputs["P"]
    if any(x -> x < 0., P)
        error("Pressure values cannot be negative. Found invalid pressure value(s) in P: $(P[P .< 0])")
    end

    # Change 0 kbar pressures to 1bar
    if all_inputs["P"] == 0.
        all_inputs["P"] = 0.001
    end

    # Change bulk composition oxides from 0 to 0.001
    for (key, value) in all_inputs["bulk"]
        if key != "H2O" && value == 0.
            all_inputs["bulk"][key] = 0.001
        end
    end

    # Check that all values in the bulk composition are valid (no zero values, unless specifically allowed)
    for (oxide, value) in all_inputs["bulk"]
        if value <= 0 && oxide != "H2O"
            error("Invalid zero value found for oxide: $oxide in bulk composition.")
        end
    end
end

"""
    validate_buffer(all_inputs)

Ensure that buffer string is permitted by MAGEMin.
"""
function validate_buffer(all_inputs::AbstractDict)
    allowed_oxygen_buffers = ["qfm", "qif", "nno", "hm", "cco"]
    allowed_activity_buffers = ["aH2O", "aO2", "aMgO", "aFeO", "aAl2O3", "aTiO2", "aSio2"]
    allowed_buffers = vcat(allowed_oxygen_buffers, allowed_activity_buffers)

    if haskey(all_inputs, "buffer")
        if !(all_inputs["buffer"] in allowed_buffers)
            allowed_buffers_str = join(sort(collect(allowed_buffers)), ", ")
            error("Invalid buffer chosen: $(all_inputs["buffer"]). It must be one of: $(allowed_buffers_str)")
        end
    end
end


"""
    prepare_inputs(constant_inputs, variable_inputs)

Prepare and validate both constant_inputs and variable_inputs prior to ensure they are suitable for MAGEMin.

Inputs:
    - constant_inputs (Dict): inputs that will remain unchanged between MAGEMin simulations.
    - variable_inputs (Dict): inputs that vary across MAGEMin simulations.

Outputs:
    - all_inputs (Dict): Single dictionary containing both variable and constant inputs that have the correct types to be used in MAGEMin.
"""
function prepare_inputs(constant_inputs::AbstractDict, variable_inputs::AbstractDict) :: AbstractDict
    # Validate input types
    validate_inputs(constant_inputs, variable_inputs)

    # Combine bulk compositions
    constant_inputs, variable_inputs = combine_bulk_compositions!(constant_inputs, variable_inputs)

    # Validate keys in constant and variable inputs
    validate_keys(constant_inputs, variable_inputs)

    # Merge inputs
    all_inputs = deepcopy(constant_inputs)
    for (key, value) in variable_inputs
        all_inputs[key] = value
    end

    # Validate compositions and pressure
    validate_compositions_and_pressure(all_inputs)

    # Validate oxides compatibility with MAGEMin
    validate_oxides(all_inputs)

    # Validate bulk composition and pressure constraints
    validate_bulk_and_pressure(all_inputs)

    # Validate the buffer
    validate_buffer(all_inputs)

    return all_inputs
end

export prepare_inputs

end
