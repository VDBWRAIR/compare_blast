# Makefile to handle comparing different ways to parallelize blast type
# applications.
# Because I am newish to Makefiles here are some helpful things:
#   http://www.chemie.fu-berlin.de/chemnet/use/info/make/make_15.html
#   $@ stands for the target(left side of :)
#   $< first dependency(right side of :)
#   $? all dependencies newer than target

TSVOUTPUT = $(BLASTOUTPUT) $(DIAMONDOUTPUT) $(SEQROUTPUT)
# These are pretty much static args and shouldn't really be messed with
## Blast & Blast DB
BLAST_VER = ncbi-blast-2.2.31+
BLAST_TGZ = $(BLAST_VER)-x64-linux.tar.gz
BLAST_URL = ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/$(BLAST_TGZ)
BLAST_DB = db
BLAST_DB_FASTA = $(BLAST_DB)/nr.fasta
BLAST_DB_FASTA_GZ = nr.gz
BLAST_DB_FASTA_URL = ftp://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/$(BLAST_DB_FASTA_GZ)
BLASTX_PATH = $(BLAST_VER)/bin/blastx
BLASTDBUPDATECMD = $(BLAST_VER)/bin/update_blastdb.pl
BLASTMAKEDBCMD = $(BLAST_VER)/bin/makeblastdb
BLASTDBCMD = $(BLAST_VER)/bin/blastdbcmd
### Subselect this many entries from full nr database
SUBSELECT = 700000
SMALLNRDB = $(BLAST_DB)/smallnr
SMALLNRDBFILES = $(SMALLNRDB).pin $(SMALLNRDB).phr $(SMALLNRDB).psq
SMALLFASTA = $(BLAST_DB)/smallnr.fasta
BLASTOPTIONS = -db $(SMALLNRDB) -task blastx -outfmt 6 -max_target_seqs 10 -evalue 0.001 -gapopen 11 -gapextend 1
## Diamond and Diamond DB
DIAMOND_VER = 0.7.9
DIAMOND_TGZ = diamond-linux64.tar.gz
DIAMOND_URL = https://github.com/bbuchfink/diamond/releases/download/v$(DIAMOND_VER)/$(DIAMOND_TGZ)
DIAMOND = diamond
DIAMOND_DB = $(BLAST_DB)/smallnr.dmnd
DIAMOND_MAKEDB_OPTIONS = -b 6
DIAMONDOPTIONS = --db $(DIAMOND_DB) --max-target-seqs 10
## SEQR and DB
SEQR_VER =  0.0.1-alpha
SEQR_JAR_URL = https://github.com/averagehat/seqr-clojure/releases/download/$(SEQR_VER)/seqr.jar
SEQR_SRC_URL = https://github.com/averagehat/seqr-clojure/archive/$(SEQR_VER).tar.gz
SEQR_SRC = seqr-clojure
SEQR_DB = $(SEQR_SRC)/testdata/solr/sequence/data
SEQR_JAR = seqr.jar                                                        #dashes for the empty alignment fields
SEQROPTIONS = --is_dna --db $(SEQR_SRC)/testdata/solr --outfm 6 query-id id - - - - - - - - - - 
SEQROUTPUT = single_cp_multi_thread_seqr.$(AVAILCPU).$(SUBSELECT).tsv

## Misc software
### GNU Parallel
PARALLEL_VER = 20150922
PARALLEL_BZ2 = parallel-$(PARALLEL_VER).tar.bz2
PARALLEL_URL = http://mirrors.kernel.org/gnu/parallel/$(PARALLEL_BZ2)
PARALLEL_PATH = parallel-$(PARALLEL_VER)/src/parallel
### pyfasta and virtualenv
VENV_PATH = venv
PIP_PATH = $(VENV_PATH)/bin/pip
PYFASTA_PATH = $(VENV_PATH)/bin/pyfasta
# All output files
CPUINFO = cpuinfo.txt
MEMINFO = meminfo.txt
SYSINFO = $(CPUINFO) $(MEMINFO)
BLASTOUTPUT = single_cpu_single_thread_blastx.tsv single_cpu_multi_thread_blastx.tsv multi_cpu_single_thread_blastx.tsv
DIAMONDOUTPUT = single_cpu_single_thread_diamond.tsv single_cpu_multi_thread_diamond.tsv
OUTPUTFILES = $(BLASTOUTPUT) $(DIAMONDOUTPUT) $(SYSINFO) $(SEQROUTPUT)
ALLSOFTWARE = $(BLAST_VER) $(DIAMOND) $(DIAMOND_TGZ) $(BLAST_TGZ)
# Here you can change a few things
AVAILCPU = 10
BLASTQUERYFILE = fasta/10.fasta.1
SPLITFASTAPREFIX = fasta/1.fasta
NUMENTRIES = $(shell grep '>' $(BLASTQUERYFILE) | wc -l)

all: $(OUTPUTFILES)

clean:
	rm -f $(OUTPUTFILES)

cleanall: clean
	rm -rf $(BLAST_DB) $(ALLSOFTWARE)

download: $(SMALLFASTA) software

software: $(BLASTX_PATH) $(DIAMOND) $(SEQR_JAR) $(SEQR_SRC)

