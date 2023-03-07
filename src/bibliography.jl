abstract type ExpandBibliography <: Builder.DocumentPipeline end

Selectors.order(::Type{ExpandBibliography}) = 2.12  # after CollectCitations

function Selectors.runner(::Type{ExpandBibliography}, doc::Documents.Document)
    Documenter.Builder.is_doctest_only(doc, "ExpandBibliography") && return
    @info "ExpandBibliography: expanding `@bibliography` blocks."
    for src in keys(doc.blueprint.pages)
        page = doc.blueprint.pages[src]
        empty!(page.globals.meta)
        for element in page.elements
            if Expanders.iscode(element, r"^@bibliography")
                Selectors.dispatch(BibliographyBlock, element, page, doc)
            end
        end
    end
end

abstract type BibliographyBlock <: Selectors.AbstractSelector end

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
    r"\{([[:alnum:]]+)\}" => s"\1",  # {<text>} 	<text> 	bracket stripping after applying all rules

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

function format_names(
    entry,
    editors=false;
    names=:full,
    and=true,
)
    # forces the names to be editors' name if the entry are Proceedings
    if !editors && entry.type ∈ ["proceedings"]
        return format_names(entry, true)
    end
    entry_names = editors ? entry.editors : entry.authors

    if names == :full
        parts = map(s -> [s.first, s.middle, s.particle, s.last, s.junior], entry_names)
    elseif names == :last
        parts = map(s -> [_initial(s.first), _initial(s.middle), s.particle, s.last, s.junior], entry_names)
    elseif names  == :lastonly
        parts = map(s -> [s.particle, s.last, s.junior], entry_names)
    else
        error("Invalid names=$(repr(names)) not in :full, :last, :lastonly")
    end

    entry_names = map(parts) do s
        return join(filter(!isempty, s), " ")
    end
    if and
        str = join(entry_names, ", ", " and ")
    else
        str = join(entry_names, ", ")
    end
    return replace(str, r"[\n\r ]+" => " ")
end


function format_published_in(entry)
    str = ""
    if entry.type == "article"
        str *= entry.in.journal
        if !isempty(entry.in.volume)
            str *= " <b>$(entry.in.volume)</b>"
        end
        if !isempty(entry.in.pages)
            str *= ", $(entry.in.pages)"
        end
        str *= " ($(entry.date.year))"
    elseif entry.type == "book"
        parts = [entry.in.publisher, entry.in.address]
        str *= join(filter!(!isempty, parts), ", ")
        str *= " ($(entry.date.year))"
        return str
    elseif entry.type == "booklet"
        parts = [entry.access.howpublished, ]
        str *= join(filter!(!isempty, parts), ", ")
        str *= " ($(entry.date.year))"
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
        str *= " ($(entry.date.year))"
    elseif entry.type == "incollection"
        parts = [
            "In $(entry.booktitle)",
            "editors",
            format_names(entry, true),
            entry.in.pages * ". " * entry.in.publisher,
            entry.in.address,
        ]
        str *= join(filter!(!isempty, parts), ", ")
        str *= " ($(entry.date.year))"
    elseif entry.type == "inproceedings"
        parts = [
            " In " * entry.booktitle,
            entry.in.series,
            entry.in.pages,
            entry.in.address,
            entry.in.publisher,
        ]
        str *= join(filter!(!isempty, parts), ", ")
        str *= " ($(entry.date.year))"
    elseif entry.type == "manual"
        parts = [entry.in.organization, entry.in.address]
        str *= join(filter!(!isempty, parts), ", ")
        str *= " ($(entry.date.year))"
    elseif entry.type ∈ ["mastersthesis", "phdthesis"]
        parts = [
            (entry.type == "mastersthesis" ? "Master's" : "PhD") * " thesis",
            entry.in.school,
            entry.in.address,
        ]
        str *= join(filter!(!isempty, parts), ", ")
        str *= " ($(entry.date.year))"
    elseif entry.type == "misc"
        parts = [
            entry.access.howpublished
            get(entry.fields, "note", "")
        ]
        str *= join(filter!(!isempty, parts), ", ")
        str *= " ($(entry.date.year))"
    elseif entry.type == "proceedings"
        parts = [
            (entry.in.volume != "" ? "Volume $(entry.in.volume) of " : "") *
            entry.in.series,
            entry.in.address,
            entry.in.publisher,
        ]
        str *= join(filter!(!isempty, parts), ", ")
        str *= " ($(entry.date.year))"
    elseif entry.type == "techreport"
        parts = [
            entry.in.number != "" ? "Technical Report $(entry.in.number)" : "",
            entry.in.institution,
            entry.in.address,
        ]
        str *= join(filter!(!isempty, parts), ", ")
        str *= " ($(entry.date.year))"
    elseif entry.type == "unpublished"
        parts = [get(entry.fields, "note", ""), ]
        str *= join(filter!(!isempty, parts), ", ")
        str *= " ($(entry.date.year))"
    end
    return str
end


function format_bibliography_entry(entry)
    authors = format_names(entry; names=:last) |> tex2unicode
    link = xlink(entry)
    title = xtitle(entry) |> tex2unicode
    published_in = format_published_in(entry) |> tex2unicode
    return "$authors. <i>$title</i>. $(linkify(published_in, link))."
end

function format_bibliography_key(key, entry, doc)
    citations = doc.plugins[CitationBibliography].citations
    i = get(citations, key, 0)
    if i == 0
        i = length(citations) + 1
        citations[key] = i
    end
    return "[$i]"
end

function Selectors.runner(::Type{BibliographyBlock}, x, page, doc)
    @info "Expanding bibliography."
    raw_bib = """<div class="citation"><dl>"""
    bib = doc.plugins[CitationBibliography].bib
    citations = doc.plugins[CitationBibliography].citations
    bib_keys = keys(citations)
    for key in bib_keys
        @info "Expanding bibliography entry: $key."
        entry = bib[key]

        # Add anchor that citations can link to from anywhere in the docs.
        Anchors.add!(doc.internal.headers, entry, entry.id, page.build)

        raw_bib *= """<dt>$(format_bibliography_key(key, entry, doc))</dt>
        <dd>
          <div id="$key">$(format_bibliography_entry(entry))</div>
        </dd>"""
    end
    raw_bib *= "\n</dl></div>"

    page.mapping[x] = Documents.RawNode(:html, raw_bib)
end
