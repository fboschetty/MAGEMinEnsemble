using Test
using Distributions
using OrderedCollections
using MAGEMinEnsemble

@testset "generate_bulk_mc" begin
    # Define input bulk composition and uncertainties
    bulk = OrderedDict("SiO2" => 50.0, "Al2O3" => 15.0, "FeO" => 10.0)
    abs_unc = OrderedDict("SiO2" => 2.0, "Al2O3" => 1.0, "FeO" => 0.0)  # FeO has 0.0 uncertainty
    n_samples = 5

    # Run function with replace_negatives = true (default behaviour)
    result_with_replace = MAGEMinEnsemble.MonteCarloBulk.generate_bulk_mc(bulk, abs_unc, n_samples, replace_negatives=true)

    # Check keys
    @test haskey(result_with_replace, "oxides")
    @test haskey(result_with_replace, "bulk")

    # Check oxides match input
    @test result_with_replace["oxides"] == collect(keys(bulk))

    # Check structure of bulk_mc output
    @test length(result_with_replace["bulk"]) == n_samples
    @test all(length(sample) == length(bulk) for sample in result_with_replace["bulk"])

    # Check that all values are non-negative
    @test all(all(value >= 0.0 for value in sample) for sample in result_with_replace["bulk"])

    # Test missing uncertainty key raises an error
    bulk_missing = OrderedDict("SiO2" => 50.0, "Al2O3" => 15.0, "MgO" => 5.0)
    abs_unc_missing = OrderedDict("SiO2" => 2.0, "Al2O3" => 1.0)  # Missing MgO
    @test_throws ErrorException MAGEMinEnsemble.MonteCarloBulk.generate_bulk_mc(bulk_missing, abs_unc_missing, n_samples)

    # Test extra uncertainty key raises an error
    abs_unc_extra = OrderedDict("SiO2" => 2.0, "Al2O3" => 1.0, "FeO" => 0.5, "TiO2" => 0.3)  # Extra TiO2
    @test_throws ErrorException MAGEMinEnsemble.MonteCarloBulk.generate_bulk_mc(bulk, abs_unc_extra, n_samples)

    # Test that negative values get replaced with zero
    bulk_negative = OrderedDict("SiO2" => -10000.0, "Al2O3" => -10000.0, "FeO" => -10000.0)  # Very negative
    @test_logs (:warn, r"Negative values replaced by zero") MAGEMinEnsemble.MonteCarloBulk.generate_bulk_mc(bulk_negative, abs_unc, n_samples)

    # Test when uncertainty is 0.0, result is constant for that oxide (FeO)
    feo_index = findfirst(x -> x == "FeO", result_with_replace["oxides"])  # Get the index of "FeO" in result["oxides"]

    # Check that the "FeO" value in all samples is constant
    @test all(result_with_replace["bulk"][i][feo_index] == bulk["FeO"] for i in 1:n_samples)

    # Run function with replace_negatives = false
    result_without_replace = MAGEMinEnsemble.MonteCarloBulk.generate_bulk_mc(bulk_negative, abs_unc, n_samples, replace_negatives=false)

    # Check that negative values are not replaced
    @test any(any(value < 0.0 for value in sample) for sample in result_without_replace["bulk"])
end

