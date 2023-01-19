# ReadStatTables.jl

*Read and write Stata, SAS and SPSS data files with Julia tables*

[![CI-stable][CI-stable-img]][CI-stable-url]
[![codecov][codecov-img]][codecov-url]
[![PkgEval][pkgeval-img]][pkgeval-url]
[![docs-stable][docs-stable-img]][docs-stable-url]
[![docs-dev][docs-dev-img]][docs-dev-url]

[CI-stable-img]: https://github.com/junyuan-chen/ReadStatTables.jl/workflows/CI-stable/badge.svg
[CI-stable-url]: https://github.com/junyuan-chen/ReadStatTables.jl/actions?query=workflow%3ACI-stable

[codecov-img]: https://codecov.io/gh/junyuan-chen/ReadStatTables.jl/branch/main/graph/badge.svg
[codecov-url]: https://codecov.io/gh/junyuan-chen/ReadStatTables.jl

[pkgeval-img]: https://juliaci.github.io/NanosoldierReports/pkgeval_badges/R/ReadStatTables.svg
[pkgeval-url]: https://juliaci.github.io/NanosoldierReports/pkgeval_badges/R/ReadStatTables.html

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://junyuan-chen.github.io/ReadStatTables.jl/stable/

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://junyuan-chen.github.io/ReadStatTables.jl/dev/

[ReadStatTables.jl](https://github.com/junyuan-chen/ReadStatTables.jl)
is a Julia package for reading and writing Stata, SAS and SPSS data files with
[Tables.jl](https://github.com/JuliaData/Tables.jl)-compatible tables.
It utilizes the [ReadStat](https://github.com/WizardMac/ReadStat) C library
developed by [Evan Miller](https://www.evanmiller.org)
for parsing and writing the data files.
The same C library is also the backend of popular packages in other languages such as
[pyreadstat](https://github.com/Roche/pyreadstat) for Python
and [haven](https://github.com/tidyverse/haven) for R.
As the Julia counterpart for similar purposes,
ReadStatTables.jl leverages the state-of-the-art Julia ecosystem
for usability and performance.
Its read performance, especially when taking advantage of multiple threads,
surpasses all related packages by a sizable margin
based on the benchmark results
[here](https://github.com/junyuan-chen/ReadStatTablesBenchmarks):

<p align="center">
  <img src="https://raw.githubusercontent.com/junyuan-chen/ReadStatTablesBenchmarks/main/results/stable/stata_10k_500.svg" height="252"><br>
</p>

## Features

ReadStatTables.jl provides the following features in addition to
wrapping the C interface of ReadStat:

- Fast multi-threaded data collection from ReadStat parsers to a [Tables.jl](https://github.com/JuliaData/Tables.jl)-compatible `ReadStatTable`
- Interface of file-level and variable-level metadata compatible with [DataAPI.jl](https://github.com/JuliaData/DataAPI.jl)
- Integration of value labels into data columns via a custom array type `LabeledArray`
- Translation of date and time values into Julia time types `Date` and `DateTime`
- Write support for [Tables.jl](https://github.com/JuliaData/Tables.jl)-compatible tables (experimental)

## Supported File Formats

ReadStatTables.jl recognizes data files with the following file extensions at this moment:

- Stata: `.dta`
- SAS: `.sas7bdat` and `.xpt`
- SPSS: `.sav` and `.por`

## Installation

ReadStatTables.jl can be installed with the Julia package manager
[Pkg](https://docs.julialang.org/en/v1/stdlib/Pkg/).
From the Julia REPL, type `]` to enter the Pkg REPL and run:

```
pkg> add ReadStatTables
```

## Quick Start

To read a data file located at `data/sample.dta`:

```julia
julia> using ReadStatTables

julia> tb = readstat("data/sample.dta")
5×7 ReadStatTable:
 Row │  mychar    mynum      mydate                dtime         mylabl           myord               mytime 
     │ String3  Float64       Date?            DateTime?  Labeled{Int8}  Labeled{Int8?}             DateTime 
─────┼───────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │       a      1.1  2018-05-06  2018-05-06T10:10:10           Male             low  1960-01-01T10:10:10
   2 │       b      1.2  1880-05-06  1880-05-06T10:10:10         Female          medium  1960-01-01T23:10:10
   3 │       c  -1000.3  1960-01-01  1960-01-01T00:00:00           Male            high  1960-01-01T00:00:00
   4 │       d     -1.4  1583-01-01  1583-01-01T00:00:00         Female             low  1960-01-01T16:10:10
   5 │       e   1000.3     missing              missing           Male         missing  2000-01-01T00:00:00
```

To access a column from the above table:

```julia
julia> tb.myord
5-element LabeledVector{Union{Missing, Int8}, Vector{Union{Missing, Int8}}, Union{Char, Int32}}:
 1 => low
 2 => medium
 3 => high
 1 => low
 missing => missing
```

Notice that for data variables with value labels,
both the original values and the value labels are preserved.

File-level and variable-level metadata can be retrieved and modified
via methods compatible with [DataAPI.jl](https://github.com/JuliaData/DataAPI.jl):

```julia
julia> metadata(tb)
ReadStatMeta:
  row count           => 5
  var count           => 7
  modified time       => 2021-04-23T04:36:00
  file format version => 118
  file label          => A test file
  file extension      => .dta

julia> colmetadata(tb, :mylabl)
ReadStatColMeta:
  label         => labeled
  format        => %16.0f
  type          => READSTAT_TYPE_INT8
  value label   => mylabl
  storage width => 1
  display width => 16
  measure       => READSTAT_MEASURE_UNKNOWN
  alignment     => READSTAT_ALIGNMENT_RIGHT
```

For more details, please see the [documentation][docs-stable-url].
