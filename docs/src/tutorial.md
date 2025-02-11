# Tutorial

The goals of this tutorial are as follows:
1. Provide a brief introduction to MAGEMin, and
2. Demonstrate the key functionality of FCEnsemble and provide simple examples of its usage.

## Mineral Assemblage Gibbs Energy Minimization (MAGEMin)
`MAGEMin` is a parallel C library that finds the thermodynamically most stable assemblage for a given bulk rock composition and intensive variables e.g., temperature and pressure. It utilises modern minimisation techniques and optimised for multi-core processors meaning it is both stable and fast.

It utilises existing thermodynamic databases allowing it to perform calculations across a broad compositional and intensive variable space. See the [MAGEMin Github](https://github.com/ComputationalThermodynamics/MAGEMin) and [companion paper](https://doi.org/10.1029/2022GC010427) for further details.

`MAGEMin_C` is a Julia wrapper for `MAGEMin` and provides a more user-friendly interface for performing simulations using `MAGEMin`, and is utilised by FCEnsemble for performing many fractional-crystallisation simulations.

## Single Calculations

Performing single calculations using MAGEMin_C is straightforward with some experience of the programming language Julia. The below snippet shows how to find the stable assemblage for a basaltic composition at 1200$\text{\textdegree}$C and 1kbar.

```Julia
using MAGEMin_C

db = "ig"  # database: ig, igneous (Holland et al., 2018)
database = Initialize_MAGEMin(db, verbose=true);
data = use_predefined_bulk_rock(database, 0);  # KLB1
P = 1.0;  # pressure in kbar
T = 1200.0;  # temperature in celsius

out  = point_wise_minimization(P, T, database);
```

## Multiple Calculations

Again, setting up and performing multiple calculations is straightforward. The function `multi_point_minimization` is written to perform simulations in parallel

```Julia
using MAGEMin_C

db = "ig"  # database: ig, igneous (Holland et al., 2018)
database = Initialize_MAGEMin(db, verbose=false);
n_points = 1000
P = rand(8.0:40, n);  # 1000 pressures between 8 and 40 kbar
T = rand(800.0:2000.0, n);  # 1000 temperatures between 800 and 2000 celsius
out  = multi_point_minimization(P, T, database, test=0);  # KLB1
Finalize_MAGEMin(data)

```

## Many (Many) Calculations

Performing many (1,000s) of simulations across a varied intensive parameter space is less straightforward. Moreover, fractional crystallisation simulations require that the melt at each temperature state is used for subsequent, down-temperature, steps. Therefore each temperature step cannot be performed in parallel. Finally, storing the output of these many simulations allowing them to be subsequently explored is non-trivial.

FCEnsemble provides a simple means to define a intensive variable space over which to perform a series of fractional crystallisation experiments. The user defines a temperature array (`T_array`); `constant_inputs`, intensive variables that are the same across the defined parameter space; and `variable_inputs`, those that define the extent of the parameter extent.

```Julia
using MAGEMin_C
using OrderedCollections
using GenerateEnsemble

# Descending temperature array [celsius]
T_array = collect(range(start=1400., stop=800., step=-2))

constant_inputs = Dict()
# Initial bulk composition [oxide wt%]
constant_inputs["bulk"] = OrderedDict(
    "SiO2" => 38.4,
    "TiO2" => 0.7,
    "Al2O3" => 7.7,
    "Cr2O3" => 0.0,
    "FeO" => 5.98,
    "MgO" => 9.95,
    "CaO" => 8.25,
    "Na2O" => 2.26,
    "K2O" => 0.24,
    "O" => 4.0,
    "H2O" => 12.7,
)

variable_inputs = Dict()
# Variable pressure [kbar]
variable_inputs["P"] = collect(range(start=0.0, stop=2.0, step=0.5))

sys_in = "wt"  # Bulk composition defined in oxide wt%
```

The above snippet is the setup to perform five fractional crystallisation simulations. The stable thermodynamic assemblage will be calculated between 1400 and 800 $\text{\textdegree}$C in 2 degree temperature steps. Note that the actual lowest temperature in the simulations will be the solidus. A constant initial bulk composition is provided in wt% oxide. Five pressures are defined as a variable input between 0 and 2 kbar in steps of 0.5 kbar.

These fractional crystallisation experiments are then performed as follows.
```Julia
Output = GenerateEnsemble.run_simulations(T_array, constant_inputs, variable_inputs, sys_in)
```
Five .csv files (and accompanying metadata.txt files), one for each variable_input combination, will be produced in the current directory containing the most thermodynamically stable phase assemblage at each temperature step. They will have simple names: P=0.0.csv, P=0.5.csv etc.

## A More Complex Example

The above example illustrates how the definition of constant and variable input dictionaries defines the parameter space over which the simulations are performed. Let's add an additional variable_input, oxygen fugacity buffer offset.

```Julia
using MAGEMin_C
using OrderedCollections
using GenerateEnsemble

# Descending temperature array [celsius]
T_array = collect(range(start=1400., stop=800., step=-2))

constant_inputs = Dict()
# Oxygen fugacity buffer set to Quartz-Fayalite-Magnetite (QFM) buffer
constant_inputs["buffer"] = "qfm"
# Initial bulk composition [oxide wt%]
constant_inputs["bulk"] = OrderedDict(
    "SiO2" => 38.4,
    "TiO2" => 0.7,
    "Al2O3" => 7.7,
    "Cr2O3" => 0.0,
    "FeO" => 5.98,
    "MgO" => 9.95,
    "CaO" => 8.25,
    "Na2O" => 2.26,
    "K2O" => 0.24,
    "O" => 4.0,
    "H2O" => 12.7,
)

variable_inputs = Dict()
# Variable pressure [kbar]
variable_inputs["P"] = collect(range(start=0.0, stop=2.0, step=0.5))
# Variable buffer offset [log units]
variable_inputs["buffer_offset"] = collect(range(start=-2., stop=2., step=1.))

sys_in = "wt"  # Bulk composition defined in oxide wt%

Output = GenerateEnsemble.run_simulations(T_array, constant_inputs, variable_inputs, sys_in)
```

This time the snippet will run a fractional crystallisation simulation for each pressure-offset pair. There are five pressures (0-2 kbar in 0.5 kbar increments) and five buffer offsets (QFM -2 to +2 in 1 log unit increments), giving a total of 25 simulations. The output of each simulation is again saved as a .csv file. This time they will be called P=0.0_buffer_offset=-2.0.csv, P=0.0_buffer_offset=-1.0.csv... P=2.0_buffer_offset=2.csv, making the intensive variables straightforward to identify.

This shows how by simply defining an additional variable_input parameter a broad range of fractional simulations can be performed.

## Variable Bulk Composition
A variable bulk composition can be defined in multiple ways. First a single oxide can be defined as a vector. Here the constant oxides in the bulk composition are defined in the `constant_inputs["bulk"]` dictionary and the changing oxide is defined in the `variable_inputs["bulk"]` dictionary.

```Julia
constant_inputs = Dict()
constant_inputs["bulk"] = OrderedDict(
    "SiO2" => 38.4,
    "TiO2" => 0.7,
    "Al2O3" => 7.7,
    "Cr2O3" => 0.0,
    "FeO" => 5.98,
    "MgO" => 9.95,
    "CaO" => 8.25,
    "Na2O" => 2.26,
    "K2O" => 0.24,
    "O" => 4.0,
    # "H2O" => 12.7,
)

variable_inputs = Dict()
variable_inputs["bulk"] = OrderedDict(
    "H2O" => collect(range(start=0.0, stop=6.0, step=1.0))
)
```

!!! note
    MAGEMin automatically normalises the input bulk composition to 100 wt% and that changing an individual oxide by 1 wt.% is a relative change, not an absolute change.

Similarly multiple, but not all, oxides can be defined as vectors. Those in the `variable_inputs["bulk"]` dictionary must be the same length.

```Julia
constant_inputs = Dict()
constant_inputs["bulk"] = OrderedDict(
    "SiO2" => 38.4,
    "TiO2" => 0.7,
    "Al2O3" => 7.7,
    "Cr2O3" => 0.0,
    "FeO" => 5.98,
    "MgO" => 9.95,
    "CaO" => 8.25,
    # "Na2O" => 2.26,
    "K2O" => 0.24,
    "O" => 4.0,
    # "H2O" => 12.7,
)

variable_inputs = Dict()
variable_inputs["bulk"] = OrderedDict(
    "H2O"  => collect(range(start=0.0, stop=6.0, step=1.0)),
    "Na2O" => collect(range(start=0.0, stop=6.0, step=1.0))
)
```

Finally, all oxides can be defined as vectors. In this case all vectors must have the same length.

```Julia
n_steps = 25
variable_inputs = Dict()
variable_inputs["bulk"] = OrderedDict(
    "SiO2"  => collect(LinRange(30., 50., n_steps)),
    "TiO2"  => collect(LinRange( 0.,  2., n_steps)),
    "Al2O3" => collect(LinRange( 5., 10., n_steps)),
    "Cr2O3" => collect(LinRange( 0.,  2., n_steps)),
    "FeO"   => collect(LinRange( 5., 10., n_steps)),
    "MgO"   => collect(LinRange( 7., 12., n_steps)),
    "CaO"   => collect(LinRange( 7., 12., n_steps)),
    "Na2O"  => collect(LinRange( 2.,  8., n_steps)),
    "K2O"   => collect(LinRange( 0.,  2., n_steps)),
    "O"     => collect(LinRange( 1., 10., n_steps)),
    "H2O"   => collect(LinRange( 0., 10., n_steps))
)
```

## Monte Carlo Uncertainty Propagation of Bulk Compositions

The bulk compositions defined in the previous snippet do not represent realistic compositions. A more realistic scenario would be assessing the impact of analytical uncertainty in the bulk composition on the results of fractional crystallisation models. FCEnsemble has a function specially designed for this. The function `generate_bulk_mc` accepts two dictionaries, one defining a bulk composition as above, and a second containing corresponding absolute uncertainties. It produces a vector `n_samples` long for each oxide where each value is randomly sampled from a normal distribution defined by the measured value and its analytical uncertainty.

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