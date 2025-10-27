# Evaluate all doctests in docstrings in the package.
#
# Also check that `DocumenterCitations` behaves correctly in the context of
# `doctest` (when no `.bib` plugin is passed).
# https://github.com/JuliaDocs/DocumenterCitations.jl/issues/34

using Test
using IOCapture: IOCapture
using Documenter: doctest
import DocumenterCitations

@testset "run doctest" begin

    c = IOCapture.capture() do
        withenv("JULIA_DEBUG" => "") do
            doctest(DocumenterCitations)
        end
    end
    if any(result -> result isa Test.Fail, c.value.results)
        @error """
        doctest failure:
        ------------------------------- output -------------------------------
        $(c.output)
        ----------------------------------------------------------------------
        Run `import DocumenterCitations; doctest(DocumenterCitations)` in the
        development REPL (`make devrepl`) for better error reporting.
        """
    else
        @test contains(c.output, "Skipped CollectCitations step (doctest only).")
        @test contains(c.output, "Skipped ExpandBibliography step (doctest only).")
        @test contains(c.output, "Skipped ExpandCitations step (doctest only).")
    end


end
