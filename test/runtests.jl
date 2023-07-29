using Test
using SafeTestsets


# Note: comment outer @testset to stop after first @safetestset failure
@time @testset verbose = true "DocumenterCitations" begin

    print("\n* formatting (test_formatting.jl):")
    @time @safetestset "formatting" begin
        include("test_formatting.jl")
    end

    print("\n* parse_bibliography_block (test_parse_bibliography_block.jl):")
    @time @safetestset "parse_bibliography_block" begin
        include("test_parse_bibliography_block.jl")
    end

    print("\n* parse_citation_link (test_parse_citation_link.jl):")
    @time @safetestset "parse_citation_link" begin
        include("test_parse_citation_link.jl")
    end

    print("\n* smart alpha style (test_alphastyle.jl):")
    @time @safetestset "smart alpha style" begin
        include("test_alphastyle.jl")
    end

    print("\n* integration test (test_makedocs.jl):")
    @time @safetestset "makedocs" begin
        include("test_makedocs.jl")
    end


    print("\n")

end;
