version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 01_tables_figures.do
* PURPOSE: This do file runs the regressions to produce all tables and figures in the paper
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
tokenize `outcome_vars'

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Calculate standard deviation of HDI for hospital population
*********************************************************************************************************************************************
*********************************************************************************************************************************************

use "$PROJ_PATH/processed/data/_hospital_resid_mort_descriptives.dta", clear
sum resid_mort_sigma
local resid_mort_sigma = r(mean)

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Table 1: Match rates and sample size count by census year
*********************************************************************************************************************************************
*********************************************************************************************************************************************

use "$PROJ_PATH/processed/data/table_01.dta", clear

eststo drop *
foreach y in 1881 1891 1901 9999 {
	eststo p1c`y': estpost tabstat no_match multiple_match matched_to_census matched_to_sib if match_input == 1 & sex_HOSP == 1 & censusyr == `y', statistics(sum mean) columns(statistics) listwise 
	eststo p2c`y': estpost tabstat matched_to_outcome matched_patsib matched_final if match_input == 1 & sex_HOSP == 1 & censusyr == `y', statistics(sum mean) columns(statistics) listwise 
}

#delimit ;
esttab p1c1881 p1c1891 p1c1901 p1c9999 using "$PROJ_PATH/output/01_paper/table_01.tex", replace
main(sum %9.0fc) aux(mean %12.3f) nostar unstack nonote noobs f substitute(\_ _)
booktabs label lines gaps collabels(none) mtitles("1881" "1891" "1901" "Any")
mgroups("Census year linked to hospital records", pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
posthead("\midrule &\multicolumn{4}{c}{Panel A: Hospital to childhood census linkage} \\ \addlinespace")
postfoot("\midrule Long-run censuses &\multicolumn{1}{c}{1901, 1911} & \multicolumn{1}{c}{1901, 1911} &\multicolumn{1}{c}{1911} &\multicolumn{1}{c}{1901, 1911} \\");

esttab p2c1881 p2c1891 p2c1901 p2c9999 using "$PROJ_PATH/output/01_paper/table_01.tex", append
posthead("\midrule &\multicolumn{4}{c}{Panel B: Linkage to census in adulthood} \\ \addlinespace")
main(sum %9.0fc) aux(mean %12.3f) nostar unstack nonote noobs f substitute(\_ _) nomtitles nonum
booktabs label lines gaps collabels(none) 
stats(N, fmt(%9.0fc) labels(`"Total admissions"') layout("\multicolumn{1}{c}{@}"));
#delimit cr

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Table 2: Long-run occupational and intergenerational outcomes
*********************************************************************************************************************************************
*********************************************************************************************************************************************

// Table 2: Sibling FE estimates for occupational success and intergenerational mobility

use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear

eststo drop *
forvalues n = 1/6 {

	* Panel A: Hospitalization indicator
	eststo t2a`n': xtreg ``n'' patient `baseline_controls', `fe'
	estadd ysumm
	matrix b = e(b)
	
	if `n' <= 5 {
		estadd scalar pctbeta = abs(b[1,1]*100/e(ymean)): t2a`n'
	}
	else if `n' == 6 {
		estadd scalar pctbeta = 100*abs(exp(b[1,1]) - 1): t2a`n'
	}
	
	* Panel B: HDI
	eststo t2b`n': xtreg ``n'' resid_mort `baseline_controls', `fe'
	estadd ysumm
	matrix b = e(b)
	
	if `n' <= 5 {
		estadd scalar pctbeta = abs(b[1,1]*`resid_mort_sigma'*100/e(ymean)): t2b`n'
	}
	else if `n' == 6 {
		estadd scalar pctbeta = 100*abs(exp(b[1,1]*`resid_mort_sigma') - 1): t2b`n'
	}
	 
	count
	local big_N = r(N)
	estadd scalar hh_N = `big_N'/2 : t2b`n'
	
}

#delimit ;
esttab t2a1 t2a2 t2a3 t2a4 t2a5 t2a6 using "$PROJ_PATH/output/01_paper/table_02.tex", `booktabs_default_options' replace
mgroups("Occupational mobility" "Own occupational rank" "", pattern(1 0 1 0 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
mtitles("Class $\nearrow$" "Class $\searrow$" "White collar" "Skilled +" "Unskilled" "Log wage")
posthead("\midrule & \multicolumn{6}{c}{Panel A: Effects of hospital admission} \\ \addlinespace")
keep(patient) b(%12.3f) se(%12.3f) 
stats(pctbeta, fmt(%9.1f) labels(`"\% effect"') layout("@")) prefoot("\addlinespace") postfoot("\addlinespace");

esttab t2b1 t2b2 t2b3 t2b4 t2b5 t2b6 using "$PROJ_PATH/output/01_paper/table_02.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{6}{c}{Panel B: Effects of health deficiency index} \\ \addlinespace") nomtitles nonum
keep(resid_mort) b(%12.3f) se(%12.3f) prefoot("\addlinespace") 
stats(pctbeta ymean hh_N N, fmt(%9.1f %12.3f %9.0fc %9.0fc) labels(`"\% effect ($\sigma$)"' `"Mean of Y"' `"N Households"' `"N"') layout("@" "@" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}"));
#delimit cr

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Table 3: Single marital status in the long run for men and women
*********************************************************************************************************************************************
*********************************************************************************************************************************************

eststo drop *
forvalues n = 1(1)3 {

	use `data_`n'', clear 
	keep if main_marital_sample == 1
	bysort sibling_id: keep if _N == 2
		
	single_reg, panel(0) col(`n') control_list(`marital_controls_`n'') clustervar(sibling_id) sigma(`resid_mort_sigma')

}

