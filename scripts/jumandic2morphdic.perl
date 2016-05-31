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

print STDERR $opt_nominalize;
print STDERR $opt_okurigana;
print STDERR $opt_debug;

# ルール
# 引っ込みを扱う条件
# 以下のルール全てで (属性1 演算子 属性2) が真であるなら追加
# TODO: ファイルから読み込む
my $hikkomi_rule = "pos\teq\t動詞
form\teq\t基本連用形
imis\t!~\t/可能動詞/
type\tne\tサ変動詞
type\tne子音動詞サ行||imis\t!~\t/同義:動詞:[^ ]*する/
imis\t!~\t/濁音化D/";

# 名詞化を扱う条件
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
        my $midasi_c = $midasi;
        $midasi_c =~ s/\\[END]//g;
        # 重複している動詞のかな表記は扱わない
        # (見出し語 会う 逢う 遭う \Eあう \Dあう \Nあう)
        if ($dictionary{$midasi_c.$yomi.$pos.$spos.$type.$rep.$imis_str} == 1){ next; }
        $dictionary{$midasi_c.$yomi.$pos.$spos.$type.$rep.$imis_str}=1;
        
        if ($type) {
            if(!$spos){$spos= "*";}

            my @ms =(&get_inflected_forms(Encode::encode('utf-8',$midasi), Encode::encode('utf-8',$type)));
            my @ys =(&get_inflected_forms(Encode::encode('utf-8',$yomi), Encode::encode('utf-8',$type)));
            my %hash; @hash{@ms}=@ys;
            for my $m_key (@ms){ # 活用形ごと
                my $mstr = Encode::decode('utf-8', $m_key->{str});
                my $ystr = Encode::decode('utf-8', $hash{$m_key}->{str});
                next unless $mstr;
                my $form = Encode::decode('utf-8', $m_key->{form});
                
                my %mrp = (midasi => $midasi, str => $mstr, yomi => $yomi, form => $form, pos => $pos, spos => $spos, imis => $imis_str, type => $type, rep => $rep);

                if( $opt_okurigana && &is_hikkomi_candidate(%mrp)){
                    # 送り仮名の処理 
                    my @replace_candidate;
                    my @segments = split(/(\p{Han}\p{Hiragana})(?!\p{Hiragana})/,$mstr); # 送り仮名が二文字以上続く場合は引っ込めない
                    #my @segments = split(/(\p{Han}\p{Hiragana})/,$mstr); # 送り仮名が何文字でも(１文字)引っ込める

                    my @imis_copy  = @imis;
                    push @imis_copy, "送り仮名引っ込み";

                    my $seg_index = 0;
                    for my $seg (@segments){
                        if($seg =~ /^\p{Han}\p{Hiragana}$/){
                            # 送り仮名の出現位置を置換えのために保存
                            push @replace_candidate, $seg_index;
                        }
                        $seg_index++;
                    }
                        
                    my @replaced = [ @segments ];
                    for my $pos (@replace_candidate){
                        my @tmp;
                        for my $sp (@replaced){
                            my @sp_2 = @$sp;
                            $sp_2[$pos] = substr($sp_2[$pos],0,1); # 一文字目のみに置き換える
                            push @tmp, \@sp_2;
                        }
                        for my $tmp_2 (@tmp){
                            push @replaced, $tmp_2;
                        }
                    }
                    for my $reps (@replaced){
                        push @hikkomi_candidates, [join("",@$reps),$pos,$spos,$form,$type,$midasi,$ystr,$rep,\@imis_copy];
                    }
                }
                # 漢字をひらがな表記している箇所の記号を除く
                $mstr =~ s/\\[END]//g;
                $midasi =~ s/\\[END]//g;
                
                &print_entry($mstr, $pos, $spos ,$form, $type, $midasi, $ystr, $rep, \@imis);
                
                # 名詞化語の出力(名詞)
                &print_nominalize_entry($mstr, $pos, $spos ,$form, $type, $midasi, $ystr, $rep, \@imis) if($opt_nominalize && &is_nominalize_candidate(%mrp));
                # 名詞化語の出力(名詞性接尾辞)
                &print_nominalized_suffix_entry($mstr, $pos, $spos ,$form, $type, $midasi, $ystr, $rep, \@imis) if($opt_nominalize && &is_nominalized_suffix_candidate(%mrp));
                # 辞書に追加
                $dictionary{$mstr.$pos.$form}=1;
            }
        } else {# 活用無し
            $midasi =~ s/\\[END]//g;
            &print_entry($midasi, $pos, $spos,'*', '*',$midasi, $yomi, $rep, \@imis);
            $dictionary{$midasi.$pos}=1;
        }
        $index++;
    }
}

