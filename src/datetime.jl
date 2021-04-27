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
const sas_dt_formats = Dict{String, Tuple{Union{DateTime,Date}, Period}}(
    "TIME" => (sas_epoch_time, Second(1)),
    "HHMM" => (sas_epoch_time, Second(1)),
    "TIME20.3" => (sas_epoch_time, Second(1)),
    "DATETIME" => (sas_epoch_time, Second(1)),
    "DATETIME20" => (sas_epoch_time, Second(1)),
    "WEEKDATE" => (sas_epoch_date, Day(1)),
    "MMDDYY" => (sas_epoch_date, Day(1)),
    "DDMMYY" => (sas_epoch_date, Day(1)),
    "YYMMDD" => (sas_epoch_date, Day(1)),
    "DATE" => (sas_epoch_date, Day(1)),
    "DATE9" => (sas_epoch_date, Day(1)),
    "YYMMDD10" => (sas_epoch_date, Day(1))
)

# Reference: https://github.com/Roche/pyreadstat/blob/master/pyreadstat/_readstat_parser.pyx
const spss_dt_formats = Dict{String, Tuple{Union{DateTime,Date}, Period}}(
    "TIME" => (spss_epoch_time, Second(1)),
    "DTIME" => (spss_epoch_time, Second(1)),
    "TIME8" => (spss_epoch_time, Second(1)),
    "TIME5" => (spss_epoch_time, Second(1)),
    "TIME11.2" => (spss_epoch_time, Second(1)),
    "DATETIME" => (spss_epoch_time, Second(1)),
    "DATETIME20" => (spss_epoch_time, Second(1)),
    "DATETIME23.2" => (spss_epoch_time, Second(1)),
    "DATETIME8" => (spss_epoch_time, Second(1)),
    "YMDHMS20" => (spss_epoch_time, Second(1)),
    "DATE" => (spss_epoch_time, Second(1)),
    "ADATE" => (spss_epoch_time, Second(1)),
    "EDATE" => (spss_epoch_time, Second(1)),
    "JDATE" => (spss_epoch_time, Second(1)),
    "SDATE" => (spss_epoch_time, Second(1)),
    "EDATE10" => (spss_epoch_time, Second(1)),
    "DATE8" => (spss_epoch_time, Second(1)),
    "EDATE8" => (spss_epoch_time, Second(1)),
    "DATE11" => (spss_epoch_time, Second(1))
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