#delimit ;
esttab p0r1c1 p0r1c2 p0r1c3 using "$PROJ_PATH/output/01_paper/table_03.tex", `booktabs_default_options' replace
mgroups("Baseline sample" "Linked only", pattern(1 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
mtitles("Women" "Men" "Men")
prehead("& \multicolumn{3}{c}{Dependent variable: =1 if ever single at ages 18+} \\ \cmidrule(lr){2-4}")
posthead("\midrule & \multicolumn{3}{c}{Panel A: Effects of hospital admission} \\ \addlinespace")
keep(patient) b(%12.3f) se(%12.3f) 
stats(pctbeta, fmt(%9.1f) labels(`"\% effect"') layout("@")) prefoot("\addlinespace") postfoot("\addlinespace");

esttab p0r2c1 p0r2c2 p0r2c3 using "$PROJ_PATH/output/01_paper/table_03.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{3}{c}{Panel B: Effects of health deficiency index} \\ \addlinespace") nomtitles nonum
keep(resid_mort) b(%12.3f) se(%12.3f) prefoot("\addlinespace") 
stats(pctbeta ymean hh_N N, fmt(%9.1f %12.3f %9.0fc %9.0fc) labels(`"\% effect ($\sigma$)"' `"Mean of Y"' `"N Households"' `"N"') layout("@" "@" "\multicolumn{1}{c}{@}" "\multicolumn{1}{c}{@}"));
#delimit cr

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Table 4: Mechanisms
*********************************************************************************************************************************************
*********************************************************************************************************************************************

eststo drop *

// Schooling: Effects on likelihood of participation in schooling

* Column 1: Sibling FE (males only)
use "$PROJ_PATH/processed/data/table_04_schooling_analysis_data.dta" if sex == 1, clear

drop older_sib
egen first_sib = min(brthord), by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

eststo t4a1: xtreg scholar patient `scholar_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*100/e(ymean)) : t4a1

eststo t4b1: xtreg scholar resid_mort `scholar_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*`resid_mort_sigma'*100/e(ymean)) : t4b1

* Column 2: Sibling FE (females only)
use "$PROJ_PATH/processed/data/table_04_schooling_analysis_data.dta" if sex == 2, clear

drop older_sib
egen first_sib = min(brthord), by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

eststo t4a2: xtreg scholar patient `scholar_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*100/e(ymean)) : t4a2

eststo t4b2: xtreg scholar resid_mort `scholar_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*`resid_mort_sigma'*100/e(ymean)) : t4b2

* Column 3: Sibling FE (both sexes - combined sample from 1+2)
use "$PROJ_PATH/processed/data/table_04_schooling_analysis_data.dta", clear

eststo t4a3: xtreg scholar patient `scholar_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*100/e(ymean)) : t4a3

eststo t4b3: xtreg scholar resid_mort `scholar_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*`resid_mort_sigma'*100/e(ymean)) : t4b3



// Effects on pre-existing disability 

* Column 4: Sibling FE (males only)
use "$PROJ_PATH/processed/data/table_04_pre_existing_analysis_data.dta" if sex == 1, clear

drop older_sib
egen first_sib = min(brthord), by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

eststo t4a4: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*100/e(ymean)) : t4a4

eststo t4b4: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*`resid_mort_sigma'*100/e(ymean)) : t4b4

* Column 5: Sibling FE (females only)
use "$PROJ_PATH/processed/data/table_04_pre_existing_analysis_data.dta" if sex == 2, clear

drop older_sib
egen first_sib = min(brthord), by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

eststo t4a5: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*100/e(ymean)) : t4a5

eststo t4b5: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*`resid_mort_sigma'*100/e(ymean)) : t4b5

* Column 6: Sibling FE (both sexes - combined sample from 1+2)
use "$PROJ_PATH/processed/data/table_04_pre_existing_analysis_data.dta", clear

eststo t4a6: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*100/e(ymean)) : t4a6

eststo t4b6: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*`resid_mort_sigma'*100/e(ymean)) : t4b6



// Effects on childhood disability and later-life disability

* Column 7: Sibling FE (males only)
use "$PROJ_PATH/processed/data/table_04_disability_analysis_data.dta" if sex == 1, clear

drop older_sib
egen first_sib = min(brthord), by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

eststo t4a7: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*100/e(ymean)) : t4a7

eststo t4b7: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*`resid_mort_sigma'*100/e(ymean)) : t4b7

* Column 8: Sibling FE (females only)
use "$PROJ_PATH/processed/data/table_04_disability_analysis_data.dta" if sex == 2, clear

drop older_sib
egen first_sib = min(brthord), by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

