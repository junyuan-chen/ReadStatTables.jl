* Generate alltypes.dta for testing purposes
version 17
clear

set obs 3
gen byte vbyte = 1 if _n == 1
gen int vint = 1 if _n == 1
gen long vlong = 1 if _n == 1
gen float vfloat = 1 if _n == 1
gen double vdouble = 1 if _n == 1
gen str2 vstr = "ab" if _n == 1
gen strL vstrL = "This is a long string! This is a long string! This is a long string! This is a long string! This is a long string!" if _n == 1

replace vbyte = .a if _n == 2
replace vint = .a if _n == 2
replace vlong = .a if _n == 2
replace vfloat = .a if _n == 2
replace vdouble = .a if _n == 2
* Missing values for string variables are simply empty strings

label define testlbl 1 "A" .a "Tagged missing", add
* Cannot attach value labels to string variables
label values vbyte vint vlong vfloat vdouble testlbl

save alltypes.dta, replace
