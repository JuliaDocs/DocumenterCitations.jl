using Test
using SafeTestsets
using DocumenterCitations


# Note: comment outer @testset to stop after first @safetestset failure
@time @testset verbose = true "DocumenterCitations" begin

    println("\n* formatting (test_formatting.jl):")
    @time @safetestset "formatting" begin
        include("test_formatting.jl")
    end

    println("\n* parse_bibliography_block (test_parse_bibliography_block.jl):")
    @time @safetestset "parse_bibliography_block" begin
        include("test_parse_bibliography_block.jl")
    end

    println("\n* parse_citation_link (test_parse_citation_link.jl):")
    @time @safetestset "parse_citation_link" begin
        include("test_parse_citation_link.jl")
    end

    println("\n* smart alpha style (test_alphastyle.jl):")
    @time @safetestset "smart alpha style" begin
        include("test_alphastyle.jl")
    end

    println("\n* collect from docstrings (test_collect_from_docstrings.jl):")
    @time @safetestset "collect_from_docstrings" begin
        include("test_collect_from_docstrings.jl")
    end

    println("\n* content_bock (test_content_block.jl):")
    @time @safetestset "content_block" begin
        include("test_content_block.jl")
    end

    println("\n* md_ast (test_md_ast.jl):")
    @time @safetestset "md_ast" begin
        include("test_md_ast.jl")
    end

    println("\n* keys_with_underscores (test_keys_with_underscores.jl):")
    @time @safetestset "keys_with_underscores" begin
        include("test_keys_with_underscores.jl")
    end

    println("\n* integration test (test_integration.jl):")
    @time @safetestset "integration" begin
        include("test_integration.jl")
    end

    println("\n* doctest (test_doctest.jl)")
    @time @safetestset "doctest" begin
        include("test_doctest.jl")
    end

    println("\n* test undefined citations (test_undefined_citations.jl):")
    @time @safetestset "undefined_citations" begin
        include("test_undefined_citations.jl")
    end

    print("\n")

end

nothing  # avoid noise when doing `include("test/runtests.jl")`
