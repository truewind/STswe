clear; clc; close all

%%% this script creates animations based on existing png files of daily
%%% dSWE and normSWE (climSWE)

%% setup

review_regions = {'USwest', 'USAK', 'CABC'};   % which regions to create animations?
review_type = {'dSWE', 'normSWE'};             % variables
nregions = numel(review_regions);
ntype = numel(review_type);

%% loading

%%% load settings
snowtoday_settings;

%% time

% xSD = floor(now);
xSD = datenum(2023,1,25);
[review_yr,review_mo,~,~,~,~] = datevec(xSD);

%% cycle through and create animations

for iregion=1:nregions
    region_str = char(review_regions(iregion));

    for itype=1:ntype
        type_str = char(review_type(itype));

        %%% get yyyymm str
        yyyymm = datestr(datenum(review_yr, review_mo,1), 'yyyymm');

        %%% path to images for that region
        file_path = fullfile(path_PL_archive, region_str);
        fpathwild = fullfile(path_PL_archive, region_str, [yyyymm '*' char(type_str) '.png']);
        D = dir(fpathwild);


        % select images in folder, save output gif (dswe_2020april), no loops, 0.75
        % sec between, no different delay for first/last
        image2animation_auto;



    end
end
