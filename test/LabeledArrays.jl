@testset "LabeledValue" begin
    lbls1 = Dict{Int32,String}(1=>"a", 2=>"b")
    lbls2 = Dict{Any,String}(1.0=>"b")
    v1 = LabeledValue(1, lbls1)
    v2 = LabeledValue(2, lbls1)
    v3 = LabeledValue(1.0, lbls2)
    v4 = LabeledValue(missing, lbls2)

    @test v1 == v3
    @test isequal(v4 == v1, missing)
    @test isequal(v1, v3)
    @test isequal(v4, v4)
    @test v1 < v2
    @test isless(v1, v2)
    @test isapprox(v1, v3)

    @test !iszero(v1)
    @test iszero(LabeledValue(0, lbls1))
    @test !isnan(v1)
    @test isnan(LabeledValue(NaN, lbls1))
    @test !isinf(v1)
    @test isinf(LabeledValue(Inf, lbls1))
    @test isfinite(v1)
    @test !isfinite(LabeledValue(Inf, lbls1))

    @test v1 == 1
    @test 1 == v1
    @test ismissing(v1 == missing)
    @test ismissing(missing == v1)
    @test isequal(v1, 1)
    @test isequal(1, v1)
    @test isequal(v4, missing)
    @test isequal(missing, v4)
    @test v1 < 2
    @test 0 < v1
    @test ismissing(v1 < missing)
    @test ismissing(missing < v1)
    @test isless(v1, 2)
    @test isless(0, v1)
    @test isless(v1, missing)
    @test !isless(missing, v1)
    @test isapprox(v3, 1.0)
    @test isapprox(1.0, v3)

    @test hash(v1) == hash(v1.value)
    d = Dict{LabeledValue, Int}(v1 => 1)
    @test haskey(d, v3)

    @test length(v1) == 1

    @test unwrap(v1) === 1
    @test valuelabel(v1) == "a"
    @test valuelabel(v4) == "missing"
    @test getvaluelabels(v1) === v1.labels

    @test sprint(show, v1) == "a"
    @test sprint(show, v4) == "missing"
    @test sprint(show, MIME("text/plain"), v1) == "1 => a"

    v5 = convert(LabeledValue{Int16, Int32}, v1)
    @test v5.value isa Int16
    @test v5.labels === v1.labels
    @test convert(String, v1) == "a"
end

