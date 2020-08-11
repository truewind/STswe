clear;
close all;

% note: lets merge this with a03 (nsidc/nusnow transfer) since very similar
% logic and utility. do this later.

%% loading

%%% load settings
snowtoday_settings;

%%

%%% look at files in the staging directory
D = dir([fullfile(path_staging, '*.png')]);

%%% move to PL archive
if isempty(D)==0
    nfiles = size(D,1);
    
    for j=1:nfiles
        %%% get current filename
        iname = char(D(j).name);
        
        %%% move to archive
        movefile(fullfile(path_staging, iname), path_PL_archive);
    end
    
end