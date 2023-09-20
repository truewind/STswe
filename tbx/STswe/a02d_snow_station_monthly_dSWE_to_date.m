clear; close all

%%% this script creates various plots which can be useful for the monthly
%%% post

%% loading

%%% load settings
snowtoday_settings;

%%% setup the spatial settings based on Areas of Interest
snowtoday_spatial;

%%% load the database
load(all_database);


%% settings for this script

%%% set minimum daily change in SWE (mm)... helps remove noise
min_dSWE = 5;

%%% set max monthly dSWE
max_dSWE = 3000;

%%% set max missing days
max_missing = 5;

%% setup date
%%% current date (now)
% xSD = floor(now);
xSD = datenum(2023,4,15); disp('OVERRIDE ON DATE')

%%% get the current year, month, and day to review
[r_year,r_month,r_day,~,~,~] = datevec(xSD);


if r_month>=10
    cWY = r_year+1;
else
    cWY = r_year;
end

%%% ensure that we do not have future dates
ind1 = 1;
ind2 = find(SNOW.TIME(:,end)==xSD);
SNOW.TIME = SNOW.TIME(ind1:ind2,:);
SNOW.WTEQ_mm = SNOW.WTEQ_mm(ind1:ind2,:);

%%% if missing SWE data on xSD but not the previous day, use the previous
%%% day's value?
if toggle_carryPrevSWE==1
    a = find(isnan(SNOW.WTEQ_mm(ind2,:))==1 & isnan(SNOW.WTEQ_mm(ind2-1,:))==0);
    if isempty(a)==0
        SNOW.WTEQ_mm(ind2,a) = SNOW.WTEQ_mm(ind2-1,a);
    end
end

%% monthly analysis

%%% only keep stations that do not exceed max_missing days
a = find(SNOW.TIME(:,2)==r_month & SNOW.TIME(:,1)==r_year);
SWEc = SNOW.WTEQ_mm(a,:);
SWEc = isnan(SWEc);
SWEc = nansum(SWEc);
badsites = find(SWEc>max_missing);
SNOW.WTEQ_mm(:,badsites)  = NaN;


%%% break SWE time series into accumulation and melt components
[acc,mlt] = SWEcomp(SNOW.WTEQ_mm);
mlt = abs(mlt);
acc(acc<min_dSWE) = 0;
mlt(mlt<min_dSWE) = 0;
acc(acc>max_dSWE) = NaN;
mlt(mlt>max_dSWE) = NaN;


%%% save a copy that will be used to look at mean storm intensity
acc2 = acc;
acc2(acc2==0) = NaN;
[monthly_mean_snowAccum, agg_yr, agg_month]=aggMON(SNOW.TIME, acc2, 1, 2);
a = find(agg_yr==r_year & agg_month==r_month);
iM_acc_mean = monthly_mean_snowAccum(a,:);

%%% summarize accumulation on a monthly basis
[monthly_total_snowAccum, agg_yr, agg_month]=aggMON(SNOW.TIME, acc, 5, 2);
a = find(agg_yr==r_year & agg_month==r_month);
iM_acc = monthly_total_snowAccum(a,:);

%%% summarize melt
[monthly_total_snowMelt, agg_yr, agg_month]=aggMON(SNOW.TIME, mlt, 5, 2);
a = find(agg_yr==r_year & agg_month==r_month);
iM_mlt = monthly_total_snowMelt(a,:);


%%% get delta SWE for the month. don't take straight from SWE record, but rather
%%% off cumulative snowfall and melt, so we are consistent
iM_dSWE = iM_acc-iM_mlt;

%% unit conversion

if strcmp(units_figs_text, 'cm')==1
    % convert SWE from mm to cm
    div_factor = 10;
elseif strcmp(units_figs_text, 'in')==1
    % convert SWE from mm to in
    div_factor = 25.4;
else
    % leave SWE in mm
    div_factor = 1;
end
iM_dSWE = iM_dSWE./div_factor;
iM_acc = iM_acc./div_factor;
iM_mlt = iM_mlt./div_factor;

%% plot delta SWE through the course of this month

SNOW.dSWE = iM_dSWE;

%%% pick limits for the data (in inches SWE)
pct = 80;  %nominally 80
p_acc=ceil(prctile(iM_acc, pct));
p_acc=nanmax([p_acc 1]);
p_mlt=ceil(prctile(iM_mlt, pct));
p_mlt=nanmax([p_mlt 1]);
% plim = nanmax([p_acc_90 p_mlt_90]);

nc = 6;
% cbins = [linspace(-30,0,nc), linspace(0,1,nc)];  % May 2023 override (inches)
cbins = [linspace(-1.*p_mlt,0,nc), linspace(0,p_acc,nc)]; 
ncol = numel(cbins)+1;
cbinLab = cell(1,ncol);
cmap = cbrewer('div', 'RdBu', ncol); 
cmap(nc+1,:) = [0 0 0]; % set zeros to black

for j=1:numel(cbinLab)-1
    cbinLab(j) = cellstr(num2str(cbins(j)));
end
cbinLab = [cellstr('loss') cbinLab];
cbinLab(end) = {'gain'};

