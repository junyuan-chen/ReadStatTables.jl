@testset "LabeledValue" begin
    v1 = LabeledValue(1, "a")
    v2 = LabeledValue(2, "b")
    v3 = LabeledValue(1, "b")
    @test v1 < v2
    @test v1 == v1
    @test v1 != v3
    @test sprint(show, v1) == "a"
    @test sprint(show, MIME("text/plain"), v1) == "1 => a\n"
end

@testset "LabeledArray" begin
    vals = repeat(1:3, inner=2)
    lbls = Dict(i=>string(i) for i in 1:3)
    x = LabeledArray(vals, lbls)
    @test eltype(x) == LabeledValue{Int}
    @test size(x) == (6,)
    @test IndexStyle(typeof(x)) == IndexLinear()

    @test x[1] == LabeledValue(1, "1")
    @test x[2:3] == LabeledValue.([1, 2], ["1", "2"])
    @test x[isodd.(1:6)] == LabeledValue.([1, 2, 3], ["1", "2", "3"])

    @test values(x) === x.values
    @test values(view(x, [1, 3])) == 1:2
    @test values(reshape(x, 3, 2)) == reshape(x.values, 3, 2)
    @test collect(values(collect(x))) == values(x)

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

    y = LabeledArray(copy(vals), copy(lbls))
    @test x == y
    y.labels[4] = "4"
    @test x != y
    delete!(y.labels, 4)
    @test x == y
    y.values[1] = 2
    @test x != y
end
