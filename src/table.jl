"""
    ColumnIndex

A type union for values accepted by [`readstat`](@ref)
and [`ReadStatTable`](@ref) for selecting a column.
A column can be selected either with the column name as `Symbol` or `String`;
or with an integer (`Int`) index based on the position in a table.
See also [`ColumnSelector`](@ref).
"""
const ColumnIndex = Union{Symbol, String, Int}

abstract type AbstractMetaDict <: AbstractDict{String, Any} end

Base.get(m::AbstractMetaDict, key, default) =
    haskey(m, key) ? getindex(m, key) : default
Base.get(f::Base.Callable, m::AbstractMetaDict, key) =
    haskey(m, key) ? getindex(m, key) : f()

"""
    ReadStatMeta <: AbstractMetaDict

A collection of file-level metadata associated with a data file processed with `ReadStat`.

Metadata can be retrieved and modified from the associated [`ReadStatTable`](@ref)
via methods compatible with `DataAPI.jl`.
A dictionary-like interface is also available for directly working with `ReadStatMeta`.

# Fields
- `row_count::Int`: number of rows returned by `ReadStat` parser; being `-1` if not available in metadata; may reflect the value set with the `row_limit` parser option instead of the actual number of rows in the data file.
- `var_count::Int`: number of data columns returned by `ReadStat` parser.
- `creation_time::DateTime`: timestamp for file creation.
- `modified_time::DateTime`: timestamp for file modification.
- `file_format_version::Int`: version number of file format.
- `file_format_is_64bit::Bool`: indicator for 64-bit file format; only relevant to SAS.
- `compression::readstat_compress_t`: file compression mode; only relevant to certain file formats.
- `endianness::readstat_endian_t`: endianness of data file.
- `table_name::String`: name of the data table; only relevant to `.xpt` format.
- `file_label::String`: label of data file.
- `file_encoding::String`: character encoding of data file.
- `notes::Vector{String}`: notes attached to data file.
- `file_ext::String`: file extension of data file.
"""
mutable struct ReadStatMeta <: AbstractMetaDict
    row_count::Int
    var_count::Int
    creation_time::DateTime
    modified_time::DateTime
    file_format_version::Int
    file_format_is_64bit::Bool
    compression::readstat_compress_t
    endianness::readstat_endian_t
    table_name::String
    file_label::String
    file_encoding::String
    notes::Vector{String}
    file_ext::String
end

ReadStatMeta() = ReadStatMeta(0, 0, now(), now(), -1, true,
    READSTAT_COMPRESS_NONE, READSTAT_ENDIAN_NONE, "", "", "", String[], "")

Base.setindex!(m::ReadStatMeta, v, n::Symbol) = setfield!(m, n, v)
Base.setindex!(m::ReadStatMeta, v, n::AbstractString) = setindex!(m, v, Symbol(n))

function Base.show(io::IO, m::ReadStatMeta)
    print(io, typeof(m).name.name, "(")
    m.file_label=="" || print(io, m.file_label, ", ")
    print(io, m.file_ext, ")")
end

function Base.show(io::IO, ::MIME"text/plain", m::ReadStatMeta)
    println(io, typeof(m).name.name, ':')
    io = IOContext(io, :limit=>true)
    println(io, "  row count           => ", m.row_count)
    println(io, "  var count           => ", m.var_count)
    println(io, "  modified time       => ", m.modified_time)
    println(io, "  file format version => ", m.file_format_version)
    length(m.table_name) > 0 && println(io, "  table name          => ", m.table_name)
    length(m.file_label) > 0 && println(io, "  file label          => ", m.file_label)
    length(m.notes) > 0 && println(io, "  notes               => ", m.notes)
    print(io,   "  file extension      => ", m.file_ext)
end

