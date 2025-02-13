using Test
using OrderedCollections
include("../src/InputValidation.jl")
using .InputValidation


# Test that constant_inputs are numeric
@testset "Check constant_inputs values are numeric except 'bulk' and 'buffer'" begin
    # Valid input
    constant_inputs_valid = OrderedDict("bulk" => OrderedDict("SiO2" => 53.0, "FeO" => 10.0), "buffer" => "qfm", "P" => 1.0)

    # Test valid case
    @test InputValidation.check_constant_inputs_values(constant_inputs_valid) === nothing

    # Invalid case: non-numeric value in constant_inputs
    constant_inputs_invalid = OrderedDict("bulk" => OrderedDict("SiO2" => 53.0, "FeO" => "invalid_value"), "P" => 1.0)

    # Expect an ArgumentError because of the non-numeric "FeO" value in the "bulk" dictionary
    @test_throws ArgumentError InputValidation.check_constant_inputs_values(constant_inputs_invalid)

    # Invalid case: "buffer" is not a string
    constant_inputs_invalid_buffer = OrderedDict("bulk" => OrderedDict("SiO2" => 53.0, "FeO" => 10.0), "buffer" => 123)

    # Expect an ArgumentError because "buffer" is not a string
    @test_throws ArgumentError InputValidation.check_constant_inputs_values(constant_inputs_invalid_buffer)

    # Invalid case: a non-numeric value for a non-"bulk", non-"buffer" key
    constant_inputs_invalid_numeric = OrderedDict("bulk" => OrderedDict("SiO2" => 53.0, "FeO" => 10.0), "P" => "not_a_number")

    # Expect an ArgumentError because "P" is not numeric
    @test_throws ArgumentError InputValidation.check_constant_inputs_values(constant_inputs_invalid_numeric)

end

@testset "Check 'bulk' in constant_inputs" begin
    constant_inputs_valid = OrderedDict("bulk" => OrderedDict("SiO2" => 53.0, "FeO" => 10.0))

    # Test valid case
    @test InputValidation.check_bulk_in_constant_inputs(constant_inputs_valid) === nothing

    # Test invalid 'bulk' (non-numeric value)
    constant_inputs_invalid = OrderedDict("bulk" => OrderedDict("SiO2" => "invalid", "FeO" => 10.0))
    @test_throws ArgumentError InputValidation.check_bulk_in_constant_inputs(constant_inputs_invalid)

    # Test invalid 'bulk' (not a dictionary)
    constant_inputs_invalid2 = OrderedDict("bulk" => [53.0, 10.0])
    @test_throws ArgumentError InputValidation.check_bulk_in_constant_inputs(constant_inputs_invalid2)
end

@testset "Check variable_inputs values are vectors except 'bulk'" begin
    variable_inputs_valid = OrderedDict("bulk" => OrderedDict("SiO2" => [53.0, 54.0], "FeO" => [10.0, 11.0]), "temperature" => [300.0, 400.0])

    # Test valid case
    @test InputValidation.check_variable_inputs_values(variable_inputs_valid) === nothing

    # Test invalid case (non-vector value)
    variable_inputs_invalid = OrderedDict("temperature" => "300,400")
    @test_throws ArgumentError InputValidation.check_variable_inputs_values(variable_inputs_invalid)

end

@testset "Check 'bulk' in variable_inputs" begin
    variable_inputs_valid = OrderedDict("bulk" => OrderedDict("SiO2" => [53.0, 54.0], "FeO" => [10.0, 11.0]), "temperature" => [300.0, 400.0])

    # Test valid case
    @test InputValidation.check_bulk_in_variable_inputs(variable_inputs_valid) === nothing

    # Test invalid case (non-numeric vector in 'bulk')
    variable_inputs_invalid = OrderedDict("bulk" => OrderedDict("SiO2" => ["invalid", 54.0], "FeO" => [10.0, 11.0]))
    @test_throws ArgumentError InputValidation.check_bulk_in_variable_inputs(variable_inputs_invalid)

    # Test invalid case (non-vector in 'bulk')
    variable_inputs_invalid2 = OrderedDict("bulk" => OrderedDict("SiO2" => 53.0))
    @test_throws ArgumentError InputValidation.check_bulk_in_variable_inputs(variable_inputs_invalid2)

