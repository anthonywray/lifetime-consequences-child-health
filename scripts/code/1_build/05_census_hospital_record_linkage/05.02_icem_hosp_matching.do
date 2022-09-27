version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 05.02_icem_hosp_matching.do
* PURPOSE: The do file links the I-CeM complete count 1881, 1891, 1901, and 1911 censuses to the hospital admission records
************

args year

*********************************************************************************************************************
*********** I-CeM-HOSP Extract Matching Vars *************
*********************************************************************************************************************

* Load matching variables

use RecID Age Sex Mar using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`year'_demographic.dta" if Age <= 21, clear
merge 1:1 RecID using "$PROJ_PATH/raw/icem_sl/ICEM_Names_EW_`year'.dta", assert(2 3) keep(3) nogen keepusing(Pname Oname Sname)
recast str Oname Sname

* Rename ICEM variables
rename Age age 
rename Sex sex
rename Mar marst

* Reshape sex
gen missing_sex = (sex == . | sex == 9)
rename sex sex1 
gen sex2 = .
replace sex1 = 1 if missing_sex == 1
replace sex2 = 2 if missing_sex == 1
drop missing_sex

gen long obs_id = _n
reshape long sex, i(obs_id) j(new_id)
drop obs_id new_id
drop if sex == .
order sex

* Don't accept matches of female patients to married women since name changed at marriage

drop if sex == 2 & (marst == 2 | marst == 3)
drop marst

merge m:1 Pname Oname sex using "$PROJ_PATH/processed/intermediate/names/firstnames_`year'.dta", keep(3) nogen
merge m:1 Sname using "$PROJ_PATH/processed/intermediate/names/surnames_`year'.dta", keep(3) nogen keepusing(phx_sname* surname*)

* Reshape firstname
save "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/reshape_fname_inprog.dta", replace
keep if firstname2 != ""
gen long obs_id = _n
reshape long firstname phx_fname, i(obs_id) j(new_id)
drop if firstname == ""
drop obs_id new_id
save "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/reshape_fname_multiple.dta", replace

use "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/reshape_fname_inprog.dta", clear
keep if firstname2 == ""
rename firstname1 temp_firstname
rename phx_fname1 temp_phx
drop firstname* phx_fname*
rename temp_firstname firstname
rename temp_phx phx_fname
append using "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/reshape_fname_multiple.dta"
drop if length(fname_orig) <= 1
drop firstname Pname Oname

rm "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/reshape_fname_inprog.dta"
rm "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/reshape_fname_multiple.dta"

* Reshape surname
save "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/reshape_sname_inprog.dta", replace
keep if surname2 != ""
gen long obs_id = _n
reshape long surname phx_sname, i(obs_id) j(new_id)
drop if surname == ""
drop obs_id new_id
save "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/reshape_sname_multiple.dta", replace

use "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/reshape_sname_inprog.dta", clear
keep if surname2 == ""
rename surname1 temp_sname
rename phx_sname1 temp_phx
drop surname* phx_sname*
rename temp_sname surname
rename temp_phx phx_sname
append using "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/reshape_sname_multiple.dta"
drop if length(surname) <= 1
drop Sname
rm "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/reshape_sname_inprog.dta"
rm "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/reshape_sname_multiple.dta"

duplicates drop
sort RecID phx_sname phx_fname sex age
save "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'/match_input_`year'_criteria.dta", replace

*********************************************************************************************************************
*********** I-CeM-HOSP Blocking Setup *************
*********************************************************************************************************************

* Create blocking input file that restricts to blocking variables

use "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'/match_input_`year'_criteria.dta", clear
keep phx* age sex 
bysort phx_sname phx_fname age sex: keep if _n == 1
save "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'/match_input_`year'_blocking.dta", replace

* Create blocking file for HOSP to ICEM

use "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'/match_input_hosp_blocking.dta", clear
sort phx_sname phx_fname age sex
rename age age_base

gen age1 = age_base - 4
gen age2 = age_base - 3
gen age3 = age_base - 2
gen age4 = age_base - 1
gen age5 = age_base 
gen age6 = age_base + 1
gen age7 = age_base + 2
gen age8 = age_base + 3

