using QuantumCitations
using Documenter
using Pkg

PROJECT_TOML = Pkg.TOML.parsefile(joinpath(@__DIR__, "..", "Project.toml"))
VERSION = PROJECT_TOML["version"]
NAME = PROJECT_TOML["name"]
AUTHORS = join(PROJECT_TOML["authors"], ", ") * " and contributors"
GITHUB = "https://github.com/JuliaQuantumControl/QuantumCitations.jl"

bib = CitationBibliography(joinpath(@__DIR__, "example.bib"), sorting = :nyt)

println("Starting makedocs")

makedocs(
    bib,
    sitename = "QuantumCitations.jl",
    strict = true,
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical="https://juliaquantumcontrol.github.io/QuantumCitations.jl",
        assets=String[],
        footer="[$NAME.jl]($GITHUB) v$VERSION docs powered by [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl)."
    ),
    pages = [
        "Home"       => "index.md",
        "References" => "references.md"
    ]
)

println("Finished makedocs")

deploydocs(; repo = "github.com/JuliaQuantumControl/QuantumCitations.jl.git")
