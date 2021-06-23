abstract type BibliographyBlock <: Expanders.ExpanderPipeline end

Selectors.order(::Type{BibliographyBlock}) = 12.0  # Expand bibliography last
Selectors.matcher(::Type{BibliographyBlock}, node, page, doc) = Expanders.iscode(node, r"^@bibliography")

const tex2unicode_replacements = (
    "---" => "—", # em dash needs to go first
    "--"  => "–",
    r"\\`\{(\S)\}" => s"\1\u300", # \`{o} 	ò 	grave accent
    r"\\'\{(\S)\}" => s"\1\u301", # \'{o} 	ó 	acute accent
    r"\\\^\{(\S)\}" => s"\1\u302", # \^{o} 	ô 	circumflex
    r"\\~\{(\S)\}" => s"\1\u303", # \~{o} 	õ 	tilde
    r"\\=\{(\S)\}" => s"\1\u304", # \={o} 	ō 	macron accent (a bar over the letter)
    r"\\u\{(\S)\}" => s"\1\u306",  # \u{o} 	ŏ 	breve over the letter
    r"\\\.\{(\S)\}" => s"\1\u307", # \.{o} 	ȯ 	dot over the letter
    r"\\\\\"\{(\S)\}" => s"\1\u308", # \"{o} 	ö 	umlaut, trema or dieresis
    r"\\r\{(\S)\}" => s"\1\u30A",  # \r{a} 	å 	ring over the letter (for å there is also the special command \aa)
    r"\\H\{(\S)\}" => s"\1\u30B",  # \H{o} 	ő 	long Hungarian umlaut (double acute)
    r"\\v\{(\S)\}" => s"\1\u30C",  # \v{s} 	š 	caron/háček ("v") over the letter
    r"\\d\{(\S)\}" => s"\1\u323",  # \d{u} 	ụ 	dot under the letter
    r"\\c\{(\S)\}" => s"\1\u327",  # \c{c} 	ç 	cedilla
    r"\\k\{(\S)\}" => s"\1\u328",  # \k{a} 	ą 	ogonek
    r"\\b\{(\S)\}" => s"\1\u331",  # \b{b} 	ḇ 	bar under the letter
    r"\{\}" => s"",  # empty curly braces should not have any effect
    r"\\o" => s"\u00F8",  # \o 	ø 	latin small letter O with stroke
    r"\\O" => s"\u00D8",  # \O 	Ø 	latin capital letter O with stroke
    r"\\l" => s"\u0142",  # \l 	ł 	latin small letter L with stroke
    r"\\L" => s"\u0141",  # \L 	Ł 	latin capital letter L with stroke
    r"\\i" => s"\u0131",  # \i 	ı 	latin small letter dotless I

    # TODO:
    # \t{oo} 	o͡o 	"tie" (inverted u) over the two letters
    # \"{\i} 	ï 	Latin Small Letter I with Diaeresis

    # Sources : https://www.compart.com/en/unicode/U+0131 enter the unicode character into the search box
)

function tex2unicode(s)
    for replacement in tex2unicode_replacements
        s = replace(s, replacement)
    end
    return Unicode.normalize(s)
end

linkify(text, link) = isempty(link) ? text : "<a href='$link'>$text</a>"

function Selectors.runner(::Type{BibliographyBlock}, x, page, doc)
    @info "Expanding bibliography."
    raw_bib = "<dl>"
    for (id, entry) in doc.plugins[CitationBibliography].bib
        @info "Expanding bibliography entry: $id."

        # Add anchor that citations can link to from anywhere in the docs.
        Anchors.add!(doc.internal.headers, entry, entry.id, page.build)

        authors = xnames(entry) |> tex2unicode
        link = xlink(entry)
        title = xtitle(entry) |> tex2unicode
        published_in = xin(entry) |> tex2unicode

        raw_bib *= """<dt>$id</dt>
        <dd>
          <div id="$id">$authors, $(linkify(title, link)), $published_in</div>
        </dd>"""
    end
    raw_bib *= "\n</dl>"

    page.mapping[x] = Documents.RawNode(:html, raw_bib)
end
