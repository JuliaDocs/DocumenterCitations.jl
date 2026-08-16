"""A place in the documentation where a reference is cited.

# Properties

* `src`: the name of the markdown file containing the citation, relative to
  `doc.user.source`
* `id`: the name of the HTML anchor at the citation, see
  [`CitationSiteNode`](@ref)
* `section`: the title of the section containing the citation, or an empty
  string if the citation is not inside any section

The citation sites for each reference are collected in the `backlinks`
attribute of the internal [`CitationBibliography`](@ref) object, and are
rendered as backlinks at the end of the corresponding entry in a canonical
`@bibliography` block.
"""
struct CitationSite
    src::String
    id::String
    section::String
end


"""Node in `MarkdownAST` that gives an HTML anchor to a citation.

# Properties

* `id`: the name of the anchor, which becomes the `id` attribute of the `<a>`
  tag of the citation link that is the child of the node

The node wraps the link of a single expanded citation, so that the backlinks
in the bibliography can point to the exact place of the citation. It is
transparent in any output format other than HTML.
"""
struct CitationSiteNode <: MarkdownAST.AbstractInline
    id::String
end

MarkdownAST.iscontainer(::CitationSiteNode) = true


function Documenter.HTMLWriter.domify(
    dctx::Documenter.HTMLWriter.DCtx,
    node::Documenter.Node,
    citation_site::CitationSiteNode
)
    @assert node.element === citation_site
    dom = Documenter.HTMLWriter.domify(dctx, node.children)
    for element in dom
        if element isa Documenter.DOM.Node && element.name === :a
            # `Documenter.DOM.Node` is immutable, but its `attributes` are not
            push!(element.attributes, :id => citation_site.id)
            break
        end
    end
    # If there is no link (`droplinks` is set for the search index), the
    # citation is rendered as plain text, without an anchor
    return dom
end


function Documenter.LaTeXWriter.latex(
    lctx::Documenter.LaTeXWriter.Context,
    node::MarkdownAST.Node,
    ::CitationSiteNode
)
    return Documenter.LaTeXWriter.latex(lctx, node.children)
end


function Documenter.MDFlatten.mdflatten(io, node::MarkdownAST.Node, ::CitationSiteNode)
    return Documenter.MDFlatten.mdflatten(io, node.children)
end
