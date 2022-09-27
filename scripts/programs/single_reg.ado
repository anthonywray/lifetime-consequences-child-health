* Program for the single marital status regressions

cap program drop single_reg
program define single_reg
	version 14
	
	syntax, panel(string) col(string) control_list(string) clustervar(string) sigma(string)
			
	eststo p`panel'r1c`col': xtreg single patient `control_list', fe cluster(`clustervar')
	estadd ysumm
	matrix b = e(b)
	estadd scalar pctbeta = abs(b[1,1]*100/e(ymean)): p`panel'r1c`col'

	eststo p`panel'r2c`col': xtreg single resid_mort `control_list', fe cluster(`clustervar')
	estadd ysumm
	matrix b = e(b)
	estadd scalar pctbeta = abs(b[1,1]*`sigma'*100/e(ymean)): p`panel'r2c`col'

	count
	local big_N = r(N)
	estadd scalar hh_N = `big_N'/2 : p`panel'r2c`col'

end
