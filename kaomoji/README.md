# Juman++ Kaomoji database

It is compiled from Juman Kaomoji database
with additions from NEologd and Unidic.

## How to update for the newer releases of NEologd

Requres: xzgrep utility

* Clone [NEologd project](https://github.com/neologd/mecab-ipadic-neologd)
* Run ./update_neologd.sh `${PATH_TO_NEOLOGD}` (no extraction of xz needed)

## How to update for the newer releases of Unidic

* Download a [newest Unidic](http://unidic.ninjal.ac.jp/back_number#unidic_cwj)
* Extract the archive file
* Run `./update_unidic.sh $PATH_TO_UNIDIC`