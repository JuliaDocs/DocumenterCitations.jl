# Test the behavior of MarkdownAST that we rely on to manipulate citations.
# This is to ensure that MarkdownAST doesn't change its behavior in some
# unexpected way, as well as a documentation of the MarkdownAST features that
# are relevant to us


using Test
using TestingUtilities: @Test  # much better at comparing long strings
using DocumenterCitations
using DocumenterCitations: ast_linktext, ast_to_str
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

* First item with just plain text...

  And a second paragraph (we don't want this to normalize to a "tight" list)

* Second item with *emphasis*

* Third item with `code`

This concludes the file.
"""

MD_MINIMAL = raw"""
Text with [rabiner_tutorial_1989](@cite).
"""


"""Return a `MarkdownAST.Document` node from a multiline markdown string.

This is how Documenter parses pages, cf. the constructor for the `Page`
object in Documenter.jl `src/documents.jl`.

It is also the basis of `Documenter.mdparse`, which only further goes into the
children of the `Document` node to return the ones selected depending on the
`mode` parameter.
"""
function parse_md_page_str(mdsrc)
    mdpage = Markdown.parse(mdsrc)
    return convert(MarkdownAST.Node, mdpage)
end



@testset "parse_md_page_str" begin

    mdast = parse_md_page_str(MD_FULL)
    @test mdast.element == MarkdownAST.Document()

    # ensure that the file can be round-tripped without loss (this does not
    # mean that the markdown code isn't "normalized", just that we get a stable
    # AST and a stable text after the first roundtrip)

    mdast2 = parse_md_page_str(MD_FULL)
    @Test mdast2 == mdast

    text = ast_to_str(mdast)
    mdast3 = parse_md_page_str(text)
    @Test mdast3 == mdast

    text2 = ast_to_str(mdast3)
    @Test text2 == text

end


@testset "Documenter.mdparse" begin
    # Test the function that is used in the pipeline to convert between
    # markdown code plain text and AST objects.
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
        c = IOCapture.capture() do
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
