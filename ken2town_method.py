#!/bin/env python
#coding: utf-8

import re
import csv
import doctest
from collections import defaultdict

def read_town_list(csvname):#{{{
    with open(csvname, newline='',encoding='cp932') as csvfile:
        town_list = []
        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
        
        last_number = False
        last_yomi = False
        line = ""
        for row in reader:
            place_number = row[2]
            place_yomi = row[5]
            place_area = row[6]
            place_name = row[8]
            # 同じ郵便番号が連続している
            # 地名の読みが同じ
            # 括弧の数が一致していない 場合は前の町域名と繋げる必要がある
            if( last_number == place_number 
                    and last_yomi == place_yomi 
                    and (not bracket_match(line))):
                line += place_name
            elif(last_number == place_number # 正例のみ
                    and (not bracket_match(line))):
                line += place_name
            else:
                town_list.append((line,"日本:"+place_area))
                line = place_name
            last_yomi = place_yomi
            last_number = place_number
        town_list.append((line,"日本:"+place_area))
        return town_list
#}}}


def bracket_match(string):#{{{
    """ 全角括弧（）の数が一致しているかどうかを調べる
    >>> bracket_match("（（（）））") # 括弧の数が一致していれば True
    True
    >>> bracket_match("）））（（（") # 順番は関係がない
    True
    >>> bracket_match("（（（））") # 一致していなければ False
    False
    >>> bracket_match("あいうえお") # 括弧が存在しない場合も True
    True
    """
    lbra = re.findall(r"[（]",string)
    rbra = re.findall(r"[）]",string)
    if(len(lbra) != len(rbra)):
        return False
    return True
#}}}

def preprocess(place_name):#{{{
    """ 番地，丁目，など一般化できる箇所，その他，階数や住所特有の表現の削除．空白をまとめる等その他前処理．
    >>> preprocess("十区")
    ' '
    >>> preprocess("東大阪３丁目")
    '東大阪 '
    """
    # 一般化，または削除するパターン
    ## 北二十五条, 等が 北二十で切れるなどの問題があったため，xx条を除く
    place_name = re.sub(r"[一二三四五六七八九十０１２３４５６７８９]+条","[N条]",place_name)
    place_name = re.sub(r"[一二三四五六七八九十０１２３４５６７８９]+筋目","[N条]",place_name)
    place_name = re.sub(r"[一二三四五六七八九十０１２３４５６７８９～]+区","[N区]",place_name)
    place_name = re.sub(r"[一二三四五六七八九十０１２３４５６７８９～]+線","[N線]",place_name)
    place_name = re.sub(r"[一二三四五六七八九十０１２３４５６７８９～]+号","[N号]",place_name)
    place_name = re.sub(r"第[一二三四五六七八九十０１２３４５６７８９～]+(町|町内)?","[第N]",place_name)
    place_name = re.sub(r"[０１２３４５６７８９～〜、の]+丁目","[N丁目]",place_name)
    place_name = re.sub(r"（[０１２３４５６７８９]+丁）","",place_name)
    place_name = re.sub(r"[０１２３４５６７８９～〜－、・の]+番地","[N番地]",place_name)
    place_name = re.sub(r"[０１２３４５６７８９～〜－、の]+番町","[N番町]",place_name)
    place_name = re.sub(r"[０１２３４５６７８９～〜－、 ]+地割","[N地割]",place_name)
    place_name = re.sub(r"[０１２３４５６７８９～〜－]+の通り","[Nの通り]",place_name)
    place_name = re.sub(r"（[０１２３４５６７８９～〜－]+階）","[N階]",place_name)
    place_name = re.sub(r"[０１２３４５６７８９～〜－]+以[上下]）","[以上]）",place_name)
    place_name = re.sub(r"「[０１２３４５６７８９～〜－、]+を除く」","[を除く]）",place_name)
    place_name = re.sub(r"（[東西南北０１２３４５６７８９〜]+）","",place_name)
    place_name = re.sub(r"[０１２３４５６７８９～〜－、の ]+）","[番地]）",place_name)
    place_name = re.sub(r"[一二三四五六七八九十０１２３４５６７８９～・]+番","[N番]",place_name)
    place_name = re.sub(r"「[０１２３４５６７８９～〜－、]*」","",place_name)
    place_name = re.sub(r"[０１２３４５６７８９]+[～〜－、の]+[０１２３４５６７８９～〜－、の]+","[番地]",place_name)
    place_name = re.sub(r"駅[東西南北]$","",place_name)
    place_name = re.sub(r"その他","",place_name)
    place_name = re.sub(r"番地のみ","",place_name)
    place_name = re.sub(r"次のビルを除く","",place_name)
    place_name = re.sub(r"地階・階層不明","",place_name)
    place_name = re.sub(r"・"," ",place_name) 
    place_name = re.sub(r"市街地","",place_name) # 住所特有の表現を削除
    place_name = re.sub(r"（[^）]*$","",place_name) # 閉じていない括弧の除去
    place_name = re.sub(r"「[^」]*$","",place_name) # 閉じていない括弧の除去

    place_name = re.sub(r"\[.*?\]"," ",place_name)
    place_name = re.sub(r"（ *）"," ", place_name)
    place_name = re.sub(r"（"," ", place_name)
    place_name = re.sub(r"「"," ", place_name)
    place_name = re.sub(r"」"," ", place_name)
    place_name = re.sub(r"）"," ", place_name)
    place_name = re.sub(r"、"," ", place_name)

    #地割～ 地割
    place_name = re.sub(r"地割 *～ *地割"," ", place_name)

    
    # 西入，東入，上る，下る
    place_name = re.sub(r"[西東]入"," ", place_name)
    place_name = re.sub(r"[上下]る"," ", place_name)
    place_name = re.sub(r"[東西南北]側$"," ", place_name)
    place_name = re.sub(r"の[上下前後外]$"," ", place_name)

    # 連続する空白をまとめる
    place_name = re.sub(r" +"," ", place_name)
    return place_name