@testset "validate_bulk_mc_keys" begin
    # Valid dictionary (should not throw an error)
    valid_dict = OrderedDict("bulk" => [1.0, 2.0, 3.0], "oxides" => ["SiO2", "Al2O3"])
    @test MAGEMinEnsemble.MonteCarloBulk.validate_bulk_mc_keys(valid_dict) === nothing  # Should not throw

    # Missing "oxides" key (should throw an error)
    missing_oxides = OrderedDict("bulk" => [1.0, 2.0, 3.0])
    @test_throws ArgumentError MAGEMinEnsemble.MonteCarloBulk.validate_bulk_mc_keys(missing_oxides)

    # Missing "bulk" key (should throw an error)
    missing_bulk = OrderedDict("oxides" => ["SiO2", "Al2O3"])
    @test_throws ArgumentError MAGEMinEnsemble.MonteCarloBulk.validate_bulk_mc_keys(missing_bulk)

    # Extra key present (should throw an error)
    extra_key = OrderedDict("bulk" => [1.0, 2.0, 3.0], "oxides" => ["SiO2", "Al2O3"], "extra" => 42)
    @test_throws ArgumentError MAGEMinEnsemble.MonteCarloBulk.validate_bulk_mc_keys(extra_key)

    # Empty dictionary (should throw an error)
    empty_dict = OrderedDict()
    @test_throws ArgumentError MAGEMinEnsemble.MonteCarloBulk.validate_bulk_mc_keys(empty_dict)

    # Incorrect key names (should throw an error)
    wrong_keys = OrderedDict("composition" => [1.0, 2.0, 3.0], "elements" => ["SiO2", "Al2O3"])
    @test_throws ArgumentError MAGEMinEnsemble.MonteCarloBulk.validate_bulk_mc_keys(wrong_keys)
end

@testset "validate_bulk_mc_structure" begin
    # Valid case (should not throw an error)
    valid_bulk_mc = OrderedDict(
        "oxides" => ["SiO2", "Al2O3"],
        "bulk" => [[50.0, 15.0], [51.0, 14.5], [49.5, 15.5]]
    )
    @test MAGEMinEnsemble.MonteCarloBulk.validate_bulk_mc_structure(valid_bulk_mc) === nothing  # No error expected

    # Missing "oxides" key (should throw an error)
    missing_oxides = OrderedDict("bulk" => [[50.0, 15.0]])
    @test_throws ArgumentError MAGEMinEnsemble.MonteCarloBulk.validate_bulk_mc_structure(missing_oxides)

    # Missing "bulk" key (should throw an error)
    missing_bulk = OrderedDict("oxides" => ["SiO2", "Al2O3"])
    @test_throws ArgumentError MAGEMinEnsemble.MonteCarloBulk.validate_bulk_mc_structure(missing_bulk)

    # "oxides" is not a Vector{String} (should throw an error)
    wrong_oxides_type = OrderedDict("oxides" => [50.0, 15.0], "bulk" => [[50.0, 15.0]])
    @test_throws ArgumentError MAGEMinEnsemble.MonteCarloBulk.validate_bulk_mc_structure(wrong_oxides_type)

    # "bulk" is not a Vector{Vector{Float64}} (should throw an error)
    wrong_bulk_type = OrderedDict("oxides" => ["SiO2", "Al2O3"], "bulk" => [50.0, 15.0])
    @test_throws ArgumentError MAGEMinEnsemble.MonteCarloBulk.validate_bulk_mc_structure(wrong_bulk_type)

    # "bulk" contains non-Float64 values (should throw an error)
    bulk_with_wrong_values = OrderedDict("oxides" => ["SiO2", "Al2O3"], "bulk" => [[50.0, "text"], [51.0, 14.5]])
    @test_throws ArgumentError MAGEMinEnsemble.MonteCarloBulk.validate_bulk_mc_structure(bulk_with_wrong_values)

    # Empty dictionary (should throw an error)
    empty_dict = OrderedDict()
    @test_throws ArgumentError MAGEMinEnsemble.MonteCarloBulk.validate_bulk_mc_structure(empty_dict)
end

