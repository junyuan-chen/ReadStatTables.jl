# Wrap relevant objects from ReadStat/src/readstat.h

@cenum readstat_handler_status begin
    READSTAT_HANDLER_OK
    READSTAT_HANDLER_ABORT
    READSTAT_HANDLER_SKIP_VARIABLE
end

@cenum readstat_type_t begin
    READSTAT_TYPE_STRING
    READSTAT_TYPE_INT8
    READSTAT_TYPE_INT16
    READSTAT_TYPE_INT32
    READSTAT_TYPE_FLOAT
    READSTAT_TYPE_DOUBLE
    READSTAT_TYPE_STRING_REF
end

@cenum readstat_measure_t begin
    READSTAT_MEASURE_UNKNOWN
    READSTAT_MEASURE_NOMINAL
    READSTAT_MEASURE_ORDINAL
    READSTAT_MEASURE_SCALE
end

@cenum readstat_alignment_t begin
    READSTAT_ALIGNMENT_UNKNOWN
    READSTAT_ALIGNMENT_LEFT
    READSTAT_ALIGNMENT_CENTER
    READSTAT_ALIGNMENT_RIGHT
end

@cenum readstat_compress_t begin
    READSTAT_COMPRESS_NONE
    READSTAT_COMPRESS_ROWS
    READSTAT_COMPRESS_BINARY
end

@cenum readstat_endian_t begin
    READSTAT_ENDIAN_NONE
    READSTAT_ENDIAN_LITTLE
    READSTAT_ENDIAN_BIG
end

@cenum readstat_error_t begin
    READSTAT_OK
    READSTAT_ERROR_OPEN
    READSTAT_ERROR_READ
    READSTAT_ERROR_MALLOC
    READSTAT_ERROR_USER_ABORT
    READSTAT_ERROR_PARSE
    READSTAT_ERROR_UNSUPPORTED_COMPRESSION
    READSTAT_ERROR_UNSUPPORTED_CHARSET
    READSTAT_ERROR_COLUMN_COUNT_MISMATCH
    READSTAT_ERROR_ROW_COUNT_MISMATCH
    READSTAT_ERROR_ROW_WIDTH_MISMATCH
    READSTAT_ERROR_BAD_FORMAT_STRING
    READSTAT_ERROR_VALUE_TYPE_MISMATCH
    READSTAT_ERROR_WRITE
    READSTAT_ERROR_WRITER_NOT_INITIALIZED
    READSTAT_ERROR_SEEK
    READSTAT_ERROR_CONVERT
    READSTAT_ERROR_CONVERT_BAD_STRING
    READSTAT_ERROR_CONVERT_SHORT_STRING
    READSTAT_ERROR_CONVERT_LONG_STRING
    READSTAT_ERROR_NUMERIC_VALUE_IS_OUT_OF_RANGE
    READSTAT_ERROR_TAGGED_VALUE_IS_OUT_OF_RANGE
    READSTAT_ERROR_STRING_VALUE_IS_TOO_LONG
    READSTAT_ERROR_TAGGED_VALUES_NOT_SUPPORTED
    READSTAT_ERROR_UNSUPPORTED_FILE_FORMAT_VERSION
    READSTAT_ERROR_NAME_BEGINS_WITH_ILLEGAL_CHARACTER
    READSTAT_ERROR_NAME_CONTAINS_ILLEGAL_CHARACTER
    READSTAT_ERROR_NAME_IS_RESERVED_WORD
    READSTAT_ERROR_NAME_IS_TOO_LONG
    READSTAT_ERROR_BAD_TIMESTAMP_STRING
    READSTAT_ERROR_BAD_FREQUENCY_WEIGHT
    READSTAT_ERROR_TOO_MANY_MISSING_VALUE_DEFINITIONS
    READSTAT_ERROR_NOTE_IS_TOO_LONG
    READSTAT_ERROR_STRING_REFS_NOT_SUPPORTED
    READSTAT_ERROR_STRING_REF_IS_REQUIRED
    READSTAT_ERROR_ROW_IS_TOO_WIDE_FOR_PAGE
    READSTAT_ERROR_TOO_FEW_COLUMNS
    READSTAT_ERROR_TOO_MANY_COLUMNS
    READSTAT_ERROR_NAME_IS_ZERO_LENGTH
    READSTAT_ERROR_BAD_TIMESTAMP_VALUE
