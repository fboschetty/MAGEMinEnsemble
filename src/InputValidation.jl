module InputValidation

using OrderedCollections

export prepare_inputs

"""
    check_constant_inputs_values(constant_inputs)

Check the contents of constant_inputs for typing, ensure that numeric values are Float64.
"""
function check_constant_inputs_values(constant_inputs::OrderedDict)::Nothing
    for (key, value) in constant_inputs
        if key == "buffer"
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
    check_variable_inputs_vectors(variable_inputs)

Check that variable inputs are Vectors.
"""
function check_variable_inputs_vectors(variable_inputs::OrderedDict)::Nothing
    for (key, value) in variable_inputs

        if !isa(value, AbstractVector)
            throw(ArgumentError("Non-vector value found for key: $key in variable_inputs"))
        end
    end
end


"""
    check_required_inputs(constant_inputs, variable_inputs)

Check that list of required inputs is defined in either constant_inputs or variable_inputs
"""
function check_required_inputs(constant_inputs::OrderedDict, variable_inputs::OrderedDict)::Nothing
    required_inputs = ["P", "T_start", "T_stop", "T_step"]

    # Check if each required input is present in either constant_inputs or variable_inputs
    for input in required_inputs
        if !(haskey(constant_inputs, input) || haskey(variable_inputs, input))
            error("Required input '$input' is not present in either constant_inputs or variable_inputs.")
        end
    end
end


"""
    check_matching_keys(constant_inputs, variable_inputs)

Check no keys are defined in both constant and variable inputs.
"""
function check_matching_keys(constant_inputs::OrderedDict, variable_inputs::OrderedDict)::Nothing
    # Check for matching keys between constant and variable inputs
    common_keys = intersect(keys(variable_inputs), keys(constant_inputs))
    if !isempty(common_keys)
        common_str = join(sort(collect(common_keys)), ", ")
        error("Matching keys in constant_inputs and variable_inputs ($common_str). Inputs must be either constant or variable, not both.")
    end
end


"""
    oxides = check_keys_oxygen(od)

Returns keys in an ordered dictionary (`od`) that contain a capital "O".
"""
function check_keys_oxygen(od::OrderedDict)::Vector{String}
    oxides = []
    for key in keys(od)
        if occursin("O", key)  # Checks if "O" appears in the key
            push!(oxides, key)
        end
    end
    return oxides
end


"""
    validate_oxides(constant_inputs, variable_inputs)

Ensure that the defined bulk composition has the correct oxides included. Provides error messages that identify missing or extraneous oxides.
"""
function validate_oxides(constant_inputs::OrderedDict, variable_inputs::OrderedDict)::Nothing
    # Define the accepted oxides for MAGEMin
    accepted_oxides = ["SiO2", "TiO2", "Al2O3", "Cr2O3", "FeO", "MgO", "CaO", "Na2O", "K2O", "H2O", "O", "Fe2O3"]

    # Extract bulk compositions & get oxides
    variable_oxides = check_keys_oxygen(variable_inputs)
    constant_oxides = check_keys_oxygen(constant_inputs)
    defined_oxides = vcat(variable_oxides, constant_oxides)

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
    validate_positive_pressure(constant_inputs, variable_inputs)

Ensures that defined pressure value(s) are positive. Throws an error if they are negative.
"""
function validate_positive_pressure(constant_inputs::OrderedDict, variable_inputs::OrderedDict)::Nothing
    # Check for pressure in constant_inputs
    if haskey(constant_inputs, "P")
        P = [constant_inputs["P"]]
    end

    # Check for pressure in variable_inputs
    if haskey(variable_inputs, "P")
        P = variable_inputs["P"]
    end

    # Ensure all pressure values are positive
    if any(p -> p < 0.0, P)
        error("Pressure values must be positive. Found negative values: $(P[P .< 0.0])")
    end
end


"""
    validate_positive_oxides(constant_inputs, variable_inputs)

Ensures that defined oxide values are positive. Throws an error if they are negative.
"""
function validate_positive_oxides(constant_inputs::OrderedDict, variable_inputs::OrderedDict)::Nothing

    constant_oxides = check_keys_oxygen(constant_inputs)
    variable_oxides = check_keys_oxygen(variable_inputs)

    # Check for negative values in constant_inputs
    for oxide in constant_oxides
        if constant_inputs[oxide] < 0.0
            error("Oxide values must be positive. Found negative value in constant_inputs for $oxide")
        end
    end

    # Check for negative values in variable_inputs (vectors of oxides)
    for oxide in variable_oxides
        if any(v -> v < 0.0, variable_inputs[oxide])
            error("Oxide values must be positive. Found negative values in variable_inputs for $oxide: $(variable_inputs[oxide][variable_inputs[oxide] .< 0.0])")
        end
    end
end


"""
    new_constant_inputs, new_variable_inputs = replace_zero_pressure!(constant_inputs, variable_inputs)

Replaces pressures defined as 0.0 with 0.001
"""
function replace_zero_pressure(constant_inputs::OrderedDict, variable_inputs::OrderedDict)::Tuple{OrderedDict, OrderedDict}
    # Create copies of the input dictionaries to avoid mutation
    new_constant_inputs = copy(constant_inputs)
    new_variable_inputs = copy(variable_inputs)

    # Check for pressure in new_constant_inputs
    if haskey(new_constant_inputs, "P")
        if new_constant_inputs["P"] == 0.0
            new_constant_inputs["P"] = 0.001
        end
    end

    # Check for pressure in new_variable_inputs
    if haskey(new_variable_inputs, "P")
        new_variable_inputs["P"] .= replace(new_variable_inputs["P"], 0.0 => 0.001)
    end

    return new_constant_inputs, new_variable_inputs
