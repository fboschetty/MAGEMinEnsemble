using Test
using OrderedCollections
include("../src/InputValidation.jl")
using .InputValidation

# Test to check constant and variable inputs are dictionaries
@testset "Var Const Dictionaries" begin

    # Test constant inputs is a dictionary
    constant_inputs_dict = Dict()
    @test InputValidation.check_constant_inputs_dict(constant_inputs_dict) === nothing

    # Test constant inputs is an ordered dictionary
    constant_inputs_odict = OrderedDict()
    @test InputValidation.check_constant_inputs_dict(constant_inputs_odict) === nothing

    # Test constant inputs not dictionary (should throw error)
    @test_throws MethodError InputValidation.check_constant_inputs_dict([1, 2, 3])

    # Test variable inputs is a dictionary
    variable_inputs_dict = Dict()
    @test InputValidation.check_variable_inputs_dict(variable_inputs_dict) === nothing

    # Test variable inputs is an ordered dictionary
    variable_inputs_odict = OrderedDict()
    @test InputValidation.check_variable_inputs_dict(variable_inputs_odict) === nothing

    # Test variable inputs not dictionary (should throw error)
    @test_throws MethodError InputValidation.check_variable_inputs_dict([1, 2, 3])

end

# Test that constant_inputs are numeric
@testset "Check constant_inputs values are numeric except 'bulk' and 'buffer'" begin
    # Valid input
    constant_inputs_valid = Dict("bulk" => Dict("SiO2" => 53.0, "FeO" => 10.0), "buffer" => "qfm", "P" => 1.0)

    # Test valid case
    @test InputValidation.check_constant_inputs_values(constant_inputs_valid) === nothing

    # Invalid case: non-numeric value in constant_inputs
    constant_inputs_invalid = Dict("bulk" => Dict("SiO2" => 53.0, "FeO" => "invalid_value"), "P" => 1.0)

    # Expect an ArgumentError because of the non-numeric "FeO" value in the "bulk" dictionary
    @test_throws ArgumentError InputValidation.check_constant_inputs_values(constant_inputs_invalid)

    # Invalid case: "buffer" is not a string
    constant_inputs_invalid_buffer = Dict("bulk" => Dict("SiO2" => 53.0, "FeO" => 10.0), "buffer" => 123)

    # Expect an ArgumentError because "buffer" is not a string
    @test_throws ArgumentError InputValidation.check_constant_inputs_values(constant_inputs_invalid_buffer)

    # Invalid case: a non-numeric value for a non-"bulk", non-"buffer" key
    constant_inputs_invalid_numeric = Dict("bulk" => Dict("SiO2" => 53.0, "FeO" => 10.0), "P" => "not_a_number")

    # Expect an ArgumentError because "P" is not numeric
    @test_throws ArgumentError InputValidation.check_constant_inputs_values(constant_inputs_invalid_numeric)

end

@testset "Check 'bulk' in constant_inputs" begin
    constant_inputs_valid = Dict("bulk" => Dict("SiO2" => 53.0, "FeO" => 10.0))

    # Test valid case
    @test InputValidation.check_bulk_in_constant_inputs(constant_inputs_valid) === nothing

    # Test invalid 'bulk' (non-numeric value)
    constant_inputs_invalid = Dict("bulk" => Dict("SiO2" => "invalid", "FeO" => 10.0))
    @test_throws ArgumentError InputValidation.check_bulk_in_constant_inputs(constant_inputs_invalid)

    # Test invalid 'bulk' (not a dictionary)
    constant_inputs_invalid2 = Dict("bulk" => [53.0, 10.0])
    @test_throws ArgumentError InputValidation.check_bulk_in_constant_inputs(constant_inputs_invalid2)
end

@testset "Check variable_inputs values are vectors except 'bulk'" begin
    variable_inputs_valid = Dict("bulk" => Dict("SiO2" => [53.0, 54.0], "FeO" => [10.0, 11.0]), "temperature" => [300.0, 400.0])

    # Test valid case
    @test InputValidation.check_variable_inputs_values(variable_inputs_valid) === nothing

    # Test invalid case (non-vector value)
    variable_inputs_invalid = Dict("temperature" => "300,400")
    @test_throws ArgumentError InputValidation.check_variable_inputs_values(variable_inputs_invalid)

end

