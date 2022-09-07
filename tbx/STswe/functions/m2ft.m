% Converts meters to feet
% 
% RELEASE NOTES
%   Written by Mark Raleigh (mraleig1@uw.edu), August 2010
% 
% SYNTAX
%   f = m2ft(m)
% 
% INPUTS
%   m = 1xN or Nx1 array, or Nxw matrix of values in meters
% 
% OUTPUTS
%   f = 1xN or Nx1 array, or Nxw matrix of values in feet
% 

%%
function f = m2ft(m)

if isempty(m) ==1
    f = [];
else
    f = m.*3.28083989501;
end


