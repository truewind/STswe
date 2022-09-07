% This code builds a time series based on user-specified start and end
% times at a user-specified timestep.  This is the standard time matrix
% used in many of my codes.
%
%RELEASE NOTES
% % % Version 1.3 = Revised by Mark Raleigh, February 2012 to fix issues with subhourly time steps
% % % Version 1.2 = Revised by Mark Raleigh, October 2010 to allow water years and serial_dates as inputs.  Also the code can build a time_matrix for just the 1st day of each month (useful for monthly timestep)
% % % Version 1.1 = Revised by Mark Raleigh, June 2009 to fix issues with rounding of minutes
% % % Version 1.0 = Created by Mark Raleigh (mraleig1@uw.edu), May 2009
%
%SYNTAX
% T = time_builder(yr_i, month_i, day_i, hr_i, min_i, yr_f, month_f, day_f, hr_f, min_f, timestep);
% T = time_builder(yr_i, month_i, day_i, yr_f, month_f, day_f, timestep);
% T = time_builder(yr_i, month_i, day_i, hr_i, timestep, num_timesteps);
% T = time_builder(yr_i, jd_i, hr_i, min_i, yr_f, jd_f, hr_f, min_f, timestep);
% T = time_builder(yr_i, jd_i, yr_f, jd_f, timestep);
% T = time_builder(serial_i, serial_f, timestep);
% T = time_builder(wy_i, wy_f, timestep);
% T = time_builder(yr_i, month_i, yr_f, month_f);       % returns the 1st of each month in this range
% T = time_builder(serial_dates);
%
%INPUT
% yr_i = 1x1, starting year (e.g. 2005)
% month_i = 1x1, starting month (e.g. 10 for October)
% day_i = 1x1, starting day (e.g. 23)
% hr_i = 1x1, starting hr (e.g. 17), 0-23
% min_i = 1x1, starting min (e.g. 40), 0-59
% jd_i = 1x1, starting julian day
% yr_f = 1x1, ending year (e.g. 2006)
% month_f = 1x1, ending month (e.g. 1)
% day_f = 1x1, ending day (e.g. 12)
% hr_f = 1x1, ending hr (e.g. 3), 0-23
% min_f = 1x1, ending min (e.g. 0), 0-59
% jd_f = 1x1, ending julian day
% serial_i = 1x1, starting serial date
% serial_f = 1x1, ending serial date
% timestep = 1x1, timestep in hours
%
%OUTPUT
% time_series = Nx7 matrix, by timestep
%   where:  Column 1: Year
%           Column 2: Month
%           Column 3: Gregorian Day
%           Column 4: Hour
%           Column 5: Minute
%           Column 6: Julian Day
%           Column 7: Matlab Serial Date



function time_series = time_builder(arg01, arg02, arg03, arg04, arg05, arg06, arg07, arg08, arg09, arg10, arg11, varargin)



%% Code

% Parse Input Data
if nargin == 11     % then the input variables are assumed to be in Gregorian
    yr_i=arg01;
    month_i=arg02;
    day_i=arg03;
    hr_i=arg04;
    min_i=arg05;
    yr_f=arg06;
    month_f=arg07;
    day_f=arg08;
    hr_f=arg09;
    min_f=arg10;
    timestep=arg11;
    jd_i= greg2jul(yr_i, month_i, day_i, hr_i, min_i);
    jd_f= greg2jul(yr_f, month_f, day_f, hr_f, min_f);
elseif nargin ==9   % then the input variables are assumed to be in Julian
    yr_i=arg01;
    jd_i=arg02;
    hr_i=arg03;
    min_i=arg04;
    yr_f=arg05;
    jd_f=arg06;
    hr_f=arg07;
    min_f=arg08;
    timestep=arg09;
elseif nargin == 7     % then the input variables are assumed to be in Gregorian, without hr and min
    yr_i=arg01;
    month_i=arg02;
    day_i=arg03;
    hr_i=0;
    min_i=0;
    yr_f=arg04;
    month_f=arg05;
    day_f=arg06;
    hr_f=0;
    min_f=0;
    timestep=arg07;
    jd_i= greg2jul(yr_i, month_i, day_i, hr_i, min_i);
    jd_f= greg2jul(yr_f, month_f, day_f, hr_f, min_f);
elseif nargin == 5      % then the input variables are assumed to be in Julian, without hr and min
    yr_i=arg01;
    jd_i=arg02;
    yr_f=arg03;
    jd_f=arg04;
    timestep=arg05;
elseif nargin == 6      % then the input variables are assumed to be with starting Greg. and # of steps
    yr_i=arg01;
    month_i=arg02;
    day_i=arg03;
    hr_i=arg04;
    timestep=arg05;
    num_timesteps = arg06;
    min_i = 0;
    jd_i= greg2jul(yr_i, month_i, day_i, hr_i, min_i);
