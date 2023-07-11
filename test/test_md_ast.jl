# Test the behavior of MarkdownAST that we rely on to manipulate citations.
# This is to ensure that MarkdownAST doesn't change its behavior in some
# unexpected way, as well as a documentation of the MarkdownAST features that
# are relevant to us

using Test
using TestingUtilities: @Test  # much better at comparing long strings
using DocumenterCitations
using IOCapture: IOCapture
import Documenter
import MarkdownAST
import Markdown
import AbstractTrees


MD_FULL = raw"""
# Markdown document

Let's just have a couple of pagragraphs with inline elements like *italic* or
**bold**.

We'll also have inline math like ``x^2`` (using the double-backtick syntax
preferred by [Julia](https://docs.julialang.org/en/v1/stdlib/Markdown/#\\LaTeX),
in lieu of `$`)

## Citation

Some citation links [rabiner_tutorial_1989; with *emphasis*](@cite) (with
inline formatting) and [GoerzQ2022](@cite) (without inline formatting).

## Lists

* First item with just plain text

* Second item with *emphasis*

* Third item with `code`

This concludes the file.
"""

MD_MINIMAL = raw"""
Text with [rabiner_tutorial_1989](@cite).
"""


"""Return an AST object from a multiline markdown string."""
function parse_md_page_str(mdsrc)
    # This is how Documenter parses pages, cf. the constructor for the Page
    # object in Documenter.jl `src/documents.jl`
    mdpage = Markdown.parse(mdsrc)
    return convert(MarkdownAST.Node, mdpage)
end


"""
Parse a string containing a markdown link to a single MarkdownAST.Link node.
"""
function parse_link(str)
    paragraph = Documenter.mdparse(str; mode=:single)[1]
    @assert length(paragraph.children) == 1
    link = first(paragraph.children)
    @assert link.element isa MarkdownAST.Link
    return link
end


"""Given a `node` that is a `MarkdownAST.Link` return the link text, converted
to plain text."""
function md_link_textstr(node)
    @assert node.element isa MarkdownAST.Link "node must be a Link, not $(typeof(node.element))"
    no_nested_markdown =
        length(node.children) === 1 &&
        (first_node = first(node.children); first_node.element isa MarkdownAST.Text)
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


"""Return a list of AST nodes representing citation links."""
function find_citation_links(mdast; order=AbstractTrees.PostOrderDFS)
    citelinks = []
    # Cf. collect_citations
    for node in order(mdast)
        if node.element isa MarkdownAST.Link
            if contains(node.element.destination, "@cite")
                push!(citelinks, node)
            end
        end
    end
    return citelinks
end

@testset "parse markdown" begin
    mdast = parse_md_page_str(MD_FULL)
    @test mdast.element == MarkdownAST.Document()
end


@testset "Documenter.mdparse" begin
    minimal_block_ast = MarkdownAST.@ast MarkdownAST.Paragraph() do
        MarkdownAST.Text("Text with ")
        MarkdownAST.Link("@cite", "") do
            MarkdownAST.Text("rabiner")
            MarkdownAST.Emph() do
                MarkdownAST.Text("tutorial")
            end
            MarkdownAST.Text("1989")
        end
        MarkdownAST.Text(".")
    end
    # https://github.com/JuliaDocs/Documenter.jl/issues/2253
    @test Documenter.mdparse(MD_MINIMAL; mode=:single) == [minimal_block_ast]
    @test Documenter.mdparse(MD_MINIMAL; mode=:blocks) == [minimal_block_ast]
    @test Documenter.mdparse(MD_MINIMAL; mode=:span) == [minimal_block_ast.children...]

    @test_throws ArgumentError begin
        IOCapture.capture() do
            Documenter.mdparse(MD_FULL; mode=:single)
        end
        @test contains(
            c.output,
            "requires the Markdown string to parse into a single block"
        )
    end
    full_blocks = Documenter.mdparse(MD_FULL; mode=:blocks)
    @test length(full_blocks) == 8
    @test full_blocks[1].element == MarkdownAST.Heading(1)
    @test full_blocks[2].element == MarkdownAST.Paragraph()
    @test full_blocks[3].element == MarkdownAST.Paragraph()
    @test full_blocks[4].element == MarkdownAST.Heading(2)
    @test full_blocks[5].element == MarkdownAST.Paragraph()
    @test full_blocks[6].element == MarkdownAST.Heading(2)
    @test full_blocks[7].element == MarkdownAST.List(:bullet, false)
    @test full_blocks[8].element == MarkdownAST.Paragraph()
    @test_throws ArgumentError begin
        c = IOCapture.capture() do
            Documenter.mdparse(MD_FULL; mode=:span)
        end
        @test contains(
            c.output,
            "requires the Markdown string to parse into a single block"
        )
    end
