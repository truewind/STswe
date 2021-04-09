clear; close all;


%% loading

%%% load settings
snowtoday_settings;

%%% setup the spatial settings based on Areas of Interest
snowtoday_spatial;

%%% load the database
load(all_database);

%% get change in SWE for this date

%%% current date (now)
xSD = floor(now);

%%% check to make sure we have enough stations reporting data on this date.
%%% if not, move backwards in time until satisfied
flag_date = 1;
while flag_date==1
    a = find(SNOW.TIME(:,sdate_col)==xSD);
    
    SWE2 = SNOW.WTEQ_mm(a,:);
    SWE2 = ~isnan(SWE2);
    
    %%% note this should be it's own utility function (check for
    %%% completeness)
    if nansum(SWE2)./numel(SWE2)>=minSTAdata
        flag_date=0;
    else
        xSD = xSD-1;
    end
end

%%% get year, month, day
[iYR, iMO, iDA, ~, ~, ~] = datevec(xSD);

%%% find this date in the record
a = find(SNOW.TIME(:,year_col)==iYR & SNOW.TIME(:,month_col)==iMO & SNOW.TIME(:,day_col)==iDA);

%%% get SWE at current date (c), yesterday (y), and change in swe (dSWE)
SWEc = SNOW.WTEQ_mm(a,:);
SWEy = SNOW.WTEQ_mm(a-1,:);
dSWE = SWEc-SWEy;

% remove any changes of 5 mm (1/5 inch) or less
a = find(abs(dSWE)<QC.min_dSWE);
dSWE(a) = 0;

% convert dSWE from mm to inches for plotting purposes
dSWE = mm2in(dSWE);

% store the data (1 x nsta) in the structure. don't know why.
SNOW.dSWE = dSWE;   % change in SWE


%% plotting

close all;

%%% load colorbar for dSWE
snowtoday_colorbar_dSWE;

%%% map dSWE to color bins
SNOW.dSWE_clr = SNOW.dSWE .* NaN;
for j=1:ncol
    if j==1
        a = find(SNOW.dSWE<cbins(j));
    elseif j==ncol
        a = find(SNOW.dSWE>=cbins(j-1));
    else
        a = find(SNOW.dSWE>=cbins(j-1) & SNOW.dSWE<cbins(j));
    end
    SNOW.dSWE_clr(a) = j;
end

%%% override the color for any zero values (set to middle color)
a = find(SNOW.dSWE==0);
col_zero = ceil(ncol/2);
SNOW.dSWE_clr(a) = col_zero;

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
    if strcmp(ShortName, 'USwest')~=1
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
    
    
    %% plot station locations
    
    %%% start a new figure
    figure;
    
    %%% construct map. use conus as default
    ax = usamap('conus');
    
    %%% set ax to invisible
    set(ax, 'Visible', 'off')
    
    %%% specify projection and turn off grid
    if strcmp(ShortName, 'USwest')==1
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
    if strcmp(ShortName, 'USwest')~=1
        
        if strcmp(Type, 'state')==1
            feat_lat = shp_states.S(shp_recNum).Y;
            feat_lon = shp_states.S(shp_recNum).X;
        elseif strcmp(Type, 'HUC02')==1
            feat_lat = shp_huc02.S(shp_recNum).Y;
            feat_lon = shp_huc02.S(shp_recNum).X;
        end
        geoshow(feat_lat, feat_lon, 'LineStyle', '-', 'Color', 'r', 'LineWidth', 1.5)
    end
    
    
    %%%  generate map if stations found in this domain... otherwise, text
    hold on
    
    if isempty(a)==0
        
        sLAT = SNOW.STA_LAT(a);
        sLON = SNOW.STA_LON(a);
        pSWE = SNOW.dSWE_clr(a);

        
        %%% loop through color bar and plot sites in each category
        for k=1:ncol
            
            if k==col_zero
                % don't plot it in loop. plot in k=1 (so will be in back)
            else
                
                if k==1
                    %%% plot zero values first (make as smaller markers)
                    a = find(pSWE==col_zero);
                    geoshow(sLAT(a), sLON(a), 'LineStyle', 'none', 'Marker', 'o', 'MarkerFaceColor', cmap(k,:), 'MarkerEdgeColor', 'none', 'MarkerSize', 1); % cmap(k,:), 'MarkerSize', 4)
                end
                
                %%% use some trickery here to plot. plot overlapping markers, with
                %%% background one slightly larger and with marker edge. the
                %%% default marker edge is too thick IMO, so this helps to reduce
                %%% the edge width
                a = find(pSWE==k);
                geoshow(sLAT(a), sLON(a), 'LineStyle', 'none', 'Marker', 'o', 'MarkerFaceColor', cmap(k,:), 'MarkerEdgeColor', 'k', 'MarkerSize', 3.3, 'LineWidth', 0.5); % cmap(k,:), 'MarkerSize', 4)
                geoshow(sLAT(a), sLON(a), 'LineStyle', 'none', 'Marker', 'o', 'MarkerFaceColor', cmap(k,:), 'MarkerEdgeColor', 'none', 'MarkerSize', 3, 'LineWidth', 0.5);
                
            end
        end
    else
        %%% no stations... plot text instead
        textm(nanmean(feat_lat), nanmean(feat_lon), 'No SWE stations', 'HorizontalAlignment', 'center', 'FontSize', 10)
    end
    
    
    %%% annotations
    title({'Change in SWE (inches) in past 24 hours'; ['\rmPlot created: ' datestr(now, 'ddd mmm dd yyyy HH:MM PM') ' MT']; ['Data updated: ' datestr(datenum(iYR, iMO, iDA), 'ddd mmm dd yyyy HH:MM PM') ' MT']})
    
    
    
    colormap(cmap);
    cb=colorbar('SouthOutside');
    set(cb,'Xtick', linspace(0,1,numel(cbinLab)));
    set(cb,'XtickLabel', cbinLab);
    
    
    %     lgd=legend(hEco, 'mountains', 'Location', 'SouthOutside');
    %     legend boxoff
    %     lgd.FontSize = 8;
    
    
    
    
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
    
    
    cd(path_staging); % need to avoid  cd'ing... just write with full path
    
    print([datestr(datenum(iYR, iMO, iDA),'yyyymmdd') 'inputs_createdOn' datestr(datenum(now),'yyyymmdd') '_' ShortName  '_dSWE'],'-dpng','-r200')
    cd(path_root);  % see above... change and remove this.
    
    
    %% create text file with summmary of data for this Area of Interest for current WY to date
    
    
end