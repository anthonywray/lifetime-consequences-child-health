*****************************************************
* OVERVIEW
*	FILE: 0_run_all_xps.do
*    in "Lifetime and intergenerational consequences of poor childhood health" 
* 	AUTHORS: Krzysztof Karbownik and Anthony Wray
*	CONTACT: krzysztof.karbownik@emory.edu, wray@sam.sdu.dk
* 	JOURNAL: Journal of Human Resources
*	VERSION: July 2022

* DESCRIPTION
* 	This script replicates the analysis in our paper and online appendix
*   All raw data are stored in /raw
*   All code is stored in /scripts 
*   All tables and figures in the paper are outputted to /output/01_paper
*   All appendix tables and figures are outputted to /output/02_appendix
* 
* SOFTWARE REQUIREMENTS
*   Analyses run on Windows using Stata version 17 (set to version 14 or 12)
*
* TO PERFORM A CLEAN RUN, DELETE THE FOLLOWING TWO FOLDERS:
*   /processed
*   /output

*****************************************************
// Clear stored objects and set preferences
clear all
matrix drop _all // Drop everything in mata
set more off
set varabbrev off

*****************************************************
// Global macros for file paths

global username 	"Anthony"
global root_path 	"D:/Users/${username}/GitHub"
global PROJ_PATH 	"$root_path/london_hospitals/replication"	

*****************************************************
// Create project directories 
cap mkdir "$PROJ_PATH/output"
cap mkdir "$PROJ_PATH/output/01_paper"
cap mkdir "$PROJ_PATH/output/02_appendix"
cap mkdir "$PROJ_PATH/processed"
cap mkdir "$PROJ_PATH/processed/data"
cap mkdir "$PROJ_PATH/processed/intermediate"
cap mkdir "$PROJ_PATH/processed/intermediate/crosswalks"
cap mkdir "$PROJ_PATH/processed/intermediate/diseases"
cap mkdir "$PROJ_PATH/processed/intermediate/final_build"
cap mkdir "$PROJ_PATH/processed/intermediate/geography"
cap mkdir "$PROJ_PATH/processed/intermediate/hospitals"
cap mkdir "$PROJ_PATH/processed/intermediate/hospitals/hharp"
cap mkdir "$PROJ_PATH/processed/intermediate/icem"
cap mkdir "$PROJ_PATH/processed/intermediate/icem/child_vars"
cap mkdir "$PROJ_PATH/processed/intermediate/icem/head_vars"
cap mkdir "$PROJ_PATH/processed/intermediate/icem/household_ids"
cap mkdir "$PROJ_PATH/processed/intermediate/icem/mom_vars"
cap mkdir "$PROJ_PATH/processed/intermediate/icem/pop_vars"
cap mkdir "$PROJ_PATH/processed/intermediate/icem/self_vars"
cap mkdir "$PROJ_PATH/processed/intermediate/icem/sibling_ids"
cap mkdir "$PROJ_PATH/processed/intermediate/icem/spouse_vars"
cap mkdir "$PROJ_PATH/processed/intermediate/icem_linked_fathers"
cap mkdir "$PROJ_PATH/processed/intermediate/names"
cap mkdir "$PROJ_PATH/processed/intermediate/occupations"
cap mkdir "$PROJ_PATH/processed/temp"

forvalues t_1 = 1881(10)1901 {
	local t_max = 1911 - `t_1'
	forvalues gap = 10(10)`t_max' {
		local t_2 = `t_1' + `gap'
		cap mkdir "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'"
		cap mkdir "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'"
	}
 	
}

forvalues year = 1881(10)1911 {
	cap mkdir "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`year'"
	cap mkdir "$PROJ_PATH/processed/temp/icem_hosp_linkage_`year'"	
}
		
// Initialize log and record system parameters
cap log close
set linesize 255 // Specify screen width for log files
local datetime : di %tcCCYY.NN.DD!_HH.MM.SS `=clock("$S_DATE $S_TIME", "DMYhms")'
local logfile "$PROJ_PATH/scripts/logs/log_`datetime'.txt"
log using "`logfile'", text

di "Begin date and time: $S_DATE $S_TIME"
di "Stata version: `c(stata_version)'"
di "Updated as of: `c(born_date)'"
di "Variant:       `=cond( c(MP),"MP",cond(c(SE),"SE",c(flavor)) )'"
di "Processors:    `c(processors)'"
di "OS:            `c(os)' `c(osdtl)'"
di "Machine type:  `c(machine_type)'"

// Set version
version 14

*****************************************************

// Disable locally installed Stata programs
cap adopath - PERSONAL
cap adopath - PLUS
cap adopath - SITE
cap adopath - OLDPLACE

// Define a local installation directory for the packages
net set ado "$PROJ_PATH/scripts/libraries/stata/"

adopath ++ "$PROJ_PATH/scripts/libraries/stata"
adopath ++ "$PROJ_PATH/scripts/programs"

// Build new list of libraries to be searched
mata: mata mlib index

*****************************************************
// Build project data
*****************************************************
local build_data 		1
local build_analysis 	1
local run_analysis		1

if `build_data' {
	
	// Extract I-CeM census variables 
	do "$PROJ_PATH/scripts/code/1_build/01_extract_icem_census_data.do"

	// Extract and clean I-CeM names and birth places 
	do "$PROJ_PATH/scripts/code/1_build/02_clean_icem_names_birthplaces.do"

	// Link I-CeM censuses
	do "$PROJ_PATH/scripts/code/1_build/03_icem_census_linkage.do"

	// Extract and clean hospital data 
	do "$PROJ_PATH/scripts/code/1_build/04_extract_hospital_data.do"

	// Census-hospital record linkage
	do "$PROJ_PATH/scripts/code/1_build/05_census_hospital_record_linkage.do"

}

if `build_analysis' {

	// Set up analysis data
	do "$PROJ_PATH/scripts/code/1_build/06_build_analysis_data.do"

}

*****************************************************
// Run project analysis
*****************************************************

if `run_analysis' {

	// Run analysis for paper
	do "$PROJ_PATH/scripts/code/2_analysis/01_tables_figures.do"

	// Run analysis for online appendix 
	do "$PROJ_PATH/scripts/code/2_analysis/02_online_appendix.do"
	
	// Reproduce in-text statistics
	do "$PROJ_PATH/scripts/code/2_analysis/03_intext_statistics.do"
	
}

*****************************************************
// End log

di "End date and time: $S_DATE $S_TIME"
log close

*****************************************************

** EOF
