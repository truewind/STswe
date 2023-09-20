%a02_snowtoday_figs_textfiles_control.m
clear;
clc;
close all;

% This script is the control script that launches scripts to create figures
% and text files after the latest snow station data have been downloaded.
%
% Code written by Mark Raleigh (raleigma@oregonstate.edu)

%% launch scripts here

%%% step 2a: generate plot for daily change in SWE (dSWE)
disp('  Step 2a: creating daily dSWE figures')
a02a_snow_station_map_dSWE;
disp('  ... DONE!')
disp('  .')

%%% step 2b: generate plot for daily SWE percent of median
disp('  Step 2b: creating normSWE/climSWE figures')
a02b_snow_station_climSWE;
disp('  ... DONE!')
disp('  .')

%%% step 2c: generate plots of SWE percent of long-term mean peak SWE for
%%% this date
disp('  Step 2c: creating percent of LT peak SWE figures')
a02c_snow_station_peakSWE_percent;
disp('  ... DONE!')
disp('  .')

%%% step 2d: generate plot of net dSWE to date for the current month
disp('  Step 2d: creating month-to-date dSWE figures')
a02d_snow_station_monthly_dSWE_to_date;
disp('  ... DONE!')
disp('  .')

%%% step 2e: create daily summary of SWE variables at all stations in
%%% single text file
disp('  Step 2e: writing daily text file summaries')
a02e_snow_station_text_summaries;
disp('  ... DONE!')
disp('  .')



