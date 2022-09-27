version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 03.02_icem_blocking_setup.do
* PURPOSE: This do file sets up the data prior to blocking
************

args t_1 t_2 

*********************************************************************************************************************
*********** I-CeM Blocking Setup *************
*********************************************************************************************************************

* Create blocking input file that restricts to blocking variables

use "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/match_input_`t_1'_criteria.dta", clear 
drop if bcounty == "" | bcounty == "UNK" | bcounty == "ZZZ" | bcounty == "CHI" | bcounty == "ENG" | bcounty == "IRL" | bcounty == "SCT" | bcounty == "WAL"
keep phx_sname phx_fname age sex bcounty
bysort phx_sname phx_fname age sex bcounty: keep if _n == 1
tab bcounty, m 
save "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/match_input_`t_1'_blocking.dta", replace

use "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/match_input_`t_2'_criteria.dta", clear 
drop if bcounty == "" | bcounty == "UNK" | bcounty == "ZZZ" | bcounty == "CHI" | bcounty == "ENG" | bcounty == "IRL" | bcounty == "SCT" | bcounty == "WAL"
keep phx_sname phx_fname age sex bcounty
bysort phx_sname phx_fname age sex bcounty: keep if _n == 1
tab bcounty, m 
save "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/match_input_`t_2'_blocking.dta", replace

* Create blocking file for ICEM childhood to ICEM adulthood

use "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/match_input_`t_1'_blocking.dta", clear
rename age age_base

tempfile age_input
save `age_input', replace

gen age = age_base
tempfile age_output
save `age_output', replace

forvalues z = 1(1)5 {
	use `age_input', clear
	gen age = age_base - `z'
	append using `age_output'
	tempfile age_output
	save `age_output', replace
	
}
forvalues z = 1(1)5 {
	use `age_input', clear
	gen age = age_base + `z'
	append using `age_output'
	tempfile age_output
	save `age_output', replace
	
}

sort phx_sname phx_fname age_base sex bcounty age 
save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/blocking_inprog.dta", replace

keep phx_sname phx_fname age sex bcounty
duplicates drop 
bysort phx_sname phx_fname age sex bcounty: keep if _n == 1

merge 1:m phx_sname phx_fname age sex bcounty using "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/match_input_`t_2'_blocking.dta", keep(3) nogen keepusing(phx_sname phx_fname age sex bcounty)

duplicates drop 
bysort phx_sname phx_fname age sex bcounty: keep if _n == 1
save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/matched_blocks.dta", replace

merge 1:m phx_sname phx_fname age sex bcounty using "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/match_input_`t_2'_criteria.dta", keep(3) nogen

duplicates drop
sort phx_sname phx_fname age sex bcounty surname_`t_2' fname_edit_`t_2' fname_orig_`t_2' RecID_`t_2'
save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/match_candidates_`t_2'.dta", replace

use "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/blocking_inprog.dta", clear
merge m:1 phx_sname phx_fname age sex bcounty using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/matched_blocks.dta", keep(3) nogen
drop age
rename age_base age

keep phx_sname phx_fname age sex bcounty
duplicates drop 
bysort phx_sname phx_fname age sex bcounty: keep if _n == 1

merge 1:m phx_sname phx_fname age sex bcounty using "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/match_input_`t_1'_criteria.dta", keep(3) nogen

duplicates drop
sort phx_sname phx_fname age sex bcounty surname_`t_1' fname_edit_`t_1' fname_orig_`t_1' RecID_`t_1'
save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/match_candidates_`t_1'.dta", replace

rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/blocking_inprog.dta"
rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/matched_blocks.dta"

disp "DateTime: $S_DATE $S_TIME"

* EOF 
