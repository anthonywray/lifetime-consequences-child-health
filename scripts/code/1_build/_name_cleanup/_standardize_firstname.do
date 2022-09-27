version 14

rename firstname fname

replace fname = subinstr(fname,"(","",.)
replace fname = subinstr(fname,")","",.)

gen firstname = regexs(1) if regexm(fname,"^([A-Z]+)[ ]")
split fname, parse(" ") gen(name_str) limit(4)
replace firstname = name_str1 if firstname == ""
gen flag_initial_1 = 0
gen flag_initial_2 = 0
gen flag_initial_3 = 0

replace flag_initial_1 = 1 if length(firstname)<=1 & length(name_str2)>1
replace firstname = name_str2 if length(firstname)<=1 & length(name_str2)>1

capture replace flag_initial_2 = 1 if length(firstname)<=1 & length(name_str3)>1
capture replace firstname = name_str3 if length(firstname)<=1 & length(name_str3)>1

capture replace flag_initial_3 = 1 if length(firstname)<=1 & length(name_str4)>1
capture replace firstname = name_str4 if length(firstname)<=1 & length(name_str4)>1 

gen midname = name_str2 if flag_initial_1 == 0 & flag_initial_2 == 0
capture replace midname = name_str3 if flag_initial_1 == 1 & flag_initial_2 == 0
capture replace midname = name_str4 if flag_initial_1 == 1 & flag_initial_3 == 0

drop flag_initial* name_str* fname

* Standardize names

gen fname_orig = firstname
gen mname_orig = midname

local names "firstname midname"
foreach name of local names {
	rename `name' nickname
	merge m:1 nickname sex using "$PROJ_PATH/processed/intermediate/names/nicknames_for_matching", keepusing(name_for_matching) keep(1 3) nogen
	replace nickname = name_for_matching if name_for_matching!=""
	drop name_for_matching
	rename nickname `name'
}

