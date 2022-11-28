# Value Labels

Value labels collected from the data files are incorporated into the associated data columns
via a customized array type [`LabeledArray`](@ref).

## LabeledValue and LabeledArray

`LabeledValue` and `LabeledArray` are designed to
imitate how variables associated with value labels
are represented in the original data files from the statistical software.
The former wraps a data array with a reference to the value labels;
while the latter wraps a single data value.
The element of a `LabeledArray` is always a `LabeledValue`.
However, a `LabeledValue` obtained from a `LabeledArray`
is only constructed when being retrieved via `getindex` for efficient storage.

Some noteworthy distinctions of a `LabeledArray` are highlighted below:

- Values are never re-encoded when a `LabeledArray` is constructed.[^1]
- It is allowed for some values in a `LabeledArray` to not have a value label.[^2]
- A label is always a `String` even when it is associated with `missing`.

In essence, a `LabeledArray` is simply an array of data values (typically numbers)
bundled with a dictionary of value labels.
There is no restriction imposed on the correspondence
between the data values and value labels.
Namely, a data value in a `LabeledArray` is not necessarily attached with a value label
from the associated dictionary;
while the key of a value label contained in the dictionary
may not match any array element.
Furthermore, the dictionary of value labels may be switched and shared
across different `LabeledArray`s.
When setting values in a `LabeledArray`,
the array of data values are modified directly
with no additional check on the associated dictionary of value labels.
For this reason, the functionality of a `LabeledArray`
is not equivalent to that of an array type designed for categorical data
(e.g., `CategoricalArray` from
[CategoricalArrays.jl](https://github.com/JuliaData/CategoricalArrays.jl)).
They are not complete substitutes for each other.

More details are below.

```@docs
LabeledValue
LabeledArray
LabeledVector
LabeledMatrix
```

## Accessing Values and Labels

For `LabeledValue`, the underlying data value can be retrieved via [`unwrap`](@ref).
The value label can be obtained via [`valuelabel`](@ref) or conversion to `String`.
For `LabeledArray`, the underlying data values can be retrieved via [`refarray`](@ref).
An iterator of value labels that maintains the shape of the `LabeledArray`
can be obtained by calling [`valuelabels`](@ref).

```@docs
unwrap
valuelabel
getvaluelabels
refarray
valuelabels
```

[^1]:

    The values themselves are sometimes meaningful and
    should not be treated as reference values.

[^2]:

    In case a label is requested for a value that is not associated with a label,
    the value is converted to `String`.
