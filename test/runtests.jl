using Test
using ReadStatTables

using CategoricalArrays
using DataAPI
using DataFrames
using Dates
using InlineStrings
using PooledArrays
using ReadStatTables: error_message, READSTAT_COMPRESS_NONE, READSTAT_ENDIAN_NONE,
    READSTAT_TYPE_INT8, READSTAT_TYPE_DOUBLE, READSTAT_MEASURE_UNKNOWN,
    READSTAT_ALIGNMENT_UNKNOWN, READSTAT_ERROR_OPEN, _pushmissing!, Int8Column, _error
using SentinelArrays: SentinelArray, SentinelVector
using StructArrays: StructVector
using Tables

const tests = [
    "LabeledArrays",
    "columns",
    "table",
    "readstat"
]

printstyled("Running tests:\n", color=:blue, bold=true)

@time for test in tests
    include("$test.jl")
    println("\033[1m\033[32mPASSED\033[0m: $(test)")
end