@testset "check_variable_inputs_vectors_mc" begin
    # Valid case: All values are vectors, except "bulk_mc"
    valid_inputs = OrderedDict{String, Union{Vector, OrderedDict}}(
        "pressure" => [1.0, 2.0, 3.0],
        "temperature" => [1000, 1100, 1200],
        "bulk_mc" => OrderedDict()
    )
    @test MAGEMinEnsemble.MonteCarloBulk.check_variable_inputs_vectors_mc(valid_inputs) === nothing

    # Non-vector value for a key other than "bulk_mc" (should throw an error)
    invalid_inputs = OrderedDict(
        "pressure" => 1000,  # Not a vector
        "temperature" => [1100, 1200],
        "bulk_mc" => OrderedDict()
    )
    @test_throws ArgumentError MAGEMinEnsemble.MonteCarloBulk.check_variable_inputs_vectors_mc(invalid_inputs)

    # Non-vector value for multiple keys (should throw an error)
    multiple_invalids = OrderedDict(
        "pressure" => 1000,  # Not a vector
        "temperature" => "not_a_vector",  # Also not a vector
        "bulk_mc" => OrderedDict()
    )
    @test_throws ArgumentError MAGEMinEnsemble.MonteCarloBulk.check_variable_inputs_vectors_mc(multiple_invalids)

    # Case where all values are vectors (including an empty vector)
    all_vectors = OrderedDict{String, Union{Vector, OrderedDict}}(
        "pressure" => [1.0, 2.0, 3.0],
        "temperature" => [],
        "bulk_mc" => OrderedDict()
    )
    @test MAGEMinEnsemble.MonteCarloBulk.check_variable_inputs_vectors_mc(all_vectors) === nothing
end

@testset "extract_bulk_mc" begin
    # Valid input: Extracts bulk_mc and restructures correctly
    constant_inputs = OrderedDict{String, Any}("P" => 1.0)
    variable_inputs = OrderedDict(
        "bulk_mc" => OrderedDict(
            "oxides" => ["SiO2", "Al2O3", "FeO"],
            "bulk" => [[50.0, 15.0, 10.0], [49.5, 15.2, 9.8]]
        ),
        "buffer" => ["qfm", "nno"]
    )

    new_constant_inputs, new_variable_inputs = MAGEMinEnsemble.MonteCarloBulk.extract_bulk_mc(constant_inputs, variable_inputs)

    # Check new_constant_inputs contains "oxides"
    @test haskey(new_constant_inputs, "oxides")
    @test new_constant_inputs["oxides"] == ["SiO2", "Al2O3", "FeO"]

    # Check other keys in constant_inputs are preserved
    @test new_constant_inputs["P"] == 1.0

    # Check new_variable_inputs contains "bulk" but not "bulk_mc"
    @test haskey(new_variable_inputs, "bulk")
    @test !haskey(new_variable_inputs, "bulk_mc")
    @test new_variable_inputs["bulk"] == [[50.0, 15.0, 10.0], [49.5, 15.2, 9.8]]

    # Ensure other keys in variable_inputs remain unchanged
    @test new_variable_inputs["buffer"] == ["qfm", "nno"]

    # Edge Case: Missing "bulk_mc" key should raise an error
    invalid_variable_inputs = OrderedDict("other_var" => [1., 2., 3.])
    @test_throws KeyError MAGEMinEnsemble.MonteCarloBulk.extract_bulk_mc(constant_inputs, invalid_variable_inputs)

    # Edge Case: "bulk_mc" missing "oxides" or "bulk" should raise an error
    invalid_bulk_mc_1 = OrderedDict("bulk" => [[50.0, 15.0, 10.0]])  # Missing "oxides"
    invalid_bulk_mc_2 = OrderedDict("oxides" => ["SiO2", "Al2O3", "FeO"])  # Missing "bulk"

    @test_throws KeyError MAGEMinEnsemble.MonteCarloBulk.extract_bulk_mc(constant_inputs, OrderedDict("bulk_mc" => invalid_bulk_mc_1))
    @test_throws KeyError MAGEMinEnsemble.MonteCarloBulk.extract_bulk_mc(constant_inputs, OrderedDict("bulk_mc" => invalid_bulk_mc_2))
end

