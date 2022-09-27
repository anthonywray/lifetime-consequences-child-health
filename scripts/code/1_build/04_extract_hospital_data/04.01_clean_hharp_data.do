version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 04.01_clean_hharp_data.do
* PURPOSE: This do file compiles and cleans the raw data from the Historical Hospital Admission Records Project (HHARP)
************

use "$PROJ_PATH/raw/hharp/hharp_hospital_admissions.dta", clear

* Clean admission and discharge dates
gen admityr = regexs(1) if regexm(admissiondate, "([1-9][0-9][0-9][0-9])$")
gen dischyr = regexs(1) if regexm(dischargedate, "([1-9][0-9][0-9][0-9])$")
destring admityr dischyr, replace

* Fix a typo
replace admissiondate = regexr(admissiondate,"2o ", "20 ")
gen admitday = regexs(1) if regexm(admissiondate, "^([0-9]+)")
gen admitmon =regexs(1) if regexm(admissiondate, "([a-zA-Z]+)")

replace admitmon = "1" if admitmon == "January"
replace admitmon = "2" if admitmon == "February"
replace admitmon = "3" if admitmon == "March"
replace admitmon = "4" if admitmon == "April"
replace admitmon = "5" if admitmon == "May"
replace admitmon = "6" if admitmon == "June" | admitmon == "june"
replace admitmon = "7" if admitmon == "July"
replace admitmon = "8" if admitmon == "August"
replace admitmon = "9" if admitmon == "September"
replace admitmon = "10" if admitmon == "October" | admitmon == "october"
replace admitmon = "11" if admitmon == "November"
replace admitmon = "12" if admitmon == "December"

destring admitday admitmon, replace
replace admitday = . if admitday > 31
drop admissiondate
gen admissiondate = mdy(admitmon, admitday, admityr)
format admissiondate %td

gen dischday = regexs(1) if regexm(dischargedate, "^([0-9][0-9])")
gen dischmon = regexs(1) if regexm(dischargedate, "\/([0-9][0-9])\/")
destring dischday dischmon dischyr, replace
drop dischargedate
gen dischargedate = mdy(dischmon, dischday, dischyr)
format dischargedate %td

recode agemonths (mis = 0)

replace address1 = regexr(address1,"¢","c")
replace address1 = regexr(address1,"½"," 1/2")
replace address1 = regexr(address1,"6 1/2 Alex Place, Clerkenwell","6 1/2 Alex. Place, Clerkenwell")
replace address1 = regexr(address1,"Putney, ValeSide, Surrey Side, Surrey","Putney, Vale Side, Surrey")
replace address1 = regexr(address1,"46b Hayes Mews  Berkeley Sq.","45b Hayes Mews  Berkeley Sq.")
replace duration = "Cong." if firstname == "Ebenezer" & surname == "Gray"
replace surname = "Johnson" if surname == "Johnson ohnson"
replace surname = "Merritt" if surname == "Merritt erritt"
replace surname = "Du Pre" if surname == "Du PrÞ"
replace surname = "Rose" if surname == "Rose/Rowe"
replace surname = "Van Wylwyk" if surname == "Van  Wylwyk"
replace surname = "McCarthy" if surname == "Mc.Carthy"
replace surname = "McIsaac" if surname == "Mc Isaac"
replace diseaseinregister = "Morbus coxae" if diseaseinregister == "\015\012orbus coxae"
replace diseaseinregister = "Disease of knee joint" if diseaseinregister == "Disease of knee joint \253"
replace diseaseinregister = "Debility after measles" if diseaseinregister == "Debility after measles\015\012debility after measles"

foreach var of varlist postmortem treatment cause occupationofparents infantilediseasehistory remarks address1-address5 admittingdoctor {
	replace `var' = "" if `var' == "."
}
duplicates drop

gen long pid_temp = _n

// Clean names

drop standardfirstnameadded

replace firstname = "" if firstname == "[anon]"
replace surname = "" if surname == "[anon]"

