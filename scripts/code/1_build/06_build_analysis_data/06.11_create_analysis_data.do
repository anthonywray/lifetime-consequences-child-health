version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 06.11_create_analysis_data.do
* PURPOSE: This do file creates the data sets used in estimation
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

local outcome_vars 					"mobility_up mobility_dn top_25 top_50 bot_25 ln_wage scholar disab_any disab_any disab_any"
local social_outcomes 				"nbr_unskilled live_with_parent cty_mover any_child ch_scholar"

// Data sets for single marital status regressions 
local data_1 						"$PROJ_PATH/processed/temp/table_03_singles_analysis_data_2.dta"
local data_2						"$PROJ_PATH/processed/temp/table_03_singles_analysis_data_1.dta"
local data_3 						`""$PROJ_PATH/processed/temp/table_03_singles_analysis_data_1.dta" if link_10 == 1 | link_20 == 1 | link_30 == 1"'

tokenize `outcome_vars'

*********************************************************************
// Table 2: Long-run occupational and intergenerational moblity
*********************************************************************

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

* Save temp file to use to set up data for other tables and figures
save "$PROJ_PATH/processed/temp/table_02_occupational_analysis_data.dta", replace

* Remove restricted variables for public version
drop hhid pid_child RecID_child RecID_adult hh_occ momocc
save "$PROJ_PATH/processed/data/table_02_occupational_analysis_data.dta", replace

*********************************************************************
// Table 4: Mechanisms, group 1: Participation in schooling
*********************************************************************

// Create separate samples for males and females (columns 1 and 2)

forvalues g = 1(1)2 {

	use "$PROJ_PATH/processed/intermediate/final_build/schooling_analysis_setup.dta", clear

	* Ensure sample includes patient and sibling from each household
	gen scholar_restrictions = (`baseline_restrictions' & `scholar_restrictions' & sex == `g')
	do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/_sibling_restrictions/06.04_schooling_analysis_restrictions.do" scholar_restrictions

	* Restrict to estimation sample
	keep if `sibling_restrictions'

	tempfile schooling_`g'
	save `schooling_`g'', replace
}

// Create pooled sample for column 3 using same observations in columns 1 and 2

clear
forvalues g = 1(1)2 {
	append using `schooling_`g''
}

drop older_sib
egen first_sib = min(brthord), by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

gsort censusyr sibling_id RecID
xtset sibling_id

* Save temp file to use to set up data for other tables and figures
save "$PROJ_PATH/processed/temp/table_04_schooling_analysis_data.dta", replace

* Remove restricted variables for public version
drop hhid pid RecID 
save "$PROJ_PATH/processed/data/table_04_schooling_analysis_data.dta", replace

*********************************************************************
// Table 4: Mechanisms, group 2: Pre-existing disability
*********************************************************************

// Create separate samples for males and females (columns 1 and 2)

forvalues g = 1(1)2 {

	use "$PROJ_PATH/processed/intermediate/final_build/pre_existing_analysis_setup.dta", clear

	* Ensure sample includes patient and sibling from each household
	gen disability_restrictions = (`baseline_restrictions' & `disability_restrictions' & sex == `g')
	do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/_sibling_restrictions/06.05_pre_existing_analysis_restrictions.do" disability_restrictions

	* Restrict to estimation sample
	keep if `sibling_restrictions'

	tempfile pre_exist_`g'
	save `pre_exist_`g'', replace
}

// Create pooled sample for column 3 using same observations in columns 1 and 2

clear
forvalues g = 1(1)2 {
	append using `pre_exist_`g''
}
drop older_sib
egen first_sib = min(brthord), by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

sort censusyr sibling_id RecID
xtset sibling_id

* Save temp file to use to set up data for other tables and figures
save "$PROJ_PATH/processed/temp/table_04_pre_existing_analysis_data.dta", replace

* Remove restricted variables for public version
drop hhid pid RecID 
save "$PROJ_PATH/processed/data/table_04_pre_existing_analysis_data.dta", replace


*********************************************************************
// Table 4: Mechanisms, group 3: Childhood disability
*********************************************************************

// Create separate samples for males and females (columns 1 and 2)

forvalues g = 1(1)2 {

	use "$PROJ_PATH/processed/intermediate/final_build/disability_analysis_setup.dta", clear

	* Ensure sample includes patient and sibling from each household
	gen disability_restrictions = (`baseline_restrictions' & `disability_restrictions' & sex == `g')
	do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/_sibling_restrictions/06.06_disability_analysis_restrictions.do" disability_restrictions

	* Restrict to estimation sample
	keep if `sibling_restrictions'

	tempfile disability_`g'
	save `disability_`g'', replace
}

// Create pooled sample for column 3 using same observations in columns 1 and 2

clear
forvalues g = 1(1)2 {
	append using `disability_`g''
}
drop older_sib
egen first_sib = min(brthord), by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

sort censusyr sibling_id RecID
xtset sibling_id

* Save temp file to use to set up data for other tables and figures
save "$PROJ_PATH/processed/temp/table_04_disability_analysis_data.dta", replace

* Remove restricted variables for public version
drop hhid pid RecID 
save "$PROJ_PATH/processed/data/table_04_disability_analysis_data.dta", replace


*********************************************************************
// Table 4: Mechanisms, column 10: Disability in adulthood, males
*********************************************************************

use "$PROJ_PATH/processed/intermediate/final_build/occupational_analysis_setup.dta" if disab_any != ., clear

* Ensure sample includes patient and sibling from each household
gen occupation_restrictions = (`baseline_restrictions' & `occupation_restrictions')
do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/_sibling_restrictions/06.02_occupational_analysis_restrictions.do" occupation_restrictions

* Restrict to estimation sample
keep if `sibling_restrictions'

gsort censusyr sibling_id RecID_child 
xtset sibling_id

* Save temp file to use to set up data for other tables and figures
save "$PROJ_PATH/processed/temp/table_04_col_10.dta", replace

* Remove restricted variables for public version
drop hhid pid_child RecID_child RecID_adult hh_occ ia_occ
save "$PROJ_PATH/processed/data/table_04_col_10.dta", replace

*********************************************************************
// Table 6 Column 2: Add multiple siblings 
*********************************************************************

use "$PROJ_PATH/processed/temp/table_02_occupational_analysis_data.dta", clear
keep sibling_id
duplicates drop
tempfile ids
save `ids', replace

use "$PROJ_PATH/processed/intermediate/final_build/occupational_analysis_setup.dta" if ia_hisc4 != . & pophisc4 != ., clear

local samp_pat "samp_pat = max(patient == 1 & insample == 1 & age_diff == 0), by(sibling_id)"
local samp_sib "samp_sib = max(patient == 0 & insample == 1 & age_diff <= 8), by(sibling_id)"

gen flag_extra_sibpat = 0

gen insample = (`baseline_restrictions' & `occupation_restrictions') 

* Compute age difference between siblings

preserve

	keep if patient == 1 & insample == 1
	keep sibling_id age_child
	bysort sibling_id age_child: keep if _n == 1
	egen temp_id = seq(), by(sibling_id)
	sum temp_id
	local max_obs = r(max)
	rename age_child patage
	reshape wide patage, i(sibling_id) j(temp_id)
	tempfile age_diff
	save `age_diff', replace

restore

capture drop age_diff
tempvar sortorder
gen `sortorder' = _n

merge m:1 sibling_id using `age_diff', assert(1 3) keep(1 3) nogen

forvalues x = 1(1)`max_obs' {
	gen temp`x' = abs(age_child - patage`x')
}
egen age_diff = rowmin(temp1-temp`max_obs')
drop temp* patage*
sort `sortorder'
drop `sortorder'

egen `samp_pat'
egen `samp_sib'

gen base_sample = (samp_pat == 1 & samp_sib == 1 & insample == 1)

* Drop households with multiple patients

egen mult_pat_hh = total(insample == 1 & patient == 1 & samp_pat == 1), by(sibling_id)
replace flag_extra_sibpat = 1 if mult_pat_hh > 1 & !missing(mult_pat_hh)
drop mult_pat_hh insample samp_pat samp_sib

gen insample = (base_sample == 1 & flag_extra_sibpat == 0 & `baseline_restrictions' & `occupation_restrictions')
egen `samp_pat'
egen `samp_sib'	

drop flag_extra_sibpat base_sample

merge m:1 sibling_id using `ids', assert(1 3) keep(3) nogen

* Define variable for oldest sibling in household in sample

egen first_sib = min(brthord) if insample == 1 & samp_pat == 1 & samp_sib == 1, by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

keep if `sibling_restrictions'

xtset sibling_id

* Remove restricted variables for public version
drop hhid pid_child RecID_child RecID_adult hh_occ ia_occ
save "$PROJ_PATH/processed/data/table_06_col_02.dta", replace


*********************************************************************
// Table 6 Column 3: Add multiple patient hhlds. 
*********************************************************************

use "$PROJ_PATH/processed/intermediate/final_build/occupational_analysis_setup.dta" if ia_hisc4 != . & pophisc4 != ., clear

local samp_pat "samp_pat = max(patient == 1 & insample == 1 & age_diff == 0), by(sibling_id)"
local samp_sib "samp_sib = max(patient == 0 & insample == 1 & age_diff <= 8), by(sibling_id)"

gen flag_extra_sibpat = 0

gen insample = (`baseline_restrictions' & `occupation_restrictions') 

* Compute age difference between siblings

preserve

	keep if patient == 1 & insample == 1
	keep sibling_id age_child
	bysort sibling_id age_child: keep if _n == 1
	egen temp_id = seq(), by(sibling_id)
	sum temp_id
	local max_obs = r(max)
	rename age_child patage
	reshape wide patage, i(sibling_id) j(temp_id)
	tempfile age_diff
	save `age_diff', replace

restore

capture drop age_diff
tempvar sortorder
gen `sortorder' = _n	
merge m:1 sibling_id using `age_diff', assert(1 3) keep(1 3) nogen
forvalues x = 1(1)`max_obs' {
	gen temp`x' = abs(age_child - patage`x')
}
egen age_diff = rowmin(temp1-temp`max_obs')
drop temp* patage*
sort `sortorder'
drop `sortorder'

egen `samp_pat'
egen `samp_sib'

gen base_sample = (samp_pat == 1 & samp_sib == 1 & insample == 1)

* Define variable for oldest sibling in household in sample

egen first_sib = min(brthord) if insample == 1 & samp_pat == 1 & samp_sib == 1, by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

keep if `sibling_restrictions'

xtset sibling_id

* Remove restricted variables for public version
drop hhid pid_child RecID_child RecID_adult hh_occ ia_occ
save "$PROJ_PATH/processed/data/table_06_col_03.dta", replace

*********************************************************************
// Table 6 Column 4: Restrict to patients residing in Greater London at the time of admission 
*********************************************************************

use "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear
keep regid county_HOSP
merge 1:m regid using "$PROJ_PATH/processed/intermediate/crosswalks/occupational_hosp_icem_crosswalk.dta", keepusing(censusyr RecID_child outcomeyr RecID_adult) assert(1 3) keep(3) nogen
keep if county_HOSP == "LONDON"
drop regid county_HOSP
duplicates drop
unique censusyr RecID_child outcomeyr RecID_adult
tempfile london_admits
save `london_admits', replace

use "$PROJ_PATH/processed/temp/table_02_occupational_analysis_data.dta", clear
merge 1:1 censusyr RecID_child outcomeyr RecID_adult using `london_admits', keep (1 3)
drop if patient == 1 & _merge != 3
drop _merge
bysort sibling_id: keep if _N == 2

xtset sibling_id

* Remove restricted variables for public version
drop hhid pid_child RecID_child RecID_adult hh_occ ia_occ
save "$PROJ_PATH/processed/data/table_06_col_04.dta", replace

*********************************************************************
// Table 7 Column 2: Use highest occupation among father, mother and HH head for child SES
*********************************************************************

use "$PROJ_PATH/processed/intermediate/final_build/occupational_analysis_setup.dta", clear

egen famhisc4 = rowmin(pophisc4 momhisc4 hh_hisc4)
replace pophisc4 = famhisc4

drop if ia_hisc4 == . | pophisc4 == .

drop mobility_up mobility_dn
gen mobility_up = (ia_hisc4 < pophisc4) if ia_hisc4 != . & pophisc4 != .
gen mobility_dn = (ia_hisc4 > pophisc4) if ia_hisc4 != . & pophisc4 != .

gen occupation_restrictions = (`baseline_restrictions' & `occupation_restrictions')
do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/_sibling_restrictions/06.02_occupational_analysis_restrictions.do" occupation_restrictions

keep if `sibling_restrictions'

xtset sibling_id

* Remove restricted variables for public version
drop hhid pid_child RecID_child RecID_adult hh_occ ia_occ
save "$PROJ_PATH/processed/data/table_07_col_02.dta", replace

*********************************************************************
// Table 7 Column 3: Use mother's occupation and then HH head's occupation if father's occupation is missing
*********************************************************************

use "$PROJ_PATH/processed/intermediate/final_build/occupational_analysis_setup.dta", clear
replace pophisc4 = momhisc4 if pophisc4 == .
replace pophisc4 = hh_hisc4 if pophisc4 == .

drop if ia_hisc4 == . | pophisc4 == .

drop mobility_up mobility_dn
gen mobility_up = (ia_hisc4 < pophisc4) if ia_hisc4 != . & pophisc4 != .
gen mobility_dn = (ia_hisc4 > pophisc4) if ia_hisc4 != . & pophisc4 != .

gen occupation_restrictions = (`baseline_restrictions' & `occupation_restrictions')
do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/_sibling_restrictions/06.02_occupational_analysis_restrictions.do" occupation_restrictions

keep if `sibling_restrictions'

xtset sibling_id

* Remove restricted variables for public version
drop hhid pid_child RecID_child RecID_adult hh_occ ia_occ
save "$PROJ_PATH/processed/data/table_07_col_03.dta", replace

*********************************************************************
// Table 7 Column 4: Recode missing occupation as worst occupation
*********************************************************************

use "$PROJ_PATH/processed/intermediate/final_build/occupational_analysis_setup.dta" if pophisc4 != ., clear

foreach n of numlist 1/5 {

	if `n' != 2 {
		recode ``n'' (mis = 0)
	}
	else {
		recode ``n'' (mis = 1)
	}
}
gen occupation_restrictions = (`baseline_restrictions' & `occupation_restrictions')
do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/_sibling_restrictions/06.02_occupational_analysis_restrictions.do" occupation_restrictions

keep if `sibling_restrictions'

xtset sibling_id

* Remove restricted variables for public version
drop hhid pid_child RecID_child RecID_adult hh_occ ia_occ
save "$PROJ_PATH/processed/data/table_07_col_04.dta", replace

*********************************************************************
// Table 7 Column 5: Recode missing occupation as best occupation
*********************************************************************

use "$PROJ_PATH/processed/intermediate/final_build/occupational_analysis_setup.dta" if pophisc4 != ., clear

foreach n of numlist 1/5 {

	if `n' != 2 {
		recode ``n'' (mis = 1)
	}
	else {
		recode ``n'' (mis = 0)
	}
}

