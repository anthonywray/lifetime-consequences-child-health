version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 04.05_create_health_deficiency_index.do
* PURPOSE: The do file cleans and standardizes the components of the original string variable containing the cause of admission to the hospital.
************

* NOTES:
* Move addresses to sseparate fite
* Move final merges to separate files
* Cut alternatives to HDI that we don't use 

use "$PROJ_PATH/processed/intermediate/hospitals/hospital_admissions_combined.dta", clear

// Merge with cleaned addresses, assigned residential districts and parish

merge m:1 address_orig using "$PROJ_PATH/processed/intermediate/hospitals/hosp_residence_coded.dta", assert(1 3) 
tab _merge if address_orig != ""
drop _merge

* Merge with disease category variables

replace dis_orig = upper(dis_orig)
replace dis_orig = upper(disinreg) if dis_orig == "" | dis_orig == "UNKNOWN"

merge m:1 dis_orig using "$PROJ_PATH/processed/intermediate/diseases/hosp_disease_cleaned.dta", assert(3) keep(3) nogen
merge m:1 dis_orig using "$PROJ_PATH/processed/intermediate/diseases/hosp_disease_variables.dta", assert(2 3) keep(3) nogen
drop disease // icd10
order dis_orig disinreg disease_cleaned-alt dis_group dis_count acute-heart injury-unclass, last
sort regid

save "$PROJ_PATH/processed/temp/mortality_index_input.dta", replace


// Create mortality index variables
	
use "$PROJ_PATH/processed/temp/mortality_index_input.dta", clear

/* Create a categorical variable for cause of admission (coa) using information
	in the variables containing the cleaned diagnosis strings.
	- Use information in main
	- Successively, add information on symptoms, surgery, external factors, 
		objects and severity if missing
*/

gen coa = main

replace coa = regexr(coa,"SEQUELA","")
replace coa = regexr(coa,"^,","")
replace coa = regexr(coa,",$","")
replace coa = regexr(coa,",,",",")
replace coa = regexr(coa,"DIPHTHERIC PARALYSIS","DIPHTHERIA")
replace coa = regexr(coa,"DIPHTHERIC CONJUCTIVITIS","DIPHTHERIA")
replace coa = regexr(coa,"PYREXIA","FEVER")
replace coa = regexr(coa,"ENTERIC","TYPHOID")

replace coa = coa + "," + bodypt + " " + object if coa != "" & bodypt != "" & object == "STONE"
replace coa = bodypt + " " + object if coa == "" & bodypt != "" & object == "STONE"
replace coa = coa + ",STONE" if coa != "" & bodypt == "" & object == "STONE"
replace coa = "STONE" if coa == "" & bodypt == "" & object == "STONE"
replace coa = coa + ",POISONING" if coa != "" & regexm(object,"POISONING")
replace coa = "POISONING" if coa == "" & regexm(object,"POISONING")
replace coa = "FOREIGN OBJECT" if coa == "" & object != ""
replace coa = sympt if coa == "" & sympt != ""
replace coa = surgery if coa == "" & surgery != ""
replace coa = external if coa == "" & external != ""
replace coa = sev if coa == "" & sev != ""
replace coa = bodypt if coa == "" & bodypt != ""

replace coa = regexr(coa,"COMPOUND FRACTURE","FRACTURE")
replace coa = regexr(coa,"GREENSTICK FRACTURE","FRACTURE")

*gen coa_orig = coa

// Create a variable containing the number of co-morbidities, capped at 4

egen coa_string = concat(main sympt surgery external object sev), punct(,)
replace coa_string = regexr(coa_string,"^[,]+","")
replace coa_string = regexr(coa_string,"[,]+$","")
replace coa_string = regexr(coa_string,",,,,,",",")
replace coa_string = regexr(coa_string,",,,,",",")
replace coa_string = regexr(coa_string,",,,",",")
replace coa_string = regexr(coa_string,",,",",")
replace coa_string = regexr(coa_string,",,",",")
replace coa_string = bodypt if coa_string == ""

gen comorbid = length(coa_string) - length(subinstr(coa_string,",","",.)) + 1
tab comorbid
replace comorbid = 4 if comorbid > 4
drop coa_string

// Generate dummy for transfers to other hospitals (no death by construction)

gen transfer = (notes != "" & notes != "DIED" & length(notes) > 1)
replace transfer = 1 if remarks == "M.A.B."

// Generate above and below median length of stay categorical variable (0 = missing)
gen los_group = 0
sum los, detail
replace los_group = 1 if los != . & los <= r(p50)
replace los_group = 2 if los != . & los > r(p50)

