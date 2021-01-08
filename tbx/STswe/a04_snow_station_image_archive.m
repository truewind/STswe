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

        %%% move to archive
        path_dest = fullfile(path_PL_archive, ShortName);
        
        try
            movefile(fullfile(path_staging, iname), path_dest);
        catch
            % if no folder setup, then issue warning and delete the png
            disp(['No destination setup at: ' path_dest])
            disp('... deleting the .png')
            delete(fullfile(path_staging, iname))
        end
    end
    
end