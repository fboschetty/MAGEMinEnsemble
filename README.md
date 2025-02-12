# MAGEMinEnsemble.jl

MAGEMinEnsemble is a Julia-based software designed to perform an ensemble of fractional crystallisation simulations across a defined intensive variable space. It utilises the Julia wrapper of [MAGEMin](https://github.com/ComputationalThermodynamics/MAGEMin_C.jl) to perform these simulations. The software is heavily inspired by Zack Gainsforth's [alphaMELTSEnsemble](https://github.com/ZGainsforth/alphaMELTSEnsemble), which similarly performs a series of thermodynamic simulations of magmatic systems using alphaMELTS.

The key features MAGEMinEnsemble provides are:
- Constant and variable intensive parameters are defined in simple dictionaries.
- An ensemble of fractional crystallisation simulations is assembled and ran across the defined parameter space.
- Multi-threading to perform simulations in parallel.
- All outputs are saved into appropriately named .csv files.
- Simple Monte Carlo functionality to assess the impact of uncertainties in bulk composition.

This package is a work in progress and additional functionality will be added in the future.

All further information is provided in the documentation that can be found online.