gen occupation_restrictions = (`baseline_restrictions' & `occupation_restrictions')
do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/_sibling_restrictions/06.02_occupational_analysis_restrictions.do" occupation_restrictions

keep if `sibling_restrictions'

xtset sibling_id

* Remove restricted variables for public version
drop hhid pid_child RecID_child RecID_adult hh_occ ia_occ
save "$PROJ_PATH/processed/data/table_07_col_05.dta", replace

*********************************************************************************************************************************************
// Figure 2: Robustness to restrictions on similar names
*********************************************************************************************************************************************

local simlist "4 6 8 10 15 20 50 100 1000"

* Extract sample for each threshold for similar names 

foreach y of local simlist {
	
	// Panel (a) Occupational outcomes 

	local occupation_restrictions_`y' "jw_sname_ICEM >= 0.80 & max(jw_fname_orig_ICEM,jw_fname_edit_ICEM) >= 0.80 & similar_10_ICEM <= `y' & age_dist_child <= 3 & jw_sname >= 0.80 & max(jw_fname_orig,jw_fname_edit) >= 0.80 & similar_10 <= `y'"
	
	use "$PROJ_PATH/processed/intermediate/final_build/occupational_analysis_setup.dta", clear

	* Ensure that occupation is non-missing for parent and child
	keep if ia_hisc4 != . & pophisc4 != .

	* Ensure sample includes patient and sibling from each household
	gen occupation_restrictions = (`baseline_restrictions' & `occupation_restrictions_`y'')
	do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/_sibling_restrictions/06.02_occupational_analysis_restrictions.do" occupation_restrictions

	* Restrict to estimation sample
	keep if `sibling_restrictions'
	
	* Flag sample
	gen flag_sample_`y' = 1
	
	save "$PROJ_PATH/processed/temp/fig_2a_`y'.dta", replace
	
	// Panel (b) Schooling 
	
	local scholar_restrictions_`y' "jw_sname >= 0.80 & max(jw_fname_orig,jw_fname_edit) >= 0.80 & similar_10 <= `y' & age_dist <= 3 & age_child >= 5 & age_child <= 10"	
	
	forvalues g = 1(1)2 {

		use "$PROJ_PATH/processed/intermediate/final_build/schooling_analysis_setup.dta", clear

		* Ensure sample includes patient and sibling from each household
		gen scholar_restrictions = (`baseline_restrictions' & `scholar_restrictions_`y'' & sex == `g')
		do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/_sibling_restrictions/06.04_schooling_analysis_restrictions.do" scholar_restrictions

		* Restrict to estimation sample
		keep if `sibling_restrictions'
	
		tempfile schooling_`g'
		save `schooling_`g'', replace
	}

	clear
	forvalues g = 1(1)2 {
		append using `schooling_`g''
	}

	* Flag sample
	gen flag_sample_`y' = 1
		
	save "$PROJ_PATH/processed/temp/fig_2b_schooling_`y'.dta", replace
	

	// Panel (b) Pre-existing disability 
	
	local disability_restrictions_`y' "jw_sname >= 0.80 & max(jw_fname_orig,jw_fname_edit) >= 0.80 & similar_10 <= `y' & age_dist <= 3"
	
	forvalues g = 1(1)2 {

		use "$PROJ_PATH/processed/intermediate/final_build/pre_existing_analysis_setup.dta", clear

		* Ensure sample includes patient and sibling from each household
		gen disability_restrictions = (`baseline_restrictions' & `disability_restrictions_`y'' & sex == `g')
		do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/_sibling_restrictions/06.05_pre_existing_analysis_restrictions.do" disability_restrictions
		
		* Restrict to estimation sample
		keep if `sibling_restrictions'
	
		tempfile disability_`g'
		save `disability_`g'', replace
	}

	clear
	forvalues g = 1(1)2 {
		append using `disability_`g''
	}
	
	* Flag sample
	gen flag_sample_`y' = 1
		
	save "$PROJ_PATH/processed/temp/fig_2b_pre_exist_`y'.dta", replace
	

	// Panel (b) Childhood disability 
	
	local disability_restrictions_`y' "jw_sname >= 0.80 & max(jw_fname_orig,jw_fname_edit) >= 0.80 & similar_10 <= `y' & age_dist <= 3"
	
	forvalues g = 1(1)2 {

		use "$PROJ_PATH/processed/intermediate/final_build/disability_analysis_setup.dta", clear

		* Ensure sample includes patient and sibling from each household
		gen disability_restrictions = (`baseline_restrictions' & `disability_restrictions_`y'' & sex == `g')
		do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/_sibling_restrictions/06.06_disability_analysis_restrictions.do" disability_restrictions

		* Restrict to estimation sample
		keep if `sibling_restrictions'
	
		tempfile disability_`g'
		save `disability_`g'', replace
	}

	clear
	forvalues g = 1(1)2 {
		append using `disability_`g''
	}
	
	* Flag sample
	gen flag_sample_`y' = 1
		
	save "$PROJ_PATH/processed/temp/fig_2b_disability_`y'.dta", replace

	
	
	// Panel (b) Long-run disability

	use "$PROJ_PATH/processed/intermediate/final_build/occupational_analysis_setup.dta" if disab_any != ., clear

	* Ensure sample includes patient and sibling from each household
	gen occupation_restrictions = (`baseline_restrictions' & `occupation_restrictions_`y'')
	do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/_sibling_restrictions/06.02_occupational_analysis_restrictions.do" occupation_restrictions

	* Restrict to estimation sample
	keep if `sibling_restrictions'
	
	* Flag sample
	gen flag_sample_`y' = 1
	
	save "$PROJ_PATH/processed/temp/fig_2b_long_run_disability_`y'.dta", replace
	
}

// Create single sample pooling observations across similar name thresholds

* Panel (a) Occupational outcomes 

clear
foreach y of local simlist {
	append using "$PROJ_PATH/processed/temp/fig_2a_`y'.dta"
	rm "$PROJ_PATH/processed/temp/fig_2a_`y'.dta"
}

recode flag_sample_* (mis = 0)

foreach y of local simlist {
	egen sample_`y' = max(flag_sample_`y'), by(censusyr RecID_child outcomeyr RecID_adult)
	drop flag_sample_`y'
}
drop older_sib
duplicates drop
unique censusyr RecID_child outcomeyr RecID_adult
drop hhid pid_child RecID_child RecID_adult hh_occ ia_occ

xtset sibling_id
save "$PROJ_PATH/processed/data/figure_02a.dta", replace 

* Panel (b) Schooling 

clear
foreach y of local simlist {
	append using "$PROJ_PATH/processed/temp/fig_2b_schooling_`y'.dta"
	rm "$PROJ_PATH/processed/temp/fig_2b_schooling_`y'.dta"
}

recode flag_sample_* (mis = 0)

foreach y of local simlist {
	egen sample_`y' = max(flag_sample_`y'), by(censusyr RecID)
	drop flag_sample_`y'
}
drop older_sib
duplicates drop
unique censusyr RecID
drop hhid pid RecID 

xtset sibling_id
save "$PROJ_PATH/processed/data/figure_02b_schooling.dta", replace 

* Panel (b) Pre-existing disability 

clear
foreach y of local simlist {
	append using "$PROJ_PATH/processed/temp/fig_2b_pre_exist_`y'.dta"
	rm "$PROJ_PATH/processed/temp/fig_2b_pre_exist_`y'.dta"
}

recode flag_sample_* (mis = 0)

foreach y of local simlist {
	egen sample_`y' = max(flag_sample_`y'), by(censusyr RecID)
	drop flag_sample_`y'
}
drop older_sib
duplicates drop
unique censusyr RecID
drop hhid pid RecID 

xtset sibling_id
save "$PROJ_PATH/processed/data/figure_02b_pre_exist.dta", replace 

* Panel (b) Childhood disability 

clear
foreach y of local simlist {
	append using "$PROJ_PATH/processed/temp/fig_2b_disability_`y'.dta"
	rm "$PROJ_PATH/processed/temp/fig_2b_disability_`y'.dta"
}

recode flag_sample_* (mis = 0)

foreach y of local simlist {
	egen sample_`y' = max(flag_sample_`y'), by(censusyr RecID)
	drop flag_sample_`y'
}
drop older_sib
duplicates drop
unique censusyr RecID
drop hhid pid RecID 

xtset sibling_id
save "$PROJ_PATH/processed/data/figure_02b_disability.dta", replace

* Panel (b) Long-run disability 

clear
foreach y of local simlist {
	append using "$PROJ_PATH/processed/temp/fig_2b_long_run_disability_`y'.dta"
	rm "$PROJ_PATH/processed/temp/fig_2b_long_run_disability_`y'.dta"
}

recode flag_sample_* (mis = 0)

foreach y of local simlist {
	egen sample_`y' = max(flag_sample_`y'), by(censusyr RecID_child outcomeyr RecID_adult)
	drop flag_sample_`y'
}
drop older_sib
duplicates drop
unique censusyr RecID_child outcomeyr RecID_adult
drop hhid pid_child RecID_child RecID_adult hh_occ ia_occ

xtset sibling_id
save "$PROJ_PATH/processed/data/figure_02b_long_run_disability.dta", replace

*********************************************************************
// Table A2: Ten most common causes of admission
*********************************************************************

// Male hospital population

use disease_cleaned coa died resid_mort sex_HOSP using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta" if sex_HOSP == 1, clear
replace coa = disease_cleaned if coa == "DISEASE"
keep coa died resid_mort

count
local N = r(N)

gen coa_freq = 1
collapse (mean) mr = died resid_mort (sum) coa_freq deaths = died , by(coa)
gen sex = 1
gen N = `N'

tempfile coa_male
save `coa_male', replace

// Female hospital population

use disease_cleaned coa died resid_mort sex_HOSP using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta" if sex_HOSP == 2, clear
replace coa = disease_cleaned if coa == "DISEASE"
keep coa died resid_mort

count
local N = r(N)

gen coa_freq = 1
collapse (mean) mr = died resid_mort (sum) coa_freq deaths = died , by(coa)
gen sex = 2
gen N = `N'

tempfile coa_female
save `coa_female', replace

// In final sample

use "$PROJ_PATH/processed/temp/table_02_occupational_analysis_data.dta" if patient == 1, clear
keep censusyr RecID_child outcomeyr RecID_adult
merge 1:m censusyr RecID_child outcomeyr RecID_adult using "$PROJ_PATH/processed/intermediate/crosswalks/occupational_hosp_icem_crosswalk.dta", keepusing(regid) assert(2 3) keep(3) nogen
keep regid 
merge 1:1 regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", assert(2 3) keep(3) nogen keepusing(coa disease_cleaned)

replace coa = disease_cleaned if coa == "DISEASE"
keep coa

count
local N = r(N)

bysort coa: gen coa_freq = _N
gen coa_pct = round(coa_freq*100/_N,0.01)
bysort coa coa_freq coa_pct: keep if _n == 1
gen sex = 9
gen N = `N'

tempfile coa_sample
save `coa_sample', replace

clear
append using `coa_male'
append using `coa_female'
append using `coa_sample'

save "$PROJ_PATH/processed/data/table_a02.dta", replace

*********************************************************************
// Table A5: Synthetic population
*********************************************************************

set seed 123

forvalues t_2 = 1901(10)1911 {
	if `t_2' == 1901 {
		local t_max = 1891
	}
	else {
		local t_max = 1901
	}
	forvalues t_1 = 1881(10)`t_max' {
	
		* Generate shares of each linked sample in main estimate sample

		use "$PROJ_PATH/processed/temp/table_02_occupational_analysis_data.dta", clear

		tempvar link_`t_1'_`t_2'
		gen `link_`t_1'_`t_2'' = (censusyr == `t_1' & outcomeyr == `t_2')

		sum `link_`t_1'_`t_2''
		local shr_`t_1'_`t_2' = r(mean)*100

		use "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/unique_matches_`t_1'_`t_2'.dta" if sex == 1 & jw_sname >= 0.8 & max(jw_fname_orig,jw_fname_edit) >= 0.8 & similar_10 <= 20, clear

		gen byr_adult = outcomeyr - age_adult
		gen valid_age = (age_adult >= 18 & byr_adult >= 1870 & byr_adult <= 1893)

		keep if valid_age == 1

		sample `shr_`t_1'_`t_2''

		keep censusyr outcomeyr RecID*

		rename censusyr Year
		rename RecID_child RecID

		merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`t_1'_occupation.dta", keep(1 3) nogen keepusing(pophisco)

		rename RecID RecID_child
		rename Year censusyr

		rename outcomeyr Year
		rename RecID_adult RecID

		merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`t_2'_occupation.dta", assert(2 3) keep(3) nogen keepusing(hisco)
		rename hisco ia_hisco
				
		rename pophisco hisco
		merge m:1 hisco using "$PROJ_PATH/processed/intermediate/occupations/hisco_to_hisclass.dta", keep(1 3) nogen keepusing(hisclass impute_hc)
		tab hisco if hisclass == .
		rename hisclass pophisclass
		rename impute_hc impute_pop_hisclass
		rename hisco pophisco

		rename ia_hisco hisco
		merge m:1 hisco using "$PROJ_PATH/processed/intermediate/occupations/hisco_to_hisclass.dta", keep(1 3) nogen keepusing(hisclass impute_hc)
		tab hisco if hisclass == .
		rename hisclass ia_hisclass
		rename impute_hc impute_ia_hisclass
		rename hisco ia_hisco
		
		* Create 4 group HISCLASS measure
		label define hisc4lab 1 "White Collar" 2 "Skilled" 3 "Semi skilled" 4 "Unskilled", replace
		local hisco_vars "pop ia_"
		foreach histype of local hisco_vars {
			gen `histype'hisc4 = .
			replace `histype'hisc4 = 1 if `histype'hisclass == 1 | `histype'hisclass == 2 | `histype'hisclass == 3 | `histype'hisclass == 4 | `histype'hisclass == 5
			replace `histype'hisc4 = 2 if `histype'hisclass == 6 | `histype'hisclass == 7 | `histype'hisclass == 8
			replace `histype'hisc4 = 3 if `histype'hisclass == 9
			replace `histype'hisc4 = 4 if `histype'hisclass == 10 | `histype'hisclass == 11 | `histype'hisclass == 12
			la val `histype'hisc4 hisc4lab
		}

		drop if pophisc4 == . | ia_hisc4 == .
		
		keeporder pophisc4 ia_hisc4
		contract pophisc4 ia_hisc4

		tempfile pop_for_dpq_`t_1'_`t_2'
		save `pop_for_dpq_`t_1'_`t_2'', replace
	}
}

clear
forvalues t_2 = 1901(10)1911 {
	if `t_2' == 1901 {
		local t_max = 1891
	}
	else {
		local t_max = 1901
	}
	forvalues t_1 = 1881(10)`t_max' {
		append using `pop_for_dpq_`t_1'_`t_2''
	}
}

collapse (sum) count_pop = _freq, by(pophisc4 ia_hisc4)

egen tot_pop = total(count_pop)

save "$PROJ_PATH/processed/data/table_a05_panel_04.dta", replace

*********************************************************************
*********************************************************************
// Table A6: Social outcomes
*********************************************************************
*********************************************************************

forvalues y = 1901(10)1911 {

	* Construct parish level measures of neighborhood quality
	
	use "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_identifiers.dta", clear
	merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_occupation.dta", assert(2 3) keep(3) nogen keepusing(hisco Occ Occode)
	merge m:1 hisco using "$PROJ_PATH/processed/intermediate/occupations/hisco_to_hisclass.dta", keep(1 3) nogen keepusing(hisclass)
	gen unskilled = inrange(hisclass,10,12)
	collapse (mean) nbr_unskilled = unskilled, by(ParID)
	tempfile neighborhood
	save `neighborhood', replace
	
	use "$PROJ_PATH/processed/intermediate/final_build/occupational_analysis_setup.dta" if outcomeyr == `y', clear
	rename RecID_adult RecID
	merge 1:1 RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_identifiers.dta", assert(2 3) keep(3) nogen keepusing(ParID h)
	rename RecID RecID_adult
	merge m:1 ParID using `neighborhood', assert(2 3) keep(3) nogen
	tempfile sample_`y'
	save `sample_`y'', replace
}
clear
forvalues y = 1901(10)1911 {
	append using `sample_`y''
}
tempfile social_outcomes_sample
save `social_outcomes_sample', replace
	
tokenize `social_outcomes'
forvalues n = 1(4)5 {

	use `social_outcomes_sample' if ``n'' != ., clear
	
	* Ensure sample includes patient and sibling from each household
	gen occupation_restrictions = (`baseline_restrictions' & `occupation_restrictions')
	do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/_sibling_restrictions/06.02_occupational_analysis_restrictions.do" occupation_restrictions
	xtset sibling_id
	
	keep if `sibling_restrictions'
	
	drop hhid pid_child RecID_child RecID_adult hh_occ ia_occ
	xtset sibling_id

	if `n' == 1 {
		save "$PROJ_PATH/processed/data/table_a06_col1to4.dta", replace
	}
	else {
		save "$PROJ_PATH/processed/data/table_a06_col`n'.dta", replace
	}
}

tokenize `outcome_vars'

*********************************************************************
*********************************************************************
// Table A10: Weighting households in regressions by hospital patient population
*********************************************************************
*********************************************************************
eststo drop *

foreach n of numlist 1 7/10 {	
	
	if `n' == 7 | `n' == 8 | `n' == 9 {
			
		if `n' == 7 {
			
			* Schooling outcome
			use "$PROJ_PATH/processed/temp/table_04_schooling_analysis_data.dta" if patient == 1, clear	
		}
		else if `n' == 8 {
			
			* Pre-existing disability outcome
			use "$PROJ_PATH/processed/temp/table_04_pre_existing_analysis_data.dta" if patient == 1, clear
		}
		else if `n' == 9 {
			
			* Childhood disability outcome
			use "$PROJ_PATH/processed/temp/table_04_disability_analysis_data.dta" if patient == 1, clear
		}
		
		rename sex sex_HOSP
		keep censusyr RecID sex_HOSP
		tempfile final_sample
		save `final_sample', replace

		use "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear 
		
		if `n' == 7 {
			merge 1:m regid using "$PROJ_PATH/processed/intermediate/crosswalks/scholar_hosp_icem_crosswalk.dta", keepusing(censusyr RecID) assert(1 3) keep(1 3) nogen // Crosswalk file with hospital and census IDs
		} 
		else if `n' == 8 {	
			merge 1:m regid using "$PROJ_PATH/processed/intermediate/crosswalks/pre_exist_hosp_icem_crosswalk.dta", keepusing(censusyr RecID) assert(1 3) keep(1 3) nogen 
		}
		else if `n' == 9 {
			merge 1:m regid using "$PROJ_PATH/processed/intermediate/crosswalks/disability_hosp_icem_crosswalk.dta", keepusing(censusyr RecID) assert(1 3) keep(1 3) nogen 
		}
		
		merge m:1 censusyr RecID sex_HOSP using `final_sample', assert(1 3)
		
		gen matched = (_merge == 3) // Dummy for match, will be outcome variable in probit
		drop _merge

		replace censusyr = . if matched == 0
		replace RecID = . if matched == 0

		gsort + pat_id_proxy - censusyr - RecID
		by pat_id_proxy: carryforward censusyr RecID, replace
		egen min_pid = min(pat_id_proxy), by(censusyr RecID)	
		replace pat_id_proxy = min_pid if matched == 1
		drop min_pid 

		replace pat_id_proxy = . if matched == 1

		egen patient_id = group(pat_id_proxy censusyr RecID), missing
		rename RecID RecID_child
	
	}
	else {
		if `n' == 10 {
			
			* Long-run disability
			use "$PROJ_PATH/processed/temp/table_04_col_10.dta" if patient == 1, clear
		}
		else {
			
			* Long-run occupational outcomes
			use "$PROJ_PATH/processed/temp/table_02_occupational_analysis_data.dta" if patient == 1, clear
		}
		
		rename sex sex_HOSP
		keep censusyr RecID_child sex_HOSP
		tempfile final_sample
		save `final_sample', replace

		use "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear 	
		merge 1:m regid using "$PROJ_PATH/processed/intermediate/crosswalks/occupational_hosp_icem_crosswalk.dta", keepusing(censusyr RecID_child) assert(1 3) keep(1 3) nogen // Crosswalk file with hospital and census IDs
		merge m:1 censusyr RecID_child sex_HOSP using `final_sample', assert(1 3)  // Census IDs in final empircal sample
		keep if sex_HOSP == 1
		
		gen matched = (_merge == 3) // Dummy for match, will be outcome variable in probit
		drop _merge

		replace censusyr = . if matched == 0
		replace RecID_child = . if matched == 0

		gsort + pat_id_proxy - censusyr - RecID_child
		by pat_id_proxy: carryforward censusyr RecID_child, replace
		egen min_pid = min(pat_id_proxy), by(censusyr RecID_child)	
		replace pat_id_proxy = min_pid if matched == 1
		drop min_pid 

		replace pat_id_proxy = . if matched == 1

		egen patient_id = group(pat_id_proxy censusyr RecID_child), missing
	}
	
	// Drop unmatched patients outside birth year range
	gen byr = admityr - admitage
	drop if (byr < 1870 | byr > 1891) & matched == 0
	drop byr

	// Use first admission per patient
	egen frst_admitdate = min(admitdate), by(patient_id)
	drop if admitdate != frst_admitdate
	drop frst_admitdate

	// Variables to include in matching:
	gen binned_admitage = 0
	replace binned_admitage = 1 if admitage <= 2
	replace binned_admitage = 2 if admitage >= 3 & admitage <= 4
	replace binned_admitage = 3 if admitage >= 5 & admitage <= 6
	replace binned_admitage = 4 if admitage >= 6 & admitage <= 9
	replace binned_admitage = 5 if admitage >=10

	gen binned_admityr = 0
	replace binned_admityr = 1 if admityr <= 1880
	replace binned_admityr = 2 if admityr >= 1881 & admityr <= 1884
	replace binned_admityr = 3 if admityr >= 1885 & admityr <= 1888
	replace binned_admityr = 4 if admityr >= 1889 & admityr <= 1892
	replace binned_admityr = 5 if admityr >= 1893

	* London dummy
	egen london_dummy = max(regexm(county_HOSP, "LONDON")), by(patient_id)
	egen london_catchment = max(london_dummy == 1 & (district_HOSP == "HOLBORN" | district_HOSP == "ISLINGTON" | district_HOSP == "SHOREDITCH" | district_HOSP == "ST OLAVE SOUTHWARK")), by(patient_id)
	gen london_outside = (london_dummy == 1 & london_catchment == 0)
	egen greater_london = max((regexm(county_HOSP,"MIDDLESEX") | regexm(county_HOSP,"ESSEX") | regexm(county_HOSP,"KENT") | regexm(county_HOSP,"SURREY")) & london_dummy == 1), by(patient_id)

	* Hospital dummies
	egen hosp_1 = max(hospid == 1), by(patient_id)
	egen hosp_2 = max(hospid == 2), by(patient_id)
	egen hosp_5 = max(hospid == 5), by(patient_id)

	* Multiple admission dummy
	bysort patient_id: gen tot_admit = _N
	gen multiple_admissions = (tot_admit > 1)

	// Get rid of duplicates
	keep matched binned_* sex_HOSP london_dummy london_catchment london_outside greater_london hosp_1-hosp_5 multiple_admissions patient_id pat_id_proxy censusyr RecID_child
	duplicates drop
	unique patient_id 

	// Variables to include in matching:
	probit matched i.binned_admityr i.binned_admitage sex_HOSP london_catchment london_outside greater_london
	predict phat

	// generate weights
	cap drop weight
	gen weight = (1-phat)/phat

	keep if matched == 1
	keep censusyr RecID_child weight
	duplicates drop
	unique censusyr RecID_child
	tempfile weights
	save `weights', replace

	if `n' == 7 {
		
		* Scholar outcome
		use "$PROJ_PATH/processed/temp/table_04_schooling_analysis_data.dta", clear	
		rename RecID RecID_child
	}
	else if `n' == 8 {
		
		* Pre-existing disability outcome
		use "$PROJ_PATH/processed/temp/table_04_pre_existing_analysis_data.dta", clear
		rename RecID RecID_child
	}
	else if `n' == 9 {
		
		* Childhood disability outcome
		use "$PROJ_PATH/processed/temp/table_04_disability_analysis_data.dta", clear
		rename RecID RecID_child
	}
	else if `n' == 10 {
		
		use "$PROJ_PATH/processed/temp/table_04_col_10.dta", clear
	}
	else {
		use "$PROJ_PATH/processed/temp/table_02_occupational_analysis_data.dta", clear
	}

	merge 1:1 censusyr RecID_child using `weights', keep(1 3) nogen

	gsort + censusyr + sibling_id + sex - patient
	by censusyr sibling_id sex: carryforward weight, replace
	
	egen temp_id = group(sibling_id sex)
	drop sibling_id
	rename temp_id sibling_id
	
	xtset sibling_id 

	if `n' == 1 {
		drop hhid pid_child RecID_child RecID_adult hh_occ ia_occ
		save "$PROJ_PATH/processed/data/table_a10_col1to6.dta", replace
	}
	else if `n' == 10 {
		drop hhid pid_child RecID_child RecID_adult hh_occ ia_occ
		save "$PROJ_PATH/processed/data/table_a10_col10.dta", replace	
	}
	else {
		drop hhid pid RecID_child
		save "$PROJ_PATH/processed/data/table_a10_col`n'.dta", replace
	}	
}

