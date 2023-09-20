% Computes various summary metrics for describing a time series of SWE
%
% RELEASE NOTES
%   V1.0 Written by Mark Raleigh (raleigh@ucar.edu), March 2014
%   V1.1 Revised by Mark Raleigh, August 2015 to include a "center of mass (COM)" variable
%   V1.2 Revised by Mark Raleigh, February 2016.  Cleaned up for first GitHub release
%
% SYNTAX
%   [snow_periods, snow_accum, snow_melt, snow_wy] = snow_metrics(TIME, SWE, SWEmin, wy)
%
% INPUTS
%   TIME = either an L-element array of MATLAB datenum formatted times (serial dates) OR Lx7 time matrix (time_builder.m format)
%   SWE  = Lxw array or matrix of SWE
%   SWEmin = 1x1 value, minimum SWE (all values below this will be set to 0). same units as SWE input
%   wy = array of water years of interest (set to 0 to accept all, set to NaN to disable.  best to set to NaN if you have a single snow year, but it overlaps two water years... eg. snow starting in September)
%
% OUTPUTS (structures of snow metrics, each stores as yxw matrices, where y=number of water years)
%   snow_periods = structure defining timing and length of snow periods for each water year, including:
%       (1)  Serial date of 1st snow
%       (2)  Serial date of beginning of longest continous snow (or last snow-free date before peak SWE)
%       (3)  Serial date of peak SWE timing (last day of SWE = peak SWE)
%       (4)  Serial date of 50%  snow disappearance (after peak SWE)
%       (5)  Serial date of 75%  snow disappearance (after peak SWE)
%       (6)  Serial date of 90%  snow disappearance (after peak SWE)
%       (7)  Serial date of 100% snow disappearance (after peak SWE)
%       (8)  Serial date of final snow disappearance
%       (9)  Length of accumulation season, days (3 minus 2)
%       (10) Length of snow melt season, days (7 minus 3)
%       (11) Length of snow season for longest continuous snow cover, days (7 minus 2)
%       (12) Total number of days with snow in the year
%       (13) Center of mass (COM) of snow melt, annual
%   snow_accum = structure defining accumulation season metrics
%       (1) Peak SWE
%       (2) Total Accumulation in accumulation season (prior to peak SWE)
%       (3) Total Mid-Winter melt (cumulative negative SWE changes before peak SWE)
%               *** Peak SWE = accum-melt (during accum season)
%   snow_melt = structure defining accumulation season metrics
%       (1) Mean melt rate from peak SWE to 50%  SDD
%       (2) Mean melt rate from peak SWE to 75%  SDD
%       (3) Mean melt rate from peak SWE to 90%  SDD
%       (4) Mean melt rate from peak SWE to 100% SDD
%       (5) Total melt during the melt season (after peak SWE)
%       (6) Total spring snowfall (cumulative positive SWE changes after peak SWE)
%               *** Peak SWE + accum = melt (during accum season)
%   snow_wy = wx1 array of water years corresponding to the structures



function [snow_periods, snow_accum, snow_melt, snow_wy] = snow_metrics(TIME, SWE, SWEmin, wy)


%% Checks

%%% get dimensions of SWE (L=number of time steps, w = number of sites)
[L,w] = size(SWE);

if size(TIME,2) ~= 1
    % then a Lx7 time matrix may have been input
    if size(TIME,2)==7
        % just keep the column with matlab serial dates
        TIME=TIME(:,7);
    else
    	error('TIME must be a Nx1 array or Nx7 time matrix')
    end
end

%%% make sure we have consistent number or rows
if numel(TIME)~=L
    error('TIME and SWE must have same number of rows')
end

%%% make sure we have a single value for minimum SWE
if numel(SWEmin)~=1
    error('SWEmin must be a 1x1 value')
end

%%% set low snow to 0
SWE(SWE<SWEmin) = 0;


%% Code

%%% find time step (hours)
dt = detect_timestep(TIME);

%%% create table with indices for water years (col 1 = starting index, col 2= ending index, col3= WY)
wy_ind=water_year(TIME);