end


@testset "md_link_textstr" begin

    link = parse_link("[Julia](https://docs.julialang.org/en/v1/stdlib/Markdown/#\\LaTeX)")
    @test link == MarkdownAST.@ast MarkdownAST.Link(
        "https://docs.julialang.org/en/v1/stdlib/Markdown/#\\LaTeX",
        ""
    ) do
        MarkdownAST.Text("Julia")
    end
    @test md_link_textstr(link) == "Julia"

    link = parse_link("[GoerzQ2022](@cite)")
    @test link.element.destination == "@cite"
    @test first(link.children).element.text == "GoerzQ2022"
    @test md_link_textstr(link) == "GoerzQ2022"

    link = parse_link("[rabiner_tutorial_1989; with *emphasis*](@cite)")
    @test md_link_textstr(link) == "rabiner*tutorial*1989; with *emphasis*"

    # Test that we didn't mutate
    @test link == parse_link("[rabiner_tutorial_1989; with *emphasis*](@cite)")

end


@testset "find_citation_links" begin

    mdast = parse_md_page_str(MD_FULL)
    citelinks = find_citation_links(mdast; order=AbstractTrees.PostOrderDFS)
    @test length(citelinks) == 2
    @test md_link_textstr(citelinks[1]) == "rabiner*tutorial*1989; with *emphasis*"
    @test md_link_textstr(citelinks[2]) == "GoerzQ2022"

    # Test that the order doesn't change the order in which we discover the
    # links. Also ensures that md_link_textstr isn't mutating
    citelinks = find_citation_links(mdast; order=AbstractTrees.PreOrderDFS)
    @test length(citelinks) == 2
    @test md_link_textstr(citelinks[1]) == "rabiner*tutorial*1989; with *emphasis*"
    @test md_link_textstr(citelinks[2]) == "GoerzQ2022"

end


@testset "transform link " begin
    c = IOCapture.capture() do
        mdast = parse_md_page_str(MD_FULL)
        println("====== IN =======")
        println("AS AST:")
        @show mdast
        println("AS TEXT:")
        print(string(convert(Markdown.MD, mdast)))
        println("=== TRANSFORM ===")
        for (i, node) in enumerate(AbstractTrees.PostOrderDFS(mdast))
            println("$i: node.element= $(node.element) [$(length(node.children)) children]")
            if node.element == MarkdownAST.Link("@cite", "")
                new_text = "[citation for `$(md_link_textstr(node))`]"
                println("-> Doing transform to new text=$new_text")
                new_nodes = Documenter.mdparse(new_text; mode=:span)
                for n in new_nodes
                    MarkdownAST.insert_before!(node, n)
                end
                MarkdownAST.unlink!(node)
            end
        end
        println("====== OUT =======")
        println("AS AST:")
        @show mdast
        println("AS TEXT:")
        print(string(convert(Markdown.MD, mdast)))
        println("====== END =======")
    end
    open(joinpath(splitext(@__FILE__)[1], "transform_link_output.txt")) do file
        output = replace(c.output, "\r\n" => "\n")
        expected_output = replace(read(file, String), "\r\n" => "\n")
        @Test output == expected_output
    end
end


nothing
