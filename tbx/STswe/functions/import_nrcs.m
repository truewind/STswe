% Imports NRCS data (e.g., SNOTEL, SCAN) into Matlab from the internet
% based on the NRCS Report Generator (http://www.wcc.nrcs.usda.gov/reportGenerator/)
%
% RELEASE NOTES
%   Written by Mark Raleigh, November 2015 (mraleig1@gmail.com)
%
% SYNTAX
%   NRCS = import_nrcs(IMPORT_OPTS)
%
% INPUTS
%   IMPORT_OPTS = structure of import options, where fields include:
%       SITES = either list of site numbers or character string of all
%               networks that you want ('SNTL', 'SNOW', 'SCAN', or 'ALL')
%                   where   'SNTL' = NRCS SNOTEL
%                           'SNOW' = non-NRCS sites (like CA DWR) that have data posted to the NRCS site
%                           'SCAN' = NRCS SCAN
%                           'ALL' = all sites
%       STATEPROV = (optional) as character string, enter two letter 
%                   state/province that you want to subset, for example:
%                            'AK' = Alaska
%                            'BC' = British Columbia
%                            'CA' = California
%                               .... etc.
%       OBS =  cellstring of observations to retrieve
%                Some possible names  include:
%                   WTEQ = snow water equivalent
%                   SNWD = snow depth
%                   TOBS = observed air temperature (instantaneous)
%                   TAVG = average air temperature
%                   TMAX = maximum air temperature
%                   TMIN = minimum air temperature
%                   PREC = accumulated WY precipitation
%                   PRCP = incremental precipitation
%                   PRCPSA = incremental precipitation (adjusted by snow obs)
%       FREQ = character or cell string with desired frequency.  Some
%              possible values include:
%                   'daily' (default)
%                   'hourly'
%       TPERIOD =  2 element array of serial dates defining begin and
%                   ends dates
%       UNITS = enter 0 for metric (default) or 1 for english
%       MAX_INT = maximum interpolation length (hours) during gridding (default = 2 hrs, enter 0 to turn off)
%
% OUTPUTS
%   NRCS = structure with outputs and station metadata
%
% EXAMPLES
%   (1) Download all daily SWE and average temperature data from Alaska
%   SNOTEL sites from Oct 1, 2000 - June 5 2022
% 
%       IMPORT_OPTS.SITES = 'SNTL';         % select SNOTEL network
%       IMPORT_OPTS.STATEPROV = 'AK';       % select a specific state (optional)
%       IMPORT_OPTS.OBS = {'WTEQ', 'TAVG'}; % select variables
%       IMPORT_OPTS.FREQ = 'daily';         % select timestep
%       IMPORT_OPTS.TPERIOD = [datenum(2000,10,1) datenum(2022,6,5)]; % select start/end dates (as matlab serial dates)
%       IMPORT_OPTS.UNITS = 0;              % select 0 for metric units
%       IMPORT_OPTS.MAX_INT = 0;            % turn off interpolation for  missing data
%       NRCS = import_nrcs(IMPORT_OPTS);    % download the data


function NRCS = import_nrcs(IMPORT_OPTS)

%% Checks

if isfield(IMPORT_OPTS, 'SITES')~=1 || isfield(IMPORT_OPTS, 'OBS') ~=1 || isfield(IMPORT_OPTS, 'TPERIOD') ~=1
    error('missing fields in input structure IMPORT_OPTS')
end

if isfield(IMPORT_OPTS, 'FREQ')~=1
    IMPORT_OPTS.FREQ = 'daily';
    dt = 24;
else
    if strcmp(char(IMPORT_OPTS.FREQ), 'daily')==1
        dt=24;
    elseif strcmp(char(IMPORT_OPTS.FREQ), 'hourly')==1
        dt=1;
    else
        error('The code has not been configured to accept that temporal frequency')
    end
end

if isfield(IMPORT_OPTS, 'UNITS')~=1
    IMPORT_OPTS.UNITSstr = ',metric';
    IMPORT_OPTS.UNITS = 0;
else
    if IMPORT_OPTS.UNITS==0
        IMPORT_OPTS.UNITSstr = ',metric';
    else
        IMPORT_OPTS.UNITSstr = '';
    end
end

if isfield(IMPORT_OPTS, 'MAX_INT')~=1
    IMPORT_OPTS.MAX_INT = 2;
end

%% Code

%%%% (1) METADATA AND SITE IDENTIFICATION
disp('Reading site list and retrieving metadata')

%%% first get list of site metadata for NRCS networks (will need different read function for Linux machines)
try
    [NRCS_num,NRCS_txt,NRCS_raw] = xlsread('NRCS_Sites.csv');
catch
    [NRCS_num,NRCS_txt,NRCS_raw] = xlsread('NRCS_Sites.xlsx');     % try Excel version
end

%%% populate the list of station numbers
if isnumeric(IMPORT_OPTS.SITES)==1
    %%% site numbers were entered
    if size(IMPORT_OPTS.SITES,2)==1
        NRCS.STA_ID = IMPORT_OPTS.SITES';
    else
        NRCS.STA_ID = IMPORT_OPTS.SITES;
    end
    ID_num_txt = ones(1,numel(NRCS.STA_ID));
else
    
    %%% then a network was selected
    if strcmp(char(IMPORT_OPTS.SITES), 'ALL')==1
        %         NRCS.STA_ID = NRCS_num(:,1)';
        NRCS.STA_ID = cell(1,size(NRCS_raw,1));
        ID_num_txt = zeros(1,size(NRCS_raw,1)); %  1 if site ID is number (NRCS), 0 if text (Calif.)
        
        for j=1:numel(NRCS.STA_ID)
            % convert all sta IDs to cell str
            cID=cell2mat(NRCS_raw(j,4));
            if isnumeric(cID)==1
                cID = num2str(cID);
                ID_num_txt(j) = 1;
            elseif ischar(cID)==1
                % dont do anything
                ID_num_txt(j) = 0;
            else
                error('unexpected data type')
            end
            NRCS.STA_ID(1,j) = cellstr(cID);
        end
        STATEPROV = NRCS_txt(:,2);
    elseif strcmp(char(IMPORT_OPTS.SITES), 'SNTL')==1 || strcmp(char(IMPORT_OPTS.SITES), 'SNOTEL')==1
        a = find(strcmp(NRCS_txt(:,1), cellstr('SNTL'))==1);
        NRCS.STA_ID = NRCS_num(a,1)';
        STATEPROV = NRCS_txt(a,2);
        ID_num_txt = ones(1,numel(a));
    elseif strcmp(char(IMPORT_OPTS.SITES), 'SCAN')==1
        a = find(strcmp(NRCS_txt(:,1), cellstr('SCAN'))==1);
        NRCS.STA_ID = NRCS_num(a,1)';
        STATEPROV = NRCS_txt(a,2);
        ID_num_txt = ones(1,numel(a));
    elseif strcmp(char(IMPORT_OPTS.SITES), 'SNOW')==1
        a = find(strcmp(NRCS_txt(:,1), cellstr('SNOW'))==1);
        NRCS.STA_ID = NRCS_txt(a,4)'; % different convention for calif.
        STATEPROV = NRCS_txt(a,2);
        ID_num_txt = zeros(1,numel(a));
    else
        error('invalid site identifier')
    end
    


    %%% check if specific state/province was selected, and if so, narrow down
    if isfield(IMPORT_OPTS, 'STATEPROV')==1
        a = find(strcmp(STATEPROV, char(IMPORT_OPTS.STATEPROV))==1);
        NRCS.STA_ID = NRCS.STA_ID(a);
        ID_num_txt = ones(1,numel(a));
    end
    
end


%%% append NaN row to end of NRCS_txt and NRCS_num (must do this after
%%% previous task of populating list of station numbers)
NRCS_num(end+1,:) = NaN;
NRCS_txt(end+1,:) = cellstr('NaN');
nan_row = size(NRCS_num,1);

%%% get site metadata
nsta = numel(NRCS.STA_ID);
sta_indices = zeros(1,nsta)*NaN;


for j=1:nsta
    % find this site in the master list
    if ID_num_txt(j)==1
        if iscellstr(NRCS.STA_ID(j))==1
            
            sfind = find(NRCS_num(:,1)==str2double(NRCS.STA_ID(j)));
            
            if isempty(sfind)==1
                sfind = find(strcmp(NRCS_txt(:,4),char(NRCS.STA_ID(j)))==1);
            end
                
        elseif isnumeric(NRCS.STA_ID(j))==1
            sfind = find(NRCS_num(:,1)==NRCS.STA_ID(j));
        else
            error('unexpected data type')
        end
    else
        sfind = find(strcmp(NRCS_txt(:,4),NRCS.STA_ID(j))==1);
    end
    if isempty(sfind)==1
        % then did not find this station... invalid number?
        sta_indices(1,j) = nan_row;
    else
        sta_indices(1,j) = sfind;
    end
end

NRCS.STA_NAME = NRCS_txt(sta_indices,3)';
NRCS.STA_NETWORK = NRCS_txt(sta_indices,1)';
NRCS.STA_LAT = NRCS_num(sta_indices,3)';
NRCS.STA_LON = NRCS_num(sta_indices,4)';
NRCS.STA_ELEV = NRCS_num(sta_indices,5)';
NRCS.STA_STATE = NRCS_txt(sta_indices,2)';
NRCS.STA_COUNTY = NRCS_txt(sta_indices,9)';
NRCS.HUC_NAME = NRCS_txt(sta_indices,10)';
NRCS.HUC_NUMBER = NRCS_num(sta_indices,8)';

%%% make cellstr array of STA IDs, in lower case for consistency
cellstr_IDs = cell(1,nsta);
for j=1:nsta
    if isnumeric(NRCS.STA_ID(j))==1
        cellstr_IDs(j) = cellstr(lower(num2str(NRCS.STA_ID(j))));
    elseif ischar(NRCS.STA_ID(j))==1 || iscellstr(NRCS.STA_ID(j))==1
        cellstr_IDs(j) = cellstr(lower(char(NRCS.STA_ID(j))));
    else
        
        error('unexpected data type')
    end
end

%%% make cellstr array of  STA NAMES, and remove spaces and make lower case
%%% to alleviate inconstincies in NRCS system. This is necessary to match
%%% sites. also, only keep text before any parentheses, if it exists
cellstr_NAMES = cell(1,nsta);
for j=1:nsta
    xNAME = char(NRCS.STA_NAME(1,j));
    xNAME = lower(xNAME);
    xNAME = xNAME(find(xNAME~=' '));
    
    a = find(xNAME=='(',1,'first');
    if isempty(a)==0
        xNAME = xNAME(1:a-1);
    end
    
    cellstr_NAMES(1,j)= cellstr(xNAME);
end


%%% convert "SNOW" network to "MSNT" (inconsistency in NRCS system)
a = strcmp(NRCS.STA_NETWORK, 'SNOW');
NRCS.STA_NETWORK(a) = cellstr('MSNT');


%%%% (2) DATA INITIALIZATION
NRCS.TIME = time_builder(IMPORT_OPTS.TPERIOD(1), IMPORT_OPTS.TPERIOD(2), dt);
ntime = size(NRCS.TIME,1);
nobs = numel(IMPORT_OPTS.OBS);
for j=1:nobs
    eval(['NRCS.' char(IMPORT_OPTS.OBS(j)) '= zeros(ntime,nsta)*NaN;'])
end


%%%% (3) DATA RETRIEVAL AND OUTPUT
str_begin_end = [datestr(IMPORT_OPTS.TPERIOD(1),'yyyy-mm-dd') ',' datestr(IMPORT_OPTS.TPERIOD(2),'yyyy-mm-dd')];
for j=1:nobs
    if j==1
        str_obs_list = [char(IMPORT_OPTS.OBS(j)) '::value'];
    else
        str_obs_list = [char(str_obs_list) char(IMPORT_OPTS.OBS(j)) '::value'];
    end
    
    if j<nobs
        str_obs_list = [char(str_obs_list) ','];
    end
end

%%% check whether we will download by group of sites (if only 1 variable)
%%% or by site (with 1 or more variables)
if nobs==1 && nsta>1
    % in this case, use multiple time series download option (faster), since we have only
    % one variable and multiple stations
    maxchunk = 100; % assume 100 stations is most we can get? my hunch is this is related to the lenght of the url string. set by trial and error (might change)
    chnk_ind = 1:maxchunk:nsta;    % starting index of each chunk
    nchunk = numel(chnk_ind);
    flag_chunk = 1;
    urlname_preamble = 'https://wcc.sc.egov.usda.gov/reportGenerator/view_csv/customMultiTimeSeriesGroupByStationReport';
    str_obs_list = ['stationId,name,' str_obs_list]; % append this to the sta_obs_list for multi-site time series
else
    nchunk = nsta; % chunk by station
    flag_chunk = 0;
    urlname_preamble = 'https://wcc.sc.egov.usda.gov/reportGenerator/view_csv/customSingleStationReport';
end

for j=1:nchunk
    if flag_chunk==0 && strcmp(NRCS.STA_NAME(j), 'NaN')==1
        
        disp(['Skipping site number ' num2str(NRCS.STA_ID(j)) ': likely invalid NRCS site number!'])

        
    else
        if flag_chunk==0
            disp(['Processing site ' char(NRCS.STA_NAME(j)) ', ' num2str(j) '/' num2str(nsta)])
        else
            disp(['Processing by groups of sites, group ' num2str(j) '/' num2str(nchunk)])
        end
        
        %%% submit URL and save data to text file
        urlname = [urlname_preamble char(IMPORT_OPTS.UNITSstr) '/' char(IMPORT_OPTS.FREQ) '/'];
        
        
        
        if flag_chunk==0
            if isnumeric(NRCS.STA_ID(j))==1
                site_str = num2str(NRCS.STA_ID(j));
            else
                site_str = char(NRCS.STA_ID(j));
            end
            
            urlname = [urlname site_str ':' char(NRCS.STA_STATE(j)) ':' char(NRCS.STA_NETWORK(j))];
            urlname = [urlname '%7C'];
        elseif flag_chunk==1
            chnk_ind1 = chnk_ind(j);
            if j~=nchunk
                chnk_ind2 = chnk_ind(j+1)-1;
            else
                chnk_ind2 = nsta;
            end
            
            for k=chnk_ind1:chnk_ind2
                if isnumeric(NRCS.STA_ID(j))==1
                    site_str = num2str(NRCS.STA_ID(k));
                else
                    site_str = char(NRCS.STA_ID(k));
                end
                
                urlname = [urlname site_str ':' char(NRCS.STA_STATE(k)) ':' char(NRCS.STA_NETWORK(k))];
                urlname = [urlname '%7C'];
            end
        end
        urlname = [urlname 'id=%22%22|name/' char(str_begin_end) '/' char(str_obs_list)];
        urlwrite(urlname, 'nrcs_data.txt');
        
        %%% read the downloaded data
        fid = fopen('nrcs_data.txt');
        ftext=fgetl(fid);
        nhead = 1;
        file_read = 1;
        nline = 0;
        
        while strcmpi(ftext(1:min([5 numel(ftext)])), 'date,')==0
            nhead=nhead+1;
            ftext=fgetl(fid);
            
            if isnumeric(ftext)==1
                if ftext==-1
                    file_read = 0;
                    fclose(fid);
                    break
                end
            end
        end
        
        if file_read==1
            A.textdata = strsplit(ftext, ',');
            A.textdata = A.textdata(1,2:end);
            ncol = size(A.textdata,2);
            fclose(fid);
            
            fid = fopen('nrcs_data.txt');
            g = textscan(fid,'%s','delimiter','\n');
            fclose(fid);
            nline=length(g{1})-nhead;
        end
        
        if nline==0
            %%% no data downloaded at this site. skip it by setting A empty
            A = [];
        else
            formatSpec=['%s' repmat(' %f',1,ncol)];
            fid = fopen('nrcs_data.txt');
            C = textscan(fid, formatSpec, nline, 'Delimiter', ',', 'HeaderLines', nhead);
            fclose(fid);
            
            A.data = cell2mat(C(1,2:end));
            
            if dt==24
                A.TIME = datenum(C{1,1}, 'yyyy-mm-dd');
            else
                A.TIME = datenum(C{1,1}, 'yyyy-mm-dd HH:MM');
            end
            A.TIME = time_builder(A.TIME);
        end
        
% % %         %%% import textfile data into matlab
% % %         if dt==24 && flag_chunk==0
% % %             A = importdata('nrcs_data.txt');
% % %         else
% % %             A = importdata('nrcs_data.txt', ',');
% % %         end
% % %         
% % %         %%% if daily file read as cell, try importing again with delim
% % %         % MSR June 30 2017
% % %         if dt==24 && iscell(A)==1
% % %             A = importdata('nrcs_data.txt', ',');
% % %         end

        % do low-level reading of the file
        
        if isstruct(A)==1
            %then this appears to be successful (data exist at this site).
            
            if flag_chunk==0
                %%% pad with dummy columns at end of A.data in case the final obs is never
                %%% available
                A.data(:,end+1:end+nobs) = repmat(A.data(:,1)*NaN,1,nobs);
            end
            
            SITEi.TIME = A.TIME;
            
%             if dt==24
%                 SITEi.TIME = time_builder(datenum(A.textdata(nhead+1:end,1), 'yyyy-mm-dd'));
%             else
%                 SITEi.TIME = time_builder(datenum(A.textdata(nhead+1:end,1), 'yyyy-mm-dd HH:MM'));
%             end
            
            if flag_chunk==1
                %%% then the columns are different sites, same obs
                % NOTE: must match the NRCS columns to what we requested.
                % they do not return the same order that we submitted.
                
                %%% get units if does not exist
                if exist('name_units', 'var')~=1
                    unit_lock=0;
                end
                
                if unit_lock==0
                    oname = char(A.textdata(1,1));
                    a1 = find(oname=='(',1,'last');
                    a2 = find(oname==')',1,'last');
                    name_units = cellstr(oname(a1+1:a2-1));
                    unit_lock=1;
                end
                
             
                                    
                
                
                %%% 1) cycle through and pick out site IDs from the nhead line
                fsites = A.textdata;
                ndload = numel(fsites);
                
                for k=1:ndload
                    if nanmin(isnan(A.data(:,k)))==0
                        % then we have some data. grab it
                        
                        % current column of data
                        %   string with site names and site ID in ()
                        xsite = char(fsites(k));
                        
                        %%% truncate to end of first closed parentheses
                        x1 = find(xsite=='(',1,'first');
                        x2 = find(xsite==')',1,'first');
                        xs1 = xsite(1:x1-2);    % site name
                        xs2 = xsite(x1+1:x2-1); % site ID
                        
                        %%% make site name lower case, remove spaces, and only keep text
                        %%% before parentheses
                        xs1 = lower(xs1);
                        xs1 = xs1(find(xs1~=' '));
                        a = find(xs1=='(',1,'first');
                        if isempty(a)==0
                            xs1 = xs1(1:a-1);
                        end
                        
                        %%% make site ID in lower case
                        xs2 = lower(xs2);
                     
                        %%% find matching site
                        ind_site = find(contains(cellstr_NAMES, xs1) & contains(cellstr_IDs, xs2));
                        
                        %%% store the data in temp structure
                        eval(['SITEi.' char(IMPORT_OPTS.OBS(1)) ' = A.data(:,k);'])

                        %%% bring the data to the master structure
                        if isempty(ind_site)==1
                            disp(['... could not find site: ' char(xs1)])
                        else
                            try
                                NRCS=data_grid(NRCS, SITEi, 1, ind_site, IMPORT_OPTS.MAX_INT);
                            catch
                                save dump.mat
                                error('issue w/ data_grid or ind_site?')
                            end
                        end
                    end
                    
                end
                
                
            else
                %%% then the columns (if more than one) are obs
                for k=1:nobs
                    eval(['SITEi.' char(IMPORT_OPTS.OBS(k)) '= A.data(:,k);']);
                    
                    %%% get units if does not exist
                    if exist('name_units', 'var')~=1
                        unit_lock=0;
                    end
                    
                    if unit_lock==0
                        oname = char(A.textdata(1,k));
                        a1 = find(oname=='(');
                        a2 = find(oname==')');
                        name_units(k) = cellstr(oname(a1+1:a2-1));
                    end
                    
                    if numel(name_units)==nobs
                        unit_lock=1;
                    end
                end
                
                %%% grid data into master NRCS structure
                NRCS=data_grid(NRCS, SITEi, 1, j, IMPORT_OPTS.MAX_INT);
            end
            
            clear SITEi
        end
        
    end
    disp(' ')
end

%%%% (4) Append variable names to include units
for j=1:nobs
    eval(['NRCS.' char(IMPORT_OPTS.OBS(j)) '_' char(name_units(j)) '=NRCS.' char(IMPORT_OPTS.OBS(j)) ';'])
    eval(['NRCS = rmfield(NRCS, ''' char(IMPORT_OPTS.OBS(j))  ''');'])
end

%%%% (5) Unit conversions (not done by NRCS)
if IMPORT_OPTS.UNITS==0
    NRCS.STA_ELEV_m = ft2m(NRCS.STA_ELEV);
    NRCS = rmfield(NRCS, 'STA_ELEV');
elseif IMPORT_OPTS.UNITS==1
    NRCS.STA_ELEV_ft = NRCS.STA_ELEV;
    NRCS = rmfield(NRCS, 'STA_ELEV');
end


%%%% (6) Cleanup
if exist('nrcs_data.txt', 'file')==2
    delete('nrcs_data.txt');
end


