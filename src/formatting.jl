# helper functions to render references in various styles

_URLDATE_FMT = Dates.DateFormat("u d, Y", "english")
_URLDATE_ACCESSED_ON = "Accessed on "
# We'll leave this not a `const`, as a way for people to "hack" this with
# `eval`


function linkify(text, link; text_fallback="")
    if isempty(link)
        return text
    else
        isempty(text) && (text = text_fallback)
        if isempty(text)
            return ""
        else
            return "[$text]($link)"
        end
    end
end


function _initial(name)
    initial = ""
    _name = Unicode.normalize(tex_to_markdown(strip(name)))
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
    editor_suffix="(Editor)",
    editors_suffix="(Editors)",
    nbsp="\u00A0",  # non-breaking space
)
    # forces the names to be editors' name if the entry are Proceedings
    if !editors && entry.type ∈ ["proceedings"]
        return format_names(
            entry,
            true;
            names=names,
            and=and,
            et_al=et_al,
            et_al_text=et_al_text,
            editor_suffix=editor_suffix,
            editors_suffix=editors_suffix,
            nbsp=nbsp
        )
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
        throw(
            ArgumentError(
                "Invalid names=$(repr(names)) not in :full, :last, :lastonly, :lastfirst"
            )
        )
    end

    if names == :lastfirst
        formatted_names = String[]
        for name in entry_names
            last_parts = [name.particle, name.last, name.junior]
            last = join(filter(!isempty, last_parts), nbsp)
            first_parts = [_initial(name.first), _initial(name.middle)]
            first = join(filter(!isempty, first_parts), nbsp)
            if isempty(first)
                push!(formatted_names, last)
            else
                push!(formatted_names, "$last,$nbsp$first")
            end
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
    if editors
        suffix = (length(entry_names) > 1) ? editors_suffix : editor_suffix
        str *= " $suffix"
    end
    return strip(str)
end


