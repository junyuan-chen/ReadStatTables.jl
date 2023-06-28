@testset "ReadStat API" begin
    @test error_message(ReadStatTables.READSTAT_OK) == ""
    @test error_message(ReadStatTables.READSTAT_ERROR_OPEN) == "Unable to open file"

    @test_throws ErrorException _error(READSTAT_ERROR_OPEN)
end

@testset "readstat dta" begin
    dta = "$(@__DIR__)/../data/sample.dta"
    d = readstat(dta)
    @test d isa ReadStatTable{ReadStatColumns}
    @test sprint(show, MIME("text/plain"), d, context=:displaysize=>(15,120)) == """
        5×7 ReadStatTable:
         Row │  mychar    mynum      mydate                dtime         mylabl           myord               mytime
             │ String3  Float64       Date?            DateTime?  Labeled{Int8}  Labeled{Int8?}             DateTime
        ─────┼───────────────────────────────────────────────────────────────────────────────────────────────────────
           1 │       a      1.1  2018-05-06  2018-05-06T10:10:10           Male             low  1960-01-01T10:10:10
           2 │       b      1.2  1880-05-06  1880-05-06T10:10:10         Female          medium  1960-01-01T23:10:10
           3 │       c  -1000.3  1960-01-01  1960-01-01T00:00:00           Male            high  1960-01-01T00:00:00
           4 │       d     -1.4  1583-01-01  1583-01-01T00:00:00         Female             low  1960-01-01T16:10:10
           5 │       e   1000.3     missing              missing           Male         missing  2000-01-01T00:00:00"""

    m = metadata(d)
    @test getvaluelabels(d, :mylabl) == d.mylabl.labels
    @test minute(m.modified_time) == 36
    @test sprint(show, m) == "ReadStatMeta(A test file, .dta)"
    # Timestamp displays different values depending on time zone
    @test sprint(show, MIME("text/plain"), m)[1:83] == """
        ReadStatMeta:
          row count           => 5
          var count           => 7
          modified time"""

    ms = colmetadata(d)
    @test length(ms) == 7
    @test sprint(show, MIME("text/plain"), ms)[1:95] == """
        ColMetaIterator{ReadStatColMeta} with 7 entries:
          :mychar => ReadStatColMeta(character, %-1s)
        """

    @test colmetadata(d, :myord, "label") == "ordinal"
    @test colmetadata(d, :mytime, :format) == "%tcHH:MM:SS"
    @test colmetadata(d, :mylabl, "vallabel") == :mylabl

    @test colmetavalues(d, :label) ==
        ["character", "numeric", "date", "datetime", "labeled", "ordinal", "time"]
    @test colmetavalues(d, :format) ==
        ["%-1s", "%16.2f", "%td", "%tc", "%16.0f", "%16.0f", "%tcHH:MM:SS"]
    @test colmetavalues(d, "vallabel") ==
        [Symbol(), Symbol(), Symbol(), Symbol(), :mylabl, :myord, Symbol()]
    @test Int.(colmetavalues(d, :measure)) == zeros(7)
    @test Int.(colmetavalues(d, :alignment)) == [1, 3, 3, 3, 3, 3, 3]

    df = DataFrame(d)
    @test all(n->isequal(df[!, n], getproperty(d, n)), columnnames(d))
    df = DataFrame(d, copycols=false)
    @test all(n->df[!, n] === getproperty(d, n), columnnames(d))

    # Metadata-related methods require DataFrames.jl v1.4 or above
    # which requires Julia v1.6 or above
    if VERSION >= v"1.6"
        @test metadata(df, "file_label") == "A test file"
        @test length(metadatakeys(df)) == fieldcount(ReadStatMeta)
        @test colmetadata(df, :mynum, "label") == "numeric"
        @test length(colmetadatakeys(df, :mylabl)) == fieldcount(ReadStatColMeta)

        metastyle!(d, "file_label", :note)
        metastyle!(d, "label", :note)
        df = DataFrame(d)
        @test metadata(df, "file_label", style=true) == ("A test file", :note)
        @test metadata(df, "modified_time", style=true)[2] == :default
        @test colmetadata(df, :mynum, "label", style=true) == ("numeric", :note)
    end

    df = DataFrame(d)
    df2 = vcat(df, df)
    @test getvaluelabels(df2.mylabl) == getvaluelabels(df.mylabl)
    @test getvaluelabels(df2.mylabl) !== getvaluelabels(df.mylabl)

    d = readstat(dta, apply_value_labels=false)
    @test eltype(d.mylabl) == Union{Missing, Int8}
    d = readstat(dta, apply_value_labels=false, ntasks=2)
    @test eltype(d.mylabl) == Int8

    d = readstat(dta, usecols=Int[])
    @test sprint(show, d) == "0×0 ReadStatTable"
    @test isempty(colmetadata(d))
    @test length(getvaluelabels(d)) == 2

    d = readstat(dta, usecols=1:3, row_offset=10)
    @test size(d) == (0, 3)

    d = readstat(dta, ntasks=3)
    @test d isa ReadStatTable{ChainedReadStatColumns}
    @test length(d.mychar.arrays[1]) == 3

    d = readstat(dta, usecols=Int[], ntasks=3)
    @test d isa ReadStatTable{ChainedReadStatColumns}
    @test sprint(show, d) == "0×0 ReadStatTable"
    @test isempty(colmetadata(d))
    @test length(getvaluelabels(d)) == 2

    df = DataFrame(readstat(dta, ntasks=3))
    @test isequal(df, DataFrame(readstat(dta, ntasks=1)))

    # Each task at least gets one row
    d = readstat(dta, row_offset=3, ntasks=3)
    @test size(d) == (2, 7)
    @test d isa ReadStatTable{ChainedReadStatColumns}
    @test length(d.mychar.arrays) == 2

    d = readstat(dta, usecols=1:3, row_offset=10, ntasks=3)
    @test size(d) == (0, 3)
    @test d isa ReadStatTable{ReadStatColumns}

    d = readstat(dta, usecols=1:3, row_limit=2, row_offset=2, convert_datetime=true)
    showstr = """
        2×3 ReadStatTable:
         Row │  mychar    mynum      mydate
             │ String3  Float64        Date
        ─────┼──────────────────────────────
           1 │       c  -1000.3  1960-01-01
           2 │       d     -1.4  1583-01-01"""
    @test sprint(show, MIME("text/plain"), d, context=:displaysize=>(15,120)) == showstr
    d = readstat(dta, usecols=1:3, row_limit=2, row_offset=2, ntasks=3, convert_datetime=true)
    @test d isa ReadStatTable{ChainedReadStatColumns}
    @test sprint(show, MIME("text/plain"), d, context=:displaysize=>(15,120)) == showstr

    d = readstat(dta, usecols=[:dtime, :mylabl], convert_datetime=false,
        file_encoding="UTF-8", handler_encoding="UTF-8")
    showstr = """
        5×2 ReadStatTable:
         Row │       dtime         mylabl
             │    Float64?  Labeled{Int8}
        ─────┼────────────────────────────
           1 │  1.84122e12           Male
           2 │  -2.5136e12         Female
           3 │         0.0           Male
           4 │ -1.18969e13         Female
           5 │     missing           Male"""
    @test sprint(show, MIME("text/plain"), d, context=:displaysize=>(15,120)) == showstr
    d = readstat(dta, usecols=[:dtime, :mylabl], ntasks=3, convert_datetime=false,
        file_encoding="UTF-8", handler_encoding="UTF-8")
    @test d isa ReadStatTable{ChainedReadStatColumns}
    @test sprint(show, MIME("text/plain"), d, context=:displaysize=>(15,120)) == showstr

    d = readstat(dta, usecols=Set(["dtime", "mylabl"]), row_limit=4)
    showstr = """
        4×2 ReadStatTable:
         Row │               dtime         mylabl
             │            DateTime  Labeled{Int8}
        ─────┼────────────────────────────────────
           1 │ 2018-05-06T10:10:10           Male
           2 │ 1880-05-06T10:10:10         Female
           3 │ 1960-01-01T00:00:00           Male
           4 │ 1583-01-01T00:00:00         Female"""
    @test sprint(show, MIME("text/plain"), d, context=:displaysize=>(15,120)) == showstr
    d = readstat(dta, usecols=Set(["dtime", "mylabl"]), row_limit=4, ntasks=3)
    @test d isa ReadStatTable{ChainedReadStatColumns}
    @test sprint(show, MIME("text/plain"), d, context=:displaysize=>(15,120)) == showstr

    d = readstat(dta, usecols=:myord)
    @test sprint(show, MIME("text/plain"), d, context=:displaysize=>(15,120)) == """
        5×1 ReadStatTable:
         Row │          myord
             │ Labeled{Int8?}
        ─────┼────────────────
           1 │            low
           2 │         medium
           3 │           high
           4 │            low
           5 │        missing"""

    nthd = Threads.nthreads()
    @test _setntasks(100) == min(2, nthd)
    @test _setntasks(20_000) == min(max(nthd÷2, 2), nthd)
    @test _setntasks(4_000_000) == nthd

    alltypes = "$(@__DIR__)/../data/alltypes.dta"
    dtype = readstat(alltypes)
    @test eltype(dtype[1]) == LabeledValue{Union{Missing, Int8}, Union{Int32,Char}}
    @test eltype(dtype[2]) == LabeledValue{Union{Missing, Int16}, Union{Int32,Char}}
    @test eltype(dtype[3]) == LabeledValue{Union{Missing, Int32}, Union{Int32,Char}}
    @test eltype(dtype[4]) == LabeledValue{Union{Missing, Float32}, Union{Int32,Char}}
    @test eltype(dtype[5]) == LabeledValue{Union{Missing, Float64}, Union{Int32,Char}}
    @test eltype(dtype[6]) == String3
    @test eltype(dtype[7]) == String
    @test length(dtype[1,7]) == 114
    vallbls = getvaluelabels(dtype)
    @test length(vallbls) == 1
    lbls = vallbls[:testlbl]
    @test length(lbls) == 2
    @test lbls['a'] == "Tagged missing"
    @test lbls[1] == "A"

    stringtypes = "$(@__DIR__)/../data/stringtypes.dta"
    strtype = readstat(stringtypes)
    @test eltype(strtype.vstr1) == String3
    @test eltype(strtype.vstr3) == String3
    @test eltype(strtype.vstr4) == String7
    @test eltype(strtype.vstr7) == String7
    @test eltype(strtype.vstr8) == String15
    @test eltype(strtype.vstr15) == String15
    @test eltype(strtype.vstr16) == String31
    @test eltype(strtype.vstr31) == String31
    @test eltype(strtype.vstr32) == String
    @test eltype(strtype.vstr63) == String
    @test eltype(strtype.vstr64) == String
    @test strtype.vstr64 isa PooledArray

    strtype = readstat(stringtypes, inlinestring_width=512, pool_width=256)
    @test eltype(strtype.vstr64) == String127
    @test eltype(strtype.vstr127) == String127
    @test eltype(strtype.vstr128) == String255
    @test eltype(strtype.vstr255) == String255
    @test eltype(strtype.vstr256) == String
    @test strtype.vstr255 isa Array
    @test strtype.vstr256 isa PooledArray

    strtype = readstat(stringtypes, inlinestring_width=0)
    @test all(x->eltype(x)==String, strtype)
    @test strtype.vstr63 isa Array
    strtype = readstat(stringtypes, pool_width=32)
    @test strtype.vstr32 isa PooledArray
    strtype = readstat(stringtypes, pool_thres=1)
    @test strtype.vstr64 isa Array
    strtype = readstat(stringtypes, pool_thres=0)
    @test strtype.vstr64 isa Array

    strtype = readstat(stringtypes, ntasks=3)
    @test strtype.vstr64 isa PooledArray
    strtype = readstat(stringtypes, ntasks=3, pool_width=256)
    @test strtype.vstr255 isa ChainedVector{String, Vector{String}}
    @test strtype.vstr256 isa PooledArray
    strtype = readstat(stringtypes, ntasks=3, pool_thres=0)
    @test strtype.vstr64 isa ChainedVector{String, Vector{String}}

    @test_throws ArgumentError readstat("$(@__DIR__)/../data/README.md")
    @test_throws ErrorException readstat(dta, ext=".xpt")
    @test_throws ArgumentError readstat(dta, row_limit=0)
    @test_throws ArgumentError readstat(dta, row_limit=-1)
    @test_throws ArgumentError readstat(dta, row_offset=-1)
    @test_throws ArgumentError readstat(dta, pool_thres=typemax(UInt16)+1)

    m = readstatmeta(dta)
    @test m.row_count == 5
    @test m.var_count == 7
    @test m.file_format_version == 118
    @test m.file_label == "A test file"
    @test m.file_ext == ".dta"

    d = readstat(dta)
    m1, names, cm, vlbls = readstatallmeta(dta)
    @test m1 == m
    @test names == columnnames(d)
    @test cm == getfield(d, :colmeta)
    @test vlbls == getvaluelabels(d)

    d = readstat(dta, usecols=[:dtime, :mylabl])
    m1, names, cm, vlbls = readstatallmeta(dta, usecols=[:dtime, :mylabl])
    @test m1 == m
    @test names == columnnames(d)
    @test cm == getfield(d, :colmeta)
    @test vlbls == getvaluelabels(d)
