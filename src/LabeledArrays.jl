struct LabeledValue{T}
    value::T
    labels::Dict{T, String}
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
Base.isequal(x::LabeledValue, y::AbstractString) = isequal(_getlabel(x), y)
Base.isequal(x::AbstractString, y::LabeledValue) = isequal(x, _getlabel(y))
Base.isequal(x::LabeledValue, y::Missing) = isequal(x.value, y)
Base.isequal(x::Missing, y::LabeledValue) = isequal(x, y.value)
Base.isapprox(x::LabeledValue, y; kwargs...) = isapprox(x.value, y; kwargs...)
Base.isapprox(x, y::LabeledValue; kwargs...) = isapprox(x, y.value; kwargs...)

unwrap(x::LabeledValue) = x.value
labels(x::LabeledValue) = _getlabel(x)

Base.show(io::IO, x::LabeledValue) = print(io, _getlabel(x))
Base.show(io::IO, ::MIME"text/plain", x::LabeledValue) =
    println(io, x.value, " => ", _getlabel(x))

Base.convert(::Type{String}, x::LabeledValue) = _getlabel(x)

struct LabeledArray{T<:LabeledValue, V, N} <: AbstractArray{T, N}
    values::Array{V, N}
    labels::Dict{V, String}
    function LabeledArray{T,V,N}(values::Array{V,N}, labels::Dict{V,String}) where {T,V,N}
        V <: AbstractString && throw(ArgumentError("values of type $V are not accepted"))
        return new{T,V,N}(values, labels)
    end
end

const LabeledVector{T, V} = LabeledArray{T, V, 1}

LabeledArray(values::Array{V,N}, labels::Dict{V,String}) where {V,N} =
    LabeledArray{LabeledValue{V},V,N}(values, labels)

Base.size(x::LabeledArray) = size(x.values)
Base.IndexStyle(::Type{<:LabeledArray}) = IndexLinear()

Base.@propagate_inbounds function Base.getindex(x::LabeledArray, i::Int)
    val = x.values[i]
    return LabeledValue(val, x.labels)
end

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

Base.copy(x::LabeledArray{T,V,N}) where {T,V,N} =
    LabeledArray{T,V,N}(copy(x.values), copy(x.labels))

# Assume VERSION >= v"1.3.0"
function compact_type_str(::Type{LabeledValue{V}}) where V
    str = V >: Missing ? string(nonmissingtype(V)) * "?" : string(V)
    return replace("Labeled{" * str * "}", "Union" => "U")
end
