% Imports California Dept. of Water Resources data into Matlab
% based on the CDEC web retrieval
%
% RELEASE NOTES
%   Written by Mark Raleigh, July 2017 (mraleig1@gmail.com)
%
% SYNTAX
%   CDWR = import_cdwr(IMPORT_OPTS)
%
% INPUTS
%   IMPORT_OPTS = structure of import options, where fields include:
%       SITES = (optional) cell string of sites of interest (typically 3-letter code, e.g., DAN)
%               OR cellstring 'ALL' to retrieve data from all sites
%                   ALTERNATIVELY, USE SPATIAL SUBSETTING BELOW:
%
%       LAT_LON_LIMITS = four value vector specifying lat/lon limits in dec degrees (- for W, +for N) (grab all sites in this box),
%               where [lon_lower, lon_upper, lat_lower, lat_upper]
%       ELEV_LIMITS = two value vector specifyingg elevation band (grab all site ins that zone)
%               where [lower_elev, upper_elev]
%                   NOTE:   units are  m if IMPORT_OPTS.UNITS = 0
%                           units are ft if IMPORT_OPTS.UNITS = 1
%
%       OBS =  vector specifying codes of observations to retrieve (see below)
%
%                                                    UNITS          TEMPORAL AVAILABILITY
%            CODE   VARIABLE                     ENG  ||  METRIC     Hourly/Daily
%           =============================================================================
%               2	PRECIPITATION, ACCUMULATED    in        mm       H,D
%               3	SNOW, WATER CONTENT           in        mm       H,D (recommend using 82 instead)
%               4	TEMPERATURE, AIR               F         C       H
%               9	WIND, SPEED                  mph       mps       H
%              10	WIND, DIRECTION              deg       deg       H
%              12	RELATIVE HUMIDITY           frac      frac       H
%              14	BATTERY VOLTAGE              --          V       H
%              16   PRECIPITATION, TIPPING BUCKET in        mm       H
%              17	ATMOSPHERIC PRESSURE          in        Pa	     H
%              18	SNOW DEPTH                    in        mm       H,D
%              30	TEMPERATURE, AIR AVERAGE       F         C       D
%              31	TEMPERATURE, AIR MAXIMUM       F         C       D
%              32	TEMPERATURE, AIR MINIMUM       F         C       D
%              45   PRECIPITATION, INCREMENTAL    in        mm       D
%              77	WIND, PEAK GUST              mph       mps	     H
%              78	WIND, DIRECTION OF PEAK GUST deg       deg       H
%              82	SNOW, WATER CONTENT(REVISED)  in        mm       D
%              96	FIELD GAMMA TEMP VOLTAGE      --        mV       H
%              97	REF GAMMA TEMP VOLTAGE        --        mV       H
%              98	FIELD GAMMA VOLTAGE           --        mV       H
%              99	REF GAMMA VOLTAGE             --        mV       H
%             103	SOLAR RADIATION AVG           --      W/m2       H
%             104	SOLAR RADIATION MIN           --      W/m2       H
%             105	SOLAR RADIATION MAX           --      W/m2       H
%             106	NET SOLAR RADIATION AVG       --      W/m2       H,D
%             107	NET SOLAR RADIATION MIN       --      W/m2       H
%             108	NET SOLAR RADIATION MAX       --      W/m2       H
%             115	BATTERY VOLTAGE AUX           --         V       H
%             116	IRRADIANCE AVERAGE            --      W/m2       H
%             117	IRRADIANCE MINIMUM            --      W/m2       H
%             118	IRRADIANCE MAXIMUM            --      W/m2       H
%             119	REFLECTED IRRADIANCE AVG      --      W/m2       H
%             120	REFLECTED IRRADIANCE MIN      --      W/m2       H
%             121	REFLECTED IRRADIANCE MAX      --      W/m2       H
%
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
%   CDWR = structure with outputs and station metadata
%
% NOTES
%   1. If SITES is defined in the IMPORT_OPTS structure as anything other
%   than 'ALL', then it will ignore LAT_LON_LIMITS and ELEV_LIMITS (if
%   provided). The script will use LAT_LON_LIMITS and/or ELEV_LIMITS if
%   SITES is not provided or if it is set to 'ALL'.
%
%   2. This script does not do any QA/QC.  You will most certainly need to
%   do this to the output data for use in your application.
%
% EXAMPLES
%   % call the script to import revised SWE (code 82)  for a single year
%   (water year 2016) for any CDWR sites above 1500 m elevation:
%
%       IMPORT_OPTS.SITES = {'ALL'}
%       IMPORT_OPTS.TPERIOD = [datenum(2015,10,1) datenum(2016,9,30)];
%       IMPORT_OPTS.ELEV_LIMITS  = [1500 5000];  % upper limit is arbitrarily large
%       IMPORT_OPTS.OBS = [82];
%       IMPORT_OPTS.FREQ = 'daily';
%       IMPORT_OPTS.MAX_INT = 0;
%       CDWR = import_cdwr(IMPORT_OPTS);
%


