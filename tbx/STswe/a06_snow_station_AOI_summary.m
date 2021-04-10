
clear;
close all;

% this script creates year-to-date summaries by state and HUC2 for climSWE
% and dSWE and posts them on the petalibrary as text files

%% loading

%%% load settings
snowtoday_settings;


%%% setup the spatial settings based on Areas of Interest
snowtoday_spatial;

%%

%%% get current WY
[Y,M,~,~,~,~]=datevec(now);
if M>=10
    iWY = Y+1;
else
    iWY = Y;
end

%%% look at daily files in the SWEsummary directory on 
path_dest = fullfile(path_PL_text_data, ['WY' num2str(iWY)], 'SWESummary');
D = dir([fullfile(path_dest, '*_SWEsummary.txt')]);

%%

if isempty(D)==0
    nfiles = size(D,1);
    
    %%% initialize
    summary_dSWE = nan(nfiles,7,nAOI);
    summary_normSWE = nan(nfiles,7,nAOI);
    
    for j=1:nfiles
        %%% get current filename
        iname = char(D(j).name);
        
        %%% get YYYYMMDD from filename (between 2nd and 3rd underscores)
        a = find(iname=='_');
        uscore2 = a(2);
        uscore3 = a(3);
        YYYYMMDD = iname(uscore2+1:uscore3-1);
        sdate= datenum(YYYYMMDD, 'yyyymmdd');
        dowy = sdate-datenum(iWY-1,10,1)+1;
        
        %%% read the file as a table
        fname = fullfile(path_dest, iname);
        T = readtable(fname);
        State = table2cell(T(:,2));
        HUC02 = table2cell(T(:,8));
        normSWE = T{:,6};
        dSWE = T{:,7};
        
        for k=1:nAOI
            ShortName = char(AOI.ShortName(k));
            a=find(strcmp(State, ShortName)==1);
            
%             flag_state_huc = 0; % 0=unknown, 1=state, 2 =huc02
%             if isempty(a)==0
%                 flag_state_huc = 1;
%             else
%                 a=find(strcmp(HUC02, ShortName)==1);
%                 if iesmpty(a)==0
%                     flag_state_huc = 2;
%                 end
%             end
            
            %%% build data matrices
            % day_of_water_year,min_dSWE,prc25_dSWE,median_dSWE,prc75_dSWE,max_dSWE,average_dSWE
            summary_dSWE(j,1,k) = dowy;
            summary_normSWE(j,1,k) = dowy;
            if isempty(a)==0
                summary_dSWE(j,2,k) = nanmin(dSWE(a));
                summary_dSWE(j,3,k) = prctile(dSWE(a),25);
                summary_dSWE(j,4,k) = prctile(dSWE(a),50);
                summary_dSWE(j,5,k) = prctile(dSWE(a),75);
                summary_dSWE(j,6,k) = nanmax(dSWE(a));
                summary_dSWE(j,7,k) = nanmean(dSWE(a));
                
                summary_normSWE(j,2,k) = nanmin(normSWE(a));
                summary_normSWE(j,3,k) = prctile(normSWE(a),25);
                summary_normSWE(j,4,k) = prctile(normSWE(a),50);
                summary_normSWE(j,5,k) = prctile(normSWE(a),75);
                summary_normSWE(j,6,k) = nanmax(normSWE(a));
                summary_normSWE(j,7,k) = nanmean(normSWE(a));
            end
            
            
        end
        
    end
    
    
    %%% write files
    head_str_dSWE = 'day_of_water_year,min_dSWE,prc25_dSWE,median_dSWE,prc75_dSWE,max_dSWE,average_dSWE';
    head_str_normSWE = 'day_of_water_year,min_normSWE,prc25_normSWE,median_normSWE,prc75_normSWE,max_normSWE,average_normSWE';
    col_fmt = '%i,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f\n';
    
    for k=1:nAOI
        ShortName = char(AOI.ShortName(k));
        
        %%% filenames
        filepath_dSWE = fullfile(path_staging, ['SnowToday_' ShortName '_dSWE_WY' num2str(iWY) '_yearToDate.txt']);
        filepath_normSWE = fullfile(path_staging, ['SnowToday_' ShortName '_normSWE_WY' num2str(iWY) '_yearToDate.txt']);
        
        %%%write files (dSWE)
        fid = fopen(filepath_dSWE, 'w');
        fprintf(fid,'%s\n', head_str_dSWE);
        for j=1:nfiles
            fprintf(fid, col_fmt, squeeze(summary_dSWE(j,:,k)));
        end
        fclose(fid);
        
        %%%write files (normSWE)
        fid = fopen(filepath_normSWE, 'w');
        fprintf(fid,'%s\n', head_str_normSWE);
        for j=1:nfiles
            fprintf(fid, col_fmt, squeeze(summary_normSWE(j,:,k)));
        end
        fclose(fid);
        
        
    end
end

