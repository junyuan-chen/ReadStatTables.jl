const stata_epoch_time = DateTime(1960, 1, 1)
const stata_epoch_date = Date(1960, 1, 1)
const sas_epoch_time = DateTime(1960, 1, 1)
const sas_epoch_date = Date(1960, 1, 1)
const spss_epoch_time = DateTime(1582, 10, 14)

# Time-of-day conventions follow pyreadstat:
# https://github.com/Roche/pyreadstat/blob/e23b1d8e56b155586cc562827972b6f7e30aab00/pyreadstat/_readstat_writer.pyx#L144-L216
const time_of_day_epoch = Time(0)
const stata_time_of_day_delta = Millisecond(1)
const sas_spss_time_of_day_delta = Second(1)

# Reference: Stata documentation
# No need to handle %ty because values are already calendar years
const stata_dt_formats = Dict{String, Tuple{Union{DateTime,Date}, Period}}(
    "%tc" => (stata_epoch_time, Millisecond(1)),
    "%td" => (stata_epoch_date, Day(1)),
    # %tw will be handled differently
    "%tw" => (stata_epoch_date, Week(1)),
    "%tm" => (stata_epoch_date, Month(1)),
    "%tq" => (stata_epoch_date, Month(3)),
    "%th" => (stata_epoch_date, Month(6))
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
    "DATETIME", "DATETIME13", "DATETIME18", "DATETIME19",  "DATETIME20", "DATETIME21",
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
const spss_time_formats = ["TIME", "DTIME", "TIME8", "TIME5", "TIME9", "TIME11.2"]

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

const ext_time_of_day_epoch = Dict{String, Time}(
    ".dta" => time_of_day_epoch,
    ".sav" => time_of_day_epoch,
    ".por" => time_of_day_epoch,
    ".sas7bdat" => time_of_day_epoch,
    ".xpt" => time_of_day_epoch
)

const ext_default_time_of_day_delta = Dict{String, Period}(
    ".dta" => stata_time_of_day_delta,
    ".sav" => sas_spss_time_of_day_delta,
    ".por" => sas_spss_time_of_day_delta,
    ".sas7bdat" => sas_spss_time_of_day_delta,
    ".xpt" => sas_spss_time_of_day_delta
)

const ext_default_time_of_day_format = Dict{String, String}(
    ".dta" => "%tcHH:MM:SS",
    ".sav" => "TIME",
    ".por" => "TIME",
    ".sas7bdat" => "TIME",
    ".xpt" => "TIME"
)

# Stata time-of-day formats per pyreadstat
const stata_time_of_day_formats = ["%tcHH:MM:SS", "%tcHH:MM"]

# Read-side lookup: format -> (Time(0), delta). Checked before dt_formats so
# time-only columns deserialize to Dates.Time rather than DateTime.
const stata_tod_dt_formats = Dict{String, Tuple{Time, Period}}(
    f => (time_of_day_epoch, stata_time_of_day_delta) for f in stata_time_of_day_formats
)

const sas_tod_dt_formats = Dict{String, Tuple{Time, Period}}(
    f => (time_of_day_epoch, sas_spss_time_of_day_delta) for f in sas_time_formats
)

const spss_tod_dt_formats = Dict{String, Tuple{Time, Period}}(
    f => (time_of_day_epoch, sas_spss_time_of_day_delta) for f in spss_time_formats
)

const ext_time_of_day_dt_formats = Dict{String, Dict{String, Tuple{Time, Period}}}(
    ".dta" => stata_tod_dt_formats,
    ".sav" => spss_tod_dt_formats,
    ".por" => spss_tod_dt_formats,
    ".sas7bdat" => sas_tod_dt_formats,
    ".xpt" => sas_tod_dt_formats
)

struct Num2DateTime{DT<:Union{DateTime, Date, Time}, P<:Period}
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

