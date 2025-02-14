using Test
using OrderedCollections

include("../src/InputValidation.jl")
using .InputValidation


# Test that constant_inputs are numeric
@testset "Check constant_inputs values are numeric" begin
    # Test Case 1: all constant inputs are Float64
    constant_inputs_valid = OrderedDict("SiO2" => 53.0, "FeO" => 10.0, "P" => 1.0)
    @test InputValidation.check_constant_inputs_values(constant_inputs_valid) === nothing

    # Test Case 2: buffer is a string
    constant_inputs_valid = OrderedDict("buffer" => "qfm")
    @test InputValidation.check_constant_inputs_values(constant_inputs_valid) === nothing

    # Test Case 3: non-numeric value in constant_inputs
    constant_inputs_invalid = OrderedDict("SiO2" => 53.0, "FeO" => "invalid_value", "P" => 1.0)
    @test_throws ArgumentError InputValidation.check_constant_inputs_values(constant_inputs_invalid)

    # Test Case 4: "buffer" is not a string
    constant_inputs_invalid_buffer = OrderedDict("SiO2" => 53.0, "FeO" => 10.0, "buffer" => 123)
    @test_throws ArgumentError InputValidation.check_constant_inputs_values(constant_inputs_invalid_buffer)
end

@testset "Check variable_inputs values are vectors" begin
    # Test Case 1: all variable_inputs are vectors
    variable_inputs_valid = OrderedDict("SiO2" => [53.0, 54.0], "FeO" => [10.0, 11.0], "temperature" => [300.0, 400.0])
    @test InputValidation.check_variable_inputs_vectors(variable_inputs_valid) === nothing

    # Test Case 2: non-vector value
    variable_inputs_invalid = OrderedDict("P" => "300,400")
    @test_throws ArgumentError InputValidation.check_variable_inputs_vectors(variable_inputs_invalid)
end

@testset "check_keys_oxygen" begin
    # Test case 1: Dictionary with keys containing "O"
    od = OrderedDict("SiO2" => 10.0, "TiO2" => 5.0, "Al2O3" => 7.0)
    @test InputValidation.check_keys_oxygen(od) == ["SiO2", "TiO2", "Al2O3"]  # All the keys contain "O"

    # Test case 2: Dictionary with no keys containing "O"
    od = OrderedDict("P" => 5.0)
    @test InputValidation.check_keys_oxygen(od) == []  # No keys contain "O"

    # Test case 3: Dictionary with some keys containing "O"
    od = OrderedDict("P" => 5.0, "SiO2" => 3.0, "FeO" => 2.0)
    @test InputValidation.check_keys_oxygen(od) == ["SiO2", "FeO"]  # Only SiO2 and FeO contain "O"

    # Test case 5: Empty dictionary (no keys)
    od = OrderedDict()
    @test InputValidation.check_keys_oxygen(od) == []  # No oxides as dictionary is empty

    # Test case 6: Dictionary with "O" in some keys, including "O" alone
    od = OrderedDict("O" => 2.0, "SiO2" => 10.0, "CaO" => 8.0)
    @test InputValidation.check_keys_oxygen(od) == ["O", "SiO2", "CaO"]  # "O" should be included
end


