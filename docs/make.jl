using Documenter
using Bibliography

const BIBLIOGRAPHY = import_bibtex("test.bib")

include("bibliography.jl")
include("citations.jl")

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

