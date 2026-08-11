handle_write(data::Ptr{UInt8}, len::Csize_t, ctx::IOStream) =
    Cssize_t(unsafe_write(ctx, data, len))

function _write_value_label(writer, vallabels, ext)
    label_sets = Dict{Symbol, Ptr{Cvoid}}()
    for (lblname, lbls) in vallabels
        # Key type of lbls is expected to be Union{T,Char} for some accepted T
        # Extract the part of key type other than Char
        T = Base.typesplit(keytype(lbls), Char)
        # T is Union{} if value labels are for Char (will be converted to String)
        if T <: AbstractFloat && T != Union{}
            readstattype = READSTAT_TYPE_DOUBLE
            labelvalue = label_double_value
        elseif T <: Integer && T != Union{}
            readstattype = READSTAT_TYPE_INT32
            labelvalue = label_int32_value
        else
            # T should be string/char as otherwise rstype should already raise error
            T <: AbstractString || error("Value label set $lblname has unaccepted key type")
            ext == ".dta" && error("Stata does not allow value labels for string variables")
            readstattype = READSTAT_TYPE_STRING
            labelvalue = label_string_value
        end
        label_set = add_label_set(writer, readstattype, lblname)
        for (val, lbl) in lbls
            if val isa T
                labelvalue(label_set, val, lbl)
            else
                label_tagged_value(label_set, val, lbl)
            end
        end
        label_sets[lblname] = label_set
    end
    return label_sets
end

function _write_value(io::IOStream, write_ext, writer, tb::ReadStatTable{<:ColumnsOrChained})
    M, N = size(tb)
    cols = _columns(tb)
    types = _colmeta(tb, :type)
    write_ext(writer, Ref{IOStream}(io), M)
    for m in 1:M
        _error(begin_row(writer))
        for n in 1:N
            var = get_variable(writer, n-1)
            @inbounds val = cols[m, n]
            @inbounds type = types[n]
            if val === missing
                _error(insert_missing_value(writer, var))
            elseif type === READSTAT_TYPE_INT8
                _error(insert_int8_value(writer, var, val))
            elseif type === READSTAT_TYPE_INT16
                _error(insert_int16_value(writer, var, val))
            elseif type === READSTAT_TYPE_INT32
                _error(insert_int32_value(writer, var, val))
            elseif type === READSTAT_TYPE_FLOAT
                _error(insert_float_value(writer, var, val))
            elseif type === READSTAT_TYPE_DOUBLE
                _error(insert_double_value(writer, var, val))
            elseif type === READSTAT_TYPE_STRING
                str = Base.unsafe_convert(Cstring, Base.cconvert(Cstring, val))
                _error(insert_string_value(writer, var, str))
            #! To do: handle string_ref
            end
        end
        _error(end_row(writer))
    end
    _error(end_writing(writer))
end

function _write_value(io::IOStream, write_ext, writer, tb::ReadStatTable)
    rows = Tables.rows(tb)
    schema = Tables.schema(tb)
    types = _colmeta(tb, :type)
    write_ext(writer, Ref{IOStream}(io), nrow(tb))
    for row in rows
        _error(begin_row(writer))
        Tables.eachcolumn(schema, row) do val, i, name
            var = get_variable(writer, i-1)
            @inbounds type = types[i]
            # unwrap is needed in case the element is a LabeledValue
            if unwrap(val) === missing
                _error(insert_missing_value(writer, var))
            elseif type === READSTAT_TYPE_INT8
                _error(insert_int8_value(writer, var, unwrap(val)))
            elseif type === READSTAT_TYPE_INT16
                _error(insert_int16_value(writer, var, unwrap(val)))
            elseif type === READSTAT_TYPE_INT32
                _error(insert_int32_value(writer, var, Int32(unwrap(val))))
            elseif type === READSTAT_TYPE_FLOAT
                _error(insert_float_value(writer, var, unwrap(val)))
            elseif type === READSTAT_TYPE_DOUBLE
                _error(insert_double_value(writer, var, Float64(unwrap(val))))
            elseif type === READSTAT_TYPE_STRING
                # str = Base.unsafe_convert(Cstring, Base.cconvert(Cstring, unwrap(val)))
                # A tentative fix for Julia v1.13
                str = Base.unsafe_convert(Cstring, String(unwrap(val)))
                _error(insert_string_value(writer, var, str))
            #! To do: handle string_ref and date/time
            end
        end
        _error(end_row(writer))
    end
    _error(end_writing(writer))
end

function _write(io::IOStream, ext, write_ext, tb)
    writer = writer_init()
    set_data_writer(writer, @cfunction(handle_write,
        Cssize_t, (Ptr{UInt8}, Csize_t, Ref{IOStream})))
    meta = _meta(tb)
    colmeta = _colmeta(tb)
    try
        label_sets = _write_value_label(writer, getvaluelabels(tb), ext)
        for (i, name) in enumerate(_names(tb))
            type = colmeta.type[i]
            width = colmeta.storage_width[i]
            var = add_variable(writer, name, type, width)
            variable_set_label(var, colmeta.label[i])
            format = colmeta.format[i]
            if format == ""
                # This enforces a default format based on storage width
                if ext ∈ (".por", ".sav") && type == READSTAT_TYPE_STRING
                    format = string("A", width)
                    variable_set_format(var, format)
                end
            else
                variable_set_format(var, format)
            end
            format == "" || variable_set_format(var, format)
            label_set = get(label_sets, colmeta.vallabel[i], nothing)
            label_set === nothing || variable_set_label_set(var, label_set)
            variable_set_measure(var, colmeta.measure[i])
            variable_set_alignment(var, colmeta.alignment[i])
            variable_set_display_width(var, colmeta.display_width[i])
        end

        for note in meta.notes
            add_note(writer, note)
        end

        _error(writer_set_file_label(writer, meta.file_label))
        _error(writer_set_file_timestamp(writer, now()))
        file_version = meta.file_format_version
        file_version == -1 || _error(writer_set_file_format_version(writer, file_version))
        ext == ".xpt" && _error(writer_set_table_name(writer, meta.table_name))
        ext ∈ (".sas7bdat", ".xpt") && _error(
            writer_set_file_format_is_64bit(writer, meta.file_format_is_64bit))
        ext ∈ (".sas7bdat", ".sav") && _error(
            writer_set_compression(writer, meta.compression))

        _write_value(io, write_ext, writer, tb)
    finally
        writer_free(writer)
        close(io)
    end
end
