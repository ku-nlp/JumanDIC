#!/bin/env python
#coding: utf-8
import sys
import re

from ken2town_method import read_town_list, bracket_match
from ken2town_method import preprocess, is_townname, get_all_prefix_map
from collections import defaultdict

# 入力サンプル
#01101,"064  ","0640822","ﾎｯｶｲﾄﾞｳ","ｻｯﾎﾟﾛｼﾁｭｳｵｳｸ","ｷﾀ2ｼﾞｮｳﾆｼ(20-28ﾁｮｳﾒ)","北海道","札幌市中央区","北二条西（２０～２８丁目）",1,0,1,0,0,0
#01101,"060  ","0600033","ﾎｯｶｲﾄﾞｳ","ｻｯﾎﾟﾛｼﾁｭｳｵｳｸ","ｷﾀ3ｼﾞｮｳﾋｶﾞｼ","北海道","札幌市中央区","北三条東",0,0,1,0,0,0

## 要るもの
# 鳳至町（石浦町）
# 茂田井（１〜５００「２１１番地を除く」「古町」、２５２７〜２５２９「土遠」）
# 徳倉（上徳倉、下徳倉、外原）
# 飯村町西山、高山
# 高師町（北原１、１−５７、５８、７６、８０〜８６、４４番地）
# 高師町（北原、その他）
## 要らないもの
# 茂田井（その他）
# 落合（３０６０、３６００〜４６００番地）
# 南安倍（１、２丁目）
# 牧之原（２５０〜３４３番地「２５５、２５６、２５８、２５９、２６２、２７６、２９４〜３００、３０２〜３０４番地を除く」）

# 問題点#{{{

# 除くべき問題点
# ○○一条
## 伏古一条 
## あいの里一条
# 西〇〇
# 〇〇東
# ○○（〜〜丁目）
## 北五条西（２５～２９丁目） 
## 常盤（１～１３１番地）
## 藤野（４００、４００－２番地）
## 南兵村一区
## 南郷通（南）
# 〜〜[地名末尾]
# 中島公園
# 地名1地名2
## 篠路町上篠路
## 篠路町太平
# 月寒|西|一条
#ｵﾄｴﾁｮｳ(ｵﾄｴ) 音江町（音江）
#ｵﾄｴﾁｮｳ(ｷｸｵｶ) 音江町（菊丘）
#ｵﾄｴﾁｮｳ(ｸﾆﾐ23-298ﾊﾞﾝﾁ) 音江町（国見２３～２９８番地）
#ｵﾄｴﾁｮｳ(ｸﾆﾐｿﾉﾀ) 音江町（国見その他）
# 第５町内（３）
# １０号
# 南１番通
# 滝沢（下川原１９０－１）
# 仁礼町（３１５３－１～３１５３－１１００「峰の原」）
#四木、七百、下久保「１７４を除く」、下淋代、高森、通目木、坪毛沢「２
#５、６３７、６４１、６４３、６４７を除く」、中屋敷、沼久保、根古橋、堀切
#５、２７７、２８０、２９５、１１９９、１２０６、１５０４を除く」、

# match_l(内里):内里 北ノ口

#ﾒﾏﾝﾍﾞﾂｺﾊﾝ 女満別湖畔
#ﾒﾏﾝﾍﾞﾂｼｮｳﾜ 女満別昭和

# match(恵山):恵山 町 #切った結果町だけ残るのは禁止？
# match_l(恵山):恵山 岬町

# match(大):大 川町 #一文字prefix は禁止？
# match_l(大):大 手町
# match_l(大):大 縄町
# match_l(大):大 船町
# match_l(大):大 町
# match_l(大):大 澗町
# match_l(大):大 森町

#match(朝里):朝里
#match_l(朝里):朝里 川温泉 # 川，山で始まるものは除く・・・とか？(保留)

# match(神居):神居
# match_l(神居):神居 町雨紛 # match_l でも町で始まる場合はリセット？ done
# match_l(神居):神居 町上雨紛

