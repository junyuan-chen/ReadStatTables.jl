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
    ReadStatColumns() = new(Tuple{Int,Int}[], StringColumn[], Int8Column[],
        Int16Column[], Int32Column[], FloatColumn[], DoubleColumn[],
        DateColumn[], TimeColumn[])
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
    end
end

# Slower than setindex! ?
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
    end
end

Base.@propagate_inbounds function _setvalue!(cols::ReadStatColumns,
        value::readstat_value_t, r::Int, c::Int)
    m, n = getfield(cols, 1)[c]
    if m === 2
        v = string_value(value)
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
    end
    return nothing
end

function Base.push!(cols::ReadStatColumns, v::StringColumn)
    tar = getfield(cols, 2)
    push!(tar, v)
    push!(cols.index, (2, length(tar)))
    return cols
end

function Base.push!(cols::ReadStatColumns, v::Int8Column)
    tar = getfield(cols, 3)
    push!(tar, v)
    push!(cols.index, (3, length(tar)))
    return cols
end

function Base.push!(cols::ReadStatColumns, v::Int16Column)
    tar = getfield(cols, 4)
    push!(tar, v)
    push!(cols.index, (4, length(tar)))
    return cols
end

function Base.push!(cols::ReadStatColumns, v::Int32Column)
    tar = getfield(cols, 5)
    push!(tar, v)
    push!(cols.index, (5, length(tar)))
    return cols
end

function Base.push!(cols::ReadStatColumns, v::FloatColumn)
    tar = getfield(cols, 6)
    push!(tar, v)
    push!(cols.index, (6, length(tar)))
    return cols
end

function Base.push!(cols::ReadStatColumns, v::DoubleColumn)
    tar = getfield(cols, 7)
    push!(tar, v)
    push!(cols.index, (7, length(tar)))
    return cols
end

function Base.push!(cols::ReadStatColumns, v::DateColumn)
    tar = getfield(cols, 8)
    push!(tar, v)
    push!(cols.index, (8, length(tar)))
    return cols
end

function Base.push!(cols::ReadStatColumns, v::TimeColumn)
    tar = getfield(cols, 9)
    push!(tar, v)
    push!(cols.index, (9, length(tar)))
    return cols
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
