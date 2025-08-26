using Printf
using Test
using IOCapture: IOCapture
using TestingUtilities: @Test  # much better at comparing long strings

import DocumenterCitations:
    DocumenterCitations,
    tex_to_markdown,
    _process_tex,
    _collect_command,
    _collect_accent,
    _collect_math,
    _collect_group


function format_char(c)
    @assert isvalid(Char, c)
    if Int64(c) < 128
        return string(c)
    else
        return @sprintf "\\u%x" Int(c)
    end
end

# for interactive debugging
function print_uni_escape(s)
    escaped = prod(format_char.(collect(s)))
    println("\"$escaped\"  # $(repr(s))")
end


@testset "collect_group" begin

    s = "{group} x"
    @test _collect_group(s, 1) == (7, "{group}", "group")

    s = "{group\\%} x"
    @test _collect_group(s, 1) == (9, "{group\\%}", "group%")

end


@testset "collect_command" begin

    s = "\\i"
    @test _collect_command(s, 1) == (2, "\\i", "\u0131")  # ı

    s = "\\i \\i{} "
    @test _collect_command(s, 1) == (3, "\\i ", "\u0131")  # ı
    @test _collect_command(s, 4) == (5, "\\i", "\u0131")  # ı

    s = "x\\url{www}x"
    @test _collect_command(s, 2) == (10, "\\url{www}", "[`www`](www)")

    s = "\\href{a}{b} x"
    @test _collect_command(s, 1) == (11, "\\href{a}{b}", "[b](a)")

    s = "\\href {a} {b} x"
    @test _collect_command(s, 1) == (13, "\\href {a} {b}", "[b](a)")

    s = "\\href{a}{\\textit{a}\\%x\\textit{b}}"
    @test _collect_command(s, 1) ==
          (33, "\\href{a}{\\textit{a}\\%x\\textit{b}}", "[_a_%x_b_](a)")

    s = "\\href{a}{\\{x\\}}"
    @test _collect_command(s, 1) == (15, "\\href{a}{\\{x\\}}", "[{x}](a)")

    #! format: off
    s = "\\href{https://en.wikipedia.org/wiki/Schrödinger%27s_cat}{Schrödinger's cat} x"
    @test _collect_command(s, 1) == (77, "\\href{https://en.wikipedia.org/wiki/Schrödinger%27s_cat}{Schrödinger's cat}", "[Schrödinger's cat](https://en.wikipedia.org/wiki/Schrödinger%27s_cat)")
    #! format: on

    s = "\\t{oo}"
    @test _collect_command(s, 1) == (6, "\\t{oo}", "o͡o")

    s = "\\i x"
    @test _collect_command(s, 1) == (3, "\\i ", "ı")

    s = "\\d ox"
    @test _collect_command(s, 1) == (4, "\\d o", "ọ")

    s = "\\S"
    @test _collect_command(s, 1) == (2, "\\S", "§")

    @test_throws BoundsError _collect_command("\\url", 1)

    #! format: off
    s = "\\href{a} x"
    @test_throws ArgumentError("Expected '{' at pos 10 in \"\\\\href{a} x\", not 'x'") _collect_command(s, 1)
    #! format: on

end


