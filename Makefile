BLAST_VER = ncbi-blast-2.2.31+
BLAST_TGZ = $(BLAST_VER)-x64-linux.tar.gz
BLAST_URL = ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/$(BLAST_TGZ)
BLAST_DB = db
BLASTX_PATH = $(BLAST_VER)/bin/blastx
BLASTDBUPDATECMD = $(BLAST_VER)/bin/update_blastdb.pl

all: blastdb

blastdb: $(BLASTDBUPDATECMD)
	mkdir -p $(BLAST_DB)
	( cd $(BLAST_DB) && $(CURDIR)/$(BLAST_VER)/bin/update_blastdb.pl --verbose --decompress nr )

$(BLASTX_PATH) $(BLASTDBUPDATECMD): $(BLAST_TGZ)
	tar xzvf $(BLAST_TGZ)
	touch $(BLAST_VER)/bin/*

$(BLAST_TGZ):
	wget $(BLAST_URL)
