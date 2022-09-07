% Converts inches to milimeters
% 
% RELEASE NOTES
%   Written by Mark Raleigh (mraleig1@uw.edu), August 2010
% 
% SYNTAX
%   mm = in2mm(in)
% 
% INPUTS
%   in = 1xN or Nx1 array, or Nxw matrix of values in inches
% 
% OUTPUTS
%   mm = 1xN or Nx1 array, or Nxw matrix of values in millimeters
% 

%%
function mm = in2mm(in)

if isempty(in) ==1
    mm = [];
else
    mm = ft2m(in./12).*1000;
end