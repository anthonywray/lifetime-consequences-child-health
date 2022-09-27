version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 02.03_icem_birthplace_cleanup.do
* PURPOSE: This do file cleans the birth place variables in the I-CeM files
*		a. Create codebook and crosswalk of birth counties and countries
*		b. Create crosswalk files for birth parish
*		c. Clean unassigned birth place strings
*		d. Match unassigned birth place strings with London place names

************

*********************************************************************************************************************
*********** I-CeM Birth Parish Cleanup *************
*********************************************************************************************************************

/****** The following section creates a crosswalk file between STD_PAR and CNTI and merges it with values of STD_PAR in the birth place field */

* Extract unique STD_PAR and CNTI values from crosswalk

import excel using "$PROJ_PATH/raw/geography/ICEM_Placelist_Unprotected.xlsx", clear firstrow case(lower)

drop if place == ""
keeporder std_par cnti alt_cnti
gduplicates drop

rename cnti cnti1
rename alt_cnti cnti2
gen obs_id = _n
greshape long cnti, i(obs_id) j(new_id)
drop obs_id new_id
drop if cnti == ""

replace std_par = upper(std_par)
replace std_par = subinstr(std_par,"'","",.)

replace std_par = regexr(std_par,"È","F") 
replace std_par = substr(std_par,1,62)

gduplicates drop
gisid std_par cnti

rename std_par edit_par
gsort edit_par cnti

tempfile par_cnti
save `par_cnti', replace

* Compile universe of standardized birth parish strings in data

forvalues y = 1881(10)1911 {
	use Cnti BpCtry HollerB using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_birthplace.dta", clear
	gduplicates drop
	tempfile std_par`y'
	save `std_par`y'', replace
}
clear
forvalues y = 1881(10)1911 {
	append using `std_par`y''
}
gduplicates drop
gisid HollerB BpCtry Cnti, missok

recast str Cnti 
rename Cnti std_par 
rename BpCtry bcounty
rename HollerB bcntry

drop if bcntry == "" | bcntry == "." | std_par == "Not Applicable" | std_par == "Not Coded" | std_par == "Unknown" | bcounty == "FOR"

keep std_par bcounty
gduplicates drop
gisid std_par bcounty
gsort std_par bcounty

gen edit_par = std_par 
replace edit_par = upper(edit_par)
replace edit_par = subinstr(edit_par,"'","",.)

// Fix errors 
replace bcounty = "INV" if std_par == "Inverness"
replace bcounty = "CAE" if std_par == "Llandrillo Yn Rh??s"
gduplicates drop

joinby edit_par using `par_cnti', unmatched(master)
gsort cnti edit_par std_par

replace cnti = bcounty if _merge == 1
drop _merge bcounty
gduplicates drop

save "$PROJ_PATH/processed/temp/icem_stdpar_cnti_xwk.dta", replace

*************************************************************

* Identify parishes in London

import excel using "$PROJ_PATH/raw/geography/Parish_ID_All_Years.xlsx", clear firstrow case(lower)
keeporder parish regcnty country
keep if regcnty == "LONDON" | regcnty == "KENT" | regcnty == "MIDDLESEX" | regcnty == "SURREY"
gen london_parish = (regcnty == "LONDON")
keep parish london_parish

rename parish edit_par
replace edit_par = upper(edit_par)
replace edit_par = subinstr(edit_par,"'","",.)
replace edit_par = subinstr(edit_par,".","",.)
replace edit_par = subinstr(edit_par,",","",.)
replace edit_par = subinstr(edit_par,"-"," ",.)
replace edit_par = regexr(edit_par,"[ ]\((.)*\)$","")
replace edit_par = substr(edit_par,1,62)

egen tot_london = total(london_parish == 1), by(edit_par)
drop if tot_london > 0 & london_parish == 0
drop tot_london

gduplicates drop 
gisid edit_par london_parish
gsort edit_par london_parish

tempfile london_parishes
save `london_parishes', replace

* Identify districts in London

import excel using "$PROJ_PATH/raw/geography/Parish_ID_All_Years.xlsx", clear firstrow case(lower)
keeporder regdist regcnty country
keep if regcnty == "LONDON" | regcnty == "KENT" | regcnty == "MIDDLESEX" | regcnty == "SURREY"
gen london_dist = (regcnty == "LONDON")
keep regdist london_dist

rename regdist edit_par
replace edit_par = upper(edit_par)
replace edit_par = subinstr(edit_par,"'","",.)
replace edit_par = subinstr(edit_par,".","",.)
replace edit_par = subinstr(edit_par,",","",.)
replace edit_par = subinstr(edit_par,"-"," ",.)
replace edit_par = regexr(edit_par,"[ ]\((.)*\)$","")
replace edit_par = substr(edit_par,1,62)

egen tot_london = total(london_dist == 1), by(edit_par)
drop if tot_london > 0 & london_dist == 0
drop tot_london

gduplicates drop 
gisid edit_par london_dist
gsort edit_par london_dist

tempfile london_districts
save `london_districts', replace

* Identify sub-districts in London

import excel using "$PROJ_PATH/raw/geography/Parish_ID_All_Years.xlsx", clear firstrow case(lower)
keeporder subdist regcnty country
keep if regcnty == "LONDON" | regcnty == "KENT" | regcnty == "MIDDLESEX" | regcnty == "SURREY"
gen london_subdist = (regcnty == "LONDON")
keep subdist london_subdist

rename subdist edit_par
replace edit_par = upper(edit_par)
replace edit_par = subinstr(edit_par,"'","",.)
replace edit_par = subinstr(edit_par,".","",.)
replace edit_par = subinstr(edit_par,",","",.)
replace edit_par = subinstr(edit_par,"-"," ",.)
replace edit_par = regexr(edit_par,"[ ]\((.)*\)$","")
replace edit_par = substr(edit_par,1,62)

egen tot_london = total(london_subdist == 1), by(edit_par)
drop if tot_london > 0 & london_subdist == 0
drop tot_london

gduplicates drop 
gisid edit_par london_subdist
gsort edit_par london_subdist

tempfile london_subdist
save `london_subdist', replace

* Merge London geography with std_par to cnti crosswalk

use "$PROJ_PATH/processed/temp/icem_stdpar_cnti_xwk.dta", clear
keep if cnti == "KEN" | cnti == "MDX" | cnti == "SRY"
replace edit_par = upper(edit_par)
replace edit_par = subinstr(edit_par,"'","",.)
replace edit_par = subinstr(edit_par,".","",.)
replace edit_par = subinstr(edit_par,",","",.)
replace edit_par = subinstr(edit_par,"-"," ",.)
replace edit_par = "ST ANDREW HOLBORN ABOVE THE BARS AND ST GEORGE THE MARTYR" if edit_par == "ST ANDREW HOLBORN ABOVE THE BARS AND ST GEORGE THE"

fmerge m:1 edit_par using `london_parishes', keep(1 3) nogen

fmerge m:1 edit_par using `london_districts', keep(1 3) nogen
replace london_parish = 1 if london_dist == 1
drop london_dist

fmerge m:1 edit_par using `london_subdist', keep(1 3) nogen 
replace london_parish = 1 if london_subdist == 1
drop london_subdist

replace london_parish = 1 if edit_par == "ALDERSGATE" | edit_par == "ALDGATE" | edit_par == "BISHOPSGATE" | edit_par == "INNER AND MIDDLE TEMPLE" | edit_par == "LONDON" | edit_par == "TOWER HAMLETS" | edit_par == "WESTMINISTER" | edit_par == "WESTMINSTER"
keep if london_parish == 1
keep std_par

gduplicates drop
gsort std_par

save "$PROJ_PATH/processed/intermediate/geography/icem_london_std_par.dta", replace

*************************************************************

* Assign coded value if unique - to "Not Coded" Cases 

forvalues y = 1881(10)1911 {
	use Bpstring Cnti BpCtry Ctry using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_birthplace.dta", clear
	
	gduplicates drop 
	gunique Bpstring Cnti BpCtry Ctry
	gsort Bpstring Cnti BpCtry Ctry
	
	tempfile std_par`y'
	save `std_par`y'', replace
}
clear
forvalues y = 1881(10)1911 {
	append using `std_par`y''
}

duplicates drop 
gunique Bpstring Cnti BpCtry Ctry
gsort Bpstring Cnti BpCtry Ctry

recast str Bpstring Cnti

rename Cnti std_par
rename BpCtry bcounty1
rename Ctry bcounty2
replace Bpstring = upper(Bpstring)

bysort Bpstring: gen mult_assignment = (_N > 1)
keep if mult_assignment == 1
drop mult_assignment
compress
save "$PROJ_PATH/processed/temp/icem_bpstring_mult_assign.dta", replace

use "$PROJ_PATH/processed/temp/icem_bpstring_mult_assign.dta" if std_par == "Not Coded", clear
keep Bpstring

gduplicates drop
gisid Bpstring
gsort Bpstring 

tempfile not_coded
save `not_coded', replace

use "$PROJ_PATH/processed/temp/icem_bpstring_mult_assign.dta" if std_par != "Not Coded", clear
fmerge m:1 Bpstring using `not_coded', keep(3) nogen
drop if std_par == "Unknown"

keep bcounty1 bcounty2 std_par Bpstring
gduplicates drop 
gisid bcounty1 bcounty2 std_par Bpstring, missok

bysort Bpstring: keep if _N == 1
drop if regexm(Bpstring,"^\(") | regexm(Bpstring,"[A-Z]") == 0 | regexm(Bpstring,"\.\.\.") | length(Bpstring) <= 3 | regexm(Bpstring,"^\?") | Bpstring == "1 ST" | Bpstring == "[BLANK]"

rename std_par recode_std_par
rename bcounty1 recode_bcounty1
rename bcounty2 recode_bcounty2

compress
save "$PROJ_PATH/processed/temp/icem_bpstring_recoded_missing.dta", replace

* Recode London cases

use "$PROJ_PATH/processed/temp/icem_bpstring_mult_assign.dta" if std_par == "London", clear
keep Bpstring
gduplicates drop 
gisid Bpstring
gsort Bpstring 
tempfile coded_london
save `coded_london', replace

use "$PROJ_PATH/processed/temp/icem_bpstring_mult_assign.dta" if std_par != "London", clear
fmerge m:1 Bpstring using `coded_london', keep(3) nogen
drop if std_par == "Unknown"
drop bcounty2

keep bcounty1 std_par Bpstring
gduplicates drop
gisid bcounty1 std_par Bpstring, missok

bysort Bpstring: keep if _N == 1
drop if regexm(Bpstring,"^\(") | regexm(Bpstring,"[A-Z]") == 0 | regexm(Bpstring,"\.\.\.") | length(Bpstring) <= 3 | regexm(Bpstring,"^\?") | Bpstring == "1 ST" | Bpstring == "[BLANK]" | Bpstring == "LONDON N K" | Bpstring == "LONDON NK"

fmerge m:1 std_par using "$PROJ_PATH/processed/intermediate/geography/icem_london_std_par.dta", keep(3) nogen
keep if bcounty1 == "KEN" | bcounty1 == "MDX" | bcounty1 == "SRY"