# 重複をチェックして問題なければ出力
if( $opt_okurigana ){
    for my $rep (@hikkomi_candidates){
        $rep->[0] =~ s/\\[END]//g;
        $rep->[5] =~ s/\\[END]//g;

        if($dictionary{$rep->[0].$rep->[1].$rep->[3]} == 1 || # 別の見出し語の連用形と重なる
            $dictionary{$rep->[0].$rep->[1].$rep->[6].$rep->[7]} == 1|| # 同じ読みで送り仮名を引っ込めた語を出力済
            $dictionary{$rep->[0]."名詞"} == 1 || # 一致する名詞がある
            $dictionary{$rep->[0]."形容詞"."語幹"} == 1 # 対応する形容詞語幹がある　
        ){
        }else{
            my %mrp = (str => $rep->[0], pos => $rep->[1], spos => $rep->[2], form => $rep->[3], 
                       type => $rep->[4], midasi => $rep->[5],  yomi => $rep->[6], rep => $rep->[7], 
                       imis => join("",@{$rep->[8]}));

            # 名詞化語の出力(名詞)
            if($opt_nominalize && &is_nominalize_candidate(%mrp)){
                $dictionary{$rep->[0].$rep->[1].$rep->[6].$rep->[7]}=1; # 出力済みの引っ込み語を読みと代表表記をつけて登録
                &print_nominalize_entry($rep->[0], $rep->[1], $rep->[2] ,$rep->[3], $rep->[4], $rep->[5], $rep->[6], $rep->[7], $rep->[8]);
            }
        }
    }
}

# 半角空白の追加（JUMANでは辞書外で例外的に処理されている）
&print_entry(' ', '特殊', '空白', '*', '*', ' ', ' ', ' / ', ());


####################################
# Sub-routines
####################################

# 辞書項目の出力
sub print_entry {
    my ($h, $pos, $spos, $form, $form_type, $midasi, $yomi, $rep, $imis) = @_;
    my $imis_str;
    if($h eq ','){ $h = '","';}
    if($midasi eq ','){ $midasi = '","';}
    if($yomi eq ','){ $yomi = '","';}
    if( (not defined $imis) || scalar(@$imis) == 0){
        $imis_str = "NIL";
    }else{
        $imis_str = join(" ",@$imis);
    }

    print $h, ',0,0,0,', $pos,',', $spos, ',' , $form, ',', $form_type, ',' , $midasi , ',', $yomi, ',' , $rep, ',' , $imis_str,"\n"; 
}

# 名詞化した語の出力
sub print_nominalize_entry {
    my ($h, $pos, $spos, $form, $form_type, $midasi, $yomi, $rep, $imis) = @_;
    my $imis_str;
    if($h eq ','){ $h = '","';}
    if($midasi eq ','){ $midasi = '","';}
    if($yomi eq ','){ $yomi = '","';}
    if( (not defined $imis) || scalar(@$imis) == 0){
        $imis_str = "NIL";
    }else{
        $imis_str = join(" ",@$imis);
    }
    
    my @imis_copy  = @$imis;
    push @imis_copy, "連用形名詞化:形態素解析";
    $imis_str = join(" ", @imis_copy);
    my $rep_inf = &get_nominalized_rep($rep, $midasi, $yomi, $form_type);

    print $h, ',0,0,0,', "名詞",',', "普通名詞", ',' , '*', ',', '*', ',' , $h , ',', $yomi, ',' , $rep_inf , ',' , $imis_str,"\n"; 
}