eststo t4a8: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*100/e(ymean)) : t4a8

eststo t4b8: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*`resid_mort_sigma'*100/e(ymean)) : t4b8

* Column 9: Sibling FE (both sexes - combined sample from 1+2)
use "$PROJ_PATH/processed/data/table_04_disability_analysis_data.dta", clear

eststo t4a9: xtreg disab_any patient `disability_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*100/e(ymean)) : t4a9

eststo t4b9: xtreg disab_any resid_mort `disability_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*`resid_mort_sigma'*100/e(ymean)) : t4b9

* Column 10: Long-run disability outcome
use "$PROJ_PATH/processed/data/table_04_col_10.dta", clear

eststo t4a10: xtreg disab_any patient `baseline_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*100/e(ymean)): t4a10

eststo t4b10: xtreg disab_any resid_mort `baseline_controls', `fe'
estadd ysumm
matrix b = e(b)
estadd scalar pctbeta = abs(b[1,1]*`resid_mort_sigma'*100/e(ymean)): t4b10

#delimit ;
esttab t4a1 t4a2 t4a3 t4a4 t4a5 t4a6 t4a7 t4a8 t4a9 t4a10 using "$PROJ_PATH/output/01_paper/table_04.tex", `booktabs_default_options' replace
mgroups("Participation in schooling" "Pre-existing disability" "Childhood disability" "LR disability", pattern(1 0 0 1 0 0 1 0 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))
mtitles("Males" "Females" "Both sexes" "Males" "Females" "Both sexes" "Males" "Females" "Both sexes" "Males") 
prehead("&&&&\multicolumn{7}{c}{Any disability x 100}\\ \cmidrule(lr){5-11}")
posthead("\midrule &\multicolumn{10}{c}{Panel A: Effects of hospital admission} \\ \addlinespace")
keep(patient) b(%12.3f) se(%12.3f)
stats(pctbeta, fmt(%9.1f) labels(`"\% effect"') layout("@"))
prefoot("\addlinespace") postfoot("\addlinespace");

esttab t4b1 t4b2 t4b3 t4b4 t4b5 t4b6 t4b7 t4b8 t4b9 t4b10 using "$PROJ_PATH/output/01_paper/table_04.tex", `booktabs_default_options' append
prehead("") posthead("&\multicolumn{10}{c}{Panel B: Effects of health deficiency index} \\ \addlinespace") nomtitles nonum
keep(resid_mort) b(%12.3f) se(%12.3f)
stats(pctbeta ymean N, fmt(%9.1f %12.3f %9.0fc) labels(`"\% effect ($\sigma$)"' `"Mean of Y"' `"N"') layout("@" "@" "\multicolumn{1}{c}{@}"))
prefoot("\addlinespace");
#delimit cr

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Table 5: Robustness, selective mortality, occupational outcomes
*********************************************************************************************************************************************
*********************************************************************************************************************************************

eststo drop *
forvalues n = 1/6 {

	* Baseline estimates
	
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	eststo t5p`n'c0: xtreg ``n'' patient `baseline_controls', `fe'
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
	
	eststo t5p`n'c1: xtreg ``n'' patient `baseline_controls', `fe'
	estadd ysumm
	
	* Drop infant admissions
	
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	keep if admitage0 != 1 & admitage1 != 1
	bysort sibling_id: keep if _N == 2

	eststo t5p`n'c2: xtreg ``n'' patient `baseline_controls', `fe'
	estadd ysumm
	
	* Drop multiple admissions
	
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	drop if tot_visits > 1 & patient == 1
	bysort sibling_id: keep if _N == 2

	eststo t5p`n'c3: xtreg ``n'' patient `baseline_controls', `fe'
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
	
	eststo t5p`n'c4: xtreg ``n'' patient `baseline_controls', `fe'
	estadd ysumm
	
	* Drop contagious diseases
	
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	keep if contagious != 1
	bysort sibling_id: keep if _N == 2
	
	eststo t5p`n'c5: xtreg ``n'' patient `baseline_controls', `fe'
	estadd ysumm
}

#delimit ;
esttab t5p1c0 t5p1c1 t5p1c2 t5p1c3 t5p1c4 t5p1c5 using "$PROJ_PATH/output/01_paper/table_05.tex", `booktabs_default_options' replace
keep(patient) b(%12.3f) se(%12.3f) nomtitles 
	posthead("
		&\multicolumn{1}{c}{Baseline}	&\multicolumn{1}{c}{Drop high}	&\multicolumn{1}{c}{Drop infant}	&\multicolumn{1}{c}{Drop multiple}	&\multicolumn{1}{c}{Drop low}	&\multicolumn{1}{c}{Drop}		\\
		&\multicolumn{1}{c}{estimate}	&\multicolumn{1}{c}{mortality}	&\multicolumn{1}{c}{admission}		&\multicolumn{1}{c}{admissions} 	&\multicolumn{1}{c}{mortality}	&\multicolumn{1}{c}{contagious} \\ 
		\midrule
		& \multicolumn{6}{c}{Panel A: Effects on P(\text{Class $\nearrow$})} \\ \addlinespace
		")
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab t5p2c0 t5p2c1 t5p2c2 t5p2c3 t5p2c4 t5p2c5 using "$PROJ_PATH/output/01_paper/table_05.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{6}{c}{Panel B: Effects on P(\text{Class $\searrow$})} \\ \addlinespace") nomtitles nonum
keep(patient) b(%12.3f) se(%12.3f)
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab t5p3c0 t5p3c1 t5p3c2 t5p3c3 t5p3c4 t5p3c5 using "$PROJ_PATH/output/01_paper/table_05.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{6}{c}{Panel C: Effects on P(\text{White collar})} \\ \addlinespace") nomtitles nonum
keep(patient) b(%12.3f) se(%12.3f) 
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab t5p4c0 t5p4c1 t5p4c2 t5p4c3 t5p4c4 t5p4c5 using "$PROJ_PATH/output/01_paper/table_05.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{6}{c}{Panel D: Effects on P(\text{Skilled +})} \\ \addlinespace") nomtitles nonum
keep(patient) b(%12.3f) se(%12.3f)
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab t5p5c0 t5p5c1 t5p5c2 t5p5c3 t5p5c4 t5p5c5 using "$PROJ_PATH/output/01_paper/table_05.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{6}{c}{Panel E: Effects on P(\text{Unskilled})} \\ \addlinespace") nomtitles nonum
keep(patient) b(%12.3f) se(%12.3f)
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab t5p6c0 t5p6c1 t5p6c2 t5p6c3 t5p6c4 t5p6c5 using "$PROJ_PATH/output/01_paper/table_05.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{6}{c}{Panel F: Effects on log occupational wage} \\ \addlinespace") nomtitles nonum
keep(patient) b(%12.3f) se(%12.3f)
prefoot("\addlinespace")
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"));
#delimit cr

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Table 6: Robustness, sample restrictions, occupational outcomes
*********************************************************************************************************************************************
*********************************************************************************************************************************************

eststo drop *
forvalues n = 1/6 {

	* Baseline estimates
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	eststo t6p`n'c0: xtreg ``n'' patient `baseline_controls', `fe'
	estadd ysumm

	* Add multiple siblings
	use "$PROJ_PATH/processed/data/table_06_col_02.dta", clear 
	eststo t6p`n'c1: xtreg ``n'' patient `baseline_controls', `fe'
	estadd ysumm

	* Add multiple patient hhlds.
	use "$PROJ_PATH/processed/data/table_06_col_03.dta", clear
	eststo t6p`n'c2: xtreg ``n'' patient `baseline_controls', `fe'
	estadd ysumm
	
	* Restrict to patients residing in Greater London at the time of admission
	use "$PROJ_PATH/processed/data/table_06_col_04.dta", clear
	eststo t6p`n'c3: xtreg ``n'' patient `baseline_controls', `fe'
	estadd ysumm
	
	* Drop Guy's patients
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	keep if hosp_guys == 0
	bysort sibling_id: keep if _N == 2
	eststo t6p`n'c4: xtreg ``n'' patient `baseline_controls', `fe'
	estadd ysumm
	
	* Restrict to unique within county
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	keep if nodist_match == 1
	bysort sibling_id: keep if _N == 2
	eststo t6p`n'c5: xtreg ``n'' patient `baseline_controls', `fe'
	estadd ysumm
	
	* Restrict to hospital-census county of residence match
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	keep if nodist_match == 1 & rescty_match == 1
	bysort sibling_id: keep if _N == 2
	eststo t6p`n'c6: xtreg ``n'' patient `baseline_controls', `fe'
	estadd ysumm
	
}

#delimit ;
esttab t6p1c0 t6p1c1 t6p1c2 t6p1c3 t6p1c4 t6p1c5 t6p1c6 using "$PROJ_PATH/output/01_paper/table_06.tex", `booktabs_default_options' replace
keep(patient) b(%12.3f) se(%12.3f) nomtitles 
	posthead("
		&\multicolumn{1}{c}{Baseline}	&\multicolumn{1}{c}{Add multiple}	&\multicolumn{1}{c}{Add multiple}	&\multicolumn{1}{c}{County of}	&\multicolumn{1}{c}{Drop Guy's}	&\multicolumn{1}{c}{Unique within}	&\multicolumn{1}{c}{Hospital-census} \\
		&\multicolumn{1}{c}{estimate}	&\multicolumn{1}{c}{siblings}		&\multicolumn{1}{c}{patient hhlds.}	&\multicolumn{1}{c}{London only}&\multicolumn{1}{c}{Hospital}	&\multicolumn{1}{c}{census county} 	&\multicolumn{1}{c}{county match} 	 \\ 
		\midrule
		& \multicolumn{7}{c}{Panel A: Effects on P(\text{Class $\nearrow$})} \\ \addlinespace
		")
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab t6p2c0 t6p2c1 t6p2c2 t6p2c3 t6p2c4 t6p2c5 t6p2c6 using "$PROJ_PATH/output/01_paper/table_06.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{7}{c}{Panel B: Effects on P(\text{Class $\searrow$})} \\ \addlinespace") nomtitles nonum 
keep(patient) b(%12.3f) se(%12.3f)
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab t6p3c0 t6p3c1 t6p3c2 t6p3c3 t6p3c4 t6p3c5 t6p3c6 using "$PROJ_PATH/output/01_paper/table_06.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{7}{c}{Panel C: Effects on P(\text{White collar})} \\ \addlinespace") nomtitles nonum 
keep(patient) b(%12.3f) se(%12.3f)
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab t6p4c0 t6p4c1 t6p4c2 t6p4c3 t6p4c4 t6p4c5 t6p4c6 using "$PROJ_PATH/output/01_paper/table_06.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{7}{c}{Panel D: Effects on P(\text{Skilled +})} \\ \addlinespace") nomtitles nonum 
keep(patient) b(%12.3f) se(%12.3f) 
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab t6p5c0 t6p5c1 t6p5c2 t6p5c3 t6p5c4 t6p5c5 t6p5c6 using "$PROJ_PATH/output/01_paper/table_06.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{7}{c}{Panel E: Effects on P(\text{Unskilled})} \\ \addlinespace") nomtitles nonum 
keep(patient) b(%12.3f) se(%12.3f)
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab t6p6c0 t6p6c1 t6p6c2 t6p6c3 t6p6c4 t6p6c5 t6p6c6 using "$PROJ_PATH/output/01_paper/table_06.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{7}{c}{Panel F: Effects on log occupational wage} \\ \addlinespace") nomtitles nonum 
keep(patient) b(%12.3f) se(%12.3f)
prefoot("\addlinespace")
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"));
#delimit cr

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Table 7: Robustness, occupational status
*********************************************************************************************************************************************
*********************************************************************************************************************************************

