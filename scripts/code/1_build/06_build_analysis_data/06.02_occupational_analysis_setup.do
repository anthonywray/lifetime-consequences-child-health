version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 06.02_occupational_analysis_setup.do
* PURPOSE: This do file merges all HOSP-to-I-CeM and I-CeM-to-I-CeM linked data
************

*********************************************************************************************************************
*********** ICEM HOSP Merge Matched Files *************
*********************************************************************************************************************

// Extract census records matched to hospital patients from ICEM-ICEM linked files
forvalues t_2 = 1901(10)1911 {
	if `t_2' == 1901 {
		local t_max = 1891
	}
	else {
		local t_max = 1901
	}
	forvalues t_1 = 1881(10)`t_max' {
		use "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`t_1'/unique_matches_`t_1'_hosp.dta", clear
		merge 1:1 regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", keep(3) nogen keepusing(regid)
		keeporder censusyr RecID sex
		bysort censusyr RecID sex: keep if _n == 1
		rename RecID RecID_child
		merge 1:1 RecID_child sex using "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/unique_matches_`t_1'_`t_2'.dta", keep(3) nogen keepusing(RecID* age_child age_adult age_dist bparish_match flag_recode_bpl* bpar_mismatch mi_mismatch jw* similar*)
		gen outcomeyr = `t_2'
		order censusyr RecID_child outcomeyr RecID_adult
		rename flag_recode_bpl_`t_1' flag_rbp_child
		rename flag_recode_bpl_`t_2' flag_rbp_adult
		foreach var of varlist age_dist mi_mismatch jw* similar* {
			rename `var' `var'_ICEM
		}
		save "$PROJ_PATH/processed/temp/hosp_icem_matches_`t_1'_`t_2'.dta", replace
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
		append using "$PROJ_PATH/processed/temp/hosp_icem_matches_`t_1'_`t_2'.dta"
	}
}
gunique censusyr RecID_child sex outcomeyr RecID_adult
gsort censusyr RecID_child sex outcomeyr RecID_adult
save "$PROJ_PATH/processed/temp/hosp_icem_matches.dta", replace

clear
forvalues t_1 = 1881(10)1901 {
	append using "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`t_1'/unique_matches_`t_1'_hosp.dta"
}
keep censusyr RecID patient_id regid sex age_dist rescty_match jw* similar* mi_mismatch distpar_match nodist_match
drop jw_fname
capture drop similar_2 similar_20
rename RecID RecID_child
joinby censusyr RecID_child sex using "$PROJ_PATH/processed/temp/hosp_icem_matches.dta"

merge m:1 regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", keep(3) nogen keepusing(ever_died pat_id_proxy admityr bdate*)

egen temp_pat_id = group(censusyr patient_id)
drop patient_id 
rename temp_pat_id patient_id

rename age_dist age_dist_child
rename age_dist_ICEM age_dist_adult

order pat_id_proxy patient_id regid censusyr RecID_child outcomeyr RecID_adult sex age_child age_adult age_dist_child age_dist_adult mi_mismatch*
order jw* similar*, last
sort pat_id_proxy patient_id regid censusyr RecID_child outcomeyr RecID_adult
save "$PROJ_PATH/processed/intermediate/crosswalks/occupational_hosp_icem_links.dta", replace



// Resolve matches to multiple censuses 
use "$PROJ_PATH/processed/intermediate/crosswalks/occupational_hosp_icem_links.dta", clear

// Drop patients who died in hospital
drop if ever_died == 1
drop ever_died

// Drop patients/admissions with difference in age from outcome census greater than 3
gen age_lb_HOSP = .
gen age_ub_HOSP = .

replace age_lb_HOSP = floor((mdy(3,31,1901) - bdate_ub_HOSP)/365.25) if outcomeyr == 1901
replace age_ub_HOSP = floor((mdy(3,31,1901) - bdate_lb_HOSP)/365.25) if outcomeyr == 1901
replace age_lb_HOSP = floor((mdy(4,2,1911) - bdate_ub_HOSP)/365.25) if outcomeyr == 1911
replace age_ub_HOSP = floor((mdy(4,2,1911) - bdate_lb_HOSP)/365.25) if outcomeyr == 1911

gen age_dist_HOSP = min(abs(age_lb_HOSP - age_adult), abs(age_ub_HOSP - age_adult))
tab age_dist_HOSP
drop if age_dist_HOSP > 5
drop bdate_*HOSP age*HOSP age_dist_HOSP
	
