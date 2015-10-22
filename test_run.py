from config import tests, varmap
from run import cmd, var_val_re, lookup, _make_file_var_map
import itertools

#import pprint
#pprint.pprint( varmap, width=1)# >> "foo.txt"
#pprint.pprint( _make_file_var_map("Makefile"), width=1)# >> "foo.txt"

# Test lookup
lines = ( "BLAST_DB_FASTA = $(BLAST_DB)/nr.fasta"  , "BLASTDBUPDATECMD = $(BLAST_DB)/bin/update_blastdb.pl", "BLAST_DB = foo")
var_val_list = list(itertools.chain(*map(var_val_re.findall, lines)))
assert lookup(var_val_list, "BLAST_DB") == "foo"
assert lookup(var_val_list, "BLAST_DB_FASTA") == "foo/nr.fasta"

#Test cmd
assert cmd(varmap, tests[0]) == "time java -jar $seqr.jar search $fasta/10.fasta.1 $--is_dna --db seqr-clojure-0.0.1-alpha/testdata/solr --outfm 6 query-id id - - - - - - - - - - > single_cpu_multi_thread_seqr.$10.$700000.tsv"

#Test Makefile Var parsing for regressions
assert _make_file_var_map("Makefile") == varmap


