#!/bin/bash
set -eu
source $HOME/miniconda3/etc/profile.d/conda.sh
conda activate gctree-newest

OUTDIR=output_trees
FASTA=""
OUTGROUP="naive"
seed=1

print_help()
{
    echo "DESCRIPTION:"
    echo "This script takes a fasta file as input and outputs \
a pickle file containing a list of ete trees with attributes: \n\
name: For leaves, the 'original_id' (see below), otherwise a node ID assigned by dnapars \n\
sequence: the sequence inferred by dnapars at the node \n\
original_sequence: (for leaves) the original sequence in the provided fasta \n\
original_ids: (for leaves) a list of original sample IDs from the original fasta represented by this leaf \history DAG containing a collection of maximally parsimonious trees found by \n\
original_id: (for leaves) the first original sample ID in 'original_ids' \n\
\nEach tree has a leaf added below the root, containing the root sequence."
    echo
    echo "Script requires dnapars and gctree, and is intended to be run w/ access to Fred Hutch cluster."
    echo
    echo "SYNTAX:    find-dnapars-trees.sh -f INPUT_FASTA"
    echo
    echo "OPTIONS:"
    echo "-f    Provide an input fasta file (-f or REQUIRED)"
    echo "-s    Provide any natural number to determine a dnapars random seed (default $seed)"
    echo "          (this script accommodates dnapars restrictions on seed values)"
    echo "-o    Specify an output directory for created trees"
    echo "          (default a directory called '$OUTDIR' in the current directory)"
    echo "-r    Specify an outgroup name appearing in fasta file (default '$OUTGROUP')"
    echo "-h    Print this help message and exit"
    echo
}


# getopts expects ':' after options that expect an argument
while getopts "f:ho:r:s:" option; do
    case $option in
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
            seed=$OPTARG;;
    esac
done

[ -e $OUTDIR ] && { echo "$OUTDIR already exists! Exiting."; exit 0; }
mkdir $OUTDIR
TMPDIR=$OUTDIR/tmp
mkdir $TMPDIR

PHYLIPFILE=$TMPDIR/deduplicated.phylip
abundance_file=$OUTDIR/abundances.csv
idmap_file=$OUTDIR/idmap.txt
deduplicate $FASTA --root $OUTGROUP --abundance_file $abundance_file --idmapfile $idmap_file > $PHYLIPFILE
mkconfig $PHYLIPFILE dnapars > $TMPDIR/dnapars.cfg
sed -i '4s/.*/1/' $TMPDIR/dnapars.cfg

MSEED=$(expr \( $seed - 1 \) \* 4 + 1)
sed -i "3s/.*/$MSEED/" $TMPDIR/dnapars.cfg
./run_dnapars.sh $TMPDIR > $TMPDIR/dnapars.log

python process_outfile.py $OUTGROUP $OUTDIR $TMPDIR/outfile $abundance_file $idmap_file $FASTA

rm -rf $TMPDIR
