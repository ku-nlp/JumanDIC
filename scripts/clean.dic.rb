#!/home/morita/.rbenv/shims/ruby -K
#encoding: utf-8


COUNTRY_PREF = "対在反親知抗排駐滞離来訪渡"
COUNTRIES = "ソ伊英欧韓台中朝独日仏米露"
SUFFIX = "相国外年"
PREFIX = "両新後北東南西"
C2SUFFIX = "生長部家員東西南北"
C2PREFIX = "年右左"
NUMBERS= "一二三四五六七八九"

#STOP_REG = /[\p{Han}\p{Katakana}\p{Hiragana}#{NUMBERS}#{COUNTRY_PREF}#{COUNTRIES}#{SUFFIX}#{PREFIX}#{C2SUFFIX}#{C2PREFIX}]/

while line=gets do 
  line =~ /\(見出し語 ((?:\([^\)]*\))*)\)/
  midasi_str = $1
  if($1 == nil)
    puts line 
    next
  end
  midasis = midasi_str.scan(/\([^\)]*\)/)

  if (!(midasis.size > 0))
    puts line 
    next
  end
  midasis[0] =~ /\((.*) [\d\.]*\)/
  midasi = $1
  if (midasi.size > 4)
    puts line 
    next
  end

  if ( #ひらがなを含むかどうかのチェック
    (midasi =~ /^[\p{Hiragana}一二三四五六七八九]/) || 
    (midasi =~ /[\p{Hiragana}一二三四五六七八九]$/) ||  
    (midasi =~ /^[\p{Han}\p{Katakana}]$/) || # 一文字漢字, カタカナ
    (midasi =~ /^[#{COUNTRY_PREF}][#{COUNTRIES}]$/) ||  
    (midasi =~ /^.[#{COUNTRIES}]$/) || 
    (midasi =~ /^[#{COUNTRIES}].$/) || 
    (midasi =~ /^[#{PREFIX}]/) || 
    (midasi =~ /[#{SUFFIX}]$/) ||
    (midasi =~ /^[#{C2PREFIX}].$/) || 
    (midasi =~ /^.[#{C2SUFFIX}]$/)  ||
    # 英数１字＋漢字１字
    (midasi =~ /^[Ａ-Ｚ０-９]\p{Han}$/) ||
    # 漢字１字＋英数１字
    (midasi =~ /^\p{Han}[Ａ-Ｚ０-９]$/) ||
    # カタカナで３文字以下の，一覧or 人名を捨てる
    (midasi =~ /^\p{Katakana}{1,3}$/ && (line =~ /Wikipedia(?:ページ内)?一覧/|| line =~ /Wikipedia人名/) ) 
     ) 
    #puts "discard " + line
  else
    puts line
  end

#  midasis.each{|midkakko|
#    if(midkakko =~ /\((.*) [\d\.]*\)/) #当てはまらないものはアルファベット
#      mid = $1
#      if mid =~ // 
#    end
#  }
end





# ファミリーレストラン
# オリオンビール

