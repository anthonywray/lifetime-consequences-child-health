version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 05_census_hospital_record_linkage.do
* PURPOSE: This do file runs the do files in the scripts folder /05_census_hospital_record_linkage/
************

// Extract hospital matching variables: Match to I-CeM 1881 census

local byr_start		1869
local byr_end 		1883
local census_month	4
local census_day 	3
local census_year	1881

do "$PROJ_PATH/scripts/code/1_build/05_census_hospital_record_linkage/05.01_extract_hospital_matching_vars.do" `byr_start' `byr_end' `census_month' `census_day' `census_year'

// Extract hospital matching variables: Match to I-CeM 1891 census

local byr_start		1869
local byr_end 		1893	
local census_month	4
local census_day 	5
local census_year	1891

do "$PROJ_PATH/scripts/code/1_build/05_census_hospital_record_linkage/05.01_extract_hospital_matching_vars.do" `byr_start' `byr_end' `census_month' `census_day' `census_year'

// Extract hospital matching variables: Match to I-CeM 1901 census

local byr_start		1879
local byr_end 		1903
local census_month	3
local census_day 	31
local census_year	1901

do "$PROJ_PATH/scripts/code/1_build/05_census_hospital_record_linkage/05.01_extract_hospital_matching_vars.do" `byr_start' `byr_end' `census_month' `census_day' `census_year'

// Extract hospital matching variables: Match to I-CeM 1911 census

local byr_start		1889
local byr_end 		1913
local census_month	4
local census_day 	2
local census_year	1911

do "$PROJ_PATH/scripts/code/1_build/05_census_hospital_record_linkage/05.01_extract_hospital_matching_vars.do" `byr_start' `byr_end' `census_month' `census_day' `census_year'

// Link I-CeM census records to hospital admission records

forvalues year = 1881(10)1911 {
	do "$PROJ_PATH/scripts/code/1_build/05_census_hospital_record_linkage/05.02_icem_hosp_matching.do" `year'
}

disp "DateTime: $S_DATE $S_TIME"

* EOF
