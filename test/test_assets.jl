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
        env=Dict("JULIA_DEBUG" => ""),
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
        # A modified stylesheet is a deliberate customization: no warning
        @test !contains(output, "unmodified copy")

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


@testset "insert_css=false" begin

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
        @test !isdir(joinpath(dir, "build", "assets", "documentercitations"))

        index_html = read(joinpath(dir, "build", "index.html"), String)
        @test !contains(index_html, CSS_LINK)

    end

end


@testset "insert_css=false with custom assets" begin

    bib = CitationBibliography(
        joinpath(@__DIR__, "test_assets", "src", "refs.bib");
        insert_css=false
    )

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
        env=Dict("JULIA_DEBUG" => ""),
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success
        @test !isdir(joinpath(dir, "build", "assets", "documentercitations"))

        index_html = read(joinpath(dir, "build", "index.html"), String)
        custom_link = "<link href=\"assets/citations.css\" rel=\"stylesheet\" type=\"text/css\"/>"
        @test !contains(index_html, CSS_LINK)
        @Test contains(index_html, custom_link)
        # With the automatic insertion disabled, the user's stylesheet is the
        # intended one, not a leftover, even if it is an unmodified copy
        @test !contains(output, "unmodified copy")

    end

end


@testset "warning for unmodified copy of the bundled stylesheet" begin

    # We deliberately do not keep a verbatim copy of the bundled stylesheet in
    # the test fixtures (it is exactly the redundancy being warned about, and
    # any edit to it would invalidate the test). Instead, we set up a project
    # that mimics the pre-1.5 recommendation on the fly.
    mktempdir() do root

        cp(joinpath(@__DIR__, "test_assets"), root; force=true)
        cp(
            joinpath(DocumenterCitations.ASSETS_FOLDER, "citations.css"),
            joinpath(root, "src", "assets", "citations.css");
            force=true
        )

        bib = CitationBibliography(joinpath(root, "src", "refs.bib"))

        run_makedocs(
            root;
            sitename="Test",
            plugins=[bib],
            pages=["Home" => "index.md", "References" => "references.md",],
            format=Documenter.HTML(
                edit_link="master",
                repolink=" ",
                prettyurls=false,
                assets=String["assets/citations.css"],
            ),
            env=Dict("JULIA_DEBUG" => ""),
            check_success=true
        ) do dir, result, success, backtrace, output

            @test success
            @test contains(
                output,
                "which is an unmodified copy of the `citations.css` bundled with DocumenterCitations"
            )

            # The warning does not change the build in any way
            index_html = read(joinpath(dir, "build", "index.html"), String)
            custom_link = "<link href=\"assets/citations.css\" rel=\"stylesheet\" type=\"text/css\"/>"
            @Test contains(index_html, CSS_LINK)
            @Test contains(index_html, custom_link)

        end

    end

end


@testset "no warning about the automatically inserted stylesheet" begin

    # Reusing the same `Documenter.HTML` object for a second build means that
    # our own asset is already registered in `format.assets` when
    # `InjectAssets` runs. It must neither be duplicated nor be mistaken for an
    # unmodified copy in the user's `assets` folder.
    format = Documenter.HTML(edit_link="master", repolink=" ", prettyurls=false)

    for _ = 1:2

        bib = CitationBibliography(joinpath(@__DIR__, "test_assets", "src", "refs.bib"))

        run_makedocs(
            joinpath(@__DIR__, "test_assets");
            sitename="Test",
            plugins=[bib],
            pages=["Home" => "index.md", "References" => "references.md",],
            format=format,
            env=Dict("JULIA_DEBUG" => ""),
            check_success=true
        ) do dir, result, success, backtrace, output

            @test success
            @test !contains(output, "unmodified copy")

            index_html = read(joinpath(dir, "build", "index.html"), String)
            @Test contains(index_html, CSS_LINK)
            # … exactly once, even in the second run
            @test length(findall(CSS_LINK, index_html)) == 1

        end

    end

end


@testset "known CSS hashes" begin

    # The first entry of `KNOWN_CSS_HASHES` must be the hash of the current
    # `assets/citations.css`. If this test fails, `citations.css` was modified:
    # PREPEND the new hash to `KNOWN_CSS_HASHES` in `src/assets.jl`, keeping
    # the existing entries, so that copies of the previous version are still
    # recognized in a user's `docs/src/assets` folder.
    css = read(joinpath(DocumenterCitations.ASSETS_FOLDER, "citations.css"), String)
    @Test DocumenterCitations._css_hash(css) == DocumenterCitations.KNOWN_CSS_HASHES[1]

    # Normalization: line endings and trailing whitespace are irrelevant. Note
    # that `css` itself may have been checked out with either LF or CRLF line
    # endings, so the variants must be derived from an explicit LF baseline.
    css_lf = replace(css, "\r\n" => "\n")
    @Test DocumenterCitations._css_hash(css_lf) == DocumenterCitations._css_hash(css)
    @Test DocumenterCitations._css_hash(replace(css_lf, "\n" => "\r\n")) ==
          DocumenterCitations._css_hash(css)
    @Test DocumenterCitations._css_hash(replace(css_lf, "\n" => "\r")) ==
          DocumenterCitations._css_hash(css)
    @Test DocumenterCitations._css_hash(css * "\n\n") == DocumenterCitations._css_hash(css)

end
