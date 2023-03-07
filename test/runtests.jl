using Test
using SafeTestsets


# Note: comment outer @testset to stop after first @safetestset failure
@time @testset verbose = true "QuantumCitations" begin

    print("\n* tex2unicode (test_tex2unicode.jl):")
    @time @safetestset "tex2unicode" begin
        include("test_tex2unicode.jl")
    end


    print("\n* integration test (test_makedocs.jl):")
    @time @safetestset "makedocs" begin
        include("test_makedocs.jl")
    end

    print("\n")

end;
