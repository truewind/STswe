% a01a_snow_station_data_download.m
clear; close all; 

% This script downloads SWE data from the NRCS and CDWR networks and then
% merges them into a single database
%
% Code written by Mark Raleigh (raleigma@oregonstate.edu)

%% load common settings

% execute snowtoday_settings.m script, which should be configured upon 
% first usage 
snowtoday_settings;

%% other settings (do not change)

% data units (0=metric, 1=english) for the downloaded SWE data in the database
IMPORT_OPTS.UNITS = 0;      % we will use metric. see snowtoday_settings.m to change the units for the figures, text files

%% check for latest NRCS, CDWR SWE data. download and update databases

flag_update= [0 0 0];  % set flags to keep track of whether new data are downloaded (1=yes, 0=no)

%%% loop through the networks
for j=1:3
    % j=1 NRCS SNOTEL
    % j=2 CDWR snow pillow
    % j=3 Canada (BC) snow pillows
    
    if j==1
        IMPORT_OPTS.SITES = {'SNTL'};
        IMPORT_OPTS.OBS = {'WTEQ'};
        name_database = nrcs_database;
    elseif j==2
        IMPORT_OPTS.SITES = {'ALL'};
        IMPORT_OPTS.OBS = 82;  % 82=Snow, water content (Revised)
        name_database = cdwr_database;
    elseif j==3
        IMPORT_OPTS.SITES = 'SNOW';         % select SNOTEL network
        IMPORT_OPTS.STATEPROV = 'BC';       % select a specific state (optional)
        IMPORT_OPTS.OBS = {'WTEQ'};         % select variables
        name_database = canada_database;
    end
    
    
    if exist(name_database, 'file')==2
        %%% then a database exists for this network. load it.
        load(name_database)
        
        %%% store a copy of the data, to make it the same regardless of
        %%% network
        if j==1 || j==3
            SNOW=NRCS;
        elseif j==2
            SNOW=CDWR;
        end
        
        %%% check if we should look for new data
        flag_needsUpdate = 0;
        if time_end>SNOW.TIME(end,sdate_col)
            flag_needsUpdate = 1;
        else
            %%% check completeness of data in the last record
            SWE2 = SNOW.WTEQ_mm(end,:);
            SWE2 = ~isnan(SWE2); % 1=data, 0=nans
            
            if (nansum(SWE2, 'all'))./(numel(SWE2))<minSTAdata
                % then the final row is missing lots of data. try
                % downloading this again
                flag_needsUpdate = 1;
                time_end = SNOW.TIME(end,sdate_col);
                SNOW.TIME = SNOW.TIME(1:end-1,:);
                SNOW.WTEQ_mm = SNOW.WTEQ_mm(1:end-1,:);
            end
        end
        
        
        if flag_needsUpdate==1
            %%% then the database is not up to date. 
            disp([name_database ' is not up to date... downloading additional data'])
            
            %%%define time period for a new download
            IMPORT_OPTS.TPERIOD = [SNOW.TIME(end,sdate_col) time_end];
            
            if diff(IMPORT_OPTS.TPERIOD)==0
                %%% a single time step seems to present problems in the
                %%% CDWR download. move the first date a little earlier
                %%% (Say, 5 days)
                IMPORT_OPTS.TPERIOD(1) = IMPORT_OPTS.TPERIOD(1)-5;
            end
            
            %%% import the latest data
            if j==1 || j==3
                SNOW2 = import_nrcs(IMPORT_OPTS);
            elseif j==2
                SNOW2 = import_cdwr(IMPORT_OPTS);
            end
            flag_update(j)=1;
            
            %%% update newest time and SWE records. Use overlap at last
            %%% time step.
            a = find(SNOW2.TIME(:,sdate_col)==SNOW.TIME(end,sdate_col));
            SNOW.TIME = [SNOW.TIME(1:end-1,:); SNOW2.TIME(a:end,:)];
            SNOW.WTEQ_mm = [SNOW.WTEQ_mm(1:end-1,:); SNOW2.WTEQ_mm(a:end,:)];
            
            %%% save the updated database
            if j==1
                NRCS = SNOW;
                save(name_database, 'NRCS');
            elseif j==2
                CDWR = SNOW;
                save(name_database, 'CDWR');
            elseif j==3
                CA_SNOW = SNOW;
                save(name_database, 'CA_SNOW');
            end
            
        else
            disp([name_database ' is up to date'])
        end
    else
        %%% then it does not exist at all
        disp([name_database ' does not exist! Initiating download now.'])
        
        %%% define the time period
        IMPORT_OPTS.TPERIOD = [time_start time_end];
        
        %%% download and save
        if j==1
            NRCS = import_nrcs(IMPORT_OPTS);
            save(name_database, 'NRCS');
        elseif j==2
            CDWR = import_cdwr(IMPORT_OPTS);
            save(name_database, 'CDWR');
        elseif j==3
            CA_SNOW = import_nrcs(IMPORT_OPTS);
            save(name_database, 'CA_SNOW');
        end
        flag_update(j)=1;
        
    end
    
    clear SNOW
