
module FractionalCrystallisation

using MAGEMin_C
using OrderedCollections
using IterTools

# Main fractional crystallisation function
"""
    fractional_crystallisation(T, P, bulk_init, database, oxides, max_steps, sys_in) -> Out

Perform a fractional crystallisation simulation using MAGEMin at constant intensive variables e.g., pressure, oxygen fugacity.

Inputs
    - T (Vector{Float64}): Temperatures in degrees Celsius.
    - P (Float64): Pressure in kbar.
    - bulk_init (Vector{Float64}): Initial bulk composition.
    - database: MAGEMin database for simulations. For example, "ig" is the igneous database of Holland et al., 2018.
    - oxides (Vector{String}): Oxides that correspond to values in the bulk composition. See MAGEMin documentation for accepted oxides.
    - max_steps (Int): The maximum number of simulations to perform. Usually determined by number of temperature steps.
    - sys_in (String): Unit for initial bulk composition, can be "wt" or "mol", for wt(defaults to "wt")

Outputs
    - Out (Vector{MAGEMin_C.gmin_struct{Float64, Int64}}): array of simulation outputs for each temperature step.
"""
function fractional_crystallisation(T_array, P, bulk_init, database, oxides, max_steps, sys_in, fo2_offset)
    P_array = fill(P, length(T_array))
    melt_fraction = 1.0
    bulk = deepcopy(bulk_init)
    temperature_step = 1

    output = Vector{MAGEMin_C.gmin_struct{Float64, Int64}}(undef, max_steps)

    while melt_fraction > 0.0 && temperature_step <= max_steps
        # Run the minimization for the current step
        out = single_point_minimization(
            P_array[temperature_step],
            T_array[temperature_step],
            database,
            X=bulk,
            Xoxides=oxides,
            sys_in=sys_in,
            B=fo2_offset
            )
        output[temperature_step] = deepcopy(out)

        # Retrieve melt composition for next iteration
        melt_fraction = out.frac_M
        bulk .= out.bulk_M
        temperature_step += 1
    end

    return output[1:temperature_step-1]  # Return only defined indices
end

export fractional_crystallisation

end  # End of module