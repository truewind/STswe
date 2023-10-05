% define colormap for use in maps with percent of SWE (climatological or
% peak SWE)

% define colormap similar to Drew Slater's. Red to blue with 13 bins (each % of SWE):
% 0-45
% 45-55
% 55-65
% 65-75
% 75-85
% 85-95
% 95-105
% 105-115
% 115-125
% 125-135
% 135-145
% 145-165
% 165+

% number of colors
ncol = 13;  

% create colormap with colorbrewer
cmap = cbrewer('div', 'RdBu', ncol);  

% define the bin dividers and labels
cbins = [0 45 55 65 75 85 95 105 115 125 135 145 165]; 
cbinLab = cell(1,numel(cbins)+1);
for j=1:ncol
    cbinLab(j) = cellstr(num2str(cbins(j)));
end
cbinLab(end) = {'%'};