gen long group_id = _n
reshape long age, i(group_id) j(obs_id)
drop group_id obs_id

save "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/blocking_inprog_`year'.dta", replace

keep phx_sname phx_fname age sex
duplicates drop
bysort phx_sname phx_fname age sex: keep if _n == 1

merge 1:m phx_sname phx_fname age sex using "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'/match_input_`year'_blocking.dta", keep(3) nogen keepusing(phx_sname phx_fname age sex)

duplicates drop
bysort phx_sname phx_fname age sex: keep if _n == 1
save "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/matched_blocks_hosp_`year'.dta", replace

merge 1:m phx_sname phx_fname age sex using "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'/match_input_`year'_criteria.dta", keep(3) nogen

duplicates drop
sort phx_sname phx_fname age sex surname fname_edit fname_orig RecID
save "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/match_candidates_icem_`year'.dta", replace

use "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/blocking_inprog_`year'.dta", clear
merge m:1 phx_sname phx_fname age sex using "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/matched_blocks_hosp_`year'.dta", keep(3) nogen
drop age
rename age_base age

keep phx_sname phx_fname age sex
bysort phx_sname phx_fname age sex: keep if _n == 1

merge 1:m phx_sname phx_fname age sex using "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'/match_input_hosp_criteria.dta", keep(3) nogen

duplicates drop
sort phx_sname phx_fname age sex surname_HOSP fname_edit_HOSP fname_orig_HOSP regid 
save "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/match_candidates_hosp_`year'.dta", replace

rm "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/blocking_inprog_`year'.dta"
rm "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/matched_blocks_hosp_`year'.dta"

// Clear ICEM names

use "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'/match_input_`year'_criteria.dta", clear
drop fname_orig fname_edit surname
duplicates drop
save "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'/match_input_`year'_criteria.dta", replace

*********************************************************************************************************************
*********** I-CeM-HOSP Census Blocking *************
*********************************************************************************************************************

use age using "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/match_candidates_hosp_`year'.dta", clear
sum age
local max_age = r(max)
local min_age = r(min)

forvalues n = `min_age'(1)`max_age' {
	use "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/match_candidates_hosp_`year'.dta", clear

	keep if age == `n'
	rename age age_ub
	gen age1 = age_ub - 4
	gen age2 = age_ub - 3
	gen age3 = age_ub - 2
	gen age4 = age_ub - 1
	gen age5 = age_ub 
	gen age6 = age_ub + 1
	gen age7 = age_ub + 2
	gen age8 = age_ub + 3
	gen long group_id = _n
	reshape long age, i(group_id) j(obs_id)
	drop group_id obs_id
	
	sort phx_sname phx_fname age sex age_ub
	joinby phx_sname phx_fname age sex using "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/match_candidates_icem_`year'.dta"

	save "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/blocking_inprog_`year'_`n'.dta", replace
	keep fname_orig fname_orig_HOSP
	bysort fname_orig fname_orig_HOSP: keep if _n == 1
	jarowinkler fname_orig fname_orig_HOSP, gen(jw_fname_orig)
	save "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/jw_fname_orig_`year'_`n'.dta", replace
	
	use "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/blocking_inprog_`year'_`n'.dta", clear
	keep fname_edit fname_edit_HOSP
	bysort fname_edit fname_edit_HOSP: keep if _n == 1
	jarowinkler fname_edit fname_edit_HOSP, gen(jw_fname_edit)
	save "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/jw_fname_edit_`year'_`n'.dta", replace
	
	use "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/blocking_inprog_`year'_`n'.dta", clear
	keep surname surname_HOSP
	bysort surname surname_HOSP: keep if _n == 1
	jarowinkler surname surname_HOSP, gen(jw_sname)
	save "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/jw_sname_`year'_`n'.dta", replace
	
	use "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/blocking_inprog_`year'_`n'.dta", clear
	merge m:1 fname_orig fname_orig_HOSP using "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/jw_fname_orig_`year'_`n'.dta", keep(1 3) nogen
	merge m:1 fname_edit fname_edit_HOSP using "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/jw_fname_edit_`year'_`n'.dta", keep(1 3) nogen
	merge m:1 surname surname_HOSP using "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/jw_sname_`year'_`n'.dta", keep(1 3) nogen
	
	recode jw_fname_orig jw_fname_edit jw_sname (mis = 0)
	keep if max(jw_fname_orig, jw_fname_edit) >= 0.7 & jw_sname >= 0.7
	
	duplicates drop
	drop phx* fname_edit fname_orig surname
	
	* Keep best match for each HOSP-ICEM pair
	egen max_jw_dist = max(jw_fname_orig), by(RecID regid)
	drop if jw_fname_orig != max_jw_dist
	drop max_jw_dist
	egen max_jw_dist = max(jw_fname_edit), by(RecID regid)
	drop if jw_fname_edit != max_jw_dist
	drop max_jw_dist
	egen max_jw_dist = max(jw_sname), by(RecID regid)
	drop if jw_sname != max_jw_dist
	drop max_jw_dist
	
	duplicates drop 
	
	save "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/blocking_matched_`year'_`n'.dta", replace
	
	rm "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/blocking_inprog_`year'_`n'.dta"
	rm "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/jw_fname_orig_`year'_`n'.dta"
	rm "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/jw_fname_edit_`year'_`n'.dta"
	rm "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/jw_sname_`year'_`n'.dta"
}
clear
forvalues n = `min_age'(1)`max_age' {
	append using "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/blocking_matched_`year'_`n'.dta"
}

