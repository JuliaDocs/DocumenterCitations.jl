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

function Selectors.runner(::Type{ExpandBibliography}, doc::Documenter.Document)
    Documenter.is_doctest_only(doc, "ExpandBibliography") && return
    @info "ExpandBibliography: expanding `@bibliography` blocks."
    expand_bibliography(doc)
end

# Expand all @bibliography blocks in the document
function expand_bibliography(doc::Documenter.Document)
    bib = Documenter.getplugin(doc, CitationBibliography)
    style = bib.style  # so that we can dispatch on different styles
    init_bibliography!(style, bib)
    for (src, page) in doc.blueprint.pages
        empty!(page.globals.meta)
        expand_bibliography(doc, page, page.mdast)
    end
end

# Expand all @bibliography blocks in one page
function expand_bibliography(doc::Documenter.Document, page, mdast::MarkdownAST.Node)
    for node in AbstractTrees.PreOrderDFS(mdast)
        is_bib_block =
            node.element isa MarkdownAST.CodeBlock &&
            occursin(r"^@bibliography", node.element.info)
        is_bib_block && expand_bibliography(node, page.globals.meta, page, doc)
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


"""Identify the sorting associated with a bibliographic style.

```
bib_sorting(style)
```

must return `:citation` or any of the `sorting_rules` accepted by
[`Bibliography.sort_bibliography!`](https://humans-of-julia.github.io/Bibliography.jl/dev/#Bibliography.sort_bibliography!),
e.g. `:nyt`.
"""
bib_sorting(style::Symbol) = bib_sorting(Val(style))


function parse_bibliography_block(block, doc, page)
    fields = Dict{Symbol,Any}()
    lines = String[]
    for (ex, str) in Documenter.parseblock(block, doc, page; raise=false)
        if Documenter.isassign(ex)
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
                warn_loc = Documenter.locrepr(
                    page.source,
                    Documenter.find_block_in_file(block, page.source)
                )
            end
            @warn("Invalid field $field ∉ $allowed_fields in $warn_loc")
            (doc ≢ nothing) && push!(doc.internal.errors, :bibliography_block)
        end
    end
    return fields, lines
end

# Expand a single @bibliography block
function expand_bibliography(node::MarkdownAST.Node, meta, page, doc)
    @assert node.element isa MarkdownAST.CodeBlock
    @assert occursin(r"^@bibliography", node.element.info)

    block = node.element.code
    @debug "Evaluating @bibliography block in $(page.source):\n```@bibliography\n$block\n```"

    bib = Documenter.getplugin(doc, CitationBibliography)
    citations = bib.citations
    style::Any = bib.style
    page_citations = bib.page_citations

    fields, lines = parse_bibliography_block(block, doc, page)
    @debug "Parsed bibliography block into fields and lines" fields lines

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
                    @debug "Add $key to keys_to_show (from page $file)"
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
        @debug "Add all cited keys to keys_to_show" citations
    end

    # second, explicitly listed keys
    for key in lines
        if key == "*"
            push!(keys_to_show, keys(bib.entries)...)
            @debug "Add all keys from $(bib.bibfile) to keys_to_show"
            break  # we don't need to look at the rest of the lines
        else
            if key in keys(bib.entries)
                push!(keys_to_show, key)
                @debug "Add listed $key to keys_to_show"
            else
                @error "Explicit key $(repr(key)) from bibliography block not found in entries from $(bib.bibfile)"
                push!(doc.internal.errors, :bibliography_block)
            end
        end
    end

    @debug "Determined keys to show" keys_to_show

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
    anchors = bib.anchor_map
    entries_to_show = OrderedDict{String,Bibliography.Entry}(
        key => bib.entries[key] for key in keys_to_show
    )
    sorting = get(fields, :Sorting, bib_sorting(style))
    # The "Sorting" field is undocumented, because the sorting is really tied
    # to the citation style. If someone wants to mess with that, they can, but
    # we probably shouldn't encourage it.
    if sorting ≠ :citation
        Bibliography.sort_bibliography!(entries_to_show, sorting)
    end
    for (key, entry) in entries_to_show
        if fields[:Canonical]
            # Add anchor that citations can link to from anywhere in the docs.
            if Documenter.anchor_exists(anchors, key)
                # Skip entries that already have a canonical bib entry
                # elsewhere. This is expected behavior, not an error/warning,
                # allowing to split the canonical bibliography in multiple
                # parts.
                @debug "Skipping key=$(key) (existing anchor)"
                continue
            else
                @debug "Defining anchor for key=$(key)"
                Documenter.anchor_add!(anchors, entry, key, page.build)
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

    node.element = Documenter.RawNode(:html, html)

end
