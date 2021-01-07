clear;
close all;

%% loading

%%% load settings
snowtoday_settings;

%%% setup the spatial settings based on Areas of Interest
snowtoday_spatial;

%%

%%% look for .png image files in the staging directory
D = dir(fullfile(path_staging, '*.png'));

%%% if found any, transfer to nusnow
if isempty(D)==0
    nfiles = size(D,1);
    
    for j=1:nfiles
        %%% get current filename
        iname = char(D(j).name);
        
        %%% get shortname from filename (between 2nd and 3rd underscores)
        a = find(iname=='_');
        uscore2 = a(2);
        uscore3 = a(3);
        ShortName = iname(uscore2+1:uscore3-1);

        %%% transfer to nusnow via scp and using SSH key
        system(['scp -i ' char(path_ssh_key) ' ' fullfile(path_staging, iname) ' snow_today@nusnow.colorado.edu:/disks/sidads_staging/incoming/snow_today/' ShortName '/']); % need to break out nsidc user/domain/path and place in settings
    end
    
end

