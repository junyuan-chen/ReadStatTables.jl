"""
    LabeledValue{T}

Value of type `T` that is associated with a dictionary of value labels.
If a value `v` is not a key in the dictionary,
then `string(v)` is taken as the label.
See also [`LabeledArray`](@ref).

The value underlying a `LabeledValue` can be accessed via [`unwrap`](@ref).
The label can be obtained by converting `LabeledValue` to `String`
or calling [`labels`](@ref) (notice the `s` at the end).

Comparison operators `==`, `isequal`, `<`, `isless` and `isapprox`
compare the underlying value of type `T`.
An exception is that when a `LabeledValue` and a string are compared with `==`,
the comparison is based on the label.

# Examples
```jldoctest
julia> lbls = Dict{Union{Int,Missing},String}(0=>"a", 1=>"a");

julia> v0 = LabeledValue(0, lbls)
0 => a

julia> v1 = LabeledValue(1, lbls)
1 => a

julia> vm = LabeledValue(missing, lbls)
missing => missing

julia> v0 == v1
false

julia> v1 == 1
true

julia> v1 == "a"
true

julia> isequal(vm, missing)
true
```
"""
struct LabeledValue{T}
    value::T
    labels::Dict{Any, String}
end

# A value is not guaranteed to have a label defined in labels
function _getlabel(x::LabeledValue)
    lbl = get(x.labels, x.value, nothing)
    lbl === nothing && return string(x.value)
    return lbl
end

# Comparison between LabeledValues ignores labels
Base.:(==)(x::LabeledValue, y::LabeledValue) = x.value == y.value
Base.isequal(x::LabeledValue, y::LabeledValue) = isequal(x.value, y.value)
Base.:(<)(x::LabeledValue, y::LabeledValue) = x.value < y.value
Base.isless(x::LabeledValue, y::LabeledValue) = isless(x.value, y.value)
Base.isapprox(x::LabeledValue, y::LabeledValue; kwargs...) =
    isapprox(x.value, y.value; kwargs...)

# Comparison with String is interpreted as comparing labels
# Comparison with any other type is interpreted as comparing values
Base.:(==)(x::LabeledValue, y) = x.value == y
Base.:(==)(x, y::LabeledValue) = x == y.value
Base.:(==)(x::LabeledValue, y::AbstractString) = _getlabel(x) == y
Base.:(==)(x::AbstractString, y::LabeledValue) = x == _getlabel(y)
Base.:(==)(::LabeledValue, ::Missing) = missing
Base.:(==)(::Missing, ::LabeledValue) = missing

Base.isequal(x::LabeledValue, y) = isequal(x.value, y)
Base.isequal(x, y::LabeledValue) = isequal(x, y.value)
Base.isequal(x::LabeledValue, y::Missing) = isequal(x.value, y)
Base.isequal(x::Missing, y::LabeledValue) = isequal(x, y.value)
Base.:(<)(x::LabeledValue, y) = x.value < y
Base.:(<)(x, y::LabeledValue) = x < y.value
Base.:(<)(x::LabeledValue, y::Missing) = x.value < y
Base.:(<)(x::Missing, y::LabeledValue) = x < y.value
Base.isless(x::LabeledValue, y) = isless(x.value, y)
Base.isless(x, y::LabeledValue) = isless(x, y.value)
Base.isless(x::LabeledValue, y::Missing) = isless(x.value, y)
Base.isless(x::Missing, y::LabeledValue) = isless(x, y.value)
Base.isapprox(x::LabeledValue, y; kwargs...) = isapprox(x.value, y; kwargs...)
Base.isapprox(x, y::LabeledValue; kwargs...) = isapprox(x, y.value; kwargs...)

Base.hash(x::LabeledValue, h::UInt=zero(UInt)) = hash(x.value, h)

"""
    unwrap(x::LabeledValue)

Get the value wrapped by `x`.
"""
unwrap(x::LabeledValue) = x.value

"""
    labels(x::LabeledValue)

Return the label associated with `x`.
"""
labels(x::LabeledValue) = _getlabel(x)

Base.show(io::IO, x::LabeledValue) = print(io, _getlabel(x))
Base.show(io::IO, ::MIME"text/plain", x::LabeledValue) =
    print(io, x.value, " => ", _getlabel(x))

Base.convert(::Type{String}, x::LabeledValue) = _getlabel(x)

