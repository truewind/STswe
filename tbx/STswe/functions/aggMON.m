% Aggregates data to monthly values.  User selects calendar year or water
% year.
% 
% RELEASE NOTES
%   Written by Mark Raleigh (mraleig1@uw.edu), October 2010
%   Updated by Mark Raleigh to fix bugs when t3 is [], Feb 2013
% 
% SYNTAX
%   [agg_vals, agg_yr, agg_month] = aggMON(TIME, data, agg_option, CY_or_WY)
% 
% INPUTS
%   TIME = Nx7 time matrix (time_builder.m format) or Nx1 or 1xN array of serial dates
%   data = Nxw data matrix, or Nx1 or 1xN data array
%   agg_option = data aggregation option, where:
%       % 1 = Average over each year
%       % 2 = Maximum over each year
%       % 3 = Minimum over each year
%       % 4 = Median over each year
%       % 5 = Cumulative sum over each year
%   CY_or_WY = 1x1 value, enter 1 for calendar year, enter 2 for water year
% 
% OUTPUTS
%   agg_vals = Nxw or Nx1 matrix/array of aggregated values
%   agg_yr = Nx1 array of aggregation years (will be either calendar year or water year, depending on CY_or_WY value)
%   agg_month = Nx1 array of aggregation month
% 
% SCRIPTS REQUIRED
%   time_builder.m, water_year.m, calendar_year.m

function [agg_vals, agg_yr, agg_month] = aggMON(TIME, data, agg_option, CY_or_WY)

%% Checks


if size(TIME,2) ~= 7
    if size(TIME,2) > 1 && size(TIME,1) == 1
        TIME = TIME';
    end
    
    if size(TIME,2) == 1
        TIME = time_builder(TIME);
    else
        error('Invalid TIME input')
    end
end

if size(TIME,2) ~= 7
    error('Invalid TIME input')
end

N = size(TIME,1);

if size(data,1) ~= N
    if size(data,2) == N
        disp('Note: Detecting horizontal time structure.  Flipping to vertical')
        data = data';
    else
        error('Data size does not match TIME input')
    end
end

if numel(agg_option) ~= 1 || numel(CY_or_WY) ~= 1
    error('Single variable must be input for agg_option and CY_or_WY')
end

if agg_option < 1 || agg_option > 5 || agg_option-floor(agg_option) ~=0
    error('Invalid agg_option')
end

if CY_or_WY < 1 || CY_or_WY > 2 || CY_or_WY-floor(CY_or_WY) ~=0
    error('Invalid CY_or_WY')
end


%% Code

if CY_or_WY==1
    y_index = calendar_year(TIME(:,7));
elseif CY_or_WY==2
    y_index = water_year(TIME(:,7));
end

w=size(data,2);

L = size(y_index,1);
Lm = L*12;

agg_vals = zeros(Lm,w)*NaN;
agg_yr = zeros(Lm,1)*NaN;
agg_month = zeros(Lm,1)*NaN;

X=1;
for i=1:L
    t1= y_index(i,1);
    t2= y_index(i,2);
    time = TIME(t1:t2,:);
    d = data(t1:t2,:);
    

    if CY_or_WY==1
        for j=1:12
            t3 = find(time(:,2)==j);
            
            if isempty(t3)==0
                if agg_option==1
                    agg_vals(X,:) = nanmean(d(t3,:));
                elseif agg_option==2
                    agg_vals(X,:) = nanmax(d(t3,:));
                elseif agg_option==3
                    agg_vals(X,:) = nanmin(d(t3,:));
                elseif agg_option==4
                    agg_vals(X,:) = nanmedian(d(t3,:));
                elseif agg_option==5
                    agg_vals(X,:) = nansum(d(t3,:));
                end
                agg_yr(X,1) = y_index(i,3);
                agg_month(X,1) = j;
            end
            
            X=X+1;
        end
    elseif CY_or_WY==2
        Z=0;
        for j=10:12
            t3 = find(time(:,2)==j);
            
            if isempty(t3)==0
                if agg_option==1
                    agg_vals(X,:) = nanmean(d(t3,:));
                elseif agg_option==2
                    agg_vals(X,:) = nanmax(d(t3,:));
                elseif agg_option==3
                    agg_vals(X,:) = nanmin(d(t3,:));
                elseif agg_option==4
                    agg_vals(X,:) = nanmedian(d(t3,:));
                elseif agg_option==5
                    agg_vals(X,:) = nansum(d(t3,:));
                end
                agg_yr(X,1) = y_index(i,3)-1;
                agg_month(X,1) = j;
            end
            
            X=X+1;
            Z=Z+1;
        end
        
        for j=1:9
            t3 = find(time(:,2)==j);
            
            if isempty(t3)==0
                if agg_option==1
                    agg_vals(X,:) = nanmean(d(t3,:));
                elseif agg_option==2
                    agg_vals(X,:) = nanmax(d(t3,:));
                elseif agg_option==3
                    agg_vals(X,:) = nanmin(d(t3,:));
                elseif agg_option==4
                    agg_vals(X,:) = nanmedian(d(t3,:));
                elseif agg_option==5
                    agg_vals(X,:) = nansum(d(t3,:));
                end
                agg_yr(X,1) = y_index(i,3);
                agg_month(X,1) = j;
            end
            
            X=X+1;
            Z=Z+1;
        end
    end

end