# 名詞性接尾辞化した語の出力
sub print_nominalized_suffix_entry {
    my ($h, $pos, $spos, $form, $form_type, $midasi, $yomi, $rep, $imis) = @_;
    my $imis_str;
    if($h eq ','){ $h = '","';}
    if($midasi eq ','){ $midasi = '","';}
    if($yomi eq ','){ $yomi = '","';}
    if( (not defined $imis) || scalar(@$imis) == 0){
        $imis_str = "NIL";
    }else{
        $imis_str = join(" ",@$imis);
    }

    # 名詞化項の生成
    # れ,0,0,0,接尾辞,動詞性接尾辞,基本連用形,母音動詞,れる,れ,れる/れる,NIL
    my @imis_copy  = @$imis;
    push @imis_copy, "連用形名詞化:形態素解析";
    $imis_str = join(" ", @imis_copy);
    my $rep_inf = &get_nominalized_rep($rep, $midasi, $yomi, $form_type);
    print $h, ',0,0,0,', "接尾辞",',', "名詞性接尾辞", ',' , '*', ',', '*', ',' , $h , ',', $yomi, ',' , $rep_inf, ',' , $imis_str,"\n"; 
}

# 活用形一覧の取得
sub get_inflected_forms {
    my ($midasi, $type) = @_;

    my $inf = new Inflection($midasi, $type, '基本形');
    return $inf->GetAllForms();
}

# 引っ込み対象語かどうかの判定
sub is_hikkomi_candidate {
    my (%mrp) = @_;

    return match_rule($hikkomi_rule, %mrp);
}

# 名詞化対象語の判定
sub is_nominalize_candidate {
    my (%mrp) = @_;

    for my $rule (@nominalize_rules){
        return 1 if(match_rule($rule, %mrp));
    }
    return 0;
}

# 名詞性接尾辞化対象語の判定
sub is_nominalized_suffix_candidate {
    my (%mrp) = @_;

    for my $rule (@nominalized_suffix_rules){
        return 1 if(match_rule($rule,%mrp));
    }
    return 0;
}

# ルールとのマッチ判定
sub match_rule{
    my ($given_rule, %mrp) = @_;
    
    for my $or_rule (split(/\n/, $given_rule)){
        my $oval = ''; # false
        for my $rule (split(/\|\|/, $or_rule)){
            my @sp = split(/\t/,$rule);
            if($sp[1] eq "eq"){
                $oval = $oval || ($mrp{$sp[0]} eq $sp[2]);
            }elsif($sp[1] eq "ne"){
                $oval = $oval || ($mrp{$sp[0]} ne $sp[2]);
            }elsif($sp[1] eq "=~"){
                $oval = $oval || ($mrp{$sp[0]} =~ eval("qr$sp[2]"));
            }elsif($sp[1] eq "!~"){
                $oval = $oval || ($mrp{$sp[0]} !~ eval("qr$sp[2]"));
            }
        }
        if (not $oval){
            return '';
        }
    }
    return 1;
}

# 動詞の連用形が名詞化した際の代表表記を生成
sub get_nominalized_rep {
    my ($rep, $midasi, $yomi, $type) = @_;

    $rep =~ /(.*)\//;
    my $rep_midasi = $1;
    $rep =~ /\/(.*)/;
    my $rep_yomi = $1;

    if($rep eq "*"){
        return &get_nominalized_midasi($midasi, $type)."/".$yomi;
    }else{
        my $inf_rep_midasi = new Inflection($rep_midasi, $type, '基本形');
        my $inf_rep_yomi = new Inflection($rep_yomi, $type, '基本形');
        
        my $new_representation = "".$inf_rep_midasi->Transform("基本連用形").'/'.$inf_rep_yomi->Transform("基本連用形");
        return $new_representation;
    }
}

# 名詞化時の見出し語を生成
sub get_nominalized_midasi {
    my ($midasi, $type) = @_;

    my $inf_midasi = new Inflection($midasi, $type, '基本形');

    return "".$inf_midasi->Transform("基本連用形");
}
