version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 03_intext_statistics.do
* PURPOSE: This do file generates the numbers mentioned in the text of the paper.
************

// Baseline sample restrictions that apply to all samples 

* Drop outliers in birth order and sibship size: max_brthord, sib_size
* Restrict to cohorts of interest: valid_age
* Drop if in military 
* Drop twins 
* Exclude patients with uncategorized cause of admission: unassigned
* Exclude patients with missing HDI: resid_mort
* Exclude patients with outlier number of hospital visits: tot_visits 
* Restrict to patients from birth cohorts of interest: patins

local baseline_restrictions 		"max_brthord <= 13 & sib_size <= 11 & valid_age == 1 & military == 0 & twins == 0 & unassigned == 0 & resid_mort != . & tot_visits <= 9 & patins == 1"

// Sample restrictions to pass as argument to _restrictions do file - occupation analysis
local occupation_restrictions_ICEM 	"jw_sname_ICEM >= 0.80 & max(jw_fname_orig_ICEM,jw_fname_edit_ICEM) >= 0.80 & similar_10_ICEM <= 20"				
local occupation_restrictions_HOSP 	"jw_sname >= 0.80 & max(jw_fname_orig,jw_fname_edit) >= 0.80 & similar_10 <= 20 & age_dist_child <= 3"
local occupation_restrictions 		"`occupation_restrictions_ICEM' & `occupation_restrictions_HOSP'"

// Sample restrictions to pass as argument to _restrictions do file - mechanisms
local scholar_restrictions			"sex != . & jw_sname >= 0.80 & max(jw_fname_orig,jw_fname_edit) >= 0.80 & similar_10 <= 20 & age_dist <= 3 & age_child >= 5 & age_child <= 10"		
local disability_restrictions 		"sex != . & jw_sname >= 0.80 & max(jw_fname_orig,jw_fname_edit) >= 0.80 & similar_10 <= 20 & age_dist <= 3"

// Restriction to ensure we have patient and sibling from each household
local sibling_restrictions 			"samp_pat == 1 & samp_sib == 1 & insample == 1"

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

// Share of inpatients who died and share under 2 who died (p. 7)

/*

"Among the cohorts in our study, the average in-hospital mortality rate was 11 percent for all inpatients and 26 percent for individuals admitted before the age of two (Online Appendix Figure A3)."

*/

use "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear 

keep if byr_ub_HOSP >= 1870 & byr_lb_HOSP <= 1890
keep if admitage <= 11
keep if admityr >= 1870 & admityr <= 1902

sum died
local mr_total = string(r(mean)*100,"%9.2f")

sum died if admitage <= 1
local mr_infant = string(r(mean)*100,"%9.2f")

display "Overall mortality rate in hospital: `mr_total'%. Infant mortality rate [age 0,1]: `mr_infant'%"


*********************************************************************************************************************************************

// Share of physician patients among all patients at Barts and Guys (among cohorts in our sample (p. 7, fn. 4)

/*

"Inpatient hospital admissions in nineteenth-century London were categorized as physician or surgeon patients. Among cohorts in our samples, physician patients accounted for 35 and 41 percent of inpatients at Barts and GOSH, respectively."

*/

use "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear 

keep if hospid == 1 & admitage <= 11 & admityr >= 1870 & admityr <= 1902 & byr_ub_HOSP >= 1870 & byr_lb_HOSP <= 1890
sum doctor
local physician_share = string(r(mean)*100,"%9.2f")

display "Share of Barts inpatients from cohorts in our sample who were physician patients: `physician_share'%"

use "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear 

keep if hospid == 2 & admitage <= 11 & admityr >= 1870 & admityr <= 1902 & byr_ub_HOSP >= 1870 & byr_lb_HOSP <= 1890
sum doctor
local physician_share = string(r(mean)*100,"%9.2f")

display "Share of GOSH inpatients from cohorts in our sample who were physician patients: `physician_share'%"

*********************************************************************************************************************************************

// HDI in main sample (p. 7)