elseif nargin ==3
    timestep = arg03;
    
    if arg01 >100000 && arg02 > 100000
        start_serial = arg01;
        end_serial = arg02;
    else
        wy1 = arg01;
        wy2 = arg02;
        
        start_serial = datenum(wy1-1, 10, 1, 0, 0, 0);
        end_serial = datenum(wy2, 10, 1, 0, 0, 0) - (timestep/24);
        
    end
elseif nargin==4
    yr_i=arg01;
    month_i=arg02;
    yr_f=arg03;
    month_f=arg04;
    
    if yr_f < yr_i || (yr_f==yr_i && month_f<month_i)
        error('Invalid yr and month.  Make sure final occurs after initial')
    end

elseif nargin==1
    sdates=arg01;

else
    error('Invalid number of input arguments.  See time_builder.m for SYNTAX')
end

if nargin == 9 || nargin == 5      % then the input variables are assumed to be in Julian
    [month_i, day_i] = jul2greg(yr_i, jd_i);
    [month_f, day_f] = jul2greg(yr_f, jd_f);
end




if nargin >1 && nargin ~=4
    if nargin == 5 || nargin == 7      % then the input variables are assumed without hr, min
        start_serial = datenum(yr_i, month_i, day_i);
        end_serial = datenum(yr_f, month_f, day_f);
    else
        if nargin ~= 3
            start_serial = datenum(yr_i, month_i, day_i, hr_i, min_i, 0);
            if nargin ~=6
                end_serial = datenum(yr_f, month_f, day_f, hr_f, min_f, 0);
            end
        end
    end
    
    
    serial_time_step = timestep/24;
    
    if nargin ~=6
        day_range = end_serial-start_serial;
        
        num_timesteps = floor(day_range/serial_time_step);
        time_temp = zeros(num_timesteps+1,7);
        
        
        if num_timesteps == ceil(day_range*24/timestep) %then the number of timesteps in the range is exact
            if timestep>=1
                time_temp(:,7) = start_serial:serial_time_step:end_serial;
            else
                time_temp(:,7) = subhrly(start_serial, end_serial, timestep);
            end
        else
            if timestep>=1
                time_temp(:,7) = (start_serial):serial_time_step:(start_serial+(num_timesteps)*serial_time_step);
                %         disp('Note: Ending date was truncated since designated time step did not divide evenly into given time range.')
            else
                time_temp(:,7) = subhrly(start_serial, (start_serial+(num_timesteps)*serial_time_step), timestep);
            end
        end
        
        [time_temp(:,1), time_temp(:,2), time_temp(:,3), time_temp(:,4), time_temp(:,5), seconds(:,1)] = datevec(time_temp(:,7));
        for i=1:size(time_temp,1)
            time_temp(i,6) = floor(greg2jul(time_temp(i,1), time_temp(i,2), time_temp(i,3), time_temp(i,4), time_temp(i,5)));
        end
        
        time_temp(:,7) = datenum(time_temp(:,1), time_temp(:,2), time_temp(:,3), time_temp(:,4), time_temp(:,5), 0);
        %     % This recomputes the serial number due to rounding errors.  It will
        %     % get the yr, month, day, hr, min correct, but may be off in the serial number.
        %     % It is an intermediate check (there will be a final check).
        
        
        
    elseif nargin == 6
        time_temp = zeros(num_timesteps,7);
        
        if timestep>=1
            time_temp(:,7) = start_serial:serial_time_step:start_serial+(serial_time_step*(num_timesteps-1));
        else
            time_temp(:,7) = subhrly(start_serial, (start_serial+(serial_time_step*(num_timesteps-1))), timestep);
        end
        [time_temp(:,1), time_temp(:,2), time_temp(:,3), time_temp(:,4), time_temp(:,5), seconds(:,1)] = datevec(time_temp(:,7));
        
        for i=1:size(time_temp,1)
            time_temp(i,6) = floor(greg2jul(time_temp(i,1), time_temp(i,2), time_temp(i,3), time_temp(i,4), time_temp(i,5)));
        end
    end
