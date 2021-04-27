# ReadStatTables.jl

Welcome to the documentation site for ReadStatTables.jl!

[ReadStatTables.jl](https://github.com/junyuan-chen/ReadStatTables.jl)
is a Julia package for loading data from Stata, SAS and SPSS files into
a [Tables.jl](https://github.com/JuliaData/Tables.jl)-compatible table.
It relies on [ReadStat.jl](https://github.com/queryverse/ReadStat.jl),
which is a Julia interface of the
[ReadStat](https://github.com/WizardMac/ReadStat) C library,
for parsing the data files.
The same C library is also the backend
for popular packages such as [pyreadstat](https://github.com/Roche/pyreadstat)
and [haven](https://github.com/tidyverse/haven).

## Features

ReadStatTables.jl adds the following features on top of the read support
from [ReadStat.jl](https://github.com/queryverse/ReadStat.jl).

- A lightweight [Tables.jl](https://github.com/JuliaData/Tables.jl)-compatible column table `ReadStatTable` for basic operations.
- Integration of value labels via a customized array type `LabeledArray`.
- Translation of date and time values into Julia time types `Date` and `DateTime`.

## Supported File Formats

ReadStatTables.jl accepts file formats that ReadStat.jl supports
and selects parsers based on file extensions.

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

The functionality of ReadStatTables.jl is constrained by what ReadStat.jl achieves.
The main limitations are the following.

- Read support of value labels for SAS files is absent.
- All missing values are represented by a single value.[^1]
- Write support of the file formats is not implemented.

[^1]: The statistical software may accept multiple values for representing missing values (e.g., `.a`, `.b`,...,`.z` in Stata). These original values are not captured when reading the files.