# match(留辺蘂町旭):留辺蘂町旭
# match_l(留辺蘂町旭):留辺蘂町旭 北 #旭の前で切れて欲しいようなどちらでも良いような
# match_l(留辺蘂町旭):留辺蘂町旭 公園
# match_l(留辺蘂町旭):留辺蘂町旭 中央

# 大阪府 守口市 高瀬旧大枝
# 大阪府 守口市 高瀬旧世木
# 大阪府 守口市 高瀬旧馬場


# match(鹿の谷):鹿の谷
# match_l(鹿の谷):鹿の谷 東丘町
# nopref:鹿の谷山手町

# ３層になってる場合 ....
#match_l(栗沢町):栗沢町 美流渡楓町
#match_l(栗沢町):栗沢町 美流渡栄町
#match_l(栗沢町):栗沢町 美流渡桜町

# 一の坂町東
## 無視？

# 以下に掲載がない場合
## 除外
# 一条...九十九条 => [N条]
# １の通り => [Nの通り]
# 唐桑町西舞根（２００番以上）
# => [以上]
#}}}

def extract_townname(town_list):#{{{
    banchi_list = [] # debug 用
    for (name, area) in town_list:
        # 「」の除去 (数が少なく，副作用無く処理できるので特別に先に処理しておく)
        name = re.sub(r"「[^」]*(を除く|その他|番地|[０-９])」"," ",name)

        # 分割
        sp = re.split(r"[、（）]",name)
        if(len(sp)> 1):
            # print (name)
            for s in sp:
                if(re.match(r"^(第?[一二三四五六七八九十０１２３４５６７８９・～－の]+(条|区|線|号|町|町内|丁目|番地|地割|の通り|階|番|以降|番以降|丁|組|以内|以外|以下|以上|を除く|番地|号の沢|[〜 ])*)+$",s)):
                    #print(s + ":丁目")
                    banchi_list.append(s)
                elif(is_townname(s)):
                    s = preprocess(s)
                    town_candidates.append((s,area))
        elif(is_townname(name)):
            name = preprocess(name)
            town_candidates.append((name, area))
    return town_candidates
#}}}

def extract_prefix(town_candidates,prefix_map,prefix_map_rev):#{{{
    for b,e in [(x,x+3) for x in range(len(town_candidates)-2)]: # 重複有りで3つずつ切り出す
        t_slice = town_candidates[b:e]
        # prefix -> (prefix で切った残りのリスト) のmap を作る
        get_all_prefix_map(t_slice[0][0],t_slice[1][0], prefix_map)
        get_all_prefix_map(t_slice[1][0],t_slice[2][0], prefix_map)
        # 逆向きを作るためもう一度 (無駄なのでまとめる)
        tmp_map = defaultdict(list)
        get_all_prefix_map(t_slice[0][0],t_slice[1][0], tmp_map)
        get_all_prefix_map(t_slice[1][0],t_slice[2][0], tmp_map)
        for k in tmp_map.keys():
            if(not re.search("(ガ|が|の|ノ)$",k) and len(k.strip())>1):
                prefix_map_rev[t_slice[1][0]].append(k.strip())
#}}}

