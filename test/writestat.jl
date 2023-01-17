@testset "writestat dta" begin
    alltypes = "$(@__DIR__)/../data/alltypes.dta"
    dtype = readstat(alltypes)
    tb = writestat("$(@__DIR__)/../data/write_alltypes.dta", dtype)
    @test isequal(tb, dtype)
    df = DataFrame(dtype)
    tb2 = writestat("$(@__DIR__)/../data/write_df_alltypes.dta", dtype)
    @test isequal(tb2, dtype)

    stringtypes = "$(@__DIR__)/../data/stringtypes.dta"
    strtype = readstat(stringtypes)
    tb = writestat("$(@__DIR__)/../data/write_stringtypes.dta", strtype)
    @test isequal(tb, strtype)
    @test Int.(colmetavalues(tb, :storage_width)) ==
        [3, 3, 7, 7, 15, 15, 31, 31, 32, 63, 64, 127, 128, 255, 256]
    df = DataFrame(strtype)
    tb2 = writestat("$(@__DIR__)/../data/write_df_stringtypes.dta", strtype)
    @test Int.(colmetavalues(tb2, :storage_width)) ==
        [3, 3, 7, 7, 15, 15, 31, 31, 32, 63, 64, 127, 128, 255, 256]
    @test isequal(tb2, strtype)
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
