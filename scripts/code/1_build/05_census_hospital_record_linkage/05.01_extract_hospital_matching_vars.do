version 14

disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 05.01_extract_hospital_matching_vars.do
* PURPOSE: The do file extracts the variables from the hospital data in preparation for linkage to the 1881, 1891, and 1901 censuses
************

args byr_start byr_end census_month census_day census_year

****************** Extract firstnames
use namestr_HOSP fnamestr_HOSP snamestr_HOSP fname_orig_HOSP fname_HOSP alt_fn_HOSP sex_HOSP using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear
rename fname_HOSP fname_edit_HOSP
rename sex_HOSP sex	
bysort namestr_HOSP fnamestr_HOSP snamestr_HOSP fname_orig_HOSP fname_edit_HOSP alt_fn_HOSP sex: keep if _n == 1

* Reshape observations with unknown gender
gen missing_sex = (sex == .)
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

* Combine original firstname and alternative firstname

rename fname_orig_HOSP fname_orig_HOSP1
rename alt_fn_HOSP fname_orig_HOSP2

replace fname_orig_HOSP2 = "" if fname_orig_HOSP1 == fname_orig_HOSP2
gen long obs_id = _n
reshape long fname_orig_HOSP, i(obs_id) j(new_id)
drop obs_id new_id
egen temp = total(fname_orig_HOSP != ""), by(sex namestr_HOSP fnamestr_HOSP snamestr_HOSP fname_edit_HOSP)
drop if temp > 0 & fname_orig_HOSP == ""
drop temp

* Split first name if "OR" format
split fname_orig_HOSP, parse("-OR-") gen(fname_orig_HOSP)
drop fname_orig_HOSP
gen long obs_id = _n
reshape long fname_orig_HOSP, i(obs_id) j(new_id)
drop obs_id new_id
egen temp = total(fname_orig_HOSP != ""), by(sex namestr_HOSP fnamestr_HOSP snamestr_HOSP fname_edit_HOSP)
drop if temp > 0 & fname_orig_HOSP == ""
drop temp

* Recreated edited name due to issues with missing gender

drop fname_edit_HOSP
gen fname_edit_HOSP = fname_orig_HOSP
local names "fname_edit_HOSP"
foreach name of local names {
	rename `name' nickname
	merge m:1 nickname sex using "$PROJ_PATH/processed/intermediate/names/nicknames_for_matching.dta", keepusing(name_for_matching) keep(1 3) nogen
	replace nickname = name_for_matching if name_for_matching!=""
	drop name_for_matching
	rename nickname `name'
}

bysort namestr_HOSP fnamestr_HOSP snamestr_HOSP fname_orig_HOSP fname_edit_HOSP sex: keep if _n == 1

gen firstname1 = fname_orig_HOSP
gen firstname2 = fname_edit_HOSP

replace firstname2 = "" if firstname2 == firstname1
gen long obs_id = _n
reshape long firstname, i(obs_id) j(new_id)
drop obs_id new_id
drop if firstname == ""

***** Create phonex code
gen tophonex = firstname
do "$PROJ_PATH/scripts/code/1_build/_name_cleanup/_phonex.do"
rename phonexed phx_fname
drop tophonex

sort namestr_HOSP fnamestr_HOSP snamestr_HOSP sex firstname
order namestr_HOSP fnamestr_HOSP snamestr_HOSP sex firstname
egen long name_id = group(namestr_HOSP fnamestr_HOSP snamestr_HOSP sex), missing
egen obs_id = seq(), by(namestr_HOSP fnamestr_HOSP snamestr_HOSP sex)
reshape wide firstname phx_fname fname_orig_HOSP fname_edit_HOSP, i(name_id) j(obs_id)
drop name_id
compress
save "$PROJ_PATH/processed/temp/firstnames.dta", replace

* Extract surnames
use namestr_HOSP fnamestr_HOSP snamestr_HOSP sname_HOSP alt_sn_HOSP using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", clear
bysort namestr_HOSP fnamestr_HOSP snamestr_HOSP sname_HOSP alt_sn_HOSP: keep if _n == 1

rename sname_HOSP surname1
rename alt_sn_HOSP surname2
gen long obs_id = _n
reshape long surname, i(obs_id) j(new_id)
drop obs_id new_id
egen temp = total(surname != ""), by(namestr_HOSP fnamestr_HOSP snamestr_HOSP)
drop if temp > 0 & surname == ""
drop temp

* Split surname if "OR" format
split surname, parse("-OR-") gen(surname)
drop surname
gen long obs_id = _n
reshape long surname, i(obs_id) j(new_id)
drop obs_id new_id
egen temp = total(surname != ""), by(namestr_HOSP fnamestr_HOSP snamestr_HOSP)
drop if temp > 0 & surname == ""
drop temp