@testset "LabeledArray" begin
    vals = repeat(1:3, inner=2)
    lbls = Dict{Union{Int,Missing},String}(i=>string(i) for i in 1:3)
    x = LabeledArray(vals, lbls)
    @test eltype(x) == LabeledValue{Int, Union{Int,Missing}}
    @test size(x) == (6,)
    @test IndexStyle(typeof(x)) == IndexStyle(typeof(vals))
    @test DataAPI.defaultarray(eltype(x), 1) == typeof(x)
    @test length(unique(x)) == 3
    @test typeof(repeat(x, 2)) == typeof(x)
    @test repeat(x, 2) == LabeledArray(repeat(vals, 2), lbls)
    @test typeof(repeat(x, inner=2, outer=2)) == typeof(x)
    @test repeat(x, inner=2, outer=2) == LabeledArray(repeat(vals, inner=2, outer=2), lbls)
    x0 = typeof(x)(undef, 10)
    @test length(x0) == 10
    @test isempty(getvaluelabels(x0))

    v = ["a", "b", "c"]
    l = LabeledArray(v, Int16)
    @test l == 1:3
    @test valuelabels(l) == v

    @test x[1] === LabeledValue(1, lbls)
    @test x[Int16(1)] === LabeledValue(1, lbls)
    s = x[2:3]
    @test s == [1, 2]
    @test s isa LabeledArray
    @test s.labels === lbls
    s = x[isodd.(1:6)]
    @test s == [1, 2, 3]
    @test s isa LabeledArray
    @test s.labels === lbls

    x2 = LabeledArray([1:3 1:3], lbls)
    ra = refarray(x2)
    @test size(ra) == (3, 2)
    @test ra isa Matrix{Int64}

    @test x2[1] === LabeledValue(1, lbls)
    @test x2[1,1] === LabeledValue(1, lbls)
    s = x2[2:3]
    @test s == [2, 3]
    @test s isa LabeledArray
    @test s.labels === lbls
    s = x2[isodd.(1:6)]
    @test s == [1, 3, 2]
    @test s isa LabeledArray
    @test s.labels === lbls
    s = x2[1,1:2]
    @test s == [1, 1]
    @test s isa LabeledArray
    @test s.labels === lbls
    s = x2[2,isodd.(1:2)]
    @test s isa LabeledArray
    @test s.labels === lbls

    @test view(x, 1:3)[Int16(1)] === LabeledValue(1, lbls)
    @test reshape(x, 2, 3)[Int16(1)] === LabeledValue(1, lbls)
    v = view(x, 1:3)[1:2]
    @test v isa LabeledArray
    @test v.labels === lbls
    v = reshape(x, 3, 2)[1:2]
    @test v isa LabeledArray
    @test v.labels === lbls
    v = reshape(x, 3, 2)[1:2, 1:2]
    @test v isa LabeledArray
    @test v.labels === lbls
    v = view(x2, 1:3)[1:2]
    @test v isa LabeledArray
    @test v.labels === lbls

    @test view(x2, 1:2, 1:2)[Int16(1)] === LabeledValue(1, lbls)
    @test reshape(x2, 2, 3)[Int16(1)] === LabeledValue(1, lbls)
    v = view(x2, 1:2, 1:2)[1,1]
    @test v isa LabeledValue
    @test v.labels === lbls
    v = view(x2, 1:2, 1:2)[Int16(1),Int16(1)]
    @test v isa LabeledValue
    @test v.labels === lbls
    v = view(x2, 1:2, 1:2)[1,1:2]
    @test v isa LabeledArray
    @test v.labels === lbls

    x[1] = 2
    @test x[1] == 2
    x[1:2] .= 1
    @test all(x[1:2] .== 1)
    x2[1,1:2] .= 2
    @test all(x2[1,1:2] .== 2)

    vals1 = [1, 2, missing]
    x1 = LabeledArray(vals1, lbls)
    @test isequal(x1[3], missing)
    @test isequal(x1[3], LabeledValue(missing, Dict{Any,String}()))
    @test length(unique(vals1)) == 3

    @test refarray(x) === x.values
    @test refarray(view(x, [1, 3])) == 1:2
    @test refarray(reshape(x, 3, 2)) == reshape(x.values, 3, 2)
    @test refarray(view(x2, 1:3)) == x2.values[1:3]

    @test_throws MethodError disallowmissing(x1)
    @test typeof(disallowmissing(x1[1:2])) ==
        LabeledVector{Int64, Vector{Int64}, Union{Missing, Int64}}

    @test typeof(repeat(x1, 2)) == typeof(x1)
    @test typeof(repeat(x1, inner=2)) == typeof(x1)

    x3 = LabeledArray(copy(vals1), lbls)
    fill!(x3, 1)
    @test all(x3 .== 1)

    v = copy(x)
    @test v == x
    @test refarray(v) !== refarray(x)
    @test v.labels === x.labels
    resize!(v, 7)
    @test length(v) == 7
    push!(v, 1)
    @test v[8] == 1
    push!(v, 5=>"0")
    @test v[end] == 5
    @test getvaluelabels(v)[5] == "0"
    pushfirst!(v, 2)
    @test v[1] == 2
    pushfirst!(v, 6=>"-1")
    @test v[1] == 6
    @test getvaluelabels(v)[6] == "-1"
    insert!(v, 3, 4)
    @test v[3] == 4
    deleteat!(v, 3)
    @test length(v) == 11
    @test v[3] == 1
    append!(v, 1:3)
    @test length(v) == 14
    @test v[12:14] == 1:3
    prepend!(v, 1:3)
    @test length(v) == 17
    @test v[1:3] == 1:3
    empty!(v)
    @test isempty(v)
    sizehint!(v, 10)

    y = LabeledArray(copy(vals), copy(lbls))
    @test x == y
    y.labels[4] = "4"
    @test x == y
    y.values[1] = 2
    @test x != y

    @test x == vals
    @test vals == x

    x2 = convert(AbstractVector{LabeledValue{Int16,Union{Int,Missing}}}, x)
    @test typeof(x2) == LabeledVector{Int16, Vector{Int16}, Union{Int,Missing}}
    @test x2.values == x.values
    @test x2.labels === x.labels

    @test convert(AbstractVector{LabeledValue{Int,Union{Int,Missing}}}, x) === x

    x3 = convertvalue(Int16, x)
    @test typeof(x3) == LabeledVector{Int16, Vector{Int16}, Union{Int,Missing}}
    @test x3.values == x.values
    @test x3.labels === x.labels

    s = similar(x)
    @test typeof(s) == typeof(x)
    s = similar(x, LabeledValue{Int16})
    @test s isa LabeledArray
    @test eltype(s) == LabeledValue{Int16, keytype(lbls)}
    copyto!(s, x)
    @test s == x
    s = similar(x, (3, 3))
    @test s isa LabeledArray
    @test size(s) == (3, 3)
    s = similar(x, LabeledValue{Int16}, (3, 3))
    @test s isa LabeledArray
    @test eltype(s) == LabeledValue{Int16, keytype(lbls)}
    @test size(s) == (3, 3)
    s = similar(x, Union{LabeledValue{Int16, keytype(lbls)}, Missing})
    @test s isa LabeledArray
    @test eltype(s) == LabeledValue{Union{Missing, Int16}, Union{Missing, Int64}}
    s = similar(x, Union{LabeledValue{Int16, keytype(lbls)}, Missing}, (3, 3))
    @test s isa LabeledArray
    @test eltype(s) == LabeledValue{Union{Missing, Int16}, Union{Missing, Int64}}
    @test size(s) == (3, 3)
    copyto!(s, 1:3, 1:1, x, 1:3, 1:1)
    @test s[1:3] == x[1:3]

    x1 = copy(x)
    @test x1 == x
    @test refarray(x1) !== refarray(x)
    @test typeof(x1) == typeof(x)
    @test x1.labels === x.labels

    dest = similar(x)
    copyto!(dest, x1)
    @test isequal(dest, refarray(x1))
    d1 = similar(refarray(dest))
    copyto!(d1, x1)
    @test isequal(d1, x1)
    dest = similar(x)
    copyto!(IndexLinear(), dest, IndexLinear(), x1)
    @test isequal(dest, refarray(x1))
    d1 = similar(refarray(dest))
    copyto!(IndexLinear(), d1, IndexLinear(), x1)
    @test isequal(d1, x1)
    dest = similar(x)
    copyto!(dest, 2, view(x1, 1:3))
    @test isequal(dest[2:4], view(refarray(x1), 1:3))
    d1 = similar(refarray(dest))
    copyto!(d1, 2, view(x1, 1:3))
    @test isequal(d1[2:4], view(refarray(x1), 1:3))
    dest = similar(x)
    copyto!(dest, 2:4, 1:1, x1, 1:3, 1:1)
    @test isequal(dest[2:4], view(refarray(x1), 1:3))
    d1 = similar(refarray(dest))
    copyto!(d1, 2:4, 1:1, x1, 1:3, 1:1)
    @test isequal(d1[2:4], view(refarray(x1), 1:3))

    x2 = collect(x)
    @test x2 == x
    @test x2 isa LabeledArray
    @test eltype(x2) == eltype(x)

    x2 = collect(view(x, 1:3))
    @test x2 == view(x, 1:3)
    @test x2 isa LabeledArray
    @test eltype(x2) == eltype(x)

    x2 = collect(LabeledValue{Int16, Int}, view(x, 1:3))
    @test x2 == view(x, 1:3)
    @test x2 isa LabeledArray
    @test eltype(x2) == LabeledValue{Int16, keytype(lbls)}

    lbs = valuelabels(x)
    @test size(lbs) == size(x)
    @test IndexStyle(typeof(lbs)) == IndexLinear()
    @test lbs[1] == "1"
    @test eltype(typeof(lbs)) == String
    @test length(lbs) == length(x)

    v = view(x, 1:3)
    lbs = valuelabels(v)
    @test size(lbs) == size(v)
    @test lbs[3] == "2"

    x1 = LabeledArray(vals1, lbls)
    lbs1 = valuelabels(x1)
    @test lbs1[3] == "missing"

    c = CategoricalArray(valuelabels(x))
    @test c == string.(vals)
end