// Drop admissions more than 10 years from census enumeration
gen hosp_census_gap = abs(censusyr - admityr)
tab hosp_census_gap
drop if hosp_census_gap > 10
drop hosp_census_gap

* Reassign patient IDs if matched to same outcome census record
egen recode_pat_id = min(pat_id_proxy), by(outcomeyr RecID_adult)
tempfile recode_patid_input_combined recode_patid_output_combined
save `recode_patid_input_combined', replace
keep pat_id_proxy recode_pat_id
bysort pat_id_proxy recode_pat_id: keep if _n == 1
save `recode_patid_output_combined', replace

use `recode_patid_input_combined', clear
replace pat_id_proxy = recode_pat_id
drop recode_pat_id

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
	bysort `patid': gen mult_match = (_N > 1)
	egen min_age_dist = min(age_dist_child), by(`patid')
	drop if age_dist_child != min_age_dist & mult_match == 1
	drop mult_match min_age_dist

	* Identify admissions/patients with matches to multiple outcome year observations
	bysort `patid': gen mult_match = (_N > 1)
	qui unique outcomeyr RecID_adult, by(`patid') gen(tot_match)
	gsort + `patid' - tot_match
	by `patid': carryforward tot_match, replace
	
	* Choose if birth parish matches between childhood and adult census
		egen max_bpl_match = max(bparish_match), by(`patid')
		drop if bparish_match != max_bpl_match & mult_match == 1 & tot_match > 1 
		drop mult_match max_bpl_match tot_match

	* Identify admissions/patients with matches to multiple outcome year observations
	bysort `patid': gen mult_match = (_N > 1)
	qui unique outcomeyr RecID_adult, by(`patid') gen(tot_match)
	gsort + `patid' - tot_match
	by `patid': carryforward tot_match, replace

	* Choose if no birth parish mismatch between childhood and adult census
		egen min_bpl_match = min(bpar_mismatch), by(`patid')
		drop if bpar_mismatch != min_bpl_match & mult_match == 1 & tot_match > 1 
		drop mult_match min_bpl_match tot_match

	* Identify admissions/patients with matches to multiple outcome year observations
	bysort `patid': gen mult_match = (_N > 1)
	qui unique outcomeyr RecID_adult, by(`patid') gen(tot_match)
	gsort + `patid' - tot_match
	by `patid': carryforward tot_match, replace
	
		* Choose best age match between childhood and adult census
		egen min_age_dist = min(age_dist_adult), by(`patid')
		drop if age_dist_adult != min_age_dist & mult_match == 1 & tot_match > 1 
		drop mult_match min_age_dist tot_match
		
	* Choose latest outcome census for each admission/patient
	egen latest_census = max(outcomeyr), by(`patid')
	drop if outcomeyr != latest_census
	drop latest_census
	
	* Choose earliest childhood census for each admission/patient
	egen earliest_census = min(censusyr), by(`patid')
	drop if censusyr != earliest_census
	drop earliest_census
	tab censusyr
}
sort pat_id_proxy patient_id regid censusyr RecID_child outcomeyr RecID_adult
save "$PROJ_PATH/processed/temp/mmf_patient_id_reshape_combined.dta", replace

****** Recover all admissions for a given patient

* Save patient and admission IDs to file
use pat_id_proxy regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear
joinby pat_id_proxy using `recode_patid_output_combined', unmatched(both)
tab _merge
drop if _merge == 2
replace pat_id_proxy = recode_pat_id if recode_pat_id != . & pat_id_proxy != recode_pat_id
drop recode_pat_id _merge

bysort pat_id_proxy regid: keep if _n == 1
save "$PROJ_PATH/processed/temp/mmf_regids_combined.dta", replace

* Reshape admission IDs wide
use outcomeyr RecID_adult pat_id_proxy using "$PROJ_PATH/processed/temp/mmf_patient_id_reshape_combined.dta", clear
bysort outcomeyr RecID_adult pat_id_proxy: keep if _n == 1
joinby pat_id_proxy using "$PROJ_PATH/processed/temp/mmf_regids_combined.dta"
drop pat_id_proxy
bysort outcomeyr RecID_adult regid: keep if _n == 1
egen temp_id = group(outcomeyr RecID_adult)
egen obs_id = seq(), by(outcomeyr RecID_adult)
reshape wide regid, i(temp_id) j(obs_id)
keep outcomeyr RecID_adult regid*
save "$PROJ_PATH/processed/temp/mmf_regids_wide_combined.dta", replace

* Save crosswalk
use pat_id_proxy censusyr RecID_child outcomeyr RecID_adult using "$PROJ_PATH/processed/temp/mmf_patient_id_reshape_combined.dta", clear
bysort pat_id_proxy censusyr RecID_child outcomeyr RecID_adult: keep if _n == 1
joinby pat_id_proxy using "$PROJ_PATH/processed/temp/mmf_regids_combined.dta"
drop pat_id_proxy
duplicates drop
drop if regid == .
unique regid
sort censusyr RecID_child outcomeyr RecID_adult
save "$PROJ_PATH/processed/temp/hosp_icem_crosswalk_inprog_combined.dta", replace

* Perform second pass (duplicates arise if same patient admitted multiple times, different admissions get matched to different censuses)

use "$PROJ_PATH/processed/temp/mmf_patient_id_reshape_combined.dta", clear
drop pat_id_proxy patient_id regid admityr
duplicates drop
joinby censusyr RecID_child outcomeyr RecID_adult using "$PROJ_PATH/processed/temp/hosp_icem_crosswalk_inprog_combined.dta", unmatched(both)
tab _merge
drop _merge

* Choose best age match between hospital and childhood census
bysort regid: gen mult_match = (_N > 1)
egen min_age_dist = min(age_dist_child), by(regid)
drop if age_dist_child != min_age_dist & mult_match == 1
drop mult_match min_age_dist

* Identify admissions/patients with matches to multiple outcome year observations
bysort regid: gen mult_match = (_N > 1)
qui unique outcomeyr RecID_adult, by(regid) gen(tot_match)
gsort + regid - tot_match
by regid: carryforward tot_match, replace

* Choose if birth parish matches between childhood and adult census
	egen max_bpl_match = max(bparish_match), by(regid)
	drop if bparish_match != max_bpl_match & mult_match == 1 & tot_match > 1 
	drop mult_match max_bpl_match tot_match

* Identify admissions/patients with matches to multiple outcome year observations
bysort regid: gen mult_match = (_N > 1)
qui unique outcomeyr RecID_adult, by(regid) gen(tot_match)
gsort + regid - tot_match
by regid: carryforward tot_match, replace

* Choose if no birth parish mismatch between childhood and adult census
	egen min_bpl_match = min(bpar_mismatch), by(regid)
	drop if bpar_mismatch != min_bpl_match & mult_match == 1 & tot_match > 1 
	drop mult_match min_bpl_match tot_match

* Identify admissions/patients with matches to multiple outcome year observations
bysort regid: gen mult_match = (_N > 1)
qui unique outcomeyr RecID_adult, by(regid) gen(tot_match)
gsort + regid - tot_match
by regid: carryforward tot_match, replace

	* Choose best age match between childhood and adult census
	egen min_age_dist = min(age_dist_adult), by(regid)
	drop if age_dist_adult != min_age_dist & mult_match == 1 & tot_match > 1 
	drop mult_match min_age_dist tot_match
	
* Choose latest outcome census for each admission/patient
egen latest_census = max(outcomeyr), by(regid)
drop if outcomeyr != latest_census
drop latest_census

* Choose earliest childhood census for each admission/patient
egen earliest_census = min(censusyr), by(regid)
drop if censusyr != earliest_census
drop earliest_census
tab censusyr

* Resolve remaining multiple matches
foreach var of varlist rescty_match distpar_match jw_name_ICEM nodist_match {
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
foreach var of varlist  jw_fname_orig-jw_name {
	egen temp_`var' = max(`var'), by(regid)
	replace `var' = temp_`var'
	drop temp_`var'
}

duplicates drop

// Save year of first hospital admission for each individual

merge m:1 regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", assert(2 3) keepusing(admityr pat_id_proxy)

gen matched = (_merge == 3)
drop _merge

gsort + pat_id_proxy - censusyr - RecID_child
by pat_id_proxy: carryforward censusyr RecID_child, replace
egen min_pid = min(pat_id_proxy), by(censusyr RecID_child)	
replace pat_id_proxy = min_pid if matched == 1
drop min_pid pat_id_proxy

egen yr_1st_admit = min(admityr), by(censusyr RecID_child)
drop admityr

keep if matched == 1
drop matched

unique regid
sort censusyr RecID_child outcomeyr RecID_adult regid
order regid censusyr RecID_child outcomeyr RecID_adult
save "$PROJ_PATH/processed/intermediate/crosswalks/occupational_hosp_icem_crosswalk.dta", replace
drop regid
duplicates drop
unique outcomeyr RecID_adult 
unique censusyr RecID_child
save "$PROJ_PATH/processed/temp/hosp_icem_matched_ids_combined.dta", replace

// Remove files

forvalues t_2 = 1901(10)1911 {
	if `t_2' == 1901 {
		local t_max = 1891
	}
	else {
		local t_max = 1901
	}
	forvalues t_1 = 1881(10)`t_max' {
		rm "$PROJ_PATH/processed/temp/hosp_icem_matches_`t_1'_`t_2'.dta"
	}
}
rm "$PROJ_PATH/processed/temp/hosp_icem_matches.dta"
rm "$PROJ_PATH/processed/temp/mmf_regids_combined.dta"
rm "$PROJ_PATH/processed/temp/mmf_regids_wide_combined.dta"
rm "$PROJ_PATH/processed/temp/mmf_patient_id_reshape_combined.dta"
rm "$PROJ_PATH/processed/temp/hosp_icem_crosswalk_inprog_combined.dta"




