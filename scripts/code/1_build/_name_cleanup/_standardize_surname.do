version 14

* Surname specific commands:

replace surname = regexr(surname," OR$","")
replace surname = regexr(surname,"^OR ","")
replace surname = subinstr(surname," (())","",.)
replace surname = regexr(surname,"^\(","")
replace surname = regexr(surname,"\)$","") if regexm(surname,"\(")==0
replace surname = regexr(surname, "\(O ", "(O")
replace surname = regexr(surname, "^DE L ","DEL")

* Create separate variable with alternative transcription of surname (found in parentheses or following "OR")
gen alt_surname = ""
replace surname = trim(surname)
replace alt_surname = regexs(1) if regexm(surname,"\(([A-Z| ]+)\)$")
replace alt_surname = regexs(1) if regexm(surname,"\(([A-Z| ]+)\)\)$")
replace surname = regexs(1) if regexm(surname,"^([A-Z| ]+)\(") 
replace surname = regexs(1) if regexm(surname,"^([A-Z| ]+) \(")

replace alt_surname = regexs(1) if regexm(surname," [O|0][R|N] ([A-Z| ]+)$")
replace surname = regexs(1) if regexm(surname,"^([A-Z| ]+) [O|0][R|N] ")
replace surname = regexr(surname," [O|0][R|N] ([A-Z| ]+)$","")
replace alt_surname = regexr(alt_surname," [O|0][R|N] ([A-Z| ]+)$","")

* Get rid of text in parentheses 
replace surname = regexr(surname,"\([.]+\)","")

local punctuation "( )"
foreach symbol of local punctuation {
	replace surname = subinstr(surname,"`symbol'","",.)
}
replace surname = trim(surname)
replace alt_surname = trim(alt_surname)

* Drop single letter at beginning of name (with exception of O)
replace surname = regexr(surname,"^O ","O")
replace alt_surname = regexr(alt_surname,"^O ","O")
gen initial = regexs(1) if regexm(surname,"^([A-Z])[ ]")
gen alt_initial = regexs(1) if regexm(alt_surname,"^([A-Z])[ ]")
replace surname = regexr(surname,"^[A-Z][ ]([A-Z][ ])*([A-Z][ ])*([A-Z][ ])*(A-Z)*( )*","")
replace alt_surname = regexr(alt_surname,"^[A-Z][ ]([A-Z][ ])*([A-Z][ ])*([A-Z][ ])*(A-Z)*( )*","")
replace surname = regexr(surname,"[ ][A-Z]$","")

* Some middle names get into surname
replace surname = regexr(surname,"^[A-Z]+[ ][A-Z][ ]","")

* Add middle initial info from surname 
* replace midname = substr(initial,1,1) if midname == ""
* replace midname = substr(alt_initial,1,1) if midname == ""
* drop initial alt_initial

* Split remaining names
split surname, parse(" ") gen(sname) limit(2)
local max_split = r(nvars)
drop surname

* Reshape to create separate observation for each alt_surname
gen long obs_id = _n
save "$PROJ_PATH/processed/temp/snames_inprog.dta", replace

keep alt_surname sname* obs_id
duplicates drop
rename alt_surname sname0
gen row_id = _n
greshape long sname, i(row_id) j(name_id)
drop row_id name_id
drop if sname == ""
gduplicates drop
gegen indiv_id = group(obs_id)
sort obs_id sname 
egen name_id = seq(), by(obs_id)
sum name_id
local max_obs = r(max)
greshape wide sname, i(indiv_id) j(name_id)
drop indiv_id
egen surname = concat(sname1-sname`max_obs'), p(;)
replace surname = regexr(surname,"[;]+$","")
drop sname*
compress surname
save "$PROJ_PATH/processed/temp/snames.dta", replace

use "$PROJ_PATH/processed/temp/snames_inprog.dta", clear
drop sname1-sname`max_split' alt_surname
gduplicates drop
fmerge 1:1 obs_id using "$PROJ_PATH/processed/temp/snames.dta", keep(1 3) assert(1 3) nogen
drop obs_id

rm "$PROJ_PATH/processed/temp/snames_inprog.dta"
rm "$PROJ_PATH/processed/temp/snames.dta"
