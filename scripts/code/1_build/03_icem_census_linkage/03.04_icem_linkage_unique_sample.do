version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 03.04_icem_linkage_unique_sample.do
* PURPOSE: This do file chooses the best match to create a uniquely matched sample
************

args t_1 t_2

local year_list "`t_1' `t_2'"

*********************************************************************************************************************
*********** I-CeM County Crosswalk *************
*********************************************************************************************************************

* Create birth county crosswalk

insheet using "$PROJ_PATH/raw/geography/ICEM_County_list.txt", clear
rename v1 county
drop if regexm(county,"I-CeM Guide Page") 
gen cc = regexm(county,"[a-z]") & regexm(county,"see CTRY variable") == 0
recode cc (1 = 2)
replace cc = 1 if cc[_n+1] == 2
replace cc = 3 if cc[_n-1] == 2

gen obs_id = (cc == 1)
gen cid = 1 if _n == 1
replace cid = obs_id + cid[_n-1] if _n > 1
drop obs_id
reshape wide county, i(cid) j(cc)
drop cid
rename county1 county_code
rename county2 county_name
rename county3 country_code

bysort county_code: gen mult_code = (_N>1)
gen original = regexm(county_name,"[ ]\(see(.)*\)$") == 0
egen total_orig = total(original == 1), by(county_code)
drop if total_orig > 0 & original == 0 & mult_code == 1
drop mult_code original total_orig

replace county_name = regexr(county_name,"[ ]\(undefined\)$","")
replace county_name = regexr(county_name,"[ ]-[ ]part$","")
replace county_name = regexr(county_name,"&","and")

replace county_name = "Foreign" if county_name == "All Foreign birthplaces"
replace county_name = "At sea" if county_name == "All those born at sea"
replace county_name = "Unknown" if county_name == "Unknown; cannot be coded"

replace country_code = "" if country_code == "see CTRY variable"
compress
save "$PROJ_PATH/processed/intermediate/geography/icem_county_codebook.dta", replace


*********************************************************************************************************************
*********** I-CeM Unique Sample *************
*********************************************************************************************************************

// Set unique sample

use "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/using_sample_`t_1'_`t_2'.dta", clear

// Compute number of similar records

