import pickle
import gctree
import historydag as hdag
from pathlib import Path
import sys

outgroup = sys.argv[1]
outdag = Path(sys.argv[2])
outdirs = [Path(path) for path in sys.argv[3:]]

dag = None
for runpath in outdirs:
    trees = gctree.phylip_parse.parse_outfile(runpath / 'outfile', root=outgroup, abundance_file=runpath / '../../abundances.csv')
    partial_dag = gctree.branching_processes._make_dag(trees, from_copy=False)
    for node in partial_dag.preorder(skip_root=True):
        if not node.is_leaf() and node.label.abundance > 0:
            node.label = type(node.label)(node.label.sequence, 0)
    if dag is None:
        dag = partial_dag
    else:
        dag.merge(partial_dag)

with open(outdag, 'wb') as fh:
    pickle.dump(dag, file=fh)
