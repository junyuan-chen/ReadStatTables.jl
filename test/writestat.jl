@testset "writestat conversion" begin
    @test rstype(Int64) == READSTAT_TYPE_INT32
    @test_throws ErrorException rstype(ComplexF64)

    alltypes = "$(@__DIR__)/../data/alltypes.dta"
    df = DataFrame(readstat(alltypes))
    emptycolmetadata!(df)
    df[!,:vbyte] = CategoricalArray(valuelabels(df.vbyte))
    df[!,:vint] = PooledArray(valuelabels(df.vint))
    tb = ReadStatTable(df, ".dta", maxdispwidth=70)
    @test colmetadata(tb, :vbyte, :vallabel) == :vbyte
    lbl = getvaluelabels(tb.vbyte)
    @test typeof(lbl) == Dict{Union{Char, Int32}, String}
    @test lbl[1] == "A"
    # How missing values are handled will be changed in v0.3
    @test lbl[2] == "missing"
    @test colmetadata(tb, :vint, :vallabel) == :vint
    @test getvaluelabels(tb.vint) == lbl
    # Date/Time columns are converted to numbers
    @test eltype(getfield(tb, :columns)[8]) >: Int32
    @test eltype(getfield(tb, :columns)[9]) >: Float64
    @test colmetadata(tb, :vstrL, "display_width") == 70

    df = DataFrame(readstat(alltypes))
    emptycolmetadata!(df)
    df[!,:vint] = PooledArray(valuelabels(df.vint))
    tb2 = ReadStatTable(df, ".dta", refpoolaslabel=false)
    @test tb2.vint isa Vector{String}
    @test colmetadata(tb2, :vint, :vallabel) == Symbol()
    df[!,:vbyte] = CategoricalArray(valuelabels(df.vbyte))
    # CategoricalValue is not handled
    @test_throws ErrorException ReadStatTable(df, ".dta", refpoolaslabel=false)

    df = DataFrame(readstat(alltypes))
    emptycolmetadata!(df)
    df[!,:vint] = PooledArray(valuelabels(df.vint))
    @test_throws ErrorException ReadStatTable(df, ".dta", refpoolaslabel=false, copycols=false)
    tb3 = ReadStatTable(df[!,1:7], ".dta", refpoolaslabel=false, copycols=false)
    @test tb3.vint isa PooledArray
    @test colmetadata(tb3, :vint, :vallabel) == Symbol()
    df[!,:vbyte] = CategoricalArray(valuelabels(df.vbyte))
    # CategoricalValue is not handled
    @test_throws ErrorException ReadStatTable(df, ".dta", refpoolaslabel=false)
end

@testset "writestat date format" begin
    outfile = "$(@__DIR__)/../data/test_date.dta"
    df = DataFrame((date = [missing, Date(1960, 1, 1), Date(1960, 1, 31), Date(1960, 2, 1),
        Date(1960, 3, 31), Date(1960, 4, 1), Date(1960, 6, 30), Date(1960, 7, 1),
        Date(1960, 12, 31), Date(1961, 1, 1), Date(1961, 3, 31),
        Date(1959, 12, 31), Date(1959, 12, 1), Date(1959, 7, 1), Date(1959, 6, 30)]))
    tb = ReadStatTable(df, ".dta", varformat=Dict(:date=>"%td"))
    @test isequal(tb.date, df.date)
    tb = writestat(outfile, df, varformat=Dict(:date=>"%tw"))
    @test eltype(tb.date) == Union{Date, Missing}
    # Compare results from Stata
    # In Mata mode, use "wofd(mdy(6, 30, 1959))" to generate value
    @test isequal(tb.date.data,
        [missing, 0, 4, 4, 12, 13, 25, 26, 51, 52, 64, -1, -5, -27, -27])
    # Compare dates with weeks displayed in Stata
    w = [1, 5, 5, 13, 14, 26, 27, 52, 1, 13, 52, 48, 26, 26]
    @test isequal(tb.date,
        [missing, (Date.(year.(df.date[2:end]), 1, 1) .+ Day.(7 .* (w .- 1)))...])
    tb = writestat(outfile, df, varformat=Dict(:date=>"%tm"))
    @test eltype(tb.date) == Union{Date, Missing}
    @test isequal(tb.date.data, [missing, 0, 0, 1, 2, 3, 5, 6, 11, 12, 14, -1, -1, -6, -7])
    @test isequal(tb.date, [missing,
        (Date.(year.(df.date[2:end]), 1, 1) .+ Month.(month.(df.date[2:end]).-1))...])
    tb = writestat(outfile, df, varformat=Dict(:date=>"%tq"))
    @test isequal(tb.date.data, [missing, 0, 0, 0, 0, 1, 1, 2, 3, 4, 4, -1, -1, -2, -3])
    @test isequal(tb.date, [missing, (Date.(year.(df.date[2:end]), 1, 1) .+
        Month.(3 .* (quarterofyear.(df.date[2:end]).-1)))...])
    tb = writestat(outfile, df, varformat=Dict(:date=>"%th"))
    @test isequal(tb.date.data, [missing, 0, 0, 0, 0, 0, 0, 1, 1, 2, 2, -1, -1, -1, -2])
