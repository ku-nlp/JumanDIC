
SCRIPT_DIR=scripts
JUMANPM_DIR=scripts/lib/
INFLECTION_DIR=inflection/blib/lib/

DIC_DIRS=$(shell echo -e "dic\nwikipediadic\nwiktionarydic\nautodic\nonomatopedic\nuserdic")
MDIC_LIST=$(addsuffix .mdic,$(DIC_DIRS))
BASIC_DICTS=$(shell find dic -name "*.dic"|grep -v "Rengo.dic"|grep -v "ContentW.dic")

.PHONY: jumanpp 
all: jumanpp

jumanpp: $(MDIC_LIST)
	mkdir -p jumanpp_dic &&\
	cat $^ | PERL5LIB="" perl -I$(SCRIPT_DIR) -I$(INFLECTION_DIR) -I$(JUMANPM_DIR)  $(SCRIPT_DIR)/jumandic2morphdic.perl --nominalize --okurigana > jumanpp.mdic &&\
	mkdarts_jumanpp jumanpp.mdic jumanpp_dic/dic &&\
	git log -1 --date=local --format="%ad-%h" > jumanpp_dic/version

%.mdic: %
	cat $</*.dic > $@

wikipediadic.mdic: wikipediadic wikipediadic/wikipedia.dic.orig 
	cat wikipediadic/wikipedia.dic.orig > $@

wikipediadic/wikipedia.dic: wikipediadic/wikipedia.dic.orig
	cat $< | ruby $(SCRIPT_DIR)/clean.dic.rb > $@ 2> wikipediadic/clean.log

dic.mdic: $(BASIC_DICTS) dic/ContentW.marked_dic 
	cat $^ > dic.mdic


