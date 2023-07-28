# helper functions to render references in various styles

const tex2unicode_chars = Dict(
    'o' => "\u00F8",  # \o 	ø 	latin small letter O with stroke
    'O' => "\u00D8",  # \O 	Ø 	latin capital letter O with stroke
    'l' => "\u0142",  # \l 	ł 	latin small letter L with stroke
    'L' => "\u0141",  # \L 	Ł 	latin capital letter L with stroke
    'i' => "\u0131",  # \i 	ı 	latin small letter dotless I
)

const tex2unicode_replacements = (
    "---" => "—", # em dash needs to go first
    "--"  => "–",

    # do this before tex2unicode_chars or it wont be recognized
    r"\\\\\"\{\\i\}" => s"\u0069\u308", # \"{\i} 	ï 	Latin Small Letter I with Diaeresis

    # replace quoted single letters before the remaining replacements, and do
    # them all at once, as these patterns rely on word boundaries which can
    # change due to the replacements we perform
    r"\\[oOlLi]\b" => c -> tex2unicode_chars[c[2]],
    r"\\`\{(\S{1})\}" => s"\1\u300", # \`{o} 	ò 	grave accent
    r"\\'\{(\S{1})\}" => s"\1\u301", # \'{o} 	ó 	acute accent
    r"\\\^\{(\S{1})\}" => s"\1\u302", # \^{o} 	ô 	circumflex
    r"\\~\{(\S{1})\}" => s"\1\u303", # \~{o} 	õ 	tilde
    r"\\=\{(\S{1})\}" => s"\1\u304", # \={o} 	ō 	macron accent (a bar over the letter)
    r"\\u\{(\S{1})\}" => s"\1\u306",  # \u{o} 	ŏ 	breve over the letter
    r"\\\.\{(\S{1})\}" => s"\1\u307", # \.{o} 	ȯ 	dot over the letter
    r"\\\\\"\{(\S{1})\}" => s"\1\u308", # \"{o} 	ö 	umlaut, trema or dieresis
    r"\\r\{(\S{1})\}" => s"\1\u30A",  # \r{a} 	å 	ring over the letter (for å there is also the special command \aa)
    r"\\H\{(\S{1})\}" => s"\1\u30B",  # \H{o} 	ő 	long Hungarian umlaut (double acute)
    r"\\v\{(\S{1})\}" => s"\1\u30C",  # \v{s} 	š 	caron/háček ("v") over the letter
    r"\\d\{(\S{1})\}" => s"\1\u323",  # \d{u} 	ụ 	dot under the letter
    r"\\c\{(\S{1})\}" => s"\1\u327",  # \c{c} 	ç 	cedilla
    r"\\k\{(\S{1})\}" => s"\1\u328",  # \k{a} 	ą 	ogonek
    r"\\b\{(\S{1})\}" => s"\1\u331",  # \b{b} 	ḇ 	bar under the letter
    r"\\t\{(\S{1})(\S{1})\}" => s"\1\u0361\2",  # \t{oo} 	o͡o 	"tie" (inverted u) over the two letters
    r"\{\}" => s"",  # empty curly braces should not have any effect
    r"\{([\w-]+)\}" => s"\1",  # {<text>} 	<text> 	bracket stripping after applying all rules

    # Sources : https://www.compart.com/en/unicode/U+0131 enter the unicode character into the search box
)

function tex2unicode(s)
    for replacement in tex2unicode_replacements
        s = replace(s, replacement)
    end
    return Unicode.normalize(s)
end

linkify(text, link) = isempty(link) ? text : "<a href='$link'>$text</a>"

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
    year = two_digit_year(entry.date.year)
    if length(entry.authors) == 1
        name = Unicode.normalize(entry.authors[1].last; stripmark=true)
        return uppercasefirst(first(name, 3)) * year
    else
        letters = join(
            [
                uppercase(Unicode.normalize(name.last; stripmark=true)[1]) for
                name in first(entry.authors, 3)
            ],
            "",
        )
        if length(entry.authors) > 3
            letters *= "+"
        end
        return letters * year
    end
end


function format_names(
    entry,
    editors=false;
    names=:full,
    and=true,
    et_al=0,
    et_al_text="et al."
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
            last = join(filter(!isempty, last_parts), " ")
            first_parts = [_initial(name.first), _initial(name.middle)]
            first = join(filter(!isempty, first_parts), " ")
            push!(formatted_names, "$last, $first")
        end
    else
        formatted_names = map(parts) do s
            return join(filter(!isempty, s), " ")
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
    if needs_et_al
        str *= " $et_al_text"
    end
    return replace(str, r"[\n\r ]+" => " ")
end


function italicize_md_et_al(text; et_al_in="*et al.*", et_al_out="et al.")
    if occursin(et_al_in, text)
        parts = split(text, et_al_in; limit=2)
        return [parts[1], Markdown.Italic(Any[et_al_out]), parts[2]]
    else
        return text
    end
end


function format_published_in(entry; include_date=true)
    str = ""
    if entry.type == "article"
        str *= entry.in.journal
        if !isempty(entry.in.volume)
            str *= " <b>$(entry.in.volume)</b>"
        end
        if !isempty(entry.in.pages)
            str *= ", $(entry.in.pages)"
        end
    elseif entry.type == "book"
        parts = [entry.in.publisher, entry.in.address]
        str *= join(filter!(!isempty, parts), ", ")
    elseif entry.type ∈ ["booklet", "misc"]
        parts = [
            entry.access.howpublished
            get(entry.fields, "note", "")
        ]
        str *= join(filter!(!isempty, parts), ", ")
    elseif entry.type == "eprint"
        if isempty(entry.eprint.archive_prefix)
            str *= entry.eprint.eprint
        else
            str *= "$(entry.eprint.archive_prefix):$(entry.eprint.eprint) [$(entry.eprint.primary_class)]"
        end
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
            "In $(entry.booktitle)",
            "editors",
            format_names(entry, true),
            entry.in.pages * ". " * entry.in.publisher,
            entry.in.address,
        ]
        str *= join(filter!(!isempty, parts), ", ")
    elseif entry.type == "inproceedings"
        parts = [
            " In " * entry.booktitle,
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
        parts = [get(entry.fields, "note", ""),]
        str *= join(filter!(!isempty, parts), ", ")
    end
    if include_date && !isempty(entry.date.year)
        str *= " ($(entry.date.year))"
    end
    return str
end
