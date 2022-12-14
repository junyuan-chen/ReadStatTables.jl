# Missing values for string variables are empty strings
# Do not use SentinelVector for Int8 because of the chance of sentinel collision
const StringColumn = Vector{String}
const Int8Column = Vector{Union{Int8, Missing}}
const Int16Column = SentinelVector{Int16, Int16, Missing, Vector{Int16}}
const Int32Column = SentinelVector{Int32, Int32, Missing, Vector{Int32}}
const FloatColumn = SentinelVector{Float32, Float32, Missing, Vector{Float32}}
const DoubleColumn = SentinelVector{Float64, Float64, Missing, Vector{Float64}}
const DateColumn = SentinelVector{Date, Date, Missing, Vector{Date}}
const TimeColumn = SentinelVector{DateTime, DateTime, Missing, Vector{DateTime}}
const PooledColumn = Tuple{PooledVector{String, UInt16, Vector{UInt16}}, Int}
for sz in (3, 7, 15, 31, 63)
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
    date::Vector{DateColumn}
    time::Vector{TimeColumn}
    pooled::Vector{PooledColumn}
    str3::Vector{Str3Column}
    str7::Vector{Str7Column}
    str15::Vector{Str15Column}
    str31::Vector{Str31Column}
    str63::Vector{Str63Column}
    ReadStatColumns() = new(Tuple{Int,Int}[], StringColumn[], Int8Column[],
        Int16Column[], Int32Column[], FloatColumn[], DoubleColumn[],
        DateColumn[], TimeColumn[], PooledColumn[],
        Str3Column[], Str7Column[], Str15Column[], Str31Column[], Str63Column[])
end

# If-else branching is needed for type stability
Base.@propagate_inbounds function Base.getindex(cols::ReadStatColumns, i::Int)
    m, n = getfield(cols, 1)[i]
    if m === 2
        return getfield(cols, 2)[n]
    elseif m === 3
        return getfield(cols, 3)[n]
    elseif m === 4
        return getfield(cols, 4)[n]
    elseif m === 5
        return getfield(cols, 5)[n]
    elseif m === 6
        return getfield(cols, 6)[n]
    elseif m === 7
        return getfield(cols, 7)[n]
    elseif m === 8
        return getfield(cols, 8)[n]
    elseif m === 9
        return getfield(cols, 9)[n]
    elseif m === 10
        return getfield(cols, 10)[n][1]
    elseif m === 11
        return getfield(cols, 11)[n]
    elseif m === 12
        return getfield(cols, 12)[n]
    elseif m === 13
        return getfield(cols, 13)[n]
    elseif m === 14
        return getfield(cols, 14)[n]
    elseif m === 15
        return getfield(cols, 15)[n]
    end
end

Base.@propagate_inbounds function Base.getindex(cols::ReadStatColumns, r, c::Int)
    m, n = getfield(cols, 1)[c]
    if m === 2
        return getindex(getfield(cols, 2)[n], r)
    elseif m === 3
        return getindex(getfield(cols, 3)[n], r)
    elseif m === 4
        return getindex(getfield(cols, 4)[n], r)
    elseif m === 5
        return getindex(getfield(cols, 5)[n], r)
    elseif m === 6
        return getindex(getfield(cols, 6)[n], r)
    elseif m === 7
        return getindex(getfield(cols, 7)[n], r)
    elseif m === 8
        return getindex(getfield(cols, 8)[n], r)
    elseif m === 9
        return getindex(getfield(cols, 9)[n], r)
    elseif m === 10
        return getindex(getfield(cols, 10)[n][1], r)
    elseif m === 11
        return getindex(getfield(cols, 11)[n], r)
    elseif m === 12
        return getindex(getfield(cols, 12)[n], r)
    elseif m === 13
        return getindex(getfield(cols, 13)[n], r)
    elseif m === 14
        return getindex(getfield(cols, 14)[n], r)
    elseif m === 15
        return getindex(getfield(cols, 15)[n], r)
    end
end

