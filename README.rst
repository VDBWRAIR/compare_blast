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

Configuration
=============

The Makefile is setup in a way that it should be easily custimizable to test various different cases

The easiest variables to edit are as follows:

BLAST_VER
  The version of blast executables to download and execute
BLAST_DB
  The root path to where you want all databases to be installed into
BLAST_DB_FASTA_URL
  This is the url to a protein fasta file that will be downloaded and used to create the databases. This must be a gzip'd file
SUBSELECT
  This is the number of sequences to extract from the BLAST_DB_FASTA_URL fasta file. This way you can use a specified amount of sequences for various tests. We used this to develop the Makefile as we didn't want to wait for all 70 million blast sequences to download.
  For example, setting this to 700000 will only extract the first 700000 sequences when downloading the BLAST_DB_FASTA_URL
SMALLNRDB
  Don't really need to change this, but this is the path to the blast database that will be created from the subsampled fasta download
BLASTOPTIONS
  Static options for when running blast that do not change between tests. We tried to match these options to the defaults of diamond
DIAMOND_VER
  Version of diamond to download
DIAMOND_MAKEDB_OPTIONS
  Really the only option that is of any interest is the ``-b`` option which you can read about on the diamond site
DIAMONDOPTIONS
  Same as BLASTOPTIONS, but passed to diamond

Running the tests
=================

Since the HPC cluster we are utilizing does not allow in/out connections on the compute nodes, the Makefile is setup such that you can do the operations that require internet prior to submitting the job

This should download and create all databases as well as executables required

.. code-block:: bash

   make download

Then you will want to also probably build the databases. This is seprate so that
the databases don't keep trying to be built

The SUBSELECT=700000 defines how many sequences you will use to build the databases

.. code-block:: bash

    make dbs SUBSELECT=700000
   
Then to run the actual tests you can qsub the included job.pbs(which is fairly specific to PBS) or if not on HPC Cluster you can just run

.. code-block:: bash

   make tests SUBSELECT=700000
   
If you want to generate an easy report::

    make report

This report is a very simple csv/tsv report that lists
testname,timetaken,uniqhits,memoryused

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

single_cpu_single_thread_diamond.tsv
------------------------------------

This test will get a baseline of how long diamond takes using a single thread on a single cpu

single_cpu_multi_thread_diamond.tsv
-----------------------------------

This test will show how long diamond takes to run using multiple threads on a single host. Diamond is supposed to be run using many threads on a single input file. This test is used to compare against the simiilarily named blast test.

.. _blastxlink: https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download
.. _diamond: https://github.com/bbuchfink/diamond/
.. _seqr: https://github.com/NCBI-Hackathons/seqr
