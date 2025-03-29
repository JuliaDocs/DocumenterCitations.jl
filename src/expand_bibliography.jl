_ALLOW_PRE_13_FALLBACK = true

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
    if (DOCUMENTER_VERSION < v"1.2") && doc.user.linkcheck
        @warn "Checking links in the bibliography (`linkcheck=true`) requires Documenter >= 1.2" DOCUMENTER_VERSION
    end
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
mdstr = format_bibliography_reference(style, entry)
```

produces a markdown string for the full reference of a
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
mdstr = format_bibliography_label(style, entry, citations)
```

produces a plain text (technically, markdown) string for the label in the
bibliography for the given
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
            key = ex.args[1]
            val = Core.eval(Main, ex.args[2])
            fields[key] = val
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
    warn_loc = "N/A"
    if (doc ≢ nothing) && (page ≢ nothing)
        warn_loc = Documenter.locrepr(
            page.source,
            Documenter.find_block_in_file(block, page.source)
        )
    end
    for field in keys(fields)
        if field ∉ allowed_fields
            @warn("Invalid field $field ∉ $allowed_fields in $warn_loc")
            (doc ≢ nothing) && push!(doc.internal.errors, :bibliography_block)
        end
    end
    if (:Canonical in keys(fields)) && !(fields[:Canonical] isa Bool)
        @warn "The field `Canonical` in $warn_loc must evaluate to a boolean. Setting invalid `Canonical=$(repr(fields[:Canonical]))` to `Canonical=false`"
        fields[:Canonical] = false
        (doc ≢ nothing) && push!(doc.internal.errors, :bibliography_block)
    end
    if (:Pages in keys(fields)) && !(fields[:Pages] isa Vector)
        @warn "The field `Pages` in $warn_loc must evaluate to a list of strings. Setting invalid `Pages = $(repr(fields[:Pages]))` to `Pages = []`"
        fields[:Pages] = String[]
        (doc ≢ nothing) && push!(doc.internal.errors, :bibliography_block)
    elseif :Pages in keys(fields)
        # Pages is a Vector, but maybe not a Vector of strings
        fields[:Pages] = [_assert_string(name, doc, warn_loc) for name in fields[:Pages]]
    end
    return fields, lines
end

function _assert_string(val, doc, warn_loc)
    str = string(val)  # doesn't ever seem to fail
    if str != val
        @warn "The value `$(repr(val))` in $warn_loc is not a string. Replacing with $(repr(str))"
        (doc ≢ nothing) && push!(doc.internal.errors, :bibliography_block)
    end
    return str
end


