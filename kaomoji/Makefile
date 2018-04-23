ZEN2HAN ?= python3 ../scripts/zen2han.py
HAN2ZEN ?= python3 ../scripts/han2zen.py
OUTPUT_SCRIPT ?= python3 ../scripts/kaomoji_output.py

jumandic.full: jumandic.dic
	grep -oE '(見出し語 [^)]+)' $< | cut -d' ' -f 2 > $@

jumandic.half: jumandic.full
	$(ZEN2HAN) < $< > $@

neologd.half: neologd.orig
	$(ZEN2HAN) < $< > $@

neologd.full: neologd.half
	$(HAN2ZEN) < $< > $@

unidic.half: unidic.orig
	$(ZEN2HAN) < $< > $@

unidic.full: unidic.orig
	$(HAN2ZEN) < $< > $@

kaomoji.jppdic: jumandic.full jumandic.half neologd.orig neologd.full \
	neologd.half unidic.orig unidic.half unidic.full
	sort $^ | uniq | $(OUTPUT_SCRIPT) $@

clean:
	rm *.half *.full kaomoji.jppdic