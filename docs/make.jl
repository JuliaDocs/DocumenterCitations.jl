using Documenter
using DocumenterCitations

const root_dir = dirname(dirname(pathof(DocumenterCitations)))
const doc_dir = joinpath(root_dir, "docs")

cite_bib = CitationBibliography(joinpath(doc_dir, "test.bib"))

makedocs(
    cite_bib,
    sitename = "Testing BibTeX citations and references",
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

