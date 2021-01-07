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
        
        %%% get shortname from filename (between 2nd and 3rd underscores)
        a = find(iname=='_');
        uscore2 = a(2);
        uscore3 = a(3);
        ShortName = iname(uscore2+1:uscore3-1);

        %%% transfer to nusnow via scp and using SSH key
        system(['scp -i ' char(path_ssh_key) ' ' fullfile(path_staging, iname) ' snow_today@nusnow.colorado.edu:/disks/sidads_staging/incoming/snow_today/' ShortName '/']);
        
        %%% move to archive
        movefile(fullfile(path_staging, iname), path_PL_archive);
    end
    
end