*********************************************************************************************************************
*********** ICEM HOSP Analysis Input *************
*********************************************************************************************************************

forvalues t_2 = 1901(10)1911 {
	if `t_2' == 1901 {
		local t_max = 1891
	}
	else {
		local t_max = 1901
	}
	forvalues t_1 = 1881(10)`t_max' {
	
		* Merge with variables needed for analysis
		
		use sex RecID Year sibling_id sib_type patient *brthord hhid pid age age_diff using "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`t_1'/icem_hosp_`t_1'_siblings.dta", clear
		rename Year censusyr
		rename RecID RecID_child
		rename pid pid_child
		merge 1:1 censusyr RecID_child sex using "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/unique_matches_`t_1'_`t_2'.dta", keep(3) nogen keepusing(outcomeyr RecID_adult age_adult age_dist bparish_match flag* bpar_mismatch mi_mismatch jw* similar*)  
		
		egen group_id = group(censusyr RecID_child)
		egen obs_id = seq(), by(censusyr RecID_child)
		reshape wide sex, i(group_id) j(obs_id)
		capture replace sex1 = . if sex2 != .
		capture drop sex2 
		drop group_id
		rename sex1 sex
		
		merge 1:1 censusyr RecID_child using "$PROJ_PATH/processed/temp/hosp_icem_matched_ids_combined.dta", keep(1 3) keepusing(censusyr RecID_child yr_1st_admit)
		
		tab patient _merge
		replace patient = 0 if _merge == 1
		drop _merge
		
		egen tot_pat = total(patient == 1), by(censusyr hhid)
		drop if tot_pat == 0
		drop tot_pat
		
		* Identify number of children age 0-5 in household when:
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

				replace `tot_0to5_at_0' = `tot_0to5_in_`y'' if `y' == `byr' - 1
				replace `tot_0to5_at_1' = `tot_0to5_in_`y'' if `y' == `byr' 
				replace `tot_0to5_at_2' = `tot_0to5_in_`y'' if `y' == `byr' + 1
				
				drop `tot_0to5_in_`y''
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

			forvalues y = `min_year'(1)`max_year' {
				tempvar tot_0to5_in_`y'
				egen `tot_0to5_in_`y'' = total(`y' - `byr' + 1 >= 0 & `y' - `byr' - 1 <= 5), by(censusyr hhid)

				replace hh_0to5_hosp = `tot_0to5_in_`y'' if `y' == `ref_yr'
				drop `tot_0to5_in_`y''
			}
			replace hh_0to5_hosp = 4 if hh_0to5_hosp > 4 & !missing(hh_0to5_hosp) // Top code at 4

			drop `byr' `age_1st_admit' `hh_1st_admit' `ref_yr'
			drop yr_1st_admit age
		}
		
		rename flag_recode_bpl_`t_1' flag_rbp_child
		rename flag_recode_bpl_`t_2' flag_rbp_adult
		
		rename censusyr Year
		rename RecID_child RecID
		merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`t_1'_demographic.dta", assert(2 3) keep(3) nogen keepusing(Age) // Rela Mar 
		merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`t_1'_residence.dta", assert(2 3) keep(3) nogen keepusing(RegCnty)
		rename Age age_child

		// Changes to ICEM county names:

		replace RegCnty = "Kent" if RegCnty == "Kent (Extra London)"
		replace RegCnty = "London" if RegCnty == "London (Parts Of Middlesex, Surrey & Kent)"
		replace RegCnty = "Middlesex" if RegCnty == "Middlesex (Extra London)"
		replace RegCnty = "Surrey" if RegCnty == "Surrey (Extra London)"
		replace RegCnty = "Yorkshire" if regexm(RegCnty,"Yorkshire")
		replace RegCnty = upper(RegCnty)
		rename RegCnty county_child
					
		merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`t_1'_occupation.dta", keep(1 3) nogen keepusing(pophisco popocc popoccode)
		merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`t_1'_demographic.dta", keep(1 3) nogen keepusing(popage) // popmarital poprelate
		
		// Add Williamson wages for father
		rename pophisco hisco
		rename popocc Occ
		rename popoccode Occode
		
		destring Occode, replace
		
		williamson `t_1'
		
		rename wage`t_1' popwage`t_1'
		rename hisco pophisco
		rename Occ popocc
		rename Occode popoccode

		merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/mom_vars/icem_mom_`t_1'_occupation.dta", keep(1 3) nogen keepusing(momhisco momocc)
		merge m:1 Year hhid using "$PROJ_PATH/processed/intermediate/icem/head_vars/icem_head_`t_1'_occupation.dta", keep(1 3) nogen keepusing(hh_hisco hh_occ)

		rename RecID RecID_child
		rename Year censusyr

		rename outcomeyr Year
		rename RecID_adult RecID
		merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`t_2'_residence.dta", assert(2 3) keep(3) nogen keepusing(RegCnty)
		merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`t_2'_occupation.dta", assert(2 3) keep(3) nogen keepusing(hisco Occ Occode)
		merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`t_2'_disability.dta", assert(2 3) keep(3) nogen keepusing(disab_any)

		// Add Williamson wages for patients and siblings as adults
		destring Occode, replace
		
		williamson `t_2'
		
		rename hisco ia_hisco 
		rename Occ ia_occ
		rename Occode ia_occode
		
		// Rescale disability variable
		replace disab_any = disab_any*100
		
		// Check if parents in household
		merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/mom_vars/icem_mom_`t_2'_identifiers.dta", keep(1 3) nogen keepusing(momloc)
		merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`t_2'_identifiers.dta", keep(1 3) nogen keepusing(poploc)
		
		rename poploc ia_poploc
		rename momloc ia_momloc
		
		// Add information on children
		rename RecID poprecid
		merge 1:1 Year poprecid using "$PROJ_PATH/processed/intermediate/icem/child_vars/icem_child_`t_2'.dta", keep(1 3) nogen
		rename poprecid RecID
		
		// Changes to ICEM county names:
		replace RegCnty = "Kent" if RegCnty == "Kent (Extra London)"
		replace RegCnty = "London" if RegCnty == "London (Parts Of Middlesex, Surrey & Kent)"
		replace RegCnty = "Middlesex" if RegCnty == "Middlesex (Extra London)"
		replace RegCnty = "Surrey" if RegCnty == "Surrey (Extra London)"
		replace RegCnty = "Yorkshire" if regexm(RegCnty,"Yorkshire")
		replace RegCnty = upper(RegCnty)
		rename RegCnty county_adult
					
		rename Year outcomeyr
		rename RecID RecID_adult
		
		tempfile ICEM_`t_1'_`t_2'
		save `ICEM_`t_1'_`t_2'', replace
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
		append using `ICEM_`t_1'_`t_2''
	}
}
duplicates drop

