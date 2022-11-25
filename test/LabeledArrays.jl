@testset "LabeledValue" begin
    lbls1 = Dict{Any,String}(1=>"a", 2=>"b")
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

    @test v1 == 1
    @test 1 == v1
    @test v1 == "a"
    @test "a" == v1
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

    @test unwrap(v1) === 1
    @test labels(v1) == "a"
    @test labels(v4) == "missing"

    @test sprint(show, v1) == "a"
    @test sprint(show, v4) == "missing"
    @test sprint(show, MIME("text/plain"), v1) == "1 => a"

    @test convert(String, v1) == "a"
end

@testset "LabeledArray" begin
    vals = repeat(1:3, inner=2)
    lbls = Dict{Any,String}(i=>string(i) for i in 1:3)
    x = LabeledArray(vals, lbls)
    @test eltype(x) == LabeledValue{Int}
    @test size(x) == (6,)
    @test IndexStyle(typeof(x)) == IndexLinear()

    @test x[1] === LabeledValue(1, lbls)
    @test x[2:3] == [1, 2]
    @test x[isodd.(1:6)] == [1, 2, 3]
    @test_throws ArgumentError LabeledArray(string.(vals), Dict{Any,String}())

    vals1 = [1, 2, missing]
    x1 = LabeledArray(vals1, lbls)
    @test isequal(x1[3], missing)
    @test x1[3] == "missing"

    @test refarray(x) === x.values
    @test refarray(view(x, [1, 3])) == 1:2
    @test refarray(reshape(x, 3, 2)) == reshape(x.values, 3, 2)
    @test collect(x) == x

    x2 = LabeledArray([1:3 1:3], lbls)
    ra = refarray(collect(x2))
    @test size(ra) == (3, 2)
    @test ra isa Matrix{Int64}

    lbs = labels(x)
    @test size(lbs) == size(x)
    @test IndexStyle(typeof(lbs)) == IndexLinear()
    @test lbs[1] == "1"
    @test eltype(typeof(lbs)) == String
    @test length(lbs) == length(x)

    v = view(x, 1:3)
    lbs = labels(v)
    @test size(lbs) == size(v)
    @test lbs[3] == "2"

    lbs1 = labels(x1)
    @test lbs1[3] == "missing"

    y = LabeledArray(copy(vals), copy(lbls))
    @test x == y
    y.labels[4] = "4"
    @test x == y
    y.values[1] = 2
    @test x != y

    @test x == vals
    @test vals == x
    @test x == string.(vals)
    @test string.(vals) == x

    @test copy(x) == x
    @test typeof(copy(x)) == typeof(x)

    @test convert(Vector{Int}, x) === x.values
    @test convert(Vector{Int16}, x) == x.values

    c = CategoricalArray(labels(x))
    @test c == string.(vals)
end
