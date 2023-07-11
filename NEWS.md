# v0.3.0

* [DocumenterCitations](https://github.com/JuliaDocs/DocumenterCitations.jl) is now hosted in the [JuliaDocs](https://github.com/JuliaDocs) organization
* The minimum supported Julia version is now 1.6
* The default citation style has changed to `:numeric`. To restore the author-year style used in previous version, instantiate `CitationBibliography` with the option `style=:authoryear` in `docs/make.jl` before passing it to `makedocs`
* Only cited references are included in the main bibliography by default, as opposed to all references in the underlying `.bib` file.
* The `@bibligraphy` block can now have additional options to customize which references are included, see [Syntax for the Bibliography Block](https://juliadocs.org/DocumenterCitations.jl/dev/syntax/#Syntax-for-the-Bibliography-Block).
* It is possible to generate [secondary bibliographies](https://juliadocs.org/DocumenterCitations.jl/dev/syntax/#noncanonical), e.g., for a specific page.
* There is [Syntax](https://juliadocs.org/DocumenterCitations.jl/dev/syntax/#Syntax-for-Citations) to create links to bibliographic references, with arbitrary text.
* The following variations of the `@cite` command are now supported: `@citet`, `@citep`, `@cite*`, `@citet*`, `@citep*`, `@Citet`, `@Citep`, `@Cite*`, `@Citet*`, `@Citep*`.  See [Syntax for Citations](https://juliadocs.org/DocumenterCitations.jl/dev/syntax/#Syntax-for-Citations) for details.
* Citations can now include notes, e.g., `See Ref. [GoerzQ2022; Eq. (1)](@cite)`
