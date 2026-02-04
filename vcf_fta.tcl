
# TCL-script for VC Formal (Synopsys)

# Change working directory to the directory of the script
set SCRIPT_LOCATION [file dirname [file normalize [info script]]]
cd $SCRIPT_LOCATION


#################
# Configure VCF #
set_fml_appmode FPV
set_app_var apply_bind_in_all_units true
set_app_var fml_auto_save default
set_app_var fml_composite_trace true
set_fml_var fml_witness_on true
set_fml_var fml_vacuity_on true

set_app_var fml_multi_step_fta_flow true

###############
# Load Design #
analyze -format sverilog -vcs "define.sv"
analyze -format sverilog -vcs "apb_master.sv"
analyze -format sverilog -vcs "-assert svaext apb_master_fv.sv"

set top apb_master
set elaborateOption -verbose 
elaborate $top $elaborateOption -sva -inject_fault all

fta_init -top $top

create_clock PCLK -period 100

# Problem (page 51 VC formal manual):
# Reset high, “create_reset rst -sense high” is the same as:
# sim_force rst -apply 1'b1
# set_constant rst -apply 1'b0
# This creates a constraint that sets reset to constant 0 which prevents any proofs
# that start from reset.
# Note: “create_reset -name reset -sense high” creates something different that does not work.
#create_reset rst -sense high
sim_force PRESETn -apply 1'b0


####################
# Check properties #
sim_run -stable
sim_save_reset


check_fv -block
configure_fta_props -status {proven inconclusive}
set_fml_appmode FTA
compute_fta -par_task FPV

