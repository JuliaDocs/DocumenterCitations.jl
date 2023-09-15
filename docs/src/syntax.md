# Syntax

## Syntax for Citations

The following syntax is available to create citations in any markdown text:

* `[key](@cite)` is the basic syntax, e.g., `Refs. [GoerzQ2022](@cite) and [Tannor2007](@cite)` which is rendered in the default numeric style as "Refs. [GoerzQ2022](@cite) and [Tannor2007](@cite)".

* `[key; note](@cite)` allows to include a note in the citation, e.g., `See Ref. [GoerzQ2022; Eq. (1)](@cite)` which is rendered as "See Ref. [GoerzQ2022; Eq. (1)](@cite)".

* `[text](@cite key)` can be used to link to a reference from arbitrary text, e.g., `[the Semi-AD paper](@cite GoerzQ2022)` renders as "[the Semi-AD paper](@cite GoerzQ2022)".

In `[…](@cite)`, the following variations can be used instead of `@cite`:

* `@citet`: Text-style citation. This embeds the citation in the text flow, e.g., "As shown by [GoerzQ2022](@citet)…". For the default numeric citations, this is an alternative to "As shown in Ref. [GoerzQ2022](@cite)"
* `@citep`: Parenthetical citation. For the built-in styles, this is equivalent to just `@cite`.
* `@citet*`: Like `@citet`, but with the full list of authors, e.g., [GoerzQ2022](@citet*).
* `@cite*`/`@citep*`: Like `@cite`/`@citep`, but with the full list of authors ([for non-numeric styles where this makes sense](@ref author_year_style)).

Lastly, capitalizing the `c` in `@citet` or `@citet*` ensures that the first letter of the citation is capitalized so that it can be used at the beginning of a sentence, e.g., [WinckelIP2008](@Citet) (`[WinckelIP2008](@Citet)`) versus [WinckelIP2008](@citet) (`[WinckelIP2008](@citet)`).

