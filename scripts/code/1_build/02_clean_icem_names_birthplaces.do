version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 02_clean_icem_names_birthplaces.do
* PURPOSE: This do file runs the do files in the scripts folder /02_clean_icem_names_birthplaces/
************

// Input nicknames for matching
do "$PROJ_PATH/scripts/code/1_build/02_clean_icem_names_birthplaces/02.00_input_nicknames_for_matching.do"

// Extract and clean I-CeM names for each census year 

forvalues year = 1881(10)1911 {
	do "$PROJ_PATH/scripts/code/1_build/02_clean_icem_names_birthplaces/02.01_icem_extract_names.do" `year'
}

// Tabulate name frequencies
do "$PROJ_PATH/scripts/code/1_build/02_clean_icem_names_birthplaces/02.02_icem_name_distribution.do" 1881 1911

// Clean I-Cem birth places
do "$PROJ_PATH/scripts/code/1_build/02_clean_icem_names_birthplaces/02.03_icem_birthplace_cleanup.do"

disp "DateTime: $S_DATE $S_TIME"

* EOF 
