% Takes SWE record(s) and separates the accumulation and melt components
% 
%RELEASE NOTES
%   V1.0 Written by Mark Raleigh (mraleig1@uw.edu)
%   V1.1 Revised by Mark Raleigh, February 2016.  Cleaned up for first GitHub release
% 
%SYNTAX
%   [accum, melt] = SWEcomp(SWE)
%
%INPUTS
%   SWE = Lxw matrix of SWE values (rows=time, columns=stations)
%
%OUTPUTS
%   accum = Lxw matrix of accumulation values (rows=time, columns=stations)
%   melt = Lxw matrix of melt values (rows=time, columns=stations)
% 

%%
function [accum, melt] = SWEcomp(SWE)


%% Checks

%%% make sure we have rows as time and multiple rows
if size(SWE,1) == 1
    error('SWE must be an array or matrix with rows as time and columns as stations')
end

%% Code

%%% get dimensions
[L,w] = size(SWE);

%%% initialize outputs
accum = zeros(L,w);
melt = zeros(L,w);

%%% cycle through stations
for i=1:w
    %%% compute difference matrices (diff in time)
    SWEdiff = zeros(L,1);
    SWEdiff(2:end,1) = diff(SWE(:,i));
    
    %%% find positive (accumulation) and negative (melt) changes in SWE
    A= find(SWEdiff>0);
    M= find(SWEdiff<0);
    
    %%% store accumulation and melt into respective outputs
    accum(A,i) = SWEdiff(A,1);
    melt(M,i) = SWEdiff(M,1);
end