replace firstname = "Kesse" if firstname == "KeSse"
replace firstname = "Lilian" if firstname == "LilIan"
replace firstname = "" if firstname == "(Baby)"
replace firstname = "Winifred" if firstname == "Baby (Winifred)"
replace firstname = "Oliver" if firstname == "Baby (Oliver)"
replace firstname = "Alfred Reginald" if firstname == "Alfred (? Reginald)"

replace surname = "Pearson (Grierson)" if surname == "Pearson / Grierson"
replace surname = "North (Watts)" if surname == "North (? Watts)"
replace surname = "Dog" if surname == "(Dog)"
replace surname = "Moore" if surname == "Moore (Leslie Shepherd see No 2707)"

rename firstname fnamestr
rename surname snamestr

gen fn = fnamestr 
qui replace fn = upper(fn)

qui replace fn = subinstr(fn,"."," ",.)
qui replace fn = subinstr(fn,"    "," ",.)
qui replace fn = subinstr(fn,"   "," ",.)
qui replace fn = subinstr(fn,"  "," ",.)
qui replace fn = subinstr(fn,"  "," ",.)
qui replace fn = trim(fn)

local symbol_list "! @ # $ % ^ & * ' ( ) / \ : ; | ~ ` < > , ? { } = + [ ] - _"
foreach symbol of local symbol_list {
	qui replace fn = subinstr(fn,"`symbol'"," ",.)
}
qui replace fn = subinstr(fn,"  "," ",.)
qui replace fn = subinstr(fn,"  "," ",.)
qui replace fn = trim(fn)

qui replace fn = regexr(fn,"INFANT","")
qui replace fn = regexr(fn,"BABY","")
qui replace fn = regexr(fn," TWIN$","")
qui replace fn = regexr(fn,"UNNAMED","")
qui replace fn = regexr(fn,"NO(T)* NAME[D|S]","")
qui replace fn = regexr(fn,"NO( )*NAME","")
qui replace fn = regexr(fn,"NAMELESS","")
qui replace fn = regexr(fn,"UNREADABLE","")
qui replace fn = regexr(fn,"NOT KNOWN","")
qui replace fn = regexr(fn,"^DR ","")
qui replace fn = regexr(fn,"^JR ","")
qui replace fn = regexr(fn,"^MDEL ","")
qui replace fn = regexr(fn,"^MR ","")
qui replace fn = regexr(fn,"^MRS ","")
qui replace fn = regexr(fn,"^NK ","")
qui replace fn = regexr(fn,"^SIR ","")
qui replace fn = regexr(fn," SIR ","")
qui replace fn = regexr(fn," JR$","")
qui replace fn = regexr(fn," SR$","")
qui replace fn = regexr(fn," 2D$","")
qui replace fn = regexr(fn," 3RD$","")
qui replace fn = regexr(fn," 2ND$","")
qui replace fn = regexr(fn," III$","")
qui replace fn = regexr(fn," NEE ","")
qui replace fn = regexr(fn," ALIAS ","")
qui replace fn = trim(fn)
qui replace fn = subinstr(fn,"  "," ",.)

/* Eliminate space following prefix in firstname and surname */
local prefix_list "DA DE DELA DEL DES DER DI DOS DU DEN FITZ JE KAUF KAUFF LE LA MAC MC NA O ORE SAN ST DEST VANDER VONDER VAN VA VON"
foreach prefix of local prefix_list {
	qui replace fn = subinstr(fn, " `prefix' ", " `prefix'",.)
	qui replace fn = regexr(fn, "^`prefix' ", "`prefix'")
}
forvalues x = 0(1)9 {
	replace fn = subinstr(fn,"`x'","",.)
}
replace fn = trim(fn)
replace fn = subinstr(fn,"  "," ",.)

* Generate separate variables for first, middle and last name
qui gen firstname = regexs(1) if regexm(fn,"^([A-Z]+)[ ]")
split fn, parse(" ") gen(name_str) limit(4)
qui replace firstname = name_str1 if firstname == ""
qui gen flag_initial_1 = 0
qui gen flag_initial_2 = 0
qui gen flag_initial_3 = 0

