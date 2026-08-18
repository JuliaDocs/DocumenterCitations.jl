using DocumenterCitations
using Test

# How a relative `bibfile` is resolved
#
# The path is resolved when `CitationBibliography` is instantiated, which
# happens before `makedocs` runs. A relative path is resolved relative to the
# folder containing the `make.jl` file that instantiates the plugin. There is
# an undocumented fallback to the current working directory, which warns.

# The fixture folder plays the role of a `docs` folder. The `make.jl` file in it
# is never read; only its directory matters for the path resolution.
const FIXTURE = joinpath(@__DIR__, "test_bibfile_path")
const FAKE_MAKE_JL = joinpath(FIXTURE, "make.jl")

const OTHER_BIB = """
@book{BrumerShapiro2003,
    Author = {Brumer, P. and Shapiro, M.},
    Publisher = {Wiley Interscience},
    Title = {Principles and Applications of the Quantum Control of Molecular Processes},
    Year = {2003},
}
"""


# Emulate running a `make.jl` in the fixture folder from the working directory
# `cwd`. Julia sets the task-local `SOURCE_PATH` from which `Base.source_dir()`
# derives the folder of the running script; setting it directly avoids having
# to spawn an actual build.
function with_fake_make_jl(f, cwd)
    return task_local_storage(:SOURCE_PATH, FAKE_MAKE_JL) do
        cd(f, cwd)
    end
end


@testset "bibfile relative to the make.jl folder" begin
    with_fake_make_jl(mktempdir()) do
        bib = CitationBibliography(joinpath("src", "refs.bib"))
        @test collect(keys(bib.entries)) == ["Tannor2007"]
    end
end


@testset "undocumented fallback to the working directory" begin
    # No `src/refs.bib` exists relative to this test file, which is the
    # "running script" here, so the fallback applies.
    cd(FIXTURE) do
        bibfile = joinpath("src", "refs.bib")
        bib =
            @test_logs (:warn, r"relative to the current working directory") CitationBibliography(
                bibfile
            )
        @test collect(keys(bib.entries)) == ["Tannor2007"]
    end
end


# A unix-style path is a valid relative path on Windows, too: the Win32 API
# accepts `/` as a separator, and `normpath` cleans up the mixed separators
# that `joinpath` produces for it.
@testset "bibfile with a unix path separator" begin
    with_fake_make_jl(mktempdir()) do
        bib = CitationBibliography("src/refs.bib")
        @test collect(keys(bib.entries)) == ["Tannor2007"]
    end
end


@testset "absolute bibfile" begin
    with_fake_make_jl(mktempdir()) do
        bib = CitationBibliography(joinpath(FIXTURE, "src", "refs.bib"))
        @test collect(keys(bib.entries)) == ["Tannor2007"]
    end
end


@testset "the make.jl folder takes precedence" begin
    with_fake_make_jl(mktempdir()) do
        mkdir("src")
        write(joinpath("src", "refs.bib"), OTHER_BIB)
        bib = CitationBibliography(joinpath("src", "refs.bib"))
        @test collect(keys(bib.entries)) == ["Tannor2007"]
    end
end


@testset "relative bibfile that does not exist" begin
    with_fake_make_jl(mktempdir()) do
        exc = @test_throws ErrorException CitationBibliography("src/nonexistent.bib")
        msg = exc.value.msg
        @test contains(msg, "bibfile \"src/nonexistent.bib\" does not exist")
        @test contains(msg, FIXTURE)
        @test contains(msg, "joinpath(@__DIR__, \"src/nonexistent.bib\")")
    end
end


@testset "absolute bibfile that does not exist" begin
    bibfile = joinpath(FIXTURE, "src", "nonexistent.bib")
    exc = @test_throws ErrorException CitationBibliography(bibfile)
    @test exc.value.msg == "bibfile $(repr(bibfile)) does not exist"
end
