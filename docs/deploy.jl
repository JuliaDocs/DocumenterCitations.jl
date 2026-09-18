# Deploy the documentation built by `docs/make.jl` to the `gh-pages` branch.
#
# This runs in its own CI job, separately from the build, so that the code that
# runs while building the documentation never has access to a token with write
# permissions. Only Documenter is installed, in the version recorded in the
# manifest of the build (the shared workspace manifest at the repository root).

import Pkg

MANIFEST = Pkg.TOML.parsefile(joinpath(@__DIR__, "..", "Manifest.toml"))
DOCUMENTER_VERSION = VersionNumber(only(MANIFEST["deps"]["Documenter"])["version"])

Pkg.activate(; temp=true)
Pkg.add(Pkg.PackageSpec(name="Documenter", version=DOCUMENTER_VERSION))

using Documenter

deploydocs(;
    root=@__DIR__,
    target="build",
    repo="github.com/JuliaDocs/DocumenterCitations.jl.git",
    devbranch="master",
    push_preview=true,
)