function format_published_in(
    entry;
    namesfmt=:last,
    include_date=true,
    nbsp="\u00A0",
    title_transform_case=(s -> s),
    article_link_doi_in_title=false,
)
    # We mostly follows https://www.bibtex.com/format/
    urls = String[]
    if entry.type == "article" && !article_link_doi_in_title
        # Article titles link exclusively to `entry.access.url`, so
        # "published in" only links to DOI, if available
        if !isempty(entry.access.doi)
            push!(urls, doi_url(entry))
        end
    else
        if isempty(get_title(entry))
            append!(urls, get_urls(entry; skip=0))
        else
            # The title already linked to the URL (or DOI, if no
            # URL available), hence we skip the first link here.
            append!(urls, get_urls(entry; skip=1))
        end
    end
    segments = [String[], String[], String[]]
    # The "published in" string has three segments: First, pub info, Second,
    # address and date info in parenthesis, Third, page/chapter info
    _push!(i::Int64, s::String; _if=true) = (!isempty(s) && _if) && push!(segments[i], s)
    if entry.type == "article"
        # Journal abbreviations should use non-breaking space
        in_journal = tex_to_markdown(replace(entry.in.journal, " " => "~"))
        if !isempty(entry.in.volume)
            in_journal *= " **$(entry.in.volume)**"
        end
        if !isempty(entry.in.pages)
            page = format_pages(entry; page_prefix="", pages_prefix="")
            in_journal *= ", $page"
        end
        _push!(1, linkify(in_journal, pop_url!(urls)))
        _push!(2, format_year(entry); _if=include_date)
    elseif entry.type in ["book", "proceedings"]
        _push!(1, format_edition(entry))
        _push!(1, format_vol_num_series(entry; title_transform_case=title_transform_case))
        _push!(2, tex_to_markdown(entry.in.organization))
        _push!(2, tex_to_markdown(entry.in.publisher))
        _push!(2, tex_to_markdown(entry.in.address))
        _push!(2, format_year(entry); _if=include_date)
        _push!(3, format_chapter(entry))
        _push!(3, format_pages(entry))
    elseif entry.type ∈ ["booklet", "misc"]
        _push!(1, tex_to_markdown(entry.access.howpublished))
        _push!(2, format_year(entry); _if=include_date)
        _push!(3, format_pages(entry))
    elseif entry.type == "eprint"
        error("Invalid bibtex type 'eprint'")
        # https://github.com/Humans-of-Julia/BibInternal.jl/issues/22
    elseif entry.type in ["inbook", "incollection", "inproceedings"]
        booktitle = get_booktitle(entry)
        if !isempty(booktitle)
            url = pop_url!(urls)
            formatted_booktitle = format_title(
                entry;
                title=get_booktitle(entry),
                italicize=true,
                url=url,
                transform_case=title_transform_case
            )
            _push!(1, "In: $formatted_booktitle")
        end
        _push!(1, format_edition(entry))
        _push!(1, format_vol_num_series(entry; title_transform_case=title_transform_case))
        if !isempty(entry.editors)
            editors = format_names(
                entry,
                true;
                names=namesfmt,
                editor_suffix="",
                editors_suffix=""
            )
            _push!(1, "edited by $editors")
        end
        _push!(2, tex_to_markdown(entry.in.organization))
        _push!(2, tex_to_markdown(entry.in.publisher))
        _push!(2, tex_to_markdown(entry.in.address))
        _push!(2, format_year(entry); _if=include_date)
        _push!(3, format_chapter(entry))
        _push!(3, format_pages(entry))
    elseif entry.type == "manual"
        _push!(1, format_edition(entry))
        _push!(1, tex_to_markdown(get(entry.fields, "type", "")))
        _push!(2, tex_to_markdown(entry.in.organization))
        _push!(2, tex_to_markdown(entry.in.address))
        _push!(2, format_year(entry); _if=include_date)
        _push!(3, format_pages(entry))
    elseif entry.type in ["mastersthesis", "phdthesis"]
        default_thesis_type =
            Dict("mastersthesis" => "Master's thesis", "phdthesis" => "Ph.D. Thesis",)
        thesis_type = get(entry.fields, "type", default_thesis_type[entry.type])
        _push!(1, tex_to_markdown(thesis_type))
        _push!(1, tex_to_markdown(entry.in.school))
        _push!(2, tex_to_markdown(entry.in.address))
        _push!(2, format_year(entry); _if=include_date)
        _push!(3, format_pages(entry))
        _push!(3, format_chapter(entry))
    elseif entry.type == "techreport"
        report_type = strip(get(entry.fields, "type", "Technical Report"))
        number = strip(entry.in.number)
        report_spec = tex_to_markdown("$report_type~$number")
        _push!(1, report_spec; _if=!isempty(number))
        _push!(2, tex_to_markdown(entry.in.institution))
        _push!(2, tex_to_markdown(entry.in.address))
        _push!(2, format_year(entry); _if=include_date)
        _push!(3, format_pages(entry))
    else
        @assert entry.type == "unpublished" "Unexpected type $(repr(entry.type))"
        # @unpublished should be rendered entirely via the Note field.
        if isempty(get(entry.fields, "note", ""))
            @warn "unpublished $(entry.id) does not have a 'note'"
        end
    end
    mdstr = join(segments[1], ", ")
    if length(segments[2]) > 0
        segment2 = join(segments[2], ", ")
        if length(urls) > 0
            segment2 = linkify(segment2, pop_url!(urls))
        end
        mdstr *= " (" * segment2 * ")"
    end
    if length(segments[3]) > 0
        mdstr *= "; " * join(segments[3], ", ")
    end
    if length(urls) > 0
        @warn "Could not link $(repr(urls)) in \"published in\" information for entry $(entry.id). Add a Note field that links to the URL(s)."
    end
    return mdstr
end


function get_title(entry)
    title = entry.title
    if entry.type == "inbook"
        if isempty(entry.booktitle)
            # For @inbook, `get_title` always returns the title of, e.g., the
            # chapter *within* the book. See `get_booktitle`
            title = ""
        end
    end
    return title
end


function get_booktitle(entry)
    booktitle = entry.booktitle
    if isempty(booktitle) && (entry.type == "inbook")
        # It's a bit ambiguous whether the Title field for an @inbook entry
        # refers to the title of the book, or, e.g., the title of the chapter
        # in the book. If only Title is given, it is taken as the booktitle,
        # but if both Title and Booktitle are given, Title is the title of the
        # section within the book.
        booktitle = entry.title
    end
    return booktitle
end


function get_urls(entry; skip=0)
    # URL is first priority, DOI second (cf. `pop_url!`)
    # Passing `skip = 1` skips the first available link
    urls = String[]
    if !isempty(entry.access.url)
        if skip <= 0
            push!(urls, entry.access.url)
        end
        skip = skip - 1
    end
    if !isempty(entry.access.doi)
        if skip <= 0
            url = doi_url(entry)
            push!(urls, url)
        end
        skip = skip - 1
    end
    return urls
end


function doi_url(entry)
    doi = entry.access.doi
    if isempty(doi)
        return ""
    else
        if !startswith(doi, "10.")
            doi_match = match(r"\b10.\d{4,9}/.*\b", doi)
            if isnothing(doi_match)
                @warn "Invalid DOI $(repr(doi)) in bibtex entry $(repr(entry.id)). Ignoring DOI."
                return ""
            else
                if startswith(doi, "http")
                    @warn "The DOI field in bibtex entry $(repr(entry.id)) should not be a URL. Extracting $(repr(doi)) -> $(repr(doi_match.match))."
                else
                    @warn "Invalid DOI $(repr(doi)) in bibtex entry $(repr(entry.id)). Extracting $(repr(doi_match.match))."
                end
                doi = doi_match.match
            end
        end
        return "https://doi.org/$doi"
    end
