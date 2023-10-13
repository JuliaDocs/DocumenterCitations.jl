using DocumenterCitations
using Test
using TestingUtilities: @Test  # much better at comparing strings
using IOCapture: IOCapture

include("run_makedocs.jl")


@testset "keys with underscores" begin

    # https://github.com/JuliaDocs/DocumenterCitations.jl/issues/14

    bib = CitationBibliography(
        joinpath(@__DIR__, "test_keys_with_underscores", "src", "refs.bib"),
        style=:numeric
    )

    run_makedocs(
        joinpath(@__DIR__, "test_keys_with_underscores");
        sitename="Test",
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",],
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success

        #! format: off
        index_html = read(joinpath(dir, "build", "index.html"), String)
        @Test contains(index_html, "[<a href=\"references/#rabiner_tutorial_1989\">1</a>]")
        @Test contains(index_html, "[<a href=\"references/#GoerzQ2022\">2</a>, with <em>emphasis</em>]")

        references_html = read(joinpath(dir, "build", "references", "index.html"), String)
        @Test contains(references_html, "<div id=\"rabiner_tutorial_1989\">")
        @Test contains(references_html, "<div id=\"GoerzQ2022\">")
        #! format: on

    end

end


@testset "keys with underscores (ambiguities)" begin

    success = @test_throws ErrorException begin
        CitationBibliography(
            joinpath(
                @__DIR__,
                "test_keys_with_underscores_ambiguities",
                "src",
                "refs_invalid.bib"
            ),
            style=:numeric
        )
    end
    @test contains(success.value.msg, "Ambiguous key \"rabiner_tutorial*1989\"")

    bib = CitationBibliography(
        joinpath(@__DIR__, "test_keys_with_underscores_ambiguities", "src", "refs.bib"),
        style=:numeric
    )

    # keys should have been normalized to underscores
    @test collect(keys(bib.entries)) == ["rabiner_tutorial_1989", "Goerz_Q_2022"]

    run_makedocs(
        joinpath(@__DIR__, "test_keys_with_underscores_ambiguities");
        sitename="Test",
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",],
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success

        #! format: off
        index_html = read(joinpath(dir, "build", "index.html"), String)
        @Test contains(index_html, "[<a href=\"references/#rabiner_tutorial_1989\">1</a>]")
        @Test contains(index_html, "[<a href=\"references/#Goerz_Q_2022\">2</a>]")
        @test !contains(index_html, "*")  # everything was normalized to "_"

        references_html = read(joinpath(dir, "build", "references", "index.html"), String)
        @Test contains(references_html, "<div id=\"rabiner_tutorial_1989\">")
        @Test contains(references_html, "<div id=\"Goerz_Q_2022\">")
        @test !contains(references_html, "*")  # everything was normalized to "_"
        #! format: on

    end

end
