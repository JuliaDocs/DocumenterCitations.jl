using Test

# The behavior of the bundled browser assets is tested in JavaScript, in
# `test/js/test_assets.js`, which evaluates the scripts in `assets/` against a
# minimal fake DOM. This runs those tests with `node`, which is available on
# the CI runners. Without it, they are skipped: the package itself does not
# depend on any JavaScript tooling.

const NODE = Sys.which("node")

const TEST_SCRIPT = joinpath(@__DIR__, "js", "test_assets.js")

@testset "bundled browser assets" begin

    if isnothing(NODE)
        @warn "Skipping the tests for the bundled browser assets: `node` not found"
        @test_skip isnothing(NODE)
    else
        io = IOBuffer()
        cmd = pipeline(ignorestatus(`$NODE $TEST_SCRIPT`); stdout=io, stderr=io)
        exitcode = run(cmd).exitcode
        output = String(take!(io))
        if exitcode ≠ 0
            println(output)
        end
        @test exitcode == 0
    end

end
