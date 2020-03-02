#!/usr/bin/env bash

/usr/bin/singularity run --bind /rds/user/$USER/hpc-work $HOME/containers/RefGenEdit-0.1.1.sif "$@"
