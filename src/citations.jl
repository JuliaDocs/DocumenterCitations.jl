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
    @info "CollectCitations: collecting `@cite` entries in document"
    collect_citations(doc)
end


function collect_citations(doc::Documents.Document)
    local bib
    try
        bib = doc.plugins[CitationBibliography]
    catch
        @error(
            "You are `using CitationBibligraphy`, but did not pass the plugin to `makedocs`"
        )
        return false
    end
    nav_sources = [node.page for node in doc.internal.navlist]
    other_sources = filter(src -> !(src in nav_sources), keys(doc.blueprint.pages))
    for src in Iterators.flatten([nav_sources, other_sources])
        page = doc.blueprint.pages[src]
        @debug "CollectCitations: collecting `@cite` entries in $src"
        empty!(page.globals.meta)
        try
            for elem in page.elements
                Documents.walk(page.globals.meta, page.mapping[elem]) do component
                    collect_citation(component, page.globals.meta, src, page, doc)
                end
            end
        catch
            push!(doc.internal.errors, :citations)
        end
    end
    @debug "Collected citations" bib.citations
end


__RX_CMD = raw"""@(?<cmd>[cC]ite(t|p|alt|alp|num)?)(?<starred>\*)?"""
__RX_KEY = raw"""[^\s"#'(),{}%]+"""
__RX_KEYS = "(?<keys>$__RX_KEY(\\s*,\\s*$__RX_KEY)*)"
__RX_NOTE = raw"""\s*;\s+(?<note>.*)"""
__RX_STYLE = raw"""%(?<style>\w+)%"""
# Regex for [_RX_TEXT_KEYS](_RX_CITE_URL), e.g. [GoerzQ2022](@cite)
_RX_CITE_URL = Regex("^$__RX_CMD($__RX_STYLE)?\$")
_RX_TEXT_KEYS = Regex("^$__RX_KEYS($__RX_NOTE)?\$")
# Regex for [text][_RX_CITE_KEY_URL], e.g. [Semi-AD paper](@cite GoerzQ2022)
_RX_CITE_KEY_URL = Regex("^@cite\\s+(?<key>$__RX_KEY)\$")

Base.@kwdef struct CitationLink
    link::Markdown.Link                    # the original markdown link
    cmd::Symbol                            # :cite, :citet, :citep (lowercase)
    style::Union{Nothing,Symbol}           # :numeric by default
    keys::Vector{String}                   # bibtex cite keys
    note::Union{Nothing,String}            # e.g. "Eq. (1)"
    capitalize::Bool                       # whether @Cite... command is used
    starred::Bool                          # whether "*" command is used
    link_text::Union{Nothing,Vector{Any}}  # can be nested markdown
    # In the standard case where link.text is the cite key(s), link_text must
    # be `nothing`. Whether or not link_text is `nothing` decides whether we
    # have a "standard citation" or a "custom text citation".
end

function Base.show(io::IO, c::CitationLink)
    print(
        io,
        "CitationLink(link=$(c.link), cmd=$(c.cmd), style=$(c.style), keys=$(c.keys), note=$(c.note), capitalize=$(c.capitalize), starred=$(c.starred), link_text=$(c.link_text))"
    )
end

function CitationLink(link::Markdown.Link)
    if (m_url = match(_RX_CITE_URL, link.url)) ≢ nothing
        # [GoerzQ2022](@cite)
        cmd = Symbol(lowercase(m_url[:cmd]))
        capitalize = startswith(m_url[:cmd], "C")
        starred = !isnothing(m_url[:starred])
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
        capitalize = false
        starred = false
        link_text = link.text
    else
        @error "The @cite link.url does not match required regex: $(link.url)"
        error("Invalid citation: $(Markdown.plaininline(link))")
    end
    CitationLink(link, cmd, style, keys, note, capitalize, starred, link_text)
end