end

@testset "Check validate_inputs function" begin
    constant_inputs = OrderedDict("bulk" => OrderedDict("SiO2" => 53.0, "FeO" => 10.0), "buffer" => "qfm", "P" => 1.0)
    variable_inputs = OrderedDict("bulk" => OrderedDict("Al2O3" => [11.0, 12.0], "TiO2" => [1.0, 2.0]), "temperature" => [300.0, 400.0])

    # Test valid case
    @test InputValidation.validate_inputs(constant_inputs, variable_inputs) === nothing

    # Test invalid case (non-numeric value in constant_inputs)
    constant_inputs_invalid = OrderedDict("bulk" => OrderedDict("SiO2" => 53.0, "FeO" => "invalid"), "buffer" => "qfm")
    @test_throws ArgumentError InputValidation.validate_inputs(constant_inputs_invalid, variable_inputs)

end

@testset "Check_matching_bulk_oxides" begin
    # Test case 1: Matching oxides (should raise an error)
    constant_inputs_1 = OrderedDict("bulk" => OrderedDict("SiO2" => 53.0))
    variable_inputs_1 = OrderedDict("bulk" => OrderedDict("SiO2" => [52.0, 54.0]))
    @test_throws ErrorException InputValidation.check_matching_bulk_oxides(constant_inputs_1, variable_inputs_1)

    # Test case 2: No matching oxides (should pass without errors)
    constant_inputs_2 = OrderedDict("bulk" => OrderedDict("SiO2" => 53.0))
    variable_inputs_2 = OrderedDict("bulk" => OrderedDict("FeO" => [9.0, 10.0]))
    @test InputValidation.check_matching_bulk_oxides(constant_inputs_2, variable_inputs_2)  === nothing

    # Test case 3: No 'bulk' key in constant_inputs (should pass without errors)
    constant_inputs_3 = OrderedDict("P" => [1.0, 2.0])  # No "bulk" key here
    variable_inputs_3 = OrderedDict("bulk" => OrderedDict("SiO2" => [52.0, 54.0]))
    @test InputValidation.check_matching_bulk_oxides(constant_inputs_3, variable_inputs_3) === nothing

    # Test case 4: No 'bulk' key in variable_inputs (should pass without errors)
    constant_inputs_4 = OrderedDict("bulk" => OrderedDict("SiO2" => 53.0))
    variable_inputs_4 = OrderedDict("P" => [1.0, 2.0])  # No "bulk" key here
    @test InputValidation.check_matching_bulk_oxides(constant_inputs_4, variable_inputs_4) === nothing
end

# Test for validation of keys in constant and variable inputs
@testset "Key validation" begin
    # Test no common keys
    constant_inputs = OrderedDict("bulk" => Dict("SiO2" => 53.0), "P" => 1.0)
    variable_inputs = OrderedDict("buffer" => "qfm")

    @test InputValidation.validate_keys(constant_inputs, variable_inputs) === nothing

    # Test common keys (should trigger an error)
    constant_inputs_with_common_keys = OrderedDict("bulk" => Dict("SiO2" => 53.0), "P" => 1.0, "buffer" => "qfm")
    variable_inputs_with_common_keys = OrderedDict("buffer" => "qfm")

    @test_throws ErrorException InputValidation.validate_keys(constant_inputs_with_common_keys, variable_inputs_with_common_keys)
end

# # Test for bulk composition and pressure validation
# @testset "Composition and pressure validation" begin
#     all_inputs = OrderedDict("bulk" => Dict("SiO2" => 53.0), "P" => 1.0)

#     # Test that bulk composition and pressure are defined
#     @test InputValidation.validate_compositions_and_pressure(all_inputs) === nothing

#     # Test missing bulk composition (should trigger an error)
#     all_inputs_no_bulk = OrderedDict("P" => 1.0)
#     @test_throws ErrorException InputValidation.validate_compositions_and_pressure(all_inputs_no_bulk)

