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
- Element type for each variable is displayed below the corresponding variable name.
- The values for each variable are displayed column-wise starting from the third row.

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

The types provided by ReadStatTables.jl should be sufficient for basic tasks.
In case more complicated operations are needed,
it is easy to convert the objects into other types.

### Converting ReadStatTable

The table returned by `readstat` is a `ReadStatTable`.
Converting the table into another table type is easy
as long as the table type can be constructed with an input following
the [Tables.jl](https://github.com/JuliaData/Tables.jl) interface.

For example, to convert the table into a `DataFrame` from
[DataFrames.jl](https://github.com/JuliaData/DataFrames.jl):

```@repl getting-started
using DataFrames
df = DataFrame(tb)
```

### Converting LabeledArray

Variables with value labels are stored in `LabeledArray`s.
To convert a `LabeledArray` into another array type,
we need to determine whether we should keep the values or the labels.
If only the labels contain the relevant information,
we can make use of the `labels` function which returns an iterator for the labels.
For example, to convert a `LabeledArray` to a `CategoricalArray` from
[CategoricalArrays.jl](https://github.com/JuliaData/CategoricalArrays.jl):

```@repl getting-started
using CategoricalArrays
CategoricalArray(labels(tb.mylabl))
```

Sometimes, the values have special meanings while the labels are not so important.
To access the array of values underlying a `LabeledArray` directly:

```@repl getting-started
refarray(tb.mylabl)
```

Alternatively, convert a `LabeledArray` to an array with appropriate element type:

```@repl getting-started
convert(Vector{Int}, tb.mylabl)
```

In the last example, the element type of the output array has become `Int`
while the labels are ignored.

!!! note

    The array returned by `refarray` (and by `convert` if element type is not converted)
    is exactly the same array underlying the `LabeledArray`.
    Therefore, modifying the elements of the array
    will also mutate the values in the associated `LabeledArray`.

## More Options

The behavior of `readstat` can be adjusted by passing keyword arguments.

```@docs
readstat
```

The values used to specify certain variables (columns)
must be either a `ColumnIndex` or a vector of `ColumnIndex`s.

```@docs
ReadStatTables.ColumnIndex
ReadStatTables.ColumnSelector
```

[^1]: The printed output is generated with [PrettyTables.jl](https://github.com/ronisbr/PrettyTables.jl).

[^2]: The time types `Date` and `DateTime` are from the [Dates](https://docs.julialang.org/en/v1/stdlib/Dates/) module of Julia.