dbs: $(BLAST_DB) $(DIAMOND_DB) $(SMALLBLASTNR) $(SMALLNRDBFILES) $(SEQR_DB)

$(CPUINFO):
	lscpu | tee $(CPUINFO)

$(MEMINFO):
	free -m | tee $(MEMINFO)

$(BLASTX_PATH) $(BLASTMAKEDBCMD) $(BLASTDBUPDATECMD):
	wget $(BLAST_URL) -O- | tar xzvf -
	touch $@

$(BLAST_DB):
	mkdir -p $(BLAST_DB)

$(SMALLFASTA): $(BLAST_DB)
	wget $(BLAST_DB_FASTA_URL) -O- | gunzip -c | ./subselect_fasta.py $(SUBSELECT) > $(SMALLFASTA)

$(SMALLNRDBFILES): $(SMALLFASTA) $(BLASTMAKEDBCMD)
	$(BLASTMAKEDBCMD) -in $(SMALLFASTA) -title smallnr -dbtype prot -max_file_sz 50GB -out $(SMALLNRDB)

$(BLAST_TGZ):
	wget $(BLAST_URL)

$(DIAMOND_TGZ):
	wget $(DIAMOND_URL)

$(DIAMOND): $(DIAMOND_TGZ)
	tar xzvf $(DIAMOND_TGZ)
	touch $(DIAMOND)

$(DIAMOND_DB): $(DIAMOND) $(SMALLFASTA)
	./$(DIAMOND) makedb --db $(DIAMOND_DB) --in $(SMALLFASTA) --threads $(AVAILCPU) $(DIAMOND_MAKEDB_OPTIONS)

$(SEQR_JAR):
	wget $(SEQR_JAR_URL)

$(SEQR_SRC): 
	wget $(SEQR_SRC_URL)
	tar xvf seqr-clojure-$(SEQR_VER) 

$(SEQR_DB): $(SEQR_SRC) $(SEQR_JAR) $(SMALLFASTA)
	java -jar $(SEQR_JAR) index $(SMALLFASTA) --in_format fasta -d $(SEQR_SRC)/testdata/solr 

# SEQR
# *May* require java 8
# Currently multi-cpu is not supported with embedded seqr because it causes database lock. it would work with server seqr.
# Currently seqr is multi-threaded by default, not sure if it actually helps or not.
single_cp_multi_thread_seqr.$(AVAILCPU).$(SUBSELECT).tsv: $(SEQR_DB) $(SEQR_JAR)
	time java -jar $(SEQR_JAR) search $(BLASTQUERYFILE) $(SEQROPTIONS) > $@

# NCBI Blastx

single_cpu_single_thread_blastx.tsv: $(SMALLNRDBFILES)
	# Run file using single cpu and single thread
	time $(BLASTX_PATH) $(BLASTOPTIONS) -num_threads 1 -query $(BLASTQUERYFILE) -out $@

single_cpu_multi_thread_blastx.tsv: $(SMALLNRDBFILES)
	# Run same file but use multiple threads
	time $(BLASTX_PATH) $(BLASTOPTIONS) -num_threads $(AVAILCPU) -query $(BLASTQUERYFILE) -out $@

multi_cpu_single_thread_blastx.tsv: $(SMALLNRDBFILES)
	# Run same file but split each fasta entry into own file/blast process
	python -c "print '\n'.join(['$(SPLITFASTAPREFIX).{0}'.format(i) for i in range(1,$(AVAILCPU)+1)])" | time xargs -P $(AVAILCPU) -IFASTA $(BLASTX_PATH) $(BLASTOPTIONS) -num_threads 1 -query FASTA > $@

# Diamond

single_cpu_single_thread_diamond.tsv: $(DIAMOND_DB) $(DIAMOND)
	# Run file using single cpu and single thread
	time ./$(DIAMOND) blastx $(DIAMONDOPTIONS) --threads 1 --query $(BLASTQUERYFILE) --daa $@
	./$(DIAMOND) view --daa $@.daa --out $@
	rm $@.daa

single_cpu_multi_thread_diamond.tsv: $(DIAMOND_DB) $(DIAMOND)
	# Run same file but use multiple threads
	time ./$(DIAMOND) blastx $(DIAMONDOPTIONS) --threads $(AVAILCPU) --query $(BLASTQUERYFILE) --daa $@
	./$(DIAMOND) view --daa $@.daa --out $@
	rm $@.daa

# Unused stuff

$(BLAST_DB)/done: $(BLAST_DB) $(BLASTDBUPDATECMD)
	( cd $(BLAST_DB) && $(CURDIR)/$(BLAST_VER)/bin/update_blastdb.pl --verbose --decompress nr )
	touch db/done

$(PARALLEL_BZ2):
	wget $(PARALLEL_URL)

$(PARALLEL_PATH): $(PARALLEL_BZ2)
	tar xjvf $(PARALLEL_BZ2)
	touch $(PARALLEL_PATH)

$(PIP_PATH):
	wget https://raw.githubusercontent.com/necrolyte2/bootstrap_vi/master/bootstrap_vi.py -O- | python - $(VENV_PATH)

