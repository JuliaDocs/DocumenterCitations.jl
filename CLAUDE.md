# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

DocumenterCitations.jl is a [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl)
plugin that adds BibTeX citation support to documentation. Users instantiate a
`CitationBibliography` plugin object from a `.bib` file and pass it to
`makedocs`. The package then injects pipeline steps into Documenter's build
process to collect `@cite` links, expand `@bibliography` blocks, and render
citations in a chosen style (`:numeric` (default), `:authoryear`, `:alpha`, or
custom).

## Development

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the development workflow: running
tests (including single test files and the `run_makedocs` helper), building the
documentation, the code-style guide, semantic versioning, and the release
process. Always read @CONTRIBUTING.md.

## Architecture

### Plugin and pipeline integration

The core is the `CitationBibliography <: Documenter.Plugin` struct in
`src/DocumenterCitations.jl`. It carries both user config (`bibfile`, `style`)
and mutable internal state that the pipeline steps populate during a build:
`entries`, `citations` (key → citation number, assigned in encounter order),
`page_citations`, `anchor_map`, and `anchor_keys` (a bijection of citation keys
to sanitized HTML anchor names). These internal fields are not part of the
stable API.

The package hooks into Documenter by defining three `Builder.DocumentPipeline`
subtypes, each ordered to run at a specific point relative to Documenter's own
steps (set via `Selectors.order`):

1. `CollectCitations` (order `2.11`, after `ExpandTemplates`) —
   `src/collect_citations.jl`. Walks all pages in navigation order, finds
   `@cite` links (including inside expanded docstrings, whose ASTs are separate
   from the page tree), and fills `citations` / `page_citations`. **Encounter
   order here determines numeric citation labels.**
2. `ExpandBibliography` (order `2.12`) — `src/expand_bibliography.jl`. Expands
   `@bibliography` blocks into rendered reference lists and registers link
   anchors in `anchor_map`.
3. `ExpandCitations` (order `2.13`) — `src/expand_citations.jl`. Replaces each
   `@cite` link with style-specific markdown, resolving link targets against the
   anchors created in the previous step.

Citation/bibliography errors are accumulated in `doc.internal.errors` under the
custom error names `:citations` and `:bibliography_block`, registered in
`__init__`.

### Citation link parsing

`src/citation_link.jl` parses the `[...](@cite)` markdown syntax into
`CitationLink` / `DirectCitationLink` objects (handling `@cite`, `@citet`,
`@citep`, etc., plus multiple keys). Note the normalization in the constructor:
`*` in BibTeX keys is normalized to `_` (both are markdown emphasis markers), so
keys differing only by `*` vs `_` are rejected as ambiguous.

### Styles

A "style" is dispatched on the `style` field of `CitationBibliography`.
Built-in styles are `Symbol`s wrapped in `Val` (`Val{:numeric}` etc.) in
`src/styles/{numeric,authoryear,alpha}.jl`; `AlphaStyle` is a struct (a "smart"
alpha that disambiguates duplicate labels via a `label_for_key` map populated at
the start of `ExpandBibliography`). A style implements a small set of generic
functions:

- `format_citation(style, cit, entries, citations)` — render an inline citation.
- `format_bibliography_reference(style, entry)` — render one bibliography entry.
- `format_bibliography_label(style, entry, citations)` — render its label.

`src/formatting.jl` provides the shared building blocks (`format_names`,
`format_published_in`, `format_title`, `format_year`, `format_pages`, …) used by
the built-in styles. `src/labeled_styles_utils.jl` holds shared logic for
label-based styles. **Custom styles** are defined by adding methods to these
functions; see worked examples in `docs/custom_styles/`
(`enumauthoryear.jl`, `keylabels.jl`).

### TeX/Markdown conversion

`src/tex_to_markdown.jl` converts BibTeX/LaTeX field content (accents, math,
formatting macros) into Markdown/MarkdownAST. `src/md_ast.jl` and
`src/bibliography_node.jl` contain helpers for constructing and manipulating the
MarkdownAST nodes that the pipeline steps insert into pages.
