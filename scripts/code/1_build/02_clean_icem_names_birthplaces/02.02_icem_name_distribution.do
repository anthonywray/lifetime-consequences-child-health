version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 02.02_icem_name_distribution.do
* PURPOSE: This do file extracts and tabulates the frequencies of given and surnames in the I-CeM data
************

args min_year max_year

forvalues y = `min_year'(10)`max_year' {

	use "$PROJ_PATH/raw/icem_sl/ICEM_Names_EW_`y'.dta", clear
	keep RecID Pname Oname Sname
	recast str Oname
	recast str Sname
	fmerge 1:1 RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_demographic.dta", keepusing(Sex Age) assert(3)
	rename Sex sex
	keep RecID Pname Oname Sname Age sex 
	
	merge m:1 Pname Oname sex using "$PROJ_PATH/processed/intermediate/names/firstnames_`y'.dta", keep(1 3) nogen keepusing(firstname1)
	rename firstname1 namefrst
	bysort namefrst sex: gen fname_count = _N

	gegen min_count = min(fname_count), by(sex)
	gegen max_count = max(fname_count), by(sex)

	gen std_fnamefreq = (fname_count - min_count)/(max_count-min_count)
	drop min_count max_count
	
	fmerge m:1 Sname using "$PROJ_PATH/processed/intermediate/names/surnames_`y'.dta", keep(1 3) nogen keepusing(surname1)
	rename surname1 namelast
	bysort namelast: gen sname_count = _N
	
	gegen min_count = min(sname_count)
	gegen max_count = max(sname_count)

	gen std_snamefreq = (sname_count - min_count)/(max_count-min_count)
	drop min_count max_count
	
	gquantiles fname_count, _pctile percentiles(10 20 30 40 50 60 80 90)

	gen fname_d1 = (fname_count <= r(r1))
	forvalues x = 2(1)9 {
		local z = `x' - 1
		gen fname_d`x' = (fname_count > r(r`z') & fname_count <= r(r`x'))
	}
	gen fname_d10 = (fname_count > r(r9))
		
	gquantiles sname_count, _pctile percentiles(10 20 30 40 50 60 80 90)

	gen sname_d1 = (sname_count <= r(r1))
	forvalues x = 2(1)9 {
		local z = `x' - 1
		gen sname_d`x' = (sname_count > r(r`z') & sname_count <= r(r`x'))
	}
	gen sname_d10 = (sname_count > r(r9))
		
	gen censusyr = `y'
	
	* Restrict to children
	
	keep if Age <= 21
	
	keep RecID censusyr *name_count std_*namefreq *name_d* 
	save "$PROJ_PATH/processed/temp/names_`y'.dta", replace
}

clear
forvalues y = `min_year'(10)`max_year' {
	append using "$PROJ_PATH/processed/temp/names_`y'.dta"
}

gen interact_namefreq = std_fnamefreq*std_snamefreq
recode std_fnamefreq interact_namefreq (mis = 0)

order censusyr RecID
gsort censusyr RecID
rename RecID RecID_child

keep censusyr RecID_child std_fnamefreq interact_namefreq
save "$PROJ_PATH/processed/intermediate/names/icem_name_analysis.dta", replace

forvalues y = `min_year'(10)`max_year' {
	rm "$PROJ_PATH/processed/temp/names_`y'.dta"
}

disp "DateTime: $S_DATE $S_TIME"

* EOF 
