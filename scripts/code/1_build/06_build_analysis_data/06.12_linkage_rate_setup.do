version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 06.12_linkage_rate_setup.do
* PURPOSE: This do file runs the regressions to produce all tables and figures in the paper and appendix
************

*********************************************************************
*********************************************************************
// Table 1: Hospital to census linkage
*********************************************************************
*********************************************************************

******************************************************************************************
* Panel A: Match rates at each step of linkage process
******************************************************************************************

* Gather final sample 

use "$PROJ_PATH/processed/temp/table_02_occupational_analysis_data.dta", clear
keep if patient == 1

keep censusyr RecID_child outcomeyr RecID_adult
merge 1:m censusyr RecID_child outcomeyr RecID_adult using "$PROJ_PATH/processed/intermediate/crosswalks/occupational_hosp_icem_crosswalk.dta", keepusing(regid) assert(2 3) keep(3) nogen
keep regid censusyr outcomeyr 
rename censusyr censusyr_combined 
rename outcomeyr outcomeyr_combined
gen final_sample_combined = 1
tempfile final_sample_combined
save `final_sample_combined', replace

* Extract valid admissions that get searched for in census


use "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_1881/match_input_hosp_criteria.dta", clear
gen censusyr = 1881
append using "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_1891/match_input_hosp_criteria.dta"
replace censusyr = 1891 if censusyr == .
append using "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_1901/match_input_hosp_criteria.dta"
replace censusyr = 1901 if censusyr == .

// Drop admissions more than 10 years apart from census

merge m:1 regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", keepusing(admityr) assert(2 3) keep(3) nogen

gen hosp_census_gap = abs(censusyr - admityr)
tab hosp_census_gap
drop if hosp_census_gap > 10
drop hosp_census_gap admityr

forvalues y = 1881(10)1901 {
	egen match_input`y' = max(censusyr == `y'), by(regid)
}
egen match_input9999 = rowmax(match_input*)

keep regid match_input*
bysort regid match_input*: keep if _n == 1

merge 1:1 regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", keepusing(hospid admitage unassigned resid_mort sex_HOSP admityr byr_lb_HOSP pat_id_proxy ever_died) assert(2 3) keep(3) nogen
bysort pat_id_proxy: gen tot_visits = _N

merge m:1 regid using `final_sample_combined', assert(1 3) nogen keepusing(regid final_sample_combined)
recode final_sample_combined (mis = 0)

// Drop patients who died in hospital since they do not get matched
drop if ever_died == 1

// Drop patients who are too young to have outcomes
drop if byr_lb_HOSP > 1891 & final_sample_combined == 0

// Restrict to boys 
keep if sex_HOSP == 1

// Identify patients satisfying final sample restrictions

gen pat_criteria = (unassigned == 0 & resid_mort != . & tot_visits <= 9) 
tab hospid
keep regid hospid match_input* pat_criteria sex_HOSP

tempfile baseline_patients
save `baseline_patients', replace

* Identify admissions matched separately to each childhood census year

use "$PROJ_PATH/processed/intermediate/crosswalks/occupational_hosp_icem_links.dta", clear

replace age_child = age_child - (outcomeyr - censusyr)
gen byr_child = censusyr - age_child
gen byr_adult = outcomeyr - age_adult

