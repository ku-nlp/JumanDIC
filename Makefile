
SCRIPT_DIR=scripts
JUMANPM_DIR=scripts/lib/

MKDIRTS:=mkdarts_jumanpp

DIC_DIRS=dic experiment wikipediadic wiktionarydic webdic onomatopedic userdic emoji
MDIC_LIST=$(addsuffix .mdic,$(DIC_DIRS))
BASIC_DICTS=$(shell find dic -name "*.dic"|grep -v "Rengo.dic"|grep -v "ContentW.dic")
JPPDIC_LIST=$(addsuffix .jppdic,$(DIC_DIRS))
BLACKLIST_ENTRIES=blacklist_entries.txt

.PHONY: jumanpp 
all: jumanpp

scripts/lib/Grammar.pm: grammar/JUMAN.katuyou grammar/JUMAN.grammar grammar/JUMAN.kankei
	rm -f scripts/lib/Grammar.pm
	perl -I scripts/lib/ scripts/mkgrammarpm grammar -o scripts/lib/Grammar.pm 

%.jppdic : %.mdic | scripts/lib/Grammar.pm $(SCRIPT_DIR)/jumandic2morphdic.perl
	PERL5LIB="" LC_ALL=C perl -I$(SCRIPT_DIR) -I$(JUMANPM_DIR) $(SCRIPT_DIR)/jumandic2morphdic.perl --nominalize --okurigana < $< > $@ 

jumanpp_dic/kaomoji.jppdic: kaomoji/jumandic.dic kaomoji/neologd.orig kaomoji/unidic.orig
	cd kaomoji && $(MAKE) kaomoji.jppdic
	mkdir -p jumanpp_dic
	cp kaomoji/kaomoji.jppdic jumanpp_dic/kaomoji.jppdic

jumanpp: $(MDIC_LIST) jumanpp_dic/kaomoji.jppdic | scripts/lib/Grammar.pm $(BLACKLIST_ENTRIES)
	mkdir -p jumanpp_dic
	cat $(MDIC_LIST) | LC_ALL=C PERL5LIB="" perl -I$(SCRIPT_DIR) -I$(JUMANPM_DIR) $(SCRIPT_DIR)/jumandic2morphdic.perl --nominalize --okurigana --blacklist $(BLACKLIST_ENTRIES) > jumanpp_dic/jumanpp.dic.0	
	cat jppdic.header jumanpp_dic/kaomoji.jppdic jumanpp_dic/jumanpp.dic.0 > jumanpp_dic/jumanpp.dic
	rm jumanpp_dic/jumanpp.dic.0
	git log --oneline --date=format:%Y%m%d --format=%ad-%h --max-count=1 HEAD > jumanpp_dic/version

%.mdic: %
	cat $</*.dic > $@

wikipediadic.mdic: wikipediadic/wikipedia.dic.orig.00 wikipediadic/wikipedia.dic.orig.01
	cat $^ > $@

dic.mdic: $(BASIC_DICTS) dic/ContentW.marked_dic 
	cat $^ > dic.mdic

clean:
	rm -rf *.mdic jumanpp_dic
	cd kaomoji && $(MAKE) clean
