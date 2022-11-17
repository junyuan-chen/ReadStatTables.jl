"""
    ColumnIndex

A type union for values accepted by [`readstat`](@ref)
and [`ReadStatTable`](@ref) for selecting a column.
A column can be selected either with the column name as `Symbol` or `String`;
or with an integer index based on the position in a table.
See also [`ColumnSelector`](@ref).
"""
const ColumnIndex = Union{Symbol, String, Integer}

abstract type AbstractMetaDict <: AbstractDict{String, Any} end

Base.get(m::AbstractMetaDict, key, default) =
    haskey(m, key) ? getindex(m, key) : default
Base.get(f::Base.Callable, m::AbstractMetaDict, key) =
    haskey(m, key) ? getindex(m, key) : f()

"""
    ReadStatMeta <: AbstractMetaDict

A collection of file-level metadata associated with a data file processed with `ReadStat`.
"""
mutable struct ReadStatMeta <: AbstractMetaDict
    filelabel::String
    vallabels::Dict{String, Dict{Any,String}}
    timestamp::DateTime
    fileext::String
end

Base.setindex!(m::ReadStatMeta, v, n::Symbol) = setfield!(m, n, v)
Base.setindex!(m::ReadStatMeta, v, n::AbstractString) = setindex!(m, v, Symbol(n))

function Base.show(io::IO, m::ReadStatMeta)
    print(io, typeof(m).name.name, "(")
    m.filelabel=="" || print(io, m.filelabel, ", ")
    print(io, m.fileext, ")")
end

function Base.show(io::IO, ::MIME"text/plain", m::ReadStatMeta)
    println(io, typeof(m).name.name, ':')
    io = IOContext(io, :limit=>true)
    println(io, "  file label     => ", m.filelabel)
    println(io, "  value labels   => ", sort!(collect(keys(m.vallabels))))
    println(io, "  timestamp      => ", m.timestamp)
    print(io,   "  file extension => ", m.fileext)
end

"""
    ReadStatColMeta <: AbstractMetaDict

A collection of variable-level metadata associated with
a data column processed with `ReadStat`.
"""
struct ReadStatColMeta <: AbstractMetaDict
    label::String
    format::String
    vallabel::String
    measure::Cint
    alignment::Cint
    storagewidth::Csize_t
end

function Base.show(io::IO, m::ReadStatColMeta)
    print(io, typeof(m).name.name, "(")
    m.label=="" || print(io, m.label, ", ")
    print(io, m.format, ")")
end

function Base.show(io::IO, ::MIME"text/plain", m::ReadStatColMeta)
    println(io, typeof(m).name.name, ':')
    io = IOContext(io, :limit=>true)
    println(io, "  label         => ", m.label)
    println(io, "  format        => ", m.format)
    println(io, "  value label   => ", m.vallabel)
    println(io, "  measure       => ", m.measure)
    println(io, "  alignment     => ", m.alignment)
    print(io, "  storage width => ", m.storagewidth)
end

const MetaOrColMeta = Union{ReadStatMeta, ReadStatColMeta}

Base.getindex(m::MetaOrColMeta, n::Symbol) = getfield(m, n)
Base.getindex(m::MetaOrColMeta, n::AbstractString) = getindex(m, Symbol(n))

function Base.iterate(m::MetaOrColMeta, state=1)
    x = iterate(fieldnames(typeof(m)), state)
    x === nothing && return nothing
    return String(x[1])=>m[x[1]], x[2]
end

Base.length(m::MetaOrColMeta) = fieldcount(typeof(m))

Base.haskey(m::MetaOrColMeta, key::Symbol) = hasfield(typeof(m), key)
Base.haskey(m::MetaOrColMeta, key::AbstractString) = haskey(m, Symbol(key))

"""
    ReadStatTable <: Tables.AbstractColumns

A `Tables.jl`-compatible column table that collects data
for a Stata, SAS or SPSS file processed with `ReadStat`.
"""
struct ReadStatTable <: Tables.AbstractColumns
    columns::Vector{AbstractVector}
    names::Vector{Symbol}
    lookup::Dict{Symbol, Int}
    meta::ReadStatMeta
    colmeta::StructVector{ReadStatColMeta}
    styles::Dict{Symbol, Symbol}
    function ReadStatTable(columns::Vector{AbstractVector}, names::Vector{Symbol},
            meta::ReadStatMeta, colmeta::StructVector{ReadStatColMeta},
            styles::Dict{Symbol, Symbol}=Dict{Symbol, Symbol}())
        lookup = Dict{Symbol, Int}(n=>i for (i, n) in enumerate(names))
        N = length(columns)
        length(lookup) == N ||
            throw(ArgumentError("column names are not unique"))
        length(colmeta) == N ||
            throw(ArgumentError("length of colmeta does not match the number of columns"))
        return new(columns, names, lookup, meta, colmeta, styles)
    end
