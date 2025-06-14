# Release notes

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Unreleased][]


## [Version 1.4.0][1.4.0] - 2025-06-14

### Added

* The `CitationBibliography` plugin object now has an internal field `anchor_keys` that is a bijective mapping of citation keys to HTML anchor names. The anchor names are normalized versions of the citation keys that are restricted to ASCII alphanumerics, dashes (`-`) and underscores (`_`). This provides [compatibility with HTML4](https://www.w3.org/TR/html4/types.html#type-id) and additionally [avoids issues with CSS selectors](https://stackoverflow.com/a/79022). It also works around restrictions of the `Documenter.DOM` framework that is used internally to render HTML content. [[#95][]]


### Fixed

* Citation keys the contain special characters (like colons) no longer produce broken links. This is achieved by normalizing HTML anchor names to contain only alphanumeric ASCII characters, dashes, and underscores [[#86][], [#95][]]


## [Version 1.3.7][1.3.7] - 2025-03-29

### Fixed

* Show error file paths consistently with `Documenter`. With `Documenter < 1.10`, paths in error messages are relative to the `docs` folder. With `Documenter >= 1.10`, they are relative to the current working directory [[#89][]]


## [Version 1.3.6][1.3.6] - 2025-03-01

### Fixed

* The `format_authoryear_bibliography_reference` function with `article_link_doi_in_title = true` would link the DOI both from the journal reference and from the title. Now, the DOI is linked from the journal when `article_link_doi_in_title = false` and from the title when `article_link_doi_in_title = true`. [[#87][]]


## [Version 1.3.5][1.3.5] - 2024-11-14

### Fixed

* Compatibility with [BibInternals v0.3.7](https://github.com/Humans-of-Julia/BibInternal.jl/releases/tag/v0.3.7) [[#80][], [#83][]]
* Allow LaTeX escape codes to appear at the beginning of a first name. That is, names are now un-escaped before generating name initials. [[#78][], [#83][]]

### Internal Changes

* The internal `format_labeled_bibliography_reference` function now forwards keyword arguments to the internal `format_names` functions. This makes it easier to customize styles, e.g., to limit the number of author before "et al." is used. [[#79][]]


## [Version 1.3.4][1.3.4] - 2024-09-19

### Internal Changes

* Added an `article_link_doi_in_title` option to the internal `format_published_in` and `format_labeled_bibliography_reference` functions. This allows custom styles to change how links appear in bibliography entries for articles. By setting the option to `true`, the title of the article,instead of the "published in" information, will be used as the link text for a DOI . This makes the bibliography for articles more consistent with other types or entries, but is recommended only if no entries have both a DOI and a URL. [[#73][], [#74][]]


## [Version 1.3.3][1.3.3] - 2024-03-08

### Fixed

* The recommended CSS (`citations.css`) now includes a fix to be compatible with the dark-mode CSS of Documenter. Existing pages should update their `citations.css` to add `!important` to the `list-style` of `.citation ul`. [[#70][]]


## [Version 1.3.2][1.3.2] - 2023-11-29

### Fixed

* Warn about markdown link syntax in `.bib` files [[#60][]]
* Warn about invalid DOIs in `.bib` files. The DOI field should never contain a URL (`https://doi.org/...`). However, such usage is detected as a special case, and the DOI is automatically extracted from the URL.
* Automatically link both URL and DOI fields. This fixes a regression in `v1.3.0`, which would throw an error for `@book` and `@proceeding` entries with both a URL and a DOI field. Now, the URL in such a case will be automatically linked via the `Title` field, and the DOI via the `organization`/`publisher`/`address` fields, similar to the behavior in `v1.2.0`. You may prefer to have the DOI linked via that `Title`, in which case you should add a `Note` field containing the `URL` (using `\url`/`\href`, as appropriate). [[#65][]]
* Calling `makedocs` with `linkcheck=true` now also checks links (e.g., DOIs) inside the bibliography. Note that the correct behavior requires [Documenter 1.2](https://github.com/JuliaDocs/Documenter.jl/releases/tag/v1.2.0). With older versions of Documenter, broken links in the bibliography will be silently ignored. [[#58][], [#62][], [Documenter#2329](https://github.com/JuliaDocs/Documenter.jl/issues/2329), [Documenter#2330](https://github.com/JuliaDocs/Documenter.jl/pull/2330)]


## [Version 1.3.1][1.3.1] - 2023-11-02

### Fixed

* Added a fallback for the `Pages` attribute in a `@bibliography` block to behave as in pre-`1.3.0`: If `Pages` references a file with a path relative to the `docs/src` directory (which was the unintentional requirement pre-`1.3.0`), this now works again, but shows a warning that the name should be updated to be relative to the folder containing the file that contains the `@bibliography` block. [[#61][]]

  This fixes the `v1.3.0` release arguably having been "breaking" [[#59][]] in that anybody who was using `Pages` pre-1.3.0 would have had to use paths relative to `docs/src`, even though that was a workaround for a known bug [[#22][]]. Note that whenever `Pages` references the current file, `@__FILE__` should be used.


## [Version 1.3.0][1.3.0] - 2023-11-01

### Fixed

* Skip the expansion of citations and bibliographies when running in doctest mode [[#34][]]
* Support underscores in citation keys [[#14][]]
* The `Pages` in a `@bibliography` block are now relative to the folder containing the current file. The behavior is consistent with `Pages` in Documenter's `@index` and `@contents` blocks. [[#22][]]
* The parsing of LaTeX strings has improved significantly. In particular, curly braces should now be stripped correctly [[#15][]]. Note that that braces in titles are never needed for `DocumenterCitations`, but handling them correctly makes it easier to use the same `.bib` file for LaTeX and `DocumenterCitations`.
* Fixed the rendering of references other than `@article`, especially `@inproceedings`, `@incollection`, `@inbooks`, mimicking RevTeX. The DOI/URL are now linked via the Title and/or Booktitle. Added support for `Chapter`, `Volume`, `Number`, `Edition`, `Month` fields. [[#56][]]

### Added

* Allow multiple citations in a single `@cite` link. In the default numeric style, these can be compressed, e.g. "Refs. [1–3]" [[#6][]]
* In general (depending on the style and citation syntax), citation links may now render to arbitrarily complex expressions.
* Citation comments can now have inline markdown elements, e.g., `[GoerzQ2022; definition of $J$ in section *Running costs*](@cite)`
* When running in non-strict mode, missing bibliographic references (either because the `.bib` file does not contain an entry with a specific BibTeX key, or because of a missing `@biblography` block) are now handled similarly to missing references in LaTeX: They will show as (unlinked) question marks.
* Support for bibliographies in PDFs generate via LaTeX (`format=Documenter.LaTeX()`). Citations and references are rendered exactly as in the HTML version. Specifically, the support does not depend on `bibtex`/`biblatex` and supports any style (including custom styles). [[#18][]]
* Functions `DocumenterCitations.set_latex_options` and `DocumenterCitations.reset_latex_options` to tweak the rendering of bibliographies in PDFs.
* The `Pages` in a `@bibliography` block can now use `@__FILE__` to refer to the current file. [[#22][]]
* You may now use `\url` and `\href` commands in the `@misc` field of an entry.
* The `Urldate` field is now supported for citing websites. [[#53][]]

### Internal Changes

* Removed the redundant `CitationLink.link_text` field.
* Added `read_citation_link` replacing the former `CitationLink` constructor.
* `CitationLink` can now be instantiated directly from markdown strings (for documentation / testing purposes)
* Added `DirectCitationLink` type to represent citations of the form `[text](@cite key)`.
* Exposed `CitationLink` to users who want to implement a custom style (see changes in `format_citation`)
* The interface for the `format_citation` function has changed: Before, the signature was `format_citation(style, entry, citations; note, cite_cmd, capitalize, starred)` and the function would return as string that would replace the link text of the citation link. Now, the signature is `format_citation(style, cit, entries, citations)` where `cit` is a `CitationLink` object, and the function returns a string of markdown code that replaces the *entire* citation link (not just the link text).  Generally, the returned markdown code is expected to contain *direct* citation links which, are automatically expanded subsequently. That is, `format_citation` now generally converts indirect citation links (`CitationLink`) into direct citation links (`DirectCitationLink`).
* Exposed the internal function `format_labeled_citation` that implements `format_citation` for the built-in styles `:numeric` and `:alpha` and may be useful for custom styles that are variations of these.
* Exposed the internal function `format_authoryear_citation` that implements `format_citation` for the built-in style `:authoryear`
* Exposed the internal function `format_labeled_bibliography_reference` that implements `format_bibliography_reference` for the built-in styles `:numeric` and `:alpha`.
* Exposed the internal function `format_authoryear_bibliography_reference` that implements `format_bibliography_reference` for the built-in style `:authoryear:`.
* The example custom styles `:enumauthoryear` and `:keylabels` have been rewritten using the above internal functions, illustrating that custom styles will usually not have to rely on the undocumented and even more internal functions like `format_names` and `tex2unicode`.
* Any `@bibliography` block is now internally expanded into an internal `BibliographyNode` instead of a raw HTML node. This `BibliographyNode` can then be translated into the desired output format by `Documenter.HTMLWriter` or `Documenter.LaTeXWriter`. This is how support for bibliographies with `format=Documenter.LaTeX()` can be achieved.
* The routine `format_bibliography_reference` must now return a markdown string instead of an HTML string.

**Upgrade guidelines**:

For anyone who was using custom styles, which rely on the [Internals](https://juliadocs.org/DocumenterCitations.jl/stable/internals/) of `DocumenterCitations`, this release will almost certainly break the customization. See the above list of internal changes.

There were several bugs and limitations in version `1.2.x` for which some existing documentations may have been using workarounds. These workarounds may cause some breakage in the new version `1.3.0`. In particular:

* The `Pages` attribute in a `@bibliography` block in version `1.2.x` required any names to be relative to the `docs/src` directory [[#22][]]. This was both unintentional and undocumented. These names must now be updated to be relative to to the folder containing the file which contains the `@bibliography` block. This is consistent with how `Pages` is used, e.g., in `@contents` or `@index` blocks. For the common usage where `Pages` was referring to the current file, `@__FILE__` should be used.

* Pre-`1.3.0`, strings in entries in the `.bib` file were extremely limited.  There was no official support for any kind of `tex` macros: only plain-text (unicode) was fully supported. As a workaround, some users exploited an (undocumented/buggy) implementation detail that would cause html or markdown strings inside the `.bib` file to "work", e.g. for adding links in a `note` field. These workarounds may break in `v1.3.0`. While unicode is still very much supported (`ö` over `\"{o}`), `.bib` files should otherwise be written to be fully compatible with `bibtex`. For links in particular, the LaTeX `\href` macro should be used. Any `tex` commands that are not supported  (`Error: Unsupported command`) should be reported. Some `tex` characters (`$%@{}&`) that may have worked directly pre-`1.3.0` will have to be escaped in version `1.3.0`.


## [Version 1.2.1][1.2.1] - 2023-09-22

### Fixed

* Collect citations that only occur in docstrings [[#39][], [#40][]]
* It is now possible to have a page that contains a `@bibliography` block listed in [`@contents`](https://documenter.juliadocs.org/stable/man/syntax/index.html#@contents-block) [[#16][], [#42][]].


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


[Unreleased]: https://github.com/JuliaDocs/DocumenterCitations.jl/compare/v1.4.0...HEAD
[1.4.0]: https://github.com/JuliaDocs/DocumenterCitations.jl/compare/v1.3.7...v1.4.0
[1.3.7]: https://github.com/JuliaDocs/DocumenterCitations.jl/compare/v1.3.6...v1.3.7
[1.3.6]: https://github.com/JuliaDocs/DocumenterCitations.jl/compare/v1.3.5...v1.3.6
[1.3.5]: https://github.com/JuliaDocs/DocumenterCitations.jl/compare/v1.3.4...v1.3.5
[1.3.4]: https://github.com/JuliaDocs/DocumenterCitations.jl/compare/v1.3.3...v1.3.4
[1.3.3]: https://github.com/JuliaDocs/DocumenterCitations.jl/compare/v1.3.2...v1.3.3
[1.3.2]: https://github.com/JuliaDocs/DocumenterCitations.jl/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/JuliaDocs/DocumenterCitations.jl/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/JuliaDocs/DocumenterCitations.jl/compare/v1.2.1...v1.3.0
[1.2.1]: https://github.com/JuliaDocs/DocumenterCitations.jl/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/JuliaDocs/DocumenterCitations.jl/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/JuliaDocs/DocumenterCitations.jl/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/JuliaDocs/DocumenterCitations.jl/compare/v0.2.12...v1.0.0
[#95]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/95
[#89]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/89
[#87]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/87
[#86]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/86
[#83]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/83
[#80]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/80
[#79]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/79
[#78]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/78
[#74]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/74
[#73]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/73
[#70]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/70
[#65]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/65
[#62]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/62
[#61]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/61
[#60]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/60
[#59]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/59
[#58]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/58
[#56]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/56
[#53]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/53
[#42]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/42
[#40]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/40
[#39]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/39
[#36]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/36
[#35]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/35
[#34]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/34
[#32]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/32
[#31]: https://github.com/JuliaDocs/DocumenterCitations.jl/pull/31
[#22]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/22
[#20]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/20
[#19]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/19
[#18]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/18
[#16]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/16
[#15]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/15
[#14]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/14
[#6]: https://github.com/JuliaDocs/DocumenterCitations.jl/issues/6