function CDWR = import_cdwr(IMPORT_OPTS)

%% Checks

%%% check for required fields
if (isfield(IMPORT_OPTS, 'SITES')~=1 && isfield(IMPORT_OPTS, 'LAT_LON_LIMITS') ~=1 && isfield(IMPORT_OPTS, 'ELEV_LIMITS'))  || isfield(IMPORT_OPTS, 'OBS') ~=1 || isfield(IMPORT_OPTS, 'TPERIOD') ~=1
    error('missing required fields in input structure IMPORT_OPTS')
end

%%% check for temporal resolution
if isfield(IMPORT_OPTS, 'FREQ')~=1
    % not specified. Use default of daily data
    IMPORT_OPTS.FREQ = 'daily';
    dt = 24;
    dur_code = 'D';
else
    % what was specified?
    if strcmp(char(IMPORT_OPTS.FREQ), 'daily')==1
        dt=24;
        dur_code = 'D';
    elseif strcmp(char(IMPORT_OPTS.FREQ), 'hourly')==1
        dt=1;
        dur_code = 'H';
    else
        error('The code has not been configured to accept that frequency')
    end
end

%%% check for output units
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

%%% check for maximum interpolation length
if isfield(IMPORT_OPTS, 'MAX_INT')~=1
	IMPORT_OPTS.MAX_INT = 2;
	
end

if strcmp(IMPORT_OPTS.FREQ, 'daily')==1
	IMPORT_OPTS.MAX_INT = 0; % this feature is not needed for daily data
end
	

%%% if SITES was input, check to see format. convert from str to cellstr if needed
if isfield(IMPORT_OPTS, 'SITES')==1
    if iscell(IMPORT_OPTS.SITES)==1
    elseif ischar(IMPORT_OPTS.SITES)==1
        % convert from cell string to array
        for j=1:size(IMPORT_OPTS.SITES,1)
            iSITES(1,j) = cellstr(IMPORT_OPTS.SITES(j,:));
        end
        IMPORT_OPTS.SITES = iSITES;
        clear iSITES
    else
        error('Invalid data format for field SITES')
    end
else
    % then this field was not included. set to default
    IMPORT_OPTS.SITES = {'ALL'};
end

%% Data codes, names, etc.
DATA_CODES = [2, ...
    3, ...
    4, ...
    9, ...
    10, ...
    12, ...
    14, ...
    16, ...
    17, ...
    18, ...
    30, ...
    31, ...
    32, ...
    45, ...
    77, ...
    78, ...
    82, ...
    96, ...
    97, ...
    98, ...
    99, ...
    103, ...
    104, ...
    105, ...
    106, ...
    107, ...
    108, ...
    115, ...
    116, ...
    117, ...
    118, ...
    119, ...
    120, ...
    121];


DATA_NAMES = {'PREC',...
    'WTEQ_RAW',...
    'TOBS',...
    'WSPD',...
    'WDIR',...
    'RHUM',...
    'BATV',...
    'PREC_TB',...
    'PATM',...
    'SNWD',...
    'TAVG',...
    'TMAX',...
    'TMIN',...
    'PREC_INC',...
    'GUST',...
    'GUSTDIR',...
    'WTEQ',...
    'FGTV',...
    'RGTV',...
    'FGV',...
    'RGB',...
    'QSI_AVG',...
    'QSI_MIN',...
    'QSI_MAX',...
    'QSN_AVG',...
    'QSN_MIN',...
    'QSN_MAX',...
    'BATV_AUX',...
    'IRR_AVG',...
    'IRR_MIN',...
    'IRR_MAX',...
    'QSO_AVG',...
    'QSO_MIN',...
    'QSO_MAX'};

