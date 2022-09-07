% Converts milimeters to inches
% 
% RELEASE NOTES
%   Written by Mark Raleigh (mraleig1@uw.edu), August 2010
% 
% SYNTAX
%   in = mm2in(mm)
% 
% INPUTS
%   mm = 1xN or Nx1 array, or Nxw matrix of values in millimeters
% 
% OUTPUTS
%   in = 1xN or Nx1 array, or Nxw matrix of values in inches
% 

%%
function in = mm2in(mm)

if isempty(mm) ==1
    in = [];
else
    in = m2ft(mm./1000).*12;
end