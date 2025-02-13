using Test
using OrderedCollections
using FileIO

include("../src/GenerateEnsemble.jl")
using .GenerateEnsemble

@testset "update all inputs" begin
    all_inputs = OrderedDict("input1" => 1., "input2" => 2.)
    variable_inputs = OrderedDict("input1" => [10., 20.], "input2" => [30., 40.])
    combination = (10., 30.)  # This should update "input1" and "input2"

    updated_inputs = GenerateEnsemble.update_all_inputs(all_inputs, variable_inputs, combination)

    @test updated_inputs["input1"] == 10.
    @test updated_inputs["input2"] == 30.
end

@testset "prepare bulk and oxides" begin
    # Case 1: Only constant_inputs["bulk"] is provided
    constant_inputs = OrderedDict("bulk" => OrderedDict("SiO2" => 53.0, "Al2O3" => 12.0))
    variable_inputs = OrderedDict()

    bulk_init, Xoxides = GenerateEnsemble.prepare_bulk_and_oxides(constant_inputs, variable_inputs)

    # Expected output for constant inputs only
    @test bulk_init == [53.0, 12.0]
    @test Xoxides == ["SiO2", "Al2O3"]

    # Case 2: Only variable_inputs["bulk"] is provided
    constant_inputs = OrderedDict()
    variable_inputs = OrderedDict("bulk" => OrderedDict("SiO2" => [52.0, 53.0], "Al2O3" => [11.0, 12.0]))

    bulk_init, Xoxides = GenerateEnsemble.prepare_bulk_and_oxides(constant_inputs, variable_inputs)

    # Expected output for variable inputs only
    @test bulk_init == [[52.0, 11.0], [53.0, 12.0]]
    @test Xoxides == ["SiO2", "Al2O3"]

    # Case 3: Both constant_inputs["bulk"] and variable_inputs["bulk"] provided (non-matching oxides)
    constant_inputs = OrderedDict("bulk" => OrderedDict("SiO2" => 53.0))
    variable_inputs = OrderedDict("bulk" => OrderedDict("Al2O3" => [11.0, 12.0, 13.0]))

    bulk_init, Xoxides = GenerateEnsemble.prepare_bulk_and_oxides(constant_inputs, variable_inputs)

    # Expected output: Both oxides should be present
    @test bulk_init == [[53.0, 11.0], [53.0, 12.0], [53.0, 13.0]]
    @test Xoxides == ["SiO2", "Al2O3"]

end

@testset "check_variable_oxides" begin

    # Test case 1: No oxides in variable_inputs
    variable_inputs_1 = OrderedDict("P" => [0.5, 1.0], "offset" => [-2.0, -1.0])
    @test GenerateEnsemble.check_variable_oxides(variable_inputs_1) == Set([])

    # Test case 2: Only one oxide in variable_inputs
    variable_inputs_2 = OrderedDict("SiO2" => [52.0, 53.0], "P" => [0.5, 1.0])
    @test GenerateEnsemble.check_variable_oxides(variable_inputs_2) == Set(["SiO2"])

    # Test case 3: Multiple oxides in variable_inputs
    variable_inputs_3 = OrderedDict("SiO2" => [52.0, 53.0], "FeO" => [9.0, 10.0], "Al2O3" => [11.0, 12.0])
    @test GenerateEnsemble.check_variable_oxides(variable_inputs_3) == Set(["SiO2", "FeO", "Al2O3"])

    # Test case 4: Multiple oxides, and other inputs, in variable_inputs
    variable_inputs_4 = OrderedDict(
        "SiO2" => [52.0, 53.0], "FeO" => [9.0, 10.0], "Al2O3" => [11.0, 12.0],
        "P" => [0.5, 1.0], "offset" => [-2.0, -1.0]
        )
    @test GenerateEnsemble.check_variable_oxides(variable_inputs_4) == Set(["SiO2", "FeO", "Al2O3"])

end

# @testset "extract_variable_bulk_oxides" begin
#     # Test 1: Case where "bulk" is present and has keys
#     input_1 = OrderedDict("bulk" => OrderedDict("oxide1" => 10., "oxide2" => 20.), "other_key" => 5.)
#     expected_1 = OrderedDict("oxide1" => 10., "oxide2" => 20., "other_key" => 5.)
#     result_1 = GenerateEnsemble.extract_variable_bulk_oxides(input_1)
#     @test result_1 == expected_1

#     # Test 2: Case where "bulk" is not present
#     input_2 = OrderedDict("oxide1" => 30, "oxide2" => 40)
#     expected_2 = OrderedDict("oxide1" => 30, "oxide2" => 40)
#     result_2 = GenerateEnsemble.extract_variable_bulk_oxides(input_2)
#     @test result_2 == expected_2

#     # Test 3: Case where "bulk" exists but is empty
#     input_3 = OrderedDict("bulk" => OrderedDict(), "other_key" => 10)
#     expected_3 = OrderedDict("other_key" => 10)
#     result_3 = GenerateEnsemble.extract_variable_bulk_oxides(input_3)
#     @test result_3 == expected_3
# end

