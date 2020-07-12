using Documenter
using Bibliography

include("citations.jl")

const BIBLIOGRAPHY = import_bibtex("test.bib")

makedocs(
    sitename = "Testing BibTeX citations and references",
      format = Documenter.HTML(
          prettyurls = get(ENV, "CI", nothing) == "true"
      )
)

