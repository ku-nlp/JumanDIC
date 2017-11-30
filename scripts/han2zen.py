#! /usr/bin/env python3
 # -*- coding: utf-8 -*-

import sys


HALF2FULL = dict((i, i + 0xFEE0) for i in range(0x21, 0x7F))
HALF2FULL[0x20] = 0x3000

def fullen(s):
	'''
	Convert all ASCII characters to the full-width counterpart.
	'''
	return str(s).translate(HALF2FULL)

for l in sys.stdin:
	sys.stdout.write(fullen(l))