end

@testset "writestat string" begin
    outfile = "$(@__DIR__)/../data/test_string.dta"
    types = [String, String3, String7, String15, String31,
        String63, String127, String255]
    cols = [Symbol(:col, i) => T[T("a")] for (i, T) in enumerate(types)]
    df = DataFrame((; cols...))
    df[!,:col0] .= 'a'
    tb = writestat(outfile, df)
    push!(types, String)
    for (i, col) in enumerate(tb)
        @test eltype(col) == types[i]
        @test col[1] == "a"
    end
    allowmissing!(df)
    df[!,:colm] .= missing
    for col in eachcol(df)
        push!(col, missing)
    end
    tb = writestat(outfile, df)
    push!(types, String)
    for (i, col) in enumerate(tb)
        @test eltype(col) == types[i]
        if i < length(tb)
            @test col[1] == "a"
            @test col[2] == ""
        else
            @test col[1] == ""
        end
    end
end

@testset "writestat dta" begin
    alltypes = "$(@__DIR__)/../data/alltypes.dta"
    dtype = readstat(alltypes)
    tb = writestat("$(@__DIR__)/../data/write_alltypes.dta", dtype)
    @test isequal(tb, dtype)
    tb = writestat("$(@__DIR__)/../data/write_alltypes.dta", dtype, copycols=false)
    @test isequal(tb, dtype)
    tb = writestat("$(@__DIR__)/../data/write_alltypes.dta", DataFrame(dtype)[:,1:7],
        copycols=false)
    @test all(i->isequal(getcolumn(tb,i), getcolumn(dtype,i)), 1:6)
    df = DataFrame(dtype)
    tb2 = writestat("$(@__DIR__)/../data/write_df_alltypes.dta", df)
    @test all(i->isequal(getcolumn(tb2,i), getcolumn(dtype,i)), 1:6)
    @test tb2.vstrL isa LabeledArray
    @test refarray(tb2.vstrL) == refarray(dtype.vstrL)
    lbl0 = getvaluelabels(df.vbyte)
    lbl = copy(lbl0)
    lbl[Int32(2)] = "B"
    df[!,:vbyte] = LabeledArray(refarray(df.vbyte), lbl)
    @test_throws ErrorException writestat("$(@__DIR__)/../data/write_df_alltypes.dta", df)
    emptymetadata!(df)
    emptycolmetadata!(df)
    tb3 = writestat("$(@__DIR__)/../data/write_df_alltypes.dta", df)
    @test all(i->isequal(getcolumn(tb2,i), getcolumn(dtype,i)), 1:6)
    @test tb3.vstrL isa LabeledArray
    @test refarray(tb3.vstrL) == refarray(dtype.vstrL)
    @test colmetadata(tb3, :vbyte, :vallabel) == :vbyte
    @test colmetadata(tb3, :vfloat, :vallabel) == :vfloat
    # Change output format
    tb4 = writestat("$(@__DIR__)/../data/write_df_alltypes.xpt", dtype)
    tb5 = writestat("$(@__DIR__)/../data/write_df_alltypes.xpt", df)

    stringtypes = "$(@__DIR__)/../data/stringtypes.dta"
    strtype = readstat(stringtypes)
    tb = writestat("$(@__DIR__)/../data/write_stringtypes.dta", strtype)
    @test isequal(tb, strtype)
    @test Int.(colmetavalues(tb, :storage_width)) ==
        [3, 3, 7, 7, 15, 15, 31, 31, 32, 63, 64, 127, 128, 255, 256]
    df = DataFrame(strtype)
    tb2 = writestat("$(@__DIR__)/../data/write_df_stringtypes.dta", df)
    # PooledArray is treated as LabeledArray
    @test all(colmetavalues(tb2, :type)[1:10].==READSTAT_TYPE_STRING)
    @test all(colmetavalues(tb2, :type)[11:15].==READSTAT_TYPE_INT32)
    @test Int.(colmetavalues(tb2, :storage_width)) ==
        [3, 3, 7, 7, 15, 15, 31, 31, 32, 63, 0, 0, 0, 0, 0]
    @test all(i->isequal(getcolumn(tb2,i), getcolumn(strtype,i)), 1:10)
    emptymetadata!(df)
    emptycolmetadata!(df)
    tb3 = writestat("$(@__DIR__)/../data/write_df_stringtypes.dta", df)
    @test all(i->isequal(getcolumn(tb3,i), getcolumn(strtype,i)), 1:10)
