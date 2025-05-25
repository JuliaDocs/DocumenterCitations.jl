using DocumenterCitations
using DocumenterCitations: get_anchor_key
using Test
using Bijections
using TestingUtilities: @Test  # much better at comparing strings
using IOCapture: IOCapture

include("run_makedocs.jl")

@testset "anchor key ambiguity" begin

    cache = Bijections.Bijection{String,String}()

    anchor_key = get_anchor_key("AbsilMahonySepulchre:2008", cache)
    @test anchor_key == "AbsilMahonySepulchre2008"

    # cache hit
    @test cache("AbsilMahonySepulchre2008") == "AbsilMahonySepulchre:2008"
    anchor_key = get_anchor_key("AbsilMahonySepulchre:2008", cache)
    @test anchor_key == "AbsilMahonySepulchre2008"

    anchor_key = get_anchor_key("2008_AbsilMahonySepulchre", cache)
    @test anchor_key == "cit-2008_AbsilMahonySepulchre"

    c = IOCapture.capture(rethrow=Union{}) do
        get_anchor_key("AbsilMahonySepulchre.2008", cache)
    end
    @test c.value == "AbsilMahonySepulchre2008-2"
    msg = "Warning: HTML anchor for citation key \"AbsilMahonySepulchre.2008\" normalizes to ambiguous \"AbsilMahonySepulchre2008\" conflicting with citation key \"AbsilMahonySepulchre:2008\". Disambiguating with suffix \"-2\""
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

        @test bib.anchor_keys["Chirikjian:2012"] == "Chirikjian2012"
        @test bib.anchor_keys["Chirikjian2012"] == "Chirikjian2012-2"

        @test contains(output, "normalizes to ambiguous \"Chirikjian2012\"")

        #! format: off
        index_html = read(joinpath(dir, "build", "index.html"), String)
        @Test contains(index_html, "<a href=\"references/#Chirikjian2012\">")
        @Test contains(index_html, "<a href=\"references/#Chirikjian2012-2\">")

        references_html = read(joinpath(dir, "build", "references", "index.html"), String)
        @Test contains(references_html, "<div id=\"Chirikjian2012\">")
        @Test contains(references_html, "<div id=\"Chirikjian2012-2\">")
        #! format: on

    end

end
