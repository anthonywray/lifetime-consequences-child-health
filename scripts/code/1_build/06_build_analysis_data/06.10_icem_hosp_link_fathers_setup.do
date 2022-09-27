version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 06.10_icem_hosp_link_fathers_setup.do
* PURPOSE: This do file links fathers across consecutive censuses
************

args t_1 t_2

// Use census-to-census links created through hospital links to supplement existing census-to-census link 
clear
append using "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`t_1'/unique_matches_`t_1'_hosp.dta"
append using "$PROJ_PATH/processed/intermediate/icem_hosp_linkage_`t_2'/unique_matches_`t_2'_hosp.dta"

merge m:1 regid using "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", keep(3) nogen 
keep if jw_sname >= 0.80 & max(jw_fname_orig,jw_fname_edit) >= 0.80 & similar_10 <= 20 & age_dist <= 3 
keep censusyr regid RecID admitdate admityr admitage hospid resid_mort sex_HOSP
tempfile hosp_icem_links
save `hosp_icem_links', replace

keep censusyr regid RecID sex_HOSP
keep if censusyr == `t_1' | censusyr == `t_2'
egen tot_`t_1' = total(censusyr == `t_1'), by(regid)
egen tot_`t_2' = total(censusyr == `t_2'), by(regid)
keep if tot_`t_1' == 1 & tot_`t_2' == 1
sort regid censusyr
reshape wide RecID, i(regid) j(censusyr)
rename RecID`t_1' RecID_child
rename RecID`t_2' RecID_adult
keep RecID* sex_HOSP
rename sex_HOSP ic_sex
gen censusyr = `t_1'
gen outcomeyr = `t_2'
order censusyr outcomeyr
save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/links_hosp_icem_`t_1'_`t_2'.dta", replace