gen jw_name = (max(jw_fname_orig,jw_fname_edit)+jw_sname)/2
egen max_jw_name = max(jw_name), by(RecID_`t_1')

gen age_dist = abs(age - age_base)
egen min_age_dist = min(age_dist), by(RecID_`t_1')

save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/similar_setup.dta", replace

foreach x in 0 5 10 15 {
	local y = 1+(`x'/100)
	use "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/similar_setup.dta" if jw_name >= max_jw_name/`y' & (age_dist - min_age_dist) <= 1, clear
	keep RecID_`t_1' RecID_`t_2'
	duplicates drop 
	bysort RecID_`t_1': gen similar_`x' = _N
	drop RecID_`t_2'
	bysort RecID_`t_1' similar_`x': keep if _n == 1
	save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/similar_`x'.dta", replace
}

use "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/similar_setup.dta", clear
foreach x in 0 5 10 15 {
	merge m:1 RecID_`t_1' using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/similar_`x'.dta", assert(1 3) keep(1 3) nogen
	recode similar_`x' (mis = 0)
	replace similar_`x' = similar_`x' - 1 if similar_`x' > 0
	rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/similar_`x'.dta"
}

drop max_jw_name
rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/similar_setup.dta"

// Drop records worse than 0.85 JW distance
keep if max(jw_fname_orig, jw_fname_edit) >= 0.85 & jw_sname >= 0.85

// Drop if age difference > 5 years
drop if age_dist > 5
drop min_age_dist

// Save similar records, JW, and demographic variables to temp files

save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/store_variables_inprog.dta", replace
keep RecID_`t_1' similar*
bysort RecID_`t_1' similar*: keep if _n == 1
save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/var_similar.dta", replace

use "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/store_variables_inprog.dta", clear
keep RecID_`t_1' RecID_`t_2' jw*
bysort RecID_`t_1' RecID_`t_2' jw*: keep if _n == 1
save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/var_jw.dta", replace

use "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/store_variables_inprog.dta", clear
keep RecID_`t_1' RecID_`t_2' sex
bysort RecID_`t_1' RecID_`t_2' sex: keep if _n == 1
save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/var_sex.dta", replace

use "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/store_variables_inprog.dta", clear
keep RecID_`t_1' age_base
bysort RecID_`t_1' age_base: keep if _n == 1
save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/var_age_`t_1'.dta", replace

use "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/store_variables_inprog.dta", clear
keep RecID_`t_2' age
bysort RecID_`t_2' age: keep if _n == 1
save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/var_age_`t_2'.dta", replace


// Add birth parish and birth country for matching, by county

#delimit ;
local county_list "	ALD GSY JSY SRK 
					BDF BKM BRK CAM CHS CON CUL DBY DEV DOR DUR ESS GLS HAM HEF HRT HUN IOM IOW KEN LAN LEI LIN LND MDX NBL NFK NTH NTT OXF RUT SAL SFK SOM SRY SSX STS WAR WES WIL WOR YKS 
					ANT ARM CAR CAV CLA COR DON DOW DUB FER GAL KER KID KIK LDY LET LEX LIM LOG LOU MAY MEA MOG OFF ROS SLI TIP TYR WAT WEM WEX WIC 
					ABD ANS ARL AYR BAN BEW BUT CAI CLK DFS DNB ELN FIF INV KCD KKD KRS LKS MLN MOR NAI OKI PEE PER RFW ROC ROX SEL SHI STI SUT WIG WLN 
					AGY BRE CAE CGN CMN DEN FLN GLA MER MGY MON PEM RAD 
					FOR SEA"
;
#delimit cr

foreach county of local county_list {
	use RecID_`t_1' RecID_`t_2' bcounty using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/store_variables_inprog.dta" if bcounty == "`county'", clear
	count
	if r(N) > 0 {
		bysort RecID_`t_1' RecID_`t_2' bcounty: keep if _n == 1
		rename bcounty bcty_match
		
		foreach y of local year_list {
		
			rename RecID_`y' RecID
			sort RecID
			save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/birth_place_match_input_`y'_`county'.dta", replace
			
			keep RecID
			bysort RecID: keep if _n == 1
		
			// Merge with birth parish variables
			
			merge 1:1 RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_birthplace.dta", keep(3) nogen keepusing(Bpstring Cnti BpCtry Ctry HollerB)
			recast str Cnti
			compress Bpstring Cnti
			
			rename Cnti std_par
			rename BpCtry cnti
			rename Ctry alt_cnti
			replace Bpstring = upper(Bpstring)
			
			merge m:1 Bpstring std_par cnti alt_cnti using "$PROJ_PATH/processed/intermediate/geography/icem_bpstring_xwk.dta", keep(1 3)
			
			replace std_par1 = std_par if _merge == 1
			replace std_par2 = std_par if _merge == 1 & alt_cnti != ""
			replace bcounty1 = cnti if _merge == 1
			replace bcounty2 = alt_cnti if _merge == 1
			replace primary_county1 = 1 if _merge == 1
			replace primary_county2 = 0 if _merge == 1 & alt_cnti != ""
			gen flag_recode_bpl_`y' = (_merge == 3)
			drop _merge std_par cnti alt_cnti Bpstring
			sort RecID
			compress
			save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/birth_place_match_inprog_`y'_`county'.dta", replace
			
			use "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/birth_place_match_input_`y'_`county'.dta", clear
			merge m:1 RecID using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/birth_place_match_inprog_`y'_`county'.dta", keep(3) nogen
			
			// Reshape multiple versions of birth county and parish

			replace std_par2 = std_par1 if std_par2 == "" & bcounty2 != ""
			save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/cnti_reshape_input.dta", replace
			keep if std_par2 == ""
			rename std_par1 temp_std_par
			rename bcounty1 temp_bcounty
			rename primary_county1 temp_primary_county
			drop std_par* bcounty* primary_county*
			rename temp_std_par std_par
			rename temp_bcounty bcounty
			rename temp_primary_county primary_county
			save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/cnti_reshape_unique.dta", replace

			use "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/cnti_reshape_input.dta", clear
			keep if std_par2 != ""
			gen long obs_id = _n
			count
			reshape long std_par bcounty primary_county, i(obs_id) j(new_id)
			drop obs_id new_id
			drop if bcounty == ""
			append using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/cnti_reshape_unique.dta"
			
			rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/cnti_reshape_unique.dta"
			rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/cnti_reshape_input.dta"
				
			// Recode London as county

			merge m:1 std_par using "$PROJ_PATH/processed/intermediate/geography/icem_london_std_par.dta", keep(1 3)
			gen bcounty_orig = bcounty
			replace bcounty = "LND" if (bcounty == "KEN" | bcounty == "MDX" | bcounty == "SRY") & _merge == 3
			drop _merge

			// Drop mismatched counties

			drop if bcounty != bcty_match
			drop bcounty

			// Clean standard parish variable
			
			replace std_par = "" if std_par == "Unknown" | std_par == "Not Applicable" | std_par == "Not Coded"
			replace std_par = upper(std_par)

			// Replace country code if inconsistent

			gen county_code = bcty_match
			merge m:1 county_code using "$PROJ_PATH/processed/intermediate/geography/icem_county_codebook.dta", keep(1 3) nogen keepusing(country_code)
			replace HollerB = country_code if HollerB != country_code & country_code != ""
			drop county_code country_code

			rename std_par y`y'_std_par
			rename bcounty_orig y`y'_bcounty_orig
			rename primary_county y`y'_primary_county
			
			rename HollerB bcountry_`y'
			rename RecID RecID_`y'
		}
		
		foreach y of local year_list {
			rename y`y'_std_par std_par_`y'
			rename y`y'_bcounty_orig bcounty_orig_`y'
			rename y`y'_primary_county primary_county_`y'
		}
 
		compress
		save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/birth_place_match_output_`county'.dta", replace
		

	}
}

foreach county of local county_list {
	foreach y of local year_list {
		capture rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/birth_place_match_input_`y'_`county'.dta"
		capture rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/birth_place_match_inprog_`y'_`county'.dta"
	}	
}

clear
foreach county of local county_list {
	capture append using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/birth_place_match_output_`county'.dta"
}

// Drop if mismatched birth country

drop if bcountry_`t_1' != bcountry_`t_2'
		
// Prioritize match on parish of birth in census

// Exact match

gen bparish_match = 0
replace bparish_match = 1 if std_par_`t_1' == std_par_`t_2' & std_par_`t_2' != "" & std_par_`t_2' != "LONDON"

foreach y of local year_list {
	egen tot_bpar_match = total(bparish_match == 1), by(RecID_`y')
	drop if tot_bpar_match > 0 & bparish_match == 0
	drop tot_bpar_match 
}

gen bparish_match_exact = bparish_match

// Jaro-Winkler match on original birth place string

foreach y of local year_list {
	rename RecID_`y' RecID
	merge m:1 RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_birthplace.dta", keep(3) nogen keepusing(Bpstring)
	compress Bpstring
	rename Bpstring bparish_`y'
	rename RecID RecID_`y'
}
save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/jw_input.dta", replace

keep bparish_`t_1' bparish_`t_2'
bysort bparish_`t_1' bparish_`t_2': keep if _n == 1
jarowinkler bparish_`t_1' bparish_`t_2', gen(jw_bpar)
keep if jw_bpar >= 0.9
save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/jw_dist.dta", replace

use "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/jw_input.dta", clear
merge m:1 bparish_`t_1' bparish_`t_2' using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/jw_dist.dta", keep(1 3) nogen
recode jw_bpar (mis = 0)
rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/jw_input.dta"
rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/jw_dist.dta"

gen east_west = ((regexm(bparish_`t_1',"EAST") & regexm(bparish_`t_2',"WEST")) | (regexm(bparish_`t_1',"WEST") & regexm(bparish_`t_2',"EAST")) )
replace bparish_match = 1 if jw_bpar >= 0.9 & east_west == 0

foreach y of local year_list {
	egen tot_bpar_match = total(bparish_match == 1), by(RecID_`y')
	drop if tot_bpar_match > 0 & bparish_match == 0
	drop tot_bpar_match 
}
drop east_west jw_bpar

// Substring match

gen bparlen`t_1' = length(bparish_`t_1')
gen bparlen`t_2' = length(bparish_`t_2')

gen bpar_short = bparish_`t_1'  if bparlen`t_1'  <= bparlen`t_2'
replace bpar_short = bparish_`t_2' if bparlen`t_1'  > bparlen`t_2'
gen bpar_long = bparish_`t_2' if bpar_short == bparish_`t_1' 
replace bpar_long = bparish_`t_1'  if bpar_short == bparish_`t_2'

replace bparish_match = 1 if substr(bpar_long,1,length(bpar_short)) == bpar_short & bparish_`t_1'  != "" & bparish_`t_2' != "" & bparish_`t_2' != "LONDON"

foreach y of local year_list {
	egen tot_bpar_match = total(bparish_match == 1), by(RecID_`y')
	drop if tot_bpar_match > 0 & bparish_match == 0
	drop tot_bpar_match 
}

replace bparish_match = 1 if substr(strreverse(bpar_long),1,length(bpar_short)) == strreverse(bpar_short) & bparish_`t_1' != "" & bparish_`t_2' != "" & bparish_`t_2' != "LONDON"

foreach y of local year_list {
	egen tot_bpar_match = total(bparish_match == 1), by(RecID_`y')
	drop if tot_bpar_match > 0 & bparish_match == 0
	drop tot_bpar_match 
}
drop bpar_long bpar_short bparlen`t_1' bparlen`t_2'

replace bparish_match = 1 if bparish_`t_1' == bparish_`t_2' & bparish_`t_2' == "LONDON"

// Excluding conflict if multiple matches

gen bpar_missing = (std_par_`t_1' == "" | std_par_`t_2' == "")
gen bpar_mismatch = (std_par_`t_1' != "" & std_par_`t_2' != "" & std_par_`t_1' != std_par_`t_2')

foreach y of local year_list {
	egen tot_bpar_miss = total(bpar_missing == 1), by(RecID_`y')
	drop if bpar_mismatch == 1 & tot_bpar_miss > 0
	drop tot_bpar_miss
}
drop bpar_missing bpar_mismatch 

gen bpar_mismatch = (std_par_`t_1' != std_par_`t_2' & std_par_`t_1' != "" & std_par_`t_2' != "" & std_par_`t_1' != "London" & std_par_`t_2' != "London" & bparish_match != 1)
drop std_par*
		
// Prioritize primary county match

foreach y of local year_list {
	egen tot_pc = total(primary_county_`y' == 1), by(RecID_`y')
	drop if tot_pc > 0 & primary_county_`y' == 0
	drop tot_pc
}

// Prioritize county match within London

foreach y of local year_list {
	egen tot_ldn_cty = total(bcounty_orig_`t_1' == bcounty_orig_`t_2'), by(RecID_`y')
	drop if tot_ldn_cty > 0 & bcounty_orig_`t_1' != bcounty_orig_`t_2'
	drop tot_ldn_cty
}
drop bcounty*

egen tot_ldn_cty = total(bcty_match == "LND"), by(RecID_`t_1' RecID_`t_2')
drop if tot_ldn_cty > 0 & bcty_match != "LND"
drop tot_ldn_cty

// Save birth place match information

duplicates drop
save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/birthplace_matched.dta", replace

keep RecID_`t_1' RecID_`t_2'
bysort RecID_`t_1' RecID_`t_2': keep if _n == 1
save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/birthplace_matched_ids.dta", replace

foreach county of local county_list {
	capture rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/birth_place_match_output_`county'.dta"
}

// Reload age, sex, and name variables

use "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/var_sex.dta", clear
merge m:1 RecID_`t_1' using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/var_age_`t_1'.dta", keep(3) nogen
merge m:1 RecID_`t_2' using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/var_age_`t_2'.dta", keep(3) nogen
merge m:1 RecID_`t_1' RecID_`t_2' using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/var_jw.dta", keep(3) nogen
merge m:1 RecID_`t_1' RecID_`t_2' using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/birthplace_matched_ids.dta", keep(3) nogen

// Prioritize closest age match

gen age_dist = abs(age - age_base)

foreach y of local year_list {
	egen min_age_dist = min(age_dist), by(RecID_`y')
	drop if age_dist != min_age_dist
	drop min_age_dist
}

// Prioritize best match on name (if best match is sufficiently different from second best): average first and last name

foreach y of local year_list {
	egen max_jw_name = max(jw_name), by(RecID_`y')
	save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/maxname_setup_`t_1'_`t_2'_`y'.dta", replace
	
	keep if jw_name != max_jw_name
	egen second_jw_name = max(jw_name), by(RecID_`y')
	keep RecID_`y' second_jw_name
	bysort RecID_`y' second_jw_name: keep if _n == 1
	save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/second_name_`t_1'_`t_2'_`y'.dta", replace
	
	use "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/maxname_setup_`t_1'_`t_2'_`y'.dta", clear
	merge m:1 RecID_`y' using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/second_name_`t_1'_`t_2'_`y'.dta", assert(1 3) keep(1 3) nogen
	replace second_jw_name = max_jw_name if second_jw_name == .
	rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/maxname_setup_`t_1'_`t_2'_`y'.dta"
	rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/second_name_`t_1'_`t_2'_`y'.dta"
	
	gen jw_gap = (max_jw_name - second_jw_name)
	drop if (jw_name != max_jw_name & second_jw_name < max_jw_name/1.1 & jw_gap != .)
	drop max_jw_name second_jw_name jw_gap
	duplicates drop
}

// Prioritize best match on name stage 2: separate for first and last names

gen jw_fname = max(jw_fname_orig,jw_fname_edit)

foreach y of local year_list {
	egen max_jw_fname = max(jw_fname), by(RecID_`y')
	egen max_jw_sname = max(jw_sname), by(RecID_`y')

	save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/maxname_setup_`t_1'_`t_2'_`y'.dta", replace
	keep if jw_fname != max_jw_fname
	egen second_jw_fname = max(jw_fname), by(RecID_`y')
	keep RecID_`y' second_jw_fname
	bysort RecID_`y' second_jw_fname: keep if _n == 1
	save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/second_name_`t_1'_`t_2'_`y'.dta", replace
	
	use "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/maxname_setup_`t_1'_`t_2'_`y'.dta", clear
	merge m:1 RecID_`y' using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/second_name_`t_1'_`t_2'_`y'.dta", assert(1 3) keep(1 3) nogen
	replace second_jw_fname = max_jw_fname if second_jw_fname == .
	rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/maxname_setup_`t_1'_`t_2'_`y'.dta"
	rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/second_name_`t_1'_`t_2'_`y'.dta"
	
	save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/maxname_setup_`t_1'_`t_2'_`y'.dta", replace
	keep if jw_sname != max_jw_sname
	egen second_jw_sname = max(jw_sname), by(RecID_`y')
	keep RecID_`y' second_jw_sname
	bysort RecID_`y' second_jw_sname: keep if _n == 1
	save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/second_name_`t_1'_`t_2'_`y'.dta", replace
	
	use "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/maxname_setup_`t_1'_`t_2'_`y'.dta", clear
	merge m:1 RecID_`y' using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/second_name_`t_1'_`t_2'_`y'.dta", assert(1 3) keep(1 3) nogen	
	replace second_jw_sname = max_jw_sname if second_jw_sname == .
	
	rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/maxname_setup_`t_1'_`t_2'_`y'.dta"
	rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/second_name_`t_1'_`t_2'_`y'.dta"
	
	gen jw_fgap = max_jw_fname - second_jw_fname
	gen jw_sgap = max_jw_sname - second_jw_sname
	drop if (jw_fname != max_jw_fname & second_jw_fname < max_jw_fname/1.1 & jw_fgap != .) | (jw_sname != max_jw_sname & second_jw_sname < max_jw_sname/1.1 & jw_sgap != .)
	drop max_jw_*name second_jw_*name jw_*gap
}

// Flag middle initial mismatch

foreach y of local year_list {
	rename RecID_`y' RecID
	merge m:1 RecID using "$PROJ_PATH/raw/icem_sl/ICEM_Names_EW_`y'.dta", assert(2 3) keep(3) nogen keepusing(Pname Oname)
	recast str Oname
	merge m:1 Pname Oname sex using "$PROJ_PATH/processed/intermediate/names/midnames_`y'.dta", assert(2 3) keep(3) nogen keepusing(midname)
	drop Pname Oname
	rename midname midname_`y'
	rename RecID RecID_`y'
}
gen temp_mi_mismatch = (substr(midname_`t_1',1,1) != substr(midname_`t_2',1,1) & midname_`t_1' != "" & midname_`t_2' != "")
egen total_mismatch = total(temp_mi_mismatch == 1), by(RecID_`t_1' RecID_`t_2')
gen mi_mismatch = (total_mismatch > 0)
drop temp_mi_mismatch total_mismatch midname*

sort RecID_`t_1' RecID_`t_2' age sex jw*
save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/age_name_matched.dta", replace

keep RecID_`t_1' RecID_`t_2'
bysort RecID_`t_1' RecID_`t_2': keep if _n == 1
save "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/age_name_matched_ids.dta", replace

use "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/birthplace_matched.dta", clear
merge m:1 RecID_`t_1' RecID_`t_2' using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/age_name_matched_ids.dta", keep(3) nogen
joinby RecID_`t_1' RecID_`t_2' using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/age_name_matched.dta"
	
merge m:1 RecID_`t_1' using "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/var_similar.dta", keep(3) nogen

gen censusyr = `t_1'
gen outcomeyr = `t_2'

foreach var in RecID bparish {
	rename `var'_`t_1' `var'_child
	rename `var'_`t_2' `var'_adult
}

rename age_base age_child
rename age age_adult

order censusyr outcomeyr RecID* age* age_dist sex bparish* bcty_match bcountry* primary* flag* bparish_match bpar_mismatch mi_mismatch jw* similar*

tab bparish_match, m
tab bparish_match_exact, m
tab bcty_match, m 
tab bpar_mismatch, m
tab mi_mismatch, m 
tab flag_recode_bpl_`t_1', m
tab flag_recode_bpl_`t_2', m
tab primary_county_`t_1', m
tab primary_county_`t_2', m

drop bparish_child bparish_adult bparish_match_exact bcty_match primary_county*

unique RecID_child RecID_adult
bysort RecID_child: gen unique_child = (_N == 1)
egen unique_adult = total(unique_child == 1), by(RecID_adult)
sort RecID_child RecID_adult

// Save multiple matches
save "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/multiple_matches_`t_1'_`t_2'.dta", replace

// Restrict to unique matches
keep if unique_child == 1 & unique_adult == 1
drop unique_child unique_adult
save "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/unique_matches_`t_1'_`t_2'.dta", replace

rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/store_variables_inprog.dta"
rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/var_sex.dta"
rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/var_age_`t_1'.dta"
rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/var_age_`t_2'.dta"
rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/var_jw.dta"
rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/birthplace_matched_ids.dta"
rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/birthplace_matched.dta"
rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/age_name_matched.dta"
rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/age_name_matched_ids.dta"
rm "$PROJ_PATH/processed/temp/icem_linkage_`t_1'_`t_2'/var_similar.dta"

// Using sample no longer needed - remove to save disk space
rm "$PROJ_PATH/processed/intermediate/icem_linkage_`t_1'_`t_2'/using_sample_`t_1'_`t_2'.dta"

disp "DateTime: $S_DATE $S_TIME"

* EOF