end

extensions = ["dta", "por", "sav", "sas7bdat", "xpt"]

@testset "writestat roundtrip $ext" for ext in extensions
    infile = "$(@__DIR__)/../data/sample.$ext"
    rs_table = readstat(infile)

    df_full = DataFrame(rs_table)

    # Drop the date/time columns for copycols=false
    selected_cols = if ext in ["por", "xpt"]
        [:MYCHAR, :MYNUM, :MYLABL, :MYORD]
    else
        [:mychar, :mynum, :mylabl, :myord]
    end
    df = df_full[!,selected_cols]

    outfile = "$(@__DIR__)/../data/sample_write_test.$ext"
    @test_throws ErrorException writestat(outfile, df_full, copycols=false)
    rs_table_out = writestat(outfile, df, copycols=false)
    @test typeof(rs_table_out) == ReadStatTable{DataFrames.DataFrameColumns{DataFrame}}
    rs_table_out = writestat(outfile, df_full)
    @test typeof(rs_table_out) == ReadStatTable{ReadStatColumns}

    rs_table_read_back = readstat(outfile)

    # check that specific table metadata is the same
    @testset "metadata \"$key\"" for key in ["file_label", "notes"]
        @test metadata(rs_table_out, key) == metadata(df, key)
        @test metadata(rs_table_read_back, key) == metadata(df, key)
    end

    # # check that column metadata in the source dataframe can be found in the read back dataframe
    # # this currently fails because some labels differ
    # for name in names(df)
    #     cm_df = colmetadata(df, name)
    #     cm_rs = colmetadata(rs_table_read_back, name)
    #     for (key, value) in cm_df
    #         @test cm_rs[key] == value
    #     end
    # end

    # check that data round-tripped correctly
    df_read_back = DataFrame(rs_table_read_back)
    @test isequal(df_read_back, df_full) # isequal returns true for missings and NaNs

    # Verify that date/time is processed as expected
    # .por file gives error of illegal character if variable name is not capitalized
    datetime = DataFrame((DATE = Date(1960,1,1).+Day.(rand(-10000:10000, 20)),
        TIME = DateTime(1960,1,1,1,1,1,120) .+ Millisecond.(rand(Int(-1e12):Int(1e12), 20))))
    datetimefile = "$(@__DIR__)/../data/test_write_datetime.$ext"
    tb = writestat(datetimefile, datetime)
    r = readstat(datetimefile)
    @test r.DATE == datetime.DATE
    @test r.TIME == datetime.TIME
end
