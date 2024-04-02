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

const ext_date_epoch = Dict{String, Date}(
    ".dta" => stata_epoch_date,
    ".sav" => spss_epoch_time,
    ".por" => spss_epoch_time,
    ".sas7bdat" => sas_epoch_date,
    ".xpt" => sas_epoch_date
)

const ext_time_epoch = Dict{String, DateTime}(
    ".dta" => stata_epoch_time,
    ".sav" => spss_epoch_time,
    ".por" => spss_epoch_time,
    ".sas7bdat" => sas_epoch_time,
    ".xpt" => sas_epoch_time
)

const ext_default_date_delta = Dict{String, Period}(
    ".dta" => Day(1),
    ".sav" => Second(1),
    ".por" => Second(1),
    ".sas7bdat" => Day(1),
    ".xpt" => Day(1)
)

const ext_default_time_delta = Dict{String, Period}(
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

const ext_default_time_format = Dict{String, String}(
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

(NDT::Num2DateTime{DT, P})(num) where {DT, P} =
    ismissing(num) ? num : NDT.epoch + num * NDT.delta

struct DateTime2Num{NDT<:Num2DateTime}
    ndt::NDT
end

# Take divisions when delta is a Millisecond or Second
(DTN::DateTime2Num{<:Num2DateTime{<:Any, <:Union{Millisecond, Second}}})(dt) =
    ismissing(dt) ? dt : (dt - DTN.ndt.epoch) / DTN.ndt.delta

# Use integers for all other types of delta
# Division can result in type promotion error for some types
function (DTN::DateTime2Num{Num2DateTime{DT, P}})(dt) where {DT, P}
    if ismissing(dt)
        return dt
    elseif dt > DTN.ndt.epoch
        return max(length(DTN.ndt.epoch:DTN.ndt.delta:dt) - 1, 0)
    elseif dt < DTN.ndt.epoch
        return - max(length(dt:DTN.ndt.delta:DTN.ndt.epoch) - 1, 0)
    else
        return 0
    end
end

num2datetime(col::AbstractVector, ndt::Num2DateTime) =
    mappedarray(ndt, DateTime2Num{typeof(ndt)}(ndt), col)

datetime2num(col::AbstractVector, ndt::Num2DateTime) =
    mappedarray(DateTime2Num{typeof(ndt)}(ndt), ndt, col)