save "$PROJ_PATH/processed/intermediate/crosswalks/occupational_icem_hosp_analysis_input.dta", replace 

*********************************************************************************************************************
*********** ICEM HOSP Analysis Setup *************
*********************************************************************************************************************

// Restrict to final HOSP-ICEM-ICEM matched sample
merge m:1 censusyr RecID_child RecID_adult outcomeyr sex using "$PROJ_PATH/processed/temp/hosp_icem_matched_ids_combined.dta", assert(1 3) keep(1 3) keepusing(censusyr RecID_child RecID_adult outcomeyr sex)
order censusyr RecID_child outcomeyr RecID_adult patient sex 
tab patient _merge

// Restrict to males
keep if sex == 1
drop fbrthord 

// Restrict to siblings within 8 years
keep if age_diff <= 8

// Keep households with matched patients (NOTE: We need to keep households with unmatched patients to do the bounding exercise)
gen matched_patient = (_merge == 3)
drop _merge 

drop if patient == 1 & matched_patient == 0
drop patient
rename matched_patient patient

// Prioritize 1911 over 1901 if at least one patient and sibling in outcome year (starting with sibling closest in age)
forvalues n = 1(1)10 {
	foreach y in 1911 1901 {
		egen tot_merge_pat = total(patient == 1 & outcomeyr == `y'), by(censusyr hhid)
		egen tot_merge_sib = total(patient == 0 & outcomeyr == `y' & age_diff >= 1 & age_diff <= `n'), by(censusyr hhid)
		drop if tot_merge_pat > 0 & tot_merge_sib > 0 & outcomeyr != `y'
		drop tot_merge*
	}
}

// Prioritize 1911 over 1901 if at least one patient in outcome year
foreach y in 1911 1901 {
	egen tot_merge = total(patient == 1 & outcomeyr == `y'), by(censusyr hhid)
	drop if tot_merge > 0 & outcomeyr != `y'
	drop tot_merge*
}

// Prioritize matches to 1911 for siblings
egen tot_1911 = total(outcomeyr == 1911), by(censusyr RecID_child)
drop if tot_1911 > 0 & outcomeyr != 1911 & patient == 0
drop tot_1911
	
unique censusyr RecID_child
if r(sum) != r(N) {
	display "Non-unique observations in data"
	exit
}

// Eliminate cases where single outcome record matched to multiple childhood records

	bysort outcomeyr RecID_adult: gen mult_obs = (_N > 1)
	
	// Prioritize patients
	egen tot_pat = total(patient == 1), by(outcomeyr RecID_adult)
	drop if patient == 0 & tot_pat > 0
	drop tot_pat
	
	// Prioritize households with siblings
	egen tot_sibs = total(patient == 0), by(censusyr hhid)
	egen max_sibs = max(tot_sibs), by(outcomeyr RecID_adult)
	drop if mult_obs == 1 & tot_sibs != max_sibs
	drop tot_sibs max_sibs mult_obs
	
	// Prioritize households with closest siblings
	forvalues x = 1(1)8 {
		bysort outcomeyr RecID_adult: gen mult_obs = (_N > 1)
		egen tot_sibs`x' = total(patient == 0 & age_diff == `x'), by(censusyr hhid)
		egen max_sibs`x' = max(tot_sibs`x'), by(outcomeyr RecID_adult)
		drop if mult_obs == 1 & tot_sibs`x' != max_sibs`x'
		drop tot_sibs`x' max_sibs`x' mult_obs
	}

	// Prioritize earliest census
	egen min_census = min(censusyr), by(outcomeyr RecID_adult)
	drop if censusyr != min_census
	drop min_census
	
