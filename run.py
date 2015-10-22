'''
run_compare <tool> [-p | --parallel]
'''
from config import tests, varmap
import re
import itertools
from functools import partial
#won't allow escaped hashtags

#var_val_list = filter(lambda x: len(x) == 2,
var_val_re = re.compile("^([^\s^:]+)\s*=\s*([^#^\n]+)")
first = lambda x: x[0]
ffirst = lambda p, xs: first(filter(p, xs))
find = lambda e, xs: ffirst(lambda x: x[0] == e, xs)
def lookup(vvs, var):
    '''if var is already well-defined, return its value ##add it to the map and return the map.
    if a var is not well-defined, lookup all of its rhs values, then format them back in.'''
    assert var in map(first,  vvs), "var  %s not in vars" % var
    val = find(var, vvs)[1]
    unbounds = re.findall(r'\$\(([^)]+)\)', val)
    if not unbounds:
        return val
    else:
        unbounded_vals = map(partial(lookup, vvs), unbounds)
        d = dict(zip(unbounds, unbounded_vals))
        py_format = re.sub(r'\$\(([^)]+)\)', r'{\1}', val)
        return py_format.format(**d)

def _make_file_var_map(fn):
    lines = open(fn).readlines()
    _var_val_list = list(itertools.chain(*map(var_val_re.findall, lines)))
    var_val_list = map(lambda x: map(str.strip, x), _var_val_list)
    vars = map(first, var_val_list)
    _varmap = dict(zip(vars, map(partial(lookup, var_val_list), vars)))
    return _varmap


# make download SUBSELECT=whatever
# make dbs
#fix how smallfasta is made

# convert to luigi?
def merge2(d1, d2):
    d3 = {}
    d3.update(d1)
    d3.update(d2)
    return d3

merge = lambda *x: reduce(merge2, x)

def cmd(_varmap, d):
    out = d['out'].format(**_varmap)
    varsdict = merge(d,_varmap, {"out" : out})
    #print varsdict
    cmd = d['cmd'].format(**varsdict)
    return cmd

def get_tests(tool=None, par=None):
    assert tool is not None or par is not None
    info = merge({"tool" : tool} if tool else {}, {"par" : par} if par else {})
    print info
    def match(d):
        return not set(info.items()) - set(d.items() )
    return filter(match, tests)
import sys
def main():
    tool = sys.argv[1]
    par = True if '-p' in sys.argv[1:] or '--parallel' in sys.argv[1:] else None
    print "Searching for test of tool %s" % tool + "multithreading specified %s" % par if par else ""
    try:
        tests = get_tests(tool, par=par)
    except:
        print "Tool %s with parallel setting %s not found. check config.py." % (pool, par)
        sys.exit(1)

    commands = map(partial(cmd, varmap), tests)
    map(run_cmd, commands)


import subprocess
def run_cmd(s):
    print "[RUNNING] %s" % s
    subprocess.check_call(s, shell=True)


if __name__ == '__main__':
    main()