// Gather all hospital to census matches between census years
use `hosp_icem_links', clear						
drop sex_HOSP

if `t_1' == 1881 {
	local census_A = mdy(4,3,1881)
	local census_B = mdy(4,5,1891)
}
if `t_1' == 1891 {
	local census_A = mdy(4,5,1891)
	local census_B = mdy(3,31,1901)
}

gen patient = (admitdate > `census_A' & admitdate < `census_B')
gen pre_patient  = (admitdate <= `census_A')
gen post_patient = (admitdate >= `census_B')

rename censusyr Year
save "$PROJ_PATH/processed/temp/patients_admitted_`t_1'_`t_2'.dta", replace

// Identify linked fathers
use "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/unique_matches_`t_1'_`t_2'.dta", clear
keep censusyr RecID_child sex outcomeyr RecID_adult age_dist jw* similar_10
unique censusyr RecID_child
rename sex ic_sex

// Drop if child-child match is poor (apply standards used elsewhere)
keep if age_dist <= 3 & jw_sname >= 0.80 & max(jw_fname_orig, jw_fname_edit) >= 0.80 & similar_10 <= 20
drop age_dist jw_* similar_* 

// Append linkages through hospital records
append using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/links_hosp_icem_`t_1'_`t_2'.dta"
duplicates drop
sort censusyr RecID_child outcomeyr RecID_adult ic_sex

// Original thought: Keep kids age 0-5 so they will be age 10-15 in later census (weird selection of kids older than 13 living with parents)
// Updated thought: We can still match fathers forward using younger siblings
rename censusyr Year
rename RecID_child RecID

merge m:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`t_1'_demographic.dta", keep(1 3) nogen keepusing(Age)

keep if Age <= 21
rename Age ic_age

// We need to observe father in both censuses
merge m:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`t_1'_identifiers.dta", keep(1 3) nogen keepusing(poprecid)
rename poprecid ic_poprecid

rename Year censusyr
rename outcomeyr Year
rename RecID RecID_child
rename RecID_adult RecID

merge m:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`t_2'_identifiers.dta", keep(1 3) nogen keepusing(poprecid)
rename poprecid ia_poprecid

drop if ic_poprecid == . | ia_poprecid == . 

rename Year outcomeyr
rename RecID RecID_adult

// Add household identifiers and residential information for parish and district FE
rename censusyr Year
rename RecID_child RecID

merge m:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/household_ids/icem_household_ids_`t_1'.dta", keep(1 3) nogen keepusing(pid_inf hhid)
merge m:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`t_1'_identifiers.dta", keep(1 3) nogen keepusing(ParID h pid)
merge m:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`t_1'_residence.dta", keep(1 3) nogen keepusing(ConParID RegCnty RegDist)

gen london = regexm(RegCnty,"^London")
drop RegCnty

// Merge in father's variables from earlier census
merge m:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`t_1'_demographic.dta", keep(1 3) nogen keepusing(popage)
merge m:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`t_1'_occupation.dta", keep(1 3) nogen keepusing(pophisco popocc)
rename pophisco hisco
merge m:1 hisco using "$PROJ_PATH/processed/intermediate/occupations/hisco_to_hisclass.dta", keep(1 3) nogen keepusing(hisclass)
rename hisclass ic_pophisclass
rename popocc ic_popocc
rename popage ic_popage
drop hisco

// Add father's name from earlier census and standardize first name 
rename RecID RecID_child
rename ic_poprecid RecID

merge m:1 Year RecID using "$PROJ_PATH/raw/icem_sl/ICEM_Names_EW_`t_1'.dta", keep(1 3) nogen keepusing(Pname Oname)
recast str Oname
gen sex = 1
merge m:1 Pname Oname sex using "$PROJ_PATH/processed/intermediate/names/firstnames_`t_1'.dta", keep(1 3) nogen keepusing(fname_edit) // Add cleaned names
drop sex

gen swap_names = length(Pname) == 1 & length(Oname) > 1
gen ic_pop_mname = ""
replace ic_pop_mname = Pname if swap_names == 1
replace ic_pop_mname = Oname if swap_names == 0
drop swap_names

rename fname_edit ic_pop_fname 
drop Pname Oname

// Add father's birth place from earlier census and allocate London parishes to separate county
merge m:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`t_1'_birthplace.dta", keep(1 3) nogen keepusing(Cnti BpCtry)
recast str Cnti
rename Cnti std_par
rename BpCtry bcounty

merge m:1 std_par using "$PROJ_PATH/processed/intermediate/geography/icem_london_std_par.dta", keep(1 3)
replace bcounty = "LND" if (bcounty == "KEN" | bcounty == "MDX" | bcounty == "SRY") & _merge == 3
drop _merge

rename std_par ic_popbpar
rename bcounty ic_popbcty

rename RecID ic_poprecid
rename Year censusyr

// Don't accept matches of girls to married women since name changed at marriage
rename outcomeyr Year
rename RecID_adult RecID

merge m:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`t_2'_demographic.dta", keep(1 3) nogen keepusing(Mar)
rename Mar ia_marst

drop if ic_sex == 2 & (ia_marst == 2 | ia_marst == 3)
drop ia_marst

// Merge in father's variables from later census
merge m:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`t_2'_occupation.dta", keep(1 3) nogen keepusing(pophisco popocc)
merge m:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`t_2'_demographic.dta", keep(1 3) nogen keepusing(popage)

rename pophisco hisco
merge m:1 hisco using "$PROJ_PATH/processed/intermediate/occupations/hisco_to_hisclass.dta", keep(1 3) nogen keepusing(hisclass)
rename hisclass ia_pophisclass
rename popocc ia_popocc
rename popage ia_popage
drop hisco

// Add father's name from later census standardize first name 
rename RecID RecID_adult
rename ia_poprecid RecID

merge m:1 Year RecID using "$PROJ_PATH/raw/icem_sl/ICEM_Names_EW_`t_2'.dta", keep(1 3) nogen keepusing(Pname Oname)
recast str Oname
gen sex = 1
merge m:1 Pname Oname sex using "$PROJ_PATH/processed/intermediate/names/firstnames_`t_2'.dta", keep(1 3) nogen keepusing(fname_edit) // Add cleaned names
drop sex

gen swap_names = length(Pname) == 1 & length(Oname) > 1
gen ia_pop_mname = ""
replace ia_pop_mname = Pname if swap_names == 1
replace ia_pop_mname = Oname if swap_names == 0
drop swap_names

rename fname_edit ia_pop_fname 
drop Pname Oname

// Add father's birth place from later census and allocate London parishes to separate county
merge m:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`t_2'_birthplace.dta", keep(1 3) nogen keepusing(Cnti BpCtry)
recast str Cnti
rename Cnti std_par
rename BpCtry bcounty

merge m:1 std_par using "$PROJ_PATH/processed/intermediate/geography/icem_london_std_par.dta", keep(1 3)
replace bcounty = "LND" if (bcounty == "KEN" | bcounty == "MDX" | bcounty == "SRY") & _merge == 3
drop _merge

rename std_par ia_popbpar
rename bcounty ia_popbcty

rename RecID ia_poprecid
rename Year outcomeyr

// Add HISCLASS variables
label define hisc4lab 1 "White Collar" 2 "Skilled" 3 "Semi skilled" 4 "Unskilled", replace
local hisco_vars "ic_pop ia_pop"
foreach histype of local hisco_vars {
	gen `histype'hisc4 = .
	replace `histype'hisc4 = 1 if `histype'hisclass == 1 | `histype'hisclass == 2 | `histype'hisclass == 3 | `histype'hisclass == 4 | `histype'hisclass == 5
	replace `histype'hisc4 = 2 if `histype'hisclass == 6 | `histype'hisclass == 7 | `histype'hisclass == 8
	replace `histype'hisc4 = 3 if `histype'hisclass == 9
	replace `histype'hisc4 = 4 if `histype'hisclass == 10 | `histype'hisclass == 11 | `histype'hisclass == 12
	la val `histype'hisc4 hisc4lab
}
drop *hisclass

