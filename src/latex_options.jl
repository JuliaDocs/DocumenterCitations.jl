const _LATEX_OPTIONS = Dict{Symbol,Any}()
# _LATEX_OPTIONS are initialized with call to reset_latex_options() __init__()


@doc raw"""
Reset the options for how bibliographies are written in LaTeX.

```julia
DocumenterCitations.reset_latex_options()
```

is equivalent to the following call to [`set_latex_options`](@ref):

```julia
set_latex_options(;
    ul_as_hanging=true,
    ul_hangindent="0.33in",
    dl_hangindent="0.33in",
    dl_labelwidth="0.33in",
    bib_blockformat="\raggedright",
)
```
"""
function reset_latex_options()
    global _LATEX_OPTIONS
    _LATEX_OPTIONS[:ul_as_hanging] = true
    _LATEX_OPTIONS[:ul_hangindent] = "0.33in"
    _LATEX_OPTIONS[:dl_hangindent] = "0.33in"
    _LATEX_OPTIONS[:dl_labelwidth] = "0.33in"
    _LATEX_OPTIONS[:bib_blockformat] = "\\raggedright"
end


@doc raw"""
Set options for how bibliographies are written via `Documenter.LaTeXWriter`.

```julia
DocumenterCitations.set_latex_options(; options...)
```

Valid options that can be passed as keyword arguments are:

* `ul_as_hanging`: If `true` (default), format unordered bibliography lists
  (`:ul` returned by [`DocumenterCitations.bib_html_list_style`](@ref)) as a
  list of paragraphs with hanging indent. This matches the recommended CSS
  styling for HTML `:ul` bibliographies, see [CSS Styling](@ref). If `false`,
  the bibliography will be rendered as a standard bulleted list.
* `ul_hangindent`: If `ul_as_hanging=true`, the amount of hanging indent. Must
   be a string that specifies a valid
   [LaTeX length](https://www.overleaf.com/learn/latex/Lengths_in_LaTeX),
   e.g., `"0.33in"`
* `dl_hangindent` : Bibliographies that should render as "definition lists"
  (`:dl` returned by [`DocumenterCitations.bib_html_list_style`](@ref)) are
  emulated as a list of paragraphs with a fixed label width and hanging indent.
  The amount of hanging indent is specified with `dl_hangindent`, cf.
  `ul_hangindent`.
* `dl_labelwidth` : The minimum width to use for the "label" in a bibliography
  rendered in the `:dl` style.
* `bib_blockformat`: A LaTeX format command to apply for a bibliography block.
   Defaults to `"\raggedright"`, which avoids hyphenation within the
   bibliography. If set to an empty string, let LaTeX decide the default, which
   will generally result in fully justified text, with hyphenation.

These should be considered experimental and not part of the the stable API.

Options that are not specified remain unchanged from the defaults, respectively
a previous call to `set_latex_options`.

For bibliography blocks rendered in a `:dl` style, setting `dl_hangindent` and
`dl_labelwidth` to the same value (slightly larger than the width of the longest
label) produces results similar to the recommended styling in HTML, see
[CSS Styling](@ref). For very long citation labels, it may look better to have
a smaller `dl_hangindent`.

Throws an `ArgumentError` if called with invalid options.

The defaults can be reset with
[`DocumenterCitations.reset_latex_options`](@ref).
"""
function set_latex_options(; reset=false, kwargs...)
    global _LATEX_OPTIONS
    for (key, val) in kwargs
        if haskey(_LATEX_OPTIONS, key)
            required_type = typeof(_LATEX_OPTIONS[key])
            if typeof(val) == required_type
                _LATEX_OPTIONS[key] = val
            else
                throw(
                    ArgumentError(
                        "`$(repr(val))` for option $key in set_latex_options must be of type $(required_type), not $(typeof(val))"
                    )
                )
            end
        else
            throw(ArgumentError("$key is not a valid option in set_latex_options."))
        end
    end
end
