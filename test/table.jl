gettestmeta() = ReadStatMeta("flabel",
    Dict{String, Dict{Any,String}}("A"=>Dict(1=>"a")), Date(1), ".dta")

gettestcolmeta() = ReadStatColMeta("varlabel", "%tf", "A", Cint(1), Cint(1), Csize_t(1))

@testset "ReadStatMeta" begin
    m = gettestmeta()
    @test keytype(m) == String
    @test valtype(m) == Any
    @test m["filelabel"] == "flabel"
    m["filelabel"] = "filelab"
    @test m.filelabel == "filelab"
    m = gettestmeta()
    @test iterate(m) == ("filelabel"=>"flabel", 2)
    @test iterate(m, 5) === nothing
    @test collect(keys(m)) == [string(n) for n in fieldnames(ReadStatMeta)]
    @test length(m) == length(fieldnames(ReadStatMeta))
    @test haskey(m, "filelabel")
    @test get(m, "lab", "default") == "default"
    @test get(Vector, m, "filelabel") == "flabel"
    @test copy(m) isa Dict{String, Any}
    @test sprint(show, m) == "ReadStatMeta(flabel, .dta)"
    m1 = ReadStatMeta("", Dict{String, Dict{Any,String}}("A"=>Dict(1=>"a")), Date(1), ".dta")
    @test sprint(show, m1) == "ReadStatMeta(.dta)"
    @test sprint(show, MIME("text/plain"), m) == """
        ReadStatMeta:
          file label     => flabel
          value labels   => ["A"]
          timestamp      => 0001-01-01T00:00:00
          file extension => .dta"""
end

@testset "ReadStatColMeta" begin
    m = gettestcolmeta()
    @test keytype(m) == String
    @test valtype(m) == Any
    @test m["label"] == "varlabel"
    @test iterate(m) == ("label"=>"varlabel", 2)
    @test iterate(m, 7) === nothing
    @test collect(keys(m)) == [string(n) for n in fieldnames(ReadStatColMeta)]
    @test length(m) == length(fieldnames(ReadStatColMeta))
    @test haskey(m, "label")
    @test get(m, "lab", "default") == "default"
    @test get(Vector, m, "label") == "varlabel"
    @test copy(m) isa Dict{String, Any}
    @test sprint(show, m) == "ReadStatColMeta(varlabel, %tf)"
    m1 = ReadStatColMeta("", "%tf", "A", Cint(1), Cint(1), Csize_t(1))
    @test sprint(show, m1) == "ReadStatColMeta(%tf)"
    @test sprint(show, MIME("text/plain"), m) == """
        ReadStatColMeta:
          label         => varlabel
          format        => %tf
          value label   => A
          measure       => 1
          alignment     => 1
          storage width => 1"""
end

@testset "ReadStatTable" begin
    m = gettestmeta()
    ms = StructVector(ReadStatColMeta[])
    tb = ReadStatTable(AbstractVector[], Symbol[], m, ms)
    @test size(tb) == (0, 0)
    @test length(tb) == 0
    @test isempty(tb)
    @test sprint(show, MIME("text/plain"), tb) == "0×0 ReadStatTable"

    @test_throws ArgumentError ReadStatTable(AbstractVector[[]], Symbol[:c], m, ms)
    ms = StructVector([gettestcolmeta()])
    tb = ReadStatTable(AbstractVector[[]], Symbol[:c], m, ms)
    @test size(tb) == (0, 1)
    @test length(tb) == 1
    @test isempty(tb)
    @test sprint(show, MIME("text/plain"), tb) == "0×1 ReadStatTable"

    c1 = collect(1:10)
    c2 = collect(10.0:-1.0:1.0)
    cols = AbstractVector[c1, c2]
    names = [:c1, :c2]
    ms = StructVector{ReadStatColMeta}(
        (["v1","v2"], ["%tf","%tc"], ["A",""], [1,1], [1,1], [1,1]))
    @test_throws ArgumentError ReadStatTable(cols, [:c1, :c1], m, ms)
    tb = ReadStatTable(cols, names, m, ms)
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

    @test Tables.schema(tb) == Tables.Schema{(:c1, :c2), Tuple{Int, Float64}}()
    @test Tables.columnindex(tb, 1) == 1
    @test Tables.columnindex(tb, :c1) == 1
    @test Tables.columnindex(tb, "c1") == 1
    @test Tables.columntype(tb, :c1) == Int
    @test Tables.rowcount(tb) == 10

    @test values(tb) === cols
    @test haskey(tb, :c1)
    @test haskey(tb, 2)
    
    @test sprint(show, tb) == "10×2 ReadStatTable"
    @test sprint(show, MIME("text/plain"), tb, context=:displaysize=>(15,80)) == """
        10×2 ReadStatTable:
         Row │    c1       c2
             │ Int64  Float64
        ─────┼────────────────
           1 │     1     10.0
           2 │     2      9.0
           3 │     3      8.0
          ⋮  │   ⋮       ⋮
           8 │     8      3.0
           9 │     9      2.0
          10 │    10      1.0
                4 rows omitted"""
end

@testset "metadata colmetadata" begin
    @test DataAPI.metadatasupport(ReadStatTable) == (read=true, write=true)
    @test DataAPI.colmetadatasupport(ReadStatTable) == (read=true, write=true)

    c1 = collect(1:10)
    c2 = collect(10.0:-1.0:1.0)
    cols = AbstractVector[c1, c2]
    names = [:c1, :c2]
    m = gettestmeta()
    ms = StructVector{ReadStatColMeta}(
        (["v1","v2"], ["%tf","%tc"], ["A",""], [1,1], [1,1], [1,1]))
    tb = ReadStatTable(cols, names, m, ms)

    @test isempty(metastyle(tb))
    @test metastyle(tb, :filelabel) == :default
    @test metastyle(tb, "filelabel") == :default

    @test metadata(tb, "filelabel") == "flabel"
    @test metadata(tb, :filelabel) == "flabel"
    @test metadata(tb, "filelabel", style=true) == ("flabel", :default)

    metastyle!(tb, "filelabel", :note)
    @test metastyle(tb, :filelabel) == :note
    @test metadata(tb, "filelabel", style=true) == ("flabel", :note)

    @test metadata(tb) === m
    v = metadata(tb, style=true)
    @test v isa AbstractDict
    @test v["filelabel"] == ("flabel", :note)
    @test length(v) == length(m)
    @test copy(v) isa Dict{String, Any}

    @test metadatakeys(tb) == map(x->String(x), fieldnames(ReadStatMeta))

    metadata!(tb, "filelabel", "filelab")
    @test m.filelabel == "filelab"
    @test metastyle(tb, :filelabel) == :note
    metadata!(tb, "filelabel", "flabel", style=:default)
    @test m.filelabel == "flabel"
    @test metastyle(tb, :filelabel) == :default

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
