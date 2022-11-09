module ReadStatTables

using DataValues: DataValueVector
using Dates
using PrettyTables: pretty_table
using ReadStat: read_data_file
using StructArrays: StructVector
using Tables

import DataAPI: refarray, unwrap, nrow, ncol, metadatasupport, colmetadatasupport,
    metadata, metadatakeys, metadata!, colmetadata, colmetadatakeys, colmetadata!
import PrettyTables: compact_type_str
import Tables: columnnames

export refarray, unwrap, nrow, ncol, metadata, metadatakeys, metadata!,
    colmetadata, colmetadatakeys, colmetadata!
export Date, DateTime
export columnnames

export LabeledValue,
       LabeledArray,
       LabeledVector,
       labels,

       AbstractMetaDict,
       ReadStatMeta,
       ReadStatColMeta,
       ReadStatTable,
       metastyle,
       metastyle!,
       MetaStyleView,
       ColMetaIterator,
       colmetavalues,

       readstat

include("LabeledArrays.jl")
include("datetime.jl")
include("table.jl")
include("readstat.jl")

end
