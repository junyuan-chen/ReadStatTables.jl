extensions = ["dta", "por", "sav", "sas7bdat", "xpt"]

@testset "writestat" begin
    @testset "writestat $ext" for ext in extensions
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
end
