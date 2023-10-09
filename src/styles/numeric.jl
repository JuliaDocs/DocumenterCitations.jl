# format_citation #############################################################

function format_citation(style::Val{:numeric}, cit::CitationLink, entries, citations)
    format_labeled_citation(style, cit, entries, citations; sort_and_collapse=true)
end


function citation_label(::Val{:numeric}, entry, citations; notfound="?")
    key = replace(entry.id, "*" => "_")
    try
        return "$(citations[key])"
    catch exc
        @warn "citation_label: $(repr(key)) not found in `citations`. Using $(repr(notfound))."
        return notfound
    end
end


# format_bibliography_reference ###############################################

function format_bibliography_reference(style::Val{:numeric}, entry)
    return format_labeled_bibliography_reference(style, entry)
end


# format_bibliography_label ###################################################

function format_bibliography_label(
    style::Val{:numeric},
    entry,
    citations::OrderedDict{String,Int64}
)
    key = replace(entry.id, "*" => "_")
    i = get(citations, key, 0)
    if i == 0
        i = length(citations) + 1
        citations[key] = i
        @debug "Mark $key as cited ($i) because it is rendered in a bibliography"
    end
    label = citation_label(style, entry, citations)
    return "[$label]"
end


# bib_html_list_style #########################################################

bib_html_list_style(::Val{:numeric}) = :dl


# bib_sorting #################################################################

bib_sorting(::Val{:numeric}) = :citation
