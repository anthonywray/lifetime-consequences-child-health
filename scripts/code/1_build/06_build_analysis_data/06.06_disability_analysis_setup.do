version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 06.06_disability_analysis_setup.do
* PURPOSE: This do file merges all HOSP-to-I-CeM and I-CeM-to-I-CeM linked data for the analysis of childhood disability outcomes
************

*********************************************************************************************************************
*********** ICEM HOSP Disability Merge Matched Files *************
*********************************************************************************************************************

/* Extract census records matched to hospital patients from ICEM-ICEM linked files */
	
forvalues y = 1881(10)1911 {
	use "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`y'/unique_matches_`y'_hosp.dta", clear
	merge 1:1 regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", keep(3) nogen keepusing(regid admitdate)
	if `y' == 1881 gen census_date = mdy(4,3,1881)
	if `y' == 1891 gen census_date = mdy(4,5,1891)
	if `y' == 1901 gen census_date = mdy(4,1,1901)
	if `y' == 1911 gen census_date = mdy(4,2,1911)
	format census_date %td
	keep if admitdate < census_date
	keeporder censusyr RecID sex
	bysort censusyr RecID sex: keep if _n == 1
	order censusyr RecID
	save "$PROJ_PATH/processed/temp/disability_hosp_icem_matches_`y'.dta", replace
}
clear
forvalues y = 1881(10)1911 {
	append using "$PROJ_PATH/processed/temp/disability_hosp_icem_matches_`y'.dta"
}
sort censusyr RecID sex
save "$PROJ_PATH/processed/temp/disability_hosp_icem_matches_`y'.dta", replace

clear
forvalues y = 1881(10)1911 {
	append using "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`y'/unique_matches_`y'_hosp.dta"
}
gen age_ICEM = .
replace age_ICEM = age_1881 if age_1881 != .
replace age_ICEM = age_1891 if age_1891 != . & age_ICEM == .
replace age_ICEM = age_1901 if age_1901 != . & age_ICEM == .
replace age_ICEM = age_1911 if age_1911 != . & age_ICEM == .
keep censusyr RecID patient_id regid sex age_ICEM age_dist rescty_match jw* similar* mi_mismatch distpar_match nodist_match
drop jw_fname
capture drop similar_2 similar_20
merge m:1 censusyr RecID sex using "$PROJ_PATH/processed/temp/disability_hosp_icem_matches_`y'.dta", assert(1 3) keep(3) nogen
merge m:1 regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", keep(3) nogen keepusing(died pat_id_proxy admityr admitdate)

egen temp_pat_id = group(censusyr patient_id)
drop patient_id 
rename temp_pat_id patient_id

order pat_id_proxy patient_id regid censusyr RecID sex age_ICEM age_dist mi_mismatch*
order jw* similar*, last
sort pat_id_proxy patient_id regid censusyr RecID
save "$PROJ_PATH/processed/intermediate/crosswalks/disability_hosp_icem_links_combined.dta", replace

***************** Resolve matches to multiple censuses *************************

use "$PROJ_PATH/processed/intermediate/crosswalks/disability_hosp_icem_links_combined.dta", clear

* Drop patients who died in hospital before census date
gen census_date = .
replace census_date = mdy(4,3,1881) if censusyr == 1881
replace census_date = mdy(4,5,1891) if censusyr == 1891
replace census_date = mdy(4,1,1901) if censusyr == 1901
replace census_date = mdy(4,2,1911) if censusyr == 1911
format census_date %td

egen tot_died = total(died == 1 & admitdate < census_date), by(pat_id_proxy censusyr)	
drop if tot_died == 1
drop tot_died admitdate census_date
	
* Drop admissions more than 10 years from census enumeration
gen hosp_census_gap = abs(censusyr - admityr)
tab hosp_census_gap
drop if hosp_census_gap > 10
drop hosp_census_gap

