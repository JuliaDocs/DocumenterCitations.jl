# D: Part 2.2


## First Section of Part 2.2

Ref [GoerzDiploma2010](@cite)


## Second Section of Part 2.2

Ref [GoerzJPB2011](@cite)


## Local References of Earlier Parts

This excludes the reference in `index.md` as well as the references in the *current* document.

One of the `Pages` uses `joinpath`, as an example for something where `eval` has to do some work.

**Content**

The content matches the bibliography

```@contents
Pages = [
    joinpath("..", "..", "part1", "section1", "p1_s1_page.md"),
    normpath("../../part1/section2/p1_s2_page.md"),
    normpath("../section1/p2_s1_page.md"),
]
```

**Bibliography**

```@bibliography
Canonical = false
Pages = [
    joinpath("..", "..", "part1", "section1", "p1_s1_page.md"),
    "../../part1/section2/p1_s2_page.md",
    "../section1/p2_s1_page.md",
]
```
