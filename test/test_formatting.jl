using Test
using TestingUtilities: @Test  # much better at comparing long strings
using OrderedCollections: OrderedDict
using DocumenterCitations
import DocumenterCitations:
    two_digit_year,
    alpha_label,
    get_urls,
    doi_url,
    format_authoryear_bibliography_reference,
    format_names,
    format_citation,
    format_bibliography_reference,
    format_urldate,
    CitationLink,
    _join_bib_parts,
    _strip_md_formatting
using Dates: Dates, @dateformat_str
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
    bib = CitationBibliography(DocumenterCitations.example_bibfile)
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
    bib = CitationBibliography(DocumenterCitations.example_bibfile)
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


@testset "format_urldate" begin

    bib = CitationBibliography(DocumenterCitations.example_bibfile)
    entry = bib.entries["WP_Schroedinger"]

    @Test format_urldate(entry) == "Accessed on Oct 24, 2023"
    @Test format_urldate(entry; accessed_on="", fmt=dateformat"d.m.Y") == "24.10.2023"

    c = IOCapture.capture(rethrow=Union{}) do
        fmt = Dates.DateFormat("SDF ", "english")
        format_urldate(entry; accessed_on="", fmt=fmt)
    end
    @test c.value isa MethodError
    @test contains(
        c.output,
        "Error: Check if fmt=dateformat\"SDF \" is a valid dateformat!"
    )

    bib = CitationBibliography(joinpath(splitext(@__FILE__)[1], "urldate.bib"))

    c = IOCapture.capture(rethrow=Union{}) do
        format_urldate(bib.entries["BrifNJP2010xxx"])
    end
    @test c.value == "Accessed on Oct 24, 2023"
    @test contains(
        c.output,
        "Warning: Entry BrifNJP2010xxx defines an 'urldate' field, but no 'url' field."
    )

    c = IOCapture.capture(rethrow=Union{}) do
        format_urldate(bib.entries["WP_Schroedingerxxx"], accessed_on="accessed ")
    end
    @test c.value == "accessed a few days ago"
    @test contains(
        c.output,
        "Warning: Invalid field urldate = \"a few days ago\". Must be in the format YYYY-MM-DD."
    )

end


@testset "format_names" begin
    bib = CitationBibliography(DocumenterCitations.example_bibfile)
    md(key; kwargs...) = format_names(bib.entries[key]; kwargs...)
    @Test md("SciPy"; names=:lastfirst) ==
          "Jones, E.; Oliphant, T.; Peterson, P. and others"
    @Test md("SciPy"; names=:last) == "E. Jones, T. Oliphant, P. Peterson and others"
    @Test md("SciPy"; names=:lastonly) == "Jones, Oliphant, Peterson and others"
    @Test md("SciPy"; names=:full) ==
          "Eric Jones, Travis Oliphant, Pearu Peterson and others"
    @test_throws ArgumentError md("SciPy"; names=:first)
end


@testset "get_urls" begin
    bib = CitationBibliography(DocumenterCitations.example_bibfile)
    @test get_urls(bib.entries["GoerzSPIEO2021"]) == [
        "https://michaelgoerz.net/research/GoerzSPIEO2021.pdf",
        "https://doi.org/10.1117/12.2587002"
    ]
    @test get_urls(bib.entries["GoerzSPIEO2021"]; skip=1) ==
          ["https://doi.org/10.1117/12.2587002"]
    @test length(get_urls(bib.entries["GoerzSPIEO2021"]; skip=2)) == 0
    @test get_urls(bib.entries["Nolting1997Coulomb"]) ==
          ["https://doi.org/10.1007/978-3-663-14691-9"]
end


