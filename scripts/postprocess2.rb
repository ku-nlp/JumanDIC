#!/home/morita/.rbenv/shims/ruby -Ku
#encoding: utf-8
# ４文字以上の漢語と，漢語カタカナ混じりの語で，JUMANで分割した時に未定義語を含まないエントリを除外する

require "/home/morita/Hitachi/script/lib/jumanknp_pipe.rb"
#JK = JumanKnpParser.new("-r ~/.jumanrc.clean_wiki9.3")
JK = JumanKnpParser.new("-r ~/.jumanrc.lebyr_base")

while(line= gets)
  if( line =~ /^;/ )
    puts line
    next
  end

  if(line =~ /\(見出し語 \(([^\)]*) 1\.1\)/)
    midashi = $1

    # 脂質グリケーション
    #if( midashi =~ /\p{Han}\p{Han}\p{Han}\p{Han}/ || #漢字四文字以上
    if( midashi =~ /\p{Han}\p{Han}\p{Han}/ || #漢字3文字以上 # 2015/09/03
        (midashi =~ /\p{Han}/ && midashi =~ /\p{Katakana}/) # 漢語カタカナ混じり
    )
      result = JK.juman_parse(midashi)
      have_unk = false
      result.each{|juman_line|
        next if(juman_line =~ /^@/)

        if (!(juman_line.split(/\s/)[0] =~ /^[\p{Katakana}ー]*$/) && juman_line =~ /未定義語/)
          #puts juman_line
          have_unk = true 
        end
      }
      puts line if have_unk
    else
      #puts ";nomatch"
      puts line
    end
  end
end
