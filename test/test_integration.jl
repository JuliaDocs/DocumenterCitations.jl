using DocumenterCitations
using Documenter
using Test

include("run_makedocs.jl")

CUSTOM1 = joinpath(@__DIR__, "..", "docs", "custom_styles", "enumauthoryear.jl")
CUSTOM2 = joinpath(@__DIR__, "..", "docs", "custom_styles", "keylabels.jl")

include(CUSTOM1)
include(CUSTOM2)


@testset "Integration Test" begin

    # We build the documentation of DocumenterCitations itself as a test

    bib = CitationBibliography(
        joinpath(@__DIR__, "..", "docs", "src", "refs.bib"),
        style=:numeric
    )
    run_makedocs(
        joinpath(@__DIR__, "..", "docs");
        sitename="DocumenterCitations.jl",
        plugins=[bib],
        format=Documenter.HTML(;
            prettyurls = true,
            canonical  = "https://juliadocs.github.io/DocumenterCitations.jl",
            assets     = String["assets/citations.css"],
            footer     = "Generated by Test",
            edit_link  = "",
            repolink   = ""
        ),
        pages=[
            "Home"                   => "index.md",
            "Syntax"                 => "syntax.md",
            "Citation Style Gallery" => "gallery.md",
            "CSS Styling"            => "styling.md",
            "Internals"              => "internals.md",
            "References"             => "references.md",
        ],
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success
        @test occursin("Info: CollectCitations", output)
        @test occursin("Info: ExpandBibliography", output)
        @test occursin("Info: ExpandCitations", output)

        ref_outfile = joinpath(dir, "build", "references", "index.html")
        @test isfile(ref_outfile)

        # Check that we have the list of cited reference and then the list of
        # all references on the main References page
        html = read(ref_outfile, String)
        rx = r"<div class=\"citation canonical\"><dl><dt>\[(\d{1,3})\]</dt>"
        matches = collect(eachmatch(rx, html))
        @test length(matches) == 2
        @test parse(Int64, matches[1].captures[1]) == 1
        # Assuming there are at least 5 explicitly cited references in the
        # docs:
        @test parse(Int64, matches[2].captures[1]) > 5

    end

end


@testset "Integration Test - dumb :alpha" begin

    # We build the documentation of DocumenterCitations itself with the
    # genuinely dumb :alpha style. Since `:alpha` usually gets upgraded
    # automatically to `AlphaStyle`, we don't get good coverage for :alpha
    # otherwise.

    using Bibliography
    using OrderedCollections: OrderedDict

    bibfile = joinpath(@__DIR__, "..", "docs", "src", "refs.bib")
    style = :alpha
    entries = Bibliography.import_bibtex(bibfile)
    citations = OrderedDict{String,Int64}()
    page_citations = Dict{String,Set{String}}()
    anchor_map = Documenter.AnchorMap()

    bib =
        CitationBibliography(bibfile, style, entries, citations, page_citations, anchor_map)

    run_makedocs(
        joinpath(@__DIR__, "..", "docs");
        sitename="DocumenterCitations.jl",
        plugins=[bib],
        pages=[
            "Home"                   => "index.md",
            "Syntax"                 => "syntax.md",
            "Citation Style Gallery" => "gallery.md",
            "CSS Styling"            => "styling.md",
            "Internals"              => "internals.md",
            "References"             => "references.md",
        ],
        check_success=true
    ) do dir, result, success, backtrace, output
        @test success
    end

end
