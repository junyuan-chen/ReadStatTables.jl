# Stata does not have a pure time type (without counting date internally)
# SPSS does not have a pure date type (without counting time internally)
# SAS has all three
# Pure time types always start from 0 and do not need epoch
const stata_epoch_datetime = DateTime(1960, 1, 1)
const stata_epoch_date = Date(1960, 1, 1)
const sas_epoch_datetime = DateTime(1960, 1, 1)
const sas_epoch_date = Date(1960, 1, 1)
const spss_epoch_datetime = DateTime(1582, 10, 14)

# Reference: Stata documentation
# No need to handle %ty because values are already calendar years
# Only consider what matters for storage
# Any extra code for "details" that controls displaying is ignored
const stata_dt_formats = Dict{String, Tuple{Union{DateTime,Date}, Period}}(
    "%tc" => (stata_epoch_datetime, Millisecond(1)),
    "%td" => (stata_epoch_date, Day(1)),
    # %tw will be handled differently
    "%tw" => (stata_epoch_date, Week(1)),
    "%tm" => (stata_epoch_date, Month(1)),
    "%tq" => (stata_epoch_date, Month(3)),
    "%th" => (stata_epoch_date, Month(6))
)

# Reference: https://github.com/Roche/pyreadstat/blob/master/pyreadstat/_readstat_parser.pyx
# Changes are made for correction
# TOD is a display format not tied to datetime and can be time
const sas_datetime_formats = [
    "DATETIME", "DATETIME13", "DATETIME18", "DATETIME19",  "DATETIME20", "DATETIME21",
    "DATETIME22", "E8601DT", "E8601DX", "E8601DZ", "E8601LX", "E8601DN",
    "E8601LZ", "E8601TX", "E8601TZ"
]
const sas_date_formats = [
    "WEEKDATE", "MMDDYY", "DDMMYY", "YYMMDD", "DATE", "DATE9", "YYMMDD10",
    "DDMMYYB", "DDMMYYB10", "DDMMYYC", "DDMMYYC10", "DDMMYYD", "DDMMYYD10",
    "DDMMYYN6", "DDMMYYN8", "DDMMYYP", "DDMMYYP10", "DDMMYYS", "DDMMYYS10",
    "MMDDYYB", "MMDDYYB10", "MMDDYYC", "MMDDYYC10", "MMDDYYD", "MMDDYYD10",
    "MMDDYYN6", "MMDDYYN8", "MMDDYYP", "MMDDYYP10", "MMDDYYS", "MMDDYYS10",
    "MONNAME", "MONTH", "WEEKDATX", "WEEKDAY", "QTR", "QTRR", "YEAR",
    "YYMMDDB", "YYMMDDD", "YYMMDDN", "YYMMDDP", "YYMMDDS", "DAY", "DOWNAME",
    "E8601DA"
]

const sas_dt_formats = Dict{String, Tuple{Union{DateTime,Date}, Period}}(
    vcat(sas_datetime_formats .=> ((sas_epoch_datetime, Second(1)),),
        sas_date_formats .=> ((sas_epoch_date, Day(1)),))
)

function is_sas_time_format(format::AbstractString)
    startswith(format, "TIME") && return true
    # This may not be exhaustive?
    return format in ("HHMM", "HOUR", "E8601TM")
end

# Reference: https://github.com/Roche/pyreadstat/blob/master/pyreadstat/_readstat_parser.pyx
const spss_datetime_formats = [
    "DATETIME", "DATETIME8", "DATETIME17", "DATETIME20", "DATETIME23.2",
    "YMDHMS16", "YMDHMS19", "YMDHMS19.2", "YMDHMS20"
]
# These date formats still internally record seconds just like datetime
const spss_date_formats = [
    "DATE", "DATE8", "DATE11", "DATE12", "ADATE", "ADATE8", "ADATE10",
    "EDATE", "EDATE8", "EDATE10", "JDATE", "JDATE5", "JDATE7", "SDATE", "SDATE8", "SDATE10"
]

const spss_dt_formats = Dict{String, Tuple{Union{DateTime,Date}, Period}}(
    vcat(spss_datetime_formats, spss_date_formats) .=> ((spss_epoch_datetime, Second(1)),)
)

function is_spss_time_format(format::AbstractString)
    # TIME_LAPSE is for days
    startswith(format, "TIME") && format!="TIME_LAPSE" && return true
    return format == "DTIME"
