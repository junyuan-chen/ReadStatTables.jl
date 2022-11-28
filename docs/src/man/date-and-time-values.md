# Date and Time Values

Date and time values in the data files are recognized based on
the variable format for each variable.
For Stata, all date/time formats except `%tC` and `%d` are supported.[^1]
In case certain date/time formats are not recognized,
they can be added easily.

## Translating Date and Time Values

For all date/time formats from the statistical software,
the date and time values are always stored as the numbers of periods
passed since a reference date or time point chosen by the software.
Therefore, knowing the reference data/time (epoch) and the length of a single period
is sufficient for uncovering the represented date/time values for a given format.

The full lists of recognized date/time formats for the statistical software
are stored as dictionary keys;
while the associated values are tuples of reference date/time and period length.[^2]
If a variable is in a date/time format that is contained in the dictionary keys,
[`readstat`](@ref) will handle the conversion to a Julia time type
(unless the `convert_datetime` option prevents it).
Otherwise, if a date/time format is not found in the dictionary keys,
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

The translation of the date/time values into a Julia time type is handled by
`parse_datetime`, which is not exported.

```@docs
ReadStatTables.parse_datetime
```

[^1]:

    The only difference between the `%tC` format and the `%tc` format
    is that `%tC` takes into account leap seconds while `%tc` does not.
    Since the `DateTime` type in the
    [Dates](https://docs.julialang.org/en/v1/stdlib/Dates/) module
    does not allow leap seconds,
    only the `%tc` format is supported.
    The `%d` format that appears in earlier versions of Stata
    is no longer documented in recent versions.

[^2]:

    For Stata, the reference for date/time value translation is
    the official [Stata documentation](https://www.stata.com/help.cgi?datetime).
    Only the first three characters in the format strings affect the coding.
    For SAS and SPSS, the reference is
    [`pyreadstat/_readstat_parser.pyx`](https://github.com/Roche/pyreadstat/blob/master/pyreadstat/_readstat_parser.pyx).
