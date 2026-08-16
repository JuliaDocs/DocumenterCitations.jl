using DocumenterCitations
using Documenter
using Test

include("run_makedocs.jl")


const BIBFILE = joinpath(@__DIR__, "..", "docs", "src", "refs.bib")

const PAGES =
    ["Home" => "index.md", "Usage" => "usage.md", "References" => "references.md",]

const BACKLINKS_JS = "citations-backlinks.js"

# The tag that `Documenter` renders for the bundled script (relative to the
# page, which is why the tests using it build with `prettyurls=false`)
const BACKLINKS_JS_TAG = "<script src=\"assets/documentercitations/$BACKLINKS_JS\"></script>"


@testset "backlinks (default)" begin

    bib = CitationBibliography(BIBFILE)
    @test bib.show_backlinks  # on by default

    run_makedocs(
        splitext(@__FILE__)[1];
        sitename="Test",
        plugins=[bib],
        pages=PAGES,
        format=Documenter.HTML(edit_link="master", repolink=" ", prettyurls=false),
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success

        # The citations are numbered in the order in which they appear in the
        # documentation, across pages. The `Example` docstring cites
        # `GoerzQ2022` twice, and citations in a docstring are attributed to
        # the docstring, not to any section inside it
        @test [site.id for site in bib.backlinks["GoerzQ2022"]] == [
            "GoerzQ2022-cite-1",
            "GoerzQ2022-cite-2",
            "GoerzQ2022-cite-3",
            "GoerzQ2022-cite-4",
        ]
        @test [site.section for site in bib.backlinks["GoerzQ2022"]] == [
            "Introduction",
            "Details",
            "DocumenterCitations.Example",
            "DocumenterCitations.Example",
        ]
        @test [site.src for site in bib.backlinks["BrifNJP2010"]] == ["index.md", "usage.md"]
        @test [site.section for site in bib.backlinks["BrifNJP2010"]] == ["Details", "Examples"]

        index_html = read(joinpath(dir, "build", "index.html"), String)
        # Every citation link carries the anchor that the backlinks point to
        @test contains(index_html, "id=\"GoerzQ2022-cite-1\"")
        @test contains(index_html, "id=\"GoerzQ2022-cite-2\"")
        @test contains(index_html, "id=\"BrifNJP2010-cite-1\"")
        # … including the citations inside docstrings
        @test contains(index_html, "id=\"GoerzQ2022-cite-3\"")
        @test !contains(index_html, "citation-backlinks")

        references_html = read(joinpath(dir, "build", "references.html"), String)
        @test contains(references_html, "<span class=\"citation-backlinks\">")
        @test contains(
            references_html,
            "<a href=\"index.html#GoerzQ2022-cite-1\" title=\"Cited in Introduction\">↩<sup>1</sup></a>"
        )
        @test contains(
            references_html,
            "<a href=\"usage.html#BrifNJP2010-cite-2\" title=\"Cited in Examples\">↩<sup>2</sup></a>"
        )
        # A non-canonical block does not get backlinks
        @test count("citation-backlinks", references_html) == 2

        # The script that marks the backlink for the citation that the reader
        # followed is inserted automatically
        @test isfile(joinpath(dir, "build", "assets", "documentercitations", BACKLINKS_JS))
        @test contains(index_html, BACKLINKS_JS_TAG)

    end

end


@testset "backlinks with prettyurls" begin

    bib = CitationBibliography(BIBFILE)

    run_makedocs(
        splitext(@__FILE__)[1];
        sitename="Test",
        plugins=[bib],
        pages=PAGES,
        format=Documenter.HTML(edit_link="master", repolink=" "),
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success

        references_html = read(joinpath(dir, "build", "references", "index.html"), String)
        @test contains(references_html, "<a href=\"../#GoerzQ2022-cite-1\"")
        @test contains(references_html, "<a href=\"../usage/#BrifNJP2010-cite-2\"")

    end

end


@testset "show_backlinks=false" begin

    bib = CitationBibliography(BIBFILE; show_backlinks=false)

    run_makedocs(
        splitext(@__FILE__)[1];
        sitename="Test",
        plugins=[bib],
        pages=PAGES,
        format=Documenter.HTML(edit_link="master", repolink=" ", prettyurls=false),
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success

        @test isempty(bib.backlinks)

        index_html = read(joinpath(dir, "build", "index.html"), String)
        @test !contains(index_html, "-cite-1")

        references_html = read(joinpath(dir, "build", "references.html"), String)
        @test !contains(references_html, "citation-backlinks")

        @test !isfile(joinpath(dir, "build", "assets", "documentercitations", BACKLINKS_JS))
        @test !contains(index_html, BACKLINKS_JS_TAG)

    end

end


@testset "backlinks are not part of the hover data" begin

    bib = CitationBibliography(BIBFILE)

    run_makedocs(
        splitext(@__FILE__)[1];
        sitename="Test",
        plugins=[bib],
        pages=PAGES,
        format=Documenter.HTML(edit_link="master", repolink=" ", prettyurls=false),
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success

        data_file =
            joinpath(dir, "build", "assets", "documentercitations", "citations-data.js")
        @test isfile(data_file)
        @test !contains(read(data_file, String), "citation-backlinks")

    end

end


@testset "backlinks do not affect the LaTeX output" begin

    tex_files = Dict{String,String}()

    for show_backlinks in (true, false)
        bib = CitationBibliography(BIBFILE; show_backlinks=show_backlinks)
        run_makedocs(
            splitext(@__FILE__)[1];
            sitename="Test",
            plugins=[bib],
            pages=PAGES,
            format=Documenter.LaTeX(platform="none"),
            check_success=true
        ) do dir, result, success, backtrace, output
            @test success
            tex_file = joinpath(dir, "build", "Test.tex")
            @test isfile(tex_file)
            tex_files["$show_backlinks"] = read(tex_file, String)
            @test !isdir(joinpath(dir, "build", "assets", "documentercitations"))
        end
    end

    @test tex_files["true"] == tex_files["false"]
    @test !contains(tex_files["true"], "cite-1")

end
