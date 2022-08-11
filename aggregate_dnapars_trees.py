import pickle
import gctree
import historydag as hdag
from pathlib import Path
import sys

tmpdir = Path(sys.argv[1])
outdir = Path(sys.argv[2])
outgroup = sys.argv[3]

dag = None
for runpath in (path for path in tmpdir.glob('*') if path.is_dir()):
    trees = gctree.phylip_parse.parse_outfile(runpath / 'outfile', root=outgroup, abundance_file=outdir/'abundances.csv')
    partial_dag = gctree.branching_processes._make_dag(trees, from_copy=False)
    for node in partial_dag.preorder(skip_root=True):
        if not node.is_leaf() and node.label.abundance > 0:
            node.label = type(node.label)(node.label.sequence, 0)
    print("Parsimony score of trees in ", runpath, " is ", partial_dag.optimal_weight_annotate())
    if dag is None:
        dag = partial_dag
    else:
        dag.merge(partial_dag)

with open(outdir / 'full_dag.p', 'wb') as fh:
    pickle.dump(dag, file=fh)

print("final DAG stats:")
dag.summary()


