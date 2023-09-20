% define colormap for use in dSWE maps 
% 
% symmetrical, but unevenly spaced colorbar (since might get more melt than accum)
nc = 6;  % number of colors

%%% set up bins based on units specified in settings file
if strcmp(units_figs_text, 'in')==1
    cbins = [linspace(-2.0,0,nc), linspace(0,1.5,nc)]; 
elseif strcmp(units_figs_text, 'cm')==1
    cbins = [linspace(-5.0,0,nc), linspace(0,4,nc)]; 
elseif strcmp(units_figs_text, 'mm')==1
    cbins = [linspace(-50,0,nc), linspace(0,40,nc)]; 
end


ncol = numel(cbins)+1;
cbinLab = cell(1,ncol);
cmap = cbrewer('div', 'RdBu', ncol); 
cmap(nc+1,:) = [0 0 0]; % set zeros to black

for j=1:numel(cbinLab)-1
    cbinLab(j) = cellstr(num2str(cbins(j)));
end
cbinLab = [cellstr('melt') cbinLab];
cbinLab(end) = {'acc'};