@testset "collect_accent" begin

    #       1234567891123456789212345678931234567894123456789512345678961
    s = raw"x\`o \`{o} \'o \'{o} \^o \^{o} \~o \~{o} \=o \={o} \.o \.{o}x"
    @test length(s) == 61
    @test _collect_accent(s, 2) == (4, "\\`o", "o\u0300")
    @test _collect_accent(s, 6) == (10, "\\`{o}", "o\u0300")
    @test _collect_accent(s, 12) == (14, "\\'o", "o\u0301")
    @test _collect_accent(s, 16) == (20, "\\'{o}", "o\u0301")
    @test _collect_accent(s, 22) == (24, "\\^o", "o\u0302")
    @test _collect_accent(s, 26) == (30, "\\^{o}", "o\u0302")
    @test _collect_accent(s, 32) == (34, "\\~o", "o\u0303")
    @test _collect_accent(s, 36) == (40, "\\~{o}", "o\u0303")
    @test _collect_accent(s, 42) == (44, "\\=o", "o\u0304")
    @test _collect_accent(s, 46) == (50, "\\={o}", "o\u0304")
    @test _collect_accent(s, 52) == (54, "\\.o", "o\u0307")
    @test _collect_accent(s, 56) == (60, "\\.{o}", "o\u0307")
    @test tex_to_markdown(s) ==
          "x\uf2 \uf2 \uf3 \uf3 \uf4 \uf4 \uf5 \uf5 \u14d \u14d \u22f \u22fx"

    #    1 2 34567 8 91123
    s = "x\\\"ox x\\\"{o}x"
    @test length(s) == 13
    @test _collect_accent(s, 2) == (4, "\\\"o", "o\u0308")
    @test _collect_accent(s, 8) == (12, "\\\"{o}", "o\u0308")
    @test tex_to_markdown(s) == "x\uf6x x\uf6x"

    s = "\\\"\\\\o"
    @test_throws ArgumentError _collect_accent(s, 1)

    s = "\\\"\\url{x}"
    c = IOCapture.capture(rethrow=Union{}) do
        _collect_accent(s, 1)
    end
    @test c.value == ArgumentError("Unsupported accent: \\\"\\url{x}.")
    @test contains(
        c.output,
        "Error: Accents may only be followed by group, a single ASCII letter, or **a supported zero-argument command**."
    )

    s = "\\\"|"
    c = IOCapture.capture(rethrow=Union{}) do
        _collect_accent(s, 1)
    end
    @test c.value == ArgumentError("Unsupported accent: \\\"|.")
    @test contains(
        c.output,
        "Error: Accents may only be followed by group, a single ASCII letter, or a supported zero-argument command."
    )

    s = "\\\"\\i\\\"{\\i}"
    @test _collect_accent(s, 1) == (4, "\\\"\\i", "\u131\u308")  # ı̈
    @test _collect_accent(s, 5) == (10, "\\\"{\\i}", "\u131\u308")  # ı̈
    @test tex_to_markdown(s) == "\u131\u308\u131\u308"

end


@testset "collect_math" begin

    #! format: off
    s = "a \$\\int_{-\\infty}^{\\infty} x^2 dx\$ b"
    @test _collect_math(s, 3) == (34, "\$\\int_{-\\infty}^{\\infty} x^2 dx\$", "``\\int_{-\\infty}^{\\infty} x^2 dx``")
    #! format: on

    @test_throws BoundsError _collect_math("\$x^2", 1)

end


@testset "special characters" begin
    @test tex_to_markdown("--- -- ---") == "\u2014 \u2013 \u2014"  # "— – —"
    @test tex_to_markdown("---~--~---") == "\u2014\u00a0\u2013\u00a0\u2014"  # "— – —"
    @test tex_to_markdown("1--2") == "1\u20132"  # "1–2"
    @test tex_to_markdown("1---2") == "1\u20142"  # "1—2"
end

@testset "accents" begin
    # unlike "collect_accent", this tests accents in the context of a full
    # string
    #! formatt: off
    @test tex_to_markdown(
        raw"\`{o}\'{o}\^{o}\~{o}\={o}\u{o}\.{o}\\\"{o}\r{a}\H{o}\v{s}\d{u}\c{c}\k{a}\b{b}\~{a}"
    ) == "\uf2\uf3\uf4\uf5\u14d\u14f\u22f\uf6\ue5\u151\u161\u1ee5\ue7\u105\u1e07\ue3"  # "òóôõōŏȯöåőšụçąḇã"
    @test tex_to_markdown(
        raw"\`o\'o\^o\~o\=o\u{o}\.o\\\"o\r{a}\H{o}\v{s}\d{u}\c{c}\k{a}\b{b}\~a"
    ) == "\uf2\uf3\uf4\uf5\u14d\u14f\u22f\uf6\ue5\u151\u161\u1ee5\ue7\u105\u1e07\ue3"  # "òóôõōŏȯöåőšụçąḇã"
    @test tex_to_markdown(raw"\i{}\o{}\O{}\l{}\L{}\i\o\O\l\L") ==
          "\u131\uf8\ud8\u142\u141\u131\uf8\ud8\u142\u141"  # "ıøØłŁıøØłŁ"
    @test tex_to_markdown(raw"\i \o \O \l \L \i{ }\o{ }\O{ }\l{ }\L") ==
          "\u131\uf8\ud8\u142\u141\u131 \uf8 \ud8 \u142 \u141"  # "ıøØłŁı ø Ø ł Ł"
    @test tex_to_markdown(raw"\SS\ae\oe\AE\OE \AA \aa") == "SS\ue6\u153\uc6\u152\uc5\ue5"  # "SSæœÆŒÅå"
    @test tex_to_markdown(raw"{\OE}{\AA}{\aa}") == "\u152\uc5\ue5" #  "ŒÅå"
    @test tex_to_markdown(raw"\t{oo}x\t{az}") == "o\u361oxa\u361z"  # "o͡oxa͡z"
    @test tex_to_markdown(raw"{\o}verline") == "øverline"
    @test tex_to_markdown(raw"\o{}verline") == "øverline"
    @test tex_to_markdown(raw"a\t{oo}b") == "ao\u361ob"  # "ao͡ob"
    @test tex_to_markdown(raw"\i x") == "\u0131x"  # "ıx"
    @test tex_to_markdown("\\\"\\i x") == "\u131\u308x"  # "ı̈x"
    @test tex_to_markdown(raw"\i\j \\\"i \\\"j \\\"\i \\\"\j") ==
          "\u0131\u0237\u00EF j\u0308 \u0131\u0308\u0237\u0308"  # "ıȷï j̈ ı̈ȷ̈"
    @test tex_to_markdown(raw"\d ox") == "\u1ecdx"  # "ọx"
    @test tex_to_markdown(raw"\d{ox}") == "\u1ecdx"  # "ọx"
    @test tex_to_markdown(raw"\d{o}x") == "\u1ecdx"  # "ọx"
    #! formatt: on
