% snowtoday_settings.m

% This script is a configuration file with the settings for running the
% Snow Today code for SWE stations. This script should be configured upon
% first usage, and updated as needed. Settings include paths, and various
% settings related to download, data format, data QC, and plotting.
%
% Code written by Mark Raleigh (raleigma@oregonstate.edu)


%% paths
%%% add path to the folder than includes various functions used in the code
path_functions = './functions';
addpath(path_functions);

%%% specify root path for snow today operational files
%%% as the location of this file
path_root = fileparts(mfilename('fullpath'));

%%% specify where the ssh key is stored
path_ssh_key = fullfile(getenv('HOME'), '.ssh', 'id_rsa_snowToday');

%%% specify the PL archive location for images
path_PL_archive = '/pl/active/rittger_esp/SnowToday/SnowStations/image_archive/';

%%% specify the PL root location for public data access
path_PL_text_data = '/pl/active/rittger_public/snow-today/';

%%% specify the path on NuSnow for SWE
path_nusnow_swe = '/share/apps/snow-today/incoming/snow-water-equivalent/';

%%% these are in the STswe project
path_data = fullfile(path_root, 'data');
path_staging = fullfile(path_root, 'staging');
path_masks = fullfile(path_root, 'masks');

%%% We are assuming that the location of the H2Snow functions is
%%% already in the path

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

%%%
create_figs = 1;    % enter 1 to generate figures, 0 to turn off

%%% specify paths to shapefiles
path_shp_states = fullfile(path_masks, 'State_masks.mat');
path_shp_counties = '';
path_shp_huc02 = fullfile(path_masks, 'HUC2_masks.mat');
path_shp_huc04 = fullfile(path_masks, 'HUC4_masks.mat');
path_shp_huc06 = '';
path_shp_huc08 = '';

path_shp_ecoregions = fullfile(path_data, 'Ecoregions', 'westUSA_mtns2.shp');

%%% specify paths to tables defining numbers/names of political boundaries
%%% (States, counties) and HUCs (2-8)
path_tab_political = fullfile(path_data, 'political.txt');
path_tab_huc = fullfile(path_data, 'huc_0208.txt');

%%% minimum fraction of network (NRCS SNOTEL + CA) w/ data (can be 0 or above 0) to report the most recent date
minSTAdata = 0.50;  

%%% year requirements to include a station
minYrs = 25;

%%% specify lat/lon buffer around each Area of Interest (AOI) in the maps
lat_buff = 0.05;  % buffer at top and bottom of plot (as fraction)
lon_buff = 0.05;  % buffer at left and right of plot (as fraction)
latlon_aspRatio = 1.3; % target lat-lon aspect ratio for the maps

%%% select area of interest (AOI), both political and hydrologic
AOI_POLITICAL = [0 4 6 8 16 30 31 32 35 41 46 49 53 56];  % FIPS codes for state or county. 0 = USWEST
AOI_HYDRO = [10 11 13 14 15 16 17 18];   % HUC2 codes
% cat the HUC04 into the HUC02: (apologies for the long list)
AOI_HYDRO = [AOI_HYDRO,1806,1807,1809,1805,1810,1802,1808,1804,1803,1801,1702,1711,1703,1706,1705,1710,1701,1704,1712,1707,1708,1709,1604,1606,1605,1602,1601,1603,1507,1503,1506,1505,1508,1502,1501,1504,1406,1401,1402,1407,1403,1405,1408,1404,1307,1310,1304,1301,1302,1303,1306,1305,1211,1202,1201,1209,1207,1204,1210,1206,1208,1203,1205,1102,1103,1112,1113,1109,1108,1104,1110,1005,1014,1028,1020,1021,1022,1004,1009,1026,1023,1018,1025,1015,1012,1003,1010,1013,1016,1007,1008,1019,1027,1024,1002,1006,1011,1017];

%%% cat into single AOI vector, and make political codes negative
AOI.ID = [-1.*AOI_POLITICAL AOI_HYDRO];
AOI.ID = unique(AOI.ID); % remove any duplicates
if size(AOI.ID,1) ==1
    AOI.ID = AOI.ID'; % make AOI a column vector
end
nAOI = numel(AOI.ID);


