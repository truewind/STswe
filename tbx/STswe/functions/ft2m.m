% Converts feet to meters
% 
% RELEASE NOTES
%   Written by Mark Raleigh (mraleig1@uw.edu), August 2010
% 
% SYNTAX
%   m = ft2m(f)
% 
% INPUTS
%   f = 1xN or Nx1 array, or Nxw matrix of values in feet
% 
% OUTPUTS
%   m = 1xN or Nx1 array, or Nxw matrix of values in meters
% 

%%
function m = ft2m(f)

if isempty(f) ==1
    m = [];
else
    m = f./3.28083989501;
 
end


