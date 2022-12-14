program define labdel 
*! NJC 1.0.0 13 January 2000 
	version 6 
	gettoken vallbl 0 : 0, parse(" ,")  
	capture label list `vallbl' 
	if _rc { 
		di in r "`vallbl' not a value label" 
		exit 498 
	} 	
	
	syntax , Delete(numlist min=1 int) [ List ] 

	tokenize `delete' 
	while "`1'" != "" { 
		local l : label `vallbl' `1' 
		if `"`l'"' == "`1'" { 
			di in r "`vallbl': no value label for `1'" 
			exit 498 
		}
		local args `"`args' `1' "" "'  
		mac shift 
	} 

	di _n `"label def `vallbl' `args', modify"'   
	label def `vallbl' `args', modify  
		
	if "`list'" != "" {
		di 
		label li `vallbl' 
	} 
end 

