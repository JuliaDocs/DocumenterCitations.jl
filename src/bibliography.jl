"""Pipeline step to expand all `@bibliography` blocks.

Runs after [`CollectCitations`](@ref) but before [`ExpandCitations`](@ref).

Each bibliography is rendered into HTML as a a [definition
list](https://www.w3schools.com/tags/tag_dl.asp), a [bullet
list](https://www.w3schools.com/tags/tag_ul.asp), or an
[enumeration](https://www.w3schools.com/tags/tag_ol.asp) depending on
[`bib_html_list_style`](@ref).

For a definition list, the label for each list item is rendered via
[`format_bibliography_label`](@ref) and the full bibliographic reference is
rendered via [`format_bibliography_reference`](@ref).

For bullet lists or enumerations, [`format_bibliography_label`](@ref) is not
used and [`format_bibliography_reference`](@ref) fully determines the entry.

The order of the entries in the bibliography is determined by the
[`bib_sorting`](@ref) method for the chosen citation style.

The `ExpandBibliography` step runs [`init_bibliography!`](@ref) before
expanding the first `@bibliography` block.
"""
abstract type ExpandBibliography <: Builder.DocumentPipeline end

Selectors.order(::Type{ExpandBibliography}) = 2.12  # after CollectCitations

function Selectors.runner(::Type{ExpandBibliography}, doc::Documents.Document)
    Documenter.Builder.is_doctest_only(doc, "ExpandBibliography") && return
    @info "ExpandBibliography: expanding `@bibliography` blocks."
    bib = doc.plugins[CitationBibliography]
    style = bib.style  # so that we can dispatch on different styles
    init_bibliography!(style, bib)
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


"""Initialize any internal state for rendering the bibliography.

```julia
init_bibliography!(style, bib)
```

is called at the beginning of the [`ExpandBibliography`](@ref) pipeline step.
It may mutate internal fields of `style` or `bib` to prepare for the rendering
of bibliography blocks.

For the default style, this does nothing.

For, e.g., [`AlphaStyle`](@ref), the call to `init_bibliography!` determines
the citation labels, by generating unique suffixed labels for all the entries
in the underlying `.bib` file (`bib.entries`), and storing the result in an
internal attribute of the `style` object.

Custom styles may implement a new method for `init_bibliography!` for similar
purposes. It can be assumed that all the internal fields of the
[`CitationBibliography`](@ref) `bib` object are up-to-date according to
the citations seen by the earlier [`CollectCitations`](@ref) step.
"""
function init_bibliography!(style, bib) end  # no-op for default style(s)

function init_bibliography!(style::Symbol, bib)
    init_bibliography!(Val(style), bib)
end


function init_bibliography!(style::AlphaStyle, bib)

    # We determine the keys from all the entries in the .bib file
    # (`bib.entries`), not just the cited ones (`bib.citations`). This keeps
    # the rendered labels more stable, e.g. if you have one `.bib` file across
    # multiple related projects. Besides, `bib.citations` isn't guaranteed to
    # be complete at the point where `init_bibliography!` is called, since
    # bibliography blocks can also introduce new citations (e.g., if using `*`)
    entries = OrderedDict{String,Bibliography.Entry}(
        # best not to mutate bib.entries, so we'll create a copy before sorting
        key => entry for (key, entry) in bib.entries
    )
    Bibliography.sort_bibliography!(entries, :nyt)

    # pass 1 - collect dumb labels, identify duplicates
    keys_for_label = Dict{String,Vector{String}}()
    for (key, entry) in entries
        label = alpha_label(entry)  # dumb label (no suffix)
        if label in keys(keys_for_label)
            push!(keys_for_label[label], key)
        else
            keys_for_label[label] = String[key,]
        end
    end

    # pass 2 - disambiguate duplicates (append suffix to dumb labels)
    label_for_key = style.label_for_key  # for in-place mutation
    for (key, entry) in entries
        label = alpha_label(entry)
        if length(keys_for_label[label]) > 1
            i = findfirst(isequal(key), keys_for_label[label])
            label *= _alpha_suffix(i)
        end
        label_for_key[key] = label
    end
    @debug "init_bibliography!(style::AlphaStyle, bib)" keys_for_label label_for_key

    # `style.label_for_key` is now up-to-date

end


function _alpha_suffix(i)
    if i <= 25
        return string(Char(96 + i))  # 1 -> "a", 2 -> "b", etc.
    else
        # 26 -> "za", 27 -> "zb", etc.
        # I couldn't find any information on (and I was too lazy to test) how
        # LaTeX handles disambiguation of more than 25 identical labels, but
        # this seems sensible. But also: Seriously? I don't think we'll ever
        # run into this in real life.
        return "z" * _alpha_suffix(i - 25)
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


function format_bibliography_reference(::AlphaStyle, entry)
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


function format_bibliography_label(
    alpha::AlphaStyle,
    entry,
    citations::OrderedDict{String,Int64}
)
    try
        return "[$(alpha.label_for_key[entry.id])]"
    catch
        @error "No AlphaStyle label for $(entry.id). Was `init_bibliography!` called?" alpha.label_for_key
        rethrow()
    end
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
bib_html_list_style(::AlphaStyle) = :dl


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
bib_sorting(::AlphaStyle) = :nyt


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

    block = x.code
    @debug "ExpandBibliography: expanding `@bibliography` block in $(page.source)" block

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
        if style == :alpha
            # same automatic upgrade as in CitationsBibliography
            style = AlphaStyle()
            init_bibliography!(style, bib)
        end
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
