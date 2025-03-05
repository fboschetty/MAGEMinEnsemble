# Monte Carlo Bulk Composition

## Introduction

Monte Carlo simulations are a method used to model the effects of uncertainty by running many simulations with random variations in input parameters. Each simulation is based on a random set of values drawn from a defined range or distribution of possible inputs, representing the uncertainty or variability in those parameters.

In the context of varying a bulk composition within its analytical uncertainty, Monte Carlo simulations allow you to:

1. Randomly adjust the bulk composition within the range of its analytical uncertainty.
2. Run multiple simulations to see how these variations affect the results or outcomes.
3. Analyse the spread of results to understand the potential impact of the analytical uncertainty on your final conclusions.

## Implementing with MAGEMinEnsemble

 MAGEMinEnsemble has a function specially designed for this. The function `generate_bulk_mc` accepts two dictionaries, one defining a bulk composition as above (`"bulk"`), and a second containing corresponding absolute uncertainties (`"abs_unc"`). It produces a vector `n_samples` long for each oxide where each value is randomly sampled from a normal distribution defined by the measured value and its analytical uncertainty.

```Julia
bulk = OrderedDict(
    "SiO2"  => 44.66,
    "TiO2"  =>  1.42,
    "Al2O3" => 15.90,
    "Cr2O3" =>  0.00,
    "FeO"   => 11.41,
    "MgO"   =>  7.79,
    "CaO"   => 11.24,
    "Na2O"  =>  2.74,
    "K2O"   =>  0.22,
    "O"     =>  4.00,
    "H2O"   =>  0.00
)

abs_unc = OrderedDict(
    "SiO2"  => 2.333,
    "TiO2"  => 0.142,
    "Al2O3" => 0.795,
    "Cr2O3" => 0.0,
    "FeO"   => 0.571,
    "MgO"   => 0.390,
    "CaO"   => 0.562,
    "Na2O"  => 0.137,
    "K2O"   => 0.022,
    "O"     => 0.0,
    "H2O"   => 0.0
)

n_samples = 5

bulk_mc = MonteCarloBulk.generate_bulk_mc(bulk, abs_unc, n_samples)
```

Each oxide in `bulk_mc` is then a vector containing 5 floats. Those values with an uncertainty of 0.0 are simply copied `n_samples` times.
The function automatically replaces any negative values produced by the sampling by 0.0. The resulting dictionary can be input as a `variable_input` to assess how the analytical uncertainty impacts the fractional crystallisation simulations.

The function `run_simulations_mc()` accounts for the randomly sampled bulk composition inside the `"bulk_mc"` ordered dictionary, and saves the outputs to .csv files as normal. They are named bulk=X.csv where X is the index of each provided bulk composition. For example, if 50 sampled bulk compositions are input, the file names will be bulk=01.csv, bulk=02.csv, ..., bulk=50.csv.

```Julia
constant_inputs = OrderedDict(
    # Set the initial, final and incremental
    # temperature in degrees celsius
    "T_start" => 1400.,
    "T_stop" => 800.,
    "T_step" => -1.,

    # Set the pressure to 1 kbar
    "P" => 1.0,

    # Set the oxygen fugacity buffer to QFM
    "buffer" => "qfm"
)

variable_inputs = OrderedDict(
    # Input the randomly sampled bulk composition
    "bulk_mc" => bulk_mc
)

# Use the run_simulations_mc function to model the randomly
# sampled bulk compositions
Output = MAGEMinEnsemble.MonteCarloBulk.run_simulations_mc(
    constant_inputs,
    variable_inputs,
    "bulk"
    )
```

Additional `variable_inputs` keys may also be provided e.g., variable pressure. In which case the format output file names will be P=Y_bulk=X.csv.

!!! note
    Bear in mind that providing many bulk compositions and other `variable_inputs` keys may result in a very large number of total simulations.
