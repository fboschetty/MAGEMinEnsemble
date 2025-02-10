module MonteCarloBulk

using Distributions

# Define the function to generate bulk_mc
function generate_bulk_mc(bulk::Dict{String, Float64}, abs_unc::Dict{String, Float64}, n_samples::Int) :: Dict{String, Vector{Float64}}
    # Ensure the type is Dict{Symbol, Vector{Float64}} regardless of input dictionary types
    bulk_mc = Dict{String, Vector{Float64}}()

    # Iterate over each oxide in the bulk dictionary
    for (oxide, value) in bulk
        # Ensure the oxide exists in the abs_unc dictionary
        if haskey(abs_unc, oxide)
            uncertainty = abs_unc[oxide]

            # Generate n_samples random samples for this oxide using a normal distribution
            bulk_mc[string(oxide)] = rand(Normal(value, uncertainty), n_samples)
        else
            # If no matching abs_unc value is found for this oxide, throw error
            error("No matching standard deviation for oxide: $oxide")
        end
    end

    return bulk_mc
end

end
