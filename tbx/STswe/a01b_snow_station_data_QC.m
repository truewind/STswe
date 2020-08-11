clear; close all

%% loading

%%% load settings
snowtoday_settings;

%%% load the database
load(all_database);

%% quality control 
%%%(to be added and modified as needed to deal with data problems that arise);

%%% remove any negative SWE values
SNOW.WTEQ_mm(SNOW.WTEQ_mm<QC.min_swe_hard) = NaN;

%%% set any remaining low values of SWE to 0 (this must come after setting
%%% negative values to NaNs)
SNOW.WTEQ_mm(SNOW.WTEQ_mm<QC.min_swe_soft) = QC.min_swe_hard;

%%% set any high values of SWE to NaN. 
SNOW.WTEQ_mm(SNOW.WTEQ_mm>QC.max_swe_hard) = NaN;


%% save
save(all_database, 'SNOW')