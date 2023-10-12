using Test
using DocumenterCitations: CitationLink, DirectCitationLink
using Markdown
import MarkdownAST
using IOCapture: IOCapture


@testset "parse_standard_citation_link" begin

    cit = CitationLink("[GoerzQ2022](@cite)")
    @test cit.cmd == :cite
    @test cit.style ≡ nothing
    @test cit.keys == ["GoerzQ2022"]
    @test cit.note ≡ nothing
    @test cit.capitalize ≡ false
    @test cit.starred ≡ false

    cit = CitationLink("[GoerzQ2022](@citet)")
    @test cit.cmd == :citet

    cit = CitationLink("[GoerzQ2022](@citep)")
    @test cit.cmd == :citep

    cit = CitationLink("[GoerzQ2022](@Citet)")
    @test cit.cmd == :citet
    @test cit.capitalize ≡ true

    cit = CitationLink("[GoerzQ2022](@cite*)")
    @test cit.cmd == :cite
    @test cit.starred ≡ true

    cit = CitationLink("[GoerzQ2022](@citet*)")
    @test cit.cmd == :citet
    @test cit.starred ≡ true

    cit = CitationLink("[GoerzQ2022](@cite%authoryear%)")
    # This is an undocumented feature (on purpose)
    @test cit.cmd == :cite
    @test cit.style ≡ :authoryear

    cit = CitationLink("[GoerzQ2022; Eq.\u00A0(1)](@cite)")
    @test cit.cmd == :cite
    @test cit.style ≡ nothing
    @test cit.keys == ["GoerzQ2022"]
    @test cit.note ≡ "Eq.\u00A0(1)"

    cit = CitationLink("[GoerzQ2022;   Eq.\u00A0(1)](@cite)")
    @test cit.note ≡ "Eq.\u00A0(1)"

    cit = CitationLink("[GoerzQ2022,CarrascoPRA2022,GoerzA2023](@cite)")
    @test cit.keys == ["GoerzQ2022", "CarrascoPRA2022", "GoerzA2023"]

    cit = CitationLink("[GoerzQ2022, CarrascoPRA2022, GoerzA2023](@cite)")
    @test cit.keys == ["GoerzQ2022", "CarrascoPRA2022", "GoerzA2023"]

    cit = CitationLink(
        "[GoerzQ2022,CarrascoPRA2022,GoerzA2023; and references therein](@cite)"
    )
    @test cit.keys == ["GoerzQ2022", "CarrascoPRA2022", "GoerzA2023"]
    @test cit.note ≡ "and references therein"

end

@testset "invalid_citation_link" begin
    c = IOCapture.capture() do
        @test_throws ErrorException begin
            cit = CitationLink("[GoerzQ2022](@citenocommand)")
            # not a citecommand
        end
        @test_throws ErrorException begin
            cit = CitationLink("[GoerzQ2022]( @cite )")
            # can't have spaces
        end
        @test_throws ErrorException begin
            cit = CitationLink("[see GoerzQ2022](@cite)")
            # can't have text before keys
        end
        @test_throws ErrorException begin
            cit = CitationLink("[GoerzQ2022](@CITE)")
            # wrong capitalization
        end
        @test_throws ErrorException begin
            cit = CitationLink("not a link")
            # must be a link
        end
        @test_throws ErrorException begin
            cit = CitationLink("See [GoerzQ2022](@cite)")
            # extra "See "
        end
        @test_throws ErrorException begin
            cit = CitationLink("# Title\n\nThis is a paragraph\n")
            # Can't be parsed as single node
        end
        @test_throws ErrorException begin
            cit = CitationLink("[text](@cite key)")
            # DirectCitationLink
        end
    end
    msgs = [
        "Error: The @cite link destination \"@citenocommand\" does not match required regex",
        "Error: citation link \"[GoerzQ2022]( @cite )\"  destination must start exactly with \"@cite\" or one of its variants",
        "Error: The @cite link text \"see GoerzQ2022\" does not match required regex",
        "Error: The @cite link destination \"@CITE\" does not match required regex",
        "Error: citation \"not a link\" must parse into MarkdownAST.Link",
        "Error: citation \"See [GoerzQ2022](@cite)\" must parse into a single MarkdownAST.Link",
        "Error: mode == :single requires the Markdown string to parse into a single block",
    ]
    for msg in msgs
        success = @test occursin(msg, c.output)
        if success isa Test.Fail
            @error "message not in output" msg
        end
    end
end


@testset "parse_direct_citation_link" begin

    cit = DirectCitationLink("[Semi-AD paper](@cite GoerzQ2022)")
    @test cit.key == "GoerzQ2022"
    @test cit.node == MarkdownAST.@ast MarkdownAST.Link("@cite GoerzQ2022", "") do
        MarkdownAST.Text("Semi-AD paper")
    end

    cit = DirectCitationLink("[*Semi*-AD paper](@cite GoerzQ2022)")
    @test cit.key == "GoerzQ2022"
    @test cit.node == MarkdownAST.@ast MarkdownAST.Link("@cite GoerzQ2022", "") do
        MarkdownAST.Emph() do
            MarkdownAST.Text("Semi")
        end
        MarkdownAST.Text("-AD paper")
    end

end

@testset "invalid_direct_text_citation_link" begin
    c = IOCapture.capture() do
        @test_throws ErrorException begin
            DirectCitationLink("[Semi-AD paper](@citet GoerzQ2022)")
            # only @cite is allowed
        end
        @test_throws ErrorException begin
            DirectCitationLink("[first two papers](@cite BrifNJP2010, GoerzQ2022)")
            # there has to be a single link target
        end
    end
    msgs = [
        "Error: The @cite link destination \"@citet GoerzQ2022\" does not match required regex",
        "Error: The @cite link destination \"@cite BrifNJP2010, GoerzQ2022\" does not match required regex",
    ]
    for msg in msgs
        success = @test occursin(msg, c.output)
        if success isa Test.Fail
            @error "message not in output" msg
        end
    end
end
