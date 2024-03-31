# Missing values for string variables are empty strings
# Do not use SentinelVector for Int8 because of the chance of sentinel collision
const StringColumn = Vector{String}
const Int8Column = Vector{Union{Int8, Missing}}
const Int16Column = SentinelVector{Int16, Int16, Missing, Vector{Int16}}
const Int32Column = SentinelVector{Int32, Int32, Missing, Vector{Int32}}
const FloatColumn = SentinelVector{Float32, Float32, Missing, Vector{Float32}}
const DoubleColumn = SentinelVector{Float64, Float64, Missing, Vector{Float64}}
const PooledColumnVec = PooledVector{String, UInt16, Vector{UInt16}}
const PooledColumn = Tuple{PooledColumnVec, Int}
for sz in (3, 7, 15, 31, 63, 127, 255)
    colname = Symbol(:Str, sz, :Column)
    strtype = Symbol(:String, sz)
    @eval const $colname = Vector{$strtype}
end

"""
    ReadStatColumns

A set of data columns for efficient data collection with `ReadStat`.

A concrete array type is specified for holding each possible type of data values
defined in `ReadStat`.
Data columns containing the same type of data values
are stored in the same `Vector` with a concrete element type.
A vector of tuples is used to locate the `Vector`
where a data column is stored and its index within that `Vector`.
"""
struct ReadStatColumns
    index::Vector{Tuple{Int,Int}}
    string::Vector{StringColumn}
    int8::Vector{Int8Column}
    int16::Vector{Int16Column}
    int32::Vector{Int32Column}
    float::Vector{FloatColumn}
    double::Vector{DoubleColumn}
    pooled::Vector{PooledColumn}
    str3::Vector{Str3Column}
    str7::Vector{Str7Column}
    str15::Vector{Str15Column}
    str31::Vector{Str31Column}
    str63::Vector{Str63Column}
    str127::Vector{Str127Column}
    str255::Vector{Str255Column}
    ReadStatColumns() = new(Tuple{Int,Int}[], StringColumn[], Int8Column[],
        Int16Column[], Int32Column[], FloatColumn[], DoubleColumn[],
        PooledColumn[], Str3Column[], Str7Column[], Str15Column[], Str31Column[],
        Str63Column[], Str127Column[], Str255Column[])
end

# If-else branching is needed for type stability
Base.@propagate_inbounds function Base.getindex(cols::ReadStatColumns, i::Int)
    m, n = getfield(cols, 1)[i]
    Base.Cartesian.@nif(
        15, # 14 ifs and 1 else
        i -> m === i+1,
        i -> @static(i+1 === 8 ? getfield(cols, m)[n][1] : getfield(cols, m)[n]),
        i -> error("invalid index $m")
    )
end

Base.@propagate_inbounds function Base.getindex(cols::ReadStatColumns, r, c::Int)
    m, n = getfield(cols, 1)[c]
    Base.Cartesian.@nif(
        15, # 14 ifs and 1 else
        i -> m === i+1,
        i -> @static(i+1 === 8 ? getindex(getfield(cols, m)[n][1], r) : getindex(getfield(cols, m)[n], r)),
        i -> error("invalid index $m")
    )
end

Base.@propagate_inbounds function Base.setindex!(cols::ReadStatColumns, v, r::Int, c::Int)
    m, n = getfield(cols, 1)[c]
    Base.Cartesian.@nif(
        15, # 14 ifs and 1 else
        i -> m === i+1,
        i -> @static(i+1 === 8 ? setindex!(getfield(cols, m)[n][1], v, r) : setindex!(getfield(cols, m)[n], v, r)),
        i -> error("invalid index $m")
    )
end

for sz in (3, 7, 15, 31, 63, 127, 255)
    strsz = Symbol(:_str, sz)
    strtype = Symbol(:String, sz)
    @eval begin
        $strsz(str::Ptr{UInt8}) = str == C_NULL ?
            $strtype() : $strtype(str, Int(ccall(:strlen, Csize_t, (Ptr{UInt8},), str)))
    end
end

