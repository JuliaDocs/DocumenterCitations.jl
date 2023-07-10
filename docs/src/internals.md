```@meta
CurrentModule = QuantumCitations
```

# Internals

```@docs
CitationBibliography
```

## Citation Pipeline

The [`QuantumCitations.CitationBibliography`](@ref) plugin hooks into the [`Documenter.Builder.DocumentPipeline`](https://documenter.juliadocs.org/stable/lib/internals/builder/#Documenter.Builder.DocumentPipeline)[^1] between [`ExpandTemplates`](https://documenter.juliadocs.org/stable/lib/internals/builder/#Documenter.Builder.ExpandTemplates) (which expands `@docs` blocks) and [`CrossReferences`](https://documenter.juliadocs.org/stable/lib/internals/builder/#Documenter.Builder.CrossReferences). The plugin adds the following three steps:

[^1]: See the documentation of [`Documenter.Utilities.Selectors`](https://documenter.juliadocs.org/stable/lib/internals/selectors/#Documenter.Utilities.Selectors) for an explanation of Documenter's pipeline concept.

1. [`CollectCitations`](@ref)
2. [`ExpandBibliography`](@ref)
3. [`ExpandCitations`](@ref)


```@docs
CollectCitations
ExpandBibliography
ExpandCitations
```

## [Customization](@id customization)

A custom style can be created by defining methods for functions listed below that specialize for a user-defined `style` argument to [`CitationBibliography`](@ref). If the `style` is identified by a simple name, e.g. `:mystyle`, the method should specialize on `Val{:mystyle}`, see the [examples for custom styles](@ref custom_styles). Beyond that, e.g., if the `style` needs to implement options or needs to maintain internal state to manage unique citation labels, `style` can be an object of a custom type.


```@docs
bib_html_list_style
bib_sorting
format_bibliography_label
format_bibliography_reference
format_citation
```

## Debugging

Set the environment variable `JULIA_DEBUG=Documenter,QuantumCitations` before generating the documentation.
