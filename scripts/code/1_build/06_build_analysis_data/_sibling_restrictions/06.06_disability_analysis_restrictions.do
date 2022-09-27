/***** 06.06_disability_analysis_restrictions.do
	* Restrict sample to one sibling vs. one patient comparisons by:
		* Dropping households with multiple patients
		* Restricting to closest healthy sibling
	* Defines baseline sample restrictions
*/

args disability_restrictions

quietly {
	local samp_pat "samp_pat = max(patient == 1 & insample == 1 & age_diff == 0), by(sibling_id)"
	local samp_sib "samp_sib = max(patient == 0 & insample == 1 & age_diff <= 5), by(sibling_id)"

	gen flag_extra_sibpat = 0
	
	gen insample = (disab_any != . & `disability_restrictions' == 1)

	* Compute age difference between siblings
	
	preserve
	keep if patient == 1 & insample == 1
	keep sibling_id age_child
	bysort sibling_id age_child: keep if _n == 1
	egen temp_id = seq(), by(sibling_id)
	sum temp_id
	local max_obs = r(max)
	rename age_child patage
	reshape wide patage, i(sibling_id) j(temp_id)
	tempfile age_diff
	save `age_diff', replace
	restore
	
	* Compute pid difference between siblings
	
	preserve
	keep if patient == 1 & insample == 1
	keep sibling_id pid
	bysort sibling_id pid: keep if _n == 1
	egen temp_id = seq(), by(sibling_id)
	sum temp_id
	local max_pid = r(max)
	rename pid patpid
	reshape wide patpid, i(sibling_id) j(temp_id)
	tempfile pid_diff
	save `pid_diff', replace
	restore	

	capture drop age_diff
	capture drop pid_diff
	tempvar sortorder
	gen `sortorder' = _n
	merge m:1 sibling_id using `age_diff', assert(1 3) keep(1 3) nogen
	merge m:1 sibling_id using `pid_diff', assert(1 3) keep(1 3) nogen
	
	forvalues x = 1(1)`max_obs' {
		gen temp`x' = abs(age_child - patage`x')
	}
	egen age_diff = rowmin(temp1-temp`max_obs')
	drop temp* patage*
	
	forvalues x = 1(1)`max_pid' {
		gen temp`x' = abs(pid - patpid`x')
	}
	egen pid_diff = rowmin(temp1-temp`max_pid')
	drop temp* patpid*
	
	sort `sortorder'
	drop `sortorder'
	
	egen `samp_pat'
	egen `samp_sib'
	
	gen base_sample = (samp_pat == 1 & samp_sib == 1 & insample == 1)

	* Drop households with multiple patients
	
	egen mult_pat_hh = total(insample == 1 & patient == 1 & samp_pat == 1), by(sibling_id)
	replace flag_extra_sibpat = 1 if mult_pat_hh > 1 & !missing(mult_pat_hh)
	drop mult_pat_hh insample samp_pat samp_sib
	
	gen insample = (disab_any != . & base_sample == 1 & flag_extra_sibpat == 0 & `disability_restrictions' == 1)
	egen `samp_pat'
	egen `samp_sib'	
	
	* Drop sibling if not closest in age to patient
	
	egen closest_sib = min(age_diff) if patient == 0 & insample == 1, by(sibling_id)
	replace flag_extra_sibpat = 1 if age_diff != closest_sib & patient == 0 & insample == 1
	drop insample samp_pat samp_sib

	gen insample = (disab_any != . & base_sample == 1 & flag_extra_sibpat == 0 & `disability_restrictions' == 1)
	egen `samp_pat'
	egen `samp_sib'	
	
	* Keep older sibling if patient's RecID is even; younger if odd
	
	tempvar tot_sibs hh_with_2plus_sibs odd_id tot_oddpats oldest
	
	egen `tot_sibs' = total(patient == 0 & insample == 1 & samp_pat == 1 & samp_sib == 1), by(sibling_id)
	gen `hh_with_2plus_sibs' = (`tot_sibs' > 1)
	
	gen `odd_id' = mod(RecID,2)
	egen `tot_oddpats' = total(patient == 1 & `odd_id' == 1), by(sibling_id)
	
	egen `oldest' = min(brthord) if patient == 0 & insample == 1 & samp_pat == 1 & samp_sib == 1, by(sibling_id)
	
	replace flag_extra_sibpat = 1 if `hh_with_2plus_sibs' == 1 & patient == 0 & `tot_oddpats' > 0 & brthord == `oldest' // In households with > 1 siibling, drop younger sibling if patient's RecID is odd
	replace flag_extra_sibpat = 1 if `hh_with_2plus_sibs' == 1 & patient == 0 & `tot_oddpats' == 0 & brthord != `oldest' // In households with > 1 siibling, drop older sibling if patient's RecID is even
			
	drop `tot_sibs' `hh_with_2plus_sibs' `odd_id' `tot_oddpats' `oldest'
	
	drop insample samp_pat samp_sib closest_sib
	
	gen insample = (disab_any != . & base_sample == 1 & flag_extra_sibpat == 0 & `disability_restrictions' == 1)
	egen `samp_pat'
	egen `samp_sib'
	
	* Drop sibling if not closest in enumeration position to patient
	
	egen closest_sib = min(pid_diff) if patient == 0 & insample == 1, by(sibling_id)
	replace flag_extra_sibpat = 1 if pid_diff != closest_sib & patient == 0 & insample == 1
	drop insample samp_pat samp_sib closest_sib
	
	gen insample = (disab_any != . & base_sample == 1 & flag_extra_sibpat == 0 & `disability_restrictions' == 1)
	egen `samp_pat'
	egen `samp_sib'
	
	drop flag_extra_sibpat base_sample
	
	* Define variable for older sibling of each patient and healthy sibling pair

	egen first_sib = min(brthord) if insample == 1 & samp_pat == 1 & samp_sib == 1, by(sibling_id)
	gen older_sib = (brthord == first_sib)
	drop first_sib
		
}
