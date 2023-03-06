module QuantumCitations

using Documenter
using Documenter.Anchors
using Documenter.Builder
using Documenter.Documents
using Documenter.Selectors
using Documenter.Utilities
using Documenter.Expanders
using Documenter.Writers.HTMLWriter

using Markdown
using Bibliography
using Bibliography: xyear, xlink, xtitle
using DataStructures: OrderedDict
using Unicode

export CitationBibliography
struct CitationBibliography <: Documenter.Plugin
    # citation key => entry
    bib::OrderedDict{String,<:Bibliography.AbstractEntry}
    # citation key => number of citations
    citations::OrderedDict{String,Int64}
end

function CitationBibliography(filename::AbstractString = "";
                              sorting::Symbol = :none)
    filename == "" && return CitationBibliography(Dict())
    bf = import_bibtex(filename)
    if sorting != :none
        sort_bibliography!(bf, sorting)
    end
    citations = Dict{String,Int64}()
    return CitationBibliography(bf, citations)
end

"""
    Example

An example object with a "References" section in its docstring.

# References

* [Goerz et al. Quantum 6, 871 (2022)](@cite GoerzQ2022)
"""
struct Example end

include("citations.jl")
include("bibliography.jl")

end