if __name__ == "__main__":
    # 町名の候補リスト
    town_candidates = []
    # prefix -> postfix の対応map 
    prefix_map = defaultdict(list) 
    # 町名 -> prefix の対応map
    prefix_map_rev = defaultdict(list) 
    # 確度の高い prefix のリスト 
    conf_prefix = [set(), set(), set()]
    used_prefix = {}
    extracted_townname = {}
    # 地名と場所の対応付け
    townname2area = {}
    prefixname2area = {}
    
    # CSVを処理し複数行に分かれている町域名を結合
    # 町域名に複数の町名が書いてあるものを分割
    town_list = read_town_list('KEN_ALL.CSV')
    
    # 町名以外を示す行, 番地など町名に付属する語を除去
    town_candidates = extract_townname(town_list)
     
    # 町名候補のリストから，prefix を取り出す
    extract_prefix(town_candidates,prefix_map,prefix_map_rev)
    
    # prefix の数をかぞえ，信頼できる prefix リストを作る
    # prefix がパターン1に当てはまる
    conf_prefix[0] = set([k for k,v in prefix_map.items() if(re.match(r".*(町|村|里|区|町通)$", k))])
    ## 信頼できるprefix 0 単独で出現する 
    conf_prefix[1] = set([i for i in prefix_map if ("" in prefix_map[i] or " " in prefix_map[i])])
    ## １０回以上出現する
    conf_prefix[2] = set([k for k,v in prefix_map.items() if 
        len([x for x in v if(len(x)>1 and not re.match(r"^(山|川|町|島|沢|台|の|々|が|ヶ|ケ|ノ|之|ガ丘|ツ|ッ)",x))])>=10 and 
        not re.search(r"(之|が|ヶ|ケ|ツ|ッ)$",k)]) 
   
    # 信頼できる prefix リストで町名を分割，辞書形式で出力する．
    count = 0
    for name, area in [(x, area) for i, (x, area) in enumerate(town_candidates) if i == town_candidates.index((x,area))]:
        count += 1
        prefix_found = False
        # 信頼度の順，prefix 0, 1, 2 の順，それぞれの中でも長いprefix を優先する．
        prefix_set = set(prefix_map_rev[name])
        for i, pref in [(i, prefix_set & conf_prefix[i]) for i in range(3)]:
            if(len(pref)>0):
                for p in sorted(pref,key=lambda x:-len(x)): # 長い順
                    #postfix のskip用パターンに当てはまったら使わない
                    if(not re.match(r"^(山|川|町|島|沢|台|の|々|が|ヶ|ケ|ノ|ガ丘).*",name[len(p):])): 
                        used_prefix[p] = i
                        prefixname2area[p] = area
                        if(not re.search(r"/の/",name)): # "の"を含む地名は分割しない
                            print("#{} {} {} {} {}".format(count, name, p, name[len(p):],i))
                            for sp in name[len(p):].strip().split(' '):
                                extracted_townname[sp] = i
                                townname2area[sp] = area
                            prefix_found = True
                            break
                prefix_found = True
                break
        # 信頼できる prefix が１つも無かった町名を登録
        if(not prefix_found):
            for sp in name.strip().split(' '):
                # 以下のような地名が存在したため，パターン がマッチしたものを除外する
                # 中の橋, 鷹の巣, 山の神, 神の山, 中の川, 皆の丘
                if(re.search(r"/^[中皆]の/",sp)):
                    continue 
                if(re.search(r"/の[巣神山]$/",sp)):
                    continue 
                if(re.search(r"/^.の町$/",sp)):
                    continue 
                extracted_townname[sp] = 3
                townname2area[sp] = area

# 表示
for k,v in (used_prefix.items()):
    print("prefix{}: {} {}".format(v,k,prefixname2area[k]))
for k,v in (extracted_townname.items()):
    if(len(k)>1):
        print("body{}:{} {}".format(v,k,townname2area[k]))

exit()