"""
    ReadStatColMeta <: AbstractMetaDict

A collection of variable-level metadata associated with
a data column processed with `ReadStat`.

Metadata can be retrieved and modified from the associated [`ReadStatTable`](@ref)
via methods compatible with `DataAPI.jl`.
A dictionary-like interface is also available for directly working with `ReadStatColMeta`,
but it does not allow modifying metadata values.
An alternative way to retrive and modify the metadata is via [`colmetavalues`](@ref).

# Fields
- `label::String`: variable label.
- `format::String`: variable format.
- `type::readstat_type_t`: original variable type recognized by `ReadStat`.
- `vallabel::Symbol`: name of the dictionary of value labels associated with the variable; see also [`getvaluelabels`](@ref) for the effect of modifying this field.
- `storage_width::Csize_t`: variable storage width in data file.
- `display_width::Cint`: width for display.
- `measure::readstat_measure_t`: measure type of the variable; only relevant to SPSS.
- `alignment::readstat_alignment_t`: variable display alignment.
"""
struct ReadStatColMeta <: AbstractMetaDict
    label::String
    format::String
    type::readstat_type_t
    vallabel::Symbol
    storage_width::Csize_t
    display_width::Cint
    measure::readstat_measure_t
    alignment::readstat_alignment_t
end

function ReadStatColMetaVec(N::Integer = 0)
    colmeta = StructVector{ReadStatColMeta}((String[], String[], readstat_type_t[],
        Symbol[], Csize_t[], Cint[], readstat_measure_t[], readstat_alignment_t[]))
    N > 0 && resize!(colmeta, N)
    return colmeta
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
    println(io, "  type          => ", m.type)
    println(io, "  value label   => ", m.vallabel)
    println(io, "  storage width => ", m.storage_width)
    println(io, "  display width => ", m.display_width)
    println(io, "  measure       => ", m.measure)
    print(io, "  alignment     => ", m.alignment)
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

const ColMetaVec = StructVector{ReadStatColMeta, NamedTuple{(:label, :format, :type,
    :vallabel, :storage_width, :display_width, :measure, :alignment),
    Tuple{Vector{String}, Vector{String}, Vector{readstat_type_t}, Vector{Symbol},
    Vector{UInt64}, Vector{Int32}, Vector{readstat_measure_t},
    Vector{readstat_alignment_t}}}, Int64}

_default_metastyles() =
    Dict{Symbol, Symbol}([:file_label, :notes, :label, :vallabel].=>:note)

"""
    ReadStatTable{Cols} <: Tables.AbstractColumns

A `Tables.jl`-compatible column table that collects data read from or written to
a Stata, SAS or SPSS file processed with the `ReadStat` C library.
File-level and variable-level metadata can be retrieved and modified
via methods compatible with `DataAPI.jl`.
For a `ReadStatTable` constructed by [`readstat`](@ref),
`Cols` is either `ReadStatColumns` or `ChainedReadStatColumns`
depending on whether multiple threads are used for parsing the data file.
For a `ReadStatTable` constructed for [`writestat`](@ref),
`Cols` is allowed to be a column table type for any `Tables.jl`-compatible table.
See also [`ReadStatMeta`](@ref) and [`ReadStatColMeta`](@ref) for the included metadata.
"""
struct ReadStatTable{Cols} <: Tables.AbstractColumns
    columns::Cols
    names::Vector{Symbol}
    lookup::Dict{Symbol, Int}
    vallabels::Dict{Symbol, Dict}
    hasmissing::Vector{Bool}
    meta::ReadStatMeta
    colmeta::ColMetaVec
    styles::Dict{Symbol, Symbol}
    function ReadStatTable()
        columns = ReadStatColumns()
        names = Symbol[]
        lookup = Dict{Symbol, Int}()
        vallabels = Dict{Symbol, Dict}()
        hasmissing = Vector{Bool}()
        meta = ReadStatMeta()
        colmeta = ReadStatColMetaVec()
        styles = _default_metastyles()
        return new{ReadStatColumns}(columns, names, lookup, vallabels, hasmissing, meta, colmeta, styles)
    end
    function ReadStatTable(columns, names::Vector{Symbol},
            vallabels::Dict{Symbol, Dict}, hasmissing::Vector{Bool},
            meta::ReadStatMeta, colmeta::ColMetaVec,
            styles::Dict{Symbol, Symbol} = _default_metastyles())
        Tables.istable(columns) ||
            columns isa Union{ReadStatColumns, ChainedReadStatColumns} ||
                throw(ArgumentError("columns of type $(typeof(columns)) is not accepted"))
        lookup = Dict{Symbol, Int}(n=>i for (i, n) in enumerate(names))
        N = length(columns)
        length(lookup) == N ||
            throw(ArgumentError("column names are not unique"))
        length(hasmissing) == N ||
            throw(ArgumentError("length of hasmissing does not match the number of columns"))
        length(colmeta) == N ||
            throw(ArgumentError("length of colmeta does not match the number of columns"))
        return new{typeof(columns)}(columns, names, lookup, vallabels, hasmissing, meta, colmeta, styles)
    end
