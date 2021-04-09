clear;
close all;

% this script transfers all text files to the public access location on the
% petalibrary

%% loading

%%% load settings
snowtoday_settings;

%%

%%% look at files in the staging directory
D = dir([fullfile(path_staging, '*.txt')]);

%%% move to PL archive
if isempty(D)==0
    nfiles = size(D,1);
    
    for j=1:nfiles
        %%% get current filename
        iname = char(D(j).name);
        
        %%% get YYYYMMDD from filename (between 2nd and 3rd underscores)
        a = find(iname=='_');
        uscore2 = a(2);
        uscore3 = a(3);
        YYYYMMDD = iname(uscore2+1:uscore3-1);
        [Y,M,~,~,~,~]=datevec(datenum(YYYYMMDD, 'yyyymmdd'));
        if M>=10
            iWY = Y+1;
        else
            iWY = Y;
        end
        
        %%% move to archive
        path_dest = fullfile(path_PL_archive, ['WY' num2str(iWY)], 'SWESummary');
        if exist(path_dest,'dir')==7
        else
            mkdir(path_dest);
        end
        
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