rename std_par recode_std_par
rename bcounty1 recode_bcounty1
bysort Bpstring: keep if _N == 1
compress
save "$PROJ_PATH/processed/temp/icem_bpstring_recoded_london.dta", replace

* Re-assign to best match if non-unique assignment of standard parish

use std_par cnti using "$PROJ_PATH/processed/temp/icem_stdpar_cnti_xwk.dta", clear
gduplicates drop 
bysort std_par: keep if _N == 1
tempfile std_par_cty
save `std_par_cty', replace

use Bpstring std_par using "$PROJ_PATH/processed/temp/icem_bpstring_mult_assign.dta", clear
gduplicates drop 

drop if regexm(Bpstring,"^\(") | regexm(Bpstring,"[A-Z]") == 0 | regexm(Bpstring,"\.\.\.") | length(Bpstring) <= 3 | regexm(Bpstring,"^\?") | Bpstring == "1 ST" | Bpstring == "[BLANK]"
drop if std_par == "Not Applicable" | std_par == "Not Coded" | std_par == "Unknown" | (std_par == "Allhallows London Wall" & regexm(Bpstring,"WALL") == 0)

gen str_bp = upper(Bpstring)
gen str_std_par = upper(std_par)

replace str_bp = regexr(str_bp,"^[^A-Z]+","")
replace str_bp = regexr(str_bp,"[^A-Z]+$","")

drop if str_std_par == "LONDON"
gen std_location = strpos(str_bp,str_std_par)
keep if std_location > 0
jarowinkler str_bp str_std_par, gen(jw_dist)
egen max_dist = max(jw_dist), by(Bpstring)
keep if max_dist == jw_dist & jw_dist >= 0.95
keep Bpstring std_par
gduplicates drop 
bysort Bpstring: keep if _N == 1

fmerge m:1 std_par using `std_par_cty', keep(3) nogen

rename std_par recode_std_par
rename cnti recode_bcounty1
bysort Bpstring: keep if _N == 1
compress
save "$PROJ_PATH/processed/temp/icem_bpstring_recoded_best_match.dta", replace
rm "$PROJ_PATH/processed/temp/icem_bpstring_mult_assign.dta"

********************************************************************

* Identify birth parish strings to recode

forvalues y = 1881(10)1911 {
	use Bpstring Cnti BpCtry HollerB using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_birthplace.dta", clear
	gduplicates drop 
	
	tempfile std_par`y'
	save `std_par`y'', replace
}
clear
forvalues y = 1881(10)1911 {
	append using `std_par`y''
}

gduplicates drop 
gunique Bpstring Cnti BpCtry HollerB
gsort Bpstring Cnti BpCtry HollerB

recast str Bpstring Cnti

replace Bpstring = upper(Bpstring)

gen recode_string = 0
replace recode_string = 1 if Cnti == "Not Coded" 
replace recode_string = 2 if Cnti == "Not Applicable"
replace recode_string = 3 if Cnti == "Unknown"
replace recode_string = 4 if Cnti == "London"

replace recode_string = 5 if regexm(Bpstring,"LONDON") & recode_string == 0

rename HollerB bcntry
rename BpCtry cnti
rename Cnti edit_par

replace edit_par = upper(edit_par)
replace edit_par = subinstr(edit_par,"'","",.)

joinby cnti edit_par using "$PROJ_PATH/processed/temp/icem_stdpar_cnti_xwk.dta", unmatched(master)

replace recode_string = 6 if _merge != 3 & recode_string == 0
drop _merge

compress Bpstring
drop if Bpstring == "[BLANK]" | Bpstring == "?" | bcntry == "FOR" |cnti == "FOR"

keep if recode_string > 0
tab recode_string

keep Bpstring
gduplicates drop 
gsort Bpstring

save "$PROJ_PATH/processed/temp/icem_bpstring_recode_input.dta", replace

*********************************************************************************************************************
*********** I-CeM Bpstring Cleanup *************
*********************************************************************************************************************

*************************************************************

* Create place name to standard parish crosswalk

import excel using "$PROJ_PATH/raw/geography/ICEM_Placelist_Unprotected.xlsx", clear firstrow case(lower)
drop if place == ""
keeporder place std_par cnti alt_cnti
gduplicates drop
gsort cnti std_par place alt_cnti 
save "$PROJ_PATH/processed/temp/icem_placelist_stdpar_xwk.dta", replace

*************************************************************

* Load London parishes and create joinby variables

use "$PROJ_PATH/processed/intermediate/geography/icem_london_std_par.dta", clear
merge 1:m std_par using "$PROJ_PATH/processed/temp/icem_stdpar_cnti_xwk.dta", assert(2 3) keep(3) nogen
drop edit_par
keep if cnti == "KEN" | cnti == "MDX" | cnti == "SRY"

keep std_par cnti
gduplicates drop 
gisid std_par cnti
gsort std_par cnti 

egen group_id = group(std_par)
egen obs_id = seq(), by(std_par)

greshape wide cnti, i(group_id) j(obs_id)

keeporder std_par cnti*
rename cnti1 cnti
rename cnti2 alt_cnti
save "$PROJ_PATH/processed/temp/london_counties.dta", replace

use "$PROJ_PATH/processed/temp/icem_placelist_stdpar_xwk.dta", clear
replace std_par = proper(std_par)
fmerge m:1 std_par using "$PROJ_PATH/processed/intermediate/geography/icem_london_std_par.dta", keep(3) nogen // assert(1 3) 
keep if cnti == "KEN" | cnti == "MDX" | cnti == "SRY"
replace std_par = "Camberwell" if place == "CAMBERWELL"

replace place = regexr(place,"^ST ","")

gen bstr_short = upper(place)
local vowels "A E I O U Y"
foreach letter of local vowels {
	replace bstr_short = subinstr(bstr_short,"`letter'","",.)
}
replace bstr_short = substr(bstr_short,1,3)
sort bstr_short std_par
save "$PROJ_PATH/processed/temp/london_parishes.dta", replace

use "$PROJ_PATH/processed/temp/icem_bpstring_recode_input.dta", clear

gen str_bp = upper(Bpstring)
replace str_bp = regexr(str_bp,"^[^A-Z]+","")
replace str_bp = regexr(str_bp,"[^A-Z]+$","")

gen london = regexm(str_bp,"LONDON")
gen city_london = (london == 1 & regexm(str_bp,"CITY"))

* Manual cleanup

replace str_bp = regexr(str_bp," B GREEN", " BETHNAL GREEN")
replace str_bp = "ST PANCRAS LONDON" if regexm(str_bp,"PANCRAS")
replace str_bp = regexr(str_bp,"SOUTH HACKNEY","HACKNEY")
replace str_bp = "ST MARYLEBONE LONDON" if regexm(str_bp,"MARYLEBONE")
replace str_bp = "ST LUKES LONDON" if regexm(str_bp,"ST LUKE")
replace str_bp = "BETHNAL GREEN" if str_bp == "B GREEN"
* Use code from name cleanup

replace str_bp = trim(str_bp)

replace str_bp = regexr(str_bp,"\.","") if regexm(str_bp,"[A-Z]\.[A-Z]")
replace str_bp = regexr(str_bp,"\.","") if regexm(str_bp,"[A-Z]\.[A-Z]")
replace str_bp = regexr(str_bp,"\.","") if regexm(str_bp,"[A-Z]\.[A-Z]")

replace str_bp = subinstr(str_bp,"."," ",.)
replace str_bp = subinstr(str_bp,"    "," ",.)
replace str_bp = subinstr(str_bp,"   "," ",.)
replace str_bp = subinstr(str_bp,"  "," ",.)
replace str_bp = subinstr(str_bp,"?","",.)

local symbol_list "! @ # $ % ^ & * ' ( ) / \ : ; | ~ ` < > , ? { } = + [ ] - _"
foreach symbol of local symbol_list {
	qui replace str_bp = subinstr(str_bp,"`symbol'","",.)
}
replace str_bp = trim(str_bp)

replace str_bp = regexr(str_bp," THE "," ")
replace str_bp = regexr(str_bp," IN "," ")
replace str_bp = regexr(str_bp," OF "," ")
replace str_bp = regexr(str_bp," BY "," ")
replace str_bp = regexr(str_bp," AND "," ")

* Extract postal code
replace str_bp = regexr(str_bp," RESIDENT$","")
replace str_bp = regexr(str_bp," PARISH$","")
replace str_bp = regexr(str_bp,"^PARISH ","")
replace str_bp = regexr(str_bp,"^LONDON ","")
replace str_bp = regexr(str_bp," LONDO(N)*$","")
replace str_bp = regexr(str_bp," LOND(N)*$","")
replace str_bp = regexr(str_bp," LDN$","")
replace str_bp = regexr(str_bp," LO(N)*$","")
replace str_bp = regexr(str_bp," BUCKS$","")
replace str_bp = regexr(str_bp," ESSEX$","")
replace str_bp = regexr(str_bp," KENT$","")
replace str_bp = regexr(str_bp," MIDDLESEX$","")
replace str_bp = regexr(str_bp," M(.)*D(.)*X$","")
replace str_bp = regexr(str_bp," SURREY$","")
replace str_bp = regexr(str_bp," LONDO(N)*$","")

local postalcode "E EC N NE NW S SE SW W WC"
replace str_bp = regexr(str_bp," E E$"," EC")
replace str_bp = regexr(str_bp," E C$"," EC")
replace str_bp = regexr(str_bp," W C$"," WC")
replace str_bp = regexr(str_bp," N E$"," NE")
replace str_bp = regexr(str_bp," N W$"," NW")
replace str_bp = regexr(str_bp," S E$"," SE")
replace str_bp = regexr(str_bp," S W$"," SW")
replace str_bp = regexr(str_bp," J W$"," SW")
replace str_bp = regexr(str_bp," [A-Z]$","")

gen postal_code = ""
local postalcode "E EC N NE NW S SE SW W WC"
foreach letter of local postalcode {
	replace postal_code = "`letter'" if regexm(str_bp," `letter'$")
	replace str_bp = regexr(str_bp," `letter'$","")
}
replace str_bp = regexr(str_bp,"^BOR(.)*[ ]OF[ ]","")
replace str_bp = regexr(str_bp,"^[0-9]+[ ][A-Z]+[ ]ST(REET)*[ ]","")
replace str_bp = regexr(str_bp,"^[0-9]+[ ][A-Z]+[ ]R(OA)*D[ ]","")
replace str_bp = regexr(str_bp,"^[A-Z]+[ ]ST(REET)*[ ]","")
replace str_bp = regexr(str_bp,"^[A-Z]+[ ]R(OA)*D[ ]","")

replace str_bp = trim(str_bp)
replace str_bp = subinstr(str_bp," RD "," ROAD ",.)
replace str_bp = regexr(str_bp," RD$"," ROAD")

