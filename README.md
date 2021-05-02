# ReadStatTables.jl

*Load data from Stata, SAS and SPSS files into Julia tables*

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

## Quick Start

To load a data file located at `data/sample.dta`:

```julia
julia> using ReadStatTables

julia> tb = readstat("data/sample.dta")
5×7 ReadStatTable:
 Row │ mychar    mynum      mydate                dtime         mylabl           myord               mytime 
     │ String  Float64       Date?            DateTime?  Labeled{Int8}  Labeled{Int8?}             DateTime 
─────┼──────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │      a      1.1  2018-05-06  2018-05-06T10:10:10           Male             low  1960-01-01T10:10:10
   2 │      b      1.2  1880-05-06  1880-05-06T10:10:10         Female          medium  1960-01-01T23:10:10
   3 │      c  -1000.3  1960-01-01  1960-01-01T00:00:00           Male            high  1960-01-01T00:00:00
   4 │      d     -1.4  1583-01-01  1583-01-01T00:00:00         Female             low  1960-01-01T16:10:10
   5 │      e   1000.3     missing              missing           Male         missing  2000-01-01T00:00:00
```

For details, please see the [documentation][docs-stable-url].