end

@testset "readstat sav" begin
    sav = "$(@__DIR__)/../data/sample.sav"
    d = readstat(sav)
    @test sprint(show, MIME("text/plain"), d, context=:displaysize=>(15,150)) == """
        5×7 ReadStatTable:
         Row │ mychar    mynum               mydate                dtime            mylabl             myord               mytime
             │ String  Float64            DateTime?            DateTime?  Labeled{Float64}  Labeled{Float64}            DateTime?
        ─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
           1 │      a      1.1  2018-05-06T00:00:00  2018-05-06T10:10:10              Male               low  1582-10-14T10:10:10
           2 │      b      1.2  1880-05-06T00:00:00  1880-05-06T10:10:10            Female            medium  1582-10-14T23:10:10
           3 │      c  -1000.3  1960-01-01T00:00:00  1960-01-01T00:00:00              Male              high  1582-10-14T00:00:00
           4 │      d     -1.4  1583-01-01T00:00:00  1583-01-01T00:00:00            Female               low  1582-10-14T16:10:10
           5 │      e   1000.3              missing              missing              Male               low              missing"""

    d = readstat(sav, ntasks=3)
    @test d isa ReadStatTable{ChainedReadStatColumns}

    m = metadata(d)
    @test sprint(show, MIME("text/plain"), m)[1:83] == """
        ReadStatMeta:
          row count           => 5
          var count           => 7
          modified time"""

    @test colmetavalues(d, :label) ==
        ["character", "numeric", "date", "datetime", "labeled", "ordinal", "time"]
    @test colmetavalues(d, :format) ==
        ["A1", "F8.2", "EDATE10", "DATETIME20", "F8.2", "F8.2", "TIME8"]
    @test colmetavalues(d, :vallabel) ==
        [Symbol(), Symbol(), Symbol(), Symbol(), :labels0, :labels1, Symbol()]
    @test Int.(colmetavalues(d, :measure)) == [1, 3, 3, 3, 3, 2, 3]
    @test Int.(colmetavalues(d, :alignment)) == [0, 0, 0, 0, 0, 0, 0]

    m = readstatmeta(sav)
    @test m.row_count == 5
    @test m.var_count == 7
    @test m.file_format_version == 2
    @test m.notes == ["some test text as notes", "   (Entered 15-Aug-2018)",
        "some other comments", "   (Entered 15-Aug-2018)"]
    @test m.file_ext == ".sav"