end

_string(str::Union{Cstring, Ptr{UInt8}}) = str == C_NULL ? "" : unsafe_string(str)

error_message(error_code::readstat_error_t) =
    _string(ccall((:readstat_error_message, libreadstat),
        Cstring, (readstat_error_t,), error_code))

get_row_count(metadata::Ptr{Cvoid}) =
    ccall((:readstat_get_row_count, libreadstat), Cint, (Ptr{Cvoid},), metadata)

get_var_count(metadata::Ptr{Cvoid}) =
    ccall((:readstat_get_var_count, libreadstat), Cint, (Ptr{Cvoid},), metadata)

get_creation_time(metadata::Ptr{Cvoid}) =
    unix2datetime(ccall((:readstat_get_creation_time, libreadstat),
        UInt, (Ptr{Cvoid},), metadata))

get_modified_time(metadata::Ptr{Cvoid}) =
    unix2datetime(ccall((:readstat_get_modified_time, libreadstat),
        UInt, (Ptr{Cvoid},), metadata))

get_file_format_version(metadata::Ptr{Cvoid}) =
    ccall((:readstat_get_file_format_version, libreadstat), Cint, (Ptr{Cvoid},), metadata)

get_file_format_is_64bit(metadata::Ptr{Cvoid}) =
    Bool(ccall((:readstat_get_file_format_is_64bit, libreadstat),
        Cint, (Ptr{Cvoid},), metadata))

get_compression(metadata::Ptr{Cvoid}) =
    ccall((:readstat_get_compression, libreadstat),
        readstat_compress_t, (Ptr{Cvoid},), metadata)

get_endianness(metadata::Ptr{Cvoid}) =
    ccall((:readstat_get_endianness, libreadstat),
        readstat_endian_t, (Ptr{Cvoid},), metadata)

get_table_name(metadata::Ptr{Cvoid}) =
    _string(ccall((:readstat_get_table_name, libreadstat), Cstring, (Ptr{Cvoid},), metadata))

get_file_label(metadata::Ptr{Cvoid}) =
    _string(ccall((:readstat_get_file_label, libreadstat), Cstring, (Ptr{Cvoid},), metadata))

get_file_encoding(metadata::Ptr{Cvoid}) =
    _string(ccall((:readstat_get_file_encoding, libreadstat),
        Cstring, (Ptr{Cvoid},), metadata))

# Needed for specifying argument type
struct readstat_value_t
    v::Int64
    type::readstat_type_t
    tag::Cchar
    @static if Sys.iswindows()
        bits::Cuint
    else
        bits::UInt8
    end
end

value_type(value::readstat_value_t) =
    ccall((:readstat_value_type, libreadstat), readstat_type_t, (readstat_value_t,), value)

value_is_missing(value::readstat_value_t, variable::Ptr{Cvoid}) =
    Bool(ccall((:readstat_value_is_missing, libreadstat),
        Cint, (readstat_value_t, Ptr{Cvoid}), value, variable))

#=
value_is_system_missing(value::readstat_value_t) =
    Bool(ccall((:readstat_value_is_system_missing, libreadstat),
        Cint, (readstat_value_t,), value))
=#

value_is_tagged_missing(value::readstat_value_t) =
    Bool(ccall((:readstat_value_is_tagged_missing, libreadstat),
        Cint, (readstat_value_t,), value))

#=
value_is_defined_missing(value::readstat_value_t, variable::Ptr{Cvoid}) =
    Bool(ccall((:readstat_value_is_defined_missing, libreadstat),
        Cint, (readstat_value_t, Ptr{Cvoid}), value, variable))
=#

value_tag(value::readstat_value_t) =
    Char(ccall((:readstat_value_tag, libreadstat), Cchar, (readstat_value_t,), value))

int8_value(value::readstat_value_t) =
    ccall((:readstat_int8_value, libreadstat), Int8, (readstat_value_t,), value)

