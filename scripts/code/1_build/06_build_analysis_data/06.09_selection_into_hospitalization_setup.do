version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 06.09_selection_into_hospitalization_setup.do
* PURPOSE: This do file creates a dataset to examine selection into hospitalization and estimate naive OLS
************

***** Census (age 0 to 5) --> Hospital (age 0 to 11 hospitalization) *****

// Gather all hospital admissions uniquely matched to 1881-1901 censuses
clear
forvalues y = 1881(10)1901 {
	append using "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`y'/unique_matches_`y'_hosp.dta"
}	

// Identify patients admitted after census enumeration
merge m:1 regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", assert(2 3) keep(3) keepusing(admityr admitdate admitage hospid resid_mort died) nogen

gen census_date = .
replace census_date = mdy(4,2,1881) if censusyr == 1881
replace census_date = mdy(4,5,1891) if censusyr == 1891
replace census_date = mdy(3,31,1901) if censusyr == 1901

gen next_census_date = .
replace next_census_date = mdy(4,5,1891) if censusyr == 1881
replace next_census_date = mdy(3,31,1901) if censusyr == 1891
replace next_census_date = mdy(4,2,1911) if censusyr == 1901

format census_date next_census_date %td

keep if admitdate > census_date & admitdate < next_census_date

egen min_hosp_census_gap = min(admitdate - census_date), by(regid)
drop if admitdate - census_date != min_hosp_census_gap
drop min_hosp_census_gap
unique regid

gen patient_match = (jw_sname >= 0.8 & max(jw_fname_orig,jw_fname_edit) >= 0.8 & age_dist <= 3 & similar_10 <= 20)
keep if patient_match == 1

// Separate patients admitted age 0 to 5 vs. 6 to 11
egen patient_0to5  = max(admitage <= 5), by(censusyr RecID)
egen patient_6to11 = max(admitage >= 6 & admitage <= 11), by(censusyr RecID)

// Generate hospital specific patient variables
egen patient_barts = max(hospid == 1), by(censusyr RecID)
egen patient_gosh  = max(hospid == 2), by(censusyr RecID)
egen patient_guys  = max(hospid == 5), by(censusyr RecID)

keep censusyr RecID patient_* resid_mort died
rename censusyr Year

egen max_mort = max(resid_mort), by(Year RecID)
replace resid_mort = max_mort
drop max_mort

egen max_died = max(died), by(Year RecID)
replace died = max_died
drop max_died

duplicates drop
unique Year RecID
sort Year RecID
tempfile pooledpats
save `pooledpats', replace

// Restrict to patients residing in London
clear
forvalues y = 1881(10)1901 {
	append using "$PROJ_PATH/processed/intermediate/final_build/hosp_catchment_area_`y'.dta"
}
merge 1:1 Year RecID using `pooledpats', keep(1 3) nogen
recode patient_* resid_mort died (mis = 0)

// Generate new sibling ID
egen temp_sibid = group(Year sibling_id)
drop sibling_id
rename temp_sibid sibling_id

// What ages are patients in the census?
tab Age if patient_match == 1
tab Age if patient_0to5 == 1
tab Age if patient_6to11 == 1

// Restrict to individuals age 0 to 11 
keep if Age <= 11

// Restrict to households with children age 0 to 11
egen valid_hh = max(Age <= 11), by(Year h ParID)
tab valid_hh patient_match
keep if valid_hh == 1

// Redefine sibling variables
replace sibsize = sibsize - 1
replace msibsize = msibsize - 1 if Sex == 1
replace fsibsize = fsibsize - 1 if Sex == 2

// Generate household level variables
egen tot_boys = total(Sex == 1 & patient_match == 0) if sibling_id != ., by(Year sibling_id)
egen tot_girls = total(Sex == 2 & patient_match == 0) if sibling_id != ., by(Year sibling_id)

gen patient_match_male = (patient_match == 1 & Sex == 1)
gen patient_match_female = (patient_match == 1 & Sex == 2)

keep sibling_id RecID pid Year ParID h ConParID RegDist sib_type sibsize msibsize fsibsize tot_boys tot_girls pophisclass popbyr mombyr patient_* resid_mort died Age Sex brthord mbrthord fbrthord immigrant catch_* excl_*

gen pop_wc = (pophisclass <= 5) if pophisclass != .
gen pop_sk = (pophisclass >= 6 & pophisclass <= 8) if pophisclass != .
gen pop_semisk = (pophisclass == 9) if pophisclass != .
gen pop_unsk = (pophisclass >= 10 & pophisclass <= 12) if pophisclass != .

gen popage = Year - popbyr

egen distid = group(RegDist)
egen par_id = group(ConParID)

la var sibsize "Sibship size"
la var msibsize "Number of male siblings"
la var fsibsize "Number of female siblings"
la var tot_boys "Number of male siblings"
la var tot_girls "Number of female siblings"
la var pop_sk "Father skilled"
la var pop_semisk "Father semi-skilled"
la var pop_unsk "Father unskilled"

sort Year ParID h

save "$PROJ_PATH/processed/data/table_a09_a20.dta", replace

disp "DateTime: $S_DATE $S_TIME"

* EOF