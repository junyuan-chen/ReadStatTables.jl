const jltypes = (String, Int8, Int16, Int32, Float32, Float64, String)

jltype(type::readstat_type_t) = jltypes[convert(Int, type)+1]

struct ParserContext
    tb::ReadStatTable
    usecols::Union{UnitRange, Set, Nothing}
    useinlinestring::Bool
    pool_thres::Int
end

parse_dta(parser::Ptr{Cvoid}, path::AbstractString, user_ctx::Ref{ParserContext}) =
    ccall((:readstat_parse_dta, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Cstring, Ref{ParserContext}), parser, path, user_ctx)

parse_dta(parser::Ptr{Cvoid}, path::AbstractString, user_ctx::Ref{ReadStatMeta}) =
    ccall((:readstat_parse_dta, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Cstring, Ref{ReadStatMeta}), parser, path, user_ctx)

parse_sav(parser::Ptr{Cvoid}, path::AbstractString, user_ctx::Ref{ParserContext}) =
    ccall((:readstat_parse_sav, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Cstring, Ref{ParserContext}), parser, path, user_ctx)

parse_sav(parser::Ptr{Cvoid}, path::AbstractString, user_ctx::Ref{ReadStatMeta}) =
    ccall((:readstat_parse_sav, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Cstring, Ref{ReadStatMeta}), parser, path, user_ctx)

parse_por(parser::Ptr{Cvoid}, path::AbstractString, user_ctx::Ref{ParserContext}) =
    ccall((:readstat_parse_por, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Cstring, Ref{ParserContext}), parser, path, user_ctx)

parse_por(parser::Ptr{Cvoid}, path::AbstractString, user_ctx::Ref{ReadStatMeta}) =
    ccall((:readstat_parse_por, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Cstring, Ref{ReadStatMeta}), parser, path, user_ctx)

parse_sas7bdat(parser::Ptr{Cvoid}, path::AbstractString, user_ctx::Ref{ParserContext}) =
    ccall((:readstat_parse_sas7bdat, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Cstring, Ref{ParserContext}), parser, path, user_ctx)

parse_sas7bdat(parser::Ptr{Cvoid}, path::AbstractString, user_ctx::Ref{ReadStatMeta}) =
    ccall((:readstat_parse_sas7bdat, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Cstring, Ref{ReadStatMeta}), parser, path, user_ctx)

parse_xport(parser::Ptr{Cvoid}, path::AbstractString, user_ctx::Ref{ParserContext}) =
    ccall((:readstat_parse_xport, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Cstring, Ref{ParserContext}), parser, path, user_ctx)

parse_xport(parser::Ptr{Cvoid}, path::AbstractString, user_ctx::Ref{ReadStatMeta}) =
    ccall((:readstat_parse_xport, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Cstring, Ref{ReadStatMeta}), parser, path, user_ctx)

const ext2parser = Dict{String, Any}(
    ".dta" => parse_dta,
    ".sav" => parse_sav,
    ".por" => parse_por,
    ".sas7bdat" => parse_sas7bdat,
    ".xpt" => parse_xport
)

function handle_metadata!(metadata::Ptr{Cvoid}, m::ReadStatMeta)
    m.row_count = get_row_count(metadata)
    m.var_count = get_var_count(metadata)
    m.creation_time = get_creation_time(metadata)
    m.modified_time = get_modified_time(metadata)
    m.file_format_version = get_file_format_version(metadata)
    m.file_format_is_64bit = get_file_format_is_64bit(metadata)
    m.compression = get_compression(metadata)
    m.endianness = get_endianness(metadata)
    m.table_name = get_table_name(metadata)
    m.file_label = get_file_label(metadata)
    m.file_encoding = get_file_encoding(metadata)
    return READSTAT_HANDLER_OK
end

handle_metadata!(metadata::Ptr{Cvoid}, ctx::ParserContext) =
    handle_metadata!(metadata, _meta(ctx.tb))

function handle_note!(note_index::Cint, note::Cstring, m::ReadStatMeta)
    # For Stata, note_index=0 gives the total number of notes
    # For SAS, each note is attached with a date that comes with the next note_index
    index = note_index + 1
    N = length(m.notes)
    if index > N
        # For Stata, note_index may not be consecutive
        # if some notes are deleted without renumbering
        resize!(m.notes, index)
        index-1 > N && fill!(view(m.notes, N+1:index-1), "")
    end
    m.notes[index] = _string(note)
    return READSTAT_HANDLER_OK
end

handle_note!(note_index::Cint, note::Cstring, ctx::ParserContext) =
    handle_note!(note_index, note, _meta(ctx.tb))

