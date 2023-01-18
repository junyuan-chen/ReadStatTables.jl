@testset "writestat conversion" begin
    @test rstype(Int64) == READSTAT_TYPE_INT32
    @test_throws ErrorException rstype(ComplexF64)
end

@testset "writestat dta" begin
    alltypes = "$(@__DIR__)/../data/alltypes.dta"
    dtype = readstat(alltypes)
    tb = writestat("$(@__DIR__)/../data/write_alltypes.dta", dtype)
    @test isequal(tb, dtype)
    df = DataFrame(dtype)
    tb2 = writestat("$(@__DIR__)/../data/write_df_alltypes.dta", df)
    @test all(i->isequal(getcolumn(tb2,i), getcolumn(dtype,i)), 1:ncol(tb2))
    lbl = copy(getvaluelabels(df.vbyte))
    lbl[Int32(2)] = "B"
    df[!,:vbyte] = LabeledArray(refarray(df.vbyte), lbl)
    @test_throws ErrorException writestat("$(@__DIR__)/../data/write_df_alltypes.dta", df)
    emptymetadata!(df)
    emptycolmetadata!(df)
    tb3 = writestat("$(@__DIR__)/../data/write_df_alltypes.dta", df)
    @test all(i->isequal(getcolumn(tb3,i), getcolumn(dtype,i)), 1:ncol(tb3))
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
    @test Int.(colmetavalues(tb2, :storage_width)) ==
        [3, 3, 7, 7, 15, 15, 31, 31, 32, 63, 64, 127, 128, 255, 256]
    @test all(i->isequal(getcolumn(tb2,i), getcolumn(strtype,i)), 1:ncol(tb2))
    emptymetadata!(df)
    emptycolmetadata!(df)
    tb3 = writestat("$(@__DIR__)/../data/write_df_stringtypes.dta", df)
    @test all(i->isequal(getcolumn(tb3,i), getcolumn(strtype,i)), 1:ncol(tb3))
end

extensions = ["dta", "por", "sav", "sas7bdat", "xpt"]

@testset "writestat roundtrip $ext" for ext in extensions
    infile = "$(@__DIR__)/../data/sample.$ext"
    rs_table = readstat(infile)

    df_full = DataFrame(rs_table)

    # Drop the date/time columns as the conversion is not implemented yet
    selected_cols = if ext in ["por", "xpt"]
        [:MYCHAR, :MYNUM, :MYLABL, :MYORD]
    else
        [:mychar, :mynum, :mylabl, :myord]
    end
    df = df_full[!,selected_cols]

    outfile = "$(@__DIR__)/../data/sample_write_test.$ext"
    rs_table_out = writestat(outfile, df)
    @test typeof(rs_table_out) == ReadStatTable{DataFrames.DataFrameColumns{DataFrame}}
    
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
    @test isequal(df_read_back, df) # isequal returns true for missings and NaNs
end
