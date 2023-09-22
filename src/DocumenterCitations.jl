module DocumenterCitations

using Documenter
using Documenter.Builder
using Documenter.Selectors
using Documenter.Expanders
using Documenter.Writers.HTMLWriter

import MarkdownAST
import AbstractTrees

using Markdown
using Bibliography: Bibliography, xyear, xlink, xtitle
using OrderedCollections: OrderedDict, OrderedSet
using Unicode

export CitationBibliography

"""Plugin for enabling bibliographic citations in Documenter.jl.

```julia
bib = CitationBibliography(bibfile; style=:numeric)
```

instantiates a plugin object that must be passed as an element of the `plugins`
keyword argument to [`Documenter.makedocs`](https://documenter.juliadocs.org/stable/lib/public/#Documenter.makedocs).

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
* `anchor_map`: an [`AnchorMap`](https://documenter.juliadocs.org/stable/lib/internals/anchors/#Documenter.AnchorMap)
  object that keeps track of the link anchors for references in bibliography
  blocks
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
    # AnchorMap object that stores the link anchors to all references in
    # canonical bibliography blocks
    anchor_map::Documenter.AnchorMap
end

function CitationBibliography(bibfile::AbstractString=""; style=nothing)
    if isnothing(style)
        style = :numeric
        @debug "Using default style=$(repr(style))"
    elseif style == :alpha
        @debug "Auto-upgrading :alpha to AlphaStyle()"
        style = AlphaStyle()
    end
    entries = Bibliography.import_bibtex(bibfile)
    if length(bibfile) > 0
        if !isfile(bibfile)
            error("bibfile $bibfile does not exist")
        end
        if length(entries) == 0
            @warn "No entries loaded from $bibfile"
        end
    end
    citations = OrderedDict{String,Int64}()
    page_citations = Dict{String,Set{String}}()
    anchor_map = Documenter.AnchorMap()
    return CitationBibliography(
        bibfile,
        style,
        entries,
        citations,
        page_citations,
        anchor_map
    )
end


"""
    Example

An example object citing Ref. [GoerzQ2022](@cite) with a "References" section
in its docstring.

# References

* [GoerzQ2022](@cite) Goerz et al. Quantum 6, 871 (2022)
"""
struct Example end


"""
"Smart" alphabetic citation style (relative to the "dumb" `:alpha`).

```julia
style = AlphaStyle()
```

instantiates a style for [`CitationBibliography`](@ref) that avoids duplicate
labels. Any of the entries that would result in the same label will be
disambiguated by appending the suffix "a", "b", etc.

Any bibliography that cites a subset of the given `entries` is guaranteed to
have unique labels.
"""
struct AlphaStyle

    # BibTeX key (entry.id) => rendered label, e.g. "GraceJMO2007" => "GBR+07b"
    label_for_key::Dict{String,String}
    # The internal field `label_for_key` is set by `init_bibliography!` at the
    # beginning of the `ExpandBibliography` pipeline step.

    AlphaStyle() = new(Dict{String,String}())

end


Base.show(io::IO, ::AlphaStyle) = print(io, "AlphaStyle()")


# Work around https://github.com/Humans-of-Julia/BibInternal.jl/issues/22
# This is a monkey-patch of the original routine. We give it preference with
# the type annotation `::String` for the id.
function Bibliography.BibInternal.make_bibtex_entry(id::String, fields; check=:error)
    # "eprint" ∈ keys(fields) && (fields["_type"] = "eprint")  # bug #22
    fields = Dict(lowercase(k) => v for (k, v) in fields) # lowercase tag names
    errors = Bibliography.BibInternal.check_entry(fields, check, id)
    if length(errors) > 0 && check ∈ [:error, :warn]
        message =
            "Entry $id is missing the " *
            foldl(((x, y) -> x * ", " * y), errors) *
            " field(s)."
        check == :error ? (@error message) : (@warn message)
    end
    return Bibliography.BibInternal.Entry(id, fields)
end


include("citations.jl")
include("bibliography.jl")
include("formatting.jl")


function __init__()
    for errname in (:bibliography_block, :citations)
        if !(errname in Documenter.ERROR_NAMES)
            push!(Documenter.ERROR_NAMES, errname)
        end
    end
end


end
