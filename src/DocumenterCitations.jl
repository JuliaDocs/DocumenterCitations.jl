module DocumenterCitations

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
using OrderedCollections: OrderedDict, OrderedSet
using Unicode

export CitationBibliography


const _CACHED_CITATIONS = OrderedDict{String,Int64}()
const _CACHED_PAGE_CITATIONS = OrderedDict{String,Set{String}}()
# The caching is used to get around a Bug in Documenter 0.27, see
# https://discourse.julialang.org/t/running-makedocs-overwrites-repl-docstrings
# Even though it doesn't *really* solve the problem, caching `bib.citations`
# and `bib.page_citation` in practice gets around the plugin not being able to
# detect citations in docstring on a second call to `makedocs`. The caching
# feature should be removed when Documenter 0.28 is released.


"""Plugin for enabling bibliographic citations in Documenter.jl.

```julia
bib = CitationBibliography(bibfile; style=:numeric)
```

instantiates a plugin that must be passed as an (undocumented!) positional
argument to
[`Documenter.makedocs`](https://documenter.juliadocs.org/stable/lib/public/#Documenter.makedocs).

# Arguments

* `bibfile`: the name of the [BibTeX](https://www.bibtex.com/g/bibtex-format/)
  file from which to read the data.
* `style`: the style to use for the bibliography and all citations. The
  available built-in styles are `:numeric` (default), `:authoryear`, and
  `:alpha`. With user-defined styles, this may be an arbitrary name or object.

# Internal fields

The following internal fields are used by the citation pipeline steps. These
should not be considered part of the stable API.

* `entries`: dict of citation keys to entries in `bibfile`
* `citations`: ordered dict of citation key to citation number
* `page_citations`: dict of page file name to set of citation keys cited on
  page.
"""
struct CitationBibliography <: Documenter.Plugin
    # name of bib file
    bibfile::String
    # Style name or object (built-in styles are symbols, but custom styles can
    # be anything)
    style::Any
    # citation key => entry (set on instantiation; private)
    entries::OrderedDict{String,<:Bibliography.AbstractEntry}
    # citation key => order index (when citation was first seen; private)
    citations::OrderedDict{String,Int64}
    # page file name => set of citation keys (private)
    page_citations::Dict{String,Set{String}}
end

function CitationBibliography(bibfile::AbstractString=""; style=nothing, cached=true)
    # note: cached is undocumented (on purpose), see comment at
    # _CACHED_PAGE_CITATIONS. Should be removed when Documenter 0.28 is
    # released
    if isnothing(style)
        @warn "The 1.0 release of DocumenterCitations changed the default citation style from author-year to numeric. To restore the pre-1.0 default style, use `CitationBibliography(bibfile; style=:authoryear)`."
        # The warning is only to transition users through the breaking change
        # in 1.0. It can be removed in any future 1.1 release.
        style = :numeric
    end
    entries = import_bibtex(bibfile)
    if length(bibfile) > 0
        if !isfile(bibfile)
            error("bibfile $bibfile does not exist")
        end
        if length(entries) == 0
            @warn "No entries loaded from $bibfile"
        end
    end
    citations = Dict{String,Int64}()
    page_citations = Dict{String,Set{String}}()
    if cached
        citations = _CACHED_CITATIONS
        page_citations = _CACHED_PAGE_CITATIONS
        if (length(citations) > 0) || (length(page_citations) > 0)
            @warn "Using cached citations"
        end
    end

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
include("formatting.jl")

end
