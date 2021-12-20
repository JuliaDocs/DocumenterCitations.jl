using DocumenterCitations
using Test


@testset "tex2unicode" begin
    @test DocumenterCitations.tex2unicode("-- ---") == "– —"
    @test DocumenterCitations.tex2unicode(
        raw"\`{o}\'{o}\^{o}\~{o}\={o}\u{o}\.{o}\\\"{o}\r{a}\H{o}\v{s}\d{u}\c{c}\k{a}\b{b}\~{a}") == "òóôõōŏȯöåőšụçąḇã"
    @test DocumenterCitations.tex2unicode(
        raw"\i{}\o{}\O{}\l{}\L{}\i\o\O\l\L") == "ıøØłŁıøØłŁ"
    @test DocumenterCitations.tex2unicode(
        raw"\t{oo}{testText}\t{az}") == "o͡otestTexta͡z"
    @test DocumenterCitations.tex2unicode(
        raw"{\o}verline") == "øverline"
    @test DocumenterCitations.tex2unicode(
        raw"\overline") == "\\overline"
end
