%%% this script loads the common settings

%% paths
addpath('/projects/raleighm/Snow-Today/operational/Matlab/functions');

%%% specify root path for snow today operational files
%%% as the location of this file
path_root = fileparts(mfilename('fullpath'));

%%% specify where the ssh key is stored
path_ssh_key = fullfile(getenv('HOME'), '.ssh', 'id_rsa_snowToday');

%%% specify the PL archive location for images
path_PL_archive = '/pl/active/rittger_esp/SnowToday/SnowStations/image_archive/';

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

%%% specify paths to shapefiles
path_shp_states = fullfile(path_masks, 'State_masks.mat');
path_shp_counties = '';
path_shp_huc02 = fullfile(path_masks, 'HUC2_masks.mat');
path_shp_huc04 = '';
path_shp_huc06 = '';
path_shp_huc08 = '';

path_shp_ecoregions = fullfile(path_data, 'Ecoregions', 'westUSA_mtns.shp');

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
AOI_HYDRO = [10 11 12 13 14 15 16 17 18];   % HUC codes

%%% cat into single AOI vector, and make political codes negative
AOI.ID = [-1.*AOI_POLITICAL AOI_HYDRO];
AOI.ID = unique(AOI.ID); % remove any duplicates
if size(AOI.ID,1) ==1
    AOI.ID = AOI.ID'; % make AOI a column vector
end
nAOI = numel(AOI.ID);


