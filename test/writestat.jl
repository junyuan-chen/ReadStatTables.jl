@testset "writestat dta" begin
    dta = "$(@__DIR__)/../data/sample.dta"
    d = readstat(dta)
    #out = writestat("$(@__DIR__)/../data/write.dta", d)

    df = DataFrame(d)
    # Drop the date/time columns as the conversion is not implemented yet
    df2 = df[!,[:mychar, :mynum, :mylabl, :myord]]
    if VERSION >= v"1.6"
        out = writestat("$(@__DIR__)/../data/write_fallback.dta", df2)
        @test typeof(out) == ReadStatTable{DataFrames.DataFrameColumns{DataFrame}}
        @test size(out) == size(df2)
    end
end
