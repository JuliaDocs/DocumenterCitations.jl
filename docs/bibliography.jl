using Documenter
using Documenter.Expanders
using Documenter.Expanders: iscode
using Documenter.Selectors
using Documenter.Documents

using Bibliography: xnames, xyear, xlink, xtitle, xin

abstract type BibliographyBlock <: Expanders.ExpanderPipeline end

Selectors.order(::Type{BibliographyBlock}) = 12.0
Selectors.matcher(::Type{BibliographyBlock}, node, page, doc) = iscode(node, r"^@bibliography")

function Selectors.runner(::Type{BibliographyBlock}, x, page, doc)
    @info "Expanding bibliography."
    raw_bib = "<dl>"
    for entry in BIBLIOGRAPHY
        @info "Expanding bibliography entry: $(entry.id)."
        entry_text = """<dt>$(entry.id)</dt>
        <dd>
          <div id="$(entry.id)">$(xnames(entry)) ($(xyear(entry))), <a href="$(xlink(entry))">$(xtitle(entry))</a>, $(xin(entry))</a>
        </dd>
        """
        raw_bib *= entry_text
    end
    raw_bib *= "\n</dl>"
    page.mapping[x] = Documents.RawNode(:html, raw_bib)
end