eststo drop *
foreach n of numlist 1/5 {

	* Column 1: Baseline estimates
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear
	eststo t7p`n'c0: xtreg ``n'' patient `baseline_controls', `fe'
	estadd ysumm
	
	* Column 2: Use highest occupation among father, mother and HH head for child SES
	use "$PROJ_PATH/processed/data/table_07_col_02.dta", clear
	eststo t7p`n'c1: xtreg ``n'' patient `baseline_controls', `fe'
	estadd ysumm

	* Column 3: Use mother's occupation and then HH head's occupation if father's occupation is missing
	use "$PROJ_PATH/processed/data/table_07_col_03.dta", clear
	eststo t7p`n'c2: xtreg ``n'' patient `baseline_controls', `fe'
	estadd ysumm
		
	* Column 4: Recode missing occupation as worst occupation
	use "$PROJ_PATH/processed/data/table_07_col_04.dta", clear
	eststo t7p`n'c3: xtreg ``n'' patient `baseline_controls', `fe'
	estadd ysumm
	
	* Column 5: Recode missing occupation as best occupation
	use "$PROJ_PATH/processed/data/table_07_col_05.dta", clear
	eststo t7p`n'c4: xtreg ``n'' patient `baseline_controls', `fe'
	estadd ysumm
	
}

