#/usr/bin/env python3

import os, sys
import re

class Emoji(object):
    """docstring for Emoji"""
    def __init__(self, seq, full, name, group, subgroup):
        self.seq = seq
        self.full = full
        self.name = name
        self.group = group
        self.subgroup = subgroup
        self.repr = ""

    def base(self):
        try:
            idx = self.name.index(': ')
            return self.name[0:idx]
        except:
            return self.name

    def print_repr(self, outfile):
        v = "(特殊 (記号 ((読み {0})(見出し語 {0})(意味情報 \"代表表記:{4}/* 絵文字:{1} 絵文字種類:{2}:{3}\"))))\n".format(
            self.seq, normalize(self.name), normalize(self.group),
            normalize(self.subgroup), self.repr)
        outfile.write(v)


normregex = re.compile('[-: \'"“”!,]+')


def normalize(data):
    data = normregex.sub('_', data)
    return data.upper()

lineregex = re.compile(r'^([^;]+?) +; ((?:non-)?fully-qualified) +# [^ ]+ (.*)$')

def parse(fname):
    curgroup = "none"
    cursubgroup = "none"
    result = []

    with open(fname, encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line.startswith('# group:'):
                curgroup = line[len('# group:'):].strip()
                continue
            elif line.startswith('# subgroup:'):
                cursubgroup = line[len('# subgroup:'):].strip()
                continue
            m = lineregex.match(line)
            if m is not None:
                seq = m.group(1).split(' ')
                seq = "".join(chr(int(c, base=16)) for c in seq)
                isfull = (m.group(2) == 'fully-qualified')
                name = m.group(3)
                result.append(Emoji(seq, isfull, name, curgroup, cursubgroup))

    return result

def printall(emoji, outfile):
    with open(outfile, mode='wt', encoding='utf-8') as f:
        for e in emoji:
            e.print_repr(f)

def compute_reprs(emoji):
    res = {}
    for e in emoji:
        if e.full:
            res[e.name] = e.seq
    return res

def main():
    infile = sys.argv[1]
    outfile = sys.argv[2]

    emoji = parse(infile)
    print("total", len(emoji), "emoji")
    reprs = compute_reprs(emoji)
    for e in emoji:
        obj = reprs.get(e.base(), None)
        if obj is None:
            e.repr = e.seq
        else:
            e.repr = obj
        #print(e.seq, e.repr, e.full, e.name)
    printall(emoji, outfile)

if __name__ == '__main__':
    main()