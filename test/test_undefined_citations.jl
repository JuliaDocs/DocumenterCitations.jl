using DocumenterCitations
using Test

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
        pages=["Home" => "index.md", "References" => "references.md",]
    ) do dir, result, success, backtrace, output

        @test success
        @test occursin("Error: Citation not found in bibliography: NoExist2023", output)

    end

    # strict
    run_makedocs(
        splitext(@__FILE__)[1];
        sitename="Test",
        warnonly=false,
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",]
    ) do dir, result, success, backtrace, output

        #if !success
        #   println("")
        #   @error "Failed makedocs:\n$output" dir
        #end
        #if result isa Exception
        #   @error "Raised $(typeof(result))\n" result
        #end

        @test !success
        @test occursin("Error: Citation not found in bibliography: NoExist2023", output)
        @test result isa ErrorException
        @test occursin(r"`makedocs` encountered errors [ [,]*:citations", result.msg)

    end

end
