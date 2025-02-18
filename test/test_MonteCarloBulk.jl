using Test
using Distributions

using MAGEMinEnsemble

# Test: Verify basic functionality with normal inputs
@testset "generate_bulk_mc basic tests" begin
    bulk = Dict("oxide1" => 10.0, "oxide2" => 20.0)  # Using String keys here
    abs_unc = Dict("oxide1" => 2.0, "oxide2" => 5.0)  # Same here
    n_samples = 1000

    bulk_mc = MAGEMinEnsemble.MonteCarloBulk.generate_bulk_mc(bulk, abs_unc, n_samples)

    # Check if the result is a dictionary with String keys and Vector{Float64} values
    @test typeof(bulk_mc) == Dict{String, Vector{Float64}}

    # Check that each key in the resulting dictionary has a value of type Vector{Float64}
    @test all(typeof(bulk_mc[key]) == Vector{Float64} for key in keys(bulk_mc))

    # Check if the number of samples for each oxide matches n_samples
    @test all(length(bulk_mc[key]) == n_samples for key in keys(bulk_mc))

    # Check if the generated values are within a reasonable range given the mean and uncertainty
    @test isapprox(mean(bulk_mc["oxide1"]), bulk["oxide1"], atol = 0.2)
    @test isapprox(mean(bulk_mc["oxide2"]), bulk["oxide2"], atol = 0.5)
end

# Test: Verify error is thrown when no matching uncertainty is found
@testset "generate_bulk_mc error handling tests" begin
    bulk = Dict("oxide1" => 10.0)
    abs_unc = Dict("oxide2" => 3.0)  # Note: no oxide1 in abs_unc
    n_samples = 1000

    # This should throw an error as no matching standard deviation is found
    @test_throws ErrorException MAGEMinEnsemble.MonteCarloBulk.generate_bulk_mc(bulk, abs_unc, n_samples)
end

# Test: Check if the function works with a single sample
@testset "generate_bulk_mc single sample test" begin
    bulk = Dict("oxide1" => 10.0)
    abs_unc = Dict("oxide1" => 1.0)
    n_samples = 1

    bulk_mc = MAGEMinEnsemble.MonteCarloBulk.generate_bulk_mc(bulk, abs_unc, n_samples)

    # Check if we got exactly 1 sample for oxide1
    @test length(bulk_mc["oxide1"]) == 1
end

# Test: Ensure the function works with both Dict and OrderedDict inputs
@testset "generate_bulk_mc with Dict and OrderedDict" begin
    # OrderedDict Test
    bulk_ordered = OrderedDict("SiO2" => 12.0, "Al2O3" => 15.0, "Fe2O3" => 20.0)
    abs_unc = Dict("SiO2" => 1.0, "Al2O3" => 1.5, "Fe2O3" => 2.0)
    n_samples = 5
    result_ordered = MAGEMinEnsemble.MonteCarloBulk.generate_bulk_mc(bulk_ordered, abs_unc, n_samples)

    @test typeof(result_ordered) == OrderedDict{String, Vector{Float64}}
    @test all(length(result_ordered[key]) == n_samples for key in keys(result_ordered))

    # Dict Test
    bulk_dict = Dict("SiO2" => 12.0, "Al2O3" => 15.0, "Fe2O3" => 20.0)
    result_dict = MAGEMinEnsemble.MonteCarloBulk.generate_bulk_mc(bulk_dict, abs_unc, n_samples)

    @test typeof(result_dict) == Dict{String, Vector{Float64}}
    @test all(length(result_dict[key]) == n_samples for key in keys(result_dict))
end

# Test: Ensure negative values are replaced by zero
@testset "generate_bulk_mc negative value replacement" begin
    bulk_with_negatives = Dict("SiO2" => 12.0, "Al2O3" => -5.0, "Fe2O3" => 20.0)
    abs_unc_neg = Dict("SiO2" => 1.0, "Al2O3" => 1.5, "Fe2O3" => 2.0)

    result_with_negatives = MAGEMinEnsemble.MonteCarloBulk.generate_bulk_mc(bulk_with_negatives, abs_unc_neg, 5)

    # Check that negative values were replaced by zero
    @test all(result_with_negatives["Al2O3"] .>= 0)
end

# Test: Ensure warning is printed only once
@testset "generate_bulk_mc warning handling" begin
    bulk_warn = Dict("SiO2" => -12.0, "Al2O3" => -5.0)
    abs_unc_warn = Dict("SiO2" => 1.0, "Al2O3" => 1.0)

    # Check if the warning message was logged
    @test_warn "Negative values replaced by zero." begin
        MAGEMinEnsemble.MonteCarloBulk.generate_bulk_mc(bulk_warn, abs_unc_warn, 5)
    end
end