DATA_UNITS = {'in', 'mm';...
    'in', 'mm';...
    'degF', 'degC';...
    'mph', 'mps';...
    'deg', 'deg';...
    'frac', 'frac';...
    '--', 'V';...
    'in', 'mm';...
    'in', 'Pa';...
    'in', 'mm';...
    'degF', 'degC';...
    'degF', 'degC';...
    'degF', 'degC';...
    'in', 'mm';...
    'mph', 'mps';...
    'deg', 'deg';...
    'in', 'mm';...
    '--', 'mV';...
    '--', 'mV';...
    '--', 'mV';...
    '--', 'mV';...
    '--', 'W_m2';...
    '--', 'W_m2';...
    '--', 'W_m2';...
    '--', 'W_m2';...
    '--', 'W_m2';...
    '--', 'W_m2';...
    '--', 'V';...
    '--', 'W_m2';...
    '--', 'W_m2';...
    '--', 'W_m2';...
    '--', 'W_m2';...
    '--', 'W_m2';...
    '--', 'W_m2'};


%%% native units for CDWR download ... enter 0 for english, 1 for metric
DATA_NATIVE_UNITS = zeros(1,numel(DATA_NAMES));
a = find(DATA_CODES== 10 | DATA_CODES== 12 | DATA_CODES== 14 | DATA_CODES== 78 | (DATA_CODES>= 96));
DATA_NATIVE_UNITS(a) = 1;

%%% specify which data's units can be converted at this time... need to
%%% update more
DATA_UNITS_CONVERT = ones(1,numel(DATA_NAMES));
a = find(DATA_CODES== 10 | DATA_CODES== 12 | DATA_CODES== 14 | DATA_CODES== 78 | (DATA_CODES>= 96));
DATA_UNITS_CONVERT(a) = 1;



%% Code


%%%% (1) METADATA AND SITE IDENTIFICATION
disp('Reading site list and retrieving metadata')

%%% first get list of site metadata for CDWR network (will need different read function for Linux machines)
try
    [CDWR_num, CDWR_txt,~] = xlsread('CDWR_Sites.csv');
catch
    [CDWR_num, CDWR_txt,~] = xlsread('CDWR_Sites.xlsx');     % try Excel version
end

%%% set weird lat/lon to NaN
a = find(CDWR_num(:,1) > -110 | CDWR_num(:,1) < -130);
CDWR_num(a,1:2) = NaN;
a = find(CDWR_num(:,2) > 43 | CDWR_num(:,2) < 32);
CDWR_num(a,1:2) = NaN;

%%% site selection
CDWR.STA_ID = {''}; % initialize empty cell string
if isfield(IMPORT_OPTS, 'SITES')==1
    if isnumeric(IMPORT_OPTS.SITES)==1
        error('Field SITES in IMPORT_OPTS cannot be numeric')
    else
        
        if strcmp(char(IMPORT_OPTS.SITES), 'ALL')==1
            CDWR.STA_ID = CDWR_txt(:,1)';
        else
            
            if size(IMPORT_OPTS.SITES,2)==1
                CDWR.STA_ID = IMPORT_OPTS.SITES';
            else
                CDWR.STA_ID = IMPORT_OPTS.SITES;
            end
        end
    end
else
    
    %%% then at least one of the subsetting options was specified. grab all
    %%% stations for now
    CDWR.STA_ID = CDWR_txt(:,1)';
end

%%% convert elevation from ft to m if metric was designated
if IMPORT_OPTS.UNITS==0
    CDWR_num(:,3) = ft2m(CDWR_num(:,3));
end

%%% append NaN row to end of CDWR_txt and CDWR_num (must do this after
%%% previous task of populating list of station numbers)
CDWR_num(end+1,:) = NaN;
CDWR_txt(end+1,:) = cellstr('NaN');
nan_row = size(CDWR_num,1);

%%% get site metadata
nsta = numel(CDWR.STA_ID);
sta_indices = zeros(1,nsta)*NaN;
for j=1:nsta
    % find this site in the master list
    sfind = find(strcmp(CDWR_txt(:,1), CDWR.STA_ID(j))==1);
    if isempty(sfind)==1
        % then did not find this station... invalid number?
        sta_indices(1,j) = nan_row;
    else
        if numel(sfind)~=1
            error('more than one station found with this ID... Mark should fix this')
        else
            sta_indices(1,j) = sfind;
        end
    end
    
end

