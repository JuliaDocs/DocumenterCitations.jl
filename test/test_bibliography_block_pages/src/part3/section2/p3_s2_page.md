# F: Part 3.2


## First Section of Part 3.2

Ref [GoerzPRA2014](@cite)


## Second Section of Part 3.2

Ref [JaegerPRA2014](@cite)


## Local References of Earlier Parts

This excludes the reference in `index.md` as well as the references in the *current* document.

The bibliography also uses a pretty fancy expression to test that we can `eval` non-trivial specification of `Pages`, not just a list of strings.


**Content**

The content matches the bibliography

```@contents
Pages = [
    [
        normpath("..", "..", "part$p", "section$s", "p$(p)_s$(s)_page.md") for
        (p, s) in Iterators.product((1, 2), (1, 2))
    ]...,
    normpath("../section1/p3_s1_page.md"),
]
```

**Bibliography**

```@bibliography
Canonical = false
Pages = [
    [
        joinpath("..", "..", "part$p", "section$s", "p$(p)_s$(s)_page.md") for
        (p, s) in Iterators.product((1, 2), (1, 2))
    ]...,
    "../section1/p3_s1_page.md",
]
```
