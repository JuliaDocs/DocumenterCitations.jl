# Collect Citations
#
# This runs after ExpandTemplates,  such that e.g. docstrings which may contain
# citations have been expanded. It walks the entire site, looking for
# `@cite` links, and collects them in the
# `doc.plugins[CitationBibliography].citations` dict
#
# The ExpandBibliography step that runs afterwards thus knows which entries in
# the bib file has been cited and which not, and in which order

abstract type CollectCitations <: Builder.DocumentPipeline end

Selectors.order(::Type{CollectCitations}) = 2.11  # After ExpandTemplates

function Selectors.runner(::Type{CollectCitations}, doc::Documents.Document)
    @info "CollectCitations"
    collect_citations(doc)
end


function collect_citations(doc::Documents.Document)
    nav_sources = [node.page for node in doc.internal.navlist]
    other_sources = filter(src -> !(src in nav_sources), keys(doc.blueprint.pages))
    @info "Looking for citations in pages" nav_sources other_sources
    for src in Iterators.flatten([nav_sources, other_sources])
        page = doc.blueprint.pages[src]
        @debug "Collecting citations in $src"
        empty!(page.globals.meta)
        for elem in page.elements
            Documents.walk(page.globals.meta, page.mapping[elem]) do component
                collect_citation(component, page.globals.meta, page, doc)
            end
        end
    end
    citations = doc.plugins[CitationBibliography].citations
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

function collect_citation(link::Markdown.Link, meta, page, doc)
    if occursin("@cite", link.url)
        if length(link.text) === 1 && isa(link.text[1], String)
            key = get_citation_key(link)
            if haskey(doc.plugins[CitationBibliography].bib, key)
                entry = doc.plugins[CitationBibliography].bib[key]
                citations = doc.plugins[CitationBibliography].citations
                if haskey(citations, entry.id)
                    @debug "Found non-new citation $(entry.id)"
                else
                    citations[entry.id] = length(citations) + 1
                    @debug "Found new citation $(citations[entry.id]): $(entry.id)"
                end
            else
                error("Citation not found in bibliography: $(key)")
            end
        else
            error("Invalid citation: $(link.text)")
        end
    end
    return false
end

function collect_citation(elem, meta, page, doc)  # for non-links
    return true   # walk into the childrem of elem
end



# Expand Citations
#
# This runs after ExpandBibliography, such that the citation anchors are
# available.

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

function format_citation(entry, doc)
    citations = doc.plugins[CitationBibliography].citations
    return "[$(citations[entry.id])]"
    # alternative style:
    # authors = format_names(entry; names=:lastonly) |> tex2unicode
    # text = authors * " (" * xyear(entry) * ")"
    # return text
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
                    anchor   = Anchors.anchor(headers, entry.id)
                    path     = relpath(anchor.file, dirname(page.build))
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
            error("Citation not found in bibliography: $(citation_name)")
        end
    else
        error("Invalid citation: $(link.text)")
    end
    return false
end

function expand_citation(other, meta, page, doc)
    return true  # Continue to `walk` through element `other`.
end
