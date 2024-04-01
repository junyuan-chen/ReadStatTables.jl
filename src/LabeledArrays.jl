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

julia> isnan(v1)
false

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

Base.iszero(x::LabeledValue) = iszero(x.value)
Base.isnan(x::LabeledValue) = isnan(x.value)
Base.isinf(x::LabeledValue) = isinf(x.value)
Base.isfinite(x::LabeledValue) = isfinite(x.value)

Base.hash(x::LabeledValue, h::UInt=zero(UInt)) = hash(x.value, h)

Base.length(x::LabeledValue) = length(x.value)

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

Base.convert(::Type{<:LabeledValue{T1,K}}, x::LabeledValue{T2,K}) where {T1,T2,K} =
    LabeledValue{T1,K}(convert(T1, x.value), x.labels)
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

For convenience, `LabeledArray(x::AbstractArray{<:AbstractString}, ::Type{T}=Int32)`
converts a string array to a `LabeledArray`
by encoding the string values with integers of the specified type (`Int32` by default).

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

julia> push!(x, 3 => "c")
5-element LabeledVector{Int64, Vector{Int64}, Int64}:
 0 => 0
 1 => a
 2 => b
 2 => b
 3 => c

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

julia> v = ["a", "b", "c"];

julia> LabeledArray(v, Int16)
3-element LabeledVector{Int16, Vector{Int16}, Union{Char, Int32}}:
 1 => a
 2 => b
 3 => c
