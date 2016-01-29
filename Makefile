
# JUMANのインストール先
JUMAN_PREFIX=/share/usr-x86_64
# KKN のディレクトリ
KKN_PREFIX=/home/morita/work/violet/kkn

SCRIPT_DIR=scripts

DIC_DIRS=$(shell find . -maxdepth 1 -type d -name "*dic")
DA_LIST=$(addsuffix /jumandic.da,$(DIC_DIRS))
MDIC_LIST=$(addsuffix .mdic,$(DIC_DIRS))
BASIC_DICTS=$(shell find dic -name "*.dic"|grep -v "Rengo.dic")

all: juman kkn

juman: $(DA_LIST)
	git log -1 --date=local --format="%ad-%h" > dic.version

kkn: $(MDIC_LIST)
	mkdir -p kkn &&\
	cat $^ | PERL5LIB="" perl -I$(SCRIPT_DIR) $(SCRIPT_DIR)/jumandic2morphdic.perl > kkn.mdic &&\
	$(KKN_PREFIX)/mkdarts kkn.mdic kkn/dic &&\
	git log -1 --date=local --format="%ad-%h" > kkn/version

# Wikipedia のみ特殊化する
wikipediadic/jumandic.da: wikipediadic/wikipedia.dic
	sh $(SCRIPT_DIR)/update.sh -d wikipediadic 

%/jumandic.da: %
	sh $(SCRIPT_DIR)/update.sh -d $< 

%.mdic: %
	cat $</*.dic > $@

wikipediadic.mdic: wikipediadic wikipediadic/wikipedia.dic.orig 
	cat wikipediadic/wikipedia.dic.orig > $@

wikipediadic/wikipedia.dic: wikipediadic/wikipedia.dic.orig
	cat $< | ruby $(SCRIPT_DIR)/clean.dic.rb > $@ 2> wikipediadic/clean.log

dic.mdic: dic	
	cat $(BASIC_DICTS) dic/lexicon_from_rengo.mdic > dic.mdic