#     # Test missing pressure (should trigger an error)
#     all_inputs_no_pressure = OrderedDict("bulk" => Dict("SiO2" => 53.0))
#     @test_throws ErrorException InputValidation.validate_compositions_and_pressure(all_inputs_no_pressure)
# end

# Test set
@testset "Validate Oxides Tests" begin

    # Test Case 1: Valid constant bulk comp
    constant_inputs = OrderedDict("bulk" => OrderedDict(
        "SiO2" => 38.4, "TiO2" => 0.7, "Al2O3" => 7.7,
        "Cr2O3" => 0.0, "FeO" => 5.98, "MgO" => 9.95,
        "CaO" => 8.25, "Na2O" => 2.26, "K2O" => 0.24,
        "O" => 4.0, "H2O" => 12.7
        )
    )
    variable_inputs = OrderedDict()  # No variable bulk
    @test InputValidation.validate_oxides(constant_inputs, variable_inputs) === nothing

    # Test Case 2: Valid variable bulk comp
    constant_inputs = OrderedDict()  # No constant bulk
    variable_inputs = OrderedDict("bulk" => OrderedDict(
        "SiO2" => 38.4, "TiO2" => 0.7, "Al2O3" => 7.7,
        "Cr2O3" => 0.0, "FeO" => 5.98, "MgO" => 9.95,
        "CaO" => 8.25, "Na2O" => 2.26, "K2O" => 0.24,
        "O" => 4.0, "H2O" => 12.7
        )
    )
    @test InputValidation.validate_oxides(constant_inputs, variable_inputs) === nothing

    # Test Case 3: Valid oxides between variable and constant bulks
    constant_inputs = OrderedDict("bulk" => OrderedDict(
        "SiO2" => 38.4, "TiO2" => 0.7, "Al2O3" => 7.7,
        "Cr2O3" => 0.0, "FeO" => 5.98,
        )
    )
    variable_inputs = OrderedDict("bulk" => OrderedDict(
        "MgO" => 9.95, "CaO" => 8.25, "Na2O" => 2.26,
        "K2O" => 0.24, "O" => 4.0, "H2O" => 12.7
        )
    )
    @test InputValidation.validate_oxides(constant_inputs, variable_inputs) === nothing

    # Test Case 4: Invalid oxide in bulk composition
    constant_inputs = constant_inputs = OrderedDict("bulk" => OrderedDict(
        "Al2O3" => 7.7, "Cr2O3" => 0.0, "FeO" => 5.98, "MgO" => 9.95,
        "CaO" => 8.25, "Na2O" => 2.26, "K2O" => 0.24, "CuO" => 4.0, "H2O" => 12.7
        )
    )
    variable_inputs = OrderedDict("bulk" => Dict("SiO2" => [38.4, 38.5], "TiO2" => [0.7, 0.8]))
    @test_throws ErrorException InputValidation.validate_oxides(constant_inputs, variable_inputs)

    # Test Case 3: Both "O" and "Fe2O3" present together
    constant_inputs = OrderedDict("bulk" => Dict("SiO2" => 50.0, "O" => 10.0))
    variable_inputs = OrderedDict("bulk" => Dict("Fe2O3" => 20.0, "Na2O" => 5.0))
    @test_throws ErrorException InputValidation.validate_oxides(constant_inputs, variable_inputs)

    # Test Case 4: Missing oxide in bulk composition
    constant_inputs = OrderedDict("bulk" => Dict("SiO2" => 50.0, "TiO2" => 10.0, "FeO" => 30.0))
    variable_inputs = OrderedDict("bulk" => Dict("CaO" => 20.0))
    @test_throws ErrorException InputValidation.validate_oxides(constant_inputs, variable_inputs)
end