Base.@propagate_inbounds function _setvalue!(cols::ReadStatColumns,
        value::readstat_value_t, r::Int, c::Int)
    m, n = getfield(cols, 1)[c]
    if m === 2
        v = _string(string_value(value))
        col = getfield(cols, 2)[n]
        r <= length(col) ? setindex!(col, v, r) : push!(col, v)
    elseif m === 3
        v = int8_value(value)
        col = getfield(cols, 3)[n]
        r <= length(col) ? setindex!(col, v, r) : push!(col, v)
    elseif m === 4
        v = int16_value(value)
        col = getfield(cols, 4)[n]
        r <= length(col) ? setindex!(col, v, r) : push!(col, v)
    elseif m === 5
        v = int32_value(value)
        col = getfield(cols, 5)[n]
        r <= length(col) ? setindex!(col, v, r) : push!(col, v)
    elseif m === 6
        v = float_value(value)
        col = getfield(cols, 6)[n]
        r <= length(col) ? setindex!(col, v, r) : push!(col, v)
    elseif m === 7
        v = double_value(value)
        col = getfield(cols, 7)[n]
        r <= length(col) ? setindex!(col, v, r) : push!(col, v)
    elseif m === 8
        col, pool_thres = getfield(cols, 8)[n]
        if length(col.pool) < pool_thres
            v = _string(string_value(value))
            r <= length(col) ? setindex!(col, v, r) : push!(col, v)
        else
            # Fall back to a string column without using a pool
            N = length(col)
            strcol = fill("", N)
            copyto!(strcol, 1, col, 1, r-1)
            strcols = getfield(cols, 2)
            push!(strcols, strcol)
            getfield(cols, 1)[c] = (2, length(strcols))
            empty!(col)
            v = _string(string_value(value))
            r <= N ? setindex!(strcol, v, r) : push!(strcol, v)
        end
    elseif m === 9
        v = _str3(string_value(value))
        col = getfield(cols, 9)[n]
        r <= length(col) ? setindex!(col, v, r) : push!(col, v)
    elseif m === 10
        v = _str7(string_value(value))
        col = getfield(cols, 10)[n]
        r <= length(col) ? setindex!(col, v, r) : push!(col, v)
    elseif m === 11
        v = _str15(string_value(value))
        col = getfield(cols, 11)[n]
        r <= length(col) ? setindex!(col, v, r) : push!(col, v)
    elseif m === 12
        v = _str31(string_value(value))
        col = getfield(cols, 12)[n]
        r <= length(col) ? setindex!(col, v, r) : push!(col, v)
    elseif m === 13
        v = _str63(string_value(value))
        col = getfield(cols, 13)[n]
        r <= length(col) ? setindex!(col, v, r) : push!(col, v)
    elseif m === 14
        v = _str127(string_value(value))
        col = getfield(cols, 14)[n]
        r <= length(col) ? setindex!(col, v, r) : push!(col, v)
    elseif m === 15
        v = _str255(string_value(value))
        col = getfield(cols, 15)[n]
        r <= length(col) ? setindex!(col, v, r) : push!(col, v)
    end
end

# Only used in the case when metadata do not have row count
@inline function _pushmissing!(cols::ReadStatColumns, i::Int)
    m, n = getfield(cols, 1)[i]
    if m === 2
        push!(getfield(cols, 2)[n], "")
    elseif m === 3
        push!(getfield(cols, 3)[n], missing)
    elseif m === 4
        push!(getfield(cols, 4)[n], missing)
    elseif m === 5
        push!(getfield(cols, 5)[n], missing)
    elseif m === 6
        push!(getfield(cols, 6)[n], missing)
    elseif m === 7
        push!(getfield(cols, 7)[n], missing)
    elseif m === 8
        push!(getfield(cols, 8)[n][1], "")
    elseif m === 9
        push!(getfield(cols, 9)[n], String3())
    elseif m === 10
        push!(getfield(cols, 10)[n], String7())
    elseif m === 11
        push!(getfield(cols, 11)[n], String15())
    elseif m === 12
        push!(getfield(cols, 12)[n], String31())
    elseif m === 13
        push!(getfield(cols, 13)[n], String63())
    elseif m === 14
        push!(getfield(cols, 14)[n], String127())
    elseif m === 15
        push!(getfield(cols, 15)[n], String255())
    end
    return nothing
end

for (i, etype) in enumerate((:String, :Int8, :Int16, :Int32, :Float, :Double, :Pooled))
    coltype = Symbol(etype, :Column)
    @eval begin
        function Base.push!(cols::ReadStatColumns, v::$coltype)
            tar = getfield(cols, $(1+i))
            push!(tar, v)
            push!(cols.index, ($(1+i), length(tar)))
            return cols
        end
    end
end

