version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 07_extract_icem_spouse_variables.do
* PURPOSE: This do file extracts the variables for spouses from the I-CeM data
************

*********************************************************************************************************************
*********** I-CeM: Spouse variables *************
*********************************************************************************************************************

args min_year max_year

forvalues y = `min_year'(10)`max_year' {
	
	use RecID Year Age Mar using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_demographic.dta", clear
	fmerge 1:1 RecID Year using "$PROJ_PATH/processed/intermediate/icem/household_ids/icem_household_ids_`y'.dta", assert(3) nogen keepusing(pid_inf hhid)
	fmerge 1:1 RecID Year using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_occupation.dta", assert(3) nogen
	if `y' == 1911 {
		fmerge 1:1 RecID Year using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_1911_childalive.dta", assert(3) nogen
		rename ChildrenCode spchildalive
		rename hhd spchilddead
		rename ChildTot spym 
		destring spchildalive spchilddead spym, replace
	}
	rename RecID sprecid
	rename pid_inf sploc
	rename Age spage
	rename Mar spmarst
	rename hisco sphisco
	rename Occode spoccode
	rename Occ spocc

	destring spage, replace
	destring sphisco, replace
	
	// NOTE: raw pid variable is missing for 4413 observations in 1901 census
	drop if sploc == . 
	
	tempfile spvars
	save `spvars', replace

	use RecID Year Rela using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_Demographic.dta", clear
	fmerge 1:1 RecID Year using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_Parents.dta", assert(3) nogen keepusing(sploc)
	fmerge 1:1 RecID Year using "$PROJ_PATH/processed/intermediate/icem/household_ids/icem_household_ids_`y'.dta", assert(3) nogen 
	
	gsort hhid pid_inf
	replace sploc = . if flag_fix_pid == 1
	rename flag_fix_pid flag_fix_spid
		
	* Impute sploc
	gen temp_sploc = sploc
	gen head_sp = (pid_inf == 1 & (Rela == 10 | Rela == 11 | Rela == 12))
	egen hh_head_sp = total(head_sp == 1), by(hhid)
	tab hh_head_sp
	tab sploc if hh_head_sp == 1 & pid_inf == 2 & (Rela == 20 | Rela == 21 | Rela == 22), missing
	replace sploc = 1 if hh_head_sp == 1 & pid_inf == 2 & (Rela == 20 | Rela == 21 | Rela == 22)
	drop head_sp hh_head_sp 

	gen sp_pos2 = (pid_inf == 2 & (Rela == 20 | Rela == 21 | Rela == 22))
	egen hh_sp_pos2 = total(sp_pos2 == 1), by(hhid)
	tab hh_sp_pos2
	tab sploc if hh_sp_pos2 == 1 & pid_inf == 1 & (Rela == 10 | Rela == 11 | Rela == 12), missing
	replace sploc = 2 if hh_sp_pos2 == 1 & pid_inf == 1 & (Rela == 10 | Rela == 11 | Rela == 12)
	drop sp_pos2 hh_sp_pos2 Rela
	
	drop if sploc == 0 | sploc == .
	gen impute_sploc = (sploc != temp_sploc)
	drop temp_sploc
	
	* Deal with coding errors in sploc (two people have the same spouse)
	
	gegen min_pid = min(pid_inf), by(hhid sploc)
	drop if sploc == 1 & pid_inf != min_pid
	drop min_pid
	
	gen sp_dist = abs(sploc - pid_inf)
	gegen min_dist = min(sp_dist), by(hhid sploc)
	drop if sp_dist != min_dist
	drop sp_dist min_dist
	
	bysort hhid sploc: drop if _N > 1
	
	fmerge 1:1 Year hhid sploc using `spvars', keep(3) nogen

	save "$PROJ_PATH/processed/intermediate/icem/spouse_vars/icem_spouse_`y'.dta", replace

}

* Save each variable to separate file 

clear
forvalues y = `min_year'(10)`max_year' {
    
	// ID variables
	use RecID Year sploc impute_sploc flag_fix_spid sprecid using "$PROJ_PATH/processed/intermediate/icem/spouse_vars/icem_spouse_`y'.dta", clear
	gduplicates drop
	save "$PROJ_PATH/processed/intermediate/icem/spouse_vars/icem_spouse_`y'_identifiers.dta", replace
	
	// Demographic
	use RecID Year spage spmarst using "$PROJ_PATH/processed/intermediate/icem/spouse_vars/icem_spouse_`y'.dta", clear
	gduplicates drop
	save "$PROJ_PATH/processed/intermediate/icem/spouse_vars/icem_spouse_`y'_demographic.dta", replace

	// Occupation
	use RecID Year sphisco spoccode spocc using "$PROJ_PATH/processed/intermediate/icem/spouse_vars/icem_spouse_`y'.dta", clear
	gduplicates drop
	save "$PROJ_PATH/processed/intermediate/icem/spouse_vars/icem_spouse_`y'_occupation.dta", replace

	// Children
	if `y' == 1911 {
		use RecID Year spchilddead spchildalive spym using "$PROJ_PATH/processed/intermediate/icem/spouse_vars/icem_spouse_`y'.dta", clear
		gduplicates drop
		save "$PROJ_PATH/processed/intermediate/icem/spouse_vars/icem_spouse_`y'_childalive.dta", replace
	}
	
	rm "$PROJ_PATH/processed/intermediate/icem/spouse_vars/icem_spouse_`y'.dta"
}

disp "DateTime: $S_DATE $S_TIME"

* EOF