## 残骸#{{{
#
#def extract_place_name(before, line, after):#{{{
#    """ 入力は (空白以外の？)町名に分割済み
#    """
#    #if(not is_townname(line)):
#    #    continue
#
#    place_name = preprocess(line)
#
#    #if(place_name == last_place):
#    #    continue
#
#    #pref = get_prefix(last_place, place_name)
#    prefixes = get_prefix_all(before, last_place , after)
#
#    # prefix に町以降は含めない
#    pref = re.sub(r"町.*$","町",pref)  
#
#    lmatch = re.search(r"^(?:{basename})?{pref}([^町村里].*)$".format(basename=basename,pref=last_prefix),last_place)
#    # 前と同じ prefix で分割する場合
#    if(len(last_prefix)>1 and lmatch and lmatch.group(1) and 
#            lmatch.group(1) != "山" and lmatch.group(1) != "川" and lmatch.group(1) != "町" and 
#            lmatch.group(1) != "島" and lmatch.group(1) != "沢" ):
#        print("match_l(" + last_prefix + "):",end="",file=sys.stderr) 
#        if(basename):
#            print(basename + " ",end="",file=sys.stderr) 
#        if(last_prefix):
#            print(last_prefix + " ",end="",file=sys.stderr)
#        print(lmatch.group(1) , file=sys.stderr)
#        
#        count_pref += 1
#        for tn in re.split(r"\s+", basename + " " + last_prefix + " " + lmatch.group(1)):
#            town_name_dict[tn] = True
#    # 新しい prefix で分割する場合
#    elif(len(pref)>1):
#        match = re.search(r"^(?:{basename})?{pref}([^町村里].*)$".format(basename=basename,pref=pref),last_place)
#        count_pref += 1
#        if(match and match.group(1) and 
#            match.group(1) != "山" and match.group(1) != "川" and match.group(1) != "町" and 
#            match.group(1) != "島" and match.group(1) != "沢" ): # 普通にマッチ
#            print("match(" + pref + "):",end="",file=sys.stderr) 
#            if(basename):
#                print(basename + " ",end="",file=sys.stderr) 
#            if(pref):
#                print(pref + " ",end="",file=sys.stderr)
#            print(match.group(1) ,file=sys.stderr)
#            last_prefix = pref
#            
#            for tn in re.split(r"\s+", basename + " " + pref + " " + match.group(1)):
#                town_name_dict[tn] = True
#        elif(match and match.group(1)): # マッチしたが，山・川・沢などで切れている
#            print("match_s:" + last_place,file=sys.stderr)
#            last_prefix = ""
#            count_failed+=1
#            count_pref -=1
#            for tn in re.split(r"\s+", last_place): # last_place のみを登録
#                town_name_dict[tn] = True
#        elif(last_place == ""): # 最初の一件
#            count_pref -= 1 # 先に成功したことにして足しているので引いておく
#            # do nothing
#        elif(pref == last_place):# prefix 単体が出現している場合
#            print("match_p(" + pref + "):" + last_place,file=sys.stderr)
#            last_prefix = pref
#            count_nopref += 1
#            count_pref -= 1
#            for tn in re.split(r"\s+", last_place):
#                town_name_dict[tn] = True
#        else:
#            for tn in re.split(r"\s+", last_place):
#                town_name_dict[tn] = True
#            last_prefix = last_place
#            count_failed += 1
#            count_pref -= 1 # 先に成功したことにして足しているので引いておく
#            print("ERROR: failed to segment place name",file=sys.stderr)
#            print("basename:"+basename,file=sys.stderr)
#            print("pref:"+ pref,file=sys.stderr)
#            print("lastplace:"+last_place,file=sys.stderr)
#    else: # prefix 無し
#        print("nopref:" + last_place,file=sys.stderr)
#        count_nopref += 1
#        for tn in re.split(r"\s+", last_place):
#            town_name_dict[tn] = True
#    last_place = place_name
#
##}}}
#
#if __name__ == "__main__":
#    with open('KEN_ALL.CSV', newline='',encoding='cp932' ) as csvfile:
#        reader = csv.reader(csvfile, delimiter=',', quotechar='"')
#        last_place = ""
#        last_number = ""
#        last_prefix = ""
#        basename = ""
#        
#        for row in reader:
#            place_name = row[8]
#            place_number = row[2]
#            # 同じ郵便番号が連続している場合
#            if(last_number == place_number):
#                continue
#            
#            count_line += 1
#            last_number = place_number
#             
#            if(not is_townname(place_name)):
#                continue
#            
#            # 連続する空白をまとめる
#            place_name = re.sub(r" +"," ", place_name)
#
#            if(place_name == last_place):
#                continue
#
#            pref = get_prefix(last_place, place_name)
#            # ひとつ前を遡って出力
#
#            # prefix に町以降は含めない
#            pref = re.sub(r"町.*$","町",pref)  
#
#            lmatch = re.search(r"^(?:{basename})?{pref}([^町村里].*)$".format(basename=basename,pref=last_prefix),last_place)
#            # 前と同じ prefix で分割する場合
#            if(len(last_prefix)>1 and lmatch and lmatch.group(1) and 
#                    lmatch.group(1) != "山" and lmatch.group(1) != "川" and lmatch.group(1) != "町" and 
#                    lmatch.group(1) != "島" and lmatch.group(1) != "沢" ):
#                print("match_l(" + last_prefix + "):",end="",file=sys.stderr) 
#                if(basename):
#                    print(basename + " ",end="",file=sys.stderr) 
#                if(last_prefix):
#                    print(last_prefix + " ",end="",file=sys.stderr)
#                print(lmatch.group(1) , file=sys.stderr)
#                
#                count_pref += 1
#                for tn in re.split(r"\s+", basename + " " + last_prefix + " " + lmatch.group(1)):
#                    town_name_dict[tn] = True
#            # 新しい prefix で分割する場合
#            elif(len(pref)>1):
#                match = re.search(r"^(?:{basename})?{pref}([^町村里].*)$".format(basename=basename,pref=pref),last_place)
#                count_pref += 1
#                if(match and match.group(1) and 
#                    match.group(1) != "山" and match.group(1) != "川" and match.group(1) != "町" and 
#                    match.group(1) != "島" and match.group(1) != "沢" ): # 普通にマッチ
#                    print("match(" + pref + "):",end="",file=sys.stderr) 
#                    if(basename):
#                        print(basename + " ",end="",file=sys.stderr) 
#                    if(pref):
#                        print(pref + " ",end="",file=sys.stderr)
#                    print(match.group(1) ,file=sys.stderr)
#                    last_prefix = pref
#                    
#                    for tn in re.split(r"\s+", basename + " " + pref + " " + match.group(1)):
#                        town_name_dict[tn] = True
#                elif(match and match.group(1)): # マッチしたが，山・川・沢などで切れている
#                    print("match_s:" + last_place,file=sys.stderr)
#                    last_prefix = ""
#                    count_failed+=1
#                    count_pref -=1
#                    for tn in re.split(r"\s+", last_place): # last_place のみを登録
#                        town_name_dict[tn] = True
#                elif(last_place == ""): # 最初の一件
#                    count_pref -= 1 # 先に成功したことにして足しているので引いておく
#                    # do nothing
#                elif(pref == last_place):# prefix 単体が出現している場合
#                    print("match_p(" + pref + "):" + last_place,file=sys.stderr)
#                    last_prefix = pref
#                    count_nopref += 1
#                    count_pref -= 1
#                    for tn in re.split(r"\s+", last_place):
#                        town_name_dict[tn] = True
#                else:
#                    for tn in re.split(r"\s+", last_place):
#                        town_name_dict[tn] = True
#                    last_prefix = last_place
#                    count_failed += 1
#                    count_pref -= 1 # 先に成功したことにして足しているので引いておく
#                    print("ERROR: failed to segment place name",file=sys.stderr)
#                    print("basename:"+basename,file=sys.stderr)
#                    print("pref:"+ pref,file=sys.stderr)
#                    print("lastplace:"+last_place,file=sys.stderr)
#            else: # prefix 無し
#                print("nopref:" + last_place,file=sys.stderr)
#                count_nopref += 1
#                for tn in re.split(r"\s+", last_place):
#                    town_name_dict[tn] = True
#            last_place = place_name
#
#    for name in sorted(town_name_dict.keys(), key=lambda x: len(x)):
#        print(name)
#
#    print("line:{count_line} pref:{count_pref}, nopref:{count_nopref}, failed:{count_failed}".format(count_line=count_line,count_pref=count_pref,count_nopref=count_nopref,count_failed=count_failed))
#
#
##}}}