for (i, sz) in enumerate((3, 7, 15, 31, 63, 127, 255))
    coltype = Symbol(:Str, sz, :Column)
    @eval begin
        function Base.push!(cols::ReadStatColumns, v::$coltype)
            tar = getfield(cols, $(8+i))
            push!(tar, v)
            push!(cols.index, ($(8+i), length(tar)))
            return cols
        end
    end
end

Base.push!(cols::ReadStatColumns, vs...) = (foreach(v->push!(cols, v), vs); cols)

Base.show(io::IO, cols::ReadStatColumns) =
    print(io, nrow(cols), '×', ncol(cols), " ReadStatColumns")

# Column types that will be directly chained together across tasks
const _chainedcoltypes = (String => :StringColumn,
    Union{Int8, Missing} => :Int8Column,
    Union{Int16, Missing} => :Int16Column,
    Union{Int32, Missing} => :Int32Column,
    Union{Float32, Missing} => :FloatColumn,
    Union{Float64, Missing} => :DoubleColumn,
    String3 => :Str3Column, String7 => :Str7Column,
    String15 => :Str15Column, String31 => :Str31Column,
    String63 => :Str63Column, String127 => :Str127Column, String255 => :Str255Column)

for (etype, coltype) in _chainedcoltypes
    colname = Symbol(:Chained, coltype)
    @eval const $colname = ChainedVector{$etype, $coltype}
end

"""
    ChainedReadStatColumns

A set of data columns obtained by lazily appending multiple `ReadStatColumns`.
"""
struct ChainedReadStatColumns
    index::Vector{Tuple{Int,Int}}
    string::Vector{ChainedStringColumn}
    int8::Vector{ChainedInt8Column}
    int8nm::Vector{Vector{Int8}}
    int16::Vector{ChainedInt16Column}
    int16nm::Vector{ChainedVector{Int16, Vector{Int16}}}
    int32::Vector{ChainedInt32Column}
    int32nm::Vector{ChainedVector{Int32, Vector{Int32}}}
    float::Vector{ChainedFloatColumn}
    floatnm::Vector{ChainedVector{Float32, Vector{Float32}}}
    double::Vector{ChainedDoubleColumn}
    doublenm::Vector{ChainedVector{Float64, Vector{Float64}}}
    pooled::Vector{PooledColumnVec}
    str3::Vector{ChainedStr3Column}
    str7::Vector{ChainedStr7Column}
    str15::Vector{ChainedStr15Column}
    str31::Vector{ChainedStr31Column}
    str63::Vector{ChainedStr63Column}
    str127::Vector{ChainedStr127Column}
    str255::Vector{ChainedStr255Column}
    ChainedReadStatColumns() = new(Tuple{Int,Int}[], ChainedStringColumn[],
        ChainedInt8Column[], Vector{Int8}[],
        ChainedInt16Column[], ChainedVector{Int16, Vector{Int16}}[],
        ChainedInt32Column[], ChainedVector{Int32, Vector{Int32}}[],
        ChainedFloatColumn[], ChainedVector{Float32, Vector{Float32}}[],
        ChainedDoubleColumn[], ChainedVector{Float64, Vector{Float64}}[],
        PooledColumnVec[], ChainedStr3Column[], ChainedStr7Column[],
        ChainedStr15Column[], ChainedStr31Column[], ChainedStr63Column[],
        ChainedStr127Column[], ChainedStr255Column[])
end

Base.@propagate_inbounds function Base.getindex(cols::ChainedReadStatColumns, i::Int)
    m, n = getfield(cols, 1)[i]
    Base.Cartesian.@nif(
        20, # 19 ifs and 1 else
        i -> m === i+1,
        i -> getfield(cols, m)[n],
        i -> error("invalid index $m")
    )
end

Base.@propagate_inbounds function Base.getindex(cols::ChainedReadStatColumns, r, c::Int)
    m, n = getfield(cols, 1)[c]
    Base.Cartesian.@nif(
        20, # 19 ifs and 1 else
        i -> m === i+1,
        i -> getindex(getfield(cols, m)[n], r),
        i -> error("invalid index $m")
    )
end

Base.@propagate_inbounds function Base.setindex!(cols::ChainedReadStatColumns, v, r::Int, c::Int)
    m, n = getfield(cols, 1)[c]
    Base.Cartesian.@nif(
        20, # 19 ifs and 1 else
        i -> m === i+1,
        i -> setindex!(getfield(cols, m)[n], v, r),
        i -> error("invalid index $m")
    )
