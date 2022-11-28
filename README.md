# Description:

These scripts make it (relatively) easy to use dnapars to build lots of maximally parsimonious trees on a reasonable (<~300 depending on sequence length) number of sequences. I found that the jumble option didn't seem to change the number of trees found by dnapars, so I decided to run dnapars multiple times to find more trees.

Given a fasta alignment, the script `find-dnapars-trees.sh` submits concurrent dnapars jobs to the cluster, then calls `aggregate_dnapars_trees.py` to read the outputs from those dnapars runs, and combine the resulting trees into a history DAG. The dnapars-interfacing infrastructure from gctree is used to make this all much easier.

# Requirements:

* A conda environment with `PHYLIP` and `gctree` and `click`
* cluster access

```
./find-dnapars-trees.sh -f input_seqs.fasta
```

should be enough to get a history DAG with a bunch of maximally parsimonious trees in it.

To see script options, do `./find-dnapars-trees.sh -h`.
