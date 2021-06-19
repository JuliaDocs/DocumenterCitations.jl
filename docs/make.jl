using Documenter
using DocumenterCitations

bib = CitationBibliography(joinpath(@__DIR__, "example.bib"), sorting = :nyt)

makedocs(
    bib,
    sitename = "DocumenterCitations.jl",
    strict = true,
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    pages = [
        "Home"       => "index.md",
        "References" => "references.md"
    ]
)

deploydocs(
    repo = "github.com/ali-ramadhan/DocumenterCitations.jl.git",
    push_preview = true
)