replace str_bp = regexr(str_bp,"^S GEORGE","ST GEORGE")
replace str_bp = regexr(str_bp," GR,"," GREEN,")
replace str_bp = regexr(str_bp," GN,"," GREEN,")
replace str_bp = regexr(str_bp,"LONDON"," LONDON") if regexm(str_bp,"[A-Z]LONDON")
replace str_bp = regexr(str_bp,"^S LUKE","ST LUKE")
replace str_bp = regexr(str_bp,"MARYLEBONE","ST MARYLEBONE") if regexm(str_bp,"MARYLEBONE") & regexm(str_bp,"ST")==0
replace str_bp = regexr(str_bp,"^S MARY","ST MARY")
replace str_bp = "LONDON" if str_bp == "WEST LONDON" | str_bp == "EAST LONDON" | str_bp == "NORTH LONDON" | str_bp == "SOUTH LONDON"
replace str_bp = regexr(str_bp,"OXFORD","OXFORDSHIRE") if regexm(str_bp,"SHIRE") == 0
replace str_bp = regexr(str_bp,"DEVON","DEVONSHIRE") if regexm(str_bp,"SHIRE") == 0

replace str_bp = regexr(str_bp," RESIDENT$","")
replace str_bp = regexr(str_bp,"^LONDON ","")
replace str_bp = regexr(str_bp," LONDO(N)*$","")
replace str_bp = regexr(str_bp," LOND(N)*$","")
replace str_bp = regexr(str_bp," LDN$","")
replace str_bp = regexr(str_bp," LO(N)*$","")
replace str_bp = regexr(str_bp," BUCKS$","")
replace str_bp = regexr(str_bp," ESSEX$","")
replace str_bp = regexr(str_bp," KENT$","")
replace str_bp = regexr(str_bp," MIDDLESEX$","")
replace str_bp = regexr(str_bp," M(.)*D(.)*X$","")
replace str_bp = regexr(str_bp," SURREY$","")
replace str_bp = regexr(str_bp," LONDO(N)*$","")

replace str_bp = subinstr(str_bp,"LONDON","",.)
replace str_bp = trim(str_bp)
replace str_bp = subinstr(str_bp,"  "," ",.)

replace str_bp = regexr(str_bp,"^[^A-Z]+","")
replace str_bp = regexr(str_bp,"[^A-Z]+$","")

* Add commas after street suffixes

replace str_bp = regexr(str_bp," ST ST "," ST, ")
replace str_bp = regexr(str_bp," STR ST "," STR, ")

local add_type "AVENUE BUILDINGS CLOSE COTTAGES COURT CRESCENT GROVE LANE PARK PLACE RENTS ROAD ROW SQUARE ST STREET TERRACE VILLAS WALK YARD"

foreach type of local add_type {
	replace str_bp = regexr(str_bp," `type' "," `type', ")
}
replace str_bp = regexr(str_bp," NR "," NR, ")
replace str_bp = regexr(str_bp," ROAD "," ROAD, ")
replace str_bp = subinstr(str_bp,"STREET ", "STREET, ",.)
replace str_bp = subinstr(str_bp,"ROAD ", "ROAD, ",.)
replace str_bp = subinstr(str_bp,"COTT ", "COTT, ",.)
replace str_bp = subinstr(str_bp,"LANE ", "LANE, ",.)
replace str_bp = subinstr(str_bp,"PLACE ", "PLACE, ",.)
replace str_bp = subinstr(str_bp,"COURT ", "COURT, ",.)
replace str_bp = subinstr(str_bp," CT ROAD", " COURT ROAD",.)
replace str_bp = subinstr(str_bp," CT PASSAGE", " COURT PASSAGE",.)
replace str_bp = subinstr(str_bp," CT ", " COURT, ",.) if regexm(str_bp," CT PASSAGE")==0
replace str_bp = subinstr(str_bp," SQ ", " SQUARE, ",.) if regexm(str_bp," SQ BUILDINGS")==0 & regexm(str_bp," SQ BDGS")==0 & regexm(str_bp," SQ TERR")==0
replace str_bp = subinstr(str_bp," SQR ", " SQUARE, ",.)
replace str_bp = subinstr(str_bp," SQRE ", " SQUARE, ",.)
replace str_bp = subinstr(str_bp," PL ", " PLACE, ",.) if regexm(str_bp," PL NORTH")==0
replace str_bp = subinstr(str_bp," YD ", " YARD, ",.) if regexm(str_bp," YD BUILDINGS")==0
replace str_bp = subinstr(str_bp," TER ", " TERRACE, ",.) if regexm(str_bp," TER MOORS")==0
replace str_bp = subinstr(str_bp," TERR ", " TERRACE, ",.)
replace str_bp = subinstr(str_bp,"COTTS ", "COTTAGES, ",.)
replace str_bp = subinstr(str_bp," GDNS ", " GARDENS, ",.) if regexm(str_bp," GDNS ESTATE")==0 & regexm(str_bp," GDNS MANSIONS")==0
replace str_bp = subinstr(str_bp," ST, BUILDINGS", " STREET BUILDINGS",.)
replace str_bp = subinstr(str_bp,"BUILDINGS ", "BUILDINGS, ",.)