order RecID regid age_ub age sex jw*
sort RecID regid surname_HOSP

save "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'/using_sample_`year'_hosp.dta", replace

forvalues n = `min_age'(1)`max_age' {
	rm "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/blocking_matched_`year'_`n'.dta"
}
rm "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/match_candidates_icem_`year'.dta"
rm "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/match_candidates_hosp_`year'.dta"

*********************************************************************************************************************
*********** I-CeM-HOSP Unique Sample *************
*********************************************************************************************************************

* Set unique sample

use "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'/using_sample_`year'_hosp.dta", clear
unique regid RecID

* Compute number of similar records

gen jw_name = (max(jw_fname_orig,jw_fname_edit)+jw_sname)/2
egen max_jw_name = max(jw_name), by(regid)

gen age_lb = age_ub - 1
gen age_dist = min(abs(age - age_ub), abs(age - age_lb))
rename age_ub age_HOSP
rename age age_`year'
drop age_lb
egen min_age_dist = min(age_dist), by(regid)

foreach x in 0 5 10 15 {
	local y = 1+(`x'/100)
	qui unique RecID if jw_name >= max_jw_name/`y' & (age_dist - min_age_dist) <= 1, by(regid) gen(similar_`x')
	gsort + regid - similar_`x'
	bysort regid: carryforward similar_`x', replace
	replace similar_`x' = similar_`x' - 1 if similar_`x' > 0
}
drop max_jw_name

* Drop records worse than 0.8 JW distance

keep if max(jw_fname_orig, jw_fname_edit) >= 0.8 & jw_sname >= 0.8

* Drop if age difference > 3 years and prioritize closest age match
drop if age_dist > 3 | age_dist != min_age_dist
drop min_age_dist

egen min_age_dist = min(age_dist), by(regid)
drop if age_dist != min_age_dist
drop min_age_dist

* Prioritize best match on name (if best match is sufficiently different from second best): average first and last name

egen max_jw_name = max(jw_name), by(regid)

egen second_jw_name = max(jw_name) if jw_name != max_jw_name, by(regid)
gsort + regid - second_jw_name
bysort regid: carryforward second_jw_name, replace
replace second_jw_name = max_jw_name if second_jw_name == .

gen jw_gap = (max_jw_name - second_jw_name)
drop if (jw_name != max_jw_name & second_jw_name < max_jw_name/1.1 & jw_gap != .)
drop max_jw_name second_jw_name jw_gap
duplicates drop

* Prioritize best match on name stage 2: separate for first and last names

gen jw_fname = max(jw_fname_orig,jw_fname_edit)
egen max_jw_fname = max(jw_fname), by(regid)
egen max_jw_sname = max(jw_sname), by(regid)

egen second_jw_fname = max(jw_fname) if jw_fname != max_jw_fname, by(regid)
gsort + regid - second_jw_fname
bysort regid: carryforward second_jw_fname, replace
replace second_jw_fname = max_jw_fname if second_jw_fname == .