end

function _pushchain!(cols::ChainedReadStatColumns, hms::Bool, vs::Vector{StringColumn})
    cv = ChainedVector(vs)
    tar = getfield(cols, 2)
    push!(tar, cv)
    push!(cols.index, (2, length(tar)))
    return cols
end

function _pushchain!(cols::ChainedReadStatColumns, hms::Bool, vs::Vector{Int8Column})
    if hms
        cv = ChainedVector(vs)
        tar = getfield(cols, 3)
        push!(tar, cv)
        push!(cols.index, (3, length(tar)))
        return cols
    else
        cv = Vector{Int8}(undef, sum(length, vs))
        i1 = 1
        for v in vs
            copyto!(cv, i1, v)
            i1 += length(v)
        end
        tar = getfield(cols, 4)
        push!(tar, cv)
        push!(cols.index, (4, length(tar)))
        return cols
    end
end

for (i, etype) in enumerate((:Int16, :Int32, :Float, :Double))
    coltype = Symbol(etype, :Column)
    @eval begin
        function _pushchain!(cols::ChainedReadStatColumns, hms::Bool, vs::Vector{$coltype})
            if hms
                cv = ChainedVector(vs)
                tar = getfield(cols, $(3+2*i))
                push!(tar, cv)
                push!(cols.index, ($(3+2*i), length(tar)))
                return cols
            else
                cv = ChainedVector(map(parent, vs))
                tar = getfield(cols, $(4+2*i))
                push!(tar, cv)
                push!(cols.index, ($(4+2*i), length(tar)))
                return cols
            end
        end
    end
end

function _pushchain!(cols::ChainedReadStatColumns, hms::Bool, vs::Vector{PooledColumnVec})
    v1 = vs[1]
    refs = v1.refs
    pool = v1.pool
    invpool = v1.invpool
    i0 = length(refs)
    resize!(refs, sum(length, vs))
    refmap = Dict{UInt16, UInt16}()
    nlbls = UInt16(length(pool))
    z = zero(UInt16)
    o = one(UInt16)
    @inbounds for n in 2:length(vs)
        vn = vs[n]
        lbln = o
        for x in vn.pool
            lbl = get(invpool, x, z)
            if iszero(lbl)
                nlbls += o
                invpool[x] = nlbls
                refmap[lbln] = nlbls
                push!(pool, x)
            else
                refmap[lbln] = lbl
            end
            lbln += o
        end
        refsn = vn.refs
        for i in 1:length(vn)
            refs[i0+i] = refmap[refsn[i]]
        end
        i0 += length(refsn)
    end
    pv = PooledArray(RefArray(refs), invpool, pool)
    tar = getfield(cols, 13)
    push!(tar, pv)
    push!(cols.index, (13, length(tar)))
    return cols
end

# vs mixes PooledColumnVec and StringColumn
function _pushchain!(cols::ChainedReadStatColumns, hms::Bool, vs::Vector{AbstractVector{String}})
    cv = ChainedVector(collect(StringColumn, vs))
    tar = getfield(cols, 2)
    push!(tar, cv)
    push!(cols.index, (2, length(tar)))
    return cols
end

for (i, sz) in enumerate((3, 7, 15, 31, 63, 127, 255))
    coltype = Symbol(:Str, sz, :Column)
    @eval begin
        function _pushchain!(cols::ChainedReadStatColumns, hms::Bool, vs::Vector{$coltype})
            cv = ChainedVector(vs)
            tar = getfield(cols, $(13+i))
            push!(tar, cv)
            push!(cols.index, ($(13+i), length(tar)))
            return cols
        end
    end
end

const ColumnsOrChained = Union{ReadStatColumns, ChainedReadStatColumns}

Base.iterate(cols::ColumnsOrChained, state=1) =
    state > length(cols) ? nothing : (cols[state], state+1)

ncol(cols::ColumnsOrChained) = length(cols.index)
nrow(cols::ColumnsOrChained) = ncol(cols) > 0 ? length(cols[1])::Int : 0
Base.size(cols::ColumnsOrChained) = (nrow(cols), ncol(cols))
Base.length(cols::ColumnsOrChained) = ncol(cols)

Base.show(io::IO, cols::ChainedReadStatColumns) =
    print(io, nrow(cols), '×', ncol(cols), " ChainedReadStatColumns")