unique outcomeyr RecID_adult

// Add HISCLASS
rename pophisco hisco
merge m:1 hisco using "$PROJ_PATH/processed/intermediate/occupations/hisco_to_hisclass.dta", keep(1 3) nogen keepusing(hisclass)
rename hisclass pophisclass
rename hisco pophisco

rename momhisco hisco
merge m:1 hisco using "$PROJ_PATH/processed/intermediate/occupations/hisco_to_hisclass.dta", keep(1 3) nogen keepusing(hisclass)
rename hisclass momhisclass
rename hisco momhisco

rename hh_hisco hisco
merge m:1 hisco using "$PROJ_PATH/processed/intermediate/occupations/hisco_to_hisclass.dta", keep(1 3) nogen keepusing(hisclass)
rename hisclass hh_hisclass
rename hisco hh_hisco

rename ia_hisco hisco
merge m:1 hisco using "$PROJ_PATH/processed/intermediate/occupations/hisco_to_hisclass.dta", keep(1 3) nogen keepusing(hisclass)
rename hisclass ia_hisclass
rename hisco ia_hisco

label define hisc4lab 1 "White Collar" 2 "Skilled" 3 "Semi skilled" 4 "Unskilled", replace
local hisco_vars "pop mom hh_ ia_" 
foreach histype of local hisco_vars {
	gen `histype'hisc4 = .
	replace `histype'hisc4 = 1 if `histype'hisclass == 1 | `histype'hisclass == 2 | `histype'hisclass == 3 | `histype'hisclass == 4 | `histype'hisclass == 5
	replace `histype'hisc4 = 2 if `histype'hisclass == 6 | `histype'hisclass == 7 | `histype'hisclass == 8
	replace `histype'hisc4 = 3 if `histype'hisclass == 9
	replace `histype'hisc4 = 4 if `histype'hisclass == 10 | `histype'hisclass == 11 | `histype'hisclass == 12
	la val `histype'hisc4 hisc4lab
}

