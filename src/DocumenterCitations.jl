module DocumenterCitations

using Documenter
using Documenter.Anchors
using Documenter.Builder
using Documenter.Documents
using Documenter.Selectors
using Documenter.Utilities
using Documenter.Expanders

using Markdown
using Bibliography
using Bibliography: xnames, xyear, xlink, xtitle, xin
using DataStructures: OrderedDict
using Unicode

export CitationBibliography
struct CitationBibliography <: Documenter.Plugin
    bib::OrderedDict{String,Bibliography.Entry}
end
function CitationBibliography(filename::AbstractString = "";
                              sorting::Symbol = :none)
    filename == "" && return CitationBibliography(Dict())
    bf = import_bibtex(filename)
    if sorting != :none
        sort_bibliography!(bf, sorting)
    end
    return CitationBibliography(bf)
end

"""
    Example

Foo.

[Mayer2012](@cite)
"""
struct Example end

include("citations.jl")
include("bibliography.jl")

end
