# Testing error for citing a non-existent keys

We cite an existing key [GoerzQ2022](@cite) and a non-existing key [NoExist2023](@cite).

In strict mode, `makedocs` errors during the collection phase.

In non-strict mode, the documentation should be rendered with "?", similar to how LaTeX itself handles missing citations. This even works for "combined references" [BrumerShapiro2003, BrifNJP2010, Shapiro2012_, KochJPCM2016_, SolaAAMOP2018, MorzhinRMS2019_, Wilhelm2003.10132, KochEPJQT2022; and references therein](@cite)

Also, with `@Citet`: [BrumerShapiro2003, BrifNJP2010, Shapiro2012_, KochJPCM2016_, SolaAAMOP2018, MorzhinRMS2019_, Wilhelm2003.10132, KochEPJQT2022; and references therein](@Citet).


Lastly, we cite a key [Tannor2007](@cite) that exists in the `.bib` file but does not appear in any bibliography block.
