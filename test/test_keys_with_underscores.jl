
using DocumenterCitations
using Test

include("run_makedocs.jl")


@testset "@Contents Block Test" begin

    # https://github.com/JuliaDocs/DocumenterCitations.jl/issues/14

    bib = CitationBibliography(
        joinpath(@__DIR__, "test_keys_with_underscores", "src", "refs.bib"),
        style=:numeric
    )
    run_makedocs(
        joinpath(@__DIR__, "test_keys_with_underscores");
        sitename="Test",
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",]
    ) do dir, result, success, backtrace, output
        #if !success
        #    println("")
        #    @error "Failed makedocs:\n$output" dir  # XXX
        #end
        #if result isa Exception
        #    @error "Raised $(typeof(result))\n" result  # XXX
        #end
        @test result isa ErrorException # XXX
        @test occursin("Invalid citation", result.msg)  # XXX
        @test_broken success
    end

end
