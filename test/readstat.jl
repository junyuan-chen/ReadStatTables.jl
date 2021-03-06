@testset "_parse_usecols" begin
    dta = "$(@__DIR__)/../data/sample.dta"
    f = read_dta(dta)
    @test _parse_usecols(f, :dtime) == _parse_usecols(f, "dtime") == (4,)
    @test_throws ArgumentError _parse_usecols(f, :time)
    @test _parse_usecols(f, [:dtime]) == _parse_usecols(f, ["dtime"]) == [4]
    @test_throws ArgumentError _parse_usecols(f, [:time])
    @test _parse_usecols(f, 1) == (1,)
    @test_throws ArgumentError _parse_usecols(f, 8)
    @test _parse_usecols(f, [1, 2]) == 1:2
    @test_throws ArgumentError _parse_usecols(f, 1:8)
end

@testset "readstat dta" begin
    dta = "$(@__DIR__)/../data/sample.dta"
    d = readstat(dta)
    @test sprint(show, MIME("text/plain"), d, context=:displaysize=>(15,120)) == """
        5×7 ReadStatTable:
         Row │ mychar    mynum      mydate                dtime         mylabl           myord               mytime
             │ String  Float64       Date?            DateTime?  Labeled{Int8}  Labeled{Int8?}             DateTime
        ─────┼──────────────────────────────────────────────────────────────────────────────────────────────────────
           1 │      a      1.1  2018-05-06  2018-05-06T10:10:10           Male             low  1960-01-01T10:10:10
           2 │      b      1.2  1880-05-06  1880-05-06T10:10:10         Female          medium  1960-01-01T23:10:10
           3 │      c  -1000.3  1960-01-01  1960-01-01T00:00:00           Male            high  1960-01-01T00:00:00
           4 │      d     -1.4  1583-01-01  1583-01-01T00:00:00         Female             low  1960-01-01T16:10:10
           5 │      e   1000.3     missing              missing           Male         missing  2000-01-01T00:00:00"""

    @test length(varlabels(d)) == 7
    @test varlabels(d)[:myord] == "ordinal"
    @test length(varformats(d)) == 7
    @test varformats(d)[:mytime] == "%tcHH:MM:SS"
    @test val_label_keys(d)[:mylabl] == "mylabl"
    @test val_label_dict(d)["mylabl"] == d.mylabl.labels
    @test filelabel(d) == "A test file"
    ts = filetimestamp(d)
    @test minute(ts) == 36
    @test fileext(d) == ".dta"

    @test sprint(show, getmeta(d)) == "ReadStatMeta"
    ss = sprint(show, MIME("text/plain"), getmeta(d))
    @test first(ss, 40) == "ReadStatMeta:\n  variable labels:    Dict"
    @test last(ss, 27) == "\n  file extension:     .dta"

    df = DataFrame(d)
    @test all(n->isequal(df[!, n], getproperty(d, n)), columnnames(d))
    df = DataFrame(d, copycols=false)
    @test all(n->df[!, n] === getproperty(d, n), columnnames(d))

    d = readstat(dta, usecols=Int[])
    @test sprint(show, d) == "0×0 ReadStatTable"
    @test isempty(varlabels(d))
    @test length(val_label_dict(d)) == 2

    d = readstat(dta, usecols=1:3, convert_datetime=3)
    @test sprint(show, MIME("text/plain"), d, context=:displaysize=>(15,120)) == """
        5×3 ReadStatTable:
         Row │ mychar    mynum      mydate
             │ String  Float64       Date?
        ─────┼─────────────────────────────
           1 │      a      1.1  2018-05-06
           2 │      b      1.2  1880-05-06
           3 │      c  -1000.3  1960-01-01
           4 │      d     -1.4  1583-01-01
           5 │      e   1000.3     missing"""

    d = readstat(dta, usecols=[:dtime, :mylabl], convert_datetime=false, apply_value_labels=10:20)
    @test sprint(show, MIME("text/plain"), d, context=:displaysize=>(15,120)) == """
        5×2 ReadStatTable:
         Row │       dtime  mylabl
             │    Float64?    Int8
        ─────┼─────────────────────
           1 │  1.84122e12       1
           2 │  -2.5136e12       2
           3 │         0.0       1
           4 │ -1.18969e13       2
           5 │     missing       1"""

    d = readstat(dta, usecols=["dtime", "mylabl"], convert_datetime=:dtime, apply_value_labels=["mylabl"])
    @test sprint(show, MIME("text/plain"), d, context=:displaysize=>(15,120)) == """
            5×2 ReadStatTable:
             Row │               dtime         mylabl
                 │           DateTime?  Labeled{Int8}
            ─────┼────────────────────────────────────
               1 │ 2018-05-06T10:10:10           Male
               2 │ 1880-05-06T10:10:10         Female
               3 │ 1960-01-01T00:00:00           Male
               4 │ 1583-01-01T00:00:00         Female
               5 │             missing           Male"""

    d = readstat(dta, usecols=:myord, missingvalue=0)
    @test d.myord.values[5] == 0
    @test sprint(show, MIME("text/plain"), d, context=:displaysize=>(15,120)) == """
        5×1 ReadStatTable:
         Row │          myord
             │ Labeled{Int64}
        ─────┼────────────────
           1 │            low
           2 │         medium
           3 │           high
           4 │            low
           5 │              0"""
    
    @test_throws ArgumentError readstat("$(@__DIR__)/../data/README.md")
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
end