// Construct class change variables
gen pop_up = ia_pophisc4 < ic_pophisc4
gen pop_dn = ia_pophisc4 > ic_pophisc4
gen pop_uc = ic_pophisc4 == ia_pophisc4

// Construct own occupation variables
gen pop_top25 = (ia_pophisc4 == 1)
gen pop_top50 = (ia_pophisc4 == 1 | ia_pophisc4 == 2)
gen pop_bot25 = (ia_pophisc4 == 4)

// We might want to flag occupation string matches

****** Linking fathers *****

// Age matches +/- 3 years
gen pop_agediff = abs(ic_popage + 10 - ia_popage)
keep if pop_agediff <= 3

// Birth parish string comparisons - check for similarity and if one in the other
gen bpar_1in2 = strpos(upper(ia_popbpar), upper(ic_popbpar))
gen bpar_2in1 = strpos(upper(ic_popbpar), upper(ia_popbpar))

gen bpar_match = (bpar_1in2 > 0 | bpar_2in1 > 0)
drop bpar_1in2 bpar_2in1

// Birth county comparison - rule out if both non-missing and mis-matched (unless name and age are exact match)
foreach var of varlist ic_popbcty ia_popbcty {
	replace `var' = "" if `var' == "UNK"
}
gen bcty_mismatch = (ic_popbcty != "" & ia_popbcty != "" & ic_popbcty != ia_popbcty)
gen bcty_match = (ic_popbcty != "" & ia_popbcty != "" & ic_popbcty == ia_popbcty)

gen bpl_mismatch  = (bcty_mismatch == 1 & bpar_match == 0)
gen bpl_match = (bcty_match == 1 | bpar_match == 1)

// First and middle name comparisons - minimum JW score of 0.8 on first name

