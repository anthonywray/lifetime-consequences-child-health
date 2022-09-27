version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 01_extract_icem_self_variables.do
* PURPOSE: This do file extracts the variables used for each individual from the I-CeM data
************

args y 

// I-CeM data are stored separately by county. The list of counties differs by census year.

local county_list_1881 "Bedfordshire Berkshire Buckinghamshire Cambridgeshire Cheshire Cornwall Cumberland Derbyshire Devon Dorset Durham Essex Gloucestershire Hampshire Herefordshire Hertfordshire Huntingdonshire Kent Lancashire Leicestershire Lincolnshire London Middlesex Norfolk Northamptonshire Northumberland Nottinghamshire Oxfordshire RoyalNavy Rutland Shropshire Somerset Staffordshire Suffolk Surrey Sussex Wales Warwickshire Westmorland Wiltshire Worcestershire Yorkshire"

local county_list_1891 "Bedfordshire Berkshire Buckinghamshire Cambridgeshire Cheshire Cornwall Cumberland Derbyshire Devon Dorset Durham Essex Gloucestershire Hampshire Herefordshire Hertfordshire Huntingdonshire Kent Lancashire Leicestershire Lincolnshire London Middlesex Norfolk Northamptonshire Northumberland Nottinghamshire Oxfordshire Rutland Shropshire Somerset Staffordshire Suffolk Surrey Sussex Wales Warwickshire Westmorland Wiltshire Worcestershire Yorkshire"

local county_list_1901 "Bedfordshire Berkshire Buckinghamshire Cambridgeshire Cheshire Cornwall Cumberland Derbyshire Devon Dorset Durham Essex Gloucestershire Hampshire Herefordshire Hertfordshire Huntingdonshire Kent Lancashire Leicestershire Lincolnshire London Middlesex Norfolk Northamptonshire Northumberland Nottinghamshire Oxfordshire RoyalNavy Rutland Shropshire Somerset Staffordshire Suffolk Surrey Sussex Wales Warwickshire Westmorland Wiltshire Worcestershire Yorkshire"

local county_list_1911 "Bedfordshire Berkshire Buckinghamshire Cambridgeshire Cheshire Cornwall Derbyshire Devon Dorset Durham Essex Gloucestershire Hampshire Herefordshire Hertfordshire Huntingdonshire Kent Lancashire Leicestershire Lincolnshire London Middlesex Military Norfolk Northamptonshire Northumberland Nottinghamshire Oxfordshire RoyalNavy Rutland Shropshire Somerset Staffordshire Suffolk Surrey Sussex Wales Warwickshire Westmorland Wiltshire Worcestershire Yorkshire"

*********************************************************************************************************************
*********** I-CeM: Self variables *************
*********************************************************************************************************************

// For each county extract the variables we need

foreach county of local county_list_`y' {
	
	if `y' != 1911 {
		
		use h ParID pid RecID Year ConParID RegCnty RegDist Parish Age Sex Rela Mar DisCode1 DisCode2 ///
			Bpstring Cnti BpCtry HollerB Ctry hisco Occode Occ Mother f_Off m_Off ///
		using "$PROJ_PATH/raw/icem/England_`y'_`county'.dta", clear
		
		order h ParID pid RecID Year ConParID RegCnty RegDist Parish Age Sex Rela Mar DisCode1 DisCode2 ///
			Bpstring Cnti BpCtry HollerB Ctry hisco Occode Occ Mother f_Off m_Off  
			
	}
	else {
		
		use h ParID pid RecID Year ConParID RegCnty RegDist Parish Age Sex Rela Mar DisCode1 DisCode2 ///
			Bpstring Cnti BpCtry HollerB Ctry hisco Occode HollerOcc Occ ChildrenCode hhd ChildTot Mother f_Off m_Off ///
		using "$PROJ_PATH/raw/icem/England_`y'_`county'.dta", clear
		
		order h ParID pid RecID Year ConParID RegCnty RegDist Parish Age Sex Rela Mar DisCode1 DisCode2 ///
			Bpstring Cnti BpCtry HollerB Ctry hisco Occode HollerOcc Occ ChildrenCode hhd ChildTot Mother f_Off m_Off
			
		tostring ChildrenCode, replace
		destring ChildTot ConParID, replace
	}
	
	tostring DisCode1, replace 
	destring DisCode2, replace
	
	destring Age, replace
	
	replace Age = floor(Age)

	replace Sex = "1" if Sex == "M"
	replace Sex = "2" if Sex == "F"
	replace Sex = "9" if Sex == "U"
	
	destring Sex, replace
	
	label define Sexlab 1 "Male" 2 "Female" 9 "Unknown"
	la val Sex Sexlab
	
	destring hisco, replace
	
	// Raw data are pipe delimited. 
		* Some observations are not loaded into Stata correctly and combine multiple variables in one cell
		* For the occupation and birth place variables, we keep the first part of the string
		
	gen pipepos = strpos(Occ,"|")
	replace Occ = substr(Occ,1,pipepos-1) if pipepos > 0
	drop pipepos
	
	gen pipepos = strpos(Bpstring,"|")
	replace Bpstring = substr(Bpstring,1,pipepos-1) if pipepos > 0
	drop pipepos
	compress
	
	// Some variables are not labeled correctly 
	rename Mother sploc
	rename f_Off poploc
	rename m_Off momloc
	
	destring sploc poploc momloc, replace
	
	gsort RecID
	save "$PROJ_PATH/processed/temp/icem_self_`y'_`county'.dta", replace
}