%%% initialize variable for the water years of interest
snow_wy=[];


if isnan(wy)==1
    % then user input NaN into wy variable
    y=1; % only 1 WY
    snow_wy = wy_ind(end,3);
else
    %%% only keep the years of interest
    for j=1:numel(wy)
        % check to make sure this WY in actually in the record
        if isempty(find(wy_ind(:,3))==wy(j))==0
            % then it is in the record!  store it in snow_wy
            snow_wy = [snow_wy; wy(j)];     % changed from "snow_wy = [snow_wy; wy_ind(:,3)];" on Sept 8 2014 to fix bug (MSR)
        end
    end
    
    %%% find number of water years
    y = size(snow_wy,1);
end




if y==0
    %%% no years found in the recrod!  output and end function
    disp('No years selected in the record!')
    snow_periods = [];
    snow_accum = [];
    snow_melt = [];
    snow_wy = [];
else
    %%% Initialization of structures (period/time metrics)
    snow_periods.sdate_01_1st_snow = zeros(y,w)*NaN;
    snow_periods.sdate_02_1st_snow_cont = zeros(y,w)*NaN;
    snow_periods.sdate_03_peak_swe = zeros(y,w)*NaN;
    snow_periods.sdate_04_melt50  = zeros(y,w)*NaN;
    snow_periods.sdate_05_melt75  = zeros(y,w)*NaN;
    snow_periods.sdate_06_melt90  = zeros(y,w)*NaN;
    snow_periods.sdate_07_melt100 = zeros(y,w)*NaN;
    snow_periods.sdate_08_final_snow = zeros(y,w)*NaN;
    snow_periods.days_09_accumulation = zeros(y,w)*NaN;
    snow_periods.days_10_snowmelt = zeros(y,w)*NaN;
    snow_periods.days_11_snowseason_cont = zeros(y,w)*NaN;
    snow_periods.days_12_allsnowdays = zeros(y,w)*NaN;
    
    %%% Initialization of structures (accumulation season metrics)
    snow_accum.peakSWE = zeros(y,w)*NaN;
    snow_accum.winterAcc = zeros(y,w)*NaN;
    snow_accum.winterMelt = zeros(y,w)*NaN;
    
    %%% Initialization of structures (melt season metrics)
    snow_melt.meanmelt50 = zeros(y,w)*NaN;
    snow_melt.meanmelt75 = zeros(y,w)*NaN;
    snow_melt.meanmelt90 = zeros(y,w)*NaN;
    snow_melt.meanmelt100 = zeros(y,w)*NaN;
    snow_melt.springAcc = zeros(y,w)*NaN;
    snow_melt.springMelt = zeros(y,w)*NaN;
    
    
    %%% loop through the water years
    for j=1:y
        %%% indexing to current WY
        if isnan(wy)==1
            % case with single period of interest (possibly overlapping
            % multiple WY).  basically take indices of full input record
            t1 = wy_ind(1,1);       % start
            t2 = wy_ind(end,2);     % end
        else
            % find indices for current water year
            c_wy = find(wy_ind(:,3)==snow_wy(j));
            t1 = wy_ind(c_wy,1);    % start
            t2 = wy_ind(c_wy,2);    % end
        end
        
        %%% subset SWE matrix and TIME array to current water year 
        cSWE = SWE(t1:t2,:);
        cTIME = TIME(t1:t2);
        
        %%% Peak SWE for all stations in this WY
        snow_accum.peakSWE(j,:) = nanmax(cSWE);
        
        %%% break into SWE components (accumulation or melt)
        [accum, melt] = SWEcomp(cSWE);
        melt = abs(melt);       % make sure positive values for melt
        melt0 = melt;           % save a copy of melt
        accum(accum==0)=NaN;    % set accum 0s to NaNs
        melt(melt==0) = NaN;    % set melt 0s to NaNS
          
        %%% now cycle through stations in this WY
        for k=1:w
            
            %%% check to make sure there are non-NaNs in this record and peak SWE > 0
            if nanmin(isnan(cSWE(:,k)))==0 && nanmax(cSWE(:,k))>0
                
                %%% date of first snow event (sdate_01_1st_snow)
                sdate_01_1st_snow_ind = find(cSWE(:,k) > 0, 1, 'first');
                snow_periods.sdate_01_1st_snow(j,k) = cTIME(sdate_01_1st_snow_ind);
                
                
                %%% peak SWE timing (sdate_03_peak_swe).  defined as the FINAL date of maximum SWE in the season
                sdate_03_peak_swe_ind = find(cSWE(:,k) == snow_accum.peakSWE(j,k), 1,'last');
                snow_periods.sdate_03_peak_swe(j,k) = cTIME(sdate_03_peak_swe_ind);
                
                
                %%% date of start of longest continuous snow (sdate_02_1st_snow_cont)
                sdate_02_1st_snow_cont_ind1 = sdate_03_peak_swe_ind:-1:1;
                sdate_02_1st_snow_cont_ind2 = find(flipud(cSWE(1:sdate_03_peak_swe_ind,k))==0, 1, 'first');
                if isempty(sdate_02_1st_snow_cont_ind2)==1
                    % then could not find date with SWE =0 before longest
                    % continuous snow.  take first day with positive SWE
                    if cSWE(1,k)>0
                        sdate_02_1st_snow_cont_ind = 1; 
                    elseif isnan(cSWE(1,k))==1
                        sdate_02_1st_snow_cont_ind2 = find(flipud(cSWE(1:sdate_03_peak_swe_ind,k))>0, 1, 'first');
                        sdate_02_1st_snow_cont_ind = sdate_02_1st_snow_cont_ind1(sdate_02_1st_snow_cont_ind2);
                    end
                else
                    sdate_02_1st_snow_cont_ind = sdate_02_1st_snow_cont_ind1(sdate_02_1st_snow_cont_ind2);
                end
                
                % MSR commented the next three lines out, August 2016