end

%% merge all networks into a single structure (the ALL database)

if exist(all_database, 'file')~=2 || nanmax(flag_update)==1
    disp(' ... merging NRCS, CDWR, and Canadian snow pillows into single database')
    
    %%% load the databases
    load(nrcs_database)
    load(cdwr_database)
    load(canada_database)
    
    %%% build the merged dataset manually
    t1 = nanmin([NRCS.TIME(:,sdate_col); CDWR.TIME(:,sdate_col); CA_SNOW.TIME(:,sdate_col)]);
    t2 = nanmax([NRCS.TIME(:,sdate_col); CDWR.TIME(:,sdate_col); CA_SNOW.TIME(:,sdate_col)]);
    SNOW.TIME = time_builder((t1:1:t2)'); % need to change to be flexible to timestep!
    ntime = size(SNOW.TIME,1);
    
    nsta_nrcs = size(NRCS.WTEQ_mm,2);
    nsta_cdwr = size(CDWR.WTEQ_mm,2);
    nsta_canada = size(CA_SNOW.WTEQ_mm,2);
    nsta = nsta_nrcs+nsta_cdwr+nsta_canada;
    
    SNOW.WTEQ_mm = nan(ntime,nsta);
    SNOW.STA_LON = nan(1,nsta);
    SNOW.STA_LAT = nan(1,nsta);
    SNOW.STA_ELEV_m = nan(1,nsta);
    SNOW.STA_NAME = cell(1,nsta);
    SNOW.STA_ID = cell(1,nsta);
    
    %%% bring in the NRCS data into the main SNOW structure
    [~,ia,ib]=intersect(SNOW.TIME(:,sdate_col), NRCS.TIME(:,sdate_col));
    i1 = 1;
    i2 = nsta_nrcs;
    SNOW.WTEQ_mm(ia,i1:i2) = NRCS.WTEQ_mm(ib,:);
    SNOW.STA_LON(1,i1:i2) = NRCS.STA_LON;
    SNOW.STA_LAT(1,i1:i2) = NRCS.STA_LAT;
    SNOW.STA_ELEV_m(1,i1:i2) = NRCS.STA_ELEV_m;
    SNOW.STA_NAME(1,i1:i2) = NRCS.STA_NAME;
    % combine sta_IDs into single datatype (cellstr)
    for j=1:nsta_nrcs
        if isnumeric(NRCS.STA_ID(j))==1
            SNOW.STA_ID(1,j) = cellstr(num2str(NRCS.STA_ID(j)));
        elseif iscellstr(NRCS.STA_ID(j))==1
            SNOW.STA_ID(1,j) = NRCS.STA_ID(j);
        else
            error('unexpected data type for NRCS STA_ID')
        end
    end
    
    %%% bring in the CDWR data into the main SNOW structure
    [~,ia,ib]=intersect(SNOW.TIME(:,sdate_col), CDWR.TIME(:,sdate_col));
    i1 = i2+1;
    i2 = nsta_nrcs+nsta_cdwr;
    SNOW.WTEQ_mm(ia,i1:i2) = CDWR.WTEQ_mm(ib,:);
    SNOW.STA_LON(1,i1:i2) = CDWR.STA_LON;
    SNOW.STA_LAT(1,i1:i2) = CDWR.STA_LAT;
    SNOW.STA_ELEV_m(1,i1:i2) = CDWR.STA_ELEV_m;
    SNOW.STA_NAME(1,i1:i2) = CDWR.STA_NAME;
    % combine sta_IDs into single datatype (cellstr)
    for j=1:nsta_cdwr
        if isnumeric(CDWR.STA_ID(j))==1
            SNOW.STA_ID(1,nsta_nrcs+j) = cellstr(num2str(CDWR.STA_ID(j)));
        elseif iscellstr(CDWR.STA_ID(j))==1
            SNOW.STA_ID(1,nsta_nrcs+j) = CDWR.STA_ID(j);
        else
            error('unexpected data type for CDWR STA_ID')
        end
    end

    %%% bring in the Canada snow data into the main SNOW structure
    [~,ia,ib]=intersect(SNOW.TIME(:,sdate_col), CA_SNOW.TIME(:,sdate_col));
    i1 = i2+1;
    i2 = nsta;
    SNOW.WTEQ_mm(ia,i1:i2) = CA_SNOW.WTEQ_mm(ib,:);
    SNOW.STA_LON(1,i1:i2) = CA_SNOW.STA_LON;
    SNOW.STA_LAT(1,i1:i2) = CA_SNOW.STA_LAT;
    SNOW.STA_ELEV_m(1,i1:i2) = CA_SNOW.STA_ELEV_m;
    SNOW.STA_NAME(1,i1:i2) = CA_SNOW.STA_NAME;
    % combine sta_IDs into single datatype (cellstr)
    for j=1:nsta_canada
        if isnumeric(CA_SNOW.STA_ID(j))==1
            SNOW.STA_ID(1,nsta_nrcs+j) = cellstr(num2str(CA_SNOW.STA_ID(j)));
        elseif iscellstr(CA_SNOW.STA_ID(j))==1
            SNOW.STA_ID(1,nsta_nrcs+j) = CA_SNOW.STA_ID(j);
        else
            error('unexpected data type for Canadian STA_ID')
        end
    end
    
    %%% now only keep stations that have some data
    good_sta = ~isnan(SNOW.WTEQ_mm);
%     good_sta = abs(good_sta-1);
    good_sta = nansum(good_sta);
    good_sta = find(good_sta>0);     % indices of stations w/ SWE data (non-NaN)
    
    %%% subset to the good stations
    FN = fieldnames(SNOW);
    for j=1:numel(FN)
        FX = char(FN(j));
        
        if strcmp(FX, 'TIME')==1
            % skip time
        else
%             eval(['SNOW.' FX '=SNOW.' FX '(:,good_sta);'])
            %%% testing this convention
            srcInfo = SNOW.(FX);
            SNOW.(FX) = srcInfo(:,good_sta);
        end
    end
    
    
    %%% check completeness of the combined NRCS and CDWR data in the last record
    missing_recent = 0;
    SWE2 = SNOW.WTEQ_mm(end,:);
    SWE2 = ~isnan(SWE2);
%     SWE2 = abs(SWE2-1);
    
    if (nansum(SWE2, 'all'))./(numel(SWE2))<minSTAdata
        % then the final row is missing lots of data from both networks
        missing_recent = missing_recent+1;
    end

    if missing_recent>0
        %%% then remove the last row
        SNOW.TIME = SNOW.TIME(1:end-1,:);
        SNOW.WTEQ_mm = SNOW.WTEQ_mm(1:end-1,:);
    end
    
    %%% save the merged database
    save(all_database, 'SNOW');
end

