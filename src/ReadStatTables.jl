module ReadStatTables

using CEnum: @cenum
using Dates
using Dates: unix2datetime
using PrettyTables: pretty_table
using ReadStat_jll
using SentinelArrays: SentinelVector
using StructArrays: StructVector
using Tables

import DataAPI: refarray, unwrap, nrow, ncol, metadatasupport, colmetadatasupport,
    metadata, metadatakeys, metadata!, colmetadata, colmetadatakeys, colmetadata!
import PrettyTables: compact_type_str
import Tables: columnnames

export refarray, unwrap, nrow, ncol, metadata, metadatakeys, metadata!,
    colmetadata, colmetadatakeys, colmetadata!
export Date, DateTime # Needed for avoiding the "Dates." qualifier when printing tables
export columnnames

export LabeledValue,
       LabeledArray,
       LabeledVector,
       labels,

       ReadStatColumns,

       AbstractMetaDict,
       ReadStatMeta,
       ReadStatColMeta,
       ReadStatTable,
       metastyle,
       metastyle!,
       MetaStyleView,
       ColMetaIterator,
       colmetavalues,

       readstat,
       readstatmeta,
       valuelabels

include("wrappers.jl")
include("LabeledArrays.jl")
include("datetime.jl")
include("columns.jl")
include("table.jl")
include("parser.jl")
include("readstat.jl")

end
