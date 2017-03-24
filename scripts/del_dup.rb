#!/bin/env ruby -Ku
#coding: utf-8

# 見出し，品詞，細分類が同じエントリを集める
midasi_pos_spos = Hash.new{|hash,key| hash[key]=[]}

#(副詞 ((読み いけ)(見出し語 イケ)(意味情報 "代表表記:イケ/いけ 副詞識別 自動獲得:テキスト")))
#(名詞 (普通名詞 ((読み 東方神起)(見出し語 東方神起)(意味情報 "代表表記:東方神起/東方神起 副詞識別 自動獲得:テキスト"))))
#(名詞 (普通名詞 ((読み 東方神起)(見出し語 東方神起)(意味情報 "自動獲得:テキスト"))))
#(副詞 ((読み あんは)(見出し語 アンは)(意味情報 "代表表記:アンは/あんは 副詞識別 自動獲得:テキスト")))

while line=gets do 
  line =~ /\(見出し語 ([^ \)]*)\)/
  midasi_str = $1

  line =~ /^\(([^ ]*) \(([^ (]*)[ (]/
  pos_str = $1
  spos_str = $2

  line =~ /代表表記:([^ ]*)[ "]/
  rep_str = $1

  if(midasi_str == nil or pos_str == nil)
    STDERR.puts midasi_str
    STDERR.puts line 
    next
  end
  if(pos_str == "名詞" and (spos_str == nil or spos_str== ""))
    STDERR.puts line
    next
  end

  midasi_pos_spos["midasi=#{midasi_str}, pos=#{pos_str}, spos=#{spos_str}"] << [line, rep_str]
end


midasi_pos_spos.each{|key,array|
  if (array.size() == 1)
    puts array[0][0]
  else
    puts array.sort{|x,y| -(x[0].size <=> y[0].size) }[0][0]
  end

}
