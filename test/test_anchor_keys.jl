using DocumenterCitations
using DocumenterCitations: get_anchor_key
using Test
using Bijections
using TestingUtilities: @Test  # much better at comparing strings
using IOCapture: IOCapture

include("run_makedocs.jl")


@testset "Documenter.DOM anchors" begin
    Documenter.DOM.@tags div
    @test string(div["#anchor"]("")) == "<div id=\"anchor\"></div>"
    @test string(div["#anchor-suffix"]("")) == "<div id=\"anchor-suffix\"></div>"
    @test string(div["#anchor_suffix"]("")) == "<div id=\"anchor_suffix\"></div>"
    # The way that Documenter.DOM eats `:` and `.` is the reason we have to
    # strip those characters from citation keys. If that behavior ever changes,
    # we can reconsider.
    @test_broken string(div["#anchor:suffix"]("")) == "<div id=\"anchor:suffix\"></div>"
    @test_broken string(div["#anchor.suffix"]("")) == "<div id=\"anchor.suffix\"></div>"
end


@testset "anchor key ambiguity" begin

    cache = Bijections.Bijection{String,String}()

    anchor_key = get_anchor_key("AbsilMahonySepulchre:2008", cache)
    @test anchor_key == "AbsilMahonySepulchre_2008"

    # cache hit
    @test cache("AbsilMahonySepulchre_2008") == "AbsilMahonySepulchre:2008"
    anchor_key = get_anchor_key("AbsilMahonySepulchre:2008", cache)
    @test anchor_key == "AbsilMahonySepulchre_2008"

    # Invalid: starts with number
    anchor_key = get_anchor_key("2008_AbsilMahonySepulchre", cache)
    @test anchor_key == "cit-2008_AbsilMahonySepulchre"

    # Ambiguous: periods are not allowed allowed (substituted with '_')
    c = IOCapture.capture(rethrow=Union{}) do
        get_anchor_key("AbsilMahonySepulchre.2008", cache)
    end
    @test c.value == "AbsilMahonySepulchre_2008-2"
    msg = "Warning: HTML anchor for citation key \"AbsilMahonySepulchre.2008\" normalizes to ambiguous \"AbsilMahonySepulchre_2008\" conflicting with citation key \"AbsilMahonySepulchre:2008\". Disambiguating with suffix \"-2\""
    @test contains(c.output, msg)

    # Ambiguous key: `=` is not allowed (dropped)
    c = IOCapture.capture(rethrow=Union{}) do
        get_anchor_key("AbsilMahonySepulchre_=2008", cache)
    end
    @test c.value == "AbsilMahonySepulchre_2008-3"
    msg = "Warning: HTML anchor for citation key \"AbsilMahonySepulchre_=2008\" normalizes to ambiguous \"AbsilMahonySepulchre_2008\" conflicting with citation key \"AbsilMahonySepulchre:2008\". Disambiguating with suffix \"-2\""
    @test contains(c.output, msg)
    msg = "Warning: HTML anchor for citation key \"AbsilMahonySepulchre_=2008\" normalizes to ambiguous \"AbsilMahonySepulchre_2008-2\" conflicting with citation key \"AbsilMahonySepulchre.2008\". Disambiguating with suffix \"-3\""
    @test contains(c.output, msg)

end


@testset "keys with symbols" begin

    # https://github.com/JuliaDocs/DocumenterCitations.jl/issues/86

    bib = CitationBibliography(
        joinpath(@__DIR__, "test_anchor_keys", "src", "refs.bib"),
        style=:numeric
    )

    run_makedocs(
        joinpath(@__DIR__, "test_anchor_keys");
        sitename="Test",
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",],
        warnonly=true,
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success

        @test bib.anchor_keys["Chirikjian:2012"] == "Chirikjian_2012"
        @test bib.anchor_keys["Chirikjian_2012"] == "Chirikjian_2012-2"

        @test contains(output, "normalizes to ambiguous \"Chirikjian_2012\"")

        #! format: off
        index_html = read(joinpath(dir, "build", "index.html"), String)
        @Test contains(index_html, "<a href=\"references/#Chirikjian_2012\">")
        @Test contains(index_html, "<a href=\"references/#Chirikjian_2012-2\">")

        references_html = read(joinpath(dir, "build", "references", "index.html"), String)
        @Test contains(references_html, "<div id=\"Chirikjian_2012\">")
        @Test contains(references_html, "<div id=\"Chirikjian_2012-2\">")
        #! format: on

    end

end