end

# Accessor functions that are not intended to be exported
_columns(tb::ReadStatTable) = getfield(tb, :columns)
_names(tb::ReadStatTable) = getfield(tb, :names)
_lookup(tb::ReadStatTable) = getfield(tb, :lookup)
_vallabels(tb::ReadStatTable) = getfield(tb, :vallabels)
_hasmissing(tb::ReadStatTable) = getfield(tb, :hasmissing)
_meta(tb::ReadStatTable) = getfield(tb, :meta)
_colmeta(tb::ReadStatTable) = getfield(tb, :colmeta)
@inline _colmeta(tb::ReadStatTable, key::Symbol) =
    getproperty(_colmeta(tb), key)
@inline _colmeta(tb::ReadStatTable, key::AbstractString) =
    getproperty(_colmeta(tb), Symbol(key))
Base.@propagate_inbounds _colmeta(tb::ReadStatTable, col, key) =
    _colmeta(tb, key)[Tables.columnindex(tb, col)]
_styles(tb::ReadStatTable) = getfield(tb, :styles)

Base.@propagate_inbounds _colmeta!(tb::ReadStatTable, col, key, v) =
    _colmeta(tb, key)[Tables.columnindex(tb, col)] = v

# getcolumn without applying value labels
Base.@propagate_inbounds function getcolumnfast(tb::ReadStatTable{ReadStatColumns}, i::Int)
    cols = _columns(tb)
    m, n = getfield(cols, 1)[i]
    if m === 2
        return getfield(cols, 2)[n]
    elseif m === 3
        # Using skipmissing would make the entire getcolumn slightly slower
        return getfield(cols, 3)[n]
    elseif m === 4
        return _hasmissing(tb)[i] ? getfield(cols, 4)[n] : parent(getfield(cols, 4)[n])
    elseif m === 5
        return _hasmissing(tb)[i] ? getfield(cols, 5)[n] : parent(getfield(cols, 5)[n])
    elseif m === 6
        return _hasmissing(tb)[i] ? getfield(cols, 6)[n] : parent(getfield(cols, 6)[n])
    elseif m === 7
        return _hasmissing(tb)[i] ? getfield(cols, 7)[n] : parent(getfield(cols, 7)[n])
    elseif m === 8
        return _hasmissing(tb)[i] ? getfield(cols, 8)[n] : parent(getfield(cols, 8)[n])
    elseif m === 9
        return _hasmissing(tb)[i] ? getfield(cols, 9)[n] : parent(getfield(cols, 9)[n])
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
    elseif m === 16
        return getfield(cols, 16)[n]
    elseif m === 17
        return getfield(cols, 17)[n]
    end
end

Base.@propagate_inbounds function getcolumnfast(tb::ReadStatTable{ChainedReadStatColumns}, i::Int)
    cols = _columns(tb)
    m, n = getfield(cols, 1)[i]
    Base.Cartesian.@nif(
        24, # 23 ifs and 1 else
        i -> m === i+1,
        i -> getfield(cols, i+1)[n],
        i -> error("invalid index $m")
    )
end

Base.@propagate_inbounds getcolumnfast(tb::ReadStatTable, i::Int) =
    Tables.getcolumn(_columns(tb), i)