%%% grab metadata
CDWR.STA_NAME = CDWR_txt(sta_indices,2)';
CDWR.STA_BASIN = CDWR_txt(sta_indices,3)';
CDWR.STA_COUNTY = CDWR_txt(sta_indices,4)';
CDWR.STA_LON = CDWR_num(sta_indices,1)';
CDWR.STA_LAT = CDWR_num(sta_indices,2)';
CDWR.STA_ELEV = CDWR_num(sta_indices,3)';
CDWR.STA_OPERATOR = CDWR_txt(sta_indices,8)';



FLAG_SITES = 1; % set flag


%%% subsetting (only IMPORT_OBS.SITES is not 'ALL')
if strcmp(IMPORT_OPTS.SITES, 'ALL')==1
    if isfield(IMPORT_OPTS, 'LAT_LON_LIMITS')==1
        %%% then lat/lon limits provied
        if numel(IMPORT_OPTS.LAT_LON_LIMITS)~=4
            error('LAT_LON_LIMITS must be 4 element array')
        else
            %%% extract pts of lat/lon box and check for upper vs. lower
            lon_ll = IMPORT_OPTS.LAT_LON_LIMITS(1);
            lon_ul = IMPORT_OPTS.LAT_LON_LIMITS(2);
            lat_ll = IMPORT_OPTS.LAT_LON_LIMITS(3);
            lat_ul = IMPORT_OPTS.LAT_LON_LIMITS(4);
            
            if lon_ll>lon_ul
                lon_ul2 = lon_ul;
                lon_ul = lon_ll;
                lon_ll = lon_ul2;
                clear lon_ul2
            end
            
            if lat_ll>lat_ul
                lat_ul2 = lat_ul;
                lat_ul = lat_ll;
                lat_ll = lat_ul2;
                clear lat_ul2
            end
            
            %%% use inpolygon to find which stations are in the lat/lon box
            xv = [lon_ll lon_ul lon_ul lon_ll lon_ll];
            yv = [lat_ll lat_ll lat_ul lat_ul lat_ll];
            [in,on] = inpolygon(CDWR.STA_LON,CDWR.STA_LAT,xv,yv);
            in = double(in) + double(on);
            a = find(in>0);
            
            %%% check if any sites were in the lat/lon box
            if isempty(a)==1
                % then no stations found in this lat/lon box!
                FLAG_SITES =0;
            else
                %%% apply subsetting
                CDWR.STA_ID = CDWR.STA_ID(a);
                CDWR.STA_NAME = CDWR.STA_NAME(a);
                CDWR.STA_BASIN = CDWR.STA_BASIN(a);
                CDWR.STA_COUNTY = CDWR.STA_COUNTY(a);
                CDWR.STA_LON = CDWR.STA_LON(a);
                CDWR.STA_LAT = CDWR.STA_LAT(a);
                CDWR.STA_ELEV = CDWR.STA_ELEV(a);
                CDWR.STA_OPERATOR = CDWR.STA_OPERATOR(a);
            end
        end
    end
    
    if isfield(IMPORT_OPTS, 'ELEV_LIMITS')==1 && FLAG_SITES==1
        %%% find sites in elevation band
        elev_min = nanmin(IMPORT_OPTS.ELEV_LIMITS);
        elev_max = nanmax(IMPORT_OPTS.ELEV_LIMITS);
        a = find(CDWR.STA_ELEV>= elev_min & CDWR.STA_ELEV<= elev_max);
        
        %%% check if any sites were in the elevation band
        if isempty(a)==1
            % then no stations found
            FLAG_SITES =0;
        else
            %%% apply subsetting
            CDWR.STA_ID = CDWR.STA_ID(a);
            CDWR.STA_NAME = CDWR.STA_NAME(a);
            CDWR.STA_BASIN = CDWR.STA_BASIN(a);
            CDWR.STA_COUNTY = CDWR.STA_COUNTY(a);
            CDWR.STA_LON = CDWR.STA_LON(a);
            CDWR.STA_LAT = CDWR.STA_LAT(a);
            CDWR.STA_ELEV = CDWR.STA_ELEV(a);
            CDWR.STA_OPERATOR = CDWR.STA_OPERATOR(a);
        end
    end
else
    if isfield(IMPORT_OPTS, 'LAT_LON_LIMITS')==1 || isfield(IMPORT_OPTS, 'ELEV_LIMITS')==1
        disp('NOTE: the subsetting options have not been applied because specific sites were input')
    end
end

%%% check number of sites after subsetting
nsta = numel(CDWR.STA_ID);

