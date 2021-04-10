%%% this script assembles the spatial info for the maps, including the
%%% ShortName, LongName, and lat/lon limits


%% load common settings

snowtoday_settings;

%% load snow station data (to append state and huc info)

load(all_database);
if isfield(SNOW, 'STA_STATE') ==1 && isfield(SNOW, 'STA_HUC02') ==1
    flag_names_huc_state = 1;
else
    flag_names_huc_state = 0;
    SNOW.STA_STATE = cell(1,numel(SNOW.STA_ID));
    SNOW.STA_HUC02 = cell(1,numel(SNOW.STA_ID));
end

%% read shapefiles and tables

%%% read each separately...  add more if we get other HUCs / counties
% shp_states = shaperead(path_shp_states);
% shp_huc02 = shaperead(path_shp_huc02);
shp_states = load(path_shp_states);
shp_huc02 = load(path_shp_huc02);

tab_political = readtable(path_tab_political);
tab_huc = readtable(path_tab_huc);


%% populate the AOI structure

%%% intialize variables
AOI.ShortName = cell(nAOI,1);
AOI.LongName = cell(nAOI,1);
AOI.Type = cell(nAOI,1);
AOI.lat_ul = nan(nAOI,1);
AOI.lat_ll = nan(nAOI,1);
AOI.lon_ul = nan(nAOI,1);
AOI.lon_ll = nan(nAOI,1);
AOI.shp_recNum = nan(nAOI,1);


%%% populate the values for AOIs
for j=1:nAOI
    %%% current AOI
    curr_AOI = AOI.ID(j);
    
    %%% determine whether political or HUC. If political, determine whether
    %%% state or county. If HUC, determine HUC 2, 4, 6, or 8. Get the
    %%% ShortName and LongName
    if curr_AOI<0
        % then this is a political location. take the abs value so we have
        % a positive value, and search for it in the political table.
        curr_AOI=abs(curr_AOI);
        
        %%% find this state in the political table
        a = find(strcmp({shp_states.S.STATE_FIPS}.', num2str(curr_AOI,'%02.f'))==1);
%         a = find(tab_political.Var1==curr_AOI);
        
        %%% determine whether it is a state or county. Assign the shortname
        %%% and longname
        if curr_AOI<100
            AOI.Type(j) = cellstr('state');
            
            %%% get LongName and ShortName (state abbreviation)
            AOI.LongName(j,1) = shp_states.LongName(a);
            AOI.ShortName(j,1) = shp_states.ShortName(a);

            
            
            %%% get the lat/lon limits based on the shapefile
            a = find(strcmp({shp_states.S.STATE}.', AOI.LongName(j,1))==1);
            
            %%% if found a match, get the bounding box
            if isempty(a)==0
                BoundingBox = shp_states.S(a).BoundingBox;
                ShapeX = shp_states.S(a).X;
                ShapeY = shp_states.S(a).Y;
                
                %%% lat/lon limits
                AOI.lat_ul(j,1) = nanmax(BoundingBox(:,2));
                AOI.lat_ll(j,1) = nanmin(BoundingBox(:,2));
                AOI.lon_ul(j,1) = nanmax(BoundingBox(:,1));
                AOI.lon_ll(j,1) = nanmin(BoundingBox(:,1));
                
                AOI.shp_recNum(j,1) = a;
                
                
                %%% find stations within this state
                if flag_names_huc_state==0
                    [in,on]=inpolygon(SNOW.STA_LON, SNOW.STA_LAT, ShapeX, ShapeY);
                    in = find(in==1);
                    SNOW.STA_STATE(in) = AOI.ShortName(j,1);
                end
            
            end
            

        else
            AOI.Type(j) = cellstr('county');
            
   
            error('need to code this in if/when we get a county shapefile')
            
            %%% 
            
        end
        
        
        
        
    elseif curr_AOI>0
        % then this is a HUC
        
        %%% find this HUC02
        huc_cellstr = {shp_huc02.S.huc2}.';
        a = find(strcmp(huc_cellstr, num2str(curr_AOI,'%02.f'))==1);
%         a = find(tab_huc.Var1==curr_AOI);
        
        %%% store long name
        AOI.LongName(j,1) = shp_huc02.LongName(a);
        
        %%% store shortname
        AOI.ShortName(j,1) = shp_huc02.ShortName(a);
        
        %%% determine HUC level and get the lat/lon max and min
        numHUC = str2double(char(huc_cellstr(a)));
        if numHUC<10^2
            AOI.Type(j) = cellstr('HUC02');
            
            %%% get the lat/lon limits based on the shapefile
            a = find(strcmp({shp_huc02.S.huc2}.', num2str(numHUC))==1);
            
            %%% if found a match, get the bounding box
            if isempty(a)==0
                BoundingBox = shp_huc02.S(a).BoundingBox;
                ShapeX = shp_huc02.S(a).X;
                ShapeY = shp_huc02.S(a).Y;
                
                %%% lat/lon limits
                AOI.lat_ul(j,1) = nanmax(BoundingBox(:,2));
                AOI.lat_ll(j,1) = nanmin(BoundingBox(:,2));
                AOI.lon_ul(j,1) = nanmax(BoundingBox(:,1));
                AOI.lon_ll(j,1) = nanmin(BoundingBox(:,1));
                
                AOI.shp_recNum(j,1) = a;
                
                %%% find stations within this huc02
                if flag_names_huc_state==0
                    [in,on]=inpolygon(SNOW.STA_LON, SNOW.STA_LAT, ShapeX, ShapeY);
                    in = find(in==1);
                    SNOW.STA_HUC02(in) = AOI.ShortName(j,1);
                end
            end
            
        elseif numHUC<10^4
            AOI.Type(j) = cellstr('HUC04');
            
            %%% 
            error('need to code this in if/when we get a HUC04 shapefile')
        elseif numHUC<10^6
            AOI.Type(j) = cellstr('HUC06');
            
            %%% 
            error('need to code this in if/when we get a HUC06 shapefile')
        elseif numHUC<10^8
            AOI.Type(j) = cellstr('HUC08');
            
            %%% 
            error('need to code this in if/when we get a HUC08 shapefile')
        else
            error('unexpected HUC number')
        end
        
        

    elseif curr_AOI==0
        % this is the US West domain
        AOI.LongName(j,1) = cellstr('Western US');
        AOI.ShortName(j,1) = cellstr('USwest');
        AOI.Type(j,1) = cellstr('region');
        
        %%% lat/lon limites
        AOI.lat_ul(j,1) = 49.10;
        AOI.lat_ll(j,1) = 31.20;
        AOI.lon_ul(j,1) = -101.50;
        AOI.lon_ll(j,1) = -124.80;
    end
    
    
    
end

%%% convert AOI structure to table for convenience of viewing
AOI = struct2table(AOI);

%%% only keep AOI wihere all lat/lon limits are not NaN
a=find(isnan(AOI.lat_ul+AOI.lat_ll+AOI.lon_ul+AOI.lon_ll)==0);
AOI = AOI(a,:);

%%% update nAOI
nAOI = size(AOI,1);

%%% update all snow database w/ states and hucs
if flag_names_huc_state==0
    save(all_database, 'SNOW');
end

