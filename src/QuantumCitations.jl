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
bib = CitationBibliography(filename; sorting=:none)
```

instantiates a plugin that must be passed as an (undocumented!) positional
argument to
[`Documenter.makedocs`](https://documenter.juliadocs.org/stable/lib/public/#Documenter.makedocs).

Internally, `bib` can then be accessed as `doc.plugins[CitationBibliography]`
where `doc` is the
[`Documenter.Documents.Document`](https://documenter.juliadocs.org/stable/lib/internals/documents/#Documenter.Documents)
object.

## Internal Attributes

* `filename`: name `filename` with which `bib` was instantiated
* `bib`: the BibTeX data, as obtained by
  [`BibParser.parse_file`](https://humans-of-julia.github.io/BibParser.jl/stable/#BibParser.parse_file-Tuple{Any,%20Val{:BibTeX}})
* `citations`: an ordered dict mapping citation keys to their numerical
  citation key
* `page_citations`: a dict mapping page file names (md files inside `docs/src`)
  to a set of citation keys that are cited on that page
"""
struct CitationBibliography <: Documenter.Plugin
    # name of bib file
    filename::String
    # citation key => entry
    bib::OrderedDict{String,<:Bibliography.AbstractEntry}
    # citation key => order index (when citation was first seen)
    citations::OrderedDict{String,Int64}
    # page file name => set of citation keys
    page_citations::Dict{String,Set{String}}
end

function CitationBibliography(filename::AbstractString=""; sorting::Symbol=:none)
    filename == "" && return CitationBibliography(Dict())
    bf = import_bibtex(filename)
    if sorting != :none
        sort_bibliography!(bf, sorting)
    end
    citations = Dict{String,Int64}()
    page_citations = Dict{String,Set{String}}()
    return CitationBibliography(filename, bf, citations, page_citations)
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