@testset "format_bibliography_reference(:numeric)" begin
    bib = CitationBibliography(DocumenterCitations.example_bibfile)
    md(key) = format_bibliography_reference(Val(:numeric), bib.entries[key])
    # Note: the test strings below contain nonbreaking spaces (" " = "\u00A0")
    @Test md("GoerzJPB2011") ==
          "M. H. Goerz, T. Calarco and C. P. Koch. *The quantum speed limit of optimal controlled phasegates for trapped neutral atoms*. [J. Phys. B **44**, 154011](https://doi.org/10.1088/0953-4075/44/15/154011) (2011), [arXiv:1103.6050](https://arxiv.org/abs/1103.6050). Special issue on quantum control theory for coherence and information dynamics."
    @Test md("Luc-KoenigEPJD2004") ==
          "E. Luc-Koenig, M. Vatasescu and F. Masnou-Seeuws. *Optimizing the photoassociation of cold atoms by use of chirped laser pulses*. [Eur. Phys. J. D **31**, 239](https://doi.org/10.1140/epjd/e2004-00161-8) (2004), [arXiv:physics/0407112 [physics.atm-clus]](https://arxiv.org/abs/physics/0407112)."
    @Test md("GoerzNPJQI2017") ==
          "M. H. Goerz, F. Motzoi, K. B. Whaley and C. P. Koch. *Charting the circuit QED design landscape using optimal control theory*, [npj Quantum Inf **3**, 37](https://doi.org/10.1038/s41534-017-0036-0) (2017)."
    @Test md("Wilhelm2003.10132") ==
          "F. K. Wilhelm, S. Kirchhoff, S. Machnes, N. Wittler and D. Sugny. *An introduction into optimal control for quantum technologies*, [arXiv:2003.10132](https://doi.org/10.48550/ARXIV.2003.10132) (2020)."
    @Test md("Evans1983") ==
          "L. C. Evans. [*An Introduction to Mathematical Optimal Control Theory*](https://math.berkeley.edu/~evans/control.course.pdf). Lecture Notes, University of California, Berkeley."
    @Test md("Giles2008b") ==
          "M. B. Giles. [*An extended collection of matrix derivative results for forward and reverse mode automatic differentiation*](https://people.maths.ox.ac.uk/gilesm/files/NA-08-01.pdf). Technical Report NA-08-01 (Oxford University Computing Laboratory, Jan 2008)."
    @Test md("QCRoadmap") ==
          "[*Quantum Computation Roadmap*](http://qist.lanl.gov) (2004). Version 2.0; April 2, 2004."
    @Test md("TedRyd") ==
          "T. Corcovilos and D. S. Weiss. *Rydberg Calculations*. Private communication."
    @Test md("jax") ==
          "J. Bradbury, R. Frostig, P. Hawkins, M. J. Johnson, C. Leary, D. Maclaurin, G. Necula, A. Paszke, J. VanderPlas, S. Wanderman-Milne and Q. Zhang. [*`JAX`: composable transformations of Python+NumPy programs*](https://github.com/google/jax), [`https://numpy.org`](https://numpy.org)."
    @Test md("WP_Schroedinger") ==
          "Wikipedia: [*Schrödinger equation*](https://en.wikipedia.org/wiki/Schrödinger_equation). Accessed on Oct 24, 2023."
    @Test md("SciPy") ==
          "E. Jones, T. Oliphant, P. Peterson and others. [*SciPy: Open source scientific tools for Python*](https://docs.scipy.org/doc/scipy/) (2001–). Project website at [`https://scipy.org`](https://scipy.org)."
    @Test md("BrionPhd2004") ==
          "E. Brion. *Contrôle Quantique et Protection de la Cohérence par effet Zénon, Applications à l'Informatique Quantique*. Ph.D. Thesis, Université Pierre et Marie Curie - Paris VI (2014). [HAL:tel-00007910v2](https://hal.science/tel-00007910v2)."
    @Test md("Tannor2007") ==
          "D. J. Tannor. [*Introduction to Quantum Mechanics: A Time-Dependent Perspective*](https://uscibooks.aip.org/books/introduction-to-quantum-mechanics-a-time-dependent-perspective/) (University Science Books, Sausalito, California, 2007)."
    @Test md("SolaAAMOP2018") ==
          "I. R. Sola, B. Y. Chang, S. A. Malinovskaya and V. S. Malinovsky. [*Quantum Control in Multilevel Systems*](https://doi.org/10.1016/bs.aamop.2018.02.003). In: *Advances In Atomic, Molecular, and Optical Physics*, Vol. 67, edited by E. Arimondo, L. F. DiMauro and S. F. Yelin (Academic Press, 2018); Chapter 3, pp. 151–256."
    @Test md("GoerzSPIEO2021") ==
          "M. H. Goerz, M. A. Kasevich and V. S. Malinovsky. [*Quantum optimal control for atomic fountain interferometry*](https://michaelgoerz.net/research/GoerzSPIEO2021.pdf). In: [*Proc. SPIE 11700, Optical and Quantum Sensing and Precision Metrology*](https://doi.org/10.1117/12.2587002) (2021)."
    @Test md("NielsenChuangCh10QEC") ==
          "M. Nielsen and I. L. Chuang. [*Quantum error-correction*](https://doi.org/10.1017/CBO9780511976667). In: *Quantum Computation and Quantum Information* (Cambridge University Press, 2000); Chapter 10."
    @Test md("Nolting1997Coulomb") ==
          "W. Nolting. In: [*Quantenmechanik*](https://doi.org/10.1007/978-3-663-14691-9), Vol. 5.2 of *Grundkurs Theoretische Physik* (Vieweg & Teubner Verlag, 1997); Chapter 6, p. 100."
    @Test md("AnderssonSGS2014") ==
          "E. Andersson and P. Öhberg (Editors). [*Quantum Information and Coherence*](https://doi.org/10.1007/978-3-319-04063-9). *Scottish Graduate Series* (Springer, 2014). Lecture notes of [SUSSP 67 (2011)](https://sussp67.phys.strath.ac.uk)."
    @Test md("SuominenSGS2014") ==
          "K.-A. Suominen. [*Open Quantum Systems and Decoherence*](https://doi.org/10.1007/978-3-319-04063-9_10). In: *Quantum Information and Coherence*, *Scottish Graduate Series*, edited by E. Andersson and P. Öhberg (Springer, 2014); pp. 247–282. Notes from lecture at [SUSSP 67 (2011)](https://sussp67.phys.strath.ac.uk)."
    @Test md("PaszkeNIPS2019") ==
          "A. Paszke, S. Gross, F. Massa, A. Lerer, J. Bradbury, G. Chanan, T. Killeen, Z. Lin, N. Gimelshein, L. Antiga, A. Desmaison, A. Köpf, E. Yang, Z. DeVito, M. Raison, A. Tejani, S. Chilamkurthy, B. Steiner, L. Fang, J. Bai and S. Chintala. [*PyTorch: An Imperative Style, High-Performance Deep Learning Library*](http://papers.neurips.cc/paper/9015-pytorch-an-imperative-style-high-performance-deep-learning-library.pdf). In: *Proceedings of the 33rd International Conference on Neural Information Processing Systems*, edited by H. M. Wallach, H. Larochelle, A. Beygelzimer, F. d'Alché-Buc, E. A. Fox and R. Garnett (NeurIPS 2019, Vancouver, BC, Canada, Dec 2019); pp. 8024–8035."
    @Test md("Giles2008") ==
          "M. B. Giles. [*Collected Matrix Derivative Results for Forward and Reverse Mode Algorithmic Differentiation*](https://people.maths.ox.ac.uk/gilesm/files/AD2008.pdf). In: [*Advances in Automatic Differentiation*](https://doi.org/10.1007/978-3-540-68942-3_4), Vol. 64 of *Lecture Notes in Computational Science and Engineering*, edited by C. H. Bischof, H. M. Bücker, P. Hovland, U. Naumann and J. Utke (Springer, Berlin, Heidelberg, 2008); pp. 35–44."