forvalues y = 1881(10)1901 {
	forvalues z = 1901(10)1911 {
		egen matched_to_outcome`y'_`z' = max(age_child <= 21 & age_adult >= 18 & age_adult <= 41 & (byr_child >= 1870 & byr_child <= 1891) & (byr_adult >=1870 & byr_adult <= 1890) & jw_sname_ICEM >= 0.80 & max(jw_fname_orig_ICEM,jw_fname_edit_ICEM) >= 0.80 & similar_10_ICEM <= 20 & jw_sname >= 0.80 & max(jw_fname_orig,jw_fname_edit) >= 0.80 & similar_10 <= 20 & age_dist_child <= 3 & censusyr == `y' & outcomeyr == `z'), by(regid)
	}
}
keep regid matched_to_outcome*
bysort regid matched_to_outcome*: keep if _n == 1
tempfile outcome_patients
save `outcome_patients', replace

* Identify admissions in consolidated hospital-to-census match

use "$PROJ_PATH/processed/intermediate/crosswalks/occupational_hosp_icem_crosswalk.dta", clear

replace age_child = age_child - (outcomeyr - censusyr)
gen byr_child = censusyr - age_child
gen byr_adult = outcomeyr - age_adult

forvalues z = 1901(10)1911 {
	gen matched_to_outcome9999_`z' = (age_child <= 21 & age_adult >= 18 & age_adult <= 41 & (byr_child >= 1870 & byr_child <= 1891) & (byr_adult >=1870 & byr_adult <= 1890) & jw_sname_ICEM >= 0.80 & max(jw_fname_orig_ICEM,jw_fname_edit_ICEM) >= 0.80 & similar_10_ICEM <= 20 & jw_sname >= 0.80 & max(jw_fname_orig,jw_fname_edit) >= 0.80 & similar_10 <= 20 & age_dist_child <= 3 & outcomeyr == `z')
}
keep regid matched_to_outcome* censusyr
rename censusyr censusyr_matched
sort regid
tempfile combined_outcome_patients
save `combined_outcome_patients', replace

******************************************************************************************

* Gather siblings matched to outcome year

use "$PROJ_PATH/processed/intermediate/crosswalks/occupational_icem_hosp_analysis_input.dta" if sex == 1 & patient == 0 & age_diff <= 8 & sibling_id != ., clear
gen byr_child = censusyr - age_child
gen byr_adult = outcomeyr - age_adult

keep if (byr_child >= 1869 & byr_child <= 1893) & (byr_adult >=1870 & byr_adult <= 1893)
keep if age_child <= 21 & age_adult >= 18 & age_adult <= 41

rename RecID_child RecID
forvalues y = 1881(10)1901 {
	forvalues z = 1901(10)1911 {
		egen sibling_match`y'_`z' = max(jw_sname >= 0.80 & max(jw_fname_orig,jw_fname_edit) >= 0.80 & similar_10 <= 20 & jw_sname >= 0.80 & max(jw_fname_orig,jw_fname_edit) >= 0.80 & similar_10 <= 20 & censusyr == `y' & outcomeyr == `z'), by(censusyr RecID)
	}
}
keep censusyr RecID sibling_match*
bysort censusyr RecID sibling_match*: keep if _n == 1
tempfile sibling_matches
save `sibling_matches', replace

* Gather siblings from childhood census	

clear
forvalues year = 1881(10)1901 {
	append using "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'/icem_hosp_`year'_siblings.dta"
}

gen censusyr = Year
merge m:1 censusyr RecID using `sibling_matches', assert(1 3) nogen
recode sibling_match* (mis = 0)

rename sibling_id sibid_orig
egen sibling_id = group(censusyr sibid_orig)

forvalues y = 1881(10)1901 {
	forvalues z = 1901(10)1911 {
		egen sibling_outcome`y'_`z' = max(sibling_match`y'_`z' == 1 & censusyr == `y'), by(sibling_id)
	}
}

keep if age_diff <= 8 & sex == 1

gen byr = censusyr - age
keep if (byr >= 1870 & byr <= 1891 & patient == 1) | (byr >= 1869 & byr <= 1893 & patient == 0)

keep if age <= 21

egen max_brthord = max(brthord), by(sibling_id)
egen tot_sibs = total(sibling_id != .), by(sibling_id)

keep if patient == 1
keep censusyr RecID tot_sibs* max_brthord sibling_outcome* 
bysort censusyr RecID tot_sibs* max_brthord sibling_outcome*: keep if _n == 1
unique censusyr RecID
tempfile sibling_info
save `sibling_info', replace

* Identify admissions in final sample 

use "$PROJ_PATH/processed/temp/table_02_occupational_analysis_data.dta", clear
keep if patient == 1

gen final_sample = 1
keep censusyr outcomeyr RecID_child final_sample
rename RecID_child RecID
rename outcomeyr outcomeyr_final
tempfile final_sample
save `final_sample'

* Check number of admission uniquely matched to census

clear
forvalues year = 1881(10)1901 {
	append using "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'/unique_matches_`year'_hosp.dta"
}

gen age_child = .
replace age_child = age_1881 if censusyr == 1881
replace age_child = age_1891 if censusyr == 1891
replace age_child = age_1901 if censusyr == 1901

gen byr_child = censusyr - age_child
keep if byr_child >= 1870 & byr_child <= 1891

keep if sex == 1

keep if jw_sname >= 0.8 & max(jw_fname_orig,jw_fname_edit) >= 0.8 & age_dist <= 3 & similar_10 <= 20
keep censusyr regid RecID age_dist sex rescty_match similar_10 jw_sname jw_fname*

