version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 06.03_single_marital_status_setup.do
* PURPOSE: This do file generates the samples for long-run marital status of men and women.
************

args gender jw_bot age_dist sim_records

*********************************************************************************************************************************************
*********************************************************************************************************************************************
// Definitively single men and women sample
*********************************************************************************************************************************************
*********************************************************************************************************************************************

// Extract HOSP to ICEM links

forvalues y = 1881(10)1901 {

	use censusyr RecID patient_id regid ///
		sex age_`y' age_dist ///
		rescty_match distpar_match nodist_match ///
		jw* similar_10 ///
		using "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`y'/unique_matches_`y'_hosp.dta", clear

	rename age_`y' age_child
	
	tempfile hosp_icem_`y'
	save `hosp_icem_`y'', replace
}

clear
forvalues y = 1881(10)1901 {
	append using `hosp_icem_`y''
}

* Apply criteria for quality of matches in final sample

keep if jw_sname >= `jw_bot' & max(jw_fname_orig,jw_fname_edit) >= `jw_bot' & similar_10 <= `sim_records' & age_dist <= `age_dist'

* Restrict to men or women

keep if sex == `gender'

* Restrict to age with no risk of marriage (<= 15)

keep if age_child <= 15						

* Merge in hospital variables

merge m:1 regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", assert(2 3) keep(3) nogen keepusing(regid ever_died pat_id_proxy admityr unassigned resid_mort byr_lb_HOSP byr_ub_HOSP)

* Restrict to patients from sample cohorts

keep if byr_ub_HOSP >= 1870 & byr_lb_HOSP <= 1890

* Drop admissions with unassigned cause of admission or missing mortality index

drop if unassigned == 1 | resid_mort == .
drop unassigned resid_mort

* Resolve matches to multiple censuses

egen temp_pat_id = group(censusyr patient_id)
drop patient_id 
rename temp_pat_id patient_id

sort pat_id_proxy patient_id regid censusyr RecID

* Drop patients who died in hospital 

drop if ever_died == 1
drop ever_died
	
* Drop admissions more than 10 years from census enumeration

gen hosp_census_gap = abs(censusyr - admityr)
tab hosp_census_gap
drop if hosp_census_gap > 10
drop hosp_census_gap

sort pat_id_proxy patient_id regid censusyr RecID
order pat_id_proxy patient_id regid censusyr RecID

* For each hospital admission, resolve links to multiple censuses

