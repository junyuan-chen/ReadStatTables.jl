const extmap = Dict{String, Val}(
    ".dta" => Val(:dta),
    ".sav" => Val(:sav),
    ".por" => Val(:por),
    ".sas7bdat" => Val(:sas7bdat),
    ".xpt" => Val(:xport)
)

const ColumnIndex = Union{Symbol, String, Integer}
const ColumnSelector = Union{ColumnIndex, AbstractVector{<:Union{ColumnIndex}}}

function _parse_usecols(file, usecols::Union{Symbol, String})
    c = findfirst(x->x==Symbol(usecols), file.headers)
    c === nothing && throw(ArgumentError("column name $usecols is not found"))
    return (c,)
end

function _parse_usecols(file, usecols::AbstractVector{<:Union{Symbol, String}})
    lookup = Dict(n=>i for (i, n) in enumerate(file.headers))
    icols = Vector{Int}(undef, length(usecols))
    for (i, c) in enumerate(usecols)
        k = get(lookup, Symbol(c), 0)
        k == 0 && throw(ArgumentError("column name $c is not found"))
        icols[i] = k
    end
    return icols
end

function _parse_usecols(file, usecols::Integer)
    N = length(file.data)
    0 < usecols <= N || throw(ArgumentError("invalid column index $usecols"))
    return (usecols,)
end

function _parse_usecols(file, usecols::AbstractVector{<:Integer})
    N = length(file.data)
    for c in usecols
        0 < c <= N || throw(ArgumentError("invalid column index $c"))
    end
    return usecols
end

_selected(i::Int, n::Symbol, sel::Bool) = sel
_selected(i::Int, n::Symbol, sel::Integer) = i == sel
_selected(i::Int, n::Symbol, sel::Symbol) = n == sel
_selected(i::Int, n::Symbol, sel::AbstractVector{<:Integer}) = i in sel
_selected(i::Int, n::Symbol, sel::AbstractVector{Symbol}) = n in sel

function _to_array!(d::DataValueVector, a::Vector, imissing::Int, missingvalue)
    if imissing > 1
        @inbounds for i in 1:imissing-1
            a[i] = d.values[i]
        end
    end
    @inbounds for i in imissing:length(d)
        a[i] = d.isna[i] ? missingvalue : d.values[i]
    end
end

function _to_array(d::DataValueVector, missingvalue)
    N = length(d)
    imissing = findfirst(d.isna)
    if imissing === nothing
        return d.values, false
    else
        V = promote_type(typeof(d).parameters[1], typeof(missingvalue))
        a = Vector{V}(undef, N)
        _to_array!(d, a, imissing, missingvalue)
        return a, true
    end
end

function readstat(filename::AbstractString;
        usecols::Union{ColumnSelector, Nothing}=nothing,
        convert_datetime::Union{Bool, ColumnSelector}=true,
        apply_value_labels::Union{Bool, ColumnSelector}=true,
        missingvalue=missing)

    ext = lowercase(splitext(filename)[2])
    filetype = get(extmap, ext, nothing)
    filetype === nothing && throw(ArgumentError("file extension $ext is not supported"))
    file = read_data_file(filename, filetype)
    if usecols === nothing
        icols = 1:length(file.data)
        names = file.headers
    else
        icols = _parse_usecols(file, usecols)
        names = [file.headers[i] for i in icols]
    end
    convert_datetime isa AbstractVector{String} &&
        (convert_datetime = Symbol.(convert_datetime))
    # ReadStat.jl does not handle value labels for SAS at this moment
    (filetype == Val(:sas7bdat) || filetype == Val(:xport)) &&
        (apply_value_labels = false)
    apply_value_labels isa AbstractVector{String} &&
        (apply_value_labels = Symbol.(apply_value_labels))

    cols = Vector{AbstractVector}(undef, length(icols))
    varlabels = Dict{Symbol, String}()
    formats = Dict{Symbol, String}()
    val_label_keys = Dict{Symbol, String}()
    @inbounds for (i, c) in enumerate(icols)
        col, hasmissing = _to_array(file.data[c], missingvalue)
        n = names[i]
        if _selected(c, n, convert_datetime)
            format = file.formats[c]
            filetype == Val(:dta) && (format = first(format, 3))
            dtpara = get(dt_formats[filetype], format, nothing)
            if dtpara !== nothing
                if hasmissing
                    col = parse_datetime(col, dtpara..., missingvalue)
                else
                    col = parse_datetime(col, dtpara...)
                end
            end
        end
        if _selected(c, n, apply_value_labels)
            lblname = file.val_label_keys[c]
            if lblname != ""
                lbls = convert(Dict{eltype(col), String}, file.val_label_dict[lblname])
                col = LabeledArray(col, lbls)
            end
        end
        cols[i] = col
        varlabels[n] = file.labels[c]
        formats[n] = file.formats[c]
        val_label_keys[n] = file.val_label_keys[c]
    end
    meta = ReadStatMeta(varlabels, formats, val_label_keys,
        file.val_label_dict, file.filelabel, file.timestamp, ext)
    return ReadStatTable(cols, names, meta)
end
