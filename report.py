#!/usr/bin/env python
from __future__ import print_function

import sys
import csv
import re
from os.path import *

tsvfiles = sys.argv[1:]

def cpu_info():
    '''
    Just get cpuspeed and model from /proc/cpuinfo
    '''
    info = {
        'cpumodel': None,
        'cpuspeed': None
    }
    with open('/proc/cpuinfo') as fh:
        for line in fh:
            line = [x.strip() for x in line.split(':')]
            if line[0] == 'model name':
                info['cpumodel'] = line[1]
                info['cpuspeed'] = re.search('@ (\d+\.\d+[MG]Hz)', line[1]).group(1)
                break
    return info

def memtotal():
    ''' pull out just meminfo from /proc/meminfo '''
    with open('/proc/meminfo') as fh:
        for line in fh:
            line = [x.strip() for x in line.split(':')]
            if line[0] == 'MemTotal':
                return line[1]

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

def filepathinfo(path):
    '''
    get usedcpus, dbsize and testname from file path

    >>> filepathinfo('sometestname.usedcpus.dbsize.tsv')
    ['sometestname', 'usedcpus', 'dbsize']
    '''
    p = '(\S+)\.(\w+)\.(\w+)\.tsv'
    return list(re.match(p, basename(path)).groups())

def report(path):
    '''
    build simple csv report for tsv and tsv.times.txt files
    testname,elapsedtime,hits,memused,availcpus,cpumodel,cpuspeed,totalmem
    '''
    uhits = count_uniq_blast_hits(path)
    time = parse_time_output_file(path+'.times.txt')
    testname,usedcpus,dbsize = filepathinfo(path) 
    cpuinfo = cpu_info()
    cpumodel = cpuinfo['cpumodel']
    cpuspeed = cpuinfo['cpuspeed']
    totalmem = memtotal()
    out = [
        testname, dbsize, time['elapsed'], uhits,
        time['maxresident'],usedcpus, cpumodel,
        cpuspeed, totalmem
    ]
    return '"' + '","'.join(map(str,out)) + '"'

if __name__ == '__main__':
    for f in tsvfiles:
        print(report(f))
