# Test of Invalid Pages

## References from Nonexisting Pages

Nothing should render here

```@bibliography
Canonical = false
Pages = [
    "index.md",
    "p3_s1_page.md",
    "noexist.md",
]
```

## References only from Pages that contain no references

Again, nothing should render here.

```@bibliography
Canonical = false
Pages = [
    "../../addendum.md",
]
```

## References Mixing Existing and Nonexisting Pages

```@bibliography
Canonical = false
Pages = [
    "p3_s1_page.md",
    "p3_s2_page.md",
]
```

The above bibliography should render only the references in [F: Part 3.2](@ref) (since the file `p3_s1_page.md` for [E: Part 3.1](@ref) exists in a different folder).

## Not passing a list to Pages

```@bibliography
Canonical = false
Pages = @__FILE__
```

