# ReadStatTables.jl

Welcome to the documentation site for ReadStatTables.jl!

[ReadStatTables.jl](https://github.com/junyuan-chen/ReadStatTables.jl)
is a Julia package for reading data files from Stata, SAS and SPSS into
a [Tables.jl](https://github.com/JuliaData/Tables.jl)-compatible table.
It utilizes the [ReadStat](https://github.com/WizardMac/ReadStat) C library
developed by [Evan Miller](https://www.evanmiller.org)
for parsing the data files.
The same C library is also the backend of popular packages in other languages such as
[pyreadstat](https://github.com/Roche/pyreadstat) for Python
and [haven](https://github.com/tidyverse/haven) for R.
As the Julia counterpart for similar purposes,
ReadStatTables.jl leverages the state-of-the-art Julia ecosystem
for usability and performance.
Its read performance dominates all related packages
based on the benchmark results
[here](https://github.com/junyuan-chen/ReadStatTablesBenchmarks).

```@raw html
<p align="center">
  <img src="https://raw.githubusercontent.com/junyuan-chen/ReadStatTablesBenchmarks/main/results/stable/stata_10k_500.svg" width="70%"><br>
</p>
```

## Features

ReadStatTables.jl provides the following features in addition to
wrapping the C interface of ReadStat.

- Efficient data collection from ReadStat parser to a [Tables.jl](https://github.com/JuliaData/Tables.jl)-compatible column table `ReadStatTable`.
- Interface of file-level and variable-level metadata compatible with [DataAPI.jl](https://github.com/JuliaData/DataAPI.jl).
- Integration of value labels into data columns via a custom array type `LabeledArray`.
- Translation of date and time values into Julia time types `Date` and `DateTime`.

## Supported File Formats

ReadStatTables.jl recognizes data files with the following file extensions at this moment:

- Stata: `.dta`.
- SAS: `.sas7bdat` and `.xpt`.
- SPSS: `.sav` and `.por`.

## Installation

ReadStatTables.jl can be installed with the Julia package manager
[Pkg](https://docs.julialang.org/en/v1/stdlib/Pkg/).
From the Julia REPL, type `]` to enter the Pkg REPL and run

```
pkg> add ReadStatTables
```

## Known Limitations

The development of ReadStatTables.jl is not fully complete.
The main limitations are the following:

- Read support of value labels for SAS files is absent.
- All missing values are represented by a single value `missing`.[^1]
- Write support of the file formats has not been implemented.

[^1]: The statistical software may accept multiple values for representing missing values (e.g., `.a`, `.b`,..., `.z` in Stata). These original values can be recognized by the parser but are not integrated into the output at this moment.
