using Test
using OrderedCollections
using FileIO

include("../src/GenerateEnsemble.jl")
using .GenerateEnsemble

# @testset "update combined inputs" begin
#     all_inputs = Dict("input1" => 1, "input2" => 2)
#     variable_inputs = Dict("input1" => [10, 20], "input2" => [30, 40])
#     combination = (10, 30)  # This should update "input1" and "input2"

#     updated_inputs = GenerateEnsemble.update_all_inputs(all_inputs, variable_inputs, combination)

#     @test updated_inputs["input1"] == 30
#     @test updated_inputs["input2"] == 10
# end

# @testset "prepare bulk and oxides" begin
#     # Case 1: Only constant_inputs["bulk"] is provided
#     constant_inputs = Dict("bulk" => OrderedDict("SiO2" => 53.0, "Al2O3" => 12.0))
#     variable_inputs = Dict()

#     bulk_init, Xoxides = GenerateEnsemble.prepare_bulk_and_oxides(constant_inputs, variable_inputs)

#     # Expected output for constant inputs only
#     @test bulk_init == [53.0, 12.0]
#     @test Xoxides == ["SiO2", "Al2O3"]

#     # Case 2: Only variable_inputs["bulk"] is provided
#     constant_inputs = Dict()
#     variable_inputs = Dict("bulk" => OrderedDict("SiO2" => [52.0, 53.0], "Al2O3" => [11.0, 12.0]))

#     bulk_init, Xoxides = GenerateEnsemble.prepare_bulk_and_oxides(constant_inputs, variable_inputs)

#     # Expected output for variable inputs only
#     @test bulk_init == [[52.0, 11.0], [53.0, 12.0]]
#     @test Xoxides == ["SiO2", "Al2O3"]

#     # Case 3: Both constant_inputs["bulk"] and variable_inputs["bulk"] provided (non-matching oxides)
#     constant_inputs = Dict("bulk" => OrderedDict("SiO2" => 53.0))
#     variable_inputs = Dict("bulk" => OrderedDict("Al2O3" => [11.0, 12.0, 13.0]))

#     bulk_init, Xoxides = GenerateEnsemble.prepare_bulk_and_oxides(constant_inputs, variable_inputs)

#     # Expected output: Both oxides should be present
#     @test bulk_init == [[53.0, 11.0], [53.0, 12.0], [53.0, 13.0]]
#     @test Xoxides == ["SiO2", "Al2O3"]

# end

# @testset "check_number_variable_oxides tests" begin
#     # Test case 1: No oxides (empty "bulk")
#     variable_inputs_1 = Dict("bulk" => OrderedDict())
#     @test GenerateEnsemble.check_number_variable_oxides(variable_inputs_1) == false
#     @test_nowarn GenerateEnsemble.check_number_variable_oxides(variable_inputs_1)

#     # Test case 2: Fewer than 3 oxides
#     variable_inputs_2 = Dict("bulk" => OrderedDict("SiO2" => [52.0, 53.0], "Al2O3" => [11.0, 12.0]))
#     @test GenerateEnsemble.check_number_variable_oxides(variable_inputs_2) == false
#     @test_nowarn GenerateEnsemble.check_number_variable_oxides(variable_inputs_2)

#     # Test case 3: Exactly 3 oxides
#     variable_inputs_3 = Dict("bulk" => OrderedDict("SiO2" => [52.0, 53.0], "Al2O3" => [11.0, 12.0], "TiO2" => [1.0, 2.0]))
#     @test GenerateEnsemble.check_number_variable_oxides(variable_inputs_3) == false
#     @test_nowarn GenerateEnsemble.check_number_variable_oxides(variable_inputs_3)

#     # Test case 4: More than 3 oxides (this should trigger a warning and return true)
#     variable_inputs_4 = Dict("bulk" => OrderedDict("SiO2" => [52.0], "Al2O3" => [11.0], "TiO2" => [1.0], "FeO" => [8.0]))
#     multi_var_oxides_flag = GenerateEnsemble.check_number_variable_oxides(variable_inputs_4)
#     @test multi_var_oxides_flag == true
#     @test_warn "You have provided more than 3 variable oxides" GenerateEnsemble.check_number_variable_oxides(variable_inputs_4)

