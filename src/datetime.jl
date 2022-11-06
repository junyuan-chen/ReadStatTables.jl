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
    "YYMMDDB", "YYMMDDD", "YYMMDDN", "YYMMDDP", "YYMMDDS", "DAY", "DOWNAME"
]
const sas_datetime_formats = [
    "DATETIME", "DATETIME18", "DATETIME19",  "DATETIME20", "DATETIME21", "DATETIME22", "TOD"
]
const sas_time_formats = ["TIME", "HHMM", "TIME20.3", "TIME20", "HOUR", "TIME5"]

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

const dt_formats = Dict{Val, Dict}(
    Val(:dta) => stata_dt_formats,
    Val(:sav) => spss_dt_formats,
    Val(:por) => spss_dt_formats,
    Val(:sas7bdat) => sas_dt_formats,
    Val(:xport) => sas_dt_formats
)

"""
    parse_datetime(col::Vector, epoch::Union{DateTime,Date}, delta::Period)
    parse_datetime(col::Vector, epoch::Union{DateTime,Date}, delta::Period, missingvalue)

Construct a vector of time values of type `DateTime` or `Date`
by interpreting the elements in `col` as the number of periods passed
since `epoch` with the length of each period being `delta`.
If `missingvalue` is specified,
indices where the elements in `col` are equal to `missingvalue` based on `isequal`
are set to be `missing` no matter what is specified with `missingvalue`.
"""
function parse_datetime(col::Vector, epoch::Union{DateTime,Date}, delta::Period)
    out = Vector{typeof(epoch)}(undef, length(col))
    @inbounds for i in eachindex(col)
        v = col[i]
        out[i] = epoch + v * delta
    end
    return out
end

# Missing value is set to be missing no matter what is specified with missingvalue
function parse_datetime(col::Vector, epoch::Union{DateTime,Date}, delta::Period, missingvalue)
    out = Vector{Union{typeof(epoch), Missing}}(undef, length(col))
    @inbounds for i in eachindex(col)
        v = col[i]
        out[i] = isequal(v, missingvalue) ? missing : epoch + v * delta
    end
    return out
end
