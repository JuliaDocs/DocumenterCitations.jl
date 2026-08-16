using DocumenterCitations
using Bibliography
using Test

include("run_makedocs.jl")

# How to use more than one `.bib` file
# (https://github.com/JuliaDocs/DocumenterCitations.jl/issues/72)
#
# `CitationBibliography` reads a single `bibfile`. Multiple files can be
# combined by reading them manually and passing the merged entries to the
# private `_entries` keyword argument. This is not officially supported: the
# `_entries` argument is deliberately undocumented.
#
# Multiple bib files are officially unsupported, but this test is a commitment
# to allow the hack / workaround in future non-breaking releases.

@testset "multiple bib files" begin

    bibfiles = [
        joinpath(@__DIR__, "test_multiple_bibfiles", "src", "refs_reviews.bib"),
        joinpath(@__DIR__, "test_multiple_bibfiles", "src", "refs_books.bib"),
    ]

    # `Bibliography.import_bibtex` returns an `OrderedDict` of citation keys to
    # entries, which is exactly what `_entries` expects. Merging preserves the
    # order in which the files are listed. For a key that occurs in more than
    # one file, the entry from the *last* file wins.
    entries = merge(Bibliography.import_bibtex.(bibfiles)...)
    @test collect(keys(entries)) ==
          ["BrifNJP2010", "KochJPCM2016", "Tannor2007", "BrumerShapiro2003"]

    # Since `_entries` is given, the `bibfile` argument is not read, and it does
    # not have to exist as a file. It is used only as a label in the error
    # messages for citation keys that are not found ("Key … not found in entries
    # from …"), so any string that identifies the source of the entries will do.
    bib = CitationBibliography(
        join(basename.(bibfiles), ", ");
        style=:numeric,
        _entries=entries
    )
    @test bib.bibfile == "refs_reviews.bib, refs_books.bib"
    @test collect(keys(bib.entries)) == collect(keys(entries))

    # From here on, `bib` is an ordinary plugin object: pass it to `makedocs` as
    # an element of the `plugins` keyword argument, as usual.
    run_makedocs(
        joinpath(@__DIR__, "test_multiple_bibfiles");
        sitename="Test",
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",],
        check_success=true
    ) do dir, result, success, backtrace, output

        @test success

        # Citations from both files resolve, and the citation numbers follow the
        # order of the citations in `index.md`, not the order of the entries in
        # the merged dict.
        #! format: off
        index_html = strip_cite_ids(read(joinpath(dir, "build", "index.html"), String))
        @test contains(index_html, "[<a href=\"references/#Tannor2007\">1</a>]")
        @test contains(index_html, "[<a href=\"references/#BrifNJP2010\">2</a>]")
        @test contains(index_html, "[<a href=\"references/#BrumerShapiro2003\">3</a>]")
        @test contains(index_html, "[<a href=\"references/#KochJPCM2016\">4</a>]")

        # All four entries end up in the single `@bibliography` block.
        references_html = read(joinpath(dir, "build", "references", "index.html"), String)
        @test contains(references_html, "<div id=\"Tannor2007\">")
        @test contains(references_html, "<div id=\"BrifNJP2010\">")
        @test contains(references_html, "<div id=\"BrumerShapiro2003\">")
        @test contains(references_html, "<div id=\"KochJPCM2016\">")
        #! format: on

    end

    # Without `_entries`, `bibfile` is read, and thus must exist.
    exc = @test_throws ErrorException CitationBibliography("does_not_exist.bib")
    @test contains(exc.value.msg, "bibfile \"does_not_exist.bib\" does not exist")

end
