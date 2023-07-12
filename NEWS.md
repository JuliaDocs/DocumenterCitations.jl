# Release notes

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## Version v1.0.0 - to be released

### Version changes

* The minimum supported Julia version has been raised from 1.4 to 1.6.

### Breaking

* The default citation style has changed to `:numeric`. To restore the author-year style used pre-1.0, instantiate `CitationBibliography` with the option `style=:authoryear` in `docs/make.jl` before passing it to `makedocs`.
* Only cited references are included in the main bibliography by default, as opposed to all references defined in the underlying `.bib` file.

### Added

* A `style` keyword argument for `CitationBibliography`. The default style is `style=:numeric`. Other built-in styles are `style=:authoryear` (corresponding to the pre-1.0 style) and `style=:alpha`.
* It is now possible to implement [custom citation styles](https://juliadocs.org/DocumenterCitations.jl/dev/gallery/#custom_styles).
* The `@bibligraphy` block can now have additional options to customize which references are included, see [Syntax for the Bibliography Block](https://juliadocs.org/DocumenterCitations.jl/dev/syntax/#Syntax-for-the-Bibliography-Block).
* It is possible to generate [secondary bibliographies](https://juliadocs.org/DocumenterCitations.jl/dev/syntax/#noncanonical), e.g., for a specific page.
* There is [new syntax](https://juliadocs.org/DocumenterCitations.jl/dev/syntax/#Syntax-for-Citations) to create links to bibliographic references with arbitrary text.
* The following variations of the `@cite` command are now supported: `@citet`, `@citep`, `@cite*`, `@citet*`, `@citep*`, `@Citet`, `@Citep`, `@Cite*`, `@Citet*`, `@Citep*`.  See the [syntax for citations](https://juliadocs.org/DocumenterCitations.jl/dev/syntax/#Syntax-for-Citations) for details.
* Citations can now include notes, e.g., `See Ref. [GoerzQ2022; Eq. (1)](@cite)`.

### Other

* [DocumenterCitations](https://github.com/JuliaDocs/DocumenterCitations.jl) is now hosted under the [JuliaDocs](https://github.com/JuliaDocs) organization.
