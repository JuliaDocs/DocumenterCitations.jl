using Test
using QuantumCitations: parse_bibliography_block

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
