.PHONY: all clean

ALL = numeric.pdf authoryear.pdf rmp.pdf prb.pdf alpha.pdf

all: $(ALL)

numeric.pdf: numeric.tex
	pdflatex $<
	bibtex $(basename $<)
	pdflatex $<
	pdflatex $<

authoryear.pdf: authoryear.tex
	pdflatex $<
	bibtex $(basename $<)
	pdflatex $<
	pdflatex $<

rmp.pdf: rmp.tex
	pdflatex $<
	bibtex $(basename $<)
	pdflatex $<
	pdflatex $<

prb.pdf: prb.tex
	pdflatex $<
	bibtex $(basename $<)
	pdflatex $<
	pdflatex $<

alpha.pdf: alpha.tex
	pdflatex $<
	bibtex $(basename $<)
	pdflatex $<
	pdflatex $<

clean:
	@rm -f ${ALL}
	@rm -f *.aux
	@rm -f *.log
	@rm -f *.toc
	@rm -f *.blg
	@rm -f *.bbl
	@rm -rf *.out
	@rm -rf .cache
	@rm -f *.bak
	@rm -f *.ilg
	@rm -f *.snm
	@rm -f *.nav
	@rm -f *.table
	@rm -f *.dvi
	@rm -f *.fls
	@rm -f *~
	@rm -f *Notes.bib
	@rm -f *-eps-converted-to.pdf
	@rm -f *.fdb_latexmk
	@rm -f *.synctex.gz*
	@rm -f .latexrun.db*
