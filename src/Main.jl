# Main.jl

using OrderedCollections
using DataStructures

include("GenerateEnsemble.jl")
using .GenerateEnsemble

### To Do ###
#   - Find Liquidus Function --> Only useful when running many many sims.
#   - IW Buffer --> Nicolas will implement in future version. Ignore for now.
#   - Deal w/ MonteCarlo bulk
#   - Make simulations threaded

# Define simulation parameters
T_start = 1400.
T_stop = 800.
T_step = 2.

if T_start > T_stop
    T_step *= -1
end
T_array = collect(range(start=T_start, stop=T_stop, step=T_step))

constant_inputs = OrderedDict()
constant_inputs["buffer"] = "qfm"
# constant_inputs["offset"] = 2.0
# constant_inputs["P"] = 1.0
constant_inputs["SiO2"] = 38.4
constant_inputs["TiO2"] = 0.7
constant_inputs["Al2O3"] = 7.7
constant_inputs["Cr2O3"] = 0.0
constant_inputs["FeO"] = 5.98
constant_inputs["MgO"] = 9.95
constant_inputs["CaO"] = 8.25
constant_inputs["Na2O"] = 2.26
constant_inputs["K2O"] = 0.24
constant_inputs["O"] = 4.0
# constant_inputs["H2O"] = 12.7

variable_inputs = OrderedDict()
variable_inputs["H2O"] = collect(range(start=0.0, stop=1.0, step=1.0))
variable_inputs["P"] = collect(range(0.0, 1.0, step=1.0))  # Pressure in kbar.
# variable_inputs["offset"] = collect(range(0.0, 1.0, step=1.0))

# Define parameters for simulation
sys_in = "wt"
output_dir = "/Users/felixboschetty/Documents/Julia/Test_Parallel/"

# Run the simulations
results = GenerateEnsemble.run_simulations(T_array, constant_inputs, variable_inputs, sys_in, output_dir)