/* 

This variable is standardized on a 0 to 1 scale with higher values implying greater severity and has a mean value of 0.28 and standard deviation of 0.10 among hospital patients in the main estimation sample."

*/

use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta" if patient == 1, clear
sum resid_mort, d
local mean_mr = string(r(mean),"%12.2f")
local sd_mr = string(r(sd),"%12.2f")

display "Among the hospital patients in the estimation sample, the mean value of the mortality index is `mean_mr' and standard deviation is `sd_mr'."

*********************************************************************************************************************************************

// Solicitors and barristers (p. 11, fn. 8)

/*

We also replace the Williamson (1980, 1982) wage estimates for solicitors and barristers, which are outliers in the data, with the average occupational wage in the highest HISCLASS category. This adjustment affects three observations in our estimation sample and has no substantive bearing on the results.

*/

forvalues y = 1901(10)1911 {
	
	use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta" if outcomeyr == `y', clear

	keep ia_hisco ia_occ ia_occode 
	rename ia_hisco  hisco 
	rename ia_occ Occ 
	rename ia_occode Occode

	williamson `y'
	
	rename wage`y' wage
	
	tempfile wage`y'
	save `wage`y'', replace
	
}

clear
forvalues y = 1901(10)1911 {
	append using `wage`y''
}

keep if wage != .

count if wage > 1000

*********************************************************************************************************************************************

// Williamson wages by social class (p. 11)

/*

"The occupational wages are consistent with our classification of occupational rank into four groups, as the average occupational wage in 1911 among white collar occupations is 87 percent higher than skilled occupations, while occupational wages in semi-skilled and unskilled occupations are 9 percent and 40 percent lower, respectively."

*/

use "$PROJ_PATH/processed/intermediate/occupations/williamson_avg_wage4_1911.dta", clear 

forvalues i = 1(1)4 {
	sum avg_wage4_1911 if ia_hisc4 == `i', d
	local wage_`i' = r(mean)
}

local wc_premium = (`wage_1' - `wage_2')*100/`wage_2'
local ss_disadv = (`wage_2' - `wage_3')*100/`wage_2'
local unsk_disadv = (`wage_2' - `wage_4')*100/`wage_2'

di "White collar premium: `wc_premium'"
di "Semi-skilled disadvantage: `ss_disadv'"
di "Unskilled premium: `unsk_disadv'"

*********************************************************************************************************************************************

// Marital status as a proxy for social status for women (p. 11, fn. 10)

use "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_1911_identifiers.dta", clear
merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_1911_demographic.dta", assert(2 3) keep(3) nogen keepusing(Age Sex Mar)
merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_1911_occupation.dta", assert(2 3) keep(3) nogen keepusing(hisco Occ Occode)
merge m:1 hisco using "$PROJ_PATH/processed/intermediate/occupations/hisco_to_hisclass.dta", keep(1 3) nogen keepusing(hisclass)
gen unskilled = inrange(hisclass,10,12)

preserve
	collapse (mean) nbr_unskilled = unskilled, by(ParID)
	tempfile neighborhood
	save `neighborhood', replace
restore 

merge m:1 ParID using `neighborhood', assert(3) nogen

keep if Sex == 2 & Age >=18 & Age <= 45

gen single = (Mar == 1) 

/*

"The share of women who were single declined from 83 percent at age 21 to 47 percent at age 26, 28 percent at age 31, and 20 percent at age 40."

*/

tab Age single, row

gen in_laborforce = !missing(hisclass)
gen white_collar = inrange(hisclass,1,5)

/*

"For this reason, single women were also more likely to be in the labor force (75 percent compared to 14 percent for married
women). Furthermore, conditional on working, single women were more likely to have unskilled occupations (33 versus 26 percent). Thus, in our setting, marital status also represents a proxy for socioeconomic well-being."

*/

sum in_laborforce if single == 1
sum in_laborforce if single == 0

sum unskilled if in_laborforce == 1 & single == 1
sum unskilled if in_laborforce == 1 & single == 0

*********************************************************************************************************************************************

