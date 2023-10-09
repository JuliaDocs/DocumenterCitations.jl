using DocumenterCitations
using Test

include("run_makedocs.jl")


@testset "Collect from docstrings" begin

    # https://github.com/JuliaDocs/DocumenterCitations.jl/issues/39

    bib = CitationBibliography(
        joinpath(@__DIR__, "..", "docs", "src", "refs.bib"),
        style=:numeric
    )
    run_makedocs(
        splitext(@__FILE__)[1];
        sitename="Test",
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",],
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success

        index_outfile = joinpath(dir, "build", "index.html")
        @test isfile(index_outfile)
        html = read(index_outfile, String)
        @test occursin("citing Ref. [<a href=\"references/#GoerzQ2022\">1</a>]", html)

        ref_outfile = joinpath(dir, "build", "references", "index.html")
        @test isfile(ref_outfile)
        html = read(ref_outfile, String)
        @test occursin("<dt>[1]</dt>", html)
        @test occursin("<div id=\"GoerzQ2022\">", html)

    end

end