*********************************************************************
*********************************************************************
// Table A11: Single marital status - weighting households by 
//	hospital patient population
*********************************************************************
*********************************************************************

forvalues n = 1(1)3 {

	* Extract identifiers by gender for single marital samples
	
	use `data_`n'', clear 
	keep if main_marital_sample == 1
	bysort sibling_id: keep if _N == 2
	
	keep if patient == 1
	
	rename sex sex_HOSP
	keep censusyr RecID_child sex_HOSP
	tempfile final_sample
	save `final_sample', replace
	
	if `n' == 1 {
		local gender 2
	}
	else {
		local gender 1
	}
		
	use "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta" if sex_HOSP == `gender', clear // Full population of hospital patients by gender at risk of being matched		
	merge 1:m regid using "$PROJ_PATH/processed/intermediate/crosswalks/singles_hosp_icem_`gender'_crosswalk.dta", keepusing(censusyr RecID_child) assert(1 3) keep(1 3) nogen // Crosswalk file with hospital and census IDs
	merge m:1 censusyr RecID_child sex_HOSP using `final_sample', assert(1 3)  // Census IDs in final empircal sample

	gen matched = (_merge == 3) // Dummy for match, will be outcome variable in probit
	drop _merge

	replace censusyr = . if matched == 0
	replace RecID_child = . if matched == 0

	gsort + pat_id_proxy - censusyr - RecID_child
	by pat_id_proxy: carryforward censusyr RecID_child, replace
	egen min_pid = min(pat_id_proxy), by(censusyr RecID_child)	
	replace pat_id_proxy = min_pid if matched == 1
	drop min_pid 

	replace pat_id_proxy = . if matched == 1

	egen patient_id = group(pat_id_proxy censusyr RecID_child), missing

	// Drop unmatched patients outside birth year range

	gen byr = admityr - admitage
	drop if (byr < 1870 | byr > 1891) & matched == 0
	drop byr

	// Use first admission per patient

	egen frst_admitdate = min(admitdate), by(patient_id)
	drop if admitdate != frst_admitdate
	drop frst_admitdate

	// Variables to include in matching:

	gen binned_admitage = 0
	replace binned_admitage = 1 if admitage <= 2
	replace binned_admitage = 2 if admitage >= 3 & admitage <= 4
	replace binned_admitage = 3 if admitage >= 5 & admitage <= 6
	replace binned_admitage = 4 if admitage >= 6 & admitage <= 9
	replace binned_admitage = 5 if admitage >=10

	gen binned_admityr = 0
	replace binned_admityr = 1 if admityr <= 1880
	replace binned_admityr = 2 if admityr >= 1881 & admityr <= 1884
	replace binned_admityr = 3 if admityr >= 1885 & admityr <= 1888
	replace binned_admityr = 4 if admityr >= 1889 & admityr <= 1892
	replace binned_admityr = 5 if admityr >= 1893

	* London dummy

	egen london_dummy = max(regexm(county_HOSP, "LONDON")), by(patient_id)
	egen london_catchment = max(london_dummy == 1 & (district_HOSP == "HOLBORN" | district_HOSP == "ISLINGTON" | district_HOSP == "SHOREDITCH" | district_HOSP == "ST OLAVE SOUTHWARK")), by(patient_id)
	gen london_outside = (london_dummy == 1 & london_catchment == 0)
	egen greater_london = max((regexm(county_HOSP,"MIDDLESEX") | regexm(county_HOSP,"ESSEX") | regexm(county_HOSP,"KENT") | regexm(county_HOSP,"SURREY")) & london_dummy == 1), by(patient_id)

	* Hospital dummies
	egen hosp_1 = max(hospid == 1), by(patient_id)
	egen hosp_2 = max(hospid == 2), by(patient_id)
	egen hosp_5 = max(hospid == 5), by(patient_id)

	* Multiple admission dummy
	bysort patient_id: gen tot_admit = _N
	gen multiple_admissions = (tot_admit > 1)

	// Get rid of duplicates

	keep matched binned_* sex_HOSP london_dummy london_catchment london_outside greater_london hosp_1-hosp_5 multiple_admissions patient_id pat_id_proxy censusyr RecID_child 
	duplicates drop
	unique patient_id 

	// Variables to include in matching:
		
	probit matched i.binned_admityr i.binned_admitage sex_HOSP london_catchment london_outside greater_london
	predict phat

	** generate weights
	cap drop weight
	gen weight = (1-phat)/phat

	keep if matched == 1
	keep censusyr RecID_child weight
	duplicates drop
	unique censusyr RecID_child
	tempfile weights
	save `weights', replace
	
	* Single outcomes
	
	use `data_`n'', clear 
	keep if main_marital_sample == 1
	bysort sibling_id: keep if _N == 2
	

	merge 1:1 censusyr RecID_child using `weights', keep(1 3) nogen

	gsort + censusyr + sibling_id + sex - patient
	by censusyr sibling_id sex: carryforward weight, replace
	
	egen temp_id = group(sibling_id sex)
	drop sibling_id
	rename temp_id sibling_id
	
	xtset sibling_id
	drop hhid pid_child RecID_child
	
	save "$PROJ_PATH/processed/data/table_a11_col`n'.dta", replace
	
}

