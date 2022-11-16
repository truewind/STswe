#!/bin/bash
# Date: 2022-09-21
# Purpose: This submits the snow-today matlab processing cron job on Alpine

# load any modules needed
module load matlab

# go to the directory where we will run - switched on Jan 7 2021, 5 PM to test directory
cd /projects/raleighm/Snow-Today/test_jan2020/STswe/tbx/STswe/
#cd /projects/raleighm/Snow-Today/Matlab/

# Run the control script (this includes the scp transfer)
matlab < a00_snowtoday_stationData_control.m > /home/raleighm/log_ST.txt