#     # Test case 5: More than 3 oxides but with different keys for other parameters
#     variable_inputs_5 = Dict("P" => [0.0, 1.0], "bulk" => OrderedDict("SiO2" => [52.0], "Al2O3" => [11.0], "TiO2" => [1.0], "FeO" => [8.0]))
#     multi_var_oxides_flag_5 = GenerateEnsemble.check_number_variable_oxides(variable_inputs_5)
#     @test multi_var_oxides_flag_5 == true
#     @test_warn "You have provided more than 3 variable oxides" GenerateEnsemble.check_number_variable_oxides(variable_inputs_5)
# end

@testset "extract_variable_bulk_oxides" begin
    # Test 1: Case where "bulk" is present and has keys
    input_1 = Dict("bulk" => Dict("oxide1" => 10., "oxide2" => 20.), "other_key" => 5.)
    expected_1 = Dict("oxide1" => 10., "oxide2" => 20., "other_key" => 5.)
    result_1 = GenerateEnsemble.extract_variable_bulk_oxides(input_1)
    @test result_1 == expected_1

    # Test 2: Case where "bulk" is not present
    input_2 = Dict("oxide1" => 30, "oxide2" => 40)
    expected_2 = Dict("oxide1" => 30, "oxide2" => 40)
    result_2 = GenerateEnsemble.extract_variable_bulk_oxides(input_2)
    @test result_2 == expected_2

    # Test 3: Case where "bulk" exists but is empty
    input_3 = Dict("bulk" => Dict(), "other_key" => 10)
    expected_3 = Dict("other_key" => 10)
    result_3 = GenerateEnsemble.extract_variable_bulk_oxides(input_3)
    @test result_3 == expected_3
end

@testset "generate_output_filename" begin

    # Test case 1: No variable bulk composition
    variable_inputs_1 = Dict("P" => [0.0, 1.0])
    combination_1 = [0.0]
    @test GenerateEnsemble.generate_output_filename(variable_inputs_1, combination_1) == "P=0.0"

    # Test case 1: Single bulk composition with no other variables
    variable_inputs_2 = Dict(
        "P" => [0.0, 1.0],
        "bulk" => OrderedDict("SiO2" => [52.0, 53.0])
    )
    combination_2 = [0.0, 52.0]

   @test GenerateEnsemble.generate_output_filename(variable_inputs_2, combination_2) == "SiO2=52.0_P=0.0"

    # # Test case 2: Single bulk composition with multiple other variables
    # variable_inputs_2 = Dict(
    #     "P" => [0.0, 1.0],
    #     "offset" => [0.5, 1.0],
    #     "bulk" => OrderedDict("SiO2" => [52.0])
    # )
    # combination_2 = [0.0, 0.5]

    # @test GenerateEnsemble.generate_output_filename(variable_inputs_2, combination_2) == "SiO2=52.0_P=0.0_offset=0.5"

    # # Test case 3: Multiple bulk compositions, more than 3 oxides
    # variable_inputs_3 = Dict(
    #     "P" => [0.0, 1.0],
    #     "offset" => [0.5, 1.0],
    #     "bulk" => OrderedDict("SiO2" => [52.0, 53.0], "Al2O3" => [11.0, 12.0], "TiO2" => [1.0, 2.0], "FeO" => [8.0, 9.0])
    # )
    # combination_3 = [0.0, 0.5]

    # @test GenerateEnsemble.generate_output_filename(variable_inputs_3, combination_3) == "bulk1_P=0.0_offset=0.5"

    # # Test case 4: Multiple bulk compositions without exceeding 3 oxides
    # variable_inputs_4 = Dict(
    #     "P" => [0.0],
    #     "offset" => [0.5],
    #     "bulk" => OrderedDict("SiO2" => [52.0], "Al2O3" => [11.0], "TiO2" => [1.0])
    # )
    # combination_4 = [0.0]

    # @test GenerateEnsemble.generate_output_filename(variable_inputs_4, combination_4) == "SiO2=52.0_Al2O3=11.0_TiO2=1.0_P=0.0_offset=0.5"

    # # Test case 5: Only variable inputs with multiple oxides
    # variable_inputs_5 = Dict(
    #     "P" => [0.0],
    #     "offset" => [0.5],
    #     "bulk" => OrderedDict("SiO2" => [52.0, 53.0], "Al2O3" => [11.0, 12.0], "TiO2" => [1.0, 2.0])
    # )
    # combination_5 = [0.0]

    # @test GenerateEnsemble.generate_output_filename(variable_inputs_5, combination_5) == "bulk1_P=0.0_offset=0.5"

    # # Test case 6: Another combination with multiple oxides
    # combination_6 = [1.0]
    # @test GenerateEnsemble.generate_output_filename(variable_inputs_5, combination_6) == "bulk1_P=1.0_offset=0.5"
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
