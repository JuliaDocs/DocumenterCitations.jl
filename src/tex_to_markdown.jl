const _DEBUG = Logging.LogLevel(-2000)  # below Logging.Debug
#const _DEBUG = Logging.Info

# COV_EXCL_START
@static if VERSION >= v"1.7"

    const _replace = replace

else

    # In principle, we really need the ability of `replace` in Julia >= 1.7 to
    # apply multiple substitutions at once. On Julia 1.6, we instead iterate
    # over the substitutions. There is a theoretical chance for a collision in
    # the back-substitution in `_process_tex`. Since the `_keys` function in
    # `_process_tex` combines a hash and a counter, there's basically zero
    # chance of this happening by accident, but it would definitely be possible
    # to hand-craft a string that produces a collision. Oh well.
    function _replace(str, subs...)
        for sub in subs
            str = replace(str, sub)
        end
        return str
    end

end
# COV_EXCL_STOP


const _TEX_ACCENTS = Dict(  # "direct" accents (non-letter commands)
    '`' => "\u0300",   # \`o  ò  grave accent
    '\'' => "\u0301",  # \'o  ó  acute accent
    '^' => "\u0302",   # \^o  ô  circumflex
    '~' => "\u0303",   # \~o  õ  tilde
    '=' => "\u0304",   # \=o  ō  macron (not the same as "overline", \u0305)
    '.' => "\u0307",   # \.o  ȯ  dot over letter
    '"' => "\u0308",   # \"o  ö  diaeresis
)


const _COMMANDS_NUM_ARGS = Dict{String,Int64}(
    # zero-arg commands do not need to be listed
    "\\url" => 1,
    "\\href" => 2,
    "\\texttt" => 1,
    "\\textit" => 1,
    "\\u" => 1,
    "\\r" => 1,
    "\\H" => 1,
    "\\v" => 1,
    "\\d" => 1,
    "\\c" => 1,
    "\\k" => 1,
    "\\b" => 1,
    "\\t" => 1,
)


_url_to_md(url) = "[`$url`]($url)"

function _href_to_md(url, linktext)
    md_linktext = _process_tex(linktext)
    return "[$md_linktext]($url)"
end

function _texttt_to_md(code)
    md_code = _process_tex(code)
    return "`$md_code`"
end


function _textit_to_md(text)
    md_text = _process_tex(text)
    return "_$(md_text)_"
end


function _accent(str, accent)
    a = firstindex(str)
    b = nextind(str, a)
    first = (str[a])
    rest = str[b:end]
    return "$first$accent$rest"
end


const _COMMANDS_TO_MD = Dict{String,Function}(
    "\\url" => _url_to_md,
    "\\href" => _href_to_md,
    "\\texttt" => _texttt_to_md,
    "\\textit" => _textit_to_md,
    "\\u" => c -> _accent(c, "\u306"),  # \u{o}  ŏ  breve over the letter
    "\\r" => c -> _accent(c, "\u30A"),  # \r{a}  å  ring over the letter
    "\\H" => c -> _accent(c, "\u30B"),  # \H{o}  ő  long Hungarian umlaut
    "\\v" => c -> _accent(c, "\u30C"),  # \v{s}  š  caron/háček
    "\\d" => c -> _accent(c, "\u323"),  # \d{u}  ụ  underdot
    "\\c" => c -> _accent(c, "\u327"),  # \c{c}  ç  cedilla
    "\\k" => c -> _accent(c, "\u328"),  # \k{a}  ą  ogonek
    "\\b" => c -> _accent(c, "\u331"),  # \b{b}  ḇ  underbar
    "\\t" => c -> _accent(c, "\u361"),  # \t{oo}  o͡o "tie" over two letters
    "\\o" => () -> "\u00F8",   # \o  ø  latin small letter O with stroke
    "\\O" => () -> "\u00D8",   # \O  Ø  latin capital letter O with stroke
    "\\l" => () -> "\u0142",   # \l  ł  latin small letter L with stroke
    "\\L" => () -> "\u0141",   # \L  Ł  latin capital letter L with stroke
    "\\i" => () -> "\u0131",   # \i  ı  latin small letter dotless I
    "\\j" => () -> "\u0237",   # \j  ȷ  latin small letter dotless J
    "\\ss" => () -> "\u00DF",  # \s  ß  latin small letter sharp S
    "\\SS" => () -> "SS",      # \SS  SS latin capital latter sharp S
    "\\OE" => () -> "\u0152",  # \OE  Œ  latin capital ligature OE
    "\\aa" => () -> "\u00E5",  # \aa  å  latin small letter A with ring above
    "\\ae" => () -> "\u00E6",  # \ae  æ  latin small letter AE
    "\\AA" => () -> "\u00C5",  # \AA  Å  latin capital letter A with ring above
    "\\oe" => () -> "\u0153",  # \oe  œ  latin small ligature oe
    "\\AE" => () -> "\u00C6",  # \AE  Æ  latin capital letter AE
)


const _TEX_ESCAPED_CHARS = Set(['\$', '%', '@', '{', '}', '&'])


