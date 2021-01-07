%%% this script assembles the spatial info for the maps, including the
%%% ShortName, LongName, and lat/lon limits


%% load common settings

snowtoday_settings;

%% read shapefiles and tables

%%% read each separately...  add more if we get other HUCs / counties
% shp_states = shaperead(path_shp_states);
% shp_huc02 = shaperead(path_shp_huc02);
shp_states = load(path_mask_states);
shp_states = shp_states.S;
shp_huc02 = load(path_mask_huc02);
shp_huc02 = shp_huc02.S;

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
        a = find(tab_political.Var1==curr_AOI);
        
        %%% determine whether it is a state or county. Assign the shortname
        %%% and longname
        if curr_AOI<100
            AOI.Type(j) = cellstr('state');
            
            %%% get LongName and ShortName (state abbreviation)
            AOI.LongName(j,1) = tab_political.Var2(a);
            AOI.ShortName(j,1) = cellstr(['US' char(tab_political.Var3(a))]);
            
            
            %%% get the lat/lon limits based on the shapefile
            a = find(strcmp({shp_states.STATE}.', AOI.LongName(j,1))==1);
            
            %%% if found a match, get the bounding box
            if isempty(a)==0
                BoundingBox = shp_states(a).BoundingBox;
                
                %%% lat/lon limits
                AOI.lat_ul(j,1) = nanmax(BoundingBox(:,2));
                AOI.lat_ll(j,1) = nanmin(BoundingBox(:,2));
                AOI.lon_ul(j,1) = nanmax(BoundingBox(:,1));
                AOI.lon_ll(j,1) = nanmin(BoundingBox(:,1));
                
                AOI.shp_recNum(j,1) = a;
            end
            

        else
            AOI.Type(j) = cellstr('county');
            
            %%% get LongName and ShortName (state abbreviation)
            county_Long = [char(tab_political.Var2(a)) ', ' char(tab_political.Var3(a))];
            county_Short = ['US' char(tab_political.Var3(a)) num2str(tab_political.Var1(a))];
            AOI.LongName(j,1) = cellstr(county_Long);
            AOI.ShortName(j,1) = cellstr(county_Short);
            
            %%% 
            error('need to code this in if/when we get a county shapefile')
        end
        
        
        
        
    elseif curr_AOI>0
        % then this is a HUC
        
        %%% find this state in the political table
        a = find(tab_huc.Var1==curr_AOI);
        
        %%% store long name
        AOI.LongName(j,1) = cellstr([char(tab_huc.Var2(a)) ' (HUC code: ' num2str(tab_huc.Var1(a)) ')']);
        
        %%% determine HUC level and get the lat/lon max and min
        numHUC = tab_huc.Var1(a);
        if numHUC<10^2
            AOI.Type(j) = cellstr('HUC02');
            
            %%% get the lat/lon limits based on the shapefile
            a = find(strcmp({shp_huc02.huc2}.', num2str(numHUC))==1);
            
            %%% if found a match, get the bounding box
            if isempty(a)==0
                BoundingBox = shp_huc02(a).BoundingBox;
                
                %%% lat/lon limits
                AOI.lat_ul(j,1) = nanmax(BoundingBox(:,2));
                AOI.lat_ll(j,1) = nanmin(BoundingBox(:,2));
                AOI.lon_ul(j,1) = nanmax(BoundingBox(:,1));
                AOI.lon_ll(j,1) = nanmin(BoundingBox(:,1));
                
                AOI.shp_recNum(j,1) = a;
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
        
        %%% store shortname
        AOI.ShortName(j,1) = cellstr(['HUC' num2str(numHUC)]);
        

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
