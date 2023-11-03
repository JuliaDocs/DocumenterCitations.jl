using DocumenterCitations
using Test
using IOCapture: IOCapture

include("run_makedocs.jl")


@testset "Check invalid url in .bib file " begin

    # https://github.com/JuliaDocs/DocumenterCitations.jl/issues/58

    root = splitext(@__FILE__)[1]

    bib = CitationBibliography(joinpath(root, "src", "invalidlink.bib"), style=:numeric)

    run_makedocs(
        root;
        linkcheck=true,
        sitename="Test",
        plugins=[bib],
        pages=["Home" => "index.md", "References" => "references.md",],
        check_failure=true,
        env=Dict("PATH" => "$root:$(ENV["PATH"])"),  # Unix only
        # The updated PATH allows to use the mock `curl` in `root`.
    ) do dir, result, success, backtrace, output

        @test !success
        @test contains(output, r"Error:.*http://www.invalid-server.doesnotexist/page.html")
        @test contains(
            output,
            "Error: linkcheck 'http://httpbin.org/status/404' status: 404."
        )
        @test contains(
            output,
            "Error: linkcheck 'http://httpbin.org/status/500' status: 500."
        )
        @test contains(
            output,
            "Error: linkcheck 'http://httpbin.org/status/403' status: 403."
        )
        @test contains(result.msg, "`makedocs` encountered an error [:linkcheck]")

    end

end
