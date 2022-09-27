version 14

args name_list 

local name_type `name_list'
quietly {
	foreach name of local name_type {
		rename `name' workname
		replace workname = upper(workname)

		// First remove any non-alpha characters

		gen namelen=length(workname)
		sum namelen
		local longname=r(max)
		drop namelen

		replace workname=trim(workname)
		
		replace workname = regexr(workname,"\.","") if regexm(workname,"[A-Z]\.[A-Z]")
		replace workname = regexr(workname,"\.","") if regexm(workname,"[A-Z]\.[A-Z]")
		replace workname = regexr(workname,"\.","") if regexm(workname,"[A-Z]\.[A-Z]")
		
		replace workname = subinstr(workname,"."," ",.)
		replace workname = subinstr(workname,"    "," ",.)
		replace workname = subinstr(workname,"   "," ",.)
		replace workname = subinstr(workname,"  "," ",.)
		replace workname = subinstr(workname,"?","",.)
			
		local symbol_list "! @ # $ % ^ & * ' ( ) / \ : ; | ~ ` < > , ? { } = + [ ] - _"
		foreach symbol of local symbol_list {
			qui replace workname = subinstr(workname,"`symbol'","",.)
		}
		replace workname=trim(workname)

		qui replace workname = regexr(workname,"^COUNTESS OF ","")
		qui replace workname = regexr(workname,"^MARQUIS OF ","")
		qui replace workname = regexr(workname,"INFANT","")
		qui replace workname = regexr(workname,"BABY","")
		qui replace workname = regexr(workname," TWIN$","")
		qui replace workname = regexr(workname," \(TWIN\)$","")
		qui replace workname = regexr(workname,"UNNAMED","")
		qui replace workname = regexr(workname,"NO(T)* NAME[D|S]","")
		qui replace workname = regexr(workname,"NO( )*NAME","")
		qui replace workname = regexr(workname,"NAMELESS","")
		qui replace workname = regexr(workname,"UNREADABLE","")
		qui replace workname = regexr(workname,"NOT KNOWN","")
		qui replace workname = regexr(workname,"^DR ","")
		qui replace workname = regexr(workname,"^JR ","")
		qui replace workname = regexr(workname,"^MDEL ","")
		qui replace workname = regexr(workname,"^MR ","")
		qui replace workname = regexr(workname,"^MRS ","")
		qui replace workname = regexr(workname,"^NK ","")
		qui replace workname = regexr(workname,"^SIR ","")
		qui replace workname = regexr(workname," SIR ","")
		qui replace workname = regexr(workname," JR$","")
		qui replace workname = regexr(workname," \(JNR\)$","")
		qui replace workname = regexr(workname," SR$","")
		qui replace workname = regexr(workname," 2D$","")
		qui replace workname = regexr(workname," 3RD$","")
		qui replace workname = regexr(workname," 2ND$","")
		qui replace workname = regexr(workname," III$","")
		qui replace workname = regexr(workname," NEE ","")
		qui replace workname = regexr(workname," ALIAS ","")
		qui replace workname = regexr(workname," JUN$","")
		qui replace workname = regexr(workname," JUNR$","")
		qui replace workname = regexr(workname," JUR$","")
		qui replace workname = regexr(workname," JNR$","")
		qui replace workname = regexr(workname," JUNIOR$","")
		qui replace workname = regexr(workname," SEN$","")
		qui replace workname = regexr(workname," SENR$","")
		qui replace workname = regexr(workname," SNR$","")
		qui replace workname = regexr(workname," SENIOR$","")
		qui replace workname = regexr(workname," SENOR$","")
		qui replace workname = regexr(workname," SER$","")
		qui replace workname = regexr(workname," M D$","")
		qui replace workname = regexr(workname," MARRIED$","")
		qui replace workname = regexr(workname," SINGLE$","")
		qui replace workname = trim(workname)
		qui replace workname = subinstr(workname,"  "," ",.)
		qui replace workname = "" if workname == "N K" | workname == "NK"

		// Eliminate space following prefix in firstname and surname
		
		local prefix_list "DA DE DELA DEL DES DER DI DOS DU DEN FITZ JE KAUF KAUFF LE LA MAC MC NA O ORE SAN ST DEST VANDER VONDER VAN VA VON"
		foreach prefix of local prefix_list {
			qui replace workname = subinstr(workname, " `prefix' ", " `prefix'",.)
			if "`name'" == "fullname" {
				qui replace workname = regexr(workname, "^`prefix' ", "`prefix'") if regexm(workname, "^`prefix'[ ][A-Z][A-Z]+[ ]") == 1
			} 
			else {
				qui replace workname = regexr(workname, "^`prefix' ", "`prefix'")
			}
		}
		rename workname `name'
	}
}
