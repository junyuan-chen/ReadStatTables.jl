using Test
using ReadStatTables

using CategoricalArrays
using DataFrames
using Dates
using ReadStat
using ReadStatTables: _parse_usecols
using Tables

const tests = [
    "LabeledArrays",
    "table",
    "readstat"
]

printstyled("Running tests:\n", color=:blue, bold=true)

@time for test in tests
    include("$test.jl")
    println("\033[1m\033[32mPASSED\033[0m: $(test)")
end
