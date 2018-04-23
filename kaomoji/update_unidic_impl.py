import sys, csv

def process(infile, outfile):
    csvrdr = csv.reader(infile, delimiter=',', quotechar='"')

    for row in csvrdr:
        if (row[4] == "補助記号" and row[5] == "ＡＡ" and row[6] == "顔文字"):
            outfile.write(row[0])
            outfile.write('\n')

def main():
    with open(sys.argv[1], 'rt', encoding='utf-8') as infile:
        with open(sys.argv[2], 'wt', encoding='utf-8') as outfile:
            process(infile, outfile)

if __name__ == '__main__':
    main()