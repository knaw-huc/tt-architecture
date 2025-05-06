.PHONY: all

all: README.html README.pdf

%.html: %.md
	sed -e 's/```mermaid/```{.mermaid format=svg}/' $< | pandoc -t html -F mermaid-filter -o $@

%.pdf: %.md
	pandoc -t pdf -F mermaid-filter -o $@ $<