/* 	For each hospital admission, prioritize matches if linked to multiple censuses. 
	Repeat for each patient ID */
	
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

	* Choose latest childhood census for each admission/patient
	egen latest_census = max(censusyr), by(`patid')
	drop if censusyr != latest_census
	drop latest_census
	tab censusyr
}
sort pat_id_proxy patient_id regid censusyr RecID
save "$PROJ_PATH/processed/temp/disability_mmf_patient_id_reshape.dta", replace

****** Recover all admissions for a given patient

* Save patient and admission IDs to file
use pat_id_proxy regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear
bysort pat_id_proxy regid: keep if _n == 1
save "$PROJ_PATH/processed/temp/disability_mmf_regids.dta", replace

* Save crosswalk
use pat_id_proxy censusyr RecID using "$PROJ_PATH/processed/temp/disability_mmf_patient_id_reshape.dta", clear
bysort pat_id_proxy censusyr RecID: keep if _n == 1
joinby pat_id_proxy using "$PROJ_PATH/processed/temp/disability_mmf_regids.dta"
drop pat_id_proxy
duplicates drop
drop if regid == .
unique regid
sort censusyr RecID
save "$PROJ_PATH/processed/temp/disability_hosp_icem_crosswalk_inprog.dta", replace

* Perform second pass (duplicates arise if same patient admitted multiple times, different admissions get matched to different censuses)
use "$PROJ_PATH/processed/temp/disability_mmf_patient_id_reshape.dta", clear
drop pat_id_proxy patient_id regid admityr
duplicates drop
joinby censusyr RecID using "$PROJ_PATH/processed/temp/disability_hosp_icem_crosswalk_inprog.dta", unmatched(both)
tab _merge
drop _merge

* Drop remaining individuals who died
egen tot_died = total(died == 1), by(regid)
drop if tot_died > 0
drop tot_died died

* Choose best age match between hospital and childhood census
bysort regid: gen mult_match = (_N > 1)
egen min_age_dist = min(age_dist), by(regid)
drop if age_dist != min_age_dist & mult_match == 1
drop mult_match min_age_dist

* Choose latest childhood census for each admission/patient
egen latest_census = max(censusyr), by(regid)
drop if censusyr != latest_census
drop latest_census
tab censusyr

* Resolve remaining multiple matches
foreach var of varlist rescty_match distpar_match nodist_match {
	egen max_`var' = max(`var'), by(regid)
	drop if `var' != max_`var'
	drop max_`var'
}

foreach var of varlist mi_mismatch {
	egen min_`var' = min(`var'), by(regid)
	drop if `var' != min_`var'
	drop min_`var'
}

foreach var of varlist similar_0-similar_15 {
	egen temp_`var' = min(`var'), by(regid)
	replace `var' = temp_`var'
	drop temp_`var'
}	
foreach var of varlist jw_fname_orig-jw_name {
	egen temp_`var' = max(`var'), by(regid)
	replace `var' = temp_`var'
	drop temp_`var'
}
foreach var of varlist jw_fname_orig-jw_name {
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
save "$PROJ_PATH/processed/intermediate/crosswalks/disability_hosp_icem_crosswalk.dta", replace
drop regid
duplicates drop
unique censusyr RecID
save "$PROJ_PATH/processed/temp/disability_hosp_icem_matched_ids.dta", replace

* Remove files
forvalues y = 1881(10)1911 {
	rm "$PROJ_PATH/processed/temp/disability_hosp_icem_matches_`y'.dta"
}
rm "$PROJ_PATH/processed/temp/disability_hosp_icem_matches_`y'.dta"

rm "$PROJ_PATH/processed/temp/disability_mmf_regids.dta"
rm "$PROJ_PATH/processed/temp/disability_mmf_patient_id_reshape.dta"
rm "$PROJ_PATH/processed/temp/disability_hosp_icem_crosswalk_inprog.dta"

*********************************************************************************************************************
*********** ICEM HOSP Disability Analysis Input *************
*********************************************************************************************************************

