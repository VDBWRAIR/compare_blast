tests = [
{
    "tool" : "seqr",
    "par" : False,
    "out" : "single_cpu_multi_thread_seqr.{AVAILCPU}.{SUBSELECT}.tsv",
    "cmd" : "time java -jar {SEQR_JAR} search {BLASTQUERYFILE} {SEQROPTIONS} > {out}"
},

{
   "tool" : "blastx",
    "par" : True,
   "out" : "single_cpu_single_thread_blastx.{AVAILCPU}.{SUBSELECT}.tsv",
   "cmd" : 	"{TIME} -o {out}.{TIMES} {BLASTX_PATH} {BLASTOPTIONS} -num_threads 1 -query {BLASTQUERYFILE} -out {out} >> {LOGFILE}"
},

{
    "tool" : "blastx",
    "par" : False,
    "out" : "multi_cpu_single_thread_blastx.{AVAILCPU}.{SUBSELECT}.tsv",
	# Run same file but split each fasta entry into own file/blast process
    "cmd" : '''python -c "print '\n'.join(['{SPLITFASTAPREFIX}.%s' % i for i in range(1,{AVAILCPU}+1)])" | {TIME} -o {out}.{TIMES} xargs -P {AVAILCPU} -IFASTA {BLASTX_PATH} {BLASTOPTIONS} -num_threads 1 -query FASTA > {out}'''
},
{
    "tool" : "diamond",
    "par" : False,
    "out" : "single_cpu_single_thread_diamond.{AVAILCPU}.{SUBSELECT}.tsv" ,
    "cmd" : "{TIME} -o {out}.{TIMES} ./{DIAMOND} blastx {DIAMONDOPTIONS} --threads 1 --query {BLASTQUERYFILE} --daa {out} >> {LOGFILE} && ./{DIAMOND} view --daa {out}.daa --out {out}"
	#rm {out}.daa
},
{
    "tool" : "diamond",
    "par" : True,
    "out" : "single_cpu_multi_thread_diamond.{AVAILCPU}.{SUBSELECT}.tsv",
	# Run same file but use multiple threads
    "cmd" : "{TIME} -o {out}.{TIMES} ./{DIAMOND} blastx {DIAMONDOPTIONS} --threads {AVAILCPU} --query {BLASTQUERYFILE} --daa {out} >> {LOGFILE} && ./{DIAMOND} view --daa {out}.daa --out {out}"
}]

varmap={'ALLSOFTWARE': 'ncbi-blast-2.2.31+ diamond diamond-linux64.tar.gz ncbi-blast-2.2.31+-x64-linux.tar.gz',
 'AVAILCPU': '10',
 'BLASTDBCMD': 'ncbi-blast-2.2.31+/bin/blastdbcmd',
 'BLASTDBUPDATECMD': 'ncbi-blast-2.2.31+/bin/update_blastdb.pl',
 'BLASTMAKEDBCMD': 'ncbi-blast-2.2.31+/bin/makeblastdb',
 'BLASTOPTIONS': '-db db/smallnr.700000 -task blastx -outfmt 6 -max_target_seqs 10 -evalue 0.001 -gapopen 11 -gapextend 1',
 'BLASTOUTPUT': 'single_cpu_single_thread_blastx.10.700000.tsv single_cpu_multi_thread_blastx.10.700000.tsv multi_cpu_single_thread_blastx.10.700000.tsv',
 'BLASTQUERYFILE': 'fasta/10.fasta.1',
 'BLASTX_PATH': 'ncbi-blast-2.2.31+/bin/blastx',
 'BLAST_DB': 'db',
 'BLAST_DB_FASTA': 'db/nr.fasta',
 'BLAST_DB_FASTA_GZ': 'nr.gz',
 'BLAST_DB_FASTA_URL': 'ftp://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nr.gz',
 'BLAST_TGZ': 'ncbi-blast-2.2.31+-x64-linux.tar.gz',
 'BLAST_URL': 'ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.2.31+-x64-linux.tar.gz',
 'BLAST_VER': 'ncbi-blast-2.2.31+',
 'CPUINFO': 'cpuinfo.txt',
 'DIAMOND': 'diamond',
 'DIAMONDOPTIONS': '--db db/smallnr.700000.dmnd --max-target-seqs 10',
 'DIAMONDOUTPUT': 'single_cpu_single_thread_diamond.10.700000.tsv single_cpu_multi_thread_diamond.10.700000.tsv',
 'DIAMOND_DB': 'db/smallnr.700000.dmnd',
 'DIAMOND_MAKEDB_OPTIONS': '-b 6',
 'DIAMOND_TGZ': 'diamond-linux64.tar.gz',
 'DIAMOND_URL': 'https://github.com/bbuchfink/diamond/releases/download/v0.7.9/diamond-linux64.tar.gz',
 'DIAMOND_VER': '0.7.9',
 'GETFILECMD': 'wget',
 'LOGFILE': 'output.txt',
 'MEMINFO': 'meminfo.txt',
 'OUTPUTFILES': 'single_cpu_single_thread_blastx.10.700000.tsv single_cpu_multi_thread_blastx.10.700000.tsv multi_cpu_single_thread_blastx.10.700000.tsv single_cpu_single_thread_diamond.10.700000.tsv single_cpu_multi_thread_diamond.10.700000.tsv single_cpu_multi_thread_seqr.10.700000.tsv cpuinfo.txt meminfo.txt',
 'PARALLEL_BZ2': 'parallel-20150922.tar.bz2',
 'PARALLEL_PATH': 'parallel-20150922/src/parallel',
 'PARALLEL_URL': 'http://mirrors.kernel.org/gnu/parallel/parallel-20150922.tar.bz2',
 'PARALLEL_VER': '20150922',
 'PIP_PATH': 'venv/bin/pip',
 'PYFASTA_PATH': 'venv/bin/pyfasta',
 'SEQROPTIONS': '--is_dna --db seqr-clojure-0.0.1-alpha/testdata/solr --outfm 6 query-id id - - - - - - - - - -',
 'SEQROUTPUT': 'single_cpu_multi_thread_seqr.10.700000.tsv',
 'SEQR_DB': 'seqr-clojure-0.0.1-alpha/testdata/solr/sequence/data',
 'SEQR_JAR': 'seqr.jar',
 'SEQR_JAR_URL': 'https://github.com/averagehat/seqr-clojure/releases/download/0.0.1-alpha/seqr.jar',
 'SEQR_SRC': 'seqr-clojure-0.0.1-alpha',
 'SEQR_SRC_URL': 'https://github.com/averagehat/seqr-clojure/archive/0.0.1-alpha.tar.gz',
 'SEQR_VER': '0.0.1-alpha',
 'SMALLFASTA': 'db/smallnr.700000.fasta',
 'SMALLNRDB': 'db/smallnr.700000',
 'SMALLNRDBFILES': 'db/smallnr.700000.pin db/smallnr.700000.phr db/smallnr.700000.psq',
 'SPLITFASTAPREFIX': 'fasta/1.fasta',
 'SUBSELECT': '700000',
 'SYSINFO': 'cpuinfo.txt meminfo.txt',
 'TIME': '/usr/bin/time',
 'TIMES': 'times.txt',
 'TSVOUTPUT': 'single_cpu_single_thread_blastx.10.700000.tsv single_cpu_multi_thread_blastx.10.700000.tsv multi_cpu_single_thread_blastx.10.700000.tsv single_cpu_single_thread_diamond.10.700000.tsv single_cpu_multi_thread_diamond.10.700000.tsv single_cpu_multi_thread_seqr.10.700000.tsv',
 'VENV_PATH': 'venv'}
