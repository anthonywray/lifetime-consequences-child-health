version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 06.07_benchmark_regression_setup.do
* PURPOSE: Scaling by intergenerational transmission of occupational status
************

use "$PROJ_PATH/processed/intermediate/icem_linkage_1881_1911/unique_matches_1881_1911.dta", clear
keep censusyr RecID_child outcomeyr RecID_adult age_adult age_dist bparish_match flag* bpar_mismatch mi_mismatch jw* similar*

rename flag_recode_bpl_1881 flag_rbp_child
rename flag_recode_bpl_1911 flag_rbp_adult

rename censusyr Year
rename RecID_child RecID

merge 1:1 RecID using "$PROJ_PATH/processed/intermediate/icem/sibling_ids/sibling_ids_1881.dta", assert(2 3) keep(3) nogen keepusing(sibling_id sib_type brthord mbrthord fbrthord)
merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_1881_identifiers.dta", assert(2 3) keep(3) nogen keepusing(h ParID pid)
merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_1881_demographic.dta", assert(2 3) keep(3) nogen keepusing(Age Sex)
merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_1881_occupation.dta", assert(2 3) keep(3) nogen keepusing(hisco Occ)

rename pid pid_child
rename Sex sex_child
rename Age age_child
rename hisco ic_hisco 
rename Occ ic_occ
			
merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_1881_occupation.dta", keep(1 3) nogen keepusing(pophisco popocc popoccode)
merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_1881_demographic.dta", keep(1 3) nogen keepusing(popage)

* Add Williamson wages for father
rename pophisco hisco
rename popocc Occ
rename popoccode Occode

destring Occode, replace

williamson 1881

rename wage1881 popwage1881
rename hisco pophisco
rename Occ popocc
rename Occode popoccode

rename RecID RecID_child
rename Year censusyr

rename outcomeyr Year
rename RecID_adult RecID
merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_1911_residence.dta", assert(2 3) keep(3) nogen keepusing(RegCnty)
merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_1911_occupation.dta", assert(2 3) keep(3) nogen keepusing(hisco Occ Occode)

* Add Williamson wages for patients and siblings as adults
destring Occode, replace

williamson 1911

rename hisco ia_hisco 
rename Occ ia_occ

***** Changes to ICEM county names:

replace RegCnty = "Kent" if RegCnty == "Kent (Extra London)"
replace RegCnty = "London" if RegCnty == "London (Parts Of Middlesex, Surrey & Kent)"
replace RegCnty = "Middlesex" if RegCnty == "Middlesex (Extra London)"
replace RegCnty = "Surrey" if RegCnty == "Surrey (Extra London)"
replace RegCnty = "Yorkshire" if regexm(RegCnty,"Yorkshire")
replace RegCnty = upper(RegCnty)
rename RegCnty county_adult
			
rename Year outcomeyr

* Add HISCLASS
	
rename pophisco hisco
merge m:1 hisco using "$PROJ_PATH/processed/intermediate/occupations/hisco_to_hisclass.dta", keep(1 3) nogen keepusing(hisclass)
tab hisco if hisclass == .
rename hisclass pophisclass
rename hisco pophisco

rename ia_hisco hisco
merge m:1 hisco using "$PROJ_PATH/processed/intermediate/occupations/hisco_to_hisclass.dta", keep(1 3) nogen keepusing(hisclass)
tab hisco if hisclass == .
rename hisclass ia_hisclass
rename hisco ia_hisco

* Create 4 group HISCLASS measure
label define hisc4lab 1 "White Collar" 2 "Skilled" 3 "Semi skilled" 4 "Unskilled", replace
local hisco_vars "pop ia_"
foreach histype of local hisco_vars {
	gen `histype'hisc4 = .
	replace `histype'hisc4 = 1 if `histype'hisclass == 1 | `histype'hisclass == 2 | `histype'hisclass == 3 | `histype'hisclass == 4 | `histype'hisclass == 5
	replace `histype'hisc4 = 2 if `histype'hisclass == 6 | `histype'hisclass == 7 | `histype'hisclass == 8
	replace `histype'hisc4 = 3 if `histype'hisclass == 9
	replace `histype'hisc4 = 4 if `histype'hisclass == 10 | `histype'hisclass == 11 | `histype'hisclass == 12
	la val `histype'hisc4 hisc4lab
}

