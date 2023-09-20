clear; close all;


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
HUC04 = SNOW.STA_HUC04(keepSTA);

%% write file with all stations for this date

YYYYMMDD = datestr(datenum(iYR,iMO,iDA), 'yyyymmdd');
filepath_SWEsummary = fullfile(path_staging, ['SnowToday_USwest_' YYYYMMDD '_SWEsummary.txt']);
fid = fopen(filepath_SWEsummary, 'w');


%%% shifted header to the top
fprintf(fid, '%s\n', ['SnowToday Calculated SWE Summary Data : ' datestr(datenum(iYR,iMO,iDA), 'yyyy-mm-dd')]);
fprintf(fid, '%s\n', 'Column01 : site name');
fprintf(fid, '%s\n', 'Column02 : latitude');
fprintf(fid, '%s\n', 'Column03 : longitude');
fprintf(fid, '%s\n', 'Column04 : elevation');
fprintf(fid, '%s\n', 'Column05 : SWE (inches)');
fprintf(fid, '%s\n', 'Column06 : percent of median long-term (25+yr) SWE');
fprintf(fid, '%s\n', 'Column07 : daily change in SWE (inches)');
fprintf(fid, '%s\n', 'Column08 : State');
fprintf(fid, '%s\n', 'Column09 : HUC02');
fprintf(fid, '%s\n', 'Column10 : HUC04');

fprintf(fid,'%s\n', 'Name,Lat,Lon,Elev_m,SWE,normSWE,dSWE,State,HUC02,HUC04');
head_str = '%s,%.4f,%.4f,%.1f,%.1f,%.1f,%.1f,%s,%s,%s\n';
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
    
    
    fprintf(fid, head_str, char(Name(j)), Lat(j), Lon(j), Elev_m(j), SWEc(j), climSWE(j), dSWE(j), char(State(j)), H2, H4);
end

fclose(fid);


 