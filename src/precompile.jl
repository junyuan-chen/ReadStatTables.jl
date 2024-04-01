using PrecompileTools: @compile_workload

@compile_workload begin
    dta = "$(@__DIR__)/../data/alltypes.dta"
    readstat(dta, ntasks=1)
    tb = readstat(dta, ntasks=2)
    out = "$(@__DIR__)/../data/write_alltypes.dta"
    writestat(out, tb)
end
