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


help:  ## show this help
	@git config --local blame.ignoreRevsFile .git-blame-ignore-revs
	@julia -e "$$PRINT_HELP_JLSCRIPT" < $(MAKEFILE_LIST)


test: test/Manifest.toml ## Run the test suite
	$(JULIA) --project=test --banner=no --startup-file=yes -e 'include("devrepl.jl"); test()'
	@echo "Done. Consider using 'make devrepl'"

coverage: test/Manifest.toml ## Run the test suite with coverage and show a summary
	$(JULIA) --project=test --banner=no --startup-file=yes -e 'include("devrepl.jl"); test(coverage=true)'

htmlcoverage: test/Manifest.toml ## Run the test suite with coverage and write an HTML report to ./coverage
	$(JULIA) --project=test --banner=no --startup-file=yes -e 'include("devrepl.jl"); test(genhtml=true)'


devrepl:  ## Start an interactive REPL for testing and building documentation
	$(JULIA) --project=test --banner=no --startup-file=yes -i devrepl.jl

test/Manifest.toml: test/Project.toml
	@git config --local blame.ignoreRevsFile .git-blame-ignore-revs
	$(JULIA) --project=test --banner=no --startup-file=yes -e 'include("devrepl.jl")'

docs/Manifest.toml: docs/Project.toml
	@git config --local blame.ignoreRevsFile .git-blame-ignore-revs
	$(JULIA) --project=docs --banner=no --startup-file=yes -e 'import Pkg; Pkg.instantiate()'

docs: docs/Manifest.toml ## Build the documentation
	$(JULIA) --project=docs docs/make.jl
	@echo "Done. Consider using 'make devrepl'"

pdf: docs/Manifest.toml ## Build the documentation in PDF format
	$(JULIA) --project=docs docs/makepdf.jl
	@echo "Done. Consider using 'make devrepl'"

servedocs: docs/Manifest.toml  ## Build (auto-rebuild) and serve documentation at PORT=8000
	$(JULIA) --project=docs -e 'ENV["DOCUMENTER_CHECK_LINKS"] = "0"; using LiveServer; servedocs(port=$(PORT), verbose=true)'

clean: ## Clean up build/doc/testing artifacts
	$(JULIA) -e 'include("test/clean.jl"); clean()'
	make -C docs/latex clean

codestyle: test/Manifest.toml ## Apply the codestyle to the entire project
	$(JULIA) --project=test -e 'using JuliaFormatter; format(["src", "docs", "test", "devrepl.jl"], verbose=true)'
	@echo "Done. Consider using 'make devrepl'"

distclean: clean ## Restore to a clean checkout state
	$(JULIA) -e 'include("test/clean.jl"); clean(distclean=true)'
