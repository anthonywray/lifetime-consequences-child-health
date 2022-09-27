version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 03.01_extract_icem_matching_vars.do
* PURPOSE: This do file extract the variables needed for linking from the I-CeM complete count data 
************

args t_1 t_2 year age_lb age_ub

* Load matching variables

use RecID Age Sex Mar using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`year'_demographic.dta" if Age >= `age_lb' & Age <= `age_ub', clear
merge 1:1 RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`year'_birthplace.dta", assert(2 3) keep(3) nogen keepusing(Bpstring Cnti BpCtry Ctry)
replace BpCtry = "UNK" if BpCtry == "ZZZ"
recast str Cnti 

* Rename ICEM variables
rename Age age 
rename Sex sex
rename Mar marst
rename BpCtry cnti
rename Ctry alt_cnti
rename Cnti std_par

* Merge with re-coded birth parish strings

merge m:1 Bpstring std_par cnti alt_cnti using "$PROJ_PATH/processed/intermediate/geography/icem_bpstring_xwk.dta", keep(1 3) 
replace std_par1 = std_par if _merge == 1
replace bcounty1 = cnti if _merge == 1
replace bcounty2 = alt_cnti if _merge == 1
drop _merge Bpstring std_par cnti alt_cnti primary_county*

* Reshape multiple versions of birth county and parish

replace std_par2 = std_par1 if std_par2 == "" & bcounty2 != ""
save "$PROJ_PATH/processed/temp/cnti_reshape_input.dta", replace
keep if std_par2 == ""
rename std_par1 temp_std_par
rename bcounty1 temp_bcounty
drop std_par* bcounty*
rename temp_std_par std_par
rename temp_bcounty bcounty
save "$PROJ_PATH/processed/temp/cnti_reshape_unique.dta", replace

use "$PROJ_PATH/processed/temp/cnti_reshape_input.dta", clear
keep if std_par2 != ""
gen long obs_id = _n
reshape long std_par bcounty, i(obs_id) j(new_id)
drop obs_id new_id
drop if bcounty == ""
append using "$PROJ_PATH/processed/temp/cnti_reshape_unique.dta"

rm "$PROJ_PATH/processed/temp/cnti_reshape_unique.dta"
rm "$PROJ_PATH/processed/temp/cnti_reshape_input.dta"

sort RecID bcounty std_par

* Recode London as county

merge m:1 std_par using "$PROJ_PATH/processed/intermediate/geography/icem_london_std_par.dta", keep(1 3)
replace bcounty = "LND" if (bcounty == "KEN" | bcounty == "MDX" | bcounty == "SRY") & _merge == 3
drop _merge std_par

keep RecID age sex marst bcounty
bysort RecID age sex marst bcounty: keep if _n == 1

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

* Add names
merge m:1 RecID using "$PROJ_PATH/raw/icem_sl/ICEM_Names_EW_`year'.dta", assert(2 3) keep(3) nogen keepusing(Pname Oname Sname)
recast str Oname Sname
merge m:1 Pname Oname sex using "$PROJ_PATH/processed/intermediate/names/firstnames_`year'.dta", keep(3) nogen
merge m:1 Sname using "$PROJ_PATH/processed/intermediate/names/surnames_`year'.dta", keep(3) nogen keepusing(phx_sname* surname*)

* Reshape firstname
save "$PROJ_PATH/processed/temp/reshape_fname_inprog.dta", replace
keep if firstname2 != ""
gen long obs_id = _n
reshape long firstname phx_fname, i(obs_id) j(new_id)
drop if firstname == ""
drop obs_id new_id
save "$PROJ_PATH/processed/temp/reshape_fname_multiple.dta", replace

use "$PROJ_PATH/processed/temp/reshape_fname_inprog.dta", clear
keep if firstname2 == ""
rename firstname1 temp_firstname
rename phx_fname1 temp_phx
drop firstname* phx_fname*
rename temp_firstname firstname
rename temp_phx phx_fname
append using "$PROJ_PATH/processed/temp/reshape_fname_multiple.dta"
drop if length(fname_orig) <= 1
drop firstname Pname Oname
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
rename surname1 temp_sname
rename phx_sname1 temp_phx
drop surname* phx_sname*
rename temp_sname surname
rename temp_phx phx_sname
append using "$PROJ_PATH/processed/temp/reshape_sname_multiple.dta"
drop if length(surname) <= 1
drop Sname

rm "$PROJ_PATH/processed/temp/reshape_sname_inprog.dta"
rm "$PROJ_PATH/processed/temp/reshape_sname_multiple.dta"

* Redefine age variable to be age in outcome census year

replace age = age + (`t_2' - `year')

* Rename matching variables (names)

rename fname_orig fname_orig_`year'
rename fname_edit fname_edit_`year'
rename surname surname_`year'
rename RecID RecID_`year'

keeporder RecID* age sex fname* surname* phx* bcounty

duplicates drop
unique RecID* age sex fname* surname* phx* bcounty
sort RecID* age sex fname* surname* phx* bcounty
	
save "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/match_input_`year'_criteria.dta", replace

disp "DateTime: $S_DATE $S_TIME"

* EOF
