BLAST_VER = ncbi-blast-2.2.31+
BLAST_TGZ = $(BLAST_VER)-x64-linux.tar.gz
BLAST_URL = ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/$(BLAST_TGZ)
BLAST_DB = db
BLASTX_PATH = $(BLAST_VER)/bin/blastx
BLASTDBUPDATECMD = $(BLAST_VER)/bin/update_blastdb.pl
BLASTOPTIONS = -db db/nr -task blastx -outfmt 6 -max_target_seqs 10

all: $(BLAST_DB)/done single_cpu_single_thread_blastx.tsv

$(BLAST_DB)/done: $(BLASTDBUPDATECMD)
	mkdir -p $(BLAST_DB)
	( cd $(BLAST_DB) && $(CURDIR)/$(BLAST_VER)/bin/update_blastdb.pl --verbose --decompress nr )
	touch db/done

$(BLASTX_PATH) $(BLASTDBUPDATECMD): $(BLAST_TGZ)
	tar xzvf $(BLAST_TGZ)
	touch $(BLAST_VER)/bin/*

$(BLAST_TGZ):
	wget $(BLAST_URL)

single_cpu_single_thread_blastx.tsv: $(BLAST_DB)/done
	echo $@
	#time $(BLASTX_PATH) $(BLASTOPTIONS) -num_threads 1 -query test.fasta -out single_cpu_single_thread_blastx.tsv
