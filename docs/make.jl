using DocumenterCitations
using Documenter
using Pkg

PROJECT_TOML = Pkg.TOML.parsefile(joinpath(@__DIR__, "..", "Project.toml"))
VERSION = PROJECT_TOML["version"]
NAME = PROJECT_TOML["name"]
AUTHORS = join(PROJECT_TOML["authors"], ", ") * " and contributors"
GITHUB = "https://github.com/JuliaDocs/DocumenterCitations.jl"

bib = CitationBibliography(
    joinpath(@__DIR__, "src", "refs.bib");
    style=:numeric  # default
)

println("Starting makedocs")

include(joinpath("custom_styles", "enumauthoryear.jl"))
include(joinpath("custom_styles", "keylabels.jl"))

makedocs(
    bib,
    authors=AUTHORS,
    sitename="DocumenterCitations.jl",
    strict=true,
    format=Documenter.HTML(
        prettyurls=true,
        canonical="https://juliadocs.github.io/DocumenterCitations.jl",
        assets=String["assets/citations.css"],
        footer="[$NAME.jl]($GITHUB) v$VERSION docs powered by [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl)."
    ),
    pages=[
        "Home"                   => "index.md",
        "Syntax"                 => "syntax.md",
        "Citation Style Gallery" => "gallery.md",
        "CSS Styling"            => "styling.md",
        "Internals"              => "internals.md",
        "References"             => "references.md",
    ]
)

println("Finished makedocs")

deploydocs(; repo="github.com/JuliaDocs/DocumenterCitations.jl.git")
