#README
## 概要
JUMAN, JUMAN++ 用の辞書生成スクリプト

## 初期設定
Makefileで JUMAN_PREFIX, KKN_PREFIX を設定する
```
#!sh
JUMAN_PREFIX=/mnt/orange/brew/data/bin/
KKN_PREFIX=/mnt/orange/brew/data/bin/
```

## juman用辞書生成
```
#!sh
make juman
```
## KKN用辞書生成
```
#!sh
make kkn
```

# TODO
* KKN表記の箇所をJUMANPPに差し替え
* 語彙獲得との連携方法を決める
* 仕様のドキュメンテーション