// Add Williamson wages for fathers
forvalues y = 1881(10)1901 {
	merge m:1 pophisclass using "$PROJ_PATH/processed/intermediate/occupations/williamson_avg_wage12_`y'.dta", keep(1 3) nogen keepusing(avg_wage12_`y')
	replace popwage`y' = avg_wage12_`y' if popwage`y' == .
	drop avg_wage12_`y'
}

// Add Williamson average wages for patients and siblings
forvalues y = 1901(10)1911 {
	merge m:1 ia_hisclass using "$PROJ_PATH/processed/intermediate/occupations/williamson_avg_wage12_`y'.dta", keep(1 3) nogen keepusing(avg_wage12_`y')
	replace wage`y' = avg_wage12_`y' if wage`y' == .
	drop avg_wage12_`y'
}

// Create single variable for father and sons' wages
gen popwage = .
forvalues y = 1881(10)1901 {
	replace popwage = popwage`y' if censusyr == `y'
}
gen ln_popwage = ln(popwage)
drop popwage popwage1881 popwage1891 popwage1901

gen wage = .
replace wage = wage1901 if outcomeyr == 1901
replace wage = wage1911 if outcomeyr == 1911
gen ln_wage = ln(wage)
drop wage1901 wage1911

// Create new sibling ID
rename sibling_id sibid_orig
egen sibling_id = group(censusyr sibid_orig)
drop sibid_orig

egen max_brthord = max(brthord), by(sibling_id)
egen matched_pats = total(patient == 1), by(sibling_id)
egen matched_sibs = total(patient == 0), by(sibling_id)
unique sibling_id if matched_pats > 0 & matched_sibs > 0

bysort sibling_id: gen sib_size = _N if sibling_id != .
recode sib_size (mis = 0)
tab sib_size

* Create regression variables

// Age variables:
gen byr_adult = outcomeyr - age_adult
gen frstbrn = (brthord == 1)
gen patfbrn = patient*frstbrn

gen patins = ((byr_adult >= 1870 & byr_adult<= 1890 & patient == 1) | patient == 0)
	
// Generate mobility variables
gen mobility_up = (ia_hisc4 < pophisc4) if ia_hisc4 != . & pophisc4 != .
gen mobility_dn = (ia_hisc4 > pophisc4) if ia_hisc4 != . & pophisc4 != .

gen top_25 = ia_hisc4 == 1 if ia_hisc4 != .
gen top_50 = (ia_hisc4 == 1 | ia_hisc4 == 2) if ia_hisc4 != .
gen bot_25 = ia_hisc4 == 4 if ia_hisc4 != .

// Set up father's occupation variables
gen pop_byr = censusyr - popage
gen popwc = (pophisc4 == 1) if pophisc4 != .
gen popsk = (pophisc4 == 1 | pophisc4 == 2) if pophisc4 != .

la var popwc "Father's status"
la var popsk "Father's status"

drop popocc

// Geography variables
gen pat_gl = ((county_child == "LONDON" | county_child == "MIDDLESEX" | county_child == "KENT" | county_child == "ESSEX" | county_child == "SURREY") & patient == 1)
egen hh_gl = max(pat_gl), by(sibling_id)
gen greater_london = (hh_gl == 1)
drop pat_gl hh_gl
	
// Generate sample restrictions
gen military = (county_adult == "MILITARY" | county_adult == "ROYAL NAVY")
gen twins = (patient == 0 & age_diff == 0)
gen valid_age = (age_adult >= 18 & byr_adult >= 1870 & byr_adult <= 1893)

// Generate social outcomes
gen cty_mover = (county_adult != county_child)
gen live_with_parent = (ia_poploc != 0 & !missing(ia_poploc)) | (ia_momloc != 0 & !missing(ia_momloc))

drop byr_1st_child county_child county_adult ia_poploc ia_momloc

// Generate child outcomes
recode nchild (mis = 0)
gen any_child = (nchild > 0 & !missing(nchild))
drop nchild

recode ch_scholar (mis = 0)
replace ch_scholar = . if any_child == 0 | missing(any_child)
replace ch_scholar = . if outcomeyr == 1901

foreach var of varlist age_dist mi_mismatch jw* similar* {
	rename `var' `var'_ICEM
}

gen jw_fname_exact = (jw_fname_orig_ICEM == 1 | jw_fname_edit_ICEM == 1)
gen jw_sname_exact = (jw_sname_ICEM == 1)

// Add HOSP-ICEM matching variables
merge 1:1 censusyr RecID_child outcomeyr RecID_adult using "$PROJ_PATH/processed/temp/hosp_icem_matched_ids_combined.dta", keep(1 3) keepusing(age_dist_child mi_mismatch rescty_match distpar_match nodist_match jw_fname_orig-jw_name similar_0-similar_15) 
tab patient _merge
recode age_dist_child mi_mismatch similar_0-similar_15 (mis = 0)
recode rescty_match distpar_match nodist_match jw_fname_orig-jw_name (mis = 1)
drop _merge

egen patient_id = group(censusyr RecID_child outcomeyr RecID_adult)
order censusyr hhid sibling_id sib_type pid_child RecID_child outcomeyr RecID_adult patient sex age_child age_adult age_dist* age_diff pop* mom* hh_* ia* brthord mbrthord bparish* bpar* mi_mismatch*
order jw* similar* flag*, last

unique censusyr hhid pid_child
sort censusyr hhid pid_child

save "$PROJ_PATH/processed/temp/icem_hosp_analysis_variables_combined.dta", replace



// Create patient specific variables
use censusyr RecID_child outcomeyr RecID_adult patient patient_id using "$PROJ_PATH/processed/temp/icem_hosp_analysis_variables_combined.dta" if patient == 1, clear
drop patient
merge 1:m censusyr RecID_child outcomeyr RecID_adult using "$PROJ_PATH/processed/intermediate/crosswalks/occupational_hosp_icem_crosswalk.dta", assert(2 3) keep(3) nogen keepusing(regid)

bysort censusyr RecID_child outcomeyr RecID_adult: gen tot_visits = _N
drop censusyr RecID_child outcomeyr RecID_adult
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
	
sort patient_id regid
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
save "$PROJ_PATH/processed/temp/hosp_patient_variables_combined.dta", replace

use "$PROJ_PATH/processed/temp/icem_hosp_analysis_variables_combined.dta", clear
merge 1:1 patient_id using "$PROJ_PATH/processed/temp/hosp_patient_variables_combined.dta", assert(1 3)
tab patient _merge
drop _merge
qui recode acute-min_los (mis = 0)
qui recode resid_mort comorbid-transfer tot_visits (mis = 0) if patient == 0 
qui recode valid_admitage (mis = 1) if patient == 0
		
// Drop remaining households with no patients

egen tot_pat = total(patient == 1), by(censusyr hhid)
drop if tot_pat == 0
drop tot_pat 

la var patient "Patient"
la var resid_mort "Health deficiency index"
la var acute "Acute"
la var doctor "Doctor"

sort censusyr RecID_child
merge 1:1 censusyr RecID_child using "$PROJ_PATH/processed/intermediate/names/icem_name_analysis.dta", assert(2 3) keep(3) nogen keepusing(std_fnamefreq interact_namefreq)

rename outcomeyr Year 
rename RecID_adult RecID

rename Year outcomeyr
rename RecID RecID_adult

unique censusyr hhid pid_child
sort censusyr hhid pid_child
save "$PROJ_PATH/processed/intermediate/final_build/occupational_analysis_setup.dta", replace

rm "$PROJ_PATH/processed/temp/icem_hosp_analysis_variables_combined.dta"
rm "$PROJ_PATH/processed/temp/hosp_patient_variables_combined.dta"
rm "$PROJ_PATH/processed/temp/hosp_icem_matched_ids_combined.dta"

disp "DateTime: $S_DATE $S_TIME"

* EOF