* Fix typos
replace str_bp = regexr(str_bp,"SNOWSFIELD","SNOWSFIELDS") if regexm(str_bp,"SNOWSFIELDS") == 0
replace str_bp = regexr(str_bp,"B(')*DSEY","BERMONDSEY")
replace str_bp = regexr(str_bp,"WALTHAMSTON(E)*","WALTHAMSTOW")
replace str_bp = regexr(str_bp,"ST GEORGE(S)*, E$","ST GEORGE IN THE EAST")
replace str_bp = regexr(str_bp,"ST GEORGES IN THE EAST","ST GEORGE IN THE EAST")
replace str_bp = regexr(str_bp,"ST GEORGES EAST","ST GEORGE IN THE EAST")
replace str_bp = regexr(str_bp,"BETHNAL GR(N)*$","BETHNAL GREEN")
replace str_bp = regexr(str_bp,"BETHNAL GR, ROAD$","BETHNAL GREEN ROAD")
replace str_bp = regexr(str_bp,"BETHNAL GREEN, ROAD$","BETHNAL GREEN ROAD")
replace str_bp = regexr(str_bp,"BETHNAL GW$","BETHNAL GREEN")
replace str_bp = regexr(str_bp,"BETHNAL GRANT ROAD$","BETHNAL GREEN ROAD")
replace str_bp = regexr(str_bp,"BETH GREEN","BETHNAL GREEN")
replace str_bp = regexr(str_bp,"BETHL GREEN","BETHNAL GREEN")
replace str_bp = regexr(str_bp,"MARY LE BONE", "MARYLEBONE")
replace str_bp = regexr(str_bp,"FARRINGTON","FARRINGDON")
replace str_bp = regexr(str_bp,"COLDBATH","COLD BATH")
replace str_bp = regexr(str_bp,"WHCROSS ST","WHITECROSS ST")
replace str_bp = regexr(str_bp,"WHITE X ST","WHITECROSS ST")
replace str_bp = regexr(str_bp,"CAMDEN LOWN","CAMDEN TOWN")
replace str_bp = regexr(str_bp,"CAMDEN$","CAMDEN TOWN")
replace str_bp = regexr(str_bp,"SHOUDITCH","SHOREDITCH")
replace str_bp = regexr(str_bp,"STOKE NEWINGTONN","STOKE NEWINGTON")
replace str_bp = regexr(str_bp,"MILE END NEW TN", "MILE END NEW TOWN")
replace str_bp = regexr(str_bp,"MILE ENDS","MILE END")
replace str_bp = regexr(str_bp,"E DULWICH","EAST DULWICH")
replace str_bp = regexr(str_bp,"MIDDX","MIDDLESEX")
replace str_bp = regexr(str_bp,"CHESHNUT","CHESHUNT")
replace str_bp = regexr(str_bp,"DALWICH","DULWICH")
replace str_bp = regexr(str_bp,"HAGGERSTONE","HAGGERSTON")
replace str_bp = regexr(str_bp,"STOKE H(.)+TON","STOKE NEWINGTON")
replace str_bp = regexr(str_bp,"CLERKENWEL,","CLERKENWELL,")
replace str_bp = regexr(str_bp,"COW CROSS","COWCROSS")
replace str_bp = regexr(str_bp,"FIREBALL","FIRE BALL")
replace str_bp = regexr(str_bp,"HOUNSDITCH","HOUNDSDITCH")
replace str_bp = regexr(str_bp,"ENFIELD, WASH","ENFIELD WASH")
replace str_bp = regexr(str_bp,"ENFIELD HEIGHWAY","ENFIELD HIGHWAY")
replace str_bp = regexr(str_bp,"CLEREKENWELL","CLERKENWELL")
replace str_bp = regexr(str_bp,"WALTHAMASTOW","WALTHAMSTOW")
replace str_bp = regexr(str_bp,"WOOLWICK","WOOLWICH")
replace str_bp = regexr(str_bp," N PADDINGTON","PADDINGTON")
replace str_bp = regexr(str_bp,"STRATFORD MARSH","STRATFORD")
replace str_bp = regexr(str_bp,"STRATFORD NEW T(OW)*N","STRATFORD")
replace str_bp = regexr(str_bp,"CLERKENWELL, ROAD","CLERKENWELL ROAD")
replace str_bp = regexr(str_bp,"CLERKENWELL ROADS","CLERKENWELL ROAD")
replace str_bp = regexr(str_bp,"CLERKENWELL GREN","CLERKENWELL GREEN")
replace str_bp = regexr(str_bp,"VICTORIA, DWELLINGS","VICTORIA DWELLINGS")
replace str_bp = regexr(str_bp,"ST JOHN ST, ROAD","ST JOHN ST ROAD")
replace str_bp = regexr(str_bp,"LITTLE SUTTON, ST,","LITTLE SUTTON ST,")
replace str_bp = regexr(str_bp,"ST JOHN STREET R(OA)*D","ST JOHN ST ROAD")
replace str_bp = regexr(str_bp,"ST JOHN STREET, ROAD","ST JOHN ST ROAD")
replace str_bp = regexr(str_bp,"ST JOHN ST, ROAD","ST JOHN ST ROAD")
replace str_bp = regexr(str_bp,"HAT & MITRE", "HAT MITRE")
replace str_bp = regexr(str_bp,"HEXTON", "HOXTON")
replace str_bp = regexr(str_bp,"LEATHERR", "LEATHER")
replace str_bp = regexr(str_bp,"LEATHER HEAD", "LEATHERHEAD")
replace str_bp = regexr(str_bp,"LEATHER SELLERS", "LEATHERSELLERS")
replace str_bp = regexr(str_bp,"LEATHER( )*[L|H]AN[D|T]", "LEATHER LANE")
replace str_bp = regexr(str_bp,"BROAD WALL","BROADWALL")
replace str_bp = regexr(str_bp,"HOLLARND ST","HOLLAND ST")
replace str_bp = regexr(str_bp,"UPGROUND ST","UPPER GROUND ST")
replace str_bp = regexr(str_bp,"CITY R,","CITY ROAD,")
replace str_bp = regexr(str_bp,"WINDSORE ","WINDSOR ")
replace str_bp = regexr(str_bp,"BARKING E","BARKING, E")
replace str_bp = regexr(str_bp,"BARKINGS ","BARKING")
replace str_bp = regexr(str_bp,"BARKING SIDE","BARKINGSIDE")
replace str_bp = regexr(str_bp," E H[A|U]M$","EAST HAM")
replace str_bp = regexr(str_bp,"DISPARD ROAD","DESPARD ROAD")
replace str_bp = regexr(str_bp,"LE[A|E]K(E)* ST", "LEEKE ST") 
replace str_bp = regexr(str_bp," FIELDS ST","FIELD ST")
replace str_bp = regexr(str_bp,"^FIELDS ST","FIELD ST")
replace str_bp = regexr(str_bp,"CALEDONCAN","CALEDONIAN")
replace str_bp = regexr(str_bp,"CALENDONIAN","CALEDONIAN")
replace str_bp = regexr(str_bp,"CALEDOMAN","CALEDONIAN")
replace str_bp = regexr(str_bp,"CALEDOMIAN","CALEDONIAN")
replace str_bp = regexr(str_bp,"STRATHAM ST","STREATHAM ST")
replace str_bp = regexr(str_bp," STH, HORNSEY"," SOUTH HORNSEY")
replace str_bp = regexr(str_bp,"HORNSEY PK(,)* ROAD","HORNSEY PARK ROAD")
replace str_bp = regexr(str_bp," S HORNSEY"," SOUTH HORNSEY")	
replace str_bp = regexr(str_bp," STH HORNSEY"," SOUTH HORNSEY")	
replace str_bp = regexr(str_bp,"PRIORY, HORNSEY","PRIORY HORNSEY")	
replace str_bp = regexr(str_bp,"BRIXTON HULL","BRIXTON HILL")	
replace str_bp = regexr(str_bp,"DANBROOKE ROAD","DANBROOK ROAD")
replace str_bp = regexr(str_bp,"FENSBURY","FINSBURY")
replace str_bp = regexr(str_bp," MKT"," MARKET")
replace str_bp = regexr(str_bp,"GOSSWELL ROAD","GOSWELL ROAD")
replace str_bp = regexr(str_bp,"FARRINGDEN ROAD","FARRINGDON ROAD")
replace str_bp = regexr(str_bp,"WHITE CROSS ST","WHITECROSS ST")
replace str_bp = regexr(str_bp,"BOURNMOUTH","BOURNEMOUTH")
replace str_bp = regexr(str_bp,"BETHNAL ROAD","BETHNAL GREEN ROAD")
replace str_bp = regexr(str_bp,"COMMERICAL ROAD","COMMERCIAL ROAD")
replace str_bp = regexr(str_bp,"FINSBY","FINSBURY")
replace str_bp = regexr(str_bp,"BLACKSFRIARS","BLACKFRIARS")
replace str_bp = regexr(str_bp,"CLEKENWELL","CLERKENWELL")
replace str_bp = regexr(str_bp,"HOLLBORN","HOLBORN")
replace str_bp = regexr(str_bp,"PENTONVILL,","PENTONVILLE ROAD,")
replace str_bp = regexr(str_bp,"BETHNAL G$","BETHNAL GREEN")
replace str_bp = regexr(str_bp,"WHITECROSS PLECE","WHITECROSS PLACE")
replace str_bp = regexr(str_bp,"ISLINGHTON","ISLINGTON")
replace str_bp = regexr(str_bp,"WESTMENSTER","WESTMINSTER")
replace str_bp = regexr(str_bp,"NOTTING MILL","NOTTING HILL")
replace str_bp = regexr(str_bp,"WHTCHAPEL","WHITECHAPEL")
replace str_bp = regexr(str_bp,"BETHNAL GR ROAD","BETHNAL GREEN ROAD")
replace str_bp = regexr(str_bp,"KENNENGTON ROAD","KENNINGTON ROAD")
replace str_bp = regexr(str_bp,"BROMLEY BY ROW","BROMLEY BY BOW")
replace str_bp = regexr(str_bp,", ROW$",", BOW")
replace str_bp = regexr(str_bp,"COPENHAGER ST","COPENHAGEN ST")
replace str_bp = regexr(str_bp,"EDGSWARE R(OA)*D","EDGWARE ROAD")
replace str_bp = regexr(str_bp,"SHITALFIELD","SPITALFIELD")
replace str_bp = regexr(str_bp,"CLARKENWELL","CLERKENWELL")
replace str_bp = regexr(str_bp,"GOSEWELL R(OA)*D","GOSWELL ROAD")
replace str_bp = regexr(str_bp," PK$"," PARK")
replace str_bp = regexr(str_bp,"CLKWELL","CLERKENWELL")
replace str_bp = regexr(str_bp,"SPITAEFIELDS","SPITALFIELDS")
replace str_bp = regexr(str_bp,"WORD GREEN","WOOD GREEN")
replace str_bp = regexr(str_bp,"HAXTON","HOXTON")
replace str_bp = regexr(str_bp,"SAFFRON HILB","SAFFRON HILL")
replace str_bp = regexr(str_bp,"NEWNORTH R(OA)*D","NEW NORTH ROAD")
replace str_bp = regexr(str_bp,"NEWINGTON, BUTTS","NEWINGTON BUTTS")
replace str_bp = regexr(str_bp,"WHITCHAPEL","WHITECHAPEL")
replace str_bp = regexr(str_bp,"BURNSBURY","BARNSBURY")
replace str_bp = regexr(str_bp,"ST JOHN, ST ROAD","ST JOHN ST ROAD")
replace str_bp = regexr(str_bp,"RE-ADMITTED","READMISSION")
replace str_bp = regexr(str_bp,"STREETM","STREET,")
replace str_bp = regexr(str_bp,"SHAFLESBURY","SHAFTESBURY")
replace str_bp = regexr(str_bp,"SHAFTERBURY","SHAFTESBURY")
replace str_bp = regexr(str_bp,"SHAFTESBURG PL,","SHAFTESBURY PLACE,")
replace str_bp = regexr(str_bp,"GALSSHOUSE YD","GLASSHOUSE YD")
replace str_bp = regexr(str_bp,"LAURDERDALE","LAUDERDALE")
replace str_bp = regexr(str_bp,"LANDERDALE","LAUDERDALE")
replace str_bp = regexr(str_bp,"BRIDGWATER PL","BRIDGEWATER PL")
replace str_bp = regexr(str_bp,"ALDGATE ROAD","ALDGATE")
replace str_bp = regexr(str_bp,"HUNSLITT ST","HUNSLETT ST")
replace str_bp = regexr(str_bp,"GREENSTREET","GREEN STREET")
replace str_bp = regexr(str_bp,"BONNERS LANE","BONNER LANE")
replace str_bp = regexr(str_bp,"WHITEPOST LANE","WHITE POST LANE")
replace str_bp = regexr(str_bp,"SEWARD STONE ROAD","SEWARDSTONE ROAD")
replace str_bp = regexr(str_bp,"HOLMER ROAD","HOMER ROAD")
replace str_bp = regexr(str_bp,"HAMILON ROAD","HAMILTON ROAD")
replace str_bp = regexr(str_bp,"ST JAMESS ROAD","ST JAMES ROAD")
replace str_bp = regexr(str_bp,"THE APPROACH R","APPROACH R")
replace str_bp = regexr(str_bp,"ALNMOUTH","ALLANMOUTH")
replace str_bp = regexr(str_bp,"ALLAMOUTH","ALLANMOUTH")
replace str_bp = regexr(str_bp,"CADOVA R(OA)*D","CORDOVA ROAD")
replace str_bp = regexr(str_bp,"NEWINGTON GR ROAD","NEWINGTON GREEN ROAD")
replace str_bp = regexr(str_bp,"NEWINGTON GR$","NEWINGTON GREEN")
replace str_bp = regexr(str_bp,"NEVILL(E)*(S)* C","NEVILLES C")
replace str_bp = regexr(str_bp,"NEVILLE ST(REET)*","NEVILLES COURT")
replace str_bp = regexr(str_bp,"SAINT LUKES$","ST LUKE")
replace str_bp = regexr(str_bp,"HUCKNEY","HACKNEY")
replace str_bp = regexr(str_bp,"FANINGDON","FARRINGDON")
replace str_bp = regexr(str_bp,"WINDSON$","WINDSOR")
replace str_bp = regexr(str_bp,"ST GEORGES-IN-THE-EAST","ST GEORGE IN THE EAST")
replace str_bp = regexr(str_bp,"HUMBLEDON$","WIMBLEDON")
replace str_bp = regexr(str_bp,"KING CROSS","KINGS CROSS")
replace str_bp = regexr(str_bp,"KINGS LAND ROAD","KINGSLAND ROAD")
replace str_bp = regexr(str_bp,"HOLLWAY","HOLLOWAY")
replace str_bp = regexr(str_bp,"BETH(NAL)* G[R|N] ROAD","BETHNAL GREEN ROAD")
replace str_bp = regexr(str_bp,"MILL WALL","MILLWALL")
replace str_bp = regexr(str_bp,"CLERKESWELL","CLERKENWELL")
replace str_bp = regexr(str_bp,"FLERT ST","FLEET ST")
replace str_bp = regexr(str_bp,"COMMERICIAL R","COMMERCIAL R")
replace str_bp = regexr(str_bp,"BELVEDORE","BELVEDERE")
replace str_bp = regexr(str_bp,"BARNSBURG","BARNSBURY")
replace str_bp = regexr(str_bp,"KINGLAND ROAD","KINGSLAND ROAD")
replace str_bp = regexr(str_bp,"CLERENWELL","CLERKENWELL")
replace str_bp = regexr(str_bp,"7 SISTERS R","SEVEN SISTERS R")
replace str_bp = regexr(str_bp,"SEVEN LISTERS","SEVEN SISTERS")
replace str_bp = regexr(str_bp,"VICTORIA PKS$","VICTORIA PARK")
replace str_bp = regexr(str_bp,"LOWISHAM","LEWISHAM")
replace str_bp = regexr(str_bp,"WOOWICH","WOOLWICH")
replace str_bp = regexr(str_bp,"GORWELL R","GOSWELL R")
replace str_bp = regexr(str_bp,"EDGEWARE R","EDGWARE R")
replace str_bp = regexr(str_bp,"SUFFRON HILL","SAFFRON HILL")
replace str_bp = regexr(str_bp,"CAMBIDGE","CAMBRIDGE")
replace str_bp = regexr(str_bp,"ST, JOHN ST","ST JOHN ST")
replace str_bp = regexr(str_bp,"ESSET R","ESSEX R")
replace str_bp = regexr(str_bp,"WALTHAM STOW","WALTHAMSTOW")
replace str_bp = regexr(str_bp,"SHEPHERDESS, WALK","SHEPHERDESS WALK")
replace str_bp = regexr(str_bp,"HINGSLAND R","KINGSLAND R")
replace str_bp = regexr(str_bp,"WALHAMSTOW","WALTHAMSTOW")
replace str_bp = regexr(str_bp,"GOWELL R","GOSWELL R")
replace str_bp = regexr(str_bp,"FURRINGDON","FARRINGDON")
replace str_bp = regexr(str_bp,"HAGGRESTON","HAGGERSTON")
replace str_bp = regexr(str_bp,"MITTWALL","MILLWALL")
replace str_bp = regexr(str_bp,"CLK WELL","CLERKENWELL")
replace str_bp = regexr(str_bp,"WHITECROSS$","WHITECROSS STREET")
replace str_bp = regexr(str_bp,"BETHNAL GREET","BETHNAL GREEN")
replace str_bp = regexr(str_bp," MDDX$"," MIDDLESEX")
replace str_bp = regexr(str_bp," WHCHAPEL$"," WHITECHAPEL")
replace str_bp = regexr(str_bp,"CLERKENEWELL","CLERKENWELL")
replace str_bp = regexr(str_bp,"HOCKNEY","HACKNEY")
replace str_bp = regexr(str_bp,"WATTHAMSTOW","WALTHAMSTOW")
replace str_bp = regexr(str_bp," E HAMS$"," EAST HAM")
replace str_bp = regexr(str_bp,"TOTTENHM","TOTTENHAM")
replace str_bp = regexr(str_bp,"BALCKFRIARS","BLACKFRIARS")
replace str_bp = regexr(str_bp,"BEDFORTD ST","BEDFORD ST")
replace str_bp = regexr(str_bp,"BRIMS BUILD","BREAMS BUILD")
replace str_bp = regexr(str_bp,"BREAMS BAG","BREAMS BUILDINGS")
replace str_bp = regexr(str_bp,"CHESTER RENTS","CM CHESTER RENTS")
replace str_bp = regexr(str_bp,"GOLDSMITHS ROW","GOLDSMITH ROW")
replace str_bp = regexr(str_bp,"GOLDSMITH ROAD","GOLDSMITH ROW") if regexm(str_bp,"MAIDSTONE PL")
replace str_bp = regexr(str_bp,"HACKNEWY","HACKNEY")
replace str_bp = regexr(str_bp,"ROSWELL ROAD","GOSWELL ROAD")
replace str_bp = regexr(str_bp,"BLKFRIARS","BLACKFRIARS")
replace str_bp = regexr(str_bp,"LITTLE BROADWALL","BROADWALL")
replace str_bp = regexr(str_bp,"BRUMSWICK","BRUNSWICK")
replace str_bp = regexr(str_bp,"STAMPFORD","STAMFORD")
replace str_bp = regexr(str_bp,"BENNET ST","BENNETT ST")
replace str_bp = regexr(str_bp,"SOUTHWARK PARK, ROAD","SOUTHWARK PARK ROAD")
replace str_bp = regexr(str_bp,"SOUTHWARK PK ROAD","SOUTHWARK PARK ROAD")
replace str_bp = regexr(str_bp,"SOUTHWARK PK, ROAD","SOUTHWARK PARK ROAD")
replace str_bp = regexr(str_bp,"SOUTHWARK B, ROAD","SOUTHWARK BRIDGE ROAD")
replace str_bp = regexr(str_bp,"SOUTHWARK PARK$","SOUTHWARK PARK ROAD")
replace str_bp = regexr(str_bp,"ROTHERHITHE ROAD","ROTHERHITHE NEW ROAD")
replace str_bp = regexr(str_bp, "HALF MOON PASSAGE, CLERKENWELL CLOSE","HALF MOON COURT, CLERKENWELL CLOSE")
replace str_bp = regexr(str_bp,"PRINCE OF WALESS R","PRINCE OF WALES R")
replace str_bp = regexr(str_bp,"PARK TERRACE, UPPARK ROAD","UPPER PARK TERR")
replace str_bp = regexr(str_bp,"OLD CHARLTON$","CHARLTON, KENT")
replace str_bp = regexr(str_bp,"OLD CHARLTON","CHARLTON")
replace str_bp = regexr(str_bp,"BETH GR(N)*$","BETHNAL GREEN")
replace str_bp = regexr(str_bp,"VINER ST","VYNER ST")
replace str_bp = regexr(str_bp,"SPITAL FIELDS","SPITALFIELDS")
replace str_bp = regexr(str_bp,"SHOREDITH","SHOREDITCH")
replace str_bp = regexr(str_bp,"HARLEY ON THAMES","HENLEY ON THAMES")
replace str_bp = regexr(str_bp,"BISHIPSGATE","BISHOPSGATE")
replace str_bp = regexr(str_bp,"GLOSTERSH$","GLOUCESTERSHIRE")
replace str_bp = regexr(str_bp,"BAITHOLOMEW","BARTHOLOMEW")
replace str_bp = regexr(str_bp," KEN GARDENS","KEW GARDENS")
replace str_bp = regexr(str_bp,"DORSETSHIRE","DORSET")
replace str_bp = regexr(str_bp,"KINGS CROP","KINGS CROSS")
replace str_bp = regexr(str_bp,"COMMEICAL ROAD","COMMERCIAL ROAD")
replace str_bp = regexr(str_bp,"HORSELY","HORSLEY")
replace str_bp = regexr(str_bp," HIL$","HILL")
replace str_bp = regexr(str_bp,"HALTON GARDEN","HATTON GARDEN")
replace str_bp = regexr(str_bp,"KINGS GROSS","KINGS CROSS")
replace str_bp = regexr(str_bp,"SHIRLEY CROYDON","SHIRLEY, CROYDON")
replace str_bp = regexr(str_bp," BAKING$","BARKING")
replace str_bp = regexr(str_bp,"CLERELAND ST","CLEVELAND ST")
replace str_bp = regexr(str_bp,"FETTTER L","FETTER L")
replace str_bp = regexr(str_bp,"BLKFRAIRS","BLACKFRIARS")
replace str_bp = regexr(str_bp,"LIME HOUSE","LIMEHOUSE")
replace str_bp = regexr(str_bp,"HACKEY","HACKNEY")
replace str_bp = regexr(str_bp,"GLOUCESTERS$","GLOUCESTERSHIRE")
replace str_bp = regexr(str_bp,"FARINGDON R","FARRINGTON R")
replace str_bp = regexr(str_bp,"NORTHAMP[A-Z]+$","NORTHAMPTONSHIRE")
replace str_bp = regexr(str_bp,"DANTI ROAD","DANTE ROAD")
replace str_bp = regexr(str_bp,"^DENT ROAD","DANTE ROAD")
replace str_bp = regexr(str_bp,"MAIDEN HEAD","MAIDENHEAD")
replace str_bp = regexr(str_bp,"ST JOHN WOOD R","ST JOHNS WOOD R")
replace str_bp = regexr(str_bp,"FINS PARK","FINSBURY PARK")