end


@testset "format_biliography_reference (preprints)" begin
    bib = CitationBibliography(DocumenterCitations.example_bibfile)
    bib0 = CitationBibliography(joinpath(splitext(@__FILE__)[1], "preprints.bib"))
    merge!(bib.entries, bib0.entries)
    md(key) = format_bibliography_reference(Val(:numeric), bib.entries[key])
    # Note: the test strings below contain nonbreaking spaces (" " = "\u00A0")
    @Test md("LarrouyPRX2020") ==
          "A. Larrouy, S. Patsch, R. Richaud, J.-M. Raimond, M. Brune, C. P. Koch and S. Gleyzes. *Fast Navigation in a Large Hilbert Space Using Quantum Optimal Control*. [Phys. Rev. X **10**, 021058](https://doi.org/10.1103/physrevx.10.021058) (2020). [HAL:hal-02887773](https://hal.science/hal-02887773)."
    @Test md("TuriniciHAL00640217") ==
          "G. Turinici. [*Quantum control*](https://hal.science/hal-00640217). HAL:hal-00640217 (2012)."
    @Test md("BrionPhd2004") ==
          "E. Brion. *Contrôle Quantique et Protection de la Cohérence par effet Zénon, Applications à l'Informatique Quantique*. Ph.D. Thesis, Université Pierre et Marie Curie - Paris VI (2014). [HAL:tel-00007910v2](https://hal.science/tel-00007910v2)."
    @Test md("KatrukhaNC2017") ==
          "E. A. Katrukha, M. Mikhaylova, H. X. van Brakel, P. M. van Bergen en Henegouwen, A. Akhmanova, C. C. Hoogenraad and L. C. Kapitein. *Probing cytoskeletal modulation of passive and active intracellular dynamics using nanobody-functionalized quantum dots*. [Nat. Commun. **8**, 14772](https://doi.org/10.1038/ncomms14772) (2017), [biorXiv:089284](https://www.biorxiv.org/content/10.1101/089284)."
    @Test md("NonStandardPreprint") ==
          "M. Tomza, M. H. Goerz, M. Musiał, R. Moszynski and C. P. Koch. *Optimized production of ultracold ground-state molecules: Stabilization employing potentials with ion-pair character and strong spin-orbit coupling*. [Phys. Rev. A **86**, 043424](https://doi.org/10.1103/PhysRevA.86.043424) (2012), xxx-preprint:1208.4331."
end