@testset "validate_oxides" begin
    # Test case 1: Valid oxides in constant_inputs.
    constant_inputs = OrderedDict("SiO2" => 38.4, "TiO2" => 0.7, "Al2O3" => 7.7,
                                  "Cr2O3" => 0.0, "FeO" => 5.98, "MgO" => 9.95,
                                  "CaO" => 8.25, "Na2O" => 2.26, "K2O" => 0.24,
                                  "O" => 4.0, "H2O" => 12.7,)
    variable_inputs = OrderedDict()
    @test InputValidation.validate_oxides(constant_inputs, variable_inputs) === nothing

    # Test case 1: Valid oxides in variable_inputs.
    constant_inputs = OrderedDict()
    variable_inputs = OrderedDict("SiO2" => [38.4, 38.5], "TiO2" => [0.7, 0.8], "Al2O3" => [7.7, 7.8],
                                  "Cr2O3" => [0.0, 0.1], "FeO" => [5.98, 5.99], "MgO" => [9.95, 9.96],
                                  "CaO" => [8.25, 8.26], "Na2O" => [2.26, 2.27], "K2O" => [0.24, 0.25],
                                  "O" => [4.0, 4.1], "H2O" => [12.7, 12.8])
    @test InputValidation.validate_oxides(constant_inputs, variable_inputs) === nothing

    # Test case 1: Valid oxides in across inputs.
    constant_inputs = OrderedDict("SiO2" => 38.4, "TiO2" => 0.7, "Al2O3" => 7.7,
                                  "Cr2O3" => 0.0, "FeO" => 5.98, "MgO" => 9.95)
    variable_inputs = OrderedDict("CaO" => [8.25, 8.26], "Na2O" => [2.26, 2.27], "K2O" => [0.24, 0.25],
                                  "O" => [4.0, 4.1], "H2O" => [12.7, 12.8])
    @test InputValidation.validate_oxides(constant_inputs, variable_inputs) === nothing

    # Test case 2: Invalid oxide in constant_inputs
    constant_inputs = OrderedDict("SiO2" => 38.4, "TiO2" => 0.7, "Al2O3" => 7.7,
                                  "Cr2O3" => 0.0, "FeO" => 5.98, "MgO" => 9.95,
                                  "CaO" => 8.25, "Na2O" => 2.26, "K2O" => 0.24,
                                  "O" => 4.0, "H2O" => 12.7, "CuO" => 13.0)  # "CuO" is invalid
    variable_inputs = OrderedDict()
    @test_throws ErrorException InputValidation.validate_oxides(constant_inputs, variable_inputs)

    # Test case 3: Invalid oxide in variable_inputs
    constant_inputs = OrderedDict()
    variable_inputs = OrderedDict("SiO2" => [38.4, 38.5], "TiO2" => [0.7, 0.8], "Al2O3" => [7.7, 7.8],
                                  "Cr2O3" => [0.0, 0.1], "FeO" => [5.98, 5.99], "MgO" => [9.95, 9.96],
                                  "CaO" => [8.25, 8.26], "Na2O" => [2.26, 2.27], "K2O" => [0.24, 0.25],
                                  "O" => [4.0, 4.1], "H2O" => [12.7, 12.8], "CuO" => [0.5, 0.6])  # "CuO" is invalid
    @test_throws ErrorException InputValidation.validate_oxides(constant_inputs, variable_inputs)

    # Test case 3: Invalid oxide in both
    constant_inputs = OrderedDict("SiO2" => 38.4, "TiO2" => 0.7, "Al2O3" => 7.7,
                                  "Cr2O3" => 0.0, "FeO" => 5.98, "MgO" => 9.95, "CuO" => 0.5)  # CuO is invalid
    variable_inputs = OrderedDict("CaO" => [8.25, 8.26], "Na2O" => [2.26, 2.27], "K2O" => [0.24, 0.25],
                                  "O" => [4.0, 4.1], "H2O" => [12.7, 12.8], "P2O5" => [0.2, 0.3])  # P2O5 is invalid
    @test_throws ErrorException InputValidation.validate_oxides(constant_inputs, variable_inputs)

    # Test case 4: Both "O" and "Fe2O3" in constant_inputs
    constant_inputs = OrderedDict("SiO2" => 38.4, "TiO2" => 0.7, "Al2O3" => 7.7,
                                  "Cr2O3" => 0.0, "FeO" => 5.98, "MgO" => 9.95,
                                  "CaO" => 8.25, "Na2O" => 2.26, "K2O" => 0.24,
                                  "O" => 4.0, "H2O" => 12.7, "Fe2O3" => 2.4)
    variable_inputs = OrderedDict()
    @test_throws ErrorException InputValidation.validate_oxides(constant_inputs, variable_inputs)

    # Test case 5: Both "O" and "Fe2O3" in variable_inputs
    constant_inputs = OrderedDict()
    variable_inputs = OrderedDict("SiO2" => [38.4, 38.5], "TiO2" => [0.7, 0.8], "Al2O3" => [7.7, 7.8],
                                  "Cr2O3" => [0.0, 0.1], "FeO" => [5.98, 5.99], "MgO" => [9.95, 9.96],
                                  "CaO" => [8.25, 8.26], "Na2O" => [2.26, 2.27], "K2O" => [0.24, 0.25],
                                  "O" => [4.0, 4.1], "H2O" => [12.7, 12.8], "Fe2O3" => [5.1, 5.2])
    @test_throws ErrorException InputValidation.validate_oxides(constant_inputs, variable_inputs)

    # Test case 6: Both "O" and "Fe2O3" present
    constant_inputs = OrderedDict("SiO2" => 38.4, "TiO2" => 0.7, "Al2O3" => 7.7,
                                  "Cr2O3" => 0.0, "FeO" => 5.98, "MgO" => 9.95, "Fe2O3" => 5.2)
    variable_inputs = OrderedDict("CaO" => [8.25, 8.26], "Na2O" => [2.26, 2.27], "K2O" => [0.24, 0.25],
                                  "O" => [4.0, 4.1], "H2O" => [12.7, 12.8])
    @test_throws ErrorException InputValidation.validate_oxides(constant_inputs, variable_inputs)

    # Test case 7: Neither "Fe2O3" nor "O" defined (should raise an error)
    constant_inputs = OrderedDict("SiO2" => 38.4, "TiO2" => 0.7, "Al2O3" => 7.7,
                                  "Cr2O3" => 0.0, "FeO" => 5.98, "MgO" => 9.95)
    variable_inputs = OrderedDict("CaO" => [8.25, 8.26], "Na2O" => [2.26, 2.27], "K2O" => [0.24, 0.25],
                                  "H2O" => [12.7, 12.8])
    @test_throws ErrorException InputValidation.validate_oxides(constant_inputs, variable_inputs)

    # Test case 8: Missing oxides constant
    constant_inputs = OrderedDict("SiO2" => 38.4, "TiO2" => 0.7, "Al2O3" => 7.7,
                                  "Cr2O3" => 0.0)
    variable_inputs = OrderedDict()
    @test_throws ErrorException InputValidation.validate_oxides(constant_inputs, variable_inputs)

    # Test case 8: Missing oxides variable
    constant_inputs = OrderedDict()
    variable_inputs = OrderedDict("SiO2" => [38.4, 38.5], "TiO2" => [0.7, 0.8], "Al2O3" => [7.7, 7.8],
                                  "Cr2O3" => [0.0, 0.1])
    @test_throws ErrorException InputValidation.validate_oxides(constant_inputs, variable_inputs)

    # Test case 8: Missing oxides across both
    constant_inputs = OrderedDict("SiO2" => 38.4, "TiO2" => 0.7, "Al2O3" => 7.7,
                                  "Cr2O3" => 0.0)
    variable_inputs = OrderedDict("CaO" => [8.25, 8.26], "Na2O" => [2.26, 2.27], "K2O" => [0.24, 0.25],
                                  "O" => [4.0, 4.1], "H2O" => [12.7, 12.8])
    @test_throws ErrorException InputValidation.validate_oxides(constant_inputs, variable_inputs)