int16_value(value::readstat_value_t) =
    ccall((:readstat_int16_value, libreadstat), Int16, (readstat_value_t,), value)

int32_value(value::readstat_value_t) =
    ccall((:readstat_int32_value, libreadstat), Int32, (readstat_value_t,), value)

float_value(value::readstat_value_t) =
    ccall((:readstat_float_value, libreadstat), Float32, (readstat_value_t,), value)

double_value(value::readstat_value_t) =
    ccall((:readstat_double_value, libreadstat), Float64, (readstat_value_t,), value)

string_value(value::readstat_value_t) =
    ccall((:readstat_string_value, libreadstat), Ptr{UInt8}, (readstat_value_t,), value)

#=
variable_get_index(variable::Ptr{Cvoid}) =
    ccall((:readstat_variable_get_index, libreadstat), Cint, (Ptr{Cvoid},), variable)
=#

variable_get_index_after_skipping(variable::Ptr{Cvoid}) =
    ccall((:readstat_variable_get_index_after_skipping, libreadstat),
        Cint, (Ptr{Cvoid},), variable)

# Variable name should never be C_NULL
variable_get_name(variable::Ptr{Cvoid}) =
    unsafe_string(ccall((:readstat_variable_get_name, libreadstat),
        Cstring, (Ptr{Cvoid},), variable))

variable_get_label(variable::Ptr{Cvoid}) =
    _string(ccall((:readstat_variable_get_label, libreadstat),
        Cstring, (Ptr{Cvoid},), variable))

variable_get_format(variable::Ptr{Cvoid}) =
    _string(ccall((:readstat_variable_get_format, libreadstat),
        Cstring, (Ptr{Cvoid},), variable))

variable_get_type(variable::Ptr{Cvoid}) =
    ccall((:readstat_variable_get_type, libreadstat),
        readstat_type_t, (Ptr{Cvoid},), variable)

variable_get_storage_width(variable::Ptr{Cvoid}) =
    ccall((:readstat_variable_get_storage_width, libreadstat),
        Csize_t, (Ptr{Cvoid},), variable)

variable_get_display_width(variable::Ptr{Cvoid}) =
    ccall((:readstat_variable_get_display_width, libreadstat),
        Cint, (Ptr{Cvoid},), variable)

variable_get_measure(variable::Ptr{Cvoid}) =
    ccall((:readstat_variable_get_measure, libreadstat),
        readstat_measure_t, (Ptr{Cvoid},), variable)

variable_get_alignment(variable::Ptr{Cvoid}) =
    ccall((:readstat_variable_get_alignment, libreadstat),
        readstat_alignment_t, (Ptr{Cvoid},), variable)

parser_init() = ccall((:readstat_parser_init, libreadstat), Ptr{Cvoid}, ())

parser_free(parser::Ptr{Cvoid}) =
    ccall((:readstat_parser_free, libreadstat), Cvoid, (Ptr{Cvoid},), parser)

set_metadata_handler(parser::Ptr{Cvoid}, metadata_handler::Ptr{Cvoid}) =
    ccall((:readstat_set_metadata_handler, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Ptr{Cvoid}), parser, metadata_handler)

set_note_handler(parser::Ptr{Cvoid}, note_handler::Ptr{Cvoid}) =
    ccall((:readstat_set_note_handler, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Ptr{Cvoid}), parser, note_handler)

set_variable_handler(parser::Ptr{Cvoid}, variable_handler::Ptr{Cvoid}) =
    ccall((:readstat_set_variable_handler, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Ptr{Cvoid}), parser, variable_handler)

#= Only relevant for SPSS?
set_fweight_handler(parser::Ptr{Cvoid}, fweight_handler::Ptr{Cvoid}) =
    ccall((:readstat_set_fweight_handler, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Ptr{Cvoid}), parser, fweight_handler)
=#

set_value_handler(parser::Ptr{Cvoid}, value_handler::Ptr{Cvoid}) =
    ccall((:readstat_set_value_handler, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Ptr{Cvoid}), parser, value_handler)

set_value_label_handler(parser::Ptr{Cvoid}, value_label_handler::Ptr{Cvoid}) =
    ccall((:readstat_set_value_label_handler, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Ptr{Cvoid}), parser, value_label_handler)

