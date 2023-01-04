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
    READSTAT_ALIGNMENT_UNKNOWN, READSTAT_ERROR_OPEN, _error,
    Int8Column, _pushmissing!, _pushchain!, _setntasks
using SentinelArrays: SentinelArray, SentinelVector, ChainedVector
using StructArrays: StructVector
using Tables

const tests = [
    "LabeledArrays",
    "columns",
    "table",
    "readstat",
    "writestat"
]

printstyled("Running tests:\n", color=:blue, bold=true)

@time for test in tests
    if VERSION < v"1.6" && test == "writestat"
        continue
    end
    include("$test.jl")
    println("\033[1m\033[32mPASSED\033[0m: $(test)")
end
