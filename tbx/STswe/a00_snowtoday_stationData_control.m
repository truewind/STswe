clear;
clc;
close all;

%% Snow pillows

disp('SNOW STATIONS')

%%% step 1a: download latest snow station data
disp('  Step 1: downloading data')
a01a_snow_station_data_download;

%%% step 1b: QC the merged database
a01b_snow_station_data_QC;
disp('  ... DONE!')
disp('  .')

%%% step 2a: generate plot for daily change in SWE (dSWE)
disp('  Step 2: generating figures')
a02a_snow_station_map_dSWE;

%%% step 2b: generate plot for daily SWE percent of median
a02b_snow_station_climSWE;
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
