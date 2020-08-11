%%% this script loads the common settings

%% paths

%%% specify root path for snow today operational files
path_root = '/projects/raleighm/Snow-Today/operational/Matlab/';

%%% specify where the ssh key is stored
path_ssh_key = '/home/raleighm/.ssh/id_rsa_snowToday';

%%% specify the PL archive location for images
path_PL_archive = '/pl/active/rittger_esp/SnowToday/SnowStations/image_archive/';

%%% don't change these
path_functions = fullfile(path_root, 'functions');
path_data = fullfile(path_root, 'data');
path_staging = fullfile(path_root, 'staging');

addpath(path_functions);

%% download settings

%%% data download options
IMPORT_OPTS.FREQ = 'daily';     % data time step
IMPORT_OPTS.UNITS = 0;          % data units (0=metric)
IMPORT_OPTS.MAX_INT = 0;        % maximum interpolation length (hrs) for missing data

%%% time settings for start/end of data donwload
time_start = datenum(1979,10,1);    % coincides with start date for pillow networks
time_end = floor(now);

%%% names of databases (don't change these)
nrcs_database = fullfile(path_data, 'SWE_database_NRCS.mat');
cdwr_database = fullfile(path_data, 'SWE_database_CDWR.mat');
all_database = fullfile(path_data, 'SWE_database_ALL.mat');

%% data settings

year_col = 1;
month_col = 2;
day_col = 3;
sdate_col = 7;  % column of the TIME matrix where matlab serial dates are stored


%% quality control

% QC settings for SWE (mm)
QC.max_swe_hard = 3500;      % 3500 mm seems to be a reasonable upper limit for SWE on the pillows. based on personal inspection at Paradise SNOTEL.
QC.min_swe_hard = 0;
QC.min_swe_soft = 25;       % assume sensor noise below this value  
    
% QC settings for dSWE (mm)
QC.min_dSWE = 5;            % minimum absolute daily change in SWE (mm)


%% plotting settings

%%% minimum fraction of network (NRCS SNOTEL + CA) w/ data (can be 0 or above 0) to report the most recent date
minSTAdata = 0.50;  

%%% year requirements to include a station
minYrs = 25;

%%% select area of interest (AOI)
AOI = [1];  
% where 1=western USA (default view for Snow Today), 2=CO, 3=MT, 4=OR, 5=UT
%       6=WY, 7=AZ, 8=ID, 9=NM, 10=CA, 11=WA

%%% define names and lat/lon limits for each area of interest
sdomain = cell(1,11);
lat_ul = nan(1,11); 
lat_ll=nan(1,11);
lon_ul = nan(1,11); 
lon_ll=nan(1,11);

%%% western USA
sdomain(1) = {'conus'};
lat_ul(1) = 49.10;
lat_ll(1) = 31.20;
lon_ll(1) = -124.80;
lon_ul(1) = -101.50;

%%% Colorado
sdomain(2) = {'CO'};
lat_ul(2) = 41.10;
lat_ll(2) = 36.75;
lon_ll(2) = -109.2;
lon_ul(2) = -101.5;

%%% Montana
sdomain(3) = {'MT'};
lat_ul(3) = 49.10;
lat_ll(3) = 44.10;
lon_ll(3) = -116.15;
lon_ul(3) = -103.90;

%%% Oregon
sdomain(4) = {'OR'};
lat_ul(4) = 46.35;
lat_ll(4) = 41.90;
lon_ll(4) = -124.70;
lon_ul(4) = -116.20;

%%% Utah
sdomain(5) = {'UT'};
lat_ul(5) = 42.10;
lat_ll(5) = 36.90;
lon_ll(5) = -114.15;
lon_ul(5) = -108.90;

%%% Wyoming
sdomain(6) = {'WY'};
lat_ul(6) = 45.10;
lat_ll(6) = 40.90;
lon_ll(6) = -111.15;
lon_ul(6) = -103.95;

%%% Arizona
sdomain(7) = {'AZ'};
lat_ul(7) = 37.10;
lat_ll(7) = 31.20;
lon_ll(7) = -115.10;
lon_ul(7) = -108.90;

%%% Idaho
sdomain(8) = {'ID'};
lat_ul(8) = 49.10;
lat_ll(8) = 41.90;
lon_ll(8) = -117.25;
lon_ul(8) = -110.90;

%%% New Mexico
sdomain(9) = {'NM'};
lat_ul(9) = 37.10;
lat_ll(9) = 31.20;
lon_ll(9) = -109.15;
lon_ul(9) = -102.90;

%%% California
sdomain(10) = {'CA'};
lat_ul(10) = 42.10;
lat_ll(10) = 32.40;
lon_ll(10) = -124.40;
lon_ul(10) = -114.00;

%%% Washington
sdomain(11) = {'WA'};
lat_ul(11) = 49.10;
lat_ll(11) = 45.40;
lon_ll(11) = -124.80;
lon_ul(11) = -116.90;
