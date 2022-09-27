version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 03_extract_icem_father_variables.do
* PURPOSE: This do file extracts the variables for fathers from the I-CeM data
************

*********************************************************************************************************************
*********** I-CeM: Father variables *************
*********************************************************************************************************************

args min_year max_year

forvalues y = `min_year'(10)`max_year' {
	
	use RecID Year Age Rela Mar using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_demographic.dta", clear
	fmerge 1:1 RecID Year using "$PROJ_PATH/processed/intermediate/icem/household_ids/icem_household_ids_`y'.dta", assert(3) nogen keepusing(pid_inf hhid)
	fmerge 1:1 RecID Year using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_occupation.dta", assert(3) nogen
		
	rename RecID poprecid
	rename pid_inf poploc
	rename Age popage
	rename hisco pophisco
	rename Occode popoccode
	rename Occ popocc
	rename Mar popmarital
	rename Rela poprelate

	destring popage, replace
	destring pophisco, replace
	
	drop if poploc == .
	
	tempfile popvars
	save `popvars', replace

	use RecID Year Rela using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_demographic.dta", clear
	fmerge 1:1 RecID Year using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_parents.dta", assert(3) nogen keepusing(poploc)
	fmerge 1:1 RecID Year using "$PROJ_PATH/processed/intermediate/icem/household_ids/icem_household_ids_`y'.dta", assert(3) nogen 
	
	gsort hhid pid_inf
	replace poploc = . if flag_fix_pid == 1
	rename flag_fix_pid flag_fix_popid
		
	// Impute poploc
	gen temp_poploc = poploc
	gen head_pop = (pid_inf == 1 & Rela == 11)
	egen hh_head_pop = total(head_pop == 1), by(hhid)
	tab hh_head_pop
	tab poploc if hh_head_pop == 1 & (Rela == 30 | Rela == 31 | Rela == 32), missing
	replace poploc = 1 if hh_head_pop == 1 & (Rela == 30 | Rela == 31 | Rela == 32)
	drop head_pop hh_head_pop 

	gen husb_pop = (pid_inf == 2 & Rela == 21)
	egen hh_husb_pop = total(husb_pop == 1), by(hhid)
	tab hh_husb_pop
	tab poploc if hh_husb_pop == 1 & (Rela == 30 | Rela == 31 | Rela == 32), missing
	replace poploc = 2 if hh_husb_pop == 1 & (Rela == 30 | Rela == 31 | Rela == 32)
	drop husb_pop hh_husb_pop Rela
	
	drop if poploc == 0 | poploc == .
	gen impute_poploc = (poploc != temp_poploc)
	drop temp_poploc
	fmerge m:1 Year hhid poploc using `popvars', keep(3) nogen

	save "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`y'.dta", replace

}

// Save each group of variables to separate files

clear
forvalues y = `min_year'(10)`max_year' {
    
	// ID variables
	use RecID Year poploc impute_poploc flag_fix_popid poprecid using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`y'.dta", clear
	gduplicates drop
	save "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`y'_identifiers.dta", replace
	
	// Demographic
	use RecID Year popage poprelate popmarital using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`y'.dta", clear
	gduplicates drop
	save "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`y'_demographic.dta", replace

	// Occupation
	use RecID Year pophisco popoccode popocc using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`y'.dta", clear
	gduplicates drop
	save "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`y'_occupation.dta", replace

	rm "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`y'.dta"
}

disp "DateTime: $S_DATE $S_TIME"

* EOF
