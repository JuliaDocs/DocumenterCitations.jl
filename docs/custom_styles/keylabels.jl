import QuantumCitations

# we use some (undocumented) internal helper functions for formatting...
using QuantumCitations: format_names, tex2unicode, italicize_md_et_al

QuantumCitations.format_bibliography_reference(::Val{:keylabels}, entry) =
    QuantumCitations.format_bibliography_reference(:numeric, entry)

function QuantumCitations.format_bibliography_label(::Val{:keylabels}, entry, citations)
    return "[$(entry.id)]"
end

function QuantumCitations.format_citation(
    style::Val{:keylabels},
    entry,
    citations;
    note,
    cite_cmd,
    capitalize,
    starred
)
    link_text = isnothing(note) ? "[$(entry.id)]" : "[$(entry.id), $note]"
    if cite_cmd == :citet
        et_al = starred ? 0 : 1  # 0: no "et al."; 1: "et al." after 1st author
        names =
            format_names(entry; names=:lastonly, and=true, et_al, et_al_text="*et al.*") |>
            tex2unicode
        capitalize && (names = uppercase(names[1]) * names[2:end])
        link_text = italicize_md_et_al("$names $link_text")
    end
    return link_text
end

QuantumCitations.bib_sorting(::Val{:keylabels}) = :nyt  # name, year, title

QuantumCitations.bib_html_list_style(::Val{:keylabels}) = :dl