%%% convert dSWE to color bins
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

idomain =1;
ptitle = {'Net Change in Snow Water Equivalent (SWE),'; ['from ' char(num2month(r_month)) ' 1 to ' char(num2month(r_month)) ' ' num2str(r_day) ', ' num2str(r_year)]};
cb_xtick = linspace(0,1,numel(cbinLab));
cb_xlabel = units_figs_text;

noSNOW = SNOW.dSWE_clr.*0;
plot_swe_stations(idomain, SNOW.STA_LAT, SNOW.STA_LON, SNOW.dSWE_clr, cmap, ptitle, cb_xtick, cbinLab, col_zero, cb_xlabel, noSNOW);

fig= gcf;
fig.PaperUnits = 'inches';
fig.PaperPosition = [0 0 5 5];
set(gcf, 'Renderer', 'zbuffer');

xl=get(gca,'xlim');
yl=get(gca,'ylim');
ht=text(xl(1)+((xl(2)-xl(1))*1.1), yl(1) + ((yl(2)-yl(1))*0.01), ['Credit: ' fig_credit_str ' // Data: USDA NRCS and CA DWR'], 'FontSize', 8, 'HorizontalAlignment', 'left');
set(ht,'Rotation', 90);


pathfile_image = fullfile(path_PL_archive, 'Analysis', [datestr(xSD,'yyyymmdd') 'inputs_createdOn' datestr(datenum(now),'yyyymmdd') '_monthly_dSWE']);
print(pathfile_image,'-dpng','-r200')
print(pathfile_image,'-depsc'); % depsc for color, deps for B&W


%% state-by-state box plot of monthly dSWE

%%% top to bottom state order
countryStateProv = {'USAK', 'CABC', 'USWA', 'USID', 'USMT', 'USOR', 'USWY', 'USSD', 'USCA', 'USNV', 'USUT', 'USCO', 'USAZ', 'USNM'};
stateProv_str = {'Alaska', 'British Columbia', 'Washington', 'Idaho', 'Montana', 'Oregon', 'Wyoming', 'South Dakota', 'California', 'Nevada', 'Utah', 'Colorado', 'Arizona', 'New Mexico'};
stateProv_str = fliplr(stateProv_str);


nstates = numel(stateProv_str);

dSWE_box = nan(300, nstates);  % arbitrary 300 rows.
noSNOW2 = noSNOW;
noSNOW2(noSNOW2==1) = NaN;
noSNOW2(noSNOW2==0) = 1;
figure
hold on
box off
plot([0 0], [-5 nstates+1], '-k')

for j=1:nstates
    %%% current state/prov
    curr_StateProv = char(countryStateProv(j));
    
    %%% find snow stations in this state/province
    in = find(strcmp(SNOW.STA_STATE, curr_StateProv)==1);
    

    p_mn=plot(nanmean(SNOW.dSWE(in).*noSNOW2(in)), j, 'LineStyle', 'none', 'Marker', 'd', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'MarkerSize', 7, 'LineWidth', 1);
    
    for k=1:numel(in)
        
        plot(SNOW.dSWE(in(k)).*noSNOW2(in(k)), j, 'LineStyle', 'none', 'Marker', 'o', 'MarkerFaceColor', cmap(SNOW.dSWE_clr(in(k)),:), 'MarkerEdgeColor', 'k', 'MarkerSize', 3.3, 'LineWidth', 0.5)
    end
    
end

set(gca, 'YTick', 1:nstates)
set(gca, 'YTickLabel', stateProv_str)
ylim([-1.5 0.5+nstates])
title(ptitle)
xlabel(['Change in SWE (' units_figs_text ')'])
quiver(0,0,+3,0, 'b', 'LineWidth', 2')
quiver(0,0,-3,0, 'r', 'LineWidth', 2')
text(3.25,0, '\it gain', 'HorizontalAlignment', 'left', 'FontSize', 10, 'Color', 'b')
text(-3.25,0, '\it loss', 'HorizontalAlignment', 'right', 'FontSize', 10 , 'Color', 'r')
legend([p_mn], 'average', 'Location', 'SouthWest')
legend boxoff
xl = get(gca, 'xlim');
if xl(1)>-10
    xl(1) = -10;
    xlim(xl)
end


fig= gcf;
fig.PaperUnits = 'inches';
fig.PaperPosition = [0 0 4.5 5];
set(gcf, 'Renderer', 'zbuffer');

xl=get(gca,'xlim');
yl=get(gca,'ylim');
ht=text(xl(1)+((xl(2)-xl(1))*1.1), yl(1) + ((yl(2)-yl(1))*0.01), ['Credit: ' fig_credit_str ' // Data: USDA NRCS and CA DWR'], 'FontSize', 8, 'HorizontalAlignment', 'left');
set(ht,'Rotation', 90);

pathfile_image = fullfile(path_PL_archive, 'Analysis', [datestr(xSD,'yyyymmdd') 'inputs_createdOn' datestr(datenum(now),'yyyymmdd') '_monthly_dSWE_boxplot']);
print(pathfile_image,'-dpng','-r200')
print(pathfile_image,'-depsc'); % depsc for color, deps for B&W



