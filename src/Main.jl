# Main.jl

using OrderedCollections
using DataStructures

include("GenerateEnsemble.jl")
using .GenerateEnsemble

### To Do ###
#   - Find Liquidus Function --> Only useful when running many many sims.
#   - IW Buffer --> Nicolas will implement in future version. Ignore for now.
#   - Tests:
        # - InputValidation X
        # - Monte Carlo X
#   - Deal with variable composition:
#       - H2O, and
#       - Monte Carlo X -> Check all way through
#   - Make fractional crystallisation simulations threaded
#   - Define output folder
#   - Return simulations as dictionary using output file.

# Define simulation parameters
T_start = 1400.
T_stop = 800.
T_step = 2.

if T_start > T_stop
    T_step *= -1
end
T_array = collect(range(start=T_start, stop=T_stop, step=T_step))

constant_inputs = Dict()
constant_inputs["buffer"] = "qfm"
constant_inputs["buffer_offset"] = 2.0
# constant_inputs["P"] = 0.0
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
variable_inputs["P"] = collect(range(0.0, 2.0, step=0.5))  # Pressure in kbar.
# variable_inputs["fo2_offset"] = collect(range(-2.0, 2.0, step=1.0))

# Define parameters for simulation
sys_in = "wt"
# output_folder = ""

# Run the simulations
results = GenerateEnsemble.run_simulations(T_array, constant_inputs, variable_inputs, sys_in, "/Users/felixboschetty/Documents/Julia/Test_Output/")
