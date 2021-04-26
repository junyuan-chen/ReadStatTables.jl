"""
    ReadStatMeta

A collection of metadata parsed from a data file.
"""
struct ReadStatMeta
    labels::Dict{Symbol, String}
    formats::Dict{Symbol, String}
    val_label_keys::Dict{Symbol, String}
    val_label_dict::Dict{String, Dict{Any,String}}
    filelabel::String
    timestamp::DateTime
    fileext::String
end

"""
    varlabels(m::ReadStatMeta)
    varlabels(tb::ReadStatTable)

Retrieve the variable labels as a dictionary indexed by variable names.
"""
varlabels(m::ReadStatMeta) = m.labels

"""
    varformats(m::ReadStatMeta)
    varformats(tb::ReadStatTable)

Retrieve the variable format strings as a dictionary indexed by variable names.
"""
varformats(m::ReadStatMeta) = m.formats

"""
    val_label_keys(m::ReadStatMeta)
    val_label_keys(tb::ReadStatTable)

Retrieve the names of the collections of value labels applied to each variable
as a dictionary indexed by variable names.
"""
val_label_keys(m::ReadStatMeta) = m.val_label_keys

"""
    val_label_dict(m::ReadStatMeta)
    val_label_dict(tb::ReadStatTable)

Retrieve all collections of value labels stored in the data file
as a dictionary indexed by the names of the collections.
Each collection of value labels itself is again a dictionary
that maps the values to the associated labels.
"""
val_label_dict(m::ReadStatMeta) = m.val_label_dict

"""
    filelabel(m::ReadStatMeta)
    filelabel(tb::ReadStatTable)

Retrieve the label of the data file.
"""
filelabel(m::ReadStatMeta) = m.filelabel

"""
    filetimestamp(m::ReadStatMeta)
    filetimestamp(tb::ReadStatTable)

Retrieve the time stamp of the data file. (Time zone is not handled.)
"""
filetimestamp(m::ReadStatMeta) = m.timestamp

"""
    fileext(m::ReadStatMeta)
    fileext(tb::ReadStatTable)

Retrieve the file extension of the data file.
"""
fileext(m::ReadStatMeta) = m.fileext

varlabels(::Nothing) = nothing
varformats(::Nothing) = nothing
val_label_keys(::Nothing) = nothing
val_label_dict(::Nothing) = nothing
filelabel(::Nothing) = nothing
filetimestamp(::Nothing) = nothing
fileext(::Nothing) = nothing

Base.show(io::IO, m::ReadStatMeta) = print(io, typeof(m).name.name)
function Base.show(io::IO, ::MIME"text/plain", m::ReadStatMeta)
    println(io, typeof(m).name.name, ':')
    println(io, "  variable labels:    ", m.labels)
    println(io, "  variable formats:   ", m.formats)
    println(io, "  value label names:  ", m.val_label_keys)
    println(io, "  value labels:       ", m.val_label_dict)
    println(io, "  file label:         ", m.filelabel)
    println(io, "  file timestamp:     ", m.timestamp)
    print(io,   "  file extension:     ", m.fileext)
end

"""
    ReadStatTable <: AbstractColumns

A `Tables.jl`-compatible column table that collects data
from a Stata, SAS or SPSS file.
"""
struct ReadStatTable <: Tables.AbstractColumns
    columns::Vector{AbstractVector}
    names::Vector{Symbol}
    lookup::Dict{Symbol, Int}
    meta::Union{ReadStatMeta, Nothing}
    function ReadStatTable(columns::Vector{AbstractVector}, names::Vector{Symbol}, meta=nothing)
        lookup = Dict{Symbol, Int}(n=>i for (i, n) in enumerate(names))
        return new(columns, names, lookup, meta)
    end
end

# Accessor functions that are not intended to be exported
_columns(tb::ReadStatTable) = getfield(tb, :columns)
_names(tb::ReadStatTable) = getfield(tb, :names)
_lookup(tb::ReadStatTable) = getfield(tb, :lookup)

"""
    getmeta(tb::ReadStatTable)

Retrieve the metadata parsed from a data file.
"""
getmeta(tb::ReadStatTable) = getfield(tb, :meta)

varlabels(tb::ReadStatTable) = varlabels(getmeta(tb))
varformats(tb::ReadStatTable) = varformats(getmeta(tb))
val_label_keys(tb::ReadStatTable) = val_label_keys(getmeta(tb))
val_label_dict(tb::ReadStatTable) = val_label_dict(getmeta(tb))
filelabel(tb::ReadStatTable) = filelabel(getmeta(tb))
filetimestamp(tb::ReadStatTable) = filetimestamp(getmeta(tb))
fileext(tb::ReadStatTable) = fileext(getmeta(tb))

Tables.getcolumn(tb::ReadStatTable, i::Int) = _columns(tb)[i]
Tables.getcolumn(tb::ReadStatTable, n::Symbol) = _columns(tb)[_lookup(tb)[n]]
Tables.columnnames(tb::ReadStatTable) = copy(_names(tb))

Tables.schema(tb::ReadStatTable) =
    Tables.Schema{(_names(tb)...,), Tuple{(eltype(col) for col in _columns(tb))...}}()

Tables.columnindex(tb::ReadStatTable, n::Symbol) = _lookup(tb)[n]
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
Base.haskey(tb::ReadStatTable, i::Int) = 0 < i <= length(_names(tb))

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
