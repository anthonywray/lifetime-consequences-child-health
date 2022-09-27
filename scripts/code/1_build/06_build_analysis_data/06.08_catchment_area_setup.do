version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 06.08_catchment_area_setup.do
* PURPOSE: This do file gathers descriptive characteristics and defines catchment areas for each hospital in 1881, 1891, or 1901
************

// Gather district characteristics

forvalues y = 1881(10)1901 {

	use "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_identifiers.dta", clear
	merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_demographic.dta", assert(2 3) keep(3) nogen
	merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_residence.dta", assert(2 3) keep(3) keepusing(RegCnty RegDist ConParID) nogen
	merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_birthplace.dta", assert(2 3) keep(3) nogen keepusing(HollerB)
	merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_occupation.dta", assert(2 3) keep(3) nogen keepusing(hisco Occ)
	merge m:1 hisco using "$PROJ_PATH/processed/intermediate/occupations/hisco_to_hisclass.dta", keep(1 3) nogen keepusing(hisclass)
	merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/sibling_ids/sibling_ids_`y'.dta", assert(2 3) keep(3) keepusing(sibling_id sib_type brthord mbrthord fbrthord sibsize msibsize fsibsize) nogen
	merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/mom_vars/icem_mom_`y'_identifiers.dta", keep(1 3) keepusing(momloc) nogen
	merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`y'_identifiers.dta", keep(1 3) keepusing(poploc) nogen
	recode momloc poploc (mis = 0)
	merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/mom_vars/icem_mom_`y'_demographic.dta", keep(1 3) keepusing(momage) nogen
	gen mombyr = Year - momage
	drop momage
	merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`y'_demographic.dta", keep(1 3) keepusing(popage) nogen
	gen popbyr = Year - popage
	drop popage
	merge 1:1 Year RecID using "$PROJ_PATH/processed/intermediate/icem/pop_vars/icem_pop_`y'_occupation.dta", keep(1 3) keepusing(pophisco) nogen
	rename hisco temp_hisco
	rename hisclass temp_hisclass
	rename pophisco hisco
	merge m:1 hisco using "$PROJ_PATH/processed/intermediate/occupations/hisco_to_hisclass.dta", keep(1 3) nogen keepusing(hisclass)
	rename hisco pophisc
	rename hisclass pophisclass
	rename temp_hisco hisco
	rename temp_hisclass ic_hisclass
	rename Occ ic_occ

	keep if RegCnty == "London (Parts Of Middlesex, Surrey & Kent)"

	// Add HISCLASS variables	
	label define hisc4lab 1 "White Collar" 2 "Skilled" 3 "Semi skilled" 4 "Unskilled", replace
	local hisco_vars "ic_"
	foreach histype of local hisco_vars {
		gen `histype'hisc4 = .
		replace `histype'hisc4 = 1 if `histype'hisclass == 1 | `histype'hisclass == 2 | `histype'hisclass == 3 | `histype'hisclass == 4 | `histype'hisclass == 5
		replace `histype'hisc4 = 2 if `histype'hisclass == 6 | `histype'hisclass == 7 | `histype'hisclass == 8
		replace `histype'hisc4 = 3 if `histype'hisclass == 9
		replace `histype'hisc4 = 4 if `histype'hisclass == 10 | `histype'hisclass == 11 | `histype'hisclass == 12
		la val `histype'hisc4 hisc4lab
	}
	rename ic_hisclass hisclass
	
	// Generate variables for hospital catchment areas

	gen catch_barts = (RegDist == "Holborn" | RegDist == "Shoreditch" | RegDist == "Islington")
	tab RegDist if catch_barts == 1
	gen catch_gosh = (RegDist == "Holborn" | RegDist == "Islington" | RegDist == "Pancras" | RegDist == "Kensington" | RegDist == "Marylebone" | RegDist == "Shoreditch" | RegDist == "St Giles")
	tab RegDist if catch_gosh == 1
	gen catch_guys = (RegDist == "St Olave Southwark" | RegDist == "St Saviour Southwark")
	tab RegDist if catch_guys == 1
	gen catch_out = (catch_barts == 0 & catch_gosh == 0 & catch_guys == 0)

	// Identify part of catchment area that does not overlap with other hospitals

	gen excl_barts = (catch_barts == 0 & (catch_gosh == 1 | catch_guys == 1))
	gen excl_gosh = (catch_gosh == 0 & (catch_barts == 1 | catch_guys == 1))
	gen excl_guys = (catch_guys == 0 & (catch_barts == 1 | catch_gosh == 1))

	gen child0to4 = (Age <= 4)
	gen child5to11 = (Age >= 5 & Age <= 11)
	gen child = (child0to4 == 1 | child5to11 == 1)

	*bysort sibling_id: gen sibsize = _N - 1 if sibling_id != .

	gen popunsk = 0 if child == 1 & poploc != 0
	replace popunsk = 1 if popunsk == 0 & pophisclass >= 10 & pophisclass <= 12

	gen headunsk = 0 if Rela == 11
	replace headunsk = 1 if headunsk == 0 & hisclass >= 10 & hisclass <= 12

	gen headmar = 0 if Rela == 11
	replace headmar = 1 if headmar == 0 & Mar == 2

	gen childwmom = 0 if child == 1
	replace childwmom = 1 if childwmom == 0 & momloc != 0

	gen childwpop = 0 if child == 1
	replace childwpop = 1 if childwpop == 0 & poploc != 0

	gen immigrant = (HollerB != "ENG")
	
	gen in_laborforce = (ic_hisc4 != .)	
	gen in_school = ((regexm(ic_occ,"SCHOLAR") | regexm(ic_occ,"SCHOOL") | ic_occ == "SCOLAR" | ic_occ == "SCHOLA" | ic_occ == "SCHOLOUR" | ic_occ == "SCHR" | ic_occ == "SCHOL" | ic_occ == "SCH" | ic_occ == "STUDENT" | ic_occ == "AT HOME")) & regexm(ic_occ,"MASTER") == 0 & regexm(ic_occ,"MONITOR") == 0 & regexm(ic_occ,"MISTRESS") == 0 & regexm(ic_occ,"TEACHER") == 0

	la var child0to4 "Share aged 0 to 4"
	la var child5to11 "Share aged 5 to 11"
	la var sibsize "Sibship size"
	la var childwmom "Share age 0 to 11 living with mother"
	la var childwpop "Share age 0 to 11 living with father"
	la var popunsk "Share of unskilled fathers"
	la var headunsk "Share of unskilled household heads"
	la var headmar "Share of household heads married"
	la var immigrant "Share of immigrants"
	la var in_laborforce "Share in labor force"
	la var in_school "Share aged 5 to 18 in school"

	sort RecID
	save "$PROJ_PATH/processed/intermediate/final_build/hosp_catchment_area_`y'.dta", replace

}

cp "$PROJ_PATH/processed/intermediate/final_build/hosp_catchment_area_1881.dta" "$PROJ_PATH/processed/data/figure_a05_a06.dta", replace
cp "$PROJ_PATH/processed/intermediate/final_build/hosp_catchment_area_1891.dta" "$PROJ_PATH/processed/data/table_a08.dta", replace

disp "DateTime: $S_DATE $S_TIME"

* EOF
