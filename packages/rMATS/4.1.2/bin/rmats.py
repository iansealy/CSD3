#!/usr/bin/env bash

/usr/bin/singularity run --bind /rds/user/$USER/hpc-work,/rds/project/rds-4Pn70P2LQH0 $HOME/containers/rMATS-4.1.2.sif "$@"