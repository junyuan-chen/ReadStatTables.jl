# ReadStatTables.jl

Welcome to the documentation site for ReadStatTables.jl!

[ReadStatTables.jl](https://github.com/junyuan-chen/ReadStatTables.jl)
is a Julia package for reading and writing Stata, SAS and SPSS data files with
a [Tables.jl](https://github.com/JuliaData/Tables.jl)-compatible table.[^1]
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

```@raw html
<p align="center">
  <img src="https://raw.githubusercontent.com/junyuan-chen/ReadStatTablesBenchmarks/main/results/stable/stata_10k_500.svg" width="70%"><br>
</p>
```

## Features

ReadStatTables.jl provides the following features in addition to
wrapping the C interface of ReadStat:

- Fast multi-threaded data collection from ReadStat parsers to a [Tables.jl](https://github.com/JuliaData/Tables.jl)-compatible column table `ReadStatTable`.
- Interface of file-level and variable-level metadata compatible with [DataAPI.jl](https://github.com/JuliaData/DataAPI.jl).
- Integration of value labels into data columns via a custom array type `LabeledArray`.
- Translation of date and time values into Julia time types `Date` and `DateTime`.
- Write support for [Tables.jl](https://github.com/JuliaData/Tables.jl)-compatible tables (experimental).

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

## Known Limitations

The development of ReadStatTables.jl is not fully complete.
The main limitations to be addressed are the following:

- Read support of value labels for SAS files is temporarily absent.
- All missing values are represented by a single value `missing`.[^2]
- Write support of the file formats is experimental and not fully developed.

[^1]:

    Development for the reading capability is temporarily prioritized over that
    for the writing capability.
    Implementation for the write support only started recently
    and should be considered as experimental.

[^2]:

    The statistical software may accept multiple values for representing missing values
    (e.g., `.a`, `.b`,..., `.z` in Stata).
    These original values can be recognized by the parser
    but are not integrated into the output at this moment.