*********************************************************************
// Table A15: Long-run marital status for men and women
*********************************************************************

eststo drop *
forvalues n = 1(1)3 {
	
	* Restrict to patients residing in Greater London at the time of admission
	
	if `n' == 1 {
		local xwk_path "$PROJ_PATH/processed/intermediate/crosswalks/singles_hosp_icem_2_crosswalk.dta"
	} 
	else {
		local xwk_path "$PROJ_PATH/processed/intermediate/crosswalks/singles_hosp_icem_1_crosswalk.dta"
	}
	
	use "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear
	keep regid county_HOSP
	merge 1:m regid using `xwk_path', keepusing(censusyr RecID_child) assert(1 3) keep(3) nogen
	keep if county_HOSP == "LONDON"
	drop regid county_HOSP
	duplicates drop
	unique censusyr RecID_child
	tempfile london_admits
	save `london_admits', replace

	use `data_`n'', clear 
	keep if main_marital_sample == 1
	
	merge 1:1 censusyr RecID_child using `london_admits', keep (1 3)
	drop if patient == 1 & _merge != 3
	drop _merge
	bysort sibling_id: keep if _N == 2
	
	xtset sibling_id
	drop RecID_child sibid_orig hhid pid_child
	
	save "$PROJ_PATH/processed/data/table_a15_col8_`n'.dta", replace
	
}