end

const dt_formats = Dict{String, Dict}(
    ".dta" => stata_dt_formats,
    ".sav" => spss_dt_formats,
    ".por" => spss_dt_formats,
    ".sas7bdat" => sas_dt_formats,
    ".xpt" => sas_dt_formats
)

const ext_date_epoch = Dict{String, Date}(
    ".dta" => stata_epoch_date,
    ".sav" => spss_epoch_datetime,
    ".por" => spss_epoch_datetime,
    ".sas7bdat" => sas_epoch_date,
    ".xpt" => sas_epoch_date
)

const ext_datetime_epoch = Dict{String, DateTime}(
    ".dta" => stata_epoch_datetime,
    ".sav" => spss_epoch_datetime,
    ".por" => spss_epoch_datetime,
    ".sas7bdat" => sas_epoch_datetime,
    ".xpt" => sas_epoch_datetime
)

const ext_default_date_delta = Dict{String, Period}(
    ".dta" => Day(1),
    ".sav" => Second(1),
    ".por" => Second(1),
    ".sas7bdat" => Day(1),
    ".xpt" => Day(1)
)

const ext_default_datetime_delta = Dict{String, Period}(
    ".dta" => Millisecond(1),
    ".sav" => Second(1),
    ".por" => Second(1),
    ".sas7bdat" => Second(1),
    ".xpt" => Second(1)
)

const ext_default_date_format = Dict{String, String}(
    ".dta" => "%td",
    ".sav" => "DATE",
    ".por" => "DATE",
    ".sas7bdat" => "DATE",
    ".xpt" => "DATE"
)

const ext_default_datetime_format = Dict{String, String}(
    ".dta" => "%tc",
    ".sav" => "DATETIME",
    ".por" => "DATETIME",
    ".sas7bdat" => "DATETIME",
    ".xpt" => "DATETIME"
)

struct Num2DateTime{DT<:Union{DateTime, Date}, P<:Period}
    epoch::DT
    delta::P
end

# Raise InexactError if num cannot be converted to integer
(NDT::Num2DateTime{DT, <:Union{Day, Month}})(num) where DT =
    ismissing(num) ? num : NDT.epoch + num * NDT.delta

# For second/millisecond, round to the closest millisecond to avoid InexactError
(NDT::Num2DateTime{DT, <:Union{Millisecond, Second}})(num) where DT =
    ismissing(num) ? num :
        NDT.epoch + round(Int, num * (NDT.delta / Millisecond(1))) * Millisecond(1)

# Stata always counts week number from Jan 1 of each year
# Each year always has 52 weeks and any extra day is in Week 52
function (NDT::Num2DateTime{DT, Week})(num) where DT
    if ismissing(num)
        return num
    else
        y = floor(Int, num/52)
        return Date(year(NDT.epoch)+y, 1, 1) + Day(7*(num - 52*y))
    end
end

struct DateTime2Num{NDT<:Num2DateTime}
    ndt::NDT
end

# Take divisions when delta is a Millisecond or Second
(DTN::DateTime2Num{<:Num2DateTime{DT, <:Union{Millisecond, Second}}})(dt) where DT =
    ismissing(dt) ? dt : (dt - DTN.ndt.epoch) / DTN.ndt.delta

# Intend to be used when delta is Day(1)
(DTN::DateTime2Num{Num2DateTime{Date, Day}})(dt) =
    ismissing(dt) ? dt : round(Int32, (dt - DTN.ndt.epoch) / DTN.ndt.delta)

# This method is just for Stata %tw
function (DTN::DateTime2Num{Num2DateTime{Date, Week}})(dt)
    if ismissing(dt)
        return dt
    else
        y = year(dt) - year(DTN.ndt.epoch)
        dofy = dayofyear(dt) - 1
        # The extra days after Week 52 are counted as Week 52
        return Int32(52 * y) + min(floor(Int32, dofy / 7), Int32(51))
    end
end

function (DTN::DateTime2Num{Num2DateTime{Date, Month}})(dt)
    if ismissing(dt)
        return dt
    else
        y = year(dt) - year(DTN.ndt.epoch)
        step = 12 ÷ DTN.ndt.delta.value
        return Int32(step * y) + floor(Int32, (month(dt)-1) / DTN.ndt.delta.value)
    end
