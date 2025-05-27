using DocumenterCitations
using DocumenterInterLinks
using Documenter
using Pkg


# Note: Set environment variable `DOCUMENTER_LATEX_DEBUG=1` in order get a copy
# of the generated tex file (or, add `platform="none"` to the
# `Documenter.LaTeX` call)


PROJECT_TOML = Pkg.TOML.parsefile(joinpath(@__DIR__, "..", "Project.toml"))
VERSION = PROJECT_TOML["version"]
NAME = PROJECT_TOML["name"]
AUTHORS = join(PROJECT_TOML["authors"], ", ") * " and contributors"
GITHUB = "https://github.com/JuliaDocs/DocumenterCitations.jl"

bib = CitationBibliography(
    joinpath(@__DIR__, "src", "refs.bib");
    style=:numeric  # default
)

links = InterLinks(
    "Documenter" => "https://documenter.juliadocs.org/stable/",
    "Bijections" => "https://docs.juliahub.com/General/Bijections/stable/",
)

println("Starting makedocs")

include("custom_styles/enumauthoryear.jl")
include("custom_styles/keylabels.jl")

withenv("DOCUMENTER_BUILD_PDF" => "1") do
    makedocs(
        authors=AUTHORS,
        linkcheck=true,
        warnonly=[:linkcheck,],
        sitename="DocumenterCitations.jl",
        format=Documenter.LaTeX(; version=VERSION),
        pages=[
            "Home"                   => "index.md",
            "Syntax"                 => "syntax.md",
            "Citation Style Gallery" => "gallery.md",
            "CSS Styling"            => "styling.md",
            "Internals"              => "internals.md",
            "References"             => "references.md",
        ],
        plugins=[bib, links],
    )
end

println("Finished makedocs")
