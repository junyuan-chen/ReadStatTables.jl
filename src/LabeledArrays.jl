"""
    LabeledValue{T, K}

Value of type `T` associated with a dictionary of value labels with keys of type `K`.
If a value `v` is not euqal (`==`) to a key in the dictionary,
then `string(v)` is taken as the value label.
See also [`LabeledArray`](@ref).

The value underlying a `LabeledValue` can be accessed via [`unwrap`](@ref).
The value label can be obtained by calling [`valuelabel`](@ref)
or converting a `LabeledValue` to `String` via `convert`.
The dictionary of value labels (typically assoicated with a data column)
can be accessed via [`getvaluelabels`](@ref).

Comparison operators `==`, `isequal`, `<`, `isless` and `isapprox`
compare the underlying value of type `T` and disregard any value label.
To compare the value label, use [`valuelabel`](@ref) to retrieve the label first.

# Examples
```jldoctest
julia> lbls = Dict{Int,String}(0=>"a", 1=>"a");

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

julia> isequal(vm, missing)
true

julia> unwrap(v0)
0

julia> valuelabel(v1) == "a"
true

julia> getvaluelabels(v1) === lbls
true
```
"""
struct LabeledValue{T, K}
    value::T
    labels::Dict{K, String}
end

# A value is not guaranteed to have a label defined in labels
function _getlabel(x::LabeledValue)
    lbl = get(x.labels, x.value, nothing)
    return lbl === nothing ? string(x.value) : lbl
end

# Comparisons involving LabeledValues always disregard labels
Base.:(==)(x::LabeledValue, y::LabeledValue) = x.value == y.value
Base.isequal(x::LabeledValue, y::LabeledValue) = isequal(x.value, y.value)
Base.:(<)(x::LabeledValue, y::LabeledValue) = x.value < y.value
Base.isless(x::LabeledValue, y::LabeledValue) = isless(x.value, y.value)
Base.isapprox(x::LabeledValue, y::LabeledValue; kwargs...) =
    isapprox(x.value, y.value; kwargs...)

Base.:(==)(x::LabeledValue, y) = x.value == y
Base.:(==)(x, y::LabeledValue) = x == y.value
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

Return the value underlying the value label of `x`.
"""
unwrap(x::LabeledValue) = x.value

"""
    valuelabel(x::LabeledValue)

Return the value label associated with `x`.
"""
valuelabel(x::LabeledValue) = _getlabel(x)

"""
    getvaluelabels(x::LabeledValue)

Return the dictionary of value labels (typically assoicated with a data column)
attached to `x`.
"""
getvaluelabels(x::LabeledValue) = x.labels

Base.show(io::IO, x::LabeledValue) = print(io, _getlabel(x))
Base.show(io::IO, ::MIME"text/plain", x::LabeledValue) =
    print(io, x.value, " => ", _getlabel(x))

Base.convert(::Type{<:LabeledValue{T1}}, x::LabeledValue{T2}) where {T1,T2} =
    LabeledValue(convert(T1, x.value), x.labels)
Base.convert(::Type{T}, x::LabeledValue) where T<:AbstractString = convert(T, _getlabel(x))

"""
    LabeledArray{V, N, A<:AbstractArray{V, N}, K} <: AbstractArray{LabeledValue{V, K}, N}

`N`-dimensional dense array with elements associated with value labels.

`LabeledArray` provides functionality that is similar to
what value labels achieve in statistical software such as Stata.
When printed to REPL, a `LabeledArray` just looks like an array of value labels.
Yet, only the underlying values of type `V` are stored in an array of type `A`.
The associated value labels are looked up
from a dictionary of type `Dict{K, String}`.
If a value `v` is not equal (`==`) to a key in the dictionary,
then `string(v)` is taken as the value label.
The elements of type [`LabeledValue{V, K}`](@ref)
are only constructed lazily when they are retrieved.

The array of values underlying a `LabeledArray`
can be accessed via [`refarray`](@ref).
The dictionary of value labels assoicated with a `LabeledArray`
can be accessed via [`getvaluelabels`](@ref).
An iterator over the value labels for each element,
which has the same array shape as the `LabeledArray`,
can be obtained via [`valuelabels`](@ref).

Equality comparison (`==`) involving a `LabeledArray`
only compares the underlying values and disregard any value label.
To compare the value labels, use [`valuelabels`](@ref) to obtain the labels first.

Additional array methods such as `push!`, `insert!`, `deleteat!`, `append!`
are supported for [`LabeledVector`](@ref).
They are applied on the underlying array of values retrieved via [`refarray`](@ref)
and do not modify the dictionary of value labels.

