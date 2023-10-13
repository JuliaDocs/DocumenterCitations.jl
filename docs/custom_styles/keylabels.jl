import DocumenterCitations

DocumenterCitations.format_bibliography_reference(style::Val{:keylabels}, entry) =
    DocumenterCitations.format_labeled_bibliography_reference(style, entry)

function DocumenterCitations.format_bibliography_label(::Val{:keylabels}, entry, citations)
    return "[$(entry.id)]"
end

function DocumenterCitations.format_citation(
    style::Val{:keylabels},
    cit,
    entries,
    citations
)
    return DocumenterCitations.format_labeled_citation(style, cit, entries, citations)
    # The only difference compared to `:alpha` is the citation label, which is
    # picked up automatically by redefining `citation_label` below.
end


function DocumenterCitations.citation_label(style::Val{:keylabels}, entry, citations; _...)
    return entry.id
end


DocumenterCitations.bib_sorting(::Val{:keylabels}) = :nyt  # name, year, title

DocumenterCitations.bib_html_list_style(::Val{:keylabels}) = :dl
