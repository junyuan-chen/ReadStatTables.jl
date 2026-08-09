# Date and Time Values

Date and time values in the data files are recognized based on
the format of each variable.
Many data/time formats can be recognized without user intervention.[^1]
In case certain date/time formats are not recognized,
they can be added easily.

## The Three Categories

The variable formats defined by the statistical software
are classified into three categories that affect
how they are stored in memory and translated to Julia types:
datetime, date and time.
Within a category, there can be multiple formats
but they only alter how data are displayed on screen (in the corresponding software)
without affecting how they are stored in memory.

| Category | Explanation |
| :--- | :--- |
| datetime | Record both the date and the time within a day in a single value |
| date | Record only the date in a value |
| time | Record either time within a day or length of period without calendar date |

The statistical software represents variables of these formats
as numeric values internally based on certain rules.
Stata provides formats dedicated to datetime (`%tc`) and date (e.g., `%td`) but not time.
For a pure time variable without meaningful date,
`%tc` may be used if time strictly refers to a time point within a date.
SAS and SPSS have built-in formats of all three categories.
For SAS, variables of the three categories are recorded as numeric values
in three different ways.
SPSS uses the same approach to represent both datetime and date
but only alters how they are displayed.
For (pure) time variables,
SAS and SPSS record them as the number of seconds elapsed
(without a specific starting point on calendar).

## Translating Datetime and Date

All datetime or date formats from Stata, SAS and SPSS
are stored as the numbers of periods elapsed
since a reference datetime or date (epoch) chosen by the software.
Therefore, knowing the epoch and the length of a single period
is sufficient for uncovering the represented datetime or date for a given format.

!!! info

    Two exceptions are Stata format `"%tw"` for weeks and `"%ty"` for years.
    Stata always counts the week numbers starting from the first day of a year.
    Each year always consists of 52 weeks.
    Any remaining day at the end of a year is counted as the 52th week within that year.
    Conversion for a variable with format `"%tw"` is therefore handled differently.
    For `"%ty"`, the recorded numeric values are simply the calendar years
    without any transformation.
    A variable with format `"%ty"` is not converted to Julia `Date` or `DateTime`.

If a variable is in a recognized format,
the values will be displayed as Julia `Datetime` or `Date`
when printing a `ReadStatTable`.
Notice that the underlying numeric values are preserved
and the conversion to the Julia `Date` or `DateTime` happens only lazily
via a [`MappedArray`](https://github.com/JuliaArrays/MappedArrays.jl)
when working with a `ReadStatTable`.

```@repl date
using ReadStatTables, DataFrames
tb = readstat("data/sample.dta")
tb.mydate
tb.mydate.data
colmetadata(tb, :mydate, "format")
```

The variable-level metadata key named `format` informs
`ReadStatTable` how the numeric values should be interpreted.
Changing the `format` may affect how the values are displayed,
although the numeric values remain unchanged.

```@repl date
colmetadata!(tb, :mydate, "format", "%tm")
tb.mydate
colmetadata!(tb, :mydate, "format", "%8.0f")
tb.mydate
```

For datetime and date variables,
copying a `ReadStatTable` (e.g., converting to a `DataFrame`)
may drop the underlying numeric values.
Hence, users who wish to directly work with the underlying numeric values
may want to preserve the `ReadStatTable` generated from the data file.

```@repl date
df = DataFrame(tb)
df.mydate
```

In the above example, `df.mydate` only contains the `Date` values
and the underlying numeric values are lost when constructing the `DataFrame`.
However, when writing columns with `DateTime` or `Date` back to files,
[`writestat`](@ref) will convert them to numeric values based on the file extension.

The full lists of recognized datetime or date formats for the statistical software
are stored as dictionary keys;
while the associated values are tuples of reference datetime/date and period length.[^2]
If a datetime/date format is not found in the dictionary,
no type conversion will be attempted.
Additional formats may be added by inserting key-value pairs to the relevant dictionaries.

```@setup time
using ReadStatTables
```

```@repl time
ReadStatTables.stata_dt_formats
ReadStatTables.sas_dt_formats["DATETIME"]
ReadStatTables.spss_dt_formats["DATE"]
```

## Translating Time

Time variables in SAS and SPSS do not necessarily represent a time point in a day.
They are simply recorded as number of seconds elapsed,
which are allowed to go above 24 hours.
For this reason, it is not always possible to convert time variables to Julia `Time`,
which strictly refers to time in a day ranging from `00:00:00` to `23:59:59.999999999`.
Depending on the use case,
time variables in SAS and SPSS may either be time in a day just like Julia `Time`
or time duration that is more like a Julia `TimePeriod`.

Without imposing a specific interpretation for time variables,
when retrieving a variable with a time format,
`ReadStatTable` wraps the column as `HMSCol`.
This custom vector type lazily converts the number of seconds to
a more readable `H:MM:SS.dd` format when needed
to ease a quick browsing of the data.
It is up to the users to decide how the time variables should be processed in Julia.
The underlying numeric values representing the number of seconds
are preserved and can be retrieved by calling [`refarray`](@ref).
When writing a table back to SAS/SPSS files,
columns with element type being `Time` or `HMS` are saved as number of seconds.
For Stata, users are expected to take an explicit stand
on how such variables should be stored
by converting the data to either `DateTime` or numeric values.

```@docs
HMS
HMSCol
```

[^1]:

    For Stata, all date/time formats except `"%tC"` and `"%d"` are supported.
    The only difference between the `"%tC"` format and the `"%tc"` format
    is that `"%tC"` takes into account leap seconds while `"%tc"` does not.
    Since the `DateTime` type in the
    [Dates](https://docs.julialang.org/en/v1/stdlib/Dates/) module
    does not allow leap seconds,
    only the `"%tc"` format is supported.
    The `"%d"` format that appears in earlier versions of Stata
    is no longer documented in recent versions.
    For SAS and SPSS, the coverage of date/time formats might be less comprehensive.

[^2]:

    For Stata, the reference for date/time value translation is
    the official [Stata documentation](https://www.stata.com/help.cgi?datetime).
    Only the first three characters in the format strings affect the coding.
    For SAS and SPSS, the reference is
    [`pyreadstat/_readstat_parser.pyx`](https://github.com/Roche/pyreadstat/blob/master/pyreadstat/_readstat_parser.pyx).