@testset "Check 'bulk' in variable_inputs" begin
    variable_inputs_valid = Dict("bulk" => Dict("SiO2" => [53.0, 54.0], "FeO" => [10.0, 11.0]), "temperature" => [300.0, 400.0])

    # Test valid case
    @test InputValidation.check_bulk_in_variable_inputs(variable_inputs_valid) === nothing

    # Test invalid case (non-numeric vector in 'bulk')
    variable_inputs_invalid = Dict("bulk" => Dict("SiO2" => ["invalid", 54.0], "FeO" => [10.0, 11.0]))
    @test_throws ArgumentError InputValidation.check_bulk_in_variable_inputs(variable_inputs_invalid)

    # Test invalid case (non-vector in 'bulk')
    variable_inputs_invalid2 = Dict("bulk" => Dict("SiO2" => 53.0))
    @test_throws ArgumentError InputValidation.check_bulk_in_variable_inputs(variable_inputs_invalid2)

end

@testset "Check validate_inputs function" begin
    constant_inputs = Dict("bulk" => Dict("SiO2" => 53.0, "FeO" => 10.0), "buffer" => "qfm", "P" => 1.0)
    variable_inputs = Dict("bulk" => Dict("SiO2" => [53.0, 54.0], "FeO" => [10.0, 11.0]), "temperature" => [300.0, 400.0])

    # Test valid case
    @test InputValidation.validate_inputs(constant_inputs, variable_inputs) === nothing

    # Test invalid case (non-numeric value in constant_inputs)
    constant_inputs_invalid = Dict("bulk" => Dict("SiO2" => 53.0, "FeO" => "invalid"), "buffer" => "qfm")
    @test_throws ArgumentError InputValidation.validate_inputs(constant_inputs_invalid, variable_inputs)

end

@testset "Check_matching_bulk_oxides" begin
    # Test case 1: Matching oxides (should raise an error)
    constant_inputs_1 = Dict("bulk" => OrderedDict("SiO2" => 53.0))
    variable_inputs_1 = Dict("bulk" => OrderedDict("SiO2" => [52.0, 54.0]))
    @test_throws ErrorException InputValidation.check_matching_bulk_oxides(constant_inputs_1, variable_inputs_1)

    # Test case 2: No matching oxides (should pass without errors)
    constant_inputs_2 = Dict("bulk" => OrderedDict("SiO2" => 53.0))
    variable_inputs_2 = Dict("bulk" => OrderedDict("FeO" => [9.0, 10.0]))
    @test InputValidation.check_matching_bulk_oxides(constant_inputs_2, variable_inputs_2)  === nothing

    # Test case 3: No 'bulk' key in constant_inputs (should pass without errors)
    constant_inputs_3 = Dict("P" => [1.0, 2.0])  # No "bulk" key here
    variable_inputs_3 = Dict("bulk" => OrderedDict("SiO2" => [52.0, 54.0]))
    @test InputValidation.check_matching_bulk_oxides(constant_inputs_3, variable_inputs_3) === nothing

    # Test case 4: No 'bulk' key in variable_inputs (should pass without errors)
    constant_inputs_4 = Dict("bulk" => OrderedDict("SiO2" => 53.0))
    variable_inputs_4 = Dict("P" => [1.0, 2.0])  # No "bulk" key here
    @test InputValidation.check_matching_bulk_oxides(constant_inputs_4, variable_inputs_4) === nothing
end