#delimit ;
esttab t7p1c0 t7p1c1 t7p1c2 t7p1c3 t7p1c4 using "$PROJ_PATH/output/01_paper/table_07.tex", `booktabs_default_options' replace
keep(patient) b(%12.3f) se(%12.3f) nomtitles 
	posthead("
		&\multicolumn{1}{c}{Baseline}	&\multicolumn{1}{c}{Highest}		&\multicolumn{1}{c}{Impute}	&\multicolumn{1}{c}{High class}		&\multicolumn{1}{c}{Low class}		\\
		&\multicolumn{1}{c}{estimate}	&\multicolumn{1}{c}{household SES}	&\multicolumn{1}{c}{household SES}	&\multicolumn{1}{c}{if missing}		&\multicolumn{1}{c}{if missing} 	\\ 
		\midrule
		& \multicolumn{5}{c}{Panel A: Effects on P(\text{Class $\nearrow$})} \\ \addlinespace
		")
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab t7p2c0 t7p2c1 t7p2c2 t7p2c3 t7p2c4 using "$PROJ_PATH/output/01_paper/table_07.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{5}{c}{Panel B: Effects on P(\text{Class $\searrow$})} \\ \addlinespace") nomtitles nonum
keep(patient) b(%12.3f) se(%12.3f)
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab t7p3c0 t7p3c1 t7p3c2 t7p3c3 t7p3c4 using "$PROJ_PATH/output/01_paper/table_07.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{5}{c}{Panel C: Effects on P(\text{White collar})} \\ \addlinespace") nomtitles nonum
keep(patient) b(%12.3f) se(%12.3f) 
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab t7p4c0 t7p4c1 t7p4c2 t7p4c3 t7p4c4 using "$PROJ_PATH/output/01_paper/table_07.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{5}{c}{Panel D: Effects on P(\text{Skilled +})} \\ \addlinespace") nomtitles nonum
keep(patient) b(%12.3f) se(%12.3f)
prefoot("\addlinespace")
stats(ymean, fmt(%12.3f) labels(`"Mean of Y"') layout("@"))
postfoot("\midrule");

