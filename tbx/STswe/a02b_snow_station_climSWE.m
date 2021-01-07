clear; close all;


%% loading

%%% load settings
snowtoday_settings;

%%% setup the spatial settings based on Areas of Interest
snowtoday_spatial;

%%% load the database
load(all_database);

%% get percent of normal for this date

%%% current date (now)
xSD = floor(now);

%%% check to make sure we have enough stations reporting data on this date. if not, move
%%% backwards in time until satisfied
flag_date = 1;
while flag_date==1
    a = find(SNOW.TIME(:,7)==xSD);
    
    SWE2 = SNOW.WTEQ_mm(a,:);
    SWE2 = isnan(SWE2);
    SWE2 = abs(SWE2-1);
    
    if nansum(SWE2)./numel(SWE2)>=minSTAdata
        flag_date=0;
    else
        xSD = xSD-1;
        
    end
end

%%% get year, month, day
[iYR, iMO, iDA, ~, ~, ~] = datevec(xSD);

%%% find all rows in record with this month/day. set exception if leap year
%%% (use Feb 28 instead).
if iMO==2 && iDA==29
    a = find(SNOW.TIME(:,2)==iMO & SNOW.TIME(:,3)==28); % compare to Feb 28 instead of 29
else
    a = find(SNOW.TIME(:,2)==iMO & SNOW.TIME(:,3)==iDA); % otherwise, compare on this date
end

%%% extract all SWE on this date in the record and QC
TIME = SNOW.TIME(a,:);
SWE = SNOW.WTEQ_mm(a,:);

%%% find number of years w/ data on this date and find sites w/ enough
%%% years (goodSites)
SWE2 = SWE;
SWE2(SWE2>0) = 1;  % should this be >= ?? need to include zero SWE.
SWE2=nansum(SWE2,1);
goodSites = find(SWE2>=minYrs);

%%% get current (c) SWE data at good sites
a = find(SNOW.TIME(:,1)==iYR & SNOW.TIME(:,2)==iMO & SNOW.TIME(:,3)==iDA);
SWEc = SNOW.WTEQ_mm(a,goodSites);  % redundant from above? see line 48

%%% compute median SWE for this date at all good sites
SWE3 = nanmedian(SWE(:,goodSites));
SWE3 = round(100.*SWEc./SWE3);

%%% convert current SWE to percent of median SWE
SNOW.SWE_pnrm = SNOW.WTEQ_mm(end,:).*NaN;
SNOW.SWE_pnrm(1,goodSites) = SWE3;   % percent of median normal SWE



%% plotting

close all;

%%% load colorbar for climatological SWE
snowtoday_colorbar_climSWE;


%%% map percent of median normal SWE to color bins
SNOW.SWE_pnrm_clr = SNOW.SWE_pnrm .* NaN;
SNOW.SWE_pnrm_clr(SNOW.SWE_pnrm<45) = 1;
SNOW.SWE_pnrm_clr(SNOW.SWE_pnrm>=45 & SNOW.SWE_pnrm<55) = 2;
SNOW.SWE_pnrm_clr(SNOW.SWE_pnrm>=55 & SNOW.SWE_pnrm<65) = 3;
SNOW.SWE_pnrm_clr(SNOW.SWE_pnrm>=65 & SNOW.SWE_pnrm<75) = 4;
SNOW.SWE_pnrm_clr(SNOW.SWE_pnrm>=75 & SNOW.SWE_pnrm<85) = 5;
SNOW.SWE_pnrm_clr(SNOW.SWE_pnrm>=85 & SNOW.SWE_pnrm<95) = 6;
SNOW.SWE_pnrm_clr(SNOW.SWE_pnrm>=95 & SNOW.SWE_pnrm<105) = 7;
SNOW.SWE_pnrm_clr(SNOW.SWE_pnrm>=105 & SNOW.SWE_pnrm<115) = 8;
SNOW.SWE_pnrm_clr(SNOW.SWE_pnrm>=115 & SNOW.SWE_pnrm<125) = 9;
SNOW.SWE_pnrm_clr(SNOW.SWE_pnrm>=125 & SNOW.SWE_pnrm<135) = 10;
SNOW.SWE_pnrm_clr(SNOW.SWE_pnrm>=135 & SNOW.SWE_pnrm<145) = 11;
SNOW.SWE_pnrm_clr(SNOW.SWE_pnrm>=145 & SNOW.SWE_pnrm<165) = 12;
SNOW.SWE_pnrm_clr(SNOW.SWE_pnrm>=165) = 13;


