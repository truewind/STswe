clear; close all;


for super_reg = 0:3
    % where
    %   super_reg = 0 is original, all sites
    %   super_reg = 1 is western US (lower 48) only
    %   super_reg = 2 is Alaska
    %   super_reg = 3 is Canada

    %% loading

    %%% load settings
    snowtoday_settings;

    %%% load the database
    load(all_database);

    %%% load temp files w/ snow analysis
    load('temp_climSWE.mat')
    iYR2 = iYR; iMO2 = iMO; iDA2 = iDA;

    load('temp_dSWE.mat')
    if iYR~=iYR2 || iMO2~=iMO || iDA~=iDA2
        disp('WARNING: Dates do not match up for dSWE and climSWE for the daily text summary')
    end

    load('temp_percentPeakSWE.mat')
    if iYR~=iYR2 || iMO2~=iMO || iDA~=iDA2
        disp('WARNING: Dates do not match up for percentPeakSWE and climSWE for the daily text summary')
    end

    %% prep

    YYYYMMDD = datestr(datenum(iYR,iMO,iDA), 'yyyymmdd');

    %%% only keep sites in our domain
    keepSTA = nan.*dSWE;
    if super_reg==0
        super_filename=['SnowToday_USwest_' YYYYMMDD '_SWEsummary.txt'];
        %%% all
        for j=1:numel(keepSTA)
            if numel(char(SNOW.STA_HUC02{j}))>1 || numel(char(SNOW.STA_STATE{j}))>1
                keepSTA(j)=1;
            else
                keepSTA(j)=0;
            end
        end
    elseif super_reg==1
        super_filename= '26000.csv';
        %%% western US lower 48
        for j=1:numel(keepSTA)

            if numel(char(SNOW.STA_HUC02{j}))>1 || numel(char(SNOW.STA_STATE{j}))>1
                if strcmp(SNOW.STA_STATE{j}, 'USAK')==1 || strcmp(SNOW.STA_STATE{j}, 'CABC')==1
                    keepSTA(j)=0;
                else
                    keepSTA(j)=1;
                end
            else
                keepSTA(j)=0;
            end

        end
    elseif super_reg==2
        super_filename= '26100.csv';
        %%% Alaska
        for j=1:numel(keepSTA)
            if strcmp(SNOW.STA_STATE{j}, 'USAK')==1
                keepSTA(j)=1;
            else
                keepSTA(j)=0;
            end
        end
    elseif super_reg==3
        super_filename= '26101.csv';
        %%% Canada BC
        for j=1:numel(keepSTA)
            if strcmp(SNOW.STA_STATE{j}, 'CABC')==1
                keepSTA(j)=1;
            else
                keepSTA(j)=0;
            end
        end
    end

    keepSTA = find(keepSTA==1);
    Name = SNOW.STA_NAME(keepSTA);
    State = SNOW.STA_STATE(keepSTA);
    Lat = SNOW.STA_LAT(keepSTA);
    Lon = SNOW.STA_LON(keepSTA);
    Elev_m = SNOW.STA_ELEV_m(keepSTA);
    climSWE = SWE_pnrm(keepSTA);
    dSWE = dSWE(keepSTA);
    HUC02 = SNOW.STA_HUC02(keepSTA);
    HUC04 = SNOW.STA_HUC04(keepSTA);

    %% write file with all stations for this date

    
    filepath_SWEsummary = fullfile(path_staging, super_filename);
    fid = fopen(filepath_SWEsummary, 'w');

    
    %%% shifted header to the top
    fprintf(fid, '%s\n', ['SnowToday Calculated SWE Summary Data : ' datestr(datenum(iYR,iMO,iDA), 'yyyy-mm-dd')]);
    fprintf(fid, '%s\n', 'Column01 : site name');
    fprintf(fid, '%s\n', 'Column02 : latitude');
    fprintf(fid, '%s\n', 'Column03 : longitude');
    fprintf(fid, '%s\n', 'Column04 : elevation');
    fprintf(fid, '%s\n', ['Column05 : SWE (' units_figs_text ')']);
    fprintf(fid, '%s\n', 'Column06 : percent of median long-term (25+yr) SWE on this date');
    fprintf(fid, '%s\n', 'Column07 : percent of long-term (25+yr) peak SWE');
    fprintf(fid, '%s\n', ['Column08 : daily change in SWE (' units_figs_text ')']);
    fprintf(fid, '%s\n', 'Column09 : State');
    fprintf(fid, '%s\n', 'Column10 : HUC02');
    fprintf(fid, '%s\n', 'Column11 : HUC04');

    fprintf(fid,'%s\n', 'Name,Lat,Lon,Elev_m,SWE,normSWE,percentPeakSWE,dSWE,State,HUC02,HUC04');
    head_str = '%s,%.4f,%.4f,%.1f,%.1f,%.1f,%.1f,%.1f,%s,%s,%s\n';
    for j=1:numel(keepSTA)
        %%% HUC02
        if isempty(HUC02{j})==0
            H2=char(HUC02(j));
        else
            H2='N/A';
        end

        %%% HUC04
        if isempty(HUC04{j})==0
            H4=char(HUC04(j));
        else
            H4='N/A';
        end


        fprintf(fid, head_str, char(Name(j)), Lat(j), Lon(j), Elev_m(j), SWEc(j), climSWE(j), SWE_percentPeakSWE(j), dSWE(j), char(State(j)), H2, H4);
    end

    fclose(fid);

    %%% for consistency, check if any "N/A" values and replace with "NaN"
    find_and_replace(filepath_SWEsummary, 'N/A', 'NaN');

    %%% clear all except super_reg loop variable
    clearvars -except super_reg

end
