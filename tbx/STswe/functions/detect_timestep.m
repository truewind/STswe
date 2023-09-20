% Detects the time step of a time matrix
% 
% RELEASE NOTES
%   V1.0 Written by Mark Raleigh (mraleig1@uw.edu), Feb 2013
%   V1.1 Revised by Mark Raleigh, February 2016.  Cleaned up for first GitHub release
% 
% SYNTAX
%   dt = detect_timestep(TIME)
% 
% INPUTS
%   TIME =Nx7 time matrix (time_builder.m format) or  Nx1 array of MATLAB datenum formatted times
% 
% OUTPUTS
%   dt = time step (hours) of the time matrix

function dt = detect_timestep(TIME)

%% Checks

%%% check whether array of serial dates or time matrix was input
if size(TIME,2) ~= 1
    if size(TIME,2)==7
        TIME=TIME(:,7);   % just focus on serial date column
    else
    	error('TIME must be a Nx1 array or Nx7 time matrix')
    end
end

%%% check for NaNs in TIME
if max(isnan(TIME)) == 1
    error('NaN values exist in TIME')
end

%%% make sure we have it sorted in chronological order.  I choose not to do
%%% this within the code because the rows in time might correspond to the
%%% rows of other external variables
if max(sort(TIME) - TIME) ~= 0 || min(sort(TIME) - TIME) ~= 0
    error('TIME must be sorted in chronological order first')
end


%% Codes

%%% find time step in hours
dt_all = diff(TIME)*24;

%%% find most common time step in hours
dt = mode(dt_all);

%%% check to see if there are timesteps that are different than mode dt
dt_all = dt_all - dt;
a = find(dt_all > 0.00000001);      % check against a tolerance

if isempty(a)==0
    disp('Note: TIME steps are not consistent! (detect_timestep.m)')
end


