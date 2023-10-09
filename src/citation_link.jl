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


"""
Data structure representing a general (non-direct) citation link.

```julia
cit = CitationLink(link)
```

parses the given `link` string, e.g. `"[GoerzQ2022](@cite)"`.

# Attributes

* `node`: The `MarkdownAST.Node` that `link` parses into
* `keys`: A list of BibTeX keys being cited. e.g.,
  `["BrumerShapiro2003", "BrifNJP2010"]` for the citation
  `"[BrumerShapiro2003,BrifNJP2010; and references therein][@cite]"`
* `cmd`: The citation command, one of `:cite`, `:citet`, `:citep`, or
  (unsupported in the default styles) `:citealt`, `:citealp`, `:citenum`.
  Note that, e.g., `"[Goerz@2022](@Citet*)"` results in `cite_cmd=:citet`
* `note`: A citation note, e.g. "Eq. (1)" in `[GoerzQ2022; Eq. (1)](@cite)`
* `capitalize`: Whether the citation should be formatted to appear at the start
  of a sentence, as indicated by a capitalized `@Cite...` command, e.g.,
  `"[GoerzQ2022](@Citet)"`
* `starred`: Whether the citation should be rendered in "extended" form, i.e.,
  with the full list of authors, as indicated by a `*` in the citation, e.g.,
  `"[Goerz@2022](@Citet*)"`

# See also

* [`DirectCitationLink`](@ref) – data structure for direct citation links of
  the form `[text](@cite key)`.
"""
struct CitationLink
    node::MarkdownAST.Node
    cmd::Symbol
    style::Union{Nothing,Symbol}  # style override (undocumented internal)
    keys::Vector{String}
    note::Union{Nothing,String}
    capitalize::Bool
    starred::Bool
end


function CitationLink(link::MarkdownAST.Node)
    citation_link = read_citation_link(link)
    if citation_link isa CitationLink
        return citation_link
    else
        @error "Invalid CitationLink" link
        error("Link parses to $(typeof(citation_link)), not CitationLink")
    end
end

function CitationLink(link::String)
    return CitationLink(parse_md_citation_link(link))
end

function Base.show(io::IO, c::CitationLink)
    print(io, "CitationLink($(repr(ast_to_str(c.node))))")
end


"""
Data structure representing a direct citation link.

```julia
cit = DirectCitationLink(link)
```

parses the given `link` string of the form `[text](@cite key)`.

# Attributes

* `node`: The `MarkdownAST.Node` that `link` parses into
* `key`: The BibTeX key being cited. Note that unlike [`CitationLink`](@ref), a
  `DirectCitationLink` can only reference a single key

# See also

* [`CitationLink`](@ref) – data structure for non-direct citation links.
"""
struct DirectCitationLink
    node::MarkdownAST.Node  # the original markdown link
    key::String             # bibtex cite keys
end


function DirectCitationLink(node::MarkdownAST.Node)
    citation_link = read_citation_link(node)
    if citation_link isa DirectCitationLink
        return citation_link
    else
        @error "Invalid DirectCitationLink" node
        error("Node parses to $(typeof(citation_link)), not DirectCitationLink")
    end
end

function DirectCitationLink(link::String)
    return DirectCitationLink(parse_md_citation_link(link))
end

function Base.show(io::IO, c::DirectCitationLink)
    print(io, "DirectCitationLink($(repr(ast_to_str(c.node))))")
end


"""
Instantiate [`CitationLink`](@ref) or [`DirectCitationLink`](@ref) from AST.

```julia
read_citation_link(link::MarkdownAST.Node)
```

receives a `MarkdownAST.Link` node that must represent a valid (direct or
non-direct) citation link, and returns either a [`CitationLink`](@ref) instance
or a [`DirectCitationLink`](@ref) instance, depending on what the link text and
link destination are. Throw an error if they the link text or description do
not have the correct syntax.

Uses [`ast_linktext`](@ref) to convert the link text to plain markdown code
before applying regexes to parse it. Also normalizes `*` in citation keys to
`_`.
"""
function read_citation_link(link::MarkdownAST.Node)
    if !(link.element isa MarkdownAST.Link)
        @error "link.element must be a MarkdownAST.Link" link
        error("Invalid markdown for citation link: $(repr(ast_to_str(link)))")
    end
    link_destination = link.element.destination
    if (m_url = match(_RX_CITE_URL, link_destination)) ≢ nothing
        # [GoerzQ2022](@cite)
        cmd = Symbol(lowercase(m_url[:cmd]))
        capitalize = startswith(m_url[:cmd], "C")
        starred = !isnothing(m_url[:starred])
        style = isnothing(m_url[:style]) ? nothing : Symbol(m_url[:style])
        link_text = ast_linktext(link)
        m_text = match(_RX_TEXT_KEYS, link_text)
        if isnothing(m_text)
            #! format: off
            @error "The @cite link text $(repr(link_text)) does not match required regex" ast = link
            error("Invalid citation: $(repr(ast_to_str(link)))")
            #! format: on
        end
        # Since the keys have been round-tripped between markdown and the AST,
        # "_" and "*" are ambiguous ("emphasis") and we normalize to "_". Cf.
        # the normalization in the constructor of `CitationBibliography`.
        keys = String[replace(strip(key), "*" => "_") for key in split(m_text[:keys], ",")]
        note = m_text[:note]
        return CitationLink(link, cmd, style, keys, note, capitalize, starred)
    elseif (m_url = match(_RX_CITE_KEY_URL, link_destination)) ≢ nothing
        # [Semi-AD Paper](@cite GoerzQ2022)
        key = replace(strip(convert(String, m_url[:key])), "*" => "_")
        return DirectCitationLink(link, key)
    else
        #! format: off
        @error "The @cite link destination $(repr(link_destination)) does not match required regex" ast=link
        error("Invalid citation: $(repr(ast_to_str(link)))")
        #! format: on
    end
end