esttab t7p5c0 t7p5c1 t7p5c2 t7p5c3 t7p5c4 using "$PROJ_PATH/output/01_paper/table_07.tex", `booktabs_default_options' append
prehead("") posthead("& \multicolumn{5}{c}{Panel E: Effects on P(\text{Unskilled})} \\ \addlinespace") nomtitles nonum
keep(patient) b(%12.3f) se(%12.3f)
prefoot("\addlinespace")
stats(ymean N, fmt(%12.3f %9.0fc) labels(`"Mean of Y"' `"N"') layout("@" "\multicolumn{1}{c}{@}"));
#delimit cr

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Figure 1: Robustness to tolerance for mismatched names 
*********************************************************************************************************************************************
*********************************************************************************************************************************************

foreach n of numlist 1/10 {	
	forvalues x = 1(1)9 {
		local bot = 1 - (`x'-1)*0.025
		if `n' == 7 {
			local jw_restrict "jw_sname >= `bot' & max(jw_fname_orig,jw_fname_edit) >= `bot'"
			
			use "$PROJ_PATH/processed/data/table_04_schooling_analysis_data.dta" if `jw_restrict', clear
			bysort sibling_id: keep if _N == 2
			
			xtreg scholar patient `scholar_controls', `fe'	
		}
		else if `n' == 8 {
			local jw_restrict "jw_sname >= `bot' & max(jw_fname_orig,jw_fname_edit) >= `bot'"
		
			use "$PROJ_PATH/processed/data/table_04_pre_existing_analysis_data.dta" if `jw_restrict', clear
			bysort sibling_id: keep if _N == 2
			
			replace disab_any = disab_any/10
			
			xtreg disab_any patient `disability_controls', `fe'
		}
		else if `n' == 9 {
			local jw_restrict "jw_sname >= `bot' & max(jw_fname_orig,jw_fname_edit) >= `bot'"
			
			use "$PROJ_PATH/processed/data/table_04_disability_analysis_data.dta" if `jw_restrict', clear
			bysort sibling_id: keep if _N == 2

			replace disab_any = disab_any/10
			
			xtreg disab_any patient `disability_controls', `fe'	
		}
		else if `n' == 10 {
			local jw_restrict "jw_sname_ICEM >= `bot' & max(jw_fname_orig_ICEM,jw_fname_edit_ICEM) >= `bot' & jw_sname >= `bot' & max(jw_fname_orig,jw_fname_edit) >= `bot'"
			
			use "$PROJ_PATH/processed/data/table_04_col_10.dta" if `jw_restrict', clear
			bysort sibling_id: keep if _N == 2
			
			replace disab_any = disab_any/10
			
			xtreg disab_any patient `baseline_controls', `fe'
		}	
		else {
			local jw_restrict "jw_sname_ICEM >= `bot' & max(jw_fname_orig_ICEM,jw_fname_edit_ICEM) >= `bot' & jw_sname >= `bot' & max(jw_fname_orig,jw_fname_edit) >= `bot'"
			
			use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta" if `jw_restrict', clear
			bysort sibling_id: keep if _N == 2
			
			xtreg ``n'' patient `baseline_controls', `fe'
		}
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
foreach n of numlist 1/10 {
	append using `jw_`n''
}

label define depvarlab 1 "Class Up" 2 "Class Down" 3 "White Collar" 4 "Skilled +" 5 "Unskilled" 6 "Log Wage" 7 "Participation in Schooling" 8 "Pre-Existing Disability" 9 "Short-Run Disability" 10 "Long-Run Disability", replace
la val outcome depvarlab

tempfile fig1
save `fig1', replace

// Panel (a): Long-run outcomes
use `fig1' if outcome <= 6, clear

twoway ///
	(scatter Pat_Coef JW_Threshold, mcolor("115 115 115") msymbol(square)) ///
	(rspike H L JW_Threshold, lcolor("115 115 115") msymbol(none) lwidth(medthin)), ///
	yline(0, lcolor(gs7) lpattern(dash) lwidth(thin)) ///
	ylabel(, nogrid angle(horizontal)) yscale(nofextend) ytitle("Coefficient on Patient") ///
	xscale(nofextend) xtitle("Maximum Jaro-Winkler Distance for Matching Names") ///
	scheme(s2mono) subtitle(,bcolor(white)) ///
	by(outcome, cols(2) legend(off) graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) note(""))

graph export "$PROJ_PATH/output/01_paper/figure_01a.eps", as(eps) preview(off) replace
graph export "$PROJ_PATH/output/01_paper/figure_01a.pdf", replace
graph export "$PROJ_PATH/output/01_paper/figure_01a.tif", width(600) replace