end

# Accessor functions that are not intended to be exported
_columns(tb::ReadStatTable) = getfield(tb, :columns)
_names(tb::ReadStatTable) = getfield(tb, :names)
_lookup(tb::ReadStatTable) = getfield(tb, :lookup)
_meta(tb::ReadStatTable) = getfield(tb, :meta)
_colmeta(tb::ReadStatTable) = getfield(tb, :colmeta)
_colmeta(tb::ReadStatTable, key::Symbol) = getproperty(_colmeta(tb), key)
_colmeta(tb::ReadStatTable, key::AbstractString) = getproperty(_colmeta(tb), Symbol(key))
_colmeta(tb::ReadStatTable, col, key) = _colmeta(tb, key)[Tables.columnindex(tb, col)]
_styles(tb::ReadStatTable) = getfield(tb, :styles)

_colmeta!(tb::ReadStatTable, col, key, v) =
    _colmeta(tb, key)[Tables.columnindex(tb, col)] = v

Tables.getcolumn(tb::ReadStatTable, i::Int) = _columns(tb)[i]
Tables.getcolumn(tb::ReadStatTable, n::Symbol) = _columns(tb)[_lookup(tb)[n]]
# Avoid directly modifying names
Tables.columnnames(tb::ReadStatTable) = copy(_names(tb))

Base.getindex(tb::ReadStatTable, n::String) = Tables.getcolumn(tb, Symbol(n))

Tables.schema(tb::ReadStatTable) =
    Tables.Schema{(_names(tb)...,), Tuple{(eltype(col) for col in _columns(tb))...}}()

Tables.columnindex(::ReadStatTable, i::Int) = i
Tables.columnindex(tb::ReadStatTable, n::Symbol) = _lookup(tb)[n]
Tables.columnindex(tb::ReadStatTable, n::String) = Tables.columnindex(tb, Symbol(n))
Tables.columntype(tb::ReadStatTable, n::Symbol) = eltype(tb[n])

ncol(tb::ReadStatTable) = length(_names(tb))
nrow(tb::ReadStatTable) = ncol(tb) > 0 ? length(_columns(tb)[1])::Int : 0
Base.size(tb::ReadStatTable) = (nrow(tb), ncol(tb))
function Base.size(tb::ReadStatTable, i::Integer)
    if i == 1
        nrow(tb)
    elseif i == 2
        ncol(tb)
    else
        throw(ArgumentError("ReadStatTable only have two dimensions"))
    end
end

Tables.rowcount(tb::ReadStatTable) = nrow(tb)

Base.length(tb::ReadStatTable) = ncol(tb)
Base.isempty(tb::ReadStatTable) = size(tb, 1) == 0 || size(tb, 2) == 0

Base.values(tb::ReadStatTable) = _columns(tb)
Base.haskey(tb::ReadStatTable, key::Symbol) = haskey(_lookup(tb), key)
Base.haskey(tb::ReadStatTable, i::Int) = 0 < i <= ncol(tb)

Base.show(io::IO, tb::ReadStatTable) = print(io, nrow(tb), '×', ncol(tb), " ReadStatTable")

function Base.show(io::IO, ::MIME"text/plain", tb::ReadStatTable)
    show(io, tb)
    if ncol(tb) > 0 && nrow(tb) > 0
        println(io, ':')
        nr, nc = displaysize(io)
        pretty_table(IOContext(io, :limit=>true, :displaysize=>(nr-3, nc)),
            tb, vlines=1:1, hlines=1:1, show_row_number=true,
            newline_at_end=false, vcrop_mode=:middle)
    end
end

metadatasupport(::Type{ReadStatTable}) = (read=true, write=true)
colmetadatasupport(::Type{ReadStatTable}) = (read=true, write=true)

"""
    metastyle(tb::ReadStatTable, [key::Union{Symbol, AbstractString}])

Return the specified style(s) of all metadata for table `tb`.
If a metadata `key` is specified, only the style for the associated metadata are returned.
By default, the style for all metadata is `:default`.

The style of metadata is only determined by `key` and hence
is not distinguished across different columns.
"""
metastyle(tb::ReadStatTable) = _styles(tb)
metastyle(tb::ReadStatTable, key::Symbol) = get(_styles(tb), key, :default)
metastyle(tb::ReadStatTable, key::AbstractString) = metastyle(tb, Symbol(key))

