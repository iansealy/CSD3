#!/usr/bin/env bash

/usr/bin/singularity run --bind /rds/user/$USER/hpc-work,/rds/project/rds-4Pn70P2LQH0 --app simulationv2 $HOME/containers/bsa-1.sif "$@"