* Panel (b): Mechanisms
use `fig1' if outcome > 6, clear

twoway ///
	(scatter Pat_Coef JW_Threshold, mcolor("115 115 115") msymbol(square)) ///
	(rspike H L JW_Threshold, lcolor("115 115 115") msymbol(none) lwidth(medthin)), ///
	yline(0, lcolor(gs7) lpattern(solid) lwidth(thin)) ///
	ylabel(, nogrid angle(horizontal)) yscale(nofextend) ytitle("Coefficient on Patient") ///
	xscale(nofextend) xtitle("Maximum Jaro-Winkler Distance for Matching Names") ///
	scheme(s2mono) subtitle(,bcolor(white)) ///
	by(outcome, cols(2) legend(off) graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) note(""))
	
graph export "$PROJ_PATH/output/01_paper/figure_01b.eps", as(eps) preview(off) replace
graph export "$PROJ_PATH/output/01_paper/figure_01b.pdf", replace
graph export "$PROJ_PATH/output/01_paper/figure_01b.tif", width(600) replace

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Figure 2: Robustness to restrictions on similar names
*********************************************************************************************************************************************
*********************************************************************************************************************************************

local simlist "4 6 8 10 15 20 50 100 1000"

local numitems : word count `simlist'
	di "`numitems'"

foreach n of numlist 1/10 {	
	forvalues x = 1(1)`numitems' {
		local y : word `x' of `simlist'
		di "`y'"
		
		if `n' == 7 {
			
			* Schooling
			use "$PROJ_PATH/processed/data/figure_02b_schooling.dta" if sample_`y' == 1, clear
			
			egen first_sib = min(brthord), by(sibling_id)
			gen older_sib = (brthord == first_sib)
			drop first_sib
			
			xtreg scholar patient `scholar_controls', `fe'
			
		}
		else if `n' == 8 {
			
			* Pre-existing disability
			use "$PROJ_PATH/processed/data/figure_02b_pre_exist.dta" if sample_`y' == 1, clear
	
			egen first_sib = min(brthord), by(sibling_id)
			gen older_sib = (brthord == first_sib)
			drop first_sib

			replace disab_any = disab_any/10
			xtreg disab_any patient `disability_controls', `fe'	
		}
		else if `n' == 9 {
			
			* Childhood disability
			use "$PROJ_PATH/processed/data/figure_02b_disability.dta" if sample_`y' == 1, clear
			
			egen first_sib = min(brthord), by(sibling_id)
			gen older_sib = (brthord == first_sib)
			drop first_sib

			replace disab_any = disab_any/10
			xtreg disab_any patient `disability_controls', `fe'	
		}
		else if `n' <= 6 | `n' == 10 {
		
			if `n' == 10 {
				
				* Long-run disability
				use "$PROJ_PATH/processed/data/figure_02b_long_run_disability.dta" if sample_`y' == 1, clear
				
				egen first_sib = min(brthord), by(sibling_id)
				gen older_sib = (brthord == first_sib)
				drop first_sib
			
				replace disab_any = disab_any/10
			}
			else {
				
				* Occupational outcomes 
				use "$PROJ_PATH/processed/data/figure_02a.dta" if sample_`y' == 1, clear
				
				egen first_sib = min(brthord), by(sibling_id)
				gen older_sib = (brthord == first_sib)
				drop first_sib
			}
			
			
			xtreg ``n'' patient `baseline_controls', `fe'
		}
		
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
foreach n of numlist 1/10 {
	append using `jw_`n''
}

label define depvarlab 1 "Class Up" 2 "Class Down" 3 "White Collar" 4 "Skilled +" 5 "Unskilled" 6 "Log Wage" 7 "Participation in Schooling" 8 "Pre-Existing Disability" 9 "Short-Run Disability" 10 "Long-Run Disability", replace
la val outcome depvarlab

egen X = seq(), by(outcome)

tostring Sim_Records, replace
labmask X, values(Sim_Records)

tempfile fig2
save `fig2', replace

* Panel (a) Occupational outcomes 
use `fig2' if outcome <= 6, clear
	
twoway ///
	(scatter Pat_Coef X, mcolor("115 115 115") msymbol(square)) 	///
	(rspike H L X, lcolor("115 115 115") msymbol(none) lwidth(medthin)), ///
	yline(0, lcolor(gs7) lpattern(dash) lwidth(thin)) ///
	ylabel(, nogrid angle(horizontal)) ///
	yscale(nofextend) ///
	ytitle("Coefficient on Patient") ///
	xlabel(1(2)9, valuelabel) xscale(range(0 10)) ///
	xtitle("Number of Similar Records") ///
	scheme(s2mono) subtitle(,bcolor(white)) ///
	by(outcome, cols(2) legend(off) graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) note(""))
		
graph export "$PROJ_PATH/output/01_paper/figure_02a.eps", as(eps) preview(off) replace
graph export "$PROJ_PATH/output/01_paper/figure_02a.pdf", replace
graph export "$PROJ_PATH/output/01_paper/figure_02a.tif", width(600) replace

