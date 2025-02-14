# [Intensive Variables](@id intensive_variables)

MAGEMinEnsemble allows the user to define a parameter space over which an ensemble of thermodynamic simulations are performed. This section describes the intensive parameters that can be specified. Those that are mandatory are marked (mandatory). Where possible, incorrect inputs will result in descriptive errors when the simulations are run.

## Temperature (mandatory)
Temperature is set outside of `constant_inputs` and `variable_inputs` as it is the same for all simulations. It is defined as a vector of floats (`T_array`) that is descending. For fractional crystallisation simulations, the lowest temperature in `T_array` may not be reached, as fractional simulations will only progress until the bulk solidus (i.e., the melt fraction is 0). To ensure that the simulations start above the solidus, a high maximum temperature should be chosen.

## Bulk composition (mandatory)

The bulk composition of the simulation is input by defining a series of oxides. `MAGEMin` performs simulations in an 11-dimensional composition space: Na2O–CaO–K2O–FeO–MgO–Al2O3–SiO2–TiO2–Fe2O3–Cr2O3–H2O. By default the composition is expected to be in units of oxide wt.%. `MAGEMin` automatically normalises the composition to 100%.

Each oxide is defined by a key, value pair, where the value is a float. All oxide values should be positive. Apart from `"H2O"`, when an oxide is set to 0.00 `MAGEMinEnsemble` will automatically convert it to 0.001 wt.% to avoid instabilities. See the [MAGEMin documentation](https://computationalthermodynamics.github.io/MAGEMin/issues.html#known-problems) for more information.

A constant bulk composition matching KLB-1 basalt can be defined as follows.
```Julia
# Assign a constant bulk composition in oxide wt.%
constant_inputs = OrderedDict{
    "SiO2"  => 44.66,
    "TiO2"  =>  1.42,
    "Al2O3" => 15.90,
    "Cr2O3" =>  0.00,
    "FeO"   => 11.41,
    "Fe2O3" =>  0.00,
    "MgO"   =>  7.79,
    "CaO"   => 11.24,
    "Na2O"  =>  2.74,
    "K2O"   =>  0.22,
    "H2O"   =>  0.00
}
```
!!! note
Here `"Fe2O3"` is given a value of 0.00 i.e. reducing conditions. Oxygen fugacity can be controlled and is discussed below. The user must define an `"Fe2O3"` or `"O"` content in the bulk composition.

Errors will be thrown if the user defines an oxide outside of `MAGEMin`'s compositional space. Either due to additional oxides, e.g,. `"CuO"` or if any oxides are missing.

Any number of oxides can be defined as vectors in a `variable_inputs` dictionary:
```Julia
# Assign a variable H2O content from 0.0 to 8.0 wt% in increments of 1.0
variable_inputs = OrderedDict{
    "H2O" => collect(range(start=0.0, stop=8.0, step=1.0))
}
```


## Pressure (mandatory)

Pressure can be set using the `"P"` key and has units of kilobars (kbar). Pressures should be positive. As with oxides, when a pressure is defined as 0.0 `MAGEMinEnsemble` automatically converts it to 1 bar to avoid instability. See the [MAGEMin documentation](https://computationalthermodynamics.github.io/MAGEMin/issues.html#known-problems) for more details.

```Julia
# Assign a constant pressure of 1.0 kbar
constant_inputs = OrderedDict{
    "P" => 1.0
}
```

## Fugacity and Activity

The fugacity (or activity) for compounds during the simulation can be buffered using the keys `"buffer"` and `"offset"`. If `"offset"` is defined, a `"buffer"` must also be defined. Values for `"buffer"` must be strings, and values for `"offset"` must be floats.

### Buffer

There are several buffers available in `MAGEMin`. These can be divided into two types, (1) oxygen fugacity buffers, and (2) activity buffers. For example to impart a constant Quartz-Fayalite-Magnetite oxygen fugacity buffer:
```Julia
# Assign a constant oxygen fugacity at the QFM buffer
constant_inputs = OrderedDict{
    "buffer" => "qfm"
}
```
The effect of the buffer on a set of simulations can be determined by defining the buffer in `variable_inputs`:

```Julia
# Assign a variable oxygen fugacity at the QFM and NNO buffers
variable_inputs = OrderedDict{
    "buffer" => ["qfm", "nno"]
}
```

#### 1. Oxygen Fugacity Buffers

The oxygen fugacity buffer allows the amount of free oxygen in the simulation to be buffered according to a oxygen-fugacity-pressure-temperature relationship. The available buffers in `MAGEMin` are:

- Quartz-Fayalite-Magnetite (`"qfm"`)
- Quartz-Iron_Faylite (`"qif"`)
- Nickel-Nickel Oxide (`"nno"`)
- Hematite-Magnetite (`"hm"`)
- Iron-Wüstite (`"iw"`)
- Carbon Dioxide-Carbon (`"cco"`)

If an oxygen fugacity buffer is set, there must be sufficient `"O"` or `"Fe2O3"` defined in the bulk composition to saturate the system at that buffer. Excess `"O"` or `"Fe2O3"` will be removed. The oxygen (`"O"`) content is set to be equal to `"Fe2O3"`. Therefore both `"O"` and `"Fe2O3"` should not be defined in the bulk composition.

#### 2. Activity Buffers

In the same manner, activity for a given oxide can be fixed using the following activity buffers:

- `"aH2O"` using water as reference phase
- `"aO2"` using dioxygen as reference phase
- `"aMgO"` using periclase as reference phase
- `"aFeO"` using ferropericlase as reference phase
- `"aAl2O3"` using corundum as reference phase
- `"aTiO2"` using rutile as reference phase
- `"aSiO2"` using quartz/coesite as reference phase

As with the oxygen fugacity buffers, the corresponding oxide content must be sufficient to saturate the system. Excess oxide-content will be removed at each simulation step.

### Buffer Offset

To perform the simulation at an activity or oxygen fugacity offset from the buffer the key "offset" can be used, where the offset is given in log10 units. A constant buffer and offset of QFM+1 can be set using:
```Julia
constant_inputs = OrderedDict{
    "buffer" => "qfm",
    "offset" => 1.0,
}
```
A variable offset can be defined by including the "offset" key in the `variable_inputs` dictionary:
```Julia
constant_inputs = OrderedDict{
    # "buffer" must be defined if "offset" is defined
    "buffer" => "qfm"
}

variable_inputs = OrderedDict{
    # perform simulations at QFM-2.0 to QFM+2.0 in increments of 1.0 log10 units
    "offset" => [-2.0, -1.0, 0.0, 1.0, 2.0]
}
```