@testset "format_biliography_reference (alternative non-articles)" begin
    # Test some alternative / problematic forms of som of the trickier
    # non-article references.

    c = IOCapture.capture() do
        # Suppress Error from Bibliography.jl: Entry JuhlARNMRS2020X is missing
        # the booktitle field(s)"  (we don't care, so we're not testing for it)
        CitationBibliography(joinpath(splitext(@__FILE__)[1], "alternative_non_articles.bib"))
    end
    bib = c.value

    md(style, key) = format_bibliography_reference(style, bib.entries[key])
    numeric = Val(:numeric)
    authoryear = Val(:authoryear)

    @Test md(numeric, "JuhlARNMRS2020X") ==
          "D. W. Juhl, Z. Tošner and T. Vosegaard. [*Versatile NMR simulations using SIMPSON*](https://pure.au.dk/portal/files/230817709/Versatile_NMR_simulations_using_SIMPSON.pdf). Vol. 100 of *Annual Reports on NMR Spectroscopy*, edited by G. A. Webb ([Elsevier, 2020](https://doi.org/10.1016/bs.arnmr.2019.12.001)); Chapter 1, pp. 1–59."
    @Test md(authoryear, "JuhlARNMRS2020X") ==
          "Juhl, D. W.; Tošner, Z. and Vosegaard, T. (2020). [*Versatile NMR simulations using SIMPSON*](https://pure.au.dk/portal/files/230817709/Versatile_NMR_simulations_using_SIMPSON.pdf). Vol. 100 of *Annual Reports on NMR Spectroscopy*, edited by Webb, G. A. ([Elsevier](https://doi.org/10.1016/bs.arnmr.2019.12.001)); Chapter 1, pp. 1–59."
    @Test md(numeric, "Nolting1997CoulombX") ==
          "W. Nolting. In: [*Quantenmechanik*](https://link.springer.com/book/10.1007/978-3-662-44230-2), Vol. 5 no. 2 of *Grundkurs Theoretische Physik* ([Vieweg & Teubner Verlag, 1997](https://doi.org/10.1007/978-3-663-14691-9)); 6th chapter, p. 100."
    @Test md(authoryear, "Nolting1997CoulombX") ==
          "Nolting, W. (1997). In: [*Quantenmechanik*](https://link.springer.com/book/10.1007/978-3-662-44230-2), Vol. 5 no. 2 of *Grundkurs Theoretische Physik* ([Vieweg & Teubner Verlag](https://doi.org/10.1007/978-3-663-14691-9)); 6th chapter, p. 100."
    @Test md(numeric, "Shapiro2012X") ==
          "M. Shapiro and P. Brumer. [*Quantum Control of Molecular Processes*](https://onlinelibrary.wiley.com/doi/book/10.1002/9783527639700). ``2^{nd}`` Ed. (Wiley and Sons, 2012)."
    @Test md(authoryear, "Shapiro2012X") ==
          "Shapiro, M. and Brumer, P. (2012). [*Quantum Control of Molecular Processes*](https://onlinelibrary.wiley.com/doi/book/10.1002/9783527639700). ``2^{nd}`` Ed. (Wiley and Sons)."
    @Test md(numeric, "PercontiSPIE2016") ==
          "P. Perconti, W. C. Alberts, J. Bajaj, J. Schuster and M. Reed. [*Sensors, nano-electronics and photonics for the Army of 2030 and beyond*](https://doi.org/10.1117/12.2217797). In: *Quantum Sensing and Nano Electronics and Photonics XIII*, Vol. 9755 no. 6 of *Proceedings SPIE* (2016)."
    @Test md(authoryear, "PercontiSPIE2016") ==
          "Perconti, P.; Alberts, W. C.; Bajaj, J.; Schuster, J. and Reed, M. (2016). [*Sensors, nano-electronics and photonics for the Army of 2030 and beyond*](https://doi.org/10.1117/12.2217797). In: *Quantum Sensing and Nano Electronics and Photonics XIII*, Vol. 9755 no. 6 of *Proceedings SPIE*."
    @Test md(numeric, "DevoretLH1995") ==
          "M. H. Devoret. [*Quantum fluctuations in electrical circuits*](https://boulderschool.yale.edu/sites/default/files/files/devoret_quantum_fluct_les_houches.pdf). In: *Quantum Fluctuations*, Session LXIII (1995) of *the Les Houches Summer School*, edited by S. Reynaud, E. Giacobino and J. Zinn-Justin (Elsevier, 1997); Chapter 10, p. 353."
    @Test md(authoryear, "DevoretLH1995") ==
          "Devoret, M. H. (1997). [*Quantum fluctuations in electrical circuits*](https://boulderschool.yale.edu/sites/default/files/files/devoret_quantum_fluct_les_houches.pdf). In: *Quantum Fluctuations*, Session LXIII (1995) of *the Les Houches Summer School*, edited by Reynaud, S.; Giacobino, E. and Zinn-Justin, J. (Elsevier); Chapter 10, p. 353."

    c = IOCapture.capture() do
        md(numeric, "Nolting1997CoulombXX")
    end
    @test contains(
        c.output,
        "Warning: Could not link [\"https://doi.org/10.1007/978-3-663-14691-9\"] in \"published in\" information for entry Nolting1997CoulombXX."
    )
    @Test c.value ==
          "W. Nolting. Vol. 5 no. 2 of *Grundkurs Theoretische Physik* ([Vieweg & Teubner Verlag, 1997](https://link.springer.com/book/10.1007/978-3-662-44230-2)); 6th chapter, p. 100."

end