@testset "Combine constant and variable bulk" begin
    # Test 1: Constant_inputs has the "bulk" key only
    constant_inputs = Dict("bulk" => OrderedDict("SiO2" => 53.0))
    variable_inputs = Dict()

    expected_constant_inputs = Dict("bulk" => OrderedDict("SiO2" => 53.0))
    expected_variable_inputs = Dict()

    result_constant_inputs, result_variable_inputs = InputValidation.combine_bulk_compositions!(constant_inputs, variable_inputs)

    @test result_constant_inputs == expected_constant_inputs
    @test result_variable_inputs == expected_variable_inputs

    # Test 2: Variable_inputs has the "bulk" key only
    constant_inputs = Dict()
    variable_inputs = Dict("bulk" => OrderedDict("Al2O3" => [11.0, 12.0, 13.0]))

    expected_constant_inputs = Dict()
    expected_variable_inputs = Dict("bulk" => OrderedDict("Al2O3" => [11.0, 12.0, 13.0]))

    result_constant_inputs, result_variable_inputs = InputValidation.combine_bulk_compositions!(constant_inputs, variable_inputs)

    @test result_constant_inputs == expected_constant_inputs
    @test result_variable_inputs == expected_variable_inputs

    # Test 3: Both constant_inputs and variable_inputs have the "bulk" key only
    constant_inputs = Dict("bulk" => OrderedDict("SiO2" => 53.0))
    variable_inputs = Dict("bulk" => OrderedDict("Al2O3" => [11.0, 12.0, 13.0]))

    expected_constant_inputs = Dict()
    expected_variable_inputs = Dict("bulk" => OrderedDict("SiO2" => [53.0, 53.0, 53.0], "Al2O3" => [11.0, 12.0, 13.0]))

    result_constant_inputs, result_variable_inputs = InputValidation.combine_bulk_compositions!(constant_inputs, variable_inputs)

    @test result_constant_inputs == expected_constant_inputs
    @test result_variable_inputs == expected_variable_inputs

    # Test 4: constant_inputs has bulk and P, variable inputs has bulk. Check P remains in constant.
    constant_inputs = Dict("bulk" => OrderedDict("SiO2" => 53.0), "P" => 2.0)
    variable_inputs = Dict("bulk" => OrderedDict("Al2O3" => [11.0, 12.0, 13.0]))

    expected_constant_inputs = Dict("P" => 2.0)
    expected_variable_inputs = Dict("bulk" => OrderedDict("SiO2" => [53.0, 53.0, 53.0], "Al2O3" => [11.0, 12.0, 13.0]))

    result_constant_inputs, result_variable_inputs = InputValidation.combine_bulk_compositions!(constant_inputs, variable_inputs)

    @test result_constant_inputs == expected_constant_inputs
    @test result_variable_inputs == expected_variable_inputs

    # Test 4: constant_inputs has bulk and P, variable inputs has bulk and buffer_offset. Check P remains in constant, buffer in variable.
    constant_inputs = Dict("bulk" => OrderedDict("SiO2" => 53.0), "P" => 2.0)
    variable_inputs = Dict("bulk" => OrderedDict("Al2O3" => [11.0, 12.0, 13.0]), "buffer_offset" => [1.0, 2.0])

    expected_constant_inputs = Dict("P" => 2.0)
    expected_variable_inputs = Dict("bulk" => OrderedDict("SiO2" => [53.0, 53.0, 53.0], "Al2O3" => [11.0, 12.0, 13.0]), "buffer_offset" => [1.0, 2.0])

    result_constant_inputs, result_variable_inputs = InputValidation.combine_bulk_compositions!(constant_inputs, variable_inputs)

    @test result_constant_inputs == expected_constant_inputs
    @test result_variable_inputs == expected_variable_inputs

end


# Test for validation of keys in constant and variable inputs
@testset "Key validation" begin
    # Test no common keys
    constant_inputs = Dict("bulk" => Dict("SiO2" => 53.0), "P" => 1.0)
    variable_inputs = Dict("buffer" => "qfm")

    @test InputValidation.validate_keys(constant_inputs, variable_inputs) === nothing

    # Test common keys (should trigger an error)
    constant_inputs_with_common_keys = Dict("bulk" => Dict("SiO2" => 53.0), "P" => 1.0, "buffer" => "qfm")
    variable_inputs_with_common_keys = Dict("buffer" => "qfm")

    @test_throws ErrorException InputValidation.validate_keys(constant_inputs_with_common_keys, variable_inputs_with_common_keys)
end

# Test for bulk composition and pressure validation
@testset "Composition and pressure validation" begin
    all_inputs = Dict("bulk" => Dict("SiO2" => 53.0), "P" => 1.0)

    # Test that bulk composition and pressure are defined
    @test InputValidation.validate_compositions_and_pressure(all_inputs) === nothing

    # Test missing bulk composition (should trigger an error)
    all_inputs_no_bulk = Dict("P" => 1.0)
    @test_throws ErrorException InputValidation.validate_compositions_and_pressure(all_inputs_no_bulk)

    # Test missing pressure (should trigger an error)
    all_inputs_no_pressure = Dict("bulk" => Dict("SiO2" => 53.0))
    @test_throws ErrorException InputValidation.validate_compositions_and_pressure(all_inputs_no_pressure)
end

