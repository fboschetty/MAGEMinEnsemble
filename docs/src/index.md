# MAGEMinEnsemble.jl Documentation

## Introduction
MAGEMinEnsemble is a Julia-based software designed to perform an ensemble of fractional crystallisation simulations across a defined intensive variable space. It utilises the Julia wrapper of [MAGEMin](https://github.com/ComputationalThermodynamics/MAGEMin_C.jl) to perform these simulations. The software is heavily inspired by Zack Gainsforth's [alphaMELTSEnsemble](https://github.com/ZGainsforth/alphaMELTSEnsemble), which similarly performs a series of thermodynamic simulations of magmatic systems using alphaMELTS.

The key features MAGEMinEnsemble provides are:
- Constant and variable intensive parameters are defined in simple dictionaries.
- An ensemble of fractional crystallisation simulations is assembled and ran across the defined parameter space.
- All outputs are saved into appropriately named .csv files.
- Simple Monte Carlo functionality to assess the impact of uncertainties in bulk composition.

This package is a work in progress and additional functionality will be added in the future.

## Installation
`MAGEMinEnsemble` is currently unregistered and must be installed using Pkg and directing it to the MAGEMinEnsemble.jl source file.
Download this repository. Add the following to the top of your script.
```Julia
using Pkg
Pkg.add(path="Path/To/MAGEMinEnsemble")

using MAGEMinEnsemble
```

## Usage
* see [Basic Usage](basic_usage.md) for an introduction to using the package;
* the [Intensive Variables](intensive_variables.md) explains the different intensive variables.
* See [Functions](functions.md) for a list of all functions and links to their source code.