@testset "readstat sas7bdat" begin
    sas7 = "$(@__DIR__)/../data/sample.sas7bdat"
    d = readstat(sas7)
    @test sprint(show, MIME("text/plain"), d, context=:displaysize=>(15,150)) == """
        5×7 ReadStatTable:
         Row │ mychar    mynum      mydate                dtime   mylabl    myord               mytime
             │ String  Float64       Date?            DateTime?  Float64  Float64            DateTime?
        ─────┼─────────────────────────────────────────────────────────────────────────────────────────
           1 │      a      1.1  2018-05-06  2018-05-06T10:10:10      1.0      1.0  1960-01-01T10:10:10
           2 │      b      1.2  1880-05-06  1880-05-06T10:10:10      2.0      2.0  1960-01-01T23:10:10
           3 │      c  -1000.3  1960-01-01  1960-01-01T00:00:00      1.0      3.0  1960-01-01T00:00:00
           4 │      d     -1.4  1583-01-01  1583-01-01T00:00:00      2.0      1.0  1960-01-01T16:10:10
           5 │      e   1000.3     missing              missing      1.0      1.0              missing"""
end

@testset "readstat xpt" begin
    xpt = "$(@__DIR__)/../data/sample.xpt"
    d = readstat(xpt)
    @test sprint(show, MIME("text/plain"), d, context=:displaysize=>(15,150)) == """
        5×7 ReadStatTable:
         Row │ MYCHAR    MYNUM      MYDATE                DTIME   MYLABL    MYORD               MYTIME
             │ String  Float64       Date?            DateTime?  Float64  Float64            DateTime?
        ─────┼─────────────────────────────────────────────────────────────────────────────────────────
           1 │      a      1.1  2018-05-06  2018-05-06T10:10:10      1.0      1.0  1960-01-01T10:10:10
           2 │      b      1.2  1880-05-06  1880-05-06T10:10:10      2.0      2.0  1960-01-01T23:10:10
           3 │      c  -1000.3  1960-01-01  1960-01-01T00:00:00      1.0      3.0  1960-01-01T00:00:00
           4 │      d     -1.4  1583-01-01  1583-01-01T00:00:00      2.0      1.0  1960-01-01T16:10:10
           5 │      e   1000.3     missing              missing      1.0      1.0              missing"""
end
