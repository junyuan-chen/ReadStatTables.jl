* Generate stringtypes.dta for testing purposes
version 17
clear

set obs 3

local strwidths = "1 3 4 7 8 15 16 31 32"

foreach v of local strwidths {
    gen str`v' vstr`v' = "a"
    replace vstr`v' = "" if _n==_N
}

save data/stringtypes.dta, replace
