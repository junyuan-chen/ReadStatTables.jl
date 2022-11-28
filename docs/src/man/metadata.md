# Metadata

```@setup meta
using ReadStatTables
tb = readstat("data/sample.dta")
```

File-level metadata associated with a data file are collected in a [`ReadStatMeta`](@ref);
while variable-level metadata associated with each data column
are collected in [`ReadStatColMeta`](@ref)s.
These metadata objects are stored in a [`ReadStatTable`](@ref) along with the data columns
and can be accessed via methods compatible with
[DataAPI.jl](https://github.com/JuliaData/DataAPI.jl).

## File-Level Metadata

Each `ReadStatTable` contains a `ReadStatMeta` for file-level metadata.

```@docs
ReadStatMeta
```

To retrieve the `ReadStatMeta` from the `ReadStatTable`:

```@repl meta
metadata(tb)
```

The value associated with a specific metadata key can be retrieved via:

```@repl meta
metadata(tb, "file_label")
metadata(tb, "file_label", style=true)
```

To obtain a complete list of metadata keys:

```@repl meta
metadatakeys(tb)
```

Metadata contained in a `ReadStatMeta` can be modified,
optionally with a metadata style set at the same time:

```@repl meta
metadata!(tb, "file_label", "A file label", style=:note)
```

Since `ReadStatMeta` has a dictionary-like interface,
one can also directly work with it:

```@repl meta
m = metadata(tb)
keys(m)
m["file_label"]
m["file_label"] = "A new file label"
copy(m)
```

## Variable-Level Metadata

A `ReadStatColMeta` is associated with each data column for variable-level metadata.

```@docs
ReadStatColMeta
```

To retrieve the `ReadStatColMeta` for a specified data column contained in a `ReadStatTable`:

```@repl meta
colmetadata(tb, :mylabl)
```

The value associated with a specific metadata key can be retrieved via:

```@repl meta
colmetadata(tb, :mylabl, "label")
colmetadata(tb, :mylabl, "label", style=true)
```

To obtain a complete list of metadata keys:

```@repl meta
colmetadatakeys(tb, :mylabl)
```

Metadata contained in a `ReadStatColMeta` can be modified,
optionally with a metadata style set at the same time:

```@repl meta
colmetadata!(tb, :mylabl, "label", "A variable label", style=:note)
```

A `ReadStatColMeta` also has a dictionary-like interface:

```@repl meta
m = colmetadata(tb, :mylabl)
keys(m)
m["label"]
copy(m)
```

However, it cannot be modified directly via `setindex!`:

```@repl meta
m["label"] = "A new label"
```

Instead, since the metadata associated with each key
are stored consecutively in arrays internally,
one may directly access the underlying array for a given metadata key:

```@docs
colmetavalues
```

```@repl meta
v = colmetavalues(tb, "label")
```

Notice that changing any value in the array returned above will
affect the corresponding `ReadStatColMeta`:

```@repl meta
colmetadata(tb, :mychar, "label")
v[1] = "char"
colmetadata(tb, :mychar, "label")
```

## Metadata Styles

Metadata styles provide additional information on
how the metadata should be processed in certain scenarios.
`ReadStatTables.jl` does not require such information.
However, specifying metadata styles can be useful
when the metadata need to be transferred to some other object
(e.g., `DataFrame` from [DataFrames.jl](https://github.com/JuliaData/DataFrames.jl)).
Packages that implement metadata-related methods compatible with
[DataAPI.jl](https://github.com/JuliaData/DataAPI.jl)
are able to recognize the metadata contained in `ReadStatTable`.

By default, all metadata have the `:default` style.
The user-specified metadata styles
are recorded in a `Dict` based on the keys of metadata:

```@repl meta
metastyle(tb)
```

All metadata associated with keys not listed above are of `:default` style.
To modify the metadata style for those associated with a given key:

```@repl meta
metastyle!(tb, "modified_time", :note)
```

The same method is also used for variable-specific metadata.
However, since the styles are only determined by the metadata keys,
metadata associated with the same key always have the same style
and hence are not distinguished across different columns.

```@repl meta
metastyle!(tb, "label", :note)
colmetadata(tb, :mychar, "label", style=true)
colmetadata(tb, :mynum, "label", style=true)
```

```@docs
metastyle
metastyle!
```
