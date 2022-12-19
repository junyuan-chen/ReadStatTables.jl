function handle_write!(data::Ptr{UInt8}, len::Cint, ctx::Ptr)
    io = unsafe_pointer_to_objref(ctx) # restore io
    actual_data = unsafe_wrap(Array{UInt8}, data, (len, )) # we may want to specify the type later
    write(io, actual_data)
    return len
end

function write_data_file(filename::AbstractString, filetype::Val, source; kwargs...) 
    io = open(filename, "w")
    write_data_file(filetype::Val, io, source; kwargs...)
    close(io)
end

function write_data_file(filetype::Val, io::IO, source; filelabel = "")
    writer = writer_init()
    try
        write_bytes = @cfunction(handle_write!, Cint, (Ptr{UInt8}, Cint, Ptr{Nothing}))
        set_data_writer(writer, write_bytes)
        writer_set_file_label(writer, filelabel)

        rows = Tables.rows(source)
        schema = Tables.schema(rows)
        if schema === nothing
            error("Could not determine table schema for data source.")
        end
        variables_array = []

        variables_array = map(schema.names, schema.types) do column_name, column_type
            readstat_type, storage_width = readstat_column_type_and_width(source, column_name, nonmissingtype(column_type))
            return add_variable!(writer, column_name, readstat_type, storage_width)
            # readstat_variable_set_label(variable, String(field)) TODO: label for a variable
        end

        begin_writing(writer, filetype, io, length(rows))

        for row in rows
            begin_row(writer)
            Tables.eachcolumn(schema, row) do val, i, name
                insert_value!(writer, variables_array[i], val)
            end
            end_row(writer)
        end

        end_writing(writer)
    finally
        writer_free(writer)
    end
end

readstat_column_type_and_width(_, _, other_type) = error("Cannot handle column with element type $other_type. Is this type supported by ReadStat?")
readstat_column_type_and_width(_, _, ::Type{Float64}) = READSTAT_TYPE_DOUBLE, 0
readstat_column_type_and_width(_, _, ::Type{Float32}) = READSTAT_TYPE_FLOAT, 0
readstat_column_type_and_width(_, _, ::Type{Int32}) = READSTAT_TYPE_INT32, 0
readstat_column_type_and_width(_, _, ::Type{Int16}) = READSTAT_TYPE_INT16, 0
readstat_column_type_and_width(_, _, ::Type{Int8}) = READSTAT_TYPE_CHAR, 0
function readstat_column_type_and_width(source, colname, ::Type{String})
    col = Tables.getcolumn(source, colname)
    maxlen = maximum(col) do str
        str === missing ? 0 : ncodeunits(str)
    end
    if maxlen >= 2045 # maximum length of normal strings
        return READSTAT_TYPE_LONG_STRING, 0
    else
        return READSTAT_TYPE_STRING, maxlen
    end
end

add_variable!(writer, name, type, width = 0) = add_variable(writer, name, type, width)

insert_value!(writer, variable, value::Float64) = insert_double_value(writer, variable, value)
insert_value!(writer, variable, value::Float32) = insert_float_value(writer, variable, value)
insert_value!(writer, variable, ::Missing) = insert_missing_value(writer, variable)
insert_value!(writer, variable, value::Int8) = insert_int8_value(writer, variable, value)
insert_value!(writer, variable, value::Int16) = insert_int16_value(writer, variable, value)
insert_value!(writer, variable, value::Int32) = insert_int32_value(writer, variable, value)
insert_value!(writer, variable, value::AbstractString) = insert_string_value(writer, variable, value)

read_dta(filename::AbstractString) = read_data_file(filename, Val(:dta))
read_sav(filename::AbstractString) = read_data_file(filename, Val(:sav))
read_por(filename::AbstractString) = read_data_file(filename, Val(:por))
read_sas7bdat(filename::AbstractString) = read_data_file(filename, Val(:sas7bdat))
read_xport(filename::AbstractString) = read_data_file(filename, Val(:xport))

write_dta(filename::AbstractString, source; kwargs...) = write_data_file(filename, Val(:dta), source; kwargs...)
write_sav(filename::AbstractString, source; kwargs...) = write_data_file(filename, Val(:sav), source; kwargs...)
write_por(filename::AbstractString, source; kwargs...) = write_data_file(filename, Val(:por), source; kwargs...)
write_sas7bdat(filename::AbstractString, source; kwargs...) = write_data_file(filename, Val(:sas7bdat), source; kwargs...)
write_xport(filename::AbstractString, source; kwargs...) = write_data_file(filename, Val(:xport), source; kwargs...)