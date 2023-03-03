# Source this script as e.g.
#
#     include("PATH/TO/devrepl.jl")
#
# from *any* Julia REPL or run it as e.g.
#
#     julia -i --banner=no PATH/TO/devrepl.jl
#
# from anywhere. This will change the current working directory and
# activate/initialize the correct Julia environment for you.
#
# You may also run this in vscode to initialize a development REPL
#
using Pkg
using Downloads: download

cd(@__DIR__)
Pkg.activate("test")

function _instantiate()
    Pkg.develop(path=".")
    if isdir(joinpath("..", "QuantumControlTestUtils.jl"))
        Pkg.develop(path=joinpath("..", "QuantumControlTestUtils.jl"))
    end
    if !isfile(joinpath("..", ".JuliaFormatter.toml"))
        download(
            "https://raw.githubusercontent.com/JuliaQuantumControl/JuliaQuantumControl/master/.JuliaFormatter.toml",
            ".JuliaFormatter.toml"
        )
    end
end

if !isfile(joinpath("test", "Manifest.toml"))
    _instantiate()
end
include("test/init.jl")

if abspath(PROGRAM_FILE) == @__FILE__
    help()
end