forvalues t_1 = 1881(10)1911 {
	
	* Merge with variables needed for analysis
	use sex RecID Year sibling_id sib_type patient *brthord hhid pid age age_diff using "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`t_1'/icem_hosp_`t_1'_siblings.dta", clear
	rename Year censusyr
	
	egen group_id = group(censusyr RecID)
	egen obs_id = seq(), by(censusyr RecID)
	reshape wide sex, i(group_id) j(obs_id)
	capture replace sex1 = . if sex2 != .
	capture drop sex2 
	drop group_id
	rename sex1 sex
	
	merge 1:1 censusyr RecID using "$PROJ_PATH/processed/temp/disability_hosp_icem_matched_ids.dta", keep(1 3) keepusing(censusyr RecID yr_1st_admit)
	tab patient _merge
	replace patient = 0 if _merge == 1
	drop _merge
	egen tot_pat = total(patient == 1), by(censusyr hhid)
	drop if tot_pat == 0
	drop tot_pat
	
	* Identify number of other children age 0-5 in household when:
	*	(a) You are in infancy (age 0-2)

	qui {
		tempvar byr
		gen `byr' = censusyr - age
		sum `byr'
		local min_year = r(min) - 1
		local max_year = r(max) + 1

		forvalues z = 0/2 {
			tempvar tot_0to5_at_`z'
			gen `tot_0to5_at_`z'' = 0
		}
		forvalues y = `min_year'(1)`max_year' {
			tempvar tot_0to5_in_`y'
			egen `tot_0to5_in_`y'' = total(`y' - `byr' + 1 >= 0 & `y' - `byr' - 1 <= 5), by(censusyr hhid)

			qui replace `tot_0to5_at_0' = `tot_0to5_in_`y'' if `y' == `byr' - 1
			qui replace `tot_0to5_at_1' = `tot_0to5_in_`y'' if `y' == `byr' 
			qui replace `tot_0to5_at_2' = `tot_0to5_in_`y'' if `y' == `byr' + 1
			
			drop `tot_0to5_in_`y''
		}
		drop `byr'

		egen hh_0to5_inf = rowmax(`tot_0to5_at_0'-`tot_0to5_at_2')
		replace hh_0to5_inf = 4 if hh_0to5_inf > 4 & !missing(hh_0to5_inf) // Top code at 4

		forvalues z = 0/2 {
			drop `tot_0to5_at_`z''
		}

		* Identify number of other children age 0-5 in household when:
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

		forvalues y = `min_year'(1)`max_year' {
			tempvar tot_0to5_in_`y'
			egen `tot_0to5_in_`y'' = total(`y' - `byr' + 1 >= 0 & `y' - `byr' - 1 <= 5), by(censusyr hhid)

			replace hh_0to5_hosp = `tot_0to5_in_`y'' if `y' == `ref_yr'
			drop `tot_0to5_in_`y''
		}
		replace hh_0to5_hosp = 4 if hh_0to5_hosp > 4 & !missing(hh_0to5_hosp)

		drop `byr' `age_1st_admit' `hh_1st_admit' `ref_yr'
		drop yr_1st_admit age
	}

	rename censusyr Year
	merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`t_1'_demographic.dta", assert(2 3) keep(3) nogen keepusing(Age)
	merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`t_1'_residence.dta", assert(2 3) keep(3) nogen keepusing(RegCnty)
	merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`t_1'_disability.dta", assert(2 3) keep(3) nogen keepusing(disab_any)

	rename Age age_child
	
	replace disab_any = disab_any*100
	
	***** Changes to ICEM county names:

	replace RegCnty = "Kent" if RegCnty == "Kent (Extra London)"
	replace RegCnty = "London" if RegCnty == "London (Parts Of Middlesex, Surrey & Kent)"
	replace RegCnty = "Middlesex" if RegCnty == "Middlesex (Extra London)"
	replace RegCnty = "Surrey" if RegCnty == "Surrey (Extra London)"
	replace RegCnty = "Yorkshire" if regexm(RegCnty,"Yorkshire")
	replace RegCnty = upper(RegCnty)
	rename RegCnty county_child

	rename Year censusyr
	
	tempfile ICEM_Disability_`t_1'
	save `ICEM_Disability_`t_1'', replace
}

clear
forvalues t_1 = 1881(10)1911 {
	append using `ICEM_Disability_`t_1''
}
duplicates drop

save "$PROJ_PATH/processed/temp/disability_hosp_icem_analysis_input.dta", replace

*********************************************************************************************************************
*********** ICEM HOSP Analysis Setup *************
*********************************************************************************************************************

use "$PROJ_PATH/processed/temp/disability_hosp_icem_analysis_input.dta", clear

* Restrict to final HOSP-ICEM-ICEM matched sample
merge m:1 censusyr RecID sex using "$PROJ_PATH/processed/temp/disability_hosp_icem_matched_ids.dta", assert(1 3) keep(1 3) keepusing(censusyr RecID sex)
order censusyr RecID patient sex 
tab patient _merge

* Restrict to siblings within 8 years
keep if age_diff <= 8

* Keep households with matched patients
gen matched_patient = (_merge == 3)
drop _merge 

egen tot_pat = total(matched_patient == 1), by(censusyr hhid)
drop if tot_pat == 0
drop tot_pat 

drop if patient == 1 & matched_patient == 0
drop patient
rename matched_patient patient

* Restrict to children age 0-21
keep if age_child <= 21

* Create new sibling ID
rename sibling_id sibid_orig
egen sibling_id = group(censusyr sibid_orig)
drop sibid_orig

egen max_brthord = max(brthord), by(sibling_id)
bysort sibling_id: gen sib_size = _N if sibling_id != .
recode sib_size (mis = 0)
tab sib_size

* Create regression variables

* Age variables:
gen byr_child = censusyr - age_child
gen patins = ((byr_child >= 1870 & byr_child<= 1890 & patient == 1) | patient == 0)
	
* Geography variables
gen pat_gl = ((county_child == "LONDON" | county_child == "MIDDLESEX" | county_child == "KENT" | county_child == "ESSEX" | county_child == "SURREY") & patient == 1)
egen hh_gl = max(pat_gl), by(sibling_id)
gen greater_london = (hh_gl == 1)
drop pat_gl hh_gl

* Generate sample restrictions
gen military = (county_child == "MILITARY" | county_child == "ROYAL NAVY")
tab military
drop county_child

gen twins = (patient == 0 & age_diff == 0)
tab twins

gen valid_age = (age_child >= 0 & age_child <= 21) 
tab valid_age

tab greater_london, missing
tab patins, missing
tab age_diff, missing

* Add HOSP-ICEM matching variables
merge 1:1 censusyr RecID using "$PROJ_PATH/processed/temp/disability_hosp_icem_matched_ids.dta", keep(1 3) keepusing(age_dist mi_mismatch rescty_match distpar_match nodist_match jw_fname_orig-jw_name similar_0-similar_15) 
tab patient _merge
recode age_dist mi_mismatch similar_0-similar_15 (mis = 0)
recode rescty_match distpar_match nodist_match jw_fname_orig-jw_name (mis = 1)
drop _merge

gen jw_fname_exact = (jw_fname_orig == 1 | jw_fname_edit == 1)
gen jw_sname_exact = (jw_sname == 1)

egen patient_id = group(censusyr RecID)
order censusyr hhid sibling_id sib_type pid RecID patient sex age_child age_dist* age_diff mi_mismatch*
order jw* similar*, last
sort censusyr hhid pid

save "$PROJ_PATH/processed/temp/disability_hosp_icem_analysis_variables.dta", replace

* Create patient specific variables
use censusyr RecID patient patient_id using "$PROJ_PATH/processed/temp/disability_hosp_icem_analysis_variables.dta" if patient == 1, clear
drop patient
merge 1:m censusyr RecID using "$PROJ_PATH/processed/intermediate/crosswalks/disability_hosp_icem_crosswalk.dta", assert(2 3) keep(3) nogen keepusing(regid)
bysort censusyr RecID: gen tot_visits = _N
drop censusyr RecID
merge 1:1 regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", assert(2 3) keep(3) nogen keepusing(hospid admitage admityr admitmon admitdate los acute-doctor diphth-policy_diseases)
sort patient_id regid

forvalues age = 0(1)11 {
	gen admitage`age' = (admitage == `age')
}
gen admit0to11 = (admitage <= 11)