merge m:1 censusyr RecID using `sibling_info', assert(2 3) keep(3) nogen
merge m:1 censusyr RecID using `final_sample', assert(1 3) keep(1 3) nogen
recode final_sample outcomeyr_final (mis = 0)

egen censusyr_final = max(censusyr*final_sample), by(regid)

forvalues y = 1881(10)1901 {
	egen matched_to_census`y' = max(censusyr == `y' & jw_sname >= 0.8 & max(jw_fname_orig,jw_fname_edit) >= 0.8 & age_dist <= 3 & similar_10 <= 20), by(regid)
	egen matched_to_sib`y'  = max(tot_sibs > 0 & tot_sibs <= 11 & max_brthord <= 13 & censusyr == `y' & matched_to_census`y' == 1), by(regid)
	
	forvalues z = 1901(10)1911 {
		egen matched_final`y'_`z' = max(final_sample == 1 & censusyr == `y' & censusyr_final == `y' & outcomeyr_final == `z'), by(regid)
		egen matched_sibout`y'_`z' = max(matched_to_sib`y' == 1 & censusyr == `y' & sibling_outcome`y'_`z' == 1), by(regid)	
		replace matched_sibout`y'_`z' = 1 if matched_final`y'_`z' == 1 
		replace matched_to_census`y' = 1 if matched_final`y'_`z' == 1
		replace matched_to_sib`y' = 1 if matched_final`y'_`z' == 1
	}
}

keep regid matched_to_sib* matched_to_census* matched_sibout* matched_final* censusyr_final
bysort regid matched_to_sib* matched_to_census* matched_sibout* matched_final* censusyr_final: keep if _n == 1
unique regid
tempfile matched_ids
save `matched_ids', replace

* Gather multiple matches to censuses

clear
forvalues year = 1881(10)1901 {
	append using "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'/multiple_matches_`year'_hosp.dta"
}
keep if jw_sname >= 0.8 & max(jw_fname_orig,jw_fname_edit) >= 0.8 & age_dist <= 3

keep if sex == 1

gen age_child = .
replace age_child = age_1881 if censusyr == 1881
replace age_child = age_1891 if censusyr == 1891
replace age_child = age_1901 if censusyr == 1901

gen byr_child = censusyr - age_child
keep if byr_child >= 1870 & byr_child <= 1891

forvalues y = 1881(10)1901 {
	egen multiple_match`y' = max(censusyr == `y' & jw_sname >= 0.8 & max(jw_fname_orig,jw_fname_edit) >= 0.8 & age_dist <= 3), by(regid)
}

egen multiple_match9999 = rowmax(multiple_match*)

keep regid multiple_match*
bysort regid multiple_match*: keep if _n == 1
tempfile mm_ids
save `mm_ids', replace

* Combine files

use `baseline_patients', clear
merge 1:1 regid using `matched_ids', keep(1 3) nogen
recode matched_to_sib* matched_to_census* matched_sibout* matched_final* censusyr_final (mis = 0)

merge 1:1 regid using `mm_ids', keep(1 3) nogen
recode multiple_match* (mis = 0)

merge 1:1 regid using `outcome_patients', keepusing(regid matched_to_outcome*) keep(1 3) nogen
recode matched_to_outcome* (mis = 0)

merge 1:1 regid using `combined_outcome_patients', keepusing(regid matched_to_outcome* censusyr_matched) keep(1 3) nogen
recode matched_to_outcome* censusyr_matched (mis = 0)

merge 1:1 regid using `final_sample_combined', assert(1 3) nogen
recode final_sample_combined censusyr_combined outcomeyr_combined (mis = 0)

foreach y in 1881 1891 1901 {
	forvalues z = 1901(10)1911 {
		replace matched_final`y'_`z' = 1 if final_sample_combined == 1 & censusyr_combined == `y' & outcomeyr_combined == `z'
		replace matched_final`y'_`z' = 0 if final_sample_combined == 0
		replace matched_sibout`y'_`z' = 1 if matched_final`y'_`z' == 1 
		replace matched_to_census`y' = 1 if matched_final`y'_`z' == 1
		replace matched_to_sib`y' = 1 if matched_final`y'_`z' == 1
	}
}
drop *_combined

forvalues z = 1901(10)1911 {
	egen matched_final9999_`z' = rowmax(matched_final*_`z')
	egen matched_sibout9999_`z' = rowmax(matched_sibout*_`z')
}

