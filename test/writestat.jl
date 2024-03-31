@testset "writestat conversion" begin
    @test rstype(Int64) == READSTAT_TYPE_INT32
    @test_throws ErrorException rstype(ComplexF64)

    alltypes = "$(@__DIR__)/../data/alltypes.dta"
    df = DataFrame(readstat(alltypes))
    emptycolmetadata!(df)
    df[!,:vbyte] = CategoricalArray(valuelabels(df.vbyte))
    df[!,:vint] = PooledArray(valuelabels(df.vint))
    tb = ReadStatTable(df, ".dta")
    @test colmetadata(tb, :vbyte, :vallabel) == :vbyte
    lbl = getvaluelabels(tb.vbyte)
    @test typeof(lbl) == Dict{Union{Char, Int32}, String}
    @test lbl[1] == "A"
    # How missing values are handled will be changed in v0.3
    @test lbl[2] == "missing"
    @test colmetadata(tb, :vint, :vallabel) == :vint
    @test getvaluelabels(tb.vint) == lbl
    # Date/Time columns are converted to numbers
    @test eltype(getfield(tb, :columns)[8]) >: Float64
    @test eltype(getfield(tb, :columns)[9]) >: Float64

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

@testset "writestat dta" begin
    alltypes = "$(@__DIR__)/../data/alltypes.dta"
    dtype = readstat(alltypes)
    tb = writestat("$(@__DIR__)/../data/write_alltypes.dta", dtype)
    @test isequal(tb, dtype)
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
end
