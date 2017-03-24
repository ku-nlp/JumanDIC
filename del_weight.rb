#!/bin/env ruby
#encoding: utf-8

while line=gets 
  if(line =~ /^\(/)
    puts line.gsub(/(\( *([^ \(\)]*?) ([0-9][0-9\.]*) *\))/){|source|
      #puts "#{$1}, #{$2} #{$3}"
      midasi = $2
      weight = $3
      if(midasi !~ /見出し語/ )
        # puts "#{source} => #{midasi}"
        midasi
      else
        source
      end
    }
  else
    puts line
  end
end
