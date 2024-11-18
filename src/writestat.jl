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

function _set_vallabels!(colmetavec, vallabels, lblname, refpoolaslabel, names, col, i)
    lbls = get(vallabels, lblname, nothing)
    lblname === Symbol() && (lblname = Symbol(names[i]))
    if col isa LabeledArrOrSubOrReshape
        if lbls === nothing
            vallabels[lblname] = getvaluelabels(col)
        else
            lbls == getvaluelabels(col) ||
                error("value label name $lblname is not unique")
        end
        colmetavec.vallabel[i] = lblname
    elseif lblname === Symbol() || lbls === nothing
        pool = refpool(col)
        if pool === nothing || !refpoolaslabel
            # Any specified vallabel is ignored as labels do not exist
            colmetavec.vallabel[i] = Symbol()
        else
            lbls = Dict{Union{Int32,Char},String}(Int32(k) => v for (k, v) in pairs(pool))
            vallabels[lblname] = lbls
            colmetavec.type[i] = rstype(nonmissingtype(eltype(refarray(col))))
            colmetavec.vallabel[i] = lblname
        end
    end
    return get(vallabels, lblname, nothing) # Return the labels
end

"""
    ReadStatTable(table, ext::AbstractString; kwargs...)

Construct a `ReadStatTable` by wrapping a `Tables.jl`-compatible column table
for a supported file format with extension `ext`.
An attempt is made to collect table-level or column-level metadata with a key
that matches a metadata field in [`ReadStatMeta`](@ref) or [`ReadStatColMeta`](@ref)
via the `metadata` and `colmetadata` interface defined by `DataAPI.jl`.

This method is used by [`writestat`](@ref) when the provided `table`
is not already a `ReadStatTable`.
Hence, it is useful for gaining fine-grained control over the content to be written.
Metadata may be manually specified with keyword arguments.

# Keywords
- `copycols::Bool = true`: copy data columns to `ReadStatColumns`; this is required for writing columns of date/time values (that are not already represented by numeric values).
- `refpoolaslabel::Bool = true`: generate value labels for columns of an array type that makes use of `DataAPI.refpool` (e.g., `CategoricalArray` and `PooledArray`).
- `vallabels::Dict{Symbol, Dict} = Dict{Symbol, Dict}()`: a dictionary of all value label dictionaries indexed by their names.
- `hasmissing::Vector{Bool} = Vector{Bool}()`: a vector of indicators for whether any missing value present in the corresponding column; irrelavent for writing tables.
- `meta::ReadStatMeta = ReadStatMeta()`: file-level metadata.
- `colmeta::ColMetaVec = ReadStatColMetaVec()`: variable-level metadata stored in a `StructArray` of `ReadStatColMeta`s; values are always overwritten.
- `varformat::Union{Dict{Symbol,String}, Nothing} = nothing`: specify variable-level format for certain variables with the key being the variable name (as `Symbol`) and value being the format string.
- `styles::Dict{Symbol, Symbol} = _default_metastyles()`: metadata styles.
- `maxdispwidth::Integer = 60`: maximum `display_width` set for any variable.
"""
function ReadStatTable(table, ext::AbstractString;
        copycols::Bool = true,
        refpoolaslabel::Bool = true,
        vallabels::Dict{Symbol, Dict} = Dict{Symbol, Dict}(),
        hasmissing::Vector{Bool} = Vector{Bool}(),
        meta::ReadStatMeta = ReadStatMeta(),
        colmeta::ColMetaVec = ReadStatColMetaVec(),
        varformat::Union{Dict{Symbol,String}, Nothing} = nothing,
        styles::Dict{Symbol, Symbol} = _default_metastyles(),
        maxdispwidth::Integer = 60,
        kwargs...)
    Tables.istable(table) && Tables.columnaccess(table) || throw(
        ArgumentError("table of type $(typeof(table)) is not accepted"))
    colmetadatasupport(typeof(table)).read ||
        error("Require a table type that supports reading column-level metadata")
    srccols = Tables.columns(table)
    cols = copycols ? ReadStatColumns() : srccols
    names = Symbol[columnnames(srccols)...]
    N = length(names)
    length(hasmissing) == N || (hasmissing = fill(true, N))
    # Only overide the default values for fields relevant to writer behavior
    meta.row_count = Tables.rowcount(srccols)
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
    # Any value in colmeta is overwritten
    length(colmeta) == N || resize!(colmeta, N)
    for i in 1:N
        col = Tables.getcolumn(srccols, i)
        colmeta.label[i] = colmetadata(table, i, "label", "")
        colmeta.format[i] = format = colmetadata(table, i, "format", "")
        # Override the format with any value set by varformat
        if varformat !== nothing
            mformat = get(varformat, names[i], nothing)
            if mformat !== nothing
                colmeta.format[i] = format = mformat
            end
        end
        # Lazily convert any Date/DateTime column
        if eltype(col) <: Union{Date, DateTime, Missing}
            copycols || error("to write tables with date/time columns, copycols must be true")
            ext == ".dta" && (format = first(format, 3))
            dtpara = get(dt_formats[ext], format, nothing)
            if dtpara === nothing
                if Date <: eltype(col)
                    epoch = ext_date_epoch[ext]
                    delta = ext_default_date_delta[ext]
                    colmeta.format[i] = ext_default_date_format[ext]
                else
                    epoch = ext_time_epoch[ext]
                    delta = ext_default_time_delta[ext]
                    colmeta.format[i] = ext_default_time_format[ext]
                end
            else
                epoch, delta = dtpara
                nonmissingtype(eltype(col)) == typeof(epoch) ||
                    error("a date/datetime column must have a date/datetime format")
            end
            col = datetime2num(col, Num2DateTime(epoch, delta))
        end
        if col isa LabeledArrOrSubOrReshape || refpool(col) !== nothing && refpoolaslabel
            type = rstype(nonmissingtype(eltype(refarray(col))))
        else
            type = rstype(nonmissingtype(eltype(col)))
        end
        colmeta.type[i] = colmetadata(table, i, "type", type)
        lblname = colmetadata(table, i, "vallabel", Symbol())
        colmeta.vallabel[i] = lblname
        lbls = _set_vallabels!(colmeta, vallabels, lblname, refpoolaslabel, names, col, i)
        # type may have been modified based on refarray
        type = colmeta.type[i]
        if type === READSTAT_TYPE_STRING
            width = _readstat_string_width(col)
        elseif type === READSTAT_TYPE_DOUBLE
            # Only needed for .xpt files
            width = Csize_t(8)
        else
            width = Csize_t(0)
        end
        colmeta.storage_width[i] = width
        if lbls === nothing
            colmeta.display_width[i] = max(min(Cint(width), Cint(maxdispwidth)), Cint(9))
        else
            colmeta.display_width[i] =
                max(min(Cint(maximum(length, values(lbls))), Cint(maxdispwidth)), Cint(9))
        end
        colmeta.measure[i] = READSTAT_MEASURE_UNKNOWN
        colmeta.alignment[i] = READSTAT_ALIGNMENT_UNKNOWN
        if copycols
            M = length(col)
            if type == READSTAT_TYPE_INT8
                tarcol = Vector{Union{Int8, Missing}}(undef, M)
            elseif type == READSTAT_TYPE_INT16
                tarcol = SentinelVector{Int16}(undef, M, typemin(Int16), missing)
            elseif type == READSTAT_TYPE_INT32
                tarcol = SentinelVector{Int32}(undef, M, typemin(Int32), missing)
            elseif type == READSTAT_TYPE_FLOAT
                tarcol = SentinelVector{Float32}(undef, M)
            elseif type == READSTAT_TYPE_DOUBLE
                tarcol = SentinelVector{Float64}(undef, M)
            else # READSTAT_TYPE_STRING
                T = eltype(col)
                if T in (String3, String7, String15, String31,
                        String63, String127, String255)
                    tarcol = Vector{T}(undef, M)
                else
                    tarcol = Vector{String}(undef, M)
                end
            end
            if col isa LabeledArrOrSubOrReshape || refpool(col) !== nothing && refpoolaslabel
                copyto!(tarcol, refarray(col))
            else
                copyto!(tarcol, col)
            end
            push!(cols, tarcol)
        end
    end
    return ReadStatTable(cols, names, vallabels, hasmissing, meta, colmeta, styles)
