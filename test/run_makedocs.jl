using IOCapture: IOCapture
using Documenter: Documenter, makedocs
import Logging


# Run `makedocs` as part of a test.
#
# Use as:
#
# ```julia
# run_makedocs(root; kwargs...) do dir, result, success, backtrace, output
#     @test success
#     # * dir is the temporary folder where `root` was copied. It should
#     #   contain the `build` output folder etc.
#     # * `result` is whatever `makedocs` returns (usually `nothing`)
#     # * `success` is a boolean whether the call returned successfully
#     # * `backtrace` contains the backtrace for any thrown exception
#     # * `output` contains the STDOUT produced by `run_makedocs`
# end
# ```
#
# Keyword args are:
#
# * `check_success`: If true, log an error if the call to `makedocs` does not
#   succeed
# * `check_failure`: If true, log an error if the call to `makedocs`
#   unexpectedly succeeds
# * `env`: dict temporary overrides for environment variables. Consider passing
#   `"JULIA_DEBUG" => ""` if testing `output` against some expected output.
#
# Note that even with `check_success`/`check_failure`, you must still `@test`
# the value of `success` inside the `do` block.
#
# All other keyword arguments are forwarded to `makedocs`.
#
# To show the output of every `run_makedocs` run, set the environment variable
# `JULIA_DEBUG=Main` or `ENV["JULIA_DEBUG"] = Main` in the dev-REPL.
function run_makedocs(
    f,
    root;
    plugins=[],
    check_success=false,
    check_failure=false,
    env=Dict{String,String}(),
    kwargs...
)

    dir = mktempdir()

    cp(root, dir; force=true)

    c = IOCapture.capture(rethrow=InterruptException) do
        default_format = Documenter.HTML(; edit_link="master", repolink=" ")
        withenv(env...) do
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

    level = Logging.Debug
    checked = (check_success || check_failure) ? " (expected)" : ""
    success = !c.error
    if (check_success && !success) || (check_failure && success)
        checked = " (UNEXPECTED)"
        level = Logging.Error
    end

    calling_frame = stacktrace()[3]
    result = c.value
    Logging.@logmsg level """

    run_makedocs(root=$root,...) -> $(success ? "success" : "failure")$checked
    @$(calling_frame.file):$(calling_frame.line)
    --------------------------------- output ---------------------------------
    $(c.output)
    --------------------------------------------------------------------------
    """ dir typeof(result) result stacktrace = stacktrace(c.backtrace)

    write(joinpath(dir, "output"), c.output)
    open(joinpath(dir, "result"), "w") do io
        show(io, "text/plain", result)
        println(io, "-"^80)
        show(io, "text/plain", stacktrace(c.backtrace))
    end

    f(dir, result, success, c.backtrace, c.output)

end
