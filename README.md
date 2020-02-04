CSD3
====

Setup:

```
mkdir ~/checkouts ~/containers
cd ~/checkouts
git clone git@github.com:iansealy/CSD3.git # Or https://github.com/iansealy/CSD3.git if you aren't iansealy
rm -f ~/.bashrc ~/.bash_profile ~/.profile ~/.bash_logout ~/.bash_history
ln -s ~/checkouts/CSD3/dotfiles/bashrc ~/.bashrc
ln -s ~/checkouts/CSD3/dotfiles/profile ~/.profile
ln -s ~/checkouts/CSD3/dotfiles/environ ~/.environ
ln -s ~/checkouts/CSD3/dotfiles/aliases ~/.aliases
ln -s ~/checkouts/CSD3/dotfiles/functions ~/.functions
ln -s ~/checkouts/CSD3/dotfiles/bash_logout ~/.bash_logout
ln -s ~/checkouts/CSD3/dotfiles/gitconfig ~/.gitconfig
ln -s ~/checkouts/CSD3/modulefiles ~/privatemodules
ln -s ~/checkouts/CSD3/packages ~/packages
ln -s ~/checkouts/CSD3/bin ~/bin
exit
```

## Useful Info

- https://docs.hpc.cam.ac.uk/hpc/

- Hard quota of 40 GB for home directories
- Home directory snapshots are under /home/.zfs/snapshot
- Scratch directory is ~/rds/hpc-work (symlink to /rds/user/$USER/hpc-work) and has 1 TB quota and max 1 M files

`quota`

```Filesystem  GiBytes    quota   limit   grace    files    quota    limit   grace User/group
/home           0.0     40.0    40.0       -    ----- No ZFS File Quotas  ----- U:is
/rds-d5         0.0   1024.0  1126.4       -        2  1048576  1048576       - G:is
```

`mybalance` - show usage in CPU core hours

```User           Usage |        Account     Usage | Account Limit Available (hours)
---------- --------- + -------------- --------- + ------------- ---------
is                 0 | XXXXX-XXXXXXXX-SL3-CPU         0 |       200,000   200,000
```

- Usage is per quarter (1st February - 30th April, 1st May - 31st July, 1st August - 31st October and 1st November - 31st January)
- Service Level 3 - 200,000 CPU core hours per PI per quarter
- Service Level 4 - jobs only run when SL1-3 jobs not running
- Max run time 12 h for SL3-4 (36 h for SL1-2)
- RAM is allocated and charged in ~5980 MB blocks
- Costs for additonal storage: https://www.hpc.cam.ac.uk/research-data-storage-services/price-list
- Costs for additonal compute: https://www.hpc.cam.ac.uk/policies/charges
- Test runs on login nodes should be short (seconds), use <= 4 CPUS, max 20 GB RAM and be prefixed with nice -19
- Can only SSH to nodes where own jobs are running

- Slurm summary: https://slurm.schedmd.com/pdfs/summary.pdf
- Convert LSF commands to Slurm equivalent: https://slurm.schedmd.com/rosetta.pdf
`bjobs` == `squeue -u $USER`
