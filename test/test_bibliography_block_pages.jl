using DocumenterCitations
import Documenter
using Test

include("run_makedocs.jl")
include("file_content.jl")


# regex for strings containing paths
function prx(s)
    rx = escape_string(s)
    # work around limitations of `replace` in Julia 1.6
    for mapping in ["[" => "\\[", "]" => "\\]", "." => "\\.", "/" => "\\W*"]
        # The mapping for path separators ("/") to "\W*" (sequence of non-word
        # characters) is deliberately broad. I've found it frustratingly hard
        # to get a regex that works on Windows.
        rx = replace(rx, mapping)
    end
    Regex(rx)
end


@testset "Bibliographies with Pages" begin

    bib = CitationBibliography(DocumenterCitations.example_bibfile, style=:numeric)

    # non-strict
    run_makedocs(
        splitext(@__FILE__)[1];
        sitename="Test",
        warnonly=true,
        plugins=[bib],
        format=Documenter.HTML(prettyurls=false, repolink=""),
        pages=[
            "Home" => "index.md",
            "A" => joinpath("part1", "section1", "p1_s1_page.md"),
            "B" => joinpath("part1", "section2", "p1_s2_page.md"),
            "C" => joinpath("part2", "section1", "p2_s1_page.md"),
            "D" => joinpath("part2", "section2", "p2_s2_page.md"),
            "E" => joinpath("part3", "section1", "p3_s1_page.md"),
            "F" => joinpath("part3", "section2", "p3_s2_page.md"),
            "Invalid" => joinpath("part3", "section2", "invalidpages.md"),
            "References" => "references.md",
            "Addendum" => "addendum.md",
        ],
        check_success=true
    ) do dir, result, success, backtrace, output

        rp = ""
        if Documenter.DOCUMENTER_VERSION >= v"1.10.0"
            # In v1.10, Documenter changed paths in error messages from being
            # relative to `make.jl` to being relative to the CWD; see
            # https://github.com/JuliaDocs/Documenter.jl/pull/2659
            rp = relpath(realpath(dir)) * "/"
        end

        @test success
        #! format: off
        if Sys.isunix()
            # These regexes are impossible to get right on Windows
            @test_broken contains(output, prx("Error: Invalid \"index.md\" in Pages attribute of @bibliography block on page $(rp)src/part3/section2/invalidpages.md: No such file \"src/part3/section2/index.md\"."))
            @test contains(output, prx("Warning: The entry \"index.md\" in the Pages attribute of the @bibliography block on page $(rp)src/part3/section2/invalidpages.md:7-14 appears to be relative to \"src\"."))
            @test contains(output, prx("Error: Invalid \"p3_s1_page.md\" in Pages attribute of @bibliography block on page $(rp)src/part3/section2/invalidpages.md:7-14: No such file \"src/part3/section2/p3_s1_page.md\"."))
            @test contains(output, prx("Error: Invalid \"noexist.md\" in Pages attribute of @bibliography block on page $(rp)src/part3/section2/invalidpages.md:7-14: No such file \"src/part3/section2/noexist.md\"."))
            @test contains(output, "Warning: No cited keys remaining after filtering to Pages")
            @test contains(output, prx("Error: Invalid \"../../addendum.md\" in Pages attribute of @bibliography block on page $(rp)src/part3/section2/invalidpages.md:20-25: File \"src/addendum.md\" exists but no references were collected."))
            @test contains(output, prx("Error: Invalid \"p3_s1_page.md\" in Pages attribute of @bibliography block on page $(rp)src/part3/section2/invalidpages.md:29-35: No such file \"src/part3/section2/p3_s1_page.md\"."))
            @test contains(output, prx("Warning: The field `Pages` in $(rp)src/part3/section2/invalidpages.md:41-44 must evaluate to a list of strings. Setting invalid `Pages = \"none\"` to `Pages = []`"))
        end
        #! format: on

        build(paths...) = joinpath(dir, "build", paths...)
        citation(n) = Regex("\\[<a href=\"[^\"]+\">$n</a>\\]")
        contentlink(name) = ".html#$(replace(name, " " => "-"))\">$name"

        index_html = FileContent(build("index.html"))
        @test index_html.exists
        @test citation(1) in index_html

        p1_s1_page_html = FileContent(build("part1", "section1", "p1_s1_page.html"))
        @test p1_s1_page_html.exists
        @test citation(2) in p1_s1_page_html
        @test citation(3) in p1_s1_page_html
        @test "<dt>[2]</dt>" in p1_s1_page_html
        @test "<dt>[3]</dt>" in p1_s1_page_html
        @test contentlink("A: Part 1.1") in p1_s1_page_html

        p1_s2_page_html = FileContent(build("part1", "section2", "p1_s2_page.html"))
        @test p1_s2_page_html.exists
        @test citation(3) in p1_s2_page_html
        @test citation(4) in p1_s2_page_html
        @test !("<dt>[2]</dt>" in p1_s2_page_html)
        @test "<dt>[3]</dt>" in p1_s2_page_html
        @test "<dt>[4]</dt>" in p1_s2_page_html
        @test "content here is empty" in p1_s2_page_html

        p2_s1_page_html = FileContent(build("part2", "section1", "p2_s1_page.html"))
        @test p2_s1_page_html.exists
        @test citation(5) in p2_s1_page_html
        @test citation(5) in p2_s1_page_html
        @test "<dt>[2]</dt>" in p2_s1_page_html
        @test "<dt>[3]</dt>" in p2_s1_page_html
        @test "<dt>[4]</dt>" in p2_s1_page_html
        @test "<dt>[5]</dt>" in p2_s1_page_html
        @test "<dt>[6]</dt>" in p2_s1_page_html
        @test contentlink("C: Part 2.1") in p2_s1_page_html
        @test contentlink("A: Part 1.1") in p2_s1_page_html
        @test contentlink("B: Part 1.2") in p2_s1_page_html

        p2_s2_page_html = FileContent(build("part2", "section2", "p2_s2_page.html"))
        @test p2_s2_page_html.exists
        @test citation(7) in p2_s2_page_html
        @test citation(8) in p2_s2_page_html
        @test "<dt>[2]</dt>" in p2_s2_page_html
        @test "<dt>[3]</dt>" in p2_s2_page_html
        @test "<dt>[4]</dt>" in p2_s2_page_html
        @test "<dt>[5]</dt>" in p2_s2_page_html
        @test "<dt>[6]</dt>" in p2_s2_page_html
        @test !("<dt>[7]</dt>" in p2_s2_page_html)
        @test !("<dt>[8]</dt>" in p2_s2_page_html)
        @test contentlink("A: Part 1.1") in p2_s2_page_html
        @test contentlink("B: Part 1.2") in p2_s2_page_html
        @test contentlink("C: Part 2.1") in p2_s2_page_html
        @test !(contentlink("D: Part 2.2") in p2_s2_page_html)

        p3_s1_page_html = FileContent(build("part3", "section1", "p3_s1_page.html"))
        @test p3_s1_page_html.exists
        @test citation(9) in p3_s1_page_html
        @test citation(10) in p3_s1_page_html
        @test "<dt>[2]</dt>" in p3_s1_page_html
        @test "<dt>[3]</dt>" in p3_s1_page_html
        @test "<dt>[4]</dt>" in p3_s1_page_html
        @test "<dt>[5]</dt>" in p3_s1_page_html
        @test "<dt>[6]</dt>" in p3_s1_page_html
        @test "<dt>[7]</dt>" in p3_s1_page_html
        @test "<dt>[8]</dt>" in p3_s1_page_html
        @test !("<dt>[9]</dt>" in p3_s1_page_html)
        @test !("<dt>[10]</dt>" in p3_s1_page_html)
        @test contentlink("A: Part 1.1") in p3_s1_page_html
        @test contentlink("B: Part 1.2") in p3_s1_page_html
        @test contentlink("C: Part 2.1") in p3_s1_page_html
        @test contentlink("D: Part 2.2") in p3_s1_page_html
        @test !(contentlink("E: Part 3.1") in p3_s1_page_html)

        p3_s2_page_html = FileContent(build("part3", "section2", "p3_s2_page.html"))
        @test p3_s2_page_html.exists
        @test citation(11) in p3_s2_page_html
        @test citation(12) in p3_s2_page_html
        @test "<dt>[2]</dt>" in p3_s2_page_html
        @test "<dt>[3]</dt>" in p3_s2_page_html
        @test "<dt>[4]</dt>" in p3_s2_page_html
        @test "<dt>[5]</dt>" in p3_s2_page_html
        @test "<dt>[6]</dt>" in p3_s2_page_html
        @test "<dt>[7]</dt>" in p3_s2_page_html
        @test "<dt>[8]</dt>" in p3_s2_page_html
        @test "<dt>[9]</dt>" in p3_s2_page_html
        @test "<dt>[10]</dt>" in p3_s2_page_html
        @test !("<dt>[11]</dt>" in p3_s2_page_html)
        @test !("<dt>[12]</dt>" in p3_s2_page_html)
        @test contentlink("A: Part 1.1") in p3_s2_page_html
        @test contentlink("C: Part 2.1") in p3_s2_page_html
        @test contentlink("B: Part 1.2") in p3_s2_page_html
        @test contentlink("D: Part 2.2") in p3_s2_page_html
        @test contentlink("E: Part 3.1") in p3_s2_page_html

        invalidpages_html = FileContent(build("part3", "section2", "invalidpages.html"))
        @test invalidpages_html.exists
        @test "Nothing should render here" in invalidpages_html
        @test "Again, nothing should render here" in invalidpages_html
        @test "<dt>[11]</dt>" in invalidpages_html
        @test "<dt>[12]</dt>" in invalidpages_html

        addendum_html = FileContent(build("addendum.html"))
        @test "No references are cited on this page" in addendum_html

    end

    # strict
    run_makedocs(
        splitext(@__FILE__)[1];
        sitename="Test",
        warnonly=false,
        plugins=[bib],
        format=Documenter.HTML(prettyurls=false, repolink=""),
        check_failure=true
    ) do dir, result, success, backtrace, output

        rp = ""
        if Documenter.DOCUMENTER_VERSION >= v"1.10.0"
            # In v1.10, Documenter changed paths in error messages from being
            # relative to `make.jl` to being relative to the CWD; see
            # https://github.com/JuliaDocs/Documenter.jl/pull/2659
            rp = relpath(realpath(dir)) * "/"
        end

        @test !success
        #! format: off
        if Sys.isunix()
            # These regexes are impossible to get right on Windows
            @test_broken contains(output, prx("Error: Invalid \"index.md\" in Pages attribute of @bibliography block on page $(rp)src/part3/section2/invalidpages.md:7-14: No such file \"src/part3/section2/index.md\"."))
            @test contains(output, prx("Warning: The entry \"index.md\" in the Pages attribute of the @bibliography block on page $(rp)src/part3/section2/invalidpages.md:7-14 appears to be relative to \"src\"."))
            @test contains(output, prx("Error: Invalid \"p3_s1_page.md\" in Pages attribute of @bibliography block on page $(rp)src/part3/section2/invalidpages.md:7-14: No such file \"src/part3/section2/p3_s1_page.md\"."))
            @test contains(output, prx("Error: Invalid \"noexist.md\" in Pages attribute of @bibliography block on page $(rp)src/part3/section2/invalidpages.md:7-14: No such file \"src/part3/section2/noexist.md\"."))
            @test contains(output, "Warning: No cited keys remaining after filtering to Pages")
            @test contains(output, prx("Error: Invalid \"../../addendum.md\" in Pages attribute of @bibliography block on page $(rp)src/part3/section2/invalidpages.md:20-25: File \"src/addendum.md\" exists but no references were collected."))
            @test contains(output, prx("Error: Invalid \"p3_s1_page.md\" in Pages attribute of @bibliography block on page $(rp)src/part3/section2/invalidpages.md:29-35: No such file \"src/part3/section2/p3_s1_page.md\"."))
            @test contains(output, prx("Warning: The field `Pages` in $(rp)src/part3/section2/invalidpages.md:41-44 must evaluate to a list of strings. Setting invalid `Pages = \"none\"` to `Pages = []`"))
        end
        #! format: on
        @test result isa ErrorException
        @test occursin("`makedocs` encountered an error [:bibliography_block]", result.msg)

    end

end
