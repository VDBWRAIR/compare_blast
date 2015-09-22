#!/usr/bin/env python
#
# Simply subselect numentries amount of sequences from a given
# fasta file and print them to stdout

import sys

try:
    infile = sys.argv[1]
    numentries = int(sys.argv[2])
except:
    print "Usage: {0} infile numentries".format(__file__)
    sys.exit(1)

seqcount = 0
with open(infile) as fh:
    for line in fh:
        if line[0] == '>':
            seqcount += 1
        if seqcount > numentries:
            break
        sys.stdout.write(line)
