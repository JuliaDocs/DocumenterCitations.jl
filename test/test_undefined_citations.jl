using DocumenterCitations
using Test
using TestingUtilities: @Test  # much better at comparing strings

include("run_makedocs.jl")


@testset "undefined citations" begin

    bib = CitationBibliography(
        joinpath(@__DIR__, "..", "docs", "src", "refs.bib"),
        style=:numeric
    )

    # non-strict
    run_makedocs(
        splitext(@__FILE__)[1];
        sitename="Test",
        warnonly=true,
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",],
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success
        #! format: off
        @Test occursin("Error: Key \"NoExist2023\" not found in entries", output)
        @Test occursin("Error: Key \"Shapiro2012_\" not found in entries", output)
        @Test occursin("Error: Explicit key \"NoExistInBibliography2023\" from bibliography block not found in entries", output)
        @Test occursin("Error: expand_citation (rec): No destination for key=\"Tannor2007\" → unlinked text \"7\"", output)
        #! format: on
        index_html_file = joinpath(dir, "build", "index.html")
        @Test isfile(index_html_file)
        if isfile(index_html_file)
            #! format: off
            index_html = read(index_html_file, String)
            @Test occursin("and a non-existing key [?]", index_html)
            @Test occursin("[?, ?, ?, <a href=\"references/#BrumerShapiro2003\">2</a>–<a href=\"references/#KochEPJQT2022\">6</a>, and references therein]", index_html)
            @Test occursin("<a href=\"references/#BrumerShapiro2003\">Brumer and Shapiro [2]</a>, <a href=\"references/#BrifNJP2010\">Brif <em>et al.</em> [3]</a>, [?], [?], <a href=\"references/#SolaAAMOP2018\">Sola <em>et al.</em> [4]</a>, [?], <a href=\"references/#Wilhelm200310132\">Wilhelm <em>et al.</em> [5]</a>, <a href=\"references/#KochEPJQT2022\">Koch <em>et al.</em> [6]</a>, and references therein", index_html)
            @Test occursin("Lastly, we cite a key [7]", index_html)
            #! format: on
        end

    end

    # strict
    run_makedocs(
        splitext(@__FILE__)[1];
        sitename="Test",
        warnonly=false,
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",],
        check_failure=true
    ) do dir, result, success, backtrace, output

        #! format: off
        @test !success
        @Test occursin("Error: Key \"NoExist2023\" not found in entries", output)
        @Test occursin("Error: Key \"Shapiro2012_\" not found in entries", output)
        @Test occursin("Error: Explicit key \"NoExistInBibliography2023\" from bibliography block not found in entries", output)
        @Test occursin("Error: expand_citation (rec): No destination for key=\"Tannor2007\" → unlinked text \"7\"", output)
        @test result isa ErrorException
        @Test occursin("`makedocs` encountered errors [:citations, :bibliography_block]", result.msg)
        #! format: on

    end

end


@testset "undefined citations – :alpha" begin

    bib = CitationBibliography(
        joinpath(@__DIR__, "..", "docs", "src", "refs.bib"),
        style=:alpha
    )

    # non-strict
    run_makedocs(
        splitext(@__FILE__)[1];
        sitename="Test",
        warnonly=true,
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",],
        check_success=true,
    ) do dir, result, success, backtrace, output

        @test success
        index_html_file = joinpath(dir, "build", "index.html")
        @Test isfile(index_html_file)
        if isfile(index_html_file)
           #! format: off
           index_html = read(index_html_file, String)
           @Test occursin("and a non-existing key [?]", index_html)
           @Test occursin("[?], [?], <a href=\"references/#SolaAAMOP2018\">Sola <em>et al.</em> [SCMM18]</a>, [?], <a href=\"references/#Wilhelm200310132\">Wilhelm <em>et al.</em> [WKM+20]</a>, <a href=\"references/#KochEPJQT2022\">Koch <em>et al.</em> [KBC+22]</a>, and references therein", index_html)
           @Test occursin("<a href=\"references/#BrumerShapiro2003\">Brumer and Shapiro [BS03]</a>, <a href=\"references/#BrifNJP2010\">Brif <em>et al.</em> [BCR10]</a>, [?], [?], <a href=\"references/#SolaAAMOP2018\">Sola <em>et al.</em> [SCMM18]</a>, [?], <a href=\"references/#Wilhelm200310132\">Wilhelm <em>et al.</em> [WKM+20]</a>, <a href=\"references/#KochEPJQT2022\">Koch <em>et al.</em> [KBC+22]</a>, and references therein", index_html)
           #! format: on
        end

    end

end


@testset "undefined citations – :authoryear" begin

    bib = CitationBibliography(
        joinpath(@__DIR__, "..", "docs", "src", "refs.bib"),
        style=:authoryear
    )

    # non-strict
    run_makedocs(
        splitext(@__FILE__)[1];
        sitename="Test",
        warnonly=true,
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",],
        check_success=true,
    ) do dir, result, success, backtrace, output

        @test success
        index_html_file = joinpath(dir, "build", "index.html")
        @Test isfile(index_html_file)
        if isfile(index_html_file)
           #! format: off
           index_html = read(index_html_file, String)
           @Test occursin("and a non-existing key (???)", index_html)
           @Test occursin("(<a href=\"references/#BrumerShapiro2003\">Brumer and Shapiro, 2003</a>; <a href=\"references/#BrifNJP2010\">Brif <em>et al.</em>, 2010</a>; ???; ???; <a href=\"references/#SolaAAMOP2018\">Sola <em>et al.</em>, 2018</a>; ???; <a href=\"references/#Wilhelm200310132\">Wilhelm <em>et al.</em>, 2020</a>; <a href=\"references/#KochEPJQT2022\">Koch <em>et al.</em>, 2022</a>; and references therein)", index_html)
           @Test occursin("<a href=\"references/#BrumerShapiro2003\">Brumer and Shapiro (2003)</a>, <a href=\"references/#BrifNJP2010\">Brif <em>et al.</em> (2010)</a>, ???, ???, <a href=\"references/#SolaAAMOP2018\">Sola <em>et al.</em> (2018)</a>, ???, <a href=\"references/#Wilhelm200310132\">Wilhelm <em>et al.</em> (2020)</a>, <a href=\"references/#KochEPJQT2022\">Koch <em>et al.</em> (2022)</a>, and references therein", index_html)
           @Test occursin("Lastly, we cite a key (Tannor, 2007)", index_html)
           #! format: on
        end

    end

end