@testset "replace_zero_oxides_mc!" begin
    # Sample input dictionaries
    variable_inputs = OrderedDict(
        "bulk_mc" => OrderedDict(
            "oxides" => ["SiO2", "Al2O3", "FeO", "H2O"],
            "bulk" => [[50.0, 15.0, 0.0, 5.0],  # First sample: FeO is zero
                       [48.0, 14.0, 10.0, 3.0], # No zeros
                       [47.0, 13.0, 0.0, 4.0]]  # Third sample: FeO is zero
        )
    )

    # Expected output (FeO values should be replaced with 0.001)
    expected_bulk = [[50.0, 15.0, 0.001, 5.0],
                     [48.0, 14.0, 10.0, 3.0],
                     [47.0, 13.0, 0.001, 4.0]]

    # Run function
    new_variable_inputs = MAGEMinEnsemble.MonteCarloBulk.replace_zero_oxides_mc(variable_inputs)

    # Test that oxides list is unchanged
    @test new_variable_inputs["bulk_mc"]["oxides"] == variable_inputs["bulk_mc"]["oxides"]

    # Test that zero values (except H2O) are replaced with 0.001
    @test new_variable_inputs["bulk_mc"]["bulk"] == expected_bulk

    # Ensure "H2O" remains unchanged
    h2o_index = findfirst(==("H2O"), variable_inputs["bulk_mc"]["oxides"])
    @test all(sample[h2o_index] == variable_inputs["bulk_mc"]["bulk"][i][h2o_index]
              for (i, sample) in enumerate(new_variable_inputs["bulk_mc"]["bulk"]))

    # Ensure non-zero values remain unchanged
    for i in 1:length(variable_inputs["bulk_mc"]["bulk"])
        @test all((var_val != 0.0 || var_ox == "H2O") || new_val == 0.001
                  for (var_val, var_ox, new_val) in zip(variable_inputs["bulk_mc"]["bulk"][i],
                                                         variable_inputs["bulk_mc"]["oxides"],
                                                         new_variable_inputs["bulk_mc"]["bulk"][i]))
    end
end

@testset "validate_positive_oxides_mc" begin
    # Test 1: All values positive (should pass)
    variable_inputs_valid = OrderedDict(
        "bulk_mc" => OrderedDict(
            "oxides" => ["SiO2", "Al2O3", "FeO"],
            "bulk" => [[50.0, 15.0, 10.0], [48.5, 14.8, 9.9]]
        )
    )

    @test MAGEMinEnsemble.MonteCarloBulk.validate_positive_oxides_mc(variable_inputs_valid) === nothing

    # Test 2: Negative value in bulk (should throw an error)
    variable_inputs_negative = OrderedDict(
        "bulk_mc" => OrderedDict(
            "oxides" => ["SiO2", "Al2O3", "FeO"],
            "bulk" => [[50.0, -15.0, 10.0], [48.5, 14.8, 9.9]]  # Negative Al2O3
        )
    )

    @test_throws ErrorException MAGEMinEnsemble.MonteCarloBulk.validate_positive_oxides_mc(variable_inputs_negative)

    # Test 3: Edge case where all values are zero (should pass)
    variable_inputs_zero = OrderedDict(
        "bulk_mc" => OrderedDict(
            "oxides" => ["SiO2", "Al2O3", "FeO"],
            "bulk" => [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]
        )
    )

    @test MAGEMinEnsemble.MonteCarloBulk.validate_positive_oxides_mc(variable_inputs_zero) === nothing
end

