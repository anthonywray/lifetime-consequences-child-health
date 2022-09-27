version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 04.02_combine_hospital_data.do
* PURPOSE: This do file combines all hospital data
************

// Combine hospital data
clear
append using "$PROJ_PATH/raw/hospitals/barts_hospital_admissions.dta"
append using "$PROJ_PATH/processed/intermediate/hospitals/hharp/gosh_hospital_admissions.dta"
append using "$PROJ_PATH/raw/hospitals/guys_hospital_admissions.dta"

// Generate dummy for whether patient died

replace notes = upper(notes)
gen died = regexm(notes,"DIED") == 1
replace died = 1 if result == 4
tab died
drop result

replace hospid = "1" if hospid == "BARTS"
replace hospid = "2" if hospid == "GOSH"
replace hospid = "5" if hospid == "GUYS"
destring hospid, replace

label define hosplab 1 "Barts" 2 "Gosh" 5 "Guys"
la val hospid hosplab

* Create doctor variables
replace physician = upper(physician)
gen doctor = (regexm(physician,"^DR") | regexm(physician,"SIR D"))
drop physician 

* Generate bounds on birthday
replace admitday = . if admitday > 31
gen bdate_lb_HOSP = mdy(admitmon, admitday, admityr - admitage - 1) + 1
gen bdate_ub_HOSP = mdy(admitmon, admitday, admityr - admitage)

replace bdate_lb_HOSP = mdy(1,2,admityr - admitage - 1) if admitmon ==. 
replace bdate_ub_HOSP = mdy(12,31,admityr - admitage) if admitmon ==. 
gen next_month = mod(admitmon+1,12)
recode next_month (0=12)
gen last_of_month = day(mdy(next_month,1,admityr)-1)
replace bdate_lb_HOSP = mdy(admitmon,2,admityr - admitage - 1) if admitday == . & admitmon != .
replace bdate_ub_HOSP = mdy(admitmon,last_of_month,admityr - admitage) if admitday == . & admitmon != .
drop next_month last_of_month

gen temp = (bdate_ub_HOSP==.)
replace bdate_ub_HOSP = mdy(admitmon, admitday-1, admityr - admitage) if bdate_ub_HOSP ==.
replace bdate_lb_HOSP = bdate_ub_HOSP - 364 if temp == 1 & day(bdate_ub_HOSP)==28
replace bdate_lb_HOSP = bdate_ub_HOSP - 365 if temp == 0 & day(bdate_ub_HOSP)==29
format bdate_ub_HOSP bdate_lb_HOSP %td
drop temp

gen byr_lb_HOSP = year(bdate_lb_HOSP)
gen byr_ub_HOSP = year(bdate_ub_HOSP)

***** Clean names

replace fname = "THOMAS" if fname == "TH"
replace mname = "C W" if mname == "CW"
replace alt_sn = "" if alt_sn == sname

gen fname_orig = fname
gen mname_orig = mname

split fname, parse("-OR-") gen(fname)
split sname, parse("-OR-") gen(sname)

gen alt_fn = ""
replace alt_fn = fname2 if fname2 != ""
replace alt_sn = sname2 if sname2 != ""
drop fname sname fname2 sname2
rename fname1 fname
rename sname1 sname

replace mname = regexs(1) if regexm(mname,"^([A-Z]+)[ ]")
local names "fname alt_fn mname"
foreach name of local names {
	rename `name' nickname
	merge m:1 nickname sex using "$PROJ_PATH/processed/intermediate/names/nicknames_for_matching.dta", keepusing(name_for_matching)
	drop if _merge == 2
	replace nickname = name_for_matching if name_for_matching!=""
	drop _merge name_for_matching
	rename nickname `name'
}
sort regid
rename address address_orig

/* 	Below we restrict the hospital sample to cohorts and hospitals used in the analysis.
	We impose the following restrictions:
	* Restrict to patients admitted at ages 0 to 11 (consistent cut-off across all hospitals)
	* Restrict to admissions between 1870 and 1902
	* Restrict to 1869/70 to 1901/02 birth cohorts
*/

drop if missing(hospid)
drop if admitage > 11
drop if admityr < 1870 | admityr > 1902
keep if byr_lb_HOSP >= 1869 & byr_lb_HOSP <= 1902

la var died "=1 if died in hospital"
la var doctor "=1 if treated by doctor"
la var bdate_lb_HOSP "Lower bound for birth date"
la var bdate_ub_HOSP "Upper bound for birth date"
la var byr_lb_HOSP "Lower bound for birth year"
la var byr_ub_HOSP "Upper bound for birth year"
la var fname_orig "Original first name"
la var mname_orig "Original middle name"
la var fname "Firstname"
la var alt_fn "Alternate first name"
la var sname "Surname"

order regid hospid namestr fnamestr snamestr fname_orig mname_orig fname mname sname alt_fn alt_sn admitage byr sex age_orig bdate_* byr_* address_orig admitdate admityr admitmon admitday dischdate dischyr dischmon dischday los dis_orig disinreg  doctor died notes remarks

desc, f
save "$PROJ_PATH/processed/intermediate/hospitals/hospital_admissions_combined.dta", replace

disp "DateTime: $S_DATE $S_TIME"

* EOF
