#!/usr/bin/env bash

/usr/bin/singularity run --bind /rds/user/$USER/hpc-work,/rds/project/rds-4Pn70P2LQH0 --app createDropseqreferencemetadata $HOME/containers/Drop-seq_tools-2.4.0.sif "$@"
