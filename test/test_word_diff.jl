# Tests for the `@test_diff` test helper itself. The diff rendering only runs
# when some other test fails, so without these tests it would be exercised for
# the first time at the least convenient moment.

using Test
using IOCapture: IOCapture
include("word_diff.jl")


"""Render a word diff without color."""
function diff_str(left, right)
    io = IOBuffer()
    show_word_diff(IOContext(io, :color => false), left, right)
    return chomp(String(take!(io)))
end


"""A test set that collects results instead of reporting or throwing."""
mutable struct QuietTestSet <: Test.AbstractTestSet
    results::Vector{Any}
end
QuietTestSet(::AbstractString; kwargs...) = QuietTestSet(Any[])
Test.record(ts::QuietTestSet, res) = (push!(ts.results, res); res)
Test.finish(ts::QuietTestSet) = ts


@testset "word diff" begin

    @test diff_str("alpha beta", "alpha beta") == "alpha beta"

    @test diff_str("alpha beta", "alpha gamma") == "alpha [-beta-]{+gamma+}"

    @test diff_str("[GBR+07]", "[GBR+07a]") == "[GBR+07{+a+}]"

    # A changed run whose two sides are similar is refined to the character
    # level; one whose sides are unrelated is not, as that would just produce
    # noise from whichever letters happen to coincide.
    @test diff_str("GraceJPB2007", "GraceJMO2007") == "GraceJ[-PB-]{+MO+}2007"
    @test diff_str("theory", "optimization") == "[-theory-]{+optimization+}"

    # Adjacent changed tokens are grouped into a single marker.
    @test diff_str("M. Grace, J. Phys. B 40", "M. Grace and W. Warren, J. Phys. B 40") ==
          "M. Grace{+ and W. Warren+}, J. Phys. B 40"

    # A pure insertion has no removed part, and vice versa.
    @test diff_str("a c", "a b c") == "a {+b +}c"
    @test diff_str("a b c", "a c") == "a [-b -]c"

    # The line structure of the common text is preserved.
    @test diff_str("<div>\n  <p>one</p>\n</div>", "<div>\n  <p>two</p>\n</div>") ==
          "<div>\n  <p>[-one-]{+two+}</p>\n</div>"

    # A change inside an attribute does not swallow the rest of the tag.
    @test diff_str(
        "<a href=\"#Grace2007\">Grace</a>",
        "<a href=\"#Grace2008\">Grace</a>"
    ) == "<a href=\"#Grace200[-7-]{+8+}\">Grace</a>"

    # Nothing in common at all.
    @test diff_str("alpha", "gamma") == "[-alpha-]{+gamma+}"

    # Empty strings on either side.
    @test diff_str("", "abc") == "{+abc+}"
    @test diff_str("abc", "") == "[-abc-]"

end


@testset "@test_diff" begin

    # Passing expressions behave like `@test`, including non-string operands
    # and expressions that are not comparisons at all.
    @test_diff "abc" == "abc"
    @test_diff 1 + 1 == 2
    @test_diff [1, 2] == [1, 2]
    @test_diff contains("hello world", "lo wo")
    @test_diff isempty("")

    # A failing string comparison writes a diff before recording the failure.
    c = IOCapture.capture() do
        @testset QuietTestSet "captured" begin
            @test_diff "alpha beta" == "alpha gamma"
        end
    end
    @test c.value.results[1] isa Test.Fail
    @test contains(c.output, "[-beta-]{+gamma+}")

    # A failing comparison of non-strings just fails, without a diff.
    c = IOCapture.capture() do
        @testset QuietTestSet "captured" begin
            @test_diff [1, 2] == [1, 3]
        end
    end
    @test c.value.results[1] isa Test.Fail
    @test !contains(c.output, "[-") && !contains(c.output, "{+")

end
