using Test
using OrderedCollections
using FileIO

using MAGEMinEnsemble

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
    file_name_1 = MAGEMinEnsemble.Output.generate_output_filename(variable_inputs_1, combination_1)
    @test contains_string(file_name_1, "P=0.0")

    # Test case 2: Single oxide with no other variables
    variable_inputs_2 = OrderedDict("SiO2" => [52.0, 53.0])
    combination_2 = (52.0,)
    filename_2 = MAGEMinEnsemble.Output.generate_output_filename(variable_inputs_2, combination_2)
    @test contains_string(filename_2, "SiO2=52.0")

    # Test case 3: Single oxide with multiple other variable inputs
    variable_inputs_3 = OrderedDict(
        "P" => [0.0, 1.0],
        "offset" => [0.5, 1.0],
        "SiO2" => [52.0, 53.0]
    )
    combination_3 = (0.0, 0.5, 52.0)
    filename_3 = MAGEMinEnsemble.Output.generate_output_filename(variable_inputs_3, combination_3)
    @test contains_string(filename_3, ["P=0.0", "offset=0.5", "SiO2=52.0"])

    # Test case 4: Three oxides, no other variable inputs
    variable_inputs_4 = OrderedDict("SiO2" => [52.0, 53.0], "Al2O3" => [11.0, 12.0], "TiO2" => [1.0, 2.0])
    combination_4 = (1.0, 11.0, 52.0)
    filename_4 = MAGEMinEnsemble.Output.generate_output_filename(variable_inputs_4, combination_4)
    @test contains_string(filename_4, ["TiO2=1.0", "Al2O3=11.0", "SiO2=52.0"])

    # Test case 5: Three oxides, multiple other inputs
    variable_inputs_5 = OrderedDict(
        "P" => [1.0, 2.0],
        "SiO2" => [52.0, 53.0], "Al2O3" => [11.0, 12.0], "TiO2" => [1.0, 2.0]
        )
    combination_5 = (1.0, 1.0, 11.0, 52.0)
    filename_5 = MAGEMinEnsemble.Output.generate_output_filename(variable_inputs_5, combination_5)
    @test contains_string(filename_5, ["TiO2=1.0", "Al2O3=11.0", "SiO2=52.0", "P=1.0"])

    # # Test case 6: More than three oxides, no other variable inputs
    # variable_inputs_6 = OrderedDict(
    #     "SiO2" => [52.0, 53.0], "Al2O3" => [11.0, 12.0], "TiO2" => [1.0, 2.0], "FeO" => [9.0, 10.0]
    #     )
    # combination_6 = (9.0, 1.0, 11.0, 52.0)
    # file_name_6 = MAGEMinEnsemble.Output.generate_output_filename(variable_inputs_6, combination_6)
    # @test contains_string(file_name_6, ["bulk"])

    # # Test case 7: More than three oxides, other variable inputs, second combination.
    # variable_inputs_7 = OrderedDict(
    #     "P" => [0.5, 1.0],
    #     "SiO2" => [52.0, 53.0], "Al2O3" => [11.0, 12.0], "TiO2" => [1.0, 2.0], "FeO" => [9.0, 10.0]
    #     )
    # combination_7 = (0.5, 1.0, 11.0, 52.0, 9.0)
    # file_name_7 = MAGEMinEnsemble.Output.generate_output_filename(variable_inputs_7, combination_7)
    # @test contains_string(file_name_7, ["bulk", "P=0.5"])
end

@testset "setup_output_directory tests" begin

    # Test 1: output_dir is empty string, should default to current directory
    temp_dir = ""
    result_dir = MAGEMinEnsemble.Output.setup_output_directory(temp_dir)
    @test result_dir == pwd()  # Should be the current directory

    # Test 1: output_dir is nothing, should default to current directory
    temp_dir = nothing
    result_dir = MAGEMinEnsemble.Output.setup_output_directory(temp_dir)
    @test result_dir == pwd()  # Should be the current directory

    # Test 2: Directory does not exist, should create it
    temp_dir = mktempdir()  # Create temporary directory
    result_dir = MAGEMinEnsemble.Output.setup_output_directory(temp_dir)
    @test isdir(result_dir)  # Check if the directory was created
    @test result_dir == temp_dir  # Ensure the right directory is returned

    # Test 3: Directory exists but contains no .csv files, should just return the directory
    temp_dir = mktempdir()
    result_dir = MAGEMinEnsemble.Output.setup_output_directory(temp_dir)
    @test result_dir == temp_dir  # Should return the existing directory without prompting

    # Test 4: Directory exists and contains .csv files, should throw error
    temp_dir = mktempdir()
    touch(joinpath(temp_dir, "existing_file.csv"))  # Create a .csv file in the directory
    @test_throws ErrorException MAGEMinEnsemble.Output.setup_output_directory(temp_dir)

end