*********************************************************************
// Table A16 Column 7: Add multiple siblings 
*********************************************************************

use "$PROJ_PATH/processed/temp/table_04_schooling_analysis_data.dta", clear
keep sibling_id censusyr RecID
tempfile indivs
save `indivs', replace

keep sibling_id
duplicates drop
tempfile ids
save `ids', replace

use "$PROJ_PATH/processed/intermediate/final_build/schooling_analysis_setup.dta" if `baseline_restrictions' & `scholar_restrictions', clear
merge m:1 sibling_id using `ids', assert(1 3) keep(3) nogen
merge 1:1 sibling_id censusyr RecID using `indivs', assert(1 3)
gen final_sample = (_merge == 3)
drop _merge

drop if patient == 1 & final_sample == 0 // Drop patients not in final sample

gen final_sex = sex*final_sample
egen max_gender = max(final_sex), by(sibling_id)
drop if sex != max_gender & final_sample == 0
drop final_sex max_gender

local samp_pat "samp_pat = max(patient == 1 & insample == 1 & age_diff == 0), by(sibling_id)"
local samp_sib "samp_sib = max(patient == 0 & insample == 1 & age_diff <= 5), by(sibling_id)"

gen flag_extra_sibpat = 0

gen insample = (`baseline_restrictions' & scholar != . & `scholar_restrictions')

* Compute age difference between siblings

preserve

	keep if patient == 1 & insample == 1
	keep sibling_id age_child
	bysort sibling_id age_child: keep if _n == 1
	egen temp_id = seq(), by(sibling_id)
	sum temp_id
	local max_obs = r(max)
	rename age_child patage
	reshape wide patage, i(sibling_id) j(temp_id)
	tempfile age_diff
	save `age_diff', replace

restore

capture drop age_diff
tempvar sortorder
gen `sortorder' = _n

merge m:1 sibling_id using `age_diff', assert(1 3) keep(1 3) nogen

forvalues x = 1(1)`max_obs' {
	gen temp`x' = abs(age_child - patage`x')
}
egen age_diff = rowmin(temp1-temp`max_obs')
drop temp* patage*
sort `sortorder'
drop `sortorder'

egen `samp_pat'
egen `samp_sib'

gen base_sample = (samp_pat == 1 & samp_sib == 1 & insample == 1)

* Drop households with multiple patients

egen mult_pat_hh = total(insample == 1 & patient == 1 & samp_pat == 1), by(sibling_id)
replace flag_extra_sibpat = 1 if mult_pat_hh > 1 & !missing(mult_pat_hh)
drop mult_pat_hh insample samp_pat samp_sib

gen insample = (scholar != . & base_sample == 1 & flag_extra_sibpat == 0 & `baseline_restrictions' & `scholar_restrictions')
egen `samp_pat'
egen `samp_sib'	

drop flag_extra_sibpat base_sample

* Define variable for older sibling of each patient and healthy sibling pair

egen first_sib = min(brthord) if insample == 1 & samp_pat == 1 & samp_sib == 1, by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

keep if `sibling_restrictions'

xtset sibling_id
drop hhid pid RecID 
save "$PROJ_PATH/processed/data/table_a16_col_07.dta", replace

*********************************************************************
// Table A16 Column 8: Add multiple patient households
*********************************************************************

use "$PROJ_PATH/processed/temp/table_04_schooling_analysis_data.dta", clear
keep sibling_id censusyr RecID
tempfile indivs
save `indivs', replace

keep sibling_id
duplicates drop
tempfile ids
save `ids', replace

use "$PROJ_PATH/processed/intermediate/final_build/schooling_analysis_setup.dta" if `baseline_restrictions' & `scholar_restrictions', clear
merge 1:1 sibling_id censusyr RecID using `indivs', keep(1) nogen

egen tot_pat = total(patient == 1), by(sibling_id)
keep if tot_pat > 1

egen boy_pats = total(patient == 1 & sex == 1), by(sibling_id)
egen girl_pats = total(patient == 1 & sex == 2), by(sibling_id)

drop if boy_pats == 0 & sex == 1
drop if girl_pats == 0 & sex == 2

tempfile mult_pats
save `mult_pats', replace

use "$PROJ_PATH/processed/intermediate/final_build/schooling_analysis_setup.dta" if `baseline_restrictions' & `scholar_restrictions', clear
merge m:1 sibling_id using `ids', assert(1 3) keep(3) nogen
merge 1:1 sibling_id censusyr RecID using `indivs', assert(1 3)
gen final_sample = (_merge == 3)
drop _merge

drop if patient == 1 & final_sample == 0 // Drop patients not in final sample

gen final_sex = sex*final_sample
egen max_gender = max(final_sex), by(sibling_id)
drop if sex != max_gender & final_sample == 0
drop final_sex max_gender

append using `mult_pats'
recode final_sample (mis = 0)

local samp_pat "samp_pat = max(patient == 1 & insample == 1 & age_diff == 0), by(sibling_id)"
local samp_sib "samp_sib = max(patient == 0 & insample == 1 & age_diff <= 5), by(sibling_id)"

gen insample = (`baseline_restrictions' & scholar != . & `scholar_restrictions')

* Compute age difference between siblings

preserve

	keep if patient == 1 & insample == 1
	keep sibling_id age_child
	bysort sibling_id age_child: keep if _n == 1
	egen temp_id = seq(), by(sibling_id)
	sum temp_id
	local max_obs = r(max)
	rename age_child patage
	reshape wide patage, i(sibling_id) j(temp_id)
	tempfile age_diff
	save `age_diff', replace

restore

capture drop age_diff
tempvar sortorder
gen `sortorder' = _n

