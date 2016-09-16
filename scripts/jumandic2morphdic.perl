#!/usr/bin/env perl

use lib "./lib/";
use Juman;
use Carp;
use Grammar qw/ $FORM $TYPE $HINSI/;
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

# -e 用の置換マップ
my %FILTER = (
 "あ" => "え", "い" => "え", "う" => "え", "え" => "え", "お" => "え",
 "ぁ" => "ぇ", "ぃ" => "ぇ", "ぅ" => "ぇ", "ぇ" => "ぇ", "ぉ" => "ぇ",
 "か" => "け", "き" => "け", "く" => "け", "け" => "け", "こ" => "け",
 "が" => "げ", "ぎ" => "げ", "ぐ" => "げ", "げ" => "げ", "ご" => "げ",
 "さ" => "せ", "し" => "せ", "す" => "せ", "せ" => "せ", "そ" => "せ",
 "た" => "て", "ち" => "て", "つ" => "て", "っ" => "て", "て" => "て", "と" => "て",
 "だ" => "で", "ぢ" => "で", "づ" => "で", "で" => "で", "ど" => "で",
 "な" => "ね", "に" => "ね", "ぬ" => "ね", "ね" => "ね", "の" => "ね",
 "は" => "へ", "ひ" => "へ", "ふ" => "へ", "へ" => "へ", "ほ" => "へ",
 "ば" => "べ", "び" => "べ", "ぶ" => "べ", "べ" => "べ", "ぼ" => "べ",
 "ぱ" => "ぺ", "ぴ" => "ぺ", "ぷ" => "ぺ", "ぺ" => "ぺ", "ぽ" => "ぺ",
 "ま" => "め", "み" => "め", "む" => "め", "め" => "め", "も" => "め",
 "や" => "え", "ゆ" => "え", "よ" => "え", "ゃ" => "ぇ", "ゅ" => "ぇ", "ょ" => "ぇ",
 "ら" => "れ", "り" => "れ", "る" => "れ", "れ" => "れ", "ろ" => "れ",
 "わ" => "え", "を" => "え", "ん" => "え"
);

my %daku2sei = ("が" => "か", "ガ" => "カ", "ぎ" => "き", "ギ" => "キ", "ぐ" => "く",
	     "グ" => "ク", "げ" => "け", "ゲ" => "ケ", "ご" => "こ", "ゴ" => "コ",
	     "ざ" => "さ", "ザ" => "サ", "じ" => "し", "ジ" => "シ", "ず" => "す",
	     "ズ" => "ス", "ぜ" => "せ", "ゼ" => "セ", "ぞ" => "そ", "ゾ" => "ソ",
	     "だ" => "た", "ダ" => "タ", "ぢ" => "ち", "ヂ" => "チ", "づ" => "つ",
	     "ヅ" => "ツ", "で" => "て", "デ" => "テ", "ど" => "と", "ド" => "ト",
	     "ば" => "は", "バ" => "ハ", "び" => "ひ", "ビ" => "ヒ", "ぶ" => "ふ",
	     "ブ" => "フ", "べ" => "へ", "ベ" => "ヘ", "ぼ" => "ほ", "ボ" => "ホ");
my %sei2daku = reverse(%daku2sei);

# TODO:見出しが一語の時

# utils for Katuyou
sub _zerop {
    ( $_[0] =~ /\D/ )? $_[0] eq '*' : $_[0] == 0;
}

sub _indexp {
    ( $_[0] !~ /\D/ and $_[0] >= 1 );
}

# 活用形のIDを取得
sub get_form_id {
    my( $type, $x ) = @_;

    $type = Encode::encode('utf-8',$type);
    $x = Encode::encode('utf-8',$x);
    
    if( $type eq '*' ){
        if( &_zerop($x) ){
            return 0;
        }
    } elsif( exists $FORM->{$type} ){
        if( exists $FORM->{$type}->[0]->{$x} ){
            return $FORM->{$type}->[0]->{$x};
        } elsif( &_indexp($x) and defined $FORM->{$type}->[$x] ){
            return $x;
        }
    }
    undef;
}

sub get_type_id {
    my( $x ) = @_;

    if (utf8::is_utf8($x)) { # encode if the input has utf8_flag
	    $x = Encode::encode('utf-8', $x);
    }

    if( &_zerop($x) ){
        0;
    } elsif( exists $TYPE->[0]->{$x} ){
        $TYPE->[0]->{$x};
    } elsif( &_indexp($x) and defined $TYPE->[$x] ){
        $x;
    } else {
        # carp "Unknown katuyou id ($x)" if $WARNING;
        undef;
    }
}

