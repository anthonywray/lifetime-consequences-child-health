version 14

disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 04.00_input_london_district_list.do
* PURPOSE: Collect district names for London to rename county from Middlesex to London
************

import excel using "$PROJ_PATH/raw/geography/UK_crosswalk.xls", firstrow clear 
keep if divisngb == "London"
keep rgdistgb
rename rgdistgb district
replace district = proper(district)
duplicates drop
sort district
tab district
save "$PROJ_PATH/processed/intermediate/geography/london_district_list.dta", replace

disp "DateTime: $S_DATE $S_TIME"