* Correct end of string place names
replace str_bp = regexr(str_bp," LONDON FIELD$"," LONDON FIELDS")
replace str_bp = regexr(str_bp," STH HACKNEY$"," SOUTH HACKNEY")
replace str_bp = regexr(str_bp," S HACKNEY$"," SOUTH HACKNEY")
replace str_bp = regexr(str_bp," SO HACKNEY$"," SOUTH HACKNEY")
replace str_bp = regexr(str_bp," STH LAMBETH$"," SOUTH LAMBETH")
replace str_bp = regexr(str_bp," LOWER EDMONTON"," EDMONTON")
replace str_bp = regexr(str_bp," L EDMONTON$"," EDMONTON")
replace str_bp = regexr(str_bp," LWR EDMONTON$"," EDMONTON")
replace str_bp = regexr(str_bp," LR EDMONTON$"," EDMONTON")
replace str_bp = regexr(str_bp," UPPER EDMONTON$"," EDMONTON")
replace str_bp = regexr(str_bp," UPP EDMONTON$"," EDMONTON")
replace str_bp = regexr(str_bp," LT EDMONTON$"," EDMONTON")
replace str_bp = regexr(str_bp," EAST STEPNEY$"," STEPNEY")
replace str_bp = regexr(str_bp," EAST GREENWICH"," GREENWICH")
replace str_bp = regexr(str_bp," E GREENWICH"," GREENWICH")
replace str_bp = regexr(str_bp," NORTH WOOLWICH$"," WOOLWICH")
replace str_bp = regexr(str_bp," SOUTH WOOLWICH$"," WOOLWICH")
replace str_bp = regexr(str_bp," S WOOLWICH$"," WOOLWICH")
replace str_bp = regexr(str_bp," NTH WOOLWICH$"," WOOLWICH")
replace str_bp = regexr(str_bp," N WOOLWICH$"," WOOLWICH")
replace str_bp = regexr(str_bp," NR WOOLWICH$"," WOOLWICH")
replace str_bp = regexr(str_bp," NR CROYDON$"," CROYDON")
replace str_bp = regexr(str_bp," WEST CROYDON$"," CROYDON")
replace str_bp = regexr(str_bp," SOUTH CROYDON$"," CROYDON")
replace str_bp = regexr(str_bp," W CROYDON$"," CROYDON")
replace str_bp = regexr(str_bp," ST CROYDON$"," CROYDON")
replace str_bp = regexr(str_bp," OLD BRENTFORD$"," BRENTFORD")
replace str_bp = regexr(str_bp," NEW BRENTFORD$"," BRENTFORD")
replace str_bp = regexr(str_bp," WEST HENDON$"," HENDON")
replace str_bp = regexr(str_bp," SOUTH GRAVESEND$"," GRAVESEND")
replace str_bp = regexr(str_bp," DEVON$"," DEVONSHIRE")
replace str_bp = regexr(str_bp," NORTH DEVONSHIRE$"," DEVONSHIRE")
replace str_bp = regexr(str_bp," N DEVONSHIRE$"," DEVONSHIRE")
replace str_bp = regexr(str_bp," NORTH DEVONSHIRE$"," DEVONSHIRE")
replace str_bp = regexr(str_bp," LINCOLN$"," LINCOLNSHIRE")
replace str_bp = regexr(str_bp," MERIONETH$"," MERIONETHSHIRE")
replace str_bp = regexr(str_bp," WORCESTER$"," WORCESTERSHIRE")
replace str_bp = regexr(str_bp," DERBY$"," DERBYSHIRE")
replace str_bp = regexr(str_bp,"[I|J] OF W$","HAMPSHIRE")
replace str_bp = regexr(str_bp,"ISLE OF WIGHT","HAMPSHIRE")
replace str_bp = regexr(str_bp,"I OF WIGHT","HAMPSHIRE")
replace str_bp = regexr(str_bp,"U HOLLOWAY$","HOLLOWAY")
replace str_bp = regexr(str_bp,"N HOLLOWAY$","HOLLOWAY")
replace str_bp = regexr(str_bp,"UP HOLLOWAY$","HOLLOWAY")
replace str_bp = regexr(str_bp,"UPP HOLLOWAY$","HOLLOWAY")
replace str_bp = regexr(str_bp,"UPPER	HOLLOWAY$","HOLLOWAY")
replace str_bp = regexr(str_bp,"BARKING,","BARKING TOWN,")
replace str_bp = regexr(str_bp,"BARKING$","BARKING TOWN")
replace str_bp = regexr(str_bp,"BETHNAL G$","BETHNAL GREEN")
replace str_bp = regexr(str_bp,"BETHNAL G ROAD","BETHNAL GREEN ROAD")
replace str_bp = regexr(str_bp,"S LUKES$","ST LUKE")
replace str_bp = regexr(str_bp,"HUNTINGS$","HUNTINGTONSHIRE")
replace str_bp = regexr(str_bp,"ST GEORGES E$","ST GEORGE IN THE EAST")
replace str_bp = regexr(str_bp,"ST GEORGE EAST$","ST GEORGE IN THE EAST")
replace str_bp = regexr(str_bp,"NORTH WCHAPEL$","WHITECHAPEL")
replace str_bp = regexr(str_bp,"WCHAPEL$","WHITECHAPEL")
replace str_bp = regexr(str_bp,"GOLDENLANE","GOLDEN LANE")
replace str_bp = regexr(str_bp,"GREEN HARBOR CT","GREEN ARBOUR CT")
replace str_bp = regexr(str_bp,"GREEN ARBOR CT","GREEN ARBOUR CT")
replace str_bp = regexr(str_bp,"GREEN HARBOUR CT","GREEN ARBOUR CT")
replace str_bp = regexr(str_bp,"S TOTTENHAM","TOTTENHAM")
replace str_bp = regexr(str_bp,"SOUTH TOTTENHAM","TOTTENHAM")
replace str_bp = regexr(str_bp,"STH TOTTENHAM","TOTTENHAM")
replace str_bp = regexr(str_bp," ST TOTTENHAM"," TOTTENHAM")
replace str_bp = regexr(str_bp,"LOWER TOTTENHAM"," TOTTENHAM")
replace str_bp = regexr(str_bp,"CANNING TN","CANNING TOWN")
replace str_bp = regexr(str_bp,"COWCROSS$","COWCROSS STREET")
replace str_bp = regexr(str_bp,"COWCROSS,","COWCROSS STREET,")
replace str_bp = regexr(str_bp,"ST JOHN ST L$","ST JOHN ST ROAD")
replace str_bp = regexr(str_bp,"CLARKWELL$","CLERKENWELL")
replace str_bp = regexr(str_bp,"GRAY INN$","GRAYS INN")
replace str_bp = regexr(str_bp,"GRAY INN$","GRAYS INN")
replace str_bp = regexr(str_bp,"COMPBELL ST","CAMPBELL ST")
replace str_bp = regexr(str_bp,", BEDS$",", BEDFORDSHIRE")
replace str_bp = regexr(str_bp," GDN$","GARDEN")
replace str_bp = regexr(str_bp," CRESET$"," CRESCENT")
replace str_bp = regexr(str_bp," CREST$"," CRESCENT")
replace str_bp = regexr(str_bp," GLOS$"," GLOUCESTERSHIRE")
replace str_bp = regexr(str_bp," GLOSTERS$"," GLOUCESTERSHIRE")
replace str_bp = regexr(str_bp,"LOUGHBORO$","LOUGHBOROUGH, BRIXTON")

