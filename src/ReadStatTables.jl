module ReadStatTables

using CEnum: @cenum
using DataAPI: refpool
using Dates
using Dates: unix2datetime
using InlineStrings
using MappedArrays: MappedArray, mappedarray
using PooledArrays: PooledArray, PooledVector, RefArray, _label
using PrettyTables: pretty_table
using ReadStat_jll
using SentinelArrays: SentinelVector, ChainedVector
using StructArrays: StructVector
using Tables

import DataAPI: defaultarray, refarray, unwrap, nrow, ncol,
    metadatasupport, colmetadatasupport,
    metadata, metadatakeys, metadata!, colmetadata, colmetadatakeys, colmetadata!
import Missings: disallowmissing
import PrettyTables: compact_type_str
import Tables: columnnames

export refarray, unwrap, nrow, ncol, metadata, metadatakeys, metadata!,
    colmetadata, colmetadatakeys, colmetadata!
export Date, DateTime # Needed for avoiding the "Dates." qualifier when printing tables
export String3, String7, String15, String31, String63, String127, String255
export disallowmissing
export columnnames

export LabeledValue,
       LabeledArray,
       LabeledVector,
       LabeledMatrix,
       valuelabel,
       getvaluelabels,
       convertvalue,
       valuelabels,

       ReadStatColumns,
       ChainedReadStatColumns,

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
       readstatallmeta,

       writestat

include("wrappers.jl")
include("LabeledArrays.jl")
include("datetime.jl")
include("columns.jl")
include("table.jl")
include("parser.jl")
include("readstat.jl")
include("writer.jl")
include("writestat.jl")
include("precompile.jl")

end