merge m:1 sibling_id using `age_diff', assert(1 3) keep(1 3) nogen

forvalues x = 1(1)`max_obs' {
	gen temp`x' = abs(age_child - patage`x')
}
egen age_diff = rowmin(temp1-temp`max_obs')
drop temp* patage*
sort `sortorder'
drop `sortorder'

egen `samp_pat'
egen `samp_sib'

* Define variable for oldest sibling in household in sample

egen first_sib = min(brthord) if insample == 1 & samp_pat == 1 & samp_sib == 1, by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

keep if `sibling_restrictions'

xtset sibling_id
drop hhid pid RecID 
save "$PROJ_PATH/processed/data/table_a16_col_08.dta", replace

*********************************************************************
// Table A16 Column 9: Restrict to patients residing in County of London at the time of admission
*********************************************************************

use "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear
keep regid county_HOSP
merge 1:m regid using "$PROJ_PATH/processed/intermediate/crosswalks/scholar_hosp_icem_crosswalk.dta", keepusing(censusyr RecID) assert(1 3) keep(3) nogen
keep if county_HOSP == "LONDON"
drop regid county_HOSP
duplicates drop
unique censusyr RecID
tempfile london_admits
save `london_admits', replace

use "$PROJ_PATH/processed/temp/table_04_schooling_analysis_data.dta", clear
merge 1:1 censusyr RecID using `london_admits', keep (1 3)
drop if patient == 1 & _merge != 3
drop _merge
bysort sibling_id: keep if _N == 2

xtset sibling_id
drop hhid pid RecID 
save "$PROJ_PATH/processed/data/table_a16_col_09.dta", replace

*********************************************************************
// Table A17 Column 7: Add multiple siblings 
*********************************************************************

use "$PROJ_PATH/processed/temp/table_04_pre_existing_analysis_data.dta", clear 
keep sibling_id censusyr RecID
tempfile indivs
save `indivs', replace

keep sibling_id
duplicates drop
tempfile ids
save `ids', replace

use "$PROJ_PATH/processed/intermediate/final_build/pre_existing_analysis_setup.dta" if `baseline_restrictions' & `disability_restrictions', clear
merge m:1 sibling_id using `ids', assert(1 3) keep(3) nogen
merge 1:1 sibling_id censusyr RecID using `indivs', assert(1 3)
gen final_sample = (_merge == 3)
drop _merge

drop if patient == 1 & final_sample == 0 // Drop patients not in final sample

gen final_sex = sex*final_sample
egen max_gender = max(final_sex), by(sibling_id)
drop if sex != max_gender & final_sample == 0
drop final_sex max_gender

local samp_pat "samp_pat = max(patient == 1 & insample == 1 & age_diff == 0), by(sibling_id)"
local samp_sib "samp_sib = max(patient == 0 & insample == 1 & age_diff <= 5), by(sibling_id)"

gen flag_extra_sibpat = 0

gen insample = (`baseline_restrictions' & disab_any != . & `disability_restrictions')

* Compute age difference between siblings

preserve

	keep if patient == 1 & insample == 1
	keep sibling_id age_child
	bysort sibling_id age_child: keep if _n == 1
	egen temp_id = seq(), by(sibling_id)
	sum temp_id
	local max_obs = r(max)
	rename age_child patage
	reshape wide patage, i(sibling_id) j(temp_id)
	tempfile age_diff
	save `age_diff', replace

restore

* Compute pid difference between siblings

preserve
	keep if patient == 1 & insample == 1
	keep sibling_id pid
	bysort sibling_id pid: keep if _n == 1
	egen temp_id = seq(), by(sibling_id)
	sum temp_id
	local max_pid = r(max)
	rename pid patpid
	reshape wide patpid, i(sibling_id) j(temp_id)
	tempfile pid_diff
	save `pid_diff', replace
restore	

capture drop age_diff
tempvar sortorder
gen `sortorder' = _n

merge m:1 sibling_id using `age_diff', assert(1 3) keep(1 3) nogen
merge m:1 sibling_id using `pid_diff', assert(1 3) keep(1 3) nogen

forvalues x = 1(1)`max_obs' {
	gen temp`x' = abs(age_child - patage`x')
}
egen age_diff = rowmin(temp1-temp`max_obs')
drop temp* patage*

forvalues x = 1(1)`max_pid' {
	gen temp`x' = abs(pid - patpid`x')
}
egen pid_diff = rowmin(temp1-temp`max_pid')
drop temp* patpid*

sort `sortorder'
drop `sortorder'

egen `samp_pat'
egen `samp_sib'

gen base_sample = (samp_pat == 1 & samp_sib == 1 & insample == 1)

* Drop households with multiple patients

egen mult_pat_hh = total(insample == 1 & patient == 1 & samp_pat == 1), by(sibling_id)
replace flag_extra_sibpat = 1 if mult_pat_hh > 1 & !missing(mult_pat_hh)
drop mult_pat_hh insample samp_pat samp_sib

gen insample = (disab_any != . & base_sample == 1 & flag_extra_sibpat == 0 & `baseline_restrictions' & `disability_restrictions')
egen `samp_pat'
egen `samp_sib'	

drop flag_extra_sibpat base_sample

* Define variable for older sibling of each patient and healthy sibling pair

egen first_sib = min(brthord) if insample == 1 & samp_pat == 1 & samp_sib == 1, by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

keep if `sibling_restrictions'

xtset sibling_id
drop hhid pid RecID 
save "$PROJ_PATH/processed/data/table_a17_col_07.dta", replace

*********************************************************************
// Table A17 Column 8: Add multiple patient households
*********************************************************************

use "$PROJ_PATH/processed/temp/table_04_pre_existing_analysis_data.dta", clear 
keep sibling_id censusyr RecID
tempfile indivs
save `indivs', replace

keep sibling_id
duplicates drop
tempfile ids
save `ids', replace

use "$PROJ_PATH/processed/intermediate/final_build/pre_existing_analysis_setup.dta" if `baseline_restrictions' & `disability_restrictions', clear
merge 1:1 sibling_id censusyr RecID using `indivs', keep(1) nogen

egen tot_pat = total(patient == 1), by(sibling_id)
keep if tot_pat > 1

egen boy_pats = total(patient == 1 & sex == 1), by(sibling_id)
egen girl_pats = total(patient == 1 & sex == 2), by(sibling_id)

drop if boy_pats == 0 & sex == 1
drop if girl_pats == 0 & sex == 2

tempfile mult_pats
save `mult_pats', replace

use "$PROJ_PATH/processed/intermediate/final_build/pre_existing_analysis_setup.dta" if `baseline_restrictions' & `disability_restrictions', clear
merge m:1 sibling_id using `ids', assert(1 3) keep(3) nogen
merge 1:1 sibling_id censusyr RecID using `indivs', assert(1 3)
gen final_sample = (_merge == 3)
drop _merge

drop if patient == 1 & final_sample == 0 // Drop patients not in final sample

gen final_sex = sex*final_sample
egen max_gender = max(final_sex), by(sibling_id)
drop if sex != max_gender & final_sample == 0
drop final_sex max_gender

append using `mult_pats'
recode final_sample (mis = 0)

local samp_pat "samp_pat = max(patient == 1 & insample == 1 & age_diff == 0), by(sibling_id)"
local samp_sib "samp_sib = max(patient == 0 & insample == 1 & age_diff <= 5), by(sibling_id)"

gen insample = (`baseline_restrictions' & disab_any != . & `disability_restrictions')

* Compute age difference between siblings

preserve

	keep if patient == 1 & insample == 1
	keep sibling_id age_child
	bysort sibling_id age_child: keep if _n == 1
	egen temp_id = seq(), by(sibling_id)
	sum temp_id
	local max_obs = r(max)
	rename age_child patage
	reshape wide patage, i(sibling_id) j(temp_id)
	tempfile age_diff
	save `age_diff', replace
	
restore

* Compute pid difference between siblings

preserve

	keep if patient == 1 & insample == 1
	keep sibling_id pid
	bysort sibling_id pid: keep if _n == 1
	egen temp_id = seq(), by(sibling_id)
	sum temp_id
	local max_pid = r(max)
	rename pid patpid
	reshape wide patpid, i(sibling_id) j(temp_id)
	tempfile pid_diff
	save `pid_diff', replace
	
restore	

