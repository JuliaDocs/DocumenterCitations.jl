# Syntax

## Syntax for the Bibliography Block

### Default `@bibliograph` block

~~~markdown
```@bibliography
```
~~~

renders a bibliography for all references that are cited throughout the entire documentation, see [Cited References](@ref). The bibliography will not included entries that may be present in the `.bib` filer but that are not cited.


### Full `@bibliography`

~~~markdown
```@bibliography
*
```
~~~

Renders a bibliography for *all* references included in the `.bib` file, not just those cited in the documentation. This corresponds to the behavior of the  [DocumenterCitations.jl](https://github.com/ali-ramadhan/DocumenterCitations.jl) package.


### Multiple `@bibliography` blocks

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
will first show the all the cited references and then the non-cited references.
This exact setup is shown on the [References](@ref) page.

### Secondary `@bibliography` blocks

Sometimes it can be useful to render a subset of the bibliography, e.g. to show the references for a particular page. Two things are required to achieve this:

* To filter the bibliography to a specific page (or set of pages), add a `Pages` field to the `@bibliography` block.

* To get around the caveat explained in [Multiple `@bibliography` blocks](@ref) that there can only be one canonical target for each citation, add `Canonical = false` to the `@bibliography` block. The resulting bibliography will be rendered in full, but it will not serve as a link target. This is the only way to have a reference rendered more than once.

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

References in a `@bibliography` are rendered (and numbered) in the order in which they are cited. When there a multiple pages in the documentation, the order in which the pages appear in the navigation bar is relevant.

For a `@bibliography` block that includes non-cited references (the `*` in a [Full `@bibliography`](@ref)), the [`Bibliography.sorting_rules`](https://humans-of-julia.github.io/Bibliography.jl/stable/#Bibliography.sorting_rules) become relevant. When instantiating the plugin, a `sorting` argument can be passed to `CitationBibliography()`,

```julia
bib = CitationBibliography("refs.bib", sorting = :nyt)
```

which sorts otherwise non-cited references by author name, year, and title.


## Syntax for Citations

The following syntax is available to create citations in any markdown text:

* `[key](@cite)` is the default syntax, e.g. `Refs [GoerzQ2022](@cite) and [Tannor2007](@cite)` which is rendered as "Refs [GoerzQ2022](@cite) and [Tannor2007](@cite)".

* `[text](@cite key)` can be used to link to a reference from arbitrary text, e.g. `[the Semi-AD paper](@cite GoerzQ2022)` renders as "[the Semi-AD paper](@cite GoerzQ2022)".


### Citations in docstrings

In docstrings, citations can be made with the same syntax as above. However, since docstrings are also used outside the rendered documentation (e.g., in the REPL help mode), they should be more self-contained.

The recommended approach is to use a `# References` section in the docstring with an abbreviated bibliography list that links to the [main bibliography](@ref References). For example,

```markdown
# References

* [GoerzQ2022](@cite) Goerz et al. Quantum 6, 871 (2022)
```

in the documentation of the following `Example`:

```@docs
QuantumCitations.Example
```

(cf. the source of the `Example` type).

If there was no explicit numerical citation in the main text of the docstring,

```markdown
* [Goerz et al. Quantum 6, 871 (2022)](@cite GoerzQ2022)
```

rendering as

* [Goerz et al. Quantum 6, 871 (2022)](@cite GoerzQ2022)

would also have been an appropriate syntax.
