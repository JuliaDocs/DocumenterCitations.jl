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

The [natbib](https://mirrors.rit.edu/CTAN/macros/latex/contrib/natbib/natnotes.pdf) commands `@citealt`, `@citealp`, and `@citenum` commands are also recognized. They are not supported by any of the built-in style, but  may be handled by [custom styles](@ref customization).

See the [Citation Style Gallery](@ref) for examples for all the possible combinations.


### Citations in docstrings

In docstrings, citations can be made with the same syntax as above. However, since docstrings are also used outside of the rendered documentation (e.g., in the REPL help mode), they should be more self-contained.

The recommended approach is to use a `# References` section in the docstring with an abbreviated bibliography list that links to the [main bibliography](@ref References). For example,

```markdown
# References

* [GoerzQ2022](@cite) Goerz et al. Quantum 6, 871 (2022)
```

in the documentation of the following `Example`:

```@docs
QuantumCitations.Example
```

(cf. the [source of the `Example` type](https://github.com/JuliaQuantumControl/QuantumCitations.jl/blob/38693339ba8da08aebacdd664acb2c7e23cf1628/src/QuantumCitations.jl#L67-L76)).

If there was no explicit numerical citation in the main text of the docstring,

```markdown
* [Goerz et al. Quantum 6, 871 (2022)](@cite GoerzQ2022)
```

rendering as

* [Goerz et al. Quantum 6, 871 (2022)](@cite GoerzQ2022)

would also have been an appropriate syntax.


## Syntax for the Bibliography Block

### Default `@bibliograph` block

~~~markdown
```@bibliography
```
~~~

renders a bibliography for all references that are cited throughout the entire documentation, see [Cited References](@ref). The bibliography will not include entries that may be present in the `.bib` file, but that are not cited.


### [Full `@bibliography`](@id full_bibliography)

~~~markdown
```@bibliography
*
```
~~~

Renders a bibliography for *all* references included in the `.bib` file, not just those cited in the documentation. This corresponds to the behavior of the  [DocumenterCitations.jl](https://github.com/ali-ramadhan/DocumenterCitations.jl) package.


### [Multiple `@bibliography` blocks](@id canonical)

It is possible to have multiple `@bibliography` blocks. However, there can only be one "canonical" bibliography target for any citation (the location where a citation links to). Any `@bibliography` block will automatically skip entries that have already been rendered in an earlier `@bibliography` block. Thus, for two consecutive

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

renders a bibliography only for the citations on the [Home](@ref QuantumCitations.jl) page:

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

In general, the citation style determines the order of the references, see the [Citation Style Gallery](@ref).


## Syntax for the .bib file

The [`refs.bib`](./refs.bib) file is in the standard [BibTeX format](https://www.bibtex.com/g/bibtex-format/). It must be parsable by [BibParser.jl](https://github.com/Humans-of-Julia/BibParser.jl).

The use of `@string` macros for abbreviated journal names is encouraged, with the caveat of [#31](https://github.com/Humans-of-Julia/BibParser.jl/issues/31) and [#32](https://github.com/Humans-of-Julia/BibParser.jl/issues/32) in the [BibParser.jl issues](https://github.com/Humans-of-Julia/BibParser.jl/issues).

Also, even though `QuantumCitations` has limited support for [escaped symbols](http://www.bibtex.org/SpecialSymbols/), the full use of unicode is both supported and strongly encouraged.

All entries should have a `Doi` field, or a `Url` field if no DOI is available.

You may be interested in using the [`getbibtex` script](https://github.com/goerz/getbibtex) to generate consistent `.bib` files.
