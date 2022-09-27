version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 01_extract_icem_census_data.do
* PURPOSE: This do file runs the do files in the scripts folder /01_extract_icem_census_data/
************

// Unpack raw I-CeM extracts
// Create separate extracts for different groups of variables for each census year

forvalues y = 1881(10)1911 {
			
	// These data sets will serve as inputs in the next set of do files below
	do "$PROJ_PATH/scripts/code/1_build/01_extract_icem_census_data/01.01_extract_icem_self_variables.do" `y'
	
}

local min_year 1881
local max_year 1911

do "$PROJ_PATH/scripts/code/1_build/01_extract_icem_census_data/01.02_fix_icem_household_ids.do" `min_year' `max_year'
do "$PROJ_PATH/scripts/code/1_build/01_extract_icem_census_data/01.03_extract_icem_father_variables.do" `min_year' `max_year'
do "$PROJ_PATH/scripts/code/1_build/01_extract_icem_census_data/01.04_extract_icem_mother_variables.do" `min_year' `max_year'
do "$PROJ_PATH/scripts/code/1_build/01_extract_icem_census_data/01.05_extract_icem_head_variables.do" `min_year' `max_year'
do "$PROJ_PATH/scripts/code/1_build/01_extract_icem_census_data/01.06_create_icem_sibling_ids.do" `min_year' `max_year'

local min_year 1901
local max_year 1911

do "$PROJ_PATH/scripts/code/1_build/01_extract_icem_census_data/01.07_extract_icem_spouse_variables.do" `min_year' `max_year'
do "$PROJ_PATH/scripts/code/1_build/01_extract_icem_census_data/01.08_extract_icem_child_variables.do" `min_year' `max_year'

disp "DateTime: $S_DATE $S_TIME"

* EOF 
