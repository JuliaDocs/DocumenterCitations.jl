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


__RX_CMD = raw"""@(?<cmd>cite(t|p)?)"""
__RX_KEY = raw"""[^\s"#'(),{}%]+"""
__RX_KEYS = "(?<keys>$__RX_KEY(\\s*,\\s*$__RX_KEY)*)"
__RX_NOTE = raw"""\s*;\s+(?<note>.*)"""
__RX_STYLE = raw"""%(?<style>\w+)%"""
# Regex for [_RX_TEXT_KEYS](_RX_CITE_URL), e.g. [GoerzQ2022](@cite)
_RX_CITE_URL = Regex("^$__RX_CMD($__RX_STYLE)?\$")
_RX_TEXT_KEYS = Regex("^$__RX_KEYS($__RX_NOTE)?\$")
# Regex for [text][_RX_CITE_KEY_URL], e.g. [Semi-AD paper](@cite GoerzQ2022)
_RX_CITE_KEY_URL = Regex("^@cite\\s+(?<key>$__RX_KEY)\$")

struct CitationLink
    link::Markdown.Link                    # the original markdown link
    cmd::Symbol                            # :cite, :citet, :citep etc.
    style::Union{Nothing,Symbol}           # :numeric by default
    keys::Vector{String}                   # bibtex cite keys
    note::Union{Nothing,String}            # e.g. "Eq. (1)"
    link_text::Union{Nothing,Vector{Any}}  # can be nested markdown
    # In the standard case where link.text is the cite key(s), link_text must
    # be `nothing`. Whether or not link_text is `nothing` decided whether we
    # have a "standard citation" or a "custom text citation".
end

function CitationLink(link::Markdown.Link)
    if (m_url = match(_RX_CITE_URL, link.url)) ≢ nothing
        # [GoerzQ2022](@cite)
        cmd = Symbol(m_url[:cmd])
        style = isnothing(m_url[:style]) ? nothing : Symbol(m_url[:style])
        if length(link.text) === 1 && isa(link.text[1], String)
            m_text = match(_RX_TEXT_KEYS, link.text[1])
            if isnothing(m_text)
                @error "Invalid bibtex key: $(link.text[1])"
                error("Invalid citation: $(Markdown.plaininline(link))")
            end
            @debug "Recognized link as standard citation" link m_url m_text
            keys = String[strip(key) for key in split(m_text[:keys], ",")]
            note = m_text[:note]
            link_text = nothing
        else
            @error "Invalid bibtex key (nested markdown)"
            error("Invalid citation: $(Markdown.plaininline(link))")
        end
    elseif (m_url = match(_RX_CITE_KEY_URL, link.url)) ≢ nothing
        @debug "Recognized link as custom text citation" link m_url
        # [Semi-AD Paper](@cite GoerzQ2022)
        cmd = :cite
        style = nothing
        keys = String[m_url[:key],]
        note = nothing
        link_text = link.text
    else
        @error "The @cite link.url does not match required regex: $(link.url)"
        error("Invalid citation: $(Markdown.plaininline(link))")
    end
    CitationLink(link, cmd, style, keys, note, link_text)
end


# Add citation from `link` to the `citations` and `page_citations` of the
# `doc.plugins[CitationBibliography]` object. The `src` is the name of the
# markdown file containing the `link` and `page` is a `Page` object.
function collect_citation(link::Markdown.Link, meta, src, page, doc)
    bib_plugin = doc.plugins[CitationBibliography]
    if occursin("@cite", link.url)
        cit = CitationLink(link)
        for key in cit.keys
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
            expand_citations(expanded, page, doc)
        end
    end
end

function expand_citations(elem, page, doc)
    Documents.walk(page.globals.meta, elem) do link
        expand_citation(link, page.globals.meta, page, doc)
    end
end

"""Format a `@cite` citation.

```julia
text = format_citation(style, entry, citations; note=nothing, cite_cmd=:cite)
```

Returns a string that replaces the link text for a `[key](@cite)` citation in
markdown text. The `entry` is a `Bibliography.Entry` and `citations` is a dict
that maps citation keys (`entry.id`) to the order in which citations appear in
the documentation, i.e., a numeric citation key.

The `note`, if given, is a string like "Eq. (1)".
The `cite_cmd` is the citation command, one of `:cite`, `:citep`, and `:citet`,
see the [natbib
documentation](https://mirrors.rit.edu/CTAN/macros/latex/contrib/natbib/natnotes.pdf)

The `style` must be `:numeric`. This returns the numeric citation key in square
brackets.
"""
function format_citation(style::Symbol, args...; kwargs...)
    return format_citation(Val(style), args...; kwargs...)
end

function format_citation(
    style::Val{:numeric},
    entry,
    citations::OrderedDict{String,Int64};
    note::Union{Nothing,String}=nothing,
    cite_cmd::Symbol=:cite
)
    if cite_cmd == :citet
        @warn "@citet is currently not fully supported  for $style citations"
        # See natbib documentation: should include author name.
    end
    if isnothing(note)
        return "[$(citations[entry.id])]"
    else
        return "[$(citations[entry.id]), $note]"
    end
end


function expand_citation(link::Markdown.Link, meta, page, doc)
    occursin("@cite", link.url) || return false
    cit = CitationLink(link)
    if length(cit.keys) > 1
        error("Multi-citations are not currently supported")
        # For a single key, all we have to do it modify the existing
        # Markdown.Link in-place. For multiple keys, things get much more
        # complicated: we'd have to *replace* the Markdown.Link with a whole
        # tree of new markdown, with multiple links.
    end
    key = cit.keys[1]
    @debug "Expanding citation: $key."
    plugin = doc.plugins[CitationBibliography]
    bib = plugin.bib
    style = plugin.style
    citations = doc.plugins[CitationBibliography].citations
    if haskey(bib, key)
        entry = bib[key]
        headers = doc.internal.headers
        if Anchors.exists(headers, entry.id)
            if Anchors.isunique(headers, entry.id)
                # Replace the `@cite` url with a path to the referenced header.
                anchor = Anchors.anchor(headers, entry.id)
                path   = relpath(anchor.file, dirname(page.build))
                if isnothing(cit.link_text)
                    link.text = format_citation(style, entry, citations; note=cit.note)
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
    return false
end

function expand_citation(other, meta, page, doc)
    return true  # Continue to `walk` through element `other`.
end
