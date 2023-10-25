using Test
using TestingUtilities: @Test  # much better at comparing long strings
using OrderedCollections: OrderedDict
using DocumenterCitations
import DocumenterCitations:
    two_digit_year,
    alpha_label,
    format_citation,
    format_bibliography_reference,
    CitationLink,
    _join_bib_parts,
    _strip_md_formatting
using IOCapture: IOCapture


@testset "two_digit_year" begin
    c = IOCapture.capture() do
        @test two_digit_year("2001--") == "01"
        @test two_digit_year("2000") == "00"
        @test two_digit_year("2000-2020") == "00"
        @test two_digit_year("2010") == "10"
        @test two_digit_year("1984") == "84"
        @test two_digit_year("11") == "11"
        @test two_digit_year("invalid") == "invalid"
    end
    @test occursin("Invalid year: invalid", c.output)
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
    function ctext(key)
        return format_citation(
            Val(:authoryear),
            CitationLink("[$key](@cite)"),
            bib.entries,
            OrderedDict{String,Int64}()
        )
    end
    @Test ctext("Wilhelm2003.10132") ==
          "([Wilhelm *et al.*, 2020](@cite Wilhelm2003.10132))"
    @Test ctext("QCRoadmap") == "([Anonymous, 2004](@cite QCRoadmap))"
    @Test ctext("TedRyd") == "([Corcovilos and Weiss, undated](@cite TedRyd))"
end


@testset "strip md formatting" begin
    @Test _strip_md_formatting("[arXiv](https://arxiv.org)") == "arXiv"
    @Test _strip_md_formatting("*Title*. [arXiv](https://arxiv.org)") == "Title. arXiv"
    @Test _strip_md_formatting("Text with ``x^2`` math") == "Text with x^2 math"
    @Test _strip_md_formatting("*italics* and **bold**") == "italics and bold"
    c = IOCapture.capture() do
        paragraphs = "Multiple\n\nparagraphs\n\nare\n\nnot allowed"
        @assert _strip_md_formatting(paragraphs) == paragraphs
    end
    @test contains(c.output, "Cannot strip formatting")
end


@testset "join_bib_parts" begin
    @Test _join_bib_parts(["Title", "(2023)"]) == "Title (2023)."
    @Test _join_bib_parts(["[Title](https://www.aps.org)", "(2023)"]) ==
          "[Title](https://www.aps.org) (2023)."
    @Test _join_bib_parts(["Title", "arXiv"]) == "Title, arXiv."
    @Test _join_bib_parts(["[Title](https://www.aps.org)", "arXiv"]) ==
          "[Title](https://www.aps.org), arXiv."
    @Test _join_bib_parts(["Title.", "arXiv"]) == "Title. arXiv."
    @Test _join_bib_parts(["Title.", "[arXiv](https://arxiv.org)"]) ==
          "Title. [arXiv](https://arxiv.org)."
    @Test _join_bib_parts(["Title", "(2023)", "arXiv"]) == "Title (2023), arXiv."
    @Test _join_bib_parts(["Title", "(2023)", "Special issue."]) ==
          "Title (2023). Special issue."
    @Test _join_bib_parts(["Title", "``x^2``"]) == "Title, ``x^2``."
    @Test _join_bib_parts(["Title", "``X^2``"]) == "Title. ``X^2``."
    @Test _join_bib_parts(["*Title*", "``x^2``"]) == "*Title*, ``x^2``."
    @Test _join_bib_parts(["*Title*", "``X^2``"]) == "*Title*. ``X^2``."
    c = IOCapture.capture() do
        paragraphs = "Multiple\n\nparagraphs\n\nare\n\nnot allowed"
        @assert _join_bib_parts(["*Title*", paragraphs]) == "*Title*. $paragraphs."
    end
    @test contains(c.output, "Cannot strip formatting")
end


