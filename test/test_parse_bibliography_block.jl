using Test
using DocumenterCitations: parse_bibliography_block
using IOCapture: IOCapture

@testset "parse_bibliography_block" begin

    block = raw"""
    Pages = ["index.md", "references.md"]
    Canonical = true
    *
    GoerzPRA2010
    """
    fields, lines = parse_bibliography_block(block, nothing, nothing)
    @test fields[:Canonical] == true
    @test fields[:Pages] == ["index.md", "references.md"]
    @test lines == ["*", "GoerzPRA2010"]

    block = raw"""
    Pages = [
        "index.md",
        "references.md"
    ]
    Canonical = true

    GoerzPRA2010
    """
    fields, lines = parse_bibliography_block(block, nothing, nothing)
    @test fields[:Canonical] == true
    @test fields[:Pages] == ["index.md", "references.md"]
    @test lines == ["GoerzPRA2010"]

    block = raw"""
    Canonical =  false
    *
    """
    fields, lines = parse_bibliography_block(block, nothing, nothing)
    @test fields[:Canonical] == false
    @test lines == ["*"]

    block = raw"""
    """
    fields, lines = parse_bibliography_block(block, nothing, nothing)
    @test fields[:Canonical] == true
    @test lines == []

end


@testset "invalid bibliography blocks" begin

    block = raw"""
    Pages = "index.md"  # not a list
    Canonical = false
    """
    c = IOCapture.capture() do
        fields, lines = parse_bibliography_block(block, nothing, nothing)
        @test fields[:Canonical] == false
        @test fields[:Pages] == []
        @test lines == []
    end
    @test contains(
        c.output,
        "Warning: The field `Pages` in N/A must evaluate to a list of strings. Setting invalid `Pages = \"index.md\"` to `Pages = []`"
    )

    block = raw"""
    Pages = [1, 2]  # not a list of strings
    """
    c = IOCapture.capture() do
        fields, lines = parse_bibliography_block(block, nothing, nothing)
        @test fields[:Canonical] == true
        @test fields[:Pages] == ["1", "2"]
        @test lines == []
    end
    @test contains(
        c.output,
        "Warning: The value `1` in N/A is not a string. Replacing with \"1\""
    )
    @test contains(
        c.output,
        "Warning: The value `2` in N/A is not a string. Replacing with \"2\""
    )

    block = raw"""
    Pages = ["index.md"]
    Canonical = "true"  # not a Bool
    """
    c = IOCapture.capture() do
        fields, lines = parse_bibliography_block(block, nothing, nothing)
        @test fields[:Canonical] == false
        @test fields[:Pages] == ["index.md"]
        @test lines == []
    end
    @test contains(
        c.output,
        "Warning: The field `Canonical` in N/A must evaluate to a boolean. Setting invalid `Canonical=\"true\"` to `Canonical=false`"
    )

end
