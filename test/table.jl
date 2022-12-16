gettestmeta() = ReadStatMeta(3, 4, Date(0), Date(1), 118, true, READSTAT_COMPRESS_NONE,
    READSTAT_ENDIAN_NONE, "name", "flabel", "U", ["n1"], ".dta")

gettestcolmeta() = ReadStatColMeta("varlabel", "%tf", READSTAT_TYPE_INT8, :A, Csize_t(1),
    Cint(1), READSTAT_MEASURE_UNKNOWN, READSTAT_ALIGNMENT_UNKNOWN)

@testset "ReadStatMeta" begin
    m = gettestmeta()
    @test keytype(m) == String
    @test valtype(m) == Any
    @test m["file_label"] == "flabel"
    m["file_label"] = "filelab"
    @test m.file_label == "filelab"
    m = gettestmeta()
    @test iterate(m) == ("row_count" => 3, 2)
    @test iterate(m, 14) === nothing
    @test collect(keys(m)) == [string(n) for n in fieldnames(ReadStatMeta)]
    @test length(m) == length(fieldnames(ReadStatMeta))
    @test haskey(m, "file_label")
    @test get(m, "lab", "default") == "default"
    @test get(Vector, m, "file_label") == "flabel"
    @test copy(m) isa Dict{String, Any}
    @test sprint(show, m) == "ReadStatMeta(flabel, .dta)"
    m1 = ReadStatMeta(3, 4, Date(0), Date(1), 118, true,
        READSTAT_COMPRESS_NONE, READSTAT_ENDIAN_NONE, "name", "", "U", ["n1"], ".dta")
    @test sprint(show, m1) == "ReadStatMeta(.dta)"
    @test sprint(show, MIME("text/plain"), m) == """
        ReadStatMeta:
          row count           => 3
          var count           => 4
          modified time       => 0001-01-01T00:00:00
          file format version => 118
          table name          => name
          file label          => flabel
          notes               => ["n1"]
          file extension      => .dta"""
end

@testset "ReadStatColMeta" begin
    m = gettestcolmeta()
    @test keytype(m) == String
    @test valtype(m) == Any
    @test m["label"] == "varlabel"
    @test iterate(m) == ("label"=>"varlabel", 2)
    @test iterate(m, 9) === nothing
    @test collect(keys(m)) == [string(n) for n in fieldnames(ReadStatColMeta)]
    @test length(m) == length(fieldnames(ReadStatColMeta))
    @test haskey(m, "label")
    @test get(m, "lab", "default") == "default"
    @test get(Vector, m, "label") == "varlabel"
    @test copy(m) isa Dict{String, Any}
    @test sprint(show, m) == "ReadStatColMeta(varlabel, %tf)"
    m1 = ReadStatColMeta("", "%tf", READSTAT_TYPE_INT8, :A, Csize_t(1),
        Cint(1), READSTAT_MEASURE_UNKNOWN, READSTAT_ALIGNMENT_UNKNOWN)
    @test sprint(show, m1) == "ReadStatColMeta(%tf)"
    @test sprint(show, MIME("text/plain"), m) == """
        ReadStatColMeta:
          label         => varlabel
          format        => %tf
          type          => READSTAT_TYPE_INT8
          value label   => A
          storage width => 1
          display width => 1
          measure       => READSTAT_MEASURE_UNKNOWN
          alignment     => READSTAT_ALIGNMENT_UNKNOWN"""
end