foreach patid in regid pat_id_proxy {
 
	* Choose census that is closest to admission year
	tab censusyr
	gen hosp_census_gap = abs(censusyr - admityr)
	egen min_gap = min(hosp_census_gap), by(`patid')
	drop if hosp_census_gap != min_gap
	drop min_gap hosp_census_gap
	tab censusyr
	
	* Choose best age match between hospital and childhood census
	bysort regid: gen mult_match = (_N > 1)
	egen min_age_dist = min(age_dist), by(`patid')
	drop if age_dist != min_age_dist & mult_match == 1
	drop mult_match min_age_dist
	
	* Choose earliest childhood census for each admission/patient
	egen earliest_census = min(censusyr), by(`patid')
	drop if censusyr != earliest_census
	drop earliest_census
	tab censusyr
}

sort pat_id_proxy patient_id regid censusyr RecID
save "$PROJ_PATH/processed/temp/singles_mmf_patient_id_reshape_`gender'.dta", replace

****** Recover all admissions for a given patient

* Save patient and admission IDs to file
use "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta" if sex_HOSP == `gender', clear
keep pat_id_proxy regid 
bysort pat_id_proxy regid: keep if _n == 1
save "$PROJ_PATH/processed/temp/singles_mmf_regids_`gender'.dta", replace

* Save crosswalk
use pat_id_proxy censusyr RecID using "$PROJ_PATH/processed/temp/singles_mmf_patient_id_reshape_`gender'.dta", clear
bysort pat_id_proxy censusyr RecID: keep if _n == 1
joinby pat_id_proxy using "$PROJ_PATH/processed/temp/singles_mmf_regids_`gender'.dta"
drop pat_id_proxy
duplicates drop
drop if regid == .
unique regid
sort censusyr RecID
save "$PROJ_PATH/processed/temp/singles_hosp_icem_crosswalk_inprog_`gender'.dta", replace

* Perform second pass (duplicates arise if same patient admitted multiple times, different admissions get matched to different censuses)

use "$PROJ_PATH/processed/temp/singles_mmf_patient_id_reshape_`gender'.dta", clear
drop pat_id_proxy patient_id regid admityr
duplicates drop
joinby censusyr RecID using "$PROJ_PATH/processed/temp/singles_hosp_icem_crosswalk_inprog_`gender'.dta", unmatched(both)
tab _merge
drop _merge

* Choose best age match between hospital and childhood census
bysort regid: gen mult_match = (_N > 1)
egen min_age_dist = min(age_dist), by(regid)
drop if age_dist != min_age_dist & mult_match == 1
drop mult_match min_age_dist

* Choose earliest childhood census for each admission/patient
egen earliest_census = min(censusyr), by(regid)
drop if censusyr != earliest_census
drop earliest_census
tab censusyr

* Resolve remaining multiple matches
foreach var of varlist rescty_match distpar_match nodist_match {
	egen max_`var' = max(`var'), by(regid)
	drop if `var' != max_`var'
	drop max_`var'
}
foreach var of varlist similar_10 {
	egen temp_`var' = min(`var'), by(regid)
	replace `var' = temp_`var'
	drop temp_`var'
}
foreach var of varlist jw_fname_orig-jw_fname {
	egen temp_`var' = max(`var'), by(regid)
	replace `var' = temp_`var'
	drop temp_`var'
}
foreach var of varlist jw_fname_orig-jw_fname {
	egen temp_`var' = max(`var'), by(censusyr RecID)
	replace `var' = temp_`var'
	drop temp_`var'
}
duplicates drop

/* Save year of first hospital admission for each individual */

merge m:1 regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", assert(2 3) keepusing(admityr pat_id_proxy)

gen matched = (_merge == 3)
drop _merge

gsort + pat_id_proxy - censusyr - RecID
by pat_id_proxy: carryforward censusyr RecID, replace
egen min_pid = min(pat_id_proxy), by(censusyr RecID)	
replace pat_id_proxy = min_pid if matched == 1
drop min_pid pat_id_proxy

egen yr_1st_admit = min(admityr), by(censusyr RecID)
drop admityr

keep if matched == 1
drop matched

unique regid
bysort regid: keep if _N == 1
sort censusyr RecID regid
order regid censusyr RecID 

rename RecID RecID_child

save "$PROJ_PATH/processed/intermediate/crosswalks/singles_hosp_icem_`gender'_crosswalk.dta", replace
drop regid
duplicates drop
unique censusyr RecID_child
save "$PROJ_PATH/processed/temp/singles_hosp_icem_`gender'_matched_ids.dta", replace

rm "$PROJ_PATH/processed/temp/singles_mmf_regids_`gender'.dta"
rm "$PROJ_PATH/processed/temp/singles_mmf_patient_id_reshape_`gender'.dta"
rm "$PROJ_PATH/processed/temp/singles_hosp_icem_crosswalk_inprog_`gender'.dta"



* Code that was here was moved to 06.03_single_marital_status_pre_processing.do



* Extract siblings and patients from childhood census

forvalues t_1 = 1881(10)1901 {

	use sex RecID Year sibling_id sib_type patient *brthord hhid pid flag_fix_pid age age_diff using "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`t_1'/icem_hosp_`t_1'_siblings.dta", clear
	rename Year censusyr
	rename RecID RecID_child
	rename pid pid_child
	rename flag_fix_pid flag_fix_pid_child
	
	tempfile siblings_`t_1'
	save `siblings_`t_1'', replace
}
clear
forvalues t_1 = 1881(10)1901 {
	append using `siblings_`t_1''
}

duplicates drop

* Merge in updated set of linked patients 

merge m:1 censusyr RecID_child using "$PROJ_PATH/processed/temp/singles_hosp_icem_`gender'_matched_ids.dta", keep(1 3) keepusing(censusyr RecID_child yr_1st_admit)
tab censusyr if _merge == 3

* Prioritize gender if linked to hospital records

egen tot_merge = total(_merge == 3), by(censusyr RecID_child)
drop if tot_merge > 1 & _merge != 3
drop tot_merge

* Assume gender is missing if ambiguous

egen tot_m = max(sex == 1), by(censusyr RecID_child)
egen tot_f = max(sex == 2), by(censusyr RecID_child)
tab tot_m tot_f

replace sex = . if tot_m == 1 & tot_f == 1
drop tot_m tot_f 
duplicates drop

unique censusyr RecID_child

* Update patient variable

tab patient _merge
drop patient

gen patient = (_merge == 3)
drop _merge

* Drop if siblings not identified

drop if sibling_id == .


* Identify number of children age 0-5 in household when:
*	(a) You are in infancy (age 0-2)

tempvar byr
gen `byr' = censusyr - age
sum `byr'
local min_year = r(min) - 1
local max_year = r(max) + 1

qui {
	forvalues z = 0/2 {
		tempvar tot_0to5_at_`z'
		gen `tot_0to5_at_`z'' = 0
	}
	forvalues y = `min_year'(1)`max_year' {
		tempvar tot_0to5_in_`y'
		egen `tot_0to5_in_`y'' = total(`y' - `byr' + 1 >= 0 & `y' - `byr' - 1 <= 5), by(censusyr hhid)

		replace `tot_0to5_at_0' = `tot_0to5_in_`y'' if `y' == `byr' - 1
		replace `tot_0to5_at_1' = `tot_0to5_in_`y'' if `y' == `byr' 
		replace `tot_0to5_at_2' = `tot_0to5_in_`y'' if `y' == `byr' + 1
		
		drop `tot_0to5_in_`y''
	}
}
drop `byr'

egen hh_0to5_inf = rowmax(`tot_0to5_at_0'-`tot_0to5_at_2')
replace hh_0to5_inf = 4 if hh_0to5_inf > 4 & !missing(hh_0to5_inf) // Top code at 4

forvalues z = 0/2 {
	drop `tot_0to5_at_`z''
}


* Identify number of children age 0-5 in household when:
*	(b) You are the same age as the age of the youngest patient in the year of the first admission

tempvar byr age_1st_admit hh_1st_admit ref_yr

gen `byr' = censusyr - age
sum `byr'
local min_year = r(min) - 1
local max_year = r(max) + 1

gen `age_1st_admit' = max(yr_1st_admit - `byr', 0)
replace `age_1st_admit' = 11 if `age_1st_admit' > 11
replace `age_1st_admit' = . if patient == 0

egen `hh_1st_admit' = min(`age_1st_admit'), by(censusyr hhid)

gen `ref_yr' = `byr' + `hh_1st_admit'

gen hh_0to5_hosp = 0

qui {
	forvalues y = `min_year'(1)`max_year' {
		tempvar tot_0to5_in_`y'
		egen `tot_0to5_in_`y'' = total(`y' - `byr' + 1 >= 0 & `y' - `byr' - 1 <= 5), by(censusyr hhid)

		replace hh_0to5_hosp = `tot_0to5_in_`y'' if `y' == `ref_yr'
		drop `tot_0to5_in_`y''
	}
}
replace hh_0to5_hosp = 4 if hh_0to5_hosp > 4 & !missing(hh_0to5_hosp) // Top code at 4

