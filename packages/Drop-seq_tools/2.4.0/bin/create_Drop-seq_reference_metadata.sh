#!/usr/bin/env bash

/usr/bin/singularity run --bind /rds/user/$USER/hpc-work --app createDropseqreferencemetadata $HOME/containers/Drop-seq_tools-2.4.0.sif "$@"
