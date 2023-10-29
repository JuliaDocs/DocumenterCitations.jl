using Pkg
using DocumenterCitations
using Documenter
using Test

include("run_makedocs.jl")
include("file_content.jl")

CUSTOM1 = joinpath(@__DIR__, "..", "docs", "custom_styles", "enumauthoryear.jl")
CUSTOM2 = joinpath(@__DIR__, "..", "docs", "custom_styles", "keylabels.jl")

include(CUSTOM1)
include(CUSTOM2)


const Documenter_version =
    Pkg.dependencies()[Base.UUID("e30172f5-a6a5-5a46-863b-614d45cd2de4")].version


function dummy_lctx()
    doc = Documenter.Document(; remotes=nothing)
    buffer = IOBuffer()
    return Documenter.LaTeXWriter.Context(buffer, doc)
end


function md_to_latex(mdstr)
    lctx = dummy_lctx()
    ast = Documenter.mdparse(mdstr; mode=:single)[1]
    Documenter.LaTeXWriter.latex(lctx, ast.children)
    return String(take!(lctx.io))
end


@testset "Invalid BibliographyNode" begin
    exc = ArgumentError("`list_style` must be one of `:dl`, `:ul`, or `:ol`, not `:bl`")
    @test_throws exc begin
        DocumenterCitations.BibliographyNode(
            :bl,  # :bl (bullet list) doesn't exist, should be :ul
            true,
            DocumenterCitations.BibliographyItem[]
        )
    end
end


@testset "QCRoadmap" begin
    reference = "[*Quantum Computation Roadmap*](http://qist.lanl.gov) (2004). Version 2.0; April 2, 2004."
    result = md_to_latex(reference)
    @test result ==
          "\\href{http://qist.lanl.gov}{\\emph{Quantum Computation Roadmap}} (2004). Version 2.0; April 2, 2004."
    # There seemed to be a problem with the hyperlink for the QCRoadmap
    # reference. However, it turned out the problem was that we were using
    # `\hypertarget{id}` instead of `\hypertarget{id}{}` (see below)
end