tempfile jw_input
save `jw_input', replace

use ic_pop_fname ia_pop_fname using `jw_input', clear
bysort ic_pop_fname ia_pop_fname: keep if _n == 1
jarowinkler ic_pop_fname ia_pop_fname, gen(jw_fn_fn_dist)
tempfile jw_fn_fn
save `jw_fn_fn', replace

use `jw_input', clear
merge m:1 ic_pop_fname ia_pop_fname using `jw_fn_fn', assert(3) nogen

// Add initial to full name match?
gen initial_match = 0
replace initial_match = 1 if length(ic_pop_fname) == 1 & length(ia_pop_fname) > 1 & substr(ic_pop_fname,1,1) == substr(ia_pop_fname,1,1)
replace initial_match = 1 if length(ic_pop_fname) > 1 & length(ia_pop_fname) == 1 & substr(ic_pop_fname,1,1) == substr(ia_pop_fname,1,1)
replace initial_match = 1 if ic_pop_fname == ia_pop_mname & substr(ic_pop_mname,1,1) == substr(ia_pop_fname,1,1)
replace initial_match = 1 if ia_pop_fname == ic_pop_mname & substr(ia_pop_mname,1,1) == substr(ic_pop_fname,1,1)

// Drop if first name doesn't match (Add exception for first name to first/middle initial)
drop if jw_fn_fn_dist < 0.8 & initial_match == 0

// Rule - if first name and age match exactly (+/- 1) then matched
gen fathers_matched = 0
replace fathers_matched = 1 if jw_fn_fn_dist == 1 & pop_agediff <= 1

// If first names are not close (jw_fn_fn_dist < 0.9), age and birthplace need to match
drop if jw_fn_fn_dist < 0.9 & initial_match == 0 & pop_agediff > 1 & bpl_match == 0 & fathers_matched == 0
drop fathers_matched

// Resolve multiple potential matches of individual child in Year A to multiple fathers in Year B
egen flag_cty_match = max(bcty_match), by(censusyr RecID_child)
drop if flag_cty_match == 1 & bcty_match == 0
drop flag_cty_match

egen flag_par_match = max(bpar_match), by(censusyr RecID_child)
drop if flag_par_match == 1 & bpar_match == 0
drop flag_par_match

gen occ_match = strpos(ia_popocc,substr(ic_popocc,1,5)) > 0 | strpos(ic_popocc,substr(ia_popocc,1,5)) > 0
egen flag_occ_match = max(occ_match == 1), by(censusyr RecID_child)
drop if flag_occ_match == 1 & occ_match == 0
drop flag_occ_match occ_match

egen flag_age_match = min(pop_agediff), by(censusyr RecID_child)
drop if pop_agediff != flag_age_match
drop flag_age_match

// Resolve multiple potential matches of individual child in Year B to multiple fathers in Year A
egen flag_cty_match = max(bcty_match), by(outcomeyr RecID_adult)
drop if flag_cty_match == 1 & bcty_match == 0
drop flag_cty_match

egen flag_par_match = max(bpar_match), by(outcomeyr RecID_adult)
drop if flag_par_match == 1 & bpar_match == 0
drop flag_par_match

gen occ_match = strpos(ia_popocc,substr(ic_popocc,1,5)) > 0 | strpos(ic_popocc,substr(ia_popocc,1,5)) > 0
egen flag_occ_match = max(occ_match == 1), by(outcomeyr RecID_adult)
drop if flag_occ_match == 1 & occ_match == 0
drop flag_occ_match occ_match

egen flag_age_match = min(pop_agediff), by(outcomeyr RecID_adult)
drop if pop_agediff != flag_age_match
drop flag_age_match

unique censusyr RecID_child
unique outcomeyr RecID_adult

bysort outcomeyr RecID_adult: keep if _N == 1
bysort censusyr RecID_child: keep if _N == 1

order censusyr hhid ic_poprecid outcomeyr ia_poprecid
order ic_pop_fname ia_pop_fname ic_pop_mname ia_pop_mname ic_popage ia_popage ic_popbcty ia_popbcty ic_popbpar ia_popbpar, last
sort hhid ic_poprecid RecID_child ia_poprecid RecID_adult
compress
save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/fathers_linked_`t_1'_`t_2'.dta", replace

// Construct household level hospital variables and identify patients
use ic_poprecid censusyr RecID_child outcomeyr RecID_adult using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/fathers_linked_`t_1'_`t_2'.dta", clear

rename censusyr Year
rename RecID_child RecID 

merge 1:m Year RecID using "$PROJ_PATH/processed/temp/patients_admitted_`t_1'_`t_2'.dta", keep(3) nogen

