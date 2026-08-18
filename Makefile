.PHONY: all png artifacts

all artifacts: png artifacts/README.html artifacts/README.pdf

artifacts/%.html: %.md
	@echo "Note: for this to work you require pandoc and mermaid 11.4 or above)""">&2
	pandoc -t html -o $@ $<

artifacts/%.pdf: %.md
	@echo "Note: for this to work you require pandoc and mermaid 11.4 or above)""">&2
	pandoc -t pdf -o $@ $<

png: artifacts/architecture.png

artifacts/%.svg: %.mmd
	mmdc -i $< -o artifacts/$*.svg

artifacts/%.png: %.mmd
	mmdc -w 3820 -i $< -o artifacts/$*.png

clean:
	-rm -f artifacts/*
