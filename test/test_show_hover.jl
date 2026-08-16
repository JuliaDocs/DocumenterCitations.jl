using DocumenterCitations
using Documenter
using Test
include("word_diff.jl")

include("run_makedocs.jl")


# The tags that `Documenter` renders for the bundled hover assets. The `href`
# and `src` are relative to the page, which is why the tests here use
# `prettyurls=false`, except where noted (all pages are in the top-level
# `build` folder).
const HOVER_CSS_LINK = "<link href=\"assets/documentercitations/citations-hover.css\" rel=\"stylesheet\" type=\"text/css\"/>"
const HOVER_JS_TAG = "<script src=\"assets/documentercitations/citations-hover.js\"></script>"
const HOVER_DATA_TAG = "<script src=\"assets/documentercitations/citations-data.js\"></script>"

# A distinctive part of the title of the only entry in the test fixture
const ENTRY_TEXT = "Semi-Automatic Differentiation"


@testset "show_hover=false" begin

    bib = CitationBibliography(
        joinpath(@__DIR__, "test_assets", "src", "refs.bib");
        show_hover=false
    )

    run_makedocs(
        joinpath(@__DIR__, "test_assets");
        sitename="Test",
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",],
        format=Documenter.HTML(edit_link="master", repolink=" ", prettyurls=false),
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success

        assets = joinpath(dir, "build", "assets", "documentercitations")
        @test !isfile(joinpath(assets, "citations-hover.css"))
        @test !isfile(joinpath(assets, "citations-hover.js"))
        @test !isfile(joinpath(assets, "citations-data.js"))

        index_html = read(joinpath(dir, "build", "index.html"), String)
        @test !contains(index_html, HOVER_CSS_LINK)
        @test !contains(index_html, HOVER_JS_TAG)
        @test !contains(index_html, HOVER_DATA_TAG)

        @test isempty(bib.hover_entries)

    end

end


@testset "automatic insertion of the hover assets" begin

    bib = CitationBibliography(joinpath(@__DIR__, "test_assets", "src", "refs.bib"))
    @test bib.show_hover  # on by default

    run_makedocs(
        joinpath(@__DIR__, "test_assets");
        sitename="Test",
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",],
        format=Documenter.HTML(edit_link="master", repolink=" ", prettyurls=false),
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success

        assets = joinpath(dir, "build", "assets", "documentercitations")
        for filename in ("citations-hover.css", "citations-hover.js")
            outfile = joinpath(assets, filename)
            @test isfile(outfile)
            packaged = joinpath(DocumenterCitations.ASSETS_FOLDER, filename)
            @test_diff read(outfile, String) == read(packaged, String)
        end

        for page in ("index.html", "references.html")
            html = read(joinpath(dir, "build", page), String)
            @test contains(html, HOVER_CSS_LINK)
            @test contains(html, HOVER_JS_TAG)
            @test contains(html, HOVER_DATA_TAG)
            # The data file must be loaded before the script that uses it
            @test findfirst(HOVER_DATA_TAG, html).start <
                  findfirst(HOVER_JS_TAG, html).start
        end

        data_file = joinpath(assets, "citations-data.js")
        @test isfile(data_file)
        data = read(data_file, String)
        @test contains(data, "window.DocumenterCitationsHoverData")
        @test contains(data, "GoerzQ2022")
        @test contains(data, ENTRY_TEXT)
        @test contains(data, "\"page\":\"references.html\"")
        # Any `</` in the entry HTML must be escaped, so that the data cannot
        # terminate the enclosing `<script>` tag
        @test !contains(data, "</")
        # The popup content must not duplicate the ID of the anchor in the
        # bibliography block
        @test !contains(data, "<div id=")

        # The entries are in `citations-data.js` precisely so that they stay
        # out of the pages: a browser that does not run JavaScript (or does not
        # apply CSS) must not end up with a copy of the bibliography on every
        # page that has citations
        index_html = read(joinpath(dir, "build", "index.html"), String)
        @test !contains(index_html, ENTRY_TEXT)
        @test !contains(index_html, "citation-hover-popup")
        @test !contains(index_html, "role=\"tooltip\"")

    end

end


@testset "hover data with prettyurls" begin

    bib = CitationBibliography(joinpath(@__DIR__, "test_assets", "src", "refs.bib"))

    run_makedocs(
        joinpath(@__DIR__, "test_assets");
        sitename="Test",
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",],
        format=Documenter.HTML(edit_link="master", repolink=" ", prettyurls=true),
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success

        data_file =
            joinpath(dir, "build", "assets", "documentercitations", "citations-data.js")
        @test isfile(data_file)
        data = read(data_file, String)
        @test contains(data, "\"page\":\"references/index.html\"")

    end

end


@testset "hover assets with insert_css=false" begin

    # The two options are independent of each other

    bib = CitationBibliography(
        joinpath(@__DIR__, "test_assets", "src", "refs.bib");
        insert_css=false
    )

    run_makedocs(
        joinpath(@__DIR__, "test_assets");
        sitename="Test",
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",],
        format=Documenter.HTML(edit_link="master", repolink=" ", prettyurls=false),
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success

        assets = joinpath(dir, "build", "assets", "documentercitations")
        @test !isfile(joinpath(assets, "citations.css"))
        @test isfile(joinpath(assets, "citations-hover.css"))
        @test isfile(joinpath(assets, "citations-hover.js"))
        @test isfile(joinpath(assets, "citations-data.js"))

        index_html = read(joinpath(dir, "build", "index.html"), String)
        @test !contains(
            index_html,
            "<link href=\"assets/documentercitations/citations.css\""
        )
        @test contains(index_html, HOVER_CSS_LINK)

    end

end


@testset "citations and bibliography on the same page" begin

    # The citation links then point to an anchor on the citing page itself,
    # which the script must still recognize as a bibliography entry

    bib = CitationBibliography(joinpath(@__DIR__, "test_show_hover", "src", "refs.bib"))

    run_makedocs(
        joinpath(@__DIR__, "test_show_hover");
        sitename="Test",
        plugins=[bib],
        pages=["Home" => "index.md",],
        format=Documenter.HTML(edit_link="master", repolink=" ", prettyurls=false),
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success

        index_html = strip_cite_ids(read(joinpath(dir, "build", "index.html"), String))
        @test contains(index_html, "<a href=\"index.html#GoerzQ2022\">")

        data_file =
            joinpath(dir, "build", "assets", "documentercitations", "citations-data.js")
        @test isfile(data_file)
        data = read(data_file, String)
        @test contains(data, "\"page\":\"index.html\"")
        @test contains(data, ENTRY_TEXT)

    end

end


@testset "no hover assets without HTML output" begin

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
        @test isempty(bib.hover_entries)

    end

end
