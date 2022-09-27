version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 04_extract_hospital_data.do
* PURPOSE: This do file runs the do files in the scripts folder /04_extract_hospital_data/
************

// Clean hospital records: Clean the raw CSV files containing the hospital patient data for Barts, HHARP, GOSH, and Guys

// Create London district list
do "$PROJ_PATH/scripts/code/1_build/04_extract_hospital_data/04.00_input_london_district_list.do"

// Clean HHARP hospital data
do "$PROJ_PATH/scripts/code/1_build/04_extract_hospital_data/04.01_clean_hharp_data.do"

// Combine hospital data
do "$PROJ_PATH/scripts/code/1_build/04_extract_hospital_data/04.02_combine_hospital_data.do"

// Clean addresses in admissions data
do "$PROJ_PATH/scripts/code/1_build/04_extract_hospital_data/04.03_clean_residential_addresses.do"

// Clean cause of admission data 
do "$PROJ_PATH/scripts/code/1_build/04_extract_hospital_data/04.04_clean_cause_of_admission.do"

// Construct health deficiency index (HDI) and compile final hospital data
do "$PROJ_PATH/scripts/code/1_build/04_extract_hospital_data/04.05_create_health_deficiency_index.do"

disp "DateTime: $S_DATE $S_TIME"

* EOF