end


@testset "names" begin
    @test tex_to_markdown(raw"Fran\c{c}ois") == "François"
    @test tex_to_markdown(raw"Kn\\\"{o}ckel") == "Knöckel"
    @test tex_to_markdown(raw"Kn\\\"ockel") == "Knöckel"
    @test tex_to_markdown(raw"Ga\\\"{e}tan") == "Gaëtan"
    @test tex_to_markdown(raw"Ga{\\\"e}tan") == "Gaëtan"
    @test tex_to_markdown(raw"C\^ot\'e") == "Côté"
    @test tex_to_markdown(raw"Gro{\ss}") == "Groß"
    @test tex_to_markdown(raw"{\L}ukasz") == "Łukasz"
    @test tex_to_markdown(raw"Ji\v{r}\'i") == "Jiří"
    @test tex_to_markdown(raw"{\\\"U}nl{\\\"u}") == "Ünlü"
    @test tex_to_markdown(raw"{\c C}a{\u g}lar") == "Çağlar"
    @test tex_to_markdown(raw"{\\\"U}nl{\\\"u}, {\c C}a{\u g}lar") == "Ünlü, Çağlar"
end

@testset "titles" begin

    #! format: off

    s = "An {{Introduction}} to {{Optimization}} on {{Smooth Manifolds}}"
    @test tex_to_markdown(s) == "An Introduction to Optimization on Smooth Manifolds"
    @test tex_to_markdown(s; transform_case=lowercase) == "an Introduction to Optimization on Smooth Manifolds"

    s = "Experimental observation of magic-wavelength behavior of \$Rb87\$ atoms in an optical lattice"
    @test tex_to_markdown(s) == "Experimental observation of magic-wavelength behavior of ``Rb87`` atoms in an optical lattice"

    s = "{Rubidium 87 D Line Data}"
    @test tex_to_markdown(s; transform_case=lowercase) == "Rubidium 87 D Line Data"

    s = "A Direct Relaxation Method for Calculating Eigenfunctions and Eigenvalues of the Schr{\\\"o}dinger Equation on a Grid"
    @test tex_to_markdown(s) == "A Direct Relaxation Method for Calculating Eigenfunctions and Eigenvalues of the Schrödinger Equation on a Grid"

    s = "Matter-wave Atomic Gradiometer Interferometric Sensor ({MAGIS-100})"
    @test tex_to_markdown(s; transform_case=lowercase) == "matter-wave atomic gradiometer interferometric sensor (MAGIS-100)"

    s = "Controlled dissociation of {I\$_2\$} via optical transitions between the {X} and {B} electronic states"
    @test tex_to_markdown(s; transform_case=lowercase) == "controlled dissociation of I``_2`` via optical transitions between the X and B electronic states"

    s = "\\texttt{DifferentialEquations.jl} -- A Performant and Feature-Rich Ecosystem for Solving Differential Equations in {Julia}"
    @test tex_to_markdown(s) == "`DifferentialEquations.jl` – A Performant and Feature-Rich Ecosystem for Solving Differential Equations in Julia"

    s = "Machine learning {\\&} artificial intelligence in the quantum domain: a review of recent progress"
    @test tex_to_markdown(s) == "Machine learning & artificial intelligence in the quantum domain: a review of recent progress"

    s = "Mutually unbiased binary observable sets on \\textit{N} qubits"
    @test tex_to_markdown(s) == "Mutually unbiased binary observable sets on _N_ qubits"

    #! format: on

end

