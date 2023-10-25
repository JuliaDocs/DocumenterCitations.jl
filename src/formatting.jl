# helper functions to render references in various styles

_URLDATE_FMT = Dates.DateFormat("u d, Y", "english")
_URLDATE_ACCESSED_ON = "Accessed on "
# We'll leave this not a `const`, as a way for people to "hack" this with
# `eval`


function linkify(text, link)
    if isempty(text)
        text = link
    end
    if isempty(link)
        return text
    else
        return "[$text]($link)"
    end
end

function _doi_link(entry)
    doi = entry.access.doi
    return isempty(doi) ? "" : "https://doi.org/$doi"
end


function _initial(name)
    initial = ""
    _name = Unicode.normalize(strip(name))
    if length(_name) > 0
        initial = "$(_name[1])."
        for part in split(_name, "-")[2:end]
            initial *= "-$(part[1])."
        end
    end
    return initial
end


# extract two-digit year from an entry.date.year
function two_digit_year(year)
    if (m = match(r"\d{4}", year)) ≢ nothing
        return m.match[3:4]
    else
        @warn "Invalid year: $year"
        return year
    end
end


# The citation label for the :alpha style
function alpha_label(entry)
    year = isempty(entry.date.year) ? "??" : two_digit_year(entry.date.year)
    if length(entry.authors) == 1
        name = tex_to_markdown(entry.authors[1].last)
        name = Unicode.normalize(name; stripmark=true)
        return uppercasefirst(first(name, 3)) * year
    else
        letters = [_alpha_initial(name) for name in first(entry.authors, 4)]
        if length(entry.authors) > 4
            letters = [first(letters, 3)..., "+"]
        end
        if length(letters) == 0
            return "Anon" * year
        else
            return join(letters, "") * year
        end
    end
end


function _is_others(name)
    # Support "and others", or "and contributors" directly in the BibTeX file
    # (often used for citing software projects)
    return (
        (name.last in ["others", "contributors"]) &&
        (name.first == name.middle == name.particle == name.junior == "")
    )
end


function _alpha_initial(name)
    # Initial of the last name, but including the "particle" (e.g., "von")
    # Used for `alpha_label`
    if _is_others(name)
        letter = "+"
    else
        letter = uppercase(Unicode.normalize(name.last; stripmark=true)[1])
        if length(name.particle) > 0
            letter = Unicode.normalize(name.particle; stripmark=true)[1] * letter
        end
    end
    return letter
end


function format_names(
    entry,
    editors=false;
    names=:full,
    and=true,
    et_al=0,
    et_al_text="*et al.*",
    nbsp="\u00A0",  # non-breaking space
)
    # forces the names to be editors' name if the entry are Proceedings
    if !editors && entry.type ∈ ["proceedings"]
        return format_names(entry, true)
    end
    entry_names = editors ? entry.editors : entry.authors

    if names == :full
        parts = map(s -> [s.first, s.middle, s.particle, s.last, s.junior], entry_names)
    elseif names == :last
        parts = map(
            s -> [_initial(s.first), _initial(s.middle), s.particle, s.last, s.junior],
            entry_names
        )
    elseif names == :lastonly
        parts = map(s -> [s.particle, s.last, s.junior], entry_names)
    elseif names == :lastfirst
        parts = String[]
        # See below
    else
        error("Invalid names=$(repr(names)) not in :full, :last, :lastonly")
    end

    if names == :lastfirst
        formatted_names = String[]
        for name in entry_names
            last_parts = [name.particle, name.last, name.junior]
            last = join(filter(!isempty, last_parts), nbsp)
            first_parts = [_initial(name.first), _initial(name.middle)]
            first = join(filter(!isempty, first_parts), nbsp)
            push!(formatted_names, "$last,$nbsp$first")
        end
    else
        formatted_names = map(parts) do s
            return join(filter(!isempty, s), nbsp)
        end
    end

    needs_et_al = false
    if et_al > 0
        if length(formatted_names) > (et_al + 1)
            formatted_names = formatted_names[1:et_al]
            and = false
            needs_et_al = true
        end
    end

    namesep = ", "
    if names == :lastfirst
        namesep = "; "
    end

    if and
        str = join(formatted_names, namesep, " and ")
    else
        str = join(formatted_names, namesep)
    end
    str = tex_to_markdown(replace(str, r"[\n\r ]+" => " "))
    if needs_et_al
        str *= " $et_al_text"
    end
    return str
