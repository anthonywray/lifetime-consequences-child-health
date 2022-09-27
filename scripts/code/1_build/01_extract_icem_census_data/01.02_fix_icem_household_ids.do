version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 02_fix_icem_household_ids.do
* PURPOSE: Create a new household ID variable since raw variable groups together multiple households
************

*********************************************************************************************************************
*********** I-CeM: Fix Household IDs *************
*********************************************************************************************************************

args min_year max_year

forvalues y = `min_year'(10)`max_year' {
	
	use "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_identifiers.dta", clear
	fmerge 1:1 RecID Year using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_demographic.dta", assert(3) nogen keepusing(Rela)

	tab Rela if pid == 1
	gen head = (Rela == 10 | Rela == 11 | Rela == 12)
	egen total_heads = total(head == 1), by(ParID h)
	tab pid if head == 1
	
	gen long head_start = (pid == 1)
	replace head_start = 1 if pid > 1 & head == 1 & total_heads > 1

	gsort ParID h pid
	gen long hhid = 0
	replace hhid = 1 if _n == 1
	replace hhid = head_start + hhid[_n-1] if _n > 1

	gegen min_pid = min(pid), by(hhid)
	tab min_pid
	gen long pid_inf = pid - min_pid + 1
	drop min_pid
	
	gen flag_fix_pid = (pid != pid_inf)

	gsort hhid pid_inf
	keep RecID Year hhid pid_inf flag_fix_pid
	save "$PROJ_PATH/processed/intermediate/icem/household_ids/icem_household_ids_`y'.dta", replace
}

disp "DateTime: $S_DATE $S_TIME"

* EOF