# Add citation from `link` to the `citations` and `page_citations` of the
# `doc.plugins[CitationBibliography]` object. The `src` is the name of the
# markdown file containing the `link` and `page` is a `Page` object.
function collect_citation(link::Markdown.Link, meta, src, page, doc)
    bib = doc.plugins[CitationBibliography]
    if startswith(lowercase(link.url), "@cite")
        cit = CitationLink(link)
        for key in cit.keys
            if haskey(bib.entries, key)
                entry = bib.entries[key]
                @assert entry.id == key
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
                @error("Citation not found in bibliography: $key")
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
    @info "ExpandCitations: resolving links and replacement text for @cite entries in document"
    expand_citations(doc)
end

function expand_citations(doc::Documents.Document)
    for (src, page) in doc.blueprint.pages
        @debug "ExpandCitations: resolving links and replacement text for @cite entries in $(src)"
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
text = format_citation(
    style,
    entry,
    citations;
    note=nothing,
    cite_cmd=:cite,
    capitalize=false,
    starred=false
)
```

returns a string that replaces the link text for a markdown
citation (`[key](@cite)` and its variations, see [Syntax for Citations](@ref)
and the [Citation Style Gallery](@ref gallery)).

For the default `style=:numeric` and `[key](@cite)`, this returns a label that
is the numeric citation key in square brackets, cf.
[`format_bibliography_label`](@ref).

# Argument

* `style`: The style  to render the citation in, as passed to
  [`CitationBibliography`](@ref)
* `entry`: The [`Bibliography.Entry`](https://humans-of-julia.github.io/Bibliography.jl/stable/internal/#BibInternal.Entry)
  that is being cited
* `citations`: A dict that maps citation keys (`entry.id`) to the order in
  which citations appear in the documentation, i.e., a numeric citation index
* `note`: A citation note, e.g. "Eq. (1)" in `[GoerzQ2022; Eq. (1)](@cite)`
* `cite_cmd`: The citation command, one of `:cite`, `:citet`, `:citep`. Note
  that, e.g., `[Goerz@2022](@Citet*)` results in `cite_cmd=:citet`
* `capitalize`: Whether the citation should be formatted to appear at the start
  of a sentence, as indicated by a capitalized `@Cite...` command, e.g.,
  `[GoerzQ2022](@Citet*)`
* `starred`: Whether the citation should be rendered in "extended" form, i.e.,
  with the full list of authors, as indicated by a `*` in the citation, e.g.,
  `[Goerz@2022](@Citet*)`
"""
function format_citation(style::Symbol, args...; kwargs...)
    return format_citation(Val(style), args...; kwargs...)
end

function format_citation(
    style::Val{:numeric},
    entry,
    citations; # OrderedDict{String,Int64}
    note::Union{Nothing,String}=nothing,
    cite_cmd::Symbol=:cite,
    capitalize::Bool=false,
    starred::Bool=false
)
    if isnothing(note)
        link_text = "[$(citations[entry.id])]"
    else
        link_text = "[$(citations[entry.id]), $note]"
    end
    if cite_cmd ∈ [:citealt, :citealp, :citenum]
        @warn "$cite_cmd citations are not supported in the default styles."
        (cite_cmd == :citealt) && (cite_cmd = :citet)
    end
    if cite_cmd == :citet
        et_al = 1
        if starred
            et_al = 0
        end
        names =
            format_names(entry; names=:lastonly, and=true, et_al, et_al_text="*et al.*") |>
            tex2unicode
        if capitalize
            names = uppercasefirst(names)
        end
        link_text = italicize_md_et_al("$names $link_text")
    end
    return link_text
end


function format_citation(
    style::Val{:authoryear},
    entry,
    citations; # OrderedDict{String,Int64}
    note::Union{Nothing,String}=nothing,
    cite_cmd::Symbol=:cite,
    capitalize::Bool=false,
    starred::Bool=false
)
    et_al = starred ? 0 : 1
    names =
        format_names(entry; names=:lastonly, and=true, et_al, et_al_text="*et al.*") |>
        tex2unicode

    if cite_cmd == :citep
        cite_cmd = :cite
    end

    year = entry.date.year |> tex2unicode
    if !isnothing(note)
        year *= ", $note"
    end

    if cite_cmd ∈ [:citealt, :citealp, :citenum]
        @warn "$cite_cmd citations are not supported in the default styles."
        (cite_cmd == :citealt) && (cite_cmd = :citet)
    end
    if cite_cmd == :citet
        link_text = "$names ($year)"
    else
        link_text = "($names, $year)"
    end

    if capitalize
        link_text = uppercasefirst(link_text)
    end

    link_text = italicize_md_et_al(link_text)

    return link_text

end


function format_citation(
    style::Val{:alpha},
    entry,
    citations; # OrderedDict{String,Int64}
    note::Union{Nothing,String}=nothing,
    cite_cmd::Symbol=:cite,
    capitalize::Bool=false,
    starred::Bool=false
)
    if isnothing(note)
        link_text = "[$(alpha_label(entry))]"
    else
        link_text = "[$(alpha_label(entry)), $note]"
    end
    if cite_cmd ∈ [:citealt, :citealp, :citenum]
        @warn "$cite_cmd citations are not supported in the default styles."
        (cite_cmd == :citealt) && (cite_cmd = :citet)
    end
    if cite_cmd == :citet
        et_al = 1
        if starred
            et_al = 0
        end
        names =
            format_names(entry; names=:lastonly, and=true, et_al, et_al_text="*et al.*") |>
            tex2unicode
        if capitalize
            names = uppercasefirst(names)
        end
        link_text = italicize_md_et_al("$names $link_text")
    end
    return link_text
end


function expand_citation(link::Markdown.Link, meta, page, doc)
    startswith(lowercase(link.url), "@cite") || return false
    cit = CitationLink(link)
    if length(cit.keys) > 1
        error("Multi-citations are not currently supported")
        # For a single key, all we have to do it modify the existing
        # Markdown.Link in-place. For multiple keys, things get much more
        # complicated: we'd have to *replace* the Markdown.Link with a whole
        # tree of new markdown, with multiple links.
    end
    key = cit.keys[1]
    @debug "Expanding citation: $key." cit
    local bib
    try
        bib = doc.plugins[CitationBibliography]
    catch
        push!(doc.internal.errors, :citations)
        @error(
            "You are `using CitationBibligraphy`, but did not pass the plugin to `makedocs`"
        )
        return false
    end
    if haskey(bib.entries, key)
        entry = bib.entries[key]
        @assert entry.id == key
        headers = doc.internal.headers
        if Anchors.exists(headers, key)
            if Anchors.isunique(headers, key)
                # Replace the `@cite` url with a path to the referenced header.
                anchor = Anchors.anchor(headers, key)
                path   = relpath(anchor.file, dirname(page.build))
                if isnothing(cit.link_text)
                    style = isnothing(cit.style) ? bib.style : cit.style
                    # Using the cit.style is an undocumented feature. We only
                    # use it to render citation in a non-default style in the
                    # Gallery in the documentation.
                    link.text = format_citation(
                        style,
                        entry,
                        bib.citations;
                        note=cit.note,
                        cite_cmd=cit.cmd,
                        capitalize=cit.capitalize,
                        starred=cit.starred
                    )
                else
                    # keep original link.text
                end
                link.url = string(path, Anchors.fragment(anchor))
                return true
            else
                push!(doc.internal.errors, :citations)
                @warn "'$key' is not unique in $(Utilities.locrepr(page.source))."
            end
        else
            push!(doc.internal.errors, :citations)
            @warn "reference for '$key' could not be found in $(Utilities.locrepr(page.source))."
        end
    else
        push!(doc.internal.errors, :citations)
        @error("Citation not found in bibliography: $key")
    end
    return false
end

function expand_citation(other, meta, page, doc)
    return true  # Continue to `walk` through element `other`.
end
