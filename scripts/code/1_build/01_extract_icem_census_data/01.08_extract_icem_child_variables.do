version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 08_extract_icem_child_variables.do
* PURPOSE: This do file extracts the variables for an individual's children from the I-CeM data
************

*********************************************************************************************************************
*********** I-CeM: Child variables *************
*********************************************************************************************************************

* Create variables for children with link back to fathers

args min_year max_year

forvalues y = `min_year'(10)`max_year' {
	
	use "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_identifiers.dta", clear

	fmerge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_demographic.dta", keep(1 3) nogen keepusing(Age Rela)
	fmerge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_occupation.dta", assert(2 3) keep(3) nogen keepusing(Occ Occode)
	fmerge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`y'_identifiers", keep(1 3) nogen keepusing(poploc poprecid)
	
	rename Rela ic_relate
	rename Occ ic_occ
	rename Occode ic_occode
	
	gen scholar = ( ic_relate == 5500 | ic_relate == 5600 | ///
		regexm(ic_occ,"STUDENT") | regexm(ic_occ,"SCHOLAR") | regexm(ic_occ,"SCHOOL") | ///
		ic_occ == "SCOLAR" | ic_occ == "SCHOLA" | ic_occ == "SCHOLOUR" | ic_occ == "SCHR" | ic_occ == "SCHOL" | ic_occ == "SCH" | ///
		ic_occode == "779" | ic_occode == "780" | ic_occode == "781" | ic_occode == "782" | ic_occode == "783" | ic_occode == "784" | ic_occode == "785" | ic_occode == "786" | ic_occode == "787" ) & ///
		regexm(ic_occ,"MASTER") == 0 & regexm(ic_occ,"MONITOR") == 0 & regexm(ic_occ,"MISTRESS") == 0 & regexm(ic_occ,"TEACHER") == 0 & regexm(ic_occ,"MONITRESS") == 0 & regexm(ic_occ,"UNDER TRAINING") == 0
	drop ic_*
		
	keep if poploc != 0
	bysort poprecid: gen nchild = _N
	
	gegen max_age = max(Age), by(poprecid)
	gen byr_1st_child = `y' - max_age

	gegen ch_scholar = max(scholar), by(poprecid)
	
	keep poprecid nchild byr_1st_child ch_scholar
	gduplicates drop
	
	gen Year = `y'
	order Year poprecid
	
	gunique poprecid
	save "$PROJ_PATH/processed/intermediate/icem/child_vars/icem_child_`y'.dta", replace
	
}

disp "DateTime: $S_DATE $S_TIME"

* EOF
