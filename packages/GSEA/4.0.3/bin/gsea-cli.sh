#!/usr/bin/env bash

/usr/bin/singularity run --bind /rds/user/$USER/hpc-work $HOME/containers/GSEA-4.0.3.sif "$@"
