using DocumenterCitations
using DocumenterCodeBlocks
using DocumenterInterLinks
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

# Syntax highlighting, line numbers, and docstring reference links for the Julia
# code blocks. `min_lines=3` keeps the gutter off the many one- and two-line
# configuration snippets.
codeblocks = CodeBlocks(; min_lines=3)

# Tweak the built-in CSS for codeblocks: no underline at all until
# hover, and then only a lightly dotted underline
codeblocks_css = "assets/codeblocks.css"


links = InterLinks(
    "Documenter" => "https://documenter.juliadocs.org/stable/",
    "Bijections" => "https://docs.juliahub.com/General/Bijections/stable/",
    "Bibliography" => "https://juliabibliographies.github.io/Bibliography.jl/stable/",
)

println("Starting makedocs")

include("custom_styles/enumauthoryear.jl")
include("custom_styles/keylabels.jl")

makedocs(
    authors=AUTHORS,
    linkcheck=(get(ENV, "DOCUMENTER_CHECK_LINKS", "1") != "0"),
    # Link checking is disabled for `make servedocs`, see the `Makefile`.
    warnonly=[:linkcheck,],
    sitename="DocumenterCitations.jl",
    format=Documenter.HTML(
        prettyurls=true,
        canonical="https://juliadocs.org/DocumenterCitations.jl",
        assets=String[codeblocks_css],
        footer="[$NAME.jl]($GITHUB) v$VERSION docs powered by [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl).",
    ),
    pages=[
        "Home"                   => "index.md",
        "Syntax"                 => "syntax.md",
        "Citation Style Gallery" => "gallery.md",
        "CSS Styling"            => "styling.md",
        "Internals"              => "internals.md",
        "References"             => "references.md",
    ],
    plugins=[bib, links, codeblocks],
)

println("Finished makedocs")

deploydocs(; repo="github.com/JuliaDocs/DocumenterCitations.jl.git", push_preview=true)
