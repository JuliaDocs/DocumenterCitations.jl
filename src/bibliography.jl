"""Pipeline step to expand all `@bibliography` blocks.

Runs after [`CollectCitations`](@ref) but before [`ExpandCitations`](@ref).

Each bibliography is rendered into HTML as a a [definition
list](https://www.w3schools.com/tags/tag_dl.asp), a [bullet
list](https://www.w3schools.com/tags/tag_ul.asp), or an
[enumeration](https://www.w3schools.com/tags/tag_ol.asp) depending on
[`bib_html_list_style`](@ref). For a definition list, the label for each list
item is rendered via [`format_bibliography_label`](@ref) and the full
bibliographic reference is rendered via
[`format_bibliography_reference`](@ref). For bullet lists of enumerations,
[`format_bibliography_label`](@ref) is not used and
[`format_bibliography_reference`](@ref) fully determines the entry.

The order of the entries in the bibliography is determined by the
[`bib_sorting`](@ref) method for the chosen citation style.
"""
abstract type ExpandBibliography <: Builder.DocumentPipeline end

Selectors.order(::Type{ExpandBibliography}) = 2.12  # after CollectCitations

function Selectors.runner(::Type{ExpandBibliography}, doc::Documents.Document)
    Documenter.Builder.is_doctest_only(doc, "ExpandBibliography") && return
    @info "ExpandBibliography: expanding `@bibliography` blocks."
    for src in keys(doc.blueprint.pages)
        page = doc.blueprint.pages[src]
        empty!(page.globals.meta)
        for element in page.elements
            if Expanders.iscode(element, r"^@bibliography")
                Selectors.dispatch(BibliographyBlock, element, page, doc)
            end
        end
    end
end

abstract type BibliographyBlock <: Selectors.AbstractSelector end


"""Format the full reference for an entry in a `@bibliography` block.

```julia
format_bibliography_reference(style, entry)
```

produces an HTML string for the full reference of a
[`Bibliography.Entry`](https://humans-of-julia.github.io/Bibliography.jl/stable/internal/#BibInternal.Entry).
For the default `style=:numeric`, the result is formatted like in
[REVTeX](https://www.ctan.org/tex-archive/macros/latex/contrib/revtex/auguide)
and [APS journals](https://journals.aps.org). That is, the full list of authors
with initials for the first names, the italicized tile, and the journal
reference (linking to the DOI, if available), ending with the publication year
in parenthesis.
"""
function format_bibliography_reference(style::Symbol, entry)
    return format_bibliography_reference(Val(style), entry)
end


function format_bibliography_reference(::Val{:numeric}, entry)
    authors = format_names(entry; names=:last) |> tex2unicode
    link = xlink(entry)
    title = xtitle(entry) |> tex2unicode
    published_in = format_published_in(entry) |> tex2unicode
    return "$authors. <i>$title</i>. $(linkify(published_in, link))."
end

function format_bibliography_reference(::Val{:authoryear}, entry)
    authors = format_names(entry; names=:lastfirst) |> tex2unicode
    year = entry.date.year |> tex2unicode
    link = xlink(entry)
    title = xtitle(entry) |> tex2unicode
    published_in = format_published_in(entry; include_date=false) |> tex2unicode
    return "$authors ($year). <i>$title</i>. $(linkify(published_in, link))."
end

function format_bibliography_reference(::Val{:alpha}, entry)
    return format_bibliography_reference(:numeric, entry)
end


"""Format the label for an entry in a `@bibliography` block.

```julia
format_bibliography_label(style, entry, citations)
```

produces a string for the label in the bibliography for the given
[`Bibliography.Entry`](https://humans-of-julia.github.io/Bibliography.jl/stable/internal/#BibInternal.Entry).
The `citations` argument is a dict that maps citation keys (`entry.id`) to the
order in which citations appear in the documentation, i.e., a numeric citation
key.

For the default `style=:numeric`, this returns a label that is the numeric
citation key in square brackets, cf. [`format_citation`](@ref). In general,
this function is used only if [`bib_html_list_style`](@ref) returns `:dl` for
the given `style`.
"""
function format_bibliography_label(style::Symbol, args...)
    return format_bibliography_label(Val(style), args...)
end

function format_bibliography_label(
    ::Val{:numeric},
    entry,
    citations::OrderedDict{String,Int64}
)
    key = entry.id
    i = get(citations, key, 0)
    if i == 0
        i = length(citations) + 1
        citations[key] = i
        @debug "Mark $key as cited ($i) because it is rendered in a bibliography"
    end
    return "[$i]"
end


function format_bibliography_label(
    ::Val{:alpha},
    entry,
    citations::OrderedDict{String,Int64}
)
    return "[$(alpha_label(entry))]"
end


"""Identify the type of HTML list associated with a bibliographic style.

```julia
bib_html_list_style(style)
```

must return one of

* `:dl` (definition list),
* `:ul` (unordered / bullet list), or
* `:ol` (ordered list / enumeration),

for any `style` that [`CitationBibliography`](@ref) is instantiated with.
"""
bib_html_list_style(style::Symbol) = bib_html_list_style(Val(style))
bib_html_list_style(::Val{:numeric}) = :dl
bib_html_list_style(::Val{:authoryear}) = :ul
bib_html_list_style(::Val{:alpha}) = :dl