@testset "format_labeled_bibliography_reference(:numeric; article_link_doi_in_title=true)" begin
    bib = CitationBibliography(DocumenterCitations.example_bibfile)
    md(key) = DocumenterCitations.format_labeled_bibliography_reference(
        Val(:numeric),
        bib.entries[key];
        article_link_doi_in_title=true
    )
    # Note: the test strings below contain nonbreaking spaces (" " = "\u00A0")
    @Test md("GoerzJPB2011") ==
          "M. H. Goerz, T. Calarco and C. P. Koch. [*The quantum speed limit of optimal controlled phasegates for trapped neutral atoms*](https://doi.org/10.1088/0953-4075/44/15/154011). J. Phys. B **44**, 154011 (2011), [arXiv:1103.6050](https://arxiv.org/abs/1103.6050). Special issue on quantum control theory for coherence and information dynamics."
    @Test md("Luc-KoenigEPJD2004") ==
          "E. Luc-Koenig, M. Vatasescu and F. Masnou-Seeuws. [*Optimizing the photoassociation of cold atoms by use of chirped laser pulses*](https://doi.org/10.1140/epjd/e2004-00161-8). Eur. Phys. J. D **31**, 239 (2004), [arXiv:physics/0407112 [physics.atm-clus]](https://arxiv.org/abs/physics/0407112)."
    @Test md("GoerzNPJQI2017") ==
          "M. H. Goerz, F. Motzoi, K. B. Whaley and C. P. Koch. [*Charting the circuit QED design landscape using optimal control theory*](https://doi.org/10.1038/s41534-017-0036-0), npj Quantum Inf **3**, 37 (2017)."
    @Test md("Wilhelm2003.10132") ==
          "F. K. Wilhelm, S. Kirchhoff, S. Machnes, N. Wittler and D. Sugny. [*An introduction into optimal control for quantum technologies*](https://doi.org/10.48550/ARXIV.2003.10132), arXiv:2003.10132 (2020)."
    @Test md("Evans1983") ==
          "L. C. Evans. [*An Introduction to Mathematical Optimal Control Theory*](https://math.berkeley.edu/~evans/control.course.pdf). Lecture Notes, University of California, Berkeley."
    @Test md("Giles2008b") ==
          "M. B. Giles. [*An extended collection of matrix derivative results for forward and reverse mode automatic differentiation*](https://people.maths.ox.ac.uk/gilesm/files/NA-08-01.pdf). Technical Report NA-08-01 (Oxford University Computing Laboratory, Jan 2008)."
    @Test md("QCRoadmap") ==
          "[*Quantum Computation Roadmap*](http://qist.lanl.gov) (2004). Version 2.0; April 2, 2004."
    @Test md("TedRyd") ==
          "T. Corcovilos and D. S. Weiss. *Rydberg Calculations*. Private communication."
    @Test md("jax") ==
          "J. Bradbury, R. Frostig, P. Hawkins, M. J. Johnson, C. Leary, D. Maclaurin, G. Necula, A. Paszke, J. VanderPlas, S. Wanderman-Milne and Q. Zhang. [*`JAX`: composable transformations of Python+NumPy programs*](https://github.com/google/jax), [`https://numpy.org`](https://numpy.org)."
    @Test md("WP_Schroedinger") ==
          "Wikipedia: [*Schrödinger equation*](https://en.wikipedia.org/wiki/Schrödinger_equation). Accessed on Oct 24, 2023."
    @Test md("SciPy") ==
          "E. Jones, T. Oliphant, P. Peterson and others. [*SciPy: Open source scientific tools for Python*](https://docs.scipy.org/doc/scipy/) (2001–). Project website at [`https://scipy.org`](https://scipy.org)."
    @Test md("BrionPhd2004") ==
          "E. Brion. *Contrôle Quantique et Protection de la Cohérence par effet Zénon, Applications à l'Informatique Quantique*. Ph.D. Thesis, Université Pierre et Marie Curie - Paris VI (2014). [HAL:tel-00007910v2](https://hal.science/tel-00007910v2)."
    @Test md("Tannor2007") ==
          "D. J. Tannor. [*Introduction to Quantum Mechanics: A Time-Dependent Perspective*](https://uscibooks.aip.org/books/introduction-to-quantum-mechanics-a-time-dependent-perspective/) (University Science Books, Sausalito, California, 2007)."
    @Test md("SolaAAMOP2018") ==
          "I. R. Sola, B. Y. Chang, S. A. Malinovskaya and V. S. Malinovsky. [*Quantum Control in Multilevel Systems*](https://doi.org/10.1016/bs.aamop.2018.02.003). In: *Advances In Atomic, Molecular, and Optical Physics*, Vol. 67, edited by E. Arimondo, L. F. DiMauro and S. F. Yelin (Academic Press, 2018); Chapter 3, pp. 151–256."
    @Test md("GoerzSPIEO2021") ==
          "M. H. Goerz, M. A. Kasevich and V. S. Malinovsky. [*Quantum optimal control for atomic fountain interferometry*](https://michaelgoerz.net/research/GoerzSPIEO2021.pdf). In: [*Proc. SPIE 11700, Optical and Quantum Sensing and Precision Metrology*](https://doi.org/10.1117/12.2587002) (2021)."
    @Test md("NielsenChuangCh10QEC") ==
          "M. Nielsen and I. L. Chuang. [*Quantum error-correction*](https://doi.org/10.1017/CBO9780511976667). In: *Quantum Computation and Quantum Information* (Cambridge University Press, 2000); Chapter 10."
    @Test md("Nolting1997Coulomb") ==
          "W. Nolting. In: [*Quantenmechanik*](https://doi.org/10.1007/978-3-663-14691-9), Vol. 5.2 of *Grundkurs Theoretische Physik* (Vieweg & Teubner Verlag, 1997); Chapter 6, p. 100."
    @Test md("AnderssonSGS2014") ==
          "E. Andersson and P. Öhberg (Editors). [*Quantum Information and Coherence*](https://doi.org/10.1007/978-3-319-04063-9). *Scottish Graduate Series* (Springer, 2014). Lecture notes of [SUSSP 67 (2011)](https://sussp67.phys.strath.ac.uk)."
    @Test md("SuominenSGS2014") ==
          "K.-A. Suominen. [*Open Quantum Systems and Decoherence*](https://doi.org/10.1007/978-3-319-04063-9_10). In: *Quantum Information and Coherence*, *Scottish Graduate Series*, edited by E. Andersson and P. Öhberg (Springer, 2014); pp. 247–282. Notes from lecture at [SUSSP 67 (2011)](https://sussp67.phys.strath.ac.uk)."
    @Test md("PaszkeNIPS2019") ==
          "A. Paszke, S. Gross, F. Massa, A. Lerer, J. Bradbury, G. Chanan, T. Killeen, Z. Lin, N. Gimelshein, L. Antiga, A. Desmaison, A. Köpf, E. Yang, Z. DeVito, M. Raison, A. Tejani, S. Chilamkurthy, B. Steiner, L. Fang, J. Bai and S. Chintala. [*PyTorch: An Imperative Style, High-Performance Deep Learning Library*](http://papers.neurips.cc/paper/9015-pytorch-an-imperative-style-high-performance-deep-learning-library.pdf). In: *Proceedings of the 33rd International Conference on Neural Information Processing Systems*, edited by H. M. Wallach, H. Larochelle, A. Beygelzimer, F. d'Alché-Buc, E. A. Fox and R. Garnett (NeurIPS 2019, Vancouver, BC, Canada, Dec 2019); pp. 8024–8035."
    @Test md("Giles2008") ==
          "M. B. Giles. [*Collected Matrix Derivative Results for Forward and Reverse Mode Algorithmic Differentiation*](https://people.maths.ox.ac.uk/gilesm/files/AD2008.pdf). In: [*Advances in Automatic Differentiation*](https://doi.org/10.1007/978-3-540-68942-3_4), Vol. 64 of *Lecture Notes in Computational Science and Engineering*, edited by C. H. Bischof, H. M. Bücker, P. Hovland, U. Naumann and J. Utke (Springer, Berlin, Heidelberg, 2008); pp. 35–44."
