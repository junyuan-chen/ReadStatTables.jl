module ReadStatTables

using DataValues: DataValueVector
using Dates
using PrettyTables: pretty_table
using ReadStat: read_data_file
using Tables

import DataAPI: refarray, unwrap
import PrettyTables: compact_type_str
import Tables: columnnames

export refarray, unwrap
export columnnames

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

       readstat

include("LabeledArrays.jl")
include("table.jl")
include("datetime.jl")
include("readstat.jl")

end
