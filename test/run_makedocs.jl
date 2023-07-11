using IOCapture: IOCapture
using Documenter: Documenter, makedocs


# Run `makedocs` as part of a test.
#
# ```julia
# run_makedocs(root; kwargs...) do dir, result, success, backtrace, output
#     success || @error "Failed makedocs:\n$output" dir
#     @test success
#     # * dir is the temporary folder where `root` was copied. It should
#     #   contain the `build` output folder etc.
#     # * `result` is whatever `makedocs` returns (usually `nothing`)
#     # * `success` is a boolean whether the call returned successfully
#     # * `backtrace` contains the backgrace for any thrown exception
#     # * `output` contains the STDOUT produced by `run_makedocs`
# end
# ```
function run_makedocs(f, root; plugins=[], kwargs...)

    dir = mktempdir()

    cp(root, dir; force=true)

    c = IOCapture.capture(rethrow=InterruptException) do
        default_format = Documenter.HTML(; edit_link="master", repolink=" ")
        # In case JULIA_DEBUG is set to something, we'll override that, so that
        # we wouldn't get some unexpected debug output from makedocs.
        withenv("JULIA_DEBUG" => "") do
            makedocs(;
                plugins=plugins,
                remotes=get(kwargs, :remotes, nothing),
                sitename=get(kwargs, :sitename, " "),
                format=get(kwargs, :format, default_format),
                root=dir,
                kwargs...
            )
        end
    end

    @debug """run_makedocs(root=$root,...) -> $(c.error ? "fail" : "success")
    Running in $dir
    --------------------------------- output ---------------------------------
    $(c.output)
    --------------------------------------------------------------------------
    """ c.value stacktrace(c.backtrace) dir

    write(joinpath(dir, "output"), c.output)
    open(joinpath(dir, "result"), "w") do io
        show(io, "text/plain", c.value)
        println(io, "-"^80)
        show(io, "text/plain", stacktrace(c.backtrace))
    end

    f(dir, c.value, !c.error, c.backtrace, c.output)

end
