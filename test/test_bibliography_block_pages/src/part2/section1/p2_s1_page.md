# C: Part 2.1


## First Section of Part 2.1

Ref [MorzhinRMS2019](@cite)


## Second Section of Part 2.1

Ref [BrumerShapiro2003](@cite)


## Local References of Part 2.1 and Earlier Parts

This excludes the reference in `index.md`.

**Content**

The content matches the bibliography

```@contents
Pages = [
    "p2_s1_page.md", # @__FILE__ is not supported
    normpath("../../part1/section1/p1_s1_page.md"),
    normpath("../../part1/section2/p1_s2_page.md"),
]
```

**Bibliography**

```@bibliography
Canonical = false
Pages = [
    @__FILE__,  # In the @bibliography block, we can use `@__FILE`
    # Note that `@bibliography` (unlike `@contents`) doesn't need `normpath`.
    "../../part1/section1/p1_s1_page.md",
    "../../part1/section2/p1_s2_page.md",
]
```
