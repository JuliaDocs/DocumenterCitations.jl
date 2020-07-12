using Documenter
using Documenter.Builder
using Documenter.Documents
using Documenter.Selectors

using Markdown
using Bibliography
using Bibliography: xnames

abstract type Citations <: Builder.DocumentPipeline end

Selectors.order(::Type{Citations}) = 3.1

function Selectors.runner(::Type{Citations}, doc::Documents.Document)
    @info "Citations: building citations."
    expand_citations(doc)
end

function expand_citations(doc::Documents.Document)
    for (src, page) in doc.blueprint.pages
        empty!(page.globals.meta)
        for element in page.elements
            expand_citation(page.mapping[element], page, doc)
        end
    end
end


function expand_citation(elem, page, doc)
    Documents.walk(page.globals.meta, elem) do link
        expand_citation(link, page.globals.meta, page, doc)
    end
end

function expand_citation(link::Markdown.Link, meta, page, doc)
    if length(link.text) === 1 && isa(link.text[1], String)
        citation_name = link.text[1]
        @info "Expanding citation: $citation_name."
        for entry in BIBLIOGRAPHY
            if entry.id == citation_name
                @info "Citation found: $(xnames(entry))"
                link.text = xnames(entry)
                link.url = "https://google.com/search?q=sweet#$citation_name"
                return true
            end
        end
        error("Citation not found in bibliography: $(citation_name)")
    else
        error("Invalid citation: $(link.text)")
    end
    return false
end

expand_citation(other, meta, page, doc) = true # Continue to `walk` through element `other`.
