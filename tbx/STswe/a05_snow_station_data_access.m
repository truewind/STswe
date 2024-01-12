clear;
close all;

% this script transfers all text files to the public access location on the
% petalibrary

%% loading

%%% load settings
snowtoday_settings;

%%

%%% look at files in the staging directory
D1 = dir([fullfile(path_staging, '*_SWEsummary.txt')]);  % our original txt file 
D2 = dir([fullfile(path_staging, '*.csv')]);             % new format for nsidc by super region
D = [D1; D2];   % merge into single listing


%%% keep track of number of files transferred to nusnow
files_transferred = 0;

%%% move to PL archive
if isempty(D)==0
    nfiles = size(D,1);
    
    for j=1:nfiles
        %%% get current filename
        iname = char(D(j).name);

        if strcmp(iname(end-2:end), 'txt')==1
            %%% original txt file format
            flag_format = 1;
        else
            %%%% new csv file format by super region
            flag_format = 0;
        end

        if flag_format==1
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
            path_dest = fullfile(path_PL_text_data, ['WY' num2str(iWY)], 'SWESummary');
            if exist(path_dest,'dir')==7
            else
                mkdir(path_dest);
            end
        end


        try
            %%% transfer to nusnow via scp and using SSH key
            system(['scp -i ' char(path_ssh_key) ' ' fullfile(path_staging, iname) ' snow_today@nusnow.colorado.edu:' path_nusnow_swe]);

            %%% add to tally of files transferred
            files_transferred = files_transferred + 1;
            
            if flag_format==1
                %%% archive to PL
                movefile(fullfile(path_staging, iname), path_dest);
            else
                delete(fullfile(path_staging, iname))
            end
        catch
            % if no folder setup, then issue warning and delete the png
            disp(['No destination setup at: ' path_dest])
            disp('... deleting the .txt')
            delete(fullfile(path_staging, iname))
        end
    end
    
end

%%% if files were transferred to nusnow, create a TRIGGER file and transfer it too
if files_transferred>0
    %%% create trigger file
    pathfile_trigger = fullfile(path_staging, 'TRIGGER'); % build string for filepath to TRIGGER
    system(['touch ' char(pathfile_trigger)]);  % create the file with touch
    
    %%% transfer to nusnow via scp and using SSH key
    system(['scp -i ' char(path_ssh_key) ' ' pathfile_trigger ' snow_today@nusnow.colorado.edu:' path_nusnow_swe]);
    disp('.... transferred TRIGGER file to NuSnow')
    
    %%% delete the TRIGGER file
    delete(pathfile_trigger);
end