gen hosp_barts = (hospid == 1)
gen hosp_gosh = (hospid == 2)
gen hosp_guys = (hospid == 5)

egen max_los = max(los), by(patient_id)
egen min_los = min(los), by(patient_id)

drop regid admityr admitage admitdate hospid admitmon los
foreach var of varlist acute-unclass doctor-policy_diseases admitage0-min_los {
	qui recode `var' (0.5 = 1) (mis = 0)
	qui egen temp_`var' = max(`var'), by(patient_id)
	qui replace `var' = temp_`var' if `var' != temp_`var'
	qui drop temp_`var'

}
foreach var of varlist resid_mort comorbid-transfer {
	qui egen temp_`var' = max(`var'), by(patient_id)
	qui replace `var' = temp_`var' if `var' != temp_`var'
	qui drop temp_`var'
}
duplicates drop
order acute-unclass doctor-min_los resid_mort comorbid-transfer, last
unique patient_id
gen valid_admitage = (admit0to11 == 1)
save "$PROJ_PATH/processed/temp/disability_hosp_analysis_variables.dta", replace

use "$PROJ_PATH/processed/temp/disability_hosp_icem_analysis_variables.dta", clear
merge 1:1 patient_id using "$PROJ_PATH/processed/temp/disability_hosp_analysis_variables.dta", assert(1 3)
tab patient _merge
drop _merge
qui recode acute-min_los (mis = 0)
qui recode resid_mort comorbid-transfer tot_visits (mis = 0) if patient == 0
qui recode valid_admitage (mis = 1) if patient == 0

la var patient "Patient"
la var resid_mort "Health deficiency index"
la var acute "Acute"
la var doctor "Doctor"

rename RecID RecID_child
sort censusyr RecID_child
merge 1:1 censusyr RecID_child using "$PROJ_PATH/processed/intermediate/names/icem_name_analysis.dta", assert(2 3) keep(3) nogen keepusing(std_fnamefreq interact_namefreq)
rename RecID_child RecID

sort censusyr hhid pid
save "$PROJ_PATH/processed/intermediate/final_build/disability_analysis_setup.dta", replace

rm "$PROJ_PATH/processed/temp/disability_hosp_icem_analysis_variables.dta"
rm "$PROJ_PATH/processed/temp/disability_hosp_icem_matched_ids.dta"
rm "$PROJ_PATH/processed/temp/disability_hosp_icem_analysis_input.dta"
rm "$PROJ_PATH/processed/temp/disability_hosp_analysis_variables.dta"

disp "DateTime: $S_DATE $S_TIME"

* EOF
