using Documenter
using DocumenterCitations
import DocumenterCitations
using Bibliography

DocumenterCitations.BIBLIOGRAPHY() = import_bibtex(joinpath(@__DIR__, "test.bib"))

makedocs(
    sitename = "Testing BibTeX citations and references",
      format = Documenter.HTML(
          prettyurls = get(ENV, "CI", nothing) == "true"
      ),
       pages = [
           "Home"       => "index.md",
           "References" => "references.md"
       ]
)