end

# Test for validation of keys in constant and variable inputs
@testset "Key validation" begin
    # Test Case 1: no common keys
    constant_inputs = OrderedDict("SiO2" => 53.0, "P" => 1.0)
    variable_inputs = OrderedDict("buffer" => "qfm")
    @test InputValidation.check_matching_keys(constant_inputs, variable_inputs) === nothing

    # Test Case 2: common keys (should trigger an error)
    constant_inputs_with_common_keys = OrderedDict("SiO2" => 53.0, "P" => 1.0, "buffer" => "qfm")
    variable_inputs_with_common_keys = OrderedDict("buffer" => "qfm")
    @test_throws ErrorException InputValidation.check_matching_keys(constant_inputs_with_common_keys, variable_inputs_with_common_keys)
end

@testset "validate_positive_pressure" begin

    # Test case 1: Pressure defined in constant_inputs only, positive value
    constant_inputs = OrderedDict("P" => 1000.0)
    variable_inputs = OrderedDict()
    @test InputValidation.validate_positive_pressure(constant_inputs, variable_inputs) === nothing

    # Test case 2: Pressure defined in variable_inputs only, positive values
    constant_inputs = OrderedDict()
    variable_inputs = OrderedDict("P" => [1000.0, 500.0])
    @test InputValidation.validate_positive_pressure(constant_inputs, variable_inputs) === nothing

    # Test case 3: Pressure in constant_inputs with negative value
    constant_inputs = OrderedDict("P" => -10.0)
    variable_inputs = OrderedDict()
    @test_throws ErrorException InputValidation.validate_positive_pressure(constant_inputs, variable_inputs)

    # Test case 4: Pressure in variable_inputs with negative value
    constant_inputs = OrderedDict()
    variable_inputs = OrderedDict("P" => [5.0, -7.0])
    @test_throws ErrorException InputValidation.validate_positive_pressure(constant_inputs, variable_inputs)

end

