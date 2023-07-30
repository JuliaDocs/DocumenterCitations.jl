using Test
using TestingUtilities: @Test  # much better at comparing long strings
using Logging
using OrderedCollections: OrderedDict
using DocumenterCitations
import DocumenterCitations:
    tex2unicode,
    two_digit_year,
    alpha_label,
    format_citation,
    format_bibliography_reference,
    italicize_md_et_al

@testset "text2unicode" begin
    @Test tex2unicode("-- ---") == "– —"
    @Test tex2unicode(
        raw"\`{o}\'{o}\^{o}\~{o}\={o}\u{o}\.{o}\\\"{o}\r{a}\H{o}\v{s}\d{u}\c{c}\k{a}\b{b}\~{a}"
    ) == "òóôõōŏȯöåőšụçąḇã"
    @Test tex2unicode(raw"\i{}\o{}\O{}\l{}\L{}\i\o\O\l\L") == "ıøØłŁıøØłŁ"
    @Test tex2unicode(raw"\t{oo}{testText}\t{az}") == "o͡otestTexta͡z"
    @Test tex2unicode(raw"{\o}verline") == "øverline"
    @Test tex2unicode(raw"\t{oo}\\\"{\i}{abcdefg}") == "o͡oïabcdefg"
    @Test tex2unicode(raw"\overline") == "\\overline"
end

@testset "two_digit_year" begin
    include("test_logger.jl")
    test_logger = _TestLogger()
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
    @test alpha_label(bib.entries["FuerstNJP2014"]) == "FGP+14"
    @test alpha_label(bib.entries["ImamogluPRE2015"]) == "IW15"
    @test alpha_label(bib.entries["SciPy"]) == "JOP+01"  # _is_others
    @test alpha_label(bib.entries["MATLAB:2014"]) == "MAT14"
    @test alpha_label(bib.entries["LapertPRA09"]) == "LTTS09"
    @test alpha_label(bib.entries["GrondPRA2009b"]) == "GvWSH09"
    @test alpha_label(bib.entries["WinckelIP2008"]) == "vWB08"
    @test alpha_label(bib.entries["QCRoadmap"]) == "Anon04"
    @test alpha_label(bib.entries["TedRyd"]) == "CW??"
    @test alpha_label(bib.entries["jax"]) == "BFH+??"
end


@testset "format_citation(:authoryear)" begin
    bib = CitationBibliography(joinpath(@__DIR__, "..", "docs", "src", "refs.bib"),)
    _c = OrderedDict{String,Int64}()
    ctext(key; kwargs...) =
        format_citation(Val(:authoryear), bib.entries[key], _c; kwargs...)
    # Pathological cases only
    @Test ctext("QCRoadmap") == "(Anonymous, 2004)"
    @Test ctext("TedRyd") == "(Corcovilos and Weiss, undated)"
end


@testset "format_bibliography_reference(:numeric)" begin
    bib = CitationBibliography(joinpath(@__DIR__, "..", "docs", "src", "refs.bib"),)
    html(key) = format_bibliography_reference(Val(:numeric), bib.entries[key])
    @Test html("GoerzJPB2011") ==
          "M. H. Goerz, T. Calarco and C. P. Koch. <i>The quantum speed limit of optimal controlled phasegates for trapped neutral atoms</i>. <a href='https://doi.org/10.1088/0953-4075/44/15/154011'>J. Phys. B <b>44</b>, 154011 (2011)</a>, <a href='https://arxiv.org/abs/1103.6050'>arXiv:1103.6050</a>. Special issue on quantum control theory for coherence and information dynamics."
    @Test html("Luc-KoenigEPJD2004") ==
          "E. Luc-Koenig, M. Vatasescu and F. Masnou-Seeuws. <i>Optimizing the photoassociation of cold atoms by use of chirped laser pulses</i>. <a href='https://doi.org/10.1140/epjd/e2004-00161-8'>Eur. Phys. J. D <b>31</b>, 239 (2004)</a>, <a href='https://arxiv.org/abs/physics/0407112'>arXiv:physics/0407112 [physics.atm-clus]</a>."
    @Test html("GoerzNPJQI2017") ==
          "M. H. Goerz, F. Motzoi, K. B. Whaley and C. P. Koch. <i>Charting the circuit QED design landscape using optimal control theory</i>, <a href='https://doi.org/10.1038/s41534-017-0036-0'>npj Quantum Inf <b>3</b>, 37 (2017)</a>."
    @Test html("Wilhelm2003.10132") ==
          "F. K. Wilhelm, S. Kirchhoff, S. Machnes, N. Wittler and D. Sugny. <i>An introduction into optimal control for quantum technologies</i>, <a href='https://doi.org/10.48550/ARXIV.2003.10132'>arXiv:2003.10132 (2020)</a>."
    @Test html("Evans1983") ==
          "L. C. Evans. <a href='https://math.berkeley.edu/~evans/control.course.pdf'><i>An Introduction to Mathematical Optimal Control Theory</i></a> (1983). Lecture Notes, University of California, Berkeley."
    @Test html("Giles2008b") ==
          "M. B. Giles. <a href='https://people.maths.ox.ac.uk/gilesm/files/NA-08-01.pdf'><i>An extended collection of matrix derivative results for forward and reverse mode automatic differentiation</i></a>. Technical Report NA-08-01, Oxford University Computing Laboratory (2008)."
    @Test html("QCRoadmap") ==
          "<a href='http://qist.lanl.gov'><i>Quantum Computation Roadmap</i></a> (2004). Version 2.0; April 2, 2004."
    @Test html("TedRyd") ==
          "T. Corcovilos and D. S. Weiss. <i>Rydberg Calculations</i>. Private communication."
    @Test html("jax") ==
          "J. Bradbury, R. Frostig, P. Hawkins, M. J. Johnson, C. Leary, D. Maclaurin, G. Necula, A. Paszke, J. VanderPlas, S. Wanderman-Milne and Q. Zhang. <a href='https://github.com/google/jax'><i>JAX: composable transformations of Python+NumPy programs</i></a>."