# Examples
```jldoctest
julia> lbls1 = Dict(1=>"a", 2=>"b");

julia> lbls2 = Dict(1.0=>"p", 2.0=>"q");

julia> x = LabeledArray([0, 1, 2], lbls1)
3-element LabeledVector{Int64, Vector{Int64}, Int64}:
 0 => 0
 1 => a
 2 => b

julia> y = LabeledArray([0.0, 1.0, 2.0], lbls2)
3-element LabeledVector{Float64, Vector{Float64}, Float64}:
 0.0 => 0.0
 1.0 => p
 2.0 => q

julia> x == y
true

julia> x == 0:2
true

julia> refarray(x)
3-element Vector{Int64}:
 0
 1
 2

julia> getvaluelabels(x)
Dict{Int64, String} with 2 entries:
  2 => "b"
  1 => "a"

julia> valuelabels(x) == ["0", "a", "b"]
true

julia> push!(x, 2)
4-element LabeledVector{Int64, Vector{Int64}, Int64}:
 0 => 0
 1 => a
 2 => b
 2 => b

julia> deleteat!(x, 4)
3-element LabeledVector{Int64, Vector{Int64}, Int64}:
 0 => 0
 1 => a
 2 => b

julia> append!(x, [0, 1, 2])
6-element LabeledVector{Int64, Vector{Int64}, Int64}:
 0 => 0
 1 => a
 2 => b
 0 => 0
 1 => a
 2 => b
```
"""
struct LabeledArray{V, N, A<:AbstractArray{V, N}, K} <: AbstractArray{LabeledValue{V, K}, N}
    values::A
    labels::Dict{K, String}
    LabeledArray(values::AbstractArray{V, N}, labels::Dict{K, String}) where {V, N, K} =
        new{V, N, typeof(values), K}(values, labels)
end

"""
    LabeledVector{V, A, K} <: AbstractVector{LabeledValue{V, K}}

Alias for [`LabeledArray{V, 1, A, K}`](@ref).
"""
const LabeledVector{V, A, K} = LabeledArray{V, 1, A, K}

"""
    LabeledMatrix{V, A, K} <: AbstractMatrix{LabeledValue{V, K}}

Alias for [`LabeledArray{V, 2, A, K}`](@ref).
"""
const LabeledMatrix{V, A, K} = LabeledArray{V, 2, A, K}

const LabeledArrOrSubOrReshape{V, N} = Union{LabeledArray{V, N},
    SubArray{<:Any, N, <:LabeledArray{V}}, Base.ReshapedArray{<:Any, N, <:LabeledArray{V}},
    SubArray{<:Any, N, <:Base.ReshapedArray{<:Any, <:Any, <:LabeledArray{V}}}}

Base.size(x::LabeledArray) = size(refarray(x))
Base.IndexStyle(::Type{<:LabeledArray{V,N,A}}) where {V,N,A} = IndexStyle(A)

Base.@propagate_inbounds function Base.getindex(x::LabeledArray, i::Int)
    val = refarray(x)[i]
    return LabeledValue(val, getvaluelabels(x))
end

Base.@propagate_inbounds function Base.setindex!(x::LabeledArray, v, i::Int)
    refarray(x)[i] = unwrap(v)
    return x
end

"""
    refarry(x::LabeledArray)
    refarray(x::SubArray{<:Any, <:Any, <:LabeledArray})
    refarray(x::Base.ReshapedArray{<:Any, <:Any, <:LabeledArray})
    refarray(x::SubArray{<:Any, <:Any, <:Base.ReshapedArray{<:Any, <:Any, <:LabeledArray}})

Return the array of values underlying a [`LabeledArray`](@ref).
"""
refarray(x::LabeledArray) = x.values
refarray(x::SubArray{<:Any, <:Any, <:LabeledArray}) =
    view(parent(x).values, x.indices...)
refarray(x::Base.ReshapedArray{<:Any, <:Any, <:LabeledArray}) =
    reshape(parent(x).values, size(x))
refarray(x::SubArray{<:Any, <:Any, <:Base.ReshapedArray{<:Any, <:Any, <:LabeledArray}}) =
    view(reshape(parent(parent(x)).values, size(parent(x))), x.indices...)

"""
    getvaluelabels(x::LabeledArray)
    getvaluelabels(x::SubArray{<:Any, <:Any, <:LabeledArray})
    getvaluelabels(x::Base.ReshapedArray{<:Any, <:Any, <:LabeledArray})
    getvaluelabels(x::SubArray{<:Any, <:Any, <:Base.ReshapedArray{<:Any, <:Any, <:LabeledArray}})

