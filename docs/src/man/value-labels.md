# Value Labels

Value labels from the data files are incorporated into the data columns
via a customized array type `LabeledArray`.

## LabeledValue and LabeledArray

`LabeledValue` and `LabeledArray` are designed to
imitate how variables associated with value labels
are represented in the original data files from the statistical software.
The element of a `LabeledArray` is always a `LabeledValue`.

In general, variables associated with value labels
should not be treated as categorical data.
Here are some noteworthy distinctions of `LabeledArray` from
an array type designed for categorical data (e.g., `CategoricalArray`):

- Values are never recoded when a `LabeledArray` is constructed.[^1]
- It is allowed for some values in a `LabeledArray` to not have a label.[^2]
- A label is always a `String` even when it is associated with `missing`.

More details are below.

```@docs
LabeledValue
LabeledArray
LabeledVector
```

## Accessing Labels and Values

If only the labels of a `LabeledArray` are needed,
an iterator that maintains the shape of the `LabeledArray`
can be obtained by calling `labels`.
The iterator can be used for either collecting all labels in a different array type
or retrieving labels for specific values.
On the other hand, if only the values are needed,
the labels can be ignored
if one directly accesses the underlying array that holds the values.

```@docs
labels
unwrap
refarray
```

[^1]:

    The values themselves are sometimes meaningful and
    should not be treated as reference values.

[^2]:

    In case a label is requested for a value that is not associated with a label,
    the value is converted to `String`.
