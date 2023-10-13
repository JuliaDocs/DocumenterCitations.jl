# Expand Citations
#
# This runs after ExpandBibliography, such that the citation anchors are
# available in `bib.anchor_map`.

"""Pipeline step to expand all `@cite` citations.

This runs after [`ExpandBibliography`](@ref), as it relies on the link targets
in the expanded `@bibliography` blocks.

All citations are formatted using [`format_citation`](@ref).
"""
abstract type ExpandCitations <: Builder.DocumentPipeline end

Selectors.order(::Type{ExpandCitations}) = 2.13  # After ExpandBibliography

function Selectors.runner(::Type{ExpandCitations}, doc::Documenter.Document)
    Documenter.is_doctest_only(doc, "ExpandCitations") && return
    @info "ExpandCitations"
    expand_citations!(doc)
end

# Expand all citations in document
function expand_citations!(doc::Documenter.Document)
    for (src, page) in doc.blueprint.pages
        @debug "ExpandCitations: resolving links and replacement text for @cite entries in $(src)"
        empty!(page.globals.meta)
        expand_citations!(doc, page, page.mdast)
    end
end

# Expand all citations in one page (modify `mdast` in-place)
function expand_citations!(doc::Documenter.Document, page, mdast::MarkdownAST.Node)
    bib = Documenter.getplugin(doc, CitationBibliography)
    replace!(mdast) do node
        if node.element isa Documenter.DocsNode
            # The docstring AST trees are not part of the tree of the page, so
            # we need to expand them explicitly
            for (docstr, meta) in zip(node.element.mdasts, node.element.metas)
                expand_citations!(doc, page, docstr)
            end
            node
        else
            expand_citation(node, page, bib)
        end
    end
end


"""Expand a [`CitationLink`](@ref) into style-specific markdown code.

```julia
md_text = format_citation(style, cit, entries, citations)
```

returns a string of markdown code that replaces the original citation link,
rendering it for the given `style`. The resulting markdown code should make use
of direct citation links (cf. [`DirectCitationLink`](@ref)).

For example, for the default style,

```jldoctest
using DocumenterCitations: format_citation, CitationLink, example_bibfile
using Bibliography

cit = CitationLink("[BrifNJP2010, Shapiro2012; and references therein](@cite)")
entries = Bibliography.import_bibtex(example_bibfile)
citations = Dict("BrifNJP2010" => 1, "Shapiro2012" => 2)

format_citation(:numeric, cit, entries, citations)

# output

"[[1](@cite BrifNJP2010), [2](@cite Shapiro2012), and references therein]"
```

# Arguments

* `style`: The style  to render the citation in, as passed to
  [`CitationBibliography`](@ref)
* `cit`: A [`CitationLink`](@ref) instance representing the original citation
  link
* `entries`: A dict mapping citations `keys` to a
  [`Bibliography.Entry`](https://humans-of-julia.github.io/Bibliography.jl/stable/internal/#BibInternal.Entry)
* `citations`: A dict mapping that maps citation keys to the order in
  which citations appear in the documentation, i.e., a numeric citation index.
"""
function format_citation(style::Symbol, args...)::String
    return format_citation(Val(style), args...)
end


# Return list of replacement nodes for  single citation Link node
# Any node that is not a citation link is returned unchanged.
function expand_citation(
    node::MarkdownAST.Node,
    page,
    bib::CitationBibliography;
    _recursive=true  # internal: expand each expanded sibling again?
)
    (node.element isa MarkdownAST.Link) || return node
    startswith(lowercase(node.element.destination), "@cite") || return node
    cit = read_citation_link(node)
    anchors = bib.anchor_map
    rec = _recursive ? "" : " (rec)"  # _recursive=false if we're *in* a recursion
    if cit isa CitationLink
        style = isnothing(cit.style) ? bib.style : cit.style
        # Using the cit.style is an undocumented feature. We only use it to
        # render citations in a non-default style in the Gallery in the
        # documentation.
        expanded_md_str = format_citation(style, cit, bib.entries, bib.citations)
        @debug "expand_citation$rec: $cit → $expanded_md_str"
        # expanded_md_str should contain direct citation links, and we now
        # expand those recursively
        local expanded_nodes1
        try
            expanded_nodes1 = Documenter.mdparse(expanded_md_str; mode=:span)
        catch
            @error "Cannot parse result of `format_citation`" style cit expanded_md_str
            error("Invalid result of `format_citation`")
        end
        expanded_nodes = []
        for sibling in expanded_nodes1
            expanded_sibling = expand_citation(sibling, page, bib; _recursive=false)
            if expanded_sibling isa Vector
                append!(expanded_nodes, expanded_sibling)
            else
                push!(expanded_nodes, expanded_sibling)
            end
        end
        return expanded_nodes
    else
        @assert cit isa DirectCitationLink
        # E.g., "[Semi-AD paper](@cite GoerzQ2022)"
        key = cit.key
        anchor = Documenter.anchor(anchors, key)
        if isnothing(anchor)
            link_text = ast_linktext(cit.node)
            @error "expand_citation$rec: No destination for key=$(repr(key)) → unlinked text $(repr(link_text))"
            return Documenter.mdparse(link_text; mode=:span)
        else
            expanded_node = MarkdownAST.copy_tree(node)
            path = relpath(anchor.file, dirname(page.build))
            expanded_node.element.destination =
                string(path, Documenter.anchor_fragment(anchor))
            @debug "expand_citation$rec: $cit → link to $(expanded_node.element.destination)"
            return expanded_node
        end
    end
end
