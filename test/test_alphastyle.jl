using Test
using TestingUtilities: @Test  # much better at comparing strings
using OrderedCollections: OrderedDict
using IOCapture: IOCapture
import DocumenterCitations:
    _alpha_suffix,
    format_citation,
    format_bibliography_label,
    init_bibliography!,
    AlphaStyle,
    CitationBibliography,
    CitationLink


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

    cit(key) = CitationLink("[$key](@cite)")
    entry(key) = bib.entries[key]

    lbl1 = format_bibliography_label(dumb, entry("GraceJPB2007"), _c)
    @Test lbl1 == "[GBR+07]"
    # The dumb style can general labels without any any initalization, while
    # the smart style *requires* that init_bibliography! was called.
    c = IOCapture.capture(rethrow=InterruptException) do
        format_bibliography_label(smart, entry("GraceJPB2007"), _c)
    end
    @test contains(
        c.output,
        "Error: No AlphaStyle label for GraceJPB2007. Was `init_bibliography!` called?"
    )
    @test c.value == "[?]"
    @test contains(c.output, " Was `init_bibliography!` called?")

    init_bibliography!(smart, bib)

    l1 = format_citation(dumb, cit("GraceJPB2007"), bib.entries, _c)
    l2 = format_citation(dumb, cit("GraceJMO2007"), bib.entries, _c)
    @Test l1 == "[[GBR+07](@cite GraceJPB2007)]"
    @Test l2 == "[[GBR+07](@cite GraceJMO2007)]"

    lbl1 = format_bibliography_label(dumb, entry("GraceJPB2007"), _c)
    lbl2 = format_bibliography_label(dumb, entry("GraceJMO2007"), _c)
    @test lbl1 == lbl2 == "[GBR+07]"

    l1 = format_citation(smart, cit("GraceJPB2007"), bib.entries, _c)
    l2 = format_citation(smart, cit("GraceJMO2007"), bib.entries, _c)
    @Test l1 == "[[GBR+07a](@cite GraceJPB2007)]"
    @Test l2 == "[[GBR+07b](@cite GraceJMO2007)]"

    lbl1 = format_bibliography_label(smart, entry("GraceJPB2007"), _c)
    lbl2 = format_bibliography_label(smart, entry("GraceJMO2007"), _c)
    @Test lbl1 == "[GBR+07a]"
    @Test lbl2 == "[GBR+07b]"

end
