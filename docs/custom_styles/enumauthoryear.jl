import QuantumCitations

function QuantumCitations.format_bibliography_reference(::Val{:enumauthoryear}, entry)
    text = QuantumCitations.format_bibliography_reference(:authoryear, entry)
    return uppercasefirst(text)
end

QuantumCitations.format_citation(::Val{:enumauthoryear}, args...; kwargs...) =
    QuantumCitations.format_citation(:authoryear, args...; kwargs...)

QuantumCitations.bib_sorting(::Val{:enumauthoryear}) = :nyt  # name, year, title

QuantumCitations.bib_html_list_style(::Val{:enumauthoryear}) = :ol