capture drop age_diff
tempvar sortorder
gen `sortorder' = _n
merge m:1 sibling_id using `age_diff', assert(1 3) keep(1 3) nogen
merge m:1 sibling_id using `pid_diff', assert(1 3) keep(1 3) nogen
	
forvalues x = 1(1)`max_obs' {
	gen temp`x' = abs(age_child - patage`x')
}
egen age_diff = rowmin(temp1-temp`max_obs')
drop temp* patage*

forvalues x = 1(1)`max_pid' {
	gen temp`x' = abs(pid - patpid`x')
}
egen pid_diff = rowmin(temp1-temp`max_pid')
drop temp* patpid*

sort `sortorder'
drop `sortorder'

egen `samp_pat'
egen `samp_sib'

* Define variable for oldest sibling in household in sample

egen first_sib = min(brthord) if insample == 1 & samp_pat == 1 & samp_sib == 1, by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

keep if `sibling_restrictions'

xtset sibling_id
drop hhid pid RecID 
save "$PROJ_PATH/processed/data/table_a17_col_08.dta", replace

*********************************************************************
// Table A17 Column 9: Restrict to patients residing in County of London at the time of admission
*********************************************************************

use "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear
keep regid county_HOSP
merge 1:m regid using "$PROJ_PATH/processed/intermediate/crosswalks/pre_exist_hosp_icem_crosswalk.dta", keepusing(censusyr RecID) assert(1 3) keep(3) nogen
keep if county_HOSP == "LONDON"
drop regid county_HOSP
duplicates drop
unique censusyr RecID
tempfile london_admits
save `london_admits', replace

use "$PROJ_PATH/processed/temp/table_04_pre_existing_analysis_data.dta", clear 
merge 1:1 censusyr RecID using `london_admits', keep (1 3)
drop if patient == 1 & _merge != 3
drop _merge
bysort sibling_id: keep if _N == 2

xtset sibling_id
drop hhid pid RecID 
save "$PROJ_PATH/processed/data/table_a17_col_09.dta", replace

*********************************************************************
// Table A18 Column 7: Add multiple siblings 
*********************************************************************

* Column 1: Add multiple siblings
use "$PROJ_PATH/processed/temp/table_04_disability_analysis_data.dta", clear 
keep sibling_id censusyr RecID
tempfile indivs
save `indivs', replace

keep sibling_id
duplicates drop
tempfile ids
save `ids', replace

use "$PROJ_PATH/processed/intermediate/final_build/disability_analysis_setup.dta" if `baseline_restrictions' & `disability_restrictions', clear
merge m:1 sibling_id using `ids', assert(1 3) keep(3) nogen
merge 1:1 sibling_id censusyr RecID using `indivs', assert(1 3)
gen final_sample = (_merge == 3)
drop _merge

drop if patient == 1 & final_sample == 0 // Drop patients not in final sample

gen final_sex = sex*final_sample
egen max_gender = max(final_sex), by(sibling_id)
drop if sex != max_gender & final_sample == 0
drop final_sex max_gender

local samp_pat "samp_pat = max(patient == 1 & insample == 1 & age_diff == 0), by(sibling_id)"
local samp_sib "samp_sib = max(patient == 0 & insample == 1 & age_diff <= 5), by(sibling_id)"

gen flag_extra_sibpat = 0

gen insample = (`baseline_restrictions' & disab_any != . & `disability_restrictions')

* Compute age difference between siblings

preserve

	keep if patient == 1 & insample == 1
	keep sibling_id age_child
	bysort sibling_id age_child: keep if _n == 1
	egen temp_id = seq(), by(sibling_id)
	sum temp_id
	local max_obs = r(max)
	rename age_child patage
	reshape wide patage, i(sibling_id) j(temp_id)
	tempfile age_diff
	save `age_diff', replace
	
restore

* Compute pid difference between siblings

preserve

	keep if patient == 1 & insample == 1
	keep sibling_id pid
	bysort sibling_id pid: keep if _n == 1
	egen temp_id = seq(), by(sibling_id)
	sum temp_id
	local max_pid = r(max)
	rename pid patpid
	reshape wide patpid, i(sibling_id) j(temp_id)
	tempfile pid_diff
	save `pid_diff', replace
	
restore	

capture drop age_diff
tempvar sortorder
gen `sortorder' = _n

merge m:1 sibling_id using `age_diff', assert(1 3) keep(1 3) nogen
merge m:1 sibling_id using `pid_diff', assert(1 3) keep(1 3) nogen

forvalues x = 1(1)`max_obs' {
	gen temp`x' = abs(age_child - patage`x')
}
egen age_diff = rowmin(temp1-temp`max_obs')
drop temp* patage*

forvalues x = 1(1)`max_pid' {
	gen temp`x' = abs(pid - patpid`x')
}
egen pid_diff = rowmin(temp1-temp`max_pid')
drop temp* patpid*

sort `sortorder'
drop `sortorder'

egen `samp_pat'
egen `samp_sib'

gen base_sample = (samp_pat == 1 & samp_sib == 1 & insample == 1)

* Drop households with multiple patients

egen mult_pat_hh = total(insample == 1 & patient == 1 & samp_pat == 1), by(sibling_id)
replace flag_extra_sibpat = 1 if mult_pat_hh > 1 & !missing(mult_pat_hh)
drop mult_pat_hh insample samp_pat samp_sib

gen insample = (disab_any != . & base_sample == 1 & flag_extra_sibpat == 0 & `baseline_restrictions' & `disability_restrictions')
egen `samp_pat'
egen `samp_sib'	

drop flag_extra_sibpat base_sample

* Define variable for older sibling of each patient and healthy sibling pair

egen first_sib = min(brthord) if insample == 1 & samp_pat == 1 & samp_sib == 1, by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

keep if `sibling_restrictions'

xtset sibling_id
drop hhid pid RecID 
save "$PROJ_PATH/processed/data/table_a18_col_07.dta", replace

*********************************************************************
// Table A18 Column 8: Add multiple patient households
*********************************************************************

use "$PROJ_PATH/processed/temp/table_04_disability_analysis_data.dta", clear 
keep sibling_id censusyr RecID
tempfile indivs
save `indivs', replace

keep sibling_id
duplicates drop
tempfile ids
save `ids', replace

use "$PROJ_PATH/processed/intermediate/final_build/disability_analysis_setup.dta" if `baseline_restrictions' & `disability_restrictions', clear
merge 1:1 sibling_id censusyr RecID using `indivs', keep(1) nogen

egen tot_pat = total(patient == 1), by(sibling_id)
keep if tot_pat > 1

egen boy_pats = total(patient == 1 & sex == 1), by(sibling_id)
egen girl_pats = total(patient == 1 & sex == 2), by(sibling_id)

drop if boy_pats == 0 & sex == 1
drop if girl_pats == 0 & sex == 2

tempfile mult_pats
save `mult_pats', replace

use "$PROJ_PATH/processed/intermediate/final_build/disability_analysis_setup.dta" if `baseline_restrictions' & `disability_restrictions', clear
merge m:1 sibling_id using `ids', assert(1 3) keep(3) nogen
merge 1:1 sibling_id censusyr RecID using `indivs', assert(1 3)
gen final_sample = (_merge == 3)
drop _merge

drop if patient == 1 & final_sample == 0 // Drop patients not in final sample

gen final_sex = sex*final_sample
egen max_gender = max(final_sex), by(sibling_id)
drop if sex != max_gender & final_sample == 0
drop final_sex max_gender

append using `mult_pats'
recode final_sample (mis = 0)

local samp_pat "samp_pat = max(patient == 1 & insample == 1 & age_diff == 0), by(sibling_id)"
local samp_sib "samp_sib = max(patient == 0 & insample == 1 & age_diff <= 5), by(sibling_id)"

gen insample = (`baseline_restrictions' & disab_any != . & `disability_restrictions')

* Compute age difference between siblings

preserve

keep if patient == 1 & insample == 1
	keep sibling_id age_child
	bysort sibling_id age_child: keep if _n == 1
	egen temp_id = seq(), by(sibling_id)
	sum temp_id
	local max_obs = r(max)
	rename age_child patage
	reshape wide patage, i(sibling_id) j(temp_id)
	tempfile age_diff
	save `age_diff', replace
	
restore

* Compute pid difference between siblings

preserve

	keep if patient == 1 & insample == 1
	keep sibling_id pid
	bysort sibling_id pid: keep if _n == 1
	egen temp_id = seq(), by(sibling_id)
	sum temp_id
	local max_pid = r(max)
	rename pid patpid
	reshape wide patpid, i(sibling_id) j(temp_id)
	tempfile pid_diff
	save `pid_diff', replace
	
restore	

capture drop age_diff
tempvar sortorder
gen `sortorder' = _n
merge m:1 sibling_id using `age_diff', assert(1 3) keep(1 3) nogen
merge m:1 sibling_id using `pid_diff', assert(1 3) keep(1 3) nogen
	
forvalues x = 1(1)`max_obs' {
	gen temp`x' = abs(age_child - patage`x')
}
egen age_diff = rowmin(temp1-temp`max_obs')
drop temp* patage*

forvalues x = 1(1)`max_pid' {
	gen temp`x' = abs(pid - patpid`x')
}
egen pid_diff = rowmin(temp1-temp`max_pid')
drop temp* patpid*

sort `sortorder'
drop `sortorder'

egen `samp_pat'
egen `samp_sib'

* Define variable for oldest sibling in household in sample

egen first_sib = min(brthord) if insample == 1 & samp_pat == 1 & samp_sib == 1, by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

keep if `sibling_restrictions'

xtset sibling_id
drop hhid pid RecID 
save "$PROJ_PATH/processed/data/table_a18_col_08.dta", replace

*********************************************************************
// Table A18 Column 9: Restrict to patients residing in County of London at the time of admission
*********************************************************************

use "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear
keep regid county_HOSP
merge 1:m regid using "$PROJ_PATH/processed/intermediate/crosswalks/disability_hosp_icem_crosswalk.dta", keepusing(censusyr RecID) assert(1 3) keep(3) nogen
keep if county_HOSP == "LONDON"
drop regid county_HOSP
duplicates drop
unique censusyr RecID
tempfile london_admits
save `london_admits', replace

use "$PROJ_PATH/processed/temp/table_04_disability_analysis_data.dta", clear 
merge 1:1 censusyr RecID using `london_admits', keep (1 3)
drop if patient == 1 & _merge != 3
drop _merge
bysort sibling_id: keep if _N == 2

xtset sibling_id
drop hhid pid RecID 
save "$PROJ_PATH/processed/data/table_a18_col_09.dta", replace

*********************************************************************
// Table A19 Column 7: Add multiple siblings 
*********************************************************************

use "$PROJ_PATH/processed/intermediate/final_build/occupational_analysis_setup.dta", clear

local samp_pat "samp_pat = max(patient == 1 & insample == 1 & age_diff == 0), by(sibling_id)"
local samp_sib "samp_sib = max(patient == 0 & insample == 1 & age_diff <= 5), by(sibling_id)"

gen flag_extra_sibpat = 0

gen insample = (`baseline_restrictions' & disab_any != . & `occupation_restrictions')

* Compute age difference between siblings

preserve
	keep if patient == 1 & insample == 1
	keep sibling_id age_child
	bysort sibling_id age_child: keep if _n == 1
	egen temp_id = seq(), by(sibling_id)
	sum temp_id
	local max_obs = r(max)
	rename age_child patage
	reshape wide patage, i(sibling_id) j(temp_id)
	tempfile age_diff
	save `age_diff', replace
restore

* Compute pid difference between siblings

preserve
	keep if patient == 1 & insample == 1
	keep sibling_id pid_child
	bysort sibling_id pid_child: keep if _n == 1
	egen temp_id = seq(), by(sibling_id)
	sum temp_id
	local max_pid = r(max)
	rename pid_child patpid
	reshape wide patpid, i(sibling_id) j(temp_id)
	tempfile pid_diff
	save `pid_diff', replace
restore	

capture drop age_diff
tempvar sortorder
gen `sortorder' = _n

merge m:1 sibling_id using `age_diff', assert(1 3) keep(1 3) nogen
merge m:1 sibling_id using `pid_diff', assert(1 3) keep(1 3) nogen

forvalues x = 1(1)`max_obs' {
	gen temp`x' = abs(age_child - patage`x')
}
egen age_diff = rowmin(temp1-temp`max_obs')
drop temp* patage*

forvalues x = 1(1)`max_pid' {
	gen temp`x' = abs(pid_child - patpid`x')
}
egen pid_diff = rowmin(temp1-temp`max_pid')
drop temp* patpid*

sort `sortorder'
drop `sortorder'

egen `samp_pat'
egen `samp_sib'

gen base_sample = (samp_pat == 1 & samp_sib == 1 & insample == 1)

* Drop households with multiple patients

egen mult_pat_hh = total(insample == 1 & patient == 1 & samp_pat == 1), by(sibling_id)
replace flag_extra_sibpat = 1 if mult_pat_hh > 1 & !missing(mult_pat_hh)
drop mult_pat_hh insample samp_pat samp_sib

gen insample = (disab_any != . & base_sample == 1 & flag_extra_sibpat == 0 & `baseline_restrictions' & `occupation_restrictions')
egen `samp_pat'
egen `samp_sib'	

drop flag_extra_sibpat base_sample

* Define variable for oldest sibling in household in sample

egen first_sib = min(brthord) if insample == 1 & samp_pat == 1 & samp_sib == 1, by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

keep if `sibling_restrictions'

xtset sibling_id
drop hhid pid_child RecID_child RecID_adult hh_occ ia_occ
save "$PROJ_PATH/processed/data/table_a19_col_07.dta", replace

*********************************************************************
// Table A19 Column 8: Add multiple patient households
*********************************************************************

use "$PROJ_PATH/processed/intermediate/final_build/occupational_analysis_setup.dta", clear

local samp_pat "samp_pat = max(patient == 1 & insample == 1 & age_diff == 0), by(sibling_id)"
local samp_sib "samp_sib = max(patient == 0 & insample == 1 & age_diff <= 5), by(sibling_id)"

gen insample = (disab_any != . & `baseline_restrictions' & `occupation_restrictions')

