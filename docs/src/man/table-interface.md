# Table Interface

This page provides further details on the interface of `ReadStatTable`.

```@docs
ReadStatTable
```

## Accessing Data in ReadStatTable

Commonly used methods are supported for working with `ReadStatTable`.
As a subtype of `Tables.AbstractColumns`,
`ReadStatTable` also supports the essential methods defined in
[Tables.jl](https://github.com/JuliaData/Tables.jl).

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

## Accessing Metadata in ReadStatTable

When calling `readstat`, a `ReadStatMeta` object,
which collects metadata from the data file,
is saved in the `ReadStatTable`.
This object can be retrieved from `ReadStatTable` via `getmeta`.

```@docs
ReadStatMeta
getmeta
```

When shown on REPL, a list of the available metadata are printed:

```@repl table
getmeta(tb)
```

Each field of `ReadStatMeta` can be accessed
either directly from `ReadStatMeta` or from `ReadStatTable`
via the corresponding accessor function.

```@docs
varlabels
varformats
val_label_keys
val_label_dict
filelabel
filetimestamp
fileext
```
