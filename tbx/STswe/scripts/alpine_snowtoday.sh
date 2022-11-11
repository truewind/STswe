#!/bin/bash
# Date: 2022-09-21
# Purpose: This submits the snow-today matlab processing cron job on Alpine

#SBATCH --partition=amilan
#SBATCH --qos=normal
#SBATCH --account=ucb-general
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --job-name=matlab_ST
#SBATCH --output=matlab_ST.out
#SBATCH --mail-type=END
#SBATCH --mail-user=mark.raleigh@colorado.edu

# load any modules needed
module load matlab

# go to the directory where we will run - switched on Jan 7 2021, 5 PM to test directory
cd /projects/raleighm/Snow-Today/test_jan2020/STswe/tbx/STswe/
#cd /projects/raleighm/Snow-Today/Matlab/

# Run the control script (this includes the scp transfer)
matlab < a00_snowtoday_stationData_control.m
