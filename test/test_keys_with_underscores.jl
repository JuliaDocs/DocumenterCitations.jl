
using DocumenterCitations
using Test

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
        check_failure=true # XXX
    ) do dir, result, success, backtrace, output
        @test result isa ErrorException # XXX
        @test occursin("Invalid citation", result.msg)  # XXX
        @test_broken success
    end

end