qui replace flag_initial_1 = 1 if length(firstname) <= 1 & length(name_str2) > 1
qui replace firstname = name_str2 if length(firstname) <= 1 & length(name_str2) > 1

replace flag_initial_2 = 1 if length(firstname) <= 1 & length(name_str3) > 1
replace firstname = name_str3 if length(firstname) <= 1 & length(name_str3) > 1

qui gen midname = name_str2 + " " + name_str3 if flag_initial_1 == 0 & flag_initial_2 == 0
replace midname = trim(midname)
replace midname = name_str3 if flag_initial_1 == 1 & flag_initial_2 == 0

gen prefix = ""
replace prefix = name_str1 + " " + name_str2 if flag_initial_1 == 1	& flag_initial_2 == 1
replace prefix = name_str1 if flag_initial_1 == 1& flag_initial_2 == 0
replace midname = prefix + " " + midname
replace midname = trim(midname)
drop name_str* flag_* prefix fn

gen sn = snamestr
replace sn = upper(sn)

qui replace sn = subinstr(sn,"."," ",.)
qui replace sn = subinstr(sn,"    "," ",.)
qui replace sn = subinstr(sn,"   "," ",.)
qui replace sn = subinstr(sn,"  "," ",.)
qui replace sn = subinstr(sn,"  "," ",.)
qui replace sn = trim(sn)

local symbol_list "! @ # $ % ^ & * ' / \ : ; | ~ ` < > , ? { } = + [ ] - _"
foreach symbol of local symbol_list {
	qui replace sn = subinstr(sn,"`symbol'","",.)
}
qui replace sn = trim(sn)

qui replace sn = regexr(sn,"INFANT","")
qui replace sn = regexr(sn,"BABY","")
qui replace sn = regexr(sn," TWIN$","")
qui replace sn = regexr(sn,"UNNAMED","")
qui replace sn = regexr(sn,"NO(T)* NAME[D|S]","")
qui replace sn = regexr(sn,"NO( )*NAME","")
qui replace sn = regexr(sn,"NAMELESS","")
qui replace sn = regexr(sn,"UNREADABLE","")
qui replace sn = regexr(sn,"NOT KNOWN","")
qui replace sn = regexr(sn,"^DR ","")
qui replace sn = regexr(sn,"^JR ","")
qui replace sn = regexr(sn,"^MDEL ","")
qui replace sn = regexr(sn,"^MR ","")
qui replace sn = regexr(sn,"^MRS ","")
qui replace sn = regexr(sn,"^NK ","")
qui replace sn = regexr(sn,"^SIR ","")
qui replace sn = regexr(sn," SIR ","")
qui replace sn = regexr(sn," JR$","")
qui replace sn = regexr(sn," SR$","")
qui replace sn = regexr(sn," 2D$","")
qui replace sn = regexr(sn," 3RD$","")
qui replace sn = regexr(sn," 2ND$","")
qui replace sn = regexr(sn," III$","")
qui replace sn = regexr(sn," NEE ","")
qui replace sn = regexr(sn," ALIAS ","")
qui replace sn = trim(sn)
qui replace sn = subinstr(sn,"  "," ",.)

/* Eliminate space following prefix in firstname and surname */
local prefix_list "DA DE DELA DEL DES DER DI DOS DU DEN FITZ JE KAUF KAUFF LE LA MAC MC NA O ORE SAN ST DEST VANDER VONDER VAN VA VON"
foreach prefix of local prefix_list {
	qui replace sn = subinstr(sn, " `prefix' ", " `prefix'",.)
	qui replace sn = regexr(sn, "^`prefix' ", "`prefix'")
}
forvalues x = 0(1)9 {
	replace sn = subinstr(sn,"`x'","",.)
}
replace sn = trim(sn)
replace sn = subinstr(sn,"  "," ",.)

