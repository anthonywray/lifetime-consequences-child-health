version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 02_online_appendix.do
* PURPOSE: This do file runs the regressions to produce all tables and figures in the online appendix
************

// LaTeX table options
local booktabs_default_options "booktabs collabels(none) f gaps label lines substitute(\_ _) star(* 0.1 ** 0.05 *** 0.01)"
local inv_golden_ratio = 2 / ( sqrt(5) + 1 )

// Control variables
local baseline_controls "i.hh_0to5_inf i.hh_0to5_hosp std_fnamefreq interact_namefreq jw_fname_exact jw_sname_exact i.age_adult i.age_adult#i.outcomeyr i.brthord older_sib flag_rbp* bpar_mismatch" 
local scholar_controls "i.hh_0to5_inf i.hh_0to5_hosp std_fnamefreq interact_namefreq jw_fname_exact jw_sname_exact i.age_child i.age_child#i.censusyr i.brthord older_sib"
local disability_controls "i.hh_0to5_inf i.hh_0to5_hosp std_fnamefreq interact_namefreq jw_fname_exact jw_sname_exact i.age_child i.age_child#i.censusyr i.brthord older_sib"

// Sibling fixed effects
local fe "fe cluster(sibling_id)"

// Data sets for single marital status regressions 
local data_1 "$PROJ_PATH/processed/data/table_03_singles_analysis_data_2.dta"
local data_2 "$PROJ_PATH/processed/data/table_03_singles_analysis_data_1.dta"
local data_3 `""$PROJ_PATH/processed/data/table_03_singles_analysis_data_1.dta" if link_10 == 1 | link_20 == 1 | link_30 == 1"'

// Control variables for single marital status regressions 
forvalues n = 1(1)3 {
	if `n' == 1 | `n' == 2 {
		local marital_controls_`n' "i.hh_0to5_inf i.hh_0to5_hosp std_fnamefreq interact_namefreq i.byr_child##i.censusyr i.brthord older_sib"
	}
	else if `n' == 3 {
		local marital_controls_`n' "i.hh_0to5_inf i.hh_0to5_hosp std_fnamefreq interact_namefreq i.byr_child##i.censusyr i.brthord older_sib jw_fname_exact jw_sname_exact flag_rbp_child flag_rbp_adult bpar_mismatch"
	}
}

// Dependent variables
local outcome_vars "mobility_up mobility_dn top_25 top_50 bot_25 ln_wage scholar disab_any disab_any disab_any"
local social_outcomes "nbr_unskilled live_with_parent cty_mover any_child ch_scholar"

tokenize `outcome_vars'

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Calculate standard deviation and median of HDI for hospital population
*********************************************************************************************************************************************
*********************************************************************************************************************************************

use "$PROJ_PATH/processed/data/_hospital_resid_mort_descriptives.dta", clear
sum resid_mort_sigma
local resid_mort_sigma = r(mean)
sum resid_mort_med
local resid_mort_med = r(mean)
sum resid_mort_mu
local resid_mort_mu = r(mean)

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Table A2: Ten most common causes of admission 
*********************************************************************************************************************************************
*********************************************************************************************************************************************

// Male hospital population

use "$PROJ_PATH/processed/data/table_a02.dta" if sex == 1, clear
drop sex coa_pct

sum N 
local N = r(mean)

tempvar totobs deaths
egen `totobs' = total(coa_freq)
egen `deaths' = total(deaths)
sum `deaths'
local deaths = r(max)

gen coa_pct = round(coa_freq*100/`totobs',0.01)

gsort - coa_freq + coa
drop if coa == ""
keep in 1/25
replace coa = proper(coa)

set obs 27
egen tot_freq = total(coa_freq)
egen tot_pct = total(coa_pct)
egen tot_deaths = total(deaths)

replace coa = "Total (top 25)" in 26
replace coa = "Outside top 25" in 27

replace coa_freq = tot_freq in 26
replace coa_pct = tot_pct in 26
replace mr = tot_deaths/tot_freq in 26

replace coa_freq = `N' - tot_freq in 27
replace coa_pct = 100 - tot_pct in 27
replace mr = (`deaths' - tot_deaths)/coa_freq in 27

format coa_pct mr %9.2f

drop tot_*

forvalues n = 1(1)27 {
	preserve
	keep in `n'
	local m_coa`n' = coa
	local m_coa_freq`n' = string(coa_freq,"%9.0fc")
	local m_coa_pct`n' = string(coa_pct,"%9.2f")
	local m_mr`n' = string(mr,"%9.2f")
	restore
}	

// Female hospital population

use "$PROJ_PATH/processed/data/table_a02.dta" if sex == 2, clear
drop sex coa_pct

sum N 
local N = r(mean)

tempvar totobs deaths
egen `totobs' = total(coa_freq)
egen `deaths' = total(deaths)
sum `deaths'
local deaths = r(max)

gen coa_pct = round(coa_freq*100/`totobs',0.01)

gsort - coa_freq + coa
drop if coa == ""
keep in 1/25
replace coa = proper(coa)

set obs 27
egen tot_freq = total(coa_freq)
egen tot_pct = total(coa_pct)
egen tot_deaths = total(deaths)

replace coa = "Total (top 25)" in 26
replace coa = "Outside top 25" in 27

replace coa_freq = tot_freq in 26
replace coa_pct = tot_pct in 26
replace mr = tot_deaths/tot_freq in 26

replace coa_freq = `N' - tot_freq in 27
replace coa_pct = 100 - tot_pct in 27
replace mr = (`deaths' - tot_deaths)/coa_freq in 27

format coa_pct mr %9.2f

drop tot_*

forvalues n = 1(1)27 {
	preserve
	keep in `n'
	local f_coa`n' = coa
	local f_coa_freq`n' = string(coa_freq,"%9.0fc")
	local f_coa_pct`n' = string(coa_pct,"%9.2f")
	local f_mr`n' = string(mr,"%9.2f")
	restore
}	

// In final sample

use "$PROJ_PATH/processed/data/table_a02.dta" if sex == 9, clear
drop sex mr deaths resid_mort

sum N 
local N = r(mean)

gsort - coa_freq + coa
keep in 1/25
replace coa = proper(coa)

set obs 27
egen tot_freq = total(coa_freq)
egen tot_pct = total(coa_pct)

replace coa = "Total (top 25)" in 26
replace coa = "Outside top 25" in 27

replace coa_freq = tot_freq in 26
replace coa_pct = tot_pct in 26

replace coa_freq = `N' - tot_freq in 27
replace coa_pct = 100 - tot_pct in 27
format coa_pct %9.2f

drop tot_freq tot_pct

forvalues n = 1(1)27 {
	preserve
	keep in `n'
	local s_coa`n' = coa
	local s_coa_freq`n' = string(coa_freq,"%9.0fc")
	local s_coa_pct`n' = string(coa_pct,"%9.2f")
	restore
}

capture file close myfile
file open myfile using "$PROJ_PATH/output/02_appendix/table_a02.tex", write text replace 
file write myfile "&\multicolumn{3}{c}{Hospital male population} && &\multicolumn{3}{c}{Hospital female population} && &\multicolumn{2}{c}{LR sample (Males)} \\" _n
file write myfile "\cmidrule(lr){2-4}\cmidrule(lr){7-9}\cmidrule(lr){12-13}" _n
file write myfile "\multicolumn{1}{l}{Cause of admission} & \multicolumn{1}{c}{Frequency} & \multicolumn{1}{c}{Percent} & \multicolumn{1}{c}{Mortality rate} && \multicolumn{1}{l}{Cause of admission} & \multicolumn{1}{c}{Frequency} & \multicolumn{1}{c}{Percent} & \multicolumn{1}{c}{Mortality rate} && \multicolumn{1}{c}{Cause of admission} & \multicolumn{1}{c}{Frequency} & \multicolumn{1}{c}{Percent} \\" _n
file write myfile "\midrule" _n
forvalues n = 1(1)27 {
	if `n' == 26 file write myfile "\addlinespace" _n
	file write myfile "`m_coa`n'' & `m_coa_freq`n'' & `m_coa_pct`n'' & `m_mr`n'' && `f_coa`n'' & `f_coa_freq`n'' & `f_coa_pct`n'' & `f_mr`n'' && `s_coa`n'' & `s_coa_freq`n'' & `s_coa_pct`n'' \\" _n
}
file close myfile

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Table A3: 5 most common occupations in each group in final sample
*********************************************************************************************************************************************
*********************************************************************************************************************************************

use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear

keep ia_occ ia_hisc4
bysort ia_hisc4 ia_occ: gen obs = _N
duplicates drop
gsort + ia_hisc4 - obs
egen order = seq(), by(ia_hisc4)
keep if order <= 5
replace ia_occ = proper(ia_occ)

forvalues i = 1(1)4 {
	forvalues j = 1(1)5 {
		preserve
		keep if ia_hisc4 == `i' & order == `j'
		local c`i'o`j' = ia_occ 
		restore
	}
}
capture file close myfile
file open myfile using "$PROJ_PATH/output/02_appendix/table_a03.tex", write text replace 
file write myfile "&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)} \\" _n
file write myfile "&\multicolumn{1}{c}{White collar} & \multicolumn{1}{c}{Skilled} & \multicolumn{1}{c}{Semi-skilled} & \multicolumn{1}{c}{Unskilled} \\" _n
file write myfile "\cmidrule(lr){2-2}\cmidrule(lr){3-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}" _n
forvalues j = 1(1)5 {
	file write myfile "`j' & \multicolumn{1}{l}{`c1o`j''} & \multicolumn{1}{l}{`c2o`j''} & \multicolumn{1}{l}{`c3o`j''} & \multicolumn{1}{l}{`c4o`j''} \\" _n
}
file close myfile

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Table A4: Scaling by intergenerational transmission of occupational status
*********************************************************************************************************************************************
*********************************************************************************************************************************************

eststo drop *
foreach n of numlist 3 4 6 {
	local m = `n' - 2
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	xtreg ``n'' patient `baseline_controls', `fe'
	matrix b_pat = e(b)
	
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	replace resid_mort = (resid_mort - `resid_mort_mu')/`resid_mort_sigma'
	xtreg ``n'' resid_mort `baseline_controls', `fe'
	matrix b_hosp = e(b)
	
	use "$PROJ_PATH/processed/data/table_a04.dta" if ``n'' != ., clear
	xtset sibling_id
	
	if `n' == 3 {
		gen treatment = popwc
	}
	else if `n' == 4 {
		gen treatment = popsk
	}
	else if `n' == 6 {
		gen treatment = ln_popwage
	}
	
	la var treatment "Father's status"

	eststo t1a`m': reg ``n'' treatment frstbrn sibsize50plus std_fnamefreq interact_namefreq flag_rbp* bpar_mismatch jw_fname_exact jw_sname_exact i.age_adult i.popage, vce(cluster sibling_id) 
	estadd ysumm
	local ymean`m' = string(e(ymean),"%9.3f")
	
	count if e(sample) == 1
	local sample_obs`m' = string(r(N),"%9.0fc")

	matrix b = e(b)
	estadd scalar scaled_mortality1 = abs(b_pat[1,1]*100/b[1,1]) : t1a`m'
	estadd scalar scaled_mortality2 = abs(b_hosp[1,1]*100/b[1,1]) : t1a`m'
	drop treatment
}

capture drop patient
capture drop resid_mort
gen treatment = ""
gen patient = .
gen resid_mort = .
la var treatment "Father's status"
la var patient "Patient"
la var resid_mort "Health deficiency index"

#delimit ;
esttab t1a1 t1a2 t1a4 using "$PROJ_PATH/output/02_appendix/table_a04.tex", replace
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
mgroups("Son's occupational status" "", pattern(1 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 
keep(treatment) mtitles("White collar" "Skilled +" "Log wage") 
legend noconstant nonote lines gaps noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace Mean of Y & `ymean1' & `ymean2' & `ymean4' \\ N &\multicolumn{1}{c}{`sample_obs1'} &\multicolumn{1}{c}{`sample_obs2'} &\multicolumn{1}{c}{`sample_obs4'} \\");
#delimit cr

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Table A5: Occupational transition matrix
*********************************************************************************************************************************************
*********************************************************************************************************************************************

// Mobility table for patients

use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear

count if patient == 1
local big_N = r(N)

forvalues x = 1(1)4 {
	forvalues y = 1(1)4 {
		qui count if pophisc4 == `y' & ia_hisc4 == `x' & patient == 1
		local n_`x'`y' = r(N)
	}
}
forvalues x = 1(1)4 {
	local m_`x'N = `n_`x'1' + `n_`x'2' + `n_`x'3' + `n_`x'4' 
	local m_N`x' = `n_1`x'' + `n_2`x'' + `n_3`x'' + `n_4`x''
}
forvalues x = 1(1)4 {
	forvalues y = 1(1)4 {
		if `n_`x'`y'' == 0 {
			local m_`x'`y' = "0.0"
		}
		else { 
			local m_`x'`y' = string(`n_`x'`y''*100/`m_N`y'',"%9.1f")
		}
	}
}
forvalues x = 1(1)4 {
	local m_`x'T = string(`m_`x'N'*100/`big_N',"%9.1f")
	local m_`x'N = string(`m_`x'N',"%9.0fc")
	local m_N`x' = string(`m_N`x'',"%9.0fc")
}
local big_N = string(`big_N',"%9.0fc")

capture file close myfile
file open myfile using "$PROJ_PATH/output/02_appendix/table_a05.tex", write text replace
file write myfile "&\multicolumn{4}{c}{Father's occupational class} & \multicolumn{1}{c}{Total} & \multicolumn{1}{c}{N} \\" _n
file write myfile"\cmidrule(lr){2-5}" _n
file write myfile"&\multicolumn{1}{c}{White collar} &\multicolumn{1}{c}{Skilled} &\multicolumn{1}{c}{Semi-skilled} & \multicolumn{1}{c}{Unskilled} & & \\" _n
file write myfile "\midrule" _n
file write myfile "&\multicolumn{6}{c}{Panel A: Patients} \\" _n
file write myfile "\multicolumn{1}{l}{White collar} & `m_11' & `m_12' & `m_13' & `m_14' & `m_1T' & \multicolumn{1}{r}{`m_1N'} \\" _n
file write myfile "\multicolumn{1}{l}{Skilled}& `m_21' & `m_22' & `m_23' & `m_24' & `m_2T' & \multicolumn{1}{r}{`m_2N'} \\" _n
file write myfile "\multicolumn{1}{l}{Semi-skilled}& `m_31' & `m_32' & `m_33' & `m_34' & `m_3T' & \multicolumn{1}{r}{`m_3N'} \\" _n
file write myfile "\multicolumn{1}{l}{Unskilled}& `m_41' & `m_42' & `m_43' & `m_44' & `m_4T' & \multicolumn{1}{r}{`m_4N'} \\" _n
file write myfile "\midrule" _n
file write myfile "\multicolumn{1}{l}{N}& \multicolumn{1}{c}{`m_N1'} & \multicolumn{1}{c}{`m_N2'} & \multicolumn{1}{c}{`m_N3'} & \multicolumn{1}{c}{`m_N4'} & \multicolumn{1}{c}{`big_N'} & \\" _n
file close myfile

// Mobility table for siblings

count if patient == 0
local big_N = r(N)

forvalues x = 1(1)4 {
	forvalues y = 1(1)4 {
		qui count if pophisc4 == `y' & ia_hisc4 == `x' & patient == 0
		local n_`x'`y' = r(N)
	}
}
forvalues x = 1(1)4 {
	local m_`x'N = `n_`x'1' + `n_`x'2' + `n_`x'3' + `n_`x'4' 
	local m_N`x' = `n_1`x'' + `n_2`x'' + `n_3`x'' + `n_4`x''
}
forvalues x = 1(1)4 {
	forvalues y = 1(1)4 {
		if `n_`x'`y'' == 0 {
			local m_`x'`y' = "0.0"
		}
		else { 
			local m_`x'`y' = string(`n_`x'`y''*100/`m_N`y'',"%9.1f")
		}
	}
}
forvalues x = 1(1)4 {
	local m_`x'T = string(`m_`x'N'*100/`big_N',"%9.1f")
	local m_`x'N = string(`m_`x'N',"%9.0fc")
	local m_N`x' = string(`m_N`x'',"%9.0fc")
}
local big_N = string(`big_N',"%9.0fc")

file open myfile using "$PROJ_PATH/output/02_appendix/table_a05.tex", write text append
file write myfile "\midrule" _n
file write myfile "&\multicolumn{6}{c}{Panel B: Siblings} \\" _n
file write myfile "\multicolumn{1}{l}{White collar} & `m_11' & `m_12' & `m_13' & `m_14' & `m_1T' & \multicolumn{1}{r}{`m_1N'} \\" _n
file write myfile "\multicolumn{1}{l}{Skilled}& `m_21' & `m_22' & `m_23' & `m_24' & `m_2T' & \multicolumn{1}{r}{`m_2N'} \\" _n
file write myfile "\multicolumn{1}{l}{Semi-skilled}& `m_31' & `m_32' & `m_33' & `m_34' & `m_3T' & \multicolumn{1}{r}{`m_3N'} \\" _n
file write myfile "\multicolumn{1}{l}{Unskilled}& `m_41' & `m_42' & `m_43' & `m_44' & `m_4T' & \multicolumn{1}{r}{`m_4N'} \\" _n
file write myfile "\midrule" _n
file write myfile "\multicolumn{1}{l}{N}& \multicolumn{1}{c}{`m_N1'} & \multicolumn{1}{c}{`m_N2'} & \multicolumn{1}{c}{`m_N3'} & \multicolumn{1}{c}{`m_N4'} & \multicolumn{1}{c}{`big_N'} & \\" _n
file close myfile

// Mobility table for patients and siblings

count
local big_N = r(N)

forvalues x = 1(1)4 {
	forvalues y = 1(1)4 {
		qui count if pophisc4 == `y' & ia_hisc4 == `x'
		local n_`x'`y' = r(N)
	}
}
forvalues x = 1(1)4 {
	local m_`x'N = `n_`x'1' + `n_`x'2' + `n_`x'3' + `n_`x'4' 
	local m_N`x' = `n_1`x'' + `n_2`x'' + `n_3`x'' + `n_4`x''
}
forvalues x = 1(1)4 {
	forvalues y = 1(1)4 {
		if `n_`x'`y'' == 0 {
			local m_`x'`y' = "0.0"
		}
		else { 
			local m_`x'`y' = string(`n_`x'`y''*100/`m_N`y'',"%9.1f")
		}
	}
}
forvalues x = 1(1)4 {
	local m_`x'T = string(`m_`x'N'*100/`big_N',"%9.1f")
	local m_`x'N = string(`m_`x'N',"%9.0fc")
	local m_N`x' = string(`m_N`x'',"%9.0fc")
}
local big_N = string(`big_N',"%9.0fc")

file open myfile using "$PROJ_PATH/output/02_appendix/table_a05.tex", write text append
file write myfile "\midrule" _n
file write myfile "&\multicolumn{6}{c}{Panel C: Patients and siblings} \\" _n
file write myfile "\multicolumn{1}{l}{White collar} & `m_11' & `m_12' & `m_13' & `m_14' & `m_1T' & \multicolumn{1}{r}{`m_1N'} \\" _n
file write myfile "\multicolumn{1}{l}{Skilled}& `m_21' & `m_22' & `m_23' & `m_24' & `m_2T' & \multicolumn{1}{r}{`m_2N'} \\" _n
file write myfile "\multicolumn{1}{l}{Semi-skilled}& `m_31' & `m_32' & `m_33' & `m_34' & `m_3T' & \multicolumn{1}{r}{`m_3N'} \\" _n
file write myfile "\multicolumn{1}{l}{Unskilled}& `m_41' & `m_42' & `m_43' & `m_44' & `m_4T' & \multicolumn{1}{r}{`m_4N'} \\" _n
file write myfile "\midrule" _n
file write myfile "\multicolumn{1}{l}{N}& \multicolumn{1}{c}{`m_N1'} & \multicolumn{1}{c}{`m_N2'} & \multicolumn{1}{c}{`m_N3'} & \multicolumn{1}{c}{`m_N4'} & \multicolumn{1}{c}{`big_N'} & \\" _n
file close myfile

// Mobility table for synthetic population
use "$PROJ_PATH/processed/data/table_a05_panel_04.dta", clear

sum tot_pop
local big_N = r(mean)

forvalues x = 1(1)4 {
	forvalues y = 1(1)4 {
		qui sum count_pop if pophisc4 == `y' & ia_hisc4 == `x'
		local n_`x'`y' = r(mean)
	}
}
forvalues x = 1(1)4 {
	local m_`x'N = `n_`x'1' + `n_`x'2' + `n_`x'3' + `n_`x'4' 
	local m_N`x' = `n_1`x'' + `n_2`x'' + `n_3`x'' + `n_4`x''
}
forvalues x = 1(1)4 {
	forvalues y = 1(1)4 {
		if `n_`x'`y'' == 0 {
			local m_`x'`y' = "0.0"
		}
		else { 
			local m_`x'`y' = string(`n_`x'`y''*100/`m_N`y'',"%9.1f")
		}
	}
}
forvalues x = 1(1)4 {
	local m_`x'T = string(`m_`x'N'*100/`big_N',"%9.1f")
	local m_`x'N = string(`m_`x'N',"%9.0fc")
	local m_N`x' = string(`m_N`x'',"%9.0fc")
}
local big_N = string(`big_N',"%9.0fc")

file open myfile using "$PROJ_PATH/output/02_appendix/table_a05.tex", write text append
file write myfile "\midrule" _n
file write myfile "&\multicolumn{6}{c}{Panel D: Population} \\" _n
file write myfile "\multicolumn{1}{l}{White collar} & `m_11' & `m_12' & `m_13' & `m_14' & `m_1T' & \multicolumn{1}{r}{`m_1N'} \\" _n
file write myfile "\multicolumn{1}{l}{Skilled}& `m_21' & `m_22' & `m_23' & `m_24' & `m_2T' & \multicolumn{1}{r}{`m_2N'} \\" _n
file write myfile "\multicolumn{1}{l}{Semi-skilled}& `m_31' & `m_32' & `m_33' & `m_34' & `m_3T' & \multicolumn{1}{r}{`m_3N'} \\" _n
file write myfile "\multicolumn{1}{l}{Unskilled}& `m_41' & `m_42' & `m_43' & `m_44' & `m_4T' & \multicolumn{1}{r}{`m_4N'} \\" _n
file write myfile "\midrule" _n
file write myfile "\multicolumn{1}{l}{N}& \multicolumn{1}{c}{`m_N1'} & \multicolumn{1}{c}{`m_N2'} & \multicolumn{1}{c}{`m_N3'} & \multicolumn{1}{c}{`m_N4'} & \multicolumn{1}{c}{`big_N'} & \\" _n
file close myfile

********************************************************************************************************************************************
********************************************************************************************************************************************
// Table A6: Social outcomes
********************************************************************************************************************************************
********************************************************************************************************************************************

tokenize `social_outcomes'

eststo drop *
forvalues n = 1(1)5 {

	if `n' <= 4 {
		use "$PROJ_PATH/processed/data/table_a06_col1to4.dta", clear
	}
	else {
		use "$PROJ_PATH/processed/data/table_a06_col5.dta", clear
	}
		
	eststo ta6a`n': xtreg ``n'' patient `baseline_controls', `fe'
	estadd ysumm
	matrix b = e(b)
	estadd scalar pctbeta = abs(b[1,1]*100/e(ymean)): ta6a`n'
	
	eststo ta6b`n': xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm
	matrix b = e(b)
	estadd scalar pctbeta = abs(b[1,1]*`resid_mort_sigma'*100/e(ymean)): ta6b`n'
	
}

#delimit ;
esttab ta6a1 ta6a2 ta6a3 ta6a4 ta6a5 using "$PROJ_PATH/output/02_appendix/table_a06.tex", replace
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
keep(patient) nomtitles
legend noconstant nonote lines gaps noobs star(* 0.1 ** 0.05 *** 0.01)
posthead("
	&\multicolumn{1}{c}{Share unskilled}	&\multicolumn{1}{c}{Living with} &\multicolumn{1}{c}{Moved to}		&\multicolumn{1}{c}{Has any}		&\multicolumn{1}{c}{Child participating}	\\
	&\multicolumn{1}{c}{in neighborhood}	&\multicolumn{1}{c}{a parent}	 &\multicolumn{1}{c}{new county}	&\multicolumn{1}{c}{children}		&\multicolumn{1}{c}{in schooling} 			\\ 
	\midrule
	& \multicolumn{5}{c}{Panel A: Effects of hospital admission} \\ \addlinespace
	")
prefoot("\addlinespace") stats(pctbeta, fmt(%9.1f) labels(`"\% effect"') layout("@"))
postfoot("\addlinespace");

esttab ta6b1 ta6b2 ta6b3 ta6b4 ta6b5 using "$PROJ_PATH/output/02_appendix/table_a06.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
keep(resid_mort) prehead("") posthead("& \multicolumn{5}{c}{Panel B: Effects of health deficiency index} \\ \addlinespace")
legend noconstant nonote lines gaps nomtitles nonum star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace") stats(pctbeta ymean N, fmt(%9.1f %12.3f %9.0fc) labels(`"\% effect ($\sigma$)"' `"Mean of Y"' `"N"') layout("@" "@" "\multicolumn{1}{c}{@}"));
#delimit cr

tokenize `outcome_vars'

********************************************************************************************************************************************
********************************************************************************************************************************************
// Table A7: Heterogeneity by HDI and age-at-admission: Long-run outcomes
********************************************************************************************************************************************
********************************************************************************************************************************************

eststo drop *
use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear

gen resid_m1 = (resid_mort <= `resid_mort_med' & patient == 1)
gen resid_m2 = (resid_mort >  `resid_mort_med' & patient == 1)

la var resid_m1 "Patient $\times$ low-HDI"
la var resid_m2 "Patient $\times$ high-HDI"

gen admit0to4 = ((admitage0 == 1 | admitage1 == 1 | admitage2 == 1 | admitage3 == 1 | admitage4 == 1) & admitage5 == 0 & admitage6 == 0 & admitage7 == 0 & admitage8 == 0 & admitage9 == 0 & admitage10 == 0 & admitage11 == 0)
gen admit5to11 = (admitage0 == 0 & admitage1 == 0 & admitage2 == 0 & admitage3 == 0 & admitage4 == 0 & (admitage5 == 1 | admitage6 == 1 | admitage7 == 1 | admitage8 == 1 | admitage9 == 1 | admitage10 == 1 | admitage11 == 1))

la var admit0to4 "Patient $\times$ [0-4]"
la var admit5to11 "Patient $\times$ [5-11]"

// Restrict to first admissions
replace admit5to11 = 0 if admit0to4 == 1 

foreach n of numlist 1/6 {
	eststo ta7a`n': xtreg ``n'' resid_m1 resid_m2 `baseline_controls', `fe'
	test resid_m1 = resid_m2
	estadd scalar pval = r(p) : ta7a`n'	
	estadd ysumm

	eststo ta7b`n': xtreg ``n'' admit0to4 admit5to11 `baseline_controls', `fe'
	test admit0to4 = admit5to11
	estadd scalar pval = r(p) : ta7b`n'	
	estadd ysumm
}

#delimit ;
esttab ta7a1 ta7a2 ta7a3 ta7a4 ta7a5 ta7a6 using "$PROJ_PATH/output/02_appendix/table_a07.tex", replace
	label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _) 
	keep(resid_m1 resid_m2) mtitles("Class $\nearrow$" "Class $\searrow$" "White collar" "Skilled +" "Unskilled" "Log wage") 
	posthead("\midrule & \multicolumn{6}{c}{Panel A: Interaction with above vs. below median HDI} \\ \addlinespace")
	legend noconstant nonote lines gaps noobs star(* 0.1 ** 0.05 *** 0.01)
	prefoot("\addlinespace") stats(pval, fmt(%12.3f) labels(`"P-value"') layout("@"))
	postfoot("\addlinespace");
esttab ta7b1 ta7b2 ta7b3 ta7b4 ta7b5 ta7b6 using "$PROJ_PATH/output/02_appendix/table_a07.tex", append
	label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _) 
	keep(admit0to4 admit5to11) prehead("") posthead("& \multicolumn{6}{c}{Panel B: Interaction with early (0-4) vs. late (5-11) childhood admission} \\ \addlinespace")
	legend noconstant nonote lines gaps nomtitles nonum star(* 0.1 ** 0.05 *** 0.01)
	prefoot("\addlinespace") stats(pval ymean N, fmt(%12.3f %12.3f %9.0fc) labels(`"P-value"' `"Mean of Y"' `"N"') layout("@" "@" "\multicolumn{1}{c}{@}"))
	postfoot("");
#delimit cr

********************************************************************************************************************************************
********************************************************************************************************************************************
// Table A8: Hospital catchment areas
********************************************************************************************************************************************
********************************************************************************************************************************************

use "$PROJ_PATH/processed/data/table_a08.dta", clear

la var child0to4 "Share age 0 to 4"
la var child5to11 "Share age 5 to 11"
	
eststo ta8c1: estpost sum child0to4 child5to11 sibsize childwmom childwpop popunsk headunsk headmar immigrant if catch_barts == 1
eststo ta8c2: estpost sum child0to4 child5to11 sibsize childwmom childwpop popunsk headunsk headmar immigrant if catch_gosh == 1
eststo ta8c3: estpost sum child0to4 child5to11 sibsize childwmom childwpop popunsk headunsk headmar immigrant if catch_guys == 1
eststo ta8c4: estpost sum child0to4 child5to11 sibsize childwmom childwpop popunsk headunsk headmar immigrant if catch_out == 1

#delimit ;
esttab ta8c1 ta8c2 ta8c3 ta8c4 using "$PROJ_PATH/output/02_appendix/table_a08.tex", replace
booktabs alignment(S) label lines gaps collabels(none) nomtitles noobs f
cells("mean(fmt(3 3 3))")
posthead("& {\multirow{2}{*}{Barts}} & {\multirow{2}{*}{GOSH}} & {\multirow{2}{*}{Guys}} &\multicolumn{1}{c}{Rest of} \\ &&&& \multicolumn{1}{c}{London} \\ \midrule")
stats(N, fmt(%9.0fc) labels(`"Catchment area size (N)"') layout("\multicolumn{1}{c}{@}"));
#delimit cr

********************************************************************************************************************************************
********************************************************************************************************************************************
// Table A9: Selection into hospitalization
********************************************************************************************************************************************
********************************************************************************************************************************************

use "$PROJ_PATH/processed/data/table_a09_a20.dta" if Age <= 5, clear

la var msibsize "Number of male siblings"
la var fsibsize "Number of female siblings"

replace catch_gosh = 0 if catch_barts == 1
replace patient_match = patient_match*100

eststo c1: reg patient_match catch_barts catch_gosh catch_guys sibsize pop_sk pop_semisk pop_unsk i.popage##i.Year i.Age##i.Year if Sex == 1 & popage >= 21 & popage <= 50 & pophisclass != ., robust
estadd ysumm
estadd local cc "Yes": c1
estadd local dfe "No" : c1
estadd local pfe "No" : c1

xtset distid

eststo c2: xtreg patient_match sibsize pop_sk pop_semisk pop_unsk i.popage##i.Year i.Age##i.Year if Sex == 1 & popage >= 21 & popage <= 50 & pophisclass != ., fe vce(robust)
estadd ysumm
estadd local cc "No": c2
estadd local dfe "Yes" : c2
estadd local pfe "No" : c2

xtset par_id

eststo c3: xtreg patient_match sibsize pop_sk pop_semisk pop_unsk i.popage##i.Year i.Age##i.Year if Sex == 1 & popage >= 21 & popage <= 50 & pophisclass != ., fe vce(robust)
estadd ysumm
estadd local cc "No": c3
estadd local dfe "No" : c3
estadd local pfe "Yes" : c3

#delimit ;
esttab c1 c2 c3 using "$PROJ_PATH/output/02_appendix/table_a09.tex", replace
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f
keep(pop_sk pop_semisk pop_unsk)
legend noconstant nonote lines gaps nomtitles star(* 0.1 ** 0.05 *** 0.01) noobs
mgroups("Observed in hospital records [$\times$ 100]", pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
stats(ymean cc dfe pfe N, fmt(3 0 0 0 %9.0fc) labels(`"Mean of Y"' `"Catchment controls"' `"District FE"' `"Parish FE"' `"N"') layout("@" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}"));
#delimit cr

********************************************************************************************************************************************
********************************************************************************************************************************************
// Table A10: Weighting households in regressions by hospital patient population
********************************************************************************************************************************************
********************************************************************************************************************************************

eststo drop *

foreach n of numlist 1/10 {	

	if `n' == 7 {
		use "$PROJ_PATH/processed/data/table_a10_col`n'.dta", clear
		eststo ta10a7: xtreg scholar patient `scholar_controls' [pw = weight], `fe'
		estadd ysumm
		matrix b = e(b)
		estadd scalar pctbeta = abs(b[1,1]*100/e(ymean)) : ta10a7

		eststo ta10b7: xtreg scholar resid_mort `scholar_controls' [pw = weight], `fe'
		estadd ysumm
		matrix b = e(b)
		estadd scalar pctbeta = abs(b[1,1]*`resid_mort_sigma'*100/e(ymean)) : ta10b7
	}
	else if `n' == 8 | `n' == 9 {
		use "$PROJ_PATH/processed/data/table_a10_col`n'.dta", clear
		eststo ta10a`n': xtreg disab_any patient `disability_controls' [pw = weight], `fe'
		estadd ysumm
		matrix b = e(b)
		estadd scalar pctbeta = abs(b[1,1]*100/e(ymean)) : ta10a`n'

		eststo ta10b`n': xtreg disab_any resid_mort `disability_controls' [pw = weight], `fe'
		estadd ysumm
		matrix b = e(b)
		estadd scalar pctbeta = abs(b[1,1]*`resid_mort_sigma'*100/e(ymean)) : ta10b`n'
	}
	else {
		
		if `n' == 10 {
			use "$PROJ_PATH/processed/data/table_a10_col`n'.dta", clear
		}
		else {
			use "$PROJ_PATH/processed/data/table_a10_col1to6.dta", clear
		}
		eststo ta10a`n': xtreg ``n'' patient `baseline_controls' [pw = weight], `fe'
		estadd ysumm
		matrix b = e(b)
		if `n' <= 5 | `n' == 10 {
			estadd scalar pctbeta = abs(b[1,1]*100/e(ymean)): ta10a`n'
		}
		else if `n' == 6 {
			estadd scalar pctbeta = 100*abs(exp(b[1,1]) - 1): ta10a`n'
		}		
		eststo ta10b`n': xtreg ``n'' resid_mort `baseline_controls' [pw = weight], `fe'
		estadd ysumm
		matrix b = e(b)
		if `n' <= 5 | `n' == 10 {
			estadd scalar pctbeta = abs(b[1,1]*`resid_mort_sigma'*100/e(ymean)): ta10b`n'
		}
		else if `n' == 6 {
			estadd scalar pctbeta = 100*abs(exp(b[1,1]*`resid_mort_sigma') - 1): ta10b`n'
		}
	}
}

#delimit ;
esttab ta10a1 ta10a2 ta10a3 ta10a4 ta10a5 ta10a6 ta10a7 ta10a8 ta10a9 ta10a10 using "$PROJ_PATH/output/02_appendix/table_a10.tex", replace
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
mgroups("Occupational" "Schooling" "Disability", pattern(1 0 0 0 0 0 1 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) 
keep(patient) mtitles("Class $\nearrow$" "Class $\searrow$" "White collar" "Skilled +" "Unskilled" "Log wage" "Participation" "Pre-existing" "Childhood" "Long-run") 
posthead("\midrule & \multicolumn{10}{c}{Panel A: Effects of hospital admission} \\ \addlinespace")
legend noconstant nonote lines gaps noobs star(* 0.1 ** 0.05 *** 0.01) 
prefoot("\addlinespace") stats(pctbeta, fmt(%9.1f) labels(`"\% effect"') layout("@"))
postfoot("\addlinespace");

esttab ta10b1 ta10b2 ta10b3 ta10b4 ta10b5 ta10b6 ta10b7 ta10b8 ta10b9 ta10b10 using "$PROJ_PATH/output/02_appendix/table_a10.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _) 
keep(resid_mort) prehead("") posthead("& \multicolumn{10}{c}{Panel B: Effects of health deficiency index} \\ \addlinespace") 
legend noconstant nonote lines gaps nomtitles nonum star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(pctbeta ymean N, fmt(%9.1f %12.3f %9.0fc) labels(`"\% effect ($\sigma$)"' `"Mean of Y"' `"N"') layout("@" "@" "\multicolumn{1}{c}{@}"));
#delimit cr

*********************************************************************************************************
*********************************************************************************************************
// Table A11: Single marital status - weighting households by hospital patient population
*********************************************************************************************************
*********************************************************************************************************
eststo drop *

forvalues n = 1(1)3 {

	use "$PROJ_PATH/processed/data/table_a11_col`n'.dta", clear
	
	eststo t1a`n': xtreg single patient `marital_controls_`n'' [pw = weight], `fe'
	estadd ysumm
	matrix b = e(b)
	estadd scalar pctbeta = abs(b[1,1]*100/e(ymean)): t1a`n'

	eststo t1b`n': xtreg single resid_mort `marital_controls_`n'' [pw = weight], `fe'
	estadd ysumm
	matrix b = e(b)
	estadd scalar pctbeta = abs(b[1,1]*`resid_mort_sigma'*100/e(ymean)): t1b`n'
	
}

#delimit ;
esttab t1a1 t1a2 t1a3 using "$PROJ_PATH/output/02_appendix/table_a11.tex", replace
	label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
	mgroups("Baseline sample" "Linked only", pattern(1 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
	keep(patient) mtitles("Women" "Men" "Men")
	prehead("& \multicolumn{3}{c}{Dependent variable: =1 if ever single at ages 18+} \\ \cmidrule(lr){2-4}")
	posthead("\midrule & \multicolumn{3}{c}{Panel A: Effects of hospital admission} \\ \addlinespace")
	legend noconstant nonote lines gaps noobs star(* 0.1 ** 0.05 *** 0.01) 
	prefoot("\addlinespace") stats(pctbeta, fmt(%9.1f) labels(`"\% effect"') layout("@"))
	postfoot("\addlinespace");

esttab t1b1 t1b2 t1b3 using "$PROJ_PATH/output/02_appendix/table_a11.tex", append
	label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _) 
	keep(resid_mort) prehead("") posthead("& \multicolumn{3}{c}{Panel B: Effects of health deficiency index} \\ \addlinespace") 
	legend noconstant nonote lines gaps nomtitles nonum star(* 0.1 ** 0.05 *** 0.01)
	prefoot("\addlinespace")
	stats(pctbeta ymean N, fmt(%9.1f %12.3f %9.0fc) labels(`"\% effect ($\sigma$)"' `"Mean of Y"' `"N"') layout("@" "@" "\multicolumn{1}{c}{@}"));
#delimit cr

*********************************************************************************************************
*********************************************************************************************************
// Table A12: Robustness, selective mortality, occupational outcomes
*********************************************************************************************************
*********************************************************************************************************

eststo drop *
foreach n of numlist 1/6 {

	* Baseline estimates

	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	eststo ta12p`n'c0: xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm

	* Drop high mortality conditions
	
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	sum resid_mort if patient == 1, detail
	local cut10 = r(p10)
	local cut90 = r(p90)
	
	gen top10_mort = (resid_mort >= `cut90' & patient == 1)
	egen total_top10 = total(top10_mort == 1), by(sibling_id)
	drop if total_top10 > 0
	drop total_top10 top10_mort 

	eststo ta12p`n'c1: xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm
	
	* Drop infant admissions
	
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	keep if admitage0 != 1 & admitage1 != 1
	bysort sibling_id: keep if _N == 2
	
	eststo ta12p`n'c2: xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm
	
	* Drop multiple admissions
	
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	drop if tot_visits > 1 & patient == 1
	bysort sibling_id: keep if _N == 2
	
	eststo ta12p`n'c3: xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm
	
	* Drop low mortality conditions
	
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	sum resid_mort if patient == 1, detail
	local cut10 = r(p10)
	local cut90 = r(p90)
	
	gen bot10_mort = (resid_mort <= `cut10' & patient == 1)
	egen total_bot10 = total(bot10_mort == 1), by(sibling_id)
	drop if total_bot10 > 0
	drop total_bot10 bot10_mort 

	eststo ta12p`n'c4: xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm
	
	* Drop contagious diseases
	
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	keep if contagious != 1
	bysort sibling_id: keep if _N == 2
	
	eststo ta12p`n'c5: xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm
	
}

#delimit ;
esttab ta12p1c0 ta12p1c1 ta12p1c2 ta12p1c3 ta12p1c4 ta12p1c5 using "$PROJ_PATH/output/02_appendix/table_a12.tex", replace
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _) 
keep(resid_mort) 
	posthead("
		&\multicolumn{1}{c}{Baseline}	&\multicolumn{1}{c}{Drop high}	&\multicolumn{1}{c}{Drop infant}	&\multicolumn{1}{c}{Drop multiple}	&\multicolumn{1}{c}{Drop low}	&\multicolumn{1}{c}{Drop}		\\
		&\multicolumn{1}{c}{estimate}	&\multicolumn{1}{c}{mortality}	&\multicolumn{1}{c}{admission}		&\multicolumn{1}{c}{admissions} 	&\multicolumn{1}{c}{mortality}	&\multicolumn{1}{c}{contagious} \\ 
		\midrule
		& \multicolumn{6}{c}{Panel A: Effects on P(\text{Class $\nearrow$})} \\ \addlinespace
		")
legend noconstant nonote lines gaps nomtitles noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab ta12p2c0 ta12p2c1 ta12p2c2 ta12p2c3 ta12p2c4 ta12p2c5 using "$PROJ_PATH/output/02_appendix/table_a12.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _) 
keep(resid_mort) prehead("") posthead("& \multicolumn{6}{c}{Panel B: Effects on P(\text{Class $\searrow$})} \\ \addlinespace")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab ta12p3c0 ta12p3c1 ta12p3c2 ta12p3c3 ta12p3c4 ta12p3c5 using "$PROJ_PATH/output/02_appendix/table_a12.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _) 
keep(resid_mort) prehead("") posthead("& \multicolumn{6}{c}{Panel C: Effects on P(\text{White collar})} \\ \addlinespace")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab ta12p4c0 ta12p4c1 ta12p4c2 ta12p4c3 ta12p4c4 ta12p4c5 using "$PROJ_PATH/output/02_appendix/table_a12.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _) 
keep(resid_mort) prehead("") posthead("& \multicolumn{6}{c}{Panel D: Effects on P(\text{Skilled +})} \\ \addlinespace")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab ta12p5c0 ta12p5c1 ta12p5c2 ta12p5c3 ta12p5c4 ta12p5c5 using "$PROJ_PATH/output/02_appendix/table_a12.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _) 
keep(resid_mort) prehead("") posthead("& \multicolumn{6}{c}{Panel E: Effects on P(\text{Unskilled})} \\ \addlinespace")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab ta12p6c0 ta12p6c1 ta12p6c2 ta12p6c3 ta12p6c4 ta12p6c5 using "$PROJ_PATH/output/02_appendix/table_a12.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _) 
keep(resid_mort) prehead("") posthead("& \multicolumn{6}{c}{Panel F: Effects on log occupational wage} \\ \addlinespace")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"));
#delimit cr

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Table A13: Robustness, sample restrictions, occupational outcomes
*********************************************************************************************************************************************
*********************************************************************************************************************************************

eststo drop *
foreach n of numlist 1/6 {

	* Baseline estimates
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	eststo ta13p`n'c0: xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm

	* Add multiple siblings
	use "$PROJ_PATH/processed/data/table_06_col_02.dta", clear 
	eststo ta13p`n'c1: xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm
	
	* Add multiple patient hhlds.
	use "$PROJ_PATH/processed/data/table_06_col_03.dta", clear
	eststo ta13p`n'c2: xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm

	* Restrict to patients residing in Greater London at the time of admission
	use "$PROJ_PATH/processed/data/table_06_col_04.dta", clear
	eststo ta13p`n'c3: xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm

	* Drop Guy's patients
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	keep if hosp_guys == 0
	bysort sibling_id: keep if _N == 2
	eststo ta13p`n'c4: xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm
	
	* Restrict to unique within census county
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	keep if nodist_match == 1
	bysort sibling_id: keep if _N == 2
	eststo ta13p`n'c5: xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm

	* Further restrict to county match from hospital to census
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	keep if nodist_match == 1 & rescty_match == 1
	bysort sibling_id: keep if _N == 2
	eststo ta13p`n'c6: xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm
}

#delimit ;
esttab ta13p1c0 ta13p1c1 ta13p1c2 ta13p1c3 ta13p1c4 ta13p1c5 ta13p1c6 using "$PROJ_PATH/output/02_appendix/table_a13.tex", replace
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _) 
keep(resid_mort) 
	posthead("
		&\multicolumn{1}{c}{Baseline}	&\multicolumn{1}{c}{Add multiple}	&\multicolumn{1}{c}{Add multiple}	&\multicolumn{1}{c}{County of}	&\multicolumn{1}{c}{Drop Guy's}	&\multicolumn{1}{c}{Unique within}	&\multicolumn{1}{c}{Hospital-census} \\
		&\multicolumn{1}{c}{estimate}	&\multicolumn{1}{c}{siblings}		&\multicolumn{1}{c}{patient hhlds.}	&\multicolumn{1}{c}{London only}&\multicolumn{1}{c}{Hospital}	&\multicolumn{1}{c}{census county} 	&\multicolumn{1}{c}{county match} 	 \\ 
		\midrule
		& \multicolumn{7}{c}{Panel A: Effects on P(\text{Class $\nearrow$})} \\ \addlinespace
		")
legend noconstant nonote lines gaps nomtitles noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab ta13p2c0 ta13p2c1 ta13p2c2 ta13p2c3 ta13p2c4 ta13p2c5 ta13p2c6 using "$PROJ_PATH/output/02_appendix/table_a13.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _) 
keep(resid_mort) prehead("") posthead("& \multicolumn{7}{c}{Panel B: Effects on P(\text{Class $\searrow$})} \\ \addlinespace")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab ta13p3c0 ta13p3c1 ta13p3c2 ta13p3c3 ta13p3c4 ta13p3c5 ta13p3c6 using "$PROJ_PATH/output/02_appendix/table_a13.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _) 
keep(resid_mort) prehead("") posthead("& \multicolumn{7}{c}{Panel C: Effects on P(\text{White collar})} \\ \addlinespace")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"))
postfoot("\midrule");

esttab ta13p4c0 ta13p4c1 ta13p4c2 ta13p4c3 ta13p4c4 ta13p4c5 ta13p4c6 using "$PROJ_PATH/output/02_appendix/table_a13.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _) 
keep(resid_mort) prehead("") posthead("& \multicolumn{7}{c}{Panel D: Effects on P(\text{Skilled +})} \\ \addlinespace")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab ta13p5c0 ta13p5c1 ta13p5c2 ta13p5c3 ta13p5c4 ta13p5c5 ta13p5c6 using "$PROJ_PATH/output/02_appendix/table_a13.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _) 
keep(resid_mort) prehead("") posthead("& \multicolumn{7}{c}{Panel E: Effects on P(\text{Unskilled})} \\ \addlinespace")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab ta13p6c0 ta13p6c1 ta13p6c2 ta13p6c3 ta13p6c4 ta13p6c5 ta13p6c6 using "$PROJ_PATH/output/02_appendix/table_a13.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _) 
keep(resid_mort) prehead("") posthead("& \multicolumn{7}{c}{Panel F: Effects on log occupational wage} \\ \addlinespace")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"));
#delimit cr

********************************************************************************************************************************************
********************************************************************************************************************************************
// Table A14: Robustness, occupational status
********************************************************************************************************************************************
********************************************************************************************************************************************

eststo drop *
foreach n of numlist 1/5 {

	* Column 1: Baseline estimates
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear	
	eststo ta14p`n'c0: xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm
	
	* Column 2: Use highest occupation among father, mother and HH head for child SES
	use "$PROJ_PATH/processed/data/table_07_col_02.dta", clear
	eststo ta14p`n'c1: xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm
	
	* Column 3: Use mother's occupation and then HH head's occupation if father's occupation is missing
	use "$PROJ_PATH/processed/data/table_07_col_03.dta", clear
	eststo ta14p`n'c2: xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm
	
	* Column 4: Recode missing occupation as worst occupation
	use "$PROJ_PATH/processed/data/table_07_col_04.dta", clear
	eststo ta14p`n'c3: xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm
	
	* Column 5: Recode missing occupation as best occupation
	use "$PROJ_PATH/processed/data/table_07_col_05.dta", clear
	eststo ta14p`n'c4: xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm
	
}

#delimit ;
esttab ta14p1c0 ta14p1c1 ta14p1c2 ta14p1c3 ta14p1c4 using "$PROJ_PATH/output/02_appendix/table_a14.tex", `booktabs_default_options' replace
keep(resid_mort) b(%12.3f) se(%12.3f) nomtitles 
	posthead("
		&\multicolumn{1}{c}{Baseline}	&\multicolumn{1}{c}{Highest}		&\multicolumn{1}{c}{Impute}			&\multicolumn{1}{c}{High class}		&\multicolumn{1}{c}{Low class}		\\
		&\multicolumn{1}{c}{estimate}	&\multicolumn{1}{c}{household SES}	&\multicolumn{1}{c}{household SES}	&\multicolumn{1}{c}{if missing}		&\multicolumn{1}{c}{if missing} 	\\ 
		\midrule
		& \multicolumn{5}{c}{Panel A: Effects on P(\text{Class $\nearrow$})} \\ \addlinespace
		")
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab ta14p2c0 ta14p2c1 ta14p2c2 ta14p2c3 ta14p2c4 using "$PROJ_PATH/output/02_appendix/table_a14.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{5}{c}{Panel B: Effects on P(\text{Class $\searrow$})} \\ \addlinespace") nomtitles nonum
keep(resid_mort) b(%12.3f) se(%12.3f)
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab ta14p3c0 ta14p3c1 ta14p3c2 ta14p3c3 ta14p3c4 using "$PROJ_PATH/output/02_appendix/table_a14.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{5}{c}{Panel C: Effects on P(\text{White collar})} \\ \addlinespace") nomtitles nonum
keep(resid_mort) b(%12.3f) se(%12.3f) 
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab ta14p4c0 ta14p4c1 ta14p4c2 ta14p4c3 ta14p4c4 using "$PROJ_PATH/output/02_appendix/table_a14.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{5}{c}{Panel D: Effects on P(\text{Skilled +})} \\ \addlinespace") nomtitles nonum
keep(resid_mort) b(%12.3f) se(%12.3f)
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab ta14p5c0 ta14p5c1 ta14p5c2 ta14p5c3 ta14p5c4 using "$PROJ_PATH/output/02_appendix/table_a14.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{5}{c}{Panel E: Effects on P(\text{Unskilled})} \\ \addlinespace") nomtitles nonum
keep(resid_mort) b(%12.3f) se(%12.3f)
prefoot("\addlinespace")
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"));
#delimit cr

********************************************************************************************************************************************
********************************************************************************************************************************************
// Table A15: Long-run marital status for men and women
********************************************************************************************************************************************
********************************************************************************************************************************************

eststo drop *
forvalues n = 1(1)3 {

	* Drop high mortality conditions
	use `data_`n'', clear 
	keep if main_marital_sample == 1
	
	sum resid_mort if patient == 1, d
	local cut10 = r(p10)
	local cut90 = r(p90)

	gen top10_mort = (resid_mort >= `cut90' & patient == 1)
	egen total_top10 = total(top10_mort == 1), by(sibling_id)
	drop if total_top10 > 0
	drop total_top10 top10_mort
	
	bysort sibling_id: keep if _N == 2
	
	single_reg, panel(`n') col(1) control_list(`marital_controls_`n'') clustervar(sibling_id) sigma(`resid_mort_sigma')


	* Drop infant admissions
	use `data_`n'', clear 
	keep if main_marital_sample == 1
	
	keep if admitage0 != 1 & admitage1 != 1
	bysort sibling_id: keep if _N == 2

	single_reg, panel(`n') col(2) control_list(`marital_controls_`n'') clustervar(sibling_id) sigma(`resid_mort_sigma')


	* Drop multiple admissions
	use `data_`n'', clear 
	keep if main_marital_sample == 1
	
	drop if tot_visits > 1 & patient == 1
	bysort sibling_id: keep if _N == 2
	
	single_reg, panel(`n') col(3) control_list(`marital_controls_`n'') clustervar(sibling_id) sigma(`resid_mort_sigma')


	* Drop low mortality conditions
	use `data_`n'', clear 
	keep if main_marital_sample == 1
	
	sum resid_mort if patient == 1, d
	local cut10 = r(p10)
	local cut90 = r(p90)

	gen bot10_mort = (resid_mort <= `cut10' & patient == 1)
	egen total_bot10 = total(bot10_mort == 1), by(sibling_id)
	drop if total_bot10 > 0
	drop total_bot10 bot10_mort 

	bysort sibling_id: keep if _N == 2
	
	single_reg, panel(`n') col(4) control_list(`marital_controls_`n'') clustervar(sibling_id) sigma(`resid_mort_sigma')
	
	
	* Drop contagious diseases
	use `data_`n'', clear 
	keep if main_marital_sample == 1
	
	keep if contagious != 1
	bysort sibling_id: keep if _N == 2
		
	single_reg, panel(`n') col(5) control_list(`marital_controls_`n'') clustervar(sibling_id) sigma(`resid_mort_sigma')
		

	* Add multiple siblings
	use `data_`n'', clear 
	keep if mult_pat_hh == 0
	
	cap drop older_sib
	egen first_sib = min(brthord), by(sibling_id)
	gen older_sib = (brthord == first_sib)
	drop first_sib
	
	egen tot_pat = total(patient == 1), by(sibling_id)
	egen tot_sib = total(patient == 0), by(sibling_id)
	
	drop if tot_pat == 0 | tot_sib == 0
	
	single_reg, panel(`n') col(6) control_list(`marital_controls_`n'') clustervar(sibling_id) sigma(`resid_mort_sigma')

	
	* Add multiple patient hhlds.
	use `data_`n'', clear 
	
	egen tot_pat = total(patient == 1), by(sibling_id)
	egen tot_sib = total(patient == 0), by(sibling_id)
	
	drop if tot_pat == 0 | tot_sib == 0
	
	single_reg, panel(`n') col(7) control_list(`marital_controls_`n'') clustervar(sibling_id) sigma(`resid_mort_sigma')

	* Restrict to patients residing in Greater London at the time of admission
	use "$PROJ_PATH/processed/data/table_a15_col8_`n'.dta", clear

	single_reg, panel(`n') col(8) control_list(`marital_controls_`n'') clustervar(sibling_id) sigma(`resid_mort_sigma')

	* Drop Guy's patients
	use `data_`n'', clear 
	keep if main_marital_sample == 1

	tab hosp_guys
	keep if hosp_guys == 0
	bysort sibling_id: keep if _N == 2

	single_reg, panel(`n') col(9) control_list(`marital_controls_`n'') clustervar(sibling_id) sigma(`resid_mort_sigma')

	* Restrict to unique within county
	use `data_`n'', clear 
	keep if main_marital_sample == 1
	
	keep if nodist_match == 1
	bysort sibling_id: keep if _N == 2

	single_reg, panel(`n') col(10) control_list(`marital_controls_`n'') clustervar(sibling_id) sigma(`resid_mort_sigma')


	* Restrict to hospital-census county of residence match
	use `data_`n'', clear 
	keep if main_marital_sample == 1
	
	keep if nodist_match == 1 & rescty_match == 1
	bysort sibling_id: keep if _N == 2

	single_reg, panel(`n') col(11) control_list(`marital_controls_`n'') clustervar(sibling_id) sigma(`resid_mort_sigma')

}

#delimit ;

esttab p1r1c1 p1r1c2 p1r1c3 p1r1c4 p1r1c5 p1r1c6 p1r1c7 p1r1c8 p1r1c9 p1r1c10 p1r1c11 using "$PROJ_PATH/output/02_appendix/table_a15.tex", `booktabs_default_options' replace
keep(patient) b(%12.3f) se(%12.3f) nomtitles noobs prehead("")
	posthead("
		&\multicolumn{1}{c}{Drop high}	&\multicolumn{1}{c}{Drop infant}	&\multicolumn{1}{c}{Drop multiple}	&\multicolumn{1}{c}{Drop low}	&\multicolumn{1}{c}{Drop}		&\multicolumn{1}{c}{Add multiple}	&\multicolumn{1}{c}{Add multiple}	&\multicolumn{1}{c}{County of}	&\multicolumn{1}{c}{Drop Guy's}	&\multicolumn{1}{c}{Unique within}	&\multicolumn{1}{c}{Hospital-census}	\\
		&\multicolumn{1}{c}{mortality}	&\multicolumn{1}{c}{admission}		&\multicolumn{1}{c}{admissions} 	&\multicolumn{1}{c}{mortality}	&\multicolumn{1}{c}{contagious} &\multicolumn{1}{c}{siblings}		&\multicolumn{1}{c}{patient hhlds.}	&\multicolumn{1}{c}{London only}&\multicolumn{1}{c}{Hospital}	&\multicolumn{1}{c}{census county} 	&\multicolumn{1}{c}{county match} 		\\ 
		\midrule
		& \multicolumn{11}{c}{Panel A: Effects on P(Ever single marital status) for women in baseline sample} \\ \addlinespace
		")
prefoot("") postfoot("\addlinespace");

esttab p1r2c1 p1r2c2 p1r2c3 p1r2c4 p1r2c5 p1r2c6 p1r2c7 p1r2c8 p1r2c9 p1r2c10 p1r2c11 using "$PROJ_PATH/output/02_appendix/table_a15.tex", `booktabs_default_options' append
keep(resid_mort) b(%12.3f) se(%12.3f) nomtitles nonum prehead("") posthead("")
prefoot("\addlinespace")
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"))
postfoot("\midrule");

esttab p2r1c1 p2r1c2 p2r1c3 p2r1c4 p2r1c5 p2r1c6 p2r1c7 p2r1c8 p2r1c9 p2r1c10 p2r1c11 using "$PROJ_PATH/output/02_appendix/table_a15.tex", `booktabs_default_options' append
keep(patient) b(%12.3f) se(%12.3f) nomtitles nonum noobs prehead("")
posthead("& \multicolumn{11}{c}{Panel B: Effects on P(Ever single marital status) for men in baseline sample} \\ \addlinespace")
prefoot("") postfoot("\addlinespace");

esttab p2r2c1 p2r2c2 p2r2c3 p2r2c4 p2r2c5 p2r2c6 p2r2c7 p2r2c8 p2r2c9 p2r2c10 p2r2c11 using "$PROJ_PATH/output/02_appendix/table_a15.tex", `booktabs_default_options' append
keep(resid_mort) b(%12.3f) se(%12.3f) nomtitles nonum prehead("") posthead("")
prefoot("\addlinespace")
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"))
postfoot("\midrule");

esttab p3r1c1 p3r1c2 p3r1c3 p3r1c4 p3r1c5 p3r1c6 p3r1c7 p3r1c8 p3r1c9 p3r1c10 p3r1c11 using "$PROJ_PATH/output/02_appendix/table_a15.tex", `booktabs_default_options' append
keep(patient) b(%12.3f) se(%12.3f) nomtitles nonum noobs prehead("")
posthead("& \multicolumn{11}{c}{Panel C: Effects on P(Ever single marital status) for men in linked sample} \\ \addlinespace")
prefoot("") postfoot("\addlinespace");

esttab p3r2c1 p3r2c2 p3r2c3 p3r2c4 p3r2c5 p3r2c6 p3r2c7 p3r2c8 p3r2c9 p3r2c10 p3r2c11 using "$PROJ_PATH/output/02_appendix/table_a15.tex", `booktabs_default_options' append
keep(resid_mort) b(%12.3f) se(%12.3f) nomtitles nonum prehead("") posthead("")
prefoot("\addlinespace")
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"))
postfoot("");

#delimit cr

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Table A16: Robustness for schooling outcome
*********************************************************************************************************************************************
*********************************************************************************************************************************************

* Column 1: Baseline 
use "$PROJ_PATH/processed/data/table_04_schooling_analysis_data.dta", clear

eststo ta16c1p1: xtreg scholar patient `scholar_controls', `fe'
estadd ysumm
eststo ta16c1p2: xtreg scholar resid_mort `scholar_controls', `fe'
estadd ysumm

// Panel A: Selective Mortality and Scarring

* Column 2: Drop high mortality
use "$PROJ_PATH/processed/data/table_04_schooling_analysis_data.dta", clear

sum resid_mort if patient == 1, detail
local cut10 = r(p10)
local cut90 = r(p90)

gen top10_mort = (resid_mort >= `cut90' & patient == 1)
egen total_top10 = total(top10_mort == 1), by(sibling_id)
drop if total_top10 > 0
drop total_top10 top10_mort

eststo ta16c2p1: xtreg scholar patient `scholar_controls', `fe'
estadd ysumm
eststo ta16c2p2: xtreg scholar resid_mort `scholar_controls', `fe'
estadd ysumm
	
* Column 3: Drop infant admissions
use "$PROJ_PATH/processed/data/table_04_schooling_analysis_data.dta", clear

keep if admitage0 != 1 & admitage1 != 1
bysort sibling_id: keep if _N == 2

eststo ta16c3p1: xtreg scholar patient `scholar_controls', `fe'
estadd ysumm
eststo ta16c3p2: xtreg scholar resid_mort `scholar_controls', `fe'
estadd ysumm

* Column 4: Drop multiple admissions
use "$PROJ_PATH/processed/data/table_04_schooling_analysis_data.dta", clear
drop if tot_visits > 1 & patient == 1
bysort sibling_id: keep if _N == 2

eststo ta16c4p1: xtreg scholar patient `scholar_controls', `fe'
estadd ysumm
eststo ta16c4p2: xtreg scholar resid_mort `scholar_controls', `fe'
estadd ysumm

* Column 5: Drop low mortality
use "$PROJ_PATH/processed/data/table_04_schooling_analysis_data.dta", clear

gen bot10_mort = (resid_mort <= `cut10' & patient == 1)
egen total_bot10 = total(bot10_mort == 1), by(sibling_id)
drop if total_bot10 > 0
drop total_bot10 bot10_mort 

eststo ta16c5p1: xtreg scholar patient `scholar_controls', `fe'
estadd ysumm
eststo ta16c5p2: xtreg scholar resid_mort `scholar_controls', `fe'
estadd ysumm

* Column 6: Drop contagious conditions
use "$PROJ_PATH/processed/data/table_04_schooling_analysis_data.dta", clear
keep if contagious != 1
bysort sibling_id: keep if _N == 2

eststo ta16c6p1: xtreg scholar patient `scholar_controls', `fe'
estadd ysumm
eststo ta16c6p2: xtreg scholar resid_mort `scholar_controls', `fe'
estadd ysumm

***** Panel B: Sample selection *****

* Column 1: Add multiple siblings
use "$PROJ_PATH/processed/data/table_a16_col_07.dta", clear

eststo ta16c1p3: xtreg scholar patient `scholar_controls', `fe'
estadd ysumm
eststo ta16c1p4: xtreg scholar resid_mort `scholar_controls', `fe'
estadd ysumm

* Column 2: Add multiple patient households
use "$PROJ_PATH/processed/data/table_a16_col_08.dta", clear

eststo ta16c2p3: xtreg scholar patient `scholar_controls', `fe'
estadd ysumm
eststo ta16c2p4: xtreg scholar resid_mort `scholar_controls', `fe'
estadd ysumm

* Column 3: Restrict to patients residing in County of London at the time of admission
use "$PROJ_PATH/processed/data/table_a16_col_09.dta", clear

eststo ta16c3p3: xtreg scholar patient `scholar_controls', `fe'
estadd ysumm
eststo ta16c3p4: xtreg scholar resid_mort `scholar_controls', `fe'
estadd ysumm

* Column 4: Drop Guy's patients
use "$PROJ_PATH/processed/data/table_04_schooling_analysis_data.dta", clear
drop if hosp_guys == 1
bysort sibling_id: keep if _N == 2

eststo ta16c4p3: xtreg scholar patient `scholar_controls', `fe'
estadd ysumm
eststo ta16c4p4: xtreg scholar resid_mort `scholar_controls', `fe'
estadd ysumm

* Column 5: Hospital-census match, unique within county
use "$PROJ_PATH/processed/data/table_04_schooling_analysis_data.dta", clear
keep if nodist_match == 1
bysort sibling_id: keep if _N == 2

eststo ta16c5p3: xtreg scholar patient `scholar_controls', `fe'
estadd ysumm
eststo ta16c5p4: xtreg scholar resid_mort `scholar_controls', `fe'
estadd ysumm

* Column 6: Hospital-census match, restrict column 5 to county match 
use "$PROJ_PATH/processed/data/table_04_schooling_analysis_data.dta", clear
keep if nodist_match == 1 & rescty_match == 1
bysort sibling_id: keep if _N == 2

eststo ta16c6p3: xtreg scholar patient `scholar_controls', `fe'
estadd ysumm
eststo ta16c6p4: xtreg scholar resid_mort `scholar_controls', `fe'
estadd ysumm

#delimit ;
esttab ta16c1p1 ta16c2p1 ta16c3p1 ta16c4p1 ta16c5p1 ta16c6p1 using "$PROJ_PATH/output/02_appendix/table_a16.tex", replace
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
keep(patient) 
posthead("
	&\multicolumn{1}{c}{Column (3)}						&\multicolumn{1}{c}{Drop high} 	&\multicolumn{1}{c}{Drop infant}&\multicolumn{1}{c}{Drop multiple}	&\multicolumn{1}{c}{Drop low} 	&\multicolumn{1}{c}{Drop} \\
	&\multicolumn{1}{c}{Table~\ref{tab:Tab_Mechanisms}}	&\multicolumn{1}{c}{mortality} 	&\multicolumn{1}{c}{admissions}	&\multicolumn{1}{c}{admissions}		&\multicolumn{1}{c}{mortality} 	&\multicolumn{1}{c}{contagious}	\\ 
	\midrule &\multicolumn{6}{c}{Panel A: Selective mortality} \\ \addlinespace
	")
legend noconstant nonote lines gaps nomtitles noobs star(* 0.1 ** 0.05 *** 0.01)
postfoot("\addlinespace");

esttab ta16c1p2 ta16c2p2 ta16c3p2 ta16c4p2 ta16c5p2 ta16c6p2 using "$PROJ_PATH/output/02_appendix/table_a16.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
keep(resid_mort) prehead("") posthead("")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"))
postfoot("\midrule");

esttab ta16c1p3 ta16c2p3 ta16c3p3 ta16c4p3 ta16c5p3 ta16c6p3 using "$PROJ_PATH/output/02_appendix/table_a16.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
keep(patient) prehead("") 
posthead("
	&\multicolumn{1}{c}{(7)}&\multicolumn{1}{c}{(8)}&\multicolumn{1}{c}{(9)}&\multicolumn{1}{c}{(10)}&\multicolumn{1}{c}{(11)}&\multicolumn{1}{c}{(12)} \\
	&\multicolumn{1}{c}{Add multiple} 	&\multicolumn{1}{c}{Add multiple}	&\multicolumn{1}{c}{County of}	&\multicolumn{1}{c}{Drop Guy's} &\multicolumn{1}{c}{Unique within}	&\multicolumn{1}{c}{Hospital-census}\\
	&\multicolumn{1}{c}{siblings}	 	&\multicolumn{1}{c}{patient hhlds.}	&\multicolumn{1}{c}{London only}&\multicolumn{1}{c}{Hospital}	&\multicolumn{1}{c}{census county}	&\multicolumn{1}{c}{county match} \\ 
	\midrule &\multicolumn{6}{c}{Panel B: Sample selection} \\ \addlinespace
	")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
postfoot("\addlinespace");

esttab ta16c1p4 ta16c2p4 ta16c3p4 ta16c4p4 ta16c5p4 ta16c6p4 using "$PROJ_PATH/output/02_appendix/table_a16.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
keep(resid_mort) prehead("") posthead("")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"));
#delimit cr

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Table A17: Robustness for pre-existing disability outcome
*********************************************************************************************************************************************
*********************************************************************************************************************************************

eststo drop *

* Column 1: Baseline 
use "$PROJ_PATH/processed/data/table_04_pre_existing_analysis_data.dta", clear 

eststo ta17c1p1: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta17c1p2: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

***** Panel A: Selective Mortality and Scarring *****

* Column 2: Drop high mortality
use "$PROJ_PATH/processed/data/table_04_pre_existing_analysis_data.dta", clear 
sum resid_mort if patient == 1, detail
local cut10 = r(p10)
local cut90 = r(p90)

gen top10_mort = (resid_mort >= `cut90' & patient == 1)
egen total_top10 = total(top10_mort == 1), by(sibling_id)
drop if total_top10 > 0
drop total_top10 top10_mort

eststo ta17c2p1: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta17c2p2: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm
	
* Column 3: Drop infant admissions
use "$PROJ_PATH/processed/data/table_04_pre_existing_analysis_data.dta", clear 
keep if admitage0 != 1 & admitage1 != 1
bysort sibling_id: keep if _N == 2

eststo ta17c3p1: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta17c3p2: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

* Column 4: Drop multiple admissions
use "$PROJ_PATH/processed/data/table_04_pre_existing_analysis_data.dta", clear 
drop if tot_visits > 1 & patient == 1
bysort sibling_id: keep if _N == 2

eststo ta17c4p1: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta17c4p2: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

* Column 5: Drop low mortality
use "$PROJ_PATH/processed/data/table_04_pre_existing_analysis_data.dta", clear 

gen bot10_mort = (resid_mort <= `cut10' & patient == 1)
egen total_bot10 = total(bot10_mort == 1), by(sibling_id)
drop if total_bot10 > 0
drop total_bot10 bot10_mort 

eststo ta17c5p1: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta17c5p2: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

* Column 6: Drop contagious conditions
use "$PROJ_PATH/processed/data/table_04_pre_existing_analysis_data.dta", clear 
keep if contagious != 1
bysort sibling_id: keep if _N == 2

eststo ta17c6p1: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta17c6p2: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

***** Panel B: Sample selection *****

* Column 1: Add multiple siblings
use "$PROJ_PATH/processed/data/table_a17_col_07.dta", clear

eststo ta17c1p3: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta17c1p4: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

* Column 2: Add multiple patient households
use "$PROJ_PATH/processed/data/table_a17_col_08.dta", clear

eststo ta17c2p3: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta17c2p4: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

* Column 3: Restrict to patients residing in County of London at the time of admission
use "$PROJ_PATH/processed/data/table_a17_col_09.dta", clear

eststo ta17c3p3: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta17c3p4: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

* Column 4: Drop Guy's patients
use "$PROJ_PATH/processed/data/table_04_pre_existing_analysis_data.dta", clear 
keep if hosp_guys == 0
bysort sibling_id: keep if _N == 2

eststo ta17c4p3: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta17c4p4: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

* Column 5: Hospital-census match, unique within county
use "$PROJ_PATH/processed/data/table_04_pre_existing_analysis_data.dta", clear 
keep if nodist_match == 1
bysort sibling_id: keep if _N == 2

eststo ta17c5p3: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta17c5p4: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

* Column 6: Hospital-census match, restrict column 5 to county match 
use "$PROJ_PATH/processed/data/table_04_pre_existing_analysis_data.dta", clear 
keep if nodist_match == 1 & rescty_match == 1
bysort sibling_id: keep if _N == 2

eststo ta17c6p3: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta17c6p4: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

#delimit ;
esttab ta17c1p1 ta17c2p1 ta17c3p1 ta17c4p1 ta17c5p1 ta17c6p1 using "$PROJ_PATH/output/02_appendix/table_a17.tex", replace
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
keep(patient) 
posthead("
	&\multicolumn{1}{c}{Column (6)}						&\multicolumn{1}{c}{Drop high} 	&\multicolumn{1}{c}{Drop infant}&\multicolumn{1}{c}{Drop multiple}	&\multicolumn{1}{c}{Drop low} 	&\multicolumn{1}{c}{Drop} \\
	&\multicolumn{1}{c}{Table~\ref{tab:Tab_Mechanisms}}	&\multicolumn{1}{c}{mortality} 	&\multicolumn{1}{c}{admissions}	&\multicolumn{1}{c}{admissions}		&\multicolumn{1}{c}{mortality} 	&\multicolumn{1}{c}{contagious}	\\ 
	\midrule &\multicolumn{6}{c}{Panel A: Selective mortality} \\ \addlinespace
	")
legend noconstant nonote lines gaps nomtitles noobs star(* 0.1 ** 0.05 *** 0.01)
postfoot("\addlinespace");

esttab ta17c1p2 ta17c2p2 ta17c3p2 ta17c4p2 ta17c5p2 ta17c6p2 using "$PROJ_PATH/output/02_appendix/table_a17.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
keep(resid_mort) prehead("") posthead("")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"))
postfoot("\midrule");

esttab ta17c1p3 ta17c2p3 ta17c3p3 ta17c4p3 ta17c5p3 ta17c6p3 using "$PROJ_PATH/output/02_appendix/table_a17.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
keep(patient) prehead("") 
posthead("
	&\multicolumn{1}{c}{(7)}&\multicolumn{1}{c}{(8)}&\multicolumn{1}{c}{(9)}&\multicolumn{1}{c}{(10)}&\multicolumn{1}{c}{(11)}&\multicolumn{1}{c}{(12)} \\
	&\multicolumn{1}{c}{Add multiple} 	&\multicolumn{1}{c}{Add multiple}	&\multicolumn{1}{c}{County of}	&\multicolumn{1}{c}{Drop Guy's} &\multicolumn{1}{c}{Unique within}	&\multicolumn{1}{c}{Hospital-census}\\
	&\multicolumn{1}{c}{siblings}	 	&\multicolumn{1}{c}{patient hhlds.}	&\multicolumn{1}{c}{London only}&\multicolumn{1}{c}{Hospital}	&\multicolumn{1}{c}{census county}	&\multicolumn{1}{c}{county match} \\ 
	\midrule &\multicolumn{6}{c}{Panel B: Sample selection} \\ \addlinespace
	")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
postfoot("\addlinespace");

esttab ta17c1p4 ta17c2p4 ta17c3p4 ta17c4p4 ta17c5p4 ta17c6p4 using "$PROJ_PATH/output/02_appendix/table_a17.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
keep(resid_mort) prehead("") posthead("")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"));
#delimit cr

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Table A18: Robustness for childhood disability outcome
*********************************************************************************************************************************************
*********************************************************************************************************************************************

eststo drop *

* Column 1: Baseline 
use "$PROJ_PATH/processed/data/table_04_disability_analysis_data.dta", clear 

eststo ta18c1p1: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta18c1p2: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

***** Panel A: Selective Mortality and Scarring *****

* Column 2: Drop high mortality
use "$PROJ_PATH/processed/data/table_04_disability_analysis_data.dta", clear 
sum resid_mort if patient == 1, detail
local cut10 = r(p10)
local cut90 = r(p90)

gen top10_mort = (resid_mort >= `cut90' & patient == 1)
egen total_top10 = total(top10_mort == 1), by(sibling_id)
drop if total_top10 > 0
drop total_top10 top10_mort

eststo ta18c2p1: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta18c2p2: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm
	
* Column 3: Drop infant admissions
use "$PROJ_PATH/processed/data/table_04_disability_analysis_data.dta", clear 
keep if admitage0 != 1 & admitage1 != 1
bysort sibling_id: keep if _N == 2

eststo ta18c3p1: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta18c3p2: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

* Column 4: Drop multiple admissions
use "$PROJ_PATH/processed/data/table_04_disability_analysis_data.dta", clear 
drop if tot_visits > 1 & patient == 1
bysort sibling_id: keep if _N == 2

eststo ta18c4p1: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta18c4p2: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

* Column 5: Drop low mortality
use "$PROJ_PATH/processed/data/table_04_disability_analysis_data.dta", clear 
gen bot10_mort = (resid_mort <= `cut10' & patient == 1)
egen total_bot10 = total(bot10_mort == 1), by(sibling_id)
drop if total_bot10 > 0
drop total_bot10 bot10_mort 

eststo ta18c5p1: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta18c5p2: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

* Column 6: Drop contagious conditions
use "$PROJ_PATH/processed/data/table_04_disability_analysis_data.dta", clear 
keep if contagious != 1
bysort sibling_id: keep if _N == 2

eststo ta18c6p1: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta18c6p2: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

***** Panel B: Sample selection *****

* Column 1: Add multiple siblings
use "$PROJ_PATH/processed/data/table_a18_col_07.dta", clear

eststo ta18c1p3: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta18c1p4: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

* Column 2: Add multiple patient households
use "$PROJ_PATH/processed/data/table_a18_col_08.dta", clear

eststo ta18c2p3: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta18c2p4: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

* Column 3: Restrict to patients residing in County of London at the time of admission
use "$PROJ_PATH/processed/data/table_a18_col_09.dta", clear

eststo ta18c3p3: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta18c3p4: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

* Column 4: Drop Guy's patients
use "$PROJ_PATH/processed/data/table_04_disability_analysis_data.dta", clear 
keep if hosp_guys == 0
bysort sibling_id: keep if _N == 2

eststo ta18c4p3: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta18c4p4: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

* Column 5: Hospital-census match, unique within county
use "$PROJ_PATH/processed/data/table_04_disability_analysis_data.dta", clear 
keep if nodist_match == 1
bysort sibling_id: keep if _N == 2

eststo ta18c5p3: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta18c5p4: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

* Column 6: Hospital-census match, restrict column 5 to county match 
use "$PROJ_PATH/processed/data/table_04_disability_analysis_data.dta", clear 
keep if nodist_match == 1 & rescty_match == 1
bysort sibling_id: keep if _N == 2

eststo ta18c6p3: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
eststo ta18c6p4: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm

#delimit ;
esttab ta18c1p1 ta18c2p1 ta18c3p1 ta18c4p1 ta18c5p1 ta18c6p1 using "$PROJ_PATH/output/02_appendix/table_a18.tex", replace
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
keep(patient) 
posthead("
	&\multicolumn{1}{c}{Column (9)}						&\multicolumn{1}{c}{Drop high} 	&\multicolumn{1}{c}{Drop infant}&\multicolumn{1}{c}{Drop multiple}	&\multicolumn{1}{c}{Drop low} 	&\multicolumn{1}{c}{Drop} \\
	&\multicolumn{1}{c}{Table~\ref{tab:Tab_Mechanisms}}	&\multicolumn{1}{c}{mortality} 	&\multicolumn{1}{c}{admissions}	&\multicolumn{1}{c}{admissions}		&\multicolumn{1}{c}{mortality} 	&\multicolumn{1}{c}{contagious}	\\ 
	\midrule &\multicolumn{6}{c}{Panel A: Selective mortality} \\ \addlinespace
	")
legend noconstant nonote lines gaps nomtitles noobs star(* 0.1 ** 0.05 *** 0.01)
postfoot("\addlinespace");

esttab ta18c1p2 ta18c2p2 ta18c3p2 ta18c4p2 ta18c5p2 ta18c6p2 using "$PROJ_PATH/output/02_appendix/table_a18.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
keep(resid_mort) prehead("") posthead("")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"))
postfoot("\midrule");

esttab ta18c1p3 ta18c2p3 ta18c3p3 ta18c4p3 ta18c5p3 ta18c6p3 using "$PROJ_PATH/output/02_appendix/table_a18.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
keep(patient) prehead("") 
posthead("
	&\multicolumn{1}{c}{(7)}&\multicolumn{1}{c}{(8)}&\multicolumn{1}{c}{(9)}&\multicolumn{1}{c}{(10)}&\multicolumn{1}{c}{(11)}&\multicolumn{1}{c}{(12)} \\
	&\multicolumn{1}{c}{Add multiple} 	&\multicolumn{1}{c}{Add multiple}	&\multicolumn{1}{c}{County of}	&\multicolumn{1}{c}{Drop Guy's} &\multicolumn{1}{c}{Unique within}	&\multicolumn{1}{c}{Hospital-census}\\
	&\multicolumn{1}{c}{siblings}	 	&\multicolumn{1}{c}{patient hhlds.}	&\multicolumn{1}{c}{London only}&\multicolumn{1}{c}{Hospital}	&\multicolumn{1}{c}{census county}	&\multicolumn{1}{c}{county match} \\ 
	\midrule &\multicolumn{6}{c}{Panel B: Sample selection} \\ \addlinespace
	")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
postfoot("\addlinespace");

esttab ta18c1p4 ta18c2p4 ta18c3p4 ta18c4p4 ta18c5p4 ta18c6p4 using "$PROJ_PATH/output/02_appendix/table_a18.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
keep(resid_mort) prehead("") posthead("")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"));
#delimit cr

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Table A19: Robustness for long-run disability outcome
*********************************************************************************************************************************************
*********************************************************************************************************************************************

eststo drop *

* Column 1: Baseline 
use "$PROJ_PATH/processed/data/table_04_col_10.dta", clear

eststo ta19c1p1: xtreg disab_any patient `baseline_controls', `fe'
estadd ysumm
eststo ta19c1p2: xtreg disab_any resid_mort `baseline_controls', `fe'
estadd ysumm

***** Panel A: Selective Mortality and Scarring *****

* Column 2: Drop high mortality
use "$PROJ_PATH/processed/data/table_04_col_10.dta", clear

sum resid_mort if patient == 1, detail
local cut10 = r(p10)
local cut90 = r(p90)

gen top10_mort = (resid_mort >= `cut90' & patient == 1)
egen total_top10 = total(top10_mort == 1), by(sibling_id)
drop if total_top10 > 0
drop total_top10 top10_mort

eststo ta19c2p1: xtreg disab_any patient `baseline_controls', `fe'
estadd ysumm
eststo ta19c2p2: xtreg disab_any resid_mort `baseline_controls', `fe'
estadd ysumm
	
* Column 3: Drop infant admissions
use "$PROJ_PATH/processed/data/table_04_col_10.dta", clear
keep if admitage0 != 1 & admitage1 != 1
bysort sibling_id: keep if _N == 2

eststo ta19c3p1: xtreg disab_any patient `baseline_controls', `fe'
estadd ysumm
eststo ta19c3p2: xtreg disab_any resid_mort `baseline_controls', `fe'
estadd ysumm

* Column 4: Drop multiple admissions
use "$PROJ_PATH/processed/data/table_04_col_10.dta", clear
drop if tot_visits > 1 & patient == 1
bysort sibling_id: keep if _N == 2

eststo ta19c4p1: xtreg disab_any patient `baseline_controls', `fe'
estadd ysumm
eststo ta19c4p2: xtreg disab_any resid_mort `baseline_controls', `fe'
estadd ysumm

* Column 5: Drop low mortality
use "$PROJ_PATH/processed/data/table_04_col_10.dta", clear
gen bot10_mort = (resid_mort <= `cut10' & patient == 1)
egen total_bot10 = total(bot10_mort == 1), by(sibling_id)
drop if total_bot10 > 0
drop total_bot10 bot10_mort 

eststo ta19c5p1: xtreg disab_any patient `baseline_controls', `fe'
estadd ysumm
eststo ta19c5p2: xtreg disab_any resid_mort `baseline_controls', `fe'
estadd ysumm

* Column 6: Drop contagious conditions
use "$PROJ_PATH/processed/data/table_04_col_10.dta", clear
keep if contagious != 1
bysort sibling_id: keep if _N == 2

eststo ta19c6p1: xtreg disab_any patient `baseline_controls', `fe'
estadd ysumm
eststo ta19c6p2: xtreg disab_any resid_mort `baseline_controls', `fe'
estadd ysumm

***** Panel B: Sample selection *****

* Column 1: Add multiple siblings
use "$PROJ_PATH/processed/data/table_a19_col_07.dta", clear

eststo ta19c1p3: xtreg disab_any patient `baseline_controls', `fe'
estadd ysumm
eststo ta19c1p4: xtreg disab_any resid_mort `baseline_controls', `fe'
estadd ysumm

* Column 2: Add multiple patient households
use "$PROJ_PATH/processed/data/table_a19_col_08.dta", clear

eststo ta19c2p3: xtreg disab_any patient `baseline_controls', `fe'
estadd ysumm
eststo ta19c2p4: xtreg disab_any resid_mort `baseline_controls', `fe'
estadd ysumm

* Column 3: Restrict to patients residing in County of London at the time of admission
use "$PROJ_PATH/processed/data/table_a19_col_09.dta", clear

eststo ta19c3p3: xtreg disab_any patient `baseline_controls', `fe'
estadd ysumm
eststo ta19c3p4: xtreg disab_any resid_mort `baseline_controls', `fe'
estadd ysumm

* Column 4: Drop Guy's patients
use "$PROJ_PATH/processed/data/table_04_col_10.dta", clear
keep if hosp_guys == 0
bysort sibling_id: keep if _N == 2

eststo ta19c4p3: xtreg disab_any patient `baseline_controls', `fe'
estadd ysumm
eststo ta19c4p4: xtreg disab_any resid_mort `baseline_controls', `fe'
estadd ysumm

* Column 5: Hospital-census match, unique within county
use "$PROJ_PATH/processed/data/table_04_col_10.dta", clear
keep if nodist_match == 1
bysort sibling_id: keep if _N == 2

eststo ta19c5p3: xtreg disab_any patient `baseline_controls', `fe'
estadd ysumm
eststo ta19c5p4: xtreg disab_any resid_mort `baseline_controls', `fe'
estadd ysumm

* Column 6: Hospital-census match, restrict column 5 to county match 
use "$PROJ_PATH/processed/data/table_04_col_10.dta", clear
keep if nodist_match == 1 & rescty_match == 1
bysort sibling_id: keep if _N == 2

eststo ta19c6p3: xtreg disab_any patient `baseline_controls', `fe'
estadd ysumm
eststo ta19c6p4: xtreg disab_any resid_mort `baseline_controls', `fe'
estadd ysumm

#delimit ;
esttab ta19c1p1 ta19c2p1 ta19c3p1 ta19c4p1 ta19c5p1 ta19c6p1 using "$PROJ_PATH/output/02_appendix/table_a19.tex", replace
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
keep(patient) 
posthead("
	&\multicolumn{1}{c}{Column (10)}						&\multicolumn{1}{c}{Drop high} 	&\multicolumn{1}{c}{Drop infant}&\multicolumn{1}{c}{Drop multiple}	&\multicolumn{1}{c}{Drop low} 	&\multicolumn{1}{c}{Drop} \\
	&\multicolumn{1}{c}{Table~\ref{tab:Tab_Mechanisms}}		&\multicolumn{1}{c}{mortality} 	&\multicolumn{1}{c}{admissions}	&\multicolumn{1}{c}{admissions}		&\multicolumn{1}{c}{mortality} 	&\multicolumn{1}{c}{contagious}	\\ 
	\midrule &\multicolumn{6}{c}{Panel A: Selective mortality} \\ \addlinespace
	")
legend noconstant nonote lines gaps nomtitles noobs star(* 0.1 ** 0.05 *** 0.01)
postfoot("\addlinespace");

esttab ta19c1p2 ta19c2p2 ta19c3p2 ta19c4p2 ta19c5p2 ta19c6p2 using "$PROJ_PATH/output/02_appendix/table_a19.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
keep(resid_mort) prehead("") posthead("")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"))
postfoot("\midrule");

esttab ta19c1p3 ta19c2p3 ta19c3p3 ta19c4p3 ta19c5p3 ta19c6p3 using "$PROJ_PATH/output/02_appendix/table_a19.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
keep(patient) prehead("") 
posthead("
	&\multicolumn{1}{c}{(7)}&\multicolumn{1}{c}{(8)}&\multicolumn{1}{c}{(9)}&\multicolumn{1}{c}{(10)}&\multicolumn{1}{c}{(11)}&\multicolumn{1}{c}{(12)} \\
	&\multicolumn{1}{c}{Add multiple} 	&\multicolumn{1}{c}{Add multiple}	&\multicolumn{1}{c}{County of}	&\multicolumn{1}{c}{Drop Guy's} &\multicolumn{1}{c}{Unique within}	&\multicolumn{1}{c}{Hospital-census}\\
	&\multicolumn{1}{c}{siblings}	 	&\multicolumn{1}{c}{patient hhlds.}	&\multicolumn{1}{c}{London only}&\multicolumn{1}{c}{Hospital}	&\multicolumn{1}{c}{census county}	&\multicolumn{1}{c}{county match} \\ 
	\midrule &\multicolumn{6}{c}{Panel B: Sample selection} \\ \addlinespace
	")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
postfoot("\addlinespace");

esttab ta19c1p4 ta19c2p4 ta19c3p4 ta19c4p4 ta19c5p4 ta19c6p4 using "$PROJ_PATH/output/02_appendix/table_a19.tex", append
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _)
keep(resid_mort) prehead("") posthead("")
legend noconstant nonote lines gaps nomtitles nonum noobs star(* 0.1 ** 0.05 *** 0.01)
prefoot("\addlinespace")
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"));
#delimit cr

********************************************************************************************************************************************
********************************************************************************************************************************************
// Table A20: Within household selection
********************************************************************************************************************************************
********************************************************************************************************************************************

use "$PROJ_PATH/processed/data/table_a09_a20.dta" if sibling_id != . & Sex != 9, clear

xtset sibling_id

egen tot_pat = total(patient_match), by(Year h ParID)
drop if tot_pat == 0

gen first_born = (brthord == 1)
gen female = (Sex == 2)
gen first_born_female = first_born*female

la var first_born "First born"
la var female "Female"
la var first_born_female "First born $\times$ female"

forvalues y = 1881(10)1901 {
	eststo p1c`y': xtreg patient_match first_born female first_born_female i.Age##i.Year if Age <= 5 & Year == `y', fe cluster(sibling_id)
	estadd ysumm
	eststo p2c`y': reg resid_mort first_born female first_born_female i.Age##i.Year if Age <= 5 & Year == `y' & patient_match == 1, robust
	estadd ysumm
}

eststo p1c9999: xtreg patient_match first_born female first_born_female i.Age##i.Year if Age <= 5, fe cluster(sibling_id)
estadd ysumm
eststo p2c9999: reg resid_mort first_born female first_born_female i.Age##i.Year if Age <= 5  & patient_match == 1, robust
estadd ysumm

#delimit ;
esttab p1c1881 p1c1891 p1c1901 p1c9999 p2c1881 p2c1891 p2c1901 p2c9999 using "$PROJ_PATH/output/02_appendix/table_a20.tex", replace
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _) lines gaps collabels(none)
mtitles("1881" "1891" "1901" "Any" "1881" "1891" "1901" "Any")
mgroups("Hospitalization (Patients vs. siblings)" "Health deficiency index $\vert$ Hospitalization (Patients only)", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
keep(first_born female first_born_female) star(* 0.1 ** 0.05 *** 0.01)
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"));
#delimit cr

********************************************************************************************************************************************
********************************************************************************************************************************************
// Table A21: Health index and likelihood of match
********************************************************************************************************************************************
********************************************************************************************************************************************

use "$PROJ_PATH/processed/data/table_a21.dta", clear

local census_date_1871 = mdy(4,2,1871)
local census_date_1881 = mdy(4,2,1881)
local census_date_1891 = mdy(4,5,1891)
local census_date_1901 = mdy(3,31,1901)
local census_date_9999 = mdy(3,31,1901)

foreach y in 1881 1891 1901 {
	local x = `y' - 10
	eststo p3c`y': reg matched_to_census resid_mort if died == 0 & sex_HOSP == 1 & match_input == 1 & censusyr == `y' & admitdate > `census_date_`x'' & dischdate < `census_date_`y'', robust
	estadd ysumm
}

egen max_match = max(matched_to_census), by(regid)
keep max_match regid resid_mort 
rename max_match matched_to_census
duplicates drop 
unique regid

eststo p3c9999: reg matched_to_census resid_mort, robust
estadd ysumm

matrix b = e(b)
local beta_hi = b[1,1]

sum resid_mort
local sd_hi = r(sd)
local mu_hi = r(mean)

local pp_change = string(`sd_hi'*`beta_hi',"%9.3f")
local pct_change = string(`sd_hi'*`beta_hi'*100/`mu_hi',"%9.2f")

display "pp change: `pp_change' and pct change: `pct_change'%"

#delimit ;
esttab p3c1881 p3c1891 p3c1901 p3c9999 using "$PROJ_PATH/output/02_appendix/table_a21.tex", replace
label b(%12.3f) se(%12.3f) alignment(S S) booktabs f substitute(\_ _) lines gaps collabels(none)
mtitles("1881" "1891" "1901" "Any")
mgroups("Census year linked to hospital records", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
keep(resid_mort) star(* 0.1 ** 0.05 *** 0.01)
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"));
#delimit cr

********************************************************************************************************************************************
********************************************************************************************************************************************
// Table A22: Match rates between censuses (males only)
********************************************************************************************************************************************
********************************************************************************************************************************************

forvalues x = 1881(10)1901 {
	if `x' < 1901 {
		local y_min = 1901
	}
	else {
		local y_min = 1911
	}
	forvalues y = `y_min'(10)1911 {
		use "$PROJ_PATH/processed/data/table_a22_icem_census_match_rates_`x'_`y'.dta", clear
		eststo m1c`x'a`y': estpost sum no_match multiple_match unique_match if england == 1, listwise
	}
}
	
#delimit ;
esttab m1c1881a1901 m1c1891a1901 m1c1881a1911 m1c1891a1911 m1c1901a1911 using "$PROJ_PATH/output/02_appendix/table_a22.tex", replace
booktabs alignment(S) label lines gaps collabels(none) noobs f
cells("mean(fmt(3))")
mgroups("Outcome year = 1901" "Outcome year = 1911", pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
mtitles("1881" "1891" "1881" "1891" "1901")
stats(N, fmt(%9.0fc) labels(`"Baseline sample"') layout("\multicolumn{1}{c}{@}"))
postfoot("");
#delimit cr

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Figure A3 Mortality rate by age at admission
*********************************************************************************************************************************************
*********************************************************************************************************************************************

// Panel A: Raw data
use died admitage using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear
collapse (mean) died, by(admitage)

twoway ///
	(connected died admitage, lcolor(purple) lwidth(medthick) mcolor(purple) msymbol(diamond)), ///
	subtitle("P(death in hospital)", position(11) justification(left) size(6) ) ///
	ylabel(0(0.05)0.35, nogrid angle(horizontal) labsize(5)) yscale(nofextend) ytitle("") ///
	xlabel(0(2)12, labsize(5)) xtick(0(1)12) xscale(nofextend) xtitle("Age at admission", size(5)) ///
	scheme(s2mono) aspectratio(`inv_golden_ratio') ///
	legend(off) graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) ///
	
graph export "$PROJ_PATH/output/02_appendix/figure_a03a.eps", replace

// Panel B: Rregression adjusted
use regid died hospid sex_HOSP admitage doctor los_group comorbid transfer admityr using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear

reg died i.admitage i.admityr i.hospid i.sex_HOSP i.comorbid i.los_group doctor transfer, robust

matrix beta = e(b)

matrix A = r(table)
matrix SE = A[2,2..12] // Extract standard errors for admission age FE
matrix list SE

matrix C = 1.96*SE
matrix list C

margins, predict(xb) at((base) admitage (mean) admityr hospid sex_HOSP comorbid doctor los_group transfer) post
matrix B = e(b)
scalar base_year = B[1,1] // Extract estimated regression-adjusted mean 
scalar list base_year

matrix Y = J(1,11,base_year)
matrix list Y

matrix age_coef = J(11,1,base_year) + beta[1,2..12]'
matrix list age_coef

matrix y1 = (base_year,0,0,0)
matrix list y1

matrix CL = age_coef - C'
matrix CH = age_coef + C'
matrix list CL
matrix list CH

matrix X = (1\2\3\4\5\6\7\8\9\10\11)
matrix Dat = (age_coef,CL,CH,X)
matrix Dat = (y1\Dat)
matrix list Dat

svmat Dat
	
keep Dat*
keep in 1/12

rename Dat1 b
rename Dat2 L
rename Dat3 H
rename Dat4 admitage

la var admitage "Age at admission"

twoway 	///
	(scatter b admitage if admitage > 0, lpattern(solid) msymbol(square) mcolor(navy) ) ///
	(rcap L H admitage if admitage > 0, lpattern(solid) lwidth(thin) lcolor(navy) ), ///
	subtitle("Estimated mortality rate", position(11) justification(left) size(6) ) ///
	ylabel(0(0.05)0.35, nogrid angle(horizontal) labsize(5)) yscale(nofextend) ytitle("Estimate", size(5)) ///
	xlabel(0(2)12, labsize(5)) xtick(0(1)12) xscale(nofextend) xtitle("Age at admission", size(5)) ///
	scheme(s2mono) aspectratio(`inv_golden_ratio') ///
	legend(off) graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white))
		
graph export "$PROJ_PATH/output/02_appendix/figure_a03b.eps", replace

*********************************************************************************************************
*********************************************************************************************************
// Figure A4: Mortality rate by admission year 
*********************************************************************************************************
*********************************************************************************************************

// Panel A: Raw data
use died admityr using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear
collapse (mean) died, by(admityr)

twoway ///
	(connected died admityr, lcolor(purple) lwidth(medthick) mcolor(purple) msymbol(diamond)), ///
	subtitle("P(death in hospital)", position(11) justification(left) size(6) ) ///
	ylabel(0(0.1)0.3, nogrid angle(horizontal) labsize(5)) yscale(nofextend) ytitle("") ///
	xlabel(1870(5)1905, labsize(5)) xscale(nofextend) xtitle("Year of admission", size(5)) ///
	scheme(s2mono) aspectratio(`inv_golden_ratio') ///
	legend(off) graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) ///
	 
graph export "$PROJ_PATH/output/02_appendix/figure_a04a.eps", replace

// Panel B: Rregression adjusted
use regid died hospid sex_HOSP admitage doctor los_group comorbid transfer admityr using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear

reg died i.admityr
local num_group = e(df_m)
local num_param = e(rank)

reg died i.admityr i.admitage i.hospid i.sex_HOSP i.comorbid i.los_group doctor transfer, robust

matrix beta = e(b)

matrix A = r(table)
matrix SE = A[2,2..`num_param'] // Extract standard errors for admission age FE
matrix list SE

matrix C = 1.96*SE
matrix list C

margins, predict(xb) at((base) admityr (mean) admitage hospid sex_HOSP comorbid doctor los_group transfer) post
matrix B = e(b)
scalar base_year = B[1,1] // Extract estimated regression-adjusted mean 
scalar list base_year

matrix Y = J(1,`num_group',base_year)
matrix list Y

matrix yr_coef = J(`num_group',1,base_year) +  beta[1,2..`num_param']'
matrix list yr_coef

matrix y1 = (base_year,0,0,0)
matrix list y1

matrix CL = yr_coef - C'
matrix CH = yr_coef + C'
matrix list CL
matrix list CH

matrix X = J(1,1,1)
forvalues n = 2(1)`num_group' {
	matrix Y = J(1,1,`n')
	matrix X = (X\Y)
}
matrix Dat = (yr_coef,CL,CH,X)
matrix Dat = (y1\Dat)
matrix list Dat

svmat Dat
	
keep Dat*
keep in 1/`num_param'

rename Dat1 b
rename Dat2 L
rename Dat3 H
rename Dat4 admityr

replace admityr = 1870 + admityr

twoway 	///
	(scatter b admityr if admityr >= 1871 & admityr <= 1901, lpattern(solid) msymbol(square) mcolor(navy) ) ///
	(rcap L H admityr if admityr >= 1871 & admityr <= 1901, lpattern(solid) lwidth(thin) lcolor(navy) ), ///
	subtitle("Estimated mortality rate", position(11) justification(left) size(6) ) ///
	ylabel(-0.1(0.1)0.3, nogrid angle(horizontal) labsize(5)) yscale(nofextend) ytitle("Estimate", size(5)) ///
	xlabel(1870(5)1905, nogrid labsize(5)) xscale(nofextend) xtitle("Year of admission", size(5)) ///
	scheme(s2mono) aspectratio(`inv_golden_ratio') ///
	legend(off) graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white))
		
graph export "$PROJ_PATH/output/02_appendix/figure_a04b.eps", replace

*********************************************************************************************************
*********************************************************************************************************
// Figure A5: Share of children living with a parent in 1881 by age
*********************************************************************************************************
*********************************************************************************************************

use "$PROJ_PATH/processed/data/figure_a05_a06.dta" if Age <= 18, clear

gen living_with_parent = (momloc != 0 | poploc != 0)
collapse (mean) living_with_parent, by(Age)

la var living_with_parent "P(Living with a parent)"
la var Age "Child's age"

twoway ///
	(line living_with_parent Age, lcolor(purple) lwidth(medthick) mcolor(purple) msymbol(diamond)), ///
	subtitle("P(Living with a parent)", position(11) justification(left) size(medsmall) ) ///
	ylabel(0(0.2)1, nogrid angle(horizontal) ) yscale(nofextend) ytitle("") ///
	xlabel(0(2)18) xscale(nofextend) xline(11, lcolor(red)) xtitle("Child's age") ///
	scheme(s2mono) aspectratio(`inv_golden_ratio') ///
	legend(off) graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white))
	 
graph export "$PROJ_PATH/output/02_appendix/figure_a05.eps", as(eps) preview(off) replace

*********************************************************************************************************
*********************************************************************************************************
// Figure A6: Labor force participation and school enrollment by age in 1881
*********************************************************************************************************
*********************************************************************************************************

use "$PROJ_PATH/processed/data/figure_a05_a06.dta" if Age >= 5 & Age <= 18, clear

collapse (mean) in_laborforce in_school, by(Age Year)

la var in_laborforce ""
la var in_school ""

twoway ///
	(connected in_laborforce Age if Year == 1881, lcolor(purple) lwidth(medthick) msymbol(none)) ///
	(connected in_school Age if Year == 1881, lcolor(purple) lwidth(medthick) lpattern(dash) msymbol(none)), ///
	subtitle("Labor force participation and school participation rates", position(11) justification(left) size(medsmall) ) ///
	text(0.87 8.1 "School participation rate", place(e)) ///
	text(0.05 5.1 "Labor force participation rate", place(e)) ///
	ylabel(0(0.2)1, nogrid angle(horizontal) ) yscale(nofextend) ytitle("") ///
	xlabel(6(2)18) xscale(range(5 18) nofextend) xtitle("Age") ///
	scheme(s2mono) aspectratio(`inv_golden_ratio') ///
	legend(off) graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white))

graph export "$PROJ_PATH/output/02_appendix/figure_a06.eps", as(eps) preview(off) replace

*********************************************************************************************************
*********************************************************************************************************
// Figure A7: Does father's occupational status change over time?
*********************************************************************************************************
*********************************************************************************************************

use "$PROJ_PATH/processed/data/figure_a07.dta", clear

la var v1 "Rest of pop." 
la var v2 "Hospital pop." 
la var v3 "Empirical sample"

graph bar v1-v3, ///
    bargap(10) ///
    graphregion(color(white)) ///
    over(y, gap(200) label(angle(0))) /// 
    ytitle("Share of population") ///
    ylabel(, angle(horizontal)) ///
    bar(1, color(red*0.3)) bar(2, color(blue*0.7)) bar(3, color(green*0.5)) ///
    legend(label(1 "Rest of pop.") label(2 "Hospital pop.") label(3 "Empirical sample") rows(1) ring(1) pos(6) region(lcolor(white))) ///
    nofill
	
graph export "$PROJ_PATH/output/02_appendix/figure_a07.eps", replace

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// // Figure A8: Randomly lower father's SES for 15% of patients 
*********************************************************************************************************************************************
*********************************************************************************************************************************************

local results "$PROJ_PATH/processed/data/figure_a08_output.dta"
local replace replace

set seed 8

qui {
	forvalues i = 1/1000 {
		
		use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
		keep sibling_id
		duplicates drop
		sample 15
		tempfile recode_sibs
		save `recode_sibs', replace
			
		use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
		merge m:1 sibling_id using `recode_sibs', assert(1 3)
		
		replace pophisc4 = 4 if pophisc4 == .
		replace pophisc4 = pophisc4 + 1 if _merge == 3 & patient == 1 & pophisc4 < 4
		replace pophisc4 = pophisc4 - 1 if _merge == 3 & patient == 0 & pophisc4 == 4 
		drop _merge

		forvalues n = 1/6 {
		
			xtreg ``n'' patient i.pophisc4 `baseline_controls', `fe'
			
			if `i' != 1 | `n' != 1 {	
				local replace append
			}
			
			regsave patient using "`results'", t p ci autoid addlabel(iteration,`i',outcome,`n') `replace'
			
		}
		
	}
}

forvalues n = 1/6 {

	// Estimate main results

	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
		
	la var mobility_up "Y = 1 if upward mobility"
	la var mobility_dn "Y = 1 if downward mobility"
	la var top_25 "Y = 1 if white collar occupation"
	la var top_50 "Y = 1 if skilled+ occupation"
	la var bot_25 "Y = 1 if unskilled occupation"
	la var ln_wage "Y: Log occupational wage"
	
	qui xtreg ``n'' patient `baseline_controls', `fe'

	// Store main results

	matrix b = e(b)
	
	local b_`n' = b[1,1]
	local dep_var : var label ``n''
	
	// Load randomized estimates

	use "`results'", clear

	la var coef "Coefficient on patient indicator"
	la var tstat "T-statistic"

	sum coef if outcome == `n'
	local text_x1 = r(min)
	local text_x2 = r(mean) + 0.75*r(sd)
	local mu_b = r(mean)
	
	local text_y = 8

	twoway ///
	(histogram coef if outcome == `n', percent fcolor(none) lcolor(black)), ///
	subtitle("`dep_var'", position(11) justification(left) size(8)) ///
	xline(`b_`n'', lstyle(foreground) lpattern(dash) lcolor(red) lwidth(0.5)) ///
	text(`text_y' `text_x1' "Main estimate", place(e) color(red) size(6)) ///
	xline(`mu_b', lstyle(foreground) lpattern(dash) lcolor(navy) lwidth(0.5)) ///
	text(`text_y' `text_x2' "Sample mean", place(e) color(navy) size(6)) ///
	ylabel(, angle(0) nogrid labsize(7)) yscale(nofextend) ytitle("Histogram (percent)", size(7)) ///
	xlabel(, angle(0) nogrid labsize(7)) xscale(nofextend) xtitle("Coefficient on patient indicator", size(7)) ///
	scheme(s2mono) aspectratio(`inv_golden_ratio') ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white))

	graph export "$PROJ_PATH/output/02_appendix/figure_a08_panel_0`n'.eps", replace
	
}

*********************************************************************************************************
*********************************************************************************************************
//  Figure A9: Unpack HDI - Include all common conditions in one regression
*********************************************************************************************************
*********************************************************************************************************

local condition_list "abscess pneumonia bronchitis phimosis chorea diphth empyema cleft_palate talipes rickets dis_knee scarlet dis_hip fracture typhoid tuberculosis tub_dis rheumatism pleurisy morbus_cordis harelip eczema fever broncho_pneumonia"

tempfile results replace
capture drop `results'
local replace replace

forvalues n = 1/6 {

	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	
	* Re-code fever as other fevers, excluding main types	
	replace fever = 0 if (typhoid == 1 | scarlet == 1 | diphth == 1) & patient == 1
	tab fever
	
	* Create separate classification for broncho-pneomonia
	replace bronchitis = 0 if broncho_pneumonia == 1 & patient == 1
	replace pneumonia = 0 if broncho_pneumonia == 1 & patient == 1
	tab bronchitis
	tab pneumonia
	tab broncho_pneumonia

	egen total_conditions = rowtotal(`condition_list')
	tab total_conditions
	
	gen multiple_conditions = (total_conditions > 1 & !missing(total_conditions))
	gen other_conditions = (total_conditions == 0 & patient == 1)

	tab multiple_conditions
	tab other_conditions

	foreach var of varlist `condition_list' {
		replace `var' = 0 if multiple_conditions == 1
	}

	la var abscess "Abscess"
	la var pneumonia "Pneumonia"
	la var bronchitis "Bronchitis"
	la var phimosis "Phimosis"
	la var chorea "Chorea"
	la var empyema "Empyema"
	la var diphth "Diphtheria"
	la var injury "Injury"
	la var cleft_palate "Cleft Palate"
	la var talipes "Talipes"
	la var fever "Fever"
	la var rickets "Rickets"
	la var dis_knee "Knee Disease"
	la var diarrhea "Diarrhea"
	la var scarlet "Scarlet Fever"
	la var dis_hip "Hip Disease" 
	la var fracture "Fracture"
	la var typhoid "Typhoid"
	la var tuberculosis "Tuberculosis"
	la var tub_dis "Tubercular Disease"
	la var rheumatism "Rheumatism"
	la var necrosis "Necrosis"
	la var harelip "Cleft Lip"
	la var pleurisy "Pleurisy"
	la var morbus_cordis "Morbus Cordis"
	la var eczema "Eczema"
	la var broncho_pneumonia "Bronchopneumonia"
	la var meningitis "Meningitis"
	la var burn "Burn"
	la var laryingitis "Laryngitis"
	la var other_conditions "Other"
	la var multiple_conditions "Multiple"

	* Store baseline estimate
	
	reghdfe ``n'' patient `baseline_controls', absorb(sibling_id) cluster(sibling_id) 
	matrix b = e(b)
	local b_`n' = b[1,1]
	
	* Estimate group-specific effects
	
	reghdfe ``n'' other_conditions multiple_conditions `condition_list' `baseline_controls', absorb(sibling_id) cluster(sibling_id) 

	foreach var of varlist other_conditions `condition_list' {
		
		if `n' > 1 | (`n' == 1 & "`var'" != "other_conditions") local replace append
	
		qui count if `var' == 1
		local obs = r(N)
		
		qui sum resid_mort if `var' == 1
		local hdi = r(mean)
		
		regsave `var' using `results', t p ci autoid addlabel(depvar,`n',main_est,`b_`n'',cause,`: var label `var'',N_obs,`obs',hdi,`hdi') `replace' 
		
	}
}

forvalues n = 1/6 {

	use `results' if depvar == `n', clear

	sort depvar coef cause
	egen rank = seq(), by(depvar)

	label define y_lab 1 "Y = 1 if upward mobility" 2 "Y = 1 if downward mobility" 3 "Y = 1 if white collar occupation" 4 "Y = 1 if skilled + occupation" 5 "Y = 1 if unskilled occupation" 6 "Y: Log occupational wage"
	la val depvar y_lab
	
	labmask rank, values(cause)
	
	sum main_est
	local main_b = r(mean)
	
	if `main_b' < 0 {
		local x_pos = `main_b' - 0.01
		local time = 9
	}
	else {
		local x_pos = `main_b' + 0.01
		local time = 3
	}
	
	count
	local lab_max = r(N)

	// Plotting coefficients by cause of admission
	
	twoway ///
		(scatter rank coef , mcolor(navy) msymbol(square)) ///
		(rcap ci_upper ci_lower rank, horizontal lcolor(navy) msymbol(none) lwidth(medthin)), ///
		title("`: label y_lab `n''", position(11) justification(left) size(medsmall) ) ///
		xline(0, lcolor(gs7) lpattern(solid) lwidth(thin)) ///
		xline(`main_b', lcolor(red) lpattern(dash) lwidth(thin)) ///
		text(24.5 `x_pos' "Main estimate", color(red) placement(`time')) ///
		ylabel(1(1)`lab_max', valuelabel nogrid angle(horizontal)) ytitle("Cause of admission type") ///
		xscale(nofextend) xtitle("Estimated coefficient") ///
		scheme(s2mono) ///
		ysize(8) ///
		legend(off) graphregion(style(none) fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) note("")		

	graph export "$PROJ_PATH/output/02_appendix/figure_a09_panel_`n'.eps", replace

}

*********************************************************************************************************
*********************************************************************************************************
// Figure A10: Unpack HDI - Include all groups in one regression
*********************************************************************************************************
*********************************************************************************************************

tempfile results replace
capture drop `results'
local replace replace

forvalues n = 1/6 {

	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear

	* Fix coding of eczema
	replace congenital = 0 if eczema == 1 & patient == 1

	* Fix coding of tubercular disease
	replace contagious = 0 if tub_dis == 1 & meningitis == 0 &tuberculosis == 0 & bronchitis == 0 & pneumonia == 0 & patient == 1

	* Fix overlap in coding of congenital
	replace acute = 0 if congenital == 1 & patient == 1
	replace chronic = 0 if congenital == 1 & patient == 1

	* Separate chronic and acute
	gen acute_chronic = (acute == 1 & chronic == 1 & contagious == 0 & patient == 1)
	gen acute_other = (acute == 1 & contagious == 0 & acute_chronic == 0 & patient == 1)

	la var acute_chronic "Chronic"
	la var acute_other "Acute"
	la var injury "Injury"
	la var congenital "Congenital"
	la var contagious "Contagious"

	egen total_conditions = rowtotal(acute_other acute_chronic contagious congenital injury) //  
	tab total_conditions

	gen multiple_conditions = (total_conditions > 1 & !missing(total_conditions))
	gen other_conditions = (total_conditions == 0 & patient == 1)

	tab multiple_conditions if patient == 1
	tab other_conditions if patient == 1

	foreach var of varlist acute_other acute_chronic contagious congenital injury {
		replace `var' = 0 if multiple_conditions == 1
		tab `var' if patient == 1
	}

	la var other_conditions "Other"
	la var multiple_conditions "Multiple"

	* Store baseline estimate
	
	reghdfe ``n'' patient `baseline_controls', absorb(sibling_id) cluster(sibling_id) 
	matrix b = e(b)
	local b_`n' = b[1,1]
	
	* Estimate group-specific effects
	
	reghdfe ``n'' other_conditions multiple_conditions acute_other acute_chronic contagious congenital injury `baseline_controls', absorb(sibling_id) cluster(sibling_id) 
	
	foreach var of varlist other_conditions acute_other acute_chronic contagious congenital injury {
		
		if `n' > 1 | (`n' == 1 & "`var'" != "other_conditions") local replace append
	
		qui count if `var' == 1
		local obs = r(N)
		
		qui sum resid_mort if `var' == 1
		local hdi = r(mean)
		
		regsave `var' using `results', t p ci autoid addlabel(depvar,`n',main_est,`b_`n'',cause,`: var label `var'',N_obs,`obs',hdi,`hdi') `replace' 
		
	}
}

forvalues n = 1/6 {

	use `results' if depvar == `n', clear

	sort depvar coef cause
	egen rank = seq(), by(depvar)

	label define y_lab 1 "Y = 1 if upward mobility" 2 "Y = 1 if downward mobility" 3 "Y = 1 if white collar occupation" 4 "Y = 1 if skilled + occupation" 5 "Y = 1 if unskilled occupation" 6 "Y: Log occupational wage"
	la val depvar y_lab
	
	labmask rank, values(cause)
	
	sum main_est
	local main_b = r(mean)
	
	if `main_b' < 0 {
		local x_pos = `main_b' - 0.01
		local time = 9
	}
	else {
		local x_pos = `main_b' + 0.01
		local time = 3
	}
	
	// Plotting coefficients by group
	
	count
	local lab_max = r(N)
	
	twoway ///
		(scatter rank coef , mcolor(navy) msymbol(square)) ///
		(rcap ci_upper ci_lower rank, horizontal lcolor(navy) msymbol(none) lwidth(medthin)), ///
		title("`: label y_lab `n''", position(11) justification(left) size(medsmall) ) ///
		xline(0, lcolor(gs7) lpattern(solid) lwidth(thin)) ///
		xline(`main_b', lcolor(red) lpattern(dash) lwidth(thin)) ///
		text(5.5 `x_pos' "Main estimate", color(red) placement(`time')) ///
		ylabel(1(1)`lab_max', valuelabel nogrid angle(horizontal)) ytitle("Cause of admission type") ///
		xscale(nofextend) ///
		xtitle("Estimated coefficient") ///
		scheme(s2mono) ///
		legend(off) graphregion(style(none) fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) note("")		

	graph export "$PROJ_PATH/output/02_appendix/figure_a10_panel_`n'.eps", replace

}

*********************************************************************************************************
*********************************************************************************************************
// Figure A11: Unpack HDI - Include all body part groups in one regression
*********************************************************************************************************
*********************************************************************************************************

local condition_list "muscskel immune resp circul digest skin tuberc nervous nutrition ent urinary eye fever genitals" 

tempfile results replace
capture drop `results'
local replace replace

forvalues n = 1/6 {

	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	
	egen total_conditions = rowtotal(`condition_list')
	tab total_conditions
	
	gen multiple_conditions = (total_conditions > 1 & !missing(total_conditions))
	gen other_conditions = (total_conditions == 0 & patient == 1)

	tab multiple_conditions
	tab other_conditions

	foreach var of varlist `condition_list' {
		replace `var' = 0 if multiple_conditions == 1
	}
	
	la var muscskel "Musc/Skel" 
	la var immune "Immune"
	la var resp "Respiratory"
	la var circul "Circulatory"
	la var digest "Digestive"
	la var skin "Skin"
	la var tuberc "Tubercular"
	la var nervous "Nervous"
	la var nutrition "Malnutrition"
	la var ent "Ear/nose/throat"
	la var urinary "Urinary"
	la var eye "Eye"
	la var fever "Fever"
	la var genitals "Genitals"
	la var tissue "Tissue"
	la var foreign "Foreign"
	la var mouth "Mouth"
	la var venereal "Venereal"
	la var parasitic "Parasitic"
	la var heart "Heart"
	la var other_conditions "Other"
	la var multiple_conditions "Multiple"
	
	* Store baseline estimate
	
	reghdfe ``n'' patient `baseline_controls', absorb(sibling_id) cluster(sibling_id) 
	matrix b = e(b)
	local b_`n' = b[1,1]
	
	* Estimate group-specific effects
	
	reghdfe ``n'' other_conditions multiple_conditions `condition_list' `baseline_controls', absorb(sibling_id) cluster(sibling_id) 
	
	foreach var of varlist other_conditions `condition_list' {
		
		if `n' > 1 | (`n' == 1 & "`var'" != "other_conditions") local replace append
	
		qui count if `var' == 1
		local obs = r(N)
		
		qui sum resid_mort if `var' == 1
		local hdi = r(mean)
		
		regsave `var' using `results', t p ci autoid addlabel(depvar,`n',main_est,`b_`n'',cause,`: var label `var'',N_obs,`obs',hdi,`hdi') `replace' 
		
	}
}

forvalues n = 1/6 {
	
	use `results' if depvar == `n', clear

	sort depvar coef cause
	egen rank = seq(), by(depvar)

	label define y_lab 1 "Y = 1 if upward mobility" 2 "Y = 1 if downward mobility" 3 "Y = 1 if white collar occupation" 4 "Y = 1 if skilled + occupation" 5 "Y = 1 if unskilled occupation" 6 "Y: Log occupational wage"
	la val depvar y_lab
	
	labmask rank, values(cause)
	
	sum main_est
	local main_b = r(mean)
	
	if `main_b' < 0 {
		local x_pos = `main_b' - 0.01
		local time = 9
	}
	else {
		local x_pos = `main_b' + 0.01
		local time = 3
	}
	
	count
	local lab_max = r(N)

	// Plotting coefficients by group
	
	twoway ///
		(scatter rank coef, mcolor(navy) msymbol(square)) ///
		(rcap ci_upper ci_lower rank, horizontal lcolor(navy) msymbol(none) lwidth(medthin)), ///
		title("`: label y_lab `n''", position(11) justification(left) size(medsmall) ) ///
		xline(0, lcolor(gs7) lpattern(solid) lwidth(thin)) ///
		xline(`main_b', lcolor(red) lpattern(dash) lwidth(thin)) ///
		text(10.5 `x_pos' "Main estimate", color(red) placement(`time')) ///
		ylabel(1(1)`lab_max', valuelabel nogrid angle(horizontal)) ytitle("Body system group") ///
		xscale(nofextend) xtitle("Estimated coefficient") ///
		scheme(s2mono) ///
		legend(off) graphregion(style(none) fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) note("")		

	graph export "$PROJ_PATH/output/02_appendix/figure_a11_panel_`n'.eps", replace

}

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Figure A12: Randomly assign treatment to 10% of siblings
*********************************************************************************************************************************************
*********************************************************************************************************************************************

local results "$PROJ_PATH/processed/data/figure_a12_output.dta"
local replace replace

set seed 12 

qui {
	forvalues i = 1/1000 {
			
		use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
		keep sibling_id
		duplicates drop
		sample 10
		tempfile recode_sibs
		save `recode_sibs', replace
			
		use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
		merge m:1 sibling_id using `recode_sibs', assert(1 3)
		replace patient = 1 if _merge == 3
		drop _merge

		forvalues n = 1/6 {
		
			xtreg ``n'' patient `baseline_controls', `fe'
			
			if `i' != 1 | `n' != 1 {	
				local replace append
			}
			
			regsave patient using "`results'", t p ci autoid addlabel(iteration,`i',outcome,`n') `replace'
			
		}

	}
}

forvalues n = 1/6 {

	// Estimate main results
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	
	la var mobility_up "Y = 1 if upward mobility"
	la var mobility_dn "Y = 1 if downward mobility"
	la var top_25 "Y = 1 if white collar occupation"
	la var top_50 "Y = 1 if skilled+ occupation"
	la var bot_25 "Y = 1 if unskilled occupation"
	la var ln_wage "Y: Log occupational wage"
	
	qui xtreg ``n'' patient `baseline_controls', `fe'

	// Store main results
	matrix b = e(b)
	
	local b_`n' = b[1,1]
	local dep_var : var label ``n''
	
	// Load randomized estimates
	use "`results'", clear

	la var coef "Coefficient on patient indicator"
	la var tstat "T-statistic"

	sum coef if outcome == `n'
	local text_x1 = r(mean) - 3.25*r(sd)
	local text_x2 = r(mean) + 0.75*r(sd)
	local mu_b = r(mean)
	
	local text_y = 8

	twoway ///
	(histogram coef if outcome == `n', percent fcolor(none) lcolor(black)), ///
	subtitle("`dep_var'", position(11) justification(left) size(8) ) ///
	xline(`b_`n'', lstyle(foreground) lpattern(dash) lcolor(red) lwidth(0.5)) ///
	text(`text_y' `text_x1' "Main estimate", place(e) color(red) size(6)) ///
	xline(`mu_b', lstyle(foreground) lpattern(dash) lcolor(navy) lwidth(0.5)) ///
	text(`text_y' `text_x2' "Sample mean", place(e) color(navy) size(6)) ///
	ylabel(, angle(0) nogrid labsize(7)) yscale(nofextend) ytitle("Histogram (percent)", size(7)) ///
	xlabel(, angle(0) nogrid labsize(7)) xscale(nofextend) xtitle("Coefficient on patient indicator", size(7)) ///
	scheme(s2mono) aspectratio(`inv_golden_ratio') ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white))

	graph export "$PROJ_PATH/output/02_appendix/figure_a12_panel_0`n'.eps", replace
	
}

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Figure A13: Density of HDI in full set of hospital records vs. estimation sample
*********************************************************************************************************************************************
*********************************************************************************************************************************************

use "$PROJ_PATH/processed/data/figure_a13.dta", clear

la var resid_mort "Health deficiency index"
label define sample_lab 1 "Estimation sample" 2 "All male patients"
la val sample sample_lab

twoway ///
	(histogram resid_mort if sample == 1, start(0) width(0.01) color(purple)) ///
    (histogram resid_mort if sample == 2, start(0) width(0.01) fcolor(none) lcolor(black)), ///
	subtitle("Density of health deficiency index", position(11) justification(left) size(medsmall) ) ///
	ylabel(0(5)20, angle(horizontal) nogrid) yscale(nofextend) ytitle("") ///
	xscale(nofextend) xtitle("Health deficiency index") ///
	legend(order(1 "Estimation sample" 2 "All male patients" ) nobox region(lstyle(none) color(white)) cols(1) ring(0) bplacement(ne)) ///
	scheme(s2mono) aspectratio(`inv_golden_ratio') ///
	graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white))

graph export "$PROJ_PATH/output/02_appendix/figure_a13.eps", replace

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Figure A14: Robustness of single marital status results
*********************************************************************************************************************************************
*********************************************************************************************************************************************

// Panel (a): Robustness to tolerance for mismatched names 

* Run regressions for each specification and save results to file
* n is going index the specifications - corresponding to the columns in Table 3

local age_dist = 3
local sim_records = 20

forvalues n = 1(1)3 {

	* For each column we need to set the gender: women (g = 2) in columns 1 and men (g = 1) in columns 2 and 3
	
	if `n' == 1 {
		local gender = 2
	}
	else {
		local gender = 1
	}
	
	forvalues x = 1(1)9 {
	
		local jw100 = 100*(1 - (`x' - 1)*0.025)
	
		* Load data
		
		use "$PROJ_PATH/processed/data/figure_a14_singles_`gender'_age_`age_dist'_jw_`jw100'_sim_`sim_records'.dta", clear

		if `n' == 3 {
		
			keep if link_10 == 1 | link_20 == 1 | link_30 == 1
			
		}
		keep if main_marital_sample == 1
		bysort sibling_id: keep if _N == 2
	
		* Run regression
		
		xtreg single patient `marital_controls_`n'', fe cluster(sibling_id)
		
		matrix b`x' = e(b)
		matrix v`x' = e(V)
		matrix n`x' = e(N)
			
	}
	
	matrix C1 = (b1[1,1]\b2[1,1]\b3[1,1]\b4[1,1]\b5[1,1]\b6[1,1]\b7[1,1]\b8[1,1]\b9[1,1])
	matrix C2 = (1.96*sqrt(v1[1,1])\1.96*sqrt(v2[1,1])\1.96*sqrt(v3[1,1])\1.96*sqrt(v4[1,1])\1.96*sqrt(v5[1,1])\1.96*sqrt(v6[1,1])\1.96*sqrt(v7[1,1])\1.96*sqrt(v8[1,1])\1.96*sqrt(v9[1,1]))
	matrix CL = (C1[1,1]-C2[1,1]\C1[2,1]-C2[2,1]\C1[3,1]-C2[3,1]\C1[4,1]-C2[4,1]\C1[5,1]-C2[5,1]\C1[6,1]-C2[6,1]\C1[7,1]-C2[7,1]\C1[8,1]-C2[8,1]\C1[9,1]-C2[9,1])
	matrix CH = (C1[1,1]+C2[1,1]\C1[2,1]+C2[2,1]\C1[3,1]+C2[3,1]\C1[4,1]+C2[4,1]\C1[5,1]+C2[5,1]\C1[6,1]+C2[6,1]\C1[7,1]+C2[7,1]\C1[8,1]+C2[8,1]\C1[9,1]+C2[9,1])

	matrix N = (n1[1,1]\n2[1,1]\n3[1,1]\n4[1,1]\n5[1,1]\n6[1,1]\n7[1,1]\n8[1,1]\n9[1,1])
	matrix X = (1\2\3\4\5\6\7\8\9)
	matrix Dat = (C1,CL,CH,N,X) 

	svmat Dat

	keep Dat*
	keep in 1/9

	rename Dat1 Pat_Coef
	rename Dat2 L
	rename Dat3 H
	rename Dat4 N
	rename Dat5 JW_Threshold

	replace JW_Threshold = (JW_Threshold - 1)*0.025

	gen outcome = `n'

	tempfile jw_`n'
	save `jw_`n'', replace
}

clear
foreach n of numlist 1/3 {
	append using `jw_`n''
}
	
label define samplelab 1 "Baseline sample, women" 2 "Baseline sample, men" 3 "Linked sample, men", replace
la val outcome samplelab

twoway ///
	(scatter Pat_Coef JW_Threshold, mcolor(navy) msymbol(square)) ///
	(rcap H L JW_Threshold, lcolor(navy) msymbol(none) lwidth(medthin)), ///
	yline(0, lcolor(gs7) lpattern(solid) lwidth(thin)) ///
	ylabel(-0.02(0.02)0.10, nogrid angle(horizontal)) yscale(nofextend) ytitle("Coefficient on patient", size(5)) ///
	xscale(nofextend) xtitle("Maximum Jaro-Winkler distance for matching names", size(5)) ///
	scheme(s2mono) xsize(8) ///
	by(outcome, cols(3) legend(off) graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) note(""))
		
graph export "$PROJ_PATH/output/02_appendix/figure_a14_panel_1.eps", as(eps) preview(off) replace
		
// Panel (b): Robustness to restrictions on similar names

* Run regressions for each specification and save results to file
* n is going index the specifications - corresponding to the columns in Table 3

local x = 9
local jw_bot = 1 - (`x' - 1)*0.025
local jw100 = 100*(1 - (`x' - 1)*0.025)
local age_dist = 3

forvalues n = 1(1)3 {

	* For each column we need to set the gender: women (gender = 2) in columns 1 and men (gender = 1) in columns 2 and 3
	
	if `n' == 1 {
		local gender = 2
	}
	else {
		local gender = 1
	}
	
	foreach y in 4 6 8 10 15 20 50 100 1000 { 
	
		if `y' == 4 local x = 1
		if `y' == 6 local x = 2
		if `y' == 8 local x = 3
		if `y' == 10 local x = 4
		if `y' == 15 local x = 5
		if `y' == 20 local x = 6
		if `y' == 50 local x = 7
		if `y' == 100 local x = 8
		if `y' == 1000 local x = 9

		* Load data
		
		use "$PROJ_PATH/processed/data/figure_a14_singles_`gender'_age_`age_dist'_jw_`jw100'_sim_`y'.dta", clear
		
		if `n' == 3 {
		
			keep if link_10 == 1 | link_20 == 1 | link_30 == 1
			
		}
		keep if main_marital_sample == 1
		bysort sibling_id: keep if _N == 2
	
		* Run regression
		
		xtreg single patient `marital_controls_`n'', fe cluster(sibling_id)
		
		matrix b`x' = e(b)
		matrix v`x' = e(V)
		matrix n`x' = e(N)
			
	}
	
	matrix C1 = (b1[1,1]\b2[1,1]\b3[1,1]\b4[1,1]\b5[1,1]\b6[1,1]\b7[1,1]\b8[1,1]\b9[1,1])
	matrix C2 = (1.96*sqrt(v1[1,1])\1.96*sqrt(v2[1,1])\1.96*sqrt(v3[1,1])\1.96*sqrt(v4[1,1])\1.96*sqrt(v5[1,1])\1.96*sqrt(v6[1,1])\1.96*sqrt(v7[1,1])\1.96*sqrt(v8[1,1])\1.96*sqrt(v9[1,1]))
	matrix CL = (C1[1,1]-C2[1,1]\C1[2,1]-C2[2,1]\C1[3,1]-C2[3,1]\C1[4,1]-C2[4,1]\C1[5,1]-C2[5,1]\C1[6,1]-C2[6,1]\C1[7,1]-C2[7,1]\C1[8,1]-C2[8,1]\C1[9,1]-C2[9,1])
	matrix CH = (C1[1,1]+C2[1,1]\C1[2,1]+C2[2,1]\C1[3,1]+C2[3,1]\C1[4,1]+C2[4,1]\C1[5,1]+C2[5,1]\C1[6,1]+C2[6,1]\C1[7,1]+C2[7,1]\C1[8,1]+C2[8,1]\C1[9,1]+C2[9,1])

	matrix N = (n1[1,1]\n2[1,1]\n3[1,1]\n4[1,1]\n5[1,1]\n6[1,1]\n7[1,1]\n8[1,1]\n9[1,1])
	matrix X = (4\6\8\10\15\20\50\100\1000)
	matrix Dat = (C1,CL,CH,N,X) 

	svmat Dat

	keep Dat*
	keep in 1/9

	rename Dat1 Pat_Coef
	rename Dat2 L
	rename Dat3 H
	rename Dat4 N
	rename Dat5 Sim_Records

	gen JW_Threshold = 10/100
	gen outcome = `n'

	tempfile jw_`n'
	save `jw_`n'', replace
}

clear
foreach n of numlist 1/3 {
	append using `jw_`n''
}
	
label define samplelab 1 "Baseline sample, women" 2 "Baseline sample, men" 3 "Linked sample, men", replace
la val outcome samplelab

egen X = seq(), by(outcome)

tostring Sim_Records, replace
labmask X, values(Sim_Records)

twoway ///
	(scatter Pat_Coef X, mcolor(navy) msymbol(square)) 	///
	(rcap H L X, lcolor(navy) msymbol(none) lwidth(medthin)), ///
	yline(0, lcolor(gs7) lpattern(solid) lwidth(thin)) ///
	ylabel(-0.02(0.02)0.10, nogrid angle(horizontal) labsize(5)) ///
	yscale(nofextend) ///
	ytitle("Coefficient on patient", size(5)) ///
	xlabel(1(2)9, valuelabel labsize(5)) xscale(nofextend) ///
	xtitle("Number of similar records", size(5)) ///
	scheme(s2mono) xsize(8) ///
	by(outcome, cols(3) legend(off) graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) note(""))
	
graph export "$PROJ_PATH/output/02_appendix/figure_a14_panel_2.eps", as(eps) preview(off) replace


		
// Panel (c): Age gap between census links

* Run regressions for each specification and save results to file
* n is going index the specifications - corresponding to the columns in Table 3

local x = 9
local jw_bot = 1 - (`x' - 1)*0.025
local jw100 = `jw_bot'*100
local sim_records = 20
	
forvalues n = 1(1)3 {

	* For each column we need to set the gender: women (g = 2) in columns 1 and men (g = 1) in columns 2 and 3
	
	if `n' == 1 {
		local gender = 2
	}
	else {
		local gender = 1
	}
	
	forvalues d = 0(1)3 {
	
		* Load data
		
		use "$PROJ_PATH/processed/data/figure_a14_singles_`gender'_age_`age_dist'_jw_`jw100'_sim_`sim_records'.dta", clear
		
		if `n' == 3 {
		
			keep if link_10 == 1 | link_20 == 1 | link_30 == 1
			
		}
		keep if main_marital_sample == 1
		bysort sibling_id: keep if _N == 2
	
		* Run regression
		
		xtreg single patient `marital_controls_`n'', fe cluster(sibling_id)
		
		matrix b`d' = e(b)
		matrix v`d' = e(V)
		matrix n`d' = e(N)
	}
	
	matrix C1 = (b0[1,1]\b1[1,1]\b2[1,1]\b3[1,1])
	matrix C2 = (1.96*sqrt(v0[1,1])\1.96*sqrt(v1[1,1])\1.96*sqrt(v2[1,1])\1.96*sqrt(v3[1,1]))
	matrix CL = (C1[1,1]-C2[1,1]\C1[2,1]-C2[2,1]\C1[3,1]-C2[3,1]\C1[4,1]-C2[4,1])
	matrix CH = (C1[1,1]+C2[1,1]\C1[2,1]+C2[2,1]\C1[3,1]+C2[3,1]\C1[4,1]+C2[4,1])

	matrix N = (n0[1,1]\n1[1,1]\n2[1,1]\n3[1,1])
	matrix X = (0\1\2\3)
	matrix Dat = (C1,CL,CH,N,X) 

	svmat Dat

	keep Dat*
	keep in 1/4

	rename Dat1 Pat_Coef
	rename Dat2 L
	rename Dat3 H
	rename Dat4 N
	rename Dat5 age_gap

	gen outcome = `n'

	tempfile age_gap_`n'
	save `age_gap_`n'', replace

}

clear
foreach n of numlist 1/3 {
	append using `age_gap_`n''
}

label define samplelab 1 "Baseline sample, women" 2 "Baseline sample, men" 3 "Linked sample, men", replace
la val outcome samplelab

twoway ///
	(scatter Pat_Coef age_gap, mcolor(navy) msymbol(square)) ///
	(rcap H L age_gap, lcolor(navy) msymbol(none) lwidth(medthin)), ///
	yline(0, lcolor(gs7) lpattern(solid) lwidth(thin)) ///
	ylabel(-0.02(0.02)0.10, nogrid angle(horizontal)) ytitle("Coefficient on patient", size(5)) ///
	xlabel(0(1)3) xtick(0(1)3) xscale(nofextend) xtitle("Maximum age gap between sources when linking (in years)", size(5)) ///
	scheme(s2mono) xsize(8) ///
	by(outcome, cols(3) legend(off) graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) note(""))
	
graph export "$PROJ_PATH/output/02_appendix/figure_a14_panel_3.eps", as(eps) preview(off) replace



*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Figure A15: Share ever married by age and sex
*********************************************************************************************************************************************
*********************************************************************************************************************************************

use "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_1911_demographic.dta", clear

rename Mar ia_marst
gen married = (ia_marst == 2 | ia_marst == 3 | ia_marst == 4 | ia_marst == 5)

drop if ia_marst == 9 | Sex == 9

collapse (mean) married, by(Age Sex)

keep if Age >= 10 & Age <= 75

la var married ""

twoway ///
	(connected married Age if Sex == 1, lcolor(purple) lwidth(medthick) msymbol(none)) ///
	(connected married Age if Sex == 2, lcolor(orange) lwidth(medthick) lpattern(dash) msymbol(none)), ///
	subtitle("Share of population ever married by age and sex in 1911", position(11) justification(left) size(4) ) ///
	ylabel(0(0.2)1, nogrid angle(horizontal) format(%9.2f)) yscale(nofextend) ytitle("") ///
	xscale(nofextend) xtitle("Age") ///
	text(0.95 60 "Men", place(e) color(purple)) ///
	text(0.80 60 "Women", place(e) color(orange)) ///
	xline(16, lcolor(red)) ///
	scheme(s2mono) aspectratio(`inv_golden_ratio') ///
	legend(off) graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white))

graph export "$PROJ_PATH/output/02_appendix/figure_a15.eps", replace

*********************************************************************************************************************************************

disp "DateTime: $S_DATE $S_TIME"

* EOF
