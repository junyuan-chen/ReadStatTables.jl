const ext2writer = Dict{String, Any}(
    ".dta" => begin_writing_dta,
    ".sav" => begin_writing_sav,
    ".por" => begin_writing_por,
    ".sas7bdat" => begin_writing_sas7bdat,
    ".xpt" => begin_writing_xport
)

# Default mapping from julia types to ReadStat types
rstype(::Type{Int8}) = READSTAT_TYPE_INT8
rstype(::Type{Int16}) = READSTAT_TYPE_INT16
rstype(::Type{<:Integer}) = READSTAT_TYPE_INT32
rstype(::Type{Float32}) = READSTAT_TYPE_FLOAT
rstype(::Type{<:Real}) = READSTAT_TYPE_DOUBLE
rstype(::Type{<:AbstractString}) = READSTAT_TYPE_STRING
rstype(type) = error("element type $type is not supported")

# Stata .dta format before version 118 does not support Unicode for string variables
const default_file_format_version = Dict{String, Int}(
    ".dta" => 118,
    ".xpt" => 5,
    ".sav" => 2,
)

# Accepted maximum length for strings varies by the file format and version
function _readstat_string_width(col)
    if eltype(col) <: Union{InlineString, Missing}
        return Csize_t(sizeof(eltype(col))-1)
    else
        maxlen = maximum(col) do str
            ismissing(str) ? 0 : ncodeunits(str)
        end
        return Csize_t(maxlen)
    end
end

function ReadStatTable(table, ext::AbstractString;
        vallabels::Dict{Symbol, Dict} = Dict{Symbol, Dict}(),
        hasmissing::Vector{Bool} = Vector{Bool}(),
        meta::ReadStatMeta = ReadStatMeta(),
        colmeta::ColMetaVec = ReadStatColMetaVec(),
        styles::Dict{Symbol, Symbol} = _default_metastyles(),
        kwargs...)
    Tables.istable(table) && Tables.columnaccess(table) || throw(
        ArgumentError("table of type $(typeof(table)) is not accepted"))
    cols = Tables.columns(table)
    names = map(Symbol, columnnames(cols))
    N = length(names)
    length(hasmissing) == N || (hasmissing = fill(true, N))
    # Only overide the default values for fields relevant to writer behavior
    meta.row_count = Tables.rowcount(cols)
    meta.var_count = N
    if ext != meta.file_ext
        meta.file_ext = ext
        meta.file_format_version = get(default_file_format_version, ext, -1)
        # Throw away any existing format string for now
        fill!(colmeta.format, "")
    end
    # Propagate the three label-like metadata attributes if present
    if metadatasupport(typeof(table)).read
        #! Need more tests on notes
        notes = metadata(table, "notes", nothing)
        if notes !== nothing
            meta.notes = notes isa AbstractString ? [notes] : notes
        end
        meta.file_label = metadata(table, "file_label", "")
        # Only used for .xpt files
        meta.table_name = metadata(table, "table_name", "")
    end
    # Assume colmeta is manually specified if the length matches
    # Otherwise, any value in colmeta is overwritten
    # The metadata interface is absent before DataFrames.jl v1.4 which requires Julia v1.6
    if length(colmeta) != N && colmetadatasupport(typeof(table)).read
        resize!(colmeta, N)
        for i in 1:N
            col = Tables.getcolumn(cols, i)
            colmeta.label[i] = colmetadata(table, i, "label", "")
            #! To do: handle format for DateTime columns
            colmeta.format[i] = colmetadata(table, i, "format", "")
            #! To do: ensure that an array of type such as CategoricalArray works
            #! Consider constructing value labels for such arrays
            if col isa LabeledArrOrSubOrReshape
                type = rstype(nonmissingtype(eltype(refarray(col))))
            else
                type = rstype(nonmissingtype(eltype(col)))
            end
            colmeta.type[i] = colmetadata(table, i, "type", type)
            lblname = colmetadata(table, i, "vallabel", Symbol())
            colmeta.vallabel[i] = lblname
            if col isa LabeledArrOrSubOrReshape
                lblname == Symbol() && (lblname = Symbol(names[i]))
                lbls = get(vallabels, lblname, nothing)
                if lbls === nothing
                    vallabels[lblname] = getvaluelabels(col)
                    colmeta.vallabel[i] = lblname
                elseif lbls != getvaluelabels(col)
                    error("value label name $lblname is not unique")
                end
            end
            if type === READSTAT_TYPE_STRING
                width = _readstat_string_width(col)
            elseif type === READSTAT_TYPE_DOUBLE
                # Only needed for .xpt files
                width = Csize_t(8)
            else
                width = Csize_t(0)
            end
            colmeta.storage_width[i] = width
            colmeta.display_width[i] = max(Cint(width), Cint(9))
            colmeta.measure[i] = READSTAT_MEASURE_UNKNOWN
            colmeta.alignment[i] = READSTAT_ALIGNMENT_UNKNOWN
        end
    end
    return ReadStatTable(cols, names, vallabels, hasmissing, meta, colmeta, styles)
