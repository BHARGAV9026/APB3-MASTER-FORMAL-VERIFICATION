
# TCL-script for VC Formal (Synopsys)

# Change working directory to the directory of the script
set SCRIPT_LOCATION [file dirname [file normalize [info script]]]
cd $SCRIPT_LOCATION


#################
# Configure VCF #
set_fml_appmode COV
set_fml_var fml_reset_property_check true
set_app_var fml_cov_tgl_input_port true
set_fml_var fml_cov_enable_branch_cov true

###############
# Load Design #
analyze -format sverilog -vcs "define.sv"
analyze -format sverilog -vcs "apb_master.sv"
analyze -format sverilog -vcs "-assert svaext apb_master_fv.sv"

set top apb_master
fta_init -top $top

set elaborateOption -verbose
elaborate $top -cov all $elaborateOption -sva 

create_clock PCLK -period 100

# Problem (page 51 VC formal manual):
# Reset high, “create_reset rst -sense high” is the same as:
# sim_force rst -apply 1'b1
# set_constant rst -apply 1'b0
# This creates a constraint that sets reset to constant 0 which prevents any proofs
# that start from reset.
# Note: “create_reset -name reset -sense high” creates something different that does not work.
#create_reset reset -sense high
 sim_force PRESETn -apply 1'b0
#create_reset reset -sense high 
#sim_save_reset


####################
# Check properties #
sim_run -stable
sim_save_reset

# Uncomment this to automatically check the properties
check_fv

