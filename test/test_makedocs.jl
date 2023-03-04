using QuantumCitations
using Documenter
using Test


@testset "Full documentation build" begin

    bib = CitationBibliography(
        joinpath(@__DIR__, "..", "docs", "example.bib"),
        sorting = :nyt
    )
    mktempdir() do tmpdir
        root = joinpath(@__DIR__, "..", "docs")
        # We're basically doing `makedocs`, but written out for debuggability
        empty!(Documenter.Selectors.selector_subtypes)
        format = Documenter.Writers.HTMLWriter.HTML()
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
            Documenter.Selectors.dispatch(
                Documenter.Builder.DocumentPipeline,
                document
            )
        end
        html = read(joinpath(tmpdir, "references", "index.html"), String)
        ∈ₛ(needle, haystack) = occursin(needle, haystack)
        @test "Optimizing Robust Quantum Gates in Open Quantum Systems" ∈ₛ html
    end

end
