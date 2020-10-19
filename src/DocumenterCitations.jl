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

export CitationBibliography
struct CitationBibliography <: Documenter.Plugin
    bib::Dict
end
function CitationBibliography(filename::AbstractString="")
    filename == "" && return CitationBibliography(Dict())
    bf = import_bibtex(filename)
    return CitationBibliography(bf)
end


include("citations.jl")
include("bibliography.jl")

end