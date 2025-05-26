using Test
using SafeTestsets
using DocumenterCitations


# Note: comment outer @testset to stop after first @safetestset failure
@time @testset verbose = true "DocumenterCitations" begin

    println("\n* formatting (test_formatting.jl):")
    @time @safetestset "formatting" begin
        include("test_formatting.jl")
    end

    println("\n* tex to markdown (test_tex_to_markdown.jl):")
    @time @safetestset "tex_to_markdown" begin
        include("test_tex_to_markdown.jl")
    end

    println("\n* parse_bibliography_block (test_parse_bibliography_block.jl):")
    @time @safetestset "parse_bibliography_block" begin
        include("test_parse_bibliography_block.jl")
    end

    println("\n* bibliography_block_pages (test_bibliography_block_pages.jl):")
    @time @safetestset "bibliography_block_pages" begin
        include("test_bibliography_block_pages.jl")
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

    println("\n* anchor_keys (test_anchor_keys.jl):")
    @time @safetestset "anchor_keys" begin
        include("test_anchor_keys.jl")
    end

    println("\n* integration test (test_integration.jl):")
    @time @safetestset "integration" begin
        include("test_integration.jl")
    end

    println("\n* doctest (test_doctest.jl)")
    @time @safetestset "doctest" begin
        include("test_doctest.jl")
    end

    println("\n* latex rendering (test_latex_rendering.jl)")
    @time @safetestset "latex_rendering" begin
        include("test_latex_rendering.jl")
    end

    println("\n* test undefined citations (test_undefined_citations.jl):")
    @time @safetestset "undefined_citations" begin
        include("test_undefined_citations.jl")
    end

    println("\n* test link checking (test_linkcheck.jl):")
    @time @safetestset "linkcheck" begin
        import Pkg
        using Documenter: DOCUMENTER_VERSION
        run_linkcheck = true
        if !Sys.isexecutable("/usr/bin/env")  # used by mock `curl`
            run_linkcheck = false
            @info "Skipped test_linkcheck.jl (cannot mock `curl`)"
        elseif DOCUMENTER_VERSION < v"1.2"
            run_linkcheck = false
            @info "Skipped test_linkcheck.jl (old version of Documenter)"
        elseif haskey(ENV, "JULIA_PKGEVAL")
            run_linkcheck = false
            @info "Skipped test_linkcheck.jl (running in PkgEval)"
        end
        run_linkcheck && include("test_linkcheck.jl")
    end

    print("\n")

end

nothing  # avoid noise when doing `include("test/runtests.jl")`