// This measure suggests that compliance with compulsory schooling was relatively high as 64 to 82 percent  of children ages 5 to 10 were recorded as a "scholar," ... (p. 13)

use "$PROJ_PATH/processed/data/figure_a05_a06.dta" if Age >=5 & Age <= 10, clear

collapse (mean) in_laborforce in_school, by(Age Year)

list in 1/6

/* ... while fewer than 1 percent  of children age 10 and below reported a gainful occupation. */

use "$PROJ_PATH/processed/data/figure_a05_a06.dta" if Age <= 10, clear

sum in_laborforce

*********************************************************************************************************************************************

// HDI in hospital population (p. 17)

/*

In the population of hospital patients, the mean value of the HDI is 0.30 and the standard deviation is 0.13.

*/

use "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear 

sum resid_mort, d
local mean_mr = string(r(mean),"%12.2f")
local sd_mr = string(r(sd),"%12.2f")

display "Among the hospital patients in the estimation sample, the mean value of the mortality index is `mean_mr' and standard deviation is `sd_mr'"

*********************************************************************************************************************************************

// What are the most common causes of admission at the mean, +/- 1 SD? (p. 17)

/*

"To fix ideas, a one-standard deviation increase in the HDI relative to the mean corresponds to being admitted for heart disease (morbus cordis) or sequela of diphtheria (diphtheric paralysis) as opposed to the causes of admission around the mean value of the HDI such as rheumatism and diseases of the hip or knee.

*/

use "$PROJ_PATH/processed/intermediate/final_build/occupational_analysis_setup.dta", clear

* Ensure that occupation is non-missing for parent and child
keep if ia_hisc4 != . & pophisc4 != .

