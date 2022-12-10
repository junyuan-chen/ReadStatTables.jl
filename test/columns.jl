function gettestcolumns(N::Int)
    strcol = fill("", N)
    int8col = Vector{Union{Int8, Missing}}(missing, N)
    int16col = SentinelVector{Int16}(undef, N)
    int32col = SentinelVector{Int32}(undef, N)
    floatcol = SentinelVector{Float32}(undef, N)
    doublecol = SentinelVector{Float64}(undef, N)
    datecol = SentinelVector{Date}(undef, N)
    timecol = SentinelVector{DateTime}(undef, N)
    pooledcol = (PooledArray(fill("", N), UInt16), 1000)
    str3col = fill(String3(), N)
    str7col = fill(String7(), N)
    str15col = fill(String15(), N)
    str31col = fill(String31(), N)
    return (strcol, int8col, int16col, int32col, floatcol, doublecol, datecol, timecol,
        pooledcol, str3col, str7col, str15col, str31col)
end

@testset "ReadStatColumns" begin
    cols = ReadStatColumns()
    @test size(cols) == (0, 0)
    @test length(cols) == 0
    @test iterate(cols) === nothing
    @test sprint(show, cols) == "0×0 ReadStatColumns"

    columns = gettestcolumns(10)
    push!(cols, columns...)
    @test size(cols) == (10, 13)
    @test length(cols) == 13
    @test cols.index == [(n, 1) for n in 2:14]
    for (i, col) in enumerate(columns)
        if i == 9
            @test cols[i] === col[1]
        else
            @test cols[i] === col
        end
    end
    @test sprint(show, cols) == "10×13 ReadStatColumns"

    vals = ["a", Int8(1), Int16(1), Int32(1), Float32(1), Float64(1), Date(1), DateTime(1), ("a" for _ in 1:5)...]
    for (i, (v, col)) in enumerate(zip(vals, columns))
        cols[1,i] = v
        @test cols[1,i] == v
        if i > 1 && i < 9
            cols[1,i] = missing
            @test ismissing(cols[1,i])
        end
    end

    for i in 1:6
        _pushmissing!(cols, i)
        if i == 1
            @test cols[11,i] == ""
        else
            @test ismissing(cols[11,i])
        end
    end

    for i in 9:13
        _pushmissing!(cols, i)
        @test cols[11,i] == ""
    end

    @test iterate(cols) === (cols[1], 2)
    @test iterate(cols, 14) === nothing
end
