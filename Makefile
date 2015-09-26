# Makefile to handle comparing different ways to parallelize blast type
# applications.
# Because I am newish to Makefiles here are some helpful things:
#   https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html
#   http://www.chemie.fu-berlin.de/chemnet/use/info/make/make_15.html
#   $@ stands for the target(left side of :)
#   $< first dependency(right side of :)
#   $? all dependencies newer than target

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
SMALLNRDB = $(BLAST_DB)/smallnr.$(SUBSELECT)
SMALLNRDBFILES = $(SMALLNRDB).pin $(SMALLNRDB).phr $(SMALLNRDB).psq
SMALLFASTA = $(BLAST_DB)/smallnr.$(SUBSELECT).fasta
BLASTOPTIONS = -db $(SMALLNRDB) -task blastx -outfmt 6 -max_target_seqs 10 -evalue 0.001 -gapopen 11 -gapextend 1
## Diamond and Diamond DB
DIAMOND_VER = 0.7.9
DIAMOND_TGZ = diamond-linux64.tar.gz
DIAMOND_URL = https://github.com/bbuchfink/diamond/releases/download/v$(DIAMOND_VER)/$(DIAMOND_TGZ)
DIAMOND = diamond
DIAMOND_DB = $(BLAST_DB)/smallnr.$(SUBSELECT).dmnd
DIAMOND_MAKEDB_OPTIONS = -b 6
DIAMONDOPTIONS = --db $(DIAMOND_DB) --max-target-seqs 10
## Misc software
TIME = /usr/bin/time
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
AVAILCPU = 10
BLASTOUTPUT = single_cpu_single_thread_blastx.$(AVAILCPU).$(SUBSELECT).tsv single_cpu_multi_thread_blastx.$(AVAILCPU).$(SUBSELECT).tsv multi_cpu_single_thread_blastx.$(AVAILCPU).$(SUBSELECT).tsv
DIAMONDOUTPUT = single_cpu_single_thread_diamond.$(AVAILCPU).$(SUBSELECT).tsv single_cpu_multi_thread_diamond.$(AVAILCPU).$(SUBSELECT).tsv
TSVOUTPUT = $(BLASTOUTPUT) $(DIAMONDOUTPUT)
OUTPUTFILES = $(TSVOUTPUT) $(SYSINFO)
ALLSOFTWARE = $(BLAST_VER) $(DIAMOND) $(DIAMOND_TGZ) $(BLAST_TGZ)
# This file will only be created if make | tee output.txt is used
LOGFILE = output.txt
TIMES = times.txt
# Here you can change a few things
BLASTQUERYFILE = fasta/10.fasta.1
SPLITFASTAPREFIX = fasta/1.fasta
NUMENTRIES = $(shell grep '>' $(BLASTQUERYFILE) | wc -l)
GETFILECMD = wget

tests: $(OUTPUTFILES)

clean:
	rm -f $(OUTPUTFILES) $(addsuffix .times.txt,$(OUTPUTFILES))

cleanall: clean
	rm -rf $(BLAST_DB) $(ALLSOFTWARE)

download: $(SMALLFASTA) software

software: $(BLASTX_PATH) $(DIAMOND)

dbs: $(BLAST_DB) $(DIAMOND_DB) $(SMALLBLASTNR) $(SMALLNRDBFILES)

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
	$(GETFILECMD) $(BLAST_DB_FASTA_URL) -O- | gunzip -c | ./subselect_fasta.py $(SUBSELECT) > $(SMALLFASTA)

$(SMALLNRDBFILES): $(SMALLFASTA) $(BLASTMAKEDBCMD)
	$(TIME) $(BLASTMAKEDBCMD) -in $(SMALLFASTA) -title smallnr -dbtype prot -max_file_sz 50GB -out $(SMALLNRDB)

$(BLAST_TGZ):
	wget $(BLAST_URL)

$(DIAMOND_TGZ):
	wget $(DIAMOND_URL)

$(DIAMOND): $(DIAMOND_TGZ)
	tar xzvf $(DIAMOND_TGZ)
	touch $(DIAMOND)

$(DIAMOND_DB): $(DIAMOND) $(SMALLFASTA)
	$(TIME) ./$(DIAMOND) makedb --db $(DIAMOND_DB) --in $(SMALLFASTA) --threads $(AVAILCPU) $(DIAMOND_MAKEDB_OPTIONS)

# NCBI Blastx

single_cpu_single_thread_blastx.$(AVAILCPU).$(SUBSELECT).tsv:
	# Run file using single cpu and single thread
	$(TIME) -o $@.$(TIMES) $(BLASTX_PATH) $(BLASTOPTIONS) -num_threads 1 -query $(BLASTQUERYFILE) -out $@ >> $(LOGFILE)

single_cpu_multi_thread_blastx.$(AVAILCPU).$(SUBSELECT).tsv:
	# Run same file but use multiple threads
	$(TIME) -o $@.$(TIMES) $(BLASTX_PATH) $(BLASTOPTIONS) -num_threads $(AVAILCPU) -query $(BLASTQUERYFILE) -out $@ >> $(LOGFILE)

multi_cpu_single_thread_blastx.$(AVAILCPU).$(SUBSELECT).tsv:
	# Run same file but split each fasta entry into own file/blast process
	python -c "print '\n'.join(['$(SPLITFASTAPREFIX).{0}'.format(i) for i in range(1,$(AVAILCPU)+1)])" | $(TIME) -o $@.$(TIMES) xargs -P $(AVAILCPU) -IFASTA $(BLASTX_PATH) $(BLASTOPTIONS) -num_threads 1 -query FASTA > $@

# Diamond

single_cpu_single_thread_diamond.$(AVAILCPU).$(SUBSELECT).tsv:
	# Run file using single cpu and single thread
	$(TIME) -o $@.$(TIMES) ./$(DIAMOND) blastx $(DIAMONDOPTIONS) --threads 1 --query $(BLASTQUERYFILE) --daa $@ >> $(LOGFILE)
	./$(DIAMOND) view --daa $@.daa --out $@
	#rm $@.daa

single_cpu_multi_thread_diamond.$(AVAILCPU).$(SUBSELECT).tsv:
	# Run same file but use multiple threads
	$(TIME) -o $@.$(TIMES) ./$(DIAMOND) blastx $(DIAMONDOPTIONS) --threads $(AVAILCPU) --query $(BLASTQUERYFILE) --daa $@ >> $(LOGFILE)
	./$(DIAMOND) view --daa $@.daa --out $@
	#rm $@.daa

times:
	grep 'elapsed' *.$(TIMES)

hits:
	wc -l $(OUTPUTFILES)

report:
	@echo "AVAILCPU: $(AVAILCPU)"
	./report.py $(TSVOUTPUT)

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

