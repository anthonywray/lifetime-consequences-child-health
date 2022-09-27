version 14
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 04.03_clean_residential_addresses.do
* PURPOSE: The do file cleans and standardizes the components of the original string variable containing the cause of admission to the hospital.
************

// Create parish-district-subdist-county crosswalks from raw 1881 census data
use "$PROJ_PATH/raw/napp/napp_00009.dta", clear

keep parishgb distgb subdisgb countygb
keep if countygb <= 100
duplicates drop 

decode parishgb, gen(parish)
decode distgb, gen(district)
decode subdisgb, gen(subdist)
decode countygb, gen(county)

drop parishgb distgb subdisgb countygb

replace parish = upper(parish)
replace district = upper(district)
replace subdist = upper(subdist)
replace county = upper(county)

* Clean parish names
split parish, parse(" AKA ") gen(par)
drop parish
gen tempid = _n
reshape long par, i(tempid) j(parid)
drop tempid parid
drop if par == ""
rename par parish

replace county = "YORKSHIRE" if regexm(county,"YORKSHIRE")==1
drop if subdist == "DALSTON"

sort county district subdist parish
save "$PROJ_PATH/processed/temp/1881_uk_crosswalk.dta", replace

* Parish-district-county crosswalk
use "$PROJ_PATH/processed/temp/1881_uk_crosswalk.dta", clear
drop subdist
duplicates drop
bysort parish: gen temp = _N
drop if temp >1
drop temp
sort county district parish
save "$PROJ_PATH/processed/intermediate/geography/1881_pardistcty_crosswalk.dta", replace

* District-county crosswalk
use "$PROJ_PATH/processed/temp/1881_uk_crosswalk.dta", clear
keep district county
duplicates drop
bysort district: keep if _N==1
sort county district
save "$PROJ_PATH/processed/intermediate/geography/1881_distcty_crosswalk.dta", replace

* Subdistrict-district-county crosswalk
use "$PROJ_PATH/processed/temp/1881_uk_crosswalk.dta", clear
keep district subdist county
duplicates drop
bysort subdist: keep if _N==1
sort county district subdist
save "$PROJ_PATH/processed/intermediate/geography/1881_subdistcty_crosswalk.dta", replace

* County list
use "$PROJ_PATH/processed/temp/1881_uk_crosswalk.dta", clear
keep county
duplicates drop
sort county
save "$PROJ_PATH/processed/intermediate/geography/1881_county_list.dta", replace

* Parish county crosswalk
use "$PROJ_PATH/processed/temp/1881_uk_crosswalk.dta", clear
keep parish county
duplicates drop
bysort parish: keep if _N==1
sort county parish
save "$PROJ_PATH/processed/intermediate/geography/1881_parcty_crosswalk.dta", replace

* Parish county crosswalk London only
use "$PROJ_PATH/processed/temp/1881_uk_crosswalk.dta", clear
keep parish county
keep if county == "MIDDLESEX" | county == "ESSEX" | county == "SURREY" | county == "KENT"
duplicates drop
bysort parish: keep if _N==1
sort county parish
save "$PROJ_PATH/processed/intermediate/geography/1881_parcty_london.dta", replace

* Subdistrict-district-county crosswalk London only
use "$PROJ_PATH/processed/temp/1881_uk_crosswalk.dta", clear
keep district subdist county
keep if county == "MIDDLESEX" | county == "ESSEX" | county == "SURREY" | county == "KENT"
duplicates drop
bysort subdist: keep if _N == 1
sort county district subdist
save "$PROJ_PATH/processed/intermediate/geography/1881_subdistcty_london.dta", replace

* Parish-district-county crosswalk London only
use "$PROJ_PATH/processed/temp/1881_uk_crosswalk.dta", clear
drop subdist
keep if county == "MIDDLESEX" | county == "ESSEX" | county == "SURREY" | county == "KENT"
duplicates drop
bysort parish: gen temp = _N
drop if temp >1
drop temp
sort county district parish
save "$PROJ_PATH/processed/intermediate/geography/1881_pardistcty_london.dta", replace

rm "$PROJ_PATH/processed/temp/1881_uk_crosswalk.dta"


// Create street-district crosswalks for 1881
use "$PROJ_PATH/raw/napp/napp_00003.dta", clear
decode GB81A_PARIDGB, gen(parish)
decode GB81A_RGDISTGB, gen(district)
decode GB81A_SUBDIDGB, gen(subdist)
decode GB81A_RGCNTYGB, gen(county)

sort GB81A_PARIDGB GB81A_RGDISTGB GB81A_SUBDIDGB GB81A_RGCNTYGB
drop GB81A_PARIDGB GB81A_RGDISTGB GB81A_SUBDIDGB GB81A_RGCNTYGB
rename GB81A_ADDRESS address

replace parish = upper(parish)
replace district = upper(district)
replace subdist = upper(subdist)
replace county = upper(county)
replace address = upper(address)

drop if regexm(address,"[0-9]")==0
count 

qui replace address = subinstr(address,","," ",.)
qui replace address = subinstr(address,"  "," ",.)

qui replace address = regexr(address,"^NO[ ]*","") if regexm(address,"^NO[0-9| ]")==1
qui replace address = regexr(address,"[0-9]+\/[0-9]+","")
qui replace address = regexr(address,"[0-9]ST ","")
qui replace address = regexr(address,"[0-9]ND ","")
qui replace address = regexr(address,"[0-9]RD ","")
qui replace address = regexr(address,"[0-9]TH ","")

qui replace address = regexr(address,"[0-9]TH ","")
qui replace address = subinstr(address,"  "," ",.)

gen min_number = regexs(1) if regexm(address,"^([0-9]+)[A-Z| ]")
gen temp = regexs(1) if regexm(address,"([0-9]+)$")
gen temp2 = regexs(1) if regexm(address,"([0-9]+)")
replace min_number = temp if min_number == "" & temp !=""
replace min_number = temp2 if min_number == "" & temp2 != ""
drop temp* 

gen temp = reverse(address)
gen temp2 = regexs(1) if regexm(temp,"([0-9]+)")
gen max_number = reverse(temp2)
drop temp*

forvalues n = 0(1)9 {
	qui replace address = subinstr(address,"`n'","",.)
}
replace address = trim(address)
qui replace address = subinstr(address,"    "," ",.)
qui replace address = subinstr(address,"   "," ",.)
qui replace address = subinstr(address,"  "," ",.)

qui replace address = subinstr(address,"&","",.)
qui replace address = subinstr(address,"  "," ",.)
replace address = trim(address)

qui replace address = regexr(address,"^NO ","")
qui replace address = regexr(address," NO "," ")
qui replace address = regexr(address,"^[A-Z] ","")
qui replace address = regexr(address,"[\(|\)]","")


qui replace address = subinstr(address,"-","",.)
qui replace address = subinstr(address,".","",.)
qui replace address = subinstr(address,"?","",.)
qui replace address = subinstr(address,")","",.)
qui replace address = subinstr(address,"(","",.)
qui replace address = subinstr(address,"+","",.)
qui replace address = subinstr(address,"/","",.)

replace address = trim(address)
qui replace address = regexr(address,"^U ","UPPER")
qui replace address = regexr(address,"^[A-Z] ","")
qui replace address = regexr(address," [A-Z]$","")
qui replace address = regexr(address," [A-Z]$","")
qui replace address = regexr(address," NO$","")
qui replace address = regexr(address," CP$","")
qui replace address = regexr(address," ST(R)*(T)*$"," STREET")
qui replace address = regexr(address," RD$"," ROAD")
qui replace address = regexr(address," T(E)*R(R)*$"," TERRACE")
qui replace address = regexr(address," PL(A)*(C)*(E)*$"," PLACE")
qui replace address = regexr(address," SQ(U)*(R)*(E)*$"," SQUARE")
qui replace address = regexr(address," COT(T)*(G)*(S)*$"," COTTAGES")
qui replace address = regexr(address," B(L)*D(N)*(G)*S$"," BUILDINGS")
qui replace address = regexr(address," C(R)*T$"," COURT") 
qui replace address = regexr(address," GD(N)*(S)*$"," GARDENS")
qui replace address = regexr(address," CR(E)*(S)*(C)*(T)*$"," CRESCENT")
qui replace address = regexr(address," YD$"," YARD")
qui replace address = regexr(address," PK$"," PARK")
qui replace address = regexr(address," TCE$"," TERRACE")
qui replace address = regexr(address," GAR$"," GARDENS")
qui replace address = regexr(address," BUILD(I)*(N)*(G)*(S)*$"," BUILDINGS")
qui replace address = regexr(address," TER(R)*CE$"," TERRACE")
qui replace address = regexr(address," AV(E)*$"," AVENUE")
qui replace address = regexr(address," WK$"," WALK")
qui replace address = regexr(address," B(L)*GS$"," BUILDINGS")
qui replace address = regexr(address," CRESENT$"," CRESCENT")
qui replace address = regexr(address," VIL(L)*(S)*$"," VILLA")
qui replace address = regexr(address," PCE$"," PLACE")
qui replace address = regexr(address," GRO$"," GROVE")  
qui replace address = regexr(address," G(R)*V(E)*$"," GROVE") 
qui replace address = regexr(address," CL$"," CLOSE")
qui replace address = regexr(address," PAS$"," PASSAGE")
qui replace address = regexr(address," LN(E)*$"," LANE")
qui replace address = regexr(address," CTGES$"," COTTAGES")
qui replace address = regexr(address," GARDNS$"," GARDENS")
qui replace address = regexr(address," GRN$"," GARDENS")
qui replace address = regexr(address," CTGS$"," COTTAGES")
qui replace address = regexr(address," BLS$"," BUILDINGS")
qui replace address = regexr(address," TER(R)*(C)*(E)*$"," TERRACE")
qui replace address = regexr(address," GNS$"," GARDENS")
qui replace address = regexr(address," BLDG$"," BUILDINGS")
qui replace address = regexr(address," GR$"," GARDENS") 
qui replace address = regexr(address," STT$"," STREET")
qui replace address = regexr(address," GARD$"," GARDENS")
qui replace address = regexr(address," COTT(G)*E$"," COTTAGES")
qui replace address = regexr(address," PL(A)*(C)*(E)*$"," PLACE")

qui replace address = regexr(address,"^GT ","GREAT ")
qui replace address = regexr(address,"^UP ","UPPER ")
qui replace address = regexr(address,"^UPP ","UPPER ")
qui replace address = regexr(address," RD "," ROAD ")

qui replace address = regexr(address,"'","")
drop if address == ""

sort address district county
egen stid = group(address district county)

destring max_number min_number, replace
replace max_number = min_number if min_number>max_number

rename min_number temp1
rename max_number temp2

egen min_number = min(temp1), by(stid)
egen max_number = max(temp2), by(stid)

drop temp* stid
duplicates drop

rename address street
rename district index81_dist
rename subdist index81_subdist
rename county index81_cty
rename parish index81_parish

sort street index81* 
save "$PROJ_PATH/processed/intermediate/geography/1881_street_district_crosswalk.dta", replace



// Create input file for scraping streets 
// Current archived url: https://webarchive.nationalarchives.gov.uk/ukgwa/+/http://yourarchives.nationalarchives.gov.uk/index.php?title=Category:1891_census_registration_districts
use district using "$PROJ_PATH/processed/intermediate/geography/hharp_london_district_subdist_crosswalk.dta", clear
duplicates drop 

gen district_original = district
replace district = "St George in the East" if district == "St George In The East"
replace district = subinstr(district," ","_",.)

gen url1 = "http://yourarchives.nationalarchives.gov.uk/index.php?title=Place:"
gen url2 = district
gen url3 = "_Registration_District,_1891_Census_Street_Index"

egen url = concat(url1 url2 url3)

gen letter1 = "_A-B"
gen letter2 = "_C-F"
gen letter3 = "_G-I"
gen letter4 = "_J-L"
gen letter5 = "_M-O"
gen letter6 = "_P-R"
gen letter7 = "_S-T"
gen letter8 = "_U-Z"

gen district_id = _n
drop district url1 url2 url3
reshape long letter, i(url) j(letter_group)
replace url = url+letter
keep url district_original district_id letter_group

/*
* Create extract for scraping streets 
version 12
outsheet using "$PROJ_PATH/processed/intermediate/geography/London_streets_1891.csv", comma replace non
version 14
*/

keep district_id district_original
rename district_original district 
duplicates drop
tempfile districts
save `districts', replace

version 12
insheet using "$PROJ_PATH/raw/streets/Streets-1-2.csv", clear
forvalues district = 1/29 {
	forvalues group = 1/8 {
		insheet using "$PROJ_PATH/raw/streets/Streets-`district'-`group'.csv", non clear
		qui tostring v5, replace
		qui tostring v6, replace
		tempfile dist`district'grp`group'
		save `dist`district'grp`group'', replace
	}
}

use `dist1grp1', clear
forvalues group = 2/8 {
	qui append using `dist1grp`group''
}
forvalues district = 2/29 {
	forvalues group = 1/8 {
		qui append using `dist`district'grp`group''
	}
}

rename v1 district_id
rename v2 group_id
rename v3 obs_id
rename v4 street
rename v5 intersect
rename v6 remarks
rename v7 dwellings
rename v8 reference
rename v9 folio

merge m:1 district_id using `districts', assert(3) nogen
unique district_id group_id obs_id
sort district_id group_id obs_id
save "$PROJ_PATH/processed/temp/1891_streets_raw.dta", replace

version 14


// Create street-district crosswalks for 1891
use "$PROJ_PATH/processed/temp/1891_streets_raw.dta", clear

* Generate correspondence between street name, registration district, and address numbers 
replace street = upper(street)
replace street = regexr(street,">","")
replace street = regexr(street,"\,$","")
replace street = regexr(street,"\, THE","")
replace street = regexr(street," & (.)+$","")
replace street = regexr(street," OR (.)+$","")
replace street = regexr(street," AND (.)+$","")
replace street = regexr(street,", (.)+$","")
replace street = subinstr(street,"'","",.)
replace street = regexr(street,"^GT ","GREAT ")
replace street = regexr(street,"^UPP ","UPPER ")
replace street = regexr(street,"^UP ","UPPER ")
replace street = regexr(street,"^U ","UPPER ")
replace street = regexr(street,"^STH ","SOUTH ")

drop obs_id intersect remarks reference folio

replace dwellings = upper(dwellings)
gen add1 = regexs(1) if regexm(dwellings,"([0-9]+[-][0-9]+)")
gen add2 = regexs(1) if regexm(dwellings,"[0-9]+[-][0-9]+[A-Z| |&|,]+([0-9]+[-][0-9]+)")
gen add3 = regexs(1) if regexm(dwellings,"[0-9]+[-][0-9]+[A-Z| |&|,]+[0-9]+[-][0-9]+[A-Z| |&|,]+([0-9]+[-][0-9]+)")

drop dwellings

gen id = _n
reshape long add, i(id) j(addid)

replace add = "177-220" if add == "177-120"
replace add = "52-56" if add == "52-6"
replace add = "610-663" if add == "610-63"
replace add = "23-25" if add == "23-5"
replace add = "169-228" if add == "169-28"
replace add = "30-34" if add == "30-4"
replace add = "5262-5288" if add == "5262-88"
replace add = "20-23" if add == "20-3"
replace add = "112-118" if add == "112-18"
replace add = "201-202" if add == "201-2"
replace add = "658-675" if add == "658-75"

gen min_number = regexs(1) if regexm(add,"^([0-9]+)[-]")
gen max_number = regexs(1) if regexm(add,"[-]([0-9]+)$")
destring min_number max_number, replace
drop add id addid

gen temp1 = mod(min_number,2)
gen temp2 = mod(max_number,2)
gen odd = (temp1==1 | temp2==1)
gen even = (temp1==0 | temp2==0)
drop temp*
duplicates drop
drop district_id group_id

sort street district min_number max_number
replace district = upper(district)
rename district index_dist
save "$PROJ_PATH/processed/intermediate/geography/1891_street_district_crosswalk.dta", replace



// Create intersect-district crosswalks for 1891
use "$PROJ_PATH/processed/temp/1891_streets_raw.dta", clear

* Generate correspondence between street name, registration district, and address numbers 
replace street = upper(street)
replace street = regexr(street,">","")
replace street = regexr(street,"\,$","")
replace street = regexr(street,"\, THE","")
replace street = regexr(street," & (.)+$","")
replace street = regexr(street," OR (.)+$","")
replace street = regexr(street," AND (.)+$","")
replace street = regexr(street,", (.)+$","")
replace street = subinstr(street,"'","",.)
replace street = regexr(street,"^GT ","GREAT ")
replace street = regexr(street,"^UPP ","UPPER ")
replace street = regexr(street,"^UP ","UPPER ")
replace street = regexr(street,"^U ","UPPER ")
replace street = regexr(street,"^STH ","SOUTH ")
replace street = regexr(street," GROVE$"," GR")

drop obs_id remarks reference folio

replace dwellings = upper(dwellings)
replace intersect = upper(intersect)
drop if intersect == ""

replace intersect = regexr(intersect,"^CONTINUATION OF ","")
replace intersect = regexr(intersect," AND (.)+$","")
replace intersect = regexr(intersect,"^PT OF ","")
replace intersect = regexr(intersect," OR (.)+$","")
replace intersect = regexr(intersect," TO (.)+$","")
replace intersect = regexr(intersect," IN (.)+$","")
replace intersect = regexr(intersect," & (.)+$","")
replace intersect = regexr(intersect,"^PART ","")
replace intersect = regexr(intersect,"^FROM ","")
replace intersect = regexr(intersect,"^(.)+[ ]PART OF ","")
replace intersect = regexr(intersect,", (.)+$","")
replace intersect = regexr(intersect," NOW (.)+$","")
replace intersect = regexr(intersect,"^(.)+[ ]WAS ","")
replace intersect = regexr(intersect," - (.)+$","")
replace intersect = regexr(intersect,"^NOW CONTAINS ","")
replace intersect = regexr(intersect,"^NOW PT ","")
replace intersect = regexr(intersect,"^(.)+[ ]FORMERLY ","")
replace intersect = regexr(intersect," LATER (.)+$","")
replace intersect = regexr(intersect," CONTINUATION OF (.)+$","")
replace intersect = regexr(intersect," RENAMED (.)+$","")
replace intersect = regexr(intersect,"^WAS ","")
replace intersect = regexr(intersect,"^(.)+[ ]FROM ","")
replace intersect = regexr(intersect,"\/(.)+$","")
replace intersect = regexr(intersect,"^(.)+: ","")
replace intersect = regexr(intersect,"^OF ","")
replace intersect = regexr(intersect,"\((.)+\)","")
replace intersect = regexr(intersect,"^ AND ","")
replace intersect = regexr(intersect," INCLUDING (.)+$","")
replace intersect = regexr(intersect,"[,|\.]$","")
replace intersect = "LADBROKE GROVE ROAD" if intersect == "LADBROKE GROVEROADPT OF VICTORIA ROAD"
replace intersect = regexr(intersect,"^(.)+[ ]MAINLY ","")
replace intersect = regexr(intersect," INCLUDES (.)+$","")
replace intersect = regexr(intersect," INC (.)+$","")
replace intersect = regexr(intersect,"^CONTINUED AS (.)+$","")
replace intersect = regexr(intersect,"^(.)+[ ]PT OF ","")
replace intersect = regexr(intersect,"^CONTINUTATION OF ","")
replace intersect = regexr(intersect,"^CONT OF ","")
replace intersect = regexr(intersect,"^EAST OF ","")
replace intersect = regexr(intersect,"^EAST SIDE OF ","")
replace intersect = regexr(intersect,"^WEST OF ","")
replace intersect = regexr(intersect,"^WEST SIDE OF ","")
replace intersect = regexr(intersect,"^PF OF ","")
replace intersect = regexr(intersect,"^LATER PT\. OF ","")
replace intersect = regexr(intersect,"^PT ","")
replace intersect = trim(intersect)
drop if regexm(intersect,"THAMES")
drop if regexm(intersect,"[0-9]")
drop if intersect == "STREET" | intersect == "INN" | intersect == "ROAD" | intersect == "VILLAS"

gen temp = length(intersect)
sum temp, detail
compress intersect

gen add1 = regexs(1) if regexm(dwellings,"([0-9]+[-][0-9]+)")
gen add2 = regexs(1) if regexm(dwellings,"[0-9]+[-][0-9]+[A-Z| |&|,]+([0-9]+[-][0-9]+)")
gen add3 = regexs(1) if regexm(dwellings,"[0-9]+[-][0-9]+[A-Z| |&|,]+[0-9]+[-][0-9]+[A-Z| |&|,]+([0-9]+[-][0-9]+)")

drop dwellings

gen id = _n
reshape long add, i(id) j(addid)

replace add = "177-220" if add == "177-120"
replace add = "52-56" if add == "52-6"
replace add = "610-663" if add == "610-63"
replace add = "23-25" if add == "23-5"
replace add = "169-228" if add == "169-28"
replace add = "30-34" if add == "30-4"
replace add = "5262-5288" if add == "5262-88"
replace add = "20-23" if add == "20-3"
replace add = "112-118" if add == "112-18"
replace add = "201-202" if add == "201-2"
replace add = "658-675" if add == "658-75"

gen min_number = regexs(1) if regexm(add,"^([0-9]+)[-]")
gen max_number = regexs(1) if regexm(add,"[-]([0-9]+)$")
destring min_number max_number, replace
drop add id addid

gen temp1 = mod(min_number,2)
gen temp2 = mod(max_number,2)
gen odd = (temp1==1 | temp2==1)
gen even = (temp1==0 | temp2==0)
drop temp*
duplicates drop
drop district_id group_id

sort street intersect district min_number max_number
replace district = upper(district)
rename district intersect_dist

save "$PROJ_PATH/processed/intermediate/geography/1891_intersect_district.dta", replace
rm "$PROJ_PATH/processed/temp/1891_streets_raw.dta"



// Clean residential address in hospital records
use address_orig using "$PROJ_PATH/processed/intermediate/hospitals/hospital_admissions_combined.dta" if address_orig != "", clear
bysort address_orig: keep if _n == 1

* Extract original address information from transcription file 
gen address = address_orig

replace address = upper(address)
replace address = trim(address)

* Remove text if no address
replace address = "NO ADDRESS" if regexm(address,"NO HOME")==1 | regexm(address,"NO FIXED")==1 | regexm(address,"BORN IN ")

* Fix missing space in street addresses
replace address = "6 1/2 HALLETT PL., WILMINGTON SQ., ROSEBERY AVE." if address == "61/2 HALLETT PL., WILMINGTON SQ., ROSEBERY AVE."
replace address = "21 COLLARD RD., WOOD ST., WALTHAMSTOW" if address == "2/2 COLLARD RD., WOOD ST., WALTHAMSTOW"
replace address = "24 1/2 GT. PEARL ST., SPITALFIELDS" if address == "241/2 GT. PEARL ST., SPITALFIELDS"
replace address = "57 WILMER GDNS., KINGSLAND RD." if address == "FLAT 6 NO. 57, WILMER GDNS., KINGSLAND RD."
replace address = regexr(address,"31CLERKENWELL", "31 CLERKENWELL")
replace address = regexr(address,"\.",". ") if regexm(address,"\.[A-Z]")
replace address = regexr(address,"  "," ")

replace address = "2 ALNWICK STREET, PRINCE OF WALES ROAD, VICTORIA DOCKS" if address == "2??"

* Remove question marks
replace address = subinstr(address,"?","",.)
replace address = trim(address)

* Remove "C/O from beginning of string
replace address = regexr(address,"^C/O[A-Z| ]+, ","")

* Separate street number
gen stnum = regexs(1) if regexm(address,"([0-9]+)")
destring stnum, replace
replace address = regexr(address,"^[0-9]+[ ]","")
replace address = regexr(address,"^&[ ]","")
replace address = regexr(address,"^[0-9]+[\.]*[ ]","") /* Cases with number space number */
replace address = regexr(address,"^[0-9]+[A-Z][\.]*[ ]","")
replace address = regexr(address,"^[A-Z][ ]","")
replace address = regexr(address,"^[A-Z]\.[ ]","")
replace address = trim(address)
replace address = regexr(address,"^[0-9]+,[ ]","") /* Some addresses have comma following number */
replace address = trim(address)
replace address = regexr(address,"^[0-9]+/[0-9]+[ ]","") /* Clear fractions */
replace address = regexr(address,"^[0-9]+,[0-9]+/[0-9]+[ ]","")  /* Clear fractions with commas*/
replace address = regexr(address,"^[0-9]+-[0-9]+[ ]","") /* Clear address dash apt no */

* Blocks 
replace address = regexr(address,"[ ]*NO\.(.)+BLOCK[S]*[\.]*[ ]*","")
replace address = regexr(address,"^,[ ]","")
replace address = regexr(address,"^BLOCK[S]*[,|\.]*[ ]","")	
replace address = regexr(address,"^[A-Z][\.]*,[ ]","")
replace address = regexr(address,"^NORTH BLOCK[S]*[,]*[ ]","")	
replace address = regexr(address,"^EAST BLOCK[S]*[,]*[ ]","")	
replace address = regexr(address,"^WEST BLOCK[S]*[,]*[ ]","")	
replace address = regexr(address,"^O'CLOCK[ ]","")	

* Remove extra spaces
replace address = subinstr(address, "  "," ",.)
replace address = regexr(address, "STREET ,", "STREET,")
replace address = regexr(address, "ROAD ,", "ROAD,")
replace address = regexr(address, "STREET CITY$", "STREET, LONDON CITY")

* Peabody Buildings
replace address = regexr(address,"PEABODY'S","PEABODY")
replace address = regexr(address,"PEABODYS","PEABODY")
replace address = regexr(address,"PEABOOLY","PEABODY")
replace address = regexr(address,"PEABODY BADGE","PEABODY BUILDINGS")

replace address = "PEABODY SQ., BLACKFRIARS" if address == "PEABODY SQ. BLACKFRIARS"
replace address = "EAST PEABODY SQ., ISLINGTON" if address == "EAST PEABODY SQ. ISLINGTON"
replace address = "PEABODY BDG., DUKE ST., SE" if address == "PEABODY BDG. DUKE ST., SE"
replace address = "PEABODY BDGS., SOUTHWARK ST., SE" if address == "PEABODY BDGS. SOUTHWARK ST., SE"
replace address = "PEABODY BLDGS., DUFFERIN ST., ST. LUKES" if address == "PEABODY, BLDGS., DUFFERIN ST., ST. LUKES"
replace address = "PEABODY BLDGS., ROSCOE ST., EC" if address == "PEABODY BLDGS. ROSCOE ST., EC"
replace address = "PEABODY BDS., GUEST STREET, ST.LUKES" if address == "PEABODY BDS. GUEST STREET, ST.LUKES"
replace address = "PEABODY BLDGS., PEAR TREE WALK, CLERKENWELL" if address  == "PEABODY BLDGS. PEAR TREE WALK, CLERKENWELL"
replace address = "PEABODY BLDGS., ROSCOE ST., ST. LUKES" if address == "PEABODY BLDGS. ROSCOE ST., ST. LUKES"
replace address = "PEABODY BDGS., FARRINGDON RD." if address == "PEABODY BDGS. FARRINGDON RD."
replace address = "PEABODY BLDGS., ROSCOE ST., ST. LUKES" if address == "PEABODY BLDGS. ROSCOE ST., ST. LUKES"
replace address = "PEABODY BDGS., ROSCOE ST., ST. L." if address == "PEABODY BDGS. ROSCOE ST., ST. L."
replace address = "PEABODY BLGS., ROSCOE STREET, E C" if address == "PEABODY BLGS. ROSCOE STREET, E C"
replace address = "PEABODY BDGS., DUFFERN ST., ST. LUKES" if address == "PEABODY BDGS. DUFFERN ST., ST. LUKES"
replace address = "PEABODY BDGS, FARRINGDON RD." if address == "PEABODY BDGS FARRINGDON RD."
replace address = "PEABODY BUILDINGS., CLERKENWELL CLOSE" if address == "PEABODY BUILDINGS. CLERKENWELL CLOSE"
replace address = "PEABODY BDGS., ESSEX RD., ISLINGTON" if address == "PEABODY BDGS. ESSEX RD., ISLINGTON"

* Typos 

* Get rid of colons
replace address = regexr(address,"ST: LUKES","ST LUKE")
replace address = regexr(address,"BETH: GREEN","BETHNAL GREEN")
replace address = regexr(address,"BARTHOL:","BARTHOLOMEWS")
replace address = subinstr(address,":,",",",.)
replace address = subinstr(address,": "," ",.)
replace address = subinstr(address,":"," ",.)

* Deal with improperly placed commas
replace address = regexr(address,"ST., ANDREW"," ST. ANDREW")
replace address = regexr(address,"ST., ANN[A-Z|']", "ST. ANN")
replace address = regexr(address,"MILE END, NEW TOWN","MILE END NEW TOWN")
replace address = regexr(address,"MILE END, NEW YN\.","MILE END NEW TOWN")
replace address = regexr(address,"MILE END, NY","MILE END NEW TOWN")
replace address = regexr(address,"MILE END, N\. Y\.","MILE END NEW TOWN")
replace address = regexr(address,"MILE END, NEW YK\.","MILE END NEW TOWN")
replace address = regexr(address,"ESSEX, ROAD","ESSEX ROAD")

* Missing commas
replace address = "CURRIERS ROW, GREEN DRAGON COURT, ST. ANDREW HILL, EC" if address == "CURRIERS ROW GREEN DRAGON COURT ST., ANDREW HILL, EC"
replace address = "IRELAND YARDS, ST. ANDREW HILL" if address == "IRELAND YARDS ST., ANDREW HILL"
replace address = "OLD MONTAGUE STREET, WHITECHAPEL" if address == "OLD MONTAGUE STREET WHITECHAPEL"
replace address = "EMMINGS BDGS., CHAPEL STREET, CLERKENWELL" if address == "EMMINGS BDGS., CHAPEL STREET CLERKENWELL"
replace address = "DANEMERE STREET, PUTNEY" if address == "DANEMERE STREET PUTNEY"
replace address = "OAK STREET, EALING" if address == "OAK STREET EALING"
replace address = "BERKELEY COURT, RED LION STREET, CLERKENWELL" if address == "BERKELEY COURT, RED LION STREET CLERKENWELL"
replace address = "HULL STREET, LEVER STREET, ST. LUKES" if address == "HULL STREET, LEVER STREET ST., LUKES"
replace address = "HOBURY STREET, CHELSEA" if address == "HOBURY STREET CHELSEA"
replace address = "COLLINS STREET, BROMLEY LE BOW" if address == "COLLINS STREET BROMLEY LE BOW"
replace address = "CHATHAM AVENUE, NILE STREET, HOXTON" if address == "CHATHAM AVENUE, NILE STREET HOXTON"
replace address = "EYRE STREET HILL, HOLBORN" if address == "EYRE STREET HILL. HOLBORN"
replace address = "WATERLOO STREET, CAMDEN TOWN" if address == "WATERLOO STREET CAMDEN IRON"
replace address = "CROSS STREET, ISLINGTON" if address == "CROSS STREET ISLINGTON"
replace address = "FOUNDRY PL., PITFIELD STREET, HOXTON" if address == "FOUNDRY PL., PITFIELD STREET HOXTON"
replace address = "DEAN STREET, HIGH HOLBORN" if address == "DEAN STREET HIGH HOLBORN"
replace address = "SEDGWICK STREET, HIGH ST., HOMERTON" if address == "SEDGWICK STREET HIGH ST., HOMERTON"
replace address = "POLE STREET, STEPNEY GREEN" if address == "POLE STREET STEPNEY GREEN"
replace address = "DRY STREET, LANGDON HILLS, NR. ROMFORD" if address == "DRY STREET LANGDON HILLS, NR. ROMFORD"
replace address = "HERBERT STREET, NEW NORTH ROAD" if address == "HERBERT STREET NEW NORTH ROAD"
replace address = "YORK STREET, YORK ROAD, WESTMISTER" if address == "YORK STREET YORK ROAD WESTMISTER"
replace address = "MONEYER STREET, NILE STREET, HOXTON" if address == "MONEYER STREET, NILE STREET HOXTON"
replace address = "HIGH STREET, EDGWARE" if address == "HIGH STREET EDGWARE"
replace address = "NELSON PLACE, REMINGTON STREET, CITY RD." if address == "NELSON PLACE, REMINGTON STREET CITY RD."
replace address = "NEW ST., BATH STREET, CITY RD." if address == "NEW ST., BATH STREET CITY RD."
replace address = "GEE STREET, GOSWELL RD" if address == "GEE STREET GOSWELL RD"
replace address = "WARE STREET, KINGSLAND" if address == "WARE STREET KINGSLAND"
replace address = "GEE STREET, GOSWELL ROAD" if address == "GEE STREET GOSWELL ROAD"
replace address = "GRIGBY PLACE, HOLLAND STREET, KENSINGTON" if address == "GRIGBY PLACE, HOLLAND STREET KENSINGTON"
replace address = "HIGH STREET, WHETSTONE" if address == "HIGH STREET WHETSTONE"
replace address = "EAGLE STREET, CITY ROAD" if address == "EAGLE STREET CITY ROAD"
replace address = "RENDALLS ROAD, YORK ROAD, KINGS CROSS" if address == "RENDALLS ROAD, YORK ROAD KINGS CROSS"
replace address = "HUTLEY PLACE, HYDE ROAD, HOXTON" if address == "HUTLEY PLACE, HYDE ROAD HOXTON"
replace address = "BARONESS ROAD, HACKNEY ROAD" if address == "BARONESS ROAD HACKNEY ROAD"
replace address = "CANNON ST., ROAD, MILE END" if address == "CANNON ST., ROAD MILE END"
replace address = "PICKERING ST. BDGS., ESSEX ROAD N" if address == "PICKERING ST., BDGS., ESSEX ROAD N"
replace address = "STANLEY ROAD, STRATFORD" if address == "STANLEY ROAD STRATFORD"
replace address = "FORD ROAD, OLD FORD" if address == "FORD ROAD OLD FORD"
replace address = "DURHAM ROAD, CANNING TOWN" if address == "DURHAM ROAD CANNING TOWN"
replace address = "TOWER ROAD, DARTFORD" if address == "TOWER ROAD DARTFORD"
replace address = "ADAIR ROAD, WESTBOURNE PARK" if address == "ADAIR ROAD WESTBOURNE PARK"
replace address = "SPRINGFIELD ROAD, HARROW" if address == "SPRINGFIELD ROAD HARROW"
replace address = "ALMACK ROAD, CLAPTON PARK" if address == "ALMACK ROAD CLAPTON PARK"
replace address = "FAIRFIELD ROAD, BOW" if address == "FAIRFIELD ROAD BOW"
replace address = "EAST ROAD, CITY ROAD" if address == "EAST ROAD CITY ROAD"
replace address = "CHICHESTER ROAD, KILBURN" if address == "CHICHESTER ROAD KILBURN"
replace address = "YORK STREET, YORK ROAD, WESTMISTER" if address == "YORK STREET YORK ROAD WESTMISTER"
replace address = "NORWOOD HOUSE INFM., ELDER ROAD, LOWER NORWOOD" if address == "NORWOOD HOUSE INFM., ELDER ROAD LOWER NORWOOD"
replace address = "COMMERCIAL ROAD, PECKHAM" if address == "COMMERCIAL ROAD PECKHAM"
replace address = "ANGEW ROAD, CHALK FARM" if address == "ANGEW ROAD CHALK FARM"
replace address = "CROSS ST., BRAMPTON PARK ROAD, HACKNEY" if address == "CROSS ST., BRAMPTON PARK ROAD HACKNEY"
replace address = "SCOVELL ROAD, BORO. SE" if address == "SCOVELL ROAD BORO. SE"
replace address = "WADESON ST., CAMBRIDGE ROAD, HACKNEY" if address == "WADESON ST., CAMBRIDGE, ROAD HACKNEY"
replace address = "STEWART ROAD, BOURNEMOUTH" if address == "STEWART ROAD BOURNEMOUTH"
replace address = "BEDFORD ROAD, HORSHAM" if address == "BEDFORD ROAD HORSHAM"
replace address = "NORFOLK BDGS., NORFOLK GDNS., CURTAIN ROAD, SHOREDITCH" if address == "NORFOLK BDGS., NORFOLK GDNS., CURTAIN ROAD SHOREDITCH"
replace address = "THOMAS ST., BURDETT ROAD, LIMEHOUSE" if address == "THOMAS ST., BURDETT ROAD LIMEHOUSE"
replace address = "STATION ROAD, PENSHURST" if address == "STATION ROAD PENSHURST"
replace address = "EAST ROAD, CITY RD." if address =="EAST ROAD CITY RD."
replace address = "YALDING ROAD, BERMONDSEY" if address == "YALDING ROAD BERMONDSEY"
replace address = "GONSALVA ROAD, WANDSWORTH RD." if address == "GONSALVA ROAD WANDSWORTH RD."
replace address = "PLEASANT PL., ESSEX ROAD N." if address == "PLEASANT PL. ESSEX ROAD N."
replace address = "SHRUBBERY ROAD, STREATHAM ST., C" if address == "SHRUBBERY ROAD STREATHAM ST., C"
replace address = "CROYLAND ROAD, LOWER EDMONTON" if address == "CROYLAND ROAD LOWER EDMONTON"
replace address = "YORK ROAD, CITY ROAD, EC" if address == "YORK ROAD CITY ROAD, EC"
replace address = "LEFEVRE ROAD, BOW" if address == "LEFEVRE ROAD BOW"
replace address = "YORK ROAD, CITY RD., EC" if address == "YORK ROAD CITY RD., EC"
replace address = "NEW CHURCH STREET, JAMAICA ROAD, BERMONDSEY" if address == "NEW CHURCH STREET, JAMAICA ROAD BERMONDSEY"
replace address = "BEVENDEN STREET, EAST ROAD, HOXTON" if address == "BEVENDEN STREET, EAST ROAD HOXTON"
replace address = "WEMLOCK ST., NEW NORTH ROAD, HOXTON" if address == "WEMLOCK ST., NEW NORTH ROAD HOXTON"
replace address = "EDITH ROAD, PALACE RD., BOWES PARK" if address == "EDITH ROAD PALACE RD., BOWES PARK"
replace address = "MALDON ROAD, COLCHESTER" if address == "MALDON ROAD COLCHESTER"
replace address = "MELBOURNE COTTAGES, SOUTHGATE RD, POTTERS BAR" if address == "MELBOURNE COTTAGES, SOUTHGATE RD POTTERS BAR"
replace address = "ALPHA TER., CANTERBURY RD, KILBURN" if address == "ALPHA TER. CANTERBURY RD KILBURN"
replace address = "JAMES ROAD, OLD KENT RD., SE" if address == "JAMES ROAD, OLD KENT, RD. SE"
replace address = "IVY COTTAGES PARK ROAD, HORNSEY" if address == "IVY COTTAGES PARK, ROAD, HORNSEY"
replace address = "BRUMSEY CLOSE, ST JOHN ST ROAD, CLERKENWELL" if address == "BRUMSEY CLOSE JOHN ST, ROAD, CLERKENWELL"

* Standardize building suffix
replace address = regexr(address," BAGS\."," BUILDINGS")
replace address = regexr(address," BEGS\."," BUILDINGS")
replace address = regexr(address," BD\."," BUILDINGS")
replace address = regexr(address," BLG\."," BUILDINGS")
replace address = regexr(address," BDG[:]*\."," BUILDINGS")
replace address = regexr(address," BUILD\."," BUILDINGS")
replace address = regexr(address," BDGS\."," BUILDINGS")
replace address = regexr(address," BLDGS\."," BUILDINGS")
replace address = regexr(address," BLDG\."," BUILDINGS")
replace address = regexr(address," BGS\."," BUILDINGS")
replace address = regexr(address," BLGS\."," BUILDINGS")
replace address = regexr(address," BDGS,"," BUILDINGS,")
replace address = regexr(address," BLDGS,"," BUILDINGS,")
replace address = regexr(address," DWELLGS"," DWELLINGS")

replace address = subinstr(address," RD."," ROAD",.)
replace address = regexr(address," ROAD "," ROAD, ") if regexm(address,"ROAD BUILD")==0 & regexm(address,"ROAD EAST")==0 & regexm(address,"ROAD SQ")==0 & regexm(address,"ROAD SOUTH")==0 & regexm(address,"ROAD VILLAS")==0 & regexm(address,"ROAD SCHOOL")==0
replace address = regexr(address,",$","")

* Separate 'ST' abbreviation "Street" from "Saint"
replace address = regexr(address,"^ST\., ", "ST ")
replace address = regexr(address,"ST\., LUKE", "ST LUKE")
replace address = "INDUSTRIAL BUILDINGS, ST JOHNS LANE" if address == "INDUSTRIAL BUILDINGS, ST., JOHNS LAW"
replace address = "AMBERMILL ST., ST JOHNS LANE" if address == "AMBERMILL ST., ST., JOHNSLANE"
replace address = "CUSTANCE ST., HOXTON" if address == "CUSTANCE, ST., HOXTON"
replace address = "NORTHUMBERLAND ST., POPLAR" if address == "NORTHUMBERLAND, ST., POPLAR"
replace address = "EAGLE COURT, ST JOHNS LANE, CLERKENWELL" if address == "EAGLE COURT, ST., JOHN'S LANE, CLERKENWELL"
replace address = "IOY STREET, ST JOHNS ROAD, HOXTON" if address == "IOY STREET, ST., JOHNS ROAD, HOXTON"
replace address = "HAT & MITRE COURT, ST JOHN ST., EC" if address == "HAT & MITRE COURT, ST., JOHN ST., EC"
replace address = "RUMMINGTON ST., CITY ROAD" if address == "RUMMINGTON, ST., CITY ROAD"
replace address = "OLD GRAVEL LANE, ST GEORGE'S, E" if address == "OLD GRAVEL LANE, ST., GEORGE'S, E"
replace address = "ST MARY'S GDNS., ST MARY'S ROAD, LOWER EDMONTON" if address == "ST MARY'S GDNS., ST., MARY'S ROAD, DOWER EDMONSTON"
replace address = "GAINS FORD ST., ST JOHNS, SE" if address == "GAINS FORD ST., ST., JOHNS, SE"
replace address = "CARTER LANE, ST PAULS, EC" if address == "CARTER LANE, ST., PAULS, EC"
replace address = "FRIAR ST., BLACKFRIARS ROAD" if address == "FRIAR, ST., BLACKFRIARS ROAD"
replace address = "TILLMAN ST., ST GEORGE, E" if address == "TILLMAN ST., ST., GEORGE, E"
replace address = "BALDWIN TERRACE, ST PETERS, ST., W." if address == "BALDWIN TERRACE, ST., PETERS, ST., W."
replace address = "EAST SURREY GROVE, ST GEORGE ROAD, PECKHAM" if address == "EAST SURREY GROVE, ST., GEORGE ROAD, PECKHAM"
replace address = "CASSLAND ROAD, SOUTH HACKNEY" if address == "CASSLAND ROAD, ST., HACKNEY"
replace address = "ALBION PL., ST JOHNS LANE, CLERKENWELL" if address == "ALBION PL., ST., JOHNS LANE, CLERKENWELL"
replace address = "BERKLEY COURT, ST JOHNS LANE, EC" if address == "BERKLEY COURT, ST., JOHN'S LANE, EC"
replace address = "CAMDEN GROVE ROAD, ST GEORGES ROAD, SE" if address == "CAMDEN GROVE ROAD, ST., GEORGES ROAD, SE"
replace address = "PORTERS LODGE, ST BARTHOLOMEWS HOSPITAL" if address == "PORTERS LODGE, ST., B. H."
replace address = "JERUSALEM COURT, ST JOHNS SQ., EC" if address == "JERUSALEM COURT, ST., JOHN SQ., EC"
replace address = "JERUSALEM BUILDINGS, ST JOHNS SQ., EC" if address == "JERUSALEM BUILDINGS, ST., JOHNS SQ., EC"
replace address = "SALES COTTAGES, ST MARY CRAY, KENT" if address == "SALES COTTAGES, ST., MARY CRAY, KENT"
replace address = "SOUTH END, ST ALBANS ROAD, KENSINGTON" if address == "SOUTH END, ST., ALBANS ROAD, KENSINGTON"
replace address = "HOWARD ROAD, SOUTH HORNSEY" if address == "HOWARD ROAD, ST., HORNSEY"
replace address = "CITY CARLTON CLUB, ST SWITHIN'S LANE, EC" if address == "CITY CARLTON CLUB, ST., SWITHIN'S LANE, EC"
replace address = "SMYRKS ROAD, OLD KENT ROAD, SE" if address == "SMYRKS ROAD, OLD KENT ROAD, ST."
replace address = "HENRY ST., OLD ST., EC" if address == "HENRY ST., BLD., ST., EC"
replace address = "REIGATE STREET, PRUSIN STREET, ST GEORGE IN THE EAST" if address == "REIGATE STREET, PRUSIN STREET, ST., GEORGE E"
replace address = "CORBETT'S COURT, HANBURY ST., E" if address == "CORBETT'S COURT, HANBURY, ST., E"
replace address = "ST. ANNS ROAD, BURDETT ROAD, SE" if address == "ST. ANNS ROAD, BURDETT ROAD, ST."
replace address = "QUEENS ARM'S CT., UP GROUND ST" if address == "QUEENS ARM'S CT., UP. GROUND, ST"
replace address = "RICHMOND ST., BATH ST., ST. L" if address == "RICHMOND ST., BATH ST., ST., L"
replace address = "THOMAS PLACE, MIDDLE ROW, OLD ST., EC" if address == "THOMAS PLACE, MIDDLE ROW ROAD, ST., EC"
replace address = "NORMANS BUILDINGS, OLD ST., ST. LUKES" if address == "NORMANS BUILDINGS, OLD, ST., ST. LUKES"
replace address = "BALDWIN TERRACE, ST PETERS ST., W." if address == "BALDWIN TERRACE, ST PETERS, ST., W."
replace address = "PELL ST., CASTLE ST., ST GEORGE IN THE EAST" if address == "PELL ST., CASTLE ST., ST., GEORGE'S, E"
replace address = "HALE ST., HIGH ST., DEPTFORD" if address == "HALE ST., HIGH,ST., DEPTFORD"
replace address = "LITTLE SUTTON STREET BUILDINGS, SE" if address == "24 ROOM, LITTLE SUTTON, ST., BUILDINGS, SE"
replace address = "THE POLLARDS, GLOUCESTER ST., LAMBETH" if address == "THE POLLARDS, GLOUCESTER, ST., LAMBETH"
replace address = "HENRY'S PLACE, HOXTON ST., HOXTON" if address == "HENRY'S PLACE, HOXTON, ST., HOXTON"

* Eliminate apostrophes and periods
replace address = subinstr(address,"STREET. ", "STREET, ",.)
replace address = subinstr(address,"ROAD. ", "ROAD, ",.)
replace address = subinstr(address,"COTT. ", "COTT, ",.)
replace address = subinstr(address,"LANE. ", "LANE, ",.)
replace address = subinstr(address,"PLACE. ", "PLACE, ",.)
replace address = subinstr(address,"COURT. ", "COURT, ",.)
replace address = subinstr(address,"'","",.)
replace address = subinstr(address,".","",.)
replace address = subinstr(address," CT ROAD", " COURT ROAD",.)
replace address = subinstr(address," CT PASSAGE", " COURT PASSAGE",.)
replace address = subinstr(address," CT ", " COURT, ",.) if regexm(address," CT PASSAGE")==0
replace address = subinstr(address," SQ ", " SQUARE, ",.) if regexm(address," SQ BUILDINGS")==0 & regexm(address," SQ BDGS")==0 & regexm(address," SQ TERR")==0
replace address = subinstr(address," SQR ", " SQUARE, ",.)
replace address = subinstr(address," SQRE ", " SQUARE, ",.)
replace address = subinstr(address," PL ", " PLACE, ",.) if regexm(address," PL NORTH")==0
replace address = subinstr(address," YD ", " YARD, ",.) if regexm(address," YD BUILDINGS")==0
replace address = subinstr(address," TER ", " TERRACE, ",.) if regexm(address," TER MOORS")==0
replace address = subinstr(address," TERR ", " TERRACE, ",.)
replace address = subinstr(address,"COTTS ", "COTTAGES, ",.)
replace address = subinstr(address," GDNS ", " GARDENS, ",.) if regexm(address," GDNS ESTATE")==0 & regexm(address," GDNS MANSIONS")==0
replace address = subinstr(address," ST, BUILDINGS", " STREET BUILDINGS",.)
replace address = subinstr(address," ST, PANCRAS", " ST PANCRAS",.)
replace address = subinstr(address,"BUILDINGS ", "BUILDINGS, ",.)

* Manual changes 
gen add_inprog = address
replace address = "SEUOTON ST., ALBANY RD., OLD KENT RD." if address == "SEUOTON ST., ALBANY RD., RD. KENT RD."
replace address = "BEVINGTON ROAD, CALEDONIAN ROAD" if address == "BEVINGTON ST, CALEDONIAN ROAD"
replace address = "HEALTHY TER, HOMERTON" if address == "HEALTHY FER, HOMERTON"
replace address = "DEVAS STREET, BROMLEY BY BOW" if address == "DEVASK STREET, BROMLEY BY BOW"
replace address = "LADBROKE GROVE, NOTTING HILL" if address == "LADBROOKE GROVE, NOTTING HILL"
replace address = "MILNER STREET, NEW BUT" if address == "MILNE STREET, NEW BUT"
replace address = "DOVE COURT, LEATHER LANE" if address == "DOVE COURT, HEATHER LANE"
replace address = "BRACKLEY ST, BARBICAN" if address == "BRACKLEY ST BARBICAN"
replace address = "BUTTESLAND ST, EAST ROAD, CITY ROAD" if address == "BUTTESLAND ST EAST ROAD, CITY ROAD"
replace address = "THRAWL ST, BRICK LANE, SPITALFIELDS" if address == "THROLE ST, BRICK LANE SPITALFIELD"
replace address = "CHILTERN GREEN, LUTON, BEDFORDSHIRE" if address == "CHILTON GREEN, N LUTON, BEDO"
replace address = "PEABODY BUILDINGS, DUKE	 STREET, EC" if address == "NEABODY BUILDINGS, DUKE STREET, EC"
replace address = "HOWS ST, KINGSLAND ROAD, N" if address == "HOWE ST, KINGSLAND ROAD, N"
replace address = "GROVE COTTAGES, BELL ST, EDGWARE ROAD" if address == "GROVE COTTAGES BELL ST, EDGWARE ROAD"
replace address = "WESTON ST, DOVER ST, BORO" if address == "WESTERN ST, DOVER ST, BORO"
replace address = "TREDERWEN ROAD, LANDSDOWN ROAD, DALSTON" if address == "FREDERWIN ROAD, LANDSDOWN ROAD, DALSTON"
replace address = "MARKET PLACE, HAYLE, CORNWALL" if address == "MARKET PLACE, HAYLE CORNWALL"
replace address = "COTLEIGH ROAD, WEST HAMPSTEAD" if address == "COLLEIGH ROAD, WEST HAMPSTEAD"
replace address = "ALNWICK ROAD, PRINCE OF WALES ROAD, VICTORIA DOCKS" if address == "2??"
replace address = "CRAWFORD PASSAGE, FARRINGDON ROAD" if address == "CRAMFORD PASSAGE, FARRINGDON ROAD" | address == "CRAWFORDS PASSAGE, FARRINGDON ROAD"
replace address = "CORPORATION BUILDINGS, FARRINGDON ROAD, EC" if address == "CORPORATION BUILDINGS FARRINGDON ROAD, EC"
replace address = "PROVIDENCE PL, BAKERS ROW, FARRINGDON ROAD, EC" if address == "PROVIDENCE PL, BIKERS ROW, FARRINGDON ROAD, EC"
replace address = "OLDHAM GARDENS, FARRINGDON ROAD" if address == "OLD HAM GARDENS, FARRINGDON ROAD"
replace address = "QUEENSBURY ST, ESSEX ROAD" if address == "QUEENSBERRY ST, ESSEX ROAD"
replace address = "JEWIN CRESCENT, EC" if address == "TWIN CRESCENT, EC"
replace address = "HIGH WYCH, SAWBRIDGEWORTH" if address == "HIGH WYCH SAWBRIDGEWORTH"
replace address = "TATWORTH STREET, TATWORTH, CHARD, SOMERSETSHIRE" if address == "TATWORTH STREET, TATWORTH NR CHARD SOMERSETSHIRE"
replace address = "JAMES STREET, HAGGERSTON" if address == "JAMES STREET, HAGGERSTONE"
replace address = "FAIRHILL NR TUNBRIDGE" if address == "FAIRHILL NR TONBRIDGE"
replace address = "FEATHERSTONE ST, CITY ROAD" if address == "FEATHERSTON ST, CITY ROAD"
replace address = "BROOKLYN COTTS, SAYER ST, HUNTINGS" if address == "BROOKLYN COTTS SAYER ST, HUNTINGS"
replace address = "WINE OFFICE COURT, EC" if add_inprog == "BOYS HOME, 9 WINE OFFICE COURT, EC"
replace address = "COWLEY, MIDDLESEX" if address == "COWLEY MIDDLESEX"
replace address = "CHESSINGTON, KINGSTON" if address == "CHESSINGTON WM KINGSTON"
replace address = "COAST GUARD STATION, THEDDLETHORPE ST, HELEN LOUTH, LINCOLNSHIRE" if address == "COAST GUARD STATION, THEDDLETHORPE ST HELEN LOUTH LINCOLNSHIRE"
replace address = "WHITECHAPEL" if address == "ADDRESS IN WHITECHAPEL UNKNOWN"
replace address = "" if address == "UNKNOWN"
replace address = "GREAT GUILFORD STREET, BLACKFRIARS" if address == "GUILFORD STREET, BLACKFRIARS"
replace address = "DELHI ST, COPENHAGEN STREET, KINGS CROSS" if address == "DELHI ST COPENHAGEN STREET, KINGSCROSS"
replace address = "WICKLOW ST, KINGS CROSS" if address == "WICKLOW, ST KINGS CROSS"
replace address = "LAVINIA GROVE, WHARFEDALE ROAD, KINGS CROSS" if address == "LAVINIA GR WHARFEDALE ROAD, KINGS CROSS"
replace address = "MODEL BUILDINGS, STREATHAM ST, BLOOMSBURY" if address == "MODEL BUILDINGS, STREATHAM, ST BLOOMSBURY"
replace address = "BELVEDERE CRESCENT, PINE ST, YORK ROAD, EC" if address == "BELVEDERE CRESCENT PINE ST, YORK ROAD, EC"
replace address = "BISHOPS HEAD COURT, GRAYS INN ROAD" if address == "BISHOPSGATE COURT, GRAYS INN ROAD"
replace address = "OLD ST, LONDON ROAD, SOUTHWARK" if address == "OLD ST LONDON ROAD, SOUTHWARK"
replace address = "FANN ST, ALDERSGATE STREET" if address == "FARM ST, ALDERSGATE STREET"
replace address = "BRIDGEWATER PLACE, ALDERSGATE ST" if address == "BRIDGWATER GDNS, ALDERSGATE ST"
replace address = "GREEN ARBOUR CT, BELL ALLEY, ALDERSGATE ST" if address == "GREEN ARBOUR CT, BELL ALLEY ALDERSGATE ST"
replace address = "GLASSHOUSE YD, ALDERSGATE ST" if address == "GLARRHOUSE YD, ALDERSGATE ST"
replace address = "BRIDGEWATER PL, FANN ST, ALDERSGATE ST, EC" if address== "BRIDGEWATER HO, FANNN ST, ALDERSGATE ST, EC"
replace address = "HUTCHINSONS AVENUE, ALDGATE, NEWTON ST" if address =="HUTCHINSONS AVENUE, ALDGATE NEWTON ST"
replace address = "FISHERS ALLEY, MIDDLESEX ST, ALDGATE" if address == "FISHERS ALLEY MIDDLESEX ST, ALDGATE"
replace address = "LANCASTER STABLES, BELSIZE PARK GARDENS" if address == "LANCASTER STABLES BELSIZE PARK, GARDENS"
replace address = "ROYSTON ST, BENNYS, VICTORIA PARK" if address == "ROYSTON ST BENNYS VICTORIA PARK"
replace address = "QUEEN STREET, TOWER HILL" if address == "QUEENS STREET, TOWER HILL"
replace address = "HENRY PL, COPENHAGEN ST, BARNSBURY" if address == "HENRY PL, COPENHAGEN BARNSBURY"
replace address = "HEATHWOOD GARDENS, CHARLTON, KENT, SE" if address == "HEATHWOOD GARDENS, CHARLTON KENT, SE"
replace address = "UNION ST, STOKE NEWINGTON" if address == "UNION ST STOKE, NEWINGTON"
replace address = "PARK LANE, STOKE NEWINGTON" if address == "PARK LANE STOKE, NEWINGTON"
replace address = "HAMILTON GARDENS, ST JOHNS WOOD" if address == "HAMILTON GARDENS ST, JOHNS WOOD"
replace address = "PENNY BANK CHAMBERS, ST JOHN SQ, EC" if address == "PENNY BANK CHAMBERS ST, JOHN SQ, EC"
replace address = "ROBIN HOOD COURT, SHOE LANE" if address == "ROBIN HOOD COURT SHOE LANE"
replace address = "ROSE & CROWN COURT, HIGH ST, N" if address == "ROSE & CROWN COURT HIGH ST, N"
replace address = "BALTIC COURT, HATFIELD ST, EC" if address == "BALTIC COURT HATFIELD ST, EC"
replace address = "ALBION PLACE, ST JOHNS LANE" if address == "ALBION PLACE ST, JOHNS LANE"
replace address = "TWISTER ALLEY BUNHILL ROW" if address == "TWISTER ALLEY BUNHILL ROW"
replace address = "HARTS COURT, FANN STREET, ALDERSGATE STREET" if address == "HARTS COURT FANN STREET, ALDERSGATE"
replace address = "GRAYS HILL, HENLEY ON THAMES" if address == "GRAYS HILL HENLEY ON THAMES"
replace address = "OXFORD ST, JUBILEE ST, COMMERCIAL ROAD" if address == "OXFORD ST JUBILES ST, COMMERCIAL ROAD"
replace address = "GUILFORD ST, FARRINGDON ROAD" if address == "GUILDFORD ST, FARRINGDON ROAD"
replace address = "THE INVALID CHILDRENS AID ASSOCIATION, 18 BUCKINGHAM ST, STRAND" if address == "THE INVALID CHILDRENS AID ASSOCIATION, 18 BUCKINGHAM ST STROUD"
replace address = "STAMFORD VILLAS, LEICESTER ROAD, NEW BARNET, N" if address == "STAMFORD VILLAS LEICESTER ROAD, NEW BARNET, N"

* Fix typos
replace address = regexr(address,"SNOWSFIELD","SNOWSFIELDS") if regexm(address,"SNOWSFIELDS") == 0
replace address = regexr(address,"B(')*DSEY","BERMONDSEY")
replace address = regexr(address,"WALTHAMSTON(E)*","WALTHAMSTOW")
replace address = regexr(address,"ST GEORGE(S)*, E$","ST GEORGE IN THE EAST")
replace address = regexr(address,"ST GEORGES IN THE EAST","ST GEORGE IN THE EAST")
replace address = regexr(address,"ST GEORGES EAST","ST GEORGE IN THE EAST")
replace address = regexr(address,"BETHNAL GR(N)*$","BETHNAL GREEN")
replace address = regexr(address,"BETHNAL GR, ROAD$","BETHNAL GREEN ROAD")
replace address = regexr(address,"BETHNAL GREEN, ROAD$","BETHNAL GREEN ROAD")
replace address = regexr(address,"BETHNAL GW$","BETHNAL GREEN")
replace address = regexr(address,"BETHNAL GRANT ROAD$","BETHNAL GREEN ROAD")
replace address = regexr(address,"BETH GREEN","BETHNAL GREEN")
replace address = regexr(address,"BETHL GREEN","BETHNAL GREEN")
replace address = regexr(address,"MARY LE BONE", "MARYLEBONE")
replace address = regexr(address,"FARRINGTON","FARRINGDON")
replace address = regexr(address,"COLDBATH","COLD BATH")
replace address = regexr(address,"WHCROSS ST","WHITECROSS ST")
replace address = regexr(address,"WHITE X ST","WHITECROSS ST")
replace address = regexr(address,"CAMDEN LOWN","CAMDEN TOWN")
replace address = regexr(address,"CAMDEN$","CAMDEN TOWN")
replace address = regexr(address,"SHOUDITCH","SHOREDITCH")
replace address = regexr(address,"STOKE NEWINGTONN","STOKE NEWINGTON")
replace address = regexr(address,"MILE END NEW TN", "MILE END NEW TOWN")
replace address = regexr(address,"MILE ENDS","MILE END")
replace address = regexr(address,"E DULWICH","EAST DULWICH")
replace address = regexr(address,"MIDDX","MIDDLESEX")
replace address = regexr(address,"CHESHNUT","CHESHUNT")
replace address = regexr(address,"DALWICH","DULWICH")
replace address = regexr(address,"HAGGERSTONE","HAGGERSTON")
replace address = regexr(address,"STOKE H(.)+TON","STOKE NEWINGTON")
replace address = regexr(address,"CLERKENWEL,","CLERKENWELL,")
replace address = regexr(address,"COW CROSS","COWCROSS")
replace address = regexr(address,"FIREBALL","FIRE BALL")
replace address = regexr(address,"HOUNSDITCH","HOUNDSDITCH")
replace address = regexr(address,"ENFIELD, WASH","ENFIELD WASH")
replace address = regexr(address,"ENFIELD HEIGHWAY","ENFIELD HIGHWAY")
replace address = regexr(address,"CLEREKENWELL","CLERKENWELL")
replace address = regexr(address,"WALTHAMASTOW","WALTHAMSTOW")
replace address = regexr(address,"WOOLWICK","WOOLWICH")
replace address = regexr(address," N PADDINGTON","PADDINGTON")
replace address = regexr(address,"STRATFORD MARSH","STRATFORD")
replace address = regexr(address,"STRATFORD NEW T(OW)*N","STRATFORD")
replace address = regexr(address,"CLERKENWELL, ROAD","CLERKENWELL ROAD")
replace address = regexr(address,"CLERKENWELL ROADS","CLERKENWELL ROAD")
replace address = regexr(address,"CLERKENWELL GREN","CLERKENWELL GREEN")
replace address = regexr(address,"VICTORIA, DWELLINGS","VICTORIA DWELLINGS")
replace address = regexr(address,"ST JOHN ST, ROAD","ST JOHN ST ROAD")
replace address = regexr(address,"LITTLE SUTTON, ST,","LITTLE SUTTON ST,")
replace address = regexr(address,"ST JOHN STREET R(OA)*D","ST JOHN ST ROAD")
replace address = regexr(address,"ST JOHN STREET, ROAD","ST JOHN ST ROAD")
replace address = regexr(address,"ST JOHN ST, ROAD","ST JOHN ST ROAD")
replace address = regexr(address,"HAT & MITRE", "HAT MITRE")
replace address = regexr(address,"HEXTON", "HOXTON")
replace address = regexr(address,"LEATHERR", "LEATHER")
replace address = regexr(address,"LEATHER HEAD", "LEATHERHEAD")
replace address = regexr(address,"LEATHER SELLERS", "LEATHERSELLERS")
replace address = regexr(address,"LEATHER( )*[L|H]AN[D|T]", "LEATHER LANE")
replace address = regexr(address,"BROAD WALL","BROADWALL")
replace address = regexr(address,"HOLLARND ST","HOLLAND ST")
replace address = regexr(address,"UPGROUND ST","UPPER GROUND ST")
replace address = regexr(address,"CITY R,","CITY ROAD,")
replace address = regexr(address,"WINDSORE ","WINDSOR ")
replace address = regexr(address,"BARKING E","BARKING, E")
replace address = regexr(address,"BARKINGS ","BARKING")
replace address = regexr(address,"BARKING SIDE","BARKINGSIDE")
replace address = regexr(address," E H[A|U]M$","EAST HAM")
replace address = regexr(address,"DISPARD ROAD","DESPARD ROAD")
replace address = regexr(address,"LE[A|E]K(E)* ST", "LEEKE ST") 
replace address = regexr(address," FIELDS ST","FIELD ST")
replace address = regexr(address,"^FIELDS ST","FIELD ST")
replace address = regexr(address,"CALEDONCAN","CALEDONIAN")
replace address = regexr(address,"CALENDONIAN","CALEDONIAN")
replace address = regexr(address,"CALEDOMAN","CALEDONIAN")
replace address = regexr(address,"CALEDOMIAN","CALEDONIAN")
replace address = regexr(address,"STRATHAM ST","STREATHAM ST")
replace address = regexr(address," STH, HORNSEY"," SOUTH HORNSEY")
replace address = regexr(address,"HORNSEY PK(,)* ROAD","HORNSEY PARK ROAD")
replace address = regexr(address," S HORNSEY"," SOUTH HORNSEY")	
replace address = regexr(address," STH HORNSEY"," SOUTH HORNSEY")	
replace address = regexr(address,"PRIORY, HORNSEY","PRIORY HORNSEY")	
replace address = regexr(address,"BRIXTON HULL","BRIXTON HILL")	
replace address = regexr(address,"DANBROOKE ROAD","DANBROOK ROAD")
replace address = regexr(address,"FENSBURY","FINSBURY")
replace address = regexr(address," MKT"," MARKET")
replace address = regexr(address,"GOSSWELL ROAD","GOSWELL ROAD")
replace address = regexr(address,"FARRINGDEN ROAD","FARRINGDON ROAD")
replace address = regexr(address,"WHITE CROSS ST","WHITECROSS ST")
replace address = regexr(address,"BOURNMOUTH","BOURNEMOUTH")
replace address = regexr(address,"BETHNAL ROAD","BETHNAL GREEN ROAD")
replace address = regexr(address,"COMMERICAL ROAD","COMMERCIAL ROAD")
replace address = regexr(address,"FINSBY","FINSBURY")
replace address = regexr(address,"BLACKSFRIARS","BLACKFRIARS")
replace address = regexr(address,"CLEKENWELL","CLERKENWELL")
replace address = regexr(address,"HOLLBORN","HOLBORN")
replace address = regexr(address,"PENTONVILL,","PENTONVILLE ROAD,")
replace address = regexr(address,"BETHNAL G$","BETHNAL GREEN")
replace address = regexr(address,"WHITECROSS PLECE","WHITECROSS PLACE")
replace address = regexr(address,"ISLINGHTON","ISLINGTON")
replace address = regexr(address,"WESTMENSTER","WESTMINSTER")
replace address = regexr(address,"NOTTING MILL","NOTTING HILL")
replace address = regexr(address,"WHTCHAPEL","WHITECHAPEL")
replace address = regexr(address,"BETHNAL GR ROAD","BETHNAL GREEN ROAD")
replace address = regexr(address,"KENNENGTON ROAD","KENNINGTON ROAD")
replace address = regexr(address,"BROMLEY BY ROW","BROMLEY BY BOW")
replace address = regexr(address,", ROW$",", BOW")
replace address = regexr(address,"COPENHAGER ST","COPENHAGEN ST")
replace address = regexr(address,"EDGSWARE R(OA)*D","EDGWARE ROAD")
replace address = regexr(address,"SHITALFIELD","SPITALFIELD")
replace address = regexr(address,"CLARKENWELL","CLERKENWELL")
replace address = regexr(address,"GOSEWELL R(OA)*D","GOSWELL ROAD")
replace address = regexr(address," PK$"," PARK")
replace address = regexr(address,"CLKWELL","CLERKENWELL")
replace address = regexr(address,"SPITAEFIELDS","SPITALFIELDS")
replace address = regexr(address,"WORD GREEN","WOOD GREEN")
replace address = regexr(address,"HAXTON","HOXTON")
replace address = regexr(address,"SAFFRON HILB","SAFFRON HILL")
replace address = regexr(address,"NEWNORTH R(OA)*D","NEW NORTH ROAD")
replace address = regexr(address,"NEWINGTON, BUTTS","NEWINGTON BUTTS")
replace address = regexr(address,"WHITCHAPEL","WHITECHAPEL")
replace address = regexr(address,"BURNSBURY","BARNSBURY")
replace address = regexr(address,"ST JOHN, ST ROAD","ST JOHN ST ROAD")
replace address = regexr(address,"RE-ADMITTED","READMISSION")
replace address = regexr(address,"STREETM","STREET,")
replace address = regexr(address,"SHAFLESBURY","SHAFTESBURY")
replace address = regexr(address,"SHAFTERBURY","SHAFTESBURY")
replace address = regexr(address,"SHAFTESBURG PL,","SHAFTESBURY PLACE,")
replace address = regexr(address,"GALSSHOUSE YD","GLASSHOUSE YD")
replace address = regexr(address,"LAURDERDALE","LAUDERDALE")
replace address = regexr(address,"LANDERDALE","LAUDERDALE")
replace address = regexr(address,"BRIDGWATER PL","BRIDGEWATER PL")
replace address = regexr(address,"ALDGATE ROAD","ALDGATE")
replace address = regexr(address,"HUNSLITT ST","HUNSLETT ST")
replace address = regexr(address,"GREENSTREET","GREEN STREET")
replace address = regexr(address,"BONNERS LANE","BONNER LANE")
replace address = regexr(address,"WHITEPOST LANE","WHITE POST LANE")
replace address = regexr(address,"SEWARD STONE ROAD","SEWARDSTONE ROAD")
replace address = regexr(address,"HOLMER ROAD","HOMER ROAD")
replace address = regexr(address,"HAMILON ROAD","HAMILTON ROAD")
replace address = regexr(address,"ST JAMESS ROAD","ST JAMES ROAD")
replace address = regexr(address,"THE APPROACH R","APPROACH R")
replace address = regexr(address,"ALNMOUTH","ALLANMOUTH")
replace address = regexr(address,"ALLAMOUTH","ALLANMOUTH")
replace address = regexr(address,"CADOVA R(OA)*D","CORDOVA ROAD")
replace address = regexr(address,"NEWINGTON GR ROAD","NEWINGTON GREEN ROAD")
replace address = regexr(address,"NEWINGTON GR$","NEWINGTON GREEN")
replace address = regexr(address,"NEVILL(E)*(S)* C","NEVILLES C")
replace address = regexr(address,"NEVILLE ST(REET)*","NEVILLES COURT")
replace address = regexr(address,"SAINT LUKES$","ST LUKE")
replace address = regexr(address,"HUCKNEY","HACKNEY")
replace address = regexr(address,"FANINGDON","FARRINGDON")
replace address = regexr(address,"WINDSON$","WINDSOR")
replace address = regexr(address,"ST GEORGES-IN-THE-EAST","ST GEORGE IN THE EAST")
replace address = regexr(address,"HUMBLEDON$","WIMBLEDON")
replace address = regexr(address,"KING CROSS","KINGS CROSS")
replace address = regexr(address,"KINGS LAND ROAD","KINGSLAND ROAD")
replace address = regexr(address,"HOLLWAY","HOLLOWAY")
replace address = regexr(address,"BETH(NAL)* G[R|N] ROAD","BETHNAL GREEN ROAD")
replace address = regexr(address,"MILL WALL","MILLWALL")
replace address = regexr(address,"CLERKESWELL","CLERKENWELL")
replace address = regexr(address,"FLERT ST","FLEET ST")
replace address = regexr(address,"COMMERICIAL R","COMMERCIAL R")
replace address = regexr(address,"BELVEDORE","BELVEDERE")
replace address = regexr(address,"BARNSBURG","BARNSBURY")
replace address = regexr(address,"KINGLAND ROAD","KINGSLAND ROAD")
replace address = regexr(address,"CLERENWELL","CLERKENWELL")
replace address = regexr(address,"7 SISTERS R","SEVEN SISTERS R")
replace address = regexr(address,"SEVEN LISTERS","SEVEN SISTERS")
replace address = regexr(address,"VICTORIA PKS$","VICTORIA PARK")
replace address = regexr(address,"LOWISHAM","LEWISHAM")
replace address = regexr(address,"WOOWICH","WOOLWICH")
replace address = regexr(address,"GORWELL R","GOSWELL R")
replace address = regexr(address,"EDGEWARE R","EDGWARE R")
replace address = regexr(address,"SUFFRON HILL","SAFFRON HILL")
replace address = regexr(address,"CAMBIDGE","CAMBRIDGE")
replace address = regexr(address,"ST, JOHN ST","ST JOHN ST")
replace address = regexr(address,"ESSET R","ESSEX R")
replace address = regexr(address,"WALTHAM STOW","WALTHAMSTOW")
replace address = regexr(address,"SHEPHERDESS, WALK","SHEPHERDESS WALK")
replace address = regexr(address,"HINGSLAND R","KINGSLAND R")
replace address = regexr(address,"WALHAMSTOW","WALTHAMSTOW")
replace address = regexr(address,"GOWELL R","GOSWELL R")
replace address = regexr(address,"FURRINGDON","FARRINGDON")
replace address = regexr(address,"HAGGRESTON","HAGGERSTON")
replace address = regexr(address,"MITTWALL","MILLWALL")
replace address = regexr(address,"CLK WELL","CLERKENWELL")
replace address = regexr(address,"WHITECROSS$","WHITECROSS STREET")
replace address = regexr(address,"BETHNAL GREET","BETHNAL GREEN")
replace address = regexr(address," MDDX$"," MIDDLESEX")
replace address = regexr(address," WHCHAPEL$"," WHITECHAPEL")
replace address = regexr(address,"CLERKENEWELL","CLERKENWELL")
replace address = regexr(address,"HOCKNEY","HACKNEY")
replace address = regexr(address,"WATTHAMSTOW","WALTHAMSTOW")
replace address = regexr(address," E HAMS$"," EAST HAM")
replace address = regexr(address,"TOTTENHM","TOTTENHAM")
replace address = regexr(address,"BALCKFRIARS","BLACKFRIARS")
replace address = regexr(address,"BEDFORTD ST","BEDFORD ST")
replace address = regexr(address,"BRIMS BUILD","BREAMS BUILD")
replace address = regexr(address,"BREAMS BAG","BREAMS BUILDINGS")
replace address = regexr(address,"CHESTER RENTS","CM CHESTER RENTS")
replace address = regexr(address,"GOLDSMITHS ROW","GOLDSMITH ROW")
replace address = regexr(address,"GOLDSMITH ROAD","GOLDSMITH ROW") if regexm(address,"MAIDSTONE PL")
replace address = regexr(address,"HACKNEWY","HACKNEY")
replace address = regexr(address,"ROSWELL ROAD","GOSWELL ROAD")
replace address = regexr(address,"BLKFRIARS","BLACKFRIARS")
replace address = regexr(address,"LITTLE BROADWALL","BROADWALL")
replace address = regexr(address,"BRUMSWICK","BRUNSWICK")
replace address = regexr(address,"STAMPFORD","STAMFORD")
replace address = regexr(address,"BENNET ST","BENNETT ST")
replace address = regexr(address,"SOUTHWARK PARK, ROAD","SOUTHWARK PARK ROAD")
replace address = regexr(address,"SOUTHWARK PK ROAD","SOUTHWARK PARK ROAD")
replace address = regexr(address,"SOUTHWARK PK, ROAD","SOUTHWARK PARK ROAD")
replace address = regexr(address,"SOUTHWARK B, ROAD","SOUTHWARK BRIDGE ROAD")
replace address = regexr(address,"SOUTHWARK PARK$","SOUTHWARK PARK ROAD")
replace address = regexr(address,"ROTHERHITHE ROAD","ROTHERHITHE NEW ROAD")
replace address = regexr(address, "HALF MOON PASSAGE, CLERKENWELL CLOSE","HALF MOON COURT, CLERKENWELL CLOSE")
replace address = regexr(address,"PRINCE OF WALESS R","PRINCE OF WALES R")
replace address = regexr(address,"PARK TERRACE, UPPARK ROAD","UPPER PARK TERR")
replace address = regexr(address,"OLD CHARLTON$","CHARLTON, KENT")
replace address = regexr(address,"OLD CHARLTON","CHARLTON")
replace address = regexr(address,"BETH GR(N)*$","BETHNAL GREEN")
replace address = regexr(address,"VINER ST","VYNER ST")
replace address = regexr(address,"SPITAL FIELDS","SPITALFIELDS")
replace address = regexr(address,"SHOREDITH","SHOREDITCH")
replace address = regexr(address,"HARLEY ON THAMES","HENLEY ON THAMES")
replace address = regexr(address,"BISHIPSGATE","BISHOPSGATE")
replace address = regexr(address,"GLOSTERSH$","GLOUCESTERSHIRE")
replace address = regexr(address,"BAITHOLOMEW","BARTHOLOMEW")
replace address = regexr(address," KEN GARDENS","KEW GARDENS")
replace address = regexr(address,"DORSETSHIRE","DORSET")
replace address = regexr(address,"KINGS CROP","KINGS CROSS")
replace address = regexr(address,"COMMEICAL ROAD","COMMERCIAL ROAD")
replace address = regexr(address,"HORSELY","HORSLEY")
replace address = regexr(address," HIL$","HILL")
replace address = regexr(address,"HALTON GARDEN","HATTON GARDEN")
replace address = regexr(address,"KINGS GROSS","KINGS CROSS")
replace address = regexr(address,"SHIRLEY CROYDON","SHIRLEY, CROYDON")
replace address = regexr(address," BAKING$","BARKING")
replace address = regexr(address,"CLERELAND ST","CLEVELAND ST")
replace address = regexr(address,"FETTTER L","FETTER L")
replace address = regexr(address,"BLKFRAIRS","BLACKFRIARS")
replace address = regexr(address,"LIME HOUSE","LIMEHOUSE")
replace address = regexr(address,"HACKEY","HACKNEY")
replace address = regexr(address,"GLOUCESTERS$","GLOUCESTERSHIRE")
replace address = regexr(address,"FARINGDON R","FARRINGTON R")
replace address = regexr(address,"NORTHAMP[A-Z]+$","NORTHAMPTONSHIRE")
replace address = regexr(address,"DANTI ROAD","DANTE ROAD")
replace address = regexr(address,"^DENT ROAD","DANTE ROAD")
replace address = regexr(address,"MAIDEN HEAD","MAIDENHEAD")
replace address = regexr(address,"ST JOHN WOOD R","ST JOHNS WOOD R")
replace address = regexr(address,"FINS PARK","FINSBURY PARK")

* Correct end of string place names
replace address = regexr(address," LONDON FIELD$"," LONDON FIELDS")
replace address = regexr(address," STH HACKNEY$"," SOUTH HACKNEY")
replace address = regexr(address," S HACKNEY$"," SOUTH HACKNEY")
replace address = regexr(address," SO HACKNEY$"," SOUTH HACKNEY")
replace address = regexr(address," STH LAMBETH$"," SOUTH LAMBETH")
replace address = regexr(address," LOWER EDMONTON"," EDMONTON")
replace address = regexr(address," L EDMONTON$"," EDMONTON")
replace address = regexr(address," LWR EDMONTON$"," EDMONTON")
replace address = regexr(address," LR EDMONTON$"," EDMONTON")
replace address = regexr(address," UPPER EDMONTON$"," EDMONTON")
replace address = regexr(address," UPP EDMONTON$"," EDMONTON")
replace address = regexr(address," LT EDMONTON$"," EDMONTON")
replace address = regexr(address," EAST STEPNEY$"," STEPNEY")
replace address = regexr(address," EAST GREENWICH"," GREENWICH")
replace address = regexr(address," E GREENWICH"," GREENWICH")
replace address = regexr(address," NORTH WOOLWICH$"," WOOLWICH")
replace address = regexr(address," SOUTH WOOLWICH$"," WOOLWICH")
replace address = regexr(address," S WOOLWICH$"," WOOLWICH")
replace address = regexr(address," NTH WOOLWICH$"," WOOLWICH")
replace address = regexr(address," N WOOLWICH$"," WOOLWICH")
replace address = regexr(address," NR WOOLWICH$"," WOOLWICH")
replace address = regexr(address," NR CROYDON$"," CROYDON")
replace address = regexr(address," WEST CROYDON$"," CROYDON")
replace address = regexr(address," SOUTH CROYDON$"," CROYDON")
replace address = regexr(address," W CROYDON$"," CROYDON")
replace address = regexr(address," ST CROYDON$"," CROYDON")
replace address = regexr(address," OLD BRENTFORD$"," BRENTFORD")
replace address = regexr(address," NEW BRENTFORD$"," BRENTFORD")
replace address = regexr(address," WEST HENDON$"," HENDON")
replace address = regexr(address," SOUTH GRAVESEND$"," GRAVESEND")
replace address = regexr(address," DEVON$"," DEVONSHIRE")
replace address = regexr(address," NORTH DEVONSHIRE$"," DEVONSHIRE")
replace address = regexr(address," N DEVONSHIRE$"," DEVONSHIRE")
replace address = regexr(address," NORTH DEVONSHIRE$"," DEVONSHIRE")
replace address = regexr(address," LINCOLN$"," LINCOLNSHIRE")
replace address = regexr(address," MERIONETH$"," MERIONETHSHIRE")
replace address = regexr(address," WORCESTER$"," WORCESTERSHIRE")
replace address = regexr(address," DERBY$"," DERBYSHIRE")
replace address = regexr(address,"[I|J] OF W$","HAMPSHIRE")
replace address = regexr(address,"ISLE OF WIGHT","HAMPSHIRE")
replace address = regexr(address,"I OF WIGHT","HAMPSHIRE")
replace address = regexr(address,"U HOLLOWAY$","HOLLOWAY")
replace address = regexr(address,"N HOLLOWAY$","HOLLOWAY")
replace address = regexr(address,"UP HOLLOWAY$","HOLLOWAY")
replace address = regexr(address,"UPP HOLLOWAY$","HOLLOWAY")
replace address = regexr(address,"UPPER	HOLLOWAY$","HOLLOWAY")
replace address = regexr(address,"BARKING,","BARKING TOWN,")
replace address = regexr(address,"BARKING$","BARKING TOWN")
replace address = regexr(address,"BETHNAL G$","BETHNAL GREEN")
replace address = regexr(address,"BETHNAL G ROAD","BETHNAL GREEN ROAD")
replace address = regexr(address,"S LUKES$","ST LUKE")
replace address = regexr(address,"HUNTINGS$","HUNTINGTONSHIRE")
replace address = regexr(address,"ST GEORGES E$","ST GEORGE IN THE EAST")
replace address = regexr(address,"ST GEORGE EAST$","ST GEORGE IN THE EAST")
replace address = regexr(address,"NORTH WCHAPEL$","WHITECHAPEL")
replace address = regexr(address,"WCHAPEL$","WHITECHAPEL")
replace address = regexr(address,"GOLDENLANE","GOLDEN LANE")
replace address = regexr(address,"GREEN HARBOR CT","GREEN ARBOUR CT")
replace address = regexr(address,"GREEN ARBOR CT","GREEN ARBOUR CT")
replace address = regexr(address,"GREEN HARBOUR CT","GREEN ARBOUR CT")
replace address = regexr(address,"S TOTTENHAM","TOTTENHAM")
replace address = regexr(address,"SOUTH TOTTENHAM","TOTTENHAM")
replace address = regexr(address,"STH TOTTENHAM","TOTTENHAM")
replace address = regexr(address," ST TOTTENHAM"," TOTTENHAM")
replace address = regexr(address,"LOWER TOTTENHAM"," TOTTENHAM")
replace address = regexr(address,"CANNING TN","CANNING TOWN")
replace address = regexr(address,"COWCROSS$","COWCROSS STREET")
replace address = regexr(address,"COWCROSS,","COWCROSS STREET,")
replace address = regexr(address,"ST JOHN ST L$","ST JOHN ST ROAD")
replace address = regexr(address,"CLARKWELL$","CLERKENWELL")
replace address = regexr(address,"GRAY INN$","GRAYS INN")
replace address = regexr(address,"GRAY INN$","GRAYS INN")
replace address = regexr(address,"COMPBELL ST","CAMPBELL ST")
replace address = regexr(address,", BEDS$",", BEDFORDSHIRE")
replace address = regexr(address," GDN$","GARDEN")
replace address = regexr(address," CRESET$"," CRESCENT")
replace address = regexr(address," CREST$"," CRESCENT")
replace address = regexr(address," GLOS$"," GLOUCESTERSHIRE")
replace address = regexr(address," GLOSTERS$"," GLOUCESTERSHIRE")
replace address = regexr(address,"LOUGHBORO$","LOUGHBOROUGH, BRIXTON")

* Missing comma before county at end of string

replace address = regexr(address," KENT$",", KENT") if regexm(address,"[A-Z] KENT$")==1 & regexm(address,"NEW KENT")==0 & regexm(address,"OLD KENT")==0
replace address = regexr(address," HERTS$",", HERTFORDSHIRE") if regexm(address,"[A-Z] HERTS$")==1 
replace address = regexr(address," WILTS$",", WILTSHIRE") if regexm(address,"[A-Z] WILTSHIRE$")==1 
replace address = regexr(address," HANTS$",", HAMPSHIRE") if regexm(address,"[A-Z] HANTS$")==1 
replace address = regexr(address," HAMPSHIRE$",", HAMPSHIRE") if regexm(address,"[A-Z] HAMPSHIRE$")==1 
replace address = regexr(address," YORKS$",", YORKSHIRE") if regexm(address,"[A-Z] YORKS$")==1 
replace address = regexr(address," BERKS$",", BERKSHIRE") if regexm(address,"[A-Z] BERKS$")==1 
replace address = regexr(address," BUCKS$",", BUCKINGHAMSHIRE") if regexm(address,"[A-Z] BUCKS$")==1 
replace address = regexr(address," HACKNEY$",", HACKNEY") if regexm(address,"[A-Z] HACKNEY$")==1  & regexm(address,"SOUTH HACKNEY")==0
replace address = regexr(address," ST LUKE(S)*$",", ST LUKE") if regexm(address,"[A-Z] ST LUKE(S)*$")==1 
replace address = regexr(address," CITY$",", LONDON CITY") if regexm(address,"[A-Z] CITY$")==1 & regexm(address,"LONDON CITY")==0
replace address = regexr(address," OXFORD$",", OXFORD") if regexm(address,"[A-Z] OXFORD$")==1 & regexm(address,"NR OXFORD")==0
replace address = regexr(address," HOLBORN$",", HOLBORN") if regexm(address,"[A-Z] HOLBORN$")==1 & regexm(address,"HIGH HOLBORN")==0
replace address = regexr(address," BETHNAL GREEN$",", BETHNAL GREEN") if regexm(address,"[A-Z] BETHNAL GREEN$")==1 
replace address = regexr(address," WHITECHAPEL$",", WHITECHAPEL") if regexm(address,"[A-Z] WHITECHAPEL$")==1 & regexm(address,"SOUTH WHITECHAPEL")==0
replace address = regexr(address," WEST HAM$",", WEST HAM") if regexm(address,"[A-Z] WEST HAM$")==1 
replace address = regexr(address," POPLAR$",", POPLAR") if regexm(address,"[A-Z] POPLAR$")==1 & regexm(address,"SOUTH POPLAR")==0
replace address = regexr(address," LAMBETH$",", LAMBETH") if regexm(address,"[A-Z] LAMBETH$")==1  & regexm(address,"SOUTH LAMBETH")==0
replace address = regexr(address," WANDSWORTH$",", WANDSWORTH") if regexm(address,"[A-Z] WANDSWORTH$")==1  & regexm(address,"NEW WANDSWORTH")==0
replace address = regexr(address," HILL DARTFORD$"," HILL, DARTFORD")
replace address = regexr(address," DORKING$",", DORKING") if regexm(address,"[A-Z] DORKING$")==1  & regexm(address,"R DORKING")==0
replace address = regexr(address," SEVENOAKS$",", SEVENOAKS") if regexm(address,"[A-Z] SEVENOAKS$")==1  & regexm(address,"R SEVENOAKS")==0
replace address = regexr(address," EPPING$",", EPPING") if regexm(address,"[A-Z] EPPING$")==1  & regexm(address,"R EPPING")==0
replace address = regexr(address," DEVONSHIRE$",", DEVONSHIRE") if regexm(address,"[A-Z] DEVONSHIRE$")==1  & regexm(address,"R DEVONSHIRE")==0
replace address = regexr(address," LINCOLNSHIRE$",", LINCOLNSHIRE") if regexm(address,"[A-Z] LINCOLNSHIRE$")==1  & regexm(address,"R LINCOLNSHIRE")==0
replace address = regexr(address," DERBYSHIRE$",", DERBYSHIRE") if regexm(address,"[A-Z] DERBYSHIRE$")==1  & regexm(address,"R DERBYSHIRE")==0
replace address = regexr(address," BARKING TOWN$",", BARKING TOWN") if regexm(address,"[A-Z] BARKING TOWN$")==1
replace address = regexr(address," BERMONDSEY$",", BERMONDSEY") if regexm(address,"[A-Z] BERMONDSEY$")==1 
replace address = regexr(address,", CITY$",", LONDON CITY")
replace address = regexr(address," CITY ROAD",", CITY ROAD") if regexm(address,"[A-Z] CITY ROAD")==1
replace address = regexr(address," GOLDEN LANE$",", GOLDEN LANE") if regexm(address,"[A-Z] GOLDEN LANE$")==1
replace address = regexr(address,"LEYTONSTONE","LEYTON") if regexm(address,"LEYTONSTONE ROAD")==0
replace address = regexr(address," MILE END NEW TOWN$",", MILE END NEW TOWN") if regexm(address,"[A-Z] MILE END NEW TOWN$")==1 
replace address = regexr(address," LEYTON",", LEYTON") if regexm(address,"[A-Z] LEYTON")==1 & regexm(address,"LEYTONSTONE")==0
replace address = regexr(address," ILFORD",", ILFORD") if regexm(address,"[A-Z] ILFORD")==1 & regexm(address,"LITTLE ILFORD")==0
replace address = regexr(address," WALTHAMSTOW",", WALTHAMSTOW") if regexm(address,"[A-Z] WALTHAMSTOW")==1 & regexm(address,"WEST WALTHAMSTOW")==0
replace address = regexr(address," HIGHGATE",", HIGHGATE") if regexm(address,"[A-Z] HIGHGATE")==1 & regexm(address,"FROM HIGHGATE")==0 & regexm(address,"FR HIGHGATE")==0
replace address = regexr(address," COWCROSS",", COWCROSS") if regexm(address,"[A-Z] COWCROSS")==1 
replace address = regexr(address," HACKNEY ROAD",", HACKNEY ROAD") if regexm(address,"[A-Z] HACKNEY ROAD")==1 
replace address = regexr(address," PECKHAM RYE",", PECKHAM RYE") if regexm(address,"[A-Z] PECKHAM RYE")==1 
replace address = regexr(address," CLERKENWELL GREEN",", CLERKENWELL GREEN") if regexm(address,"[A-Z] CLERKENWELL GREEN")==1 
replace address = regexr(address," CLERKENWELL CLOSE",", CLERKENWELL CLOSE") if regexm(address,"[A-Z] CLERKENWELL CLOSE")==1 
replace address = regexr(address," CLERKENWELL ROAD",", CLERKENWELL ROAD") if regexm(address,"[A-Z] CLERKENWELL ROAD")==1 
replace address = regexr(address," CLERKENWELL EC",", CLERKENWELL, EC") if regexm(address,"[A-Z] CLERKENWELL EC")==1 
replace address = regexr(address," ST JOHN",", ST JOHN") if regexm(address,"[A-Z] ST JOHN")==1 
replace address = regexr(address," COMMERCIAL ROAD",", COMMERCIAL ROAD") if regexm(address,"[A-Z] COMMERCIAL ROAD")==1 
replace address = regexr(address," STAMFORD ST",", STAMFORD ST") if regexm(address,"[A-Z] STAMFORD ST")==1 
replace address = regexr(address," BRUNSWICK STREET",", BRUNSWICK STREET") if regexm(address,"[A-Z] BRUNSWICK STREET")==1 
replace address = regexr(address," YORK ROAD",", YORK ROAD") if regexm(address,"[A-Z] YORK ROAD")==1 & regexm(address,"OLD YORK ROAD")==0
replace address = regexr(address," KINGS( )*CROSS",", KINGS CROSS") if regexm(address,"[A-Z] KINGS( )*CROSS")==1 & regexm(address,"R KINGS( )*CROSS")==0
replace address = regexr(address," HORNSEY ROAD",", HORNSEY ROAD") if regexm(address,"[A-Z] HORNSEY ROAD")==1
replace address = regexr(address," STOKE NEWINGTON",", STOKE NEWINGTON") if regexm(address,"[A-Z] STOKE NEWINGTON")==1
replace address = regexr(address," ESSEX ROAD",", ESSEX ROAD") if regexm(address,"[A-Z] ESSEX ROAD")==1
replace address = regexr(address," BETHNAL GREEN ROAD",", BETHNAL GREEN ROAD") if regexm(address,"[A-Z] BETHNAL GREEN ROAD")==1 & regexm(address,"OLD BETHNAL GREEN ROAD")==0
replace address = regexr(address," EAST HAM",", EAST HAM") if regexm(address,"[A-Z] EAST HAM")==1 & regexm(address,"SOUTH EAST HAM")==0
replace address = regexr(address," OLD ST",", OLD ST") if regexm(address,"[A-Z] OLD ST")==1 & regexm(address,"NEW OLD ST")==0
replace address = regexr(address," OLD KENT ROAD",", OLD KENT ROAD") if regexm(address,"[A-Z] OLD KENT ROAD")==1
replace address = regexr(address," GRAYS INN(,)* R(OA)*D",", GRAYS INN ROAD") if regexm(address,"[A-Z] GRAYS INN(,)* R(OA)*D")==1
replace address = regexr(address," ALDERSGATE ST",", ALDERSGATE ST") if regexm(address,"[A-Z] ALDERSGATE ST")==1
replace address = regexr(address," VICTORIA P(AR)*K",", VICTORIA PARK") if regexm(address,"[A-Z] VICTORIA P(AR)*K")==1
replace address = regexr(address," CHANCERY LANE",", CHANCERY LANE") if regexm(address,"[A-Z] CHANCERY LANE")==1
replace address = regexr(address," SOUTHWARK",", SOUTHWARK") if regexm(address,"[A-Z] SOUTHWARK")==1 & regexm(address,"THE SOUTHWARK")==0
replace address = regexr(address," ROTHERHITHE",", ROTHERHITHE") if regexm(address,"[A-Z] ROTHERHITHE")==1
replace address = regexr(address," NEWINGTON BUTTS",", NEWINGTON BUTTS") if regexm(address,"[A-Z] NEWINGTON BUTTS")==1
replace address = regexr(address," O K RD$"," OLD KENT ROAD")

replace address = regexr(address," E C$"," EC")
replace address = regexr(address," S C$"," SE")
replace address = regexr(address," S E$"," SE")
replace address = regexr(address," S W$"," SW")
replace address = regexr(address," W C$"," WC")
replace address = regexr(address," N E$"," NE")
replace address = regexr(address," N W$"," NW")

#delimit ;
local placenames "ESSEX SURREY SOMERSET HOXTON CLERKENWELL SOUTHWARK SHOREDITCH ISLINGTON CAMBERWELL EDMONTON STEPNEY GREENWICH
					WOOLWICH LEWISHAM RICHMOND GRAVESEND MIDDLESEX SUSSEX CORNWALL NORFOLK WILTSHIRE DORSET MERIONETHSHIRE BARBICAN
					ANERLEY CHELMSFORD TOTTENHAM CHESHUNT FINSBURY COWCROSS PADDINGTON STRATFORD BASINGSTOKE BLACKFRIARS DARTFORD CARDIFF
					WINDSOR LIMEHOUSE PORTSMOUTH MITCHAM ALDGATE VAUXHALL HAYMARKET NUNHEAD WAPPING KNIGHTSBRIDGE RADCLIFFE BARNSBURY
					HAGGERSTON GLOUCESTERSHIRE HAMMERSMITH GLOUCESTERSHIRE LEICESTER";
#delimit cr
					
foreach place of local placenames {
	replace address = regexr(address," `place'$",", `place'") if regexm(address,"[A-Z] `place'$")==1 
}

replace address = "JESSAMINE VILLA, CRESCENT RD, BRENTWOOD, GREAT WAKREN, ESSEX" if address == "MRS WELSTED, JESSAMINE VILLA, CRESCENT RD, BRENTWOOD, GREAT WAKREN, ESSEX"

* Split address into component parts
split address, parse(,) gen(add) limit(5)

* Clear numbers in 2nd and 3rd address field
foreach var of varlist add2 add3 {
	replace `var' = trim(`var')
	replace `var' = regexr(`var',"^[0-9]+[ ]","")
	replace `var' = regexr(`var',"^&[ ]","")
	replace `var' = regexr(`var',"^[0-9]+[\.]*[ ]","") /* Cases with number space number */
	replace `var' = regexr(`var',"^[0-9]+[A-Z][\.]*[ ]","")
	replace `var' = regexr(`var',"^[A-Z][ ]","")
	replace `var' = regexr(`var',"^[A-Z]\.[ ]","")
	replace `var' = trim(`var')
	replace `var' = regexr(`var',"^[0-9]+,[ ]","") /* Some addresses have comma following number */
	replace `var' = trim(`var')
	replace `var' = regexr(`var',"^[0-9]+/[0-9]+[ ]","") /* Clear fractions */
	replace `var' = regexr(`var',"^[0-9]+,[0-9]+/[0-9]+[ ]","")  /* Clear fractions with commas*/
	replace `var' = regexr(`var',"^[0-9]+-[0-9]+[ ]","") /* Clear `var' dash apt no */
}

foreach var of varlist add1 add2 add3 add4 add5 {
	qui replace `var' = trim(`var')
	qui replace `var' = regexr(`var'," ","") if regexm(`var',"^[A-Z][ ][A-Z]$")
	qui replace `var' = regexr(`var',"S	LUKES","ST LUKE")
	qui replace `var' = regexr(`var',"ST LUKES","ST LUKE")
	qui replace `var' = regexr(`var',"STLUKES","ST LUKE")
	qui replace `var' = regexr(`var',"CLKWELL","CLERKENWELL")
	qui replace `var' = regexr(`var',"BETH GREEN$","BETHNAL GREEN")
	qui replace `var' = regexr(`var',"BETH GR$","BETHNAL GREEN")
	qui replace `var' = regexr(`var',"OXFORDSH$","OXFORD")
	qui replace `var' = regexr(`var',"GLAMORGAN$","GLAMORGANSHIRE")
	qui replace `var' = regexr(`var',"BLACKFRIARS","BLACKFRIARS ROAD")
	qui replace `var' = regexr(`var',"BLACKFRIAR ROAD","BLACKFRIARS ROAD")
	qui replace `var' = regexr(`var',"BLACKFRIARS ROAD ROAD","BLACKFRIARS ROAD")
	qui replace `var' = regexr(`var',"SPITALFIELD$","SPITALFIELDS")
	
	* Standardize street prefixes
	qui replace `var' = regexr(`var',"^GT ","GREAT ")
	qui replace `var' = regexr(`var',"^UP ","UPPER ")
	qui replace `var' = regexr(`var',"^UPP ","UPPER ")
	qui replace `var' = regexr(`var',"^UPR ","UPPER ")
	qui replace `var' = regexr(`var'," UPR "," UPPER ")
	qui replace `var' = regexr(`var',"^STH ","SOUTH ")
	
	* Standardize street suffixes
	
	qui replace `var' = regexr(`var'," ST$"," STREET")
	qui replace `var' = regexr(`var'," RD$"," ROAD")
	qui replace `var' = regexr(`var'," CL$"," CLOSE")
	qui replace `var' = regexr(`var',"^CT ","COURT ")
	qui replace `var' = regexr(`var'," CT$"," COURT")
	qui replace `var' = regexr(`var'," CRESCT$"," CRESCENT")
	qui replace `var' = regexr(`var'," CR$"," CRESCENT")
	qui replace `var' = regexr(`var'," CRES$"," CRESCENT")
	qui replace `var' = regexr(`var'," COTTS$"," COTTAGES")
	qui replace `var' = regexr(`var'," CTTGES$"," COTTAGES")
	qui replace `var' = regexr(`var'," CTGE$"," COTTAGES")
	qui replace `var' = regexr(`var'," CTTAGE$"," COTTAGES")
	qui replace `var' = regexr(`var'," LN$"," LANE")
	qui replace `var' = regexr(`var'," YD$"," YARD")
	qui replace `var' = regexr(`var'," YD "," YARD ")
	qui replace `var' = regexr(`var'," PL$"," PLACE")
	qui replace `var' = regexr(`var'," PL "," PLACE ")
	qui replace `var' = regexr(`var'," PK$"," PARK")
	qui replace `var' = regexr(`var'," TERR$"," TERRACE")
	qui replace `var' = regexr(`var'," TER$"," TERRACE")
	qui replace `var' = regexr(`var'," TN$"," TOWN")
	qui replace `var' = regexr(`var'," GN$"," GREEN")
	qui replace `var' = regexr(`var'," GROVE$"," GR")
	qui replace `var' = regexr(`var'," GDNS "," GARDENS ")
	qui replace `var' = regexr(`var'," GDNS$"," GARDENS")
	qui replace `var' = regexr(`var'," GDRS$"," GARDENS")
	qui replace `var' = regexr(`var'," BAGS$"," BUILDINGS")
	qui replace `var' = regexr(`var'," BEGS$"," BUILDINGS")
	qui replace `var' = regexr(`var'," BD$"," BUILDINGS")
	qui replace `var' = regexr(`var'," BLG$"," BUILDINGS")
	qui replace `var' = regexr(`var'," BDG[:]*$"," BUILDINGS")
	qui replace `var' = regexr(`var'," BUILD$"," BUILDINGS")
	qui replace `var' = regexr(`var'," BDGS$"," BUILDINGS")
	qui replace `var' = regexr(`var'," BLDGS$"," BUILDINGS")
	qui replace `var' = regexr(`var'," BLDNGS$"," BUILDINGS")
	qui replace `var' = regexr(`var'," BUILDGS$"," BUILDINGS")
	qui replace `var' = regexr(`var'," BLDG$"," BUILDINGS")
	qui replace `var' = regexr(`var'," BLDGS$"," BUILDINGS")
	qui replace `var' = regexr(`var'," BDDGS$"," BUILDINGS")
	qui replace `var' = regexr(`var'," BGS$"," BUILDINGS")
	qui replace `var' = regexr(`var'," BLGS$"," BUILDINGS")
	qui replace `var' = regexr(`var'," SQ$"," SQUARE")
	qui replace `var' = regexr(`var'," SQ "," SQUARE ")
	qui replace `var' = regexr(`var'," SQR$"," SQUARE")
	qui replace `var' = regexr(`var'," SQRE$"," SQUARE")
	qui replace `var' = regexr(`var'," RD "," ROAD ")	
	qui replace `var' = regexr(`var'," ST BUILD"," STREET BUILD")
	qui replace `var' = regexr(`var'," WK$"," WALK")
}

* Extract postal district from address
local postalcode "E EC N NE NW S SE SW W WC"
gen postcode = ""
foreach var of varlist add1 add2 add3 add4 add5 {
	foreach code of local postalcode {
		qui replace postcode = "`code'" if `var' == "`code'"
		qui replace `var' = "" if `var' == "`code'"
		qui replace postcode = "`code'" if regexm(`var'," `code'$")
		qui replace `var' = regexr(`var'," `code'$","")
	}
	replace `var' = regexr(`var',"STAMFORD ST","STANFORD ST") if postcode=="EC"
	replace `var' = regexr(`var',"STANFORD ST","STAMFORD ST") if postcode== "SE"
}

* Remove identifier "Near" or "Nr" to separate place names
replace add3 = regexr(add3,"^NEAR ","")
replace add3 = regexr(add3,"^NR ","")
replace add5 = regexs(1) if regexm(add3,"[ ]NEAR[ ]([A-Z| ]+)$")==1 & add4!=""
replace add5 = regexs(1) if regexm(add3,"[ ]NR[ ]([A-Z| ]+)$")==1 & add4!=""
replace add4 = regexs(1) if regexm(add3,"[ ]NEAR[ ]([A-Z| ]+)$")==1 & add4==""
replace add4 = regexs(1) if regexm(add3,"[ ]NR[ ]([A-Z| ]+)$")==1 & add4==""
replace add3 = regexr(add3,"[ ]NEAR[ ][A-Z| ]+$","")
replace add3 = regexr(add3,"[ ]NR[ ][A-Z| ]+$","")
replace add2 = regexr(add2,"\(NEAR CHURCH\)","NEAR CHURCH")
replace add2 = regexr(add2,"\(NR CHURCH\)","NR CHURCH")
replace add2 = regexr(add2,"^NEAR ","")
replace add2 = regexr(add2," NEAR$","")
replace add2 = regexr(add2,"^NR ","")
replace add2 = regexr(add2," NR$","")
replace add4 = regexs(1) if regexm(add2,"[ ]NEAR[ ]([A-Z| ]+)$")==1 & add3!=""
replace add4 = regexs(1) if regexm(add2,"[ ]NR[ ]([A-Z| ]+)$")==1 & add3!=""
replace add3 = regexs(1) if regexm(add2,"[ ]NEAR[ ]([A-Z| ]+)$")==1 & add3==""
replace add3 = regexs(1) if regexm(add2,"[ ]NR[ ]([A-Z| ]+)$")==1 & add3==""
replace add2 = regexr(add2,"[ ]NEAR[ ][A-Z| ]+$","")
replace add2 = regexr(add2,"[ ]NR[ ][A-Z| ]+$","")
replace add1 = regexr(add1," NEAR$","")
replace add1 = regexr(add1,"^NEAR ","")
replace add1 = regexr(add1," NR$","")
replace add1 = regexr(add1,"^NR ","")
replace add3 = regexs(1) if regexm(add1,"[ ]NEAR[ ]([A-Z| ]+)$")==1 & add2!=""
replace add3 = regexs(1) if regexm(add1,"[ ]NR[ ]([A-Z| ]+)$")==1 & add2!=""
replace add2 = regexs(1) if regexm(add1,"[ ]NEAR[ ]([A-Z| ]+)$")==1 & add2==""
replace add2 = regexs(1) if regexm(add1,"[ ]NR[ ]([A-Z| ]+)$")==1 & add2==""
replace add1 = regexr(add1,"[ ]NEAR[ ][A-Z| ]+$","")
replace add1 = regexr(add1,"[ ]NR[ ][A-Z| ]+$","")

* Expand abbreviations
foreach var of varlist add1 add2 add3 add4 add5 {
	replace `var' = "ST PETER WALWORTH" if `var' == "WALWORTH"
	replace `var' = "HOXTON OLD TOWN" if `var' == "HOXTON"
	replace `var' = "HERTFORDSHIRE" if `var' == "HERTS"
	replace `var' = "BERKSHIRE" if `var' == "BERKS"
	replace `var' = "HAMPSHIRE" if `var' == "HANTS"
	replace `var' = "BUCKINGHAMSHIRE" if `var' == "BUCKS"
	replace `var' = "WILTSHIRE" if `var' == "WILTS"
	replace `var' = "ST LUKE" if `var' == "ST L"
	replace `var' = "MILE END OLD TOWN" if `var' == "MILE END"
	replace `var' = regexr(`var',"^S ","SOUTH ")
	replace `var' = regexr(`var',"^N ","NORTH ")
	replace `var' = regexr(`var',"^W ","WEST ")
	replace `var' = regexr(`var',"^E ","EAST ")
	replace `var' = regexr(`var',"^GT ","GREAT ")
	
* Eliminate punctuation
	replace `var' = regexr(`var',"^>","")

* Erase near
	replace `var' = "" if `var' == "NEAR" | `var' == "NR"
}

* Fill in missing info from repeated entries
foreach var of varlist add1 add2 add3 add4 add5 {
	replace `var' = "CLERKENWELL" if regexm(`var',"FARRINGTON")==1 & regexm(`var',"BUILDING")==1
}

* Move up missing fields

replace add2 = add3 if add2 ==""
replace add3 = "" if add2 ==add3
replace add3 = add4 if add3 == ""
replace add4 = "" if add3 == add4
replace add4 = add5 if add4 == ""
replace add5 = "" if add4 == add5

* Recombine address components

egen temp_add = concat(add1-add5), punct(,)
drop add1-add5
replace temp_add = regexr(temp_add,"(,)*$","")

forvalues n = 1(1)9 {
	replace temp_add = regexr(temp_add,"[ ]`n'",", `n'") if regexm(temp_add,"[A-Z][ ][0-9]") & regexm(temp_add,"NO [0-9]")==0
	replace temp_add = regexr(temp_add,"`n',","`n' ")
	replace temp_add = regexr(temp_add,"`n'-","`n' ") if regexm(temp_add,"[0-9]-[0-9]") == 0
	replace temp_add = regexr(temp_add,"`n'","`n' ") if regexm(temp_add,"`n'[A-Z]")
}
replace temp_add = subinstr(temp_add,"  "," ",.)

replace temp_add = regexr(temp_add,"SOUTHWALK BR ROAD","SOUTHWARK BRIDGE ROAD")
replace temp_add = regexr(temp_add,"BETHNAL,C$","BETHNAL GREEN")
replace temp_add = regexr(temp_add,"GT,BASTERN","GREAT EASTERN")
replace temp_add = regexr(temp_add,"OLD KENTH ROAD","OLD KENT ROAD")

replace temp_add = regexr(temp_add,",ALLEY"," ALLEY") 
replace temp_add = regexr(temp_add,"ALLEY ","ALLEY,") if regexm(temp_add,"ALLEY,") == 0 & regexm(temp_add,"[A-Z]ALLEY") == 0 & regexm(temp_add,"ALLEY STREET") == 0 & regexm(temp_add,"ALLEY COURT") == 0

replace temp_add = regexr(temp_add,",GARDENS"," GARDENS") 
replace temp_add = regexr(temp_add,"GARDENS ","GARDENS,") if regexm(temp_add,"GARDENS,") == 0 & regexm(temp_add,"GARDENS DWELLINGS") == 0 & regexm(temp_add,"GARDENS ROW") == 0 & regexm(temp_add,"GARDENS ESTATE") == 0

replace temp_add = regexr(temp_add,"LANE ","LANE,") if regexm(temp_add,"LANE,") == 0 & regexm(temp_add,"LANE BUILDINGS") == 0 & regexm(temp_add,"LANE STREET") == 0 & regexm(temp_add,"LANE BAKERY") == 0

replace temp_add = subinstr(temp_add," RD "," ROAD ",.)
replace temp_add = subinstr(temp_add,"ROAD ROAD","ROAD",.)
replace temp_add = subinstr(temp_add,"ROAD RAOD","ROAD",.)
replace temp_add = regexr(temp_add,"ROAD ","ROAD,") if regexm(temp_add,"ROAD,") == 0 & regexm(temp_add,"ROAD BUILDING") == 0 & regexm(temp_add,"[A-Z]ROAD") == 0 & regexm(temp_add,"ROAD EAST") == 0 & ///
	regexm(temp_add,"ROAD STREET") == 0 & regexm(temp_add,"ROAD BRIDGE") == 0 & regexm(temp_add,"ROAD SQUARE") == 0 & regexm(temp_add,"^ROAD") == 0 & regexm(temp_add,"ROAD HOUSE") == 0 & regexm(temp_add,"ROAD MEWS") == 0 & ///
	regexm(temp_add,"ROAD MANOR") == 0 & regexm(temp_add,"ROAD SCHOOL") == 0

replace temp_add = regexr(temp_add,"STREET"," STREET") if regexm(temp_add,"[A-Z]STREET")
replace temp_add = regexr(temp_add,"STREET ","STREET,") if ///
	regexm(temp_add,"STREET BUILD") == 0 & regexm(temp_add,"STREET ROAD") == 0 & regexm(temp_add,"STREET HILL") == 0 & regexm(temp_add,"STREET EAST") == 0 & regexm(temp_add,"STREET NORTH") == 0 & ///
	regexm(temp_add,"STREET SQUARE") == 0 & regexm(temp_add,"STREET HOSPITAL") == 0 & regexm(temp_add,"STREET WITHOUT") == 0

replace temp_add = regexr(temp_add,",WALK"," WALK") 
replace temp_add = regexr(temp_add,"WALK ","WALK,") if regexm(temp_add,"WALK,") == 0 & regexm(temp_add,"[A-Z]WALK") == 0 & regexm(temp_add,"WALK STREET") == 0 & regexm(temp_add,"WALK ROAD") == 0 & ///
	regexm(temp_add,"WALK PLACE") == 0 

split temp_add, parse(,) gen(add) limit(5)
keep stnum add_inprog add* postcode

sort add1 stnum add2-add5 postcode
save "$PROJ_PATH/processed/intermediate/hospitals/hosp_addresses_cleaned.dta", replace

**************************************
* Merge crosswalk files with addresses

**************************************

use "$PROJ_PATH/processed/intermediate/hospitals/hosp_addresses_cleaned.dta", clear

* Merge addresses with place name files
gen district_1 = ""
gen subdist_1 = ""
gen parish_1 = ""
gen county_1 = ""

gen district_2 = ""
gen subdist_2 = ""
gen parish_2 = ""
gen county_2 = ""

gen district_3 = ""
gen subdist_3 = ""
gen parish_3 = ""
gen county_3 = ""

gen cty1 = ""
gen cty2 = ""
gen cty3 = ""

foreach var of varlist district_1 subdist_1 parish_1 county_1 {
	replace `var' = "NO ADDRESS" if address == "NO ADDRESS"
	replace `var' = "READMISSION" if address == "READMISSION"
}

* Merge with county list
foreach var of varlist add1 add2 add3 add4 add5 {
	rename `var' county
	qui merge m:1 county using "$PROJ_PATH/processed/intermediate/geography/1881_county_list.dta", keep(1 3)
	replace cty1 = county if _merge == 3 & cty1 == ""
	replace cty2 = county if _merge == 3 & cty2 == "" & cty1 != "" & county != cty1
	replace cty3 = county if _merge == 3 & cty3 == "" & cty1 != "" & cty2 != "" & county != cty1 & county != cty2
	drop _merge
	rename county `var'
}	
unique address_orig

* Merge with district files
foreach var of varlist add1 add2 add3 add4 add5 {
	rename `var' district
	qui merge m:1 district using "$PROJ_PATH/processed/intermediate/geography/1881_distcty_crosswalk.dta", keep(1 3)
	replace _merge = 1 if _merge == 3 & ((county != cty1 & cty1!="") | (county != cty2 & cty2!="") | (county != cty3 & cty3!=""))
	replace district_1 = district if _merge == 3 & district_1 == ""
	replace district_2 = district if _merge == 3 & district_2 == "" & district_1!="" & district != district_1
	replace district_3 = district if _merge == 3 & district_3 == "" & district_2 != "" & district_1!="" & district != district_1 & district != district_2
	replace county_1 = county if _merge == 3 & county_1 == "" & district_1 == district
	replace county_2 = county if _merge == 3 & county_2 == "" & county_1!="" & district_2 == district
	replace county_3 = county if _merge == 3 & county_3 == "" & county_2 != "" & county_1!="" & district_3 == district
	drop _merge county
	rename district `var'
}

unique address_orig

* Merge with subdistrict files
foreach var of varlist add1 add2 add3 add4 add5 {
	rename `var' subdist
	qui merge m:1 subdist using "$PROJ_PATH/processed/intermediate/geography/1881_subdistcty_crosswalk.dta", keep(1 3)
	replace _merge = 1 if _merge == 3 & regexm(subdist," ROAD")==1 | regexm(subdist," STREET")==1		 
	replace _merge = 1 if _merge == 3 & ((county != cty1 & cty1!="") | (county != cty2 & cty2!="") | (county != cty3 & cty3!=""))
	
	replace subdist_1 = subdist if _merge == 3 & subdist_1 == "" & (district_1 == "" | district == district_1)
	replace district_1 = district if _merge == 3 & district_1 == ""
	replace subdist_2 = subdist if _merge == 3 & subdist_2 == "" & subdist!=subdist_1 & district_1!="" & (district_2 == "" | district == district_2)
	replace district_2 = district if _merge == 3 & district_2 == "" & district_1 != "" & district!=district_1
	replace subdist_3 = subdist if _merge == 3 & subdist_3 == "" & subdist!=subdist_1 & subdist!=subdist_2 & district_1!="" & district_2!="" & (district_3 == "" | district == district_3)
	replace district_3 = district if _merge == 3 & district_3 == "" & district_1 != "" & district_2 != "" & district!=district_1 & district!=district_2
	
	replace county_1 = county if _merge ==3 & subdist==subdist_1
	replace county_2 = county if _merge ==3 & subdist==subdist_2
	replace county_3 = county if _merge ==3 & subdist==subdist_3
	drop _merge district county
	rename subdist `var'
}

* Merge with subdistrict files (London only)
foreach var of varlist add1 add2 add3 add4 add5 {
	rename `var' subdist
	qui merge m:1 subdist using "$PROJ_PATH/processed/intermediate/geography/1881_subdistcty_london.dta", keep(1 3)
	replace _merge = 1 if _merge == 3 & regexm(subdist," ROAD")==1 | regexm(subdist," STREET")==1		 
	replace _merge = 1 if _merge == 3 & ((county != cty1 & cty1!="") | (county != cty2 & cty2!="") | (county != cty3 & cty3!=""))
	
	replace subdist_1 = subdist if _merge == 3 & subdist_1 == "" & (district_1 == "" | district == district_1)
	replace district_1 = district if _merge == 3 & district_1 == ""
	replace subdist_2 = subdist if _merge == 3 & subdist_2 == "" & subdist!=subdist_1 & district_1!="" & (district_2 == "" | district == district_2)
	replace district_2 = district if _merge == 3 & district_2 == "" & district_1 != "" & district!=district_1
	replace subdist_3 = subdist if _merge == 3 & subdist_3 == "" & subdist!=subdist_1 & subdist!=subdist_2 & district_1!="" & district_2!="" & (district_3 == "" | district == district_3)
	replace district_3 = district if _merge == 3 & district_3 == "" & district_1 != "" & district_2 != "" & district!=district_1 & district!=district_2
	
	replace county_1 = county if _merge ==3 & subdist==subdist_1
	replace county_2 = county if _merge ==3 & subdist==subdist_2
	replace county_3 = county if _merge ==3 & subdist==subdist_3
	drop _merge district county
	rename subdist `var'
}
unique address_orig

* Merge with parish-district-county crosswalk file
foreach var of varlist add1 add2 add3 add4 add5 {
	rename `var' parish
	qui merge m:1 parish using "$PROJ_PATH/processed/intermediate/geography/1881_pardistcty_crosswalk.dta", keep(1 3)
	replace _merge = 1 if _merge == 3 & regexm(parish," ROAD")==1 | regexm(parish," STREET")==1	
	replace _merge = 1 if _merge == 3 & ((county != cty1 & cty1!="") | (county != cty2 & cty2!="") | (county != cty3 & cty3!=""))
	
	replace parish_1 = parish if _merge == 3 & (district == district_1 | district_1 == "")
	replace district_1 = district if _merge == 3 & parish_1 == parish 
	replace county_1 = county if _merge == 3 & parish_1 == parish 
	
	replace parish_2 = parish if _merge == 3 & district_1 != "" & (district == district_2 | district_2 == "") & parish!=parish_1
	replace district_2 = district if _merge == 3 & parish_2 == parish 
	replace county_2 = county if _merge == 3 & parish_2 == parish 

	replace parish_3 = parish if _merge == 3 & district_1 != "" & district_2 != "" & (district == district_3 | district_3 == "") & parish!=parish_1 & parish != parish_2
	replace district_3 = district if _merge == 3 & parish_3 == parish 
	replace county_3 = county if _merge == 3 & parish_3 == parish 
	
	drop _merge district county
	rename parish `var'
}

* Merge with parish-district-county crosswalk file (London only)
foreach var of varlist add1 add2 add3 add4 add5 {
	rename `var' parish
	qui merge m:1 parish using "$PROJ_PATH/processed/intermediate/geography/1881_pardistcty_london.dta", keep(1 3)
	replace _merge = 1 if _merge == 3 & regexm(parish," ROAD")==1 | regexm(parish," STREET")==1	
	replace _merge = 1 if _merge == 3 & ((county != cty1 & cty1!="") | (county != cty2 & cty2!="") | (county != cty3 & cty3!=""))
	
	replace parish_1 = parish if _merge == 3 & (district == district_1 | district_1 == "")
	replace district_1 = district if _merge == 3 & parish_1 == parish 
	replace county_1 = county if _merge == 3 & parish_1 == parish 
	
	replace parish_2 = parish if _merge == 3 & district_1 != "" & (district == district_2 | district_2 == "") & parish!=parish_1
	replace district_2 = district if _merge == 3 & parish_2 == parish 
	replace county_2 = county if _merge == 3 & parish_2 == parish 

	replace parish_3 = parish if _merge == 3 & district_1 != "" & district_2 != "" & (district == district_3 | district_3 == "") & parish!=parish_1 & parish != parish_2
	replace district_3 = district if _merge == 3 & parish_3 == parish 
	replace county_3 = county if _merge == 3 & parish_3 == parish 
	
	drop _merge district county
	rename parish `var'
}

unique address_orig

* Merge first component with 1891 street index file
gen oddnum = mod(stnum,2)
rename add1 street

joinby street using "$PROJ_PATH/processed/intermediate/geography/1891_street_district_crosswalk.dta", unmatched(master)

gen match_oddev = ((oddnum == 1 & odd==1) | (oddnum==0 & even==1))
gen match_add = (stnum>=min_number & stnum<=max_number & match_oddev) /* Matched to street index in address number falls in max/min range from index and matches even/odd */

egen tot_match = total(match_add), by(address_orig)
drop if tot_match>0 & match_add == 0 /* Drop observations that match name but not number if at least one number matches */
drop min_number max_number odd even oddnum match_oddev match_add tot_match
duplicates drop
egen tot_match = count(address_orig), by(address_orig)
replace index_dist = "" if index_dist != district_1 & tot_match>1 /* Drop potential district name if multiple matches */
drop tot_match
duplicates drop
gen temp = (index_dist!="")
egen temp2 = count(address_orig), by(address_orig)
egen temp3 = total(temp), by(address_orig)
unique address_orig
drop if temp==0 & temp2>1
unique address_orig	
drop temp* _merge

rename index_dist district
qui merge m:1 district using "$PROJ_PATH/processed/intermediate/geography/1881_distcty_crosswalk.dta", keep(1 3)
replace district = "" if _merge ==3 & ((county != cty1 & cty1!="") | (county != cty2 & cty2!="") | (county != cty3 & cty3!=""))
rename district index_dist

replace district_1 = index_dist if district_1==""
replace district_2 = index_dist if district_2=="" & district_1 !="" & district_1 != index_dist
replace district_3 = index_dist if district_3=="" & district_2 !="" & district_1 !="" & district_1 != index_dist & district_2 != index_dist

replace county_1 = county if _merge==3 & district_1 == index_dist
replace county_2 = county if _merge==3 & district_2 == index_dist
replace county_3 = county if _merge==3 & district_3 == index_dist

drop _merge county

* Merge first and second components with 1891 street intersect file
gen oddnum = mod(stnum,2)
rename add2 intersect
joinby street intersect using "$PROJ_PATH/processed/intermediate/geography/1891_intersect_district.dta", unmatched(master)

gen match_oddev = ((oddnum==1 & odd==1) | (oddnum==0 & even==1))
gen match_add = (stnum>=min_number & stnum<=max_number & match_oddev) /* Matched to street index in address number falls in max/min range from index and matches even/odd */

egen tot_match = total(match_add), by(address_orig)
drop if tot_match>0 & match_add == 0 /* Drop observations that match name but not number if at least one number matches */
drop min_number max_number odd even oddnum match_oddev match_add tot_match
duplicates drop
egen tot_match = count(address_orig), by(address_orig)
replace intersect_dist = "" if intersect_dist != district_1 & tot_match>1 /* Drop potential district name if multiple matches */
drop tot_match
duplicates drop
gen temp = (intersect_dist!="")
egen temp2 = count(address_orig), by(address_orig)
egen temp3 = total(temp), by(address_orig)
unique address_orig
tab temp3 if temp2>1
drop if temp==0 & temp2>1
unique address_orig
drop temp* _merge

rename intersect_dist district
qui merge m:1 district using "$PROJ_PATH/processed/intermediate/geography/1881_distcty_crosswalk.dta", keep(1 3)
replace district = "" if _merge ==3 & ((county != cty1 & cty1!="") | (county != cty2 & cty2!="") | (county != cty3 & cty3!=""))
rename district intersect_dist

replace district_1 = intersect_dist if district_1==""
replace district_2 = intersect_dist if district_2=="" & district_1 !="" & district_1 != intersect_dist
replace district_3 = intersect_dist if district_3=="" & district_2 !="" & district_1 !="" & district_1 != intersect_dist & district_2 != intersect_dist

replace county_1 = county if _merge==3 & district_1 == intersect_dist
replace county_2 = county if _merge==3 & district_2 == intersect_dist
replace county_3 = county if _merge==3 & district_3 == intersect_dist

drop _merge county
count

* Merge with 1891 street intersect using second and third part of address string
rename street add1
rename intersect street
rename add3 intersect
rename intersect_dist intersect_dist12

joinby street intersect using "$PROJ_PATH/processed/intermediate/geography/1891_intersect_district.dta", unmatched(master)

gen match_add = (stnum>=min_number & stnum<=max_number) /* Matched to street index in address number falls in max/min range from index and matches even/odd */

egen tot_match = total(match_add), by(address_orig)
drop if tot_match>0 & match_add == 0 /* Drop observations that match name but not number if at least one number matches */
drop min_number max_number odd even match_add tot_match
duplicates drop
egen tot_match = count(address_orig), by(address_orig)
replace intersect_dist = "" if intersect_dist != district_1 & tot_match>1 /* Drop potential district name if multiple matches */
drop tot_match
duplicates drop
gen temp = (intersect_dist!="")
egen temp2 = count(address_orig), by(address_orig)
egen temp3 = total(temp), by(address_orig)
unique address_orig
tab temp3 if temp2>1
drop if temp==0 & temp2>1
unique address_orig
drop temp* _merge

rename intersect_dist district
qui merge m:1 district using "$PROJ_PATH/processed/intermediate/geography/1881_distcty_crosswalk.dta", keep(1 3)
replace district = "" if _merge ==3 & ((county != cty1 & cty1!="") | (county != cty2 & cty2!="") | (county != cty3 & cty3!=""))
rename district intersect_dist

replace district_1 = intersect_dist if district_1==""
replace district_2 = intersect_dist if district_2=="" & district_1 !="" & district_1 != intersect_dist
replace district_3 = intersect_dist if district_3=="" & district_2 !="" & district_1 !="" & district_1 != intersect_dist & district_2 != intersect_dist

replace county_1 = county if _merge==3 & district_1 == intersect_dist
replace county_2 = county if _merge==3 & district_2 == intersect_dist
replace county_3 = county if _merge==3 & district_3 == intersect_dist

drop _merge county

* Merge with 1891 street intersect using first and second part of address string reversed
rename intersect add3
rename add1 intersect
rename intersect_dist intersect_dist23

joinby street intersect using "$PROJ_PATH/processed/intermediate/geography/1891_intersect_district.dta", unmatched(master)

gen match_add = (stnum>=min_number & stnum<=max_number) /* Matched to street index in address number falls in max/min range from index and matches even/odd */

egen tot_match = total(match_add), by(address_orig)
drop if tot_match>0 & match_add == 0 /* Drop observations that match name but not number if at least one number matches */
drop min_number max_number odd even match_add tot_match
duplicates drop
egen tot_match = count(address_orig), by(address_orig)
replace intersect_dist = "" if intersect_dist != district_1 & tot_match>1 /* Drop potential district name if multiple matches */
drop tot_match
duplicates drop
gen temp = (intersect_dist!="")
egen temp2 = count(address_orig), by(address_orig)
egen temp3 = total(temp), by(address_orig)
unique address_orig
tab temp3 if temp2>1
drop if temp==0 & temp2>1
unique address_orig
drop temp* _merge

rename intersect_dist district
qui merge m:1 district using "$PROJ_PATH/processed/intermediate/geography/1881_distcty_crosswalk.dta", keep(1 3)
replace district = "" if _merge ==3 & ((county != cty1 & cty1!="") | (county != cty2 & cty2!="") | (county != cty3 & cty3!=""))
rename district intersect_dist

replace district_1 = intersect_dist if district_1==""
replace district_2 = intersect_dist if district_2=="" & district_1 !="" & district_1 != intersect_dist
replace district_3 = intersect_dist if district_3=="" & district_2 !="" & district_1 !="" & district_1 != intersect_dist & district_2 != intersect_dist

replace county_1 = county if _merge==3 & district_1 == intersect_dist
replace county_2 = county if _merge==3 & district_2 == intersect_dist
replace county_3 = county if _merge==3 & district_3 == intersect_dist

drop _merge county

* Merge with 1891 street intersect using second and third part of address string reversed
rename intersect add1
rename street intersect
rename add3 street
rename intersect_dist intersect_dist21

joinby street intersect using "$PROJ_PATH/processed/intermediate/geography/1891_intersect_district.dta", unmatched(master)

gen match_add = (stnum>=min_number & stnum<=max_number) /* Matched to street index in address number falls in max/min range from index and matches even/odd */

egen tot_match = total(match_add), by(address_orig)
drop if tot_match>0 & match_add == 0 /* Drop observations that match name but not number if at least one number matches */
drop min_number max_number odd even match_add tot_match
duplicates drop
egen tot_match = count(address_orig), by(address_orig)
replace intersect_dist = "" if intersect_dist != district_1 & tot_match>1 /* Drop potential district name if multiple matches */
drop tot_match
duplicates drop
gen temp = (intersect_dist!="")
egen temp2 = count(address_orig), by(address_orig)
egen temp3 = total(temp), by(address_orig)
unique address_orig
tab temp3 if temp2>1
drop if temp==0 & temp2>1
unique address_orig
drop temp* _merge

rename intersect_dist district
qui merge m:1 district using "$PROJ_PATH/processed/intermediate/geography/1881_distcty_crosswalk.dta", keep(1 3)
replace district = "" if _merge ==3 & ((county != cty1 & cty1!="") | (county != cty2 & cty2!="") | (county != cty3 & cty3!=""))
rename district intersect_dist

replace district_1 = intersect_dist if district_1==""
replace district_2 = intersect_dist if district_2=="" & district_1 !="" & district_1 != intersect_dist
replace district_3 = intersect_dist if district_3=="" & district_2 !="" & district_1 !="" & district_1 != intersect_dist & district_2 != intersect_dist

replace county_1 = county if _merge==3 & district_1 == intersect_dist
replace county_2 = county if _merge==3 & district_2 == intersect_dist
replace county_3 = county if _merge==3 & district_3 == intersect_dist

drop _merge county
rename intersect_dist intersect_dist32
count

* Merge second component with 1891 street index file
rename street add3
rename intersect add2

gen oddnum = mod(stnum,2)
rename add2 street

joinby street using "$PROJ_PATH/processed/intermediate/geography/1891_street_district_crosswalk.dta", unmatched(master)

gen match_oddev = ((oddnum==1 & odd==1) | (oddnum==0 & even==1))
gen match_add = (stnum>=min_number & stnum<=max_number & match_oddev) /* Matched to street index in address number falls in max/min range from index and matches even/odd */

egen tot_match = total(match_add), by(address_orig)
drop if tot_match>0 & match_add == 0 /* Drop observations that match name but not number if at least one number matches */
drop min_number max_number odd even oddnum match_oddev match_add tot_match
duplicates drop
egen tot_match = count(address_orig), by(address_orig)
replace index_dist = "" if index_dist != district_1 & tot_match>1 /* Drop potential district name if multiple matches */
drop tot_match
duplicates drop
gen temp = (index_dist!="")
egen temp2 = count(address_orig), by(address_orig)
egen temp3 = total(temp), by(address_orig)
unique address_orig
drop if temp==0 & temp2>1
unique address_orig	
drop temp* _merge

rename index_dist district
qui merge m:1 district using "$PROJ_PATH/processed/intermediate/geography/1881_distcty_crosswalk.dta", keep(1 3)
replace district = "" if _merge ==3 & ((county != cty1 & cty1!="") | (county != cty2 & cty2!="") | (county != cty3 & cty3!=""))
rename district index_dist

replace district_1 = index_dist if district_1==""
replace district_2 = index_dist if district_2=="" & district_1 !="" & district_1 != index_dist
replace district_3 = index_dist if district_3=="" & district_2 !="" & district_1 !="" & district_1 != index_dist & district_2 != index_dist

replace county_1 = county if _merge==3 & district_1 == index_dist
replace county_2 = county if _merge==3 & district_2 == index_dist
replace county_3 = county if _merge==3 & district_3 == index_dist

drop _merge county

* Merge third component with 1891 street index file
rename street add2

gen oddnum = mod(stnum,2)
rename add3 street

joinby street using "$PROJ_PATH/processed/intermediate/geography/1891_street_district_crosswalk.dta", unmatched(master)

gen match_oddev = ((oddnum==1 & odd==1) | (oddnum==0 & even==1))
gen match_add = (stnum>=min_number & stnum<=max_number & match_oddev) /* Matched to street index in address number falls in max/min range from index and matches even/odd */

egen tot_match = total(match_add), by(address_orig)
drop if tot_match>0 & match_add == 0 /* Drop observations that match name but not number if at least one number matches */
drop min_number max_number odd even oddnum match_oddev match_add tot_match 
duplicates drop
egen tot_match = count(address_orig), by(address_orig)
replace index_dist = "" if index_dist != district_1 & tot_match>1 /* Drop potential district name if multiple matches */
drop tot_match
duplicates drop
gen temp = (index_dist!="")
egen temp2 = count(address_orig), by(address_orig)
egen temp3 = total(temp), by(address_orig)
unique address_orig
drop if temp==0 & temp2>1
unique address_orig	
drop temp* _merge

rename index_dist district
qui merge m:1 district using "$PROJ_PATH/processed/intermediate/geography/1881_distcty_crosswalk.dta", keep(1 3)
replace district = "" if _merge ==3 & ((county != cty1 & cty1!="") | (county != cty2 & cty2!="") | (county != cty3 & cty3!=""))
rename district index_dist

replace district_1 = index_dist if district_1==""
replace district_2 = index_dist if district_2=="" & district_1 !="" & district_1 != index_dist
replace district_3 = index_dist if district_3=="" & district_2 !="" & district_1 !="" & district_1 != index_dist & district_2 != index_dist

replace county_1 = county if _merge==3 & district_1 == index_dist
replace county_2 = county if _merge==3 & district_2 == index_dist
replace county_3 = county if _merge==3 & district_3 == index_dist

drop _merge county

* Merge with 1881 street index file (first address component)
rename street add3
rename add1 street
joinby street using "$PROJ_PATH/processed/intermediate/geography/1881_street_district_crosswalk.dta", unmatched(master)

gen match_add = (stnum>=min_number & stnum<=max_number) /* Matched to street index in address number falls in max/min range from index and matches even/odd */
egen tot_match = total(match_add), by(address_orig)

unique address_orig
drop if tot_match>0 & match_add == 0 /* Drop observations that match name but not number if at least one number matches */
unique address_orig
drop min_number max_number match_add tot_match 
duplicates drop
egen tot_match = count(address_orig), by(address_orig)
replace index81_subdist = "" if index81_dist != district_1 & tot_match>1
replace index81_parish = "" if index81_dist != district_1 & tot_match>1
replace index81_cty = "" if index81_dist != district_1 & tot_match>1 
replace index81_dist = "" if index81_dist != district_1 & tot_match>1 /* Drop potential district name if multiple matches */
drop tot_match
duplicates drop
gen temp = (index81_dist !="")
egen temp2 = count(address_orig), by(address_orig)
egen temp3 = total(temp), by(address_orig)
unique address_orig
tab temp3 if temp2>1
drop if temp==0 & temp2>1
unique address_orig
drop temp* _merge

egen temp = count(address_orig), by(address_orig)
replace index81_parish = "" if temp>1
replace index81_subdist = "" if temp>1
drop temp
duplicates drop

replace district_1 = index81_dist if district_1==""
replace district_2 = index81_dist if district_2=="" & district_1 !="" & district_1 != index81_dist 
replace district_3 = index81_dist if district_3=="" & district_2 !="" & district_1 !="" & district_1 != index81_dist & district_2 != index81_dist 

replace county_1 = index81_cty if district_1 == index81_dist 
replace county_2 = index81_cty if district_2 == index81_dist 
replace county_3 = index81_cty if district_3 == index81_dist 

replace subdist_1 = index81_subdist if district_1 == index81_dist 
replace subdist_2 = index81_subdist if district_2 == index81_dist  
replace subdist_3 = index81_subdist if district_3 == index81_dist

replace parish_1 = index81_parish if district_1 == index81_dist 
replace parish_2 = index81_parish if district_2 == index81_dist 
replace parish_3 = index81_parish if district_3 == index81_dist

drop index81_subdist index81_dist index81_parish index81_cty

* Merge with 1881 street index file (second address component)
rename street add1
rename add2 street
joinby street using "$PROJ_PATH/processed/intermediate/geography/1881_street_district_crosswalk.dta", unmatched(master) 

unique address_orig
drop min_number max_number 
duplicates drop
egen tot_match = count(address_orig), by(address_orig)
replace index81_subdist = "" if index81_dist != district_1 & tot_match>1
replace index81_parish = "" if index81_dist != district_1 & tot_match>1
replace index81_cty = "" if index81_dist != district_1 & tot_match>1 
replace index81_dist = "" if index81_dist != district_1 & tot_match>1 /* Drop potential district name if multiple matches */
drop tot_match
duplicates drop
gen temp = (index81_dist !="")
egen temp2 = count(address_orig), by(address_orig)
egen temp3 = total(temp), by(address_orig)
unique address_orig
tab temp3 if temp2>1
drop if temp==0 & temp2>1
unique address_orig
drop temp* _merge

egen temp = count(address_orig), by(address_orig)
replace index81_parish = "" if temp>1
replace index81_subdist = "" if temp>1
drop temp
duplicates drop

replace district_1 = index81_dist if district_1==""
replace district_2 = index81_dist if district_2=="" & district_1 !="" & district_1 != index81_dist 
replace district_3 = index81_dist if district_3=="" & district_2 !="" & district_1 !="" & district_1 != index81_dist & district_2 != index81_dist 

replace county_1 = index81_cty if district_1 == index81_dist 
replace county_2 = index81_cty if district_2 == index81_dist 
replace county_3 = index81_cty if district_3 == index81_dist 

replace subdist_1 = index81_subdist if district_1 == index81_dist 
replace subdist_2 = index81_subdist if district_2 == index81_dist 
replace subdist_3 = index81_subdist if district_3 == index81_dist 

replace parish_1 = index81_parish if district_1 == index81_dist 
replace parish_2 = index81_parish if district_2 == index81_dist 
replace parish_3 = index81_parish if district_3 == index81_dist  

drop index81_subdist index81_dist index81_parish index81_cty

* Merge with 1881 street index file (third address component)
rename street add2
rename add3 street
joinby street using "$PROJ_PATH/processed/intermediate/geography/1881_street_district_crosswalk.dta", unmatched(master)

unique address_orig
drop min_number max_number 
duplicates drop
egen tot_match = count(address_orig), by(address_orig)
replace index81_subdist = "" if index81_dist != district_1 & tot_match>1
replace index81_parish = "" if index81_dist != district_1 & tot_match>1
replace index81_cty = "" if index81_dist != district_1 & tot_match>1 
replace index81_dist = "" if index81_dist != district_1 & tot_match>1 /* Drop potential district name if multiple matches */
drop tot_match
duplicates drop
gen temp = (index81_dist !="")
egen temp2 = count(address_orig), by(address_orig)
egen temp3 = total(temp), by(address_orig)
unique address_orig
tab temp3 if temp2>1
drop if temp==0 & temp2>1
unique address_orig
drop temp* _merge

egen temp = count(address_orig), by(address_orig)
replace index81_parish = "" if temp>1
replace index81_subdist = "" if temp>1
drop temp
duplicates drop

replace district_1 = index81_dist if district_1==""
replace district_2 = index81_dist if district_2=="" & district_1 !="" & district_1 != index81_dist 
replace district_3 = index81_dist if district_3=="" & district_2 !="" & district_1 !="" & district_1 != index81_dist & district_2 != index81_dist 

replace county_1 = index81_cty if district_1 == index81_dist 
replace county_2 = index81_cty if district_2 == index81_dist 
replace county_3 = index81_cty if district_3 == index81_dist 

replace subdist_1 = index81_subdist if district_1 == index81_dist 
replace subdist_2 = index81_subdist if district_2 == index81_dist 
replace subdist_3 = index81_subdist if district_3 == index81_dist

replace parish_1 = index81_parish if district_1 == index81_dist 
replace parish_2 = index81_parish if district_2 == index81_dist 
replace parish_3 = index81_parish if district_3 == index81_dist 

rename street add3

drop index81_subdist index81_dist index81_parish index81_cty



// Match addresses against street names in London street index in 1881 census

tempfile addresses
save `addresses', replace

keep if district_1 == ""
drop if cty1 != "" & cty1 != "MIDDLESEX" & cty1 != "KENT" & cty1 !="SURREY" & cty1 !="ESSEX" & cty1 != "HERTFORDSHIRE"

keep address_orig address add1-add5 cty1
rename add1 street
joinby street using "$PROJ_PATH/processed/intermediate/geography/1881_street_district_crosswalk.dta"

unique address_orig
drop min_number max_number 
duplicates drop

drop if index81_cty != cty1 & cty1!=""
keep address_orig address index81*

tempfile street1
save `street1', replace

* Merge with 1881 street index file (second address component)
use `addresses', clear

keep if district_1 == ""
drop if cty1 != "" & cty1 != "MIDDLESEX" & cty1 != "KENT" & cty1 !="SURREY" & cty1 !="ESSEX" & cty1 != "HERTFORDSHIRE"

keep address_orig address add1-add5 cty1

rename add2 street
joinby street using "$PROJ_PATH/processed/intermediate/geography/1881_street_district_crosswalk.dta"

unique address_orig
drop min_number max_number 
duplicates drop

drop if index81_cty != cty1 & cty1!=""
keep address_orig address index81* 
sort address_orig address index81_parish index81_dist index81_subdist index81_cty

tempfile street2
save `street2', replace

* Merge with 1881 street index file (second address component)
use `addresses', clear

keep if district_1 == ""
drop if cty1 != "" & cty1 != "MIDDLESEX" & cty1 != "KENT" & cty1 !="SURREY" & cty1 !="ESSEX" & cty1 != "HERTFORDSHIRE"

keep address_orig address add1-add5 cty1

rename add3 street
joinby street using "$PROJ_PATH/processed/intermediate/geography/1881_street_district_crosswalk.dta"

unique address_orig
drop min_number max_number 
duplicates drop

drop if index81_cty != cty1 & cty1!=""
keep address_orig address index81*

tempfile street3
save `street3', replace

use `street1', clear

joinby address_orig address index81_parish index81_dist index81_subdist index81_cty using `street2'

egen temp = count(address_orig), by(address_orig)
replace index81_parish = "" if temp>1
replace index81_subdist = "" if temp>1
drop temp
duplicates drop
sort address_orig address index81_parish index81_dist index81_subdist index81_cty

tempfile street12
save `street12', replace

use `street2', clear

joinby address_orig address index81_parish index81_dist index81_subdist index81_cty using `street3'

egen temp = count(address_orig), by(address_orig)
replace index81_parish = "" if temp>1
replace index81_subdist = "" if temp>1
drop temp
duplicates drop

tempfile street23
save `street23', replace

use `street1', clear

joinby address_orig address index81_parish index81_dist index81_subdist index81_cty using `street3'

egen temp = count(address_orig), by(address_orig)
replace index81_parish = "" if temp>1
replace index81_subdist = "" if temp>1
drop temp
duplicates drop

tempfile street13
save `street13', replace

use `street12', clear
append using `street13'
append using `street23'
duplicates drop

egen tot_match = count(address_orig), by(address_orig)
drop if tot_match > 1
drop tot_match

tempfile intersect
save `intersect', replace

use `addresses', clear
merge 1:1 address_orig address using `intersect'

replace district_1 = index81_dist if district_1==""
replace district_2 = index81_dist if district_2=="" & district_1 !="" & district_1 != index81_dist 
replace district_3 = index81_dist if district_3=="" & district_2 !="" & district_1 !="" & district_1 != index81_dist & district_2 != index81_dist 

replace county_1 = index81_cty if district_1 == index81_dist 
replace county_2 = index81_cty if district_2 == index81_dist
replace county_3 = index81_cty if district_3 == index81_dist

replace subdist_1 = index81_subdist if district_1 == index81_dist 
replace subdist_2 = index81_subdist if district_2 == index81_dist
replace subdist_3 = index81_subdist if district_3 == index81_dist 

replace parish_1 = index81_parish if district_1 == index81_dist 
replace parish_2 = index81_parish if district_2 == index81_dist 
replace parish_3 = index81_parish if district_3 == index81_dist

drop _merge
drop index81_subdist index81_dist index81_parish index81_cty



// Redo subdistrict matches with "Road" and "Street" names
// Merge with subdistrict files (London only)

foreach var of varlist add1 add2 add3 add4 add5 {
	rename `var' subdist
	qui merge m:1 subdist using "$PROJ_PATH/processed/intermediate/geography/1881_subdistcty_london.dta", keep(1 3)
	drop if _merge == 2
	replace _merge = 1 if _merge == 3 & ((county != cty1 & cty1!="") | (county != cty2 & cty2!="") | (county != cty3 & cty3!=""))
	
	replace subdist_1 = subdist if _merge == 3 & subdist_1 == "" & (district_1 == "" | district == district_1)
	replace district_1 = district if _merge == 3 & district_1 == ""
	replace subdist_2 = subdist if _merge == 3 & subdist_2 == "" & subdist!=subdist_1 & district_1!="" & (district_2 == "" | district == district_2)
	replace district_2 = district if _merge == 3 & district_2 == "" & district_1 != "" & district!=district_1
	replace subdist_3 = subdist if _merge == 3 & subdist_3 == "" & subdist!=subdist_1 & subdist!=subdist_2 & district_1!="" & district_2!="" & (district_3 == "" | district == district_3)
	replace district_3 = district if _merge == 3 & district_3 == "" & district_1 != "" & district_2 != "" & district!=district_1 & district!=district_2
	
	replace county_1 = county if _merge ==3 & subdist==subdist_1
	replace county_2 = county if _merge ==3 & subdist==subdist_2
	replace county_3 = county if _merge ==3 & subdist==subdist_3
	* replace subdist = "" if _merge == 3
	drop _merge district county
	rename subdist `var'
}

* Drop false matches in cases where matched county is different from county name given in address

replace district_1 = district_2 if cty1== county_2 & cty1!="" & cty1!=county_1
replace subdist_1 = subdist_2 if cty1== county_2 & cty1!="" & cty1!=county_1
replace parish_1 = parish_2 if cty1== county_2 & cty1!="" & cty1!=county_1
replace county_1 = county_2 if cty1== county_2 & cty1!="" & cty1!=county_1

replace district_2 = "" if district_1==district_2 & subdist_1==subdist_2 & parish_1==parish_2 & county_1 == county_2
replace subdist_2 = "" if district_1==district_2 & subdist_1==subdist_2 & parish_1==parish_2 & county_1 == county_2
replace parish_2 = "" if district_1==district_2 & subdist_1==subdist_2 & parish_1==parish_2 & county_1 == county_2
replace county_2 = "" if district_1==district_2 & subdist_1==subdist_2 & parish_1==parish_2 & county_1 == county_2

replace district_1 = district_3 if cty1 == county_3 & cty1!="" & cty1!=county_1
replace subdist_1 = subdist_3 if cty1== county_3 & cty1!="" & cty1!=county_1
replace parish_1 = parish_3 if cty1== county_3 & cty1!="" & cty1!=county_1
replace county_1 = county_3 if cty1 == county_3 & cty1!="" & cty1!=county_1

replace district_3 = "" if district_1==district_3 & subdist_1==subdist_3 & parish_1==parish_3 & county_1 == county_3
replace subdist_3 = "" if district_1==district_3 & subdist_1==subdist_3 & parish_1==parish_3 & county_1 == county_3
replace parish_3 = "" if district_1==district_3 & subdist_1==subdist_3 & parish_1==parish_3 & county_1 == county_3
replace county_3 = "" if district_1==district_3 & subdist_1==subdist_3 & parish_1==parish_3 & county_1 == county_3

replace district_1 = "" if county_1 != cty1 & cty1!=""
replace subdist_1 = "" if county_1 != cty1 & cty1!=""
replace parish_1 = "" if county_1 != cty1 & cty1!=""
replace county_1 = cty1 if county_1 != cty1 & cty1!=""

count

* Add county information from parish-county crosswalk 
foreach var of varlist add1 add2 add3 add4 add5 {
	rename `var' parish
	qui merge m:1 parish using "$PROJ_PATH/processed/intermediate/geography/1881_parcty_london.dta", keep(1 3)

	replace parish_1 = parish if _merge == 3 & parish_1 == "" & district_1 == "" & county_1 == ""
	replace parish_2 = parish if _merge == 3 & parish_2 == "" & district_1 != "" & district_2 == "" & parish != parish_1 & county_2 == ""
	replace parish_3 = parish if _merge == 3 & parish_3 == "" & district_1 != "" & district_2 != "" & district_3 == "" & parish != parish_1 & parish != parish_2 & county_3 == ""
	
	replace county_1 = county if _merge ==3 & parish_1 == parish & district_1 == "" & county_1 == "" 
	replace county_2 = county if _merge ==3 & parish_2 == parish & district_1 != "" & district_2 == "" & county_2 == "" 
	replace county_3 = county if _merge ==3 & parish_3 == parish & district_1 != "" & district_2 != "" & district_3 == "" & county_3 == "" 

	drop _merge county
	rename parish `var'
}

* Add county information from full parish-county crosswalk 
foreach var of varlist add1 add2 add3 add4 add5 {
	rename `var' parish
	qui merge m:1 parish using "$PROJ_PATH/processed/intermediate/geography/1881_parcty_crosswalk.dta", keep(1 3)

	replace parish_1 = parish if _merge == 3 & parish_1 == "" & district_1 == "" & county_1 == ""
	replace parish_2 = parish if _merge == 3 & parish_2 == "" & district_1 != "" & district_2 == "" & parish != parish_1 & county_2 == ""
	replace parish_3 = parish if _merge == 3 & parish_3 == "" & district_1 != "" & district_2 != "" & district_3 == "" & parish != parish_1 & parish != parish_2 & county_3 == ""
	
	replace county_1 = county if _merge ==3 & parish_1 == parish & district_1 == "" & county_1 == ""
	replace county_2 = county if _merge ==3 & parish_2 == parish & district_1 != "" & district_2 == "" & county_2 == "" 
	replace county_3 = county if _merge ==3 & parish_3 == parish & district_1 != "" & district_2 != "" & district_3 == "" & county_3 == "" 

	drop _merge county
	rename parish `var'
}

// Manual cleanup 

* Fill in no address entries
replace district_1 = "READMISSION" if regexm(address,"FROM ")==1 & regexm(address,"[0-9]")==0 & regexm(address,"GLASGOW")==0
replace subdist_1 = "READMISSION" if regexm(address,"FROM ")==1 & regexm(address,"[0-9]")==0 & regexm(address,"GLASGOW")==0
replace parish_1 = "READMISSION" if regexm(address,"FROM ")==1 & regexm(address,"[0-9]")==0 & regexm(address,"GLASGOW")==0
replace county_1 = "READMISSION" if regexm(address,"FROM ")==1 & regexm(address,"[0-9]")==0 & regexm(address,"GLASGOW")==0

replace district_1 = "READMISSION" if regexm(address,"HOSPITAL")==1 & regexm(address,"[0-9]")==0
replace subdist_1 = "READMISSION" if regexm(address,"HOSPITAL")==1 & regexm(address,"[0-9]")==0
replace parish_1 = "READMISSION" if regexm(address,"HOSPITAL")==1 & regexm(address,"[0-9]")==0
replace county_1 = "READMISSION" if regexm(address,"HOSPITAL")==1 & regexm(address,"[0-9]")==0

* Manually fill in geographic info
egen rank = seq(), by(address)
order rank district_1 address

replace district_1 = "HOLBORN" if address == "PUMP COURT, COWCROSS ST" 
replace subdist_1 = "SAFFRON HILL" if address == "PUMP COURT, COWCROSS ST" 
replace parish_1 = "ST SEPULCHRE" if address == "PUMP COURT, COWCROSS ST" 
replace county_1 = "MIDDLESEX" if address == "PUMP COURT, COWCROSS ST" 

replace district_1 = "HACKNEY" if address == "SEDGWICK ROAD, HOMERTON"
replace subdist_1 = "HACKNEY" if address == "SEDGWICK ROAD, HOMERTON"
replace parish_1 = "HACKNEY" if address == "SEDGWICK ROAD, HOMERTON"
replace county_1 = "MIDDLESEX" if address == "SEDGWICK ROAD, HOMERTON"

replace district_1 = "BANBURY" if address == "MALCOMBE W BANBURY, OXFORDSH"
replace subdist_1 = "BLOXHAM" if address == "MALCOMBE W BANBURY, OXFORDSH"
replace parish_1 = "MILCOMBE" if address == "MALCOMBE W BANBURY, OXFORDSH"
replace county_1 = "OXFORD" if address == "MALCOMBE W BANBURY, OXFORDSH"

replace district_1 = "WEST HAM" if address == "ODESSA TER, ODESSA ROAD, FOREST GATE" 
replace subdist_1 = "WEST HAM" if address == "ODESSA TER, ODESSA ROAD, FOREST GATE"
replace parish_1 = "" if address == "ODESSA TER, ODESSA ROAD, FOREST GATE"
replace county_1 = "ESSEX" if address == "ODESSA TER, ODESSA ROAD, FOREST GATE"

replace district_1 = "LONDON CITY" if address == "ARTISANS BWGS, STONEY LANE, HOUNDSDITCH"
replace subdist_1 = "ST BOTOLPH" if address == "ARTISANS BWGS, STONEY LANE, HOUNDSDITCH"
replace parish_1 = "ST BOTOLPH WITHOUT ALDGATE" if address == "ARTISANS BWGS, STONEY LANE, HOUNDSDITCH"
replace county_1 = "MIDDLESEX" if address == "ARTISANS BWGS, STONEY LANE, HOUNDSDITCH"

replace district_1 = "HOLBORN" if address == "GUINNESS BUILDINGS, LEVER ST, EC"
replace subdist_1 = "OLD STREET" if address == "GUINNESS BUILDINGS, LEVER ST, EC"
replace parish_1 = "ST LUKE" if address == "GUINNESS BUILDINGS, LEVER ST, EC"
replace county_1 = "MIDDLESEX" if address == "GUINNESS BUILDINGS, LEVER ST, EC"

replace district_1 = "HOLBORN" if address == "DOVE COURT, LEATHER LANE"
replace subdist_1 = "ST ANDREW EASTERN" if address == "DOVE COURT, LEATHER LANE"
replace parish_1 = "ST ANDREW HOLBORN" if address == "DOVE COURT, LEATHER LANE"
replace county_1 = "MIDDLESEX" if address == "DOVE COURT, LEATHER LANE"

replace district_1 = "ST SAVIOUR SOUTHWARK" if address == "PEABODY SQ, BLACKFRIARS"
replace subdist_1 = "LONDON ROAD" if address == "PEABODY SQ, BLACKFRIARS"
replace parish_1 = "ST GEORGE THE MARTYR SOUTHWARK" if address == "PEABODY SQ, BLACKFRIARS"
replace county_1 = "SURREY" if address == "PEABODY SQ, BLACKFRIARS"

replace district_1 = "HOLBORN" if address == "GLOUCESTER ST, BLOOMSBURY"
replace subdist_1 = "GOSWELL STREET" if address == "GLOUCESTER ST, BLOOMSBURY"
replace parish_1 = "CLERKENWELL" if address == "GLOUCESTER ST, BLOOMSBURY"
replace county_1 = "MIDDLESEX" if address == "GLOUCESTER ST, BLOOMSBURY"

replace district_1 = "KENSINGTON" if address == "CLARENDON ROAD, NOTTING H"
replace subdist_1 = "KENSINGTON TOWN" if address == "CLARENDON ROAD, NOTTING H"
replace parish_1 = "KENSINGTON" if address == "CLARENDON ROAD, NOTTING H"
replace county_1 = "MIDDLESEX" if address == "CLARENDON ROAD, NOTTING H"

replace district_1 = "CAMBERWELL" if address == "BLOXSAM BUILDINGS, CAMBERWELL G"
replace subdist_1 = "CAMBERWELL" if address == "BLOXSAM BUILDINGS, CAMBERWELL G"
replace parish_1 = "CAMBERWELL" if address == "BLOXSAM BUILDINGS, CAMBERWELL G"
replace county_1 = "SURREY" if address == "BLOXSAM BUILDINGS, CAMBERWELL G"

replace district_1 = "LUTON" if address == "CHILTERN GREEN, LUTON, BEDFORDSHIRE"
replace subdist_1 = "LUTON" if address == "CHILTERN GREEN, LUTON, BEDFORDSHIRE"

replace district_1 = "GUILDFORD" if address == "MILFORD, N GODALMING, SURREY"
replace subdist_1 = "GODALMING" if address == "MILFORD, N GODALMING, SURREY"
replace parish_1 = "GODALMING" if address == "MILFORD, N GODALMING, SURREY"

replace district_1 = "HACKNEY" if regexm(address,"HOMERTON")
replace subdist_1 = "HACKNEY" if regexm(address,"HOMERTON")
replace parish_1 = "HACKNEY" if regexm(address,"HOMERTON")
replace county_1 = "MIDDLESEX" if regexm(address,"HOMERTON")

replace district_1 = "SHOREDITCH" if address == "KINGSLAND ROAD" & stnum<295
replace subdist_1 = "HAGGERSTON" if address == "KINGSLAND ROAD" & stnum<295
replace parish_1 = "SHOREDITCH" if address == "KINGSLAND ROAD" & stnum<295
replace county_1 = "MIDDLESEX" if address == "KINGSLAND ROAD" & stnum<295

replace district_1 = "MARYLEBONE" if address == "GROVE COTTAGES, BELL ST, EDGWARE ROAD"
replace subdist_1 = "CHRISTCHURCH" if address == "GROVE COTTAGES, BELL ST, EDGWARE ROAD"
replace parish_1 = "ST MARYLEBONE" if address == "GROVE COTTAGES, BELL ST, EDGWARE ROAD"
replace county_1 = "MIDDLESEX" if address == "GROVE COTTAGES, BELL ST, EDGWARE ROAD"

replace district_1 = "HOLBORN" if address == "YORK ROAD, CITY ROAD"
replace subdist_1 = "CITY ROAD" if address == "YORK ROAD, CITY ROAD"
replace parish_1 = "ST LUKE" if address == "YORK ROAD, CITY ROAD"
replace county_1 = "MIDDLESEX" if address == "YORK ROAD, CITY ROAD"

replace district_1 = "ISLINGTON" if address == "ASTEY ROW, CANONBURY ROAD"
replace subdist_1 = "ISLINGTON EAST" if address == "ASTEY ROW, CANONBURY ROAD"
replace parish_1 = "ISLINGTON" if address == "ASTEY ROW, CANONBURY ROAD"
replace county_1 = "MIDDLESEX" if address == "ASTEY ROW, CANONBURY ROAD"

replace district_1 = "PENZANCE" if address == "MARKET PLACE, HAYLE, CORNWALL"
replace parish_1 = "HAYLE" if address == "MARKET PLACE, HAYLE, CORNWALL"
replace county_1 = "CORNWALL" if address == "MARKET PLACE, HAYLE, CORNWALL"

replace district_1 = "BRENTFORD" if address == "DUKE OF YORK, BARROW ROAD, HOUNSLOW"
replace county_1 = "MIDDLESEX" if address == "DUKE OF YORK, BARROW ROAD, HOUNSLOW"

replace district_1 = "HAMPSTEAD" if address == "COTLEIGH ROAD, WEST HAMPSTEAD"
replace county_1 = "MIDDLESEX" if address == "COTLEIGH ROAD, WEST HAMPSTEAD"

replace district_1 = "ST SAVIOUR SOUTHWARK" if address == "QUINN SQ, WATERLOO ROAD, BLACKFRIARS"
replace subdist_1 = "LONDON ROAD" if address == "QUINN SQ, WATERLOO ROAD, BLACKFRIARS"
replace parish_1 = "ST GEORGE THE MARTYR SOUTHWARK" if address == "QUINN SQ, WATERLOO ROAD, BLACKFRIARS"
replace county_1 = "SURREY" if address == "QUINN SQ, WATERLOO ROAD, BLACKFRIARS"

replace district_1 = "ISLINGTON" if address == "STOREY ST, CALEDONIAN ROAD, N"
replace subdist_1 = "ISLINGTON WEST" if address == "STOREY ST, CALEDONIAN ROAD, N"
replace parish_1 = "ISLINGTON" if address == "STOREY ST, CALEDONIAN ROAD, N"
replace county_1 = "MIDDLESEX" if address == "STOREY ST, CALEDONIAN ROAD, N"

replace district_1 = "ISLINGTON" if address == "GLOUCESTER ROAD, HOLLOWAY"
replace subdist_1 = "ISLINGTON EAST" if address == "GLOUCESTER ROAD, HOLLOWAY"
replace parish_1 = "ISLINGTON" if address == "GLOUCESTER ROAD, HOLLOWAY"
replace county_1 = "MIDDLESEX" if address == "GLOUCESTER ROAD, HOLLOWAY"

replace district_1 = "BRIDGEND" if address == "SPLOTT FARM ST, DONATTS NEAR BRIDGEND E, GLAMORGAN"

replace district_1 = "ST SAVIOUR SOUTHWARK" if address == "BITTERN ST, SOUTHWARK"
replace subdist_1 = "KENT ROAD" if address == "BITTERN ST, SOUTHWARK"
replace parish_1 = "ST GEORGE THE MARTYR SOUTHWARK" if address == "BITTERN ST, SOUTHWARK"
replace county_1 = "SURREY" if address == "BITTERN ST, SOUTHWARK"

replace district_1 = "WEST HAM" if address == "PEARCROFT ROAD, LEYTONSTONE"
replace subdist_1 = "LEYTON" if address == "PEARCROFT ROAD, LEYTONSTONE"
replace county_1 = "ESSEX" if address == "PEARCROFT ROAD, LEYTONSTONE"

replace district_1 = "HENDON" if address == "MIDLAND TERR, CRICKLEWOOD"
replace subdist_1 = "WILLESDEN" if address == "MIDLAND TERR, CRICKLEWOOD"
replace county_1 = "MIDDLESEX" if address == "MIDLAND TERR, CRICKLEWOOD"

replace district_1 = "MIDHURST" if address == "THE COTTAGE STEADHAM, NEAR MIDHURST"
replace parish_1 = "IPING" if address == "THE COTTAGE STEADHAM, NEAR MIDHURST"
replace county_1 = "SUSSEX" if address == "THE COTTAGE STEADHAM, NEAR MIDHURST"

replace district_1 = "WEST HAM" if address == "ALNWICK ROAD, PRINCE OF WALES ROAD, VICTORIA DOCKS"
replace subdist_1 = "WEST HAM" if address == "ALNWICK ROAD, PRINCE OF WALES ROAD, VICTORIA DOCKS"
replace county_1 = "MIDDLESEX" if address == "ALNWICK ROAD, PRINCE OF WALES ROAD, VICTORIA DOCKS"

replace district_1 = "HOLBORN" if address == "COLD BATH SQ BUILDINGS, ROSEBERY AV, EC"
replace subdist_1 = "AMWELL" if address == "COLD BATH SQ BUILDINGS, ROSEBERY AV, EC"
replace parish_1 = "CLERKENWELL" if address == "COLD BATH SQ BUILDINGS, ROSEBERY AV, EC"
replace county_1 = "MIDDLESEX" if address == "COLD BATH SQ BUILDINGS, ROSEBERY AV, EC"

replace district_1 = "HOLBORN" if address == "COLD BATH SQR CLERKENWELL"
replace subdist_1 = "AMWELL" if address == "COLD BATH SQR CLERKENWELL"
replace parish_1 = "CLERKENWELL" if address == "COLD BATH SQR CLERKENWELL"
replace county_1 = "MIDDLESEX" if address == "COLD BATH SQR CLERKENWELL"

replace district_1 = "HOLBORN" if address == "COLD BATH SQ BUILDINGS, FARRINGDON ROAD"
replace subdist_1 = "AMWELL" if address == "COLD BATH SQ BUILDINGS, FARRINGDON ROAD"
replace parish_1 = "CLERKENWELL" if address == "COLD BATH SQ BUILDINGS, FARRINGDON ROAD"
replace county_1 = "MIDDLESEX" if address == "COLD BATH SQ BUILDINGS, FARRINGDON ROAD"

replace district_1 = "HOLBORN" if address == "FARRINGDON ST BUILDINGS" | address == "GREAT SUTTON ST, GOSWELL ROAD, EC"
replace subdist_1 = "ST JAMES CLERKENWELL" if address == "FARRINGDON ST BUILDINGS" | address == "GREAT SUTTON ST, GOSWELL ROAD, EC"
replace parish_1 = "CLERKENWELL" if address == "FARRINGDON ST BUILDINGS" | address == "GREAT SUTTON ST, GOSWELL ROAD, EC"
replace county_1 = "MIDDLESEX" if address == "FARRINGDON ST BUILDINGS" | address == "GREAT SUTTON ST, GOSWELL ROAD, EC"

replace district_1 = "HOLBORN" if address == "FARRINGDON BUILDINGS FARRINGDON ROAD"
replace subdist_1 = "ST JAMES CLERKENWELL" if address == "FARRINGDON BUILDINGS FARRINGDON ROAD"
replace parish_1 = "CLERKENWELL" if address == "FARRINGDON BUILDINGS FARRINGDON ROAD"
replace county_1 = "MIDDLESEX" if address == "FARRINGDON BUILDINGS FARRINGDON ROAD"

replace district_1 = "HOLBORN" if address == "HARRINGDON ROAD, BUILDINGS FARRINGDON ROAD, EC"
replace subdist_1 = "ST JAMES CLERKENWELL" if address == "HARRINGDON ROAD, BUILDINGS FARRINGDON ROAD, EC"
replace parish_1 = "CLERKENWELL" if address == "HARRINGDON ROAD, BUILDINGS FARRINGDON ROAD, EC"
replace county_1 = "MIDDLESEX" if address == "HARRINGDON ROAD, BUILDINGS FARRINGDON ROAD, EC"

replace district_1 = "HOLBORN" if address == "FARRINGDON ROAD BUILDING"
replace subdist_1 = "ST JAMES CLERKENWELL" if address == "FARRINGDON ROAD BUILDING"
replace parish_1 = "CLERKENWELL" if address == "FARRINGDON ROAD BUILDING"
replace county_1 = "MIDDLESEX" if address == "FARRINGDON ROAD BUILDING"

replace district_1 = "HOLBORN" if address == "COLD BATH SQ BUILDINGS, FARRINGDON ROAD"
replace subdist_1 = "AMWELL" if address == "COLD BATH SQ BUILDINGS, FARRINGDON ROAD"
replace parish_1 = "CLERKENWELL" if address == "COLD BATH SQ BUILDINGS, FARRINGDON ROAD"
replace county_1 = "MIDDLESEX" if address == "COLD BATH SQ BUILDINGS, FARRINGDON ROAD"

replace district_1 = "HOLBORN" if address == "CORPORATION BOY FARRINGDON ROAD"
replace subdist_1 = "ST JAMES CLERKENWELL" if address == "CORPORATION BOY FARRINGDON ROAD"
replace parish_1 = "CLERKENWELL" if address == "CORPORATION BOY FARRINGDON ROAD"
replace county_1 = "MIDDLESEX" if address == "CORPORATION BOY FARRINGDON ROAD"

replace district_1 = "HOLBORN" if address == "1 BLOCK, FARRINGDON ROAD BUILDINGS, EC"
replace subdist_1 = "ST JAMES CLERKENWELL" if address == "1 BLOCK, FARRINGDON ROAD BUILDINGS, EC"
replace parish_1 = "CLERKENWELL" if address == "1 BLOCK, FARRINGDON ROAD BUILDINGS, EC"
replace county_1 = "MIDDLESEX" if address == "1 BLOCK, FARRINGDON ROAD BUILDINGS, EC"

replace district_1 = "HOLBORN" if regexm(address,"FARRINGDON")==1 & regexm(address,"BAKER")==1
replace subdist_1 = "ST JAMES CLERKENWELL" if regexm(address,"FARRINGDON")==1 & regexm(address,"BAKER")==1
replace parish_1 = "CLERKENWELL" if regexm(address,"FARRINGDON")==1 & regexm(address,"BAKER")==1
replace county_1 = "MIDDLESEX" if regexm(address,"FARRINGDON")==1 & regexm(address,"BAKER")==1

replace district_1 = "HOLBORN" if address == "FARRINGDON ROL, EC"
replace subdist_1 = "ST JAMES CLERKENWELL" if address == "FARRINGDON ROL, EC"
replace parish_1 = "CLERKENWELL" if address == "FARRINGDON ROL, EC"
replace county_1 = "MIDDLESEX" if address == "FARRINGDON ROL, EC"

replace district_1 = "HOLBORN" if regexm(address,"FARRINGDON")==1 & regexm(address,"BATH ST")==1 & stnum<=23
replace subdist_1 = "ST JAMES CLERKENWELL" if regexm(address,"FARRINGDON")==1 & regexm(address,"BATH ST")==1 & stnum<=23
replace parish_1 = "CLERKENWELL" if regexm(address,"FARRINGDON")==1 & regexm(address,"BATH ST")==1 & stnum<=23
replace county_1 = "MIDDLESEX" if regexm(address,"FARRINGDON")==1 & regexm(address,"BATH ST")==1 & stnum<=23

replace district_1 = "HOLBORN" if regexm(address,"FARRINGDON")==1 & regexm(address,"BATH ST")==1 & stnum>23
replace subdist_1 = "AMWELL" if regexm(address,"FARRINGDON")==1 & regexm(address,"BATH ST")==1 & stnum>23
replace parish_1 = "CLERKENWELL" if regexm(address,"FARRINGDON")==1 & regexm(address,"BATH ST")==1 & stnum>23
replace county_1 = "MIDDLESEX" if regexm(address,"FARRINGDON")==1 & regexm(address,"BATH ST")==1 & stnum>23

replace district_1 = "HOLBORN" if address == "BATH ROW, FARRINGDON ROAD" | address == "BATH ROAD, FARRINGDON ROAD, EC"
replace subdist_1 = "ST JAMES CLERKENWELL" if address == "BATH ROW, FARRINGDON ROAD" | address == "BATH ROAD, FARRINGDON ROAD, EC"
replace parish_1 = "CLERKENWELL" if address == "BATH ROW, FARRINGDON ROAD" | address == "BATH ROAD, FARRINGDON ROAD, EC"
replace county_1 = "MIDDLESEX" if address == "BATH ROW, FARRINGDON ROAD" | address == "BATH ROAD, FARRINGDON ROAD, EC"

replace district_1 = "HOLBORN" if regexm(address,"FARRINGDON")==1 & regexm(address,"BATH SQ")==1
replace subdist_1 = "AMWELL" if regexm(address,"FARRINGDON")==1 & regexm(address,"BATH SQ")==1
replace parish_1 = "CLERKENWELL" if regexm(address,"FARRINGDON")==1 & regexm(address,"BATH SQ")==1
replace county_1 = "MIDDLESEX" if regexm(address,"FARRINGDON")==1 & regexm(address,"BATH SQ")==1

replace district_1 = "HOLBORN" if address == "GREAT SAFFRON HILL, FARRINGDON ROAD"
replace subdist_1 = "SAFRON HILL" if address == "GREAT SAFFRON HILL, FARRINGDON ROAD"
replace parish_1 = "SAFFRON" if address == "GREAT SAFFRON HILL, FARRINGDON ROAD"
replace county_1 = "MIDDLESEX" if address == "GREAT SAFFRON HILL, FARRINGDON ROAD"

replace district_1 = "HOLBORN" if regexm(address,"FARRINGDON")==1 & regexm(address,"CORPORATION")
replace subdist_1 = "ST JAMES CLERKENWELL" if regexm(address,"FARRINGDON")==1 & regexm(address,"CORPORATION")
replace parish_1 = "CLERKENWELL" if regexm(address,"FARRINGDON")==1 & regexm(address,"CORPORATION")
replace county_1 = "MIDDLESEX" if regexm(address,"FARRINGDON")==1 & regexm(address,"CORPORATION")

replace district_1 = "HOLBORN" if regexm(address,"FARRINGDON")==1 & regexm(address,"BU") & regexm(address,"CORPORATION")==0 & regexm(address,"PEABODY")==0 & regexm(address,"BATH")==0 & regexm(address,"MARGARET")==0 & regexm(address,"VICTORIA")==0 & regexm(address,"GARFIELD")==0 & regexm(address,"BRAZIER")==0
replace subdist_1 = "AMWELL" if regexm(address,"FARRINGDON")==1 & regexm(address,"BU") & regexm(address,"CORPORATION")==0 & regexm(address,"PEABODY")==0 & regexm(address,"BATH")==0 & regexm(address,"MARGARET")==0 & regexm(address,"VICTORIA")==0 & regexm(address,"GARFIELD")==0 & regexm(address,"BRAZIER")==0
replace parish_1 = "CLERKENWELL" if regexm(address,"FARRINGDON")==1 & regexm(address,"BU") & regexm(address,"CORPORATION")==0 & regexm(address,"PEABODY")==0 & regexm(address,"BATH")==0 & regexm(address,"MARGARET")==0 & regexm(address,"VICTORIA")==0 & regexm(address,"GARFIELD")==0 & regexm(address,"BRAZIER")==0
replace county_1 = "MIDDLESEX" if regexm(address,"FARRINGDON")==1 & regexm(address,"BU") & regexm(address,"CORPORATION")==0 & regexm(address,"PEABODY")==0 & regexm(address,"BATH")==0 & regexm(address,"MARGARET")==0 & regexm(address,"VICTORIA")==0 & regexm(address,"GARFIELD")==0 & regexm(address,"BRAZIER")==0

replace district_1 = "HOLBORN" if regexm(address,"FARRINGDON")==1 & regexm(address,"VICTORIA")==1 
replace county_1 = "MIDDLESEX" if regexm(address,"FARRINGDON")==1 & regexm(address,"VICTORIA")==1 

replace district_1 = "HOLBORN" if regexm(address,"FARRINGDON")==1 & regexm(address,"SPRING")==1 
replace county_1 = "MIDDLESEX" if regexm(address,"FARRINGDON")==1 & regexm(address,"SPRING")==1 

replace district_1 = "HOLBORN" if regexm(address,"FARRINGDON")==1 & regexm(address,"PLEASANT")==1
replace subdist_1 = "AMWELL" if regexm(address,"FARRINGDON")==1 & regexm(address,"PLEASANT")==1
replace parish_1 = "CLERKENWELL" if regexm(address,"FARRINGDON")==1 & regexm(address,"PLEASANT")==1
replace county_1 = "MIDDLESEX" if regexm(address,"FARRINGDON")==1 & regexm(address,"PLEASANT")==1

replace district_1 = "HOLBORN" if regexm(address,"FARRINGDON")==1 & regexm(address,"GARFIELD")
replace subdist_1 = "ST JAMES CLERKENWELL" if regexm(address,"FARRINGDON")==1 & regexm(address,"GARFIELD")
replace parish_1 = "CLERKENWELL" if regexm(address,"FARRINGDON")==1 & regexm(address,"GARFIELD")
replace county_1 = "MIDDLESEX" if regexm(address,"FARRINGDON")==1 & regexm(address,"GARFIELD")

replace district_1 = "HOLBORN" if regexm(address,"FARRINGDON")==1 & regexm(address,"SAFFRON TER")==1 
replace county_1 = "MIDDLESEX" if regexm(address,"FARRINGDON")==1 & regexm(address,"SAFFRON TER")==1 

replace district_1 = "LONDON CITY" if regexm(address,"FARRINGDON")==1 & regexm(address,"WOOD ST")==1 
replace county_1 = "MIDDLESEX" if regexm(address,"FARRINGDON")==1 & regexm(address,"WOOD ST")==1 

replace district_1 = "HOLBORN" if regexm(address,"FARRINGDON")==1 & regexm(address,"VINYARD")==1
replace subdist_1 = "AMWELL" if regexm(address,"FARRINGDON")==1 & regexm(address,"VINYARD")==1
replace parish_1 = "CLERKENWELL" if regexm(address,"FARRINGDON")==1 & regexm(address,"VINYARD")==1
replace county_1 = "MIDDLESEX" if regexm(address,"FARRINGDON")==1 & regexm(address,"VINYARD")==1

replace district_1 = "LONDON CITY" if regexm(address,"FARRINGDON")==1 & regexm(address,"BRAZIER")==1 
replace county_1 = "MIDDLESEX" if regexm(address,"FARRINGDON")==1 & regexm(address,"BRAZIER")==1 

replace district_1 = "LONDON CITY" if address == "CASTLE ST, FARRINGDON ST"
replace subdist_1 = "ST BRIDE" if address == "CASTLE ST, FARRINGDON ST"
replace parish_1 = "ST ANDREW HOLBORN BELOW THE BARS" if address == "CASTLE ST, FARRINGDON ST"
replace county_1 = "MIDDLESEX" if address == "CASTLE ST, FARRINGDON ST"

replace district_1 = "ST SAVIOUR SOUTHWARK" if address == "GEORGE ST, BLACKFRIARS ROAD"
replace subdist_1 = "CHRISTCHURCH SOUTHWARK" if address == "GEORGE ST, BLACKFRIARS ROAD" 
replace parish_1 = "CHRISTCHURCH SOUTHWARK" if address == "GEORGE ST, BLACKFRIARS ROAD"
replace county_1 = "SURREY" if address == "GEORGE ST, BLACKFRIARS ROAD"

replace district_1 = "POPLAR" if address == "NORTHUMBERLAND COTTAGES, WESTFERRY ROAD, MILLWALL"
replace subdist_1 = "POPLAR" if address == "NORTHUMBERLAND COTTAGES, WESTFERRY ROAD, MILLWALL"
replace parish_1 = "POPLAR" if address == "NORTHUMBERLAND COTTAGES, WESTFERRY ROAD, MILLWALL"
replace county_1 = "MIDDLESEX" if address == "NORTHUMBERLAND COTTAGES, WESTFERRY ROAD, MILLWALL"

replace district_1 = "SHOREDITCH" if address == "WHITECROSS PLACE, EC"
replace county_1 = "MIDDLESEX" if address == "WHITECROSS PLACE, EC"

replace district_1 = "SHOREDITCH" if address == "DUNSTAN ROAD, KINGSLAND ROAD"
replace subdist_1 = "HAGGERSTON" if address == "DUNSTAN ROAD, KINGSLAND ROAD"
replace parish_1 = "SHOREDITCH" if address == "DUNSTAN ROAD, KINGSLAND ROAD"
replace county_1 = "MIDDLESEX" if address == "DUNSTAN ROAD, KINGSLAND ROAD"

replace district_1 = "ISLINGTON" if address == "QUEENSBURY ST, ESSEX ROAD"
replace subdist_1 = "ISLINGTON EAST" if address == "QUEENSBURY ST, ESSEX ROAD"
replace parish_1 = "ISLINGTON" if address == "QUEENSBURY ST, ESSEX ROAD"
replace county_1 = "MIDDLESEX" if address == "QUEENSBURY ST, ESSEX ROAD"

replace district_1 = "ISLINGTON" if address == "PEABODY SQUARE, ESSEX ROAD, N"
replace subdist_1 = "ISLINGTON EAST" if address == "PEABODY SQUARE, ESSEX ROAD, N"
replace parish_1 = "ISLINGTON" if address == "PEABODY SQUARE, ESSEX ROAD, N"
replace county_1 = "MIDDLESEX" if address == "PEABODY SQUARE, ESSEX ROAD, N"

replace district_1 = "PANCRAS" if address == "HIGH STREET, HIGHGATE"
replace subdist_1 = "KENTISH TOWN" if address == "HIGH STREET, HIGHGATE"
replace parish_1 = "ST PANCRAS" if address == "HIGH STREET, HIGHGATE"
replace county_1 = "MIDDLESEX" if address == "HIGH STREET, HIGHGATE"

replace district_1 = "POPLAR" if address == "HARMER ROAD, OLD FORD"
replace subdist_1 = "BOW" if address == "HARMER ROAD, OLD FORD"
replace parish_1 = "BOW AKA ST MARY STRATFORD-LE-BOW" if address == "HARMER ROAD, OLD FORD"
replace county_1 = "MIDDLESEX" if address == "HARMER ROAD, OLD FORD"

replace district_1 = "ISLINGTON" if address == "ALBION PLACE, DORSET ST, N"
replace subdist_1 = "ISLINGTON EAST" if address == "ALBION PLACE, DORSET ST, N"
replace parish_1 = "ISLINGTON" if address == "ALBION PLACE, DORSET ST, N"
replace county_1 = "MIDDLESEX" if address == "ALBION PLACE, DORSET ST, N"

replace district_1 = "LONDON CITY" if address == "BISHOPS CT, OLD BAILEY" | address == "SUGAR LOAF CT, FLEET ST"
replace subdist_1 = "ST SEPULCHRE" if address == "BISHOPS CT, OLD BAILEY" | address == "SUGAR LOAF CT, FLEET ST"
replace parish_1 = "ST SEPULCHRE" if address == "BISHOPS CT, OLD BAILEY" | address == "SUGAR LOAF CT, FLEET ST"
replace county_1 = "MIDDLESEX" if address == "BISHOPS CT, OLD BAILEY" | address == "SUGAR LOAF CT, FLEET ST"

replace district_1 = "WEST HAM" if address == "ODESSA ROAD, FOREST GATE"
replace subdist_1 = "WEST HAM" if address == "ODESSA ROAD, FOREST GATE"
replace county_1 = "ESSEX" if address == "ODESSA ROAD, FOREST GATE"

replace district_1 = "HACKNEY" if address =="LANSDOWNE ROAD, DALSTON"
replace subdist_1 = "HACKNEY" if address =="LANSDOWNE ROAD, DALSTON"
replace parish_1 = "HACKNEY" if address =="LANSDOWNE ROAD, DALSTON"
replace county_1 = "MIDDLESEX" if address =="LANSDOWNE ROAD, DALSTON"

replace district_1 = "ST OLAVE SOUTHWARK" if address == "LINDSAY ST, SOUTHWARK PK ROAD"
replace subdist_1 = "ST JAMES BERMONDSEY" if address == "LINDSAY ST, SOUTHWARK PK ROAD"
replace parish_1 = "BERMONDSEY" if address == "LINDSAY ST, SOUTHWARK PK ROAD"
replace county_1 = "SURREY" if address == "LINDSAY ST, SOUTHWARK PK ROAD"

replace district_1 = "CHARD" if address == "TATWORTH STREET, TATWORTH, CHARD, SOMERSETSHIRE"

replace district_1 = "HOLBORN" if address == "THE BATHS, GOLDEN LANE"
replace subdist_1 = "WHITECROSS STREET" if address == "THE BATHS, GOLDEN LANE"
replace parish_1 = "ST LUKE" if address == "THE BATHS, GOLDEN LANE"
replace county_1 = "MIDDLESEX" if address == "THE BATHS, GOLDEN LANE"

replace district_1 = "" if address == "BROOKLYN COTTAGES, SAYER ST, HUNTINGS"
replace subdist_1 = "" if address == "BROOKLYN COTTAGES, SAYER ST, HUNTINGS"
replace parish_1 = "" if address == "BROOKLYN COTTAGES, SAYER ST, HUNTINGS"
replace county_1 = "CAMBRIDGESHIRE" if address == "BROOKLYN COTTAGES, SAYER ST, HUNTINGS"

replace district_1 = "CAMBERWELL" if address == "CHASE VILLAS, PORTSMOUTH ROAD, NUNHEAD"
replace subdist_1 = "PECKHAM" if address == "CHASE VILLAS, PORTSMOUTH ROAD, NUNHEAD"
replace parish_1 = "CAMBERWELL" if address == "CHASE VILLAS, PORTSMOUTH ROAD, NUNHEAD"
replace county_1 = "SURREY" if address == "CHASE VILLAS, PORTSMOUTH ROAD, NUNHEAD"

replace district_1 = "SHOREDITCH" if address == "NEWTON ST, NEW NORTH ROAD"
replace subdist_1 = "HOXTON OLD TOWN" if address == "NEWTON ST, NEW NORTH ROAD"
replace parish_1 = "SHOREDITCH" if address == "NEWTON ST, NEW NORTH ROAD"
replace county_1 = "MIDDLESEX" if address == "NEWTON ST, NEW NORTH ROAD"

replace district_1 = "EDMONTON" if address == "FLORENCE VILLA TOTTERIDGE ROAD, ENFIELD WASH"
replace subdist_1 = "ENFIELD" if address == "FLORENCE VILLA TOTTERIDGE ROAD, ENFIELD WASH"
replace parish_1 = "1832" if address == "FLORENCE VILLA TOTTERIDGE ROAD, ENFIELD WASH"
replace county_1 = "MIDDLESEX" if address == "FLORENCE VILLA TOTTERIDGE ROAD, ENFIELD WASH"

replace district_1 = "LAMBETH" if address == "GRUNSWORTH ROAD, WORDSWORTH ROAD, SW"
replace subdist_1 = "KENSINGTON FIRST" if address == "GRUNSWORTH ROAD, WORDSWORTH ROAD, SW"
replace parish_1 = "LAMBETH" if address == "GRUNSWORTH ROAD, WORDSWORTH ROAD, SW"
replace county_1 = "SURREY" if address == "GRUNSWORTH ROAD, WORDSWORTH ROAD, SW"

replace district_1 = "PANCRAS" if address == "CLEVELAND ST, FITZROY SQRE"
replace subdist_1 = "TOTTENHAM COURT" if address == "CLEVELAND ST, FITZROY SQRE"
replace parish_1 = "ST PANCRAS" if address == "CLEVELAND ST, FITZROY SQRE"
replace county_1 = "MIDDLESEX" if address == "CLEVELAND ST, FITZROY SQRE"

replace district_1 = "KENSINGTON" if regexm(address,"KENSINGTON")==1 & district_1 == ""
replace county_1 = "MIDDLESEX" if regexm(address,"KENSINGTON")==1

replace district_1 = "HAMPSHIRE" if regexm(address,"HAMPSHIRE")==1 & district_1 == ""
replace county_1 = "MIDDLESEX" if regexm(address,"HAMPSHIRE")==1

replace subdist_1 = "" if regexm(address,"HOLLOWAY$")==1 & district_1 != "ISLINGTON"
replace parish_1 = "" if regexm(address,"HOLLOWAY$")==1 & district_1 != "ISLINGTON"
replace district_1 = "ISLINGTON" if regexm(address,"HOLLOWAY$")==1 
replace county_1 = "MIDDLESEX" if regexm(address,"HOLLOWAY$")==1 

replace parish_1 = "" if regexm(address,"BISHOP(S)*GATE")==1 & subdist_1 !="ST BOTOLPH"
replace subdist_1 = "" if regexm(address,"BISHOP(S)*GATE")==1 & subdist_1 !="ST BOTOLPH"
replace district_1 = "LONDON CITY" if regexm(address,"BISHOP(S)*GATE")==1 
replace county_1 = "MIDDLESEX" if regexm(address,"BISHOP(S)*GATE")==1 

replace subdist_1 = "" if regexm(address,"NOTTING HILL")==1 & district_1 != "KENSINGTON"
replace parish_1 = "" if regexm(address,"NOTTING HILL$")==1 & district_1 != "KENSINGTON"
replace district_1 = "KENSINGTON" if regexm(address,"NOTTING HILL$")==1 
replace county_1 = "MIDDLESEX" if regexm(address,"NOTTING HILL$")==1

replace subdist_1 = "" if regexm(address,"SMITHFIELD")==1 & regexm(address,"EAST SMITHFIELD")==0 & regexm(address," E SMITHFIELD")==0 & (district_1 !="LONDON CITY" | district_1 != "HOLBORN")
replace parish_1 = "" if regexm(address,"SMITHFIELD")==1 & regexm(address,"EAST SMITHFIELD")==0 & regexm(address," E SMITHFIELD")==0 & (district_1 !="LONDON CITY" | district_1 != "HOLBORN")
replace district_1 = "LONDON CITY" if regexm(address,"SMITHFIELD")==1 & regexm(address,"EAST SMITHFIELD")==0 & regexm(address," E SMITHFIELD")==0 & (district_1 !="LONDON CITY" | district_1 != "HOLBORN")
replace county_1 = "MIDDLESEX" if regexm(address,"SMITHFIELD")==1 & regexm(address,"EAST SMITHFIELD")==0 & regexm(address," E SMITHFIELD")==0 & (district_1 !="LONDON CITY" | district_1 != "HOLBORN")

replace subdist_1 = "ALDGATE" if regexm(address," E SMITHFIELD")==1 & district_1==""
replace county_1 = "MIDDLESEX" if regexm(address," E SMITHFIELD")==1 & district_1=="" 
replace district_1 = "WHITECHAPEL" if regexm(address," E SMITHFIELD")==1 & district_1==""

replace county_1 = "SURREY" if regexm(address,"TOOTING")==1 & district_1==""
replace district_1 = "WANDSWORTH" if regexm(address,"TOOTING")==1 & district_1==""

replace district_1 = "WEST HAM" if regexm(address,"FOREST( )*GATE")==1
replace subdist_1 = "WEST HAM" if regexm(address,"FOREST( )*GATE")==1
replace parish_1 = "WEST HAM" if regexm(address,"FOREST( )*GATE")==1
replace county_1 = "ESSEX" if regexm(address,"FOREST( )*GATE")==1

replace subdist_1 = "" if regexm(address,"CLAPTON")==1 & district_1 !="HACKNEY"
replace parish_1 = "" if regexm(address,"CLAPTON")==1 & district_1 !="HACKNEY"
replace district_1 = "HACKNEY" if regexm(address,"CLAPTON")==1 
replace county_1 = "MIDDLESEX" if regexm(address,"CLAPTON")==1 

replace district_1 = "HOLBORN" if regexm(address,"^CITY ROAD")==1 & stnum<=326
replace parish_1 = "ST LUKE" if regexm(address,"^CITY ROAD")==1 & stnum<=326
replace district_1 = "ISLINGTON" if regexm(address,"^CITY ROAD")==1 & stnum>326
replace parish_1 = "ISLINGTON" if regexm(address,"^CITY ROAD")==1 & stnum>326
replace subdist_1 = "ISLINGTON EAST" if regexm(address,"^CITY ROAD")==1 & stnum>326
replace county_1 = "MIDDLESEX" if regexm(address,"^CITY ROAD")==1 

replace district_1 = "HOLBORN" if regexm(address,"GOLDEN LANE")==1 & (regexm(address,"BATH")==1 | regexm(address,"HARTSHORN")==1 )
replace subdist_1 = "WHITECROSS STREET" if regexm(address,"GOLDEN LANE")==1 & (regexm(address,"BATH")==1 | regexm(address,"HARTSHORN")==1 )
replace parish_1 = "ST LUKE" if regexm(address,"GOLDEN LANE")==1 & (regexm(address,"BATH")==1 | regexm(address,"HARTSHORN")==1 )
replace county_1 = "MIDDLESEX" if regexm(address,"GOLDEN LANE")==1 & (regexm(address,"BATH")==1 | regexm(address,"HARTSHORN")==1 )

replace district_1 = "HACKNEY" if regexm(address,"LONDON FIELDS")==1
replace subdist_1 = "HACKNEY" if regexm(address,"LONDON FIELDS")==1
replace parish_1 = "HACKNEY" if regexm(address,"LONDON FIELDS")==1
replace county_1 = "MIDDLESEX" if regexm(address,"LONDON FIELDS")==1

replace subdist_1 = "" if regexm(address,"STEPNEY GREEN")==1 & district_1 !="MILE END OLD TOWN"
replace parish_1 = "MILE END OLD TOWN" if regexm(address,"STEPNEY GREEN")==1 & district_1 !="MILE END OLD TOWN"
replace county_1 = "MIDDLESEX" if regexm(address,"STEPNEY GREEN")==1 & district_1 !="MILE END OLD TOWN"
replace district_1 = "MILE END OLD TOWN" if regexm(address,"STEPNEY GREEN")==1 & district_1 !="MILE END OLD TOWN"

replace district_1 = "CROYDON" if regexm(address,"ANERLEY$")==1 | regexm(address,"ANERLEY,")==1
replace subdist_1 = "CROYDON" if regexm(address,"ANERLEY$")==1 | regexm(address,"ANERLEY,")==1
replace parish_1 = "PENGE" if regexm(address,"ANERLEY$")==1 | regexm(address,"ANERLEY,")==1
replace county_1 = "SURREY" if regexm(address,"ANERLEY$")==1 | regexm(address,"ANERLEY,")==1

replace district_1 = "CAMBERWELL" if regexm(address,"DULWICH")==1
replace subdist_1 = "DULWICH" if regexm(address,"DULWICH")==1
replace parish_1 = "CAMBERWELL" if regexm(address,"DULWICH")==1
replace county_1 = "SURREY" if regexm(address,"DULWICH")==1

replace district_1 = "BRENTFORD" if regexm(address,"EALING")==1
replace subdist_1 = "BRENTFORD" if regexm(address,"EALING")==1
replace parish_1 = "EALING WITH OLD BRENTFORD" if regexm(address,"EALING")==1
replace county_1 = "MIDDLESEX" if regexm(address,"EALING")==1

replace county_1 = "SURREY" if regexm(address,"LAMBETH")==1 & district_1==""
replace district_1 = "LAMBETH" if regexm(address,"LAMBETH")==1 & district_1==""

replace district_1 = "HENDON" if regexm(address,"HARLESDEN")==1
replace subdist_1 = "WILLESDEN" if regexm(address,"HARLESDEN")==1
replace parish_1 = "" if regexm(address,"HARLESDEN")==1
replace county_1 = "MIDDLESEX" if regexm(address,"HARLESDEN")==1

replace subdist_1 = "ILFORD" if regexm(address,"ILFORD")==1 & district_1 == ""
replace parish_1 = "" if regexm(address,"ILFORD")==1 & district_1 == ""
replace county_1 = "ESSEX" if regexm(address,"ILFORD")==1 & district_1 == ""
replace district_1 = "ROMFORD" if regexm(address,"ILFORD")==1 & district_1 == ""

replace district_1 = "GREENWICH" if regexm(address,"NEW CROSS")==1
replace subdist_1 = "ST PAUL DEPTFORD" if regexm(address,"NEW CROSS")==1
replace parish_1 = "ST PAUL DEPTFORD" if regexm(address,"NEW CROSS")==1
replace county_1 = "KENT" if regexm(address,"NEW CROSS")==1

replace district_1 = "GREENWICH" if regexm(address,"DEPTFORD")==1
replace subdist_1 = "ST PAUL DEPTFORD" if regexm(address,"DEPTFORD")==1
replace parish_1 = "ST PAUL DEPTFORD" if regexm(address,"DEPTFORD")==1
replace county_1 = "KENT" if regexm(address,"DEPTFORD")==1

replace subdist_1 = "WEST HAM" if regexm(address,"CANNING TOWN")==1 & district_1 != "WEST HAM"
replace parish_1 = "" if regexm(address,"CANNING TOWN")==1 & district_1 != "WEST HAM"
replace county_1 = "ESSEX" if regexm(address,"CANNING TOWN")==1 & district_1 != "WEST HAM"
replace district_1 = "WEST HAM" if regexm(address,"CANNING TOWN")==1 & district_1 != "WEST HAM"

replace district_1 = "ISLINGTON" if regexm(address, "FINSBURY PARK")==1
replace subdist_1 = "ISLINGTON EAST" if regexm(address, "FINSBURY PARK")==1
replace parish_1 = "ISLINGTON" if regexm(address, "FINSBURY PARK")==1
replace county_1 = "MIDDLESEX" if regexm(address, "FINSBURY PARK")==1

replace district_1 = "WEST HAM" if regexm(address,"WALTHAMSTOW")==1
replace subdist_1 = "WALTHAMSTOW" if regexm(address,"WALTHAMSTOW")==1
replace parish_1 = "WALTHAMSTOW" if regexm(address,"WALTHAMSTOW")==1
replace county_1 = "ESSEX" if regexm(address,"WALTHAMSTOW")==1

replace district_1 = "HOLBORN" if regexm(address,"COWCROSS")==1
replace subdist_1 = "SAFFRON HILL" if regexm(address,"COWCROSS")==1
replace parish_1 = "ST SEPULCHRE" if regexm(address,"COWCROSS")==1
replace county_1 = "MIDDLESEX" if regexm(address,"COWCROSS")==1

replace district_1 = "LONDON CITY" if regexm(address,"HOUNDSDITCH")==1
replace subdist_1 = "ST BOTOLPH" if regexm(address,"HOUNDSDITCH")==1
replace parish_1 = "ST BOTOLPH WITHOUT ALDGATE" if regexm(address,"HOUNDSDITCH")==1
replace county_1 = "MIDDLESEX" if regexm(address,"HOUNDSDITCH")==1

replace subdist_1 = "" if regexm(address,"PLUMSTEAD")==1 & district_1 != "WOOLWICH"
replace parish_1 = "" if regexm(address,"PLUMSTEAD")==1 & district_1 != "WOOLWICH"
replace district_1 = "WOOLWICH" if regexm(address,"PLUMSTEAD")==1 
replace county_1 = "KENT" if regexm(address,"PLUMSTEAD")==1 

replace subdist_1 = "" if regexm(address,"WALWORTH")==1 & district_1 != "ST SAVIOUR SOUTHWARK"
replace parish_1 = "" if regexm(address,"WALWORTH")==1 & district_1 != "ST SAVIOUR SOUTHWARK"
replace district_1 = "ST SAVIOUR SOUTHWARK" if regexm(address,"WALWORTH")==1 
replace county_1 = "SURREY" if regexm(address,"WALWORTH")==1 

replace district_1 = "PORTSEA ISLAND" if regexm(address,"SOUTHSEA")==1
replace subdist_1 = "LANDPORT" if regexm(address,"SOUTHSEA")==1
replace parish_1 = "PORTSEA" if regexm(address,"SOUTHSEA")==1
replace county_1 = "HAMPSHIRE" if regexm(address,"SOUTHSEA")==1

replace subdist_1 = "" if regexm(address,"UPTON P(AR)*K")==1 & district_1 != "WEST HAM"
replace parish_1 = "" if regexm(address,"UPTON P(AR)*K")==1 & district_1 != "WEST HAM"
replace district_1 = "WEST HAM" if regexm(address,"UPTON P(AR)*K")==1
replace county_1 = "ESSEX" if regexm(address,"UPTON P(AR)*K")==1

replace district_1 = "POPLAR" if (regexm(address,"BROMLEY$")==1 |regexm(address,"BROMLEY, E")==1) & regexm(address,"BOW")==0 & regexm(address,"KENT")==0 
replace subdist_1 = "BROMLEY" if (regexm(address,"BROMLEY$")==1 |regexm(address,"BROMLEY, E")==1) & regexm(address,"BOW")==0 & regexm(address,"KENT")==0
replace parish_1 = "BROMLEY" if (regexm(address,"BROMLEY$")==1 |regexm(address,"BROMLEY, E")==1) & regexm(address,"BOW")==0 & regexm(address,"KENT")==0
replace county_1 = "MIDDLESEX" if (regexm(address,"BROMLEY$")==1 |regexm(address,"BROMLEY, E")==1) & regexm(address,"BOW")==0 & regexm(address,"KENT")==0

replace district_1 = "POPLAR" if regexm(address,"BROMLEY")==1 & (regexm(address,"BOW")==1 | postcode == "E")
replace subdist_1 = "BROMLEY" if regexm(address,"BROMLEY")==1 & (regexm(address,"BOW")==1 | postcode == "E")
replace parish_1 = "BROMLEY" if regexm(address,"BROMLEY")==1 & (regexm(address,"BOW")==1 | postcode == "E")
replace county_1 = "MIDDLESEX" if regexm(address,"BROMLEY")==1 & (regexm(address,"BOW")==1 | postcode == "E")

replace subdist_1 = "ENFIELD" if regexm(address," ENFIELD")==1 & district_1 != "EDMONTON" 
replace parish_1 = "ENFIELD" if regexm(address," ENFIELD")==1 & district_1 != "EDMONTON"
replace district_1 = "EDMONTON" if regexm(address," ENFIELD")==1 
replace county_1 = "MIDDLESEX" if regexm(address," ENFIELD")==1 

replace subdist_1 = "" if regexm(address,"HOUNSLOW")==1 & district_1 != "BRENTFORD"
replace parish_1 = "" if regexm(address,"HOUNSLOW")==1 & district_1 != "BRENTFORD"
replace district_1 = "BRENTFORD" if regexm(address,"HOUNSLOW")==1
replace county_1 = "MIDDLESEX" if regexm(address,"HOUNSLOW")==1

replace subdist_1 = "ISLEWORTH" if regexm(address,"HOUNSLOW")  & regexm(address,"ORPHANAGE")
replace parish_1 = "HESTON" if regexm(address,"HOUNSLOW")  & regexm(address,"ORPHANAGE")

replace subdist_1 = "" if regexm(address,"T[O|U]NBRIDGE") & district_1 != "TUNBRIDGE" 
replace parish_1 = "" if regexm(address,"T[O|U]NBRIDGE") & district_1 != "TUNBRIDGE"
replace district_1 = "TUNBRIDGE" if regexm(address,"T[O|U]NBRIDGE")
replace county_1 = "KENT" if regexm(address,"T[O|U]NBRIDGE")

replace district_1 = "MEDWAY" if regexm(address,"NEW BROMPTON")
replace subdist_1 = "GILLINGHAM" if regexm(address,"NEW BROMPTON")
replace parish_1 = "GILLING" if regexm(address,"NEW BROMPTON")
replace county_1 = "KENT" if regexm(address,"NEW BROMPTON")

replace subdist_1 = "" if regexm(address,"BROMPTON")==1 & district_1 !="KENSINGTON" & district_1 != "CHELSEA" & district_1 != "MEDWAY"
replace parish_1 = "" if regexm(address,"BROMPTON")==1 & district_1 !="KENSINGTON" & district_1 != "CHELSEA" & district_1 != "MEDWAY"
replace county_1 = "MIDDLESEX" if regexm(address,"BROMPTON")==1 & district_1 !="KENSINGTON" & district_1 != "CHELSEA" & district_1 != "MEDWAY"
replace district_1 = "KENSINGTON" if regexm(address,"BROMPTON")==1 & district_1 !="KENSINGTON" & district_1 != "CHELSEA" & district_1 != "MEDWAY"

replace subdist_1 = "" if regexm(address," WOOD GREEN")==1 & district_1 != "EDMONTON" 
replace parish_1 = "" if regexm(address," WOOD GREEN")==1 & district_1 != "EDMONTON"
replace district_1 = "EDMONTON" if regexm(address," WOOD GREEN")==1 
replace county_1 = "MIDDLESEX" if regexm(address," WOOD GREEN")==1 

replace subdist_1 = "" if regexm(address," HAMPSTEAD")==1 & regexm(address,"HAMPSTEAD ROAD")==0 & district_1 != "WOKINGHAM" & district_1 != "HERTFORD" & district_1 ! = "HAMPSHIRE"
replace parish_1 = "" if regexm(address," HAMPSTEAD")==1 & regexm(address,"HAMPSTEAD ROAD")==0 & district_1 != "WOKINGHAM" & district_1 != "HERTFORD" & district_1 ! = "HAMPSHIRE"
replace county_1 = "MIDDLESEX" if regexm(address," HAMPSTEAD")==1 & regexm(address,"HAMPSTEAD ROAD")==0 & district_1 != "WOKINGHAM" & district_1 != "HERTFORD"
replace district_1 = "HAMPSTEAD" if regexm(address," HAMPSTEAD")==1 & regexm(address,"HAMPSTEAD ROAD")==0 & district_1 != "WOKINGHAM" & district_1 != "HERTFORD"

replace subdist_1 = "" if regexm(address,"NORWOOD")==1 & district_1 !="CROYDON" & district_1 != "READMISSION" & district_1 != "LAMBETH"
replace parish_1 = "LAMBETH" if regexm(address,"NORWOOD")==1 & district_1 !="CROYDON" & district_1 != "READMISSION" & district_1 != "LAMBETH"
replace county_1 = "SURREY" if regexm(address,"NORWOOD")==1 & district_1 !="CROYDON" & district_1 != "READMISSION"
replace district_1 = "LAMBETH" if regexm(address,"NORWOOD")==1 & district_1 !="CROYDON" & district_1 != "READMISSION"

replace district_1 = "WEST HAM" if regexm(address,"STRATFORD$")==1
replace subdist_1 = "WEST HAM" if regexm(address,"STRATFORD$")==1
replace parish_1 = "WEST HAM" if regexm(address,"STRATFORD$")==1
replace county_1 = "ESSEX" if regexm(address,"STRATFORD$")==1

replace subdist_1 = "" if regexm(address,"BERMONDSEY")==1 & district_1 != "ST OLAVE SOUTHWARK"
replace parish_1 = "BERMONDSEY" if regexm(address,"BERMONDSEY")==1
replace county_1 = "SURREY" if regexm(address,"BERMONDSEY")==1 
replace district_1 = "ST OLAVE SOUTHWARK" if regexm(address,"BERMONDSEY")==1

replace subdist_1 = "" if regexm(address,"SWANLEY")==1 & district_1 != "READMISSION" & district_1 != "DARTFORD" 
replace parish_1 = "" if regexm(address,"SWANLEY")==1 & district_1 != "READMISSION" & district_1 != "DARTFORD"
replace county_1 = "KENT" if regexm(address,"SWANLEY")==1 & district_1 != "READMISSION"
replace district_1 = "DARTFORD" if regexm(address,"SWANLEY")==1 & district_1 != "READMISSION"

replace district_1 = "HOLBORN" if regexm(address,"CLERKENWELL")==1 & regexm(address,"MOUNT PLEASANT")==1
replace subdist_1 = "AMWELL" if regexm(address,"CLERKENWELL")==1 & regexm(address,"MOUNT PLEASANT")==1
replace parish_1 = "CLERKENWELL" if regexm(address,"CLERKENWELL")==1 & regexm(address,"MOUNT PLEASANT")==1
replace county_1 = "MIDDLESEX" if regexm(address,"CLERKENWELL")==1 & regexm(address,"MOUNT PLEASANT")==1

replace district_1 = "HOLBORN" if regexm(address,"CLERKENWELL CLOSE")==1 | regexm(address,"CLERKENWELL GREEN")==1
replace subdist_1 = "ST JAMES CLERKENWELL" if regexm(address,"CLERKENWELL CLOSE")==1 | regexm(address,"CLERKENWELL GREEN")==1
replace parish_1 = "CLERKENWELL" if regexm(address,"CLERKENWELL CLOSE")==1 | regexm(address,"CLERKENWELL GREEN")==1
replace county_1 = "MIDDLESEX" if regexm(address,"CLERKENWELL CLOSE")==1 | regexm(address,"CLERKENWELL GREEN")==1

replace district_1 = "POPLAR" if regexm(address,"MILLWALL")==1
replace subdist_1 = "POPLAR" if regexm(address,"MILLWALL")==1
replace parish_1 = "POPLAR" if regexm(address,"MILLWALL")==1
replace county_1 = "MIDDLESEX" if regexm(address,"MILLWALL")==1

replace subdist_1 = "" if regexm(address,"CLERKENWELL ROAD")==1 | regexm(address,"CLERKENWELL SQUARE")==1 | regexm(address,"CLERKENWELL WORKHOUSE")==1 & district_1 != "HOLBORN"
replace parish_1 = "CLERKENWELL" if regexm(address,"CLERKENWELL ROAD")==1 | regexm(address,"CLERKENWELL SQUARE")==1 | regexm(address,"CLERKENWELL WORKHOUSE")==1 & district_1 != "HOLBORN"
replace county_1 = "MIDDLESEX" if regexm(address,"CLERKENWELL ROAD")==1 | regexm(address,"CLERKENWELL SQUARE")==1 | regexm(address,"CLERKENWELL WORKHOUSE")==1 & district_1 != "HOLBORN"
replace district_1 = "HOLBORN" if regexm(address,"CLERKENWELL ROAD")==1 | regexm(address,"CLERKENWELL SQUARE")==1 | regexm(address,"CLERKENWELL WORKHOUSE")==1 & district_1 != "HOLBORN"

replace subdist_1 = "" if regexm(address,"GOSWELL ROAD")==1 & district_1 != "HOLBORN"
replace parish_1 = "" if regexm(address,"GOSWELL ROAD")==1 & district_1 != "HOLBORN"
replace county_1 = "MIDDLESEX" if regexm(address,"GOSWELL ROAD")==1 & district_1 != "HOLBORN"
replace district_1 = "HOLBORN" if regexm(address,"GOSWELL ROAD")==1 & district_1 != "HOLBORN"

replace district_1 = "HOLBORN" if regexm(address,"GOSWELL")==1 & district_1 != "HOLBORN" & district_1 != "LONDON CITY" & district_1 != "BETHNAL GREEN" & district_1 != "ISLINGTON" & district_1 != "STRAND"
replace subdist_1 = "GOSWELL STREET" if regexm(address,"GOSWELL")==1 & district_1 != "HOLBORN" & district_1 != "LONDON CITY" & district_1 != "BETHNAL GREEN" & district_1 != "ISLINGTON" & district_1 != "STRAND"
replace parish_1 = "CLERKENWELL" if regexm(address,"GOSWELL")==1 & district_1 != "HOLBORN" & district_1 != "LONDON CITY" & district_1 != "BETHNAL GREEN" & district_1 != "ISLINGTON" & district_1 != "STRAND"
replace county_1 = "MIDDLESEX" if regexm(address,"GOSWELL")==1 & district_1 != "HOLBORN" & district_1 != "LONDON CITY" & district_1 != "BETHNAL GREEN" & district_1 != "ISLINGTON" & district_1 != "STRAND"

replace district_1 = "HOLBORN" if regexm(address,"ST JOHN ST ROAD")==1
replace subdist_1 = "GOSWELL STREET" if regexm(address,"ST JOHN ST ROAD")==1
replace parish_1 = "CLERKENWELL" if regexm(address,"ST JOHN ST ROAD")==1
replace county_1 = "MIDDLESEX" if regexm(address,"ST JOHN ST ROAD")==1

replace district_1 = "HOLBORN" if regexm(address,"ST JOHN ST")==1 & regexm(address,"NORTHAMPTON")==1
replace subdist_1 = "ST JAMES CLERKENWELL" if regexm(address,"ST JOHN ST")==1 & regexm(address,"NORTHAMPTON")==1
replace parish_1 = "CLERKENWELL" if regexm(address,"ST JOHN ST")==1 & regexm(address,"NORTHAMPTON")==1
replace county_1 = "MIDDLESEX" if regexm(address,"ST JOHN ST")==1 & regexm(address,"NORTHAMPTON")==1

replace subdist_1 = "" if regexm(address,"ST JOHN ST")==1 & district_1 == "" & postcode == "EC"
replace parish_1 = "" if regexm(address,"ST JOHN ST")==1 & district_1 == "" & postcode == "EC"
replace county_1 = "MIDDLESEX" if regexm(address,"ST JOHN ST")==1 & district_1 == "" & postcode == "EC"
replace district_1 = "HOLBORN" if regexm(address,"ST JOHN ST")==1 & district_1 == "" & postcode == "EC"

replace subdist_1 = "WHITECROSS STREET" if regexm(address,"GOLDEN LANE")==1 & (district_1 != "HOLBORN" & district_1 != "LONDON CITY")
replace parish_1 = "ST LUKE" if regexm(address,"GOLDEN LANE")==1 & (district_1 != "HOLBORN" & district_1 != "LONDON CITY")
replace county_1 = "MIDDLESEX" if regexm(address,"GOLDEN LANE")==1 & (district_1 != "HOLBORN" & district_1 != "LONDON CITY")
replace district_1 = "HOLBORN" if regexm(address,"GOLDEN LANE")==1 & (district_1 != "HOLBORN" & district_1 != "LONDON CITY")

replace district_1 = "WHITECHAPEL" if regexm(address,"COMMERCIAL ST") & (regexm(address,"ROTH") | regexm(address,"NATH") | regexm(address,"WORTH"))
replace subdist_1 = "SPITALFIELDS" if regexm(address,"COMMERCIAL ST") & (regexm(address,"ROTH") | regexm(address,"NATH") | regexm(address,"WORTH"))
replace parish_1 = "SPITALFIELDS" if regexm(address,"COMMERCIAL ST") & (regexm(address,"ROTH") | regexm(address,"NATH") | regexm(address,"WORTH"))
replace county_1 = "MIDDLESEX" if regexm(address,"COMMERCIAL ST") & (regexm(address,"ROTH") | regexm(address,"NATH") | regexm(address,"WORTH"))

replace district_1 = "WHITECHAPEL" if regexm(address,"COMMERCIAL ST") & district_1 != "ST GEORGE IN THE EAST"
replace subdist_1 = "SPITALFIELDS" if regexm(address,"COMMERCIAL ST") & district_1 != "ST GEORGE IN THE EAST"
replace parish_1 = "SPITALFIELDS" if regexm(address,"COMMERCIAL ST") & district_1 != "ST GEORGE IN THE EAST"
replace county_1 = "MIDDLESEX" if regexm(address,"COMMERCIAL ST") & district_1 != "ST GEORGE IN THE EAST"

replace district_1 = district_2 if regexm(address,"KINGSLAND")==1 & county_1 != "MIDDLESEX" & county_2 == "MIDDLESEX"
replace subdist_1 = subdist_2 if regexm(address,"KINGSLAND")==1 & county_1 != "MIDDLESEX" & county_2 == "MIDDLESEX" 
replace parish_1 = parish_2 if regexm(address,"KINGSLAND")==1 & county_1 != "MIDDLESEX" & county_2 == "MIDDLESEX"
replace county_1 = county_2 if regexm(address,"KINGSLAND")==1 & county_1 != "MIDDLESEX" & county_2 == "MIDDLESEX"

replace subdist_1 = subdist_2 if regexm(address,"KINGSLAND")==1 & (district_1!="ISLINGTON" & district_1!="HACKNEY" & district_1!="SHOREDITCH") & (district_2=="ISLINGTON" | district_2=="HACKNEY" | district_2=="SHOREDITCH")
replace parish_1 = parish_2 if regexm(address,"KINGSLAND")==1 & (district_1!="ISLINGTON" & district_1!="HACKNEY" & district_1!="SHOREDITCH") & (district_2=="ISLINGTON" | district_2=="HACKNEY" | district_2=="SHOREDITCH")
replace county_1 = county_2 if regexm(address,"KINGSLAND")==1 & (district_1!="ISLINGTON" & district_1!="HACKNEY" & district_1!="SHOREDITCH") & (district_2=="ISLINGTON" | district_2=="HACKNEY" | district_2=="SHOREDITCH")
replace district_1 = district_2 if regexm(address,"KINGSLAND")==1 & (district_1!="ISLINGTON" & district_1!="HACKNEY" & district_1!="SHOREDITCH") & (district_2=="ISLINGTON" | district_2=="HACKNEY" | district_2=="SHOREDITCH")

replace district_1 = "ISLINGTON" if regexm(address,"KINGSLAND")==1 & regexm(address,"PHILIP ST")==1
replace subdist_1 = "ISLINGTON EAST" if regexm(address,"KINGSLAND")==1 & regexm(address,"PHILIP ST")==1
replace parish_1 = "ISLINGTON" if regexm(address,"KINGSLAND")==1 & regexm(address,"PHILIP ST")==1
replace county_1 = "MIDDLESEX" if regexm(address,"KINGSLAND")==1 & regexm(address,"PHILIP ST")==1

replace district_1 = "SHOREDITCH" if regexm(address,"^KINGSLAND R")==1 & stnum<100
replace subdist_1 = "ST LEONARD" if regexm(address,"^KINGSLAND R")==1 & stnum<100
replace parish_1 = "SHOREDITCH" if regexm(address,"^KINGSLAND R")==1 & stnum<100
replace county_1 = "MIDDLESEX" if regexm(address,"^KINGSLAND R")==1 & stnum<100

replace district_1 = "SHOREDITCH" if regexm(address,"^KINGSLAND R")==1 & stnum>100 & stnum<300
replace subdist_1 = "HAGGERSTON" if regexm(address,"^KINGSLAND R")==1 & stnum>100 & stnum<300
replace parish_1 = "SHOREDITCH" if regexm(address,"^KINGSLAND R")==1 & stnum>100 & stnum<300
replace county_1 = "MIDDLESEX" if regexm(address,"^KINGSLAND R")==1 & stnum>100 & stnum<300

replace district_1 = "" if regexm(address,"KINGSLAND")==1 & (district_1!="ISLINGTON" & district_1!="HACKNEY" & district_1!="SHOREDITCH")
replace subdist_1 = "" if regexm(address,"KINGSLAND")==1 & (district_1!="ISLINGTON" & district_1!="HACKNEY" & district_1!="SHOREDITCH")
replace parish_1 = "" if regexm(address,"KINGSLAND")==1 & (district_1!="ISLINGTON" & district_1!="HACKNEY" & district_1!="SHOREDITCH")
replace county_1 = "" if regexm(address,"KINGSLAND")==1 & (district_1!="ISLINGTON" & district_1!="HACKNEY" & district_1!="SHOREDITCH")

replace district_1 = "" if regexm(address,"DALSTON")==1 & (district_1!="ISLINGTON" & district_1!="HACKNEY" & district_1!="SHOREDITCH")
replace subdist_1 = "" if regexm(address,"DALSTON")==1 & (district_1!="ISLINGTON" & district_1!="HACKNEY" & district_1!="SHOREDITCH")
replace parish_1 = "" if regexm(address,"DALSTON")==1 & (district_1!="ISLINGTON" & district_1!="HACKNEY" & district_1!="SHOREDITCH")
replace county_1 = "" if regexm(address,"DALSTON")==1 & (district_1!="ISLINGTON" & district_1!="HACKNEY" & district_1!="SHOREDITCH")

replace district_1 = "HOLBORN" if regexm(address,"LEATHER LANE")==1
replace subdist_1 = "ST ANDREW EASTERN" if regexm(address,"LEATHER LANE")==1
replace parish_1 = "ST ANDREW HOLBORN ABOVE THE BARS AND ST GEORGE THE MARTYR" if regexm(address,"LEATHER LANE")==1
replace county_1 = "MIDDLESEX" if regexm(address,"LEATHER LANE")==1

replace county_1 = "SURREY" if regexm(address,"BLACKFRIAR(S)* ROAD")==1 & district_1 != "ST SAVIOUR SOUTHWARK" & district_1 != "LAMBETH"
replace district_1 = "ST SAVIOUR SOUTHWARK" if regexm(address,"BLACKFRIAR(S)* ROAD")==1 & district_1 != "ST SAVIOUR SOUTHWARK" & district_1 != "LAMBETH"

replace county_1 = "SURREY" if regexm(address,"BLACKFRIAR(S)*$")==1 & regexm(address,"CORNWALL ROAD")==1 & district_1 != "ST SAVIOUR SOUTHWARK" & district_1 != "LAMBETH"
replace subdist_1 = "WATERLOO ROAD FIRST" if regexm(address,"BLACKFRIAR(S)*$")==1 & regexm(address,"CORNWALL ROAD")==1 & district_1 != "ST SAVIOUR SOUTHWARK" & district_1 != "LAMBETH"
replace parish_1 = "LAMBETH" if regexm(address,"BLACKFRIAR(S)*$")==1 & regexm(address,"CORNWALL ROAD")==1 & district_1 != "ST SAVIOUR SOUTHWARK" & district_1 != "LAMBETH"
replace district_1 = "LAMBETH" if regexm(address,"BLACKFRIAR(S)*$")==1 & regexm(address,"CORNWALL ROAD")==1 & district_1 != "ST SAVIOUR SOUTHWARK" & district_1 != "LAMBETH"

replace county_1 = "SURREY" if regexm(address,"BLACKFRIAR(S)*")==1 & district_1 != "ST SAVIOUR SOUTHWARK" & district_1 != "LAMBETH" & regexm(address,"BLACKFRIAR(S)* ROAD")==0
replace district_1 = "LAMBETH, ST SAVIOUR SOUTHWARK" if regexm(address,"BLACKFRIAR(S)*")==1 & district_1 != "ST SAVIOUR SOUTHWARK" & district_1 != "LAMBETH" & regexm(address,"BLACKFRIAR(S)* ROAD")==0

replace district_1 = "ST SAVIOUR SOUTHWARK" if address == "AQUINAS STREET, BLACKFRIARS"
replace county_1 = "SURREY" if address == "AQUINAS STREET, BLACKFRIARS"

replace county_1 = "SURREY" if regexm(address,"BLACKFRIAR")==1 & regexm(address,"MITRE ST")==1 
replace subdist_1 = "WATERLOO ROAD FIRST" if regexm(address,"BLACKFRIAR")==1 & regexm(address,"MITRE ST")==1 
replace parish_1 = "LAMBETH" if regexm(address,"BLACKFRIAR")==1 & regexm(address,"MITRE ST")==1 
replace district_1 = "LAMBETH" if regexm(address,"BLACKFRIAR")==1 & regexm(address,"MITRE ST")==1 

replace district_1 = "ST SAVIOUR SOUTHWARK" if regexm(address,"BLACKFRIARS")==1 & postcode == "SE" & district_1 !="ST SAVIOUR SOUTHWARK" & district_1 != "LAMBETH"
replace county_1 = "SURREY" if regexm(address,"BLACKFRIARS")==1 & postcode == "SE" & district_1 !="ST SAVIOUR SOUTHWARK" & district_1 != "LAMBETH"

replace district_1 = "LONDON CITY" if regexm(address,"BLACKFRIARS")==1 & regexm(address,"NEW BRIDGE ST")==1
replace subdist_1 = "" if regexm(address,"BLACKFRIARS")==1 & regexm(address,"NEW BRIDGE ST")==1
replace parish_1 = "" if regexm(address,"BLACKFRIARS")==1 & regexm(address,"NEW BRIDGE ST")==1
replace county_1 = "MIDDLESEX" if regexm(address,"BLACKFRIARS")==1 & regexm(address,"NEW BRIDGE ST")==1

replace district_1 = "CHRISTCHURCH" if regexm(address,"BOURNEMOUTH$")
replace county_1 = "HAMPSHIRE" if regexm(address,"BOURNEMOUTH$")

replace district_1 = "SHOREDITCH" if regexm(address,"CITY R(OA)*D")==1 & regexm(address,"WESTMORELAND")==1
replace subdist_1 = "HOXTON NEW TOWN" if regexm(address,"CITY R(OA)*D")==1 & regexm(address,"WESTMORELAND")==1
replace parish_1 = "SHOREDITCH" if regexm(address,"CITY R(OA)*D")==1 & regexm(address,"WESTMORELAND")==1
replace county_1 = "MIDDLESEX" if regexm(address,"CITY R(OA)*D")==1 & regexm(address,"WESTMORELAND")==1

replace subdist_1 = "BELGRAVE" if regexm(address,"PIMLICO")==1 & district_1 != "ST GEORGE HANOVER SQUARE" & district_1 != "CHELSEA" & district_1 != "KENSINGTON"
replace parish_1 = "ST GEORGE HANOVER SQUARE" if regexm(address,"PIMLICO")==1 & district_1 != "ST GEORGE HANOVER SQUARE" & district_1 != "CHELSEA" & district_1 != "KENSINGTON"
replace county_1 = "MIDDLESEX" if regexm(address,"PIMLICO")==1 & district_1 != "ST GEORGE HANOVER SQUARE" & district_1 != "CHELSEA" & district_1 != "KENSINGTON"
replace district_1 = "ST GEORGE HANOVER SQUARE" if regexm(address,"PIMLICO")==1 & district_1 != "ST GEORGE HANOVER SQUARE" & district_1 != "CHELSEA" & district_1 != "KENSINGTON"

replace district_1 = "KINGSTON" if regexm(address,"WIMBLEDON")==1
replace subdist_1 = "WIMBLEDON" if regexm(address,"WIMBLEDON")==1
replace parish_1 = "WIMBLEDON" if regexm(address,"WIMBLEDON")==1
replace county_1 = "SURREY" if regexm(address,"WIMBLEDON")==1

replace district_1 = "CARDIFF" if regexm(address,"CARDIFF")==1 & regexm(address,"CARDIFF ROAD")==0
replace subdist_1 = "CARDIFF" if regexm(address,"CARDIFF")==1 & regexm(address,"CARDIFF ROAD")==0
replace parish_1 = "CARDIFF" if regexm(address,"CARDIFF")==1 & regexm(address,"CARDIFF ROAD")==0
replace county_1 = "GLAMORGANSHIRE" if regexm(address,"CARDIFF")==1 & regexm(address,"CARDIFF ROAD")==0

replace district_1 = "HOLBORN" if regexm(address,"SAFFRON HILL")==1
replace subdist_1 = "SAFFRON HILL" if regexm(address,"SAFFRON HILL")==1
replace parish_1 = "SAFFRON HILL HATTON GARDEN ELY RENTS AND ELY PLACE" if regexm(address,"SAFFRON HILL")==1
replace county_1 = "MIDDLESEX" if regexm(address,"SAFFRON HILL")==1

replace district_1 = "HOLBORN" if regexm(address,"RATCLIFF(E)*")==1 & (regexm(address,"GROVE")==1 | regexm(address,"G(AR)*D(E)*NS")==1)
replace subdist_1 = "CITY ROAD" if regexm(address,"RATCLIFF(E)*")==1 & (regexm(address,"GROVE")==1 | regexm(address,"G(AR)*D(E)*NS")==1)
replace parish_1 = "ST LUKE" if regexm(address,"RATCLIFF(E)*")==1 & (regexm(address,"GROVE")==1 | regexm(address,"G(AR)*D(E)*NS")==1)
replace county_1 = "MIDDLESEX" if regexm(address,"RATCLIFF(E)*")==1 & (regexm(address,"GROVE")==1 | regexm(address,"G(AR)*D(E)*NS")==1)

replace subdist_1 = "RATCLIFF" if regexm(address,"RATCLIFF(E)*")==1 & district_1 == ""
replace parish_1 = "RATCLIFF" if regexm(address,"RATCLIFF(E)*")==1 & district_1 == ""
replace county_1 = "MIDDLESEX" if regexm(address,"RATCLIFF(E)*")==1 & district_1 == ""
replace district_1 = "STEPNEY" if regexm(address,"RATCLIFF(E)*")==1 & district_1 == ""

replace district_1 = "WEST HAM" if regexm(address,"PLAISTOW")==1 & cty1!="SUSSEX"
replace subdist_1 = "WEST HAM" if regexm(address,"PLAISTOW")==1 & cty1!="SUSSEX"
replace parish_1 = "WEST HAM" if regexm(address,"PLAISTOW")==1 & cty1!="SUSSEX"
replace county_1 = "ESSEX" if regexm(address,"PLAISTOW")==1 & cty1!="SUSSEX"

replace district_1 = "ROMFORD" if regexm(address,"BARKINGSIDE")==1
replace subdist_1 = "ILFORD" if regexm(address,"BARKINGSIDE")==1
replace parish_1 = "BARKING" if regexm(address,"BARKINGSIDE")==1
replace county_1 = "ESSEX" if regexm(address,"BARKINGSIDE")==1

replace district_1 = "FROME" if regexm(address, "FROME UNION")==1
replace subdist_1 = "FROME" if regexm(address, "FROME UNION")==1
replace parish_1 = "FROME" if regexm(address, "FROME UNION")==1
replace county_1 = "SOMERSET" if regexm(address, "FROME UNION")==1

replace subdist_1 = "" if regexm(address,"HIGHGATE HILL")==1
replace parish_1 = "" if regexm(address,"HIGHGATE HILL")==1
replace county_1 = "MIDDLESEX" if regexm(address,"HIGHGATE HILL")==1
replace district_1 = "ISLINGTON" if regexm(address,"HIGHGATE HILL")==1

replace county_1 = "MIDDLESEX" if regexm(address,"HIGHGATE")==1 & (regexm(address,"COLERIDGE")==1 | regexm(address,"COLLEGE")) & district_1 != "EDMONTON"
replace district_1 = "EDMONTON" if regexm(address,"HIGHGATE")==1 & (regexm(address,"COLERIDGE")==1 | regexm(address,"COLLEGE")) & district_1 != "EDMONTON"

replace county_1 = "MIDDLESEX" if regexm(address,"HIGHGATE")==1 & regexm(address,"HOLBORN")==1 & district_1 != "ISLINGTON"
replace district_1 = "ISLINGTON" if regexm(address,"HIGHGATE")==1 & regexm(address,"HOLBORN")==1 & district_1 != "ISLINGTON"

replace district_1 = "HOLBORN" if regexm(address,"^KING(S)*( )*CROSS R(OA)*D")==1 & stnum<110
replace subdist_1 = "AMWELL" if regexm(address,"^KING(S)*( )*CROSS R(OA)*D")==1 & stnum<110
replace parish_1 = "CAMBERWELL" if regexm(address,"^KING(S)*( )*CROSS R(OA)*D")==1 & stnum<110
replace county_1 = "MIDDLESEX" if regexm(address,"^KING(S)*( )*CROSS R(OA)*D")==1 & stnum<110

replace district_1 = "HOLBORN" if regexm(address,"^KING(S)*( )*CROSS R(OA)*D")==1 & stnum>109 & stnum <169
replace subdist_1 = "PENTONVILLE" if regexm(address,"^KING(S)*( )*CROSS R(OA)*D")==1 & stnum>109 & stnum <169
replace parish_1 = "CAMBERWELL" if regexm(address,"^KING(S)*( )*CROSS R(OA)*D")==1 & stnum>109 & stnum <169
replace county_1 = "MIDDLESEX" if regexm(address,"^KING(S)*( )*CROSS R(OA)*D")==1 & stnum>109 & stnum <169

replace district_1 = "PANCRAS" if regexm(address,"^KING(S)*( )*CROSS R(OA)*D")==1 & stnum>168
replace subdist_1 = "GRAYS INN LANE" if regexm(address,"^KING(S)*( )*CROSS R(OA)*D")==1 & stnum>168
replace parish_1 = "ST PANCRAS" if regexm(address,"^KING(S)*( )*CROSS R(OA)*D")==1 & stnum>168
replace county_1 = "MIDDLESEX" if regexm(address,"^KING(S)*( )*CROSS R(OA)*D")==1 & stnum>168

replace district_1 = "HOLBORN" if regexm(address,"KING(S)*( )*CROSS R(OA)*D")==1 & regexm(address,"ROWTON")==1
replace subdist_1 = "AMWELL" if regexm(address,"KING(S)*( )*CROSS R(OA)*D")==1 & regexm(address,"ROWTON")==1
replace parish_1 = "CAMBERWELL" if regexm(address,"KING(S)*( )*CROSS R(OA)*D")==1 & regexm(address,"ROWTON")==1
replace county_1 = "MIDDLESEX" if regexm(address,"KING(S)*( )*CROSS R(OA)*D")==1 & regexm(address,"ROWTON")==1

replace district_1 = "HOLBORN" if regexm(address,"KING(S)*( )*CROSS R(OA)*D")==1 & regexm(address,"MODEL B")==1
replace subdist_1 = "PENTONVILLE" if regexm(address,"KING(S)*( )*CROSS R(OA)*D")==1 & regexm(address,"MODEL B")==1
replace parish_1 = "CAMBERWELL" if regexm(address,"KING(S)*( )*CROSS R(OA)*D")==1 & regexm(address,"MODEL B")==1
replace county_1 = "MIDDLESEX" if regexm(address,"KING(S)*( )*CROSS R(OA)*D")==1 & regexm(address,"MODEL B")==1

replace district_1 = "ISLINGTON" if regexm(address,"KING(S)*( )*CROSS") & regexm(address,"R[A|E]NDALL")
replace subdist_1 = "ISLINGTON WEST" if regexm(address,"KING(S)*( )*CROSS") & regexm(address,"R[A|E]NDALL")
replace parish_1 = "ISLINGTON" if regexm(address,"KING(S)*( )*CROSS") & regexm(address,"R[A|E]NDALL")
replace county_1 = "MIDDLESEX" if regexm(address,"KING(S)*( )*CROSS") & regexm(address,"R[A|E]NDALL")

replace district_1 = "ISLINGTON" if regexm(address,"HORNSEY RISE") | address == "HANLEY ROAD, W HORNSEY"
replace subdist_1 = "ISLINGTON EAST" if regexm(address,"HORNSEY RISE") | address == "HANLEY ROAD, W HORNSEY"
replace parish_1 = "ISLINGTON" if regexm(address,"HORNSEY RISE") | address == "HANLEY ROAD, W HORNSEY"
replace county_1 = "MIDDLESEX" if regexm(address,"HORNSEY RISE") | address == "HANLEY ROAD, W HORNSEY"

replace subdist_1 = "" if regexm(address,"SOUTH HORNSEY")==1 & district_1 != "HACKNEY"
replace parish_1 = "" if regexm(address,"SOUTH HORNSEY")==1 & district_1 != "HACKNEY"
replace county_1 = "MIDDLESEX" if regexm(address,"SOUTH HORNSEY")==1 & district_1 != "HACKNEY"
replace district_1 = "HACKNEY" if regexm(address,"SOUTH HORNSEY")==1 & district_1 != "HACKNEY"

replace district_1 = "EDMONTON" if (regexm(address,"HORNSEY$") ==1 | regexm(address,"HORNSEY,") ==1) & regexm(address,"SOUTH HORNSEY") == 0
replace subdist_1 = "HORNSEY" if (regexm(address,"HORNSEY$") ==1 | regexm(address,"HORNSEY,") ==1) & regexm(address,"SOUTH HORNSEY") == 0
replace parish_1 = "HORNSEY" if (regexm(address,"HORNSEY$") ==1 | regexm(address,"HORNSEY,") ==1) & regexm(address,"SOUTH HORNSEY") == 0
replace county_1 = "MIDDLESEX" if (regexm(address,"HORNSEY$") ==1 | regexm(address,"HORNSEY,") ==1) & regexm(address,"SOUTH HORNSEY") == 0

replace subdist_1 = "" if regexm(address,"HORNSEY R(OA)*D") ==1 | regexm(address,"HORNSEY ST") ==1 & district_1 != "ISLINGTON"
replace parish_1 = "" if regexm(address,"HORNSEY R(OA)*D") ==1 | regexm(address,"HORNSEY ST") ==1 & district_1 != "ISLINGTON"
replace county_1 = "MIDDLESEX" if regexm(address,"HORNSEY R(OA)*D") ==1 | regexm(address,"HORNSEY ST") ==1 & district_1 != "ISLINGTON"
replace district_1 = "HORNSEY" if regexm(address,"HORNSEY R(OA)*D") ==1 | regexm(address,"HORNSEY ST") ==1 & district_1 != "ISLINGTON"

replace district_1 = "LEWISHAM" if regexm(address,"SYDENHAM")
replace subdist_1 = "LEWISHAM" if regexm(address,"SYDENHAM")
replace parish_1 = "LEWISHAM" if regexm(address,"SYDENHAM")
replace county_1 = "KENT" if regexm(address,"SYDENHAM")

replace district_1 = "LAMBETH" if regexm(address,"ALBERT EMBANKMENT")
replace subdist_1 = "LAMBETH CHURCH FIRST" if regexm(address,"ALBERT EMBANKMENT")
replace parish_1 = "LAMBETH" if regexm(address,"ALBERT EMBANKMENT") 
replace county_1 = "SURREY" if regexm(address,"ALBERT EMBANKMENT")

replace district_1 = "STRAND" if regexm(address,"EMBANKMENT") & regexm(address,"VICTORIA")
replace subdist_1 = "" if regexm(address,"EMBANKMENT") & regexm(address,"VICTORIA")
replace parish_1 = "" if regexm(address,"EMBANKMENT") & regexm(address,"VICTORIA")
replace county_1 = "MIDDLESEX" if regexm(address,"EMBANKMENT") & regexm(address,"VICTORIA")

replace district_1 = "LAMBETH" if regexm(address,"CORNWALL") & regexm(address,"STAMFORD")
replace subdist_1 = "WATERLOO ROAD FIRST" if regexm(address,"CORNWALL") & regexm(address,"STAMFORD")
replace parish_1 = "LAMBETH" if regexm(address,"CORNWALL") & regexm(address,"STAMFORD")
replace county_1 = "SURREY" if regexm(address,"CORNWALL") & regexm(address,"STAMFORD")

replace district_1 = "LAMBETH" if regexm(address,"BRIXTON$") | regexm(address,"BRIXTON,")
replace subdist_1 = "BRIXTON" if regexm(address,"BRIXTON$") | regexm(address,"BRIXTON,") & subdist_1 != "KENNINGTON SECOND"
replace parish_1 = "LAMBETH" if regexm(address,"BRIXTON$") | regexm(address,"BRIXTON,") 
replace county_1 = "SURREY" if regexm(address,"BRIXTON$") | regexm(address,"BRIXTON,")

replace district_1 = "WANDSWORTH" if regexm(address,"STREATHAM COMMON")
replace subdist_1 = "STREATHAM" if regexm(address,"STREATHAM COMMON")
replace parish_1 = "STREATHAM" if regexm(address,"STREATHAM COMMON")
replace county_1 = "SURREY" if regexm(address,"STREATHAM COMMON")

replace district_1 = "TENDRING" if regexm(address,"CLACTON[ |-]ON[ |-]SEA")
replace county_1 = "ESSEX" if regexm(address,"CLACTON[ |-]ON[ |-]SEA")

replace district_1 = "WEST HAM" if regexm(address,"VICTORIA DOCK(S)*") | regexm(address,"SILVER( )*TOWN")
replace subdist_1 = "WEST HAM" if regexm(address,"VICTORIA DOCK(S)*") | regexm(address,"SILVER( )*TOWN")
replace parish_1 = "WEST HAM" if regexm(address,"VICTORIA DOCK(S)*") | regexm(address,"SILVER( )*TOWN")
replace county_1 = "ESSEX" if regexm(address,"VICTORIA DOCK(S)*") | regexm(address,"SILVER( )*TOWN")

replace district_1 = "DARTFORD" if regexm(address,"BELVEDERE$") | regexm(address,"BELVEDERE, KENT")
replace subdist_1 = "BEXLEY" if regexm(address,"BELVEDERE$") | regexm(address,"BELVEDERE, KENT")
replace parish_1 = "ERITH" if regexm(address,"BELVEDERE$") | regexm(address,"BELVEDERE, KENT") 
replace county_1 = "KENT" if regexm(address,"BELVEDERE$") | regexm(address,"BELVEDERE, KENT")

replace district_1 = "WOOLWICH" if regexm(address,"WOOLWICH COMMON")
replace subdist_1 = "WOOLWICH ARSENAL" if regexm(address,"WOOLWICH COMMON")
replace parish_1 = "WOOLWICH" if regexm(address,"WOOLWICH COMMON")
replace county_1 = "KENT" if regexm(address,"WOOLWICH COMMON")

replace district_1 = "WOOLWICH" if regexm(address,"SOUTH WOOLWICH")
replace subdist_1 = "" if regexm(address,"SOUTH WOOLWICH")
replace parish_1 = "" if regexm(address,"SOUTH WOOLWICH")
replace county_1 = "KENT" if regexm(address,"SOUTH WOOLWICH")

replace subdist_1 = "" if regexm(address,"LEVER ST") & district_1 != "HOLBORN"
replace parish_1 = "ST LUKE" if regexm(address,"LEVER ST")
replace county_1 = "MIDDLESEX" if regexm(address,"LEVER ST")
replace district_1 = "HOLBORN" if regexm(address,"LEVER ST")

replace district_1 = "ISLINGTON" if regexm(address,"CALEDONIAN R")==1 & district_1 != "HOLBORN"
replace subdist_1 = "ISLINGTON WEST" if regexm(address,"CALEDONIAN R")==1 & district_1 != "HOLBORN"
replace parish_1 = "ISLINGTON" if regexm(address,"CALEDONIAN R")==1 & district_1 != "HOLBORN"
replace county_1 = "MIDDLESEX" if regexm(address,"CALEDONIAN R")==1 & district_1 != "HOLBORN" 

replace district_1 = "SHOREDITCH" if regexm(address," OLD ST") & regexm(address,"VINCENT")
replace subdist_1 = "ST LEONARD" if regexm(address," OLD ST") & regexm(address,"VINCENT")
replace parish_1 = "SHOREDITCH" if regexm(address," OLD ST") & regexm(address,"VINCENT") 
replace county_1 = "MIDDLESEX" if regexm(address," OLD ST") & regexm(address,"VINCENT")

replace subdist_1 = "" if (regexm(address," OLD ST")==1 | regexm(address,"^OLD ST")==1) & regexm(address,"NEW OLD")==0 & regexm(address,"WALTHAMSTOW")==0 & regexm(address,"BERMONDSEY")==0 & district_1 != "HOLBORN" & district_1 != "SHOREDITCH" & regexm(address,"SOUTHWARK")==0
replace parish_1 = "" if (regexm(address," OLD ST")==1 | regexm(address,"^OLD ST")==1) & regexm(address,"NEW OLD")==0 & regexm(address,"WALTHAMSTOW")==0 & regexm(address,"BERMONDSEY")==0 & district_1 != "HOLBORN" & district_1 != "SHOREDITCH" & regexm(address,"SOUTHWARK")==0
replace county_1 = "MIDDLESEX" if (regexm(address," OLD ST")==1 | regexm(address,"^OLD ST")==1) & regexm(address,"NEW OLD")==0 & regexm(address,"WALTHAMSTOW")==0 & regexm(address,"BERMONDSEY")==0 & district_1 != "HOLBORN" & district_1 != "SHOREDITCH" & regexm(address,"SOUTHWARK")==0
replace district_1 = "HOLBORN, SHOREDITCH" if (regexm(address," OLD ST")==1 | regexm(address,"^OLD ST")==1) & regexm(address,"NEW OLD")==0 & regexm(address,"WALTHAMSTOW")==0 & regexm(address,"BERMONDSEY")==0 & district_1 != "HOLBORN" & district_1 != "SHOREDITCH" & regexm(address,"SOUTHWARK")==0

replace subdist_1 = "" if regexm(address,"EUSTON R") & district_1 != "PANCRAS"
replace parish_1 = "ST PANCRAS" if regexm(address,"EUSTON R") 
replace county_1 = "MIDDLESEX" if regexm(address,"EUSTON R") 
replace district_1 = "PANCRAS" if regexm(address,"EUSTON R") 

replace district_1 = "HOLBORN" if regexm(address,"SUTTON ST")
replace subdist_1 = "ST JAMES CLERKENWELL" if regexm(address,"SUTTON ST")
replace parish_1 = "CLERKENWELL" if regexm(address,"SUTTON ST")
replace county_1 = "MIDDLESEX" if regexm(address,"SUTTON ST")

replace subdist_1 = "" if regexm(address,"ALDERSGATE ST") & (regexm(address,"GLASSHOUSE") | regexm(address,"MOON P(A)*SS") | regexm(address,"SHAFTESBURY")) & district_1 != "LONDON CITY"
replace parish_1 = "" if regexm(address,"ALDERSGATE ST") & (regexm(address,"GLASSHOUSE") | regexm(address,"MOON P(A)*SS") | regexm(address,"SHAFTESBURY")) & district_1 != "LONDON CITY"
replace county_1 = "MIDDLESEX" if regexm(address,"ALDERSGATE ST") & (regexm(address,"GLASSHOUSE") | regexm(address,"MOON P(A)*SS") | regexm(address,"SHAFTESBURY")) & district_1 != "LONDON CITY"
replace district_1 = "LONDON CITY" if regexm(address,"ALDERSGATE ST") & (regexm(address,"GLASSHOUSE") | regexm(address,"MOON P(A)*SS") | regexm(address,"SHAFTESBURY")) & district_1 != "LONDON CITY"

replace district_1 = "HOLBORN" if regexm(address,"HOLBORN UNION") & regexm(address,"GRAYS INN")
replace subdist_1 = "ST ANDREW EASTERN" if regexm(address,"HOLBORN UNION") & regexm(address,"GRAYS INN")
replace parish_1 = "ST ANDREW HOLBORN ABOVE THE BARS AND ST GEORGE THE MARTYR" if regexm(address,"HOLBORN UNION") & regexm(address,"GRAYS INN")
replace county_1 = "MIDDLESEX" if regexm(address,"HOLBORN UNION") & regexm(address,"GRAYS INN")

replace district_1 = "ISLINGTON" if regexm(address,"HOLBORN UNION") & regexm(address,"INFIRMARY")
replace subdist_1 = "ISLINGTON EAST" if regexm(address,"HOLBORN UNION") & regexm(address,"INFIRMARY")
replace parish_1 = "ISLINGTON" if regexm(address,"HOLBORN UNION") & regexm(address,"INFIRMARY")
replace county_1 = "MIDDLESEX" if regexm(address,"HOLBORN UNION") & regexm(address,"INFIRMARY")

replace district_1 = district_2 if regexm(address,"ALDGATE") & district_2 == "LONDON CITY"
replace parish_1 = parish_2 if regexm(address,"ALDGATE") & district_2 == "LONDON CITY"
replace subdist_1 = subdist_2 if regexm(address,"ALDGATE") & district_2 == "LONDON CITY"
replace county_1 = county_2 if regexm(address,"ALDGATE") & district_2 == "LONDON CITY"

replace district_1 = "ROCHFORD" if (regexm(address,"SOUTHEND$") | (regexm(address,"SOUTHEND") & regexm(address,"SEA"))) & regexm(address,"BILLERICAY")==0
replace subdist_1 = "" if (regexm(address,"SOUTHEND$") | (regexm(address,"SOUTHEND") & regexm(address,"SEA"))) & regexm(address,"BILLERICAY")==0
replace parish_1 = "" if (regexm(address,"SOUTHEND$") | (regexm(address,"SOUTHEND") & regexm(address,"SEA"))) & regexm(address,"BILLERICAY")==0
replace county_1 = "ESSEX" if (regexm(address,"SOUTHEND$") | (regexm(address,"SOUTHEND") & regexm(address,"SEA"))) & regexm(address,"BILLERICAY")==0

replace subdist_1 = "" if regexm(address,"NEW KENT R") & district_1 != "ST SAVIOUR SOUTHWARK"
replace parish_1 = "NEWINGTON" if regexm(address,"NEW KENT R") & district_1 != "ST SAVIOUR SOUTHWARK"
replace county_1 = "SURREY" if regexm(address,"NEW KENT R") & district_1 != "ST SAVIOUR SOUTHWARK"
replace district_1 = "ST SAVIOUR SOUTHWARK" if regexm(address,"NEW KENT R") & district_1 != "ST SAVIOUR SOUTHWARK"

replace district_1 = "WHITECHAPEL" if regexm(address,"FLOWER") & regexm(address,"DEAN")
replace subdist_1 = "SPITALFIELDS" if regexm(address,"FLOWER") & regexm(address,"DEAN")
replace parish_1 = "SPITALFIELDS" if regexm(address,"FLOWER") & regexm(address,"DEAN")
replace county_1 = "MIDDLESEX" if regexm(address,"FLOWER") & regexm(address,"DEAN")

replace district_1 = "POPLAR" if regexm(address,"ALLANMOUTH")
replace subdist_1 = "BOW" if regexm(address,"ALLANMOUTH")
replace parish_1 = "BOW" if regexm(address,"ALLANMOUTH")
replace county_1 = "MIDDLESEX" if regexm(address,"ALLANMOUTH")

replace district_1 = "ISLINGTON" if regexm(address,"NEWINGTON GR(EEN)*")
replace subdist_1 = "ISLINGTON EAST" if regexm(address,"NEWINGTON GR(EEN)*")
replace parish_1 = "ISLINGTON" if regexm(address,"NEWINGTON GR(EEN)*")
replace county_1 = "MIDDLESEX" if regexm(address,"NEWINGTON GR(EEN)*")

replace subdist_1 = "" if regexm(address,"VAUXHALL") & regexm(address,"VAUXHALL ST")==0 & district_1 != "LAMBETH"
replace parish_1 = "LAMBETH" if regexm(address,"VAUXHALL") & regexm(address,"VAUXHALL ST")==0 & district_1 != "LAMBETH"
replace county_1 = "SURREY" if regexm(address,"VAUXHALL") & regexm(address,"VAUXHALL ST")==0 & district_1 != "LAMBETH"
replace district_1 = "LAMBETH" if regexm(address,"VAUXHALL") & regexm(address,"VAUXHALL ST")==0 & district_1 != "LAMBETH"

replace district_1 = "LONDON CITY" if regexm(address,"FLEET ST")
replace subdist_1 = "ST BRIDE" if regexm(address,"FLEET ST")
replace parish_1 = "ST BRIDE" if regexm(address,"FLEET ST")
replace county_1 = "MIDDLESEX" if regexm(address,"FLEET ST")

replace subdist_1 = "" if regexm(address,"BATH ST")==1 & regexm(address,"LONDON R")==0 & district_1 != "WHITECHAPEL" & district_1 != "HOLBORN"
replace parish_1 = "" if regexm(address,"BATH ST")==1 & regexm(address,"LONDON R")==0 & district_1 != "WHITECHAPEL" & district_1 != "HOLBORN"
replace county_1 = "MIDDLESEX" if regexm(address,"BATH ST")==1 & regexm(address,"LONDON R")==0 & district_1 != "WHITECHAPEL" & district_1 != "HOLBORN"
replace district_1 = "HOLBORN" if regexm(address,"BATH ST")==1 & regexm(address,"LONDON R")==0 & district_1 != "WHITECHAPEL" & district_1 != "HOLBORN"

replace subdist_1 = "BRENTFORD" if regexm(address,"BRENTFORD") & regexm(address,"ROMFORD")==0
replace parish_1 = "" if regexm(address,"BRENTFORD") & regexm(address,"ROMFORD")==0 & district_1 != "BRENTFORD"
replace county_1 = "MIDDLESEX" if regexm(address,"BRENTFORD") & regexm(address,"ROMFORD")==0
replace district_1 = "BRENTFORD" if regexm(address,"BRENTFORD") & regexm(address,"ROMFORD")==0

replace subdist_1 = "" if regexm(address,"LITTLE BRITAIN") & regexm(address,"UXBRIDGE")==0 & district_1 != "LONDON CITY"
replace parish_1 = "" if regexm(address,"LITTLE BRITAIN") & regexm(address,"UXBRIDGE")==0 & district_1 != "LONDON CITY"
replace county_1 = "MIDDLESEX" if regexm(address,"LITTLE BRITAIN") & regexm(address,"UXBRIDGE")==0
replace district_1 = "LONDON CITY" if regexm(address,"LITTLE BRITAIN") & regexm(address,"UXBRIDGE")==0

replace subdist_1 = "" if regexm(address,"NEW BARNET") & district_1 != "BARNET"
replace parish_1 = "" if regexm(address,"NEW BARNET") & district_1 != "BARNET"
replace county_1 = "MIDDLESEX" if regexm(address,"NEW BARNET") & district_1 != "BARNET"
replace district_1 = "BARNET" if regexm(address,"NEW BARNET") & district_1 != "BARNET"

replace district_1 = "HOLBORN" if regexm(address,"COLD( )*BATH") & regexm(address,"GREENWICH")==0
replace subdist_1 = "AMWELL" if regexm(address,"COLD( )*BATH") & regexm(address,"GREENWICH")==0
replace parish_1 = "CLERKENWELL" if regexm(address,"COLD( )*BATH") & regexm(address,"GREENWICH")==0
replace county_1 = "MIDDLESEX" if regexm(address,"COLD( )*BATH") & regexm(address,"GREENWICH")==0

replace district_1 = "HOLBORN" if regexm(address,"NORTHAMPTON B")
replace subdist_1 = "GOSWELL STREET" if regexm(address,"NORTHAMPTON B")
replace parish_1 = "CLERKENWELL" if regexm(address,"NORTHAMPTON B")
replace county_1 = "MIDDLESEX" if regexm(address,"NORTHAMPTON B")

replace district_1 = district_2 if regexm(address,"WAPPING")==1 & district_2 == "ST GEORGE IN THE EAST"
replace subdist_1 = subdist_2 if regexm(address,"WAPPING")==1 & district_2 == "ST GEORGE IN THE EAST"
replace parish_1 = parish_2 if regexm(address,"WAPPING")==1 & district_2 == "ST GEORGE IN THE EAST"
replace county_1 = county_2 if regexm(address,"WAPPING")==1 & district_2 == "ST GEORGE IN THE EAST"

replace district_1 = district_3 if regexm(address,"WAPPING")==1 & district_3 == "ST GEORGE IN THE EAST"
replace subdist_1 = subdist_3 if regexm(address,"WAPPING")==1 & district_3 == "ST GEORGE IN THE EAST"
replace parish_1 = parish_3 if regexm(address,"WAPPING")==1 & district_3 == "ST GEORGE IN THE EAST"
replace county_1 = county_3 if regexm(address,"WAPPING")==1 & district_3 == "ST GEORGE IN THE EAST"

replace district_1 = "DARTFORD" if regexm(address,"BEXLEY( )*HEATH")
replace subdist_1 = "" if regexm(address,"BEXLEY( )*HEATH")
replace parish_1 = "" if regexm(address,"BEXLEY( )*HEATH")
replace county_1 = "KENT" if regexm(address,"BEXLEY( )*HEATH")

replace subdist_1 = "" if regexm(address,"BETHNAL GREEN R") & district_1 != "BETHNAL GREEN"
replace parish_1 = "BETHNAL GREEN" if regexm(address,"BETHNAL GREEN R")
replace county_1 = "MIDDLESEX" if regexm(address,"BETHNAL GREEN R")
replace district_1 = "BETHNAL GREEN" if regexm(address,"BETHNAL GREEN R") & district_1 != "BETHNAL GREEN"

replace district_1 = "LONDON CITY" if regexm(address,"BART") & regexm(address,"CLOSE")
replace subdist_1 = "ST SEPULCHRE" if regexm(address,"BART") & regexm(address,"CLOSE")
replace parish_1 = "ST BARTHOLOMEW THE GREAT" if regexm(address,"BART") & regexm(address,"CLOSE")
replace county_1 = "MIDDLESEX" if regexm(address,"BART") & regexm(address,"CLOSE")

replace district_1 = "LONDON CITY" if (regexm(address,"ST BART") & regexm(address,"HO")) | regexm(address,"THE COLLEGE") | regexm(address,"ST[,| ]B H")
replace subdist_1 = "ST SEPULCHRE" if (regexm(address,"ST BART") & regexm(address,"HO")) | regexm(address,"THE COLLEGE") | regexm(address,"ST[,| ]B H")
replace parish_1 = "ST BARTHOLOMEW THE LESS" if (regexm(address,"ST BART") & regexm(address,"HO")) | regexm(address,"THE COLLEGE") | regexm(address,"ST[,| ]B H")
replace county_1 = "MIDDLESEX" if (regexm(address,"ST BART") & regexm(address,"HO")) | regexm(address,"THE COLLEGE") | regexm(address,"ST[,| ]B H")

replace district_1 = "LONDON CITY" if regexm(address,"LOWER WHITECROSS ST")
replace subdist_1 = "CRIPPLEGATE" if regexm(address,"LOWER WHITECROSS ST")
replace parish_1 = "ST GILES WITHOUT CRIPPLEGATE" if regexm(address,"LOWER WHITECROSS ST")
replace county_1 = "MIDDLESEX" if regexm(address,"LOWER WHITECROSS ST")

replace district_1 = "HOLBORN" if regexm(address,"UPP(ER)* WHITECROSS ST")
replace subdist_1 = "WHITECROSS STREET" if regexm(address,"UPP(ER)* WHITECROSS ST")
replace parish_1 = "ST LUKE" if regexm(address,"UPP(ER)* WHITECROSS ST")
replace county_1 = "MIDDLESEX" if regexm(address,"UPP(ER)* WHITECROSS ST")
replace parish_1 = "ST LUKE" if regexm(address,"WHITECROSS ST") & district_1 == "HOLBORN"

replace subdist_1 = "ALLHALLOWS BARKING" if regexm(address,"G(REA)*T TOWER ST")
replace parish_1 = "" if regexm(address,"G(REA)*T TOWER ST") & district_1 != "LONDON CITY"
replace county_1 = "MIDDLESEX" if regexm(address,"G(REA)*T TOWER ST")
replace district_1 = "LONDON CITY" if regexm(address,"G(REA)*T TOWER ST")

replace district_1 = "ST GILES" if address == "EMPRESS BED CHAMBERS, QUEENS ST, 7 DIALS"
replace subdist_1 = "" if address == "EMPRESS BED CHAMBERS, QUEENS ST, 7 DIALS"
replace parish_1 = "" if address == "EMPRESS BED CHAMBERS, QUEENS ST, 7 DIALS"
replace county_1 = "MIDDLESEX" if address == "EMPRESS BED CHAMBERS, QUEENS ST, 7 DIALS"

replace subdist_1 = "" if regexm(address,"RED LION ST") & district_1 == ""
replace parish_1 = "CLERKENWELL" if regexm(address,"RED LION ST") & district_1 == ""
replace county_1 = "MIDDLESEX" if regexm(address,"RED LION ST") & district_1 == ""
replace district_1 = "HOLBORN" if regexm(address,"RED LION ST") & district_1 == ""

replace parish_1 = parish_2 if (parish_2 =="ST LUKE" | parish_2 == "CLERKENWELL") & regexm(address,"RED LION ST") & district_1 == "HOLBORN"
replace parish_1 = parish_3 if (parish_3 =="ST LUKE" | parish_3 == "CLERKENWELL") & regexm(address,"RED LION ST") & district_1 == "HOLBORN"

replace district_1 = "BETHNAL GREEN" if regexm(address,"MAIDSTONE PL") & regexm(address,"GOLDSMITH ROW")
replace subdist_1 = "HACKNEY ROAD" if regexm(address,"MAIDSTONE PL") & regexm(address,"GOLDSMITH ROW")
replace parish_1 = "BETHNAL GREEN" if regexm(address,"MAIDSTONE PL") & regexm(address,"GOLDSMITH ROW")
replace county_1 = "MIDDLESEX" if regexm(address,"MAIDSTONE PL") & regexm(address,"GOLDSMITH ROW")

replace district_1 = "HOLBORN" if regexm(address,"GEE ST")
replace subdist_1 = "OLD STREET" if regexm(address,"GEE ST")
replace parish_1 = "ST LUKE" if regexm(address,"GEE ST")
replace county_1 = "MIDDLESEX" if regexm(address,"GEE ST")

replace district_1 = "LAMBETH" if regexm(address,"PEABODY") & (regexm(address,"STAMFORD") | regexm(address,"DUKE ST"))
replace subdist_1 = "WATERLOO ROAD FIRST" if regexm(address,"PEABODY") & (regexm(address,"STAMFORD") | regexm(address,"DUKE ST"))
replace parish_1 = "LAMBETH" if regexm(address,"PEABODY") & (regexm(address,"STAMFORD") | regexm(address,"DUKE ST")) 
replace county_1 = "SURREY" if regexm(address,"PEABODY") & (regexm(address,"STAMFORD") | regexm(address,"DUKE ST"))

replace district_1 = "ST SAVIOUR SOUTHWARK" if regexm(address,"PEABODY") & regexm(address,"SOUTHWARK ST")
replace subdist_1 = "ST SAVIOUR SOUTHWARK" if regexm(address,"PEABODY") & regexm(address,"SOUTHWARK ST")
replace parish_1 = "ST SAVIOUR SOUTHWARK" if regexm(address,"PEABODY") & regexm(address,"SOUTHWARK ST") 
replace county_1 = "SURREY" if regexm(address,"PEABODY") & regexm(address,"STAMFORD")

replace district_1 = "ST SAVIOUR SOUTHWARK" if regexm(address,"SOUTHWARK ST") | regexm(address,"SOUTHWARK B")
replace subdist_1 = "ST SAVIOUR SOUTHWARK" if regexm(address,"SOUTHWARK ST") | regexm(address,"SOUTHWARK B")
replace parish_1 = "ST SAVIOUR SOUTHWARK" if regexm(address,"SOUTHWARK ST") | regexm(address,"SOUTHWARK B")
replace county_1 = "SURREY" if regexm(address,"SOUTHWARK ST") | regexm(address,"SOUTHWARK B")

replace subdist_1 = "" if regexm(address,"SOUTHWARK PARK R") & district_1 != "ST OLAVE SOUTHWARK"
replace parish_1 = "" if regexm(address,"SOUTHWARK PARK R") & district_1 != "ST OLAVE SOUTHWARK"
replace county_1 = "SURREY" if regexm(address,"SOUTHWARK PARK R") & district_1 != "ST OLAVE SOUTHWARK"
replace district_1 = "ST OLAVE SOUTHWARK" if regexm(address,"SOUTHWARK PARK R") & district_1 != "ST OLAVE SOUTHWARK"

replace subdist_1 = "ST OLAVE SOUTHWARK" if regexm(address,"TOOLEY ST") & parish_1 != "BERMONDSEY" & parish_1 != "HORSLEYDOWN"
replace parish_1 = "ST OLAVE SOUTHWARK" if regexm(address,"TOOLEY ST") & parish_1 != "BERMONDSEY" & parish_1 != "HORSLEYDOWN"
replace county_1 = "SURREY" if regexm(address,"TOOLEY ST")
replace district_1 = "ST OLAVE SOUTHWARK" if regexm(address,"TOOLEY ST")

replace district_1 = "ST OLAVE SOUTHWARK" if regexm(address,"ROTHERHITHE NEW ROAD")
replace subdist_1 = "ROTHERHITHE" if regexm(address,"ROTHERHITHE NEW ROAD")
replace parish_1 = "ROTHERHITHE" if regexm(address,"ROTHERHITHE NEW ROAD")
replace county_1 = "SURREY" if regexm(address,"ROTHERHITHE NEW ROAD")

replace district_1 = "LAMBETH" if (regexm(address,"WATERLOO R") | regexm(address,"AQUINAS")) & regexm(address,"DUKE ST")
replace subdist_1 = "WATERLOO ROAD FIRST" if (regexm(address,"WATERLOO R") | regexm(address,"AQUINAS")) & regexm(address,"DUKE ST")
replace parish_1 = "LAMBETH" if (regexm(address,"WATERLOO R") | regexm(address,"AQUINAS")) & regexm(address,"DUKE ST")
replace county_1 = "SURREY" if (regexm(address,"WATERLOO R") | regexm(address,"AQUINAS")) & regexm(address,"DUKE ST")

replace district_1 = "LONDON CITY" if address=="DUKE STREET"
replace subdist_1 = "ST SEPULCHRE" if address=="DUKE STREET"
replace parish_1 = "ST BARTHOLOMEW THE GREAT" if address=="DUKE STREET"
replace county_1 = "MIDDLESEX" if address=="DUKE STREET"

replace subdist_1 = "" if regexm(address,"ESSEX R") & district_1 != "ISLINGTON"
replace parish_1 = "ISLINGTON" if regexm(address,"ESSEX R") & district_1 != "ISLINGTON"
replace county_1 = "MIDDLESEX" if regexm(address,"ESSEX R") & district_1 != "ISLINGTON"
replace district_1 = "ISLINGTON" if regexm(address,"ESSEX R") & district_1 != "ISLINGTON"

replace district_1 = "SHOREDITCH" if regexm(address,"SHEPHERDESS W")
replace subdist_1 = "HOXTON NEW TOWN" if regexm(address,"SHEPHERDESS W")
replace parish_1 = "SHOREDITCH" if regexm(address,"SHEPHERDESS W") 
replace county_1 = "MIDDLESEX" if regexm(address,"SHEPHERDESS W")

replace subdist_1 = "PENTONVILLE" if regexm(address,"PENTONVILLE") & district_1 != "HOLBORN" & district_1 != "ISLINGTON"
replace parish_1 = "CLERKENWELL" if regexm(address,"PENTONVILLE") & district_1 != "HOLBORN" & district_1 != "ISLINGTON"
replace county_1 = "MIDDLESEX" if regexm(address,"PENTONVILLE") & district_1 != "HOLBORN" & district_1 != "ISLINGTON"
replace district_1 = "HOLBORN" if regexm(address,"PENTONVILLE") & district_1 != "HOLBORN" & district_1 != "ISLINGTON"

replace subdist_1 = "PENTONVILLE" if regexm(address,"PENTONVILLE") & district_1 == "HOLBORN" & subdist_1 == ""
replace parish_1 = "CLERKENWELL" if regexm(address,"PENTONVILLE") & district_1 == "HOLBORN" 

replace subdist_1 = "SAFFRON HILL" if regexm(address,"CHARTERHOUSE ST")
replace parish_1 = "SAFFRON HILL HATTON GARDEN ELY RENTS AND ELY PLACE" if regexm(address,"CHARTERHOUSE ST")
replace county_1 = "MIDDLESEX" if regexm(address,"CHARTERHOUSE ST")
replace district_1 = "HOLBORN" if regexm(address,"CHARTERHOUSE ST")

replace district_1 = "HOLBORN" if regexm(address,"HALF( )*MOON C(OUR)*T")
replace subdist_1 = "ST ANDREW EASTERN" if regexm(address,"HALF( )*MOON C(OUR)*T")
replace parish_1 = "ST ANDREW HOLBORN ABOVE THE BARS AND ST GEORGE THE MARTYR" if regexm(address,"HALF( )*MOON C(OUR)*T")
replace county_1 = "MIDDLESEX" if regexm(address,"HALF( )*MOON C(OUR)*T")

replace district_1 = "LONDON CITY" if regexm(address,"HALF( )*MOON P")
replace subdist_1 = "ST SEPULCHRE" if regexm(address,"HALF( )*MOON P")
replace parish_1 = "ST BARTHOLOMEW THE GREAT" if regexm(address,"HALF( )*MOON P")
replace county_1 = "MIDDLESEX" if regexm(address,"HALF( )*MOON P")

replace district_1 = "HASTINGS" if regexm(address,"LEONARDS[-| ]ON")
replace subdist_1 = "" if regexm(address,"LEONARDS[-| ]ON")
replace parish_1 = "" if regexm(address,"LEONARDS[-| ]ON")
replace county_1 = "SUSSEX" if regexm(address,"LEONARDS[-| ]ON")

replace district_1 = "LONDON CITY" if regexm(address,"BARBICAN") | regexm(address,"LONDON WALL")
replace subdist_1 = "CRIPPLEGATE" if regexm(address,"BARBICAN") | regexm(address,"LONDON WALL")
replace parish_1 = "ST GILES WITHOUT CRIPPLEGATE" if regexm(address,"BARBICAN") | regexm(address,"LONDON WALL")
replace county_1 = "MIDDLESEX" if regexm(address,"BARBICAN") | regexm(address,"LONDON WALL")

replace district_1 = "KENSINGTON" if regexm(address,"NOTTING HILL")
replace subdist_1 = "KENSINGTON TOWN" if regexm(address,"NOTTING HILL")
replace parish_1 = "KENSINGTON" if regexm(address,"NOTTING HILL") 
replace county_1 = "MIDDLESEX" if regexm(address,"NOTTING HILL")

replace district_1 = "WHITECHAPEL" if regexm(address,"FASHION ST")
replace subdist_1 = "SPITALFIELDS" if regexm(address,"FASHION ST")
replace parish_1 = "SPITALFIELDS" if regexm(address,"FASHION ST")
replace county_1 = "MIDDLESEX" if regexm(address,"FASHION ST")

replace district_1 = "FARNHAM" if regexm(address,"ALDERSHOT")
replace subdist_1 = "" if regexm(address,"ALDERSHOT")
replace parish_1 = "ALDERSHOT" if regexm(address,"ALDERSHOT")
replace county_1 = "HAMPSHIRE" if regexm(address,"ALDERSHOT")

replace subdist_1 = "" if (regexm(address,"LOUGHBOROUGH J") | regexm(address,"LONGHBORO")) & district_1 != "LAMBETH"
replace parish_1 = "LAMBETH" if (regexm(address,"LOUGHBOROUGH J") | regexm(address,"LONGHBORO")) & district_1 != "LAMBETH"
replace county_1 = "SURREY" if (regexm(address,"LOUGHBOROUGH J") | regexm(address,"LONGHBORO")) & district_1 != "LAMBETH"
replace district_1 = "LAMBETH" if (regexm(address,"LOUGHBOROUGH J") | regexm(address,"LONGHBORO")) & district_1 != "LAMBETH"

replace district_1 = "ST OLAVE SOUTHWARK" if regexm(address,"HORSLEY( )*DOWN")
replace subdist_1 = "ST JOHN HORSLEYDOWN" if regexm(address,"HORSLEY( )*DOWN")
replace parish_1 = "HORSLEYDOWN" if regexm(address,"HORSLEY( )*DOWN")
replace county_1 = "SURREY" if regexm(address,"HORSLEY( )*DOWN")

replace district_1 = "ISLINGTON" if regexm(address,"ISLINGTON G")
replace subdist_1 = "ISLINGTON EAST" if regexm(address,"ISLINGTON G")
replace parish_1 = "ISLINGTON" if regexm(address,"ISLINGTON G")
replace county_1 = "MIDDLESEX" if regexm(address,"ISLINGTON G")

replace district_1 = "HOLBORN" if (regexm(address,"ST JOHN(S)* L") | regexm(address,"ST JOHN(S)* SQ") | regexm(address,"ST JOHN(S)* GA")) & regexm(address,"SMITHFIELD")==0
replace subdist_1 = "ST JAMES CLERKENWELL" if (regexm(address,"ST JOHN(S)* L") | regexm(address,"ST JOHN(S)* SQ") | regexm(address,"ST JOHN(S)* GA")) & regexm(address,"SMITHFIELD")==0
replace parish_1 = "CLERKENWELL" if (regexm(address,"ST JOHN(S)* L") | regexm(address,"ST JOHN(S)* SQ") | regexm(address,"ST JOHN(S)* GA")) & regexm(address,"SMITHFIELD")==0
replace county_1 = "MIDDLESEX" if (regexm(address,"ST JOHN(S)* L") | regexm(address,"ST JOHN(S)* SQ") | regexm(address,"ST JOHN(S)* GA")) & regexm(address,"SMITHFIELD")==0

replace subdist_1 = "" if regexm(address,"HATTON G") & district_1 != "HOLBORN"
replace parish_1 = "" if regexm(address,"HATTON G") & district_1 != "HOLBORN"
replace county_1 = "MIDDLESEX" if regexm(address,"HATTON G") & district_1 != "HOLBORN"
replace district_1 = "HOLBORN" if regexm(address,"HATTON G") & district_1 != "HOLBORN"

replace district_1 = "LONDON CITY" if (regexm(address,"LONG L") & postcode=="EC") | address == "LONG LANE"
replace subdist_1 = "ST SEPULCHRE" if (regexm(address,"LONG L") & postcode=="EC") | address == "LONG LANE"
replace parish_1 = "ST BARTHOLOMEW THE GREAT" if (regexm(address,"LONG L") & postcode=="EC") | address == "LONG LANE"
replace county_1 = "MIDDLESEX" if (regexm(address,"LONG L") & postcode=="EC") | address == "LONG LANE"

replace district_1 = "ST OLAVE SOUTHWARK" if regexm(address,"LONG L") & postcode=="SE"
replace subdist_1 = "LEATHER MARKET" if regexm(address,"LONG L") & postcode=="SE"
replace parish_1 = "BERMONDSEY" if regexm(address,"LONG L") & postcode=="SE"
replace county_1 = "SURREY" if regexm(address,"LONG L") & postcode=="SE"

replace subdist_1 = "CASTLE BAYNARD" if (regexm(address," WOOD ST") | regexm(address,"^WOOD ST")) & postcode== "EC"
replace parish_1 = "" if (regexm(address," WOOD ST") | regexm(address,"^WOOD ST")) & postcode== "EC" & district_1 !="LONDON CITY"
replace county_1 = "MIDDLESEX" if (regexm(address," WOOD ST") | regexm(address,"^WOOD ST")) & postcode== "EC"
replace district_1 = "LONDON CITY" if (regexm(address," WOOD ST") | regexm(address,"^WOOD ST")) & postcode== "EC"

replace district_1 = "ST SAVIOUR SOUTHWARK" if regexm(address,"COLLING( )*WOOD") & regexm(address,"BRUNSWICK")
replace subdist_1 = "CHRISTCHURCH SOUTHWARK" if regexm(address,"COLLING( )*WOOD") & regexm(address,"BRUNSWICK")
replace parish_1 = "CHRISTCHURCH SOUTHWARK" if regexm(address,"COLLING( )*WOOD") & regexm(address,"BRUNSWICK")
replace county_1 = "SURREY" if regexm(address,"COLLING( )*WOOD") & regexm(address,"BRUNSWICK")

replace district_1 = "SHOREDITCH" if regexm(address,"COLLING( )*WOOD") & regexm(address,"SHOREDITCH")
replace subdist_1 = "HOLLYWELL" if regexm(address,"COLLING( )*WOOD") & regexm(address,"SHOREDITCH")
replace parish_1 = "SHOREDITCH" if regexm(address,"COLLING( )*WOOD") & regexm(address,"SHOREDITCH")
replace county_1 = "SURREY" if regexm(address,"COLLING( )*WOOD") & regexm(address,"SHOREDITCH")

replace subdist_1 = "" if regexm(address,"VICTORIA DW") & district_1 != "HOLBORN"
replace parish_1 = "CLERKENWELL" if regexm(address,"VICTORIA DW") & district_1 != "HOLBORN"
replace county_1 = "MIDDLESEX" if regexm(address,"VICTORIA DW") & district_1 != "HOLBORN"
replace district_1 = "HOLBORN" if regexm(address,"VICTORIA DW") & district_1 != "HOLBORN"

replace district_1 = "ISLINGTON" if regexm(address,"HOLBORN") & regexm(address,"INF")
replace subdist_1 = "ISLINGTON EAST" if regexm(address,"HOLBORN") & regexm(address,"INF")
replace parish_1 = "ISLINGTON" if regexm(address,"HOLBORN") & regexm(address,"INF")
replace county_1 = "MIDDLESEX" if regexm(address,"HOLBORN") & regexm(address,"INF")

replace district_1 = "READING" if regexm(address,"READING WORKHOUSE")
replace subdist_1 = "ST GILES" if regexm(address,"READING WORKHOUSE")
replace parish_1 = "READING ST GILES" if regexm(address,"READING WORKHOUSE")
replace county_1 = "BERKSHIRE" if regexm(address,"READING WORKHOUSE")

replace district_1 = "ST GEORGE HANOVER SQUARE" if regexm(address,"BERKELEY SQ")
replace subdist_1 = "MAYFAIR" if regexm(address,"BERKELEY SQ")
replace parish_1 = "ST GEORGE HANOVER SQUARE" if regexm(address,"BERKELEY SQ")
replace county_1 = "MIDDLESEX" if regexm(address,"BERKELEY SQ")

replace subdist_1 = "" if regexm(address,"UPPER ST,") | regexm(address,"UPPER STREET") & district_1 != "ISLINGTON"
replace parish_1 = "ISLINGTON" if regexm(address,"UPPER ST,") | regexm(address,"UPPER STREET")
replace county_1 = "MIDDLESEX" if regexm(address,"UPPER ST,") | regexm(address,"UPPER STREET")
replace district_1 = "ISLINGTON" if regexm(address,"UPPER ST,") | regexm(address,"UPPER STREET")

replace district_1 = "MARYLEBONE" if address == "ADAM & EVE CT, OXFORD ST" | (regexm(address,"OXFORD ST") & regexm(address,"ROYAL ORTH"))
replace subdist_1 = "ALL SOULS" if address == "ADAM & EVE CT, OXFORD ST" | (regexm(address,"OXFORD ST") & regexm(address,"ROYAL ORTH"))
replace parish_1 = "ST MARYLEBONE" if address == "ADAM & EVE CT, OXFORD ST" | (regexm(address,"OXFORD ST") & regexm(address,"ROYAL ORTH"))
replace county_1 = "MIDDLESEX" if address == "ADAM & EVE CT, OXFORD ST" | (regexm(address,"OXFORD ST") & regexm(address,"ROYAL ORTH"))

replace district_1 = "MARYLEBONE" if regexm(address,"JAMES ST") & regexm(address,"OXFORD ST")
replace subdist_1 = "RECTORY" if regexm(address,"JAMES ST") & regexm(address,"OXFORD ST")
replace parish_1 = "ST MARYLEBONE" if regexm(address,"JAMES ST") & regexm(address,"OXFORD ST")
replace county_1 = "MIDDLESEX" if regexm(address,"JAMES ST") & regexm(address,"OXFORD ST")

replace district_1 = "PANCRAS" if address == "WARREN ST, NR OXFORD ST"
replace subdist_1 = "TOTTENHAM COURT ROAD" if address == "WARREN ST, NR OXFORD ST"
replace parish_1 = "ST PANCRAS" if address == "WARREN ST, NR OXFORD ST" 
replace county_1 = "MIDDLESEX" if address == "WARREN ST, NR OXFORD ST"

replace subdist_1 = "" if regexm(address,"MARYLEBONE R") & district_1 != "MARYLEBONE"
replace parish_1 = "ST MARYLEBONE" if regexm(address,"MARYLEBONE R")
replace county_1 = "MIDDLESEX" if regexm(address,"MARYLEBONE R")
replace district_1 = "MARYLEBONE" if regexm(address,"MARYLEBONE R")

replace subdist_1 = "" if regexm(address,"SURBITON") & district_1 != "KINGSTON"
replace parish_1 = "" if regexm(address,"SURBITON") & district_1 != "KINGSTON"
replace county_1 = "SURREY" if regexm(address,"SURBITON") & district_1 != "KINGSTON"
replace district_1 = "KINGSTON" if regexm(address,"SURBITON") & district_1 != "KINGSTON"

replace district_1 = "ST SAVIOUR SOUTHWARK" if regexm(address,"G(REA)*T GUILDFORD ST") | (regexm(address,"GUILDFORD ST") & regexm(address,"SOUTHWARK"))
replace subdist_1 = "ST SAVIOUR SOUTHWARK" if regexm(address,"G(REA)*T GUILDFORD ST") | (regexm(address,"GUILDFORD ST") & regexm(address,"SOUTHWARK"))
replace parish_1 = "ST SAVIOUR SOUTHWARK" if regexm(address,"G(REA)*T GUILDFORD ST") | (regexm(address,"GUILDFORD ST") & regexm(address,"SOUTHWARK"))
replace county_1 = "SURREY" if regexm(address,"G(REA)*T GUILDFORD ST") | (regexm(address,"GUILDFORD ST") & regexm(address,"SOUTHWARK"))

replace district_1 = "PANCRAS" if regexm(address,"FOUNDLING")
replace subdist_1 = "" if regexm(address,"FOUNDLING")
replace parish_1 = "ST PANCRAS" if regexm(address,"FOUNDLING") 
replace county_1 = "MIDDLESEX" if regexm(address,"FOUNDLING")

replace subdist_1 = "" if regexm(address,"TEDDINGTON") & district_1 != "KINGSTON"
replace parish_1 = "" if regexm(address,"TEDDINGTON") & district_1 != "KINGSTON"
replace county_1 = "SURREY" if regexm(address,"TEDDINGTON") & district_1 != "KINGSTON"
replace district_1 = "KINGSTON" if regexm(address,"TEDDINGTON") & district_1 != "KINGSTON"

replace district_1 = "COOKHAM (MAIDENHEAD)" if regexm(address,"MAIDENHEAD")==1 & regex(address,"MAIDENHEAD C")==0
replace subdist_1 = "" if regexm(address,"MAIDENHEAD")==1 & regex(address,"MAIDENHEAD C")==0
replace parish_1 = "MAIDENHEAD" if regexm(address,"MAIDENHEAD")==1 & regex(address,"MAIDENHEAD C")==0
replace county_1 = "BERKSHIRE" if regexm(address,"MAIDENHEAD")==1 & regex(address,"MAIDENHEAD C")==0

replace district_1 = "WANDSWORTH" if regexm(address,"LAVENDER HILL") & regexm(address,"TONBRIDGE")==0 & regexm(address,"ROTHERHITHE")==0
replace subdist_1 = "BATTERSEA" if regexm(address,"LAVENDER HILL") & regexm(address,"TONBRIDGE")==0 & regexm(address,"ROTHERHITHE")==0
replace parish_1 = "BATTERSEA" if regexm(address,"LAVENDER HILL") & regexm(address,"TONBRIDGE")==0 & regexm(address,"ROTHERHITHE")==0
replace county_1 = "SURREY" if regexm(address,"LAVENDER HILL") & regexm(address,"TONBRIDGE")==0 & regexm(address,"ROTHERHITHE")==0

replace subdist_1 = "" if regexm(address,"HOLLOWAY R") & district_1 != "ISLINGTON"
replace parish_1 = "ISLINGTON" if regexm(address,"HOLLOWAY R") & district_1 != "ISLINGTON"
replace county_1 = "MIDDLESEX" if regexm(address,"HOLLOWAY R") & district_1 != "ISLINGTON"
replace district_1 = "ISLINGTON" if regexm(address,"HOLLOWAY R") & district_1 != "ISLINGTON"

replace district_1 = "HOLBORN" if regexm(address,"CLERKENWELL G")
replace subdist_1 = "ST JAMES CLERKENWELL" if regexm(address,"CLERKENWELL G")
replace parish_1 = "CLERKENWELL" if regexm(address,"CLERKENWELL G")
replace county_1 = "MIDDLESEX" if regexm(address,"CLERKENWELL G")

replace subdist_1 = "" if regexm(address,"RED HILL") & district_1 !="REIGATE"
replace parish_1 = "" if regexm(address,"RED HILL") & district_1 !="REIGATE"
replace county_1 = "SURREY" if regexm(address,"RED HILL") & district_1 !="REIGATE"
replace district_1 = "REIGATE" if regexm(address,"RED HILL") & district_1 !="REIGATE"

replace district_1 = "STROUD" if regexm(address,"GLOUCESTERSHIRE") & regexm(address,"STROUD")

* Multiple district cases 

replace subdist_1 = "" if regexm(address,"OLD FORD")==1 & (district_1 != "POPLAR" & district_1 != "BETHNAL GREEN")
replace parish_1 = "" if regexm(address,"OLD FORD")==1 & (district_1 != "POPLAR" & district_1 != "BETHNAL GREEN")
replace county_1 = "MIDDLESEX" if regexm(address,"OLD FORD")==1 & (district_1 != "POPLAR" & district_1 != "BETHNAL GREEN")
replace district_1 = "BETHNAL GREEN, POPLAR" if regexm(address,"OLD FORD")==1 & (district_1 != "POPLAR" & district_1 != "BETHNAL GREEN")

replace district_1 = "" if regexm(address,"BRICK LANE")==1 & district_1!="BETHNAL GREEN" & district_1 != "WHITECHAPEL"
replace subdist_1 = "" if regexm(address,"BRICK LANE")==1 & district_1!="BETHNAL GREEN" & district_1 != "WHITECHAPEL"
replace parish_1 = "" if regexm(address,"BRICK LANE")==1 & district_1!="BETHNAL GREEN" & district_1 != "WHITECHAPEL"
replace county_1 = "" if regexm(address,"BRICK LANE")==1 & district_1!="BETHNAL GREEN" & district_1 != "WHITECHAPEL"

replace county_1 = "MIDDLESEX" if regexm(address,"BRICK LANE")==1 & district_1 == ""
replace district_1 = "BETHNAL GREEN, WHITECHAPEL" if regexm(address,"BRICK LANE")==1 & district_1 == ""

replace subdist_1 = "" if regexm(address,"MINORIES")==1 & district_1 != "LONDON CITY" & district_1 != "WHITECHAPEL"
replace parish_1 = "" if regexm(address,"MINORIES")==1 & district_1 != "LONDON CITY" & district_1 != "WHITECHAPEL"
replace county_1 = "MIDDLESEX" if regexm(address,"MINORIES")==1 & district_1 != "LONDON CITY" & district_1 != "WHITECHAPEL"
replace district_1 = "LONDON CITY, WHITECHAPEL" if regexm(address,"MINORIES")==1 & district_1 != "LONDON CITY" & district_1 != "WHITECHAPEL"

replace subdist_1 = "" if (regexm(address,"DALSTON")==1 | regexm(address,"KINGSLAND")==1) & district_1!="ISLINGTON" & district_1 != "SHOREDITCH" & district_1 != "HACKNEY"
replace parish_1 = "" if (regexm(address,"DALSTON")==1 | regexm(address,"KINGSLAND")==1) & district_1!="ISLINGTON" & district_1 != "SHOREDITCH" & district_1 != "HACKNEY"
replace county_1 = "MIDDLESEX" if (regexm(address,"DALSTON")==1 | regexm(address,"KINGSLAND")==1) & district_1!="ISLINGTON" & district_1 != "SHOREDITCH" & district_1 != "HACKNEY"
replace district_1 = "ISLINGTON, SHOREDITCH, HACKNEY" if (regexm(address,"DALSTON")==1 | regexm(address,"KINGSLAND")==1) & district_1!="ISLINGTON" & district_1 != "SHOREDITCH" & district_1 != "HACKNEY"

replace county_1 = "MIDDLESEX" if regexm(address,"COMMERCIAL R")==1 & district_1==""
replace district_1 = "MILE END OLD TOWN, ST GEORGE IN THE EAST, STEPNEY, WHITECHAPEL" if regexm(address,"COMMERCIAL R")==1 & district_1==""

replace subdist_1 = "" if regexm(address,"CITY R(OA)*D")==1 & district_1 != "HOLBORN" & district_1 !="ISLINGTON" & district_1 != "SHOREDITCH"
replace parish_1 = "" if regexm(address,"CITY R(OA)*D")==1 & district_1 != "HOLBORN" & district_1 !="ISLINGTON" & district_1 != "SHOREDITCH"
replace county_1 = "MIDDLESEX" if regexm(address,"CITY R(OA)*D")==1 & district_1 != "HOLBORN" & district_1 !="ISLINGTON" & district_1 != "SHOREDITCH"
replace district_1 = "HOLBORN, ISLINGTON, SHOREDITCH" if regexm(address,"CITY R(OA)*D")==1 & district_1 != "HOLBORN" & district_1 !="ISLINGTON" & district_1 != "SHOREDITCH"

replace subdist_1 = "" if regexm(address,"HIGHGATE")==1 & district_1 !="PANCRAS" & district_1 !="ISLINGTON" & district_1 != "PANCRAS" & cty1=="" & district_1 != "READMISSION"
replace parish_1 = "" if regexm(address,"HIGHGATE")==1 & district_1 !="PANCRAS" & district_1 !="ISLINGTON" & district_1 != "PANCRAS" & cty1=="" & district_1 != "READMISSION"
replace county_1 = "MIDDLESEX" if regexm(address,"HIGHGATE")==1 & district_1 !="PANCRAS" & district_1 !="ISLINGTON" & district_1 != "PANCRAS" & cty1=="" & district_1 != "READMISSION"
replace district_1 = "EDMONTON, ISLINGTON, PANCRAS" if regexm(address,"HIGHGATE")==1 & district_1 !="PANCRAS" & district_1 !="ISLINGTON" & district_1 != "PANCRAS" & cty1=="" & district_1 != "READMISSION"

replace subdist_1 = "" if regexm(address,"KING(S)*( )*CROSS R")==1 & district_1 != "HOLBORN" & district_1 != "PANCRAS" & district_1 != "SHOREDITCH"
replace parish_1 = "" if regexm(address,"KING(S)*( )*CROSS R")==1 & district_1 != "HOLBORN" & district_1 != "PANCRAS" & district_1 != "SHOREDITCH"
replace county_1 = "MIDDLESEX" if regexm(address,"KING(S)*( )*CROSS R")==1 & district_1 != "HOLBORN" & district_1 != "PANCRAS" & district_1 != "SHOREDITCH"
replace district_1 = "HOLBORN, PANCRAS" if regexm(address,"KING(S)*( )*CROSS R")==1 & district_1 != "HOLBORN" & district_1 != "PANCRAS" & district_1 != "SHOREDITCH"

replace subdist_1 = "" if regexm(address,"KING(S)*( )*CROSS")==1 & regexm(address,"KING(S)*( )*CROSS R")==0 & district_1 != "HOLBORN" & district_1 != "PANCRAS" & district_1 !="ISLINGTON"
replace parish_1 = "" if regexm(address,"KING(S)*( )*CROSS")==1 & regexm(address,"KING(S)*( )*CROSS R")==0 & district_1 != "HOLBORN" & district_1 != "PANCRAS" & district_1 !="ISLINGTON"
replace county_1 = "MIDDLESEX" if regexm(address,"KING(S)*( )*CROSS")==1 & regexm(address,"KING(S)*( )*CROSS R")==0 & district_1 != "HOLBORN" & district_1 != "PANCRAS" & district_1 !="ISLINGTON"
replace district_1 = "HOLBORN, ISLINGTON, PANCRAS" if regexm(address,"KING(S)*( )*CROSS")==1 & regexm(address,"KING(S)*( )*CROSS R")==0 & district_1 != "HOLBORN" & district_1 != "PANCRAS" & district_1 !="ISLINGTON"

replace subdist_1 = "" if regexm(address,"BLOOMSBURY")==1 & district_1 != "HOLBORN" & district_1 != "ST GILES"
replace parish_1 = "" if regexm(address,"BLOOMSBURY")==1 & district_1 != "HOLBORN" & district_1 != "ST GILES"
replace county_1 = "MIDDLESEX" if regexm(address,"BLOOMSBURY")==1 & district_1 != "HOLBORN" & district_1 != "ST GILES"
replace district_1 = "HOLBORN, ST GILES" if regexm(address,"BLOOMSBURY")==1 & district_1 != "HOLBORN" & district_1 != "ST GILES"

replace subdist_1 = "" if regexm(address,"HORNSEY") & district_1 != "EDMONTON" & district_1 != "ISLINGTON" & district_1 != "HACKNEY"
replace parish_1 = "" if regexm(address,"HORNSEY") & district_1 != "EDMONTON" & district_1 != "ISLINGTON" & district_1 != "HACKNEY"
replace county_1 = "MIDDLESEX" if regexm(address,"HORNSEY") & district_1 != "EDMONTON" & district_1 != "ISLINGTON" & district_1 != "HACKNEY"
replace district_1 = "EDMONTON, ISLINGTON, HACKNEY" if regexm(address,"HORNSEY") & district_1 != "EDMONTON" & district_1 != "ISLINGTON" & district_1 != "HACKNEY"

replace subdist_1 = "" if regexm(address,"STREATHAM")==1 & regexm(address,"STREATHAM ST")==0 & district_1 != "LAMBETH" & district_1 != "WANDSWORTH"
replace parish_1 = "" if regexm(address,"STREATHAM")==1 & regexm(address,"STREATHAM ST")==0 & district_1 != "LAMBETH" & district_1 != "WANDSWORTH"
replace county_1 = "SURREY" if regexm(address,"STREATHAM")==1 & regexm(address,"STREATHAM ST")==0 & district_1 != "LAMBETH" & district_1 != "WANDSWORTH"
replace district_1 = "LAMBETH, WANDSWORTH" if regexm(address,"STREATHAM")==1 & regexm(address,"STREATHAM ST")==0 & district_1 != "LAMBETH" & district_1 != "WANDSWORTH"

replace subdist_1 = "" if regexm(address,"OLD KENT R")==1 & district_1 != "CAMBERWELL" & district_1 != "ST SAVIOUR SOUTHWARK" & district_1 != "ST OLAVE SOUTHWARK"
replace parish_1 = "" if regexm(address,"OLD KENT R")==1 & district_1 != "CAMBERWELL" & district_1 != "ST SAVIOUR SOUTHWARK" & district_1 != "ST OLAVE SOUTHWARK"
replace county_1 = "SURREY" if regexm(address,"OLD KENT R")==1 & district_1 != "CAMBERWELL" & district_1 != "ST SAVIOUR SOUTHWARK" & district_1 != "ST OLAVE SOUTHWARK"
replace district_1 = "CAMBERWELL, ST OLAVE SOUTHWARK, ST SAVIOUR SOUTHWARK" if regexm(address,"OLD KENT R")==1 & district_1 != "CAMBERWELL" & district_1 != "ST SAVIOUR SOUTHWARK" & district_1 != "ST OLAVE SOUTHWARK"

replace subdist_1 = "" if regexm(address,"GRAYS INN R") & district_1 != "HOLBORN" & district_1 != "PANCRAS"
replace parish_1 = "" if regexm(address,"GRAYS INN R") & district_1 != "HOLBORN" & district_1 != "PANCRAS"
replace county_1 = "MIDDLESEX" if regexm(address,"GRAYS INN R") & district_1 != "HOLBORN" & district_1 != "PANCRAS"
replace district_1 = "HOLBORN, PANCRAS" if regexm(address,"GRAYS INN R") & district_1 != "HOLBORN" & district_1 != "PANCRAS"

replace subdist_1 = "" if regexm(address,"DRURY L") & district_1 !="STRAND" & district_1 !="ST GILES"
replace parish_1 = "" if regexm(address,"DRURY L") & district_1 !="STRAND" & district_1 !="ST GILES"
replace county_1 = "MIDDLESEX" if regexm(address,"DRURY L") & district_1 !="STRAND" & district_1 !="ST GILES"
replace district_1 = "STRAND, ST GILES" if regexm(address,"DRURY L") & district_1 !="STRAND" & district_1 !="ST GILES"

replace subdist_1 = "" if regexm(address,"NEW NORTH ROAD")==1 & district_1 !="ISLINGTON" & district_1 != "SHOREDITCH"
replace parish_1 = "" if regexm(address,"NEW NORTH ROAD")==1 & district_1 !="ISLINGTON" & district_1 != "SHOREDITCH"
replace county_1 = "MIDDLESEX" if regexm(address,"NEW NORTH ROAD")==1 & district_1 !="ISLINGTON" & district_1 != "SHOREDITCH"
replace district_1 = "ISLINGTON, SHOREDITCH" if regexm(address,"NEW NORTH ROAD")==1 & district_1 !="ISLINGTON" & district_1 != "SHOREDITCH"

replace subdist_1 = "" if regexm(address,"ALDERSGATE ST") & district_1 != "LONDON CITY" & district_1 != "HOLBORN" 
replace parish_1 = "" if regexm(address,"ALDERSGATE ST") & district_1 != "LONDON CITY" & district_1 != "HOLBORN"
replace county_1 = "MIDDLESEX" if regexm(address,"ALDERSGATE ST") & district_1 != "LONDON CITY" & district_1 != "HOLBORN"
replace district_1 = "HOLBORN, LONDON CITY" if regexm(address,"ALDERSGATE ST") & district_1 != "LONDON CITY" & district_1 != "HOLBORN"

replace subdist_1 = "" if regexm(address,"^(THE )*HOLBORN UNION$")
replace parish_1 = "" if regexm(address,"^(THE )*HOLBORN UNION$")
replace county_1 = "MIDDLESEX" if regexm(address,"^(THE )*HOLBORN UNION$")
replace district_1 = "HOLBORN, SHOREDITCH" if regexm(address,"^(THE )*HOLBORN UNION$")

replace subdist_1 = "" if regexm(address,"VICTORIA P(AR)*K") & district_1 != "BETHNAL GREEN" & district_1 != "HACKNEY" & district_1 != "POPLAR"
replace parish_1 = "" if regexm(address,"VICTORIA P(AR)*K") & district_1 != "BETHNAL GREEN" & district_1 != "HACKNEY" & district_1 != "POPLAR"
replace county_1 = "MIDDLESEX" if regexm(address,"VICTORIA P(AR)*K") & district_1 != "BETHNAL GREEN" & district_1 != "HACKNEY" & district_1 != "POPLAR"
replace district_1 = "BETHNAL GREEN, HACKNEY, POPLAR" if regexm(address,"VICTORIA P(AR)*K") & district_1 != "BETHNAL GREEN" & district_1 != "HACKNEY" & district_1 != "POPLAR"

replace subdist_1 = "" if regexm(address,"FETTER L") & district_1 != "HOLBORN" & district_1 !="LONDON CITY"
replace parish_1 = "" if regexm(address,"FETTER L") & district_1 != "HOLBORN" & district_1 !="LONDON CITY"
replace county_1 = "MIDDLESEX" if regexm(address,"FETTER L") & district_1 != "HOLBORN" & district_1 !="LONDON CITY"
replace district_1 = "HOLBORN, LONDON CITY" if regexm(address,"FETTER L") & district_1 != "HOLBORN" & district_1 !="LONDON CITY"

replace subdist_1 = "" if regexm(address,"HIGH HOLBORN") & district_1 != "HOLBORN" & district_1 !="ST GILES"
replace parish_1 = "" if regexm(address,"HIGH HOLBORN") & district_1 != "HOLBORN" & district_1 !="ST GILES"
replace county_1 = "MIDDLESEX" if regexm(address,"HIGH HOLBORN") & district_1 != "HOLBORN" & district_1 !="ST GILES"
replace district_1 = "HOLBORN, ST GILES" if regexm(address,"HIGH HOLBORN") & district_1 != "HOLBORN" & district_1 !="ST GILES"

replace subdist_1 = "" if regexm(address,"SEVEN SISTER(S)* R") & district_1 !="ISLINGTON" & district_1 !="HACKNEY" & district_1 !="EDMONTON"
replace parish_1 = "" if regexm(address,"SEVEN SISTER(S)* R") & district_1 !="ISLINGTON" & district_1 !="HACKNEY" & district_1 !="EDMONTON"
replace county_1 = "MIDDLESEX" if regexm(address,"SEVEN SISTER(S)* R") & district_1 !="ISLINGTON" & district_1 !="HACKNEY" & district_1 !="EDMONTON"
replace district_1 = "ISLINGTON, HACKNEY, EDMONTON" if regexm(address,"SEVEN SISTER(S)* R") & district_1 !="ISLINGTON" & district_1 !="HACKNEY" & district_1 !="EDMONTON"

replace subdist_1 = "" if regexm(address,"BOW COMMON") & district_1 != "MILE END OLD TOWN" & district_1 != "POPLAR" & district_1 != "STEPNEY"
replace parish_1 = "" if regexm(address,"BOW COMMON") & district_1 != "MILE END OLD TOWN" & district_1 != "POPLAR" & district_1 != "STEPNEY"
replace county_1 = "MIDDLESEX" if regexm(address,"BOW COMMON") & district_1 != "MILE END OLD TOWN" & district_1 != "POPLAR" & district_1 != "STEPNEY"
replace district_1 = "MILE END OLD TOWN, POPLAR, STEPNEY" if regexm(address,"BOW COMMON") & district_1 != "MILE END OLD TOWN" & district_1 != "POPLAR" & district_1 != "STEPNEY"

replace subdist_1 = "" if regexm(address,"NUNHEAD") & district_1 !="CAMBERWELL" & district_1 != "GREENWICH"
replace parish_1 = "" if regexm(address,"NUNHEAD") & district_1 !="CAMBERWELL" & district_1 != "GREENWICH"
replace county_1 = "SURREY, KENT" if regexm(address,"NUNHEAD") & district_1 !="CAMBERWELL" & district_1 != "GREENWICH"
replace district_1 = "CAMBERWELL, GREENWICH" if regexm(address,"NUNHEAD") & district_1 !="CAMBERWELL" & district_1 != "GREENWICH"

replace subdist_1 = "" if regexm(address,"HACKNEY R") & district_1 != "BETHNAL GREEN" & district_1 != "SHOREDITCH"
replace parish_1 = "" if regexm(address,"HACKNEY R") & district_1 != "BETHNAL GREEN" & district_1 != "SHOREDITCH"
replace county_1 = "MIDDLESEX" if regexm(address,"HACKNEY R") & district_1 != "BETHNAL GREEN" & district_1 != "SHOREDITCH"
replace district_1 = "BETHNAL GREEN, SHOREDITCH" if regexm(address,"HACKNEY R") & district_1 != "BETHNAL GREEN" & district_1 != "SHOREDITCH"

replace subdist_1 = "" if regexm(address,"SOHO") & district_1 != "ST GILES" & district_1 !="WESTMINSTER"
replace parish_1 = "" if regexm(address,"SOHO") & district_1 != "ST GILES" & district_1 !="WESTMINSTER"
replace county_1 = "MIDDLESEX" if regexm(address,"SOHO") & district_1 != "ST GILES" & district_1 !="WESTMINSTER"
replace district_1 = "ST GILES, WESTMINSTER" if regexm(address,"SOHO") & district_1 != "ST GILES" & district_1 !="WESTMINSTER"

replace subdist_1 = "" if regexm(address,"WHITECROSS ST") & district_1 != "HOLBORN" & district_1 != "LONDON CITY"
replace parish_1 = "" if regexm(address,"WHITECROSS ST") & district_1 != "HOLBORN" & district_1 != "LONDON CITY"
replace county_1 = "MIDDLESEX" if regexm(address,"WHITECROSS ST") & district_1 != "HOLBORN" & district_1 != "LONDON CITY"
replace district_1 = "HOLBORN, LONDON CITY" if regexm(address,"WHITECROSS ST") & district_1 != "HOLBORN" & district_1 != "LONDON CITY"

replace subdist_1 = "" if regexm(address,"TOWER HILL") & district_1 != "LONDON CITY" & district_1 != "WHITECHAPEL"
replace parish_1 = "" if regexm(address,"TOWER HILL") & district_1 != "LONDON CITY" & district_1 != "WHITECHAPEL"
replace county_1 = "MIDDLESEX" if regexm(address,"TOWER HILL") & district_1 != "LONDON CITY" & district_1 != "WHITECHAPEL"
replace district_1 = "LONDON CITY, WHITECHAPEL" if regexm(address,"TOWER HILL") & district_1 != "LONDON CITY" & district_1 != "WHITECHAPEL"

replace subdist_1 = "" if regexm(address,"LONDON DOCK") & district_1 != "ST GEORGE IN THE EAST" & district_1 !="STEPNEY"
replace parish_1 = "" if regexm(address,"LONDON DOCK") & district_1 != "ST GEORGE IN THE EAST" & district_1 !="STEPNEY"
replace county_1 = "MIDDLESEX" if regexm(address,"LONDON DOCK") & district_1 != "ST GEORGE IN THE EAST" & district_1 !="STEPNEY"
replace district_1 = "ST GEORGE IN THE EAST, STEPNEY" if regexm(address,"LONDON DOCK") & district_1 != "ST GEORGE IN THE EAST" & district_1 !="STEPNEY"

replace subdist_1 = "" if regexm(address,"CHANCERY L") & district_1 != "HOLBORN" & district_1 != "LONDON CITY" & district_1 !="STRAND"
replace parish_1 = "" if regexm(address,"CHANCERY L") & district_1 != "HOLBORN" & district_1 != "LONDON CITY" & district_1 !="STRAND"
replace county_1 = "MIDDLESEX" if regexm(address,"CHANCERY L") & district_1 != "HOLBORN" & district_1 != "LONDON CITY" & district_1 !="STRAND"
replace district_1 = "HOLBORN, LONDON CITY, STRAND" if regexm(address,"CHANCERY L") & district_1 != "HOLBORN" & district_1 != "LONDON CITY" & district_1 !="STRAND"

replace subdist_1 = "" if regexm(address,"STAMFORD ST") & district_1 !="LAMBETH" & district_1 !="ST SAVIOUR SOUTHWARK" & district_1 != "FULHAM"
replace parish_1 = "" if regexm(address,"STAMFORD ST") & district_1 !="LAMBETH" & district_1 !="ST SAVIOUR SOUTHWARK" & district_1 != "FULHAM"
replace county_1 = "SURREY" if regexm(address,"STAMFORD ST") & district_1 !="LAMBETH" & district_1 !="ST SAVIOUR SOUTHWARK" & district_1 != "FULHAM"
replace district_1 = "LAMBETH, ST SAVIOUR SOUTHWARK" if regexm(address,"STAMFORD ST") & district_1 !="LAMBETH" & district_1 !="ST SAVIOUR SOUTHWARK" & district_1 != "FULHAM"

replace subdist_1 = "" if (regexm(address,"SOUTHWARK$") | regexm(address,"SOUTHWARK,")) & district_1 != "LAMBETH" & district_1 !="ST SAVIOUR SOUTHWARK" & district_1 !="ST OLAVE SOUTHWARK"
replace parish_1 = "" if (regexm(address,"SOUTHWARK$") | regexm(address,"SOUTHWARK,")) & district_1 != "LAMBETH" & district_1 !="ST SAVIOUR SOUTHWARK" & district_1 !="ST OLAVE SOUTHWARK"
replace county_1 = "SURREY" if (regexm(address,"SOUTHWARK$") | regexm(address,"SOUTHWARK,")) & district_1 != "LAMBETH" & district_1 !="ST SAVIOUR SOUTHWARK" & district_1 !="ST OLAVE SOUTHWARK"
replace district_1 = "LAMBETH, ST OLAVE SOUTHWARK, ST SAVIOUR SOUTHWARK" if (regexm(address,"SOUTHWARK$") | regexm(address,"SOUTHWARK,")) & district_1 != "LAMBETH" & district_1 !="ST SAVIOUR SOUTHWARK" & district_1 !="ST OLAVE SOUTHWARK"

replace subdist_1 = "" if regexm(address,"WATERLOO R")==1 & regexm(address,"KENT")==0 & regexm(address,"UPTON P")==0 & district_1 != "LAMBETH" & district_1 != "ST SAVIOUR SOUTHWARK"
replace parish_1 = "" if regexm(address,"WATERLOO R")==1 & regexm(address,"KENT")==0 & regexm(address,"UPTON P")==0 & district_1 != "LAMBETH" & district_1 != "ST SAVIOUR SOUTHWARK"
replace county_1 = "SURREY" if regexm(address,"WATERLOO R")==1 & regexm(address,"KENT")==0 & regexm(address,"UPTON P")==0 & district_1 != "LAMBETH" & district_1 != "ST SAVIOUR SOUTHWARK"
replace district_1 = "LAMBETH, ST SAVIOUR SOUTHWARK" if regexm(address,"WATERLOO R")==1 & regexm(address,"KENT")==0 & regexm(address,"UPTON P")==0 & district_1 != "LAMBETH" & district_1 != "ST SAVIOUR SOUTHWARK"

replace subdist_1 = "" if regexm(address,"LIVERPOOL R")==1 & regexm(address,"CANNING T")==0 & regexm(address,"KINGSTON")==0 & district_1 != "HOLBORN" & district_1 != "ISLINGTON"
replace parish_1 = "" if regexm(address,"LIVERPOOL R")==1 & regexm(address,"CANNING T")==0 & regexm(address,"KINGSTON")==0 & district_1 != "HOLBORN" & district_1 != "ISLINGTON"
replace county_1 = "MIDDLESEX" if regexm(address,"LIVERPOOL R")==1 & regexm(address,"CANNING T")==0 & regexm(address,"KINGSTON")==0 & district_1 != "HOLBORN" & district_1 != "ISLINGTON"
replace district_1 = "HOLBORN, ISLINGTON" if regexm(address,"LIVERPOOL R")==1 & regexm(address,"CANNING T")==0 & regexm(address,"KINGSTON")==0 & district_1 != "HOLBORN" & district_1 != "ISLINGTON"

replace subdist_1 = "" if regexm(address,"WANDSWORTH R") & district_1 != "LAMBETH" & district_1 != "WANDSWORTH"
replace parish_1 = "" if regexm(address,"WANDSWORTH R") & district_1 != "LAMBETH" & district_1 != "WANDSWORTH"
replace county_1 = "SURREY" if regexm(address,"WANDSWORTH R") & district_1 != "LAMBETH" & district_1 != "WANDSWORTH"
replace district_1 = "LAMBETH, WANDSWORTH" if regexm(address,"WANDSWORTH R") & district_1 != "LAMBETH" & district_1 != "WANDSWORTH"

replace subdist_1 = "" if regexm(address,"KNIGHTSBRIDGE")
replace parish_1 = "" if regexm(address,"KNIGHTSBRIDGE")
replace county_1 = "MIDDLESEX" if regexm(address,"KNIGHTSBRIDGE")
replace district_1 = "KENSINGTON, ST GEORGE IN THE EAST" if regexm(address,"KNIGHTSBRIDGE")

replace subdist_1 = "" if regexm(address, "HAVERSTOCK HILL") & district_1 != "HAMPSTEAD" & district_1 != "PANCRAS"
replace parish_1 = "" if regexm(address, "HAVERSTOCK HILL") & district_1 != "HAMPSTEAD" & district_1 != "PANCRAS"
replace county_1 = "MIDDLESEX" if regexm(address, "HAVERSTOCK HILL") & district_1 != "HAMPSTEAD" & district_1 != "PANCRAS"
replace district_1 = "HAMPSTEAD, PANCRAS" if regexm(address, "HAVERSTOCK HILL") & district_1 != "HAMPSTEAD" & district_1 != "PANCRAS"

replace subdist_1 = "" if regexm(address,"CAMBRIDGE HEATH") & district_1 != "BETHNAL GREEN" & district_1 != "HACKNEY" & district_1 != "MILE END OLD TOWN"
replace parish_1 = "" if regexm(address,"CAMBRIDGE HEATH") & district_1 != "BETHNAL GREEN" & district_1 != "HACKNEY" & district_1 != "MILE END OLD TOWN"
replace county_1 = "MIDDLESEX" if regexm(address,"CAMBRIDGE HEATH") & district_1 != "BETHNAL GREEN" & district_1 != "HACKNEY" & district_1 != "MILE END OLD TOWN"
replace district_1 = "BETHNAL GREEN, HACKNEY, MILE END OLD TOWN" if regexm(address,"CAMBRIDGE HEATH") & district_1 != "BETHNAL GREEN" & district_1 != "HACKNEY" & district_1 != "MILE END OLD TOWN"

replace subdist_1 = "" if regexm(address,"NEWINGTON BUTTS") & district_1 != "LAMBETH" & district_1 != "ST SAVIOUR SOUTHWARK"
replace parish_1 = "" if regexm(address,"NEWINGTON BUTTS") & district_1 != "LAMBETH" & district_1 != "ST SAVIOUR SOUTHWARK"
replace county_1 = "SURREY" if regexm(address,"NEWINGTON BUTTS") & district_1 != "LAMBETH" & district_1 != "ST SAVIOUR SOUTHWARK"
replace district_1 = "LAMBETH, ST SAVIOUR SOUTHWARK" if regexm(address,"NEWINGTON BUTTS") & district_1 != "LAMBETH" & district_1 != "ST SAVIOUR SOUTHWARK"

replace subdist_1 = "" if regexm(address,"KENSAL RISE") & district_1 !="CHELSEA" & district_1 !="HENDON" & district_1 !="KENSINGTON"
replace parish_1 = "" if regexm(address,"KENSAL RISE") & district_1 !="CHELSEA" & district_1 !="HENDON" & district_1 !="KENSINGTON"
replace county_1 = "MIDDLESEX" if regexm(address,"KENSAL RISE") & district_1 !="CHELSEA" & district_1 !="HENDON" & district_1 !="KENSINGTON"
replace district_1 = "CHELSEA, HENDON, KENSINGTON" if regexm(address,"KENSAL RISE") & district_1 !="CHELSEA" & district_1 !="HENDON" & district_1 !="KENSINGTON"

replace subdist_1 = "" if regexm(address,"CAMBERWELL R") & district_1 != "CAMBERWELL" & district_1 != "ST SAVIOUR SOUTHWARK"
replace parish_1 = "" if regexm(address,"CAMBERWELL R") & district_1 != "CAMBERWELL" & district_1 != "ST SAVIOUR SOUTHWARK"
replace county_1 = "SURREY" if regexm(address,"CAMBERWELL R") & district_1 != "CAMBERWELL" & district_1 != "ST SAVIOUR SOUTHWARK"
replace district_1 = "CAMBERWELL, ST SAVIOUR SOUTHWARK" if regexm(address,"CAMBERWELL R") & district_1 != "CAMBERWELL" & district_1 != "ST SAVIOUR SOUTHWARK"

replace subdist_1 = "" if (regex(address,"^MILTON ST") | regex(address," MILTON ST")) & regexm(address,"HORNSEY")==0 & district_1 != "HOLBORN" & district_1 != "LONDON CITY"
replace parish_1 = "" if (regex(address,"^MILTON ST") | regex(address," MILTON ST")) & regexm(address,"HORNSEY")==0 & district_1 != "HOLBORN" & district_1 != "LONDON CITY"
replace county_1 = "MIDDLESEX" if (regex(address,"^MILTON ST") | regex(address," MILTON ST")) & regexm(address,"HORNSEY")==0 & district_1 != "HOLBORN" & district_1 != "LONDON CITY"
replace district_1 = "HOLBORN, LONDON CITY" if (regex(address,"^MILTON ST") | regex(address," MILTON ST")) & regexm(address,"HORNSEY")==0 & district_1 != "HOLBORN" & district_1 != "LONDON CITY"

replace subdist_1 = "" if regexm(address,"STROUD GREEN") & district_1 != "EDMONTON" & district_1 !="ISLINGTON"
replace parish_1 = "" if regexm(address,"STROUD GREEN") & district_1 != "EDMONTON" & district_1 !="ISLINGTON"
replace county_1 = "MIDDLESEX" if regexm(address,"STROUD GREEN") & district_1 != "EDMONTON" & district_1 !="ISLINGTON"
replace district_1 = "EDMONTON, ISLINGTON" if regexm(address,"STROUD GREEN") & district_1 != "EDMONTON" & district_1 !="ISLINGTON"

replace subdist_1 = "ST JAMES BERMONDSEY" if regexm(address,"DOCKHEAD") & subdist_1 != "ST MARY MAGDALEN"
replace parish_1 = "BERMONDSEY" if regexm(address,"DOCKHEAD")
replace county_1 = "MIDDLESEX" if regexm(address,"DOCKHEAD")
replace district_1 = "ST OLAVE SOUTHWARK" if regexm(address,"DOCKHEAD")

gen temp = regexm(address,"LONG LANE") & regexm(address,"FINCHLEY") == 0 & regexm(district_1,"SOUTHWARK") == 0 & district_1 != "LONDON CITY"
replace subdist_1 = "" if temp == 1 
replace parish_1 = "BERMONDSEY" if temp == 1 
replace county_1 = "SURREY" if temp == 1
replace district_1 = "ST SAVIOUR SOUTHWARK, ST OLAVE SOUTHWARK" if temp == 1
drop temp

replace subdist_1 = "BRACKNELL" if regexm(address,"ASCOT PRIORY")
replace parish_1 = "WINKFIELD" if regexm(address,"ASCOT PRIORY")
replace county_1 = "BERKSHIRE" if regexm(address,"ASCOT PRIORY")
replace district_1 = "EASTHAMPSTEAD" if regexm(address,"ASCOT PRIORY")

replace subdist_1 = "ST OLAVE SOUTHWARK" if regexm(address,"MAZE POND")
replace parish_1 = "BERMONDSEY" if regexm(address,"MAZE POND")
replace county_1 = "SURREY" if regexm(address,"MAZE POND")
replace district_1 = "ST OLAVE SOUTHWARK" if regexm(address,"MAZE POND")

replace subdist_1 = "LEWISHAM" if regexm(address,"LEWISHAM UNION")
replace parish_1 = "LEWISHAM" if regexm(address,"LEWISHAM UNION")
replace county_1 = "KENT" if regexm(address,"LEWISHAM UNION")
replace district_1 = "LEWISHAM" if regexm(address,"LEWISHAM UNION")

replace subdist_1 = "RAMSGATE" if regexm(address,"BROADSTAIRS")
replace parish_1 = "ST PETER" if regexm(address,"BROADSTAIRS")
replace county_1 = "KENT" if regexm(address,"BROADSTAIRS")
replace district_1 = "THANET" if regexm(address,"BROADSTAIRS")

replace subdist_1 = "ST JOHN PADDINGTON" if regexm(address,"BROOK") & regexm(address,"LANCASTER STR")
replace parish_1 = "PADDINGTON" if regexm(address,"BROOK") & regexm(address,"LANCASTER STR")
replace county_1 = "MIDDLESEX" if regexm(address,"BROOK") & regexm(address,"LANCASTER STR")
replace district_1 = "KENSINGTON" if regexm(address,"BROOK") & regexm(address,"LANCASTER STR")

replace parish_1 = "ST GEORGE THE MARTYR SOUTHWARK" if regexm(address,"BROOK") == 0 & regexm(address,"LANCASTER STR")
replace county_1 = "SURREY" if regexm(address,"BROOK") == 0 & regexm(address,"LANCASTER STR")
replace district_1 = "ST SAVIOUR SOUTHWARK" if regexm(address,"BROOK") == 0 & regexm(address,"LANCASTER STR")

replace subdist_1 = "ST MARY NEWINGTON" if regexm(address,"KENNINGTON")
replace parish_1 = "NEWINGTON" if regexm(address,"KENNINGTON")
replace county_1 = "SURREY" if regexm(address,"KENNINGTON")
replace district_1 = "ST SAVIOUR SOUTHWARK" if regexm(address,"KENNINGTON")

replace subdist_1 = "CAMBERWELL" if regexm(address,"CAMBERWELL NEW ROAD") & district_1 == ""
replace parish_1 = "CAMBERWELL" if regexm(address,"CAMBERWELL NEW ROAD") & district_1 == ""
replace county_1 = "SURREY" if regexm(address,"CAMBERWELL NEW ROAD") & district_1 == ""
replace district_1 = "CAMBERWELL" if regexm(address,"CAMBERWELL NEW ROAD") & district_1 == ""

replace subdist_1 = "ST MARY MAGDALEN" if regexm(address,"STAR CORNER")
replace parish_1 = "BERMONDSEY" if regexm(address,"STAR CORNER")
replace county_1 = "SURREY" if regexm(address,"STAR CORNER")
replace district_1 = "ST OLAVE SOUTHWARK" if regexm(address,"STAR CORNER")

replace subdist_1 = "ST MARY MAGDALEN" if regexm(address,"GRANGE R") & regexm(address,"PLA(I)*STOW") == 0 & regexm(address,"EALING") == 0
replace parish_1 = "BERMONDSEY" if regexm(address,"GRANGE R") & regexm(address,"PLA(I)*STOW") == 0 & regexm(address,"EALING") == 0
replace county_1 = "SURREY" if regexm(address,"GRANGE R") & regexm(address,"PLA(I)*STOW") == 0 & regexm(address,"EALING") == 0
replace district_1 = "ST OLAVE SOUTHWARK" if regexm(address,"GRANGE R") & regexm(address,"PLA(I)*STOW") == 0 & regexm(address,"EALING") == 0

replace subdist_1 = "WEST HAM" if regexm(address,"GRANGE R") & regexm(address,"PLA(I)*STOW")
replace parish_1 = "WEST HAM" if regexm(address,"GRANGE R") & regexm(address,"PLA(I)*STOW")
replace county_1 = "ESSEX" if regexm(address,"GRANGE R") & regexm(address,"PLA(I)*STOW")
replace district_1 = "WEST HAM" if regexm(address,"GRANGE R") & regexm(address,"PLA(I)*STOW") 

replace subdist_1 = "ST OLAVE SOUTHWARK" if regexm(address,"VINE ST(.)*B")
replace parish_1 = "ST OLAVE SOUTHWARK" if regexm(address,"VINE ST(.)*B")
replace county_1 = "SURREY" if regexm(address,"VINE ST(.)*B")
replace district_1 = "ST OLAVE SOUTHWARK" if regexm(address,"VINE ST(.)*B")

replace subdist_1 = "ST OLAVE SOUTHWARK" if regexm(address,"BARNHAM") & regexm(parish_1,"HORSLEYDOWN") == 0
replace parish_1 = "ST OLAVE SOUTHWARK" if regexm(address,"BARNHAM") & regexm(parish_1,"HORSLEYDOWN") == 0
replace county_1 = "SURREY" if regexm(address,"BARNHAM") & regexm(parish_1,"HORSLEYDOWN") == 0
replace district_1 = "ST OLAVE SOUTHWARK" if regexm(address,"BARNHAM") & regexm(parish_1,"HORSLEYDOWN") == 0



// Cross district checks

rename add1 street
gen multdist = regexm(district_1,",")
split district_1, parse(", ") gen(dist)
replace dist1 = "" if multdist==0

joinby street using "$PROJ_PATH/processed/intermediate/geography/1881_street_district_crosswalk.dta", unmatched(master)

gen match_add = ((stnum>=min_number & stnum<=max_number) | stnum==.) & (index81_dist == dist1 | index81_dist ==dist2 | index81_dist == dist3 | index81_dist == dist4) & multdist==1 & _merge==3 /* Matched to street index in address number falls in max/min range from index and matches even/odd */
egen tot_match = total(match_add), by(address_orig)

replace index81_subdist = "" if tot_match == 0
replace index81_parish = "" if tot_match == 0
replace index81_cty = "" if tot_match == 0 
replace index81_dist = "" if tot_match == 0

drop dist1-dist4

unique address_orig
drop if tot_match>0 & match_add == 0 /* Drop observations that match name but not number if at least one number matches */
unique address_orig
drop min_number max_number match_add tot_match 
duplicates drop
egen tot_match = count(address_orig), by(address_orig)
replace index81_subdist = "" if index81_dist != district_1 & tot_match>1
replace index81_parish = "" if index81_dist != district_1 & tot_match>1
replace index81_cty = "" if index81_dist != district_1 & tot_match>1 
replace index81_dist = "" if index81_dist != district_1 & tot_match>1 /* Drop potential district name if multiple matches */
drop tot_match
duplicates drop
gen temp = (index81_dist !="")
egen temp2 = count(address_orig), by(address_orig)
egen temp3 = total(temp), by(address_orig)
unique address_orig
tab temp3 if temp2>1
drop if temp==0 & temp2>1
unique address_orig
drop temp* _merge

egen temp = count(address_orig), by(address_orig)
replace index81_parish = "" if temp>1
replace index81_subdist = "" if temp>1
drop temp
duplicates drop

replace district_1 = index81_dist if index81_dist !=""
replace county_1 = index81_cty if index81_cty != ""
replace subdist_1 = index81_subdist if index81_subdist !=""
replace parish_1 = index81_parish if index81_parish !=""

drop index81_subdist index81_dist index81_parish index81_cty multdist
rename street add1

* Merge with street index file
drop index_dist
gen oddnum = mod(stnum,2)
rename add1 street
gen multdist = regexm(district_1,",")
split district_1, parse(", ") gen(dist)
replace dist1 = "" if multdist==0

joinby street using "$PROJ_PATH/processed/intermediate/geography/1891_street_district_crosswalk.dta", unmatched(master)

gen match_oddev = ((oddnum==1 & odd==1) | (oddnum==0 & even==1))
gen match_add = (stnum>=min_number & stnum<=max_number & match_oddev) & (index_dist == dist1 | index_dist == dist2 | index_dist == dist3 | index_dist == dist4) & multdist==1 & _merge==3 /* Matched to street index in address number falls in max/min range from index and matches even/odd */

egen tot_match = total(match_add), by(address_orig)

replace index_dist = "" if tot_match == 0

drop dist1-dist4

drop if tot_match>0 & match_add == 0 /* Drop observations that match name but not number if at least one number matches */
drop min_number max_number odd even oddnum match_oddev match_add tot_match 
duplicates drop
egen tot_match = count(address_orig), by(address_orig)
replace index_dist = "" if index_dist != district_1 & tot_match>1 /* Drop potential district name if multiple matches */
drop tot_match
duplicates drop
gen temp = (index_dist!="")
egen temp2 = count(address_orig), by(address_orig)
egen temp3 = total(temp), by(address_orig)
unique address_orig
drop if temp==0 & temp2>1
unique address_orig	
drop temp* _merge

rename index_dist district
qui merge m:1 district using "$PROJ_PATH/processed/intermediate/geography/1881_distcty_crosswalk.dta", keep(1 3)
replace district = "" if _merge ==3 & ((county != cty1 & cty1!="") | (county != cty2 & cty2!="") | (county != cty3 & cty3!=""))
rename district index_dist

replace district_1 = index_dist if _merge == 3 & index_dist!=""
replace county_1 = county if _merge == 3 & county !=""

drop _merge county index_dist multdist
rename street add1



// Cross district checks - Part 2

rename add2 street
gen multdist = regexm(district_1,",")
split district_1, parse(", ") gen(dist)
replace dist1 = "" if multdist==0

joinby street using "$PROJ_PATH/processed/intermediate/geography/1881_street_district_crosswalk.dta", unmatched(master)

drop min_number max_number 
duplicates drop

gen match_add = (index81_dist == dist1 | index81_dist ==dist2 | index81_dist == dist3 | index81_dist == dist4) & multdist==1 & _merge==3
egen tot_match = total(match_add), by(address_orig)

replace index81_subdist = "" if tot_match == 0
replace index81_parish = "" if tot_match == 0
replace index81_cty = "" if tot_match == 0 
replace index81_dist = "" if tot_match == 0

drop dist1-dist4

unique address_orig
drop if tot_match>0 & match_add == 0 /* Drop observations that match name but not number if at least one number matches */
unique address_orig
drop match_add tot_match
duplicates drop
egen tot_match = count(address_orig), by(address_orig)
replace index81_subdist = "" if index81_dist != district_1 & tot_match>1
replace index81_parish = "" if index81_dist != district_1 & tot_match>1
replace index81_cty = "" if index81_dist != district_1 & tot_match>1 
replace index81_dist = "" if index81_dist != district_1 & tot_match>1 /* Drop potential district name if multiple matches */
drop tot_match
duplicates drop
gen temp = (index81_dist !="")
egen temp2 = count(address_orig), by(address_orig)
egen temp3 = total(temp), by(address_orig)
unique address_orig
tab temp3 if temp2>1
drop if temp==0 & temp2>1
unique address_orig
drop temp* _merge

egen temp = count(address_orig), by(address_orig)
replace index81_parish = "" if temp>1
replace index81_subdist = "" if temp>1
drop temp
duplicates drop

replace district_1 = index81_dist if index81_dist !=""
replace county_1 = index81_cty if index81_cty != ""
replace subdist_1 = index81_subdist if index81_subdist !=""
replace parish_1 = index81_parish if index81_parish !=""

drop index81_subdist index81_dist index81_parish index81_cty multdist
rename street add2

* Merge with street index file
* drop index_dist
rename add2 street
gen multdist = regexm(district_1,",")
split district_1, parse(", ") gen(dist)
replace dist1 = "" if multdist==0

joinby street using "$PROJ_PATH/processed/intermediate/geography/1891_street_district_crosswalk.dta", unmatched(master)

drop min_number max_number odd even 
duplicates drop

gen match_add = (index_dist == dist1 | index_dist == dist2 | index_dist == dist3 | index_dist == dist4) & multdist==1 & _merge==3
egen tot_match = total(match_add), by(address_orig)

replace index_dist = "" if tot_match == 0

drop dist1-dist4

drop if tot_match>0 & match_add == 0 /* Drop observations that match name but not number if at least one number matches */
drop tot_match
duplicates drop
egen tot_match = count(address_orig), by(address_orig)
replace index_dist = "" if index_dist != district_1 & tot_match>1 /* Drop potential district name if multiple matches */
drop tot_match
duplicates drop
gen temp = (index_dist!="")
egen temp2 = count(address_orig), by(address_orig)
egen temp3 = total(temp), by(address_orig)
unique address_orig
drop if temp==0 & temp2>1
unique address_orig	
drop temp* _merge

rename index_dist district
qui merge m:1 district using "$PROJ_PATH/processed/intermediate/geography/1881_distcty_crosswalk.dta", keep(1 3)
replace district = "" if _merge ==3 & ((county != cty1 & cty1!="") | (county != cty2 & cty2!="") | (county != cty3 & cty3!=""))
rename district index_dist

replace district_1 = index_dist if _merge == 3 & index_dist!=""
replace county_1 = county if _merge == 3 & county !=""

drop _merge county index_dist multdist
rename street add2


* Use secondary match information

gen multdist = regexm(district_1,",")
split district_1, parse(", ") gen(dist)
replace dist1 = "" if multdist==0

replace district_1 = district_2 if (district_2 == dist1 | district_2 == dist2 | district_2 == dist3 | district_2 ==dist4) & district_2 !=""
replace subdist_1 = subdist_2 if (district_2 == dist1 | district_2 == dist2 | district_2 == dist3 | district_2 ==dist4) & district_2 !=""
replace parish_1 = parish_2 if (district_2 == dist1 | district_2 == dist2 | district_2 == dist3 | district_2 ==dist4) & district_2 !=""
replace county_1 = county_2 if (district_2 == dist1 | district_2 == dist2 | district_2 == dist3 | district_2 ==dist4) & district_2 !=""

drop multdist
gen multdist = regexm(district_1,",")

replace district_1 = district_3 if (district_3 == dist1 | district_3 == dist2 | district_3 == dist3 | district_3 ==dist4) & district_3 !="" & multdist==1
replace subdist_1 = subdist_3 if (district_3 == dist1 | district_3 == dist2 | district_3 == dist3 | district_3 ==dist4) & district_3 !="" & multdist==1
replace parish_1 = parish_3 if (district_3 == dist1 | district_3 == dist2 | district_3 == dist3 | district_3 ==dist4) & district_3 !="" & multdist==1
replace county_1 = county_3 if (district_3 == dist1 | district_3 == dist2 | district_3 == dist3 | district_3 ==dist4) & district_3 !="" & multdist==1

drop multdist dist1-dist4



// Final steps

sort address_orig
count if district_1 != ""
count if county_1 != ""
count if district_1 != "" & district_1 !="READMISSION" & district_1 != "NO ADDRESS" & regexm(district_1,",")==0
count if district_1 != "" & district_1 !="READMISSION" & district_1 != "NO ADDRESS" 
count if county_1 != "" & district_1 !="READMISSION" & district_1 != "NO ADDRESS" 
count if address != "" & district_1 != "READMISSION" & district_1 != "NO ADDRESS" 
count if district_1 == "" & address !="" & county_1 == ""

keep address_orig district_1 county_1 subdist_1 parish_1 
order address_orig district_1 county_1 subdist_1 parish_1
rename subdist_1 subdist 
rename parish_1 parish
rename county_1 county
rename district_1 district
sort address_orig

tempfile address
save `address', replace

use "$PROJ_PATH/processed/intermediate/hospitals/hosp_addresses_cleaned.dta", clear
merge 1:1 address_orig using `address', assert(3) nogen
egen address_cleaned = concat(add1-add5), punct(,)
replace address_cleaned = regexr(address_cleaned,"(,)*$","")
replace address_cleaned = subinstr(address_cleaned,",",", ",.)
drop add_inprog add1-add5 address 

replace county = "LONDON" if postcode != "" & county == ""

gen flag_error = (regexm(address_cleaned,"KENNINGTON") & district == "EAST ASHFORD")
replace district = "LAMBETH" if flag_error == 1
replace subdist = "KENNINGTON" if flag_error == 1
replace parish = "LAMBETH" if flag_error == 1
replace county = "SURREY" if flag_error == 1
drop flag_error

* Fix district and county variables

replace district = "" if district == "NO ADDRESS"
replace district = proper(district)
split district, parse(", ") gen(district)
local max_nvars = r(nvars)
rename district dist_orig
forvalues dist = 1(1)`max_nvars' {
	rename district`dist' district
	merge m:1 district using "$PROJ_PATH/processed/intermediate/geography/london_district_list.dta"
	tab district if _merge == 2
	drop if _merge == 2
	replace county = "LONDON" if _merge == 3
	drop _merge district
}
rename dist_orig district
replace district = upper(district)

replace county = proper(county)
replace county = "Yorkshire" if regexm(county,"Yorkshire")==1
replace county = "" if county == "No Address" | county == "Readmission"
replace county = upper(county)
replace county = "LONDON, MIDDLESEX" if county == "LONDON" & regexm(district,"EDMONTON") // NOTE: Some multiple district entries include Edmonton which is a district in Middlesex
replace parish = "" if parish == "NO ADDRESS"

sort address_orig	
save "$PROJ_PATH/processed/intermediate/hospitals/hosp_residence_coded.dta", replace

disp "DateTime: $S_DATE $S_TIME"

* EOF
