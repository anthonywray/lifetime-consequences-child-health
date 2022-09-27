version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 06_build_analysis_data.do
* PURPOSE: This do file runs the do files in the scripts folder /06_build_analysis_data/
************

// Assign HISCLASS rank to HISCO codes
do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/06.00_hisco_to_hisclass.do"

// Construct Williamson wages
do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/06.01_assign_williamson_wages.do"

// Long-run occupational and intergenerational mobility analysis setup
do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/06.02_occupational_analysis_setup.do"

// Single marital status preprocessing
forvalues gender = 1(1)2 {
	do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/06.03_single_marital_status_pre_processing.do" `gender'
}

// Single marital status setup
local x = 9
local jw_bot = 1 - (`x' - 1)*0.025
local age_dist = 3
local sim_records = 20

forvalues gender = 1(1)2 {  
	do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/06.03_single_marital_status_setup.do" `gender' `jw_bot' `age_dist' `sim_records'
}

// Participation in schooling analysis setup
do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/06.04_schooling_analysis_setup.do"

// Pre-existing disability analysis setup
do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/06.05_pre_existing_analysis_setup.do"

// Childhood disability analysis setup
do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/06.06_disability_analysis_setup.do"

// Benchmark regression setup
do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/06.07_benchmark_regression_setup.do"

// Catchment area setup
do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/06.08_catchment_area_setup.do"

// Selection into hospitalization setup
do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/06.09_selection_into_hospitalization_setup.do"

// Link fathers across consecutive censuses 

forvalues t_1 = 1881(10)1891 {
	
	local t_2 = `t_1' + 10
	
	do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/06.10_icem_hosp_link_fathers_setup.do" `t_1' `t_2'
}

// Create analysis data
do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/06.11_create_analysis_data.do"

// Set up data for linkage table
do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/06.12_linkage_rate_setup.do"

disp "DateTime: $S_DATE $S_TIME"

* EOF