end


function pop_url!(urls)
    try
        return popfirst!(urls)
    catch
        return ""
    end
end


function format_title(
    entry;
    title=get_title(entry),
    italicize=true,
    url="",
    transform_case=(s -> s)
)
    isnothing(title) && (title = "")
    title = tex_to_markdown(title; transform_case=transform_case)
    already_italics = startswith(title, "*") || endswith(title, "*")
    if !isempty(title) && italicize && !already_italics
        title = "*" * title * "*"
    end
    if !isempty(url)
        title = linkify(title, url)
    end
    return title
end


function format_pages(entry; page_prefix="p.\u00A0", pages_prefix="pp.\u00A0")
    pages = tex_to_markdown(strip(entry.in.pages))
    range_match = match(r"^(\d+)\s*[-–—]\s*(\d+)$", pages)
    if isnothing(range_match)
        if isempty(pages)
            return ""
        else
            return "$page_prefix$pages"
        end
    else  # page range
        p1 = range_match.captures[1]
        p2 = range_match.captures[2]
        return "$pages_prefix$(p1)–$(p2)"

    end
end


function format_chapter(entry; prefix="Chapter\u00A0")
    chapter = strip(entry.in.chapter)
    if isempty(chapter)
        return ""
    else
        if startswith(chapter, "{")
            return tex_to_markdown(chapter)
        else
            return "$prefix$(tex_to_markdown(chapter))"
        end
    end
end


function format_edition(entry; suffix="\u00A0Edition")
    edition = entry.in.edition
    if isempty(edition)
        return ""
    else
        formatted_edition = tex_to_markdown(edition)
        if startswith(edition, "{")
            # We allow to "protect" the edition with braces to render it
            # verbatim. It should include its own suffix in that case, e.g.,
            # "{1st Edition}"
            return formatted_edition
        else
            # Otherwise, we assume a basic ordinal, and append the suffix
            return "$formatted_edition$suffix"
        end
    end
end


function format_vol_num_series(
    entry;
    vol_prefix="vol.\u00A0",
    num_prefix="no.\u00A0",
    title_transform_case=(s -> s)
)
    parts = String[]
    if !isempty(entry.in.volume)
        vol = tex_to_markdown(entry.in.volume)
        push!(parts, occursin(r"^\d+$", vol) ? "$vol_prefix$vol" : vol)
    end
    if !isempty(entry.in.number)
        num = tex_to_markdown(entry.in.number)
        push!(parts, occursin(r"^\d+$", num) ? "$num_prefix$num" : num)
    end
    vol_num = uppercasefirst(join(parts, " "))
    if isempty(entry.in.series)
        return vol_num
    else
        series_title = format_title(
            entry;
            title=entry.in.series,
            italicize=true,
            transform_case=title_transform_case,
        )
        if isempty(vol_num)
            return series_title
        else
            return "$vol_num of $series_title"
        end
    end
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


const _MONTH_MAP = Dict{String,String}(
    # Bibliography.jl replaces month macros like `jan` with the string
    # "January"
    "January" => "Jan",
    "February" => "Feb",
    "March" => "Mar",
    "April" => "Apr",
    "May" => "May",
    "June" => "Jun",
    "July" => "Jul",
    "August" => "Aug",
    "September" => "Sep",
    "October" => "Oct",
    "November" => "Nov",
    "December" => "Dec",
    "1" => "Jan",
    "2" => "Feb",
    "3" => "Mar",
    "4" => "Apr",
    "5" => "May",
    "6" => "Jun",
    "7" => "Jul",
    "8" => "Aug",
    "9" => "Sep",
    "10" => "Oct",
    "11" => "Nov",
    "12" => "Dec",
)

const _TYPES_WITH_MONTHS = Set{String}([
    # The following types are the only ones where the month field shouldn't be
    # ignored.
    "proceedings",
    "booklet",
    "misc",
    "inproceedings",
    "manual",
    "mastersthesis",
    "phdthesis",
    "techreport",
    "unpublished"
])


function format_year(entry; include_month=:auto)
    year = entry.date.year |> tex_to_markdown
    if include_month == :auto
        include_month = (entry.type in _TYPES_WITH_MONTHS)
    end
    if include_month && !isempty(entry.date.month)
        month = tex_to_markdown(entry.date.month)
        month = get(_MONTH_MAP, month, month)
        year = "$month $year"
    end
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
