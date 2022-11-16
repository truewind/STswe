#!/bin/bash
module load slurm/alpine
sbatch --export=NONE /projects/raleighm/Snow-Today/test_jan2020/STswe/tbx/STswe/scripts/snowtoday.sh
