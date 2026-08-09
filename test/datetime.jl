@testset "HMS" begin
    t0 = HMS(0)
    t1 = HMS(100.0)
    t2 = HMS(200)
    t3 = HMS(100)

    @test unwrap(t1) === 100.0
    @test t1 == t3
    @test t1 == 100
    @test 100 == t1
    @test ismissing(t1 == missing)
    @test ismissing(missing == t1)
    @test isequal(t1, t3)
    @test isequal(t1, 100)
    @test isequal(100, t1)
    @test !isequal(t1, missing)
    @test !isequal(missing, t1)
    @test t1 < t2
    @test t1 < 200
    @test 0 < t1
    @test ismissing(t1 < missing)
    @test ismissing(missing < t1)
    @test isless(t1, t2)
    @test isless(t1, 200)
    @test isless(0, t1)
    @test isless(t1, missing)
    @test !isless(missing, t1)
    @test isapprox(t1, t3)
    @test isapprox(t1, 100)
    @test isapprox(100, t1)
    @test !ismissing(t1)

    @test iszero(t0)
    @test isnan(HMS(NaN))
    @test isinf(HMS(Inf))
    @test isfinite(t1)

    @test hash(t1) == hash(t1.value)
    @test length(t1) == 1

    @test t1 + t2 == HMS(300)
    @test t1 + 100 == HMS(200)
    @test 100 + t1 == 200
    @test ismissing(t1 + missing)
    @test ismissing(missing + t1)
    @test t1 - t2 == HMS(-100)
    @test t1 - 100 == 0
    @test 100 - t1 == HMS(0)
    @test ismissing(t1 - missing)
    @test ismissing(missing - t1)
    @test -t1 == HMS(-100)
    @test abs(HMS(-10)) == 10

    @test Time(HMS(123.456)) == Time("00:02:03.456")

    @test sprint(show, HMS(123456.789)) == "34:17:36.79"
    @test sprint(show, MIME("text/plain"), [HMS(1e6),HMS(-1.2)]) == """
        2-element Vector{HMS{Float64}}:
         277:46:40.00
          -0:00:01.20"""
end

@testset "HMSCol" begin
    x = HMSCol([1e6, -1.2, 123.456, missing])
    @test refarray(x) === x.a
    @test refarray(view(x,1:2)) == view(x.a,1:2)

    @test size(x) == (4,)
    @test IndexStyle(x) == IndexStyle(x.a)
    @test x[1] == HMS(1e6)
    @test ismissing(x[4])
    x[1] = HMS(123)
    @test x[1] == 123
    x[1] = 456
    @test x[1] == HMS(456)
    x1 = similar(x)
    @test typeof(x1) == typeof(x)
    @test size(x1) == size(x)

    # HMSCol copy is still HMSCol
    @test copy(x) == typeof(x)
end