end

@testset "readstat por" begin
    por = "$(@__DIR__)/../data/sample.por"
    d = readstat(por)
    @test sprint(show, MIME("text/plain"), d, context=:displaysize=>(15,150)) == """
        5×7 ReadStatTable:
         Row │ MYCHAR    MYNUM               MYDATE                DTIME            MYLABL             MYORD               MYTIME
             │ String  Float64            DateTime?            DateTime?  Labeled{Float64}  Labeled{Float64}            DateTime?
        ─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
           1 │      a      1.1  2018-05-06T00:00:00  2018-05-06T10:10:10              Male               low  1582-10-14T10:10:10
           2 │      b      1.2  1880-05-06T00:00:00  1880-05-06T10:10:10            Female            medium  1582-10-14T23:10:10
           3 │      c  -1000.3  1960-01-01T00:00:00  1960-01-01T00:00:00              Male              high  1582-10-14T00:00:00
           4 │      d     -1.4  1583-01-01T00:00:00  1583-01-01T00:00:00            Female               low  1582-10-14T16:10:10
           5 │      e   1000.3              missing              missing              Male               low              missing"""

    d = readstat(por, ntasks=3)
    @test d isa ReadStatTable{ReadStatColumns}

    m = metadata(d)
    @test sprint(show, MIME("text/plain"), m)[1:84] == """
        ReadStatMeta:
          row count           => -1
          var count           => 7
          modified time"""

    @test colmetavalues(d, :label) ==
        ["character", "numeric", "date", "datetime", "labeled", "ordinal", "time"]
    @test colmetavalues(d, :format) ==
        ["A1", "F8.2", "EDATE10", "DATETIME20", "F8.2", "F8.2", "TIME8"]
    @test colmetavalues(d, :vallabel) ==
        [Symbol(), Symbol(), Symbol(), Symbol(), :labels0, :labels1, Symbol()]
    @test Int.(colmetavalues(d, :measure)) == zeros(7)
    @test Int.(colmetavalues(d, :alignment)) == zeros(7)

    m = readstatmeta(por)
    @test m.row_count == -1
    @test m.var_count == 7
    @test m.file_format_version == 0
    @test m.notes == ["some test text as notes", "   (Entered 15-Aug-2018)",
        "some other comments", "   (Entered 15-Aug-2018)"]
    @test m.file_ext == ".por"
