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

_string(str::Cstring) = str == C_NULL ? "" : unsafe_string(str)

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

value_is_tagged_missing(value::readstat_value_t) =
    Bool(ccall((:readstat_value_is_tagged_missing, libreadstat),
        Cint, (readstat_value_t,), value))

value_is_defined_missing(value::readstat_value_t, variable::Ptr{Cvoid}) =
    Bool(ccall((:readstat_value_is_defined_missing, libreadstat),
        Cint, (readstat_value_t, Ptr{Cvoid}), value, variable))

value_tag(value::readstat_value_t) =
    ccall((:readstat_value_tag, libreadstat), Cchar, (readstat_value_t,), value)
=#

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
    _string(ccall((:readstat_string_value, libreadstat),
        Cstring, (readstat_value_t,), value))

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