end

num2datetime(col::AbstractVector, ndt::Num2DateTime) =
    mappedarray(ndt, DateTime2Num{typeof(ndt)}(ndt), col)

datetime2num(col::AbstractVector, ndt::Num2DateTime) =
    mappedarray(DateTime2Num{typeof(ndt)}(ndt), ndt, col)

_time2num(x::Time) = x.instant.value / 1e9
_time2num(::Missing) = missing

# Only used when writing to files
time2num(col::AbstractVector) = mappedarray(_time2num, col)

"""
    HMS{T}

A wrapped numeric value of type `T` representing the number of seconds
printed in a time format `H:MM:SS.dd` on REPL.
The value may represent either the duration of time elapsed or a time point in a day.

`H` is either the number of hours elapsed or hours in a day.
Unlike `Dates.Time`, `H` is allowed to be greater than 23
because it may represent duration.
`MM` is for minutes (00 to 59).
`SS` is for seconds (00 to 59).
`dd` is for decimal fractions of a second, rounded to the closest 1/100 second (00 to 99).

Some basic operations are supported,
including comparison and addition/subtraction.
For more involved time operations,
users are expected to convert an instance of `HMS` to a more specialized object.
Conversion to `Dates.Time` is supported if `H` falls in 0 to 23.
To retrieve the wrapped numeric value, call `unwrap`.

# Examples
```jldoctest
julia> t1 = HMS(99999.99)
27:46:39.99

julia> t2 = HMS(-123.4567)
-0:02:03.46

julia> t1 < t2
false

julia> t1 + t2
27:44:36.53

julia> t1 - t2
27:48:43.45

julia> t3 = HMS(12345.6789)
3:25:45.68

julia> Time(t3)
03:25:45.6789

julia> unwrap(t3)
12345.6789
```
"""
struct HMS{T}
    value::T
    function HMS(value::T) where T<:Real
        return new{T}(value)
    end
end

"""
    unwrap(x::HMS)

Return the numeric value representing the number of seconds elapsed.
"""
unwrap(x::HMS) = x.value

# Allow comparisons between HMS and numbers
Base.:(==)(x::HMS, y::HMS) = x.value == y.value
Base.isequal(x::HMS, y::HMS) = isequal(x.value, y.value)
Base.:(<)(x::HMS, y::HMS) = x.value < y.value
Base.isless(x::HMS, y::HMS) = isless(x.value, y.value)
Base.isapprox(x::HMS, y::HMS; kwargs...) =
    isapprox(x.value, y.value; kwargs...)

Base.:(==)(x::HMS, y) = x.value == y
Base.:(==)(x, y::HMS) = x == y.value
Base.:(==)(::HMS, ::Missing) = missing
Base.:(==)(::Missing, ::HMS) = missing

Base.isequal(x::HMS, y) = isequal(x.value, y)
Base.isequal(x, y::HMS) = isequal(x, y.value)
Base.isequal(x::HMS, y::Missing) = isequal(x.value, y)
Base.isequal(x::Missing, y::HMS) = isequal(x, y.value)
Base.:(<)(x::HMS, y) = x.value < y
Base.:(<)(x, y::HMS) = x < y.value
Base.:(<)(x::HMS, y::Missing) = x.value < y
Base.:(<)(x::Missing, y::HMS) = x < y.value
Base.isless(x::HMS, y) = isless(x.value, y)
Base.isless(x, y::HMS) = isless(x, y.value)
Base.isless(x::HMS, y::Missing) = isless(x.value, y)
Base.isless(x::Missing, y::HMS) = isless(x, y.value)
Base.isapprox(x::HMS, y; kwargs...) = isapprox(x.value, y; kwargs...)
Base.isapprox(x, y::HMS; kwargs...) = isapprox(x, y.value; kwargs...)
Base.ismissing(x::HMS) = ismissing(x.value)

Base.iszero(x::HMS) = iszero(x.value)
Base.isnan(x::HMS) = isnan(x.value)
Base.isinf(x::HMS) = isinf(x.value)
Base.isfinite(x::HMS) = isfinite(x.value)

Base.hash(x::HMS, h::UInt) = hash(x.value, h)

Base.length(x::HMS) = length(x.value)

