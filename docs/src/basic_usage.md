# Basic Usage

Simply, `MAGEMinEnsemble` provides an interface to define a parameter space over which many `MAGEMin` simulations can be performed. It does this using two ordered dictionaries: `constant_inputs` and `variable_inputs`. As their names suggest, the user uses `constant_inputs` to assign the intensive variables that do not change across the ensemble of simulations. `variable_inputs` is used to assign intensive variables that change across the ensemble.

Intensive variables are assigned using key-value pairs, where the key is always a string. `constant_inputs` contains values that are single floats or strings. `variable_inputs` contains values that are vectors of floats or strings. The same key cannot be assigned in both `constant_inputs` and `variable_inputs`: a parameter cannot be defined as both constant and variable in the same simulation.

The below example shows how the key and values of `constant_inputs` and `variable_inputs` can be assigned. These will define an ensemble of simulations over variable pressure, water and oxygen fugacity space. For a description of the available intensive variables, see section [Intensive Variables](@ref intensive_variables).

```Julia
# Assign a constant bulk composition and oxygen fugacity buffer
constant_inputs = OrderedDict{
    # Set bulk composition oxides
    "SiO2"  => 44.66,
    "TiO2"  =>  1.42,
    "Al2O3" => 15.90,
    "Cr2O3" =>  0.00,
    "FeO"   => 11.41,
    "Fe2O3" =>  6.00,
    "MgO"   =>  7.79,
    "CaO"   => 11.24,
    "Na2O"  =>  2.74,
    "K2O"   =>  0.22,

    # Set constant oxygen fugacity buffer
    "buffer" => "qfm"
}

# Assign variable pressure, oxygen fugacity buffer offset and water content
variable_inputs = OrderedDict{
    # Set variable pressure between 0.0 and 5.0 kbar in incremenets of 1.0
    "P" => collect(range(start=0.0, stop=5.0, step=1.0))

    # Set variable oxygen fugacity buffer offset from
    # QFM-2.0 to QFM+2.0 in increments of 1.0 log units
    "offset" => [-2.0, -1.0, 0.0, 1.0, 2.0]

    # Set variable water content from 0.0 to 8.0 wt%
    #in increments of 1.0
    "H2O" => collect(range(start=0.0, stop=8.0, step=1.0))
}

sys_in = "wt"  # Bulk composition defined in oxide wt%

# Set an initial temperature of 1400 celsius, final temperature
# of 800 celsius, and temperature step of -5 celsius.
T_array = collect(range(start=1400, stop=800, step=-5))

# Run the simulations, store result in variable Output
Output = GenerateEnsemble.run_simulations(
    T_array,
    constant_inputs,
    variable_inputs,
    sys_in
    )
```
The temperature is set outside of `constant_inputs` and `variable_inputs` and is defined as an array of temperatures. Currently only crystallisation simulations can be run in MAGEMinEnsemble, so the temperature array must be descending.

`sys_in = "wt"` tells `MAGEMinEnsemble` that the defined bulk composition is in oxide wt.%.

The `T_array`, `constant_inputs`, `variable_inputs`, and `sys_in` are passed to the `run_simulations()` function to generate and run the ensemble. The results will be saved as appropriately named .csv files (in this case "P=X_offset=Y_H2O=Z.csv, where X, Y and Z refer to the combination of values in `variable_inputs`), accompanied by metadata.txt files.To allow for further processing in Julia, the results are also stored in the variable `Output`.