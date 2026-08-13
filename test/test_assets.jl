using DocumenterCitations
using Documenter
using Test
using TestingUtilities: @Test  # much better at comparing strings

include("run_makedocs.jl")


# The `<link>` tag that `Documenter` renders for the bundled stylesheet. The
# `href` is relative to the page, which is why all tests here use
# `prettyurls=false` (all pages are in the top-level `build` folder).
const CSS_LINK = "<link href=\"assets/documentercitations/citations.css\" rel=\"stylesheet\" type=\"text/css\"/>"


@testset "automatic asset insertion" begin

    bib = CitationBibliography(joinpath(@__DIR__, "test_assets", "src", "refs.bib"))

    run_makedocs(
        joinpath(@__DIR__, "test_assets");
        sitename="Test",
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",],
        format=Documenter.HTML(edit_link="master", repolink=" ", prettyurls=false),
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success

        css_outfile =
            joinpath(dir, "build", "assets", "documentercitations", "citations.css")
        @test isfile(css_outfile)
        packaged_css = joinpath(DocumenterCitations.ASSETS_FOLDER, "citations.css")
        @Test read(css_outfile, String) == read(packaged_css, String)

        index_html = read(joinpath(dir, "build", "index.html"), String)
        @Test contains(index_html, CSS_LINK)

        references_html = read(joinpath(dir, "build", "references.html"), String)
        @Test contains(references_html, CSS_LINK)

    end

end


@testset "custom assets take precedence" begin

    bib = CitationBibliography(joinpath(@__DIR__, "test_assets", "src", "refs.bib"))

    run_makedocs(
        joinpath(@__DIR__, "test_assets");
        sitename="Test",
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",],
        format=Documenter.HTML(
            edit_link="master",
            repolink=" ",
            prettyurls=false,
            assets=String["assets/citations.css"],
        ),
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success

        index_html = read(joinpath(dir, "build", "index.html"), String)
        custom_link = "<link href=\"assets/citations.css\" rel=\"stylesheet\" type=\"text/css\"/>"
        @Test contains(index_html, CSS_LINK)
        @Test contains(index_html, custom_link)
        # The custom stylesheet must come *after* the bundled one, so that its
        # rules take precedence
        @test findfirst(CSS_LINK, index_html).start <
              findfirst(custom_link, index_html).start

    end

end


@testset "no assets without HTML output" begin

    bib = CitationBibliography(joinpath(@__DIR__, "test_assets", "src", "refs.bib"))

    run_makedocs(
        joinpath(@__DIR__, "test_assets");
        sitename="Test",
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",],
        format=Documenter.LaTeX(platform="none"),
        env=Dict("DOCUMENTER_BUILD_PDF" => "1"),
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success
        @test !isdir(joinpath(dir, "build", "assets", "documentercitations"))

    end

end
