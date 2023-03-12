using QuantumCitations
using QuantumControlTestUtils: QuantumTestLogger
using Documenter
using Logging
using Test

CUSTOM1 = joinpath(@__DIR__, "..", "docs", "custom_styles", "enumauthoryear.jl")
CUSTOM2 = joinpath(@__DIR__, "..", "docs", "custom_styles", "keylabels.jl")

@testset "Integration Test" begin

    # we build the complete documentation of QuantumCitations in a test
    # environment

    eval(:(using QuantumCitations))
    eval(:(include(CUSTOM1)))
    eval(:(include(CUSTOM2)))

    bib = CitationBibliography(
        joinpath(@__DIR__, "..", "docs", "src", "refs.bib"),
        style=:numeric
    )
    mktempdir() do tmpdir
        root = joinpath(@__DIR__, "..", "docs")
        # We're basically doing `makedocs`, but written out for debuggability
        empty!(Documenter.Selectors.selector_subtypes)
        format = Documenter.Writers.HTMLWriter.HTML(; edit_link=nothing, disable_git=true)
        plugins = [bib]
        document = Documenter.Documents.Document(
            plugins;
            format,
            strict=false,
            sitename="QuantumCitations.jl",
            root,
            build=tmpdir
        )
        cd(document.user.root) do
            test_logger = QuantumTestLogger()
            with_logger(test_logger) do
                Documenter.Selectors.dispatch(Documenter.Builder.DocumentPipeline, document)
            end
        end
        html = read(joinpath(tmpdir, "references", "index.html"), String)
        ∈ₛ(needle, haystack) = occursin(needle, haystack)
        @test "Quantum Optimal Control" ∈ₛ html
    end
    @test bib.citations["GoerzQ2022"] == 2

end