end


"""
    new_constant_inputs, new_variable_inputs = replace_zero_oxides!(constant_inputs, variable_inputs)

Replaces oxides, except H2O, defined as 0.0 with 0.001.
"""
function replace_zero_oxides(constant_inputs::OrderedDict, variable_inputs::OrderedDict)::Tuple{OrderedDict, OrderedDict}
    # Create copies of the input dictionaries to avoid mutation
    new_constant_inputs = copy(constant_inputs)
    new_variable_inputs = copy(variable_inputs)

    # Get the oxide keys
    constant_oxides = check_keys_oxygen(new_constant_inputs)
    variable_oxides = check_keys_oxygen(new_variable_inputs)

    # Replace 0.0 with 0.001 for oxides in new_constant_inputs
    for oxide in constant_oxides
        if haskey(new_constant_inputs, oxide) && new_constant_inputs[oxide] == 0.0 && oxide != "H2O"
            new_constant_inputs[oxide] = 0.001
        end
    end

    # Replace 0.0 with 0.001 for oxides in new_variable_inputs
    for oxide in variable_oxides
        if haskey(new_variable_inputs, oxide) && oxide != "H2O"
            new_variable_inputs[oxide] .= replace(new_variable_inputs[oxide], 0.0 => 0.001)
        end
    end

    return new_constant_inputs, new_variable_inputs
end


"""
    validate_buffer(constant_inputs, variable_inputs)

Ensure that provided buffer string(s) is permitted by MAGEMin.
"""
function validate_buffer(constant_inputs::OrderedDict, variable_inputs::OrderedDict)::Nothing
    allowed_oxygen_buffers = ["qfm", "qif", "nno", "hm", "cco"]
    allowed_activity_buffers = ["aH2O", "aO2", "aMgO", "aFeO", "aAl2O3", "aTiO2", "aSio2"]
    allowed_buffers = vcat(allowed_oxygen_buffers, allowed_activity_buffers)

    # Skip checks if "buffer" isn't defined in either constant_inputs or variable_inputs
    if !haskey(constant_inputs, "buffer") && !haskey(variable_inputs, "buffer")
        return nothing
    end

    # Check if "buffer" is in constant_inputs and validate
    if haskey(constant_inputs, "buffer")
        buffer = constant_inputs["buffer"]
        if !(buffer in allowed_buffers)
            allowed_buffers_str = join(sort(collect(allowed_buffers)), ", ")
            error("Invalid buffer chosen : $buffer. It must be one of: $allowed_buffers_str")
        end
    end

    # Check if "buffer" is in variable_inputs and validate
    if haskey(variable_inputs, "buffer")
        buffers = variable_inputs["buffer"]
        # Ensure the "buffer" is a vector of strings
        if !(typeof(buffers) <: AbstractVector{String})
            error("In variable_inputs, 'buffer' must be a vector of strings.")
        end
        # Validate each buffer in the vector
        for buffer in buffers
            if !(buffer in allowed_buffers)
                allowed_buffers_str = join(sort(collect(allowed_buffers)), ", ")
                error("Invalid buffer chosen in variable_inputs: $buffer. It must be one of: $allowed_buffers_str")
            end
        end
    end
end


"""
    check_buffer_if_offset(constant_inputs::OrderedDict, variable_inputs::OrderedDict)

If offset is provided, checks that buffer is also provided.
"""
function check_buffer_if_offset(constant_inputs::OrderedDict, variable_inputs::OrderedDict)::Nothing
    # Check if "buffer" is present in either constant_inputs or variable_inputs
    if haskey(constant_inputs, "offset") || haskey(variable_inputs, "offset")
        if !haskey(constant_inputs, "buffer") && !haskey(variable_inputs, "buffer")
            error("'offset' key is present, but 'buffer' key is missing in either constant_inputs or variable_inputs.")
        end
    end
end


"""
    prepare_inputs(constant_inputs, variable_inputs)

Prepare and validate both constant_inputs and variable_inputs prior to ensure they are suitable for MAGEMin.

## Inputs:
- `constant_inputs` (Dict): inputs that will remain unchanged between MAGEMin simulations.
- `variable_inputs` (Dict): inputs that vary across MAGEMin simulations.

## Outputs:
- `updated_constant_inputs` (Dict): inputs that will remain unchanged between MAGEMin simulations.
- `updated_variable_inputs` (Dict): inputs that vary across MAGEMin simulations.
"""
function prepare_inputs(constant_inputs::OrderedDict, variable_inputs::OrderedDict)::Tuple{OrderedDict, OrderedDict}
    check_constant_inputs_values(constant_inputs)
    check_variable_inputs_vectors(variable_inputs)

    check_required_inputs(constant_inputs, variable_inputs)

    check_matching_keys(constant_inputs, variable_inputs)

    validate_oxides(constant_inputs, variable_inputs)

    validate_buffer(constant_inputs, variable_inputs)
    check_buffer_if_offset(constant_inputs, variable_inputs)

    validate_positive_pressure(constant_inputs, variable_inputs)
    validate_positive_oxides(constant_inputs, variable_inputs)

    new_constant_inputs, new_variable_inputs = replace_zero_pressure(constant_inputs, variable_inputs)
    new_constant_inputs, new_variable_inputs = replace_zero_oxides(new_constant_inputs, new_variable_inputs)

    return new_constant_inputs, new_variable_inputs
end


end
