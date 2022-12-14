program define labvalch
*! NJC 1.1.0 12 July 2002 
* NJC 1.0.1 6 April 2000 
* NJC 1.0.0 13 January 2000 
	version 7 
	gettoken vallbl 0 : 0, parse(" ,")  
	capture label list `vallbl' 
	if _rc { 
		di as err "`vallbl' not a value label" 
		exit 498 
	} 	
	
	syntax , [ From(numlist min=1 int) To(numlist min=1 int) /* 
	*/ Swap(numlist min=2 max=2 int) DELETE(numlist min=1 int) List ] 

	if "`swap'`from'`to'`delete'" == "" { 
		di as txt "nothing to do?" 
		exit 0 
	}

	if "`swap'" != "" & "`from'`to'" != "" { 
		di as err "may not combine swapping and mapping" 
		exit 198 
	} 
	
	local nopts = ("`from'" != "") + ("`to'" != "") 
	if `nopts' == 1 { 
		di as err "from( ) must be combined with to( )"
		exit 198 
	}	

	local newline "_n" 
	
	if "`swap'" != "" { /* swapping */ 
		tokenize `swap' 
		forval i = 1/2 { 
			local l`i' : label `vallbl' ``i'' 
			if `"`l`i''"' == "``i''" { 
				di as err "`vallbl': no value label for ``i''" 
				exit 498 
			}	
		}	

		di _n as txt `"label def `vallbl' `1' `"`l2'"' "' _c 
		di as txt `" `2' `"`l1'"', modify "'
                label def `vallbl' `1' `"`l2'"' `2' `"`l1'"', modify  
		local newline 
	} 	

	if "`from'`to'" != "" { /* mapping */  
		local nfrom : word count `from' 
		local nto : word count `to' 

		if `nfrom' != `nto' { 
			di as err "from( ) and to( ) should match one-one" 
			exit 198
		}

		tokenize `from' 
		forval i = 1 / `nfrom' { 
			local l`i' : label `vallbl' ``i'' 
			if `"`l`i''"' == "``i''" { 
				di as err "`vallbl': no value label for ``i''" 
				exit 498 
			}
			local t`i' : word `i' of `to' 
			local args `"`args'`t`i'' `"`l`i''"' "' 
		} 

		di _n as txt `"label def `vallbl' `args', modify"'   
		label def `vallbl' `args', modify  
		local newline 
	}	

	if "`delete'" != "" { 
		local args 
		tokenize `delete' 
		local ndelete : word count `delete' 
		forval i = 1 / `ndelete' {
			local l`i' : label `vallbl' ``i'' 
			if `"`l`i''"' == "``i''" { 
				local msg "`msg'``i'' " 
			}
			else local args `"`args'``i'' "" "' 
		} 
		if `"`args'"' != "" { 
			di `newline' as txt `"label def `vallbl' `args', modify"'   
			label def `vallbl' `args', modify  
			local newline 
		} 
		if `"`msg'"' != "" { 
			local wc : word count `msg' 
			local s = cond(`wc' > 1, "s", "")  
			di `newline' as txt /* 
			*/ "note: `vallbl': label`s' for `msg'not defined" 
		} 
	} 
	
	if "`list'" != "" {
		di 
		label li `vallbl' 
	} 
end 

/* 
Note: 

We delete a label for # by 

label def lblname # "" , modify 

Any subsequent 

label def lblname # "" , modify 

redefines the label as an empty string. So we need to trap that. 

*/ 