@testset "validate_oxides_mc" begin
    # Test 1: Valid case (should pass)
    variable_inputs_valid = OrderedDict(
        "bulk_mc" => OrderedDict(
            "oxides" => ["SiO2", "TiO2", "Al2O3", "Cr2O3", "FeO", "MgO", "CaO", "Na2O", "K2O", "H2O", "Fe2O3"]
        )
    )
    @test MAGEMinEnsemble.MonteCarloBulk.validate_oxides_mc(variable_inputs_valid) === nothing  # Should not throw an error

    # Test 2: Invalid oxide present (should throw an error)
    variable_inputs_invalid = OrderedDict(
        "bulk_mc" => OrderedDict(
            "oxides" => ["SiO2", "Al2O3", "MgO", "UnknownOxide"]  # Contains an invalid oxide
        )
    )
    @test_throws ErrorException MAGEMinEnsemble.MonteCarloBulk.validate_oxides_mc(variable_inputs_invalid)

    # Test 3: Both "O" and "Fe2O3" present (should throw an error)
    variable_inputs_conflict = OrderedDict(
        "bulk_mc" => OrderedDict(
            "oxides" => ["SiO2", "FeO", "O", "Fe2O3"]  # Both "O" and "Fe2O3" present
        )
    )
    @test_throws ErrorException MAGEMinEnsemble.MonteCarloBulk.validate_oxides_mc(variable_inputs_conflict)

    # Test 4: Neither "O" nor "Fe2O3" present (should throw an error)
    variable_inputs_missing_oxygen = OrderedDict(
        "bulk_mc" => OrderedDict(
            "oxides" => ["SiO2", "TiO2", "Al2O3", "Cr2O3", "FeO", "MgO", "CaO", "Na2O", "K2O", "H2O"]  # Missing both "O" and "Fe2O3"
        )
    )
    @test_throws ErrorException MAGEMinEnsemble.MonteCarloBulk.validate_oxides_mc(variable_inputs_missing_oxygen)

    # Test 5: Missing required oxides (should throw an error)
    variable_inputs_missing_oxides = OrderedDict(
        "bulk_mc" => OrderedDict(
            "oxides" => ["SiO2", "FeO", "Fe2O3"]  # Missing multiple required oxides
        )
    )
    @test_throws ErrorException MAGEMinEnsemble.MonteCarloBulk.validate_oxides_mc(variable_inputs_missing_oxides)
end

@testset "check_required_inputs_mc" begin
    # Test 1: All required inputs present (should pass)
    constant_inputs_valid = OrderedDict(
        "P" => 1.0,
        "T_start" => 800.0,
        "T_stop" => 1200.0,
        "T_step" => 50.0
    )
    variable_inputs_valid = OrderedDict(
        "bulk_mc" => OrderedDict("oxides" => ["SiO2", "FeO"], "bulk" => [[50.0, 50.0]])
    )
    @test MAGEMinEnsemble.MonteCarloBulk.check_required_inputs_mc(constant_inputs_valid, variable_inputs_valid) === nothing  # Should not throw an error

    # Test 2: Some required inputs in constant, others in variable (should pass)
    constant_inputs_partial = OrderedDict("P" => 1.0, "T_start" => 800.0)
    variable_inputs_partial = OrderedDict(
        "T_stop" => 1200.0,
        "T_step" => 50.0,
        "bulk_mc" => OrderedDict("oxides" => ["SiO2", "FeO"], "bulk" => [[50.0, 50.0]])
    )
    @test MAGEMinEnsemble.MonteCarloBulk.check_required_inputs_mc(constant_inputs_partial, variable_inputs_partial) === nothing  # Should not throw an error

    # Test 3: Missing one required input (should throw an error)
    constant_inputs_missing = OrderedDict("P" => 1.0, "T_start" => 800.0, "T_step" => 50.0)
    variable_inputs_missing = OrderedDict(
        "bulk_mc" => OrderedDict("oxides" => ["SiO2", "FeO"], "bulk" => [[50.0, 50.0]])
    )
    @test_throws ErrorException MAGEMinEnsemble.MonteCarloBulk.check_required_inputs_mc(constant_inputs_missing, variable_inputs_missing)

    # Test 4: Missing multiple required inputs (should throw an error)
    constant_inputs_few = OrderedDict("P" => 1.0)
    variable_inputs_few = OrderedDict("bulk_mc" => OrderedDict("oxides" => ["SiO2", "FeO"], "bulk" => [[50.0, 50.0]]))
    @test_throws ErrorException MAGEMinEnsemble.MonteCarloBulk.check_required_inputs_mc(constant_inputs_few, variable_inputs_few)

    # Test 5: No required inputs provided at all (should throw an error)
    constant_inputs_empty = OrderedDict()
    variable_inputs_empty = OrderedDict()
    @test_throws ErrorException MAGEMinEnsemble.MonteCarloBulk.check_required_inputs_mc(constant_inputs_empty, variable_inputs_empty)
end

