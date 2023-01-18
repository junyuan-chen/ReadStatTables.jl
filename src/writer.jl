handle_write(data::Ptr{UInt8}, len::Csize_t, ctx::IOStream) =
    Cssize_t(unsafe_write(ctx, data, len))

function _write_value_label(writer, vallabels)
    label_sets = Dict{Symbol, Ptr{Cvoid}}()
    for (lblname, lbls) in vallabels
        if keytype(lbls) == Union{Float64, Char}
            label_set = add_label_set(writer, READSTAT_TYPE_DOUBLE, lblname)
            for (val, lbl) in lbls
                if val isa Float64
                    label_double_value(label_set, val, lbl)
                else
                    label_tagged_value(label_set, val, lbl)
                end
            end
            label_sets[lblname] = label_set
        elseif keytype(lbls) == Union{Int32, Char}
            label_set = add_label_set(writer, READSTAT_TYPE_INT32, lblname)
            for (val, lbl) in lbls
                if val isa Int32
                    label_int32_value(label_set, val, lbl)
                else
                    label_tagged_value(label_set, val, lbl)
                end
            end
            label_sets[lblname] = label_set
        end
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
            #! To do: handle string_ref and date/time
            end
        end
        _error(end_row(writer))
    end
    _error(end_writing(writer))
end

function _write_value(io::IOStream, write_ext, writer, tb::ReadStatTable)
    rows = Tables.rows(_columns(tb))
    schema = Tables.schema(tb)
    types = _colmeta(tb, :type)
    write_ext(writer, Ref{IOStream}(io), length(rows))
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
                str = Base.unsafe_convert(Cstring, Base.cconvert(Cstring, unwrap(val)))
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
        label_sets = _write_value_label(writer, getvaluelabels(tb))
        for (i, name) in enumerate(_names(tb))
            type = colmeta.type[i]
            width = colmeta.storage_width[i]
            var = add_variable(writer, name, type, width)
            variable_set_label(var, colmeta.label[i])
            format = colmeta.format[i]
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
