using DocumenterCitations
const root_dir = dirname(dirname(pathof(DocumenterCitations)))
const doc_dir = joinpath(root_dir, "docs")
import DocumenterCitations

using Documenter
using Bibliography

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

