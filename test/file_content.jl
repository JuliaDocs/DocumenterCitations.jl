"""Wrapper around the content of a text file, for testing.

```julia
file = FileContent(name)
```

can be used as

```julia
@test file.exists
@test "string" in file
@test contains(file, "string")
```

Apart from providing the convenient `in`, when the test fails, this produces
more useful output than the equivalent

```
file = read(name, String)
@test contains(file, "string")
```

in that it doesn't dump the entire content of the file to the screen.
"""
struct FileContent
    name::String
    exists::Bool
    content::String
    function FileContent(filename)
        if isfile(filename)
            new(abspath(filename), true, read(filename, String))
        else
            new(abspath(filename), false, "")
        end
    end
end

Base.show(io::IO, f::FileContent) = print(io, "<Content of $(f.name)>")

Base.in(str, file::FileContent) = contains(file.content, str)

Base.contains(file::FileContent, str) = contains(file.content, str)
