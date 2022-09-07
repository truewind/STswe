% Determines the fractional Julian day from Gregorian values
% 
%RELEASE NOTES
% Written by Mark Raleigh (mraleig1@uw.edu)
% Version 1.0 released Jan 2010
% 
%SYNTAX
% jday = greg2jul(yr, mo, da, hr, minu)
% 
%INPUTS
% yr = 1x1 value, year
% mo = 1x1 value, month
% da = 1x1 value, Gregorian day
% hr = 1x1 value, hour
% minu = 1x1 value, minute
% 
%OUTPUTS
% jday = 1x1 value, Julian day


function jday = greg2jul(yr, mo, da, hr, minu)

%% checks

if mo < 1 || mo > 12
    disp([num2str(mo)])

    error('Invalid month')
end

if da < 1
    error('Invalid day')
end

if hr < 0 || hr > 23
    error('Hour must be between 0 and 23')
end

if minu < 0 || minu > 59
    disp(['minute value: ' num2str(minu)]);
    error('Minute must be between 0 and 59')
end

if rem(yr,4) == 0 % then it is a leap year
    if mo == 1 || mo == 3 || mo == 5 || mo == 7 || mo == 8 || mo == 10 || mo == 12
        if da > 31
            error('Invalid days in the selected month')
        end
    elseif mo == 2
        if da > 29
            error('Invalid days in the selected month')
        end
    else
        if da > 30
            error('Invalid days in the selected month')
        end
    end
else
     if mo == 1 || mo == 3 || mo == 5 || mo == 7 || mo == 8 || mo == 10 || mo == 12
        if da > 31
            error('Invalid days in the selected month')
        end
    elseif mo == 2
        if da > 28
            error('Invalid days in the selected month')
        end
    else
        if da > 30
            error('Invalid days in the selected month')
        end
     end
end


%% CODE
% Originally adapted from julday4

for yri=min(yr):max(yr)
    cumd=[0,31,59,90,120,151,181,212,243,273,304,334];
    if (rem(yri,400)==0) 
        inc=1;
    elseif ((rem(yri,100)~=0)&&(rem(yri,4)==0)) 
        inc=1;
    else
        inc=0;
    end
    
    cumd(3:12)=cumd(3:12)+inc;
    yrkp=find(yr==yri);
    days(yrkp)= reshape(cumd(mo(yrkp)),size(da(yrkp)))+da(yrkp);
end


minu=minu/60;
hr = hr+minu;
hr = hr/24;
days = days+hr;


jday=days;
