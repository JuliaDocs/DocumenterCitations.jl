# To enable proper handling of citation links, we want to process the link as
# plain text (markdown source). In the pipeline, the steps are as follows:
#
# * convert the AST of a citation link in a given page to text via
#  [`ast_linktext`](@ref). At the lowest level, the ast-to-text conversion
#  happens with `Markdown.plain(convert(Markdown.MD, ast))`
# * Create [`CitationLink`](@ref) from that, which is processed in the
#  [`CollectCitations`](@ref) and [`ExpandCitations`](@ref) steps.
#
# For [`ExpandCitations`](@ref):
#
# * The [`CitationLink`](@ref) is transformed by [`format_citation`](@ref)
#   into new markdown (plain) text, which must be a valid in-line markup.
# * That text is converted to a "span" of AST nodes with `Documenter.mdparse`
# and replaces the original citation link node. `Documenter.mdparse` internally
# uses `convert(MarkdownAST.Node, Markdown.parse(text))`.
#
# We also do some round-tripping with the `parse_md_citation_link` (str to ast)
# and `ast_to_str`. These are explicitly used only for log/error messages and
# such, but they use the same low-levels conversions and should thus be
# completely compatible with [`ast_linktext`](@ref) and `Documenter.mdparse`.
#
# **In summary**: to test/understand the roundrip behavior, look at
#
# * [`DocumenterCitations.ast_to_str`](@ref) for ast to text conversion
# * `Documenter.mdparse` for text to ast conversion


# Parse a markdown text citation link into an AST. Used when instantiating
# CitationLink/DirectCitationLink from a string. This is used extensively in
# the documentation and for unit testing, but it is not actually part of the
# pipeline (where we instantiate CitationLinks directly from the AST)
function parse_md_citation_link(str)
    local paragraph
    try
        paragraph = Documenter.mdparse(str; mode=:single)[1]
    catch
        error("Invalid citation: $(repr(str))")
    end
    if length(paragraph.children) != 1
        @error "citation $(repr(str)) must parse into a single MarkdownAST.Link" ast =
            collect(paragraph.children)
        error("Invalid citation: $(repr(str))")
    end
    link = first(paragraph.children)
    if !(link.element isa MarkdownAST.Link)
        @error "citation $(repr(str)) must parse into MarkdownAST.Link" ast = link
        error("Invalid citation: $(repr(str))")
    end
    if !startswith(lowercase(link.element.destination), "@cite")
        @error "citation link $(repr(str))  destination must start exactly with \"@cite\" or one of its variants" ast =
            link
        error("Invalid citation: $(repr(str))")
    end
    return link
end


# Convert a markdown node to plain text (markdown source). Used only for
# showing ASTs in a more readable form in error messages / logging, and not
# used otherwise in the pipeline.
function ast_to_str(node::MarkdownAST.Node)
    if node.element isa MarkdownAST.Document
        document = node
    elseif node.element isa MarkdownAST.AbstractBlock
        document = MarkdownAST.@ast MarkdownAST.Document() do
            MarkdownAST.copy_tree(node)
        end
    else
        @assert node.element isa MarkdownAST.AbstractInline
        document = MarkdownAST.@ast MarkdownAST.Document() do
            MarkdownAST.Paragraph() do
                MarkdownAST.copy_tree(node)
            end
        end
    end
    text = Markdown.plain(convert(Markdown.MD, document))
    return strip(text)
end


# Given a `node` that is a `MarkdownAST.Link` return the link text (as plain
# markdown text). This routine is central to the pipeline, as it controls the
# creation of `CitationLink` instances and thus the text that the various
# `format_*` routines receive.
function ast_linktext(node)
    @assert node.element isa MarkdownAST.Link "node must be a Link, not $(typeof(node.element))"
    no_nested_markdown =
        length(node.children) === 1 &&
        (first_node=first(node.children); first_node.element isa MarkdownAST.Text)
    if no_nested_markdown
        text = first_node.element.text
    else
        document = MarkdownAST.@ast MarkdownAST.Document() do
            MarkdownAST.Paragraph()
        end
        paragraph = first(document.children)
        children = [MarkdownAST.copy_tree(child) for child in node.children]
        # append! without copy_tree would unlink the children
        append!(paragraph.children, children)
        text = Markdown.plain(convert(Markdown.MD, document))
    end
    return strip(text)
end