* Compute age difference between siblings

preserve
	keep if patient == 1 & insample == 1
	keep sibling_id age_child
	bysort sibling_id age_child: keep if _n == 1
	egen temp_id = seq(), by(sibling_id)
	sum temp_id
	local max_obs = r(max)
	rename age_child patage
	reshape wide patage, i(sibling_id) j(temp_id)
	tempfile age_diff
	save `age_diff', replace
restore

* Compute pid difference between siblings

preserve
	keep if patient == 1 & insample == 1
	keep sibling_id pid_child
	bysort sibling_id pid_child: keep if _n == 1
	egen temp_id = seq(), by(sibling_id)
	sum temp_id
	local max_pid = r(max)
	rename pid_child patpid
	reshape wide patpid, i(sibling_id) j(temp_id)
	tempfile pid_diff
	save `pid_diff', replace
restore	

capture drop age_diff
tempvar sortorder
gen `sortorder' = _n

merge m:1 sibling_id using `age_diff', assert(1 3) keep(1 3) nogen
merge m:1 sibling_id using `pid_diff', assert(1 3) keep(1 3) nogen

forvalues x = 1(1)`max_obs' {
	gen temp`x' = abs(age_child - patage`x')
}
egen age_diff = rowmin(temp1-temp`max_obs')
drop temp* patage*

forvalues x = 1(1)`max_pid' {
	gen temp`x' = abs(pid_child - patpid`x')
}
egen pid_diff = rowmin(temp1-temp`max_pid')
drop temp* patpid*

sort `sortorder'
drop `sortorder'

egen `samp_pat'
egen `samp_sib'

* Define variable for oldest sibling in household in sample

egen first_sib = min(brthord) if insample == 1 & samp_pat == 1 & samp_sib == 1, by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

keep if `sibling_restrictions'

xtset sibling_id
drop hhid pid_child RecID_child RecID_adult hh_occ ia_occ
save "$PROJ_PATH/processed/data/table_a19_col_08.dta", replace

*********************************************************************
// Table A19 Column 9: Restrict to patients residing in County of London at the time of admission
*********************************************************************

use "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear
keep regid county_HOSP
merge 1:m regid using "$PROJ_PATH/processed/intermediate/crosswalks/occupational_hosp_icem_crosswalk.dta", keepusing(censusyr RecID_child outcomeyr RecID_adult) assert(1 3) keep(3) nogen
keep if county_HOSP == "LONDON"
drop regid county_HOSP
duplicates drop
unique censusyr RecID_child outcomeyr RecID_adult
tempfile london_admits
save `london_admits', replace

use "$PROJ_PATH/processed/temp/table_04_col_10.dta", clear
merge 1:1 censusyr RecID_child outcomeyr RecID_adult using `london_admits', keep (1 3)
drop if patient == 1 & _merge != 3
bysort sibling_id: keep if _N == 2
drop _merge hhid pid_child RecID_child RecID_adult hh_occ ia_occ

save "$PROJ_PATH/processed/data/table_a19_col_09.dta", replace

*********************************************************************
*********************************************************************
// Figure A7: Does father's occupational status change over time?
*********************************************************************
*********************************************************************

* Link to hospital records and final sample

forvalues y = 1881(10)1901 {
	
	use "$PROJ_PATH/processed/temp/table_02_occupational_analysis_data.dta" if patient == 1, clear
	keep if censusyr == `y'
	rename censusyr Year
	rename RecID_child RecID
	merge m:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`y'_identifiers.dta", keep(1 3) nogen keepusing(poprecid)
	rename poprecid ic_poprecid
	rename Year censusyr
	keep censusyr ic_poprecid
	duplicates drop
	tempfile pop`y'
	save `pop`y'', replace
}
clear
forvalues y = 1881(10)1901 {
	append using `pop`y'',
}
tempfile final_sample_child
save `final_sample_child', replace

rename censusyr outcomeyr
rename ic_poprecid ia_poprecid
tempfile final_sample_adult
save `final_sample_adult', replace

clear
forvalues t_1 = 1881(10)1891 {
	
	local t_2 = `t_1' + 10
	append using "$PROJ_PATH/processed/intermediate/icem_linked_fathers/fathers_linked_`t_1'_`t_2'.dta"
}

* Patients and final sample separately

gen hosp_final = 0
merge m:1 censusyr ic_poprecid using `final_sample_child', keep(1 3)
replace hosp_final = 1 if _merge == 3
drop _merge

merge m:1 outcomeyr ia_poprecid using `final_sample_adult', keep(1 3)
replace hosp_final = 1 if _merge == 3
drop _merge

sort censusyr ParID h ic_poprecid

* Drop parishes with no hospitalized patients

egen pat_in_par = total(hosp_patient == 1), by(ConParID)
drop if pat_in_par == 0

* Drop households who end up hospitalized before earlier census date or after later census date (Note: so far only dropping those in final sample)

drop if (hosp_pre == 1 & hosp_patient == 0) | (hosp_post == 1 & hosp_patient == 0)

egen dist_id = group(ConParID)
xtset dist_id

gen group_1 = (hosp_patient == 0 & hosp_final == 0)
gen group_2 = (hosp_patient == 1)
gen group_3 = (hosp_final == 1)

keep if ic_popage >= 18 & ic_popage <= 65

tempfile group_input
save `group_input', replace

forvalues x = 1(1)3 {
	use `group_input', clear
	keep if group_`x' == 1
	tempfile group_`x'
	save `group_`x'', replace
}
clear
forvalues x = 1(1)3 {
	append using `group_`x''
}

gen group_id = 0
replace group_id = 1 if group_1 == 1
replace group_id = 2 if group_2 == 1
replace group_id = 3 if group_3 == 1

label define group_lab 1 "Rest of pop." 2 "Hospital pop." 3 "Empirical sample", replace
la val group_id group_lab
tab group_id

collapse (mean) pop_up pop_dn pop_uc, by(group_id)

order pop_up pop_dn pop_uc, last 
rename pop_up v1
rename pop_dn v2
rename pop_uc v3

gen id = _n
reshape long v, i(id) j(y)
drop id

label define y_lab 1 "Upward mobility" 2 "Downward mobility" 3 "Same status", replace
la val y y_lab

reshape wide v, i(y) j(group_id)

save "$PROJ_PATH/processed/data/figure_a07.dta", replace

*********************************************************************
*********************************************************************
// Figure A13: Density of HDI in full set of hospital records vs. estimation sample
*********************************************************************
*********************************************************************

use "$PROJ_PATH/processed/temp/table_02_occupational_analysis_data.dta" if patient == 1, clear
keep resid_mort
gen obs_id = _n
gen sample = 1
tempfile final_sample
save `final_sample', replace

use resid_mort sex_HOSP using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta" if sex_HOSP == 1, clear
drop sex_HOSP
gen obs_id = _n 
gen sample = 2
append using `final_sample'

keep resid_mort sample
save "$PROJ_PATH/processed/data/figure_a13.dta", replace

*********************************************************************
*********************************************************************
// Figure A14: Robustness of single marital status results
*********************************************************************
*********************************************************************

* Run marital status data construction separately for each matching threshold in robustness checks

// Panel (a): Robustness to tolerance for mismatched names 

local age_dist = 3
local sim_records = 20

forvalues gender = 1(1)2 {
	
	forvalues x = 1(1)9 {
		
		local jw_bot = 1 - (`x' - 1)*0.025
		
		do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/06.03_single_marital_status_setup.do" `gender' `jw_bot' `age_dist' `sim_records'
		
	}
}	

// Panel (b): Robustness to restrictions on similar names

local x = 9
local jw_bot = 1 - (`x' - 1)*0.025
local age_dist = 3

forvalues gender = 1(1)2 {
	
	foreach y in 4 6 8 10 15 20 50 100 1000 { 
		
		local sim_records = `y'
		
		do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/06.03_single_marital_status_setup.do" `gender' `jw_bot' `age_dist' `sim_records'
		
	}
}

// Panel (c): Age gap between census links

local x = 9
local jw_bot = 1 - (`x' - 1)*0.025
local sim_records = 20

forvalues gender = 1(1)2 {

	forvalues age_dist = 0(1)3 {
		
		do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data/06.03_single_marital_status_setup.do" `gender' `jw_bot' `age_dist' `sim_records'
		
	}
}

forvalues gender = 1(1)2 {
	rm "$PROJ_PATH/processed/temp/singles_`gender'_double_links.dta"
}

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Calculate standard deviation and median of HDI for hospital population
*********************************************************************************************************************************************
*********************************************************************************************************************************************

use "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear
sum resid_mort, d
gen resid_mort_sigma = r(sd)
gen resid_mort_med = r(p50)
gen resid_mort_mu = r(mean)

keep in 1
keep resid_mort_*
save "$PROJ_PATH/processed/data/_hospital_resid_mort_descriptives.dta", replace

*********************************************************************

rm "$PROJ_PATH/processed/temp/table_04_schooling_analysis_data.dta"
rm "$PROJ_PATH/processed/temp/table_04_pre_existing_analysis_data.dta"
rm "$PROJ_PATH/processed/temp/table_04_disability_analysis_data.dta"
rm "$PROJ_PATH/processed/temp/table_04_col_10.dta"

forvalues gender = 1(1)2 {
	rm "$PROJ_PATH/processed/temp/table_03_singles_analysis_data_`gender'.dta"
}

disp "DateTime: $S_DATE $S_TIME"

* EOF