egen second_jw_sname = max(jw_sname) if jw_sname != max_jw_sname, by(regid)
gsort + regid - second_jw_sname
bysort regid: carryforward second_jw_sname, replace
replace second_jw_sname = max_jw_sname if second_jw_sname == .

gen jw_fgap = max_jw_fname - second_jw_fname
gen jw_sgap = max_jw_sname - second_jw_sname
drop if (jw_fname != max_jw_fname & second_jw_fname < max_jw_fname/1.1 & jw_fgap != .) | (jw_sname != max_jw_sname & second_jw_sname < max_jw_sname/1.1 & jw_sgap != .)
drop max_jw_*name second_jw_*name jw_*gap

unique RecID
unique regid

* Add middle initials for matching

merge m:1 RecID using "$PROJ_PATH/raw/icem_sl/ICEM_Names_EW_`year'.dta", assert(2 3) keep(3) nogen keepusing(Pname Oname)
recast str Oname
merge m:1 Pname Oname sex using "$PROJ_PATH/processed/intermediate/names/midnames_`year'.dta", assert(2 3) keep(3) nogen keepusing(midname)
drop Pname Oname

merge m:1 regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", assert(2 3) keep(3) nogen keepusing(mname_HOSP)

sort regid RecID

* Flag middle initial mismatch
gen temp_mi_mismatch = (substr(midname,1,1) != substr(mname_HOSP,1,1) & midname != "" & mname_HOSP != "")
egen total_mismatch = total(temp_mi_mismatch == 1), by(regid)
gen mi_mismatch = (total_mismatch > 0)
drop temp_mi_mismatch total_mismatch midname
duplicates drop
unique regid RecID

* Merge with county of residence in census and hospital records

merge m:1 RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`year'_residence.dta", keep(3) assert(2 3) nogen keepusing(RegCnty)
merge m:1 regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", keep(3) assert(2 3) nogen keepusing(county_HOSP)

split county_HOSP, parse(", ") gen(ctyhosp)
local maxvar = r(nvars)
display `maxvar'

***** Changes to county name in HOSP records to correspond to ICEM county names:
forvalues x = 1(1)`maxvar' {
	replace ctyhosp`x' = "DEVON" if ctyhosp`x' == "DEVONSHIRE"
	replace ctyhosp`x' = "WARWICKSHIRE" if ctyhosp`x' == "WARWICK"
	replace ctyhosp`x' = "OXFORDSHIRE" if ctyhosp`x' == "OXFORD"
	replace ctyhosp`x' = "CARNARVONSHIRE" if ctyhosp`x' == "CAERNARVONSHIRE"
	replace ctyhosp`x' = "GUERNSEY AND ADJACENT ISLES" if ctyhosp`x' == "GUERNSEY" | ctyhosp`x' == "ALDERNEY"
}

***** Changes to ICEM county names:

replace RegCnty = "Kent" if RegCnty == "Kent (Extra London)"
replace RegCnty = "London" if RegCnty == "London (Parts Of Middlesex, Surrey & Kent)"
replace RegCnty = "Middlesex" if RegCnty == "Middlesex (Extra London)"
replace RegCnty = "Surrey" if RegCnty == "Surrey (Extra London)"
replace RegCnty = "Yorkshire" if regexm(RegCnty,"Yorkshire")

replace RegCnty = upper(RegCnty)

split county_HOSP, parse(", ") gen(temp)
local maxvar = r(nvars)
drop temp*
display `maxvar'

gen rescty_match = 0
forvalues x = 1(1)`maxvar' {
	replace rescty_match = 1 if RegCnty == ctyhosp`x'
} 
drop ctyhosp*
sort regid RecID

* Prioritize match on residence county

egen tot_rescty_match = total(rescty_match == 1), by(regid)
drop if tot_rescty_match > 0 & rescty_match == 0
drop tot_rescty_match 

* Identify matches on registration district

merge m:1 RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`year'_residence.dta", keepusing(RegDist Parish) assert(2 3) keep(3) nogen
gen district = upper(RegDist)
gen parish = upper(Parish)
drop RegDist Parish

merge m:1 regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", keep(3) assert(2 3) nogen keepusing(district_HOSP parish_HOSP)