// Append county-specific files to create big file for each census year
		
clear

foreach county of local county_list_`y' {
	append using "$PROJ_PATH/processed/temp/icem_self_`y'_`county'.dta"
}

count 
if `y' == 1881 assert r(N) == 26124585
if `y' == 1891 assert r(N) == 29509255
if `y' == 1901 assert r(N) == 32493318
if `y' == 1911 assert r(N) == 36353455

gisid RecID
gsort RecID

save "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'.dta", replace

// Remove temp files
foreach county of local county_list_`y' {
	rm "$PROJ_PATH/processed/temp/icem_self_`y'_`county'.dta"
}

// Save each group of variables to separate files
clear
    
// ID variables
use RecID Year h ParID pid using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'.dta", clear
save "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_identifiers.dta", replace

// Residence
use RecID Year ConParID RegCnty RegDist Parish using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'.dta", clear
save "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_residence.dta", replace

// Demographic
use RecID Year Age Sex Rela Mar using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'.dta", clear
save "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_demographic.dta", replace

// Birth Place
use RecID Year Bpstring Cnti BpCtry HollerB Ctry using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'.dta", clear
compress Bpstring Cnti BpCtry HollerB Ctry
save "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_birthplace.dta", replace

// Occupation
use RecID Year hisco Occode Occ using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'.dta", clear
save "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_occupation.dta", replace

// Children alive or dead
if `y' == 1911 {
	use RecID Year ChildrenCode hhd ChildTot using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_1911.dta", clear
	save "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_1911_childalive.dta", replace
}

// Parents' location
use RecID Year poploc momloc sploc using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'.dta", clear
save "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_parents.dta", replace

// Disability
use RecID Year DisCode1 DisCode2 using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'.dta", clear

gen disability_string = DisCode1

replace disability_string = "0000000" if disability_string == "."
replace disability_string = "0" + disability_string if length(disability_string) == 6
replace disability_string = "00" + disability_string if length(disability_string) == 5
replace disability_string = "000" + disability_string if length(disability_string) == 4
replace disability_string = "0000" + disability_string if length(disability_string) == 3
replace disability_string = "00000" + disability_string if length(disability_string) == 2
replace disability_string = "000000" + disability_string if length(disability_string) == 1

gen disab_visual = substr(disability_string,1,1)
gen disab_hearing = substr(disability_string,2,1)
gen disab_idiocy = substr(disability_string,3,1)
gen disab_lunacy = substr(disability_string,4,1)
gen disab_other = substr(disability_string,5,1)

destring disab_visual disab_hearing disab_idiocy disab_lunacy disab_other, replace
drop DisCode1 disability_string

gen disab_physical = (DisCode2 == 180 | DisCode2 == 280 | DisCode2 == 380 | DisCode2 == 580 | DisCode2 == 680 | DisCode2 == 780 | DisCode2 == 800 | DisCode2 == 804)

egen disab_any = rowmax(disab_visual disab_hearing disab_idiocy disab_lunacy disab_other disab_physical)

drop disab_visual disab_hearing disab_idiocy disab_lunacy disab_other disab_physical DisCode2

gsort RecID
save "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_disability.dta", replace

rm "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'.dta"

disp "DateTime: $S_DATE $S_TIME"

* EOF
