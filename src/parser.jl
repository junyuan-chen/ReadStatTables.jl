const jltypes = (String, Int8, Int16, Int32, Float32, Float64, String)

jltype(type::readstat_type_t) = jltypes[convert(Int, type)+1]

mutable struct ParserContext
    tb::ReadStatTable{ReadStatColumns}
    usecols::Union{UnitRange, Set, Nothing}
    inlinestring_width::Int
    pool_width::Int
    pool_thres::Int
end

mutable struct AllMetaContext
    meta::ReadStatMeta
    names::Vector{Symbol}
    colmeta::ColMetaVec
    vallabels::Dict{Symbol, Dict}
    usecols::Union{UnitRange, Set, Nothing}
end

for ext in (:dta, :sav, :por, :sas7bdat, :xport)
    for ctxtype in (ParserContext, ReadStatMeta, AllMetaContext)
        parse_ext = Symbol(:parse_, ext)
        readstat_parse_ext = QuoteNode(Symbol(:readstat_parse_, ext))
        @eval begin $parse_ext(parser::Ptr{Cvoid}, path::AbstractString,
            user_ctx::Ref{$ctxtype}) = ccall(($readstat_parse_ext, libreadstat),
            readstat_error_t, (Ptr{Cvoid}, Cstring, Ref{$ctxtype}), parser, path, user_ctx)
        end
    end
end

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

handle_metadata!(metadata::Ptr{Cvoid}, ctx::AllMetaContext) =
    handle_metadata!(metadata, ctx.meta)

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

handle_note!(note_index::Cint, note::Cstring, ctx::AllMetaContext) =
    handle_note!(note_index, note, ctx.meta)

function _pushcolmeta!(colmeta, variable, val_labels)
    push!(colmeta.label, variable_get_label(variable))
    push!(colmeta.format, variable_get_format(variable))
    type = variable_get_type(variable)
    push!(colmeta.type, type)
    push!(colmeta.vallabel, Symbol(_string(val_labels)))
    width = variable_get_storage_width(variable)
    push!(colmeta.storage_width, width)
    push!(colmeta.display_width, variable_get_display_width(variable))
    push!(colmeta.measure, variable_get_measure(variable))
    push!(colmeta.alignment, variable_get_alignment(variable))
    return type, width
end

function _pushcolumn!(cols, T, N, width, width_offset, inlinestring_width, pool_width, pool_thres)
    if T === String
        # No "" for String1
        # StrL in Stata has width being 0
        if (width == 0 || width >= pool_width + width_offset) && pool_thres > 0
            push!(cols, (PooledArray(RefArray(fill(one(UInt16), N)),
                Dict(""=>one(UInt16)), [""]), pool_thres))
        elseif width < min(4, inlinestring_width) + width_offset
            push!(cols, fill(String3(), N))
        elseif width < min(8, inlinestring_width) + width_offset
            push!(cols, fill(String7(), N))
        elseif width < min(16, inlinestring_width) + width_offset
            push!(cols, fill(String15(), N))
        elseif width < min(32, inlinestring_width) + width_offset
            push!(cols, fill(String31(), N))
        elseif width < min(64, inlinestring_width) + width_offset
            push!(cols, fill(String63(), N))
        elseif width < min(128, inlinestring_width) + width_offset
            push!(cols, fill(String127(), N))
        elseif width < min(256, inlinestring_width) + width_offset
            push!(cols, fill(String255(), N))
        else
            push!(cols, fill("", N))
        end
    elseif T === Int8
        push!(cols, Vector{Union{T, Missing}}(missing, N))
    elseif T <: Union{Int16, Int32}
        push!(cols, SentinelVector{T}(undef, N, typemin(T), missing))
    else
        push!(cols, SentinelVector{T}(undef, N))
    end
end

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
    type, width = _pushcolmeta!(_colmeta(tb), variable, val_labels)

    # Row count is not always available from metadata
    N = max(m.row_count, 0)
    cols = _columns(tb)
    T = jltype(type)
    _pushcolumn!(cols, T, N, width, Int(m.file_ext == ".dta"),
        ctx.inlinestring_width, ctx.pool_width, ctx.pool_thres)
    push!(_hasmissing(tb), false)
    return READSTAT_HANDLER_OK
end

function handle_variable_meta!(index::Cint, variable::Ptr{Cvoid}, val_labels::Cstring,
        ctx::AllMetaContext)
    usecols = ctx.usecols
    icol = index + 1
    name = Symbol(variable_get_name(variable))
    if usecols !== nothing && !(icol in usecols || name in usecols)
        return READSTAT_HANDLER_SKIP_VARIABLE
    end
    push!(ctx.names, name)
    _pushcolmeta!(ctx.colmeta, variable, val_labels)
    return READSTAT_HANDLER_OK
end