replace parish = "BOW" if parish == "BOW AKA ST MARY STRATFORD-LE-BOW"
replace parish_HOSP = "BOW" if parish_HOSP == "BOW AKA ST MARY STRATFORD-LE-BOW" | parish_HOSP == "ST MARY-LE-BOW"
replace parish = "ST BOTOLPH WITHOUT ALDGATE" if regexm(parish,"ST BOTOLPH WITHOUT ALDGATE")
replace parish_HOSP = "ST BOTOLPH WITHOUT ALDGATE" if parish_HOSP == "ST BOTOLPH WITHOUT ALDGATE AKA EAST SMITHFIELD" | regexm(parish_HOSP,"ST BOTOLPH WITHOUT ALDGATE")
replace parish = "LOWER TOOTING" if parish == "LOWER TOOTING AKA TOOTING GRAVENEY"
replace parish_HOSP = "ST MARGARET AND ST JOHN THE EVANGELIST WESTMINSTER" if parish_HOSP == "ST JOHNS"
replace parish_HOSP = "WALTHAM ABBEY" if parish_HOSP == "WALTHAM ABBEY AKA WALTHAM HOLY CROSS (ESSEX)"

capture split district_HOSP, parse(", ") gen(dist)
local max_split = r(nvars)
gen dist_match = 0
forvalues n = 1(1)`max_split' {
	replace dist_match = 1 if district == dist`max_split'
}
drop dist1-dist`max_split'

gen par_match = (parish == parish_HOSP)
gen distpar_match = (dist_match == 1 | par_match == 1)
drop dist_match 

* Add manual matches based on partial parish match

replace distpar_match = 1 if parish=="SOUTHWARK" & (regexm(parish_HOSP,"SOUTHWARK") | regexm(district_HOSP,"SOUTHWARK"))
replace distpar_match = 1 if parish == "ST OLAVE AND ST THOMAS" & (parish_HOSP == "ST OLAVE SOUTHWARK" | parish_HOSP == "ST THOMAS SOUTHWARK")
replace distpar_match = 1 if parish == "MILE END" & regexm(parish_HOSP,"MILE END")
replace distpar_match = 1 if parish == "DEPTFORD" & regexm(parish_HOSP,"DEPTFORD")
replace distpar_match = 1 if regexm(parish,"ST ANDREW HOLBORN") & regexm(parish_HOSP,"ST ANDREW HOLBORN")
replace distpar_match = 1 if parish == "ST ANDREW" & regexm(parish_HOSP,"ST ANDREW HOLBORN")
replace distpar_match = 1 if parish == "ST BOTOLPH" & regexm(parish_HOSP,"ST BOTOLPH")
replace distpar_match = 1 if regexm(parish,"BATTERSEA, CLAPHAM, AND FORMBY") & (regexm(parish_HOSP,"BATTERSEA") | regexm(parish_HOSP,"CLAPHAM"))
replace distpar_match = 1 if parish == "ST GILES" & regexm(parish_HOSP,"ST GILES")
replace distpar_match = 1 if parish == "ST GEORGE" & regexm(parish_HOSP,"ST GEORGE")
replace distpar_match = 1 if parish == "ST MARY" & (regexm(parish_HOSP,"ST MARY") | parish_HOSP=="BOW")
replace distpar_match = 1 if regexm(parish,"ST DUNSTAN") & regexm(parish_HOSP,"ST DUNSTAN")
replace distpar_match = 1 if regexm(parish,"ST OLAVE") & regexm(parish_HOSP,"ST OLAVE")
replace distpar_match = 1 if regexm(parish,"ST BARTHOLOMEW") & regexm(parish_HOSP,"ST BARTHOLOMEW")
replace distpar_match = 1 if regexm(parish,"HOLY TRINITY") & regexm(parish_HOSP,"HOLY TRINITY")

* Generate total matches per patient

bysort regid: gen tot_match1 = _N

egen total_distpar = total(distpar_match), by(regid)
gen nodist_match = (tot_match1 == 1)

sort regid RecID
egen temp = min(regid), by(RecID)
egen patient_id = group(temp)
drop temp
unique regid RecID
unique regid

gen censusyr = `year'
sort patient_id regid
order censusyr patient_id regid RecID fname_orig_HOSP fname_edit_HOSP mname_HOSP surname_HOSP age_`year' age_HOSP age_dist sex RegCnty county_HOSP rescty_match jw* mi_mismatch

***** Save multiple matches
save "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'/multiple_matches_`year'_hosp.dta", replace