end


@testset "format_bibliography_reference(:authoryear)" begin
    bib = CitationBibliography(DocumenterCitations.example_bibfile)
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
          "Giles, M. B. (Jan 2008). [*An extended collection of matrix derivative results for forward and reverse mode automatic differentiation*](https://people.maths.ox.ac.uk/gilesm/files/NA-08-01.pdf). Technical Report NA-08-01 (Oxford University Computing Laboratory)."
    @Test md("QCRoadmap") ==
          "— (2004). [*Quantum Computation Roadmap*](http://qist.lanl.gov). Version 2.0; April 2, 2004."
    @Test md("TedRyd") ==
          "Corcovilos, T. and Weiss, D. S. *Rydberg Calculations*. Private communication."
    @Test md("jax") ==
          "Bradbury, J.; Frostig, R.; Hawkins, P.; Johnson, M. J.; Leary, C.; Maclaurin, D.; Necula, G.; Paszke, A.; VanderPlas, J.; Wanderman-Milne, S. and Zhang, Q. [*`JAX`: composable transformations of Python+NumPy programs*](https://github.com/google/jax), [`https://numpy.org`](https://numpy.org)."
    @Test md("SciPy") ==
          "Jones, E.; Oliphant, T.; Peterson, P. and others (2001–). [*SciPy: Open source scientific tools for Python*](https://docs.scipy.org/doc/scipy/). Project website at [`https://scipy.org`](https://scipy.org)."
    @Test md("BrionPhd2004") ==
          "Brion, E. (2014). *Contrôle Quantique et Protection de la Cohérence par effet Zénon, Applications à l'Informatique Quantique*. Ph.D. Thesis, Université Pierre et Marie Curie - Paris VI. [HAL:tel-00007910v2](https://hal.science/tel-00007910v2)."
    @Test md("Tannor2007") ==
          "Tannor, D. J. (2007). [*Introduction to Quantum Mechanics: A Time-Dependent Perspective*](https://uscibooks.aip.org/books/introduction-to-quantum-mechanics-a-time-dependent-perspective/) (University Science Books, Sausalito, California)."
    @Test md("SolaAAMOP2018") ==
          "Sola, I. R.; Chang, B. Y.; Malinovskaya, S. A. and Malinovsky, V. S. (2018). [*Quantum Control in Multilevel Systems*](https://doi.org/10.1016/bs.aamop.2018.02.003). In: *Advances In Atomic, Molecular, and Optical Physics*, Vol. 67, edited by Arimondo, E.; DiMauro, L. F. and Yelin, S. F. (Academic Press); Chapter 3, pp. 151–256."
    @Test md("GoerzSPIEO2021") ==
          "Goerz, M. H.; Kasevich, M. A. and Malinovsky, V. S. (2021). [*Quantum optimal control for atomic fountain interferometry*](https://michaelgoerz.net/research/GoerzSPIEO2021.pdf). In: [*Proc. SPIE 11700, Optical and Quantum Sensing and Precision Metrology*](https://doi.org/10.1117/12.2587002)."
    @Test md("NielsenChuangCh10QEC") ==
          "Nielsen, M. and Chuang, I. L. (2000). [*Quantum error-correction*](https://doi.org/10.1017/CBO9780511976667). In: *Quantum Computation and Quantum Information* (Cambridge University Press); Chapter 10."
    @Test md("Nolting1997Coulomb") ==
          "Nolting, W. (1997). In: [*Quantenmechanik*](https://doi.org/10.1007/978-3-663-14691-9), Vol. 5.2 of *Grundkurs Theoretische Physik* (Vieweg & Teubner Verlag); Chapter 6, p. 100."
    @Test md("AnderssonSGS2014") ==
          "Andersson, E. and Öhberg, P. (Editors) (2014). [*Quantum Information and Coherence*](https://doi.org/10.1007/978-3-319-04063-9). *Scottish Graduate Series* (Springer). Lecture notes of [SUSSP 67 (2011)](https://sussp67.phys.strath.ac.uk)."
    @Test md("SuominenSGS2014") ==
          "Suominen, K.-A. (2014). [*Open Quantum Systems and Decoherence*](https://doi.org/10.1007/978-3-319-04063-9_10). In: *Quantum Information and Coherence*, *Scottish Graduate Series*, edited by Andersson, E. and Öhberg, P. (Springer); pp. 247–282. Notes from lecture at [SUSSP 67 (2011)](https://sussp67.phys.strath.ac.uk)."
    @Test md("PaszkeNIPS2019") ==
          "Paszke, A.; Gross, S.; Massa, F.; Lerer, A.; Bradbury, J.; Chanan, G.; Killeen, T.; Lin, Z.; Gimelshein, N.; Antiga, L.; Desmaison, A.; Köpf, A.; Yang, E.; DeVito, Z.; Raison, M.; Tejani, A.; Chilamkurthy, S.; Steiner, B.; Fang, L.; Bai, J. and Chintala, S. (Dec 2019). [*PyTorch: An Imperative Style, High-Performance Deep Learning Library*](http://papers.neurips.cc/paper/9015-pytorch-an-imperative-style-high-performance-deep-learning-library.pdf). In: *Proceedings of the 33rd International Conference on Neural Information Processing Systems*, edited by Wallach, H. M.; Larochelle, H.; Beygelzimer, A.; d'Alché-Buc, F.; Fox, E. A. and Garnett, R. (NeurIPS 2019, Vancouver, BC, Canada); pp. 8024–8035."
    @Test md("Giles2008") ==
          "Giles, M. B. (2008). [*Collected Matrix Derivative Results for Forward and Reverse Mode Algorithmic Differentiation*](https://people.maths.ox.ac.uk/gilesm/files/AD2008.pdf). In: [*Advances in Automatic Differentiation*](https://doi.org/10.1007/978-3-540-68942-3_4), Vol. 64 of *Lecture Notes in Computational Science and Engineering*, edited by Bischof, C. H.; Bücker, H. M.; Hovland, P.; Naumann, U. and Utke, J. (Springer, Berlin, Heidelberg); pp. 35–44."
