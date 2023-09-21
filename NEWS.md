# Release notes

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased][]

### Fixed

* Collect citations that only occur in docstrings [[#39][], [#40][]]


## [Version 1.2.0][1.2.0] - 2023-09-16

### Version changes

* Update to [Documenter 1.0](https://github.com/JuliaDocs/Documenter.jl/releases/tag/v1.0.0). The most notable user-facing breaking change in Documenter 1.0 affecting DocumenterCitations is that the `CitationBibliography` plugin object now has to be passed to `makedocs` as an element of the `plugins` keyword argument, instead of as a positional argument.

### Fixed

* The plugin no longer conflicts with the `linkcheck` option of `makedocs` [[#19][]]


## [Version 1.1.0][1.1.0] - 2023-09-15

### Fixed

* Avoid duplicate labels in `:alpha` style. This is implemented via the new stateful `AlphaStyle()`, but is handled automatically with (`style=:alpha`) [[#31][]]
* With the alphabetic style (`:alpha`/`AlphaStyle`), include up to 4 names in the label, not 3 (but 5 or more names results in 3 names and "+"). Also, include the first letter of a "particle" in the label, e.g. "vWB08" for a first author "von Winckel". Both of these are consistent with LaTeX's behavior.
* Handle missing author/year, especially for `:authoryar` and `:alpha` styles. You end up with `:alpha` labels like `Anon04` (missing authors) or `CW??` (missing year), and `:authoryear` citations like "(Anonymous, 2004)" and "(Corcovilos and Weiss, undated)".
* Consistent punctuation in the rendered bibliography, including for cases of missing fields.

### Added

* New `style=AlphaStyle()` that generates unique citation labels. This can mostly be considered internal, as `style=:alpha` is automatically upgraded to `style=AlphaStyle()`.
* Support for `eprint` field. It is recommended to add the arXiv ID in the `eprint` field for any article whose DOI is behind a paywall [[#32][]]
* Support for non-arXiv preprint servers BiorXiv and HAL [[#35][], [#36][]]
* Support for `note` field. [[#20][]]

### Changed

* In the rendered bibliography, the BibTeX "URL" field is now linked via the title, while the "DOI" is linked via the journal information. This allows to have a DOI and URL at the same time, or a URL for an `@unpublished`/`@misc` citation. If there is a URL but no title, the URL is used as the title.

### Internal Changes

* Added an internal function `init_bibliography!` that is called at the beginning of the `ExpandBibliography` pipeline step. This function is intended to initialize internal state either of the `style` object or the `CitationBibliography` plugin object before rendering any `@bibliography` blocks. This is used to generate unique citation labels for the new `AlphaStyle()`. For the other builtin styles, it is a no-op. Generally, `init_bibliography!` can help with implementing custom "stateful" styles.


## [Version 1.0.0][1.0.0] - 2023-07-12

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


[Unreleased]: https://github.com/JuliaDocs/DocumenterCitations.jl/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/JuliaDocs/DocumenterCitations.jl/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/JuliaDocs/DocumenterCitations.jl/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/JuliaDocs/DocumenterCitations.jl/compare/v0.2.12...v1.0.0
[#40]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/40
[#39]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/39
[#36]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/36
[#35]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/35
[#32]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/32
[#31]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/31
[#20]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/20
[#19]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/19