end


function format_published_in(entry; include_date=true, nbsp="\u00A0", link_doi=true)
    # TODO: option to transform case of title
    str = ""
    if entry.type == "article"
        str *= replace(entry.in.journal, " " => nbsp)  # non-breaking space
        if !isempty(entry.in.volume)
            str *= " **$(entry.in.volume)**"
        end
        if !isempty(entry.in.pages)
            str *= ", $(entry.in.pages)"
        end
    elseif entry.type == "book"
        parts = [entry.in.publisher, entry.in.address]
        str *= join(filter!(!isempty, parts), ", ")
    elseif entry.type ∈ ["booklet", "misc"]
        parts = [entry.access.howpublished]
        str *= join(filter!(!isempty, parts), ", ")
    elseif entry.type == "eprint"
        error("Invalid bibtex type 'eprint'")
        # https://github.com/Humans-of-Julia/BibInternal.jl/issues/22
    elseif entry.type == "inbook"
        parts = [
            entry.booktitle,
            isempty(entry.in.chapter) ? entry.in.pages : entry.in.chapter,
            entry.in.publisher,
            entry.in.address,
        ]
        str *= join(filter!(!isempty, parts), ", ")
    elseif entry.type == "incollection"
        parts = [
            "In: $(entry.booktitle)",
            "editors",
            format_names(entry, true),
            entry.in.pages * ". " * entry.in.publisher,
            entry.in.address,
        ]
        str *= join(filter!(!isempty, parts), ", ")
    elseif entry.type == "inproceedings"
        parts = [
            " In: " * entry.booktitle,
            entry.in.series,
            entry.in.pages,
            entry.in.address,
            entry.in.publisher,
        ]
        str *= join(filter!(!isempty, parts), ", ")
    elseif entry.type == "manual"
        parts = [entry.in.organization, entry.in.address]
        str *= join(filter!(!isempty, parts), ", ")
    elseif entry.type == "mastersthesis"
        parts = [
            get(entry.fields, "type", "Master's thesis"),
            entry.in.school,
            entry.in.address,
        ]
        str *= join(filter!(!isempty, parts), ", ")
    elseif entry.type == "phdthesis"
        parts =
            [get(entry.fields, "type", "Phd thesis"), entry.in.school, entry.in.address,]
        str *= join(filter!(!isempty, parts), ", ")
    elseif entry.type == "proceedings"
        parts = [
            (entry.in.volume != "" ? "Volume $(entry.in.volume) of " : "") *
            entry.in.series,
            entry.in.address,
            entry.in.publisher,
        ]
        str *= join(filter!(!isempty, parts), ", ")
    elseif entry.type == "techreport"
        parts = [
            entry.in.number != "" ? "Technical Report $(entry.in.number)" : "",
            entry.in.institution,
            entry.in.address,
        ]
        str *= join(filter!(!isempty, parts), ", ")
    elseif entry.type == "unpublished"
        if isempty(get(entry.fields, "note", ""))
            @warn "unpublished $(entry.id) does not have a 'note'"
        end
    end
    if include_date && !isempty(entry.date.year)
        str *= " ($(entry.date.year))"
    end
    mdtext = tex_to_markdown(str)
    if link_doi
        link = _doi_link(entry)
        return linkify(mdtext, link)
    else
        return mdtext
    end
end