@testset "format_bibliography_reference(:numeric)" begin
    bib = CitationBibliography(joinpath(@__DIR__, "..", "docs", "src", "refs.bib"),)
    md(key) = format_bibliography_reference(Val(:numeric), bib.entries[key])
    # Note: the test strings below contain nonbreaking spaces (" " = "\u00A0")
    @Test md("GoerzJPB2011") ==
          "M. H. Goerz, T. Calarco and C. P. Koch. *The quantum speed limit of optimal controlled phasegates for trapped neutral atoms*. [J. Phys. B **44**, 154011 (2011)](https://doi.org/10.1088/0953-4075/44/15/154011), [arXiv:1103.6050](https://arxiv.org/abs/1103.6050). Special issue on quantum control theory for coherence and information dynamics."
    @Test md("Luc-KoenigEPJD2004") ==
          "E. Luc-Koenig, M. Vatasescu and F. Masnou-Seeuws. *Optimizing the photoassociation of cold atoms by use of chirped laser pulses*. [Eur. Phys. J. D **31**, 239 (2004)](https://doi.org/10.1140/epjd/e2004-00161-8), [arXiv:physics/0407112 [physics.atm-clus]](https://arxiv.org/abs/physics/0407112)."
    @Test md("GoerzNPJQI2017") ==
          "M. H. Goerz, F. Motzoi, K. B. Whaley and C. P. Koch. *Charting the circuit QED design landscape using optimal control theory*, [npj Quantum Inf **3**, 37 (2017)](https://doi.org/10.1038/s41534-017-0036-0)."
    @Test md("Wilhelm2003.10132") ==
          "F. K. Wilhelm, S. Kirchhoff, S. Machnes, N. Wittler and D. Sugny. *An introduction into optimal control for quantum technologies*, [arXiv:2003.10132 (2020)](https://doi.org/10.48550/ARXIV.2003.10132)."
    @Test md("Evans1983") ==
          "L. C. Evans. [*An Introduction to Mathematical Optimal Control Theory*](https://math.berkeley.edu/~evans/control.course.pdf) (1983). Lecture Notes, University of California, Berkeley."
    @Test md("Giles2008b") ==
          "M. B. Giles. [*An extended collection of matrix derivative results for forward and reverse mode automatic differentiation*](https://people.maths.ox.ac.uk/gilesm/files/NA-08-01.pdf). Technical Report NA-08-01, Oxford University Computing Laboratory (2008)."
    @Test md("QCRoadmap") ==
          "[*Quantum Computation Roadmap*](http://qist.lanl.gov) (2004). Version 2.0; April 2, 2004."
    @Test md("TedRyd") ==
          "T. Corcovilos and D. S. Weiss. *Rydberg Calculations*. Private communication."
    @Test md("jax") ==
          "J. Bradbury, R. Frostig, P. Hawkins, M. J. Johnson, C. Leary, D. Maclaurin, G. Necula, A. Paszke, J. VanderPlas, S. Wanderman-Milne and Q. Zhang. [*`JAX`: composable transformations of Python+NumPy programs*](https://github.com/google/jax), [`https://numpy.org`](https://numpy.org)."
end


@testset "format_biliography_reference (preprints)" begin
    bib = CitationBibliography(joinpath(@__DIR__, "..", "docs", "src", "refs.bib"),)
    bib0 = CitationBibliography(joinpath(splitext(@__FILE__)[1], "preprints.bib"))
    merge!(bib.entries, bib0.entries)
    md(key) = format_bibliography_reference(Val(:numeric), bib.entries[key])
    # Note: the test strings below contain nonbreaking spaces (" " = "\u00A0")
    @Test md("LarrouyPRX2020") ==
          "A. Larrouy, S. Patsch, R. Richaud, J.-M. Raimond, M. Brune, C. P. Koch and S. Gleyzes. *Fast Navigation in a Large Hilbert Space Using Quantum Optimal Control*. [Phys. Rev. X **10**, 021058 (2020)](https://doi.org/10.1103/physrevx.10.021058). [HAL:hal-02887773](https://hal.science/hal-02887773)."
    @Test md("TuriniciHAL00640217") ==
          "G. Turinici. [*Quantum control*](https://hal.science/hal-00640217). HAL:hal-00640217 (2012)."
    @Test md("BrionPhd2004") ==
          "E. Brion. *Contrôle Quantique et Protection de la Cohérence par effet Zénon, Applications à l'Informatique Quantique*. Phd thesis, Université Pierre et Marie Curie - Paris VI (2014). [HAL:tel-00007910v2](https://hal.science/tel-00007910v2)."
    @Test md("KatrukhaNC2017") ==
          "E. A. Katrukha, M. Mikhaylova, H. X. van Brakel, P. M. van Bergen en Henegouwen, A. Akhmanova, C. C. Hoogenraad and L. C. Kapitein. *Probing cytoskeletal modulation of passive and active intracellular dynamics using nanobody-functionalized quantum dots*. [Nat. Commun. **8**, 14772 (2017)](https://doi.org/10.1038/ncomms14772), [biorXiv:089284](https://www.biorxiv.org/content/10.1101/089284)."
    @Test md("NonStandardPreprint") ==
          "M. Tomza, M. H. Goerz, M. Musiał, R. Moszynski and C. P. Koch. *Optimized production of ultracold ground-state molecules: Stabilization employing potentials with ion-pair character and strong spin-orbit coupling*. [Phys. Rev. A **86**, 043424 (2012)](https://doi.org/10.1103/PhysRevA.86.043424), xxx-preprint:1208.4331."
