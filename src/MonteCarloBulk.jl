module MonteCarloBulk

using Distributions
using OrderedCollections

"""
    generate_bulk_mc(bulk, abs_unc, n_samples)

Randomly sample normal distributions for each oxide defined by a bulk composition and its absolute uncertainty, n_samples times.

## Inputs
- `bulk` (AbstractDict{String, Float64}): Bulk composition with keys as oxide strings, e.g. SiO2.
- `abs_unc` (AbstractDict{String, Float64}): Absolute uncertainties with keys that correspond to those in bulk.
- `n_samples` (Int): number of times to sample normal distributions.

## Outputs
- `bulk_mc` (AbstractDict{String, Vector{Float64}}): Randomly sampled bulk composition.
"""
function generate_bulk_mc(bulk::AbstractDict{String, Float64}, abs_unc::AbstractDict{String, Float64}, n_samples::Int) :: AbstractDict{String, Vector{Float64}}
    # Ensure output matches input types
    if isa(bulk, OrderedDict)
        bulk_mc = OrderedDict{String, Vector{Float64}}()
    else
        bulk_mc = Dict{String, Vector{Float64}}()
    end
    warning_raised = false  # Flag to ensure warning is only raised once

    # Iterate over each oxide in the bulk dictionary
    for (oxide, value) in bulk
        # Ensure the oxide exists in the abs_unc dictionary
        if haskey(abs_unc, oxide)
            uncertainty = abs_unc[oxide]
            # Generate n_samples random samples for this oxide using a normal distribution
            samples = rand(Normal(value, uncertainty), n_samples)

            # Raise a warning once if any negative values were replaced
            if any(samples .< 0.) && !warning_raised
                @warn "Negative values replaced by zero."
                warning_raised = true
            end

            samples[samples .< 0.] .= 0.0
            bulk_mc[string(oxide)] = samples
        else
            # If no matching abs_unc value is found for this oxide, throw error
            error("No matching uncertainty for oxide: $oxide")
        end
    end

    return bulk_mc
end

end
