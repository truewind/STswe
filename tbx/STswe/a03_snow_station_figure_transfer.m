clear;
close all;

%% loading

%%% load settings
snowtoday_settings;

%%

%%% look for .png image files in the staging directory
D = dir(fullfile(path_staging, '*.png'));

%%% if found any, transfer to nusnow
if isempty(D)==0
    nfiles = size(D,1);
    
    for j=1:nfiles
        %%% get current filename
        iname = char(D(j).name);
        
        %%% transfer to nusnow via scp and using SSH key
        system(['scp -i ' char(path_ssh_key) ' ' fullfile(path_staging, iname) ' snow_today@nusnow.colorado.edu:/disks/sidads_staging/incoming/snow_today/']); % need to break out nsidc user/domain/path and place in settings
    end
    
end
