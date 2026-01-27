module ReadStatTablesDataFramesExt

using DataFrames
using ReadStatTables

# Follow compact_type_str to get more readable type printing
DataFrames.compacttype(::Type{<:LabeledValue{V}}, maxwidth::Int) where V =
    string("Labeled{", DataFrames.compacttype(V, maxwidth), "}")

end # module
