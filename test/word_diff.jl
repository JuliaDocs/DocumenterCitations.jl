# Test helper providing `@test_diff`, a variant of `@test` for comparing the
# long strings (HTML, Markdown, LaTeX) that most tests in this folder generate.
# A plain `@test` reports only "Evaluated: false", which says nothing about
# where a generated string drifted from its reference.

using Test: Test


"""Split a string into diffable tokens.

A token is a run of word characters, a run of whitespace, or a single other
character. This is fine-grained enough that a change inside a tag or a URL
shows up as a single changed token rather than swallowing the whole line.
"""
_diff_tokens(str::AbstractString) =
    String[m.match for m in eachmatch(r"\w+|\s+|[^\w\s]", str)]


"""Upper limit on the size of the dynamic programming table in `_lcs_pairs`."""
const MAX_LCS_CELLS = 4_000_000


"""Indices of a longest common subsequence of `left` and `right`.

Returns a list of `(i, j)` pairs with `left[i] == right[j]`. For inputs large
enough to exceed `MAX_LCS_CELLS`, returns an empty list, which makes the
surrounding diff degrade to "everything changed" instead of allocating an
enormous table.
"""
function _lcs_pairs(left, right)
    n, m = length(left), length(right)
    (n * m > MAX_LCS_CELLS) && return Tuple{Int,Int}[]
    table = zeros(Int, n + 1, m + 1)
    for i = n:-1:1, j = m:-1:1
        table[i, j] =
            (left[i] == right[j]) ? table[i+1, j+1] + 1 : max(table[i+1, j], table[i, j+1])
    end
    pairs = Tuple{Int,Int}[]
    i = j = 1
    while i <= n && j <= m
        if left[i] == right[j]
            push!(pairs, (i, j))
            i += 1
            j += 1
        elseif table[i+1, j] >= table[i, j+1]
            i += 1
        else
            j += 1
        end
    end
    return pairs
end


"""Split a string into single-character tokens, for a refined diff."""
_char_tokens(str::AbstractString) = String[string(c) for c in str]


"""How much of a changed run must be common for it to be refined.

A one-word edit like `GraceJPB2007` → `GraceJMO2007` is much easier to read
when diffed by character. Two unrelated words are not: diffing `theory`
against `optimization` by character produces noise built from whichever
letters happen to coincide. Only runs at least this similar are refined.
"""
const MIN_REFINE_SIMILARITY = 0.5


"""Write a run of text that differs between the two sides.

With `refine`, a run whose two sides are similar enough is diffed again at the
character level, so that a small edit inside a word shows as such instead of
replacing the whole word.
"""
function _write_change(io::IO, removed::AbstractString, added::AbstractString, refine::Bool)
    if refine && !isempty(removed) && !isempty(added)
        chars_l, chars_r = _char_tokens(removed), _char_tokens(added)
        common = length(_lcs_pairs(chars_l, chars_r))
        if common >= MIN_REFINE_SIMILARITY * max(length(chars_l), length(chars_r))
            return _write_diff(io, chars_l, chars_r, false)
        end
    end
    isempty(removed) || printstyled(io, "[-", removed, "-]"; color=:red)
    isempty(added) || printstyled(io, "{+", added, "+}"; color=:green)
    return nothing
end


"""Write a diff of two token sequences.

Tokens common to both sequences are written once; runs that differ are wrapped
in `[-…-]` (red) and `{+…+}` (green) markers. See `_write_change` for `refine`.
"""
function _write_diff(io::IO, tok_l, tok_r, refine::Bool)
    # Trim the common head and tail, so that the (quadratic) LCS below only
    # runs on the part that actually differs.
    head = 0
    while head < min(length(tok_l), length(tok_r)) && tok_l[head+1] == tok_r[head+1]
        head += 1
    end
    tail = 0
    while tail < min(length(tok_l), length(tok_r)) - head &&
          tok_l[end-tail] == tok_r[end-tail]
        tail += 1
    end
    mid_l, mid_r = tok_l[(head+1):(end-tail)], tok_r[(head+1):(end-tail)]
    common = _lcs_pairs(mid_l, mid_r)
    common_l, common_r = Set(first.(common)), Set(last.(common))

    print(io, join(tok_l[1:head]))
    i = j = 1
    while i <= length(mid_l) || j <= length(mid_r)
        if i <= length(mid_l) && j <= length(mid_r) && i ∈ common_l && j ∈ common_r
            # Emit a whole run of unchanged tokens at once, so that the output
            # is not littered with per-token color resets.
            unchanged = IOBuffer()
            while i <= length(mid_l) && j <= length(mid_r) && i ∈ common_l && j ∈ common_r
                print(unchanged, mid_l[i])
                i += 1
                j += 1
            end
            print(io, String(take!(unchanged)))
        else
            # Likewise, group adjacent changed tokens into a single run.
            removed, added = IOBuffer(), IOBuffer()
            while i <= length(mid_l) && i ∉ common_l
                print(removed, mid_l[i])
                i += 1
            end
            while j <= length(mid_r) && j ∉ common_r
                print(added, mid_r[j])
                j += 1
            end
            _write_change(io, String(take!(removed)), String(take!(added)), refine)
        end
    end
    print(io, join(tok_l[(length(tok_l)-tail+1):end]))
    return nothing
end


"""Write a word-level diff of two strings.

```julia
show_word_diff([io=stderr], left, right)
```

The diff is in the style of `git diff --word-diff`: the text common to both
strings is written once, keeping its original line structure, with text only in
`left` marked `[-like this-]` (red) and text only in `right` marked
`{+like this+}` (green).
"""
function show_word_diff(io::IO, left::AbstractString, right::AbstractString)
    _write_diff(io, _diff_tokens(left), _diff_tokens(right), true)
    println(io)
    return nothing
end

show_word_diff(left::AbstractString, right::AbstractString) =
    show_word_diff(stderr, left, right)


"""Test an expression, showing a word diff for strings that do not match.

```julia
@test_diff expr
```

behaves exactly like `Test.@test`, except that when `expr` is of the form
`left == right`, both sides are strings, and they are not equal, a word-level
diff (see [`show_word_diff`](@ref)) is written to `stderr` before the regular
failure report.

Both sides are evaluated a second time for the underlying `@test`, so that it
reports the original expression rather than internal temporaries. Only use
`@test_diff` with side-effect-free operands.
"""
macro test_diff(ex)
    # Hand `@test` the unescaped expression and the original source location, so
    # that it escapes the expression itself and reports the true call site.
    test_call = esc(Expr(:macrocall, GlobalRef(Test, Symbol("@test")), __source__, ex))
    Meta.isexpr(ex, :call, 3) && ex.args[1] === :(==) || return test_call
    left, right = ex.args[2], ex.args[3]
    return quote
        local lhs = $(esc(left))
        local rhs = $(esc(right))
        if lhs isa AbstractString && rhs isa AbstractString && lhs != rhs
            show_word_diff(lhs, rhs)
        end
        $test_call
    end
end
