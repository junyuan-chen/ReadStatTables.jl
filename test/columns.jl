function gettestcolumns(N::Int)
    strcol = fill("", N)
    int8col = Vector{Union{Int8, Missing}}(missing, N)
    int16col = SentinelVector{Int16}(undef, N)
    int32col = SentinelVector{Int32}(undef, N)
    floatcol = SentinelVector{Float32}(undef, N)
    doublecol = SentinelVector{Float64}(undef, N)
    datecol = SentinelVector{Date}(undef, N)
    timecol = SentinelVector{DateTime}(undef, N)
    return [strcol, int8col, int16col, int32col, floatcol, doublecol, datecol, timecol]
end

@testset "ReadStatColumns" begin
    cols = ReadStatColumns()
    @test size(cols) == (0, 0)
    @test length(cols) == 0
    @test iterate(cols) === nothing
    @test sprint(show, cols) == "0×0 ReadStatColumns"

    columns = gettestcolumns(10)
    push!(cols, columns...)
    @test_throws ArgumentError push!(cols, rand(10))
    @test size(cols) == (10, 8)
    @test length(cols) == 8
    @test cols.index == [(n, 1) for n in 2:9]
    for (i, col) in enumerate(columns)
        @test cols[i] === col
    end
    @test sprint(show, cols) == "10×8 ReadStatColumns"

    vals = ["a", Int8(1), Int16(1), Int32(1), Float32(1), Float64(1), Date(1), DateTime(1)]
    for (i, (v, col)) in enumerate(zip(vals, columns))
        cols[i,i] = v
        @test cols[i,i] == v
        if i > 1
            cols[i,i] = missing
            @test ismissing(cols[i,i])
        end
    end

    for i in 1:6
        _pushmissing!(cols, i)
        if i == 1
            @test cols[11,1] == ""
        else
            @test ismissing(cols[11,i])
        end
    end

    @test iterate(cols) === (cols[1], 2)
    @test iterate(cols, 9) === nothing
end
