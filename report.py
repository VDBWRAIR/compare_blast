#!/usr/bin/env python
from __future__ import print_function

import sys
import csv
import re
from os.path import *

tsvfiles = sys.argv[1:]

def count_uniq_blast_hits(tsvfile):
	u_hits = set()
	for row in csv.reader(open(tsvfile)):
		u_hits.add(row[0])
	return len(u_hits)

def parse_time_output_file(path):
	time_pat = '(?P<user>\d+\.\d+)user (?P<system>\d+\.\d+)system (?P<elapsed>\d+:\d+\.\d+)elapsed (?P<CPU>\d+)%CPU \((?P<avgtext>\d+)avgtext\+(?P<avgdata>\d+)avgdata (?P<maxresident>\d+)maxresident\)k'
	contents = None
	with open(path) as fh:
		contents = fh.readline().strip()
	return re.search(time_pat, contents).groupdict()

def report(path):
	'''
	build simple csv report for tsv and tsv.times.txt files
	testname,elapsedtime,hits,memused
	'''
	uhits = count_uniq_blast_hits(path)
	time = parse_time_output_file(path+'.times.txt')
	testname = splitext(basename(path))[0]
	out = [testname,time['elapsed'],uhits,time['maxresident']]
	return ' '.join(map(str,out))

if __name__ == '__main__':
	for f in tsvfiles:
		print(report(f))
