"""
    ColumnSelector

A type union for values accepted by [`readstat`](@ref)
for selecting a single column or multiple columns.
The accepted values can be of type [`ColumnIndex`](@ref),
a `UnitRange` of integers, an array or a set of [`ColumnIndex`](@ref).
"""
const ColumnSelector = Union{ColumnIndex, UnitRange, AbstractArray, AbstractSet}

function _setntasks(ncells::Integer)
    nthd = Threads.nthreads()
    if ncells < 10_000
        return min(2, nthd)
    elseif ncells < 4_000_000
        return min(max(nthd÷2, 2), nthd)
    else
        return nthd
    end
end

const _supported_formats_str = """
    # Supported File Formats
    - Stata: `.dta`
    - SAS: `.sas7bdat` and `.xpt`
    - SPSS: `.sav` and `por`"""

"""
    readstat(filepath; kwargs...)

Return a [`ReadStatTable`](@ref) that collects data (including metadata)
from a supported data file located at `filepath`.

$_supported_formats_str

# Keywords
- `ext = lowercase(splitext(filepath)[2])`: extension of data file for choosing the parser.
- `usecols::Union{ColumnSelector, Nothing} = nothing`: only collect data from the specified columns (variables); collect all columns if `usecols=nothing`.
- `row_limit::Union{Integer, Nothing} = nothing`: restrict the total number of rows to be read; read all rows if `row_limit=nothing`.
- `row_offset::Integer = 0`: skip the specified number of rows.
- `ntasks::Union{Integer, Nothing} = nothing`: number of tasks spawned to read data file in concurrent chunks with multiple threads; with `ntasks` being `nothing` or smaller than 1, select a default value based on the size of data file and the number of threads available (`Threads.nthreads()`); not applicable to `.xpt` and `.por` files where row count is unknown from metadata.
- `convert_datetime::Bool = true`: convert data from any column with a recognized date/time format to `Date` or `DateTime`.
- `apply_value_labels::Bool = true`: apply value labels to the associated columns.
- `inlinestring_width::Integer = ext ∈ (".sav", ".por") ? 0 : 32`: use a fixed-width string type that can be stored inline for any string variable with width below `inlinestring_width` and `pool_width`; a non-positive value avoids using any inline string type; not recommended for SPSS files.
- `pool_width::Integer = 64`: only attempt to use `PooledArray` for string variables with width of at least 64.
- `pool_thres::Integer = 500`: do not use `PooledArray` for string variables if the number of unique values exceeds `pool_thres`; a non-positive value avoids using `PooledArray`.
- `file_encoding::Union{String, Nothing} = nothing`: manually specify the file character encoding; need to be an `iconv`-compatible name.
- `handler_encoding::Union{String, Nothing} = nothing`: manually specify the handler character encoding; default to UTF-8.
"""
function readstat(filepath;
        ext = lowercase(splitext(filepath)[2]),
        usecols::Union{ColumnSelector, Nothing} = nothing,
        row_limit::Union{Integer, Nothing} = nothing,
        row_offset::Integer = 0,
        ntasks::Union{Integer, Nothing} = nothing,
        convert_datetime::Bool = true,
        apply_value_labels::Bool = true,
        inlinestring_width::Integer = ext ∈ (".sav", ".por") ? 0 : 32,
        pool_width::Integer = 64,
        pool_thres::Integer = 500,
        file_encoding::Union{String, Nothing} = nothing,
        handler_encoding::Union{String, Nothing} = nothing)

    # Do not restrict argument type of filepath to allow AbstractPath
    filepath = string(filepath)
    parse_ext = get(ext2parser, ext, nothing)
    parse_ext === nothing && throw(ArgumentError("file extension $ext is not supported"))
    typeof(usecols) <: ColumnIndex && (usecols = (usecols,))
    if !(typeof(usecols) <: Union{UnitRange, Nothing})
        usecols = Set{Union{Int,Symbol}}(
            idx isa Integer ? Int(idx) : Symbol(idx) for idx in usecols)
    end
    row_limit === nothing || row_limit > 0 ||
        throw(ArgumentError("non-positive row_limit is not allowed"))
    row_offset < 0 && throw(ArgumentError("negative row_offset is not allowed"))
    pool_thres_max = Int(typemax(UInt16))
    pool_thres > pool_thres_max && throw(ArgumentError(
        "pool_thres greater than $pool_thres_max is not supported"))

    # row_count is not in metadata for some formats
    if ext ∈ (".xpt", ".por")
        ntasks = 1
    elseif ntasks === nothing || ntasks < 1
        ntasks = filesize(filepath) < 150_000 ? 1 : nothing
    end

    dtformats = dt_formats[ext]
    isdta = ext == ".dta"

    if ntasks == 1
        tb = _parse_all(filepath, ext, parse_ext, usecols, row_limit, row_offset,
            inlinestring_width, pool_width, pool_thres, file_encoding, handler_encoding)
    else
        m, names, cm, vlbls = _parse_allmeta(filepath, ext, parse_ext, usecols,
            file_encoding, handler_encoding)
        nrows = m.row_count - row_offset
        row_limit === nothing || (nrows = min(nrows, row_limit))
        if nrows < 2
            ntasks = 1
            tb = _parse_all(filepath, ext, parse_ext, usecols, row_limit, row_offset,
                inlinestring_width, pool_width, pool_thres, file_encoding, handler_encoding)
        else
            ncols = length(cm)
            ntasks === nothing && (ntasks = _setntasks(nrows * ncols))
            # Ensure that each task gets at least one row
            ntasks = min(nrows, ntasks)
            row_limits = fill(nrows÷ntasks, ntasks)
            row_limits[1] = nrows - (ntasks-1) * row_limits[1]
            row_offsets = Vector{Int}(undef, ntasks)
            row_offsets[1] = row_offset
            for i in 2:ntasks
                row_offsets[i] = row_offsets[i-1] + row_limits[i-1]
            end
            width_offset = isdta
            tbs = Vector{ReadStatTable{ReadStatColumns}}(undef, ntasks)
            @sync for i in 1:ntasks
                # Use @wkspawn from WorkerUtilities.jl in the future?
                Threads.@spawn begin
                    taskcols = ReadStatColumns()
                    @inbounds for j in 1:ncols
                        T = jltype(cm.type[j])
                        width = cm.storage_width[j]
                        _pushcolumn!(taskcols, T, row_limits[i], width, width_offset,
                            inlinestring_width, pool_width, pool_thres)
                    end
                    tasktb = ReadStatTable(taskcols, names, vlbls, fill(false, ncols), m, cm)
                    _parse_chunk!(tasktb, filepath, parse_ext, usecols, row_limits[i],
                        row_offsets[i], pool_thres, file_encoding, handler_encoding)
                    if convert_datetime
                        @inbounds for j in 1:ncols
                            format = cm.format[j]
                            isdta && (format = first(format, 3))
                            dtpara = get(dtformats, format, nothing)
                            if dtpara !== nothing
                                epoch, delta = dtpara
                                col0 = taskcols[j]
                                col = parse_datetime(col0, epoch, delta, _hasmissing(tasktb)[j])
                                if epoch isa Date
                                    push!(taskcols.date, col)
                                    taskcols.index[j] = (8, length(taskcols.date))
                                    empty!(col0)
                                elseif epoch isa DateTime
                                    push!(taskcols.time, col)
                                    taskcols.index[j] = (9, length(taskcols.time))
                                    empty!(col0)
                                end
                            end
                        end
                    end
                    tbs[i] = tasktb
                end
            end
            cols = ChainedReadStatColumns()
            hms = Vector{Bool}(undef, ncols)
            for i in 1:ncols
                hmsi = any(x->@inbounds(_hasmissing(x)[i]), tbs)
                @inbounds hms[i] = hmsi
                _pushchain!(cols, hmsi, map(x->@inbounds(_columns(x)[i]), tbs))
            end
            apply_value_labels || fill!(cm.vallabel, Symbol())
            return ReadStatTable(cols, names, vlbls, hms, m, cm)
        end
    end

    if ntasks == 1 && convert_datetime
        cols = _columns(tb)
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
    apply_value_labels || fill!(_colmeta(tb, :vallabel), Symbol())
    return tb
