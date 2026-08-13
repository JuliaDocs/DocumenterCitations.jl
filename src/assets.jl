# Inject Assets
#
# This runs before Documenter's `RenderDocument` step, so that the assets are in
# place before the HTML pages are written.

"""Pipeline step to automatically insert the bundled `citations.css` stylesheet.

The stylesheet shipped with the package (`assets/citations.css`) is copied into
`build/assets/documentercitations/` and registered in the `assets` list of the
[`Documenter.HTML`](@extref Documenter.HTMLWriter.HTML) format, so that
`Documenter` emits the corresponding `<link>` tag in the `<head>` of every
page. Thus, no manual `assets` entry is required in
[`Documenter.makedocs`](@extref).

The entry is inserted *before* any user-defined assets, so that custom CSS
still takes precedence over the bundled stylesheet, see [CSS Styling](@ref).

The step is skipped if the documentation has no HTML output format.
"""
abstract type InjectAssets <: Builder.DocumentPipeline end

Selectors.order(::Type{InjectAssets}) = 5.5  # Before RenderDocument

function Selectors.runner(::Type{InjectAssets}, doc::Documenter.Document)
    Documenter.is_doctest_only(doc, "InjectAssets") && return
    inject_assets!(doc)
end


# The folder containing the assets shipped as part of the package
const ASSETS_FOLDER = normpath(joinpath(@__DIR__, "..", "assets"))

# The names of the assets to insert, relative to `ASSETS_FOLDER`
const ASSETS = ("citations.css",)

# The sub-folder of `build/assets` into which the assets are copied
const ASSETS_SUBFOLDER = "documentercitations"


# Copy the bundled assets into the build folder and register them with the HTML
# format object
function inject_assets!(doc::Documenter.Document)
    html = _find_html_format(doc.user.format)
    isnothing(html) && return  # no HTML output
    destination = joinpath(doc.user.build, "assets", ASSETS_SUBFOLDER)
    mkpath(destination)
    for filename in ASSETS
        cp(joinpath(ASSETS_FOLDER, filename), joinpath(destination, filename); force=true)
        uri = "assets/$ASSETS_SUBFOLDER/$filename"
        _has_asset(html.assets, uri) && continue
        asset = Documenter.asset(uri; islocal=true)
        if asset isa eltype(html.assets)
            # Insert before any user-defined assets, so that custom CSS wins
            pushfirst!(html.assets, asset)
        else
            # Can happen if the `assets` of `Documenter.HTML` were given as a
            # vector that cannot hold an `HTMLAsset`, e.g., a vector of
            # `RawHTMLHeadContent` only
            @warn "InjectAssets: cannot register $(repr(uri)). Add `assets=String[$(repr(uri))]` to `Documenter.HTML` manually."
        end
    end
    return
end


# Find the `Documenter.HTML` format object in the (possibly multiple) output
# formats of the documentation, or `nothing` if there is no HTML output
_find_html_format(format::Documenter.HTML) = format

_find_html_format(format) = nothing

function _find_html_format(formats::AbstractVector)
    for format in formats
        html = _find_html_format(format)
        isnothing(html) || return html
    end
    return nothing
end


# Check whether `uri` is already registered in the `assets` of the HTML format
function _has_asset(assets, uri)
    return any(assets) do asset
        asset isa Documenter.HTMLWriter.HTMLAsset && asset.uri == uri
    end
end
