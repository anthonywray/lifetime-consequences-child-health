version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 02.01_icem_extract_names.do
* PURPOSE: This do file loads the crosswalk file with nicknames for matching
************

args year

// Extract firstnames

use "$PROJ_PATH/raw/icem_sl/ICEM_Names_EW_`year'.dta", clear
keep RecID Pname Oname
recast str Oname
fmerge 1:1 RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`year'_demographic.dta", keepusing(Sex) assert(3)
rename Sex sex
keep Pname Oname sex
bysort Pname Oname sex: gen temp_name_count = _N
gduplicates drop
gunique Pname Oname sex
compress

gen missing_sex = (sex == 9)
rename sex sex1 
gen sex2 = .
replace sex1 = 1 if missing_sex == 1
replace sex2 = 2 if missing_sex == 1
drop missing_sex

gen long obs_id = _n
greshape long sex, i(obs_id) j(new_id)
drop obs_id new_id
drop if sex == .
order sex

egen long name_count = total(temp_name_count), by(Pname sex)
drop temp_name_count

gduplicates drop
gunique Pname Oname sex

gen temp_pname = upper(Pname)
gen temp_oname = upper(Oname)
replace temp_pname = trim(temp_pname)
replace temp_oname = trim(temp_oname)

egen firstname = concat(temp_pname temp_oname), punct(" ")
replace firstname = trim(firstname)
drop temp*

local name_list "firstname"

do "$PROJ_PATH/scripts/code/1_build/_name_cleanup/_name_cleanup.do" `name_list'
do "$PROJ_PATH/scripts/code/1_build/_name_cleanup/_standardize_firstname.do"

save "$PROJ_PATH/processed/temp/fname_inprog.dta", replace
drop midname mname_orig name_count

// Reshape firstname 

rename firstname fname_edit
gen firstname1 = fname_orig
gen firstname2 = fname_edit
replace firstname2 = "" if firstname2 == firstname1
gen long obs_id = _n
greshape long firstname, i(obs_id) j(new_id)
drop obs_id new_id
drop if firstname == ""

***** Create phonex code
gen tophonex = firstname
do "$PROJ_PATH/scripts/code/1_build/_name_cleanup/_phonex.do"
rename phonexed phx_fname
drop tophonex

sort Pname Oname firstname
egen long name_id = group(Pname Oname sex), missing
egen obs_id = seq(), by(Pname Oname sex)
greshape wide firstname phx_fname, i(name_id) j(obs_id)
drop name_id
compress
save "$PROJ_PATH/processed/intermediate/names/firstnames_`year'.dta", replace

* Extract surnames
use "$PROJ_PATH/raw/icem_sl/ICEM_Names_EW_`year'.dta", clear
keep Sname
recast str Sname
bysort Sname: gen long name_count = _N
gduplicates drop 
gunique Sname
recast str Sname
compress

gen surname = upper(Sname)

local name_list "surname"

do "$PROJ_PATH/scripts/code/1_build/_name_cleanup/_name_cleanup.do" `name_list'
do "$PROJ_PATH/scripts/code/1_build/_name_cleanup/_standardize_surname.do"

drop name_count

****** Reshape surname
gen long obs_id = _n
split surname, parse(;) gen(surname)
drop surname
greshape long surname, i(obs_id) j(new_id)
drop obs_id new_id
drop if surname == ""

***** Create phonex code
gen tophonex = surname
do "$PROJ_PATH/scripts/code/1_build/_name_cleanup/_phonex.do"
rename phonexed phx_sname
drop tophonex

gsort Sname surname 
egen long name_id = group(Sname)
egen obs_id = seq(), by(Sname)
greshape wide surname phx_sname, i(name_id) j(obs_id)
drop name_id
compress

order Sname
save "$PROJ_PATH/processed/intermediate/names/surnames_`year'.dta", replace

* Save middle names to file

use "$PROJ_PATH/processed/temp/fname_inprog.dta", clear
keep Pname Oname sex mname_orig midname 
gduplicates drop 
gunique Pname Oname sex mname_orig midname
save "$PROJ_PATH/processed/intermediate/names/midnames_`year'.dta", replace

// Clean up temp files
rm "$PROJ_PATH/processed/temp/fname_inprog.dta"

disp "DateTime: $S_DATE $S_TIME"

* EOF 
