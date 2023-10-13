# Collect Citations
#
# This runs after ExpandTemplates, such that e.g. docstrings which may contain
# citations have been expanded.

"""Pipeline step to collect citations from all pages.

It walks all pages in the order they appear in the navigation bar, looking for
`@cite` links. It fills the `citations` and `page_citations` attributes of the
internal [`CitationBibliography`](@ref) object.

Thus, the order in which `CollectCitations` encounters citations determines the
numerical key that will appear in the rendered documentation (see
[`ExpandBibliography`](@ref) and [`ExpandCitations`](@ref)).
"""
abstract type CollectCitations <: Builder.DocumentPipeline end

Selectors.order(::Type{CollectCitations}) = 2.11  # After ExpandTemplates

function Selectors.runner(::Type{CollectCitations}, doc::Documenter.Document)
    Documenter.is_doctest_only(doc, "CollectCitations") && return
    @info "CollectCitations"
    collect_citations(doc)
end

# Collect all citations in document
function collect_citations(doc::Documenter.Document)
    bib = Documenter.getplugin(doc, CitationBibliography)
    nav_sources = [node.page for node in doc.internal.navlist]
    other_sources = filter(src -> !(src in nav_sources), keys(doc.blueprint.pages))
    for src in Iterators.flatten([nav_sources, other_sources])
        page = doc.blueprint.pages[src]
        @debug "CollectCitations: collecting `@cite` entries in $src"
        empty!(page.globals.meta)
        try
            _collect_citations(page.mdast, page.globals.meta, src, page, doc)
        catch exc
            #! format: off
            @error "Error collecting citations from $(repr(src))" exception=(exc, catch_backtrace())
            #! format: on
            push!(doc.internal.errors, :citations)
        end
    end
    @debug "Collected citations" bib.citations
end

function _collect_citations(mdast::MarkdownAST.Node, meta, src, page, doc)
    for node in AbstractTrees.PreOrderDFS(mdast)
        if node.element isa Documenter.DocsNode
            # The docstring AST trees are not part of the tree of the page, so
            # we need to expand them explicitly
            for (docstr, docmeta) in zip(node.element.mdasts, node.element.metas)
                _collect_citations(docstr, docmeta, src, page, doc)
            end
        elseif node.element isa MarkdownAST.Link
            collect_citation(node, meta, src, page, doc)
        end
    end
end


# Add citation from `link` to the `citations` and `page_citations` of the
# `doc.plugins[CitationBibliography]` object. The `src` is the name of the
# markdown file containing the `link` and `page` is a `Page` object.
#
# Called on every Link node in the AST.
function collect_citation(node::MarkdownAST.Node, meta, src, page, doc)
    @assert node.element isa MarkdownAST.Link
    bib = Documenter.getplugin(doc, CitationBibliography)
    if startswith(lowercase(node.element.destination), "@cite")
        cit = read_citation_link(node)
        if cit isa CitationLink
            keys = cit.keys
        else
            @assert cit isa DirectCitationLink
            keys = [cit.key]
        end
        for key in keys
            if haskey(bib.entries, key)
                entry = bib.entries[key]
                if haskey(bib.citations, key)
                    @debug "Found non-new citation $key"
                else
                    bib.citations[key] = length(bib.citations) + 1
                    @debug "Found new citation $(bib.citations[key]): $key"
                end
                if !haskey(bib.page_citations, src)
                    bib.page_citations[src] = Set{String}()
                end
                push!(bib.page_citations[src], key)
            else
                @error "Key $(repr(key)) not found in entries from $(bib.bibfile)"
                push!(doc.internal.errors, :citations)
            end
        end
    end
    return false
end
