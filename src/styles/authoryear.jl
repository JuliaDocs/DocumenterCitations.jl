# format_citation #############################################################

function format_citation(style::Val{:authoryear}, cit::CitationLink, entries, citations)
    format_authoryear_citation(style, cit, entries, citations)
end


"""Format a citation as in the `:authoryear` style.

```julia
md = format_authoryear_citation(
    style, cit, entries, citations;
    empty_names="Anonymous",
    empty_year="undated",
    parenthesis="()",
    notfound="???",
)
```

may be used when implementing [`format_citation`](@ref) for custom styles, to
render the given [`CitationLink`](@ref) object `cit` in a format similar to the
built-in `:authoryear` style.

# Options

* `namesfmt`: How to format the author names (`:full`, `:last`, `:lastonly`)
* `empty_names`: String to use as "author" when the entry defines no author
* `empty_year`: String to use as "year" when the entry defines no year
* `parenthesis`: The parenthesis symbols to use for `@cite`/`@citep`
* `notfound`: How to render a citation without a corresponding entry

"""
function format_authoryear_citation(
    style,
    cit,
    entries,
    citations;
    namesfmt=:lastonly,
    empty_names="Anonymous",
    empty_year="undated",
    parentheses="()",
    notfound="???"
)
    et_al = cit.starred ? 0 : 1
    cite_cmd = cit.cmd
    if cite_cmd == :citep
        cite_cmd = :cite
    end
    if cite_cmd ∈ [:citealt, :citealp, :citenum]
        @warn "$cite_cmd citations are not supported in the default styles."
        (cite_cmd == :citealt) && (cite_cmd = :citet)
    end
    parts = String[]
    for (i, key) in enumerate(cit.keys)
        local entry
        try
            entry = entries[key]
        catch exc
            if exc isa KeyError
                @warn "citation_label: $(repr(key)) not found. Using $(repr(notfound))."
                push!(parts, notfound)
                continue
            else
                rethrow()
            end
        end
        names = tex2unicode(
            format_names(entry; names=namesfmt, and=true, et_al, et_al_text="*et al.*")
        )
        if isempty(names)
            names = empty_names
        end
        if i == 1 && cit.capitalize
            names = uppercasefirst(names)
        end
        year = tex2unicode(entry.date.year)
        if isempty(year)
            year = empty_year
        end
        if cite_cmd == :citet
            push!(parts, "[$names ($year)](@cite $key)")
        else
            @assert cite_cmd in [:cite, :citep]
            push!(parts, "[$names, $year](@cite $key)")
        end
    end

    if !isnothing(cit.note)
        push!(parts, cit.note)
    end

    if cite_cmd == :citet
        return join(parts, ", ")
    else
        @assert cite_cmd in [:cite, :citep]
        return parentheses[begin] * join(parts, "; ") * parentheses[end]
    end

end


# format_bibliography_reference ###############################################


function format_bibliography_reference(style::Val{:authoryear}, entry)
    return format_authoryear_bibliography_reference(style, entry)
end


"""Format a bibliography reference as for the `:authoryear` style.

```julia
html = format_authoryear_bibliography_reference(
    style, entry; namesfmt=:lastfirst, empty_names="—"
)
```

# Options

* `namesfmt`: How to format the author names (`:full`, `:last`, `:lastonly`)
* `empty_names`: String to use in place of the authors if there are no authors
"""
function format_authoryear_bibliography_reference(
    style,
    entry;
    namesfmt=:lastfirst,
    empty_names="—"
)
    authors = format_names(entry; names=namesfmt) |> tex2unicode
    year = entry.date.year |> tex2unicode
    if !isempty(year)
        if isempty(authors)
            authors = empty_names
        end
        year = "($year)"
    end
    title = xtitle(entry)
    if !isempty(title)
        title = "<i>" * tex2unicode(title) * "</i>"
    end
    linked_title = linkify(title, entry.access.url)
    published_in = linkify(
        tex2unicode(format_published_in(entry; include_date=false)),
        _doi_link(entry)
    )
    eprint = format_eprint(entry)
    note = format_note(entry)
    parts = String[]
    for part in (authors, year, linked_title, published_in, eprint, note)
        if !isempty(part)
            push!(parts, part)
        end
    end
    html = _join_bib_parts(parts)
    return html
end


# format_bibliography_label ###################################################

# N/A — this style does not use labels


# bib_html_list_style #########################################################

bib_html_list_style(::Val{:authoryear}) = :ul


# bib_sorting #################################################################

bib_sorting(::Val{:authoryear}) = :nyt