# Test for bulk composition and pressure constraints
@testset "Bulk and pressure constraints validation" begin
    all_inputs_valid = OrderedDict("bulk" => Dict("SiO2" => 53.0), "P" => 1.0)

    # Test valid bulk and pressure constraints
    @test InputValidation.validate_bulk_and_pressure(all_inputs_valid) === nothing

    # Test pressure 0 kbar conversion to 0.001 kbar
    all_inputs_P_0 = OrderedDict("bulk" => Dict("SiO2" => 53.0), "P" => 0.0)
    try
        InputValidation.validate_bulk_and_pressure(all_inputs_P_0)
        @test all_inputs_P_0["P"] == 0.001
        true
    catch e
        false
    end

    # Test oxide 0 wt% conversion to 0.001 wt%
    all_inputs_Bulk_0 = OrderedDict("bulk" => Dict("SiO2" => 0.), "P" => 1.0)
    try
        InputValidation.validate_bulk_and_pressure(all_inputs_Bulk_0)
        @test all_inputs_Bulk_0["bulk"]["SiO2"] == 0.001
        true
    catch e
        false
    end

    # Test invalid bulk composition
    all_inputs_invalid_bulk = OrderedDict("bulk" => Dict("SiO2" => -0.1), "P" => 1.0)
    @test_throws ErrorException InputValidation.validate_bulk_and_pressure(all_inputs_invalid_bulk)

    # Test invalid pressure value (should trigger an error)
    all_inputs_invalid_pressure = OrderedDict("bulk" => Dict("SiO2" => 53.0), "P" => [-1.0])
    @test_throws ErrorException InputValidation.validate_bulk_and_pressure(all_inputs_invalid_pressure)

end

# Test for buffer validation
@testset "validate_buffer tests" begin
    # Test 1: Valid single sbuffer in constant_inputs
    constant_inputs = OrderedDict("buffer" => "qfm")
    variable_inputs = OrderedDict()  # No buffer here
    @test InputValidation.validate_buffer(constant_inputs, variable_inputs) === nothing

    # Test 2: Valid vector of buffers in variable_inputs
    constant_inputs = OrderedDict()  # No buffer here
    variable_inputs = OrderedDict("buffer" => ["qif", "nno"])
    @test InputValidation.validate_buffer(constant_inputs, variable_inputs) === nothing

    # Test 3: Invalid buffer in constant_inputs (string)
    constant_inputs = OrderedDict("buffer" => "invalid_buffer")
    variable_inputs = OrderedDict()  # No buffer here
    @test_throws ErrorException InputValidation.validate_buffer(constant_inputs, variable_inputs)

    # Test 4: Invalid buffer in variable_inputs (vector)
    constant_inputs = OrderedDict()  # No buffer here
    variable_inputs = OrderedDict("buffer" => ["qif", "invalid_buffer"])
    @test_throws ErrorException InputValidation.validate_buffer(constant_inputs, variable_inputs)

    # Test 5: Missing buffer in both constant_inputs and variable_inputs
    constant_inputs = OrderedDict()  # No buffer here
    variable_inputs = OrderedDict()  # No buffer here
    @test InputValidation.validate_buffer(constant_inputs, variable_inputs) === nothing

    # Test 7: Valid buffers in both constant_inputs and variable_inputs
    constant_inputs = OrderedDict("buffer" => "hm")
    variable_inputs = OrderedDict("buffer" => ["cco", "aH2O"])
    @test InputValidation.validate_buffer(constant_inputs, variable_inputs) === nothing

    # Test 8: Check that variable 'buffer' is a vector of strings
    constant_inputs = OrderedDict("buffer" => "qfm")
    variable_inputs = OrderedDict("buffer" => ["qif", 123])  # Invalid entry (integer instead of string)
    @test_throws ErrorException InputValidation.validate_buffer(constant_inputs, variable_inputs)
end

