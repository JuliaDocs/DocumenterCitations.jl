"""
    clean([distclean=false])

Clean up build/doc/testing artifacts. Restore to clean checkout state
(distclean)
"""
function clean(; distclean=false, _exit=true)

    _exists(name) = isfile(name) || isdir(name)
    _push!(lst, name) = _exists(name) && push!(lst, name)

    ROOT = dirname(@__DIR__)
    # Directories that are never searched for artifacts (either because they
    # are removed wholesale below, or because they are not ours).
    PRUNE = [".git", "build", "node_modules"]
    ARTIFACTS = [".cov", ".mem", ".info"]

    ###########################################################################
    CLEAN = String[]
    for (folder, subfolders, files) in walkdir(ROOT)
        filter!(!in(PRUNE), subfolders)
        for name in files
            any(endswith(name, ending) for ending in ARTIFACTS) &&
                push!(CLEAN, joinpath(folder, name))
        end
    end
    _push!(CLEAN, joinpath(ROOT, "coverage"))
    _push!(CLEAN, joinpath(ROOT, "docs", "build"))
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
