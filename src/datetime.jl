const stata_epoch_time = DateTime(1960, 1, 1)
const stata_epoch_date = Date(1960, 1, 1)
const sas_epoch_time = DateTime(1960, 1, 1)
const sas_epoch_date = Date(1960, 1, 1)
const spss_epoch_time = DateTime(1582, 10, 14)

# Reference: Stata documentation
const stata_dt_formats = Dict{String, Tuple{Union{DateTime,Date}, Period}}(
    "%tc" => (stata_epoch_time, Millisecond(1)),
    "%td" => (stata_epoch_date, Day(1)),
    "%tw" => (stata_epoch_date, Week(1)),
    "%tm" => (stata_epoch_date, Month(1)),
    "%tq" => (stata_epoch_date, Month(3)),
    "%th" => (stata_epoch_date, Month(6)),
    "%ty" => (Date(0), Year(1))
)

# Reference: https://github.com/Roche/pyreadstat/blob/master/pyreadstat/_readstat_parser.pyx
const sas_date_formats = [
    "WEEKDATE", "MMDDYY", "DDMMYY", "YYMMDD", "DATE", "DATE9", "YYMMDD10",
    "DDMMYYB", "DDMMYYB10", "DDMMYYC", "DDMMYYC10", "DDMMYYD", "DDMMYYD10",
    "DDMMYYN6", "DDMMYYN8", "DDMMYYP", "DDMMYYP10", "DDMMYYS", "DDMMYYS10",
    "MMDDYYB", "MMDDYYB10", "MMDDYYC", "MMDDYYC10", "MMDDYYD", "MMDDYYD10",
    "MMDDYYN6", "MMDDYYN8", "MMDDYYP", "MMDDYYP10", "MMDDYYS", "MMDDYYS10",
    "MONNAME", "MONTH", "WEEKDATX", "WEEKDAY", "QTR", "QTRR", "YEAR",
    "YYMMDDB", "YYMMDDD", "YYMMDDN", "YYMMDDP", "YYMMDDS", "DAY", "DOWNAME",
    "E8601DA", "E8601DN"
]
const sas_datetime_formats = [
    "DATETIME", "DATETIME18", "DATETIME19",  "DATETIME20", "DATETIME21",
    "DATETIME22", "TOD", "E8601DT", "E8601DX", "E8601DZ", "E8601LX",
]
const sas_time_formats = [
    "TIME", "HHMM", "TIME20.3", "TIME20", "HOUR", "TIME5", "E8601LZ", "E8601TM",
    "E8601TX", "E8601TZ"]

const sas_dt_formats = Dict{String, Tuple{Union{DateTime,Date}, Period}}(
    vcat(sas_date_formats .=> ((sas_epoch_date, Day(1)),),
        sas_datetime_formats .=> ((sas_epoch_time, Second(1)),),
        sas_time_formats .=> ((sas_epoch_time, Second(1)),))
)

# Reference: https://github.com/Roche/pyreadstat/blob/master/pyreadstat/_readstat_parser.pyx
const spss_datetime_formats = [
    "DATETIME", "DATETIME8", "DATETIME17", "DATETIME20", "DATETIME23.2",
    "YMDHMS16", "YMDHMS19", "YMDHMS19.2", "YMDHMS20"
]
const spss_date_formats = [
    "DATE", "DATE8", "DATE11", "DATE12", "ADATE", "ADATE8", "ADATE10",
    "EDATE", "EDATE8", "EDATE10", "JDATE", "JDATE5", "JDATE7", "SDATE", "SDATE8", "SDATE10"
]
const spss_time_formats = ["TIME", "DTIME", "TIME8", "TIME5", "TIME11.2"]

const spss_dt_formats = Dict{String, Tuple{Union{DateTime,Date}, Period}}(
    vcat(spss_datetime_formats, spss_date_formats, spss_time_formats) .=>
        ((spss_epoch_time, Second(1)),)
)

const dt_formats = Dict{String, Dict}(
    ".dta" => stata_dt_formats,
    ".sav" => spss_dt_formats,
    ".por" => spss_dt_formats,
    ".sas7bdat" => sas_dt_formats,
    ".xpt" => sas_dt_formats
)

"""
    parse_datetime(col, epoch::Union{DateTime,Date}, delta::Period, hasmissing::Bool)

Construct a vector of time values of type `DateTime` or `Date`
by interpreting the elements in `col` as the number of periods passed
since `epoch` with the length of each period being `delta`.
Returned object is of a type acceptable by `ReadStatColumns`.
"""
function parse_datetime(col::AbstractVector, epoch::Union{DateTime,Date}, delta::Period,
        hasmissing::Bool)
    out = SentinelVector{typeof(epoch)}(undef, length(col))
    if hasmissing
        @inbounds for i in eachindex(col)
            v = col[i]
            out[i] = ismissing(v) ? missing : epoch + round(Int64, v) * delta
        end
    else
        tar = parent(out)
        @inbounds for i in eachindex(col)
            v = col[i]
            tar[i] = epoch + round(Int64, v) * delta
        end
    end
    return out
end