%%% cycle through Areas of Interest (AOI)
for j=1:nAOI
    
    
    %%% get other info for this AOI
    ShortName = char(AOI.ShortName(j));
    LongName = char(AOI.LongName(j));
    Type = AOI.Type(j);
    shp_recNum = AOI.shp_recNum(j);
    
    %%% get plotting limits and spatial domain
    plot_lat_ll = AOI.lat_ll(j);
    plot_lat_ul = AOI.lat_ul(j);
    plot_lon_ll = AOI.lon_ll(j);
    plot_lon_ul = AOI.lon_ul(j);
    
    %%% expand upper/lower limits of lat/lon for buffer
    if strcmp(ShortName, 'USWEST')~=1
        range_lat = abs(plot_lat_ul - plot_lat_ll);
        range_lon = abs(plot_lon_ul - plot_lon_ll);
        plot_lat_ll = plot_lat_ll - (range_lat.*lat_buff);
        plot_lat_ul = plot_lat_ul + (range_lat.*lat_buff);
        plot_lon_ll = plot_lon_ll - (range_lon.*lon_buff);
        plot_lon_ul = plot_lon_ul + (range_lon.*lon_buff);
    end
    
    %%% change plot lon/lat to meet target aspect ratio
    range_lat = abs(plot_lat_ul - plot_lat_ll);
    range_lon = abs(plot_lon_ul - plot_lon_ll);
    center_lat = nanmean([plot_lat_ul plot_lat_ll]);
    center_lon = nanmean([plot_lon_ul plot_lon_ll]);
    if range_lon./range_lat>latlon_aspRatio
        %%% need to expand lat ul and ll to make it fit
        range_lat = abs(range_lon./latlon_aspRatio);
        plot_lat_ul = center_lat + (range_lat/2);
        plot_lat_ll = center_lat - (range_lat/2);
    elseif range_lon./range_lat<latlon_aspRatio
        %%% need to expand lon ul and ll to make it plot right
        range_lon = abs(range_lat.*latlon_aspRatio);
        plot_lon_ul = center_lon + (range_lon/2);
        plot_lon_ll = center_lon - (range_lon/2);
    end
    
    %%% subset to this area of interest
    a = find(SNOW.STA_LAT>=plot_lat_ll & SNOW.STA_LAT<=plot_lat_ul & SNOW.STA_LON >= plot_lon_ll & SNOW.STA_LON <= plot_lon_ul);
    
    %%% only generate map if stations found in this domain
    if isempty(a)==1
        disp('... no map generated because no stations here'
    else
        
        sLAT = SNOW.STA_LAT(a);
        sLON = SNOW.STA_LON(a);
        pSWE = SNOW.SWE_pnrm_clr(a);
        
        
        %% plot station locations
        
        %%% start a new figure
        figure;
        
        %%% construct map. use conus as default
        ax = usamap('conus');
        
        %%% set ax to invisible
        set(ax, 'Visible', 'off')
        
        %%% specify projection and turn off grid
        if strcmp(ShortName, 'USWEST')==1
            frame_opt='off';
        else
            frame_opt='on';
        end
        axesm('MapProjection','utm','grid','off', 'frame', frame_opt)
        
        %%% set lat/lon limits
        setm(ax, 'MapLatLimit', [plot_lat_ll plot_lat_ul]);
        setm(ax, 'MapLonLimit', [plot_lon_ll plot_lon_ul]);
        
        
        %%% read shapefile and plot on map
        states = shaperead('usastatehi','UseGeoCoords', true);
        hstates=geoshow(ax, states, 'FaceColor', 'none');
        set(hstates,'Clipping','on');
        
        %%% display the ecoregions to highlight mountain areas
        ecoR = shaperead(path_shp_ecoregions);
        oldField = 'X';
        newField = 'Lon';
        [ecoR.(newField)] = ecoR.(oldField);
        ecoR = rmfield(ecoR,oldField);
        oldField = 'Y';
        newField = 'Lat';
        [ecoR.(newField)] = ecoR.(oldField);
        ecoR = rmfield(ecoR,oldField);
        hEco=geoshow(ax, ecoR, 'FaceColor', [0.1 0.5 0.1], 'EdgeColor', 'none', 'facealpha',.3);
        
        
        %%% plot red outline of the shapefile (state or HUC) to highlight
        if strcmp(ShortName, 'USWEST')~=1
            
            if strcmp(Type, 'state')==1
                feat_lat = shp_states(shp_recNum).Y;
                feat_lon = shp_states(shp_recNum).X;
            elseif strcmp(Type, 'HUC02')==1
                feat_lat = shp_huc02(shp_recNum).Y;
                feat_lon = shp_huc02(shp_recNum).X;
            end
            geoshow(feat_lat, feat_lon, 'LineStyle', '-', 'Color', 'r', 'LineWidth', 1.5)
        end
        
        
        hold on
        %%% loop through color bar and plot sites in each category
        for k=1:ncol
            
            if k==1
                %%% plot a small marker at all sites first
                geoshow(sLAT, sLON, 'LineStyle', 'none', 'Marker', 'o', 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'none', 'MarkerSize', 1); % cmap(k,:), 'MarkerSize', 4)
            end
            
            
            a = find(pSWE==k);
            
            %%% use some trickery here to plot. plot overlapping markers, with
            %%% background one slightly larger and with marker edge. the
            %%% default marker edge is too thick IMO, so this helps to reduce
            %%% the edge width
            geoshow(sLAT(a), sLON(a), 'LineStyle', 'none', 'Marker', 'o', 'MarkerFaceColor', cmap(k,:), 'MarkerEdgeColor', 'k', 'MarkerSize', 3.3, 'LineWidth', 0.5)
            geoshow(sLAT(a), sLON(a), 'LineStyle', 'none', 'Marker', 'o', 'MarkerFaceColor', cmap(k,:), 'MarkerEdgeColor', 'none', 'MarkerSize', 3, 'LineWidth', 0.5)
            
        end
        
        
        
        %%% annotations
        title({'Percentage of Median (25+yr) SWE'; ['\rmPlot created: ' datestr(now, 'ddd mmm dd yyyy HH:MM PM') ' MT']; ['Data updated: ' datestr(datenum(iYR, iMO, iDA), 'ddd mmm dd yyyy HH:MM PM') ' MT']})
        
        colormap(cmap);
        cb=colorbar('SouthOutside');
        set(cb,'Xtick', linspace(0,1,14));
        set(cb,'XtickLabel', cbinLab);
        
        
        
        
        %% create png file
        fig = gcf;
        axis tight
        
        %%% the following is supposed to reduce white space around the figure
        ax = gca;
        outerpos = ax.OuterPosition;
        ti = ax.TightInset;
        left = outerpos(1) + ti(1);
        bottom = outerpos(2) + ti(2);
        ax_width = outerpos(3) - ti(1) - ti(3);
        ax_height = outerpos(4) - ti(2) - ti(4);
        ax.Position = [left bottom ax_width ax_height];
        
        
        fig.PaperUnits = 'inches';
        fig.PaperPosition = [0 0 5 5];
        set(gcf, 'Renderer', 'zbuffer');
        
        %%% now that the figure is sized, add ylabel-like text for LongName
        xl=get(gca,'xlim');
        yl = get(gca,'ylim');
        ht=text( xl(1) -((xl(2)-xl(1))*0.05), yl(1) +((yl(2)-yl(1))*0.05), LongName);
        set(ht,'Rotation',90);
        
        
        
        cd(path_staging);  % do not CD in... write directly with path
        
        print([datestr(datenum(iYR, iMO, iDA),'yyyymmdd') 'inputs_createdOn' datestr(datenum(now),'yyyymmdd') '_' ShortName '_normSWE'],'-dpng','-r200')
        cd(path_root);
    end
end
