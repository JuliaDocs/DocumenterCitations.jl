using Test
using Logging
using QuantumCitations
using QuantumControlTestUtils: QuantumTestLogger
import QuantumCitations: tex2unicode, two_digit_year, alpha_label

@testset "text2unicode" begin
    @test tex2unicode("-- ---") == "– —"
    @test tex2unicode(
        raw"\`{o}\'{o}\^{o}\~{o}\={o}\u{o}\.{o}\\\"{o}\r{a}\H{o}\v{s}\d{u}\c{c}\k{a}\b{b}\~{a}"
    ) == "òóôõōŏȯöåőšụçąḇã"
    @test tex2unicode(raw"\i{}\o{}\O{}\l{}\L{}\i\o\O\l\L") == "ıøØłŁıøØłŁ"
    @test tex2unicode(raw"\t{oo}{testText}\t{az}") == "o͡otestTexta͡z"
    @test tex2unicode(raw"{\o}verline") == "øverline"
    @test tex2unicode(raw"\t{oo}\\\"{\i}{abcdefg}") == "o͡oïabcdefg"
    @test tex2unicode(raw"\overline") == "\\overline"
end

@testset "two_digit_year" begin
    test_logger = QuantumTestLogger()
    with_logger(test_logger) do
        @test two_digit_year("2001--") == "01"
        @test two_digit_year("2000") == "00"
        @test two_digit_year("2000-2020") == "00"
        @test two_digit_year("2010") == "10"
        @test two_digit_year("1984") == "84"
        @test two_digit_year("11") == "11"
        @test two_digit_year("invalid") == "invalid"
    end
end


@testset "alpha_label" begin
    bib = CitationBibliography(joinpath(@__DIR__, "..", "docs", "src", "refs.bib"),)
    @test alpha_label(bib.entries["Tannor2007"]) == "Tan07"
    @test alpha_label(bib.entries["FuerstNJP2014"]) == "FGP14"
    @test alpha_label(bib.entries["ImamogluPRE2015"]) == "IW15"
    @test alpha_label(bib.entries["SciPy"]) == "JOP01"
    @test alpha_label(bib.entries["MATLAB:2014"]) == "MAT14"
end