#=
set_error_handler(parser::Ptr{Cvoid}, error_handler::Ptr{Cvoid}) =
    ccall((:readstat_set_error_handler, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Ptr{Cvoid}), parser, error_handler)
=#

set_file_character_encoding(parser::Ptr{Cvoid}, encoding::AbstractString) =
    ccall((:readstat_set_file_character_encoding, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Cstring), parser, encoding)

set_handler_character_encoding(parser::Ptr{Cvoid}, encoding::AbstractString) =
    ccall((:readstat_set_handler_character_encoding, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Cstring), parser, encoding)

set_row_limit(parser::Ptr{Cvoid}, row_limit::Integer) =
    ccall((:readstat_set_row_limit, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Clong), parser, row_limit)

set_row_offset(parser::Ptr{Cvoid}, row_offset::Integer) =
    ccall((:readstat_set_row_offset, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Clong), parser, row_offset)

writer_init() = ccall((:readstat_writer_init, libreadstat), Ptr{Cvoid}, ())

set_data_writer(writer::Ptr{Cvoid}, data_writer::Ptr{Cvoid}) =
    ccall((:readstat_set_data_writer, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Ptr{Cvoid}), writer, data_writer)

add_label_set(writer::Ptr{Cvoid}, type::readstat_type_t, name::AbstractString) =
    ccall((:readstat_add_label_set, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Ptr{Cvoid}), writer, data_writer)

label_double_value(label_set::Ptr{Cvoid}, value::Real, label::AbstractString) =
    ccall((:readstat_label_double_value, libreadstat),
        Cvoid, (Ptr{Cvoid}, Cdouble, Cstring), label_set, value, label)

label_int32_value(label_set::Ptr{Cvoid}, value::Integer, label::AbstractString) =
    ccall((:readstat_label_int32_value, libreadstat),
        Cvoid, (Ptr{Cvoid}, Int32, Cstring), label_set, value, label)

label_tagged_value(label_set::Ptr{Cvoid}, tag::Char, label::AbstractString) =
    ccall((:readstat_label_tagged_value, libreadstat),
        Cvoid, (Ptr{Cvoid}, Cchar, Cstring), label_set, tag, label)

add_variable(writer::Ptr{Cvoid}, name::AbstractString, type::readstat_type_t, storage_width::Integer) =
    ccall((:readstat_add_variable, libreadstat), Ptr{Cvoid},
        (Ptr{Cvoid}, Cstring, readstat_type_t, Csize_t), writer, name, type, storage_width)

variable_set_label(variable::Ptr{Cvoid}, label::AbstractString) =
    ccall((:readstat_variable_set_label, libreadstat),
        Cvoid, (Ptr{Cvoid}, Cstring), variable, label)

variable_set_format(variable::Ptr{Cvoid}, format::AbstractString) =
    ccall((:readstat_variable_set_format, libreadstat),
        Cvoid, (Ptr{Cvoid}, Cstring), variable, format)

variable_set_label_set(variable::Ptr{Cvoid}, label_set::Ptr{Cvoid}) =
    ccall((:readstat_variable_set_label_set, libreadstat),
        Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), variable, label_set)

variable_set_measure(variable::Ptr{Cvoid}, measure::readstat_measure_t) =
    ccall((:readstat_variable_set_measure, libreadstat),
        Cvoid, (Ptr{Cvoid}, readstat_measure_t), variable, measure)

variable_set_alignment(variable::Ptr{Cvoid}, alignment::readstat_alignment_t) =
    ccall((:readstat_variable_set_alignment, libreadstat),
        Cvoid, (Ptr{Cvoid}, readstat_alignment_t), variable, alignment)

variable_set_display_width(variable::Ptr{Cvoid}, display_width::Integer) =
    ccall((:readstat_variable_set_display_width, libreadstat),
        Cvoid, (Ptr{Cvoid}, Cint), variable, display_width)

get_variable(writer::Ptr{Cvoid}, index::Integer) =
    ccall((:readstat_get_variable, libreadstat),
        Ptr{Cvoid}, (Ptr{Cvoid}, Cint), writer, index)

