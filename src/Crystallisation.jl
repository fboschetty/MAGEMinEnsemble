
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
- `database`: MAGEMin database for simulations.
- `oxides` (Vector{String}): Oxides that correspond to values in the bulk composition. See MAGEMin documentation for accepted oxides.
- `sys_in` (String): Unit for initial bulk composition, can be "wt" or "mol" (defaults to "wt").
- `offset` (Float64): buffer offset.

## Outputs
- `Out` (Vector{MAGEMin_C.gmin_struct{Float64, Int64}}): array of simulation outputs for each temperature step.
"""
function fractional_crystallisation(T_array::Vector{Float64}, P::Float64, bulk_init::Vector{Float64}, database, oxides::Vector{String}, sys_in::String, offset::Float64) :: Array{MAGEMin_C.gmin_struct{Float64, Int64}, 1}
    P_array = fill(P, length(T_array))
    bulk = deepcopy(bulk_init)
    max_T_steps = length(T_array)
    melt_fraction = 1.0
    output = Vector{MAGEMin_C.gmin_struct{Float64, Int64}}(undef, max_T_steps)

    id_O = findfirst(oxides .== "O")

    while melt_fraction > 0.0 && current_T_step <= max_T_steps
        output[i] = deepcopy(single_point_minimization(
            P_array[current_T_step],
            T_array[current_T_step],
            database,
            X=bulk,
            Xoxides=oxides,
            sys_in=sys_in,
            B=offset
            ))

        # If the liquid phase is present, the bulk composition is updated
        if "liq" in output[current_T_step].ph
            bulk = deepcopy(output[current_T_step].bulk_M)
            bulk[id_O] = bulk_init[id_O]  # Ensure sufficient O to saturate buffer.
        else
            break
        end

        melt_fraction = deepcopy(output[current_T_step].frac_M)
        current_T_step += 1

    end

    Finalize_MAGEMin(database)

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
- `sys_in` (String): Unit for initial bulk composition, can be "wt" or "mol" (defaults to "wt")
- `offset` (Float64): buffer offset.

## Outputs
- `Out` (Vector{MAGEMin_C.gmin_struct{Float64, Int64}}): array of simulation outputs for each temperature step.
"""
function bulk_crystallisation(T_array::Vector{Float64}, P::Float64, bulk_init::Vector{Float64}, database, oxides::Vector{String}, sys_in::String, offset::Float64) :: Array{MAGEMin_C.gmin_struct{Float64, Int64}, 1}
    P_array = fill(P, length(T_array))
    melt_fraction = 1.0
    bulk = deepcopy(bulk_init)
    max_T_steps = length(T_array)
    current_T_step = 1

    output = Vector{MAGEMin_C.gmin_struct{Float64, Int64}}(undef, max_T_steps)

    while melt_fraction > 0.0 && current_T_step <= max_T_steps
        output[current_T_step] = deepcopy(single_point_minimization(
            P_array[current_T_step],
            T_array[current_T_step],
            database,
            X=bulk,
            Xoxides=oxides,
            sys_in=sys_in,
            B=offset
            ))

        melt_fraction = deepcopy(output[current_T_step].frac_M)
        current_T_step += 1

    end

    Finalize_MAGEMin(database)

    return output[1:current_T_step-1]  # Return only defined indices
end

end