using OrderedCollections: OrderedDict
import DocumenterCitations:
    _alpha_suffix,
    format_citation,
    format_bibliography_label,
    init_bibliography!,
    AlphaStyle,
    CitationBibliography


@testset "alpha suffix" begin
    @test _alpha_suffix(1) == "a"
    @test _alpha_suffix(2) == "b"
    @test _alpha_suffix(25) == "y"
    @test _alpha_suffix(26) == "za"
    @test _alpha_suffix(27) == "zb"
    @test _alpha_suffix(50) == "zy"
    @test _alpha_suffix(51) == "zza"
end


@testset "alpha label disambiguation" begin

    bib = CitationBibliography(joinpath(@__DIR__, "..", "docs", "src", "refs.bib"),)
    _c = OrderedDict{String,Int64}()  # dummy "citations"
    dumb = Val(:alpha)
    smart = AlphaStyle()
    init_bibliography!(smart, bib)

    lbl1 = format_citation(dumb, bib.entries["GraceJPB2007"], _c)
    lbl2 = format_citation(dumb, bib.entries["GraceJMO2007"], _c)
    @test lbl1 == lbl2 == "[GBR+07]"

    lbl1 = format_bibliography_label(dumb, bib.entries["GraceJPB2007"], _c)
    lbl2 = format_bibliography_label(dumb, bib.entries["GraceJMO2007"], _c)
    @test lbl1 == lbl2 == "[GBR+07]"

    lbl1 = format_citation(smart, bib.entries["GraceJPB2007"], _c)
    lbl2 = format_citation(smart, bib.entries["GraceJMO2007"], _c)
    @test lbl1 == "[GBR+07a]"
    @test lbl2 == "[GBR+07b]"

    lbl1 = format_bibliography_label(smart, bib.entries["GraceJPB2007"], _c)
    lbl2 = format_bibliography_label(smart, bib.entries["GraceJMO2007"], _c)
    @test lbl1 == "[GBR+07a]"
    @test lbl2 == "[GBR+07b]"

end