function supported_tex_commands()
    return sort([["\\$s" for s in keys(_TEX_ACCENTS)]..., keys(_COMMANDS_TO_MD)...])
end


function tex_to_markdown(tex_str; transform_case=s -> s, debug=_DEBUG)
    try
        md_str = _process_tex(tex_str; transform_case=transform_case, debug=debug)
        return Unicode.normalize(md_str)
    catch exc
        if exc isa BoundsError
            throw(ArgumentError("Premature end of tex string: $exc"))
        else
            rethrow()
        end
    end
end


function _process_tex(tex_str; transform_case=(s -> s), debug=_DEBUG)

    @logmsg debug "_process_tex($(repr(tex_str)))"
    result = ""
    accent_chars = Set(keys(_TEX_ACCENTS))
    subs = Dict{String,String}()
    N = lastindex(tex_str)
    i = firstindex(tex_str)

    _k = 0
    _keys = Dict{String,String}()
    function _key(s)
        key = get(_keys, s, "")
        if key == ""
            _k += 1
            # The key must be unique, and on Julia 1.6, the key also must not
            # collide with any string that might show up in the output of
            # `_process_tex`. Combining a hash and a counter achieves this for
            # anything but maliciously crafted strings.
            key = "{$(hash(s)):$_k}"
            _keys[s] = key
        end
        return key
    end

    while i <= N
        letter = tex_str[i]
        if (letter == '\\')
            next_letter = tex_str[nextind(tex_str, i)]
            if next_letter in _TEX_ESCAPED_CHARS
                i = nextind(tex_str, i)  # eat the '\'
                result *= next_letter
                @logmsg debug "Processed escape '\\' and escaped $(repr(next_letter))"
            elseif next_letter in accent_chars
                i, cmd, replacement = _collect_accent(tex_str, i)
                key = _key(cmd)
                subs[key] = replacement
                result *= key
                @logmsg debug "Processed accent: $(repr(cmd)) -> $(repr(replacement))"
            else
                i, cmd, replacement = _collect_command(tex_str, i; debug=debug)
                key = _key(cmd)
                subs[key] = replacement
                result *= key
                @logmsg debug "Processed accent: $(repr(cmd)) -> $(repr(replacement))"
            end
        elseif (letter == '\$')
            i, math, replacement = _collect_math(tex_str, i)
            key = _key(math)
            subs[key] = replacement
            result *= key
            @logmsg debug "Processed math: $(repr(math)) -> $(repr(replacement))"
        elseif (letter == '{')
            i, group, replacement = _collect_group(tex_str, i)
            key = _key(group)
            subs[key] = replacement
            result *= key
            @logmsg debug "Processed group: $(repr(group)) -> $(repr(replacement))"
        elseif letter in _TEX_ESCAPED_CHARS
            throw(
                ArgumentError(
                    "Character $(repr(letter)) at pos $i in $(repr(tex_str)) must be escaped"
                )
            )
        else  # regular letter
            if letter == '~'
                result *= '\u00a0'  # non-breaking space
            elseif (letter == '-') && (length(result) > 0)
                if result[end] == '-'
                    result = chop(result) * '\u2013'  # en-dash (–)
                elseif result[end] == '\u2013'
                    result = chop(result) * '\u2014'  # en-dash (—)
                else
                    result *= letter
                end
            else
                result *= letter
            end
            @logmsg debug "Processed regular $(repr(letter))"
        end
        i = nextind(tex_str, i)
    end

    @logmsg debug "Applying back-substitution of protected groups" subs
    return _replace(transform_case(result), subs...)

end


# collect a "direct accent" from the given `tex_str`, as specified in _TEX_ACCENTS
# These are special because they don't need braces: you can have
# "Schr\"odinger", not just "Schr\"{o}dinger" or "Schr{\"o}dinger". On the
# other hand, you have to have "Fran\c{c}oise", not "Fran\ccoise"
function _collect_accent(tex_str, i)
    letter = tex_str[i]
    @assert letter == '\\'
    i = nextind(tex_str, i)
    accent = tex_str[i]
    cmd = "\\$accent"
    i = nextind(tex_str, i)
    next_letter = tex_str[i]
    if next_letter == '{'
        i, group, group_replacement = _collect_group(tex_str, i)
        cmd *= group
        a = firstindex(group_replacement)
        b = nextind(group_replacement, a)
        first = (group_replacement[a])
        rest = group_replacement[b:end]
        replacement = "$first$(_TEX_ACCENTS[accent])$rest"
    elseif next_letter == '\\'
        m = match(r"^\\[a-zA-Z]+\b\s*", tex_str[i:end])
        if isnothing(m)
            throw(ArgumentError("Invalid accent: $cmd$(tex_str[i:end])"))
        else # E.g., \"\i
            _replacement = ""
            try
                l, _cmd, _replacement = _collect_command(m.match, 1)
                cmd *= _cmd
                i = prevind(tex_str, i + l)  # end of match
            catch exc
                @error "Accents may only be followed by group, a single ASCII letter, or **a supported zero-argument command**." exc
                throw(ArgumentError("Unsupported accent: $cmd$(tex_str[i:end])."))
            end
            a = firstindex(_replacement)
            b = nextind(_replacement, a)
            first = (_replacement[a])
            rest = _replacement[b:end]
            replacement = "$first$(_TEX_ACCENTS[accent])$rest"
        end
    elseif _is_ascii_letter(next_letter)
        cmd *= next_letter
        replacement = "$next_letter$(_TEX_ACCENTS[accent])"
    else
        @error "Accents may only be followed by group, a single ASCII letter, or a supported zero-argument command."
        throw(ArgumentError("Unsupported accent: $cmd$(tex_str[i:end])."))
    end
    return i, cmd, replacement
