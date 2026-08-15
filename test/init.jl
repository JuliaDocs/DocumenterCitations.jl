# init file for "make devrepl"
using Revise
using JuliaFormatter
using Documenter: doctest
using LiveServer: LiveServer, serve, servedocs
using LocalCoverage: LocalCoverage, process_coverage, html_coverage
include(joinpath(@__DIR__, "clean.jl"))


"""Run a package test-suite in a subprocess.

```julia
test(
    file="test/runtests.jl";
    root=pwd(),
    project="test",
    coverage=false,
    genhtml=false,
    covdir="coverage",
    color=<inherit>,
    compiled_modules=<inherit>,
    startup_file=<inherit>,
    depwarn=<inherit>,
    inline=<inherit>,
    check_bounds="yes",
    track_allocation=<inherit>,
    threads=<inherit>
)
```

runs the test suite of the package located at `root` by running `include(file)`
inside a new julia process.

This is similar to what `Pkg.test()` does, but differs in the "sandboxing"
approach. While `Pkg.test()` creates a new temporary sandboxed environment,
`test()` uses an existing environment in `project` (the `test` subfolder by
default). This allows testing against the dev-versions of other packages. It
requires that the `test` folder contains both a `Project.toml` and a
`Manifest.toml` file.

With `coverage=true`, the subprocess tracks coverage (which is only possible
when running the tests in a subprocess) and a per-file summary is printed
afterwards. The raw coverage data is collected into `coverage/lcov.info`. With
`genhtml=true`, a full HTML coverage report is written to `covdir` as well.
This requires the `genhtml` executable, which is part of the
[lcov](https://github.com/linux-test-project/lcov) package.

All other keyword arguments correspond to the respective command line flag for
the `julia` executable that is run as the subprocess.

This function is intended to be exposed in a project's development-REPL.
"""
function test(
    file="test/runtests.jl";
    root=pwd(),
    project="test",
    coverage=false,
    genhtml=false,
    covdir="coverage",
    color=(Base.have_color === nothing ? "auto" : Base.have_color ? "yes" : "no"),
    compiled_modules=(Bool(Base.JLOptions().use_compiled_modules) ? "yes" : "no"),
    startup_file=(Base.JLOptions().startupfile == 1 ? "yes" : "no"),
    depwarn=(Base.JLOptions().depwarn == 2 ? "error" : "yes"),
    inline=(Bool(Base.JLOptions().can_inline) ? "yes" : "no"),
    track_allocation=(("none", "user", "all")[Base.JLOptions().malloc_log+1]),
    check_bounds="yes",
    threads=Threads.nthreads()
)
    with_coverage = coverage || genhtml
    julia = Base.julia_cmd().exec[1]
    cmd = [
        julia,
        "--project=$project",
        "--color=$color",
        "--compiled-modules=$compiled_modules",
        "--startup-file=$startup_file",
        # `@` restricts tracking to the code of the package under development,
        # writing `.cov` files next to the sources in `src`.
        "--code-coverage=$(with_coverage ? "@" : "none")",
        "--track-allocation=$track_allocation",
        "--depwarn=$depwarn",
        "--check-bounds=$check_bounds",
        "--threads=$threads",
        "--inline=$inline",
        "--eval",
        "include(\"$file\")"
    ]
    @info "Running '$(join(cmd, " "))' in subprocess"
    run(Cmd(Cmd(cmd), dir=root))
    if with_coverage
        # `process_coverage` consumes the `.cov` files, writes
        # `coverage/lcov.info`, and returns the summarized metrics.
        report = process_coverage("DocumenterCitations")
        show(report)
        println()
        genhtml && html_coverage(report; dir=covdir)
    end
    return nothing
end


REPL_MESSAGE = """
*******************************************************************************
DEVELOPMENT REPL

Revise, JuliaFormatter, LiveServer are loaded.

* `help()` – Show this message
* `include("test/runtests.jl")` – Run the entire test suite
* `test()` – Run the entire test suite in a subprocess
* `test(coverage=true)` – … and print a coverage summary
* `test(genhtml=true)` – … and write an HTML coverage report to ./coverage
* `import DocumenterCitations; doctest(DocumenterCitations)` –
  Run doctests for docstrings in package
* `include("docs/make.jl")` – Generate the documentation
* `format(".")` – Apply code formatting to all files
* `servedocs([port=8000, verbose=false])` –
  Build and serve the documentation. Automatically recompile and redisplay on
  changes
* `clean()` – Clean up build/doc/testing artifacts
* `distclean()` – Restore to a clean checkout state
*******************************************************************************
"""

"""Show help"""
help() = println(REPL_MESSAGE)