end

@testset "readstat sas7bdat" begin
    sas7 = "$(@__DIR__)/../data/sample.sas7bdat"
    d = readstat(sas7)
    @test sprint(show, MIME("text/plain"), d, context=:displaysize=>(15,150)) == """
        5×7 ReadStatTable:
         Row │  mychar    mynum      mydate                dtime   mylabl    myord               mytime
             │ String3  Float64       Date?            DateTime?  Float64  Float64            DateTime?
        ─────┼──────────────────────────────────────────────────────────────────────────────────────────
           1 │       a      1.1  2018-05-06  2018-05-06T10:10:10      1.0      1.0  1960-01-01T10:10:10
           2 │       b      1.2  1880-05-06  1880-05-06T10:10:10      2.0      2.0  1960-01-01T23:10:10
           3 │       c  -1000.3  1960-01-01  1960-01-01T00:00:00      1.0      3.0  1960-01-01T00:00:00
           4 │       d     -1.4  1583-01-01  1583-01-01T00:00:00      2.0      1.0  1960-01-01T16:10:10
           5 │       e   1000.3     missing              missing      1.0      1.0              missing"""

    d = readstat(sas7, ntasks=3)
    @test d isa ReadStatTable{ChainedReadStatColumns}

    m = metadata(d)
    @test sprint(show, MIME("text/plain"), m)[1:83] == """
        ReadStatMeta:
          row count           => 5
          var count           => 7
          modified time"""

    # Labels are not handled for SAS at this moment
    # ReadStat_jll.jl v1.1.8 requires Julia v1.6 or above
    # Older versions of ReadStat_jll.jl have different results for formats
    if VERSION >= v"1.6"
        @test colmetavalues(d, :format) ==
            ["\$1", "BEST12", "YYMMDD10", "DATETIME", "BEST12", "BEST12", "TIME20"]
    else
        @test colmetavalues(d, :format) ==
            ["\$", "BEST", "YYMMDD", "DATETIME", "BEST", "BEST", "TIME"]
    end
    @test Int.(colmetavalues(d, :measure)) == zeros(7)
    @test Int.(colmetavalues(d, :alignment)) == zeros(7)

    m = readstatmeta(sas7)
    @test m.row_count == 5
    @test m.var_count == 7
    @test m.file_format_version == 9
    @test m.table_name == "SAMPLE"
    @test m.file_ext == ".sas7bdat"