end


_is_ascii_letter(l) =
    let i = Int64(l)
        (65 <= i <= 90) || (97 <= i <= 122)  # [A-Za-z]
    end


function _collect_command(tex_str, i; debug=_DEBUG)
    @logmsg debug "_process_command($(repr(tex_str[i:end])))"
    i0 = i
    letter = tex_str[i]
    @assert letter == '\\'
    m = match(r"^\\[a-z-A-Z]+\b\s*", tex_str[i:end])
    cmd = "$letter"
    if isnothing(m)
        throw(ArgumentError("Invalid command: $(tex_str[i:end])"))
    else
        i += lastindex(m.match)  # character after cmd
        cmd = strip(m.match)
    end
    n_args = get(_COMMANDS_NUM_ARGS, cmd, 0)
    @logmsg debug "cmd = $(repr(cmd)), n_args = $n_args"
    args = String[]
    if n_args == 0
        i = prevind(tex_str, i)  # go back to end of cmd
    elseif (n_args == 1) && (tex_str[i] != '{')
        # E.g. `\d o` instead of `\d{o}` (single letter arg)
        @logmsg debug "processing single-letter arg"
        push!(args, string(tex_str[i]))
    else
        i_arg = 0
        while n_args > 0
            i_arg += 1
            @logmsg debug "starting to process arg $i_arg"
            arg = ""
            if tex_str[i] != '{'
                throw(
                    ArgumentError(
                        "Expected '{' at pos $i in $(repr(tex_str)), not $(repr(tex_str[i]))"
                    )
                )
            end
            open_braces = 1
            while true
                i = nextind(tex_str, i)
                letter = tex_str[i]
                if letter == '\\'
                    i = nextind(tex_str, i)
                    next_letter = tex_str[i]
                    arg *= letter  # we leave the escape in place
                    arg *= next_letter
                    @logmsg debug "Processed (keep) escape '\\' and next letter $(repr(next_letter))"
                elseif letter == '{'
                    open_braces += 1
                    arg *= letter
                    @logmsg debug "Processed '{'" open_braces
                elseif letter == '}'
                    open_braces -= 1
                    @logmsg debug "Processed '}'" open_braces
                    if open_braces == 0
                        push!(args, arg)
                        @logmsg debug "finished collecting arg $i_arg" arg
                        n_args -= 1
                        if n_args > 0
                            next_i = nextind(tex_str, i)
                            while tex_str[next_i] == ' '
                                # remove spaces to next argument
                                i = next_i
                                next_i = nextind(tex_str, i)
                            end
                            i = nextind(tex_str, i)
                        end
                        break  # next arg
                    else
                        arg *= letter
                        @logmsg debug "Processed regular $(repr(letter)) (in-arg)"
                    end
                else
                    arg *= letter
                    @logmsg debug "Processed regular $(repr(letter))"
                end
            end
        end
    end
    if !haskey(_COMMANDS_TO_MD, cmd)
        @error "Unsupported command: $cmd" supported_commands = supported_tex_commands()
        throw(ArgumentError("Unsupported command: $cmd. Please report a bug."))
    end
    try
        replacement = _COMMANDS_TO_MD[cmd](args...)
        return i, tex_str[i0:i], replacement
    catch exc
        throw(ArgumentError("Cannot evaluate $cmd: $exc"))
    end
end


function _collect_math(tex_str, i)
    letter = tex_str[i]
    @assert letter == '\$'
    math = "$letter"
    while true  # ends by return, or BoundsError for incomplete math
        i = nextind(tex_str, i)
        letter = tex_str[i]
        math *= letter
        if letter == '\\'
            i = nextind(tex_str, i)
            next_letter = tex_str[i]
            math *= next_letter
        elseif letter == '\$'
            replacement = "``" * chop(math; head=1, tail=1) * "``"
            return i, math, replacement
        end
    end
end


function _collect_group(tex_str, i)
    letter = tex_str[i]
    @assert letter == '{'
    group = "$letter"
    open_braces = 1
    while true  # ends by return, or BoundsError for incomplete math
        i = nextind(tex_str, i)
        letter = tex_str[i]
        group *= letter
        if letter == '\\'
            i = nextind(tex_str, i)
            next_letter = tex_str[i]
            group *= next_letter
        elseif letter == '{'
            open_braces += 1
        elseif letter == '}'
            open_braces -= 1
            if open_braces == 0
                replacement = _process_tex(chop(group; head=1, tail=1))
                return i, group, replacement
            end
        end
    end
end
