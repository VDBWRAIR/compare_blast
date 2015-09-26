#!/bin/bash

exec >& >(tee -a "runtests.log")

subsizes="70000 700000 7000000"
for i in $subsizes
do
		make clean
		make SUBSELECT=$i dbs
		make SUBSELECT=$i AVAILCPU=8 BLASTQUERYFILE=fasta/100.fasta tests report
done