drop `byr' `age_1st_admit' `hh_1st_admit' `ref_yr'
drop yr_1st_admit


rename age age_child

* Generate birth order/number of siblings variable

egen max_brthord = max(brthord), by(censusyr sibling_id)
keep if max_brthord <= 13
drop max_brthord

* Restrict to patients and siblings no older than age 15

keep if age_child <= 15

* Restrict to households with patients

egen tot_pat = total(patient == 1), by(censusyr sibling_id)
drop if tot_pat == 0
drop tot_pat

* Create new sibling ID

rename sibling_id sibid_orig
egen sibling_id = group(censusyr sibid_orig)

* Restrict to males or females

keep if sex == `gender'

drop fbrthord mbrthord

* Restrict remaining sibling size

bysort sibling_id: gen sib_size = _N if sibling_id != .
recode sib_size (mis = 0)
tab sib_size
keep if sib_size <= 11

* Drop twins
gen twins = (patient == 0 & age_diff == 0)
tab twins
drop if twins == 1
drop twins

* Final sample of patients and siblings

local samp_pat "samp_pat = max(patient == 1), by(sibling_id)"
local samp_sib "samp_sib = max(patient == 0), by(sibling_id)"

gen flag_extra_sibpat = 0

preserve
	
	keep if patient == 1
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

* Restrict to siblings within 5 years

keep if age_diff <= 5

egen `samp_pat'
egen `samp_sib'

keep if samp_pat == 1 & samp_sib == 1

* Drop households with multiple patients

egen mult_pat_hh = total(patient == 1 & samp_pat == 1), by(sibling_id)
tab mult_pat_hh
	