foreach y in 1881 1891 1901 {
	forvalues z = 1901(10)1911 {
		replace matched_to_outcome`y'_`z' = 1 if matched_to_outcome`y'_`z' == 0 & matched_to_outcome9999_`z' == 1 & censusyr_matched == `y'
	}
}
forvalues z = 1901(10)1911 {
	replace matched_to_outcome9999_`z' = 1 if matched_final9999_`z' == 1
}
drop censusyr_matched censusyr_final

foreach y in 1881 1891 1901 {
	forvalues z = 1901(10)1911 {
		gen matched_patsib`y'_`z' = (matched_to_outcome`y'_`z' == 1 & matched_sibout`y'_`z' == 1)
		replace matched_to_census`y' = 1 if matched_to_outcome`y'_`z' == 1
	}
}

foreach y in 1881 1891 1901 {
	egen matched_to_outcome`y' = rowmax(matched_to_outcome`y'_*)
	egen matched_sibout`y' = rowmax(matched_sibout`y'_*)
	egen matched_patsib`y' = rowmax(matched_patsib`y'_*)
	egen matched_final`y' = rowmax(matched_final`y'_*)
}
drop *_1901 *_1911

foreach y in 1881 1891 1901 {
	replace match_input`y' = 1 if matched_final`y' == 1
	replace matched_to_census`y' = 0 if match_input`y' == 0
	replace matched_to_sib`y' = 0 if match_input`y' == 0
	replace matched_to_outcome`y' = 0 if match_input`y' == 0
	replace matched_sibout`y' = 0 if match_input`y' == 0
	replace matched_patsib`y' = 0 if match_input`y' == 0
}

egen matched_to_census9999 = rowmax(matched_to_census*)
egen matched_to_sib9999 = rowmax(matched_to_sib*)
egen matched_to_outcome9999 = rowmax(matched_to_outcome*)
egen matched_sibout9999 = rowmax(matched_sibout*)
egen matched_patsib9999 = rowmax(matched_patsib*)
egen matched_final9999 = rowmax(matched_final*)

replace match_input9999 = 1 if matched_final9999 == 1
replace matched_to_census9999 = 1 if matched_final9999 == 1
replace matched_to_sib9999 = 1 if matched_final9999 == 1
replace matched_to_outcome9999 = 1 if matched_final9999 == 1
replace matched_sibout9999 = 1 if matched_final9999 == 1
replace matched_patsib9999 = 1 if matched_final9999 == 1

foreach y in 1881 1891 1901 9999 {
	replace multiple_match`y' = 0 if matched_to_census`y' == 1
	gen no_match`y' = (multiple_match`y' == 0 & matched_to_census`y' == 0)
}

// Reshape data 

reshape long match_input no_match multiple_match matched_to_census matched_to_sib matched_to_outcome matched_sibout matched_patsib matched_final, i(regid) j(censusyr)

label define year_lab 1881 "1881" 1891 "1891" 1901 "1901" 9999 "Any", replace
la val censusyr year_lab

la var no_match "No match"
la var multiple_match "Multiple matches"
la var matched_to_census "Unique match"
la var matched_to_sib "Sibling present"
la var matched_to_outcome "Patient matched"
la var matched_sibout "Sibling matched"
la var matched_patsib "Patient and sibling"
la var matched_final "In final sample"

order regid sex_HOSP hospid censusyr match_input matched_to_census matched_to_sib matched_to_outcome matched_sibout matched_patsib matched_final

save "$PROJ_PATH/processed/data/table_01.dta", replace

*********************************************************************
*********************************************************************
// Table A21: Health index and likelihood of match
*********************************************************************
*********************************************************************

use "$PROJ_PATH/processed/data/table_01.dta", clear
merge m:1 regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", keepusing(resid_mort admitage admityr admitdate dischdate died) keep(1 3) nogen
la var resid_mort "Health deficiency index"

local census_date_1871 = mdy(4,2,1871)
local census_date_1881 = mdy(4,2,1881)
local census_date_1891 = mdy(4,5,1891)
local census_date_1901 = mdy(3,31,1901)
local census_date_9999 = mdy(3,31,1901)

