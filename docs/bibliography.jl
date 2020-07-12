using Documenter
using Documenter.Expanders
using Documenter.Expanders: iscode
using Documenter.Documents

using Bibliography: xnames, xyear, xtitle, xin

abstract type BibliographyBlock <: Expanders.ExpanderPipeline end

Selectors.order(::Type{BibliographyBlock}) = 12.0
Selectors.matcher(::Type{BibliographyBlock}, node, page, doc) = iscode(node, r"^@bibliography")

function Selectors.runner(::Type{BibliographyBlock}, x, page, doc)
    raw_bib = "<dl>"
    for entry in BIBLIOGRAPHY
        entry_text = """<dt>$(entry.id)</dt>
        <dd>$(xnames(entry)) ($(xyear(entry))), $(xtitle(entry)), $(xin(entry))</dd>
        """
        raw_bib *= entry_text
    end
    raw_bib *= "\n</dl>"
    page.mapping[x] = Documents.RawNode(:html, raw_bib)
end