@testset "generate_output_filename_mc" begin
    # Test case 1: Standard case with bulk variable
    variable_inputs = OrderedDict("bulk" => [[1., 2., 3.], [2., 3., 4.], [3., 4., 5.]], "temp" => [1000., 1100.])
    combination = ([1., 2., 3.], 1000.)
    @test MAGEMinEnsemble.MonteCarloBulk.generate_output_filename_mc(variable_inputs, combination) == "bulk=1_temp=1000.0"

    # Test case 2: Different bulk value
    combination = ([2., 3., 4.], 1100.)
    @test MAGEMinEnsemble.MonteCarloBulk.generate_output_filename_mc(variable_inputs, combination) == "bulk=2_temp=1100.0"

    # Test case 3: Multiple variables
    variable_inputs = OrderedDict("bulk" => [[1., 2., 3.], [2., 3., 4.]], "temp" => [900., 950.], "pressure" => [5., 10.])
    combination = ([2., 3., 4.], 950., 10.)
    @test MAGEMinEnsemble.MonteCarloBulk.generate_output_filename_mc(variable_inputs, combination) == "bulk=2_temp=950.0_pressure=10.0"

    # Test case 4: Bulk value not found (should throw an error)
    variable_inputs = OrderedDict("bulk" => [[1., 2., 3.], [2., 3., 4.]], "temp" => [900., 950.])
    combination = ([3., 4., 5.], 900.)
    @test_throws ErrorException MAGEMinEnsemble.MonteCarloBulk.generate_output_filename_mc(variable_inputs, combination)
end

@testset "get_bulk_oxides_mc" begin
    # Test case 1: Standard extraction
    all_inputs = OrderedDict("bulk" => [10.0, 20.0, 30.0], "oxides" => ["SiO2", "Al2O3", "FeO"])
    bulk_init, Xoxides = MAGEMinEnsemble.MonteCarloBulk.get_bulk_oxides_mc(all_inputs)
    @test bulk_init == [10.0, 20.0, 30.0]
    @test Xoxides == ["SiO2", "Al2O3", "FeO"]

    # Test case 2: Empty inputs
    all_inputs = OrderedDict("bulk" => [], "oxides" => [])
    bulk_init, Xoxides = MAGEMinEnsemble.MonteCarloBulk.get_bulk_oxides_mc(all_inputs)
    @test bulk_init == []
    @test Xoxides == []

    # Test case 3: Mismatched bulk and oxides length (should not raise error but return as is)
    all_inputs = OrderedDict("bulk" => [5.0, 15.0], "oxides" => ["MgO", "CaO", "Na2O"])
    bulk_init, Xoxides = MAGEMinEnsemble.MonteCarloBulk.get_bulk_oxides_mc(all_inputs)
    @test bulk_init == [5.0, 15.0]
    @test Xoxides == ["MgO", "CaO", "Na2O"]
end

@testset "prepare_inputs_mc" begin
    # Test 1: Valid Inputs
    constant_inputs = OrderedDict("P" => 1000., "T_start" => 1500., "T_stop" => 300., "T_step" => 10.)
    variable_inputs = OrderedDict("bulk_mc" => OrderedDict(
        "bulk" => [
            [43.75, 1.34, 15.61, 0.0, 11.01, 7.26, 11.32, 2.95, 0.24, 10.0, 0.0],
            [44.45, 1.59, 16.16, 0.0, 10.17, 8.01, 11.05, 2.68, 0.21, 10.0, 0.0]
            ],
        "oxides" => ["SiO2", "TiO2", "Al2O3", "Cr2O3", "FeO", "MgO", "CaO", "Na2O", "K2O", "O", "H2O"]
        )
        )
    bulk_frac = "bulk"
    td_database = "ig"

    new_constant_inputs, new_variable_inputs = MAGEMinEnsemble.MonteCarloBulk.prepare_inputs_mc(constant_inputs, variable_inputs, bulk_frac, td_database)

    @test haskey(new_constant_inputs, "oxides")
    @test haskey(new_variable_inputs, "bulk")
end