Base.@propagate_inbounds function Tables.getcolumn(tb::ReadStatTable, i::Int)
    lblname = _colmeta(tb, i, :vallabel)
    col = getcolumnfast(tb, i)
    if lblname === Symbol()
        return col
    else
        # Value labels might be missing despite their name existing in metadata
        lbls = get(_vallabels(tb), lblname, nothing)
        return lbls === nothing ? col : LabeledArray(refarray(col), lbls)
    end
end

Base.@propagate_inbounds Tables.getcolumn(tb::ReadStatTable, n::Symbol) =
    Tables.getcolumn(tb, _lookup(tb)[n])

# Avoid directly modifying names
Tables.columnnames(tb::ReadStatTable) = copy(_names(tb))

Base.getindex(tb::ReadStatTable, n::String) = Tables.getcolumn(tb, Symbol(n))

# This method does not handle value labels
Base.@propagate_inbounds Base.getindex(tb::ReadStatTable{<:ColumnsOrChained}, r, c) =
    getindex(_columns(tb), r, Tables.columnindex(tb, c))

Base.@propagate_inbounds Base.setindex!(tb::ReadStatTable{<:ColumnsOrChained}, val, r, c) =
    setindex!(_columns(tb), val, r, Tables.columnindex(tb, c))

function _geteltype(tb::ReadStatTable{ReadStatColumns}, i)
    T = eltype(Tables.getcolumn(tb, i))
    if T === Union{Int8, Missing}
        _hasmissing(tb)[i] || return Int8
    elseif T <: LabeledValue && T.parameters[1] === Union{Int8, Missing}
        _hasmissing(tb)[i] || return LabeledValue{Int8, T.parameters[2]}
    end
    return T
end

_geteltype(tb::ReadStatTable, i) = eltype(Tables.getcolumn(tb, i))

Tables.schema(tb::ReadStatTable) =
    Tables.Schema{(_names(tb)...,), Tuple{ntuple(i->_geteltype(tb,i), length(tb))...}}()

Tables.columnindex(::ReadStatTable, i::Int) = i
Tables.columnindex(tb::ReadStatTable, n::Symbol) = _lookup(tb)[n]
Tables.columnindex(tb::ReadStatTable, n::String) = Tables.columnindex(tb, Symbol(n))
Tables.columntype(tb::ReadStatTable, n::Symbol) =
    (i = get(_lookup(tb), n, 0); i === 0 ? Union{} : _geteltype(tb, i))

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

metadatasupport(::Type{<:ReadStatTable}) = (read=true, write=true)
colmetadatasupport(::Type{<:ReadStatTable}) = (read=true, write=true)

"""
    metastyle(tb::ReadStatTable, [key::Union{Symbol, AbstractString}])

Return the specified style(s) of all metadata for table `tb`.
If a metadata `key` is specified, only the style for the associated metadata are returned.
By default, metadata on labels and notes have the `:note` style;
all other metadata have the `:default` style.

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
metadatakeys(::ReadStatTable) = ("row_count", "var_count", "creation_time", "modified_time",
    "file_format_version", "file_format_is_64bit", "compression", "endianness",
    "table_name", "file_label", "file_encoding", "notes", "file_ext")

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
colmetadatakeys(::ReadStatTable, ::ColumnIndex) = ("label", "format", "type",
    "vallabel", "storage_width", "display_width", "measure", "alignment")
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

"""
    getvaluelabels(tb::ReadStatTable)
    getvaluelabels(tb::ReadStatTable, name::Symbol)

Return a dictionary of all value label dictionaries contained in `tb`
obtained from the data file.
Return a specific dictionary of value labels if a `name` is specified.

Each dictionary of value labels is associated with a name
that may appear in the variable-level metadata under the key `vallabel`
for identifying the dictionary of value labels attached to each data column.
The same dictionary may be associated with multiple data columns.
Modifying the metadata value of `vallabel` for a data column
switches the associated value labels for the data column.
If the metadata value is set to `Symbol("")`,
the data column is not associated with any value label.
"""
getvaluelabels(tb::ReadStatTable) = _vallabels(tb)
getvaluelabels(tb::ReadStatTable, name::Symbol) = _vallabels(tb)[name]