@testset "validate_positive_oxides" begin

    # Test case 1: Oxides defined in constant_inputs only, all positive values
    constant_inputs = OrderedDict("SiO2" => 10.0, "TiO2" => 5.0)
    variable_inputs = OrderedDict()
    @test InputValidation.validate_positive_oxides(constant_inputs, variable_inputs) === nothing

    # Test case 2: Oxides defined in variable_inputs only, all positive values
    constant_inputs = OrderedDict()
    variable_inputs = OrderedDict("SiO2" => [10.0, 7.0], "TiO2" => [5.0, 6.0])
    @test InputValidation.validate_positive_oxides(constant_inputs, variable_inputs) === nothing

    # Test case 3: Oxides in constant_inputs with negative value
    constant_inputs = OrderedDict("SiO2" => -10.0, "TiO2" => 5.0)
    variable_inputs = OrderedDict()
    @test_throws ErrorException InputValidation.validate_positive_oxides(constant_inputs, variable_inputs)

    # Test case 4: Oxides in variable_inputs with negative value
    constant_inputs = OrderedDict()
    variable_inputs = OrderedDict("SiO2" => [10.0, -5.0], "TiO2" => [5.0, 6.0])
    @test_throws ErrorException InputValidation.validate_positive_oxides(constant_inputs, variable_inputs)

    # Test case 5: Oxides defined in both constant_inputs and variable_inputs, positive values
    constant_inputs = OrderedDict("SiO2" => 10.0, "TiO2" => 5.0)
    variable_inputs = OrderedDict("SiO2" => [7.0, 4.0], "TiO2" => [8.0, 9.0])
    @test InputValidation.validate_positive_oxides(constant_inputs, variable_inputs) === nothing

    # Test case 6: Oxides defined in both constant_inputs and variable_inputs, negative value in variable_inputs
    constant_inputs = OrderedDict("SiO2" => 10.0, "TiO2" => 5.0)
    variable_inputs = OrderedDict("SiO2" => [7.0, -4.0], "TiO2" => [8.0])
    @test_throws ErrorException InputValidation.validate_positive_oxides(constant_inputs, variable_inputs)

    # Test case 7: Oxides defined in both constant_inputs and variable_inputs, negative value in variable_inputs
    constant_inputs = OrderedDict("SiO2" => 10.0, "TiO2" => 5.0)
    variable_inputs = OrderedDict("SiO2" => [7.0, -4.0], "TiO2" => [8.0])
    @test_throws ErrorException InputValidation.validate_positive_oxides(constant_inputs, variable_inputs)

    # Test case 8: Oxides defined in both constant_inputs and variable_inputs, negative value in variable_inputs
    constant_inputs = OrderedDict("SiO2" => 10.0, "TiO2" => 5.0)
    variable_inputs = OrderedDict("SiO2" => [7.0, -4.0], "TiO2" => [8.0])
    @test_throws ErrorException InputValidation.validate_positive_oxides(constant_inputs, variable_inputs)

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

@testset "replace_zero_pressure" begin
    # Test case 1: Pressure in constant_inputs is 0.0, should be replaced with 0.001
    constant_inputs = OrderedDict("P" => 0.0)
    variable_inputs = OrderedDict()
    new_constant_inputs, new_variable_inputs = InputValidation.replace_zero_pressure(constant_inputs, variable_inputs)
    @test new_constant_inputs["P"] == 0.001

    # Test case 2: Pressure in constant_inputs is positive, should remain unchanged
    constant_inputs = OrderedDict("P" => 1000.0)
    variable_inputs = OrderedDict()
    new_constant_inputs, new_variable_inputs = InputValidation.replace_zero_pressure(constant_inputs, variable_inputs)
    @test new_constant_inputs["P"] == 1000.0

    # Test case 3: Pressure in variable_inputs is a vector with some 0.0 values, should be replaced
    constant_inputs = OrderedDict()
    variable_inputs = OrderedDict("P" => [0.0, 1000.0, 0.0])
    new_constant_inputs, new_variable_inputs = InputValidation.replace_zero_pressure(constant_inputs, variable_inputs)
    @test new_variable_inputs["P"] == [0.001, 1000.0, 0.001]

    # Test case 4: Pressure in variable_inputs is a vector with no 0.0 values, should remain unchanged
    constant_inputs = OrderedDict()
    variable_inputs = OrderedDict("P" => [1000.0, 500.0])
    new_constant_inputs, new_variable_inputs = InputValidation.replace_zero_pressure(constant_inputs, variable_inputs)
    @test new_variable_inputs["P"] == [1000.0, 500.0]

    # Test case 5: Pressure defined in both constant_inputs and variable_inputs, 0.0 values replaced
    constant_inputs = OrderedDict("P" => 0.0)
    variable_inputs = OrderedDict("P" => [0.0, 1000.0])
    new_constant_inputs, new_variable_inputs = InputValidation.replace_zero_pressure(constant_inputs, variable_inputs)
    @test new_constant_inputs["P"] == 0.001
    @test new_variable_inputs["P"] == [0.001, 1000.0]

    # Test case 6: Pressure in both constant_inputs and variable_inputs, no 0.0 values, should remain unchanged
    constant_inputs = OrderedDict("P" => 1000.0)
    variable_inputs = OrderedDict("P" => [1000.0, 500.0])
    new_constant_inputs, new_variable_inputs = InputValidation.replace_zero_pressure(constant_inputs, variable_inputs)
    @test new_constant_inputs["P"] == 1000.0
    @test new_variable_inputs["P"] == [1000.0, 500.0]
