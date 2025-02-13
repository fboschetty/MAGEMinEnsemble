module InputValidation

using OrderedCollections


"""
    check_constant_inputs_values(constant_inputs)

Check the contents of constant_inputs for typing, ensure that numeric values are Float64.
"""
function check_constant_inputs_values(constant_inputs::OrderedDict)
    for (key, value) in constant_inputs
        if key == "bulk"
            check_bulk_in_constant_inputs(constant_inputs)

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

If "bulk" is a constant_input, check it is an ordered dict and that oxides are numeric.
"""
function check_bulk_in_constant_inputs(constant_inputs::OrderedDict)
    if haskey(constant_inputs, "bulk")
        if !(isa(constant_inputs["bulk"], OrderedDict))
            throw(ArgumentError("The key 'bulk' should be an ordered dictionary"))
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
function check_variable_inputs_values(variable_inputs::OrderedDict)
    for (key, value) in variable_inputs
        if key == "bulk"
            check_bulk_in_variable_inputs(variable_inputs)

        elseif !isa(value, AbstractVector)
            throw(ArgumentError("Non-vector value found for key: $key in variable_inputs"))
        end
    end
end


"""
    check_bulk_in_variable_input(constant_inputs)

If "bulk" is a variable input, check that it is an ordered dictionary and that it contains Vectors of Numeric values.
"""
function check_bulk_in_variable_inputs(variable_inputs::OrderedDict)
    if haskey(variable_inputs, "bulk")
        if !(isa(variable_inputs["bulk"], OrderedDict))
            throw(ArgumentError("The key 'bulk' should be an ordered dictionary."))
        end

        for (oxide, oxide_value) in variable_inputs["bulk"]
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
function check_matching_bulk_oxides(constant_inputs::OrderedDict, variable_inputs::OrderedDict)
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
function validate_inputs(constant_inputs::OrderedDict, variable_inputs::OrderedDict)
    check_constant_inputs_values(constant_inputs)
    check_variable_inputs_values(variable_inputs)
    check_bulk_in_constant_inputs(constant_inputs)
    check_bulk_in_variable_inputs(variable_inputs)
    check_matching_bulk_oxides(constant_inputs, variable_inputs)
end


"""
    validate_keys(constant_inputs, variable_inputs)

Check no keys are defined in both constant and variable inputs.
"""
function validate_keys(constant_inputs::OrderedDict, variable_inputs::OrderedDict)
    # Check for matching keys between constant and variable inputs
    common_keys = intersect(keys(variable_inputs), keys(constant_inputs))
    if !isempty(common_keys) && !("bulk" in common_keys)
        common_str = join(sort(collect(common_keys)), ", ")
        error("Matching keys in constant_inputs and variable_inputs ($common_str). Inputs must be either constant or variable, not both.")
    end
end


"""
    validate_compositions_and_pressure(constant_inputs, variable_inputs)

Check that list of required inputs is defined in either constant_inputs or variable_inputs
"""
function check_required_inputs_provided(constant_inputs::OrderedDict, variable_inputs::OrderedDict)
    required_inputs = ["P", "bulk"]

    # Check if each required input is present in either constant_inputs or variable_inputs
    for input in required_inputs
        if !(haskey(constant_inputs, input) || haskey(variable_inputs, input))
            error("Required input '$input' is missing from both constant_inputs and variable_inputs.")
        end
    end
end


"""
    validate_oxides(constant_inputs, variable_inputs)

Ensure that the defined bulk composition has the correct oxides included. Provides error messages that identify missing or extraneous oxides.
"""
function validate_oxides(constant_inputs::OrderedDict, variable_inputs::OrderedDict)
    # Define the accepted oxides for MAGEMin
    accepted_oxides = ["SiO2", "TiO2", "Al2O3", "Cr2O3", "FeO", "MgO", "CaO", "Na2O", "K2O", "H2O", "O", "Fe2O3"]

    # Extract bulk compositions & get oxides
    defined_oxides = []
    if haskey(variable_inputs, "bulk")
        variable_bulk = variable_inputs["bulk"]
        append!(defined_oxides, keys(variable_bulk))
    end

    if haskey(constant_inputs, "bulk")
        constant_bulk = constant_inputs["bulk"]
        append!(defined_oxides, keys(constant_bulk))
    end

    # Ensure all oxides in bulk composition are from the accepted list
    invalid_oxides = setdiff(defined_oxides, accepted_oxides)
    if !isempty(invalid_oxides)
        invalid_str = join(sort(collect(invalid_oxides)), ", ")
        error("Invalid oxides found in bulk composition: $invalid_str. Allowed oxides are: $(join(accepted_oxides, ", ")).")
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


function validate_positive_pressure(constant_inputs::OrderedDict, variable_inputs::OrderedDict)
    # Check for pressure in constant_inputs and add it if present
    if haskey(constant_inputs, "P")
        P = [constant_inputs["P"]]
    end

    # Check for pressure in variable_inputs and add it if present
    if haskey(variable_inputs, "P")
        P = variable_inputs["P"]
    end

    # Ensure all pressure values are positive
    if any(p -> p < 0.0, P)
        error("Pressure values must be positive. Found negative values: $(P[P .< 0.0])")
    end
end


function validate_positive_bulk_composition(bulk::Dict{String, Float64})
    # Exclude "H2O" and ensure all values are positive
    for (oxide, value) in bulk
        if value < 0.0
            error("Bulk composition for $oxide cannot be negative.")
        end
    end
end


function replace_zero_pressure!(P::Vector{Float64})
    for i in 1:length(P)
        if P[i] == 0.0
            P[i] = 0.001
        end
    end
    return P
end


function replace_zero_bulk_composition!(bulk::Dict{String, Float64})
    for (oxide, value) in bulk
        if oxide != "H2O" && value == 0.0
            bulk[oxide] = 0.001
        end
    end
    return bulk
end


"""
    validate_buffer(constant_inputs, variable_inputs)

Ensure that provided buffer string(s) is permitted by MAGEMin.
"""
function validate_buffer(constant_inputs::OrderedDict, variable_inputs::OrderedDict)
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
function check_buffer_if_offset(constant_inputs::OrderedDict, variable_inputs::OrderedDict)
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

Inputs:
    - constant_inputs (Dict): inputs that will remain unchanged between MAGEMin simulations.
    - variable_inputs (Dict): inputs that vary across MAGEMin simulations.

Outputs:
    - all_inputs (Dict): Single dictionary containing both variable and constant inputs that have the correct types to be used in MAGEMin.
"""
function prepare_inputs(constant_inputs::OrderedDict, variable_inputs::OrderedDict) :: AbstractDict
    # Check required inputs are defined in constant_inputs or variable_inputs
    check_required_inputs_provided(constant_inputs, variable_inputs)  # TESTS

    # Validate input types
    validate_inputs(constant_inputs, variable_inputs)

    # Validate keys in constant and variable inputs
    validate_keys(constant_inputs, variable_inputs)

    # Validate oxide compatibility with MAGEMin
    validate_oxides(constant_inputs, variable_inputs)

    # Validate the buffer
    validate_buffer(constant_inputs, variable_inputs)
    check_buffer_if_offset(constant_inputs, variable_inputs)

    # Validate bulk composition and pressure constraints
    validate_bulk_and_pressure(all_inputs)

    return all_inputs
end

export prepare_inputs

end