end

"""
    ReadStatTable(table::ReadStatTable, ext::AbstractString; kwargs...)

Construct a `ReadStatTable` from an existing `ReadStatTable`
for a supported file format with extension `ext`.

# Keywords
- `update_width::Bool = true`: determine the storage width for each string variable by checking the actual data columns instead of any existing metadata value.
"""
function ReadStatTable(table::ReadStatTable, ext::AbstractString;
        update_width::Bool = true, kwargs...)
    meta = _meta(table)
    meta.row_count = nrow(table)
    meta.var_count = ncol(table)
    colmeta = _colmeta(table)
    vallabels = _vallabels(table)
    names = _names(table)
    if ext != meta.file_ext
        meta.file_ext = ext
        meta.file_format_version = get(default_file_format_version, ext, -1)
        fill!(colmeta.format, "")
    end
    for i in 1:ncol(table)
        # ! Assume no need to re-encode columns with date/time values
        col = Tables.getcolumn(table, i)
        lblname = colmeta.vallabel[i]
        _set_vallabels!(colmeta, vallabels, lblname, false, names, col, i)
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
- SAS: `.sas7bdat` and `.xpt` (Note: SAS may not recognize the produced `.sas7bdat` files due to a known limitation with ReadStat.)
- SPSS: `.sav` and `por`

# Conversion

For data values, Julia objects are converted to the closest `ReadStat` type
for either numerical values or strings.
However, depending on the file format of the output file,
a data column may be written in a different type
when the closest `ReadStat` type is not supported.

For metadata, if the user-provided `table` is not a [`ReadStatTable`](@ref),
an attempt will be made to collect table-level or column-level metadata with a key
that matches a metadata field in [`ReadStatMeta`](@ref) or [`ReadStatColMeta`](@ref)
via the `metadata` and `colmetadata` interface defined by `DataAPI.jl`.
If the `table` is a [`ReadStatTable`](@ref),
then the associated metadata will be written as long as their values
are compatible with the format of the output file.
Value labels associated with a [`LabeledArray`](@ref) are always preserved
even when the name of the dictionary of value labels is not specified in metadata
(column name will be used by default).
If a column is of an array type that makes use of `DataAPI.refpool`
(e.g., `CategoricalArray` and `PooledArray`),
value labels will be generated automatically by default
(with keyword `refpoolaslabel` set to be `true`)
and the underlying numerical reference values instead of the values returned by `getindex`
are written to files (with value labels attached).
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