end

function ReadStatTable(table::ReadStatTable, ext::AbstractString;
        update_width::Bool = true, kwargs...)
    meta = _meta(table)
    meta.row_count = nrow(table)
    meta.var_count = ncol(table)
    colmeta = _colmeta(table)
    if ext != meta.file_ext
        meta.file_ext = ext
        meta.file_format_version = get(default_file_format_version, ext, -1)
        fill!(colmeta.format, "")
    end
    for i in 1:ncol(table)
        col = Tables.getcolumn(table, i)
        if update_width
            type = colmeta.type[i]
            if type === READSTAT_TYPE_STRING
                colmeta.storage_width[i] = _readstat_string_width(col)
            elseif type === READSTAT_TYPE_DOUBLE
                # Only needed for .xpt files
                colmeta.storage_width[i] = Csize_t(8)
            end
        end
    end
    return table
end

"""
    writestat(filepath, table; ext = lowercase(splitext(filepath)[2]), kwargs...)

Write a `Tables.jl`-compatible `table` to `filepath` as a data file supported by `ReadStat`.
File format is determined based on the extension contained in `filepath`
and may be overriden by the `ext` keyword.

Any user-provided `table` is converted to a [`ReadStatTable`](@ref) first
before being handled by a `ReadStat` writer.
Therefore, to gain fine-grained control over the content to be written,
especially for metadata,
one may directly work with a [`ReadStatTable`](@ref)
(possibly converted from another table type such as `DataFrame` from `DataFrames.jl`)
before passing it to `writestat`.
Alternatively, one may pass any keyword argument accepted by
a constructor of [`ReadStatTable`](@ref) to `writestat`.
The actual [`ReadStatTable`](@ref) handled by the writer is returned
after the writer finishes.

# Supported File Formats
- Stata: `.dta`
- SAS: `.sas7bdat` and `.xpt` (Note: `SAS` may not recognize the produced `.sas7bdat` files due to a known limitation with `ReadStat`.)
- SPSS: `.sav` and `por`

# Conversion

For data values, Julia objects are converted to the closest `ReadStat` type
for either numerical values or strings.
However, depending on the file format of the output file,
a data column may be written in a different type
when the closest `ReadStat` type is not supported.

For metadata, if the user-provided `table` is not a [`ReadStatTable`](@ref),
an attempt will be made to collect
any table-level or column-level metadata with a key
that matches a metadata field in [`ReadStatMeta`](@ref) or [`ReadStatColMeta`](@ref)
via the `metadata` and `colmetadata` interface defined by `DataAPI.jl`.
If the `table` is a [`ReadStatTable`](@ref),
then the associated metadata will be written as long as their values
are compatible with the format of the output file.
"""
function writestat(filepath, table; ext = lowercase(splitext(filepath)[2]), kwargs...)
    filepath = string(filepath)
    write_ext = get(ext2writer, ext, nothing)
    write_ext === nothing && throw(ArgumentError("file extension $ext is not supported"))
    tb = ReadStatTable(table, ext; kwargs...)
    io = open(filepath, "w")
    _write(io, ext, write_ext, tb)
    return tb
end
