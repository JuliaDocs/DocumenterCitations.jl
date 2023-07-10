import DocumenterCitations

function DocumenterCitations.format_bibliography_reference(::Val{:enumauthoryear}, entry)
    text = DocumenterCitations.format_bibliography_reference(:authoryear, entry)
    return uppercasefirst(text)
end

DocumenterCitations.format_citation(::Val{:enumauthoryear}, args...; kwargs...) =
    DocumenterCitations.format_citation(:authoryear, args...; kwargs...)

DocumenterCitations.bib_sorting(::Val{:enumauthoryear}) = :nyt  # name, year, title

DocumenterCitations.bib_html_list_style(::Val{:enumauthoryear}) = :ol
