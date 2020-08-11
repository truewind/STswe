clear; close all;


%% loading

%%% load settings
snowtoday_settings;

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
for q=1:numel(AOI)
    
    %%% get number for this site
    j = AOI(q);
    
    figure(j);
    
    %%% get plotting limits and spatial domain
    plot_lat_ll = lat_ll(j);
    plot_lat_ul = lat_ul(j);
    plot_lon_ll = lon_ll(j);
    plot_lon_ul = lon_ul(j);
    plot_sdomain = sdomain(j);
    
    %%% subset to this area of interest
    a = find(SNOW.STA_LAT>=plot_lat_ll & SNOW.STA_LAT<=plot_lat_ul & SNOW.STA_LON >= plot_lon_ll & SNOW.STA_LON <= plot_lon_ul);
    sLAT = SNOW.STA_LAT(a);
    sLON = SNOW.STA_LON(a);
    pSWE = SNOW.dSWE_clr(a);
    
    
    %% plot station locations
    
    %%% construct map
    ax = usamap(plot_sdomain);
    
    %%% set ax to invisible
    set(ax, 'Visible', 'off')
    
    %%% specify grid (none for western US, grid for specific states)
    if j==1
        axesm('MapProjection','utm','grid','off')
    else
        axesm('MapProjection','utm','grid','on')
    end
    
    %%% set lat/lon limits
    setm(ax, 'MapLatLimit', [plot_lat_ll plot_lat_ul]);
    setm(ax, 'MapLonLimit', [plot_lon_ll plot_lon_ul]);
    
    %%% read shapefile and plot on map
    states = shaperead('usastatehi','UseGeoCoords', true);
    geoshow(ax, states, 'FaceColor', 'none');
    
    hold on
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
  
    
    %%% annotations
    title({'Change in SWE (inches) in past 24 hours'; ['\rmPlot created: ' datestr(now, 'ddd mmm dd yyyy HH:MM PM') ' MT']; ['Data updated: ' datestr(datenum(iYR, iMO, iDA), 'ddd mmm dd yyyy HH:MM PM') ' MT']})
    
    colormap(cmap);
    cb=colorbar('SouthOutside');
    set(cb,'Xtick', linspace(0,1,numel(cbinLab)));
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
    cd(path_staging); % need to avoid  cd'ing... just write with full path
    if j==1
        slocation =''; % do not append a location for western US map
    else
        slocation = ['_' char(plot_sdomain)];
    end
    print([datestr(datenum(iYR, iMO, iDA),'yyyymmdd') 'inputs_createdOn' datestr(datenum(now),'yyyymmdd')  '_dSWE' slocation],'-dpng','-r200')
    cd(path_root);  % see above... change and remove this.
end