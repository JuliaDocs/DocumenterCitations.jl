.PHONY: help devrepl test coverage htmlcoverage docs pdf servedocs codestyle clean distclean
.DEFAULT_GOAL := help

JULIA ?= julia
PORT ?= 8000

define PRINT_HELP_JLSCRIPT
rx = r"^([a-z0-9A-Z_-]+):.*?##[ ]+(.*)$$"
for line in eachline()
    m = match(rx, line)
    if !isnothing(m)
        target, help = m.captures
        println("$$(rpad(target, 20)) $$help")
    end
end
endef
export PRINT_HELP_JLSCRIPT

define DEVREPL_INIT_JLSCRIPT
@assert VERSION >= v"1.12" "The development REPL requires Julia >= 1.12 (Pkg workspace support)"
# The `docs` project goes after the active `test` project but before the
# shared `@v#.#` environment, so that docs-only dependencies always load at
# the versions pinned in the workspace manifest.
insert!(LOAD_PATH, 2, abspath("docs"))
ENV["DOCUMENTER_CHECK_LINKS"] = "0"
using Revise
println("""
**Development REPL for DocumenterCitations.jl** (Revise active)

* `include("test/runtests.jl")` – Run the test suite
* `include("docs/make.jl")` – Build the documentation (link checking disabled)
""")
endef
export DEVREPL_INIT_JLSCRIPT


help:  ## show this help
	@git config --local blame.ignoreRevsFile .git-blame-ignore-revs
	@julia -e "$$PRINT_HELP_JLSCRIPT" < $(MAKEFILE_LIST)

devrepl: Manifest.toml ## Start an interactive REPL for testing and building documentation (requires Julia >= 1.12)
	$(JULIA) --project=test -e "$$DEVREPL_INIT_JLSCRIPT" -i

test: test/Manifest.toml ## Run the test suite
	$(JULIA) --project=test --banner=no --startup-file=yes --check-bounds=yes --depwarn=yes -e 'include("test/runtests.jl")'

coverage: test/Manifest.toml ## Run the test suite with coverage
	$(JULIA) --project=test -e 'using LocalCoverage; report = generate_coverage("DocumenterCitations"; run_test = true); show(report)'

htmlcoverage: test/Manifest.toml ## Run the test suite with coverage and generate an HTML report in ./coverage
	$(JULIA) --project=test -e 'using LocalCoverage; html_coverage("DocumenterCitations"; dir = "coverage")'

docs: docs/Manifest.toml ## Build the documentation
	$(JULIA) --project=docs docs/make.jl

pdf: docs/Manifest.toml ## Build the documentation in PDF format
	$(JULIA) --project=docs docs/makepdf.jl

servedocs: docs/Manifest.toml  ## Build (auto-rebuild) and serve documentation at PORT=8000
	$(JULIA) --project=docs -e 'ENV["DOCUMENTER_CHECK_LINKS"] = "0"; using LiveServer; servedocs(port=$(PORT), verbose=true)'

clean: ## Clean up build/doc/testing artifacts
	rm -f *.jl.*.cov src/*.jl.*.cov test/*.jl.*.cov
	rm -f *.jl.cov src/*.jl.cov test/*.jl.cov
	rm -f *.jl.mem src/*.jl.mem test/*.jl.mem
	rm -f lcov.info
	rm -rf coverage
	rm -rf docs/build
	make -C docs/latex clean

codestyle: test/Manifest.toml ## Apply the codestyle to the entire project
	$(JULIA) --project=test -e 'using JuliaFormatter; format(["src", "docs", "test"], verbose=true)'

distclean: clean ## Restore to a clean checkout state
	rm -f Manifest.toml
	rm -f test/Manifest.toml
	rm -f docs/Manifest.toml

test/Manifest.toml: test/Project.toml
	@git config --local blame.ignoreRevsFile .git-blame-ignore-revs
	$(JULIA) --project=test -e 'using Pkg; Pkg.resolve(); Pkg.instantiate()'
	@touch $@  # mark as instantiated (empty file) on Julia >= 1.12 

docs/Manifest.toml: docs/Project.toml
	@git config --local blame.ignoreRevsFile .git-blame-ignore-revs
	$(JULIA) --project=docs -e 'using Pkg; Pkg.resolve(); Pkg.instantiate()'
	@touch $@  # mark as instantiated (empty file) on Julia >= 1.12

# The shared workspace manifest (Julia >= 1.12 only), used by `make devrepl`.
Manifest.toml: Project.toml test/Project.toml docs/Project.toml
	@git config --local blame.ignoreRevsFile .git-blame-ignore-revs
	$(JULIA) --project=. -e 'using Pkg; Pkg.resolve(); Pkg.instantiate()'
