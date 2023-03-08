```@meta
CurrentModule = QuantumCitations
```

# Internals

```@docs
CitationBibliography
```

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

### Customization

Even though `QuantumCitations` targets the APS/REVTeX numeric citation style, it is technically possible to completely customize the rendering of citations and references by overwriting the [`format_bibliography_key`](@ref), [`format_bibliography_entry`](@ref), and [`format_citation`](@ref) methods detailed below.

```@docs
format_bibliography_key
format_bibliography_entry
format_citation
```

### Debugging

Set the environment variable `JULIA_DEBUG=Documenter,QuantumCitations` before generating the documentation.
