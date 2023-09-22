using DocumenterCitations
using Test

include("run_makedocs.jl")


@testset "@Contents Block Test" begin

    # https://github.com/JuliaDocs/DocumenterCitations.jl/issues/16
    # https://github.com/ali-ramadhan/DocumenterCitations.jl/issues/33
    # https://github.com/ali-ramadhan/DocumenterCitations.jl/issues/24

    bib = CitationBibliography(
        joinpath(@__DIR__, "test_content_block", "src", "refs.bib"),
        style=:numeric
    )
    run_makedocs(
        joinpath(@__DIR__, "test_content_block");
        sitename="Test",
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",],
        check_success=true
    ) do dir, result, success, backtrace, output
        @test success
    end

end