function handle_variable!(index::Cint, variable::Ptr{Cvoid}, val_labels::Cstring,
        ctx::ParserContext)
    tb = ctx.tb
    m = _meta(tb)
    usecols = ctx.usecols
    icol = index + 1
    name = Symbol(variable_get_name(variable))
    if usecols !== nothing
        if !(icol in usecols || name in usecols)
            return READSTAT_HANDLER_SKIP_VARIABLE
        else
            icol = variable_get_index_after_skipping(variable) + 1
        end
    end
    push!(_names(tb), name)
    _lookup(tb)[name] = icol
    colmetas = _colmeta(tb)
    push!(colmetas.label, variable_get_label(variable))
    push!(colmetas.format, variable_get_format(variable))
    type = variable_get_type(variable)
    push!(colmetas.type, type)
    push!(colmetas.vallabel, Symbol(_string(val_labels)))
    width = variable_get_storage_width(variable)
    push!(colmetas.storage_width, width)
    push!(colmetas.display_width, variable_get_display_width(variable))
    push!(colmetas.measure, variable_get_measure(variable))
    push!(colmetas.alignment, variable_get_alignment(variable))

    # Row count is not always available from metadata
    N = max(m.row_count, 0)
    cols = _columns(tb)
    pool_thres = ctx.pool_thres
    usepool = pool_thres > 0
    T = jltype(type)
    if T === String
        if ctx.useinlinestring
            # No "" for String1
            # StrL in Stata has width being 0
            if width == 0 || width > 32
                if usepool
                    push!(cols, (PooledArray(fill("", N), UInt16), pool_thres))
                else
                    push!(cols, fill("", N))
                end
            elseif width < 5
                push!(cols, fill(String3(), N))
            elseif width < 9
                push!(cols, fill(String7(), N))
            elseif width < 17
                push!(cols, fill(String15(), N))
            elseif width < 33
                push!(cols, fill(String31(), N))
            end
        else
            if usepool
                push!(cols, (PooledArray(fill("", N), UInt16), pool_thres))
            else
                push!(cols, fill("", N))
            end
        end
    elseif T === Int8
        push!(cols, Vector{Union{T, Missing}}(missing, N))
    elseif T <: Union{Int16, Int32}
        push!(cols, SentinelVector{T}(undef, N, typemin(T), missing))
    else
        push!(cols, SentinelVector{T}(undef, N))
    end
    push!(_hasmissing(tb), false)
    return READSTAT_HANDLER_OK
end

function handle_value!(obs_index::Cint, variable::Ptr{Cvoid}, value::readstat_value_t,
        ctx::ParserContext)
    tb = ctx.tb
    cols = _columns(tb)
    nrow = _meta(tb).row_count
    icol = variable_get_index_after_skipping(variable) + 1
    ismiss = value_is_missing(value, variable)
    if ismiss
        @inbounds _hasmissing(tb)[icol] = true
        # Assume columns are otherwise initialized with missing
        if nrow < 1
            @inbounds _pushmissing!(cols, icol)
        end
        # Todo: Handle the case with tagged missing
    else
        irow = obs_index + 1
        @inbounds _setvalue!(cols, value, irow, icol)
    end
    return READSTAT_HANDLER_OK
end

function handle_value_label!(val_labels::Cstring, value::readstat_value_t, label::Cstring,
        ctx::ParserContext)
    tb = ctx.tb
    lblname = Symbol(_string(val_labels))
    type = value_type(value)
    # String variables do not have value labels
    # All integers are Int32 and all floats are Float64 (ReadStat handles type conversion)
    # Tentatively save tagged missing values as Char
    if Int(type) <= 3
        lbls = get!(Dict{Union{Int32,Char},String}, _vallabels(tb), lblname)
        val = value_is_tagged_missing(value) ? value_tag(value) : int32_value(value)
        lbls[val] = _string(label)
    else
        lbls = get!(Dict{Union{Float64,Char},String}, _vallabels(tb), lblname)
        val = value_is_tagged_missing(value) ? value_tag(value) : double_value(value)
        lbls[val] = _string(label)
    end
    return READSTAT_HANDLER_OK
end

_error(e::readstat_error_t) = e === READSTAT_OK ? nothing : error(error_message(e))

function _parse_all(filepath, usecols, row_limit, row_offset,
        useinlinestring, pool_thres, file_encoding, handler_encoding)
    ext = lowercase(splitext(filepath)[2])
    parse_ext = get(ext2parser, ext, nothing)
    parse_ext === nothing && throw(ArgumentError("file extension $ext is not supported"))
    tb = ReadStatTable()
    m = _meta(tb)
    m.file_ext = ext
    ctx = ParserContext(tb, usecols, useinlinestring, pool_thres)
    refctx = Ref{ParserContext}(ctx)
    parser = parser_init()
    set_metadata_handler(parser, @cfunction(handle_metadata!,
        readstat_handler_status, (Ptr{Cvoid}, Ref{ParserContext})))
    set_note_handler(parser, @cfunction(handle_note!,
        readstat_handler_status, (Cint, Cstring, Ref{ParserContext})))
    set_variable_handler(parser, @cfunction(handle_variable!,
        readstat_handler_status, (Cint, Ptr{Cvoid}, Cstring, Ref{ParserContext})))
    set_value_handler(parser, @cfunction(handle_value!,
        readstat_handler_status, (Cint, Ptr{Cvoid}, readstat_value_t, Ref{ParserContext})))
    set_value_label_handler(parser, @cfunction(handle_value_label!,
        readstat_handler_status, (Cstring, readstat_value_t, Cstring, Ref{ParserContext})))
    row_limit === nothing || _error(set_row_limit(parser, row_limit))
    row_offset === nothing || _error(set_row_offset(parser, row_offset))
    file_encoding === nothing ||
        _error(set_file_character_encoding(parser, file_encoding))
    handler_encoding === nothing ||
        _error(set_handler_character_encoding(parser, handler_encoding))
    # Run the parser
    _error(parse_ext(parser, filepath, refctx))
    parser_free(parser)
    return ctx
end
