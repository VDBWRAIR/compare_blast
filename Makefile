# Makefile to handle comparing different ways to parallelize blast type
# applications.
# Because I am newish to Makefiles here are some helpful things:
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
BLASTX_PATH = $(BLAST_VER)/bin/blastx
BLASTDBUPDATECMD = $(BLAST_VER)/bin/update_blastdb.pl
BLASTDBCMD = $(BLAST_VER)/bin/blastdbcmd
BLASTOPTIONS = -db db/nr -task blastx -outfmt 6 -max_target_seqs 10
## Diamond and Diamond DB
DIAMOND_VER = 0.7.9
DIAMOND_TGZ = diamond-linux64.tar.gz
DIAMOND_URL = https://github.com/bbuchfink/diamond/releases/download/v$(DIAMOND_VER)/$(DIAMOND_TGZ)
DIAMOND = diamond
DIAMOND_DB = $(BLAST_DB)/nr.dmnd
DIAMOND_MAKEDB_OPTIONS = -b 6
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
OUTPUTFILES = $(BLASTOUTPUT) $(SYSINFO)
# Here you can change a few things
AVAILCPU = 10
BLASTQUERYFILE = fasta/10.fasta.1
SPLITFASTAPREFIX = fasta/1.fasta
NUMENTRIES = $(shell grep '>' $(BLASTQUERYFILE) | wc -l)

all: $(BLAST_DB)/done $(OUTPUTFILES)

clean:
	rm -f $(OUTPUTFILES)

$(CPUINFO):
	lscpu | tee $(CPUINFO)

$(MEMINFO):
	free -m | tee $(MEMINFO)

$(BLAST_DB)/done: $(BLASTDBUPDATECMD)
	mkdir -p $(BLAST_DB)
	( cd $(BLAST_DB) && $(CURDIR)/$(BLAST_VER)/bin/update_blastdb.pl --verbose \
	--decompress nr )
	touch db/done

$(BLASTX_PATH) $(BLASTDBUPDATECMD) $(BLASTDBCMD): $(BLAST_TGZ)
	tar xzvf $(BLAST_TGZ)
	touch $(BLAST_VER)/bin/*

$(BLAST_TGZ):
	wget $(BLAST_URL)

$(PARALLEL_BZ2):
	wget $(PARALLEL_URL)

$(PARALLEL_PATH): $(PARALLEL_BZ2)
	tar xjvf $(PARALLEL_BZ2)
	touch $(PARALLEL_PATH)

$(PIP_PATH):
	wget https://raw.githubusercontent.com/necrolyte2/bootstrap_vi/master/bootstrap_vi.py -O- | python - $(VENV_PATH)

$(BLAST_DB_FASTA): $(BLASTDBCMD)
	$(BLASTDBCMD) -db db/nr -entry all -outfmt %f -out $(BLAST_DB_FASTA)

$(DIAMOND_TGZ):
	wget $(DIAMOND_URL)

$(DIAMOND): $(DIAMOND_TGZ)
	tar xzvf $(DIAMOND_TGZ)
	touch $(DIAMOND)

$(DIAMOND_DB): $(DIAMOND) $(BLAST_DB_FASTA)
	./$(DIAMOND) makedb --db $(DIAMOND_DB) --in $(BLAST_DB_FASTA) --threads $(AVAILCPU) $(DIAMOND_MAKEDB_OPTIONS)

single_cpu_single_thread_blastx.tsv: $(BLAST_DB)/done
	# Run file using single cpu and single thread
	time $(BLASTX_PATH) $(BLASTOPTIONS) -num_threads 1 \
	-query $(BLASTQUERYFILE) -out $@

single_cpu_multi_thread_blastx.tsv: $(BLAST_DB)/done
	# Run same file but use multiple threads
	time $(BLASTX_PATH) $(BLASTOPTIONS) -num_threads $(AVAILCPU) \
	-query $(BLASTQUERYFILE) -out $@

multi_cpu_single_thread_blastx.tsv: $(BLAST_DB)/done
	# Run same file but split each fasta entry into own file/blast process
	python -c "print '\n'.join(['$(SPLITFASTAPREFIX).{0}'.format(i) \
	for i in range(1,$(AVAILCPU)+1)])" | time xargs -P $(AVAILCPU) -IFASTA \
	$(BLASTX_PATH) $(BLASTOPTIONS) -num_threads 1 -query FASTA > $@