end


@testset "replace_zero_oxides" begin
    # Test case 1: Oxides in constant_inputs are 0.0, should be replaced with 0.001 (excluding H2O)
    constant_inputs = OrderedDict("SiO2" => 0.0, "TiO2" => 0.0, "H2O" => 0.0)
    variable_inputs = OrderedDict()
    new_constant_inputs, new_variable_inputs = InputValidation.replace_zero_oxides(constant_inputs, variable_inputs)
    @test new_constant_inputs["SiO2"] == 0.001
    @test new_constant_inputs["TiO2"] == 0.001
    @test new_constant_inputs["H2O"] == 0.0  # H2O should not be replaced

    # Test case 2: Oxides in constant_inputs are positive, should remain unchanged
    constant_inputs = OrderedDict("SiO2" => 1000.0, "TiO2" => 500.0)
    variable_inputs = OrderedDict()
    new_constant_inputs, new_variable_inputs = InputValidation.replace_zero_oxides(constant_inputs, variable_inputs)
    @test new_constant_inputs["SiO2"] == 1000.0
    @test new_constant_inputs["TiO2"] == 500.0

    # Test case 3: Oxides in variable_inputs are 0.0, should be replaced with 0.001 (excluding H2O)
    constant_inputs = OrderedDict()
    variable_inputs = OrderedDict("SiO2" => [0.0, 10.0], "TiO2" => [0.0, 5.0], "H2O" => [0.0, 0.0])
    new_constant_inputs, new_variable_inputs = InputValidation.replace_zero_oxides(constant_inputs, variable_inputs)
    @test new_variable_inputs["SiO2"] == [0.001, 10.0]
    @test new_variable_inputs["TiO2"] == [0.001, 5.0]
    @test new_variable_inputs["H2O"] == [0.0, 0.0]  # H2O should not be replaced

    # Test case 4: Oxides in variable_inputs are positive, should remain unchanged
    constant_inputs = OrderedDict()
    variable_inputs = OrderedDict("SiO2" => [1000.0, 500.0], "TiO2" => [300.0, 200.0])
    new_constant_inputs, new_variable_inputs = InputValidation.replace_zero_oxides(constant_inputs, variable_inputs)
    @test new_variable_inputs["SiO2"] == [1000.0, 500.0]
    @test new_variable_inputs["TiO2"] == [300.0, 200.0]

    # Test case 5: Pressure and oxides in both constant_inputs and variable_inputs, 0.0 values replaced
    constant_inputs = OrderedDict("SiO2" => 0.0, "TiO2" => 1000.0)
    variable_inputs = OrderedDict("TiO2" => [0.0, 500.0], "H2O" => [0.0, 0.0])
    new_constant_inputs, new_variable_inputs = InputValidation.replace_zero_oxides(constant_inputs, variable_inputs)
    @test new_constant_inputs["SiO2"] == 0.001
    @test new_constant_inputs["TiO2"] == 1000.0
    @test new_variable_inputs["TiO2"] == [0.001, 500.0]
    @test new_variable_inputs["H2O"] == [0.0, 0.0]  # H2O should not be replaced

    # Test case 6: Oxides with no 0.0 values in both constant_inputs and variable_inputs, should remain unchanged
    constant_inputs = OrderedDict("SiO2" => 1000.0, "TiO2" => 500.0)
    variable_inputs = OrderedDict("SiO2" => [1000.0, 500.0], "TiO2" => [300.0, 200.0])
    new_constant_inputs, new_variable_inputs = InputValidation.replace_zero_oxides(constant_inputs, variable_inputs)
    @test new_constant_inputs["SiO2"] == 1000.0
    @test new_constant_inputs["TiO2"] == 500.0
    @test new_variable_inputs["SiO2"] == [1000.0, 500.0]
    @test new_variable_inputs["TiO2"] == [300.0, 200.0]
end

