#!/bin/bash
set -eu
source $HOME/miniconda3/etc/profile.d/conda.sh
conda activate gctree-newest

RUNDIR=$1

cd $RUNDIR
dnapars < dnapars.cfg