end

"""
    readstatmeta(filepath; kwargs...)

Return a [`ReadStatMeta`](@ref) that collects file-level metadata
without reading the full data
from a supported data file located at `filepath`.
See also [`readstatallmeta`](@ref).

$_supported_formats_str

# Keywords
- `ext = lowercase(splitext(filepath)[2])`: extension of data file for choosing the parser.
- `file_encoding::Union{String, Nothing} = nothing`: manually specify the file character encoding; need to be an `iconv`-compatible name.
- `handler_encoding::Union{String, Nothing} = nothing`: manually specify the handler character encoding; default to UTF-8.
"""
function readstatmeta(filepath;
        ext = lowercase(splitext(filepath)[2]),
        file_encoding::Union{String, Nothing} = nothing,
        handler_encoding::Union{String, Nothing} = nothing)
    filepath = string(filepath)
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

"""
    readstatallmeta(filepath; kwargs...)

Return all metadata including value labels without reading the full data
from a supported data file located at `filepath`.
The four returned objects are for file-level metadata,
variable names, variable-level metadata and value labels respectively.
See also [`readstatmeta`](@ref).

$_supported_formats_str

# Keywords
- `ext = lowercase(splitext(filepath)[2])`: extension of data file for choosing the parser.
- `usecols::Union{ColumnSelector, Nothing} = nothing`: only collect variable-level metadata from the specified columns (variables); collect all columns if `usecols=nothing`.
- `file_encoding::Union{String, Nothing} = nothing`: manually specify the file character encoding; need to be an `iconv`-compatible name.
- `handler_encoding::Union{String, Nothing} = nothing`: manually specify the handler character encoding; default to UTF-8.
"""
function readstatallmeta(filepath;
        ext = lowercase(splitext(filepath)[2]),
        usecols::Union{ColumnSelector, Nothing} = nothing,
        file_encoding::Union{String, Nothing} = nothing,
        handler_encoding::Union{String, Nothing} = nothing)
    filepath = string(filepath)
    typeof(usecols) <: ColumnIndex && (usecols = (usecols,))
    if !(typeof(usecols) <: Union{UnitRange, Nothing})
        usecols = Set{Union{Int,Symbol}}(
            idx isa Integer ? Int(idx) : Symbol(idx) for idx in usecols)
    end
    parse_ext = get(ext2parser, ext, nothing)
    parse_ext === nothing && throw(ArgumentError("file extension $ext is not supported"))
    return _parse_allmeta(filepath, ext, parse_ext, usecols, file_encoding, handler_encoding)
end