replace sn = regexr(sn," & MOTHER","")

* Create separate variable with alternative transcription of sn (found in parentheses or following "OR")
replace sn = regexr(sn,","," OR")
replace sn = regexr(sn,"/"," OR ")
replace sn = regexr(sn,"\(OR ","(")
replace sn = regexr(sn," OR \("," OR ")
gen alt_sn = ""
replace sn = trim(sn)
replace alt_sn = regexs(1) if regexm(sn,"\(([A-Z]+)\)$")
replace alt_sn = regexs(1) if regexm(sn,"\(([A-Z]+)\)\)$")
replace sn = regexs(1) if regexm(sn,"^([A-Z]+)\(") 
replace sn = regexs(1) if regexm(sn,"^([A-Z]+) \(")

replace alt_sn = regexs(1) if regexm(sn," [O|0][R|F] ([A-Z]+)$")
replace sn = regexs(1) if regexm(sn,"^([A-Z]+) [O|0][R|F] ")

* Get rid of text in parentheses 
replace sn = regexr(sn,"\([.]+\)","")

local punctuation "( )"
foreach symbol of local punctuation {
	replace sn = subinstr(sn,"`symbol'","",.)
}

rename sn surname

* Sex to byte
replace sex = upper(sex)
replace sex = "1" if sex == "M"
replace sex = "2" if sex == "F"
destring sex, replace
label define sex_lab 1 "Male" 2 "Female", replace
la val sex sex_lab
tab sex, missing

* Impute missing admit date or discharge date using length of stay information and generate own length of stay variable

replace admitday = 28 if admitmon == 2 & admitday == 29

drop admissiondate dischargedate
gen admitdate = mdy(admitmon, admitday, admityr)
format admitdate %td
gen dischdate = mdy(dischmon, dischday, dischyr)
format dischdate %td

rename lengthofstayindaysadded los
replace los = . if los < 0
replace admitdate = dischdate - los if admitdate == . & los != . & dischdate != .
replace dischdate = admitdate + los if dischdate == . & los != . & admitdate != .

drop los
gen los = dischdate - admitdate
replace los = . if los < 0 

replace admitmon = month(admitdate) if admitmon == .
replace admitday = day(admitdate) if admitday == .
drop admitdate dischdate

gen admitdate = mdy(admitmon, admitday, admityr)
format admitdate %td
gen dischdate = mdy(dischmon, dischday, dischyr)
format dischdate %td

* Recode and label Result variable

replace result = "1" if result == "Cured"
replace result = "2" if result == "Relieved"
replace result = "3" if result == "Not relieved"
replace result = "4" if result == "Died"
replace result = "9" if result == "Not recorded"
destring result, replace

label define resultlab 1 "Cured" 2 "Relieved" 3 "Not Relieved" 4 "Died" 5 "Transferred" 6 "Sent home" 9 "Not Recorded", replace
la val result resultlab
tab result, missing

* Recode obvious ageyr coding errors
rename ageyears admitage
rename agemonths admitage_mon
drop birthyearadded
replace admitage = . if admitage > 20
gen byr = year(floor(admitdate - 365.25/2)) - admitage
replace byr = admityr - admitage if byr == .

* Clean residence

forvalues x = 1(1)5 {
	replace address`x' = "" if address`x' == "."
}
egen temp_address = concat(address1 address2 address3 address4 address5), punct(", ")
replace temp_address = subinstr(temp_address,", , ",", ",.) 
replace temp_address = trim(temp_address)
replace temp_address = regexr(temp_address,"[, ]+$","")
replace temp_address = regexr(temp_address,"^[, ]+","")
replace temp_address = trim(temp_address)
replace temp_address = subinstr(temp_address,"  "," ",.)
drop address* residencestreetadded
rename temp_address address

rename registrationdistrictadded district_HHARP
rename registrationsubdistrictadded subdist_HHARP
rename county county_HHARP

