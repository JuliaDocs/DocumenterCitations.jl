# format_citation #############################################################


function format_citation(style::Union{Val{:alpha},AlphaStyle}, cit, entries, citations)
    format_labeled_citation(style, cit, entries, citations; sort_and_collapse=false)
end


function citation_label(
    style::Union{Val{:alpha},AlphaStyle},
    entry,
    citations;
    notfound="?"
)
    local label
    if style == Val(:alpha)
        # dumb style
        label = alpha_label(entry)
    else
        # smart style
        @assert style isa AlphaStyle
        key = replace(entry.id, "*" => "_")
        try
            label = style.label_for_key[key]
        catch
            @error "No AlphaStyle label for $key. Was `init_bibliography!` called?" style.label_for_key
            return notfound
        end
    end
    return label
end


# init_biliography! ###########################################################


function init_bibliography!(style::AlphaStyle, bib)

    # We determine the keys from all the entries in the .bib file
    # (`bib.entries`), not just the cited ones (`bib.citations`). This keeps
    # the rendered labels more stable, e.g., if you have one `.bib` file across
    # multiple related projects. Besides, `bib.citations` isn't guaranteed to
    # be complete at the point where `init_bibliography!` is called, since
    # bibliography blocks can also introduce new citations (e.g., if using `*`)
    entries = OrderedDict{String,Bibliography.Entry}(
        # best not to mutate bib.entries, so we'll create a copy before sorting
        key => entry for (key, entry) in bib.entries
    )
    Bibliography.sort_bibliography!(entries, :nyt)

    # pass 1 - collect dumb labels, identify duplicates
    keys_for_label = Dict{String,Vector{String}}()
    for (key, entry) in entries
        label = alpha_label(entry)  # dumb label (no suffix)
        if label in keys(keys_for_label)
            push!(keys_for_label[label], key)
        else
            keys_for_label[label] = String[key,]
        end
    end

    # pass 2 - disambiguate duplicates (append suffix to dumb labels)
    label_for_key = style.label_for_key  # for in-place mutation
    for (key, entry) in entries
        label = alpha_label(entry)
        if length(keys_for_label[label]) > 1
            i = findfirst(isequal(key), keys_for_label[label])
            label *= _alpha_suffix(i)
        end
        label_for_key[key] = label
    end
    @debug "init_bibliography!(style::AlphaStyle, bib)" keys_for_label label_for_key

    # `style.label_for_key` is now up-to-date

end


function _alpha_suffix(i)
    if i <= 25
        return string(Char(96 + i))  # 1 -> "a", 2 -> "b", etc.
    else
        # 26 -> "za", 27 -> "zb", etc.
        # I couldn't find any information on (and I was too lazy to test) how
        # LaTeX handles disambiguation of more than 25 identical labels, but
        # this seems sensible. But also: Seriously? I don't think we'll ever
        # run into this in real life.
        return "z" * _alpha_suffix(i - 25)
    end
end


# format_bibliography_reference ###############################################


function format_bibliography_reference(style::Val{:alpha}, entry)
    return format_labeled_bibliography_reference(style, entry)
end


function format_bibliography_reference(style::AlphaStyle, entry)
    return format_labeled_bibliography_reference(style, entry)
end


# format_bibliography_label ###################################################


function format_bibliography_label(
    style::Union{Val{:alpha},AlphaStyle},
    entry,
    citations::OrderedDict{String,Int64}
)
    label = citation_label(style, entry, citations)
    return "[$label]"
end


# bib_html_list_style #########################################################

bib_html_list_style(::Val{:alpha}) = :dl
bib_html_list_style(::AlphaStyle) = :dl


# bib_sorting #################################################################

bib_sorting(::Val{:alpha}) = :nyt
bib_sorting(::AlphaStyle) = :nyt