end

@testset "readstat xpt" begin
    xpt = "$(@__DIR__)/../data/sample.xpt"
    d = readstat(xpt)
    @test sprint(show, MIME("text/plain"), d, context=:displaysize=>(15,150)) == """
        5×7 ReadStatTable:
         Row │  MYCHAR    MYNUM      MYDATE                DTIME   MYLABL    MYORD               MYTIME
             │ String3  Float64       Date?            DateTime?  Float64  Float64            DateTime?
        ─────┼──────────────────────────────────────────────────────────────────────────────────────────
           1 │       a      1.1  2018-05-06  2018-05-06T10:10:10      1.0      1.0  1960-01-01T10:10:10
           2 │       b      1.2  1880-05-06  1880-05-06T10:10:10      2.0      2.0  1960-01-01T23:10:10
           3 │       c  -1000.3  1960-01-01  1960-01-01T00:00:00      1.0      3.0  1960-01-01T00:00:00
           4 │       d     -1.4  1583-01-01  1583-01-01T00:00:00      2.0      1.0  1960-01-01T16:10:10
           5 │       e   1000.3     missing              missing      1.0      1.0              missing"""

    d = readstat(xpt, ntasks=3)
    @test d isa ReadStatTable{ReadStatColumns}

    m = metadata(d)
    @test m.table_name == "SAMPLE"
    @test sprint(show, MIME("text/plain"), m)[1:84] == """
        ReadStatMeta:
          row count           => -1
          var count           => 7
          modified time"""
    @test sprint(show, MIME("text/plain"), m)[144:172] ==
        "table name          => SAMPLE"

    @test colmetavalues(d, :format) ==
        ["\$1", "BEST12", "YYMMDD10", "DATETIME", "BEST12", "BEST12", "TIME20.3"]
    @test Int.(colmetavalues(d, :measure)) == zeros(7)
    @test Int.(colmetavalues(d, :alignment)) == ones(7)

    m = readstatmeta(xpt)
    @test m.row_count == -1
    @test m.var_count == 7
    @test m.file_format_version == 5
    @test m.table_name == "SAMPLE"
    @test m.file_ext == ".xpt"
end