# Test for oxides validation
@testset "Oxide validation" begin
    all_inputs_valid = Dict()
    all_inputs_valid["P"] = 1.0
    all_inputs_valid["bulk"] = Dict("SiO2" => 38.4, "TiO2" => 0.7, "Al2O3" => 7.7, "Cr2O3" => 0.0,
                                         "FeO" => 5.98, "MgO" => 9.95, "CaO" => 8.25, "Na2O" => 2.26,
                                         "K2O" => 0.24, "O" => 4.0, "H2O" => 12.7)
    # Test valid oxides
    @test InputValidation.validate_oxides(all_inputs_valid) === nothing

    # Test incompatible oxides (O and Fe2O3 together, should trigger an error)
    all_inputs_invalid_oxides = Dict("bulk" => Dict("O" => 1.0, "Fe2O3" => 1.0), "P" => 1.0)
    @test_throws ErrorException InputValidation.validate_oxides(all_inputs_invalid_oxides)

    # Test invalid oxide (should trigger an error)
    all_inputs_invalid_oxide = Dict("bulk" => Dict("CuO" => 1.0), "P" => 1.0)
    @test_throws ErrorException InputValidation.validate_oxides(all_inputs_invalid_oxide)

    # Test missing oxide (should trigger an error)
    all_inputs_missing_oxide = Dict("bulk" => Dict("SiO2" => 53.0), "P" => 1.0)
    @test_throws ErrorException InputValidation.validate_oxides(all_inputs_missing_oxide)

end

# Test for bulk composition and pressure constraints
@testset "Bulk and pressure constraints validation" begin
    all_inputs_valid = Dict("bulk" => Dict("SiO2" => 53.0), "P" => 1.0)

    # Test valid bulk and pressure constraints
    @test InputValidation.validate_bulk_and_pressure(all_inputs_valid) === nothing

    # Test pressure 0 kbar conversion to 0.001 kbar
    all_inputs_P_0 = Dict("bulk" => Dict("SiO2" => 53.0), "P" => 0.0)
    try
        InputValidation.validate_bulk_and_pressure(all_inputs_P_0)
        @test all_inputs_P_0["P"] == 0.001
        true
    catch e
        false
    end

    # Test oxide 0 wt% conversion to 0.001 wt%
    all_inputs_Bulk_0 = Dict("bulk" => Dict("SiO2" => 0.), "P" => 1.0)
    try
        InputValidation.validate_bulk_and_pressure(all_inputs_Bulk_0)
        @test all_inputs_Bulk_0["bulk"]["SiO2"] == 0.001
        true
    catch e
        false
    end

    # Test invalid bulk composition
    all_inputs_invalid_bulk = Dict("bulk" => Dict("SiO2" => -0.1), "P" => 1.0)
    @test_throws ErrorException InputValidation.validate_bulk_and_pressure(all_inputs_invalid_bulk)

    # Test invalid pressure value (should trigger an error)
    all_inputs_invalid_pressure = Dict("bulk" => Dict("SiO2" => 53.0), "P" => [-1.0])
    @test_throws ErrorException InputValidation.validate_bulk_and_pressure(all_inputs_invalid_pressure)

end

# Test for buffer validation
@testset "Buffer validation" begin
    all_inputs_valid_buffer = Dict("buffer" => "qfm", "P" => 1.0, "bulk" => Dict("SiO2" => 53.0))

    # Test valid buffer
    @test InputValidation.validate_buffer(all_inputs_valid_buffer) === nothing

    # Test invalid buffer (should trigger an error)
    all_inputs_invalid_buffer = Dict("buffer" => "invalid_buffer", "P" => 1.0, "bulk" => Dict("SiO2" => 53.0))
    @test_throws ErrorException InputValidation.validate_buffer(all_inputs_invalid_buffer)

end

# Test overall prepare_inputs function
@testset "Prepare inputs" begin
    constant_inputs = Dict()
    constant_inputs["buffer"] = "qfm"
    constant_inputs["bulk"] = Dict("SiO2" => 38.4, "TiO2" => 0.7, "Al2O3" => 7.7, "Cr2O3" => 0.0,
                                    "FeO" => 5.98, "MgO" => 9.95, "CaO" => 8.25, "Na2O" => 2.26,
                                    "K2O" => 0.24, "O" => 4.0, "H2O" => 12.7)
    variable_inputs = Dict()
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
    constant_inputs_no_bulk = Dict("P" => 1.0, "buffer" => "qfm")
    variable_inputs_no_bulk = Dict()
    @test_throws ErrorException InputValidation.prepare_inputs(constant_inputs_no_bulk, variable_inputs_no_bulk)

    # Test prepare_inputs with missing pressure (should trigger an error)
    constant_inputs_no_pressure = Dict("buffer" => "qfm", "bulk" => Dict("SiO2" => 53.0))
    variable_inputs_no_pressure = Dict()
    @test_throws ErrorException InputValidation.prepare_inputs(constant_inputs_no_pressure, variable_inputs_no_pressure)

end

