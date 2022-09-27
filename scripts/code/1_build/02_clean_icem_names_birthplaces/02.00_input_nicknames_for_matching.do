version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 02.00_input_nicknames_for_matching.do
* PURPOSE: This do file loads the crosswalk file with nicknames for matching
************

// Update nicknames for matching

import delim using "$PROJ_PATH/raw/names/nicknames_for_matching.csv", varnames(1) clear 

replace sex = "1" if sex == "Male"
replace sex = "2" if sex == "Female"
destring sex, replace
label define sex_lab 1 "Male" 2 "Female", replace
la val sex sex_lab

save "$PROJ_PATH/processed/intermediate/names/nicknames_for_matching.dta", replace

disp "DateTime: $S_DATE $S_TIME"

* EOF