function handle_variable_chunk!(index::Cint, variable::Ptr{Cvoid}, val_labels::Cstring,
        ctx::ParserContext)
    usecols = ctx.usecols
    if usecols === nothing
        return READSTAT_HANDLER_OK
    else
        icol = index + 1
        name = Symbol(variable_get_name(variable))
        if !(icol in usecols || name in usecols)
            return READSTAT_HANDLER_SKIP_VARIABLE
        else
            return READSTAT_HANDLER_OK
        end
    end
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

function _handle_value_label!(val_labels, value, label, vallabels)
    lblname = Symbol(_string(val_labels))
    type = value_type(value)
    # String variables do not have value labels
    # All integers are Int32 and all floats are Float64 (ReadStat handles type conversion)
    # Tentatively save tagged missing values as Char
    if Int(type) <= 3
        lbls = get!(Dict{Union{Int32,Char},String}, vallabels, lblname)
        val = value_is_tagged_missing(value) ? value_tag(value) : int32_value(value)
        lbls[val] = _string(label)
    else
        lbls = get!(Dict{Union{Float64,Char},String}, vallabels, lblname)
        val = value_is_tagged_missing(value) ? value_tag(value) : double_value(value)
        lbls[val] = _string(label)
    end
    return READSTAT_HANDLER_OK
end

handle_value_label!(val_labels::Cstring, value::readstat_value_t, label::Cstring,
    ctx::ParserContext) =
        _handle_value_label!(val_labels, value, label, _vallabels(ctx.tb))

handle_value_label!(val_labels::Cstring, value::readstat_value_t, label::Cstring,
    ctx::AllMetaContext) =
        _handle_value_label!(val_labels, value, label, ctx.vallabels)

_error(e::readstat_error_t) = e === READSTAT_OK ? nothing : error(error_message(e))

function _parse_all(filepath, ext, parse_ext, usecols, row_limit, row_offset,
        inlinestring_width, pool_width, pool_thres, file_encoding, handler_encoding)
    tb = ReadStatTable()
    m = _meta(tb)
    m.file_ext = ext
    ctx = Ref{ParserContext}(
        ParserContext(tb, usecols, inlinestring_width, pool_width, pool_thres))
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
    _error(parse_ext(parser, filepath, ctx))
    parser_free(parser)
    return tb
end

function _parse_allmeta(filepath, ext, parse_ext, usecols, file_encoding, handler_encoding)
    m = ReadStatMeta()
    m.file_ext = ext
    names = Symbol[]
    cm = StructVector{ReadStatColMeta}((String[], String[], readstat_type_t[],
            Symbol[], Csize_t[], Cint[], readstat_measure_t[], readstat_alignment_t[]))
    vlbls = Dict{Symbol, Dict}()
    ctx = Ref{AllMetaContext}(AllMetaContext(m, names, cm, vlbls, usecols))
    parser = parser_init()
    set_metadata_handler(parser, @cfunction(handle_metadata!,
        readstat_handler_status, (Ptr{Cvoid}, Ref{AllMetaContext})))
    set_note_handler(parser, @cfunction(handle_note!,
        readstat_handler_status, (Cint, Cstring, Ref{AllMetaContext})))
    set_variable_handler(parser, @cfunction(handle_variable_meta!,
        readstat_handler_status, (Cint, Ptr{Cvoid}, Cstring, Ref{AllMetaContext})))
    set_value_label_handler(parser, @cfunction(handle_value_label!,
        readstat_handler_status, (Cstring, readstat_value_t, Cstring, Ref{AllMetaContext})))
    file_encoding === nothing ||
        _error(set_file_character_encoding(parser, file_encoding))
    handler_encoding === nothing ||
        _error(set_handler_character_encoding(parser, handler_encoding))
    _error(parse_ext(parser, filepath, ctx))
    parser_free(parser)
    return m, names, cm, vlbls
end

function _parse_chunk!(tb, filepath, parse_ext, usecols, row_limit, row_offset,
        pool_thres, file_encoding, handler_encoding)
    ctx = Ref{ParserContext}(ParserContext(tb, usecols, 0, 0, pool_thres))
    parser = parser_init()
    set_variable_handler(parser, @cfunction(handle_variable_chunk!,
        readstat_handler_status, (Cint, Ptr{Cvoid}, Cstring, Ref{ParserContext})))
    set_value_handler(parser, @cfunction(handle_value!,
        readstat_handler_status, (Cint, Ptr{Cvoid}, readstat_value_t, Ref{ParserContext})))
    _error(set_row_limit(parser, row_limit))
    _error(set_row_offset(parser, row_offset))
    file_encoding === nothing ||
        _error(set_file_character_encoding(parser, file_encoding))
    handler_encoding === nothing ||
        _error(set_handler_character_encoding(parser, handler_encoding))
    # Run the parser
    _error(parse_ext(parser, filepath, ctx))
    parser_free(parser)
end
