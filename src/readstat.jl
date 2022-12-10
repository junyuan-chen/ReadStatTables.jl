"""
    ColumnSelector

A type union for values accepted by [`readstat`](@ref)
for selecting a single column or multiple columns.
The accepted values can be of type [`ColumnIndex`](@ref),
a `UnitRange` of integers, an array or a set of [`ColumnIndex`](@ref).
"""
const ColumnSelector = Union{ColumnIndex, UnitRange, AbstractArray, AbstractSet}

"""
    readstat(filepath; kwargs...)

Return a [`ReadStatTable`](@ref) that collects data (including metadata)
from a supported data file located at `filepath`.

# Accepted File Extensions
- Stata: `.dta`.
- SAS: `.sas7bdat` and `.xpt`.
- SPSS: `.sav` and `por`.

# Keywords
- `usecols::Union{ColumnSelector, Nothing} = nothing`: only collect data from the specified columns (variables); collect all columns if `usecols=nothing`.
- `row_limit::Union{Integer, Nothing} = nothing`: restrict the total number of rows to be read; read all rows if `row_limit=nothing`.
- `row_offset::Integer = 0`: skip the specified number of rows.
- `convert_datetime::Bool = true`: convert data from any column with a recognized date/time format to `Date` or `DateTime`.
- `useinlinestring::Bool = true`: use a fixed-width string type that can be stored inline for any string variable with width below 32.
- `pool_thres::Integer = 500`: use `PooledArray` for any string variable that does not have a fixed-width string type if the number of unique values does not exceed `pool_thres`; a non-positive value avoids using `PooledArray`.
- `file_encoding::Union{String, Nothing} = nothing`: manually specify the file character encoding; need to be an `iconv`-compatible name.
- `handler_encoding::Union{String, Nothing} = nothing`: manually specify the handler character encoding; default to UTF-8.
"""
function readstat(filepath;
        usecols::Union{ColumnSelector, Nothing} = nothing,
        row_limit::Union{Integer, Nothing} = nothing,
        row_offset::Integer = 0,
        convert_datetime::Bool = true,
        useinlinestring::Bool = true,
        pool_thres::Integer = 500,
        file_encoding::Union{String, Nothing} = nothing,
        handler_encoding::Union{String, Nothing} = nothing)

    # Do not restrict argument type of filepath to allow AbstractPath
    filepath = string(filepath)
    typeof(usecols) <: ColumnIndex && (usecols = (usecols,))
    if !(typeof(usecols) <: Union{UnitRange, Nothing})
        usecols = Set{Union{Int,Symbol}}(
            idx isa Integer ? Int(idx) : Symbol(idx) for idx in usecols)
    end
    ctx = _parse_all(filepath, usecols, row_limit, row_offset,
        useinlinestring, pool_thres, file_encoding, handler_encoding)
    tb = ctx.tb
    cols = _columns(tb)
    m = _meta(tb)
    ext = m.file_ext
    dtformats = dt_formats[ext]
    isdta = ext == ".dta"
    if convert_datetime
        @inbounds for i in 1:ncol(tb)
            format = _colmeta(tb, i, :format)
            isdta && (format = first(format, 3))
            dtpara = get(dtformats, format, nothing)
            if dtpara !== nothing
                epoch, delta = dtpara
                col0 = cols[i]
                col = parse_datetime(col0, epoch, delta, _hasmissing(tb)[i])
                if epoch isa Date
                    push!(cols.date, col)
                    cols.index[i] = (8, length(cols.date))
                    empty!(col0)
                elseif epoch isa DateTime
                    push!(cols.time, col)
                    cols.index[i] = (9, length(cols.time))
                    empty!(col0)
                end
            end
        end
    end
    return tb
end

"""
    readstatmeta(filepath; kwargs...)

Return a [`ReadStatMeta`](@ref) that collects file-level metadata
without reading the full data
from a supported data file located at `filepath`.

# Accepted File Extensions
- Stata: `.dta`.
- SAS: `.sas7bdat` and `.xpt`.
- SPSS: `.sav` and `por`.

# Keywords
- `file_encoding::Union{String, Nothing} = nothing`: manually specify the file character encoding; need to be an `iconv`-compatible name.
- `handler_encoding::Union{String, Nothing} = nothing`: manually specify the handler character encoding; default to UTF-8.
"""
function readstatmeta(filepath;
        file_encoding::Union{String, Nothing} = nothing,
        handler_encoding::Union{String, Nothing} = nothing)
    filepath = string(filepath)
    ext = lowercase(splitext(filepath)[2])
    parse_ext = get(ext2parser, ext, nothing)
    parse_ext === nothing && throw(ArgumentError("file extension $ext is not supported"))
    m = ReadStatMeta()
    m.file_ext = ext
    ctx = Ref{ReadStatMeta}(m)
    parser = parser_init()
    set_metadata_handler(parser, @cfunction(handle_metadata!,
        readstat_handler_status, (Ptr{Cvoid}, Ref{ReadStatMeta})))
    set_note_handler(parser, @cfunction(handle_note!,
        readstat_handler_status, (Cint, Cstring, Ref{ReadStatMeta})))
    file_encoding === nothing ||
        _error(set_file_character_encoding(parser, file_encoding))
    handler_encoding === nothing ||
        _error(set_handler_character_encoding(parser, handler_encoding))
    _error(parse_ext(parser, filepath, ctx))
    parser_free(parser)
    return m
end