end


@testset "corporate author" begin

    # https://github.com/JuliaDocs/DocumenterCitations.jl/issues/44

    bib = CitationBibliography(joinpath(splitext(@__FILE__)[1], "corporateauthor.bib"))

    entry = bib.entries["OEIS"]

    name = entry.authors[1]
    @test name.last == "{OEIS Foundation Inc.}"
    @test name.first == ""
    @test name.middle == ""
    @test name.particle == ""

    md(key) = format_bibliography_reference(Val(:numeric), bib.entries[key])
    @test md("OEIS") ==
          "OEIS Foundation Inc. [*The On-Line Encyclopedia of Integer Sequences*](https://oeis.org). Published electronically at https://oeis.org (2023)."

    nbsp = "\u00A0"
    @test md("OEISworkaround") ==
          "OEIS$(nbsp)Foundation$(nbsp)Inc. [*The On-Line Encyclopedia of Integer Sequences*](https://oeis.org). Published electronically at https://oeis.org (2023)."


end


@testset "Handling initial for tex-escaped Ł (#78)" begin

    # https://github.com/JuliaDocs/DocumenterCitations.jl/issues/78

    bib = CitationBibliography(joinpath(splitext(@__FILE__)[1], "issue78.bib"))
    md(key) = format_bibliography_reference(Val(:numeric), bib.entries[key])
    @test md("vaswani2017Attention") ==
          "Ł. Kaiser. *Attention Is All You Need*. In: *Proceedings of the 31st International Conference on Neural Information Processing Systems* (2017)."

