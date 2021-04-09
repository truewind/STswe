clear; close all;


%% loading

%%% load settings
snowtoday_settings;

%%% load the database
load(all_database);

%%% load temp files w/ snow analysis
load('temp_climSWE.mat')
load('temp_dSWE.mat')


%% prep

%%% only keep sites in our domain
keepSTA = nan.*dSWE;
for j=1:numel(keepSTA)
    if numel(char(SNOW.STA_HUC02{j}))>1 || numel(char(SNOW.STA_STATE{j}))>1
        keepSTA(j)=1;
    else
        keepSTA(j)=0;
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

%% write file with all stations for this date

YYYYMMDD = datestr(datenum(iYR,iMO,iDA), 'yyyymmdd');
filepath_SWEsummary = fullfile(path_staging, ['SnowToday_USwest_' YYYYMMDD '_SWEsummary.txt']);
fid = fopen(filepath_SWEsummary, 'w');
fprintf(fid,'%s\n', 'Name,State,Lat,Lon,Elev_m,climSWE,dSWE,HUC02');
head_str = '%s,%s,%.4f,%.4f,%.1f,%.1f,%.1f,%s\n';
for j=1:numel(keepSTA)
    if isempty(HUC02{j})==0
        H2=char(HUC02(j));
    else
        H2='N/A';
    end
    fprintf(fid, head_str, char(Name(j)), char(State(j)), Lat(j), Lon(j), Elev_m(j), climSWE(j), dSWE(j), H2);
end
fclose(fid);
 