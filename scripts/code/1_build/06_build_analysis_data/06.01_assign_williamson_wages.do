version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 06.01_assign_williamson_wages.do
* PURPOSE: This do file merges all HOSP-I-CeM abd I-CeM-I-CeM linked data
************

*********************************************************************************************************************
*********** Assign Williamson Wages *************
*********************************************************************************************************************

// Assign wages to sample

forvalues y = 1881(10)1911 { 

	// Williamson wages in population by occupational class (HISCLASS 12 and HISCLASS 4)

	use hisco Occ Occode using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_occupation.dta", clear

	bysort hisco Occode Occ: gen obs = _N
	gduplicates drop
	merge m:1 hisco using "$PROJ_PATH/processed/intermediate/occupations/hisco_to_hisclass.dta", keep(1 3) nogen keepusing(hisclass)

	destring Occode, replace

	williamson `y'
	
	drop Occ Occode 
	rename hisco ia_hisco
	rename hisclass ia_hisclass
	
	gen pophisclass = ia_hisclass
	gen pophisco = ia_hisco

	keep if wage`y' != . & wage`y' < 1000 // Ignore solicitors and barristers in computing group averages

	* Create 4 group HISCLASS measure
	label define hisc4lab 1 "White Collar" 2 "Skilled" 3 "Semi skilled" 4 "Unskilled", replace
	local hisco_vars "ia_ pop"
	foreach histype of local hisco_vars {
		gen `histype'hisc4 = .
		replace `histype'hisc4 = 1 if `histype'hisclass == 1 | `histype'hisclass == 2 | `histype'hisclass == 3 | `histype'hisclass == 4 | `histype'hisclass == 5
		replace `histype'hisc4 = 2 if `histype'hisclass == 6 | `histype'hisclass == 7 | `histype'hisclass == 8
		replace `histype'hisc4 = 3 if `histype'hisclass == 9
		replace `histype'hisc4 = 4 if `histype'hisclass == 10 | `histype'hisclass == 11 | `histype'hisclass == 12
		la val `histype'hisc4 hisc4lab
	}

	drop if ia_hisclass == .
	
	preserve
	
	egen N = total(obs), by(ia_hisclass pophisclass)
	gen wt = obs/N
	replace wage`y' = wt*wage`y'
	drop N wt

	collapse (sum) avg_wage12_`y' = wage`y', by(ia_hisclass pophisclass)
	count
	list in 1/`r(N)'
	save "$PROJ_PATH/processed/intermediate/occupations/williamson_avg_wage12_`y'.dta", replace
	
	restore
	
	egen N = total(obs), by(ia_hisc4 pophisc4)
	gen wt = obs/N
	replace wage`y' = wt*wage`y'
	drop N wt

	collapse (sum) avg_wage4_`y' = wage`y', by(ia_hisc4 pophisc4)
	list in 1/4
	save "$PROJ_PATH/processed/intermediate/occupations/williamson_avg_wage4_`y'.dta", replace
}