elseif nargin==4
    
    if yr_i~=yr_f
        num_timesteps = (12-month_i+1) + ((nanmax((yr_f-yr_i-1),0))*12) + month_f;
    else
        num_timesteps = month_f-month_i+1;
    end
    
    time_temp=zeros(num_timesteps,7)*NaN;
    
    time_temp(1,1) = yr_i;
    time_temp(1,2) = month_i;
    time_temp(1,3) = 1;
    time_temp(1,4) = 0;
    time_temp(1,5) = 0;
    time_temp(1,6)= greg2jul(time_temp(1,1), time_temp(1,2), 1, 0, 0);
    time_temp(1,7) = datenum(time_temp(1,1), time_temp(1,2), 1, 0, 0, 0);
    
    if num_timesteps>1
        for i=2:num_timesteps
            time_temp(i,2) = time_temp(i-1,2) + 1;
            if time_temp(i,2) > 12
                time_temp(i,2) = 1;
                time_temp(i,1) = time_temp(i-1,1) + 1;
            else
                time_temp(i,1) = time_temp(i-1,1);
            end
            time_temp(i,3) = 1;
            time_temp(i,4) = 0;
            time_temp(i,5) = 0;
            time_temp(i,6)= greg2jul(time_temp(i,1), time_temp(i,2), 1, 0, 0);
            time_temp(i,7) = datenum(time_temp(i,1), time_temp(i,2), 1, 0, 0, 0);
        end
    end
else
    

    
    time_temp = zeros(size(sdates,1),7);
    time_temp(:,7) = sdates;
    [time_temp(:,1), time_temp(:,2), time_temp(:,3), time_temp(:,4), time_temp(:,5), seconds(:,1)] = datevec(time_temp(:,7));
    
    for i=1:size(time_temp,1)
        try
            time_temp(i,6) = floor(greg2jul(time_temp(i,1), time_temp(i,2), time_temp(i,3), time_temp(i,4), time_temp(i,5)));
        catch
            error('Subscripted assignment dimension mismatch.')
        end
    end
    
    
    
    
end
%% Final Check
% Sometimes time_builder will start or get out of sync when converting back and forth between serial dates.  For example a
% starting time of 2200 hrs and a 0.5 hr timestep has shown every third
% time step being off by 1 minute.  This is probably due to rounding errors.

% This final check will ensure that the the min portion is accurate for the
% requested time step.

current_hr = time_temp(1,4);
current_min = time_temp(1,5);

if nargin>1 && nargin~=4
    for i=2:size(time_temp,1)
        current_min = current_min + (timestep*60);
        if current_min >=60
            while current_min >=60
                current_min = current_min-60;
                current_hr = current_hr+1;
            end
        end
        
        if current_hr >= 24
            current_hr = 0;
        end
        
        if (current_min < time_temp(i,5)) && (current_hr > time_temp(i,4))
            % Then the computed time step is probably 1-2 minutes behind, and the min/hr both need adjustment
            time_temp(i,4) = current_hr;
            time_temp(i,5) = current_min;
            time_temp(i,7) = datenum(time_temp(i,1), time_temp(i,2), time_temp(i,3), time_temp(i,4), time_temp(i,5), 0);
            time_temp(i,6) = floor(greg2jul(time_temp(i,1), time_temp(i,2), time_temp(i,3), time_temp(i,4), time_temp(i,5)));
        elseif (current_min < time_temp(i,5)) && (current_hr == time_temp(i,4))
            % Then the computed time step is probably 1-2 minutes ahead, and the min column needs adjustment
            time_temp(i,4) = current_hr;
            time_temp(i,5) = current_min;
            time_temp(i,7) = datenum(time_temp(i,1), time_temp(i,2), time_temp(i,3), time_temp(i,4), time_temp(i,5), 0);
            time_temp(i,6) = floor(greg2jul(time_temp(i,1), time_temp(i,2), time_temp(i,3), time_temp(i,4), time_temp(i,5)));
        elseif (current_min > time_temp(i,5)) && (current_hr == time_temp(i,4))
            % Then the computed time step is probably 1-2 minutes behind, and min column needs needs adjustment
            time_temp(i,4) = current_hr;
            time_temp(i,5) = current_min;
            time_temp(i,7) = datenum(time_temp(i,1), time_temp(i,2), time_temp(i,3), time_temp(i,4), time_temp(i,5), 0);
            time_temp(i,6) = floor(greg2jul(time_temp(i,1), time_temp(i,2), time_temp(i,3), time_temp(i,4), time_temp(i,5)));
        end
        
    end
end



time_series = time_temp;
end

%% Sub-hourly time steps

function sd = subhrly(sd1, sd2, dt)

   if dt>=1
       error('Invalid dt for subhourly time steps')
   end
   
   if sd1>sd2
       error('sd1 must be <= sd2')
   end
    
    sdi = sd1;
    Z=1;
    
    while sdi<sd2
        if Z==1
            sd(Z,1) = sdi;
        else
            A = (sd(Z-1,1)+(dt/24));
            %%% correct it!
            [Y, M, D, H, MN, S] = datevec(A);
            Y=round(Y);
            M=round(M);
            D=round(D);
            H=round(H);
            MN=round(MN);
            S=round(S);
            sd(Z,1) = datenum(Y,M,D,H,MN,S);
            sdi = sd(Z,1);
        end
        
        Z=Z+1;
    end
end