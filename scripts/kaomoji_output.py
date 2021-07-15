#!/usr/bin/env python3

import sys


def escape(word):
    return '"' + word.replace('"', '""') + '"'

def process(input, output):
    for line in input:
        line = line.strip()
        if '"' in line or ',' in line:
            line = escape(line)        
        output.write(f"{line},0,0,0,特殊,記号,*,*,{line},{line},顔文字/顔文字,顔文字\n")

def main():    
    outfile = sys.argv[1]

    with open(outfile, 'wt', encoding='utf-8') as out:
        process(sys.stdin, out)


if __name__ == "__main__":
    main()