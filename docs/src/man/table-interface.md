# Table Interface

This page provides further details on the interface of `ReadStatTable`.

```@docs
ReadStatTable
```

## Data Columns

As a subtype of `Tables.AbstractColumns`, commonly used methods
including those defined in [Tables.jl](https://github.com/JuliaData/Tables.jl)
are implemented for `ReadStatTable`.

```@repl table
using ReadStatTables, Tables
tb = readstat("data/sample.dta")
```

A column can be accessed either by name or by position via multiple methods:

```@repl table
tb.mynum
tb[:mynum]
Tables.getcolumn(tb, :mynum)
tb[2]
Tables.getcolumn(tb, 2)
```

To check whether a column is in a `ReadStatTable`:

```@repl table
haskey(tb, :mynum)
haskey(tb, 2)
```

To check the number of rows in a `ReadStatTable`:

```@repl table
Tables.rowcount(tb)
size(tb, 1)
```

To check the number of columns in a `ReadStatTable`:

```@repl table
length(tb)
size(tb, 2)
```

Iterating a `ReadStatTable` directly results in iteration across columns:

```@repl table
for col in tb
    println(eltype(col))
end
```

## Data Values

In addition to retrieving the data columns,
it is possible to directly retrieving and modifying individual data values
via `getindex` and `setindex!`.

```@repl table
tb[1,1]
tb[1,1] = "f"
tb[1,1]
tb[1,:mylabl]
tb[1,:mylabl] = 2
tb[1,:mylabl]
```

Notice that for data columns with value labels,
these methods only deal with the underlying values and disregard the value labels.
