@testset "ReadStatTable" begin
    tb = ReadStatTable(AbstractVector[], Symbol[])
    @test size(tb) == (0, 0)
    @test length(tb) == 0
    @test isempty(tb)
    @test sprint(show, MIME("text/plain"), tb) == "0×0 ReadStatTable"

    tb = ReadStatTable(AbstractVector[[]], Symbol[:c])
    @test size(tb) == (0, 1)
    @test length(tb) == 1
    @test isempty(tb)
    @test sprint(show, MIME("text/plain"), tb) == "0×1 ReadStatTable"

    c1 = collect(1:10)
    c2 = collect(10.0:-1.0:1.0)
    cols = AbstractVector[c1, c2]
    names = [:c1, :c2]
    tb = ReadStatTable(cols, names)
    @test ncol(tb) == 2
    @test nrow(tb) == 10
    @test size(tb) == (10, 2)
    @test size(tb, 1) == 10
    @test_throws ArgumentError size(tb, 3)
    @test length(tb) == 2
    @test !isempty(tb)

    @test Tables.getcolumn(tb, 1) === c1
    @test Tables.getcolumn(tb, :c2) === c2
    @test Tables.columnnames(tb) == names
    @test Tables.columnnames(tb) !== names

    @test Tables.schema(tb) == Tables.Schema{(:c1, :c2), Tuple{Int, Float64}}()
    @test Tables.columnindex(tb, :c1) == 1
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

    @test varlabels(tb) === nothing
    @test varformats(tb) === nothing
    @test val_label_keys(tb) === nothing
    @test val_label_dict(tb) === nothing
    @test filelabel(tb) === nothing
    @test filetimestamp(tb) === nothing
    @test fileext(tb) === nothing
end