"""
    LabeledArray{V, N, T<:LabeledValue} <: AbstractArray{T, N}

`N`-dimensional dense array with elements associated with labels.

`LabeledArray` provides functionality that is similar to
what value labels achieve in statistical software such as Stata.
When printed to REPL, a `LabeledArray` just looks like an array of labels.
Yet, only the underlying values of type `V` are stored in an `Array`.
The associated labels are looked up
from a dictionary of type `Dict{V, String}`.
If a value `v` is not a key in the dictionary,
then `string(v)` is taken as the label.
The elements of type [`LabeledValue`](@ref)
are only constructed lazily when retrieved.

The array of values underlying a `LabeledArray`
can be accessed with [`refarray`](@ref);
while an iterator over the labels for each element
is returned by [`labels`](@ref).

Equality comparison as defined by `==` involving a `LabeledArray`
only compares the underlying values
unless the element type of the other array is a subtype of `AbstractString`.
The labels are used for comparison in the latter case.

# Examples
```jldoctest
julia> lbls1 = Dict(1=>"a", 2=>"b");

julia> lbls2 = Dict(1.0=>"p", 2.0=>"q");

julia> x = LabeledArray([0, 1, 2], lbls1)
3-element LabeledVector{Int64, LabeledValue{Int64}}:
 0 => 0
 1 => a
 2 => b

julia> y = LabeledArray([0.0, 1.0, 2.0], lbls2)
3-element LabeledVector{Float64, LabeledValue{Float64}}:
 0.0 => 0.0
 1.0 => p
 2.0 => q

julia> x == y
true

julia> x == 0:2
true

julia> x == ["0", "a", "b"]
true
```
"""
struct LabeledArray{V, N, T<:LabeledValue, A} <: AbstractArray{T, N}
    values::A
    labels::Dict{Any, String}
    function LabeledArray(values::AbstractArray{V,N},
            labels::Dict{Any,String}) where {V,N}
        V <: AbstractString && throw(ArgumentError("values of type $V are not accepted"))
        return new{V,N,LabeledValue{V},typeof(values)}(values, labels)
    end
end

"""
    LabeledVector{V, T, A}

Alias for [`LabeledArray{V, 1, T, A}`](@ref).
"""
const LabeledVector{V, T, A} = LabeledArray{V, 1, T, A}

Base.size(x::LabeledArray) = size(x.values)
Base.IndexStyle(::Type{<:LabeledArray}) = IndexLinear()

Base.@propagate_inbounds function Base.getindex(x::LabeledArray, i::Int)
    val = x.values[i]
    return LabeledValue(val, x.labels)
end

"""
    refarry(x::LabeledArray)
    refarray(x::SubArray{<:Any, <:Any, <:LabeledArray})
    refarray(x::Base.ReshapedArray{<:Any, <:Any, <:LabeledArray})
    refarray(x::AbstractArray{<:LabeledValue})

Return the array of values underlying a [`LabeledArray`](@ref).
"""
refarray(x::LabeledArray) = x.values
refarray(x::SubArray{<:Any, <:Any, <:LabeledArray}) =
    view(parent(x).values, x.indices...)
refarray(x::Base.ReshapedArray{<:Any, <:Any, <:LabeledArray}) =
    reshape(parent(x).values, size(x))
refarray(x::AbstractArray{<:LabeledValue}) = collect(v.value for v in x)

struct LabelIterator{A, N} <: AbstractArray{String, N}
    a::A
    LabelIterator(a::AbstractArray{<:LabeledValue, N}) where N = new{typeof(a), N}(a)
end

"""
    labels(x::AbstractArray{<:LabeledValue})

Return an iterator over the labels for each element in `x`.
The returned object is a subtype of `AbstractArray` with the same size of `x`.

The iterator can be used to collect the labels while discarding the underlying values.

# Examples
```jldoctest
julia> x = LabeledArray([1, 2, 3], Dict(1=>"a", 2=>"b"))
3-element LabeledVector{Int64, LabeledValue{Int64}}:
 1 => a
 2 => b
 3 => 3

julia> lbls = labels(x)
3-element ReadStatTables.LabelIterator{LabeledVector{Int64, LabeledValue{Int64}}, 1}:
 "a"
 "b"
 "3"

julia> collect(lbls)
3-element Vector{String}:
 "a"
 "b"
 "3"

julia> CategoricalArray(lbls)
3-element CategoricalArray{String,1,UInt32}:
 "a"
 "b"
 "3"
```
"""
labels(x::AbstractArray{<:LabeledValue}) = LabelIterator(x)

Base.size(lbls::LabelIterator) = size(lbls.a)
Base.IndexStyle(::Type{<:LabelIterator{A}}) where A = IndexStyle(A)

Base.@propagate_inbounds function Base.getindex(lbls::LabelIterator{<:LabeledArray}, i::Int)
    val = lbls.a.values[i]
    lbl = get(lbls.a.labels, val, nothing)
    lbl === nothing && return string(val)
    return lbl
end

Base.@propagate_inbounds Base.getindex(lbls::LabelIterator{<:AbstractArray}, i::Int) =
    _getlabel(lbls.a[i])

Base.:(==)(x::LabeledArray, y::LabeledArray) = x.values == y.values
Base.:(==)(x::LabeledArray, y::AbstractArray) = x.values == y
Base.:(==)(x::AbstractArray, y::LabeledArray) = x == y.values
Base.:(==)(x::LabeledArray, y::AbstractArray{<:AbstractString}) = labels(x) == y
Base.:(==)(x::AbstractArray{<:AbstractString}, y::LabeledArray) = x == labels(y)

Base.copy(x::LabeledArray) =
    LabeledArray(copy(x.values), copy(x.labels))

Base.convert(::Type{Array{V1,N}}, x::LabeledArray{V2,N}) where {V1,V2,N} =
    convert(Array{V1}, x.values)

# Assume VERSION >= v"1.3.0"
function compact_type_str(::Type{LabeledValue{V}}) where V
    str = V >: Missing ? string(nonmissingtype(V)) * "?" : string(V)
    return replace("Labeled{" * str * "}", "Union" => "U")
end