Base.:(+)(x::HMS, y::HMS) = HMS(x.value + y.value)
Base.:(+)(x::HMS, y::Real) = HMS(x.value + y)
Base.:(+)(x::Real, y::HMS) = HMS(x + y.value)
Base.:(+)(::HMS, ::Missing) = missing
Base.:(+)(::Missing, ::HMS) = missing
Base.:(-)(x::HMS, y::HMS) = HMS(x.value - y.value)
Base.:(-)(x::HMS, y::Real) = HMS(x.value - y)
Base.:(-)(x::Real, y::HMS) = HMS(x - y.value)
Base.:(-)(::HMS, ::Missing) = missing
Base.:(-)(::Missing, ::HMS) = missing
Base.:(-)(x::HMS) = HMS(-x.value)
Base.abs(x::HMS) = HMS(abs(x.value))

# When the data represent time in a day
function Time(t::HMS)
    t.value < 0 && error("Time cannot be negative")
    ns = round(Int, 1e9*t.value)
    return Time(Nanosecond(ns))
end

function _parse_time(t::Real)
    v = abs(t)
    whole_sec = floor(Int, v)
    hours, remainder = divrem(whole_sec, 3600)
    minutes, seconds = divrem(remainder, 60)
    return hours, minutes, seconds, v - whole_sec
end

function Base.show(io::IO, t::HMS)
    H, M, S, d = _parse_time(t.value)
    t.value < 0 && print(io, '-')
    d = round(Int, 100 * d) # Only print 2 decimals
    # H is intentionally not padded by 0 to hint the possibility of varying width
    print(io, H, ':', lpad(M,2,'0'), ':', lpad(S,2,'0'), '.', lpad(d,2,'0'))
end

# This allows array show to align HMS by the first ':'
function Base.alignment(io::IO, t::HMS)
    s = sprint(show, t, context=Base.nocolor(io), sizehint=0)
    i = findfirst(==(':'), s)
    return textwidth(first(s, i-1)), textwidth(SubString(s, i))
end

struct HMSCol{T, A<:AbstractVector{T}} <: AbstractVector{HMS{T}}
    a::A
    function HMSCol(a::AbstractVector{T}) where T
        nonmissingtype(T) <: Real ||
            error("Unsupported element type of $(T)")
        return new{T, typeof(a)}(a)
    end
end

"""
    refarray(x::HMSCol)
    refarray(x::SubArray{<:Any, <:Any, <:HMSCol})
    refarray(x::Base.ReshapedArray{<:Any, <:Any, <:HMSCol})
    refarray(x::SubArray{<:Any, <:Any, <:Base.ReshapedArray{<:Any, <:Any, <:HMSCol}})

Return the array of values underlying a [`HMSCol`](@ref).
"""
refarray(x::HMSCol) = x.a
refarray(x::SubArray{<:Any, <:Any, <:HMSCol}) =
    view(parent(x).a, x.indices...)
refarray(x::Base.ReshapedArray{<:Any, <:Any, <:HMSCol}) =
    reshape(parent(x).a, size(x))
refarray(x::SubArray{<:Any, <:Any, <:Base.ReshapedArray{<:Any, <:Any, <:HMSCol}}) =
    view(reshape(parent(parent(x)).a, size(parent(x))), x.indices...)

Base.size(col::HMSCol) = size(refarray(col))
Base.IndexStyle(::Type{<:HMSCol{T,A}}) where {T,A} = IndexStyle(A)

Base.@propagate_inbounds Base.getindex(col::HMSCol, i::Int) =
    (v = refarray(col)[i]; ismissing(v) ? v : HMS(v))
Base.@propagate_inbounds Base.setindex!(col::HMSCol, v, i::Int) =
    (refarray(col)[i] = unwrap(v); col)

Base.similar(col::HMSCol, ::Type{<:HMS{T}}, dims::Dims) where T =
    HMSCol(similar(refarray(col), T, dims))

# Define abbreviated element type name for printing with PrettyTables.jl
@static if isdefined(PrettyTables, :compact_type_str) # PrettyTables < v3
    PrettyTables.compact_type_str(::Type{HMS{V}}) where V =
        string("HMS{", PrettyTables.compact_type_str(V), "}")
elseif isdefined(PrettyTables, :_compact_type_str) # PrettyTables v3
    PrettyTables._compact_type_str(::Type{HMS{V}}) where V =
        string("HMS{", PrettyTables._compact_type_str(V), "}")
end