preserve
	
	keep if mult_pat_hh > 1
	replace mult_pat_hh = 1 if mult_pat_hh > 1
	
	* Define variable for older sibling of each patient and healthy sibling pair

	egen first_sib = min(brthord), by(sibling_id)
	gen older_sib = (brthord == first_sib)
	drop first_sib

	tempfile mult_pat_hh
	save `mult_pat_hh', replace
	
restore
		
drop if mult_pat_hh > 1
drop mult_pat_hh samp_pat samp_sib

egen `samp_pat'
egen `samp_sib'	

keep if samp_pat == 1 & samp_sib == 1

* Drop sibling if not closest in age to patient

egen closest_sib = min(age_diff) if patient == 0, by(sibling_id)

preserve
	
	keep if age_diff != closest_sib & patient == 0
	gen extra_sibs = 1
	
	tempfile extra_sibs
	save `extra_sibs', replace
	
restore

drop if age_diff != closest_sib & patient == 0

drop closest_sib samp_pat samp_sib

egen `samp_pat'
egen `samp_sib'	

keep if samp_pat == 1 & samp_sib == 1

* Keep older sibling if patient's RecID is even; younger if odd

tempvar tot_sibs hh_with_2plus_sibs odd_id tot_oddpats oldest

egen `tot_sibs' = total(patient == 0 & samp_pat == 1 & samp_sib == 1), by(sibling_id)
gen `hh_with_2plus_sibs' = (`tot_sibs' > 1)

gen `odd_id' = mod(RecID_child,2)
egen `tot_oddpats' = total(patient == 1 & `odd_id' == 1), by(sibling_id)

egen `oldest' = min(brthord) if patient == 0 & samp_pat == 1 & samp_sib == 1, by(sibling_id)

preserve
	
	keep if (`hh_with_2plus_sibs' == 1 & patient == 0 & `tot_oddpats' > 0 & brthord == `oldest') | (`hh_with_2plus_sibs' == 1 & patient == 0 & `tot_oddpats' == 0 & brthord != `oldest')
	drop `tot_sibs' `hh_with_2plus_sibs' `odd_id' `tot_oddpats' `oldest'
	gen extra_sibs = 1
	
	tempfile extra_sib_ties
	save `extra_sib_ties', replace
	
restore

drop if `hh_with_2plus_sibs' == 1 & patient == 0 & `tot_oddpats' > 0 & brthord == `oldest' // In households with > 1 siibling, drop younger sibling if patient's RecID is odd
drop if `hh_with_2plus_sibs' == 1 & patient == 0 & `tot_oddpats' == 0 & brthord != `oldest' // In households with > 1 siibling, drop older sibling if patient's RecID is even

drop `tot_sibs' `hh_with_2plus_sibs' `odd_id' `tot_oddpats' `oldest'

* Restrict to households with one patient and one sibling

drop samp_pat samp_sib

egen `samp_pat'
egen `samp_sib'	

keep if samp_pat == 1 & samp_sib == 1

tab samp_pat samp_sib
drop samp_pat samp_sib

tab patient

* Define variable for older sibling of each patient and healthy sibling pair

egen first_sib = min(brthord), by(sibling_id)
gen older_sib = (brthord == first_sib)
drop first_sib

* Restrict to households with 1 siblings and 1 patient
bysort sibling_id: keep if _N == 2

* Add back multiple patient households and extra siblings for robustness

gen main_marital_sample = 1

append using `mult_pat_hh'
append using `extra_sibs'
append using `extra_sib_ties'

recode main_marital_sample mult_pat_hh extra_sibs (mis = 0)

if `gender' == 1 {
	
	merge 1:1 censusyr RecID_child using "$PROJ_PATH/processed/temp/singles_`gender'_double_links.dta", keep(1 3) keepusing(censusyr RecID_child link_* single_* married_* jw_fname_exact_* jw_sname_exact_* flag_rbp_child_* flag_rbp_adult_* bpar_mismatch_*) nogen
	recode link_* single_* married_* jw_fname_exact_* jw_sname_exact_* flag_rbp_child_* flag_rbp_adult_* bpar_mismatch_* (mis = 0)

}
else if `gender' == 2 {

	merge 1:1 censusyr RecID_child using "$PROJ_PATH/processed/temp/singles_`gender'_double_links.dta", keep(1 3) keepusing(censusyr RecID_child link_*) nogen
	recode link_* (mis = 0)
	
}

xtset sibling_id

forvalues y = 10(10)30 {

	if `gender' == 1 {
		tab single_`y'
		tab married_`y'
		tab link_`y'
		
		tab single_`y' patient, col
	}
	else if `gender' == 2 {
		tab link_`y' patient, col
	}
	
	gen age_`y' = age_child + `y'	
	gen min_age_`y' = 8*(`y' == 10)
}

* Add name frequency

merge 1:1 censusyr RecID_child using "$PROJ_PATH/processed/intermediate/names/icem_name_analysis.dta", assert(2 3) keep(3) nogen keepusing(std_fnamefreq interact_namefreq)

