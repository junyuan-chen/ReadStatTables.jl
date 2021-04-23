struct LabeledValue{T}
    value::T
    label::String
end

Base.isless(x::LabeledValue, y::LabeledValue) = isless(x.value, y.value)
Base.:(==)(x::LabeledValue, y::LabeledValue) = x.value == y.value && x.label==y.label

Base.show(io::IO, x::LabeledValue) = print(io, x.label)
Base.show(io::IO, ::MIME"text/plain", x::LabeledValue) =
    println(io, x.value, " => ", x.label)

mutable struct LabeledArray{T<:LabeledValue, V, N} <: AbstractArray{T, N}
    values::Array{V, N}
    labels::Dict{V, String}
    function LabeledArray(values::Array{V,N}, labels::Dict{V,String}) where {V,N}
        V <: AbstractString && throw(ArgumentError("values of type $V are not accepted"))
        return new{LabeledValue{V},V,N}(values, labels)
    end
end

const LabeledVector{T, V} = LabeledArray{T, V, 1}

Base.size(x::LabeledArray) = size(x.values)
Base.IndexStyle(::Type{<:LabeledArray}) = IndexLinear()

Base.@propagate_inbounds function Base.getindex(x::LabeledArray, i::Int)
    val = x.values[i]
    return LabeledValue(val, x.labels[val])
end

Base.values(x::LabeledArray) = x.values
Base.values(x::SubArray{<:Any, <:Any, <:LabeledArray}) =
    view(parent(x).values, x.indices...)
Base.values(x::Base.ReshapedArray{<:Any, <:Any, <:LabeledArray}) =
    reshape(parent(x).values, size(x))
Base.values(x::AbstractArray{<:LabeledValue}) = (k.value for k in x)

struct LabelIterator{A, N} <: AbstractArray{String, N}
    a::A
    LabelIterator(a::AbstractArray{<:LabeledValue, N}) where N = new{typeof(a), N}(a)
end

labels(x::AbstractArray{<:LabeledValue}) = LabelIterator(x)

Base.size(lbls::LabelIterator) = size(lbls.a)
Base.IndexStyle(::Type{<:LabelIterator{A}}) where A = IndexStyle(A)
Base.@propagate_inbounds Base.getindex(lbls::LabelIterator{<:LabeledArray}, i::Int) =
    lbls.a.labels[lbls.a.values[i]]
Base.@propagate_inbounds Base.getindex(lbls::LabelIterator{<:AbstractArray}, i::Int) =
    lbls.a[i].label

Base.:(==)(x::LabeledArray, y::LabeledArray) = x.labels==y.labels && x.values == y.values

function compact_type_str(::Type{LabeledValue{V}}) where V
    if VERSION < v"1.3.0"
        str = V >: Missing ? string(Core.Compiler.typesubtract(V, Missing)) * "?" : string(V)
    else
        str = V >: Missing ? string(nonmissingtype(V)) * "?" : string(V)
    end
    return replace("Labeled{" * str * "}", "Union" => "U")
end
