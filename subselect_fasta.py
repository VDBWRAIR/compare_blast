#!/usr/bin/env python
#
# Simply subselect numentries amount of sequences from a given
# fasta file and print them to stdout

import sys

try:
    numentries = int(sys.argv[1])
except:
    print "Usage: {0} numentries".format(__file__)
    sys.exit(1)

seqcount = 0
for line in sys.stdin:
    if line[0] == '>':
        seqcount += 1
    if seqcount > numentries:
        break
    sys.stdout.write(line)