* Add HOSP-ICEM matching variables

merge 1:1 censusyr RecID_child using "$PROJ_PATH/processed/temp/singles_hosp_icem_`gender'_matched_ids.dta", keep(1 3) keepusing(rescty_match distpar_match nodist_match)
tab patient _merge 
recode rescty_match distpar_match nodist_match (mis = 1)
drop _merge

* Create patient ID

egen patient_id = group(censusyr RecID_child)

compress
desc, f
save "$PROJ_PATH/processed/temp/singles_icem_hosp_`gender'_analysis_variables.dta", replace

* Prepare hospital variables

use censusyr RecID_child patient patient_id using "$PROJ_PATH/processed/temp/singles_icem_hosp_`gender'_analysis_variables.dta", clear

keep if patient == 1
drop patient

merge 1:m censusyr RecID_child using "$PROJ_PATH/processed/intermediate/crosswalks/singles_hosp_icem_`gender'_crosswalk.dta", assert(2 3) keep(3) nogen keepusing(regid)
bysort censusyr RecID_child: gen tot_visits = _N
drop censusyr RecID_child
merge m:1 regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", assert(2 3) keep(3) nogen keepusing(resid_mort admitage contagious hospid)
sort patient_id regid
drop regid

forvalues age = 0(1)11 {
	gen admitage`age' = (admitage == `age')
}
gen hosp_guys = (hospid == 5)

drop admitage hospid

foreach var of varlist admitage0-admitage11 contagious hosp_guys {
	qui recode `var' (0.5 = 1) (mis = 0)
	egen temp_`var' = max(`var'), by(patient_id)
	replace `var' = temp_`var' if `var' != temp_`var'
	drop temp_`var'
}
foreach var of varlist resid_mort tot_visits {
	egen temp_`var' = max(`var'), by(patient_id)
	replace `var' = temp_`var' if `var' != temp_`var'
	drop temp_`var'
}

duplicates drop
unique patient_id
save "$PROJ_PATH/processed/temp/singles_hosp_patient_`gender'_variables.dta", replace

use "$PROJ_PATH/processed/temp/singles_icem_hosp_`gender'_analysis_variables.dta", clear
merge 1:1 patient_id using "$PROJ_PATH/processed/temp/singles_hosp_patient_`gender'_variables.dta", assert(1 3)
tab patient _merge
drop _merge
qui recode resid_mort contagious admitage0 admitage1 hosp_guys (mis = 0) if patient == 0

la var patient "Patient"
la var resid_mort "Health deficiency index"

* Restriction on number of visits

egen hh_too_many_visits = max(patient == 1 & tot_visits > 9), by(sibling_id)
drop if hh_too_many_visits == 1
drop hh_too_many_visits

* Define new variables for regressions
gen byr_child = censusyr - age_child

if `gender' == 1 {

	gen single = (single_10 == 1 | single_20 == 1 | single_30 == 1)
	
	* Define controls for linked sample only
	
	foreach v in jw_fname_exact jw_sname_exact flag_rbp_child flag_rbp_adult bpar_mismatch {

		egen `v' = rowmax(`v'_*)
	
	}
	
}
else if `gender' == 2 {

	gen single = (link_10 == 1 | link_20 == 1 | link_30 == 1)
	
}

xtset sibling_id
sort censusyr RecID_child
desc, f

* Save data set for main sample used in Table 3

if `age_dist' == 3 & `jw_bot' == 0.80 & `sim_records' == 20 {

	save "$PROJ_PATH/processed/temp/table_03_singles_analysis_data_`gender'.dta", replace
	
	preserve 
	
		* Remove restricted variables for public version
		drop RecID_child sibid_orig hhid pid_child
		save "$PROJ_PATH/processed/data/table_03_singles_analysis_data_`gender'.dta", replace
	
	restore
}

* Drop restricted variables
drop RecID_child sibid_orig hhid pid_child

* Save data sets used in creating robustness figures
local jw100 = `jw_bot'*100
save "$PROJ_PATH/processed/data/figure_a14_singles_`gender'_age_`age_dist'_jw_`jw100'_sim_`sim_records'.dta", replace


rm "$PROJ_PATH/processed/temp/singles_hosp_icem_`gender'_matched_ids.dta"
rm "$PROJ_PATH/processed/temp/singles_hosp_patient_`gender'_variables.dta"
rm "$PROJ_PATH/processed/temp/singles_icem_hosp_`gender'_analysis_variables.dta"

disp "DateTime: $S_DATE $S_TIME"

* EOF
