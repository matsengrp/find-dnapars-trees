#!/bin/bash
set -eu
source $HOME/miniconda3/etc/profile.d/conda.sh
conda activate gctree-newest

OUTDIR=output_trees
FASTA=""
NUM_SEEDS=5
OUTGROUP="naive"
AGGSPLIT=10

print_help()
{
    echo "DESCRIPTION:"
    echo "This script takes a fasta file as input and outputs \
a history DAG containing a collection of maximally parsimonious trees found by \
running dnapars repeatedly with different random seeds.
times the value passed to -n."
    echo
    echo "Script requires dnapars, gctree, and historydag, and is intended to be run w/ access to Fred Hutch cluster."
    echo
    echo "SYNTAX:    find-dnapars-trees.sh -f INPUT_FASTA"
    echo
    echo "OPTIONS:"
    echo "-f    Provide an input fasta file (-f or REQUIRED)"
    echo "-n    Specify the number of times to run dnapars with different random seeds (default $NUM_SEEDS)"
    echo "-o    Specify an output directory for created trees"
    echo "          (default a directory called '$OUTDIR' in the current directory)"
    echo "-r    Specify an outgroup directory for created trees (default '$OUTGROUP')"
    echo "-s    Specify how many dnapars outfiles to assign to each aggregation job (default '$AGGSPLIT')"
    echo "-h    Print this help message and exit"
    echo
}


# getopts expects ':' after options that expect an argument
while getopts "n:f:ho:r:s:" option; do
    case $option in
        n)
            NUM_SEEDS=$OPTARG;;
        f)
            FASTA=$OPTARG;;
        h)
            print_help
            exit;;
        o)
            OUTDIR=$OPTARG;;
        r)
            OUTGROUP=$OPTARG;;
        s)
            AGGSPLIT=$OPTARG;;
    esac
done

[ -e $OUTDIR ] && { echo "$OUTDIR already exists! Exiting."; exit 0; }
mkdir $OUTDIR
TMPDIR=$OUTDIR/tmp
mkdir $TMPDIR

PHYLIPFILE=$TMPDIR/deduplicated.phylip
deduplicate $FASTA --root $OUTGROUP --abundance_file $OUTDIR/abundances.csv --idmapfile $OUTDIR/idmap.txt > $PHYLIPFILE
mkconfig $PHYLIPFILE dnapars > $TMPDIR/dnapars.cfg
sed -i '4s/.*/1/' $TMPDIR/dnapars.cfg

for ((seed=1;seed<=NUM_SEEDS;seed++)); do
    RUNDIR=$TMPDIR/run_$seed
    mkdir $RUNDIR
    MSEED=$(expr \( $seed - 1 \) \* 4 + 1)
    sed "3s/.*/$MSEED/" $TMPDIR/dnapars.cfg > $RUNDIR/dnapars.cfg
    sbatch -c 1 -J dps$seed -o $RUNDIR/dnapars.log ./run_dnapars.sh $RUNDIR
done

while :
do
    sleep 40
    NJOBS=$(squeue -l -u $USER | wc -l)
    [ $NJOBS == 2 ] && break
done
# Now all jobs are finished!

DAGDIR=$TMPDIR/dags
mkdir -p $DAGDIR
jobidx=0
ls -d $TMPDIR/run_*/ | xargs -n $AGGSPLIT | while read args; do
    jobidx=$(expr $jobidx + 1)
    echo $args | xargs sbatch -c 1 -J ag$jobidx -o $DAGDIR/agg$jobidx.log ./aggregate_script.sh $OUTGROUP $DAGDIR/dag$jobidx.p
done

while :
do
    sleep 40
    NJOBS=$(squeue -l -u $USER | wc -l)
    [ $NJOBS == 2 ] && break
done
# Now all jobs are finished!

#change args here:
python aggregate_dags.py $DAGDIR $OUTDIR/full_dag.p
# rm -rf $TMPDIR
