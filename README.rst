Blastx Comparison
=================

We are looking to compare the speedup that is achieved by spreading blastx and similar tools across multiple CPU cores as well as
across multiple multiple nodes in a cluster configuration.

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

.. _blastxlink: https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download
.. _diamond: https://github.com/bbuchfink/diamond/
.. _seqr: https://github.com/NCBI-Hackathons/seqr