@testset "LaTeXWriter Integration Test" begin

    bib = CitationBibliography(
        joinpath(@__DIR__, "..", "docs", "src", "refs.bib"),
        style=:numeric
    )
    run_makedocs(
        joinpath(@__DIR__, "..", "docs");
        sitename="DocumenterCitations.jl",
        plugins=[bib],
        format=Documenter.LaTeX(platform="none"),
        pages=[
            "Home"                   => "index.md",
            "Syntax"                 => "syntax.md",
            "Citation Style Gallery" => "gallery.md",
            "CSS Styling"            => "styling.md",
            "Internals"              => "internals.md",
            "References"             => "references.md",
        ],
        env=Dict("DOCUMENTER_BUILD_PDF" => "1"),
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success
        @test occursin("LaTeXWriter: creating the LaTeX file.", output)

        tex_outfile = joinpath(dir, "build", "DocumenterCitations.jl.tex")
        @test isfile(tex_outfile)
        tex = FileContent(tex_outfile)
        @test raw"{\raggedright% @bibliography" in tex
        @test raw"}% end @bibliography" in tex
        # must use `\hypertarget{id}{}`, not `\hypertarget{id}`
        @test r"\\hypertarget{\d+}{}" in tex
        @test contains(
            tex,
            r"\\hypertarget{\d+}{}\\href{http://qist\.lanl\.gov}{\\emph{Quantum Computation Roadmap}} \(2004\)"
        )
        @test contains(
            tex,
            raw"\hangindent=0.33in {\makebox[{\ifdim0.33in<\dimexpr\width+1ex\relax\dimexpr\width+1ex\relax\else0.33in\fi}][l]{[1]}}"
        )
        nbsp = "\u00A0"  # nonbreaking space
        if Documenter_version >= v"1.1.2"
            # https://github.com/JuliaDocs/Documenter.jl/pull/2300
            nbsp = "~"
        end
        @test contains(
            tex,
            "\\hangindent=0.33in Brif,$(nbsp)C.; Chakrabarti,$(nbsp)R. and Rabitz,$(nbsp)H. (2010)."
        ) # authoryear :ul

    end

end


@testset "LaTeXWriter – :ul bullet list, justified" begin

    DocumenterCitations.set_latex_options(ul_as_hanging=false, bib_blockformat="")
    @test DocumenterCitations._LATEX_OPTIONS == Dict{Symbol,Any}(
        :ul_as_hanging   => false,
        :ul_hangindent   => "0.33in",
        :dl_hangindent   => "0.33in",
        :dl_labelwidth   => "0.33in",
        :bib_blockformat => "",
    )

    bib = CitationBibliography(
        joinpath(@__DIR__, "..", "docs", "src", "refs.bib"),
        style=:numeric
    )
    run_makedocs(
        joinpath(@__DIR__, "..", "docs");
        sitename="DocumenterCitations.jl",
        plugins=[bib],
        format=Documenter.LaTeX(platform="none"),
        pages=[
            "Home"                   => "index.md",
            "Syntax"                 => "syntax.md",
            "Citation Style Gallery" => "gallery.md",
            "CSS Styling"            => "styling.md",
            "Internals"              => "internals.md",
            "References"             => "references.md",
        ],
        env=Dict("DOCUMENTER_BUILD_PDF" => "1"),
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success
        @test occursin("LaTeXWriter: creating the LaTeX file.", output)

        tex_outfile = joinpath(dir, "build", "DocumenterCitations.jl.tex")
        @test isfile(tex_outfile)
        tex = FileContent(tex_outfile)
        @test raw"{% @bibliography" in tex
        @test raw"}% end @bibliography" in tex
        nbsp = "\u00A0"  # nonbreaking space
        if Documenter_version >= v"1.1.2"
            # https://github.com/JuliaDocs/Documenter.jl/pull/2300
            nbsp = "~"
        end
        @test contains(
            tex,
            "\\begin{itemize}\n\\item Brif,$(nbsp)C.; Chakrabarti,$(nbsp)R. and Rabitz,$(nbsp)H. (2010)."
        ) # authoryear :ul

    end

    DocumenterCitations.reset_latex_options()
    @test DocumenterCitations._LATEX_OPTIONS == Dict{Symbol,Any}(
        :ul_as_hanging   => true,
        :ul_hangindent   => "0.33in",
        :dl_hangindent   => "0.33in",
        :dl_labelwidth   => "0.33in",
        :bib_blockformat => "\\raggedright",
    )

end


@testset "LaTeXWriter – custom indents" begin

    DocumenterCitations.set_latex_options(
        ul_hangindent="1cm",
        dl_hangindent="1.5cm",
        dl_labelwidth="2.0cm"
    )
    @test DocumenterCitations._LATEX_OPTIONS == Dict{Symbol,Any}(
        :ul_as_hanging   => true,
        :ul_hangindent   => "1cm",
        :dl_hangindent   => "1.5cm",
        :dl_labelwidth   => "2.0cm",
        :bib_blockformat => "\\raggedright",
    )

    bib = CitationBibliography(
        joinpath(@__DIR__, "..", "docs", "src", "refs.bib"),
        style=:numeric
    )
    run_makedocs(
        joinpath(@__DIR__, "..", "docs");
        sitename="DocumenterCitations.jl",
        plugins=[bib],
        format=Documenter.LaTeX(platform="none"),
        pages=[
            "Home"                   => "index.md",
            "Syntax"                 => "syntax.md",
            "Citation Style Gallery" => "gallery.md",
            "CSS Styling"            => "styling.md",
            "Internals"              => "internals.md",
            "References"             => "references.md",
        ],
        env=Dict("DOCUMENTER_BUILD_PDF" => "1"),
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success
        @test occursin("LaTeXWriter: creating the LaTeX file.", output)

        tex_outfile = joinpath(dir, "build", "DocumenterCitations.jl.tex")
        @test isfile(tex_outfile)
        tex = FileContent(tex_outfile)
        @test raw"{\raggedright% @bibliography" in tex
        @test raw"}% end @bibliography" in tex
        nbsp = "\u00A0"  # nonbreaking space
        if Documenter_version >= v"1.1.2"
            # https://github.com/JuliaDocs/Documenter.jl/pull/2300
            nbsp = "~"
        end
        @test contains(
            tex,
            "\\hangindent=1cm Brif,$(nbsp)C.; Chakrabarti,$(nbsp)R. and Rabitz,$(nbsp)H. (2010)."
        ) # authoryear :ul
        @test contains(
            tex,
            raw"\hangindent=1.5cm {\makebox[{\ifdim2.0cm<\dimexpr\width+1ex\relax\dimexpr\width+1ex\relax\else2.0cm\fi}][l]{[BCR10]}}"
        ) # :alpha style
        @test contains(
            tex,
            raw"\hangindent=1.5cm {\makebox[{\ifdim2.0cm<\dimexpr\width+1ex\relax\dimexpr\width+1ex\relax\else2.0cm\fi}][l]{[1]}}"
        ) # :numeric style

    end

    DocumenterCitations.reset_latex_options()
    @test DocumenterCitations._LATEX_OPTIONS == Dict{Symbol,Any}(
        :ul_as_hanging   => true,
        :ul_hangindent   => "0.33in",
        :dl_hangindent   => "0.33in",
        :dl_labelwidth   => "0.33in",
        :bib_blockformat => "\\raggedright",
    )

end


@testset "invalid latex options" begin

    msg = "dl_as_hanging is not a valid option in set_latex_options."
    @test_throws ArgumentError(msg) begin
        DocumenterCitations.set_latex_options(dl_as_hanging=false)
        # We've confused `dl_as_hanging` with `ul_as_hanging`
    end

    msg = "`0` for option ul_hangindent in set_latex_options must be of type String, not Int64"
    @test_throws ArgumentError(msg) begin
        DocumenterCitations.set_latex_options(ul_hangindent=0)
    end

    msg = "width \"\" must be a valid LaTeX width"
    @test_throws ArgumentError(msg) begin
        # DocumenterCitations.set_latex_options(ul_hangindent="")
        # actually works, but then we get an error when we try to generate a
        # label box:
        DocumenterCitations._labelbox(nothing, nothing; width="")
    end

    @test DocumenterCitations._LATEX_OPTIONS == Dict{Symbol,Any}(
        :ul_as_hanging   => true,
        :ul_hangindent   => "0.33in",
        :dl_hangindent   => "0.33in",
        :dl_labelwidth   => "0.33in",
        :bib_blockformat => "\\raggedright",
    )

end
