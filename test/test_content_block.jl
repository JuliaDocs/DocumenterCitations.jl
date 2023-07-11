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
        pages=["Home" => "index.md", "References" => "references.md",]
    ) do dir, result, success, backtrace, output
        #if !success
        #    println("")
        #    @error "Failed makedocs:\n$output" dir  # XXX
        #end
        #if result isa Exception
        #    @error "Raised $(typeof(result))\n" result  # XXX
        #end
        @test result == ErrorException("type Entry has no field level")  # XXX
        @test_broken success
    end

end