@testset "ReadStatTable" begin
    tb = ReadStatTable()
    @test size(tb) == (0, 0)
    @test length(tb) == 0
    @test isempty(tb)
    @test sprint(show, MIME("text/plain"), tb) == "0×0 ReadStatTable"

    m = gettestmeta()
    ms = StructVector(ReadStatColMeta[])
    lbls = Dict{Any,String}()
    vls = Dict{Symbol, Dict}(:A=>lbls)
    hms = Bool[false]
    @test_throws ArgumentError ReadStatTable(ReadStatColumns(), Symbol[:c], vls, hms, m, ms)
    @test_throws ArgumentError ReadStatTable(ReadStatColumns(), Symbol[], vls, [true], m, ms)
    ms = StructVector([gettestcolmeta()])
    cols = ReadStatColumns()
    push!(cols, Int8Column())
    tb = ReadStatTable(cols, Symbol[:c], vls, hms, m, ms)
    @test size(tb) == (0, 1)
    @test length(tb) == 1
    @test isempty(tb)
    @test getvaluelabels(tb) === vls
    @test getvaluelabels(tb, :A) === lbls
    delete!(vls, :A)
    @test sprint(show, MIME("text/plain"), tb) == "0×1 ReadStatTable"

    c1 = Union{Int8,Missing}[1:10...]
    c2 = SentinelArray(collect(10.0:-1.0:1.0), 10.0, missing)
    cols = ReadStatColumns()
    push!(cols, c1, c2)
    names = [:c1, :c2]
    hms = Bool[false, true]
    ms = StructVector{ReadStatColMeta}((["v1","v2"], ["%tf","%tc"],
        [READSTAT_TYPE_INT8, READSTAT_TYPE_DOUBLE], [:A,Symbol()], [Csize_t(1),Csize_t(1)],
        [Cint(1),Cint(1)], [READSTAT_MEASURE_UNKNOWN,READSTAT_MEASURE_UNKNOWN],
        [READSTAT_ALIGNMENT_UNKNOWN,READSTAT_ALIGNMENT_UNKNOWN]))
    @test_throws ArgumentError ReadStatTable(cols, [:c1, :c1], vls, hms, m, ms)
    tb = ReadStatTable(cols, names, vls, hms, m, ms)
    @test size(tb) == (10, 2)
    @test size(tb, 1) == 10
    @test_throws ArgumentError size(tb, 3)
    @test length(tb) == 2
    @test !isempty(tb)

    @test Tables.getcolumn(tb, 1) === c1
    @test Tables.getcolumn(tb, :c2) === c2
    @test columnnames(tb) == names
    @test columnnames(tb) !== names

    @test tb["c1"] === c1
    tb[2,"c2"] = missing
    @test all(ismissing.(tb[[1,2],"c2"]))
    tb[2,"c2"] = 9

    @test Tables.schema(tb) ==
        Tables.Schema{(:c1, :c2), Tuple{Int8, Union{Float64,Missing}}}()
    @test Tables.columnindex(tb, 1) == 1
    @test Tables.columnindex(tb, :c1) == 1
    @test Tables.columnindex(tb, "c1") == 1
    @test Tables.columntype(tb, :c1) == Int8
    @test Tables.columntype(tb, :n) == Union{}
    @test Tables.rowcount(tb) == 10

    @test values(tb) === cols
    @test haskey(tb, :c1)
    @test haskey(tb, 2)
    
    @test sprint(show, tb) == "10×2 ReadStatTable"
    @test sprint(show, MIME("text/plain"), tb, context=:displaysize=>(15,80)) == """
        10×2 ReadStatTable:
         Row │   c1        c2
             │ Int8  Float64?
        ─────┼────────────────
           1 │    1   missing
           2 │    2       9.0
           3 │    3       8.0
          ⋮  │  ⋮       ⋮
           8 │    8       3.0
           9 │    9       2.0
          10 │   10       1.0
                4 rows omitted"""

    columns = gettestcolumns(10)
    cols = ReadStatColumns()
    push!(cols, columns...)
    N = 16
    names = [Symbol("n",i) for i in 1:N]
    hms = fill(false, N)
    ms = StructVector{ReadStatColMeta}((["v$i" for i in 1:N], fill("%tf", N),
        fill(READSTAT_TYPE_DOUBLE, N), fill(Symbol(), N), fill(Csize_t(1), N),
        fill(Cint(1), N), fill(READSTAT_MEASURE_UNKNOWN, N),
        fill(READSTAT_ALIGNMENT_UNKNOWN, N)))
    tb = ReadStatTable(cols, names, vls, hms, m, ms)
    for i in 1:N
        if 1 < i < 9
            @test ismissing(tb[i,i])
        end
        if i < 3 || i > 9
            @test tb[i] === columns[i]
        elseif i == 9
            @test tb[i] === columns[i][1]
        else
            @test tb[i] === parent(columns[i])
        end
    end
    hms = fill(true, N)
    tb = ReadStatTable(cols, names, vls, hms, m, ms)
    for i in 1:N
        if i == 9
            @test tb[i] === columns[i][1]
        else
            @test tb[i] === columns[i]
        end
    end

    columns, cols = gettestchainedcolumns(5)
    N = 21
    names = [Symbol("n",i) for i in 1:N]
    hms = fill(true, N)
    ms = StructVector{ReadStatColMeta}((["v$i" for i in 1:N], fill("%tf", N),
        fill(READSTAT_TYPE_DOUBLE, N), fill(Symbol(), N), fill(Csize_t(1), N),
        fill(Cint(1), N), fill(READSTAT_MEASURE_UNKNOWN, N),
        fill(READSTAT_ALIGNMENT_UNKNOWN, N)))
    tb = ReadStatTable(cols, names, vls, hms, m, ms)
    for i in 1:N
        if i in 2:2:10 || 11 < i < 14
            @test ismissing(tb[1,i])
        end
        @test tb[i] === columns[i]
    end
    sch = Tables.schema(tb)
    @test typeof(sch).parameters[2] == Tuple{String, Union{Int8, Missing}, Int8,
        Union{Int16, Missing}, Int16, Union{Int32, Missing}, Int32,
        Union{Float32, Missing}, Float32, Union{Float64, Missing}, Float64,
        Union{Date, Missing}, Union{DateTime, Missing},
        String, String3, String7, String15, String31, String63, String127, String255}