* Ensure sample includes patient and sibling from each household
gen occupation_restrictions = ( `baseline_restrictions' & `occupation_restrictions')
do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/_sibling_restrictions/06.02_occupational_analysis_restrictions.do" occupation_restrictions

* Restrict to estimation sample
keep if `sibling_restrictions'

gsort censusyr sibling_id RecID_child 
xtset sibling_id

keep if patient == 1

sum resid_mort
local mean_mr = string(r(mean),"%12.2fc")
local sd_mr = string(r(sd),"%12.2fc")

keep censusyr RecID_child outcomeyr RecID_adult
merge 1:m censusyr RecID_child outcomeyr RecID_adult using "$PROJ_PATH/processed/intermediate/crosswalks/occupational_hosp_icem_crosswalk.dta", keepusing(regid) assert(2 3) keep(3) nogen
keep regid 
merge 1:1 regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", assert(2 3) keep(3) nogen keepusing(coa resid_mort disease_cleaned)

bysort coa: gen coa_obs = _N

* At final sample mean
tab coa if coa_obs > 10 & resid_mort >= `mean_mr' - 0.0025 & resid_mort <= `mean_mr' + 0.0025, sort

* At mean + 1 sd
tab coa if coa_obs > 10 & resid_mort >= `mean_mr' + `sd_mr' - 0.0025 & resid_mort <= `mean_mr' + `sd_mr' + 0.0025, sort

*********************************************************************************************************************************************

// Mobility rates in final sample and synthetic population (p. 18)

/*

"The rates of upward and downward mobility in the synthetic linked population are somewhat lower than in our estimation sample at 31.8 and 24.7 percent compared to 35.7 and 26.0."

*/

* Compute upward and downward mobility shares in synthetic linked population 

use "$PROJ_PATH/processed/data/table_a05_panel_04.dta", clear

egen upward_pop = total(count_pop*(ia_hisc4 < pophisc4))
egen dnward_pop = total(count_pop*(ia_hisc4 > pophisc4))

replace upward_pop = upward_pop*100/tot_pop
replace dnward_pop = dnward_pop*100/tot_pop

sum upward_pop
sum dnward_pop

*********************************************************************************************************************************************

// Share of patients admitted from outside of London by hospital (p. 21)

use "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear 

gen outside_london = regexm(county_HOSP,"LONDON") == 0

sum outside_london if hospid == 1
local barts_share = string(r(mean)*100,"%9.2f")
sum outside_london if hospid == 2
local gosh_share = string(r(mean)*100,"%9.2f")
sum outside_london if hospid == 5
local guys_share = string(r(mean)*100,"%9.2f")

display "Share of patients from outside London: `barts_share'% at Barts, `gosh_share' at GOSH, and `guys_share' at Guys"

*********************************************************************************************************************************************

// Testing joint significance - separately by cause of admission - downward mobility outcome (p. 24)

/*

"... F-tests indicate that groups of coefficients for causes ofa dmission with the largest effect sizes are jointly significant (p. 24). For example, in Online Appendix A9, the coefficients on admissions for cleft lip, eczema, diphtheria, scarlet fever, bronchitis, and chorea are jointly significant at conventional levels in the specification with downward occupational mobility as the outcome."

*/

local condition_list "abscess pneumonia bronchitis phimosis chorea diphth empyema cleft_palate talipes rickets dis_knee scarlet dis_hip fracture typhoid tuberculosis tub_dis rheumatism pleurisy morbus_cordis harelip eczema fever broncho_pneumonia"

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

reghdfe mobility_dn other_conditions multiple_conditions `condition_list' `baseline_controls', absorb(sibling_id) cluster(sibling_id) 

test harelip eczema diphth scarlet bronchitis chorea 

*********************************************************************************************************************************************

// Admissions by age group (p. 25, fn 18) 

/*

"34.8 percent of patients in our main sample were admitted only at ages 0 to 4, 62.6 percent of patients were
admitted only at ages 5 to 11, and 2.5 percent were admitted during both age ranges."

*/

use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta" if patient == 1, clear

gen admit0to4 = ((admitage0 == 1 | admitage1 == 1 | admitage2 == 1 | admitage3 == 1 | admitage4 == 1) & admitage5 == 0 & admitage6 == 0 & admitage7 == 0 & admitage8 == 0 & admitage9 == 0 & admitage10 == 0 & admitage11 == 0)
gen admit5to11 = (admitage0 == 0 & admitage1 == 0 & admitage2 == 0 & admitage3 == 0 & admitage4 == 0 & (admitage5 == 1 | admitage6 == 1 | admitage7 == 1 | admitage8 == 1 | admitage9 == 1 | admitage10 == 1 | admitage11 == 1))

gen only0to4 = (admit0to4 == 1 & admit5to11 == 0)
sum only0to4
local share_0to4 = string(r(mean)*100,"%9.2f")

gen only5to11 = (admit0to4 == 0 & admit5to11 == 1)
sum only5to11
local share_5to11 = string(r(mean)*100,"%9.2f")

gen both_groups = (admit0to4 == 0 & admit5to11 == 0)
sum both_groups
local share_both = string(r(mean)*100,"%9.2f")

display "Share of patients in main sample admitted only at ages 0 to 4: `share_0to4'"
display "Share of patients in main sample admitted only at ages 5 to 11: `share_5to11'"
display "Share of patients in main sample admitted at ages 0 to 4 and 5 to 11: `share_both'"

*********************************************************************************************************************************************

// Share of sample with variation in own rank and mobility outcomes (Online Appendix B2, p. 10)

use "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", clear

forvalues n = 1(1)5 {
	
	tempvar tot_`n' mobility_variation
	egen tot_`n' = total(``n''== 1), by(sibling_id)
	gen `mobility_variation' = (tot_`n' == 1)
	sum `mobility_variation'
	local share_`n' = string(r(mean)*100,"%9.2f")
}

local min_mobility = min(`share_1', `share_2')
local max_mobility = max(`share_1', `share_2')

local min_own = min(`share_3', `share_4', `share_5')
local max_own = max(`share_3', `share_4', `share_5')

di "Share of sample with variation in mobility outcomes: `min_mobility' to `max_mobility'"
di "Share of sample with variation in own rank outcomes: `min_own' to `max_own'"

*********************************************************************************************************************************************

disp "DateTime: $S_DATE $S_TIME"

* EOF