***** Create phonex code
gen tophonex = surname
do "$PROJ_PATH/scripts/code/1_build/_name_cleanup/_phonex.do"
rename phonexed phx_sname
drop tophonex

sort namestr_HOSP fnamestr_HOSP snamestr_HOSP surname
keeporder namestr_HOSP fnamestr_HOSP snamestr_HOSP surname phx_sname
egen long name_id = group(namestr_HOSP fnamestr_HOSP snamestr_HOSP), missing
egen obs_id = seq(), by(namestr_HOSP fnamestr_HOSP snamestr_HOSP)
reshape wide surname phx_sname, i(name_id) j(obs_id)
drop name_id
compress
save "$PROJ_PATH/processed/temp/surnames.dta", replace

* Load matching variables

use regid namestr_HOSP fnamestr_HOSP snamestr_HOSP sex_HOSP byr_lb_HOSP byr_ub_HOSP bdate* using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta" if byr_ub_HOSP >= `byr_start' & byr_lb_HOSP <= `byr_end', clear
drop byr*
rename sex_HOSP sex

* Reshape sex
gen missing_sex = (sex == .)
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

merge m:1 sex namestr_HOSP fnamestr_HOSP snamestr_HOSP using "$PROJ_PATH/processed/temp/firstnames.dta", keep(3) nogen 
merge m:1 namestr_HOSP fnamestr_HOSP snamestr_HOSP using "$PROJ_PATH/processed/temp/surnames.dta", keep(3) nogen keepusing(phx_sname* surname*)

* Reshape firstname
save "$PROJ_PATH/processed/temp/reshape_fname_inprog.dta", replace
keep if firstname2 != ""
gen long obs_id = _n
reshape long firstname phx_fname fname_orig_HOSP fname_edit_HOSP, i(obs_id) j(new_id)
drop if firstname == ""
drop obs_id new_id
save "$PROJ_PATH/processed/temp/reshape_fname_multiple.dta", replace

use "$PROJ_PATH/processed/temp/reshape_fname_inprog.dta", clear
keep if firstname2 == ""
rename firstname1 temp_firstname
rename phx_fname1 temp_phx
rename fname_orig_HOSP1 temp_fname_orig_HOSP
rename fname_edit_HOSP1 temp_fname_edit_HOSP
drop firstname* phx_fname* fname_orig* fname_edit*
rename temp_firstname firstname
rename temp_phx phx_fname
rename temp_fname_orig_HOSP fname_orig_HOSP 
rename temp_fname_edit_HOSP fname_edit_HOSP 
append using "$PROJ_PATH/processed/temp/reshape_fname_multiple.dta"
drop if length(firstname) <= 1
drop firstname 
rm "$PROJ_PATH/processed/temp/reshape_fname_inprog.dta"
rm "$PROJ_PATH/processed/temp/reshape_fname_multiple.dta"

* Reshape surname
save "$PROJ_PATH/processed/temp/reshape_sname_inprog.dta", replace
keep if surname2 != ""
gen long obs_id = _n
reshape long surname phx_sname, i(obs_id) j(new_id)
drop if surname == ""
drop obs_id new_id
save "$PROJ_PATH/processed/temp/reshape_sname_multiple.dta", replace

use "$PROJ_PATH/processed/temp/reshape_sname_inprog.dta", clear
keep if surname2 == ""
rename surname1 temp_surname
rename phx_sname1 temp_phx
drop surname* phx_sname*
rename temp_surname surname
rename temp_phx phx_sname
append using "$PROJ_PATH/processed/temp/reshape_sname_multiple.dta"
drop if length(surname) <= 1
drop *namestr*
rm "$PROJ_PATH/processed/temp/reshape_sname_inprog.dta"
rm "$PROJ_PATH/processed/temp/reshape_sname_multiple.dta"

order sex bdate*, last
gen age = floor((mdy(`census_month',`census_day',`census_year') - bdate_lb_HOSP)/365.25)
drop bdate*
rename surname surname_HOSP

duplicates drop
sort regid surname_HOSP fname_orig_HOSP fname_edit_HOSP sex age phx_fname phx_sname

save "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`census_year'/match_input_hosp_criteria.dta", replace

* Restrict to blocking variables
keep phx* age sex
bysort phx_sname phx_fname age sex: keep if _n == 1
drop if phx_sname == "000" & phx_fname == "000"
save "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`census_year'/match_input_hosp_blocking.dta", replace

rm "$PROJ_PATH/processed/temp/firstnames.dta"
rm "$PROJ_PATH/processed/temp/surnames.dta"

disp "DateTime: $S_DATE $S_TIME"

* EOF
