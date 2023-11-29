"""Representation of a reference within a [`BibliographyNode`}(@ref).

# Properties

* `anchor_key`: the anchor key for the link target as a string (generally the
  BibTeX key), or `nothing` if the item is in a non-canonical bibliography
  block.
* `label`: `MarkdownAST.Node` for the label of the entry. Usually a simple
  `Text` node, as labels in the default styles do not have inline formatting.
    or `nothing` if the style does not use labels
  the rendered bibliography.
* `reference`: `MarkdownAST.Node` for the paragraph for the fully rendered
  reference.
"""
struct BibliographyItem
    anchor_key::Union{Nothing,String}
    label::Union{Nothing,MarkdownAST.Node{Nothing}}
    reference::MarkdownAST.Node{Nothing}
end


"""Node in `MarkdownAST` corresponding to a `@bibliography` block.

# Properties

* `list_style`: One of `:dl`, `:ul`, `:ol`, cf. [`bib_html_list_style`](@ref)
* `canonical`: Whether or not the references in the `@bibliography` block are
  link targets.
* `items`: A list of [`BibliographyItem`](@ref) objects, one for each reference
in the block
"""
struct BibliographyNode <: Documenter.AbstractDocumenterBlock
    list_style::Symbol  # one of :dl, :ul, :ol
    canonical::Bool
    items::Vector{BibliographyItem}
    function BibliographyNode(list_style, canonical, items)
        if list_style in (:dl, :ul, :ol)
            new(list_style, canonical, items)
        else
            throw(
                ArgumentError(
                    "`list_style` must be one of `:dl`, `:ul`, or `:ol`, not `$(repr(list_style))`"
                )
            )
        end
    end
end


function Documenter.MDFlatten.mdflatten(io, ::MarkdownAST.Node, b::BibliographyNode)
    for item in b.items
        Documenter.MDFlatten.mdflatten(io, item.reference)
        print(io, "\n\n\n\n")
    end
end


function Documenter.HTMLWriter.domify(
    dctx::Documenter.HTMLWriter.DCtx,
    node::Documenter.Node,
    bibliography::BibliographyNode
)
    @assert node.element === bibliography
    return domify_bib(dctx, bibliography)
end


function domify_bib(dctx::Documenter.HTMLWriter.DCtx, bibliography::BibliographyNode)
    Documenter.DOM.@tags dl ul ol li div dt dd
    list_tag = dl
    if bibliography.list_style == :ul
        list_tag = ul
    elseif bibliography.list_style == :ol
        list_tag = ol
    end
    html_list = list_tag()
    for item in bibliography.items
        anchor_id = isnothing(item.anchor_key) ? "" : "#$(item.anchor_key)"
        html_reference = Documenter.HTMLWriter.domify(dctx, item.reference.children)
        if bibliography.list_style == :dl
            html_label = Documenter.HTMLWriter.domify(dctx, item.label.children)
            push!(html_list.nodes, dt(html_label))
            push!(html_list.nodes, dd(div[anchor_id](html_reference)))
        else
            push!(html_list.nodes, li(div[anchor_id](html_reference)))
        end
    end
    class = ".citation"
    if bibliography.canonical
        class *= ".canonical"
    else
        class *= ".noncanonical"
    end
    return div[class](html_list)
end


_hash(x) = string(hash(x))


function _wrapblock(f, io, env)
    if !isnothing(env)
        println(io, "\\begin{", env, "}")
    end
    f()
    if !isnothing(env)
        println(io, "\\end{", env, "}")
    end
end


function _labelbox(f, io; width="0in")
    local width_val
    try
        width_val = parse(Float64, string(match(r"[\d.]+", width).match))
    catch
        throw(ArgumentError("width $(repr(width)) must be a valid LaTeX width"))
    end
    if width_val == 0.0
        # do not use a makebox if width is zero
        print(io, "{")
        f()
        print(io, "} ")
        return
    end
    print(
        io,
        "\\makebox[{\\ifdim$(width)<\\dimexpr\\width+1ex\\relax\\dimexpr\\width+1ex\\relax\\else$(width)\\fi}][l]{"
    )
    f()
    print(io, "}")
end


function Documenter.LaTeXWriter.latex(
    lctx::Documenter.LaTeXWriter.Context,
    node::MarkdownAST.Node,
    bibliography::BibliographyNode
)

    if bibliography.list_style == :ol
        texenv = "enumerate"
    elseif bibliography.list_style == :ul
        if _LATEX_OPTIONS[:ul_as_hanging]
            texenv = nothing
        else
            texenv = "itemize"
        end
    else
        @assert bibliography.list_style == :dl
        # We emulate a definition list manually with hangindent and labelwidth
        texenv = nothing
    end

    io = lctx.io

    function tex_item(n, item)
        if bibliography.list_style == :ul
            if _LATEX_OPTIONS[:ul_as_hanging]
                print(io, "\\hangindent=$(_LATEX_OPTIONS[:ul_hangindent]) ")
            else
                print(io, "\\item ")
            end
        elseif bibliography.list_style == :ol  # enumerate
            print(io, "\\item ")
        else
            @assert bibliography.list_style == :dl
            print(io, "\\hangindent=$(_LATEX_OPTIONS[:dl_hangindent]) {")
            _labelbox(io; width=_LATEX_OPTIONS[:dl_labelwidth]) do
                Documenter.LaTeXWriter.latex(lctx, item.label.children)
            end
            print(io, "}")
        end
    end

    println(io, "{$(_LATEX_OPTIONS[:bib_blockformat])% @bibliography\n")
    _wrapblock(io, texenv) do
        for (n, item) in enumerate(bibliography.items)
            tex_item(n, item)
            if !isnothing(item.anchor_key)
                id = _hash(item.anchor_key)
                print(io, "\\hypertarget{", id, "}{}")
            end
            Documenter.LaTeXWriter.latex(lctx, item.reference.children)
            print(io, "\n\n")
        end
    end
    println(io, "}% end @bibliography")

end


function Documenter.linkcheck(
    node::MarkdownAST.Node,
    bibliography::BibliographyNode,
    doc::Documenter.Document
)
    success = true
    for item in bibliography.items
        success &= !(Documenter.linkcheck(item.reference, doc) === false)
        # `linkcheck` may return `true` / `false` / `nothing`
    end
    return success
end