end


@testset "format_bibliography_reference(:authoryear)" begin
    bib = CitationBibliography(joinpath(@__DIR__, "..", "docs", "src", "refs.bib"),)
    md(key) = format_bibliography_reference(Val(:authoryear), bib.entries[key])
    # Note: the test strings below contain nonbreaking spaces (" " = "\u00A0")
    @Test md("GoerzJPB2011") ==
          "Goerz, M. H.; Calarco, T. and Koch, C. P. (2011). *The quantum speed limit of optimal controlled phasegates for trapped neutral atoms*. [J. Phys. B **44**, 154011](https://doi.org/10.1088/0953-4075/44/15/154011), [arXiv:1103.6050](https://arxiv.org/abs/1103.6050). Special issue on quantum control theory for coherence and information dynamics."
    @Test md("Luc-KoenigEPJD2004") ==
          "Luc-Koenig, E.; Vatasescu, M. and Masnou-Seeuws, F. (2004). *Optimizing the photoassociation of cold atoms by use of chirped laser pulses*. [Eur. Phys. J. D **31**, 239](https://doi.org/10.1140/epjd/e2004-00161-8), [arXiv:physics/0407112 [physics.atm-clus]](https://arxiv.org/abs/physics/0407112)."
    @Test md("GoerzNPJQI2017") ==
          "Goerz, M. H.; Motzoi, F.; Whaley, K. B. and Koch, C. P. (2017). *Charting the circuit QED design landscape using optimal control theory*, [npj Quantum Inf **3**, 37](https://doi.org/10.1038/s41534-017-0036-0)."
    @Test md("Wilhelm2003.10132") ==
          "Wilhelm, F. K.; Kirchhoff, S.; Machnes, S.; Wittler, N. and Sugny, D. (2020). *An introduction into optimal control for quantum technologies*, [arXiv:2003.10132](https://doi.org/10.48550/ARXIV.2003.10132)."
    @Test md("Evans1983") ==
          "Evans, L. C. (1983). [*An Introduction to Mathematical Optimal Control Theory*](https://math.berkeley.edu/~evans/control.course.pdf). Lecture Notes, University of California, Berkeley."
    @Test md("Giles2008b") ==
          "Giles, M. B. (2008). [*An extended collection of matrix derivative results for forward and reverse mode automatic differentiation*](https://people.maths.ox.ac.uk/gilesm/files/NA-08-01.pdf). Technical Report NA-08-01, Oxford University Computing Laboratory."
    @Test md("QCRoadmap") ==
          "— (2004). [*Quantum Computation Roadmap*](http://qist.lanl.gov). Version 2.0; April 2, 2004."
    @Test md("TedRyd") ==
          "Corcovilos, T. and Weiss, D. S. *Rydberg Calculations*. Private communication."
    @Test md("jax") ==
          "Bradbury, J.; Frostig, R.; Hawkins, P.; Johnson, M. J.; Leary, C.; Maclaurin, D.; Necula, G.; Paszke, A.; VanderPlas, J.; Wanderman-Milne, S. and Zhang, Q. [*`JAX`: composable transformations of Python+NumPy programs*](https://github.com/google/jax), [`https://numpy.org`](https://numpy.org)."
end
