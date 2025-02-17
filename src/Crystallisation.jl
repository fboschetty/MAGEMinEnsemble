
module Crystallisation

using MAGEMin_C
using OrderedCollections
using IterTools

export fractional_crystallisation, bulk_crystallisation

"""
    Out = fractional_crystallisation(T_array, P, bulk_init, database, oxides, max_steps, sys_in)

Perform a fractional crystallisation simulation using MAGEMin at constant intensive variables e.g., pressure, oxygen fugacity.

## Inputs
- `T_array` (Vector{Float64}): Temperatures in degrees Celsius.
- `P` (Float64): Pressure in kbar.
- `bulk_init` (Vector{Float64}): Initial bulk composition.
- `database`: MAGEMin database for simulations. For example, "ig" is the igneous database of Holland et al., 2018.
- `oxides` (Vector{String}): Oxides that correspond to values in the bulk composition. See MAGEMin documentation for accepted oxides.
- `sys_in` (String): Unit for initial bulk composition, can be "wt" or "mol", for wt(defaults to "wt")

## Outputs
- `Out` (Vector{MAGEMin_C.gmin_struct{Float64, Int64}}): array of simulation outputs for each temperature step.
"""
function fractional_crystallisation(T_array::Vector{Float64}, P::Float64, bulk_init::Vector{Float64}, database, oxides::Vector{String}, sys_in::String, offset::Union{Float64, Nothing}) :: Array{MAGEMin_C.gmin_struct{Float64, Int64}, 1}
    P_array = fill(P, length(T_array))
    melt_fraction = 1.0
    bulk = deepcopy(bulk_init)
    max_T_steps = length(T_array)
    current_T_step = 1

    output = Vector{MAGEMin_C.gmin_struct{Float64, Int64}}(undef, max_T_steps)

    while melt_fraction > 0.0 && current_T_step <= max_T_steps
        if offset === nothing
            out = single_point_minimization(
                P_array[current_T_step],
                T_array[current_T_step],
                database,
                X=bulk,
                Xoxides=oxides,
                sys_in=sys_in,
                )
        else

            out = single_point_minimization(
                P_array[current_T_step],
                T_array[current_T_step],
                database,
                X=bulk,
                Xoxides=oxides,
                sys_in=sys_in,
                B=offset
                )
        end

        # Write T_step to output
        output[current_T_step] = deepcopy(out)

        # Retrieve melt composition for next iteration
        melt_fraction = out.frac_M
        bulk .= out.bulk_M
        current_T_step += 1

    end

    return output[1:current_T_step-1]  # Return only defined indices
end


"""
    Out = bulk_crystallisation(T_array, P, bulk_init, database, oxides, max_steps, sys_in)

    Perform a bulk crystallisation simulation using MAGEMin at constant intensive variables e.g., pressure, oxygen fugacity.

## Inputs
- `T_array` (Vector{Float64}): Temperatures in degrees Celsius.
- `P` (Float64): Pressure in kbar.
- `bulk_init` (Vector{Float64}): Initial bulk composition.
- `database`: MAGEMin database for simulations. For example, "ig" is the igneous database of Holland et al., 2018.
- `oxides` (Vector{String}): Oxides that correspond to values in the bulk composition. See MAGEMin documentation for accepted oxides.
- `sys_in` (String): Unit for initial bulk composition, can be "wt" or "mol", for wt(defaults to "wt")

## Outputs
- `Out` (Vector{MAGEMin_C.gmin_struct{Float64, Int64}}): array of simulation outputs for each temperature step.
"""
function bulk_crystallisation(T_array::Vector{Float64}, P::Float64, bulk_init::Vector{Float64}, database, oxides::Vector{String}, sys_in::String, offset::Union{Float64, Nothing}) :: Array{MAGEMin_C.gmin_struct{Float64, Int64}, 1}
    P_array = fill(P, length(T_array))
    melt_fraction = 1.0
    bulk = deepcopy(bulk_init)
    max_T_steps = length(T_array)
    current_T_step = 1

    output = Vector{MAGEMin_C.gmin_struct{Float64, Int64}}(undef, max_T_steps)

    while melt_fraction > 0.0 && current_T_step <= max_T_steps
        if offset === nothing
            out = single_point_minimization(
                P_array[current_T_step],
                T_array[current_T_step],
                database,
                X=bulk,
                Xoxides=oxides,
                sys_in=sys_in,
                )
        else

            out = single_point_minimization(
                P_array[current_T_step],
                T_array[current_T_step],
                database,
                X=bulk,
                Xoxides=oxides,
                sys_in=sys_in,
                B=offset
                )
        end

        # Write T_step to output
        output[current_T_step] = deepcopy(out)

        # Retrieve melt composition for next iteration
        melt_fraction = out.frac_M
        current_T_step += 1

    end

    return output[1:current_T_step-1]  # Return only defined indices
end

end