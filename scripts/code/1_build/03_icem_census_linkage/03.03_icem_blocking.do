version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 03.03_icem_blocking.do
* PURPOSE: This do file does the data blocking 
************

args t_1 t_2

*********************************************************************************************************************
*********** I-CeM Census Blocking *************
*********************************************************************************************************************

use age using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/match_candidates_`t_1'.dta", clear
sum age
local min_age = r(min)
local max_age = r(max)

forvalues n = `min_age'(1)`max_age' {
	
	use "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/match_candidates_`t_1'.dta" if age == `n', clear
	rename age age_base

	tempfile age_input
	save `age_input', replace

	gen age = age_base
	tempfile age_output
	save `age_output', replace

	forvalues z = 1(1)5 {
		use `age_input', clear
		gen age = age_base - `z'
		append using `age_output'
		tempfile age_output
		save `age_output', replace
		
	}
	forvalues z = 1(1)5 {
		use `age_input', clear
		gen age = age_base + `z'
		append using `age_output'
		tempfile age_output
		save `age_output', replace
		
	}

	sort phx_sname phx_fname age sex bcounty age_base 
	joinby phx_sname phx_fname age sex bcounty using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/match_candidates_`t_2'.dta"
	save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/blocking_inprog_`t_1'_`t_2'_`n'.dta", replace
	
	keep fname_orig_`t_1' fname_orig_`t_2'
	bysort fname_orig_`t_1' fname_orig_`t_2': keep if _n == 1
	jarowinkler fname_orig_`t_1' fname_orig_`t_2', gen(jw_fname_orig)
	save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/jw_fname_orig_`t_1'_`t_2'_`n'.dta", replace
	
	use fname_edit_`t_1' fname_edit_`t_2' using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/blocking_inprog_`t_1'_`t_2'_`n'.dta", clear
	bysort fname_edit_`t_1' fname_edit_`t_2': keep if _n == 1
	jarowinkler fname_edit_`t_1' fname_edit_`t_2', gen(jw_fname_edit)
	save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/jw_fname_edit_`t_1'_`t_2'_`n'.dta", replace
	
	use surname_`t_1' surname_`t_2' using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/blocking_inprog_`t_1'_`t_2'_`n'.dta", clear
	bysort surname_`t_1' surname_`t_2': keep if _n == 1
	jarowinkler surname_`t_1' surname_`t_2', gen(jw_sname)
	save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/jw_sname_`t_1'_`t_2'_`n'.dta", replace
	
	use "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/blocking_inprog_`t_1'_`t_2'_`n'.dta", clear
	merge m:1 fname_orig_`t_1' fname_orig_`t_2' using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/jw_fname_orig_`t_1'_`t_2'_`n'.dta", keep(1 3) nogen
	merge m:1 fname_edit_`t_1' fname_edit_`t_2' using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/jw_fname_edit_`t_1'_`t_2'_`n'.dta", keep(1 3) nogen
	merge m:1 surname_`t_1' surname_`t_2' using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/jw_sname_`t_1'_`t_2'_`n'.dta", keep(1 3) nogen
	
	recode jw_fname_orig jw_fname_edit jw_sname (mis = 0)
	keep if max(jw_fname_orig, jw_fname_edit) >= 0.75 & jw_sname >= 0.75
	
	duplicates drop
	drop phx* fname_orig* fname_edit* surname*
	
	// Keep best match for each pair of censuses
	egen max_jw_dist = max(jw_fname_orig), by(RecID_`t_1' RecID_`t_2')
	drop if jw_fname_orig != max_jw_dist
	drop max_jw_dist
	
	egen max_jw_dist = max(jw_fname_edit), by(RecID_`t_1' RecID_`t_2')
	drop if jw_fname_edit != max_jw_dist
	drop max_jw_dist
	
	egen max_jw_dist = max(jw_sname), by(RecID_`t_1' RecID_`t_2')
	drop if jw_sname != max_jw_dist
	drop max_jw_dist
	
	duplicates drop 
	
	save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/blocking_matched_`t_1'_`t_2'_`n'.dta", replace
	
	rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/blocking_inprog_`t_1'_`t_2'_`n'.dta"
	rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/jw_fname_orig_`t_1'_`t_2'_`n'.dta"
	rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/jw_fname_edit_`t_1'_`t_2'_`n'.dta"
	rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/jw_sname_`t_1'_`t_2'_`n'.dta"
}

clear
forvalues n = `min_age'(1)`max_age' {
	append using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/blocking_matched_`t_1'_`t_2'_`n'.dta"
}

order RecID_`t_1' RecID_`t_2' age_base age sex bcounty jw*

unique RecID_`t_1' RecID_`t_2' bcounty
sort RecID_`t_1' RecID_`t_2' bcounty 

save "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/using_sample_`t_1'_`t_2'.dta", replace

forvalues n = `min_age'(1)`max_age' {
	rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/blocking_matched_`t_1'_`t_2'_`n'.dta"
}
rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/match_candidates_`t_1'.dta"
rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/match_candidates_`t_2'.dta"

disp "DateTime: $S_DATE $S_TIME"

* EOF
