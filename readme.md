#README

## 初期設定
Makefile中の JUMAN_PREFIX, KKN_PREFIX を設定する
JUMAN_PREFIX=/mnt/orange/brew/data/bin/
KKN_PREFIX=/mnt/orange/brew/data/bin/

## juman用辞書生成
make juman

## KKN用辞書生成
make kkn

# TODO
* KKN表記の箇所をJUMANPPに差し替え
* 語彙獲得との連携方法を決める
* 仕様のドキュメント