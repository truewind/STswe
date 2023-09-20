% this functions creates the standard plot for the Snow Today SWE figures

function plot_swe_stations(idomain, STA_LAT, STA_LON, STA_CLR, cmap, ptitle, cb_xtick, cb_xtick_lab, col_zero, cb_xlabel, noSNOW)

%%% load settings
snowtoday_settings;


figure;

% figure(fignum);
% for ii = 1:spn
%     ax(ii) = subaxis(spr,spc,ii,'sp',0,'mar',0); % FEX #3696
% end

% subplot(spr,spc,spn);
% gcf;

if idomain==1
    %%% western USA
    sdomain = {'conus'};
    lat_ul = 49.10;
    lat_ll = 31.20;
    lon_ll = -124.80;
    lon_ul = -101.50;
elseif idomain==2
    %%% Colorado
    sdomain = {'CO'};
    lat_ul = 41.10;
    lat_ll = 36.75;
    lon_ll = -109.2;
    lon_ul = -101.5;
elseif idomain==3
    %%% Montana
    sdomain = {'MT'};
    lat_ul = 49.10;
    lat_ll = 44.10;
    lon_ll = -116.15;
    lon_ul = -103.90;
elseif idomain==4
    %%% Oregon
    sdomain = {'OR'};
    lat_ul = 46.35;
    lat_ll = 41.90;
    lon_ll = -124.70;
    lon_ul = -116.20;
elseif idomain==5
    %%% Utah
    sdomain = {'UT'};
    lat_ul = 42.10;
    lat_ll = 36.90;
    lon_ll = -114.15;
    lon_ul = -108.90;
elseif idomain==6
    %%% Wyoming
    sdomain = {'WY'};
    lat_ul = 45.10;
    lat_ll = 40.90;
    lon_ll = -111.15;
    lon_ul = -103.95;
elseif idomain==7
    %%% Arizona
    sdomain = {'AZ'};
    lat_ul = 37.10;
    lat_ll = 31.20;
    lon_ll = -115.10;
    lon_ul = -108.90;
elseif idomain==8
    %%% Idaho
    sdomain = {'ID'};
    lat_ul = 49.10;
    lat_ll = 41.90;
    lon_ll = -117.25;
    lon_ul = -110.90;
elseif idomain==9
    %%% New Mexico
    sdomain = {'NM'};
    lat_ul = 37.10;
    lat_ll = 31.20;
    lon_ll = -109.15;
    lon_ul = -102.90;
elseif idomain==10
    %%% California
    sdomain = {'CA'};
    lat_ul = 42.10;
    lat_ll = 32.40;
    lon_ll = -124.40;
    lon_ul = -114.00;
elseif idomain==11
    %%% Washington
    sdomain = {'WA'};
    lat_ul = 49.10;
    lat_ll = 45.40;
    lon_ll = -124.80;
    lon_ul = -116.90;
end

%%% subset
a = find(STA_LAT>=lat_ll & STA_LAT<=lat_ul & STA_LON >= lon_ll & STA_LON <= lon_ul);
sLAT = STA_LAT(a);
sLON = STA_LON(a);
pSWE = STA_CLR(a);

noSNOW = noSNOW(a);
noSNOW = find(noSNOW==1);

%% plot station locations

flag_zero = zeros(1,numel(cb_xtick));
if isempty(col_zero)==0
    flag_zero(col_zero)=1;
end



ax = usamap(sdomain);

set(ax, 'Visible', 'off')

if idomain==1
    axesm('MapProjection','utm','grid','off')
else
    axesm('MapProjection','utm','grid','on')
end

setm(ax, 'MapLatLimit', [lat_ll lat_ul]);
setm(ax, 'MapLonLimit', [lon_ll lon_ul]);


states = shaperead('usastatehi',...
    'UseGeoCoords', true); %, 'BoundingBox', [lonlim', latlim']);
geoshow(ax, states, 'FaceColor', 'none')


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
% set(gcf,'renderer','opengl'); % might need this at the end??

hold on

%%% no snow stations
if isempty(noSNOW)==0
    noSWE=geoshow(sLAT(noSNOW), sLON(noSNOW), 'Marker', 'x', 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k', 'MarkerSize', 5, 'LineStyle', 'none');  % marker size was 3 for X, but increased and changed from k color to 0.5 gray
end


%%% marker stations
for k=1:size(cmap,1)
    
    if flag_zero(k)==0
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
end



%%% annotations
title(ptitle)

colormap(cmap);
cb=colorbar('SouthOutside');
set(cb,'Xtick', cb_xtick);
set(cb,'XtickLabel', cb_xtick_lab);
xlabel(cb, cb_xlabel);

if isempty(noSNOW)==0
    lgd=legend([noSWE hEco], 'no snow', 'mountains', 'Location', 'SouthWest');
else
    lgd=legend(hEco, 'mountains', 'Location', 'SouthWest');
end
legend boxoff
lgd.FontSize = 8;
set(lgd,'position',[0.19,0.17,0.1,0.1])

%% formatting
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