end


@testset "More escaped unicode (#85)" begin

    # https://github.com/JuliaDocs/DocumenterCitations.jl/issues/85
    bib = CitationBibliography(joinpath(splitext(@__FILE__)[1], "issue85.bib"))
    md(key) = format_bibliography_reference(Val(:numeric), bib.entries[key])

    @test md("Unlu2024") ==
          "Ç. Ünlü. *More issues with escaped unicode* (2024). Bug Report #85."
    @test md("baumgartner2022") ==
          "M. Baumgartner, C. Rolf, J.-U. Grooß, J. Schneider, T. Schorr, O. Möhler, P. Spichtinger and M. Krämer. [*New investigations on homogeneous ice nucleation: the effects of water activity and water saturation formulations*](https://acp.copernicus.org/articles/22/65/2022/). [Atmospheric Chemistry and Physics **22**, 65–91](https://doi.org/10.5194/acp-22-65-2022) (2022)."
    @test md("Kaul2015") ==
          "C. M. Kaul, J. Teixeira and K. Suzuki. *Sensitivities in large-eddy simulations of mixed-phase Arctic stratocumulus clouds using a simple microphysics approach*. [Monthly Weather Review **143**, 4393–4421](https://doi.org/10.1175/MWR-D-14-00319.1) (2015)."
    @test md("Lehtinen2007") ==
          "K. E. Lehtinen, M. Dal Maso, M. Kulmala and V.-M. Kerminen. *Estimating nucleation rates from apparent particle formation rates and vice versa: Revised formulation of the Kerminen–Kulmala equation*. [Journal of Aerosol Science **38**, 988–994](https://doi.org/10.1016/j.jaerosci.2007.06.009) (2007)."

end


@testset "invalid DOI" begin

    bib = CitationBibliography(joinpath(splitext(@__FILE__)[1], "invalid_doi.bib"))

    c = IOCapture.capture() do
        doi_url(bib.entries["Brif"])
    end
    @test contains(
        c.output,
        "Warning: The DOI field in bibtex entry \"Brif\" should not be a URL."
    )
    @test c.value == "https://doi.org/10.1088/1367-2630/12/7/075008"

    c = IOCapture.capture() do
        doi_url(bib.entries["Shapiro"])
    end
    @test contains(
        c.output,
        "Warning: Invalid DOI \"doi:10.1002/9783527639700\" in bibtex entry \"Shapiro\"."
    )
    @test c.value == "https://doi.org/10.1002/9783527639700"

    c = IOCapture.capture() do
        doi_url(bib.entries["Tannor"])
    end
    @test contains(
        c.output,
        "Warning: Invalid DOI \"0.1007/978-94-011-2642-7_23\" in bibtex entry \"Tannor\"."
    )
    @test c.value == ""

end


@testset "Avoid double-linking of DOI in authoryear style (#87)" begin
    bib = CitationBibliography(joinpath(splitext(@__FILE__)[1], "preprints.bib"))
    b = bib.entries["NonStandardPreprint"]
    md = format_authoryear_bibliography_reference(
        :authoryear,
        b,
        article_link_doi_in_title=true
    )
    @test md !=
          "Tomza, M.; Goerz, M. H.; Musiał, M.; Moszynski, R. and Koch, C. P. (2012). [*Optimized production of ultracold ground-state molecules: Stabilization employing potentials with ion-pair character and strong spin-orbit coupling*](https://doi.org/10.1103/PhysRevA.86.043424). [Phys. Rev. A **86**, 043424](https://doi.org/10.1103/PhysRevA.86.043424), xxx-preprint:1208.4331."
    @Test md ==
          "Tomza, M.; Goerz, M. H.; Musiał, M.; Moszynski, R. and Koch, C. P. (2012). [*Optimized production of ultracold ground-state molecules: Stabilization employing potentials with ion-pair character and strong spin-orbit coupling*](https://doi.org/10.1103/PhysRevA.86.043424). Phys. Rev. A **86**, 043424, xxx-preprint:1208.4331."
end