* Add Williamson wages for fathers
forvalues y = 1881(10)1881 {
	merge m:1 pophisclass using "$PROJ_PATH/processed/intermediate/occupations/williamson_avg_wage12_`y'.dta", keep(1 3) nogen keepusing(avg_wage12_`y')
	replace popwage`y' = avg_wage12_`y' if popwage`y' == .
	drop avg_wage12_`y'
}

* Add Williamson averages wages for patients and siblings
forvalues y = 1911(10)1911 {
	merge m:1 ia_hisclass using "$PROJ_PATH/processed/intermediate/occupations/williamson_avg_wage12_`y'.dta", keep(1 3) nogen keepusing(avg_wage12_`y')
	replace wage`y' = avg_wage12_`y' if wage`y' == .
	drop avg_wage12_`y'
}

* Create single variable for father and sons' wages
rename popwage1881 popwage
gen ln_popwage = ln(popwage)

rename wage1911 wage
gen ln_wage = ln(wage)

* Add sibling variables
egen max_brthord = max(brthord), by(sibling_id)
bysort sibling_id: gen sib_size = _N if sibling_id != .
recode sib_size (mis = 0)
tab sib_size

* Create regression variables

* Age variables:
gen byr_adult = outcomeyr - age_adult
gen frstbrn = (brthord == 1)

* Occupational variables:
gen top_25 = ia_hisc4 == 1 if ia_hisc4 != .
gen top_50 = (ia_hisc4 == 1 | ia_hisc4 == 2) if ia_hisc4 != .
gen bot_25 = ia_hisc4 == 4 if ia_hisc4 != .

* Set up father's occupation variables
gen popwc = (pophisc4 == 1) if pophisc4 != .
gen popsk = (pophisc4 == 1 | pophisc4 == 2) if pophisc4 != .

la var popwc "Father's status"
la var popsk "Father's status"

recast str popocc

* Generate sample restrictions
egen mult_order = seq() if sibling_id != ., by(sibling_id age_child)
egen mult_birth = max(mult_order) if sibling_id != ., by(sibling_id age_child)
gen twins = (mult_birth > 1) if sibling_id != .
drop mult_birth mult_order

gen military = (county_adult == "MILITARY" | county_adult == "ROYAL NAVY")
tab military

gen valid_age = (age_adult >= 18 & byr_adult >= 1870 & byr_adult <= 1893)
tab valid_age

foreach var of varlist age_dist mi_mismatch jw* similar* {
	rename `var' `var'_ICEM
}

gen jw_fname_exact = (jw_fname_orig_ICEM == 1 | jw_fname_edit_ICEM == 1)
gen jw_sname_exact = (jw_sname_ICEM == 1)

sort censusyr RecID_child
merge 1:1 censusyr RecID_child using "$PROJ_PATH/processed/intermediate/names/icem_name_analysis.dta", assert(2 3) keep(3) nogen keepusing(std_fnamefreq interact_namefreq)

sum sib_size, detail
gen sibsize50plus = (sib_size > r(p50))

keep if sibling_id != . & age_child <= 11 & jw_sname_ICEM >= 0.80 & max(jw_fname_orig_ICEM,jw_fname_edit_ICEM) >= 0.80 & similar_10_ICEM <= 20 & max_brthord <= 13 & sib_size <= 11 & valid_age == 1 & military == 0 & twins == 0
drop military twins valid_age byr_adult 

sort censusyr RecID_child	
keep sibling_id ln_wage top_25 top_50 popwc popsk ln_popwage frstbrn sibsize50plus std_fnamefreq interact_namefreq flag_rbp* bpar_mismatch jw_fname_exact jw_sname_exact age_adult popage
save "$PROJ_PATH/processed/data/table_a04.dta", replace

disp "DateTime: $S_DATE $S_TIME"

* EOF