recode sex (mis = 9)

// Create district IDs
*egen dist_id = group(district)
*replace dist_id = 0 if county != "LONDON" | district == "" | regexm(district,",") | district == "READMISSION"
*egen new_id = group(dist_id)
*replace dist_id = new_id
*drop new_id

tempfile coa_inprog
save `coa_inprog', replace

/* Deal with multiple causes of admission
	- Use the condition with the highest observed mortality rate
	- Use the condition with the most observations
	- Take the first condition in the alphabet (only 3 cases - DEBILITY/ECZEMA with 485 obs, others singletons)
*/

keep regid died coa
gen obs_id = _n
split coa, parse(",") gen(d)
reshape long d, i(obs_id) j(new_id)
drop if coa == "" | d == ""

egen mort_rate = mean(died), by(d)
gen obs = 1
egen d_freq = total(obs), by(d)

egen max_mr = max(mort_rate), by(coa)
drop if mort_rate != max_mr
egen max_freq = max(d_freq), by(coa)
drop if d_freq != max_freq
keep coa d mort_rate d_freq
bysort coa d mort_rate d_freq: keep if _n == 1
sort coa d
egen order_id = seq(), by(coa)
keep if order_id == 1
keep coa d
tempfile coa_d
save `coa_d', replace

use `coa_inprog', clear
merge m:1 coa using `coa_d', assert(1 3) nogen
replace coa = d if coa != d 
drop d

// Create cause of admission fixed effects

bysort coa sex: gen coa_obs = _N
egen coa_id = group(coa)

// Identify conditions with no variation in p(death in hospital) by gender

egen coa_tot_died = total(died == 1), by(coa sex)
egen coa_tot_aliv = total(died == 0), by(coa sex)

gen coa_sample = (coa_tot_died > 0 & coa_tot_aliv > 0)
drop coa_tot_died coa_tot_aliv

// Group together all conditions with fewer than 25 observations
replace coa_id = 0 if coa_obs < 25
replace coa_id = . if coa_sample == 0 & coa_obs >= 25 
unique coa_id if coa_id != 0 & coa_id != .
egen new_id = group(coa_id)
replace coa_id = new_id
drop new_id coa_sample

sort regid
save "$PROJ_PATH/processed/temp/mortality_index_inprog.dta", replace

// Compute expected mortality separately by gender

forvalues g = 1(1)2 {
	
	use admitage admityr hospid sex died coa coa_id using "$PROJ_PATH/processed/temp/mortality_index_inprog.dta" if coa != "" & coa_id !=. & sex == `g', clear
	
	// Estimate residual mortality at individual level

	reg died i.hospid i.admitage i.admityr, vce(robust)
	predict resid_mort, residuals

	tempfile coa_temp
	save `coa_temp', replace

	use `coa_temp' if coa != "", clear
	collapse (mean) resid_mort, by(coa coa_id) 

	tempfile coa_out
	save `coa_out', replace

	use admitage admityr hospid sex died coa coa_id using "$PROJ_PATH/processed/temp/mortality_index_inprog.dta" if coa != "" & coa_id !=. & sex == `g', clear
	merge m:1 coa using `coa_out', assert(1 3) nogen

	keep coa coa_id resid_mort
	bysort coa coa_id resid_mort: keep if _n == 1
	
	sort coa coa_id
	gen sex = `g'
	order sex coa
	save "$PROJ_PATH/processed/temp/hdi_split_gender_`g'.dta", replace
}
clear
forvalues g = 1(1)2 {
	append using "$PROJ_PATH/processed/temp/hdi_split_gender_`g'.dta"
	rm "$PROJ_PATH/processed/temp/hdi_split_gender_`g'.dta"
}
save "$PROJ_PATH/processed/temp/hdi_split_gender.dta", replace

// Merge with residual mortality rates

use "$PROJ_PATH/processed/temp/mortality_index_inprog.dta", clear
merge m:1 sex coa coa_id using "$PROJ_PATH/processed/temp/hdi_split_gender.dta", assert(1 3) nogen
sort regid

egen death_rate = mean(died), by(coa coa_id sex)

sum resid_mort
egen min_resid_mort = min(resid_mort)
egen max_resid_mort = max(resid_mort)
replace resid_mort = (resid_mort - min_resid_mort)/(max_resid_mort - min_resid_mort)
replace resid_mort = 1 if resid_mort == . & death_rate == 1
replace resid_mort = 0 if resid_mort == . & death_rate == 0
drop min_resid_mort max_resid_mort death_rate

