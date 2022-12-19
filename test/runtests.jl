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
    "readstat"
]

printstyled("Running tests:\n", color=:blue, bold=true)

@testset "ReadStatTables" verbose=true begin
    for test in tests
        @testset "$test" verbose=true begin
            include("$test.jl")
        end
    end
end