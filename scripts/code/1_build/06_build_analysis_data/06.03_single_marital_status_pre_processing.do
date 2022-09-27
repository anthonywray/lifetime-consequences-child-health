version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 06.03_single_marital_status_pre_processing.do
* PURPOSE: This do file extracts generates the samples for long-run marital status of men and women.
************

args gender

// Extract ICEM-ICEM census links that meet final criteria

if `gender' == 1 {
	local matchvar "jw* similar_10 flag_recode_bpl* bpar_mismatch"
}
else if `gender' == 2 {
	local matchvar "jw* similar_10"
}

forvalues y = 1881(10)1901 {

	local min_yr = `y' + 10
	
	forvalues z = `min_yr'(10)1911 {
	
		use censusyr outcomeyr RecID* ///
			age_child age_adult age_dist sex ///
			`matchvar' ///
			using "$PROJ_PATH/processed/intermediate/icem_linkage_`y'_`z'/unique_matches_`y'_`z'.dta", clear

		foreach var of varlist age_dist jw* similar* { 
			rename `var' `var'_ICEM
		}

		if `gender' == 1 {
		
			rename flag_recode_bpl_`y' flag_rbp_child
			rename flag_recode_bpl_`z' flag_rbp_adult
		}
		
		tab age_dist_ICEM, m
				
		* Apply critiera for quality of name match:

		sum jw_sname_ICEM, d
		sum jw_fname_orig_ICEM, d
		sum jw_fname_edit_ICEM, d

		tab similar_10_ICEM, m

		keep if jw_sname_ICEM >= 0.80 & max(jw_fname_orig_ICEM,jw_fname_edit_ICEM) >= 0.80 & similar_10_ICEM <= 20

		* Restrict to men or women

		keep if sex == `gender'
		
		if `gender' == 1 {
		
			* Gather variables from childhood census
		
			rename censusyr Year
			rename RecID_child RecID
			
			merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`y'_occupation.dta", keep(1 3) nogen keepusing(pophisco popocc popoccode)
			
			rename RecID RecID_child
			rename Year censusyr
		
		}
				
		* Gather variables from adulthood census
		
		rename outcomeyr Year
		rename RecID_adult RecID
		
		merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`z'_demographic.dta", assert(2 3) keep(3) nogen keepusing(Mar)
		
		if `gender' == 1 {
		
			merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`z'_occupation.dta", assert(2 3) keep(3) nogen keepusing(hisco Occ Occode)
			merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`z'_residence.dta", assert(2 3) keep(3) nogen keepusing(RegCnty)

		}
		
		rename Year outcomeyr
		rename RecID RecID_adult
		
		rename Mar ia_marst
		
		if `gender' == 1 {
		
			rename hisco ia_hisco 
			rename Occ ia_occ
			rename Occode ia_occode

			
			* Changes to ICEM county names:

			replace RegCnty = "Kent" if RegCnty == "Kent (Extra London)"
			replace RegCnty = "London" if RegCnty == "London (Parts Of Middlesex, Surrey & Kent)"
			replace RegCnty = "Middlesex" if RegCnty == "Middlesex (Extra London)"
			replace RegCnty = "Surrey" if RegCnty == "Surrey (Extra London)"
			replace RegCnty = "Yorkshire" if regexm(RegCnty,"Yorkshire")
			replace RegCnty = upper(RegCnty)
			rename RegCnty county_adult
			
			
			gen single = (ia_marst == 1) 
			gen married = (ia_marst == 2 | ia_marst == 3 | ia_marst == 4 | ia_marst == 5) 
			
			gen military = (county_adult == "MILITARY" | county_adult == "ROYAL NAVY")

			gen jw_fname_exact = (jw_fname_orig_ICEM == 1 | jw_fname_edit_ICEM == 1)
			gen jw_sname_exact = (jw_sname_ICEM == 1)
			
		}
		else if `gender' == 2 {
				
			gen single = (ia_marst == 1)
		
			keep if single == 1
			drop single
			
		}

		* Restrict to cohorts of interest:

		gen byr_adult = outcomeyr - age_adult
		gen valid_age = (age_adult >= 18 & byr_adult >= 1870 & byr_adult <= 1893)

		tab byr_adult, m
		tab valid_age, m

		keep if valid_age == 1
		drop valid_age
		
		tempfile icem_double_links_`y'_`z'
		save `icem_double_links_`y'_`z'', replace
	}
}
clear
forvalues y = 1881(10)1901 {
	
	local min_yr = `y' + 10

	forvalues z = `min_yr'(10)1911 {
		append using `icem_double_links_`y'_`z''
	}
	
}

if `gender' == 1 {

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

	gen valid_occ = (!missing(pophisclass) & !missing(ia_hisclass))

	tab valid_occ
	tab military

}

* Track number of years between censuses

if `gender' == 1 {

	forvalues y = 10(10)30 {

		gen link_`y' = (outcomeyr - censusyr == `y')
		gen single_`y' = single*link_`y'
		gen married_`y' = married*link_`y'
		
		gen jw_fname_exact_`y' = jw_fname_exact*(link_`y')
		gen jw_sname_exact_`y' = jw_sname_exact*(link_`y')
		
		gen flag_rbp_child_`y' = flag_rbp_child*(link_`y')
		gen flag_rbp_adult_`y' = flag_rbp_adult*(link_`y')
		
		gen bpar_mismatch_`y' = bpar_mismatch*(link_`y')
	}

	collapse (max) link_* single_* married_* jw_fname_exact_* jw_sname_exact_* flag_rbp_child_* flag_rbp_adult_* bpar_mismatch_*, by(censusyr RecID_child)

	sum link_* single_* married_*

}
else if `gender' == 2 {

	forvalues y = 10(10)30 {
		gen link_`y' = (outcomeyr - censusyr == `y')
	}

	collapse (max) link_*, by(censusyr RecID_child)

	sum link_*

}

* Save double links					
unique censusyr RecID_child
save "$PROJ_PATH/processed/temp/singles_`gender'_double_links.dta", replace

* EOF