// Restrict sample to cohorts in final analysis
drop if byr_ub_HOSP == 1869 | byr_lb_HOSP == 1902

foreach var of varlist namestr fname_orig fname alt_fn mname_orig mname sname alt_sn byr sex address_orig address_cleaned parish district subdist county stnum fnamestr snamestr { 
	rename `var' `var'_HOSP
}

* Generate household ID proxy
egen hhid_proxy = group(sname_HOSP district_HOSP), missing

* Generate proxy patient ID
gen mname_impute = mname_HOSP
sort sname_HOSP fname_HOSP byr_HOSP district_HOSP admitdate
by sname_HOSP fname_HOSP byr_HOSP district_HOSP (admitdate): carryforward mname_impute, replace
gsort + sname_HOSP fname_HOSP byr_HOSP district_HOSP - admitdate
by sname_HOSP fname_HOSP byr_HOSP district_HOSP: carryforward mname_impute, replace
egen pat_id_proxy = group(sname_HOSP fname_HOSP mname_impute byr_HOSP district_HOSP), missing
drop mname_impute

bysort pat_id_proxy: gen temp = (_n == 1)
egen ever_died = max(died), by(pat_id_proxy)
tab ever_died if temp == 1
drop temp

sort regid

order 	regid pat_id_proxy hhid_proxy hospid namestr_HOSP fnamestr_HOSP snamestr_HOSP fname_orig_HOSP fname_HOSP alt_fn_HOSP mname_orig_HOSP mname_HOSP sname_HOSP alt_sn_HOSP ///
		byr_HOSP byr_lb_HOSP byr_ub_HOSP bdate_lb_HOSP bdate_ub_HOSP age_orig admitage sex_HOSP admit* disch* address_orig_HOSP address_cleaned_HOSP stnum_HOSP postcode parish_HOSP district_HOSP subdist_HOSP county_HOSP ///
		los los_group died ever_died notes dis_orig disease_cleaned-alt dis_group disinreg dis_count acute-unclass resid_mort comorbid-transfer ///
		doctor coa diphth-policy_diseases
		
drop coa_obs coa_id remarks notes dis_count dis_group 

la var regid "Admission identifier for combined data"
la var pat_id_proxy "Proxy for patient identifier"
la var hhid_proxy "Proxy for household identifier"
la var hospid "Hospital identifier"
la var namestr_HOSP "Original name string (hospital records)"
la var los "Length of stay in hospital"
la var died "Indicator for death in hospital"
la var ever_died "Inicator for patient who died in hospital"

la var address_cleaned_HOSP "Residential address cleaned"
la var stnum_HOSP "Residential street number"
la var postcode "Residential post code"
la var parish_HOSP "Residential parish"
la var district_HOSP "Residential district"
la var subdist_HOSP "Residential subdistrict"

la var disease_cleaned "Cleaned cause of admission string"
la var main "Cause of admission, main"
la var sympt "Cause of admission, symptoms"
la var bodypt "Cause of admission, body part"
la var surgery "Cause of admission, surgery"
la var external "Cause of admission, external factor"
la var object "Cause of admission, external object"
la var loc "Cause of admission, location on body"
la var sev "Cause of admission, severity"
la var alt "Cause of admission, alternate"

la var circul "Circulatory system"
la var congenital "Congenital disorders"
la var digest "Digestive system"
la var ent "Ear nose or throat"
la var eye "Diseases of the eye"
la var fever "Infectious fevers"
la var genitals "Reproductive system"
la var heart "Diseases of the heart"
la var immune "Immune system"
la var mouth "Diseases of the mouth"
la var muscskel "Muscular-skeletal system"
la var nervous "Nervous system"
la var nutrition "Diseases of malnutrition"
la var resp "Respiratory system"
la var skin "Diseases of the skin"
la var injury "Injuries"
la var tuberc "Tubercular disease"
la var urinary "Urinary system"

la var comorbid "Number of causes of admission"
la var transfer "=1 if transferred to another hospital"
la var coa "Consolidated cause of admission string"
la var los_group "Length of stay, binned"

desc, f
save "$PROJ_PATH/processed/intermediate/hospitals/london_hospital_admission_records.dta", replace

rm "$PROJ_PATH/processed/temp/mortality_index_input.dta"
rm "$PROJ_PATH/processed/temp/mortality_index_inprog.dta"
rm "$PROJ_PATH/processed/temp/hdi_split_gender.dta"

disp "DateTime: $S_DATE $S_TIME"

* EOF