// Missing comma before county at end of string

replace str_bp = regexr(str_bp," KENT$",", KENT") if regexm(str_bp,"[A-Z] KENT$")==1 & regexm(str_bp,"NEW KENT")==0 & regexm(str_bp,"OLD KENT")==0
replace str_bp = regexr(str_bp," HERTS$",", HERTFORDSHIRE") if regexm(str_bp,"[A-Z] HERTS$")==1 
replace str_bp = regexr(str_bp," WILTS$",", WILTSHIRE") if regexm(str_bp,"[A-Z] WILTSHIRE$")==1 
replace str_bp = regexr(str_bp," HANTS$",", HAMPSHIRE") if regexm(str_bp,"[A-Z] HANTS$")==1 
replace str_bp = regexr(str_bp," HAMPSHIRE$",", HAMPSHIRE") if regexm(str_bp,"[A-Z] HAMPSHIRE$")==1 
replace str_bp = regexr(str_bp," YORKS$",", YORKSHIRE") if regexm(str_bp,"[A-Z] YORKS$")==1 
replace str_bp = regexr(str_bp," BERKS$",", BERKSHIRE") if regexm(str_bp,"[A-Z] BERKS$")==1 
replace str_bp = regexr(str_bp," BUCKS$",", BUCKINGHAMSHIRE") if regexm(str_bp,"[A-Z] BUCKS$")==1 
replace str_bp = regexr(str_bp," HACKNEY$",", HACKNEY") if regexm(str_bp,"[A-Z] HACKNEY$")==1  & regexm(str_bp,"SOUTH HACKNEY")==0
replace str_bp = regexr(str_bp," ST LUKE(S)*$",", ST LUKE") if regexm(str_bp,"[A-Z] ST LUKE(S)*$")==1 
replace str_bp = regexr(str_bp," CITY$",", LONDON CITY") if regexm(str_bp,"[A-Z] CITY$")==1 & regexm(str_bp,"LONDON CITY")==0
replace str_bp = regexr(str_bp," OXFORD$",", OXFORD") if regexm(str_bp,"[A-Z] OXFORD$")==1 & regexm(str_bp,"NR OXFORD")==0
replace str_bp = regexr(str_bp," HOLBORN$",", HOLBORN") if regexm(str_bp,"[A-Z] HOLBORN$")==1 & regexm(str_bp,"HIGH HOLBORN")==0
replace str_bp = regexr(str_bp," BETHNAL GREEN$",", BETHNAL GREEN") if regexm(str_bp,"[A-Z] BETHNAL GREEN$")==1 
replace str_bp = regexr(str_bp," WHITECHAPEL$",", WHITECHAPEL") if regexm(str_bp,"[A-Z] WHITECHAPEL$")==1 & regexm(str_bp,"SOUTH WHITECHAPEL")==0
replace str_bp = regexr(str_bp," WEST HAM$",", WEST HAM") if regexm(str_bp,"[A-Z] WEST HAM$")==1 
replace str_bp = regexr(str_bp," POPLAR$",", POPLAR") if regexm(str_bp,"[A-Z] POPLAR$")==1 & regexm(str_bp,"SOUTH POPLAR")==0
replace str_bp = regexr(str_bp," LAMBETH$",", LAMBETH") if regexm(str_bp,"[A-Z] LAMBETH$")==1  & regexm(str_bp,"SOUTH LAMBETH")==0
replace str_bp = regexr(str_bp," WANDSWORTH$",", WANDSWORTH") if regexm(str_bp,"[A-Z] WANDSWORTH$")==1  & regexm(str_bp,"NEW WANDSWORTH")==0
replace str_bp = regexr(str_bp," HILL DARTFORD$"," HILL, DARTFORD")
replace str_bp = regexr(str_bp," DORKING$",", DORKING") if regexm(str_bp,"[A-Z] DORKING$")==1  & regexm(str_bp,"R DORKING")==0
replace str_bp = regexr(str_bp," SEVENOAKS$",", SEVENOAKS") if regexm(str_bp,"[A-Z] SEVENOAKS$")==1  & regexm(str_bp,"R SEVENOAKS")==0
replace str_bp = regexr(str_bp," EPPING$",", EPPING") if regexm(str_bp,"[A-Z] EPPING$")==1  & regexm(str_bp,"R EPPING")==0
replace str_bp = regexr(str_bp," DEVONSHIRE$",", DEVONSHIRE") if regexm(str_bp,"[A-Z] DEVONSHIRE$")==1  & regexm(str_bp,"R DEVONSHIRE")==0
replace str_bp = regexr(str_bp," LINCOLNSHIRE$",", LINCOLNSHIRE") if regexm(str_bp,"[A-Z] LINCOLNSHIRE$")==1  & regexm(str_bp,"R LINCOLNSHIRE")==0
replace str_bp = regexr(str_bp," DERBYSHIRE$",", DERBYSHIRE") if regexm(str_bp,"[A-Z] DERBYSHIRE$")==1  & regexm(str_bp,"R DERBYSHIRE")==0
replace str_bp = regexr(str_bp," BARKING TOWN$",", BARKING TOWN") if regexm(str_bp,"[A-Z] BARKING TOWN$")==1
replace str_bp = regexr(str_bp," BERMONDSEY$",", BERMONDSEY") if regexm(str_bp,"[A-Z] BERMONDSEY$")==1 
replace str_bp = regexr(str_bp,", CITY$",", LONDON CITY")
replace str_bp = regexr(str_bp," CITY ROAD",", CITY ROAD") if regexm(str_bp,"[A-Z] CITY ROAD")==1
replace str_bp = regexr(str_bp," GOLDEN LANE$",", GOLDEN LANE") if regexm(str_bp,"[A-Z] GOLDEN LANE$")==1
replace str_bp = regexr(str_bp,"LEYTONSTONE","LEYTON") if regexm(str_bp,"LEYTONSTONE ROAD")==0
replace str_bp = regexr(str_bp," MILE END NEW TOWN$",", MILE END NEW TOWN") if regexm(str_bp,"[A-Z] MILE END NEW TOWN$")==1 
replace str_bp = regexr(str_bp," LEYTON",", LEYTON") if regexm(str_bp,"[A-Z] LEYTON")==1 & regexm(str_bp,"LEYTONSTONE")==0
replace str_bp = regexr(str_bp," ILFORD",", ILFORD") if regexm(str_bp,"[A-Z] ILFORD")==1 & regexm(str_bp,"LITTLE ILFORD")==0
replace str_bp = regexr(str_bp," WALTHAMSTOW",", WALTHAMSTOW") if regexm(str_bp,"[A-Z] WALTHAMSTOW")==1 & regexm(str_bp,"WEST WALTHAMSTOW")==0
replace str_bp = regexr(str_bp," HIGHGATE",", HIGHGATE") if regexm(str_bp,"[A-Z] HIGHGATE")==1 & regexm(str_bp,"FROM HIGHGATE")==0 & regexm(str_bp,"FR HIGHGATE")==0
replace str_bp = regexr(str_bp," COWCROSS",", COWCROSS") if regexm(str_bp,"[A-Z] COWCROSS")==1 
replace str_bp = regexr(str_bp," HACKNEY ROAD",", HACKNEY ROAD") if regexm(str_bp,"[A-Z] HACKNEY ROAD")==1 
replace str_bp = regexr(str_bp," PECKHAM RYE",", PECKHAM RYE") if regexm(str_bp,"[A-Z] PECKHAM RYE")==1 
replace str_bp = regexr(str_bp," CLERKENWELL GREEN",", CLERKENWELL GREEN") if regexm(str_bp,"[A-Z] CLERKENWELL GREEN")==1 
replace str_bp = regexr(str_bp," CLERKENWELL CLOSE",", CLERKENWELL CLOSE") if regexm(str_bp,"[A-Z] CLERKENWELL CLOSE")==1 
replace str_bp = regexr(str_bp," CLERKENWELL ROAD",", CLERKENWELL ROAD") if regexm(str_bp,"[A-Z] CLERKENWELL ROAD")==1 
replace str_bp = regexr(str_bp," CLERKENWELL EC",", CLERKENWELL, EC") if regexm(str_bp,"[A-Z] CLERKENWELL EC")==1 
replace str_bp = regexr(str_bp," ST JOHN",", ST JOHN") if regexm(str_bp,"[A-Z] ST JOHN")==1 
replace str_bp = regexr(str_bp," COMMERCIAL ROAD",", COMMERCIAL ROAD") if regexm(str_bp,"[A-Z] COMMERCIAL ROAD")==1 
replace str_bp = regexr(str_bp," STAMFORD ST",", STAMFORD ST") if regexm(str_bp,"[A-Z] STAMFORD ST")==1 
replace str_bp = regexr(str_bp," BRUNSWICK STREET",", BRUNSWICK STREET") if regexm(str_bp,"[A-Z] BRUNSWICK STREET")==1 
replace str_bp = regexr(str_bp," YORK ROAD",", YORK ROAD") if regexm(str_bp,"[A-Z] YORK ROAD")==1 & regexm(str_bp,"OLD YORK ROAD")==0
replace str_bp = regexr(str_bp," KINGS( )*CROSS",", KINGS CROSS") if regexm(str_bp,"[A-Z] KINGS( )*CROSS")==1 & regexm(str_bp,"R KINGS( )*CROSS")==0
replace str_bp = regexr(str_bp," HORNSEY ROAD",", HORNSEY ROAD") if regexm(str_bp,"[A-Z] HORNSEY ROAD")==1
replace str_bp = regexr(str_bp," STOKE NEWINGTON",", STOKE NEWINGTON") if regexm(str_bp,"[A-Z] STOKE NEWINGTON")==1
replace str_bp = regexr(str_bp," ESSEX ROAD",", ESSEX ROAD") if regexm(str_bp,"[A-Z] ESSEX ROAD")==1
replace str_bp = regexr(str_bp," BETHNAL GREEN ROAD",", BETHNAL GREEN ROAD") if regexm(str_bp,"[A-Z] BETHNAL GREEN ROAD")==1 & regexm(str_bp,"OLD BETHNAL GREEN ROAD")==0
replace str_bp = regexr(str_bp," EAST HAM",", EAST HAM") if regexm(str_bp,"[A-Z] EAST HAM")==1 & regexm(str_bp,"SOUTH EAST HAM")==0
replace str_bp = regexr(str_bp," OLD ST",", OLD ST") if regexm(str_bp,"[A-Z] OLD ST")==1 & regexm(str_bp,"NEW OLD ST")==0
replace str_bp = regexr(str_bp," OLD KENT ROAD",", OLD KENT ROAD") if regexm(str_bp,"[A-Z] OLD KENT ROAD")==1
replace str_bp = regexr(str_bp," GRAYS INN(,)* R(OA)*D",", GRAYS INN ROAD") if regexm(str_bp,"[A-Z] GRAYS INN(,)* R(OA)*D")==1
replace str_bp = regexr(str_bp," ALDERSGATE ST",", ALDERSGATE ST") if regexm(str_bp,"[A-Z] ALDERSGATE ST")==1
replace str_bp = regexr(str_bp," VICTORIA P(AR)*K",", VICTORIA PARK") if regexm(str_bp,"[A-Z] VICTORIA P(AR)*K")==1
replace str_bp = regexr(str_bp," CHANCERY LANE",", CHANCERY LANE") if regexm(str_bp,"[A-Z] CHANCERY LANE")==1
replace str_bp = regexr(str_bp," SOUTHWARK",", SOUTHWARK") if regexm(str_bp,"[A-Z] SOUTHWARK")==1 & regexm(str_bp,"THE SOUTHWARK")==0
replace str_bp = regexr(str_bp," ROTHERHITHE",", ROTHERHITHE") if regexm(str_bp,"[A-Z] ROTHERHITHE")==1
replace str_bp = regexr(str_bp," NEWINGTON BUTTS",", NEWINGTON BUTTS") if regexm(str_bp,"[A-Z] NEWINGTON BUTTS")==1
replace str_bp = regexr(str_bp," O K RD$"," OLD KENT ROAD")

