version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 05_extract_icem_head_variables.do
* PURPOSE: This do file extracts the variables for household heads from the I-CeM data
************

*********************************************************************************************************************
*********** I-CeM: Household head variables *************
*********************************************************************************************************************

args min_year max_year

forvalues y = `min_year'(10)`max_year' {

	use RecID Year Age Rela using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_demographic.dta", clear
	fmerge 1:1 RecID Year using "$PROJ_PATH/processed/intermediate/icem/household_ids/icem_household_ids_`y'.dta", assert(3) nogen keepusing(pid_inf hhid)
	fmerge 1:1 RecID Year using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_occupation.dta", assert(3) nogen
		
	rename RecID hh_recid
	rename pid_inf hh_loc
	rename Age hh_age
	rename hisco hh_hisco
	rename Occode hh_occode
	rename Occ hh_occ
	rename Rela hh_relate

	destring hh_age, replace
	destring hh_hisco, replace
	
	keep if hh_relate == 10 | hh_relate == 11 | hh_relate == 12
	
	gegen first_head = min(hh_loc), by(hhid)
	drop if hh_loc != first_head
	drop first_head
	
	gsort hhid 
	gunique hhid
	
	compress
	save "$PROJ_PATH/processed/intermediate/icem/head_vars/icem_head_`y'.dta", replace
}

* Save each variable to separate file 

clear
forvalues y = `min_year'(10)`max_year' {
	
	// ID variables
	use hhid Year hh_loc hh_recid using "$PROJ_PATH/processed/intermediate/icem/head_vars/icem_head_`y'.dta", clear
	gduplicates drop
	save "$PROJ_PATH/processed/intermediate/icem/head_vars/icem_head_`y'_identifiers.dta", replace
	
	// Demographic
	use hhid Year hh_age hh_relate using "$PROJ_PATH/processed/intermediate/icem/head_vars/icem_head_`y'.dta", clear
	gduplicates drop
	save "$PROJ_PATH/processed/intermediate/icem/head_vars/icem_head_`y'_demographic.dta", replace

	// Occupation
	use hhid Year hh_hisco hh_occode hh_occ using "$PROJ_PATH/processed/intermediate/icem/head_vars/icem_head_`y'.dta", clear
	gduplicates drop
	save "$PROJ_PATH/processed/intermediate/icem/head_vars/icem_head_`y'_occupation.dta", replace

	rm "$PROJ_PATH/processed/intermediate/icem/head_vars/icem_head_`y'.dta"
}

disp "DateTime: $S_DATE $S_TIME"

* EOF
