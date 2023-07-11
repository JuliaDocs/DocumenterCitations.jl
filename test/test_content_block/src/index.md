# Testing that DocumenterCitations works with Contents blocks

## Contents

```@contents
Pages = ["index.md", "references.md"]
```


## Problem description

As reported in [#16](https://github.com/JuliaDocs/DocumenterCitations.jl/issues/16) and [ali-ramadhan/DocumenterCitations.jl#24](https://github.com/ali-ramadhan/DocumenterCitations.jl/issues/24), there have been problems with the DocumenterCitations plugin and `@contents` blocks.

Having a `@contents` block that includes any `Pages` that also have a `@bibliography` block causes a crash like this:

```
ERROR: LoadError: MethodError: no method matching header_level(::BibInternal.Entry)

Closest candidates are:
  header_level(::Markdown.Header{N}) where N
   @ Documenter ~/.julia/packages/Documenter/bYYzK/src/Utilities/Utilities.jl:380
```


## Workarounds

Guillaume Gautier [guilgautier](@cite) provides the following workaround:

> I'll propose the above dirty fix in #24, namely
> Remove the file where the @bibliography block is called (here reference.md), from the list of Pages involved in all @contents block.
