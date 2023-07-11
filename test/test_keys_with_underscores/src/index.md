# Testing citation keys with underscores


## Problem description


Citations keys with underscores [rabiner_tutorial_1989](@cite) get messed up because they get mangled by the markdown parser.

At the same time, we *do* want to support nested markdown in the "notes" of a citations, e.g. [GoerzQ2022; with *emphasis*](@cite).
