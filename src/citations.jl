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

function Selectors.runner(::Type{CollectCitations}, doc::Documents.Document)
    @info "CollectCitations"
    collect_citations(doc)
end


function collect_citations(doc::Documents.Document)
    citations = doc.plugins[CitationBibliography].citations
    page_citations = doc.plugins[CitationBibliography].page_citations
    empty!(citations)
    empty!(page_citations)
    nav_sources = [node.page for node in doc.internal.navlist]
    other_sources = filter(src -> !(src in nav_sources), keys(doc.blueprint.pages))
    @info "Looking for citations in pages" nav_sources other_sources
    for src in Iterators.flatten([nav_sources, other_sources])
        page = doc.blueprint.pages[src]
        @debug "Collecting citations in $src"
        empty!(page.globals.meta)
        for elem in page.elements
            Documents.walk(page.globals.meta, page.mapping[elem]) do component
                collect_citation(component, page.globals.meta, src, page, doc)
            end
        end
    end
    @debug "Collected citations" citations
end

function get_citation_key(link)
    if link.url == "@cite"   # citation format: [key](@cite)
        key = link.text[1]
    else  # citation format:                    [text](@cite key)
        if (m = match(r"^@cite\s*([^\s},]+)\s*$", link.url)) ≢ nothing
            key = m[1]
        else
            error("Invalid citation: [$(link.text)]($(link.url))")
        end
    end
    return key
end

function collect_citation(link::Markdown.Link, meta, src, page, doc)
    bib_plugin = doc.plugins[CitationBibliography]
    if occursin("@cite", link.url)
        if length(link.text) === 1 && isa(link.text[1], String)
            key = get_citation_key(link)
            if haskey(doc.plugins[CitationBibliography].bib, key)
                entry = bib_plugin.bib[key]
                citations = bib_plugin.citations
                page_citations = bib_plugin.page_citations
                if haskey(citations, entry.id)
                    @debug "Found non-new citation $(entry.id)"
                else
                    citations[entry.id] = length(citations) + 1
                    @debug "Found new citation $(citations[entry.id]): $(entry.id)"
                end
                if !haskey(page_citations, src)
                    page_citations[src] = Set{String}()
                end
                push!(page_citations[src], entry.id)
            else
                error("Citation not found in bibliography: $(key)")
            end
        else
            error("Invalid citation: $(link.text)")
        end
    end
    return false
end

function collect_citation(elem, meta, src, page, doc)  # for non-links
    return true   # walk into the childrem of elem
end



# Expand Citations
#
# This runs after ExpandBibliography, such that the citation anchors are
# available.

"""Pipeline step to expand all `@cite` citations.

This runs after [`ExpandBibliography`](@ref), as it relies on the link targets
in the expanded `@bibliography` blocks.

All citations are formatted using [`format_citation`](@ref).
"""
abstract type ExpandCitations <: Builder.DocumentPipeline end

Selectors.order(::Type{ExpandCitations}) = 2.13  # After ExpandBibliography

function Selectors.runner(::Type{ExpandCitations}, doc::Documents.Document)
    @info "ExpandCitations"
    expand_citations(doc)
end

function expand_citations(doc::Documents.Document)
    citations = doc.plugins[CitationBibliography].citations
    for (src, page) in doc.blueprint.pages
        @info "Expanding citations in $src"
        empty!(page.globals.meta)
        for expanded in values(page.mapping)
            expand_citation(expanded, page, doc)
        end
    end
end

function expand_citation(elem, page, doc)
    Documents.walk(page.globals.meta, elem) do link
        expand_citation(link, page.globals.meta, page, doc)
    end
end

"""Format a `@cite` citation.

Returns a string that replaces a `[key](@cite)` citation in markdown text.

This returns the same numerical key in square brackets that the default
[`format_bibliography_key`](@ref) produces in the rendered bibliography.
"""
function format_citation(entry, doc)
    citations = doc.plugins[CitationBibliography].citations
    return "[$(citations[entry.id])]"
end

function expand_citation(link::Markdown.Link, meta, page, doc)
    occursin("@cite", link.url) || return false
    if length(link.text) === 1 && isa(link.text[1], String)
        key = get_citation_key(link)
        @debug "Expanding citation: $key."

        bib = doc.plugins[CitationBibliography].bib
        if haskey(bib, key)
            entry = bib[key]
            headers = doc.internal.headers
            if Anchors.exists(headers, entry.id)
                if Anchors.isunique(headers, entry.id)
                    # Replace the `@cite` url with a path to the referenced header.
                    anchor = Anchors.anchor(headers, entry.id)
                    path   = relpath(anchor.file, dirname(page.build))
                    if link.url == "@cite"
                        link.text = format_citation(entry, doc)
                    else
                        # keep original link.text
                    end
                    link.url = string(path, Anchors.fragment(anchor))
                    return true
                else
                    push!(doc.internal.errors, :citations)
                    @warn "'$(entry.id)' is not unique in $(Utilities.locrepr(page.source))."
                end
            else
                push!(doc.internal.errors, :citations)
                @warn "reference for '$(entry.id)' could not be found in $(Utilities.locrepr(page.source))."
            end
        else
            error("Citation not found in bibliography: $(key)")
        end
    else
        error("Invalid citation: $(link.text)")
    end
    return false
end

function expand_citation(other, meta, page, doc)
    return true  # Continue to `walk` through element `other`.
end
