
SCRIPT_DIR=scripts
JUMANPM_DIR=scripts/lib/

MKDIRTS:=mkdarts_jumanpp

DIC_DIRS=dic wikipediadic wiktionarydic webdic onomatopedic userdic
MDIC_LIST=$(addsuffix .mdic,$(DIC_DIRS))
BASIC_DICTS=$(shell find dic -name "*.dic"|grep -v "Rengo.dic"|grep -v "ContentW.dic")
JPPDIC_LIST=$(addsuffix .jppdic,$(DIC_DIRS))

.PHONY: jumanpp 
all: jumanpp

scripts/lib/Grammar.pm: grammar/JUMAN.katuyou grammar/JUMAN.grammar grammar/JUMAN.kankei
	rm -f scripts/lib/Grammar.pm
	perl -I scripts/lib/ scripts/mkgrammarpm grammar -o scripts/lib/Grammar.pm 

%.jppdic : %.mdic | scripts/lib/Grammar.pm $(SCRIPT_DIR)/jumandic2morphdic.perl
	PERL5LIB="" perl -I$(SCRIPT_DIR) -I$(JUMANPM_DIR) $(SCRIPT_DIR)/jumandic2morphdic.perl --nominalize --okurigana < $< > $@ 

jumanpp: $(MDIC_LIST) | scripts/lib/Grammar.pm
	mkdir -p jumanpp_dic
	cat $^ | PERL5LIB="" perl -I$(SCRIPT_DIR) -I$(JUMANPM_DIR) $(SCRIPT_DIR)/jumandic2morphdic.perl --nominalize --okurigana > jumanpp_dic/jumanpp.dic
	git log --oneline --date=format:%Y%m%d --format=%ad-%h --max-count=1 HEAD > jumanpp_dic/version

%.mdic: %
	cat $</*.dic > $@

wikipediadic.mdic: wikipediadic wikipediadic/wikipedia.dic.orig 
	cat wikipediadic/wikipedia.dic.orig > $@

dic.mdic: $(BASIC_DICTS) dic/ContentW.marked_dic 
	cat $^ > dic.mdic


clean:
	rm *.mdic *.jppdic