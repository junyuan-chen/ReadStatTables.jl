# Date and Time Values

Date and time values in the data files are recognized based on
the format of each variable.
Many data/time formats can be recognized without user intervention.[^1]
In case certain date/time formats are not recognized,
they can be added easily.

## Translating Date and Time Values

For all date/time formats from Stata, SAS and SPSS,
the date and time values are stored as the numbers of periods elapsed
since a reference date or time point (epoch) chosen by the software.
Therefore, knowing the reference data/time and the length of a single period
is sufficient for uncovering the represented date/time values for a given format.

!!! info

    Two exceptions are Stata format `"%tw"` for weeks and `"%ty"` for years.
    Stata always counts the week numbers starting from the first day of a year.
    Each year always consists of 52 weeks.
    Any remaining day at the end of a year is counted as the 52th week within that year.
    Conversion for a variable with format `"%tw"` is therefore handled differently.
    For `"%ty"`, the recorded numerical values are simply the year numbers
    without any transformation.
    A variable with format `"%ty"` is not converted to Julia `Date` or `DateTime`.

If a variable is in a date/time format that can be recognized,
the values will be displayed as Julia `Date` or `DateTime`
when printing a `ReadStatTable`.
Notice that the underlying numerical values are preserved
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
`ReadStatTable` whether the variable represents date/time
and how the numerical values should be interpreted.
Changing the `format` directly affects how the values are displayed,
although the numerical values remain unchanged.

```@repl date
colmetadata!(tb, :mydate, "format", "%tm")
tb.mydate
colmetadata!(tb, :mydate, "format", "%8.0f")
tb.mydate
```

Copying a `ReadStatTable` (e.g., converting to a `DataFrame`)
may drop the underlying numerical values.
Hence, users who wish to directly work with the underlying numerical values
may want to preserve the `ReadStatTable` generated from the data file.

```@repl date
df = DataFrame(tb)
df.mydate
```

In the above example, `df.mydate` only contains the `Date` values
and the underlying numerical values are lost when constructing the `DataFrame`.

The full lists of recognized date/time formats for the statistical software
are stored as dictionary keys;
while the associated values are tuples of reference date/time and period length.[^2]
If a date/time format is not found in the dictionary,
no type conversion will be attempted.
Additional formats may be added by inserting key-value pairs to the relevant dictionaries.

```@setup time
using ReadStatTables
```

```@repl time
ReadStatTables.stata_dt_formats
ReadStatTables.sas_dt_formats["MMDDYY"]
ReadStatTables.spss_dt_formats["TIME"]
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