# Expand a single @bibliography block
function expand_bibliography(node::MarkdownAST.Node, meta, page, doc)

    @assert node.element isa MarkdownAST.CodeBlock
    @assert occursin(r"^@bibliography", node.element.info)

    block = node.element.code
    warn_loc =
        Documenter.locrepr(page.source, Documenter.find_block_in_file(block, page.source))
    @debug "Evaluating @bibliography block in $warn_loc:\n```@bibliography\n$block\n```"

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
    if (length(citations) > 0) && (:Pages in keys(fields))
        page_folder = dirname(Documenter.pagekey(doc, page))
        # The `page_folder` is relative to `doc.user.source` (corresponding to
        # the definition of the keys in `page_citations`)
        keys_in_pages = Set{String}()  # not ordered (see below)
        Pages = _resolve__FILE__(fields[:Pages], page)
        @debug "filtering citations to Pages" Pages
        for name in Pages
            # names in `Pages` are supposed to be relative to the folder
            # containing the file containing the `@bibliography` block,
            # i.e., `page_folder`
            file = normpath(page_folder, name)
            # `file` should now be a valid key in `page_citations`
            try
                @debug "Add keys cited in $file to keys_to_show"
                push!(keys_in_pages, page_citations[file]...)
            catch exc
                @assert exc isa KeyError
                expected_file = normpath(doc.user.source, page_folder, name)
                if isfile(expected_file)
                    @error "Invalid $(repr(name)) in Pages attribute of @bibliography block on page $(warn_loc): File $(repr(expected_file)) exists but no references were collected."
                    push!(doc.internal.errors, :bibliography_block)
                else
                    # try falling back to pre-1.3 behavior
                    exists_in_src = isfile(joinpath(doc.user.source, name))
                    valid_pre_13 = exists_in_src && haskey(page_citations, name)
                    if _ALLOW_PRE_13_FALLBACK && valid_pre_13
                        @warn "The entry $(repr(name)) in the Pages attribute of the @bibliography block on page $(warn_loc) appears to be relative to $(repr(doc.user.source)). Starting with DocumenterCitations 1.3, names in `Pages` must be relative to the folder containing the file which contains the `@bibliography` block."
                        @debug "Add keys cited in $(abspath(normpath(doc.user.source, name))) to keys_to_show (pre-1.3 fallback)"
                        push!(keys_in_pages, page_citations[name]...)
                    else
                        # Files that don't contain any citations don't show up in
                        # `page_citations`.
                        @error "Invalid $(repr(name)) in Pages attribute of @bibliography block on page $(warn_loc): No such file $(repr(expected_file))."
                        push!(doc.internal.errors, :bibliography_block)
                    end
                end
                continue
            end
        end
        keys_to_add = [k for k in keys(citations) if k in keys_in_pages]
        if length(keys_to_add) > 0
            push!(keys_to_show, keys_to_add...)
            @debug "Collected keys_to_show from Pages" keys_to_show
        elseif length(lines) == 0
            # Only warn if there are no explicit keys. Otherwise, the common
            # idiom of `Pages = []` (with explicit keys) would fail
            @warn "No cited keys remaining after filtering to Pages" Pages
        end
    else
        # all cited keys
        if length(citations) > 0
            push!(keys_to_show, keys(citations)...)
            @debug "Add all cited keys to keys_to_show" keys(citations)
        else
            @warn "There were no citations"
        end
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

    @debug "Determined full list of keys to show" keys_to_show

    tag = bib_html_list_style(style)
    allowed_tags = (:ol, :ul, :dl)
    if tag ∉ allowed_tags
        error(
            "bib_html_list_tyle returned an invalid tag $(repr(tag)). " *
            "Must be one of $(repr(allowed_tags))"
        )
    end

    bibliography_node = BibliographyNode(tag, fields[:Canonical], BibliographyItem[])

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
            anchor_key = key
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
            anchor_key = nothing
            # For non-canonical bibliographies, no anchors are generated, and
            # we don't skip any keys. That is, multiple non-canonical
            # bibliographies may contain entries for the same keys.
        end
        @debug "Expanding bibliography entry: $key."
        reference = MarkdownAST.@ast MarkdownAST.Paragraph()
        append!(
            reference.children,
            Documenter.mdparse(format_bibliography_reference(style, entry); mode=:span)
        )
        if tag == :dl
            label = MarkdownAST.@ast MarkdownAST.Paragraph()
            append!(
                label.children,
                Documenter.mdparse(
                    format_bibliography_label(style, entry, citations);
                    mode=:span
                )
            )
        else
            label = nothing
        end
        push!(bibliography_node.items, BibliographyItem(anchor_key, label, reference))
    end
    node.element = bibliography_node

end


# Deal with `@__FILE__` in `Pages`, convert it to the name of the current file.
function _resolve__FILE__(Pages, page)
    __FILE__ = let ex = Meta.parse("_ = @__FILE__", 1; raise=false)[1]
        # What does a `@__FILE__` in the Pages list evaluate to?
        # Cf. `Core.eval` in `parse_bibliography_block`.
        # Should be the string "none", but that's an implementation detail.
        Core.eval(Main, ex.args[2])
    end
    result = String[]
    for name in Pages
        if name == __FILE__
            # Replace @__FILE__ in Pages with the current file:
            name = basename(page.source)
            @debug "__@FILE__ -> $(repr(name)) in Pages attribute of @bibliography block on page $(page.source)"
        end
        push!(result, name)
    end
    return result
end
