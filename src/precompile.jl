using PrecompileTools: @compile_workload

@compile_workload begin
    dta = "$(@__DIR__)/../data/sample.dta"
    readstat(dta, ntasks=1)
    readstat(dta, ntasks=2)
end