replace str_bp = regexr(str_bp," E C$"," EC")
replace str_bp = regexr(str_bp," S C$"," SE")
replace str_bp = regexr(str_bp," S E$"," SE")
replace str_bp = regexr(str_bp," S W$"," SW")
replace str_bp = regexr(str_bp," W C$"," WC")
replace str_bp = regexr(str_bp," N E$"," NE")
replace str_bp = regexr(str_bp," N W$"," NW")

#delimit ;
local placenames "ESSEX SURREY SOMERSET HOXTON CLERKENWELL SOUTHWARK SHOREDITCH ISLINGTON CAMBERWELL EDMONTON STEPNEY GREENWICH
					WOOLWICH LEWISHAM RICHMOND GRAVESEND MIDDLESEX SUSSEX CORNWALL NORFOLK WILTSHIRE DORSET MERIONETHSHIRE BARBICAN
					ANERLEY CHELMSFORD TOTTENHAM CHESHUNT FINSBURY COWCROSS PADDINGTON STRATFORD BASINGSTOKE BLACKFRIARS DARTFORD CARDIFF
					WINDSOR LIMEHOUSE PORTSMOUTH MITCHAM ALDGATE VAUXHALL HAYMARKET NUNHEAD WAPPING KNIGHTSBRIDGE RADCLIFFE BARNSBURY
					HAGGERSTON GLOUCESTERSHIRE HAMMERSMITH GLOUCESTERSHIRE LEICESTER";
#delimit cr
					
foreach place of local placenames {
	replace str_bp = regexr(str_bp," `place'$",", `place'") if regexm(str_bp,"[A-Z] `place'$")==1 
}

replace str_bp = substr(str_bp,strpos(str_bp,",")+1,.) if strpos(str_bp,",") > 0
replace str_bp = substr(str_bp,strpos(str_bp,",")+1,.) if strpos(str_bp,",") > 0
replace str_bp = substr(str_bp,strpos(str_bp,",")+1,.) if strpos(str_bp,",") > 0
replace str_bp = trim(str_bp)

replace str_bp = "" if regexm(str_bp," ST$") | regexm(str_bp,"ROAD$")

drop if length(str_bp) <= 3 | regexm(str_bp,"NOT KNOWN") | regexm(str_bp," N K ") | str_bp == "GREEN" | str_bp == "SOUTH"

replace str_bp = regexr(str_bp,"^[^A-Z]+","")
replace str_bp = regexr(str_bp,"[^A-Z]+$","")

replace str_bp = regexr(str_bp,"^[A-Z][ ]","")
replace str_bp = regexr(str_bp,"^[A-Z][ ]","")
replace str_bp = regexr(str_bp,"^OR[ ]","")

******** Prepare merge with parish list for London **********

save "$PROJ_PATH/processed/temp/icem_bpstring_recode_inprog.dta", replace
keep str_bp
gduplicates drop 
gsort str_bp

gen bstr_short = upper(str_bp)

local vowels "A E I O U Y"
foreach letter of local vowels {
	replace bstr_short = subinstr(bstr_short,"`letter'","",.)
}
replace bstr_short = substr(bstr_short,1,3)
sort bstr_short str_bp

joinby bstr_short using "$PROJ_PATH/processed/temp/london_parishes.dta"

gen upper_str_bp = upper(str_bp)
gen upper_std_par = upper(place)

save "$PROJ_PATH/processed/temp/icem_bpstring_jw_input.dta", replace
keep upper_std_par upper_str_bp
bysort upper_std_par upper_str_bp: keep if _n == 1
jarowinkler upper_std_par upper_str_bp, gen(jw_dist)
keep if jw_dist >= 0.9
save "$PROJ_PATH/processed/temp/icem_bpstring_jw_dist.dta", replace

use "$PROJ_PATH/processed/temp/icem_bpstring_jw_input.dta", clear
merge m:1 upper_std_par upper_str_bp using "$PROJ_PATH/processed/temp/icem_bpstring_jw_dist.dta", keep(3) nogen

egen max_dist = max(jw_dist), by(str_bp)
keep if jw_dist == max_dist

keep str_bp std_par
gduplicates drop 
bysort str_bp: keep if _N == 1

fmerge m:1 std_par using "$PROJ_PATH/processed/temp/london_counties.dta", keep(3) nogen
sort str_bp std_par cnti alt_cnti
save "$PROJ_PATH/processed/temp/icem_bpstring_jw_output.dta", replace

use "$PROJ_PATH/processed/temp/icem_bpstring_recode_inprog.dta", clear
joinby str_bp using "$PROJ_PATH/processed/temp/icem_bpstring_jw_output.dta", unmatched(master)

replace std_par = "London" if _merge == 1  & london == 1
replace cnti = "MDX" if _merge == 1  & london == 1

keep if std_par != ""

keeporder Bpstring std_par cnti alt_cnti
gsort Bpstring std_par cnti alt_cnti

rename std_par recode_std_par
rename cnti recode_cnti
rename alt_cnti recode_alt_cnti

save "$PROJ_PATH/processed/temp/icem_bpstring_assigned.dta", replace

rm "$PROJ_PATH/processed/temp/icem_bpstring_recode_inprog.dta"
rm "$PROJ_PATH/processed/temp/icem_bpstring_jw_input.dta"
rm "$PROJ_PATH/processed/temp/icem_bpstring_jw_dist.dta"
rm "$PROJ_PATH/processed/temp/icem_bpstring_jw_output.dta"
rm "$PROJ_PATH/processed/temp/london_parishes.dta"
rm "$PROJ_PATH/processed/temp/london_counties.dta"

*********************************************************************************************************************
*********** I-CeM Bpstring Crosswalk *************
*********************************************************************************************************************