if FLAG_SITES==1
    
    %%%% (2) DATA INITIALIZATION
    CDWR.TIME = time_builder(IMPORT_OPTS.TPERIOD(1), IMPORT_OPTS.TPERIOD(2), dt);
    ntime = size(CDWR.TIME,1);
    nobs = numel(IMPORT_OPTS.OBS);
    OBS_FINAL = {''};
    CODE_FINAL = [];
    count_obs = 0;
    for j=1:nobs
        a = find(DATA_CODES == IMPORT_OPTS.OBS(j));
        if isempty(a)==1
            disp(['...did not find OBS with code ' num2str(IMPORT_OPTS.OBS(j)) '! Skipping...'])
        else
            OBS_STR = char(DATA_NAMES(a));
            eval(['CDWR.' OBS_STR '= zeros(ntime,nsta)*NaN;'])
            
            count_obs = count_obs+1;
            OBS_FINAL(count_obs) = cellstr(OBS_STR);
            CODE_FINAL(count_obs) = IMPORT_OPTS.OBS(j);
        end
    end
    
    %%% recompute number of observations (valid ones only)
    nobs = count_obs;
    
    if nobs==0
        FLAG_SITES=0;
    end
    
    
    %%%% (3) DATA RETRIEVAL AND OUTPUT
    if FLAG_SITES==1

%         urlname_preamble = 'http://cdec.water.ca.gov/cgi-progs/queryCSV?station_id=';
%         str_begin_end = ['&start_date=' datestr(IMPORT_OPTS.TPERIOD(1),'yyyy/mm/dd') '&end_date=' datestr(IMPORT_OPTS.TPERIOD(2),'yyyy-mm-dd')];
        % change in Nov 2018
        urlname_preamble = 'http://cdec.water.ca.gov/dynamicapp/req/CSVDataServlet?Stations=';
        str_begin_end = ['&Start=' datestr(IMPORT_OPTS.TPERIOD(1),'yyyy-mm-dd') '&End=' datestr(IMPORT_OPTS.TPERIOD(2),'yyyy-mm-dd')];
        
        for j=1:nsta
            if strcmp(CDWR.STA_NAME(j), 'NaN')==1
                disp(['Skipping site number ' num2str(CDWR.STA_ID(j)) ': likely invalid CDWR site number!'])
            else
                disp(['Processing site ' char(CDWR.STA_NAME(j)) ', ' num2str(j) '/' num2str(nsta)])
                
                for k=1:nobs
                    disp(['--getting ' char(OBS_FINAL(k)) '--'])
                    
                    %%% submit URL and save data to text file
                    urlname = [urlname_preamble char(CDWR.STA_ID(j)) '&SensorNums=' num2str(CODE_FINAL(k)) '&dur_code=' char(dur_code) str_begin_end];
                    outname = ['CDWR_data_' char(CDWR.STA_ID(j)) '_' num2str(CODE_FINAL(k)) '.txt'];
                    
                    try
                        %%% grab data from internet url
                        outname = websave(outname,urlname);
                    catch
                        % then we ran into a problem downloading the file.
                        % The website may have caused a timeout, so lets
                        % increase timeout.
                        
                        %%% get current weboptions
                        Woptions = weboptions;
                        Woptions_TO = Woptions.Timeout;
                        %%% add 30 seconds to current Timeout
                        weboptions('Timeout',30+Woptions_TO);
                        
                        %%% try again to grab data from internet url
                        try
                            outname = websave(outname,urlname);
                            weboptions('Timeout',Woptions_TO); % set timeout back to original value
                        catch
                            disp('********** Warning: problem downloading URL data for this site/observation *************')
                            weboptions('Timeout',Woptions_TO); % set timeout back to original value
                        end
                    end
                    
                    if exist(outname, 'file')==2
                        %%% convert ',m' values to ',NaN' - CDWR uses m for
                        %%% missing, which messes with Matlab I/O
                        find_and_replace(outname, ',m', ',NaN');
                        
                        %%% read file
                        find_and_replace(outname, '---', 'NaN'); % ... because they decided to put '---' in numeric data
                        
                        %%% read table... and suppress the warning
                        warning off;
                        A = readtable(outname, 'Delimiter', ','); 
                        warning on;
                        
                        if istable(A)~=1
                            disp('...... could not find data')
                        else
                            if size(A,1)>1
                                if ismember('VALUE', A.Properties.VariableNames)~=1 || ismember('DATETIME', A.Properties.VariableNames) ~=1
                                    disp('...... could not find data')
                                else
                                    
                                    eval(['SITEi.' char(OBS_FINAL(k)) '= A.VALUE;']);
                                    % 								if strcmp(IMPORT_OPTS.FREQ, 'hourly')==1
                                    % 									SITEi.TIME = datenum(num2str(A.data(:,1)), 'yyyymmdd') + ((A.data(:,2)/100))/24; % include hhmm
                                    % 								else
                                    % 									SITEi.TIME = datenum(num2str(A.data(:,1)), 'yyyymmdd');
                                    % 								end
                                    SITEi.TIME = datenum(A.DATETIME, 'yyyymmdd HHMM');
                                    SITEi.TIME = time_builder(SITEi.TIME);
                                    
                                    %%% grid data into master CDWR structure
                                    CDWR=data_grid(CDWR, SITEi, 2, j, IMPORT_OPTS.MAX_INT);
                                    
                                    clear SITEi
                                    
                                end
                            else
                                disp('..... no data found')
                            end
                        end
                        
                        %%%% Cleanup
                        delete(outname);
                    end
                    
                end
                
                
                
                
            end
        end
    end