%                 if isempty(sdate_02_1st_snow_cont_ind)==1 && cSWE(1,k) >0   
%                     sdate_02_1st_snow_cont_ind = 1; 
%                 end
                
                snow_periods.sdate_02_1st_snow_cont(j,k) = cTIME(sdate_02_1st_snow_cont_ind);
                
                
                %%% normalized SWE (for computing dates of 50%, 75%, 90% melt out, etc)
                nSWE = cSWE(:,k)./snow_accum.peakSWE(j,k);
                
                
                %%% date of 100% snowmelt, i.e., first snow-free date after peak SWE. (sdate_07_melt100 )
                sdate_07_melt100_ind = find(cSWE(sdate_03_peak_swe_ind:end,k)==0, 1, 'first') + sdate_03_peak_swe_ind-1;
                if isempty(sdate_07_melt100_ind)==1
                    snow_periods.sdate_07_melt100(j,k)=NaN;
                else
                    snow_periods.sdate_07_melt100(j,k) = cTIME(sdate_07_melt100_ind);
                end
                
                
                %%% dates of 50%, 75%, and 90% melt (sdate_04_melt50, sdate_05_melt75, sdate_06_melt90)
                if isempty(sdate_07_melt100_ind)==1
                    snow_periods.sdate_04_melt50(j,k) = NaN;
                    snow_periods.sdate_05_melt75(j,k) = NaN;
                    snow_periods.sdate_06_melt90(j,k) = NaN;
                else
                    sdate_04_melt50_ind = find(nSWE(1:sdate_07_melt100_ind)>=0.50, 1, 'last');
                    sdate_05_melt75_ind = find(nSWE(1:sdate_07_melt100_ind)>=0.25, 1, 'last');
                    sdate_06_melt90_ind = find(nSWE(1:sdate_07_melt100_ind)>=0.10, 1, 'last');
                    
                    snow_periods.sdate_04_melt50(j,k) = cTIME(sdate_04_melt50_ind);
                    snow_periods.sdate_05_melt75(j,k) = cTIME(sdate_05_melt75_ind);
                    snow_periods.sdate_06_melt90(j,k) = cTIME(sdate_06_melt90_ind);
                end
                
                
                %%% final snow day (sdate_08_final_snow)
                sdate_08_final_snow_ind = find(cSWE(:,k)>0, 1, 'last');
                snow_periods.sdate_08_final_snow(j,k) = cTIME(sdate_08_final_snow_ind)+(dt/24);
                
                
                %%% length of accumulation (days_09_accumulation), melt (days_10_snowmelt), 
                %%%    continuous snow season (days_11_snowseason_cont) and total snow days (days_12_allsnowdays)
                snow_periods.days_09_accumulation(j,k) = snow_periods.sdate_03_peak_swe(j,k) - snow_periods.sdate_02_1st_snow_cont(j,k);
                if isempty(sdate_07_melt100_ind)==1
                    snow_periods.days_10_snowmelt(j,k) = NaN;
                    snow_periods.days_11_snowseason_cont(j,k) = NaN;
                else
                    snow_periods.days_10_snowmelt(j,k) = snow_periods.sdate_07_melt100(j,k) - snow_periods.sdate_03_peak_swe(j,k);
                    snow_periods.days_11_snowseason_cont(j,k) = snow_periods.sdate_07_melt100(j,k) - snow_periods.sdate_02_1st_snow_cont(j,k);
                end
                snow_periods.days_12_allsnowdays(j,k) = length(find(cSWE(:,k)>0))*(dt/24);
                
                
                %%% center of mass (COM) of snowmelt (sdate_13_meltCOM_annual)
                melt0cumulative = cumsum(melt0(:,k));
                melt0cumulative = melt0cumulative./nanmax(melt0cumulative);
                sdate_13_meltCOM_annual_ind = find(melt0cumulative>=0.5,1,'first');
                if isempty(sdate_13_meltCOM_annual_ind)==0
                    snow_periods.sdate_13_meltCOM_annual(j,k) = cTIME(sdate_13_meltCOM_annual_ind);
                end
                
                %%% Accumulation Season metrics
                snow_accum.winterAcc(j,k) = nansum(accum(1:sdate_03_peak_swe_ind,k));       % total snowfall during accumulation season (prior to peak SWE)
                snow_accum.winterMelt(j,k) = nansum(melt(1:sdate_03_peak_swe_ind,k));       % total snowmelt during accumulation season (prior to peak SWE)
                
                
                %%% Melt Season metrics
                if isempty(sdate_07_melt100_ind)==1
                    snow_melt.meanmelt50(j,k)  = NaN;   % mean melt rate from peak SWE to 50% snow melted out
                    snow_melt.meanmelt75(j,k)  = NaN;   % mean melt rate from peak SWE to 75% snow melted out
                    snow_melt.meanmelt90(j,k)  = NaN;   % mean melt rate from peak SWE to 90% snow melted out
                    snow_melt.meanmelt100(j,k) = NaN;   % mean melt rate from peak SWE to 100% snow melted out
                else
                    snow_melt.meanmelt50(j,k)  = nanmean(melt(sdate_03_peak_swe_ind:sdate_04_melt50_ind,k));
                    snow_melt.meanmelt75(j,k)  = nanmean(melt(sdate_03_peak_swe_ind:sdate_05_melt75_ind,k));
                    snow_melt.meanmelt90(j,k)  = nanmean(melt(sdate_03_peak_swe_ind:sdate_06_melt90_ind,k));
                    snow_melt.meanmelt100(j,k) = nanmean(melt(sdate_03_peak_swe_ind:sdate_07_melt100_ind,k));
                end
                
                snow_melt.springAcc(j,k)  = nansum(accum(1+sdate_03_peak_swe_ind:end,k));   % total snowfall during snowmelt season (after peak SWE)
                snow_melt.springMelt(j,k) = nansum(melt(1+sdate_03_peak_swe_ind:end,k));    % total snowmelt during snowmelt season (after peak SWE)
            end
        end
        
        
        
    end
end




