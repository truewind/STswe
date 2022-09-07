% Finds repeat values in a data array
% 
% RELEASE NOTES
% Written by Mark Raleigh Nov 21, 2009
% 
%SYNTAX
% repeat_vals = find_repeat(data)
% 
%INPUTS
% data = 1xN or Nx1 array of data
% 
%OUTPUTS
% repeat_vals = 1xm or mx1 array of repeating values in the data

function repeat_vals = find_repeat(data)


%% Checks
if size(data,1) >1 && size(data,2) >1
    error('data must be an array')
end

if size(data,1)==1 && size(data,2) >1
    data=data';
    fl =1;
else
    fl = 0;
end

%% Code
repeat_vals =[];
data_unique=unique(data);

L=length(data_unique);

ind=1;
for i=1:L
    num_vals = length(find(data==data_unique(i,1)));
    if num_vals > 1
        repeat_vals(ind,1) = data_unique(i,1);
        ind=ind+1;
    end
end


if fl==1
    repeat_vals = repeat_vals';
end