forvalues y = 1881(10)1911 {
	use Bpstring Cnti BpCtry Ctry using "$PROJ_PATH/processed/intermediate/icem/self_vars/icem_self_`y'_birthplace.dta", clear
	
	gduplicates drop 
	gisid Bpstring Cnti BpCtry Ctry, missok 
	gsort Bpstring Cnti BpCtry Ctry
	
	tempfile std_par`y'
	save `std_par`y'', replace
}
clear
forvalues y = 1881(10)1911 {
	append using `std_par`y''
}

gduplicates drop 
gisid Bpstring Cnti BpCtry Ctry, missok 
gsort Bpstring Cnti BpCtry Ctry

recast str Bpstring Cnti

rename Cnti std_par
rename BpCtry cnti
rename Ctry alt_cnti
replace Bpstring = upper(Bpstring)

***** Recode birth parish ****

gen flag_recode_bp = 0

gen bcounty1 = cnti
gen bcounty2 = alt_cnti
gen std_par1 = std_par 
gen std_par2 = std_par1 if bcounty2 != ""
order Bpstring std_par cnti alt_cnti std_par* bcounty* flag*, last
compress

/* 	Among observations with raw 'Bpstring' variable coded to std_par == "Not Coded" and bcounty1 == "UNK",
	check if same original birth place string has been coded with a unique parish and county combination,
	then assign coded value to the "Not Coded" cases.

*/

fmerge m:1 Bpstring using "$PROJ_PATH/processed/temp/icem_bpstring_recoded_missing.dta", keep (1 3) nogen

gen temp_flag_recode = (std_par1 == "Not Coded" & bcounty1 == "UNK" & recode_std_par != "")
	replace std_par1 = recode_std_par if temp_flag_recode == 1
	replace bcounty1 = recode_bcounty1 if temp_flag_recode == 1
	replace std_par2 = recode_std_par if temp_flag_recode == 1 & recode_bcounty2 != ""
	replace bcounty2 = recode_bcounty2 if temp_flag_recode == 1 & recode_bcounty2 != ""
	replace flag_recode_bp = 1 if temp_flag_recode == 1
	drop temp_flag_recode
	
gen temp_flag_recode = (std_par1 == "Unknown" & recode_std_par != "")
	replace bcounty2 = bcounty1 if temp_flag_recode == 1 & bcounty1 != recode_bcounty1
	replace std_par1 = recode_std_par if temp_flag_recode == 1
	replace bcounty1 = recode_bcounty1 if temp_flag_recode == 1
	replace std_par2 = recode_std_par if temp_flag_recode == 1 & recode_bcounty2 != ""
	replace bcounty2 = recode_bcounty2 if temp_flag_recode == 1 & recode_bcounty2 != ""
	replace flag_recode_bp = 1 if temp_flag_recode == 1
	drop temp_flag_recode	
drop recode_*

/* 	Recode cases where 'Bpstring' has been assigned a value of std_par == "London" if the same raw string
	was assigned to a parish within London in other cases.
*/

fmerge m:1 Bpstring using "$PROJ_PATH/processed/temp/icem_bpstring_recoded_london.dta", keep(1 3) nogen

gen temp_flag_recode = (std_par1 == "London" & recode_std_par != "")
	replace bcounty2 = bcounty1 if temp_flag_recode == 1 & bcounty1 != recode_bcounty1
	replace std_par1 = recode_std_par if temp_flag_recode == 1
	replace bcounty1 = recode_bcounty1 if temp_flag_recode == 1
	replace flag_recode_bp = 1 if temp_flag_recode == 1
	drop temp_flag_recode
gen temp_flag_recode = (std_par1 == "Unknown" & recode_std_par != "")
	replace bcounty2 = bcounty1 if temp_flag_recode == 1 & bcounty1 != recode_bcounty1
	replace std_par1 = recode_std_par if temp_flag_recode == 1
	replace bcounty1 = recode_bcounty1 if temp_flag_recode == 1
	replace flag_recode_bp = 1 if temp_flag_recode == 1
	drop temp_flag_recode
drop recode_*

/* 	Identify cases where 'Bpstring' has been assigned to multiple std_par values. Find best JW match
	among std_par strings contained within Bpstring. Recode these cases. */
	
fmerge m:1 Bpstring using "$PROJ_PATH/processed/temp/icem_bpstring_recoded_best_match.dta", keep(1 3) nogen

gen temp_flag_recode = (std_par1 == "Not Coded" & bcounty1 == "UNK" & recode_std_par != "") // )
	replace std_par1 = recode_std_par if temp_flag_recode == 1
	replace bcounty1 = recode_bcounty1 if temp_flag_recode == 1
	replace flag_recode_bp = 1 if temp_flag_recode == 1
	drop temp_flag_recode
	
	gen temp_flag_recode = (std_par1 == "Unknown" & bcounty1 == recode_bcounty1 & recode_std_par != "")
	replace std_par1 = recode_std_par if temp_flag_recode == 1
	replace flag_recode_bp = 1 if temp_flag_recode == 1
	drop temp_flag_recode
	
	gen temp_flag_recode = (std_par1 == "Unknown" & bcounty1 != recode_bcounty1 & recode_std_par != "")
	replace std_par2 = recode_std_par if temp_flag_recode == 1
	replace bcounty2 = recode_bcounty1 if temp_flag_recode == 1
	replace flag_recode_bp = 1 if temp_flag_recode == 1
	drop temp_flag_recode
		
	gen string_overlap = (strpos(std_par1,recode_std_par) == 0 & strpos(std_par2,recode_std_par) == 0 & strpos(Bpstring,upper(recode_std_par)) > 0)
		
	gen temp_flag_recode = (string_overlap == 1 & recode_bcounty1 == bcounty1) 
	replace std_par1 = recode_std_par if temp_flag_recode == 1
	replace flag_recode_bp = 1 if temp_flag_recode == 1
	drop temp_flag_recode
	
	gen temp_flag_recode = (string_overlap == 1 & recode_bcounty1 == bcounty2)
	replace std_par2 = recode_std_par if temp_flag_recode == 1
	replace flag_recode_bp = 1 if temp_flag_recode == 1
	drop temp_flag_recode
	
	gen std_par3 = ""
	gen bcounty3 = ""
	
	gen temp_flag_recode = (string_overlap == 1 & recode_bcounty1 != bcounty1 & recode_bcounty1 != bcounty2)
	replace std_par3 = recode_std_par if temp_flag_recode == 1
	replace bcounty3 = recode_bcounty1 if temp_flag_recode == 1
	replace flag_recode_bp = 1 if temp_flag_recode == 1
	drop temp_flag_recode
	
	gen temp_flag_recode = (recode_std_par != "" & flag_recode_bp == 0 & std_par1 != recode_std_par & bcounty1 == recode_bcounty1 & upper(recode_std_par) == Bpstring)
	replace std_par1 = recode_std_par if temp_flag_recode == 1
	replace flag_recode_bp = 1 if temp_flag_recode == 1
	drop temp_flag_recode

	gen temp_flag_recode = (recode_std_par != "" & flag_recode_bp == 0 & std_par2 != recode_std_par & bcounty2 == recode_bcounty1 & upper(recode_std_par) == Bpstring)
	replace std_par2 = recode_std_par if temp_flag_recode == 1
	replace flag_recode_bp = 1 if temp_flag_recode == 1
	drop temp_flag_recode

drop string_overlap recode*
order Bpstring std_par cnti alt_cnti std_par* bcounty* flag*, last

* Assign parish and county for strings matched to London parishes

replace std_par1 = "Not Coded" if Bpstring == "HORSLEY DOWN" & std_par1 == "Not Applicable"

fmerge m:1 Bpstring using "$PROJ_PATH/processed/temp/icem_bpstring_assigned.dta", keep(1 3) nogen
	gen temp_flag_recode = (recode_std_par != "" & std_par1 == "Not Coded" & bcounty1 == "UNK")
	replace std_par1 = recode_std_par if temp_flag_recode == 1
	replace bcounty1 = recode_cnti if temp_flag_recode == 1
	replace std_par2 = recode_std_par if temp_flag_recode == 1 & bcounty2 == "" & recode_alt_cnti != ""
	replace bcounty2 = recode_alt_cnti if temp_flag_recode == 1 & bcounty2 == "" & recode_alt_cnti != ""
	replace flag_recode_bp = 1 if temp_flag_recode == 1
	drop temp_flag_recode

	gen temp_flag_recode = (recode_std_par != "" & std_par1 == "Unknown" & bcounty1 == recode_cnti)
	replace std_par1 = recode_std_par if temp_flag_recode == 1
	replace bcounty1 = recode_cnti if temp_flag_recode == 1
	replace std_par2 = recode_std_par if temp_flag_recode == 1 & bcounty2 == "" & recode_alt_cnti != ""
	replace bcounty2 = recode_alt_cnti if temp_flag_recode == 1 & bcounty2 == "" & recode_alt_cnti != ""
	replace flag_recode_bp = 1 if temp_flag_recode == 1
	drop temp_flag_recode
	
	gen temp_flag_recode = (recode_std_par != "" & std_par1 == "London" & recode_std_par != "London")
	replace std_par1 = recode_std_par if temp_flag_recode == 1
	replace bcounty1 = recode_cnti if temp_flag_recode == 1
	replace std_par2 = recode_std_par if temp_flag_recode == 1 & bcounty2 == "" & recode_alt_cnti != ""
	replace bcounty2 = recode_alt_cnti if temp_flag_recode == 1 & bcounty2 == "" & recode_alt_cnti != ""
	replace flag_recode_bp = 1 if temp_flag_recode == 1
	drop temp_flag_recode

	gen std_par4 = ""
	gen std_par5 = ""
	gen bcounty4 = ""
	gen bcounty5 = ""
	
	gen temp_flag_recode = (recode_std_par != "" & recode_std_par != std_par1 & recode_std_par != "London" & (recode_cnti == bcounty1 | recode_cnti == bcounty2))
	replace std_par4 = recode_std_par if temp_flag_recode == 1
	replace bcounty4 = recode_cnti if temp_flag_recode == 1
	replace std_par5 = recode_std_par if temp_flag_recode == 1 & recode_alt_cnti != ""
	replace bcounty5 = recode_alt_cnti if temp_flag_recode == 1 & recode_alt_cnti != ""
	replace flag_recode_bp = 1 if temp_flag_recode == 1
	drop temp_flag_recode
	
	gen std_par6 = ""
	gen std_par7 = ""
	gen bcounty6 = ""
	gen bcounty7 = ""
	
	gen temp_flag_recode = (recode_std_par != "" & recode_std_par != std_par1 & upper(std_par1) != Bpstring)
	replace std_par6 = recode_std_par if temp_flag_recode == 1
	replace bcounty6 = recode_cnti if temp_flag_recode == 1
	replace std_par7 = recode_std_par if temp_flag_recode == 1 & recode_alt_cnti != ""
	replace bcounty7 = recode_alt_cnti if temp_flag_recode == 1 & recode_alt_cnti != ""
	replace flag_recode_bp = 1 if temp_flag_recode == 1
	drop temp_flag_recode
	drop recode*
	
order Bpstring std_par cnti alt_cnti flag* std_par* bcounty*, last
gunique Bpstring std_par cnti alt_cnti flag*
rename std_par std_par_orig

keep if flag_recode_bp == 1
drop flag_recode_bp

gen long obs_id = _n
greshape long std_par bcounty, i(obs_id) j(order_id)
gen primary_county = (order_id == 1)
drop if std_par == "" & bcounty == ""

* Reassign primary county
egen tot_pc = total(primary_county == 1), by(obs_id bcounty)
replace primary_county = 1 if tot_pc > 0
drop tot_pc

* Check for London parishes

fmerge m:1 std_par using "$PROJ_PATH/processed/intermediate/geography/icem_london_std_par.dta", keep(1 3)

egen tot_lp = total(_merge == 3 & std_par != "London"), by(obs_id bcounty)
drop if tot_lp > 0 & std_par == "London"
drop tot_lp _merge

drop order_id
gduplicates drop

gsort + obs_id - primary_county + bcounty + std_par
egen order_id = seq(), by(obs_id)
greshape wide std_par bcounty primary_county, i(obs_id) j(order_id)

tab primary_county1
replace primary_county1 = 1 if primary_county1 > 0
tab primary_county1

rename std_par_orig std_par
order Bpstring std_par cnti alt_cnti
drop obs_id
save "$PROJ_PATH/processed/intermediate/geography/icem_bpstring_xwk.dta", replace

// Clean up 
rm "$PROJ_PATH/processed/temp/icem_placelist_stdpar_xwk.dta"
rm "$PROJ_PATH/processed/temp/icem_stdpar_cnti_xwk.dta"
rm "$PROJ_PATH/processed/temp/icem_bpstring_recoded_missing.dta"
rm "$PROJ_PATH/processed/temp/icem_bpstring_recoded_london.dta"
rm "$PROJ_PATH/processed/temp/icem_bpstring_recoded_best_match.dta"
rm "$PROJ_PATH/processed/temp/icem_bpstring_recode_input.dta" 
rm "$PROJ_PATH/processed/temp/icem_bpstring_assigned.dta" 

disp "DateTime: $S_DATE $S_TIME"

* EOF
