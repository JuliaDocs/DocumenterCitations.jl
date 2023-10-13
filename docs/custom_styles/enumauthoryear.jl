import DocumenterCitations

function DocumenterCitations.format_bibliography_reference(
    style::Val{:enumauthoryear},
    entry
)
    text = DocumenterCitations.format_authoryear_bibliography_reference(style, entry)
    return uppercasefirst(text)
end

DocumenterCitations.format_citation(style::Val{:enumauthoryear}, args...) =
    DocumenterCitations.format_authoryear_citation(style, args...)

DocumenterCitations.bib_sorting(::Val{:enumauthoryear}) = :nyt  # name, year, title

DocumenterCitations.bib_html_list_style(::Val{:enumauthoryear}) = :ol
