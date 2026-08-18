.PHONY: all png

all: png README.html README.pdf

%.html: %.md
	@echo "Note: for this to work you require pandoc and mermaid 11.4 or above)"""
	pandoc -t html -o $@ $<

%.pdf: %.md
	@echo "Note: for this to work you require pandoc and mermaid 11.4 or above)"""
	pandoc -t pdf -o $@ $<

png: architecture.png

%.svg: %.mmd
	mmdc -i $< -o $(basename $<).svg

%.png: %.mmd
	mmdc -w 3820 -i $< -o $(basename $<).png

clean:
	-rm -f architecture.png README.html README.pdf
