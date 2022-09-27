version 14

// Assign Williamson wages
// Source: http://www.pierre-marteau.com/currency/indices/uk-03.html

capture program drop williamson
program define williamson 

	args year

	if `year' == 1881 | `year' == 1891 | `year' == 1901 | `year' == 1911 {
		capture drop *wage`year'*
		gen wage`year' = .
	}
	else if `year' != . {
		di in red "Year must be 1881, 1891, 1901, or 1911"
		exit
	}
	else {
		di in red "You must include one argument: specify the year to be 1881, 1891, 1901, or 1911"
	}

	tempvar wg_police wg_teachers wg_aglab wg_laborer wg_govt_low wg_miners wg_trades wg_porters wg_textiles wg_ships wg_engineer wg_printing wg_clerks wg_doctors wg_govt_high wg_clergy wg_law wg_commodity wg_railways wg_domestics wg_surveyor
	
	gen `wg_police' 	= inlist(Occode,10,11) 
	gen `wg_teachers' 	= inlist(Occode,52,53,54,70,73,79,107, 783) 
	gen `wg_aglab' 		= inlist(Occode,139,185,187,190,734,735) | inrange(Occode,175,176) | inrange(Occode,178,181)
	gen `wg_laborer' 	= inlist(Occode,141,166,168,169,170,205,274,354,436,764,765) 
	gen `wg_govt_low' 	= inlist(Occode,1,2,3,4) 
	gen `wg_miners' 	= inlist(Occode,142,147) | (Occode >= 196 & Occode <= 200) | Occode == 203 | (Occode >= 207 & Occode <= 213) | inlist(Occode,215,224,225,227,230,231,232) 
	gen `wg_trades' 	= inlist(Occode,192,405,406,407,409,410,412,413,414,415,416,417,418,419,420,422,423,424,425,435) | (Occode >= 437 & Occode <= 446) 
	gen `wg_porters' 	= Occode == 16 | (Occode == 103 & regexm(Occ,"PORTER") | Occode == 171)
	gen `wg_textiles'	= Occode == 298 |  Occode == 505 | (Occode >= 548 & Occode <= 628 ) | (Occode >= 645 & Occode <= 665 & Occode != 655 & Occode != 656 & Occode != 660) | Occode == 670 | Occode == 741
	gen `wg_ships' 		= inlist(Occode,345,346,348,349,350,351) 
	gen `wg_clerks' 	= inlist(Occode,40,41,55,119,121,123,729) | (Occode == 125 & regexm(Occ,"CLERK") == 1)
	gen `wg_doctors' 	= Occode == 42 
	gen `wg_govt_high' 	= inrange(Occode,5,7) | inrange(Occode,12,15) 
	gen `wg_clergy' 	= inrange(Occode,28,33)
	gen `wg_law' 		= Occode == 38 | Occode == 39
	gen `wg_commodity'  = inrange(Occode,241,252) 
	gen `wg_domestics'	= inrange(Occode,82,87) | (Occode == 88 & regexm(Occ,"DOMESTIC")) | inlist(Occode,93,101,102,109) 
	gen `wg_surveyor'	= inrange(Occode,64,69) | Occode == 201 | (Occode == 279 & regexm(Occ,"ENGINEER") & regexm(Occ,"LABOURER") == 0) | (Occode == 284 & regexm(Occ,"ENGINEER") & regexm(Occ,"LABOURER") == 0) 
	gen `wg_railways' 	= (inrange(Occode,125,134) & regexm(Occ,"CLERK") == 0) | inlist(Occode,265,281)
	
	if `year' == 1881 {

		replace wage1881 = 76.73 if `wg_police' == 1 		// Police and guards
		replace wage1881 = 120.80 if `wg_teachers' == 1		// Teachers
		replace wage1881 = 41.52 if `wg_aglab' == 1			// Agricultural laborers
		replace wage1881 = 55.88 if `wg_laborer' == 1		// General non-agricultural laborers
		replace wage1881 = 74.65 if `wg_govt_low' == 1		// Government low wage
		replace wage1881 = 59.58 if `wg_miners' == 1		// Miners
		replace wage1881 = 87.18 if `wg_trades' == 1		// Skilled in building trades
		replace wage1881 = 97.05 if `wg_porters' == 1		// Messengers and Porters (Private Sector)
		replace wage1881 = 85.77 if `wg_textiles' == 1		// Skilled in textiles
		replace wage1881 = 81.38 if `wg_ships' == 1			// Skilled in shipbuilding 
		replace wage1881 = 286.65 if `wg_clerks' == 1		// Clerks (Private Sector)
		replace wage1881 = 520.29 if `wg_doctors' == 1		// Surgeons and doctors
		replace wage1881 = 275.29 if `wg_govt_high' == 1	// Government high wage
		replace wage1881 = 315.37 if `wg_clergy' == 1		// Clergymen and ministers
		replace wage1881 = 1280 if `wg_law' == 1			// Solicitors and barristers
		replace wage1881 = 312.97 if `wg_surveyor' == 1		// Engineers and surveyors	
		replace wage1881 = 64.58 if `wg_commodity' == 1		// Manual workers in commodity production
		replace wage1881 = 55 if `wg_domestics' == 1		// Male domestics
		replace wage1881 = 58.85 if `wg_railways' == 1 		// Railways
		
		// Manual recoding
		replace wage1881 = 286.65 if regexm(Occ,"CLERK") & wage1881 == .
		replace wage1881 = 55.88 if regexm(Occ,"LABOURER") & `wg_aglab' == 0

	}
	else if `year' == 1891 {
		
		replace wage1891 = 72.33 if `wg_police' == 1 		// Police and guards
		replace wage1891 = 133.90 if `wg_teachers' == 1		// Teachers
		replace wage1891 = 41.94 if `wg_aglab' == 1			// Agricultural laborers
		replace wage1891 = 62.68 if `wg_laborer' == 1		// General non-agricultural laborers
		replace wage1891 = 70.40 if `wg_govt_low' == 1		// Government low wage
		replace wage1891 = 82.75 if `wg_miners' == 1		// Miners
		replace wage1891 = 91.52 if `wg_trades' == 1		// Skilled in building trades
		replace wage1891 = 89.51 if `wg_porters' == 1		// Messengers and Porters (Private Sector)
		replace wage1891 = 93.60 if `wg_textiles' == 1		// Skilled in textiles
		replace wage1891 = 87.80 if `wg_ships' == 1			// Skilled in shipbuilding 
		replace wage1891 = 268.06 if `wg_clerks' == 1		// Clerks (Private Sector)
		replace wage1891 = 475.47 if `wg_doctors' == 1		// Surgeons and doctors
		replace wage1891 = 215.01 if `wg_govt_high' == 1	// Government high wage
		replace wage1891 = 336.90 if `wg_clergy' == 1		// Clergymen and ministers
		replace wage1891 = 1342.60 if `wg_law' == 1			// Solicitors and barristers
		replace wage1891 = 380.61 if `wg_surveyor' == 1		// Engineers and surveyors	

		// Manual recoding
		replace wage1891 = 268.06 if regexm(Occ,"CLERK") & wage1891 == .
		replace wage1891 = 62.68 if regexm(Occ,"LABOURER") & `wg_aglab' == 0
	}
	else if `year' == 1901 {

		replace wage1901 = 68.69 if `wg_police' == 1 		// Police and guards
		replace wage1901 = 147.50 if `wg_teachers' == 1		// Teachers
		replace wage1901 = 46.12 if `wg_aglab' == 1			// Agricultural laborers
		replace wage1901 = 68.90 if `wg_laborer' == 1		// General non-agricultural laborers
		replace wage1901 = 72.20 if `wg_govt_low' == 1		// Government low wage
		replace wage1901 = 89.37 if `wg_miners' == 1		// Miners
		replace wage1901 = 103.35 if `wg_trades' == 1		// Skilled in building trades
		replace wage1901 = 101.97 if `wg_porters' == 1		// Messengers and Porters (Private Sector)
		replace wage1901 = 101.40 if `wg_textiles' == 1		// Skilled in textiles
		replace wage1901 = 92.51 if `wg_ships' == 1			// Skilled in shipbuilding 
		replace wage1901 = 286.86 if `wg_clerks' == 1		// Clerks (Private Sector)
		replace wage1901 = 265.39 if `wg_doctors' == 1		// Surgeons and doctors
		replace wage1901 = 159.63 if `wg_govt_high' == 1	// Government high wage
		replace wage1901 = 238 if `wg_clergy' == 1			// Clergymen and ministers
		replace wage1901 = 1500 if `wg_law' == 1			// Solicitors and barristers
		replace wage1901 = 333.99 if `wg_surveyor' == 1		// Engineers and surveyors	
		replace wage1901 = 79.27 if `wg_commodity' == 1		// Manual workers in commodity production
		replace wage1901 = 63.65 if `wg_domestics' == 1		// Male domestics
		replace wage1901 = 69.34 if `wg_railways' == 1		// Railways

		// Manual recoding
		replace wage1901 = 286.86 if regexm(Occ,"CLERK") & wage1901 == .
		replace wage1901 = 68.90 if regexm(Occ,"LABOURER") & `wg_aglab' == 0

	}
	else if `year' == 1911 {

		replace wage1911 = 70.62 if `wg_police' == 1 		// Police and guards
		replace wage1911 = 176.15 if `wg_teachers' == 1		// Teachers
		replace wage1911 = 46.96 if `wg_aglab' == 1			// Agricultural laborers
		replace wage1911 = 74.04 if `wg_laborer' == 1		// General non-agricultural laborers
		replace wage1911 = 67.95 if `wg_govt_low' == 1		// Government low wage
		replace wage1911 = 83.63 if `wg_miners' == 1		// Miners
		replace wage1911 = 105.14 if `wg_trades' == 1		// Skilled in building trades
		replace wage1911 = 85.91 if `wg_porters' == 1		// Messengers and Porters (Private Sector)
		replace wage1911 = 108.50 if `wg_textiles' == 1		// Skilled in textiles
		replace wage1911 = 102.34 if `wg_ships' == 1		// Skilled in shipbuilding 
		replace wage1911 = 229.89 if `wg_clerks' == 1		// Clerks (Private Sector)
		replace wage1911 = 272.75 if `wg_doctors' == 1		// Surgeons and doctors
		replace wage1911 = 161.61 if `wg_govt_high' == 1	// Government high wage
		replace wage1911 = 206 if `wg_clergy' == 1			// Clergymen and ministers
		replace wage1911 = 1343.50 if `wg_law' == 1			// Solicitors and barristers
		replace wage1911 = 287.37 if `wg_surveyor' == 1		// Engineers and surveyors	

		// Manual recoding
		replace wage1911 = 229.89 if regexm(Occ,"CLERK") & wage1911 == .
		replace wage1911 = 74.04 if regexm(Occ,"LABOURER") & `wg_aglab' == 0

	}	
	drop `wg_police' `wg_teachers' `wg_aglab' `wg_laborer' `wg_govt_low' `wg_miners' `wg_trades' `wg_porters' `wg_textiles' `wg_ships' `wg_clerks' `wg_doctors' `wg_govt_high' `wg_clergy' `wg_law' `wg_commodity' `wg_domestics' `wg_surveyor' `wg_railways'

end
