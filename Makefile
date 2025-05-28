.PHONY: all extractmmd png

all: README.html README.pdf

%.html: %.md
	@echo "Note: for this to work you require pandoc, mermaid-filter with mermaid 11.4 or above)"""
	sed -e 's/```mermaid/```{.mermaid format=svg}/' $< | pandoc -t html -F mermaid-filter -o $@

%.pdf: %.md
	@echo "Note: for this to work you require pandoc, mermaid-filter with mermaid 11.4 or above and latex)"""
	sed -e 's/```mermaid/```{.mermaid format=pdf}/' $< | pandoc -t pdf -F mermaid-filter -o $@

png: extractmmd 1.png 2.png 3.png 4.png 5.png

extractmmd:
	python extractmmd.py

%.mmd: extractmmd

%.svg: %.mmd
	mmdc -i $< -o $(basename $<).svg

%.png: %.mmd
	mmdc -w 3820 -i $< -o $(basename $<).png
