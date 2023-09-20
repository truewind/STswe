% Returns the cellstring version of a numeric month
% 
% RELEASE NOTES
%   Written by Mark Raleigh (mraleig1@uw.edu) January 2010
% 
% SYNTAX
%   month_cell = num2month(month_num)
%   month_cell = num2month(month_num, abb_option)
% 
% INPUTS
%   month_num = lxw matrix of values (1-12) representing months, where
%                % 1 = January
%                % 2 = February
%                % 3 = March
%                % 
%                % and so on
% 
%   abb_option = 1x1 value, if abbreviated months is needed.
%           Enter: 1 for 3 letters max (Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
%                  2 for 3-4 letters max (Jan Feb Mar Apr May June July Aug Sept Oct Nov Dec)
%                  3 for 1 letter max (J F M A M J J A S O N D)
% 
% OUTPUTS
%   month_cell = lxw matrix of cellstring values of the months
% 

function month_cell = num2month(month_num, arg01, varargin)


%% Code

if nargin==1
elseif nargin==2
    if numel(arg01) ~=1
        error('abb_option must be a 1x1 value')
    end
    abb_option=arg01;
else
    error('Invalid number of inputs')
end

l = size(month_num,1);
w = size(month_num,2);



if nargin==1
    for i=1:l
        for j=1:w
            if month_num(i,j) ==1
                month_cell(i,j) =cellstr('January');
            elseif month_num(i,j) ==2
                month_cell(i,j) =cellstr('February');
            elseif month_num(i,j) ==3
                month_cell(i,j) =cellstr('March');
            elseif month_num(i,j) ==4
                month_cell(i,j) =cellstr('April');
            elseif month_num(i,j) ==5
                month_cell(i,j) =cellstr('May');
            elseif month_num(i,j) ==6
                month_cell(i,j) =cellstr('June');
            elseif month_num(i,j) ==7
                month_cell(i,j) =cellstr('July');
            elseif month_num(i,j) ==8
                month_cell(i,j) =cellstr('August');
            elseif month_num(i,j) ==9
                month_cell(i,j) =cellstr('September');
            elseif month_num(i,j) ==10
                month_cell(i,j) =cellstr('October');
            elseif month_num(i,j) ==11
                month_cell(i,j) =cellstr('November');
            elseif month_num(i,j) ==12
                month_cell(i,j) =cellstr('December');
            else
                error('Invalid month number')
            end
        end
    end
elseif nargin ==2
    if abb_option ==1
        for i=1:l
            for j=1:w
                if month_num(i,j) ==1
                    month_cell(i,j) =cellstr('Jan');
                elseif month_num(i,j) ==2
                    month_cell(i,j) =cellstr('Feb');
                elseif month_num(i,j) ==3
                    month_cell(i,j) =cellstr('Mar');
                elseif month_num(i,j) ==4
                    month_cell(i,j) =cellstr('Apr');
                elseif month_num(i,j) ==5
                    month_cell(i,j) =cellstr('May');
                elseif month_num(i,j) ==6
                    month_cell(i,j) =cellstr('Jun');
                elseif month_num(i,j) ==7
                    month_cell(i,j) =cellstr('Jul');
                elseif month_num(i,j) ==8
                    month_cell(i,j) =cellstr('Aug');
                elseif month_num(i,j) ==9
                    month_cell(i,j) =cellstr('Sep');
                elseif month_num(i,j) ==10
                    month_cell(i,j) =cellstr('Oct');
                elseif month_num(i,j) ==11
                    month_cell(i,j) =cellstr('Nov');
                elseif month_num(i,j) ==12
                    month_cell(i,j) =cellstr('Dec');
                else
                    error('Invalid month number')
                end
            end
        end
        
    elseif abb_option ==2
        for i=1:l
            for j=1:w
                if month_num(i,j) ==1
                    month_cell(i,j) =cellstr('Jan');
                elseif month_num(i,j) ==2
                    month_cell(i,j) =cellstr('Feb');
                elseif month_num(i,j) ==3
                    month_cell(i,j) =cellstr('Mar');
                elseif month_num(i,j) ==4
                    month_cell(i,j) =cellstr('Apr');
                elseif month_num(i,j) ==5
                    month_cell(i,j) =cellstr('May');
                elseif month_num(i,j) ==6
                    month_cell(i,j) =cellstr('June');
                elseif month_num(i,j) ==7
                    month_cell(i,j) =cellstr('July');
                elseif month_num(i,j) ==8
                    month_cell(i,j) =cellstr('Aug');
                elseif month_num(i,j) ==9
                    month_cell(i,j) =cellstr('Sept');
                elseif month_num(i,j) ==10
                    month_cell(i,j) =cellstr('Oct');
                elseif month_num(i,j) ==11
                    month_cell(i,j) =cellstr('Nov');
                elseif month_num(i,j) ==12
                    month_cell(i,j) =cellstr('Dec');
                else
                    error('Invalid month number')
                end
            end
        end
        
    elseif abb_option==3
        for i=1:l
            for j=1:w
                if month_num(i,j) ==1
                    month_cell(i,j) =cellstr('J');
                elseif month_num(i,j) ==2
                    month_cell(i,j) =cellstr('F');
                elseif month_num(i,j) ==3
                    month_cell(i,j) =cellstr('M');
                elseif month_num(i,j) ==4
                    month_cell(i,j) =cellstr('A');
                elseif month_num(i,j) ==5
                    month_cell(i,j) =cellstr('M');
                elseif month_num(i,j) ==6
                    month_cell(i,j) =cellstr('J');
                elseif month_num(i,j) ==7
                    month_cell(i,j) =cellstr('J');
                elseif month_num(i,j) ==8
                    month_cell(i,j) =cellstr('A');
                elseif month_num(i,j) ==9
                    month_cell(i,j) =cellstr('S');
                elseif month_num(i,j) ==10
                    month_cell(i,j) =cellstr('O');
                elseif month_num(i,j) ==11
                    month_cell(i,j) =cellstr('N');
                elseif month_num(i,j) ==12
                    month_cell(i,j) =cellstr('D');
                else
                    error('Invalid month number')
                end
            end
        end
        
        
    end
    
    
    
end