drop if distpar_match == 0 & total_distpar > 0 & tot_match1 > 1
drop total_distpar 

* Restrict to unique matches
bysort regid: gen tot_match3 = _N
keep if tot_match3 == 1

sort regid patient_id 
save "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'/unique_matches_`year'_hosp.dta", replace

*********************************************************************************************************************
*********** I-CeM-HOSP Matching Households I-CeM *************
*********************************************************************************************************************

use RecID similar_10 mi_mismatch rescty_match using "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'/unique_matches_`year'_hosp.dta", clear

**NOTE: Need to carry around counter for number of similar records and middle initial mismatch to exclude cases to search for in marriage records

foreach var of varlist similar_10 mi_mismatch rescty_match {
	egen temp_`var' = min(`var'), by(RecID)
	replace `var' = temp_`var'
	drop temp_`var'
}
bysort RecID similar_10 mi_mismatch rescty_match: keep if _n == 1
gen patient = 1
merge 1:1 RecID using "$PROJ_PATH/processed/intermediate/icem/sibling_ids/sibling_ids_`year'.dta", assert(2 3) nogen
recode patient similar_10 mi_mismatch rescty_match (mis = 0)
merge 1:1 RecID using "$PROJ_PATH/processed/intermediate/icem/household_ids/icem_household_ids_`year'.dta", assert(3) nogen keepusing(hhid pid_inf flag_fix_pid)
rename pid_inf pid
egen hh_match = total(patient == 1), by(hhid)
keep if hh_match > 0
drop hh_match

compress
merge 1:1 RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`year'_residence.dta", keepusing(RegCnty) assert(2 3) nogen keep(3)
merge 1:1 RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`year'_demographic.dta", keepusing(Age Sex Mar) assert(2 3) nogen keep(3)

* Rename ICEM variables
rename Age age 
rename Sex sex
rename Mar marst

* Reshape sex
gen missing_sex = (sex == . | sex == 9)
rename sex sex1 
gen sex2 = .
replace sex1 = 1 if missing_sex == 1
replace sex2 = 2 if missing_sex == 1
drop missing_sex

gen long obs_id = _n
reshape long sex, i(obs_id) j(new_id)
drop obs_id new_id
drop if sex == .
order sex

* Add father's given names

merge m:1 RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`year'_identifiers.dta", keep(1 3) nogen keepusing(poprecid)

drop if patient == 0 & sibling_id == .
egen tot_pat = total(patient == 1), by(sibling_id)
drop if tot_pat == 0 & sibling_id != .

* Compute age difference between siblings
save "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/agediff_inprog_`year'.dta", replace
use "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/agediff_inprog_`year'.dta", clear
keep if patient == 1 & sibling_id != .
keep sibling_id age
bysort sibling_id age: keep if _n == 1
egen temp_id = seq(), by(sibling_id)
sum temp_id
local max_obs = r(max)
rename age patage
reshape wide patage, i(sibling_id) j(temp_id)
save "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/agediff_reshape_`year'.dta", replace

use "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/agediff_inprog_`year'.dta", clear
merge m:1 sibling_id using "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/agediff_reshape_`year'.dta", assert(1 3) keep(1 3) 
tab sibling_id if _merge == 1
drop _merge
forvalues x = 1(1)`max_obs' {
	gen temp`x' = abs(age - patage`x')
}
egen age_diff = rowmin(temp1-temp`max_obs')
tab age_diff if patient == 1, missing
replace age_diff = 0 if patient == 1 & sibling_id == .
drop temp* patage*

sort hhid pid sex
save "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'/icem_hosp_`year'_siblings.dta", replace 

rm "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/agediff_inprog_`year'.dta"
rm "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'/agediff_reshape_`year'.dta"

rm "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'/using_sample_`year'_hosp.dta"

disp "DateTime: $S_DATE $S_TIME"

* EOF