keep if resid_mort != . & died == 0 & sex_HOSP == 1 & admitage <= 11 & match_input == 1 & ( ///
																		  (censusyr == 1881 & admitdate > `census_date_1871' & dischdate < `census_date_1881') | ///
																		  (censusyr == 1891 & admitdate > `census_date_1881' & dischdate < `census_date_1891') | ///
																		  (censusyr == 1901 & admitdate > `census_date_1891' & dischdate < `census_date_1901') ///
																		  )

save "$PROJ_PATH/processed/data/table_a21.dta", replace	

*********************************************************************
*********************************************************************
// Table A22: Census-to-census linkage
*********************************************************************
*********************************************************************

// Creates datasets for table with match rates from childhood to adulthood censuses													  

forvalues t_1 = 1881(10)1901 {
	if `t_1' < 1901 {
		local y_min = 1901
	}
	else {
		local y_min = 1911
	}
	forvalues t_2 = `y_min'(10)1911 {
	
		use "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/multiple_matches_`t_1'_`t_2'.dta", clear
		keep if sex == 1
		drop sex
		rename RecID_child RecID

		egen multiple_match = max(jw_sname >= 0.8 & max(jw_fname_orig,jw_fname_edit) >= 0.8), by(RecID)
		egen multiple_strict = max(jw_sname >= 0.9 & max(jw_fname_orig,jw_fname_edit) >= 0.9), by(RecID)
		
		keep censusyr RecID multiple_match multiple_strict
		bysort censusyr RecID multiple_match multiple_strict: keep if _n == 1
		
		tempfile mm_`t_1'_`t_2'
		save `mm_`t_1'_`t_2'', replace

		use "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/unique_matches_`t_1'_`t_2'.dta", clear
		keep if sex == 1
		rename RecID_child RecID
		
		egen unique_match = max(jw_sname >= 0.8 & max(jw_fname_orig,jw_fname_edit) >= 0.8 & similar_10 <= 20), by(RecID)
		egen unique_strict = max(jw_sname >= 0.9 & max(jw_fname_orig,jw_fname_edit) >= 0.9 & similar_10 <= 10 & bpar_mismatch == 0), by(RecID)
		
		keep censusyr RecID unique_match unique_strict
		bysort censusyr RecID unique_match unique_strict: keep if _n == 1
		
		tempfile um_`t_1'_`t_2'
		save `um_`t_1'_`t_2'', replace

		use RecID_`t_1' sex bcounty using "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/match_input_`t_1'_criteria.dta", clear
		keep if sex == 1
		drop sex
		
		rename RecID_`t_1' RecID
		rename bcounty county_code
		merge m:1 county_code using "$PROJ_PATH/processed/intermediate/geography/icem_county_codebook.dta", keep(1 3) nogen keepusing(country_code)
		rename county_code bcounty
		
		merge m:1 RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`t_1'_birthplace.dta", keep(3) nogen keepusing(Cnti)
		recast str Cnti
		
		rename Cnti std_par
		merge m:1 std_par using "$PROJ_PATH/processed/intermediate/geography/icem_london_std_par.dta", keep(1 3)
		replace bcounty = "LND" if _merge == 3
		drop _merge
		
		egen england = max(country_code == "ENG"), by(RecID)
		egen greater_london = max(bcounty == "KEN" | bcounty == "MDX" | bcounty == "SRY"), by(RecID)
		egen london_county = max(bcounty == "LND"), by(RecID)
		
		keep RecID england greater_london london_county
		bysort RecID england greater_london london_county: keep if _n == 1
		gen censusyr = `t_1'

		merge 1:1 RecID using `mm_`t_1'_`t_2'', assert(1 3) nogen
		merge 1:1 RecID using `um_`t_1'_`t_2'', assert(1 3) nogen
		
		recode unique_match multiple_match multiple_strict unique_strict (mis = 0)

		replace multiple_match = 0 if unique_match == 1
		replace multiple_strict = 0 if unique_strict == 1
		gen no_match = (unique_match == 0 & multiple_match == 0)
		gen no_strict = (unique_strict == 0 & multiple_strict == 0)

		la var no_match "No match"
		la var multiple_match "Multiple matches"
		la var unique_match "Unique match"
		
		la var no_strict "No match"
		la var multiple_strict "Multiple matches"
		la var unique_strict "Unique match"
		
		drop RecID
		save "$PROJ_PATH/processed/data/table_a22_icem_census_match_rates_`t_1'_`t_2'.dta", replace
	}
}

rm "$PROJ_PATH/processed/temp/table_02_occupational_analysis_data.dta"
																	  
disp "DateTime: $S_DATE $S_TIME"

* EOF
