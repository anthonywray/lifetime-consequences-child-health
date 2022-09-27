version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 06_create_icem_sibling_ids.do
* PURPOSE: This do file creates IDs for siblings in the I-CeM data
************

*********************************************************************************************************************
*********** I-CeM: Extract siblings *************
*********************************************************************************************************************

* Generate sibling variables

args min_year max_year

forvalues y = `min_year'(10)`max_year' {

	use "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_identifiers.dta", clear
	fmerge 1:1 RecID Year using "$PROJ_PATH/processed/intermediate/icem/household_ids/icem_household_ids_`y'.dta", assert(3) nogen keepusing(pid_inf hhid)
	fmerge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_demographic.dta", assert(3) nogen keepusing(Sex Age)
	fmerge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`y'_identifiers.dta", assert(1 3) keep(1 3) nogen keepusing(poploc impute_poploc flag_fix_popid)
	fmerge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/mom_vars/icem_mom_`y'_identifiers.dta", assert(1 3) keep(1 3) nogen keepusing(momloc impute_momloc flag_fix_momid)
	
	recode momloc poploc (mis = 0)

	* Identify siblings
	* (1) Main definition of sibling: share the same mother (either full sibs or uterine sibs)
	gegen mother_only = group(hhid momloc) if momloc != 0

	* (2) Siblings who share only a father
	gegen father_only = group(hhid poploc) if momloc == 0 & poploc != 0

	* Generate sibling type
	gen sib_type = .
	replace sib_type = 1 if mother_only != . & poploc != 0
	replace sib_type = 2 if mother_only != . & poploc == 0
	replace sib_type = 3 if father_only != . & momloc == 0
	replace sib_type = 9 if momloc == 0 & poploc == 0
	label define siblab 1 "Full" 2 "Uterine" 3 "Agnate" 9 "Unknown"
	la val sib_type siblab

	* Generate household identifier from combined groups
	gegen sibling_id = group(mother_only father_only) if momloc != 0 | poploc != 0, missing
	drop mother_only father_only

	* Generate overall birth order and birth order by gender
	gsort + sibling_id - Age + pid_inf 
	egen brthord = seq() if sibling_id != ., by(sibling_id)
	egen mbrthord = seq() if Sex == 1 & sibling_id != ., by(sibling_id)
	egen fbrthord = seq() if Sex == 2 & sibling_id != ., by(sibling_id)

	* Generate sibsize variables
	
	bysort sibling_id: gen sibsize = _N if sibling_id != .
	egen msibsize = total(mbrthord != .) if sibling_id != ., by(sibling_id)
	egen fsibsize = total(fbrthord != .) if sibling_id != ., by(sibling_id)
	
	gsort Year hhid pid_inf
	gen long sortvar = _n
	keeporder sortvar Year RecID sibling_id sib_type brthord mbrthord fbrthord sibsize msibsize fsibsize

	save "$PROJ_PATH/processed/intermediate/icem/sibling_ids/sibling_ids_`y'.dta", replace
}

disp "DateTime: $S_DATE $S_TIME"

* EOF
