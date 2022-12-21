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
rstype(::Type{Float32}) = READSTAT_TYPE_Float
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
        return Csize_t(sizeof(col))
    else
        maxlen = maximum(col) do str
            str === missing ? 0 : ncodeunits(str)
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
    end
    # Assume colmeta is manually specified if the length matches
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
            type = rstype(nonmissingtype(eltype(refarray(col))))
            colmeta.type[i] = colmetadata(table, i, "type", type)
            lblname = colmetadata(table, i, "vallabel", Symbol())
            colmeta.vallabel[i] = lblname
            if col isa LabeledArrOrSubOrReshape
                lbls = get(vallabels, lblname, nothing)
                if lbls === nothing
                    vallabels[lblname] = getvaluelabels(col)
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
            colmeta.display_width[i] = max(Cint(width), Cint(8))
            colmeta.measure[i] = READSTAT_MEASURE_UNKNOWN
            colmeta.alignment[i] = READSTAT_ALIGNMENT_UNKNOWN
        end
    end
    return ReadStatTable(cols, names, vallabels, hasmissing, meta, colmeta, styles)
end

function ReadStatTable(table::ReadStatTable{<:ColumnsOrChained}, ext::AbstractString;
        update_width::Bool=true,
        kwargs...)
    meta = _meta(table)
    meta.row_count = nrow(table)
    meta.var_count = ncol(table)
    if ext != meta.file_ext
        meta.file_ext = ext
        meta.file_format_version = get(default_file_format_version, ext, -1)
    end
    if update_width
        for i in 1:ncol(table)
            type = _colmeta(table, i, :type)
            if type === READSTAT_TYPE_STRING
                width = _readstat_string_width(col)
            elseif type === READSTAT_TYPE_DOUBLE
                # Only needed for .xpt files
                width = Csize_t(8)
            else
                width = Csize_t(0)
            end
            colmeta.storage_width[i] = width
        end
    end
    return table
end

function writestat(filepath, table;
        ext = lowercase(splitext(filepath)[2]),
        kwargs...)
    filepath = string(filepath)
    write_ext = get(ext2writer, ext, nothing)
    write_ext === nothing && throw(ArgumentError("file extension $ext is not supported"))
    tb = ReadStatTable(table, ext; kwargs...)
    io = open(filepath, "w")
    _write(io, ext, write_ext, tb)
    return tb
end