add_note(writer::Ptr{Cvoid}, note::AbstractString) =
    ccall((:readstat_add_note, libreadstat),
        Cvoid, (Ptr{Cvoid}, Cstring), writer, note)

writer_set_file_label(writer::Ptr{Cvoid}, file_label::AbstractString) =
    ccall((:readstat_writer_set_file_label, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Cstring), writer, file_label)

writer_set_file_timestamp(writer::Ptr{Cvoid}, timestamp::DateTime) =
    ccall((:readstat_writer_set_file_timestamp, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, UInt), writer, datetime2unix(timestamp))

writer_set_file_format_version(writer::Ptr{Cvoid}, file_format_version::Integer) =
    ccall((:readstat_writer_set_file_format_version, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, UInt8), writer, file_format_version)

writer_set_table_name(writer::Ptr{Cvoid}, table_name::AbstractString) =
    ccall((:readstat_writer_set_table_name, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Cstring), writer, table_name)

writer_set_file_format_is_64bit(writer::Ptr{Cvoid}, is_64bit::Bool) =
    ccall((:readstat_writer_set_file_format_is_64bit, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Cint), writer, is_64bit)

writer_set_compression(writer::Ptr{Cvoid}, compression::readstat_compress_t) =
    ccall((:readstat_writer_set_compression, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, readstat_compress_t), writer, compression)

for ext in (:dta, :sav, :por, :sas7bdat, :xport)
    begin_writing = Symbol(:begin_writing_, ext)
    readstat_begin_writing = QuoteNode(Symbol(:readstat_begin_writing_, ext))
    @eval begin $begin_writing(writer::Ptr{Cvoid}, user_ctx::Ref{Cvoid},
        row_count::Integer) = ccall(($readstat_parse_ext, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Ref{Cvoid}, Clong), writer, user_ctx, row_count)
    end
end

begin_row(writer::Ptr{Cvoid}) =
    ccall((:readstat_begin_row, libreadstat), readstat_error_t, (Ptr{Cvoid},), writer)

insert_int8_value(writer::Ptr{Cvoid}, variable::Ptr{Cvoid}, value::Int8) =
    ccall((:readstat_insert_int8_value, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Ptr{Cvoid}, Cchar), writer, variable, value)

insert_int16_value(writer::Ptr{Cvoid}, variable::Ptr{Cvoid}, value::Int16) =
    ccall((:readstat_insert_int16_value, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Ptr{Cvoid}, Cshort), writer, variable, value)

insert_int32_value(writer::Ptr{Cvoid}, variable::Ptr{Cvoid}, value::Int32) =
    ccall((:readstat_insert_int32_value, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Ptr{Cvoid}, Cint), writer, variable, value)

insert_float_value(writer::Ptr{Cvoid}, variable::Ptr{Cvoid}, value::Float32) =
    ccall((:readstat_insert_float_value, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Ptr{Cvoid}, Cfloat), writer, variable, value)

insert_double_value(writer::Ptr{Cvoid}, variable::Ptr{Cvoid}, value::Float64) =
    ccall((:readstat_insert_double_value, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Ptr{Cvoid}, Cdouble), writer, variable, value)

insert_string_value(writer::Ptr{Cvoid}, variable::Ptr{Cvoid}, value::AbstractString) =
    ccall((:readstat_insert_string_value, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Ptr{Cvoid}, Cstring), writer, variable, value)

insert_missing_value(writer::Ptr{Cvoid}, variable::Ptr{Cvoid}) =
    ccall((:readstat_insert_missing_value, libreadstat),
        readstat_error_t, (Ptr{Cvoid}, Ptr{Cvoid}), writer, variable)

end_row(writer::Ptr{Cvoid}) =
    ccall((:readstat_end_row, libreadstat), readstat_error_t, (Ptr{Cvoid},), writer)

end_writing(writer::Ptr{Cvoid}) =
    ccall((:readstat_end_writing, libreadstat), readstat_error_t, (Ptr{Cvoid},), writer)

writer_free(writer::Ptr{Cvoid}) =
    ccall((:readstat_writer_free, libreadstat), Cvoid, (Ptr{Cvoid},), writer)