# 語尾を変化させる内部関数
sub _change_gobi {
    my( $str, $cut, $add ) = @_;

    unless( $cut eq '*' ){
        # エ基本形からほかの活用形へは変更できない．
        if($cut =~ /^-e/){
            return $str;
        }
        $str =~ s/$cut\Z//;
    }

    unless( $add eq '*' ){
        # -e の処理
        if( $add =~ /^-e(.*)$/ ){
            my $add_tail = $1;
            if( $str =~ /^(.*)(.)$/ ){

                my $head = $1;
                my $tail = $2;
                if( exists( $FILTER{$tail} )){
                    $str = $head.$FILTER{$tail};
                }
            }
            $str .= $add_tail;
        }else{
            $str .= $add;
        }
    }
    $str;
}

sub change_katuyou {
    my( $midasi, $form, $from_form, $type ) = @_;
    
    my $from_form_id = &get_form_id( $type, $from_form );
    my $id = &get_form_id( $type, $form );

    my $encoded_type = Encode::encode('utf-8',$type);
    if( defined $id and $id > 0 and defined $from_form_id and $from_form_id > 0){
        # 変更先活用形が存在する場合
        my @oldgobi = @{ $FORM->{$encoded_type}->[$from_form_id] }; 
        my @newgobi = @{ $FORM->{$encoded_type}->[$id] };

        # カ変動詞来の場合の処理
        if( $type eq 'カ変動詞来'){
            if( $midasi eq Encode::decode('utf-8',$oldgobi[1])){
                return &_change_gobi($midasi, Encode::decode('utf-8',$oldgobi[1]), Encode::decode('utf-8',$newgobi[1]) );
            }else{
                return &_change_gobi($midasi, Encode::decode('utf-8',$oldgobi[2]), Encode::decode('utf-8',$newgobi[2]) );
            }
        }else{
            return &_change_gobi( $midasi, Encode::decode('utf-8',$oldgobi[1]), Encode::decode('utf-8',$newgobi[1]) );
        }
    } else {
        # 変更先活用形が存在しない場合
        undef;
    }
}