end

@testset "metadata colmetadata" begin
    @test DataAPI.metadatasupport(ReadStatTable) == (read=true, write=true)
    @test DataAPI.colmetadatasupport(ReadStatTable) == (read=true, write=true)

    c1 = Union{Int8,Missing}[1:10...]
    c2 = SentinelArray(collect(10.0:-1.0:1.0), 10.0, missing)
    cols = ReadStatColumns()
    push!(cols, c1, c2)
    names = [:c1, :c2]
    hms = Bool[false, true]
    vls = Dict{Symbol, Dict}()
    m = gettestmeta()
    ms = StructVector{ReadStatColMeta}((["v1","v2"], ["%tf","%tc"],
        [READSTAT_TYPE_INT8, READSTAT_TYPE_DOUBLE], [:A,Symbol()], [Csize_t(1),Csize_t(1)],
        [Cint(1),Cint(1)], [READSTAT_MEASURE_UNKNOWN,READSTAT_MEASURE_UNKNOWN],
        [READSTAT_ALIGNMENT_UNKNOWN,READSTAT_ALIGNMENT_UNKNOWN]))
    tb = ReadStatTable(cols, names, vls, hms, m, ms)

    @test isempty(metastyle(tb))
    @test metastyle(tb, :file_label) == :default
    @test metastyle(tb, "file_label") == :default

    @test metadata(tb, "file_label") == "flabel"
    @test metadata(tb, :file_label) == "flabel"
    @test metadata(tb, "file_label", style=true) == ("flabel", :default)

    metastyle!(tb, "file_label", :note)
    @test metastyle(tb, :file_label) == :note
    @test metadata(tb, "file_label", style=true) == ("flabel", :note)

    @test metadata(tb) === m
    v = metadata(tb, style=true)
    @test v isa AbstractDict
    @test v["file_label"] == ("flabel", :note)
    @test length(v) == length(m)
    @test copy(v) isa Dict{String, Any}

    @test metadatakeys(tb) == map(x->String(x), fieldnames(ReadStatMeta))

    metadata!(tb, "file_label", "filelab")
    @test m.file_label == "filelab"
    @test metastyle(tb, :file_label) == :note
    metadata!(tb, "file_label", "flabel", style=:default)
    @test m.file_label == "flabel"
    @test metastyle(tb, :file_label) == :default

    @test colmetadata(tb, :c1, "label") == "v1"
    @test colmetadata(tb, :c1, "label", style=true) == ("v1", :default)
    @test colmetadata(tb, :c1) == ms[1]

    metastyle!(tb, "label", :note)
    @test metastyle(tb, :label) == :note
    @test colmetadata(tb, :c1, "label", style=true) == ("v1", :note)

    v = colmetadata(tb, :c1, style=true)
    @test v isa AbstractDict
    @test v["label"] == ("v1", :note)
    @test length(v) == length(ms[1])

    d = colmetadata(tb)
    @test d isa AbstractDict
    @test keytype(d) == Symbol
    @test valtype(d) == ReadStatColMeta
    @test d[:c1] == colmetadata(tb, :c1)
    @test length(d) == 2
    @test haskey(d, :c1)
    @test copy(d) isa Dict{Symbol, ReadStatColMeta}

    d = colmetadata(tb, style=true)
    @test d isa AbstractDict
    @test keytype(d) == Symbol
    @test valtype(d) == MetaStyleView
    @test d[:c1] == colmetadata(tb, :c1, style=true)
    @test length(d) == 2
    @test haskey(d, :c1)
    @test copy(d) isa Dict{Symbol, MetaStyleView}

    @test colmetadatakeys(tb, :c1) == map(x->String(x), fieldnames(ReadStatColMeta))
    ps = colmetadatakeys(tb)
    @test iterate(ps) == (:c1 => colmetadatakeys(tb, :c1), 2)

    colmetadata!(tb, :c1, "label", "lab")
    @test ms.label[1] == "lab"
    @test metastyle(tb, :label) == :note
    colmetadata!(tb, :c1, "label", "v1", style=:default)
    @test ms.label[1] == "v1"
    @test metastyle(tb, :label) == :default

    lbls = colmetavalues(tb, "label")
    @test lbls == ["v1","v2"]
    lbls[1] = "v"
    @test colmetadata(tb, :c1, "label") == "v"
end