replace district_HHARP = upper(district_HHARP)
replace subdist_HHARP = upper(subdist_HHARP)
replace county_HHARP = upper(county_HHARP)

* Clean disease information

rename standarddiseaseadded dis_orig
rename diseaseinregister disinreg 
rename icd10codeadded icd10

replace dis_orig = regexr(dis_orig,"[; ]+$","")
replace dis_orig = regexr(dis_orig,"^[; ]+","")
replace disinreg = regexr(disinreg,"[; ]+$","")
replace disinreg = regexr(disinreg,"^[; ]+","")
replace icd10 = regexr(icd10,"[; ]+$","")
replace icd10 = regexr(icd10,"^[; ]+","")

replace dis_orig = disinreg if dis_orig == ""

rename firstname fname
rename midname mname
rename surname sname
rename institution hospid
rename admittingdoctor physician
rename dischargedto notes

drop postmortem treatment occupationofparents vaccinatedforsmallpox infantilediseasehistory remarks diseasegroupadded duration cause

sort pid_temp
gen hharp_id = _n
drop pid_temp

// Construct common identifier for hospital admissions 
gen regid = .
replace regid = hharp_id + 40152 + 210 + 10983 + 8416 if !missing(hharp_id)
sum regid if !missing(hharp_id)
order regid 

// Set up district-subdistrict crosswalk for cleaning streets 
preserve 

	keep district_HHARP subdist_HHARP
	rename district_HHARP district
	rename subdist_HHARP subdist
	replace district = upper(district)
	replace subdist = upper(subdist)
	duplicates drop

	drop if district == "OUTSIDE LONDON" | district == "NOT KNOWN" | district == "ADDRESS NOT RECORDED" | district == ""
	drop if subdist == ""
	
	count
	forvalues i = 1/5 {
		local newobs_`i' = r(N) + `i'	
	}
	set obs `newobs_5'
	
	// Add districts with no patients
	replace district = "Camberwell" in `newobs_1'
	replace subdist = "St Paul Deptford" in `newobs_1'
	replace district = "St Olave Southwark" in `newobs_2'
	replace subdist = "St Olave Southwark" in `newobs_2'
	replace district = "Westminster" in `newobs_3'
	replace subdist = "Lambeth Church First" in `newobs_3'
	replace district = "Westminster" in `newobs_4'
	replace subdist = "St John Westminster" in `newobs_4'
	replace district = "Westminster" in `newobs_5'
	replace subdist = "St Margaret Westminster" in `newobs_5'
	
	replace district = proper(district)
	replace subdist = proper(subdist)

	sort district subdist
		
	save "$PROJ_PATH/processed/intermediate/geography/hharp_london_district_subdist_crosswalk.dta", replace
	
restore 

// Drop variables we won't use 
drop hharp_id county_HHARP district_HHARP subdist_HHARP ward icd10 admitage_mon

// Add variable labels 
la var regid "Admission ID"
la var admitmon "Admission month"
la var admitday "Admission day"
la var admityr "Admission year"
la var admitdate "Admission date"
la var admitage "Age at admission"
la var byr "Year of birth"
la var fname "First name"
la var mname "Middle name"
la var sname "Surname"
la var alt_sn "Alternate surname"
la var sex "Gender"
la var hospid "Hospital ID"
la var physician "Name of physician"
la var address "Residential address"
la var dischmon "Discharge month"
la var dischday "Discharge day"
la var dischyr "Discharge year"
la var dischdate "Discharge date"
la var los "Length of stay in days"
la var dis_orig "Raw cause of admission string"
la var result "Result"
la var fnamestr "Raw first name string"
la var snamestr "Raw surname string"

order regid hospid fnamestr snamestr fname mname sname alt_sn admitage byr sex admitdate admityr admitmon admitday dischdate dischyr dischmon dischday los address physician dis_orig result
compress 
desc, f

save "$PROJ_PATH/processed/intermediate/hospitals/hharp/gosh_hospital_admissions.dta", replace

disp "DateTime: $S_DATE $S_TIME"

* EOF
