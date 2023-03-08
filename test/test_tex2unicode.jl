using Test
import QuantumCitations

@testset "text2unicode" begin
    @test QuantumCitations.tex2unicode("-- ---") == "– —"
    @test QuantumCitations.tex2unicode(
        raw"\`{o}\'{o}\^{o}\~{o}\={o}\u{o}\.{o}\\\"{o}\r{a}\H{o}\v{s}\d{u}\c{c}\k{a}\b{b}\~{a}"
    ) == "òóôõōŏȯöåőšụçąḇã"
    @test QuantumCitations.tex2unicode(raw"\i{}\o{}\O{}\l{}\L{}\i\o\O\l\L") == "ıøØłŁıøØłŁ"
    @test QuantumCitations.tex2unicode(raw"\t{oo}{testText}\t{az}") == "o͡otestTexta͡z"
    @test QuantumCitations.tex2unicode(raw"{\o}verline") == "øverline"
    @test QuantumCitations.tex2unicode(raw"\t{oo}\\\"{\i}{abcdefg}") == "o͡oïabcdefg"
    @test QuantumCitations.tex2unicode(raw"\overline") == "\\overline"
end
