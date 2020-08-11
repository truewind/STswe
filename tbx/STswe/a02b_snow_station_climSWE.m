clear; close all;


%% loading

%%% load settings
snowtoday_settings;

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
    pSWE = SNOW.SWE_pnrm_clr(a);
    
    
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
    for k=1:13
        
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
    cd(path_staging);  % do not CD in... write directly with path
    if j==1
        slocation =''; % do not append a location for western US map
    else
        slocation = ['_' char(plot_sdomain)];
    end
    print([datestr(datenum(iYR, iMO, iDA),'yyyymmdd') 'inputs_createdOn' datestr(datenum(now),'yyyymmdd')  '_normSWE' slocation],'-dpng','-r200')
    cd(path_root);  
end
