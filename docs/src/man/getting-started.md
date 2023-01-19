# Getting Started

An overview of the usage of
[ReadStatTables.jl](https://github.com/junyuan-chen/ReadStatTables.jl) is provided below.
For instructions on installation, see [Installation](@ref).

## Reading a Data File

Suppose we have a Stata `.dta` file located at `data/sample.dta`.
To read this file into Julia:

```@repl getting-started
using ReadStatTables
tb = readstat("data/sample.dta")
```

Here is how we read the above result:[^1]

- Variable names from the data file are displayed in the first row.
- Element type of each variable is displayed below the corresponding variable name.
- The values of each variable are displayed column-wise starting from the third row.

Some additional details to be noted:

- If a variable contains any missing value, there is a question mark `?` in the displayed element type.
- By default, all missing values are treated as [`missing`](https://docs.julialang.org/en/v1/manual/missing/), a special value in Julia.
- The date and time values have been translated into `Date` and `DateTime` respectively.[^2]
- Labels instead of the numeric values are displayed for variables with value labels.
- `Labeled{Int8}` is an abbreviation for [`LabeledValue{Int8}`](@ref).

## Accessing Individual Objects

A vector of all variable names can be obtained as follows:

```@repl getting-started
columnnames(tb)
```

To retrieve the array containing data for a specific variable:

```@repl getting-started
tb.mylabl
```

!!! note

    The returned array is exactly the same array holding the data for the table.
    Therefore, modifying elements in the returned array
    will also change the data in the table.
    To avoid such changes, please
    [`copy`](https://docs.julialang.org/en/v1/base/base/#Base.copy) the array first.

Metadata for the data file can be accessed from `tb`
using methods that are compatible with [DataAPI.jl](https://github.com/JuliaData/DataAPI.jl).

```@repl getting-started
metadata(tb)
colmetadata(tb)
colmetadata(tb, :myord)
```

## Type Conversions

The interface provided by ReadStatTables.jl allows basic tasks.
In case more complicated operations are needed,
it is easy to convert the objects into other types.

### Converting ReadStatTable

The table returned by [`readstat`](@ref) is a [`ReadStatTable`](@ref).
Converting a `ReadStatTable` to another table type is easy,
thanks to the widely supported [Tables.jl](https://github.com/JuliaData/Tables.jl) interface.

For example, to convert a `ReadStatTable` to a `DataFrame` from
[DataFrames.jl](https://github.com/JuliaData/DataFrames.jl):

```@repl getting-started
using DataFrames
df = DataFrame(tb)
```

Metadata contained in a `ReadStatTable` are preserved in the converted `DataFrame`
when working with DataFrames.jl version `v1.4.0` or above,
which supports the same [DataAPI.jl](https://github.com/JuliaData/DataAPI.jl)
interface for metadata:

```@repl getting-started
metadata(df)
colmetadata(df, :myord)
```

### Converting LabeledArray

Variables with value labels are stored in [`LabeledArray`](@ref)s.
To convert a `LabeledArray` to another array type,
we may either obtain an array of [`LabeledValue`](@ref)s
or collect the values and labels separately.
The data values can be directly retrieved by calling [`refarray`](@ref):

```@repl getting-started
refarray(tb.mylabl)
```

!!! note

    The array returned by `refarray`
    is exactly the same array underlying the `LabeledArray`.
    Therefore, modifying the elements of the array
    will also mutate the values in the associated `LabeledArray`.

If only the value labels are needed,
we can obtain an iterator of the value labels via [`valuelabels`](@ref).
For example, to convert a `LabeledArray` to a `CategoricalArray` from
[CategoricalArrays.jl](https://github.com/JuliaData/CategoricalArrays.jl):

```@repl getting-started
using CategoricalArrays
CategoricalArray(valuelabels(tb.mylabl))
```

It is also possible to only convert the type of the underlying data values:

```@repl getting-started
convertvalue(Int32, tb.mylabl)
```

```@docs
convertvalue
```

## Writing a Data File

To write a table to a supported data file format:

```@repl getting-started
# Create a data frame for illustration
df = DataFrame(readstat("data/alltypes.dta")); emptycolmetadata!(df)
out = writestat("data/write_alltypes.dta", df)
```

The returned table `out` contains the actual data (including metadata)
that are exposed to the writer.

Value labels attached to a `LabeledArray` are always preserved in the output file.
If the input table contains any column of type `CategoricalArray` or `PooledArray`,
value labels are created and written automatically by default:

```@repl getting-started
using PooledArrays
df[!,:vbyte] = CategoricalArray(valuelabels(df.vbyte))
df[!,:vint] = PooledArray(valuelabels(df.vint))
out = writestat("data/write_alltypes.dta", df)
```

Notice that in the returned table, the columns `vbyte` and `vint` are `LabeledArray`s:

```@repl getting-started
out.vbyte
out.vint
```

!!! warning

    The write support is experimental and not fully developed.
    Caution should be taken when writing the data files.

## More Options

The behavior of `readstat` can be adjusted by passing keyword arguments:

```@docs
readstat
```

The accepted types of values for selecting certain variables (data columns) are shown below:

```@docs
ReadStatTables.ColumnIndex
ReadStatTables.ColumnSelector
```

File-level metadata can be obtained without reading the entire data file:

```@docs
readstatmeta
```

To additionally collect variable-level metadata and all value labels:

```@docs
readstatallmeta
```

For writing tables to data files,
one may gain more control by first converting a table to a `ReadStatTable`:

```@docs
writestat
ReadStatTable(table, ext::AbstractString; kwargs...)
ReadStatTable(table::ReadStatTable, ext::AbstractString; kwargs...)
```

[^1]: The printed output is generated with [PrettyTables.jl](https://github.com/ronisbr/PrettyTables.jl).

[^2]: The time types `Date` and `DateTime` are from the [Dates](https://docs.julialang.org/en/v1/stdlib/Dates/) module of Julia.