#}}}

def is_townname(name):#{{{
    """ 町名として適切かどうかを判定する
    >>> is_townname("御徒町")
    True
    >>> is_townname("以下に掲載がない場合")
    False
    >>> is_townname("境町の次に番地がくる場合")
    False
    >>> is_townname("以下に掲載がない場合")
    False
    """
    if(name == "以下に掲載がない場合"):
        return False
    if(re.search(r"〔東京電力福島第二原子力発電所構内〕",name)):
        return False
    # 番地の途中で改行されている場合に生じる断片の除去
    if(re.match(r"^[０１２３４５６７８９－、～〜－、の（）]*$", name)):
        return False
    # 対応がとれていない括弧
    if(re.match(r"^[^（]*）$", name) or re.match(r"^[^「]*」.*$", name)):
        return False
    if(re.match(r"^.*の次に番地がくる場合$", name)):
        return False
    return True
#}}}

def get_all_prefix_map(str1, str2, prefix_map):#{{{
    """ str1 と str2 の二文字以上の共通 prefix と prefix以降のmap をdictで返す
    >>> sorted(get_all_prefix_map("あいうえお","あいうえおか",defaultdict(list)).items())
    [('あい', ['うえお', 'うえおか']), ('あいう', ['えお', 'えおか']), ('あいうえ', ['お', 'おか']), ('あいうえお', ['', 'か'])]
    >>> sorted(get_all_prefix_map("あい","あい２",get_all_prefix_map("あい","あい１",defaultdict(list))).items())
    [('あい', ['', '１', '', '２'])]
    >>> sorted(get_all_prefix_map("あいうえお","あえおか",defaultdict(list)).items())
    []
    >>> sorted(get_all_prefix_map('末吉', '住吉',defaultdict(list)).items())
    []
    """
    # 共通する prefix で分割
    min_length = min(len(str1),len(str2))
    if(min_length == 0 or str1[0] != str2[0]):
        return prefix_map
    for ind in range(1, min_length):
        if(str1[ind] == str2[ind]):
            prefix = str1[0:ind+1]
            suffix1 = str1[ind+1:]
            suffix2 = str2[ind+1:]
            # ひらがなで分割する prefix-suffix のペアは候補に含めない
            if(not (re.search("[ぁ-ん]$",prefix) and re.search("^[ぁ-ん]",suffix1)and re.search("^[ぁ-ん]",suffix2))):
                prefix_map[prefix].append(suffix1)
                prefix_map[prefix].append(suffix2)
        else:
            return prefix_map
    return prefix_map
#}}}

# 使用していない
def get_prefix(str1, str2):#{{{
    """ str1 と str2 の二文字以上で，最長の共通prefixを返す
    >>> get_prefix("abcd","abcefg")
    'abc'
    >>> get_prefix("abcd","bcd")
    ''
    """
    prefix = ""
    # 共通する prefix で分割
    min_length = min(len(str1),len(str2))
    for ind in range(min_length):
        if(str1[ind] == str2[ind]):
            prefix += str1[ind]
        else:
            return prefix
    return prefix
