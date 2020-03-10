#!/usr/bin/env bash

/usr/bin/singularity run --bind /rds/user/$USER/hpc-work $HOME/containers/topgo-wrapper-99.sif "$@"
