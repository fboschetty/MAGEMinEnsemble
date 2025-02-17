# [Intensive Variables](@id intensive_variables)

MAGEMinEnsemble allows the user to define a parameter space over which an ensemble of thermodynamic simulations are performed. This section describes the intensive parameters that can be specified. Mandatory parameters are marked (mandatory). Incorrect inputs will generally result in descriptive errors when the simulations are run.

## Temperature (mandatory)
Temperature is specified using initial (`"T_start"`), final (`"T_stop"`) and incremental (`"T_step"`) temperatures, in degrees Celsius. Where corresponding values are floats.
```Julia
constant_inputs = OrderedDict(
    "T_start" => 1400.,  # Starting temperature (°C)
    "T_stop" => 800.,    # Final temperature (°C)
    "T_step" => -1.      # Temperature step (°C)
)
```
!!! note
    For crystallisation simulations, the final temperature may not be reached, as fractional simulations will stop when the bulk solidus (i.e., when the melt fraction is 0). To ensure that the simulations start above the solidus, choose a sufficiently high maximum temperature.

Any or all of the three temperature keys can also be assigned as `variable_inputs`. For example, running multiple simulations with variable `"T_step"` to investigate the effects of varying temperature increments.
```Julia
variable_inputs = OrderedDict(
    # Different step sizes
    "T_step" => [-1., -2., -5., -10., -20.]
)
```

## Bulk composition (mandatory)

The bulk composition of the simulation is specified in terms of oxide wt.%. `MAGEMin` operates in an 11-dimensional composition space: Na₂O–CaO–K₂O–FeO–MgO–Al₂O₃–SiO₂–TiO₂–Fe₂O₃–Cr₂O₃–H₂O.

Each oxide is defined by a key, value pair, where the value is a float. All oxide values should be positive. When an oxide is set to 0.0  (except for `"H2O"`) it is internally adjusted to 0.001 wt.% to avoid instabilities. See the [MAGEMin documentation](https://computationalthermodynamics.github.io/MAGEMin/issues.html#known-problems) for more information.

!!! note
    `MAGEMin` automatically normalises the assigned composition to 100%.

For example, a constant bulk composition of KLB-1 basalt can be defined as follows.
```Julia
constant_inputs = OrderedDict(
    # Assign a constant bulk composition in oxide wt.%
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
)
```
!!! note
    Here `"Fe2O3"` is given a value of 0.00 i.e. reducing conditions. Oxygen fugacity is discussed in the @ref[Fugacity and Activity] section. Either `"Fe2O3"` or `"O"` must be defined in the bulk composition.

Errors will be thrown if the user defines an oxide outside of `MAGEMin`'s compositional space. Either due to additional oxides, e.g,. `"CuO"` or if any oxides are missing.

Any number of oxides can be defined as vectors in a `variable_inputs` dictionary:
```Julia
variable_inputs = OrderedDict(
    # Assign a variable H2O content from 0.0 to 8.0 wt.%
    # in increments of 1.0 wt.%
    "H2O" => collect(range(start=0.0, stop=8.0, step=1.0))
)
```

## Pressure (mandatory)

Pressure is defined using the `"P"` key and has units of kilobars (kbar) and must be positive. As with oxides, when a pressure is defined as 0.0 kbar `MAGEMinEnsemble` automatically converts it to 1 bar to avoid instability. See the [MAGEMin documentation](https://computationalthermodynamics.github.io/MAGEMin/issues.html#known-problems) for more details.

```Julia
# Assign a constant pressure of 1.0 kbar
constant_inputs = OrderedDict(
    "P" => 1.0
)
```

## Fugacity and Activity

The fugacity (or activity) for compounds during the simulation can be buffered using the `"buffer"` and `"offset"` keys. The `"buffer"` value must be a string, while `"offset"` values are floats. If `"offset"` is defined, a `"buffer"` must also be defined.

### Buffer

There are several buffers available in `MAGEMin`. These can be divided into two types, (1) oxygen fugacity buffers, and (2) activity buffers.

#### 1. Oxygen Fugacity Buffers

The oxygen fugacity buffer constrains the free oxygen content according to a pressure-temperature relationship. The available buffers in `MAGEMin` are:

- Quartz-Fayalite-Magnetite (`"qfm"`)
- Quartz-Iron_Faylite (`"qif"`)
- Nickel-Nickel Oxide (`"nno"`)
- Hematite-Magnetite (`"hm"`)
- Iron-Wüstite (`"iw"`)
- Carbon Dioxide-Carbon (`"cco"`)

If an oxygen fugacity buffer is set, there must be sufficient `"O"` or `"Fe2O3"` defined in the bulk composition to saturate the system at that buffer. Excess `"O"` or `"Fe2O3"` will be removed. The oxygen (`"O"`) content is set to be equal to `"Fe2O3"`. Therefore both `"O"` and `"Fe2O3"` should not be defined in the bulk composition.

Assigning a constant oxygen fugacity buffer:
```Julia
# Assign a constant oxygen fugacity at the QFM buffer
constant_inputs = OrderedDict(
    "buffer" => "qfm"
)
```
Running simulations with different buffers:
```Julia
# Assign a variable oxygen fugacity at the QFM and NNO buffers
variable_inputs = OrderedDict(
    "buffer" => ["qfm", "nno"]
)
```

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

To perform the simulation at an activity or oxygen fugacity offset from the buffer the key `"offset"` can be used, where the offset is given in log10 units. A constant buffer and offset of QFM+1 can be set using:
```Julia
constant_inputs = OrderedDict(
    "buffer" => "qfm",
    "offset" => 1.0,
)
```
A variable offset can be defined by including the "offset" key in the `variable_inputs` dictionary:
```Julia
constant_inputs = OrderedDict(
    # "buffer" must be defined if "offset" is defined
    "buffer" => "qfm"
)

variable_inputs = OrderedDict(
    # perform simulations at QFM-2.0 to QFM+2.0 in increments of 1.0 log10 units
    "offset" => [-2.0, -1.0, 0.0, 1.0, 2.0]
)
```

