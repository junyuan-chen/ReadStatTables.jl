module ReadStatTables

using DataValues: DataValueVector
using Dates
using PrettyTables: pretty_table
using ReadStat: read_data_file
using Tables

import PrettyTables: compact_type_str

export LabeledValue,
       LabeledArray,
       labels,

       varlabels,
       varformats,
       val_label_keys,
       val_label_dict,
       filelabel,
       filetimestamp,
       fileext,
       ReadStatTable,
       getmeta,
       ncol,
       nrow,
       columnnames,

       readstat

include("LabeledArrays.jl")
include("table.jl")
include("datetime.jl")
include("readstat.jl")

end
