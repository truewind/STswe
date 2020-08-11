%%% colorbar for dSWE -  symmetrical, but unevenly spaced colorbar (since might get more melt than accum)
nc = 6;  % number of colors
cbins = [linspace(-2.0,0,nc), linspace(0,1.5,nc)]; 
ncol = numel(cbins)+1;
cbinLab = cell(1,ncol);
cmap = cbrewer('div', 'RdBu', ncol); 
cmap(nc+1,:) = [0 0 0]; % set zeros to black

for j=1:numel(cbinLab)-1
    cbinLab(j) = cellstr(num2str(cbins(j)));
end
cbinLab = [cellstr('melt') cbinLab];
cbinLab(end) = {'acc'};