function format_title(entry; italicize=true, link_url=true)
    # TODO: option to transform case of title
    title = tex_to_markdown(xtitle(entry))
    already_italics = startswith(title, "*") || endswith(title, "*")
    if !isempty(title) && italicize && !already_italics
        title = "*" * title * "*"
    end
    if link_url
        title = linkify(title, entry.access.url)
    end
    return title
end


function format_note(entry)
    return strip(get(entry.fields, "note", "")) |> tex_to_markdown
end


function format_urldate(entry; accessed_on=_URLDATE_ACCESSED_ON, fmt=_URLDATE_FMT)
    urldate = strip(get(entry.fields, "urldate", ""))
    if urldate != ""
        if entry.access.url == ""
            @warn "Entry $(entry.id) defines an 'urldate' field, but no 'url' field."
        end
        formatted_date = urldate
        try
            date = Dates.Date(urldate, dateformat"yyyy-mm-dd")
            formatted_date = Dates.format(date, fmt)
        catch exc
            if exc isa ArgumentError
                @warn "Invalid field urldate = $(repr(urldate)). Must be in the format YYYY-MM-DD. $exc"
                # We'll continue with the unformatted `formatted_date = urldate`
            else
                # Most likely, a MethodError because there's something wrong
                # with `fmt`.
                @error "Check if fmt=$(repr(fmt)) is a valid dateformat!"
                rethrow()
            end
        end
        return "$accessed_on$formatted_date"
    else
        return ""
    end
end


function format_year(entry)
    year = entry.date.year |> tex_to_markdown
    return year
end


function format_eprint(entry)

    eprint = entry.eprint.eprint
    if isempty(eprint)
        return ""
    end
    archive_prefix = entry.eprint.archive_prefix
    primary_class = entry.eprint.primary_class

    # standardize prefix for supported preprint repositories
    if isempty(archive_prefix) || (lowercase(archive_prefix) == "arxiv")
        archive_prefix = "arXiv"
    end
    if lowercase(archive_prefix) == "hal"
        archive_prefix = "HAL"
    end
    if lowercase(archive_prefix) == "biorxiv"
        archive_prefix = "biorXiv"
    end

    text = "$(archive_prefix):$eprint"
    if !isempty(primary_class)
        text *= " [$(primary_class)]"
    end

    # link url for supported preprint repositories
    link = ""
    if archive_prefix == "arXiv"
        link = "https://arxiv.org/abs/$eprint"
    elseif archive_prefix == "HAL"
        link = "https://hal.science/$eprint"
    elseif archive_prefix == "biorXiv"
        link = "https://www.biorxiv.org/content/10.1101/$eprint"
    end

    return linkify(text, link)

end


function _strip_md_formatting(mdstr)
    try
        ast = Documenter.mdparse(mdstr; mode=:single)
        buffer = IOBuffer()
        Documenter.MDFlatten.mdflatten(buffer, ast)
        return String(take!(buffer))
    catch exc
        @warn "Cannot strip formatting from $(repr(mdstr))" exc
        return strip(mdstr)
    end
end


# Intelligently join the parts with appropriate punctuation
function _join_bib_parts(parts)
    mdstr = ""
    if length(parts) == 0
        mdstr = ""
    elseif length(parts) == 1
        mdstr = strip(parts[1])
        if !endswith(_strip_md_formatting(mdstr), r"[:.!?]")
            mdstr *= "."
        end
    else
        mdstr = strip(parts[1])
        rest = _join_bib_parts(parts[2:end])
        rest_text = _strip_md_formatting(rest)
        if endswith(_strip_md_formatting(mdstr), r"[:,;.!?]") || startswith(rest_text, "(")
            mdstr *= " " * rest
        else
            if uppercase(rest_text[1]) == rest_text[1]
                mdstr *= ". " * rest
            else
                mdstr *= ", " * rest
            end
        end
    end
    return mdstr
end
