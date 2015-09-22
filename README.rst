Blastx Comparison
=================

We are looking to compare the speedup that is achieved by spreading blastx and similar tools across multiple CPU cores as well as
across multiple multiple nodes in a cluster configuration.

#. First a baseline is created using a single node in a cluster.
#. Then the blast task is split across multiple hosts to compare against the baseline

   #. Each host will first run a single process with one of the split up sequence files
   #. After that, for blastx only, each host will split up its sequence file into NCPU pieces and start a seperate
      process for each to compare processes vs. threads 

Executables to compare
======================

* `NCBI blastx+ <blastxlink_>`
* diamond
* seqr

Process
=======

A simple fasta file containing 100 contigs is used for all tests. This file is 
broken into 10 smaller fasta files each with 10 sequences each. Then the first
of those 10 is broken into 10 more fasta files with 1 sequence each.

These files are used for all of the tests and are named

* 100.fasta
* 10.fasta.X
* 1.fasta.X

single_cpu_single_thread_blastx.tsv
-----------------------------------

This test gives a baseline of how long the query file takes to run using only 1 thread on 1 CPU

single_cpu_multi_thread_blastx.tsv
----------------------------------

This test gives a baseline of how long the query file takes to run using multiple threads

multi_cpu_multi_thread_blastx.tsv
---------------------------------

This test compares to the single_cpu_multi_thread_blastx.tsv test except a separate blastx process is spawned
for each sequence instead. This is achieved by utilizing the split up blastx files and having xargs spawn the 
separate processes for each file.

.. _blastxlink: https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download
.. _diamond: https://github.com/bbuchfink/diamond/
.. _seqr: https://github.com/NCBI-Hackathons/seqr
