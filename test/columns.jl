function gettestcolumns(N::Int)
    strcol = fill("", N)
    int8col = Vector{Union{Int8, Missing}}(missing, N)
    int16col = SentinelVector{Int16}(undef, N)
    int32col = SentinelVector{Int32}(undef, N)
    floatcol = SentinelVector{Float32}(undef, N)
    doublecol = SentinelVector{Float64}(undef, N)
    datecol = SentinelVector{Date}(undef, N)
    timecol = SentinelVector{DateTime}(undef, N)
    pooledcol = (PooledArray(fill("", N), UInt16), 100)
    str3col = fill(String3(), N)
    str7col = fill(String7(), N)
    str15col = fill(String15(), N)
    str31col = fill(String31(), N)
    str63col = fill(String63(), N)
    str127col = fill(String127(), N)
    str255col = fill(String255(), N)
    return (strcol, int8col, int16col, int32col, floatcol, doublecol, datecol, timecol,
        pooledcol, str3col, str7col, str15col, str31col, str63col, str127col, str255col)
end

@testset "ReadStatColumns" begin
    cols = ReadStatColumns()
    @test size(cols) == (0, 0)
    @test length(cols) == 0
    @test iterate(cols) === nothing
    @test sprint(show, cols) == "0×0 ReadStatColumns"

    columns = gettestcolumns(10)
    push!(cols, columns...)
    @test size(cols) == (10, 16)
    @test length(cols) == 16
    @test cols.index == [(n, 1) for n in 2:17]
    for (i, col) in enumerate(columns)
        if i == 9
            @test cols[i] === col[1]
        else
            @test cols[i] === col
        end
    end
    @test sprint(show, cols) == "10×16 ReadStatColumns"

    vals = ["a", Int8(1), Int16(1), Int32(1), Float32(1), Float64(1), Date(1), DateTime(1),
        ("a" for _ in 1:8)...]
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

    for i in 9:16
        _pushmissing!(cols, i)
        @test cols[11,i] == ""
    end

    @test iterate(cols) === (cols[1], 2)
    @test iterate(cols, 17) === nothing
end

function gettestchainedcolumns(N::Int)
    strcol = ChainedVector([fill("", N), fill("", N)])
    int8col = Vector{Union{Int8, Missing}}(missing, N)
    int8col = ChainedVector([int8col, copy(int8col)])
    int8nmcol = fill(Int8(1), 2*N)
    int16col = SentinelVector{Int16}(undef, N)
    int16col = ChainedVector([int16col, int16col])
    int16nmcol = ChainedVector([fill(Int16(1), N), fill(Int16(1), N)])
    int32col = SentinelVector{Int32}(undef, N)
    int32col = ChainedVector([int32col, int32col])
    int32nmcol = ChainedVector([fill(Int32(1), N), fill(Int32(1), N)])
    floatcol = SentinelVector{Float32}(undef, N)
    floatcol = ChainedVector([floatcol, floatcol])
    floatnmcol = ChainedVector([fill(Float32(1), N), fill(Float32(1), N)])
    doublecol = SentinelVector{Float64}(undef, N)
    doublecol = ChainedVector([doublecol, doublecol])
    doublenmcol = ChainedVector([fill(Float64(1), N), fill(Float64(1), N)])
    datecol = SentinelVector{Date}(undef, N)
    timecol = SentinelVector{DateTime}(undef, N)
    pooledcol = PooledArray(fill("", 2*N), UInt16)
    str3col = ChainedVector([fill(String3(), N), fill(String3(), N)])
    str7col = ChainedVector([fill(String7(), N), fill(String7(), N)])
    str15col = ChainedVector([fill(String15(), N), fill(String15(), N)])
    str31col = ChainedVector([fill(String31(), N), fill(String31(), N)])
    str63col = ChainedVector([fill(String63(), N), fill(String63(), N)])
    str127col = ChainedVector([fill(String127(), N), fill(String127(), N)])
    str255col = ChainedVector([fill(String255(), N), fill(String255(), N)])
    columns = (strcol, int8col, int8nmcol, int16col, int16nmcol, int32col, int32nmcol,
        floatcol, floatnmcol, doublecol, doublenmcol, datecol, timecol, pooledcol,
        str3col, str7col, str15col, str31col, str63col, str127col, str255col)
    cols = ChainedReadStatColumns()
    for i in 1:length(columns)
        push!(cols.index, (i+1, 1))
        push!(getfield(cols, i+1), columns[i])
    end
    return columns, cols
end

@testset "ChainedReadStatColumns" begin
    cols = ChainedReadStatColumns()
    @test size(cols) == (0, 0)
    @test length(cols) == 0
    @test iterate(cols) === nothing
    @test sprint(show, cols) == "0×0 ChainedReadStatColumns"

    columns1 = gettestcolumns(5)[vcat(1:6, 9:16)]
    columns2 = gettestcolumns(5)[vcat(1:6, 9:16)]
    for (i, (col1, col2)) in enumerate(zip(columns1, columns2))
        if i == 7
            _pushchain!(cols, true, [col1[1], col2[1]])
        else
            _pushchain!(cols, true, [col1, col2])
        end
        if i in 2:6
            fill!(col1, 1)
            fill!(col2, 1)
            _pushchain!(cols, false, [col1, col2])
        end
    end
    _pushchain!(cols, false, [columns1[9], columns1[1]])
    @test size(cols) == (10, 20)
    @test length(cols) == 20
    @test cols.index == [((n, 1) for n in vcat(2:12, 15:22))..., (2, 2)]

    pv1 = PooledArray(fill("a", 3), UInt16)
    pv2 = PooledArray(fill("b", 3), UInt16)
    _pushchain!(cols, false, [pv1, pv2])
    @test cols[21].refs == vcat(fill(UInt16(1), 3), fill(UInt16(2), 3))
    @test cols[21].pool == ["a", "b"]
    _pushchain!(cols, false, [pv1])
    @test cols[22] == pv1

    columns, cols = gettestchainedcolumns(5)
    for (i, col) in enumerate(columns)
        @test cols[i] === col
    end
    @test sprint(show, cols) == "10×21 ChainedReadStatColumns"

    vals = ["a", Int8(1), Int8(1), Int16(1), Int16(1), Int32(1), Int32(1),
        Float32(1), Float32(1), Float64(1), Float64(1), Date(1), DateTime(1),
        ("a" for _ in 1:8)...]
    for (i, v) in enumerate(vals)
        cols[1,i] = v
        @test cols[1,i] == v
        if i in 2:2:10
            cols[1,i] = missing
            @test ismissing(cols[1,i])
        end
    end

    @test iterate(cols) === (cols[1], 2)
    @test iterate(cols, 22) === nothing
end
