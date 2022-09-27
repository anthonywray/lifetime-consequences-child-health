version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 04_extract_icem_mother_variables.do
* PURPOSE: This do file extracts the variables for mothers from the I-CeM data
************

*********************************************************************************************************************
*********** I-CeM: Mother variables *************
*********************************************************************************************************************

args min_year max_year

forvalues y = `min_year'(10)`max_year' {

	use RecID Year Age Rela Mar using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_demographic.dta", clear
	fmerge 1:1 RecID Year using "$PROJ_PATH/processed/intermediate/icem/household_ids/icem_household_ids_`y'.dta", assert(3) nogen keepusing(pid_inf hhid)
	fmerge 1:1 RecID Year using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_occupation.dta", assert(3) nogen
	
	if `y' == 1911 {
		fmerge 1:1 RecID Year using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_1911_childalive.dta", assert(3) nogen
		rename ChildrenCode momchildalive
		rename hhd momchilddead
		rename ChildTot momym
		destring momchildalive momchilddead momym, replace
	}
	
	rename RecID momrecid
	rename pid_inf momloc
	rename Age momage
	rename hisco momhisco
	rename Occode momoccode
	rename Occ momocc
	rename Mar mommarital
	rename Rela momrelate

	destring momage, replace
	destring momhisco, replace
	
	drop if momloc == .
	
	tempfile momvars
	save `momvars', replace

	use RecID Year Rela using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_demographic.dta", clear
	fmerge 1:1 RecID Year using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_parents.dta", assert(3) nogen keepusing(momloc)
	fmerge 1:1 RecID Year using "$PROJ_PATH/processed/intermediate/icem/household_ids/icem_household_ids_`y'.dta", assert(3) nogen 
	
	gsort hhid pid_inf
	replace momloc = . if flag_fix_pid == 1
	rename flag_fix_pid flag_fix_momid
		
	* Impute momloc
	gen temp_momloc = momloc
	gen wife_mom = (pid_inf == 2 & Rela == 22)
	egen hh_wife_mom = total(wife_mom == 1), by(hhid)
	tab hh_wife_mom
	tab momloc if hh_wife_mom == 1 & (Rela == 30 | Rela == 31 | Rela == 32), missing
	replace momloc = 2 if hh_wife_mom == 1 & (Rela == 30 | Rela == 31 | Rela == 32)
	drop wife_mom hh_wife_mom 

	gen head_mom = (pid_inf == 1 & Rela == 12)
	egen hh_head_mom = total(head_mom == 1), by(hhid)
	tab hh_head_mom
	tab momloc if hh_head_mom == 1 & (Rela == 30 | Rela == 31 | Rela == 32), missing
	replace momloc = 1 if hh_head_mom == 1 & (Rela == 30 | Rela == 31 | Rela == 32)
	drop head_mom hh_head_mom Rela
	
	drop if momloc == 0 | momloc == .
	gen impute_momloc = (momloc != temp_momloc)
	drop temp_momloc
	fmerge m:1 Year hhid momloc using `momvars', keep(3) nogen

	save "$PROJ_PATH/processed/intermediate/icem/mom_vars/icem_mom_`y'.dta", replace
}

* Save each variable to separate file 

clear
forvalues y = `min_year'(10)`max_year' {
    
	// ID variables
	use RecID Year momloc impute_momloc flag_fix_momid momrecid using "$PROJ_PATH/processed/intermediate/icem/mom_vars/icem_mom_`y'.dta", clear
	gduplicates drop
	save "$PROJ_PATH/processed/intermediate/icem/mom_vars/icem_mom_`y'_identifiers.dta", replace
	
	// Demographic
	use RecID Year momage momrelate mommarital using "$PROJ_PATH/processed/intermediate/icem/mom_vars/icem_mom_`y'.dta", clear
	gduplicates drop
	save "$PROJ_PATH/processed/intermediate/icem/mom_vars/icem_mom_`y'_demographic.dta", replace

	// Occupation
	use RecID Year momhisco momoccode momocc using "$PROJ_PATH/processed/intermediate/icem/mom_vars/icem_mom_`y'.dta", clear
	gduplicates drop
	save "$PROJ_PATH/processed/intermediate/icem/mom_vars/icem_mom_`y'_occupation.dta", replace

	if `y' == 1911 {	
		// Children
		use RecID Year momchildalive momchilddead momym using "$PROJ_PATH/processed/intermediate/icem/mom_vars/icem_mom_`y'.dta", clear
		gduplicates drop
		save "$PROJ_PATH/processed/intermediate/icem/mom_vars/icem_mom_`y'_children.dta", replace
	}
	rm "$PROJ_PATH/processed/intermediate/icem/mom_vars/icem_mom_`y'.dta"
}

disp "DateTime: $S_DATE $S_TIME"

* EOF
