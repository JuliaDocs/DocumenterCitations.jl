using Test
using DocumenterCitations: CitationLink
using Markdown
import MarkdownAST
using IOCapture: IOCapture


function _link(text::String)
    md = Markdown.parse(text)
    ast = convert(MarkdownAST.Node, md)
    link = first(first(ast.children).children)
    @assert link.element isa MarkdownAST.Link
    return link
end

function _CitationLink(text::String)
    CitationLink(_link(text))
end


@testset "parse_standard_citation_link" begin

    cit = _CitationLink("[GoerzQ2022](@cite)")
    @test cit.cmd == :cite
    @test cit.style ≡ nothing
    @test cit.keys == ["GoerzQ2022"]
    @test cit.note ≡ nothing
    @test cit.capitalize ≡ false
    @test cit.starred ≡ false
    @test cit.link_text ≡ nothing

    cit = _CitationLink("[GoerzQ2022](@citet)")
    @test cit.cmd == :citet

    cit = _CitationLink("[GoerzQ2022](@citep)")
    @test cit.cmd == :citep

    cit = _CitationLink("[GoerzQ2022](@Citet)")
    @test cit.cmd == :citet
    @test cit.capitalize ≡ true

    cit = _CitationLink("[GoerzQ2022](@cite*)")
    @test cit.cmd == :cite
    @test cit.starred ≡ true

    cit = _CitationLink("[GoerzQ2022](@citet*)")
    @test cit.cmd == :citet
    @test cit.starred ≡ true

    cit = _CitationLink("[GoerzQ2022](@cite%authoryear%)")
    # This is an undocumented feature (on purpose)
    @test cit.cmd == :cite
    @test cit.style ≡ :authoryear

    cit = _CitationLink("[GoerzQ2022; Eq. (1)](@cite)")
    @test cit.cmd == :cite
    @test cit.style ≡ nothing
    @test cit.keys == ["GoerzQ2022"]
    @test cit.note ≡ "Eq. (1)"

    cit = _CitationLink("[GoerzQ2022;   Eq. (1)](@cite)")
    @test cit.note ≡ "Eq. (1)"

    cit = _CitationLink("[GoerzQ2022,CarrascoPRA2022,GoerzA2023](@cite)")
    @test cit.keys == ["GoerzQ2022", "CarrascoPRA2022", "GoerzA2023"]

    cit = _CitationLink("[GoerzQ2022, CarrascoPRA2022, GoerzA2023](@cite)")
    @test cit.keys == ["GoerzQ2022", "CarrascoPRA2022", "GoerzA2023"]

    cit = _CitationLink(
        "[GoerzQ2022,CarrascoPRA2022,GoerzA2023; and references therein](@cite)"
    )
    @test cit.keys == ["GoerzQ2022", "CarrascoPRA2022", "GoerzA2023"]
    @test cit.note ≡ "and references therein"

end

@testset "invalid_standard_citation_link" begin
    c = IOCapture.capture() do
        @test_throws ErrorException begin
            cit = _CitationLink("[GoerzQ2022](@citenocommand)")
            # not a citecommand
        end
        @test_throws ErrorException begin
            cit = _CitationLink("[GoerzQ2022]( @cite )")
            # can't have spaces
        end
        @test_throws ErrorException begin
            cit = _CitationLink("[see GoerzQ2022](@cite)")
            # can't have text before keys (we might allow this in the future)
        end
        @test_throws ErrorException begin
            cit = _CitationLink("[GoerzQ2022](@CITE)")
            # wrong capitalization
        end
    end
    msgs = [
        "Error: The @cite link destination does not match required regex: @citenocommand",
        "Error: The @cite link destination does not match required regex:  @cite ",
        "Error: Invalid bibtex key: see GoerzQ2022",
        "Error: The @cite link destination does not match required regex: @CITE"
    ]
    for msg in msgs
        @test occursin(msg, c.output)
    end
end


@testset "parse_custom_text_citation_link" begin

    cit = _CitationLink("[Semi-AD paper](@cite GoerzQ2022)")
    @test cit.cmd == :cite
    @test cit.style ≡ nothing
    @test cit.keys == ["GoerzQ2022"]
    @test cit.note ≡ nothing
    @test cit.link_text == MarkdownAST.@ast MarkdownAST.Link("@cite GoerzQ2022", "") do
        MarkdownAST.Text("Semi-AD paper")
    end

    cit = _CitationLink("[*Semi*-AD paper](@cite GoerzQ2022)")
    @test cit.cmd == :cite
    @test cit.style ≡ nothing
    @test cit.keys == ["GoerzQ2022"]
    @test cit.note ≡ nothing
    @test cit.link_text == MarkdownAST.@ast MarkdownAST.Link("@cite GoerzQ2022", "") do
        MarkdownAST.Emph() do
            MarkdownAST.Text("Semi")
        end
        MarkdownAST.Text("-AD paper")
    end

end

@testset "invalid_custom_text_citation_link" begin
    c = IOCapture.capture() do
        @test_throws ErrorException begin
            _CitationLink("[Semi-AD paper](@citet GoerzQ2022)")
            # only @cite is allowed
        end
        @test_throws ErrorException begin
            _CitationLink("[first two papers](@cite BrifNJP2010, GoerzQ2022)")
            # there has to be a single link target
        end
    end
    msgs = [
        "Error: The @cite link destination does not match required regex: @citet GoerzQ2022",
        "Error: The @cite link destination does not match required regex: @cite BrifNJP2010, GoerzQ2022",
    ]
    for msg in msgs
        @test occursin(msg, c.output)
    end
end