"""Identify the sorting associated with a bibliographic style.

```
bib_sorting(style)
```

must return `:citation` or any of the `sorting_rules` accepted by
[`Bibliography.sort_bibliography!`](https://humans-of-julia.github.io/Bibliography.jl/dev/#Bibliography.sort_bibliography!),
e.g. `:nyt`.
"""
bib_sorting(style::Symbol) = bib_sorting(Val(style))
bib_sorting(::Val{:numeric}) = :citation
bib_sorting(::Val{:authoryear}) = :nyt
bib_sorting(::Val{:alpha}) = :nyt


function parse_bibliography_block(block, doc, page)
    fields = Dict{Symbol,Any}()
    lines = String[]
    for (ex, str) in Documenter.Utilities.parseblock(block, doc, page)
        if Utilities.isassign(ex)
            fields[ex.args[1]] = Core.eval(Main, ex.args[2])
        else
            line = String(strip(str))
            if length(line) > 0
                push!(lines, line)
            end
        end
    end
    if :Canonical ∉ keys(fields)
        fields[:Canonical] = true
    end
    allowed_fields = Set{Symbol}((:Canonical, :Pages, :Sorting, :Style))
    # Note: :Sorting and :Style are undocumented features
    for field in keys(fields)
        if field ∉ allowed_fields
            warn_loc = "N/A"
            if (doc ≢ nothing) && (page ≢ nothing)
                warn_loc = Documenter.Utilities.locrepr(
                    page.source,
                    Documenter.Utilities.find_block_in_file(block, page.source)
                )
            end
            @warn("Invalid field $field ∉ $allowed_fields in $warn_loc")
            (doc ≢ nothing) && push!(doc.internal.errors, :bibliography_block)
        end
    end
    return fields, lines
end


function Selectors.runner(::Type{BibliographyBlock}, x, page, doc)

    @info "Expanding bibliography in $(page.source)."
    block = x.code
    @debug "Evaluating @bibliography block" block

    bib = doc.plugins[CitationBibliography]
    citations = bib.citations
    style::Any = bib.style
    page_citations = bib.page_citations

    fields, lines = parse_bibliography_block(block, doc, page)

    style = bib.style
    if :Style in keys(fields)
        # The :Style field in @bibliography is an undocumented feature. Citations
        # and bibliography should use the same style (set at the plugin level).
        # Local styles are for the Gallery in the documentation only.
        @assert fields[:Style] isa Symbol
        style = fields[:Style]
        @debug "Overriding local style with $repr($style)"
    end

    keys_to_show = OrderedSet{String}()

    # first, cited keys (filter by Pages)
    if :Pages in keys(fields)
        for key in keys(citations)
            for file in fields[:Pages]
                if key in page_citations[file]
                    push!(keys_to_show, key)
                    @debug "Add $key to keys_to_show (from page $file)" keys_to_show
                    break  # only need the first page that cites the key
                end
            end
        end
    else
        # all cited keys
        if length(citations) > 0
            push!(keys_to_show, keys(citations)...)
        else
            @warn "There were no citations"
        end
        @debug "Add all cited keys to keys_to_show" citations keys_to_show
    end

    # second, explicitly listed keys
    for key in lines
        if key == "*"
            push!(keys_to_show, keys(bib.entries)...)
            @debug "Add all keys from $(bib.bibfile) to keys_to_show" keys_to_show
            break  # we don't need to look at the rest of the lines
        else
            if key in keys(bib.entries)
                push!(keys_to_show, key)
                @debug "Add listed $key to keys_to_show" keys_to_show
            else
                error("Citation key not found in bibliography: $(key)")
            end
        end
    end

    tag = bib_html_list_style(style)
    allowed_tags = (:ol, :ul, :dl)
    if tag ∉ allowed_tags
        error(
            "bib_html_list_tyle returned an invalid tag $(repr(tag)). " *
            "Must be one of $(repr(allowed_tags))"
        )
    end
    html = """<div class="citation noncanonical"><$tag>"""
    if fields[:Canonical]
        html = """<div class="citation canonical"><$tag>"""
    end
    headers = doc.internal.headers
    entries = OrderedDict{String,Bibliography.Entry}(
        key => bib.entries[key] for key in keys_to_show
    )
    sorting = get(fields, :Sorting, bib_sorting(style))
    # The "Sorting" field is undocumented, because the sorting is really tied
    # to the citation style. If someone wants to mess with that, they can, but
    # we probably shouldn't encourage it.
    if sorting ≠ :citation
        Bibliography.sort_bibliography!(entries, sorting)
    end
    for (key, entry) in entries
        @assert entry.id == key
        if fields[:Canonical]
            # Add anchor that citations can link to from anywhere in the docs.
            if Anchors.exists(headers, key)
                # Skip entries that already have a canonical bib entry
                # elsewhere. This is expected behavior, not an error/warning,
                # allowing to split the canonical bibliography in multiple
                # parts.
                @debug "Skipping key=$(key) (existing anchor)"
                continue
            else
                @debug "Defining anchor for key=$(key)"
                Anchors.add!(headers, entry, key, page.build)
            end
        else
            # For non-canonical bibliographies, no anchors are generated, and
            # we don't skip any keys. That is, multiple non-canonical
            # bibliographies may contain entries for the same keys.
        end
        @debug "Expanding bibliography entry: $key."
        if tag == :dl
            html *= """
            <dt>$(format_bibliography_label(style, entry, citations))</dt>
            <dd>
            <div id="$key">$(format_bibliography_reference(style, entry))</div>
            </dd>"""
        else
            html *= """
            <li>
            <div id="$key">$(format_bibliography_reference(style, entry))</div>
            </li>"""
        end
    end
    html *= "\n</$tag></div>"

    page.mapping[x] = Documents.RawNode(:html, html)

end
