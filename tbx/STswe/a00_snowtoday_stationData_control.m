%a00_snowtoday_stationData_control
clear;
clc;
close all;

% This script is the master control script that is invoked with the
% scrontab job for SWE station data on Snow Today.
% It sequentially executes a series of scripts that download
% the latest SWE station data, does basic quality control (QC), generates
% figures and text summaries, and transfers copies of these files to other
% locations (e.g., Petalibary archive, NSIDC nusnow
%
% Code written by Mark Raleigh (raleigma@oregonstate.edu)

%% Snow pillows

disp('SNOW STATIONS')

%%% step 1a: download latest snow station data
disp('  Step 1a: downloading data')
a01a_snow_station_data_download;
disp('  ... DONE!')
disp('  .')

%%% step 1b: QC the merged database
disp('  Step 1b: basic QC on the data')
a01b_snow_station_data_QC;
disp('  ... DONE!')
disp('  .')

%%% step 2: generate figures and text files
disp('  Step 2: generating figures and text summary')
a02_snowtoday_figs_textfiles_control;
disp('  ... DONE!')
disp('  .')

%%% step 3: transfer images to nusnow
disp('  Step 3: transferring to NSIDC')
a03_snow_station_figure_transfer;
disp('  ... DONE!')
disp('  .')

%%% step 4: move images to PetaLibrary archive
disp('  Step 4: moving images to PetaLibrary')
a04_snow_station_image_archive;
disp('  ... DONE!')
disp('  .')

%%% step 5: move text summaries to PetaLibrary archive
disp('  Step 5: transferring text summaries to NSIDC and archiving to PetaLibrary')
a05_snow_station_data_access;
disp('  ... DONE!')
disp('  .') 

%%% step 6: write state/huc summaries to PL
disp('  Step 6: writing year-to-date SWE summaries by state and HUC')
a06_snow_station_AOI_summary;
disp('  ... DONE!')
disp('  .') 

%%% step 7: create animations of dSWE and clim SWE for month to date
disp('  Step 7: generating animations of dSWE and clim SWE for month to date')
a07_snow_station_animate;
disp('  ... DONE!')
disp('  .') 