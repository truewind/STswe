% This script takes an array of chronologically sorted MATLAB serial dates
% and returns the indexes that will divide the time series into water
% years.
% 
% Note: A water year begins on October 1 and ends on September 30.  The
% water year is the calendar year of the majority of the year.  Thus, the
% 2006 water year began on October 1, 2005 and ended on September 30, 2006.
% 
% When the time series begins in the middle a water year, this script will
% return that first value as the first index.
% 
% When the time series ends in the middle a water year, this script will
% return that last value as the last index.
% 
%RELEASE NOTES
% Written by Mark Raleigh (mraleig1@uw.ed), 01 May 2009
% Version 1.0 Released on January 27, 2010
% Version 1.1 Revised by Mark Raleigh, February 2016.  Cleaned up for first GitHub release

% 
%SYNTAX
%   wy_index = water_year(time_in)
% 
%INPUT
%   time_in = either Nx1 array of MATLAB datenum formatted times or Nx7 time matrix (time_builder.m format)
% 
%OUTPUT
%   wy_index = Mx3 array of water year index, where:
%         1st column = starting index
%         2nd column = ending index
%         3rd column = water year
%           and M corresponds to the number of water years

function wy_index = water_year(time_in)


%% Initial Checks

%%% check whether array of serial dates or time matrix is input
if size(time_in,2) ~= 1
    if size(time_in,2)==7
        time_in=time_in(:,7);   % just focus on serial date column
    else
    	error('time_in must be a Nx1 array or Nx7 time matrix')
    end
end

%%% check for NaNs in the time input
if max(isnan(time_in)) == 1
    error('NaN values exist in time_in')
end

%%% make sure we have it sorted in chronological order.  I choose not to do
%%% this within the code because the rows in time might correspond to the
%%% rows of other external variables
if max(sort(time_in) - time_in) ~= 0 || min(sort(time_in) - time_in) ~= 0
    error('time_in must be sorted in chronological order first')
end

%% Code

%%% get years and months of the time array
[Y, M, ~, ~, ~, ~] = datevec(time_in);

%%% Examine first date to find initial water year
if M(1,1) < 10                  % Then the first date falls before October 1
    water_yr_i = Y(1,1);
else
    water_yr_i = Y(1,1)+1;
end

%%% Examine last date to find final water year
if M(end,1) < 10                  % Then the last date falls before October 1
    water_yr_f = Y(end,1);
else
    water_yr_f = Y(end,1)+1;
end

%%% increment WY from initial to final and find length
wyrs = water_yr_i:1:water_yr_f;
wyrs = wyrs';
L = length(wyrs);

%%% initialize output (WY matrix table)
wy_index = zeros(L,3);

%%% place WY in the third column
wy_index(:,3) = wyrs;


%%% populate the wy_index, where 1st col = index of start of WY, 2nd col = index  of end of WY
drow = 1;

for i = 1:L
    clear current_yr cutoff A
    
    current_yr = wy_index(i,3);
    cutoff = datenum(current_yr, 10, 1);
    A = find(time_in < cutoff);
    
    if numel(A) ~= 0
        % then we have some steps during this WY
        wy_index(i,1) = A(1);
        wy_index(i,2) = A(end);
        time_in(A,1) = NaN;
    else
        % then there are no steps in this WY
        no_wyr(drow,1) = i;
        drow=drow+1;
    end
end

%%% delete any WY that do not appear in time
if drow >1
    wy_index = delrow(wy_index, no_wyr);
end