* Panel (b) Mechanisms 
use `fig2' if outcome > 6, clear

twoway ///
	(scatter Pat_Coef X, mcolor("115 115 115") msymbol(square)) 	///
	(rspike H L X, lcolor("115 115 115") msymbol(none) lwidth(medthin)), ///
	yline(0, lcolor(gs7) lpattern(dash) lwidth(thin)) ///
	ylabel(, nogrid angle(horizontal)) ///
	yscale(nofextend) ///
	ytitle("Coefficient on Patient") ///
	xlabel(1(2)9, valuelabel) xscale(range(0 10)) ///
	xtitle("Number of Similar Records") ///
	scheme(s2mono) subtitle(,bcolor(white)) ///
	by(outcome, cols(2) legend(off) graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) note(""))
		
graph export "$PROJ_PATH/output/01_paper/figure_02b.eps", as(eps) preview(off) replace
graph export "$PROJ_PATH/output/01_paper/figure_02b.pdf", replace
graph export "$PROJ_PATH/output/01_paper/figure_02b.tif", width(600) replace

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Figure 3: Robustness to tolerance for age gap when linking
*********************************************************************************************************************************************
*********************************************************************************************************************************************

foreach n of numlist 1/10 {	
	forvalues x = 0(1)3 {
		if `n' == 7 {
			local age_gap_restrict "age_dist <= `x'"
			
			use "$PROJ_PATH/processed/data/table_04_schooling_analysis_data.dta" if `age_gap_restrict', clear
			bysort sibling_id: keep if _N == 2

			xtreg scholar patient `scholar_controls', `fe'	
		}
		else if `n' == 8 {
			local age_gap_restrict "age_dist <= `x'"
		
			use "$PROJ_PATH/processed/data/table_04_pre_existing_analysis_data.dta" if `age_gap_restrict', clear
			bysort sibling_id: keep if _N == 2						

			replace disab_any = disab_any/10
			xtreg disab_any patient `disability_controls', `fe'
		}
		else if `n' == 9 {
			local age_gap_restrict "age_dist <= `x'"
		
			use "$PROJ_PATH/processed/data/table_04_disability_analysis_data.dta" if `age_gap_restrict', clear
			bysort sibling_id: keep if _N == 2
			
			replace disab_any = disab_any/10
			xtreg disab_any patient `disability_controls', `fe'
		}
		else if `n' == 10 {
			local age_gap_restrict "age_dist_child <= `x' & age_dist_ICEM <= `x'"
			
			use "$PROJ_PATH/processed/data/table_04_col_10.dta" if `age_gap_restrict', clear
			bysort sibling_id: keep if _N == 2
			
			replace disab_any = disab_any/10
			xtreg disab_any patient `baseline_controls', `fe'
		}
		else {
			local age_gap_restrict "age_dist_child <= `x' & age_dist_ICEM <= `x'"
			
			use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta" if `age_gap_restrict', clear
			bysort sibling_id: keep if _N == 2
				
			xtreg ``n'' patient `baseline_controls', `fe'	
		}
		matrix b`x' = e(b)
		matrix v`x' = e(V)
		matrix n`x' = e(N)
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
foreach n of numlist 1/10 {
	append using `age_gap_`n''
}

label define depvarlab 1 "Class Up" 2 "Class Down" 3 "White Collar" 4 "Skilled +" 5 "Unskilled" 6 "Log Wage" 7 "Participation in Schooling" 8 "Pre-Existing Disability" 9 "Short-Run Disability" 10 "Long-Run Disability", replace
la val outcome depvarlab

tempfile fig3
save `fig3', replace

// Panel (a): Long-run outcomes
use `fig3' if outcome <= 6, clear

twoway ///
	(scatter Pat_Coef age_gap, mcolor("115 115 115") msymbol(square)) ///
	(rspike H L age_gap, lcolor("115 115 115") msymbol(none) lwidth(medthin)), ///
	yline(0, lcolor(gs7) lpattern(dash) lwidth(thin)) ///
	ylabel(, nogrid angle(horizontal)) ytitle("Coefficient on Patient") ///
	xlabel(0(1)3) xtick(0(1)3) xscale(nofextend) xtitle("Maximum Age Gap Between Sources When Linking (In Years)") ///
	scheme(s2mono) subtitle(,bcolor(white)) ///
	by(outcome, cols(2) legend(off) graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) note(""))		

graph export "$PROJ_PATH/output/01_paper/figure_03a.eps", as(eps) preview(off) replace
graph export "$PROJ_PATH/output/01_paper/figure_03a.pdf", replace
graph export "$PROJ_PATH/output/01_paper/figure_03a.tif", width(600) replace

// Panel (b): Mechanisms
use `fig3' if outcome > 6, clear

twoway ///
	(scatter Pat_Coef age_gap, mcolor("115 115 115") msymbol(square)) ///
	(rspike H L age_gap, lcolor("115 115 115") msymbol(none) lwidth(medthin)), ///
	yline(0, lcolor(gs7) lpattern(dash) lwidth(thin)) ///
	ylabel(, nogrid angle(horizontal)) ytitle("Coefficient on Patient") ///
	xlabel(0(1)3) xtick(0(1)3) xscale(nofextend) xtitle("Maximum Age Gap Between Sources When Linking (In Years)") ///
	scheme(s2mono) subtitle(,bcolor(white)) ///
	by(outcome, cols(2) legend(off) graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) note(""))		

graph export "$PROJ_PATH/output/01_paper/figure_03b.eps", as(eps) preview(off) replace
graph export "$PROJ_PATH/output/01_paper/figure_03b.pdf", replace
graph export "$PROJ_PATH/output/01_paper/figure_03b.tif", width(600) replace

*********************************************************************************************************************************************

disp "DateTime: $S_DATE $S_TIME"

* EOF