@testset "check_buffer_if_offset" begin
    # Test 1: Both 'buffer' and 'offset' are present in constant
    constant_inputs = OrderedDict("buffer" => "qfm", "offset" => 1.0)
    variable_inputs = OrderedDict()
    @test InputValidation.check_buffer_if_offset(constant_inputs, variable_inputs) === nothing

    # Test 2: Both 'buffer' and 'offset' are present in variable
    constant_inputs = OrderedDict()
    variable_inputs = OrderedDict("buffer" => ["qfm", "nno"], "offset" => [1.0, 2.0])
    @test InputValidation.check_buffer_if_offset(constant_inputs, variable_inputs) === nothing

    # Test 3: 'buffer' in variable, 'offset' in constant
    constant_inputs = OrderedDict("offset" => 1.0)
    variable_inputs = OrderedDict("buffer" => ["qfm", "nno"])
    @test InputValidation.check_buffer_if_offset(constant_inputs, variable_inputs) === nothing

    # Test 4: 'offset' in variable, 'buffer' in constant
    constant_inputs = OrderedDict("buffer" => "qfm")
    variable_inputs = OrderedDict("offset" => [1.0, 2.0])
    @test InputValidation.check_buffer_if_offset(constant_inputs, variable_inputs) === nothing

    # Test 5: 'buffer' in constant, but 'offset' is missing
    constant_inputs = OrderedDict("buffer" => "qfm")
    variable_inputs = OrderedDict()
    @test InputValidation.check_buffer_if_offset(constant_inputs, variable_inputs) === nothing

    # Test 6: 'buffer' in variable, but 'offset' is missing
    constant_inputs = OrderedDict()
    variable_inputs = OrderedDict("buffer" => ["qfm", "nno"])
    @test InputValidation.check_buffer_if_offset(constant_inputs, variable_inputs) === nothing

    # Test 7: Neither 'buffer' nor 'offset' is present
    constant_inputs = OrderedDict()
    variable_inputs = OrderedDict()
    @test InputValidation.check_buffer_if_offset(constant_inputs, variable_inputs) === nothing

    # Test 8: 'offset' in constant, no buffer
    constant_inputs = OrderedDict("offset" => 1.0)
    variable_inputs = OrderedDict()
    @test_throws ErrorException InputValidation.check_buffer_if_offset(constant_inputs, variable_inputs)

    # Test 9: 'offset' in variable, no buffer
    constant_inputs = OrderedDict()
    variable_inputs = OrderedDict("offset" => [1.0, 2.0])
    @test_throws ErrorException InputValidation.check_buffer_if_offset(constant_inputs, variable_inputs)

end

# Test overall prepare_inputs function
@testset "Prepare inputs" begin
    constant_inputs = OrderedDict()
    constant_inputs["buffer"] = "qfm"
    constant_inputs["bulk"] = OrderedDict("SiO2" => 38.4, "TiO2" => 0.7, "Al2O3" => 7.7, "Cr2O3" => 0.0,
                                    "FeO" => 5.98, "MgO" => 9.95, "CaO" => 8.25, "Na2O" => 2.26,
                                    "K2O" => 0.24, "O" => 4.0, "H2O" => 12.7)
    variable_inputs = OrderedDict()
    variable_inputs["P"] = collect(range(start=0.0, stop=1.0, step=0.1))
    variable_inputs["buffer_offset"] = collect(range(start=-2., stop=2.0, step=0.5))

    # Test prepare_inputs with valid inputs
    @test begin
        try
            prepared_inputs = InputValidation.prepare_inputs(constant_inputs, variable_inputs)
            @test "bulk" in keys(prepared_inputs)
            @test "P" in keys(prepared_inputs)
            @test "buffer" in keys(prepared_inputs)
            true
        catch e
            false
        end
    end

    # Test prepare_inputs with missing bulk (should trigger an error)
    constant_inputs_no_bulk = OrderedDict("P" => 1.0, "buffer" => "qfm")
    variable_inputs_no_bulk = OrderedDict()
    @test_throws ErrorException InputValidation.prepare_inputs(constant_inputs_no_bulk, variable_inputs_no_bulk)

    # Test prepare_inputs with missing pressure (should trigger an error)
    constant_inputs_no_pressure = OrderedDict("buffer" => "qfm", "bulk" => OrderedDict("SiO2" => 53.0))
    variable_inputs_no_pressure = OrderedDict()
    @test_throws ErrorException InputValidation.prepare_inputs(constant_inputs_no_pressure, variable_inputs_no_pressure)

end