rename Year censusyr
rename RecID RecID_child

tempfile links_A
save `links_A', replace

use ic_poprecid censusyr RecID_child outcomeyr RecID_adult using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/fathers_linked_`t_1'_`t_2'.dta", clear

rename censusyr Year
rename RecID_child RecID 

merge 1:m Year RecID using "$PROJ_PATH/processed/temp/patients_admitted_`t_1'_`t_2'.dta", keep(1) nogen keepusing(Year RecID)

rename Year censusyr
rename RecID RecID_child

rename outcomeyr Year
rename RecID_adult RecID

merge 1:m Year RecID using "$PROJ_PATH/processed/temp/patients_admitted_`t_1'_`t_2'.dta", keep(3) nogen

append using `links_A'

egen hosp_patient = max(patient == 1), by(ic_poprecid)
egen hosp_pre = max(pre_patient == 1), by(ic_poprecid)
egen hosp_post = max(post_patient == 1), by(ic_poprecid)

egen hosp_barts = max(hospid == 1), by(ic_poprecid)
egen hosp_gosh = max(hospid == 2), by(ic_poprecid)
egen hosp_guys = max(hospid == 5), by(ic_poprecid)
egen hosp_age = min(admitage), by(ic_poprecid)
egen hosp_yr = min(admityr), by(ic_poprecid)
egen hosp_hdi = mean(resid_mort), by(ic_poprecid)

keep ic_poprecid censusyr hosp_*
duplicates drop

tempfile pop_patients
save `pop_patients', replace

// Drop remaining individual variables
use "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/fathers_linked_`t_1'_`t_2'.dta", clear

drop RecID_child pid pid_inf RecID_adult ic_age ic_sex
duplicates drop

// Resolve multiple potential matches to single father 
egen flag_cty_match = max(bcty_match), by(censusyr ic_poprecid)
drop if flag_cty_match == 1 & bcty_match == 0
drop flag_cty_match

egen flag_par_match = max(bpar_match), by(censusyr ic_poprecid)
drop if flag_par_match == 1 & bpar_match == 0
drop flag_par_match

gen occ_match = strpos(ia_popocc,substr(ic_popocc,1,5)) > 0 | strpos(ic_popocc,substr(ia_popocc,1,5)) > 0
egen flag_occ_match = max(occ_match == 1), by(censusyr ic_poprecid)
drop if flag_occ_match == 1 & occ_match == 0
drop flag_occ_match occ_match

egen flag_age_match = min(pop_agediff), by(censusyr ic_poprecid)
drop if pop_agediff != flag_age_match
drop flag_age_match

// Restrict to uniquely matched fathers
bysort censusyr ic_poprecid: gen tot_A = _N
bysort outcomeyr ia_poprecid: gen tot_B = _N

keep if tot_A == 1 & tot_B == 1
drop tot_A tot_B

// Merge in hospital variables
merge 1:1 censusyr ic_poprecid using `pop_patients', keep(1 3) nogen
recode hosp_* (mis = 0)

// Restrict to parishes with any hospital patients 
egen any_patient = max(hosp_patient == 1), by(ParID)
keep if any_patient == 1 
drop any_patient

order ConParID ParID h hhid RegDist censusyr ic_poprecid outcomeyr ia_poprecid ic_pop_fname ia_pop_fname ic_pop_mname ia_pop_mname ic_popage ia_popage ic_popbcty ia_popbcty ic_popbpar ia_popbpar ic_popocc ia_popocc ic_pophisc4 ia_pophisc4 pop_* jw_* *_match *_mismatch hosp_*

sort ParID h ic_poprecid
compress
save "$PROJ_PATH/processed/intermediate/icem_linked_fathers/fathers_linked_`t_1'_`t_2'.dta", replace

rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/fathers_linked_`t_1'_`t_2'.dta"
rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/links_hosp_icem_`t_1'_`t_2'.dta"
rm "$PROJ_PATH/processed/temp/patients_admitted_`t_1'_`t_2'.dta"

disp "DateTime: $S_DATE $S_TIME"

* EOF
