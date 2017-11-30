 #! /usr/bin/env python3
 # -*- coding: utf-8 -*-     

import sys

FULL2HALF = dict((i + 0xFEE0, i) for i in range(0x21, 0x7F))
FULL2HALF[0x3000] = 0x20

def halfen(s):
    '''
    Convert full-width characters to ASCII counterpart
    '''
    return str(s).translate(FULL2HALF)

for l in sys.stdin:
	sys.stdout.write(halfen(l))
