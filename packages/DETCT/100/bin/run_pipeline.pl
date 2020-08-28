#!/usr/bin/env bash

/usr/bin/singularity run --bind /rds/user/$USER/hpc-work $HOME/containers/DETCT-100.sif "$@"