@testset "incomplete" begin

    s = "Text with incomplete \$math..."
    c = IOCapture.capture(rethrow=Union{}) do
        tex_to_markdown(s)
    end
    @test c.value isa ArgumentError
    @test contains(c.value.msg, "Premature end of tex string")

    s = "Text with incomplete {group..."
    c = IOCapture.capture(rethrow=Union{}) do
        tex_to_markdown(s)
    end
    @test c.value isa ArgumentError
    @test contains(c.value.msg, "Premature end of tex string")

    s = "Text with incomplete \\url{cmd..."
    c = IOCapture.capture(rethrow=Union{}) do
        tex_to_markdown(s)
    end
    @test c.value isa ArgumentError
    @test contains(c.value.msg, "Premature end of tex string")

    s = "Text with incomplete \\url"  # missing argument
    c = IOCapture.capture(rethrow=Union{}) do
        tex_to_markdown(s)
    end
    @test c.value isa ArgumentError
    @test contains(c.value.msg, "Premature end of tex string")

    s = "Text with incomplete \\href{text}"  # missing argument
    c = IOCapture.capture(rethrow=Union{}) do
        tex_to_markdown(s)
    end
    @test c.value isa ArgumentError
    @test contains(c.value.msg, "Premature end of tex string")

end


@testset "invalid" begin

    s = "Text with incomplete \\invalidcommand"
    c = IOCapture.capture(rethrow=Union{}) do
        tex_to_markdown(s) == ""
    end
    @test c.value isa ArgumentError
    @test contains(c.value.msg, "Unsupported command: \\invalidcommand")
    @test contains(c.output, "Supported commands are: ")

    s = "Text with unescaped %"
    c = IOCapture.capture(rethrow=Union{}) do
        tex_to_markdown(s) == ""
    end
    @test c.value isa ArgumentError
    @test c.value.msg ==
          "Character '%' at pos 21 in \"Text with unescaped %\" must be escaped"

    s = "Text with non-ascii \\commänd{x}"
    c = IOCapture.capture(rethrow=Union{}) do
        tex_to_markdown(s) == ""
    end
    @test c.value isa ArgumentError
    @test c.value.msg == "Invalid command: \\commänd{x}"

    s = "Text with \\command_with_underscore{x}"
    # LaTeX does not allow for underscore in commands
    c = IOCapture.capture(rethrow=Union{}) do
        tex_to_markdown(s) == ""
    end
    @test c.value isa ArgumentError
    @test c.value.msg == "Invalid command: \\command_with_underscore{x}"

    s = "\\href{a}{Link text with \\error{unknown command}}"
    c = IOCapture.capture(rethrow=Union{}) do
        tex_to_markdown(s) == ""
    end
    @test c.value isa ArgumentError
    @test c.value.msg ==
          "Cannot evaluate \\href: ArgumentError(\"Unsupported command: \\\\error. Please report a bug.\")"

    s = "The krotov Pyhon package is available on [Github](https://github.com/qucontrol/krotov)"
    c = IOCapture.capture(rethrow=Union{}) do
        tex_to_markdown(s)
    end
    @test c.value == s
    @test contains(
        c.output,
        "Warning: The tex string \"The krotov Pyhon package is available on [Github](https://github.com/qucontrol/krotov)\" appears to contain a link in markdown syntax"
    )

end


@testset "replacement collisions" begin

    # An earlier implementation would fail the check below on Julia 1.6,
    # because `replace` in Julia 1.6 does not support making multiple
    # substitutions at once. We've mitigated this by using a more elaborate
    # `_keys` function inside `_process_tex`
    s = "{\\{2\\}} {collision} {\\{1\\}}"
    @test _process_tex(s) == "{2} collision {1}"

end


@testset "custom command" begin

    # This is an undocumented feature (as indicated by the underscores in the
    # names) to add support for new commands to `tex_to_markdown`.  People are
    # encouraged to to submit bug reports for any "legitimate" command that
    # occurs in `.bib` files "in the wild". Manually extending functionality in
    # the `docs/make.jl` file as below is a fallback for the "less-legitimiate"
    # edge cases.

    DocumenterCitations._COMMANDS_NUM_ARGS["\\ket"] = 1
    DocumenterCitations._COMMANDS_TO_MD["\\ket"] =
        str -> begin
            md_str = DocumenterCitations._process_tex(str)
            return "|$(md_str)⟩"
        end

    s = "\\ket{Ψ}"
    @test tex_to_markdown(s) == "|Ψ⟩"

    delete!(DocumenterCitations._COMMANDS_NUM_ARGS, "\\ket")
    delete!(DocumenterCitations._COMMANDS_TO_MD, "\\ket")

end
