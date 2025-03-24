using Test
using OrderedCollections
using FileIO

using MAGEMinEnsemble


@testset "get_bulk_oxides" begin
    # Test case 1: all_inputs contains oxides only from accepted_oxides
    all_inputs = OrderedDict("SiO2" => 10.0, "FeO" => 5.0, "MgO" => 8.0, "O" => 3.0)
    bulk_init, Xoxides = MAGEMinEnsemble.GenerateEnsemble.get_bulk_oxides(all_inputs)
    @test Xoxides == ["SiO2", "FeO", "MgO", "O"]
    @test bulk_init == [10.0, 5.0, 8.0, 3.0]
end

@testset "create_T_array" begin
    # Test case 1: Normal increasing range
    inputs = OrderedDict("T_start" => 0.0, "T_stop" => 10.0, "T_step" => 2.0)
    @test MAGEMinEnsemble.GenerateEnsemble.create_T_array(inputs) == [0.0, 2.0, 4.0, 6.0, 8.0, 10.0]

    # Test case 2: Normal decreasing range
    inputs = OrderedDict("T_start" => 10.0, "T_stop" => 0.0, "T_step" => 2.0)
    @test MAGEMinEnsemble.GenerateEnsemble.create_T_array(inputs) == [10.0, 8.0, 6.0, 4.0, 2.0, 0.0]

    # Test case 3: Single element range
    inputs = OrderedDict("T_start" => 5.0, "T_stop" => 5.0, "T_step" => 1.0)
    @test MAGEMinEnsemble.GenerateEnsemble.create_T_array(inputs) == [5.0]

    # Test case 4: Step size is negative but should still work
    inputs = OrderedDict("T_start" => 10.0, "T_stop" => 0.0, "T_step" => -2.0)
    @test MAGEMinEnsemble.GenerateEnsemble.create_T_array(inputs) == [10.0, 8.0, 6.0, 4.0, 2.0, 0.0]

    # Test case 5: Error when step size is zero
    inputs = OrderedDict("T_start" => 0.0, "T_stop" => 10.0, "T_step" => 0.0)
    @test_throws ErrorException("The temperature step cannot be zero.") MAGEMinEnsemble.GenerateEnsemble.create_T_array(inputs)
end

@testset "initialize_database" begin
    # Test 1: When "buffer" is provided
    all_inputs_with_buffer = OrderedDict("buffer" => "QFM", "offset" => 0.2)
    db, offset, exclude_O = MAGEMinEnsemble.GenerateEnsemble.initialize_database("ig", all_inputs_with_buffer)

    @test offset == 0.2
    @test exclude_O == true

    # Test 2: When "buffer" is NOT provided
    all_inputs_no_buffer = OrderedDict()
    db, offset, exclude_O = MAGEMinEnsemble.GenerateEnsemble.initialize_database("ig", all_inputs_no_buffer)

    @test offset == 0.0
    @test exclude_O == false

    # Test 3: When "buffer" is present but "offset" is missing
    all_inputs_buffer_only = OrderedDict("buffer" => "IW")
    db, offset, exclude_O = MAGEMinEnsemble.GenerateEnsemble.initialize_database("ig", all_inputs_buffer_only)

    @test offset == 0.0  # Default offset
    @test exclude_O == true
end

@testset "convert_bulk_composition" begin
    # Test 1: Oxygen is excluded (exclude_oxygen = true)
    bulk_init = [40.0, 30.0, 20.0, 10.0]  # Example composition
    Xoxides = ["SiO2", "TiO2", "Al2O3", "O"]  # Example oxides
    sys_in = "wt"
    td_database = "ig"

    bulk_converted, Xoxides_converted, sys_in_updated = MAGEMinEnsemble.GenerateEnsemble.convert_bulk_composition(bulk_init, Xoxides, sys_in, td_database, true)

    @test isapprox(bulk_converted, [53.7789, 15.8446, 0.00999600, 0.00999600, 0.00999600, 0.0, 0.00999600, 30.3365, 0.62500, 0.0, 0.0], atol=0.001)
    @test Xoxides_converted == ["SiO2", "Al2O3", "CaO", "MgO", "FeO", "K2O", "Na2O", "TiO2", "O", "Cr2O3", "H2O"]
    @test sys_in_updated == "mol"

    # Test 2: Oxygen is not excluded (exclude_oxygen = false)
    bulk_converted, Xoxides_converted, sys_in_updated = MAGEMinEnsemble.GenerateEnsemble.convert_bulk_composition(bulk_init, Xoxides, sys_in, td_database, false)

    @test isapprox(bulk_converted, [35.7323, 10.5276, 0.00999600, 0.00999600, 0.00999600, 0.0, 0.00999600, 20.1564, 33.5437, 0.0, 0.0], atol=0.001)
    @test Xoxides_converted == ["SiO2", "Al2O3", "CaO", "MgO", "FeO", "K2O", "Na2O", "TiO2", "O", "Cr2O3", "H2O"]
    @test sys_in_updated == "mol"

    # Test 3: Oxygen is present but with modified composition (to verify oxygen restoration)
    bulk_init_with_oxygen = [40.0, 30.0, 20.0, 15.0]  # Oxygen mass is 15.0
    Xoxides_with_oxygen = ["SiO2", "TiO2", "Al2O3", "O"]

    bulk_converted, Xoxides_converted, sys_in_updated = MAGEMinEnsemble.GenerateEnsemble.convert_bulk_composition(bulk_init_with_oxygen, Xoxides_with_oxygen, sys_in, td_database, true)

    @test isapprox(bulk_converted, [53.7789, 15.8446, 0.00999600, 0.00999600, 0.00999600, 0.0, 0.00999600, 30.3365, 0.93751, 0.0, 0.0], atol=0.001)
    @test Xoxides_converted == ["SiO2", "Al2O3", "CaO", "MgO", "FeO", "K2O", "Na2O", "TiO2", "O", "Cr2O3", "H2O"]
    @test sys_in_updated == "mol"  # sys_in should be updated to "mol" after oxygen is excluded and restored

    # Test 4: No oxygen present in the input (nothing should change)
    bulk_init_without_oxygen = [40.0, 30.0, 20.0]  # No oxygen in bulk
    Xoxides_without_oxygen = ["SiO2", "TiO2", "Al2O3"]

    bulk_converted, Xoxides_converted, sys_in_updated = MAGEMinEnsemble.GenerateEnsemble.convert_bulk_composition(bulk_init_without_oxygen, Xoxides_without_oxygen, sys_in, td_database, false)

    @test isapprox(bulk_converted, [53.7789, 15.8446, 0.00999600, 0.00999600, 0.00999600, 0.0, 0.00999600, 30.3364, 0.0, 0.0, 0.0], atol=0.001)
    @test Xoxides_converted == ["SiO2", "Al2O3", "CaO", "MgO", "FeO", "K2O", "Na2O", "TiO2", "O", "Cr2O3", "H2O"]
    @test sys_in_updated == "mol"
end