@testset "generate_output_filename" begin
    """
        contains_string(target, substrings)

    Function to check if a substring, or list of substrings, is contained within a target string.
    Necessary because if variable_inputs is a regular, nor ordered, dictionary, the output string is non-ordered.
    """
    function contains_string(target::String, substrings::Union{String, Vector{String}})::Bool
        if typeof(substrings) == String
            return occursin(substrings, target)
        elseif typeof(substrings) == Vector{String}
            return any(occursin.(substrings, target))
        end
    end

    # Test case 1: No oxides in variable_inputs
    variable_inputs_1 = OrderedDict("P" => [0.0, 1.0])
    combination_1 = (0.0,)
    file_name_1 = GenerateEnsemble.generate_output_filename(variable_inputs_1, combination_1)
    @test contains_string(file_name_1, "P=0.0")

    # Test case 2: Single oxide with no other variables
    variable_inputs_2 = OrderedDict("SiO2" => [52.0, 53.0])
    combination_2 = (52.0,)
    filename_2 = GenerateEnsemble.generate_output_filename(variable_inputs_2, combination_2)
    @test contains_string(filename_2, "SiO2=52.0")

    # Test case 3: Single oxide with multiple other variable inputs
    variable_inputs_3 = OrderedDict(
        "P" => [0.0, 1.0],
        "offset" => [0.5, 1.0],
        "SiO2" => [52.0, 53.0]
    )
    combination_3 = (0.0, 0.5, 52.0)
    filename_3 = GenerateEnsemble.generate_output_filename(variable_inputs_3, combination_3)
    @test contains_string(filename_3, ["P=0.0", "offset=0.5", "SiO2=52.0"])

    # Test case 4: Three oxides, no other variable inputs
    variable_inputs_4 = OrderedDict("SiO2" => [52.0, 53.0], "Al2O3" => [11.0, 12.0], "TiO2" => [1.0, 2.0])
    combination_4 = (1.0, 11.0, 52.0)
    filename_4 = GenerateEnsemble.generate_output_filename(variable_inputs_4, combination_4)
    @test contains_string(filename_4, ["TiO2=1.0", "Al2O3=11.0", "SiO2=52.0"])

    # Test case 5: Three oxides, multiple other inputs
    variable_inputs_5 = OrderedDict(
        "P" => [1.0, 2.0],
        "SiO2" => [52.0, 53.0], "Al2O3" => [11.0, 12.0], "TiO2" => [1.0, 2.0]
        )
    combination_5 = (1.0, 1.0, 11.0, 52.0)
    filename_5 = GenerateEnsemble.generate_output_filename(variable_inputs_5, combination_5)
    @test contains_string(filename_5, ["TiO2=1.0", "Al2O3=11.0", "SiO2=52.0", "P=1.0"])

    # Test case 6: More than three oxides, no other variable inputs
    variable_inputs_6 = OrderedDict(
        "SiO2" => [52.0, 53.0], "Al2O3" => [11.0, 12.0], "TiO2" => [1.0, 2.0], "FeO" => [9.0, 10.0]
        )
    combination_6 = (9.0, 1.0, 11.0, 52.0)
    file_name_6 = GenerateEnsemble.generate_output_filename(variable_inputs_6, combination_6)
    @test contains_string(file_name_6, ["bulk"])

    # Test case 7: More than three oxides, other variable inputs, second combination.
    variable_inputs_7 = OrderedDict(
        "P" => [0.5, 1.0],
        "SiO2" => [52.0, 53.0], "Al2O3" => [11.0, 12.0], "TiO2" => [1.0, 2.0], "FeO" => [9.0, 10.0]
        )
    combination_7 = (0.5, 1.0, 11.0, 52.0, 9.0)
    file_name_7 = GenerateEnsemble.generate_output_filename(variable_inputs_7, combination_7)
    @test contains_string(file_name_7, ["bulk", "P=0.5"])
end

@testset "setup_output_directory tests" begin

    # Test 1: output_dir is empty string, should default to current directory
    temp_dir = ""
    result_dir = GenerateEnsemble.setup_output_directory(temp_dir)
    @test result_dir == pwd()  # Should be the current directory

    # Test 1: output_dir is nothing, should default to current directory
    temp_dir = nothing
    result_dir = GenerateEnsemble.setup_output_directory(temp_dir)
    @test result_dir == pwd()  # Should be the current directory

    # Test 2: Directory does not exist, should create it
    temp_dir = mktempdir()  # Create temporary directory
    result_dir = GenerateEnsemble.setup_output_directory(temp_dir)
    @test isdir(result_dir)  # Check if the directory was created
    @test result_dir == temp_dir  # Ensure the right directory is returned

    # Test 3: Directory exists but contains no .csv files, should just return the directory
    temp_dir = mktempdir()
    result_dir = GenerateEnsemble.setup_output_directory(temp_dir)
    @test result_dir == temp_dir  # Should return the existing directory without prompting

    # Test 4: Directory exists and contains .csv files, should throw error
    temp_dir = mktempdir()
    touch(joinpath(temp_dir, "existing_file.csv"))  # Create a .csv file in the directory
    @test_throws ErrorException GenerateEnsemble.setup_output_directory(temp_dir)

end