#print STDERR &change_katuyou("ある","基本連用形","基本形","子音動詞ラ行")."\n";
#print STDERR &change_katuyou("有る","基本連用形","基本形","子音動詞ラ行")."\n";
#print STDERR &change_katuyou("なし","基本連用形","文語基本形","イ形容詞アウオ段")."\n";
#for my $i (&get_all_forms("ある","子音動詞ラ行")){
#    print STDERR "#".Encode::decode('utf-8',$i->{str})." ".Encode::decode('utf-8',$i->{form})."\n";
#}
# exit 0;


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
# TODO: 形容詞は辞書に追加して，自動処理では扱わない．
my @nominalize_rules = (
"pos\teq\t動詞
str\tne\tする
imis\t!~\t/可能動詞/
type\tne\tサ変動詞
type\tne子音動詞サ行||imis\t!~\t/同義:動詞:[^ ]*する/
form\teq\t基本連用形");
#,
#"pos\teq\t形容詞
#str\teq\t多く
#form\teq\t基本連用形"

my @nominalized_suffix_rules = (
"pos\teq\t接尾辞
spos\teq\t動詞性接尾辞
form\teq\t基本連用形");

#TODO: 辞書の優先順位を受け取る

my %dictionary; # 重複チェック用
my @hikkomi_candidates;
my @nominalize_candidates;

my %dict_from; # 辞書間の重複チェック用

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


        # 辞書間で重複した単語を削除する
        if($imis_str =~ /自動獲得:([^ ]*)/ ){
            my $dict_name = $1;
            if (exists($dict_from{$midasi_c.$yomi.$pos.$spos.$type.$rep}) && 
                $dict_from{$midasi_c.$yomi.$pos.$spos.$type.$rep} ne $dict_name){ next; }
            $dict_from{$midasi_c.$yomi.$pos.$spos.$type.$rep}=$dict_name;
        }elsif($imis_str =~ /(自動生成)/){
            my $dict_name = $1;
            my $hiragana_yomi = $yomi;
            $hiragana_yomi =~ tr/ァ-ン/ぁ-ん/; # カタカナ->ひらがな
            if (exists($dict_from{$midasi_c.$hiragana_yomi.$pos.$spos.$type.$midasi_c."/".$hiragana_yomi}) ){next;}
            $dict_from{$midasi_c.$hiragana_yomi.$pos.$spos.$type.$midasi_c."/".$yomi}=$dict_name;
        }else{
            $dict_from{$midasi_c.$yomi.$pos.$spos.$type.$rep}="基本語彙";
        }
        
        if ($type) {
            if(!$spos){$spos= "*";}
            
            my @ms =(&get_inflected_forms($midasi, $type));
            my @ys =(&get_inflected_forms($yomi, $type));
            my %hash; @hash{@ms}=@ys;
            for my $m_key (@ms){ # 活用形ごと
                my $mstr = Encode::decode('utf-8', $m_key->{str});
                my $ystr = Encode::decode('utf-8', $hash{$m_key}->{str});
                next unless $mstr;
                my $form = Encode::decode('utf-8', $m_key->{form});
                
                my %mrp = (midasi => $midasi, str => $mstr, yomi => $yomi, form => $form, pos => $pos, spos => $spos, imis => $imis_str, type => $type, rep => $rep);

                # 形容詞語幹は名詞化時のチェック対象
                if($pos eq "形容詞" and $form eq "語幹"){
                    $dictionary{$midasi."形容詞語幹"}=1;
                }

                if( $opt_okurigana && &is_hikkomi_candidate(%mrp)){
                    # 送り仮名の処理 
                    my @replace_candidate;
                    # 送り仮名が二文字以上続く場合は引っ込めない
                    my @segments = split(/(\p{Han}\p{Hiragana})(?!\p{Hiragana})/,$mstr); 
                    # 送り仮名が何文字でも(１文字)引っ込める
                    #my @segments = split(/(\p{Han}\p{Hiragana})/,$mstr); 

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

                my @imis_copy  = @imis;
                push @nominalize_candidates, [$mstr, $pos, $spos, $form, $type, $midasi,$ystr,$rep,\@imis_copy] if(&is_nominalize_candidate(%mrp));
                
                # 名詞化語の出力(名詞性接尾辞)
                &print_nominalized_suffix_entry($mstr, $pos, $spos ,$form, $type, $midasi, $ystr, $rep, \@imis) if($opt_nominalize && &is_nominalized_suffix_candidate(%mrp));
            }
        } else {# 活用無し
            $midasi =~ s/\\[END]//g;
            &print_entry($midasi, $pos, $spos,'*', '*',$midasi, $yomi, $rep, \@imis);
            $dictionary{$midasi.$pos}=1;
            $dictionary{$midasi.$pos.$rep}=1;
        }
        $index++;
    }
}

print STDERR "output nominalize\n";
print STDERR "line break\n";
# 重複をチェックして問題なければ出力
if( $opt_nominalize ){
    print STDERR "size: ".scalar(@nominalize_candidates).".\n";
    my $n_index=0;
    for my $rep (@nominalize_candidates){
        print STDERR "\r".$n_index;
        if(not is_duplicated($rep, \%dictionary)){
            # 名詞化語の出力(名詞) 
            &print_nominalize_entry($rep->[0], $rep->[1], $rep->[2] ,$rep->[3], $rep->[4], $rep->[5], $rep->[6], $rep->[7], $rep->[8]);
            # 名詞化したら，名詞として記録しておく
            my $rep_inf = &get_nominalized_rep($rep->[7], $rep->[5], $rep->[6], $rep->[4], '');
            $dictionary{$rep->[0]."名詞".$rep_inf} = 1;
        }
        $n_index += 1;
    }
}else{
    print STDERR "skip";
}

print STDERR "output hikkomi";
# 重複をチェックして問題なければ出力
if( $opt_okurigana ){
    for my $rep (@hikkomi_candidates){
        $rep->[0] =~ s/\\[END]//g;
        $rep->[5] =~ s/\\[END]//g;

        my $rep_inf = &get_nominalized_rep($rep->[7], $rep->[5], $rep->[6], $rep->[4], '');

        if($dictionary{$rep->[0].$rep->[1].$rep->[3]} == 1 || # 別の見出し語の連用形と重なる
            $dictionary{$rep->[0].$rep->[1].$rep->[6].$rep->[7]} == 1|| # 同じ読みで送り仮名を引っ込めた語を出力済
            $dictionary{$rep->[0]."名詞"} == 1 || # 一致する名詞がある
            $dictionary{$rep->[0]."名詞".$rep_inf} == 1 || # 一致する名詞がある
            $dictionary{$rep->[0]."形容詞語幹"} == 1 # 対応する形容詞語幹がある　
        ){
        }else{
            my %mrp = (str => $rep->[0], pos => $rep->[1], spos => $rep->[2], form => $rep->[3], 
                       type => $rep->[4], midasi => $rep->[5],  yomi => $rep->[6], rep => $rep->[7], 
                       imis => join("",@{$rep->[8]}));

            # 名詞化語の出力(名詞)
            if($opt_nominalize && &is_nominalize_candidate(%mrp)){
                # 出力済みの引っ込み語を読みと代表表記をつけて登録
                $dictionary{$rep->[0].$rep->[1].$rep->[6]..$rep->[7]}=1; 
                # 名詞化済みであることを記録
                $dictionary{$rep->[0]."名詞".$rep_inf}=1; 
                &print_nominalize_entry($rep->[0], $rep->[1], $rep->[2] ,$rep->[3], $rep->[4], $rep->[5], $rep->[6], $rep->[7], $rep->[8]);
            }
        }
    }
}

print STDERR "output white space";

# 半角空白の追加（JUMANでは辞書外で例外的に処理されている）
&print_entry(' ', '特殊', '空白', '*', '*', ' ', ' ', ' / ', ());


####################################
# Sub-routines
####################################

# 重複チェック
sub is_duplicated {
    my ($rep, $dictionary) = @_;
    # [join("",@$reps),$pos,$spos,$form,$type,$midasi,$ystr,$rep,\@imis_copy]
    $rep->[0] =~ s/\\[END]//g;
    $rep->[5] =~ s/\\[END]//g;
    
    my $rep_inf = &get_nominalized_rep($rep->[7], $rep->[5], $rep->[6], $rep->[4], '');

    if($$dictionary{$rep->[0].$rep->[1].$rep->[3]} == 1 || # 別の見出し語の連用形と重なる(引っ込み用)
       $$dictionary{$rep->[0].$rep->[1].$rep->[6].$rep->[7]} == 1|| # 同じ読みで送り仮名を引っ込めた語を出力済
       $$dictionary{$rep->[0]."名詞".$rep_inf} == 1 || # 一致する名詞がある
       $$dictionary{$rep->[0]."名詞"} == 1 || # 一致する名詞がある
       $$dictionary{$rep->[0]."形容詞語幹"} == 1 # 対応する形容詞語幹がある　
    ){
        return 1;
    }else{ # ok
        return 0;
    }
}

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
    my $rep_inf = &get_nominalized_rep($rep, $midasi, $yomi, $form_type, 'v');

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
    my $rep_inf = &get_nominalized_rep($rep, $midasi, $yomi, $form_type,"");
    print $h, ',0,0,0,', "接尾辞",',', "名詞性名詞接尾辞", ',' , '*', ',', '*', ',' , $h , ',', $yomi, ',' , $rep_inf, ',' , $imis_str,"\n"; 
}

