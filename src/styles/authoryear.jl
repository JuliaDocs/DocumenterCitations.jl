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
        names = format_names(entry; names=namesfmt, and=true, et_al, et_al_text="*et al.*")
        if isempty(names)
            names = empty_names
        end
        if i == 1 && cit.capitalize
            names = uppercasefirst(names)
        end
        year = format_year(entry)
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
mdstr = format_authoryear_bibliography_reference(
    style, entry;
    namesfmt=:lastfirst,
    empty_names="—",
    urldate_accessed_on="Accessed on ",
    urldate_fmt=dateformat"u d, Y",
    title_transform_case=(s->s),
    article_link_doi_in_title=false,
)
```

# Options

* `namesfmt`: How to format the author names (`:full`, `:last`, `:lastonly`)
* `empty_names`: String to use in place of the authors if there are no authors
* `urldate_accessed_on`: The prefix for a rendered `urldate` field.
* `urldate_fmt`: The format in which to render an `urldate` field.
* `title_transform_case`: A function that transforms the case of a Title
  (Booktitle, Series) field. Strings enclosed in braces are protected
  from the transformation.
* `article_link_doi_in_title`: If `false`, the URL is linked to the title for
  Article entries, and the DOI is linked to the published-in. If `true`, 
  Article entries are handled as other entries, i.e., the first available URL
  (URL or, if no URL available, DOI) is linked to the title, while only in
  the presence of both, the DOI is linked to the published-in.
"""
function format_authoryear_bibliography_reference(
    style,
    entry;
    namesfmt=:lastfirst,
    empty_names="—",
    urldate_accessed_on=_URLDATE_ACCESSED_ON,
    urldate_fmt=_URLDATE_FMT,
    title_transform_case=(s -> s),
    article_link_doi_in_title=false,
)
    authors = format_names(entry; names=namesfmt)
    if entry.type == "article" && !article_link_doi_in_title
        title =
            format_title(entry; url=entry.access.url, transform_case=title_transform_case)
    else
        urls = get_urls(entry)
        # Link URL, or DOI if no URL is available
        title = format_title(entry; url=pop_url!(urls), transform_case=title_transform_case)
    end
    year = format_year(entry)
    if !isempty(year)
        if isempty(authors)
            authors = empty_names
        end
        year = "($year)"
    end
    published_in = format_published_in(
        entry;
        include_date=false,
        namesfmt=namesfmt,
        title_transform_case=title_transform_case,
        article_link_doi_in_title=article_link_doi_in_title
    )
    eprint = format_eprint(entry)
    urldate = format_urldate(entry; accessed_on=urldate_accessed_on, fmt=urldate_fmt)
    note = format_note(entry)
    parts = String[]
    for part in (authors, year, title, published_in, eprint, urldate, note)
        if !isempty(part)
            push!(parts, part)
        end
    end
    mdtext = _join_bib_parts(parts)
    return mdtext
end


# format_bibliography_label ###################################################

# N/A — this style does not use labels


# bib_html_list_style #########################################################

bib_html_list_style(::Val{:authoryear}) = :ul


# bib_sorting #################################################################

bib_sorting(::Val{:authoryear}) = :nyt
