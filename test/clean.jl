"""
    clean([distclean=false])

Clean up build/doc/testing artifacts. Restore to clean checkout state
(distclean)
"""
function clean(; distclean=false, _exit=true)

    _glob(folder, ending) =
        [name for name in readdir(folder; join=true) if (name |> endswith(ending))]
    _glob_star(folder; except=[]) = [
        joinpath(folder, name) for
        name in readdir(folder) if !(name |> startswith(".") || name ∈ except)
    ]
    _exists(name) = isfile(name) || isdir(name)
    _push!(lst, name) = _exists(name) && push!(lst, name)

    ROOT = dirname(@__DIR__)

    ###########################################################################
    CLEAN = String[]
    src_folders =
        ["", "src", joinpath("src", "styles"), "test", joinpath("docs", "custom_styles")]
    for folder in src_folders
        append!(CLEAN, _glob(joinpath(ROOT, folder), ".cov"))
    end
    _push!(CLEAN, joinpath(ROOT, "coverage"))
    _push!(CLEAN, joinpath(ROOT, "docs", "build"))
    append!(CLEAN, _glob(ROOT, ".info"))
    append!(CLEAN, _glob(joinpath(ROOT, ".coverage"), ".info"))
    ###########################################################################

    ###########################################################################
    DISTCLEAN = String[]
    for folder in ["", "docs", "test"]
        _push!(DISTCLEAN, joinpath(joinpath(ROOT, folder), "Manifest.toml"))
    end
    ###########################################################################

    for name in CLEAN
        @info "rm $name"
        rm(name, force=true, recursive=true)
    end
    if distclean
        for name in DISTCLEAN
            @info "rm $name"
            rm(name, force=true, recursive=true)
        end
        if _exit
            @info "Exiting"
            exit(0)
        end
    end

end

distclean() = clean(distclean=true)