#}}}
def get_all_prefix(str1, str2):#{{{
    """ str1 と str2 の二文字以上の共通 prefix をリストで返す
    >>> get_all_prefix("あいうえお","あいうえおか")
    ['あい', 'あいう', 'あいうえ', 'あいうえお']
    >>> get_all_prefix("あいうえお","あえおか")
    []
    """
    prefix = []
    # 共通する prefix で分割
    min_length = min(len(str1),len(str2))
    for ind in range(1, min_length):
        if(str1[ind] == str2[ind]):
            prefix.append(str1[0:ind+1])
        else:
            return prefix
    return prefix
#}}}
def preprocess_old(place_name):#{{{
    """ 番地，丁目，など一般化できる箇所，その他，階数や住所特有の表現の削除．空白をまとめる等その他前処理．
    >>> preprocess_old("十条")
    ' '
    >>> preprocess_old("東大阪３丁目")
    '東大阪 '
    """
    # 一般化，または削除するパターン
    place_name = re.sub(r"[一二三四五六七八九十０１２３４５６７８９]+条","[N条]",place_name)
    place_name = re.sub(r"[一二三四五六七八九十０１２３４５６７８９～]+区","[N区]",place_name)
    place_name = re.sub(r"[一二三四五六七八九十０１２３４５６７８９～]+線","[N線]",place_name)
    place_name = re.sub(r"[一二三四五六七八九十０１２３４５６７８９～]+号","[N号]",place_name)
    place_name = re.sub(r"第[一二三四五六七八九十０１２３４５６７８９～]+(町|町内)?","[第N]",place_name)
    place_name = re.sub(r"[０１２３４５６７８９～〜、の]+丁目","[N丁目]",place_name)
    place_name = re.sub(r"（[０１２３４５６７８９]+丁）","",place_name)
    place_name = re.sub(r"[０１２３４５６７８９～〜－、・の]+番地","[N番地]",place_name)
    place_name = re.sub(r"[０１２３４５６７８９～〜－、の]+番町","[N番町]",place_name)
    place_name = re.sub(r"[０１２３４５６７８９～〜－、 ]+地割","[N地割]",place_name)
    place_name = re.sub(r"[０１２３４５６７８９～〜－]+の通り","[Nの通り]",place_name)
    place_name = re.sub(r"（[０１２３４５６７８９～〜－]+階）","[N階]",place_name)
    place_name = re.sub(r"[０１２３４５６７８９～〜－]+以[上下]）","[以上]）",place_name)
    place_name = re.sub(r"「[０１２３４５６７８９～〜－、]+を除く」","[を除く]）",place_name)
    place_name = re.sub(r"（[東西南北０１２３４５６７８９〜]+）","",place_name)
    place_name = re.sub(r"[０１２３４５６７８９～〜－、の ]+）","[番地]）",place_name)
    place_name = re.sub(r"[一二三四五六七八九十０１２３４５６７８９～・]+番","[N番]",place_name)
    place_name = re.sub(r"「[０１２３４５６７８９～〜－、]*」","",place_name)
    place_name = re.sub(r"[０１２３４５６７８９]+[～〜－、の]+[０１２３４５６７８９～〜－、の]+","[番地]",place_name)
    place_name = re.sub(r"その他","",place_name)
    place_name = re.sub(r"次のビルを除く","",place_name)
    place_name = re.sub(r"地階・階層不明","",place_name)
    place_name = re.sub(r"・"," ",place_name) 
    place_name = re.sub(r"市街地","",place_name) # 住所特有の表現を削除
    place_name = re.sub(r"（[^）]*$","",place_name) # 閉じていない括弧の除去
    place_name = re.sub(r"「[^」]*$","",place_name) # 閉じていない括弧の除去

    place_name = re.sub(r"\[.*?\]"," ",place_name)
    place_name = re.sub(r"（ *）"," ", place_name)
    place_name = re.sub(r"（"," ", place_name)
    place_name = re.sub(r"「"," ", place_name)
    place_name = re.sub(r"」"," ", place_name)
    place_name = re.sub(r"）"," ", place_name)
    place_name = re.sub(r"、"," ", place_name)

    # 連続する空白をまとめる
    place_name = re.sub(r" +"," ", place_name)
    return place_name
#}}}

if __name__ == "__main__":
        doctest.testmod()
