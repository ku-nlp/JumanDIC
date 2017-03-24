#!/usr/bin/env perl

use JumanSexp;
use Inflection;
use utf8;
use Encode;
use Getopt::Long;
binmode STDIN, ':encoding(utf-8)';
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

use strict;
my $opt_nominalize = 0;
my $opt_okurigana = 0;
my $opt_debug = 0;

GetOptions('nominalize' => \$opt_nominalize, 'okurigana' => \$opt_okurigana, 'debug+' => \$opt_debug);

# ルール
# TODO: ファイルから読み込む
my $hikkomi_rule = "pos\teq\t動詞
form\teq\t基本連用形
imis\t!~\t/可能動詞/
type\tne\tサ変動詞
type\tne子音動詞サ行||imis\t!~\t/同義:動詞:[^ ]*する/
imis\t!~\t/濁音化D/";

my @nominalize_rules = (
"pos\teq\t動詞
str\tne\tする
imis\t!~\t/可能動詞/
type\tne\tサ変動詞
type\tne子音動詞サ行||imis\t!~\t/同義:動詞:[^ ]*する/
form\teq\t基本連用形",
"pos\teq\t形容詞
str\teq\t多く
form\teq\t基本連用形");

my @nominalized_suffix_rules = (
"pos\teq\t接尾辞
spos\teq\t動詞性動詞接尾辞
form\teq\t基本連用形");


my %dictionary; # 重複チェック用
my @hikkomi_candidates;

my $number = 0;
while (<STDIN>) {
    print STDERR "\r".$number;
    $number = $number +1;
    if($_ =~ /^\s*;/){ next;}
    if($_ =~ /^\s*$/){ next;}
    $_ =~ s/\s*$//; # 末尾の空白削除

    # (名詞 (副詞的名詞 ((読み とこ)(見出し語 とこ)(意味情報 "代表表記:とこ/とこ"))))
    my $s = new JumanSexp($_);
    my $pos = $s->{data}[0]{element};

    if($pos eq "連語"){next;} # 連語は飛ばす
    # 連語の場合は分解して保存し，後で重複のないものだけを追加

    my $spos = $s->{data}[1]{element};
    my $yomi = ($s->get_elem('読み'))[0];
    my $type = ($s->get_elem('活用型'))[0];
    my $imis_str = join(" ", ($s->get_elem('意味情報'))); 
    my @imis = $s->get_elem('意味情報');
    my $rep = "*";
    $imis_str =~ s/^"//; #最初と最後のクォーテーションを除く
    $imis_str =~ s/"$//;
    if($imis_str =~ s/代表表記:([^ "]*) ?//){
        $rep = $1;
    }
        
    if($imis_str =~ /,/){ #フォーマットが崩れるためエラーを出力して終了
        print STDERR "\n".$number."\n";
        print STDERR "err: 意味情報が','を含む.";
        exit(1);
    }

    my $imis_index = 0;
    my @del_imis_indexs;
    for my $imi (@imis){
        if ($imi =~ /代表表記:([^ "]*) ?/){
            $rep = $1;
            unshift @del_imis_indexs, $imis_index; # 配列の要素を削除する
        }
        $imi =~ s/^"//;
        $imi =~ s/"$//;
        $imis_index++;
    }
    for my $ind (@del_imis_indexs){ #index に影響を与えないように後から削除
        splice @imis, $ind, 1;
    }
         
    my $index = 0;
    for my $midasi ($s->get_elem('見出し語')) {# 連語から来たものは，同じ表層で同じ品詞のものがない場合のみ使う
        my $score = "1.0";
        my @val = $s->GetElemFromS_with_parent($midasi,'見出し語');
        if(length(@val) > 0 and $val[0] ne ''){ 
            $score = $val[0]; 
        }
        
        if($midasi eq ','){$midasi ='","';};
        if($yomi eq ','){$yomi ='","';};
        if(!$spos){$spos= "*";}
        if(!$type){$type= "*";}
        if(!$imis_str){$imis_str= "NIL";}
        $midasi =~ s/\\[END]//g;
        print $midasi, ',', $score , ',', $yomi, ',', $pos, ',', $spos, ',', $type, ',' , $rep, ',' , $imis_str,"\n"; 
        $index++;
    }
}