Return the dictionary of value labels attached to `x`.
"""
getvaluelabels(x::LabeledArray) = x.labels
getvaluelabels(x::SubArray{<:Any, <:Any, <:LabeledArray}) = parent(x).labels
getvaluelabels(x::Base.ReshapedArray{<:Any, <:Any, <:LabeledArray}) = parent(x).labels
getvaluelabels(x::SubArray{<:Any, <:Any,
    <:Base.ReshapedArray{<:Any, <:Any, <:LabeledArray}}) = parent(parent(x)).labels

Base.@propagate_inbounds function Base.getindex(x::LabeledArrOrSubOrReshape, i::Integer)
    val = refarray(x)[i]
    return LabeledValue(val, getvaluelabels(x))
end

Base.@propagate_inbounds function Base.getindex(x::LabeledArrOrSubOrReshape, i)
    val = refarray(x)[i]
    return LabeledArray(val, getvaluelabels(x))
end

Base.@propagate_inbounds function Base.getindex(x::LabeledArrOrSubOrReshape{V,N},
        I::Vararg{Int,N}) where {V,N}
    val = refarray(x)[I...]
    return LabeledValue(val, getvaluelabels(x))
end

Base.@propagate_inbounds function Base.getindex(x::LabeledArrOrSubOrReshape{V,N},
        I::Vararg{<:Integer,N}) where {V,N}
    val = refarray(x)[I...]
    return LabeledValue(val, getvaluelabels(x))
end

Base.@propagate_inbounds function Base.getindex(x::LabeledArrOrSubOrReshape{V,N},
        I::Vararg{Any,N}) where {V,N}
    val = refarray(x)[I...]
    return LabeledArray(val, getvaluelabels(x))
end

Base.fill!(x::LabeledArrOrSubOrReshape, v) = (fill!(refarray(x), unwrap(v)); x)

Base.resize!(x::LabeledVector, n::Integer) = (resize!(refarray(x), n); x)
Base.push!(x::LabeledVector, v) = (push!(refarray(x), unwrap(v)); x)
Base.pushfirst!(x::LabeledVector, v) = (pushfirst!(refarray(x), unwrap(v)); x)
Base.insert!(x::LabeledVector, i, v) = (insert!(refarray(x), i, unwrap(v)); x)
Base.deleteat!(x::LabeledVector, i) = (deleteat!(refarray(x), i); x)
Base.append!(x::LabeledVector, v) = (append!(refarray(x), refarray(v)); x)
Base.prepend!(x::LabeledVector, v) = (prepend!(refarray(x), refarray(v)); x)
Base.empty!(x::LabeledVector) = (empty!(refarray(x)); x)
Base.sizehint!(x::LabeledVector, n) = (sizehint!(refarray(x), n); x)

Base.:(==)(x::LabeledArray, y::LabeledArray) = refarray(x) == refarray(y)
Base.:(==)(x::LabeledArray, y::AbstractArray) = refarray(x) == y
Base.:(==)(x::AbstractArray, y::LabeledArray) = x == refarray(y)

# Value labels are not copied and may still be shared with other LabeledArrays
Base.copy(x::LabeledArray) = LabeledArray(copy(refarray(x)), getvaluelabels(x))

# Only convert the value type
Base.convert(::Type{<:AbstractArray{<:LabeledValue{T},N}},
    x::LabeledArray{V,N}) where {T,V,N} =
        LabeledArray(convert(AbstractArray{T,N}, refarray(x)), getvaluelabels(x))

"""
    convertvalue(T, x::LabeledArray)

Convert the type of data values contained in `x` to `T`.
This method is equivalent to `convert(AbstractArray{LabeledValue{T, K}, N}}, x)`.
"""
convertvalue(::Type{T}, x::LabeledArray{V,N}) where {T,V,N} =
    LabeledArray(convert(AbstractArray{T,N}, refarray(x)), getvaluelabels(x))

# Keep the same value labels
Base.similar(x::LabeledArrOrSubOrReshape) =
    LabeledArray(similar(refarray(x)), getvaluelabels(x))

Base.similar(x::LabeledArrOrSubOrReshape, ::Type{<:LabeledValue{V}}) where V =
    LabeledArray(similar(refarray(x), V), getvaluelabels(x))

Base.similar(x::LabeledArrOrSubOrReshape, dims::Dims) =
    LabeledArray(similar(refarray(x), dims), getvaluelabels(x))

Base.similar(x::LabeledArrOrSubOrReshape, ::Type{<:LabeledValue{V}}, dims::Dims) where V =
    LabeledArray(similar(refarray(x), V, dims), getvaluelabels(x))

# Assume VERSION >= v"1.3.0"
# Define abbreviated element type name for printing with PrettyTables.jl
function compact_type_str(::Type{<:LabeledValue{V}}) where V
    str = V >: Missing ? string(nonmissingtype(V)) * "?" : string(V)
    return replace("Labeled{" * str * "}", "Union" => "U")
end

struct LabelIterator{A, N} <: AbstractArray{String, N}
    a::A
    LabelIterator(a::AbstractArray{<:LabeledValue, N}) where N = new{typeof(a), N}(a)
end

"""
    valuelabels(x::AbstractArray{<:LabeledValue})

Return an iterator over the value labels of all elements in `x`.
The returned object is a subtype of `AbstractArray` with the same size of `x`.

The iterator can be used to collect value labels to arrays
while discarding the underlying values.

# Examples
```jldoctest
julia> x = LabeledArray([1, 2, 3], Dict(1=>"a", 2=>"b"))
3-element LabeledVector{Int64, Vector{Int64}, Int64}:
 1 => a
 2 => b
 3 => 3

julia> lbls = valuelabels(x)
3-element ReadStatTables.LabelIterator{LabeledVector{Int64, Vector{Int64}, Int64}, 1}:
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
valuelabels(x::AbstractArray{<:LabeledValue}) = LabelIterator(x)

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
