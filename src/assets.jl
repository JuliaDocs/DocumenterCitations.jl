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

The step is skipped if the documentation has no HTML output format, or if the
[`CitationBibliography`](@ref) plugin was instantiated with `insert_css=false`.

If any of the user-defined assets is an unmodified copy of a `citations.css`
that was bundled with some version of `DocumenterCitations`, the step issues a
warning.
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
    bib = Documenter.getplugin(doc, CitationBibliography)
    bib.insert_css || return  # opt-out
    html = _find_html_format(doc.user.format)
    isnothing(html) && return  # no HTML output
    _warn_stale_css(doc, html)  # must run *before* registering our own asset
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

_find_html_format(::Any) = nothing

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


# Normalize a stylesheet before hashing: line endings, trailing whitespace on
# each line, and surrounding blank lines do not affect whether a file is a
# verbatim copy of a bundled version
function _normalize_css(str::AbstractString)
    lines = rstrip.(split(str, r"\r\n|\r|\n"))  # handles all three line endings
    return String(strip(join(lines, "\n")))
end


_css_hash(str::AbstractString) = bytes2hex(sha256(_normalize_css(str)))


# The `_css_hash` of every version of `citations.css` that this package has
# ever shipped or recommended, newest first.
#
# When editing `assets/citations.css`, PREPEND the hash of the new content here
# and KEEP all existing entries: they are what allows `_warn_stale_css` to
# recognize an outdated copy in a user's `docs/src/assets` folder. The test in
# `test/test_assets.jl` fails if the first entry does not match the current
# `assets/citations.css`.
const KNOWN_CSS_HASHES = (
    "ad197a59c8c6e614024dd464d9b9693a0ab5bb8479bcb2c1d423fb30ff7ee87b",  # since v1.3.3
    "f2986976ab24cbac4d387e85c0c87c297591d0a153160913ee4bf01551402763",  # v1.0 – v1.3.2
    "a84156754fe3efcce021d9be813b2d3fa4e1cd83ef5669e9aac013c44b543b74",  # before v1.0
)


# Warn about entries in the `assets` of the HTML format that are unmodified
# copies of a bundled `citations.css`: they are redundant, and they would
# silently override any future update of the bundled stylesheet
function _warn_stale_css(doc::Documenter.Document, html::Documenter.HTML)
    for asset in html.assets
        asset isa Documenter.HTMLWriter.HTMLAsset || continue
        (asset.islocal && (asset.class == :css)) || continue
        # Skip our own asset, which is still registered in `html.assets` if the
        # same `Documenter.HTML` object is reused for a second `makedocs` run
        startswith(asset.uri, "assets/$ASSETS_SUBFOLDER/") && continue
        file = joinpath(doc.user.root, doc.user.source, asset.uri)
        isfile(file) || continue
        if _css_hash(read(file, String)) in KNOWN_CSS_HASHES
            @warn "The `assets` of `Documenter.HTML` contain $(repr(asset.uri)), which is an unmodified copy of the `citations.css` bundled with DocumenterCitations. As of v1.5, the stylesheet is inserted automatically by default, so both the `assets` entry and the file itself can be deleted. Keeping the copy may mask any future update of the bundled stylesheet. To suppress the bundled stylesheet instead, use `CitationBibliography(bibfile; insert_css=false)`."
        end
    end
    return
end
