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
using DataStructures: OrderedDict, OrderedSet
using Unicode

export CitationBibliography

"""Plugin for enabling APS style citations in Documenter.jl.

```julia
bib = CitationBibliography(bibfile; style=:numeric)
```

instantiates a plugin that must be passed as an (undocumented!) positional
argument to
[`Documenter.makedocs`](https://documenter.juliadocs.org/stable/lib/public/#Documenter.makedocs).

# Arguments

* `bibfile`: the name of the BiBTeX file from which to read the data.
* `style`: the style to use for the bibliography and all citations. Currently,
  only `:numeric` is supported.
"""
struct CitationBibliography <: Documenter.Plugin
    # name of bib file
    bibfile::String
    # Style name or object (built-in styles are symbols, but custom styles can
    # be anything)
    style::Any
    # citation key => entry
    entries::OrderedDict{String,<:Bibliography.AbstractEntry}
    # citation key => order index (when citation was first seen)
    citations::OrderedDict{String,Int64}
    # page file name => set of citation keys
    page_citations::Dict{String,Set{String}}
end

function CitationBibliography(bibfile::AbstractString=""; style=:numeric)
    entries = import_bibtex(bibfile)
    citations = Dict{String,Int64}()
    page_citations = Dict{String,Set{String}}()
    return CitationBibliography(bibfile, style, entries, citations, page_citations)
end

"""
    Example

An example object citing Ref. [GoerzQ2022](@cite) with a "References" section
in its docstring.

# References

* [GoerzQ2022](@cite) Goerz et al. Quantum 6, 871 (2022)
"""
struct Example end

include("citations.jl")
include("bibliography.jl")

end