"""
    metastyle!(tb::ReadStatTable, key::Union{Symbol, AbstractString}, style::Symbol)

Set the style of all metadata associated with `key` to `style` for table `tb`.

The style of metadata is only determined by `key` and hence
is not distinguished across different columns.
"""
metastyle!(tb::ReadStatTable, key::Symbol, style::Symbol) =
    (_styles(tb)[key] = style; _styles(tb))
metastyle!(tb::ReadStatTable, key::AbstractString, style::Symbol) =
    metastyle!(tb, Symbol(key), style)

metadata(tb::ReadStatTable, key::Union{AbstractString, Symbol}; style::Bool=false) =
    style ? (_meta(tb)[key], metastyle(tb, key)) : _meta(tb)[key]

struct MetaStyleView{T<:MetaOrColMeta} <: AbstractMetaDict
    parent::ReadStatTable
    m::T
end

Base.getindex(v::MetaStyleView, key::Symbol) = (getfield(v.m, key), metastyle(v.parent, key))
Base.getindex(v::MetaStyleView, key::AbstractString) = getindex(v, Symbol(key))

function Base.iterate(v::MetaStyleView{T}, state=1) where T
    x = iterate(v.m, state)
    x === nothing && return nothing
    style = metastyle(v.parent, fieldname(T, state))
    return x[1][1]=>(x[1][2], style), x[2]
end

Base.length(v::MetaStyleView) = length(v.m)
Base.haskey(v::MetaStyleView, key::Union{Symbol, AbstractString}) = haskey(v.m, key)

metadata(tb::ReadStatTable; style::Bool=false) =
    style ? MetaStyleView(tb, _meta(tb)) : _meta(tb)

# DataFrames.jl assume that metadata keys are strings
metadatakeys(::ReadStatTable) = ("filelabel", "vallabels", "timestamp", "fileext")

function metadata!(tb::ReadStatTable, key::Union{AbstractString, Symbol}, value;
        style=nothing)
    m = _meta(tb)
    m[key] = value
    style === nothing || (metastyle!(tb, key, style))
    return m
end

# style is only specified based on metadata field name and is not column-specific
function colmetadata(tb::ReadStatTable, col::ColumnIndex, key::Union{AbstractString, Symbol};
        style::Bool=false)
    return style ? (_colmeta(tb, col, key), metastyle(tb, key)) : _colmeta(tb, col, key)
end

function colmetadata(tb::ReadStatTable, col::ColumnIndex; style::Bool=false)
    i = Tables.columnindex(tb, col)
    return style ? MetaStyleView(tb, _colmeta(tb)[i]) : _colmeta(tb)[i]
end

struct ColMetaIterator{V} <: AbstractDict{Symbol, V}
    parent::ReadStatTable
end

Base.getindex(v::ColMetaIterator{ReadStatColMeta}, col) = colmetadata(v.parent, col)
Base.getindex(v::ColMetaIterator{MetaStyleView}, col) =
    colmetadata(v.parent, col, style=true)

function Base.iterate(v::ColMetaIterator, state=1)
    x = iterate(_names(v.parent), state)
    x === nothing && return nothing
    return x[1] => v[x[1]], x[2]
end

Base.length(v::ColMetaIterator) = ncol(v.parent)
Base.haskey(v::ColMetaIterator, key) = haskey(v.parent, key)

colmetadata(tb::ReadStatTable; style::Bool=false) =
    style ? ColMetaIterator{MetaStyleView}(tb) : ColMetaIterator{ReadStatColMeta}(tb)

# DataFrames.jl assume that metadata keys are strings
colmetadatakeys(::ReadStatTable, ::ColumnIndex) =
    ("label", "format", "vallabel", "measure", "alignment", "storagewidth")
colmetadatakeys(tb::ReadStatTable) = (n=>colmetadatakeys(tb, n) for n in _names(tb))

function colmetadata!(tb::ReadStatTable, col::ColumnIndex,
        key::Union{AbstractString, Symbol}, value; style=nothing)
    _colmeta!(tb, col, key, value)
    style === nothing || (metastyle!(tb, key, style))
    return colmetadata(tb)
end

"""
    colmetavalues(tb::ReadStatTable, key)

Return an array of metadata values associated with `key` for all columns in `tb`.
"""
colmetavalues(tb::ReadStatTable, key) = _colmeta(tb, key)