end


@testset "format_bibliography_reference(:authoryear)" begin
    bib = CitationBibliography(joinpath(@__DIR__, "..", "docs", "src", "refs.bib"),)
    html(key) = format_bibliography_reference(Val(:authoryear), bib.entries[key])
    @Test html("GoerzJPB2011") ==
          "Goerz, M. H.; Calarco, T. and Koch, C. P. (2011). <i>The quantum speed limit of optimal controlled phasegates for trapped neutral atoms</i>. <a href='https://doi.org/10.1088/0953-4075/44/15/154011'>J. Phys. B <b>44</b>, 154011</a>, <a href='https://arxiv.org/abs/1103.6050'>arXiv:1103.6050</a>. Special issue on quantum control theory for coherence and information dynamics."
    @Test html("Luc-KoenigEPJD2004") ==
          "Luc-Koenig, E.; Vatasescu, M. and Masnou-Seeuws, F. (2004). <i>Optimizing the photoassociation of cold atoms by use of chirped laser pulses</i>. <a href='https://doi.org/10.1140/epjd/e2004-00161-8'>Eur. Phys. J. D <b>31</b>, 239</a>, <a href='https://arxiv.org/abs/physics/0407112'>arXiv:physics/0407112 [physics.atm-clus]</a>."
    @Test html("GoerzNPJQI2017") ==
          "Goerz, M. H.; Motzoi, F.; Whaley, K. B. and Koch, C. P. (2017). <i>Charting the circuit QED design landscape using optimal control theory</i>, <a href='https://doi.org/10.1038/s41534-017-0036-0'>npj Quantum Inf <b>3</b>, 37</a>."
    @Test html("Wilhelm2003.10132") ==
          "Wilhelm, F. K.; Kirchhoff, S.; Machnes, S.; Wittler, N. and Sugny, D. (2020). <i>An introduction into optimal control for quantum technologies</i>, <a href='https://doi.org/10.48550/ARXIV.2003.10132'>arXiv:2003.10132</a>."
    @Test html("Evans1983") ==
          "Evans, L. C. (1983). <a href='https://math.berkeley.edu/~evans/control.course.pdf'><i>An Introduction to Mathematical Optimal Control Theory</i></a>. Lecture Notes, University of California, Berkeley."
    @Test html("Giles2008b") ==
          "Giles, M. B. (2008). <a href='https://people.maths.ox.ac.uk/gilesm/files/NA-08-01.pdf'><i>An extended collection of matrix derivative results for forward and reverse mode automatic differentiation</i></a>. Technical Report NA-08-01, Oxford University Computing Laboratory."
    @Test html("QCRoadmap") ==
          "— (2004). <a href='http://qist.lanl.gov'><i>Quantum Computation Roadmap</i></a>. Version 2.0; April 2, 2004."
    @Test html("TedRyd") ==
          "Corcovilos, T. and Weiss, D. S. <i>Rydberg Calculations</i>. Private communication."
    @Test html("jax") ==
          "Bradbury, J.; Frostig, R.; Hawkins, P.; Johnson, M. J.; Leary, C.; Maclaurin, D.; Necula, G.; Paszke, A.; VanderPlas, J.; Wanderman-Milne, S. and Zhang, Q. <a href='https://github.com/google/jax'><i>JAX: composable transformations of Python+NumPy programs</i></a>."
end