```
"""
struct LabeledArray{V, N, A<:AbstractArray{V, N}, K} <: AbstractArray{LabeledValue{V, K}, N}
    values::A
    labels::Dict{K, String}
    LabeledArray(values::AbstractArray{V, N}, labels::Dict{K, String}) where {V, N, K} =
        new{V, N, typeof(values), K}(values, labels)
    LabeledArray{V, N, A, K}(::UndefInitializer, dims) where {V, N, A, K} =
        new{V, N, A, K}(A(undef, dims), Dict{K, String}())
end

# Convenience method for encoding string arrays
function LabeledArray(x::AbstractArray{<:AbstractString}, ::Type{T}=Int32) where T
    refs, invpool, pool = _label(x, eltype(x), T)
    lbls = Dict{Union{Int32,Char},String}(Int32(v)=>string(k) for (k, v) in pairs(invpool))
    return LabeledArray(refs, lbls)
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

defaultarray(::Type{LabeledValue{V,K}}, N) where {V,K} =
    LabeledArray{V, N, defaultarray(V, N), K}

const LabeledArrOrSubOrReshape{V, K, N} = Union{LabeledArray{V, N, <:Any, K},
    SubArray{<:Any, N, <:LabeledArray{V, <:Any, <:Any, K}}, Base.ReshapedArray{<:Any, N, <:LabeledArray{V, <:Any, <:Any, K}},
    SubArray{<:Any, N, <:Base.ReshapedArray{<:Any, <:Any, <:LabeledArray{V, <:Any, <:Any, K}}}}

Base.size(x::LabeledArray) = size(refarray(x))
Base.IndexStyle(::Type{<:LabeledArray{V,N,A}}) where {V,N,A} = IndexStyle(A)

Base.@propagate_inbounds function Base.getindex(x::LabeledArray{V,N,A,K}, i::Int) where {V,N,A,K}
    val = refarray(x)[i]::V
    return LabeledValue{V,K}(val, getvaluelabels(x))
end

Base.@propagate_inbounds function Base.setindex!(x::LabeledArray, v, i::Int)
    refarray(x)[i] = unwrap(v)
    return x
end

"""
    refarray(x::LabeledArray)
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

# The type annotation ::V and LabeledValue{V,K} avoids an allocation
Base.@propagate_inbounds function Base.getindex(x::LabeledArrOrSubOrReshape{V,K}, i::Integer) where {V,K}
    val = refarray(x)[i]::V
    return LabeledValue{V,K}(val, getvaluelabels(x))
end

# This avoids method ambiguity on Julia v1.11 with
# getindex(V::SubArray{T, N, P, I, true} where {T, N, P, I<:Union{Tuple{Vararg{Real}},
#    Tuple{AbstractUnitRange, Vararg{Any}}}}, i::AbstractUnitRange{Int64})
# Need to restrict I to UnitRange for resolving ambiguity on v1.12?
Base.@propagate_inbounds function Base.getindex(x::SubArray{<:Any, N,
        <:Union{<:LabeledArray{V},
        <:Base.ReshapedArray{<:Any, <:Any, <:LabeledArray{V}}}, R, true},
        I::UnitRange{Int64}) where {V,N,
        R<:Union{Tuple{Vararg{Real}}, Tuple{AbstractUnitRange, Vararg{Any}}}}
    val = refarray(x)[I]
    return LabeledArray(val, getvaluelabels(x))
end

# Needed for repeat(x, inner=2) to work
Base.@propagate_inbounds function Base.getindex(x::LabeledArrOrSubOrReshape{V,K}, i::CartesianIndex) where {V,K}
    val = refarray(x)[i]::V
    return LabeledValue{V,K}(val, getvaluelabels(x))
end

Base.@propagate_inbounds function Base.getindex(x::LabeledArrOrSubOrReshape, i)
    val = refarray(x)[i]
    return LabeledArray(val, getvaluelabels(x))
end

Base.@propagate_inbounds function Base.getindex(x::LabeledArrOrSubOrReshape{V,K,N},
        I::Vararg{Int,N}) where {V,K,N}
    val = refarray(x)[I...]::V
    return LabeledValue{V,K}(val, getvaluelabels(x))
end

Base.@propagate_inbounds function Base.getindex(x::LabeledArrOrSubOrReshape{V,K,N},
        I::Vararg{Integer,N}) where {V,K,N}
    val = refarray(x)[I...]::V
    return LabeledValue{V,K}(val, getvaluelabels(x))
end

Base.fill!(x::LabeledArrOrSubOrReshape, v) = (fill!(refarray(x), unwrap(v)); x)

Base.resize!(x::LabeledVector, n::Integer) = (resize!(refarray(x), n); x)
Base.push!(x::LabeledVector, v) = (push!(refarray(x), unwrap(v)); x)
Base.push!(x::LabeledVector, p::Pair) =
    (getvaluelabels(x)[p[1]] = p[2]; push!(refarray(x), p[1]); x)
Base.pushfirst!(x::LabeledVector, v) = (pushfirst!(refarray(x), unwrap(v)); x)
Base.pushfirst!(x::LabeledVector, p::Pair) =
    (getvaluelabels(x)[p[1]] = p[2]; pushfirst!(refarray(x), p[1]); x)
Base.insert!(x::LabeledVector, i, v) = (insert!(refarray(x), i, unwrap(v)); x)
Base.deleteat!(x::LabeledVector, i) = (deleteat!(refarray(x), i); x)
Base.append!(x::LabeledVector, v) = (append!(refarray(x), refarray(v)); x)
Base.prepend!(x::LabeledVector, v) = (prepend!(refarray(x), refarray(v)); x)
Base.empty!(x::LabeledVector) = (empty!(refarray(x)); x)
Base.sizehint!(x::LabeledVector, n) = (sizehint!(refarray(x), n); x)

Base.:(==)(x::LabeledArray, y::LabeledArray) = refarray(x) == refarray(y)
Base.:(==)(x::LabeledArray, y::AbstractArray) = refarray(x) == y
Base.:(==)(x::AbstractArray, y::LabeledArray) = x == refarray(y)

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

Base.similar(x::LabeledArrOrSubOrReshape, ::Type{<:LabeledValue{V}}, dims::Dims) where V =
    LabeledArray(similar(refarray(x), V, dims), getvaluelabels(x))

# Needed for similar_missing in DataFrames.jl to work
Base.similar(x::LabeledArrOrSubOrReshape,
    ::Type{Union{LabeledValue{V, K}, Missing}}, dims::Dims) where {V,K} =
        LabeledArray(similar(refarray(x), Union{V, Missing}, dims), getvaluelabels(x))

# Value labels are not copied and may still be shared with other LabeledArrays
Base.copy(x::LabeledArray) = LabeledArray(copy(refarray(x)), getvaluelabels(x))

Base.copyto!(dest::AbstractArray, src::LabeledArrOrSubOrReshape) =
    copyto!(dest, refarray(src))

# dest labels are updated in case src labels are different
_mergelbl!(dest::LabeledArrOrSubOrReshape, src::LabeledArrOrSubOrReshape) =
    getvaluelabels(dest) === getvaluelabels(src) ||
        merge!(getvaluelabels(dest), getvaluelabels(src))

function Base.copyto!(dest::LabeledArrOrSubOrReshape, src::LabeledArrOrSubOrReshape)
    copyto!(refarray(dest), refarray(src))
    _mergelbl!(dest, src)
    return dest
end

Base.copyto!(deststyle::IndexStyle, dest::AbstractArray, srcstyle::IndexStyle,
    src::LabeledArrOrSubOrReshape) =
        copyto!(deststyle, dest, srcstyle, refarray(src))

function Base.copyto!(deststyle::IndexStyle, dest::LabeledArrOrSubOrReshape,
        srcstyle::IndexStyle, src::LabeledArrOrSubOrReshape)
    copyto!(deststyle, refarray(dest), srcstyle, refarray(src))
    _mergelbl!(dest, src)
    return dest
end

Base.copyto!(dest::AbstractArray, dstart::Integer, src::LabeledArrOrSubOrReshape,
    sstart::Integer, n::Integer) =
        copyto!(dest, dstart, refarray(src), sstart, n)

function Base.copyto!(dest::LabeledArrOrSubOrReshape, dstart::Integer,
        src::LabeledArrOrSubOrReshape, sstart::Integer, n::Integer)
    copyto!(refarray(dest), dstart, refarray(src), sstart, n)
    _mergelbl!(dest, src)
    return dest
end

Base.copyto!(B::AbstractVecOrMat, ir_dest::AbstractRange{Int},
    jr_dest::AbstractRange{Int}, A::LabeledArrOrSubOrReshape,
    ir_src::AbstractRange{Int}, jr_src::AbstractRange{Int}) =
        copyto!(B, ir_dest, jr_dest, refarray(A), ir_src, jr_src)

function Base.copyto!(B::LabeledArrOrSubOrReshape, ir_dest::AbstractRange{Int},
        jr_dest::AbstractRange{Int}, A::LabeledArrOrSubOrReshape,
        ir_src::AbstractRange{Int}, jr_src::AbstractRange{Int})
    copyto!(refarray(B), ir_dest, jr_dest, refarray(A), ir_src, jr_src)
    _mergelbl!(B, A)
    return B
end

# Behavior of collect is nonstandard as LabeledArray instead of Array is returned
Base.collect(x::LabeledArrOrSubOrReshape) =
    LabeledArray(collect(refarray(x)), getvaluelabels(x))

Base.collect(::Type{<:LabeledValue{T}}, x::LabeledArrOrSubOrReshape) where T =
    LabeledArray(collect(T, refarray(x)), getvaluelabels(x))

disallowmissing(x::LabeledArrOrSubOrReshape) =
    LabeledArray(disallowmissing(refarray(x)), getvaluelabels(x))

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
