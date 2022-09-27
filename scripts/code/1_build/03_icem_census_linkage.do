version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 03_icem_census_linkage.do
* PURPOSE: This do file runs the do files in the scripts folder /03_icem_census_linkage/
************

disp "DateTime: $S_DATE $S_TIME"

forvalues t_1 = 1881(10)1901 {
	
	local t_max = 1911 - `t_1'
	
	forvalues gap = 10(10)`t_max' {
		
		// Extract matching variables for childhood census year
		local year = `t_1'
		local t_2 = `t_1' + `gap'	
		local age_lb = 0
		local age_ub = 21
		
		do "$PROJ_PATH/scripts/code/1_build/03_icem_census_linkage/03.01_extract_icem_matching_vars.do" `t_1' `t_2' `year' `age_lb' `age_ub'
		
		// Extract matching variables for adulthood census year
		local year = `t_2'
		local age_lb = (`t_2' - `t_1') - 5
		local age_ub = 21 + (`t_2' - `t_1') + 5
		
		do "$PROJ_PATH/scripts/code/1_build/03_icem_census_linkage/03.01_extract_icem_matching_vars.do" `t_1' `t_2' `year' `age_lb' `age_ub'
		
		// Blocking setup 
		do "$PROJ_PATH/scripts/code/1_build/03_icem_census_linkage/03.02_icem_blocking_setup.do" `t_1' `t_2' 
		
		// Blocking
		do "$PROJ_PATH/scripts/code/1_build/03_icem_census_linkage/03.03_icem_blocking.do" `t_1' `t_2' 
		
		// Create uniquely linked sample
		do "$PROJ_PATH/scripts/code/1_build/03_icem_census_linkage/03.04_icem_linkage_unique_sample.do" `t_1' `t_2' 
	}
}

disp "DateTime: $S_DATE $S_TIME"

* EOF