The [natbib](https://mirrors.rit.edu/CTAN/macros/latex/contrib/natbib/natnotes.pdf) commands `@citealt`, `@citealp`, and `@citenum` commands are also recognized. They are not supported by any of the built-in styles, but  may be handled by [custom styles](@ref customization).

See the [Citation Style Gallery](@ref gallery) for examples of all the possible combinations.


### Citations in docstrings

In docstrings, citations can be made with the same syntax as above. However, since docstrings are also used outside of the rendered documentation (e.g., in the REPL help mode), they should be more self-contained.

The recommended approach is to use a `# References` section in the docstring with an abbreviated bibliography list that links to the [main bibliography](@ref References). For example,

```markdown
# References

* [GoerzQ2022](@cite) Goerz et al. Quantum 6, 871 (2022)
```

in the documentation of the following `Example`:

```@docs
DocumenterCitations.Example
```

(cf. the [source of the `Example` type](https://github.com/JuliaDocs/DocumenterCitations.jl/blob/3b208240f29f9fe7104d27c90f0c324517d18ba6/src/DocumenterCitations.jl#L100-L110)).

If there was no explicit numerical citation in the main text of the docstring,

```markdown
* [Goerz et al. Quantum 6, 871 (2022)](@cite GoerzQ2022)
```

rendering as

* [Goerz et al. Quantum 6, 871 (2022)](@cite GoerzQ2022)

would also have been an appropriate syntax.


## Syntax for the Bibliography Block

### Default `@bibliography` block

~~~markdown
```@bibliography
```
~~~

renders a bibliography for all references that are cited throughout the entire documentation, see [Cited References](@ref). As of version 1.0, the bibliography will not include entries that may be present in the `.bib` file, but that are not cited.


### [Full `@bibliography`](@id full_bibliography)

~~~markdown
```@bibliography
*
```
~~~

Renders a bibliography for *all* references included in the `.bib` file, not just those cited in the documentation. This corresponds to the pre-1.0 default behavior.


### [Multiple `@bibliography` blocks](@id canonical)

It is possible to have multiple `@bibliography` blocks. However, there can only be one "canonical" bibliography target for any citation (the location where a citation links to). Any `@bibliography` block will automatically skip entries that have already been rendered in an earlier canonical `@bibliography` block. Thus, for two consecutive

~~~markdown
```@bibliography
```
~~~

blocks, the second block will not show anything.

On the other hand,
~~~markdown
```@bibliography
```

```@bibliography
*
```
~~~
will first show all the cited references and then all the non-cited references.
This exact setup is shown on the [References](@ref) page.

### [Secondary `@bibliography` blocks](@id noncanonical)

Sometimes it can be useful to render a subset of the bibliography, e.g., to show the references for a particular page. Two things are required to achieve this:

* To filter the bibliography to a specific page (or set of pages), add a `Pages` field to the `@bibliography` block.

* To get around the caveat with [multiple `@bibliography` blocks](@ref canonical) that there can only be one canonical target for each citation, add `Canonical = false` to the `@bibliography` block. The resulting bibliography will be rendered in full, but it will not serve as a link target. This is the only way to have a reference rendered more than once.

For example,

~~~markdown
```@bibliography
Pages = ["index.md"]
Canonical = false
```
~~~

renders a bibliography only for the citations on the [Home](@ref DocumenterCitations.jl) page:

```@bibliography
Pages = ["index.md"]
Canonical = false
```

Usually, you would have this at the bottom of a page, as in [Home References](@ref).

Another possibility that is appropriate for [Citations in docstrings](@ref) is to write out a shortened bibliography "by hand".


### Explicit references

A non-canonical `@bibliography` block can also be used to render a bibliography for a few specific citations keys:

~~~markdown
```@bibliography
Pages = []
Canonical = false

BrifNJP2010
GoerzDiploma2010
GoerzPhd2015
```
~~~

renders a bibliography only for the references
[BrifNJP2010](@cite BrifNJP2010),
[GoerzDiploma2010](@cite GoerzDiploma2010), and [GoerzPhd2015](@cite GoerzPhd2015):

```@bibliography
Pages = []
Canonical = false

BrifNJP2010
GoerzDiploma2010
GoerzPhd2015
```

The `Pages = []` is required to exclude all other cited references.
Note that the numbers [BrifNJP2010](@cite), [GoerzDiploma2010](@cite), and [GoerzPhd2015](@cite) are from the main (canonical) [References](@ref) page.

### Order of references

In the default numeric style, references in a `@bibliography` are rendered (and numbered) in the order in which they are cited. When there are multiple pages in the documentation, the order in which the pages appear in the navigation bar is relevant.

Non-cited references ([`*` in a full bibliography](@ref full_bibliography)) will appear in the order they are listed in the underlying `.bib` file. That order may be changed by [sorting it explicitly](https://humans-of-julia.github.io/Bibliography.jl/stable/#Bibliography.sort_bibliography!):

```julia
bib = CitationBibliography("refs.bib")

using Bibliography
sort_bibliography!(bib.entries, :nyt)  # name-year-title
```

In general, the citation style determines the order of the references, see the [Citation Style Gallery](@ref gallery).


## Syntax for the .bib file

The [`refs.bib`](./refs.bib) file is in the standard [BibTeX format](https://www.bibtex.com/g/bibtex-format/). It must be parsable by [BibParser.jl](https://github.com/Humans-of-Julia/BibParser.jl).

You will find that you get the best results by maintaining a `.bib` files by hand, specifically for a given project using `DocumenterCitations`. A `.bib` file that works well with LaTeX may or may not work well with `DocumenterCitations`: remember that in LaTeX, the strings inside any BibTeX fields are rendered through the TeX engine. At least in principle, they may contain arbitrary macros.

In contrast, for `DocumenterCitations`, the BibTeX fields are minimally processed to convert some common LaTeX constructs to plain text, but beyond that, they are used "as-is". In future versions, the handling of LaTeX macros may improve, but it is best not to rely on it, and instead edit the `.bib` file so that it gives good results with `DocumenterCitations` (see the tips below).

While we try to be reasonably compatible, "Any `.bib` file will render the bibliography you expect" is not a design goal, but "It is possible to write a `.bib` file so that you get exactly the bibliography you want" is.

Some tips to keep in mind when editing a `.bib` file to be used with `DocumenterCitations`:

* Use unicode instead of [escaped symbols](http://www.bibtex.org/SpecialSymbols/).
* You do not need to use [braces to protect capitalization](https://texfaq.org/FAQ-capbibtex). `DocumenterCitations` is not always able to remove such braces. But, unlike `bibtex`, `DocumenterCitation` will preserve the capitalization of titles.
* Use a consistent scheme for citation keys. Shorter keys are better.
* All entries should have a `Doi` field, or a `Url` field if no DOI is available.
* Use `@string` macros for abbreviated journal names, with the caveat of [#31](https://github.com/Humans-of-Julia/BibParser.jl/issues/31) and [#32](https://github.com/Humans-of-Julia/BibParser.jl/issues/32) in the [BibParser.jl issues](https://github.com/Humans-of-Julia/BibParser.jl/issues).


You may be interested in using (or forking) the [`getbibtex` script](https://github.com/goerz/getbibtex) to generate consistent `.bib` files.


### Preprint support

If the published paper (`Doi` link) is not open-access, but a version of the paper is available on a preprint server like the [arXiv](https://arxiv.org), your are strongly encouraged to add the arXiv ID as `Eprint` in the BibTeX entry. In the rendered bibliography, the preprint information will be shown and automatically link to `https://arxiv.org/abs/<ID>`.
If necessary, you may also add a `Primaryclass` field to indicate a category, see ["BibTeX and Eprints" in the arXiv documentation](https://info.arxiv.org/help/hypertex/bibstyles/index.html).

Note that unlike in [default](https://tex.stackexchange.com/questions/386078/workaround-for-missing-archiveprefix-in-bib-entry) BibTeX, it is not necessary to define `Archiveprefix` in the `.bib` file. A missing `Archiveprefix` is assumed to be `arXiv`. The field name `Eprinttype` (which in BibTeX is an alias for `Archiveprefix`) is currently not yet supported, nor is `Eprintclass` as an alias for `Primaryclass`.

For documents that are available *only* as an arXiv eprint, the best result is obtained with a BibTeX entry using the `@article` class, with, e.g., `arXiv:2003.10132` in the `Journal` field, and, e.g., `10.48550/ARXIV.2003.10132` in the `Doi` field (but no `Eprint` field) [Wilhelm2003.10132](@cite).

Beyond arXiv, other preprint servers are supported. The `Archiveprefix` field for non-arXiv preprints is mandatory. For any defined `Archiveprefix`, `Eprint`, and `Primaryclass` fields, the rendered bibliography will include the preprint information in the format `ArchivePrefix:Eprint [Primaryclass]`. However, only certain preprint servers (known `ArchivePrefix`) will automatically be linked. Besides arXiv, the currently supported preprint servers are:

* [BiorXiv](https://www.biorxiv.org). The `Archiveprefix` is `biorXiv`. The `Eprint` ID should be the final part of the DOI, e.g. `2022.09.09.507322` [KatrukhaNC2017](@cite).
* [HAL](https://hal.science). The `Archiveprefix` is `HAL`. The `Eprint` ID should include the prefix (usually `hal-`, but sometimes `tel-`, etc.), e.g., Refs [SauvagePRXQ2020](@cite) and [BrionPhd2004](@cite).

If you would like support for any additional preprint server, [please open an issue](https://github.com/JuliaDocs/DocumenterCitations.jl/issues/new/choose).
