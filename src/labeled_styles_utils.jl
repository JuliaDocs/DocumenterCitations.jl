# Auxiliary routines common to the implementation of the `:numeric` and
# `:alpha` (both of which use citation labels)


"""Format a citation as in a "labeled" style.

```julia
md = format_labeled_citation(
    style, cit, entries, citations;
    sort_and_collapse=true,
    brackets="[]",
    names=:lastonly,
    notfound="?",
)
```

may be used when implementing [`format_citation`](@ref) for custom styles, to
render the given [`CitationLink`](@ref) object `cit` in a format similar to the
built-in `:numeric` and `:alpha` styles.

# Options

* `sort_and_collapse`: whether to sort and collapse combined citations,
  e.g. `[1-3]` instead of `[2,1,3]`. Not applicable to `@citet`.
* `brackets`: characters to use to enclose citation labels
* `namesfmt`: How to format the author names in `@citet` (`:full`, `:last`, `:lastonly`)
* `notfound`: citation label to use for a citation to a non-existing entry

Beyond the above options, defining a custom [`citation_label`](@ref) method for
the `style` controls the label to be used (e.g., the citation number for the
default `:numeric` style.)
"""
function format_labeled_citation(
    style,
    cit,
    entries,
    citations;
    sort_and_collapse=true,
    brackets="[]",
    namesfmt=:lastonly,
    notfound="?"
)
    cite_cmd = cit.cmd
    if cite_cmd in [:citealt, :citealp, :citenum]
        @warn "$cite_cmd citations are not supported in the default styles."
        (cite_cmd == :citealt) && (cite_cmd = :citet)
    end
    if cite_cmd in [:cite, :citep]
        return _format_labeled_cite(
            style,
            cit,
            entries,
            citations;
            sort_and_collapse=sort_and_collapse,
            brackets=brackets,
            notfound=notfound
        )
    else
        @assert cite_cmd == :citet
        return _format_labeled_citet(
            style,
            cit,
            entries,
            citations;
            brackets=brackets,
            namesfmt=namesfmt,
            notfound=notfound
        )
    end
end


function _format_labeled_cite(
    style,
    cit,
    entries,
    citations;
    sort_and_collapse=false,
    brackets="[]",
    notfound="?"
)

    if sort_and_collapse

        keys = sort(cit.keys; by=(key -> get(citations, key, 0)))

        # collect groups of consecutive citations
        key = popfirst!(keys)
        group = [key]
        groups = [group]
        while length(keys) > 0
            key = popfirst!(keys)
            if get(citations, key, 0) == get(citations, group[end], 0) + 1
                push!(group, key)
            else
                group = [key]
                push!(groups, group)
            end
        end

    else

        groups = [[key] for key in cit.keys]

    end

    # collect link(s) for each group
    parts = String[]
    for group in groups
        if length(group) ≤ 2
            for key in group
                try
                    entry = entries[key]
                    lbl = citation_label(style, entry, citations; notfound=notfound)
                    push!(parts, "[$lbl](@cite $key)")
                catch exc
                    @assert (exc isa KeyError) && (exc.key == key)
                    # This will already have triggered an error during the
                    # collection phase, so we can handle this silently
                    push!(parts, notfound)
                end
            end
        else
            local lnk1, lnk2
            k1 = group[begin]
            k2 = group[end]
            try
                entry = entries[k1]
                lbl = citation_label(style, entry, citations; notfound=notfound)
                lnk1 = "[$lbl](@cite $k1)"
            catch exc
                @assert (exc isa KeyError) && (exc.key == k1)
                lnk1 = notfound  # handle silently (see above)
            end
            try
                entry = entries[k2]
                lbl = citation_label(style, entry, citations; notfound=notfound)
                lnk2 = "[$lbl](@cite $k2)"
            catch exc
                @assert (exc isa KeyError) && (exc.key == k2)
                lnk1 = notfound   # handle silently (see above)
            end
            push!(parts, "$(lnk1)–$(lnk2)")
        end
    end

    if !isnothing(cit.note)
        push!(parts, cit.note)
    end

    return brackets[begin] * join(parts, ", ") * brackets[end]

end


function _format_labeled_citet(
    style,
    cit,
    entries,
    citations;
    brackets="[]",
    namesfmt=:lastonly,
    notfound="?"
)
    parts = String[]
    et_al = cit.starred ? 0 : 1
    for (i, key) in enumerate(cit.keys)
        try
            entry = entries[key]
            names =
                format_names(entry; names=namesfmt, and=true, et_al, et_al_text="*et al.*")
            if i == 1 && cit.capitalize
                names = uppercasefirst(names)
            end
            label = citation_label(style, entry, citations)
            label = brackets[begin] * label * brackets[end]
            push!(parts, "[$names $label](@cite $key)")
        catch exc
            if exc isa KeyError
                label = brackets[begin] * notfound * brackets[end]
                @warn "citation_label: $(repr(key)) not found. Using $(repr(label))."
                push!(parts, label)
            else
                rethrow()
            end
        end
    end
    if !isnothing(cit.note)
        push!(parts, cit.note)
    end
    if isnothing(cit.note)
        return join(parts, ", ", " and ")
    else
        return join(parts, ", ")
    end
end


"""Return a citation label.

```julia
label = citation_label(style, entry, citations; notfound="?")
```

returns the label used in citations and the bibliography for the given entry in
the given style. Used by [`format_labeled_citation`](@ref), and thus by the
built-in styles `:numeric` and `:alpha`.

For the default `:numeric` style, this returns the citation number (as found by
looking up `entry.id` in the `citations` dict) as a string.

May return `notfound` if the citation label cannot be determined.
"""
function citation_label end  # implemented by various styles


"""Format a bibliography reference as in a "labeled" style.

```julia
mdstr = format_labeled_bibliography_reference(style, entry; namesfmt=:last)
```

# Options

* `namesfmt`: How to format the author names (`:full`, `:last`, `:lastonly`)
"""
function format_labeled_bibliography_reference(style, entry; namesfmt=:last)
    authors = format_names(entry; names=namesfmt)
    title = format_title(entry)
    published_in = format_published_in(entry)
    eprint = format_eprint(entry)
    note = format_note(entry)
    parts = String[]
    for part in (authors, title, published_in, eprint, note)
        if !isempty(part)
            push!(parts, part)
        end
    end
    mdtext = _join_bib_parts(parts)
    return mdtext
end