# 活用形一覧の取得
sub get_inflected_forms {
    my ($midasi, $type) = @_;

    # my $inf = new Inflection($midasi, $type, '基本形');
    return get_all_forms($midasi, $type);
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
    my ($rep, $midasi, $yomi, $type, $suffix) = @_;

    $rep =~ /(.*)\//;
    my $rep_midasi = $1;
    $rep =~ /\/(.*)/;
    my $rep_yomi = $1;

    if($rep eq "*"){
        return &get_nominalized_midasi($midasi, $type)."/".$yomi;
    }else{
        # my $inf_rep_midasi = new Inflection($rep_midasi, $type, '基本形');
        my $inf_rep_midasi = "".&change_katuyou($rep_midasi,"基本連用形","基本形",$type);
        #my $inf_rep_yomi = new Inflection($rep_yomi, $type, '基本形');
        my $inf_rep_yomi = "".&change_katuyou($rep_yomi,"基本連用形","基本形",$type);
        
        #my $new_representation = "".$inf_rep_midasi->Transform("基本連用形").'/'.$inf_rep_yomi->Transform("基本連用形").$suffix;
        my $new_representation = "".$inf_rep_midasi.'/'.$inf_rep_yomi.$suffix;
        return $new_representation;
    }
}

# 名詞化時の見出し語を生成
sub get_nominalized_midasi {
    my ($midasi, $type) = @_;

    return &change_katuyou($midasi,"基本連用形","基本形",$type);
}

sub get_all_forms {
    my ($midasi, $type) = @_;

    # output
    my @forms;
    my $type_id = get_type_id($type);

    my @form_list = @{ $TYPE->[$type_id] };
    shift(@form_list);

    for my $form (@form_list) {
        my $form_decoded = Encode::decode('utf-8',$form);
        push(@forms, {str => Encode::encode('utf-8', &change_katuyou($midasi,$form_decoded,"基本形",$type)), form => $form});
    }

    return @forms;
}