Base.@propagate_inbounds function Base.setindex!(cols::ReadStatColumns, v, r::Int, c::Int)
    m, n = getfield(cols, 1)[c]
    if m === 2
        return setindex!(getfield(cols, 2)[n], v, r)
    elseif m === 3
        return setindex!(getfield(cols, 3)[n], v, r)
    elseif m === 4
        return setindex!(getfield(cols, 4)[n], v, r)
    elseif m === 5
        return setindex!(getfield(cols, 5)[n], v, r)
    elseif m === 6
        return setindex!(getfield(cols, 6)[n], v, r)
    elseif m === 7
        return setindex!(getfield(cols, 7)[n], v, r)
    elseif m === 8
        return setindex!(getfield(cols, 8)[n], v, r)
    elseif m === 9
        return setindex!(getfield(cols, 9)[n], v, r)
    elseif m === 10
        return setindex!(getfield(cols, 10)[n][1], v, r)
    elseif m === 11
        return setindex!(getfield(cols, 11)[n], v, r)
    elseif m === 12
        return setindex!(getfield(cols, 12)[n], v, r)
    elseif m === 13
        return setindex!(getfield(cols, 13)[n], v, r)
    elseif m === 14
        return setindex!(getfield(cols, 14)[n], v, r)
    elseif m === 15
        return setindex!(getfield(cols, 15)[n], v, r)
    end
end

for sz in (3, 7, 15, 31, 63)
    strsz = Symbol(:_str, sz)
    strtype = Symbol(:String, sz)
    @eval $strsz(str::Ptr{UInt8}) = str == C_NULL ? $strtype() : $strtype(str)
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
    elseif m === 10
        col, pool_thres = getfield(cols, 10)[n]
        if length(col.pool) < pool_thres
            v = _string(string_value(value))
            r <= length(col) ? setindex!(col, v, r) : push!(col, v)
        else
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
    elseif m === 11
        v = _str3(string_value(value))
        col = getfield(cols, 11)[n]
        r <= length(col) ? setindex!(col, v, r) : push!(col, v)
    elseif m === 12
        v = _str7(string_value(value))
        col = getfield(cols, 12)[n]
        r <= length(col) ? setindex!(col, v, r) : push!(col, v)
    elseif m === 13
        v = _str15(string_value(value))
        col = getfield(cols, 13)[n]
        r <= length(col) ? setindex!(col, v, r) : push!(col, v)
    elseif m === 14
        v = _str31(string_value(value))
        col = getfield(cols, 14)[n]
        r <= length(col) ? setindex!(col, v, r) : push!(col, v)
    elseif m === 15
        v = _str63(string_value(value))
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
    elseif m === 10
        push!(getfield(cols, 10)[n][1], "")
    elseif m === 11
        push!(getfield(cols, 11)[n], String3())
    elseif m === 12
        push!(getfield(cols, 12)[n], String7())
    elseif m === 13
        push!(getfield(cols, 13)[n], String15())
    elseif m === 14
        push!(getfield(cols, 14)[n], String31())
    elseif m === 15
        push!(getfield(cols, 15)[n], String63())
    end
    return nothing
end

for (i, etype) in enumerate((:String, :Int8, :Int16, :Int32, :Float, :Double, :Date, :Time, :Pooled))
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

for (i, sz) in enumerate((3, 7, 15, 31, 63))
    coltype = Symbol(:Str, sz, :Column)
    @eval begin
        function Base.push!(cols::ReadStatColumns, v::$coltype)
            tar = getfield(cols, $(10+i))
            push!(tar, v)
            push!(cols.index, ($(10+i), length(tar)))
            return cols
        end
    end
end

Base.push!(cols::ReadStatColumns, vs...) = (foreach(v->push!(cols, v), vs); cols)

Base.iterate(cols::ReadStatColumns, state=1) =
    state > length(cols) ? nothing : (cols[state], state+1)

ncol(cols::ReadStatColumns) = length(cols.index)
nrow(cols::ReadStatColumns) = ncol(cols) > 0 ? length(cols[1])::Int : 0
Base.size(cols::ReadStatColumns) = (nrow(cols), ncol(cols))
Base.length(cols::ReadStatColumns) = ncol(cols)

Base.show(io::IO, cols::ReadStatColumns) =
    print(io, nrow(cols), '×', ncol(cols), " ReadStatColumns")
