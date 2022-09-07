% Deletes a series of rows out of a matrix or array
% 
%RELEASE NOTES
% Written by Mark Raleigh (mraleig1@uw.edu), June 2009
% Version 1.0 released on January 27, 2010
% Version 1.1 released on January 11, 2011 - Revised to be MUCH faster
% 
%SYNTAX
% data_out = delrow(data_in, rows)
% 
%INPUT
% data_in = NxM matrix
% rows = Lx1 array of rows to be deleted
% 
%OUTPUT
% data_out = (N-L)xM matrix

function data_out = delrow(data_in, rows)


%% Checks

if isempty(rows)==1
    data_out = data_in;
    return
end

if size(rows,2) ~= 1 && size(rows,1) ~=1
    error('rows must be a Lx1 or 1xL array')
end

if size(rows,1) == 1
    rows=rows';
end

if min(rows) < 1 || max(rows) > size(data_in,1)
    error('Out of bounds rows')
end


L = size(rows,1);

for i=1:L
    if rows(i) - floor(rows(i)) ~= 0
        error('Non-integer values found in the rows designation')
    end
end


%% Code

rows=sort(rows, 'descend');

L0 = size(data_in,1);
L1 = 1:L0;
L1=L1';
L1(rows) = 0;
L2 = L1(L1>0);

data_out = data_in(L2,:);
