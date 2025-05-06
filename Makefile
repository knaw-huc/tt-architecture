.PHONY: all

all: README.html README.pdf

%.html: %.md
	@echo "Note: for this to work you require pandoc, mermaid-filter with mermaid 11.4 or above)"""
	sed -e 's/```mermaid/```{.mermaid format=svg}/' $< | pandoc -t html -F mermaid-filter -o $@

%.pdf: %.md
	@echo "Note: for this to work you require pandoc, mermaid-filter with mermaid 11.4 or above and latex)"""
	sed -e 's/```mermaid/```{.mermaid format=pdf}/' $< | pandoc -t pdf -F mermaid-filter -o $@