end


%%% may be redundant, but do final check on whether we have valid output
if FLAG_SITES==1
    if nobs==0
        FLAG_SITES = 0;
    end
    
    
    if numel(OBS_FINAL)==1
        if strcmp(OBS_FINAL, {''})==1
            FLAG_SITES = 0;
        end
    end
end

%%% final steps before exit
if FLAG_SITES==1 && nobs>0
    
    %%%% (4) Convert units and append variable names to include units
    for j=1:nobs
        CODEx = CODE_FINAL(j);
        
        %%% convert RH from percent to fraction)
        if CODEx ==12
            eval(['CDWR.' char(OBS_FINAL(j))  '= CDWR.' char(OBS_FINAL(j)) ' ./ 100;']);
            str_units = 'frac';
        end
        
        a = find(DATA_CODES==CODEx);
        if DATA_NATIVE_UNITS(a)==0 && DATA_UNITS_CONVERT(a)==1 && IMPORT_OPTS.UNITS==0
            % then we got english, we want metric, and this is possible
            
            if strcmp(DATA_UNITS(a,1), 'in') && strcmp(DATA_UNITS(a,2), 'mm')
                %%% convert from in to mm
                eval(['CDWR.' char(OBS_FINAL(j))  '=in2mm(CDWR.' char(OBS_FINAL(j)) ');']);
                str_units = 'mm';
            elseif strcmp(DATA_UNITS(a,1), 'degF') && strcmp(DATA_UNITS(a,2), 'degC')
                %%% convert from deg F to deg C
                eval(['CDWR.' char(OBS_FINAL(j))  '=tempF2C(CDWR.' char(OBS_FINAL(j)) ');']);
                str_units = 'degC';
            elseif strcmp(DATA_UNITS(a,1), 'mph') && strcmp(DATA_UNITS(a,2), 'mps')
                %%% convert from mph to mps
                eval(['CDWR.' char(OBS_FINAL(j))  '=mph2mps(CDWR.' char(OBS_FINAL(j)) ');']);
                str_units = 'mps';
            elseif strcmp(DATA_UNITS(a,1), 'in') && strcmp(DATA_UNITS(a,2), 'Pa')
                %%% convert from inches (assumed mercury) to Pa
                eval(['CDWR.' char(OBS_FINAL(j))  '= CDWR.' char(OBS_FINAL(j)) ' .* (101591.67/30);']);
                str_units = 'Pa';
            end
        else
            str_units = char(DATA_UNITS(a,1));
            
            if strcmp(str_units, '--')==1
                str_units = char(DATA_UNITS(a,2));
            end
            
        end
        
        %%% append units to variable name and remove old variable
        eval(['CDWR.' char(OBS_FINAL(j)) '_' char(str_units) '=CDWR.' char(OBS_FINAL(j)) ';'])
        eval(['CDWR = rmfield(CDWR, ''' char(OBS_FINAL(j))  ''');'])
    end
    
    %%%% (5) rename elevation field to include units
    if IMPORT_OPTS.UNITS==0
        CDWR.STA_ELEV_m = CDWR.STA_ELEV;
    elseif IMPORT_OPTS.UNITS==1
        CDWR.STA_ELEV_ft = CDWR.STA_ELEV;
    end
    CDWR = rmfield(CDWR, 'STA_ELEV');
    
    
else
    disp('No sites found that met the search criteria!')
    CDWR = [];
end
