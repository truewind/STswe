% Grids a dataset D2 into a larger, existing dataset D1 within a structure.  A
% variable will only be gridded in D2 if it exists in both D1 and D2 (same
% exact name), and there is some overlap in time between D1 and D2.
%
% RELEASE NOTES
%   Written by Mark Raleigh (mraleig1@uw.edu), April 2013
%   Version 1.1 edited by Mark Raleigh, Dec 2013:
%           - fixed bugs with repeat time step checker and created
%             subfunction to check for repeat steps
%           - introduced "max_int" variable, where users can now specify
%             the maximum gap size (hrs) to allow interpolation
%   Version 1.2 edited by Mark Raleigh, Nov 2015:
%           - improved performance in direct insertion when max_int is set
%           to 0 (uses intersect.m command to quickly index common time steps)
%
% SYNTAX
%   D1 = data_grid(D1, D2)
%   D1 = data_grid(D1, D2, repeat_time)
%   D1 = data_grid(D1, D2, repeat_time, add_col)
%   D1 = data_grid(D1, D2, repeat_time, add_col, max_int)
%
% INPUTS
%   D1 = master data (packed into a structure - use v2struct)
%   D2 = data that will be gridded to D1
%   repeat_time: what should be done if repeat time steps found in D2?
%             enter 1 to stop program w/ error
%             enter 2 to average the repeated steps
%   add_col: enter column number to begin adding data for matching (default = 1)
%             if multiple columns exist in D2, these will all be added to
%             D1, starting at add_col
%   max_int: maximum interpolation length (hrs).  Default is that it will
%             interpolate over any gap length.  Enter 0 to turn off
%             interpolation and quickly use direct insertion where possible
%
% OUTPUTS
%   D1 = master data, with D2 gridded (if TIME overlaps) for all variables
%   with the SAME NAME
%
% NOTE
%   Both D1 and D2 must have a 7-column TIME matrix (time_builder.m
%   format)... the TIME matrix must be named "TIME" in both


function D1 = data_grid(D1,D2,arg01,arg02,arg03)

%% Checks

if nargin==2
    repeat_time = 1;
    add_col = 1;
    max_int = 0;
elseif nargin==3
    repeat_time = arg01;
    add_col = 1;
    max_int = 0;
elseif nargin==4
    repeat_time = arg01;
    add_col = arg02;
    max_int = 0;
elseif nargin==5
    repeat_time = arg01;
    add_col = arg02;
    max_int = arg03;
else
    error('Invalid number of inputs')
end

names1 = fieldnames(D1);
names2 = fieldnames(D2);

if isstruct(D1)==0 || isstruct(D2)==0
    error('Both inputs must be structure arrays')
end

if isempty(find(strcmp('TIME', names1)==1))==1 || isempty(find(strcmp('TIME', names2)==1))==1
    error('Both D1 and D2 must have a TIME variable in the structure')
end

if numel(add_col)~=1 || add_col<=0 || add_col-floor(add_col)~=0
    error('Invalid add_col')
end

if numel(max_int)~=1 || max_int < 0 || max_int-floor(max_int)~=0
    error('Invalid max_int')
end

%% Code


%%% check for repeat time steps in D1 and D2
D1 = remedy_repeat_steps(D1, repeat_time);
D2 = remedy_repeat_steps(D2, repeat_time);

%%% find min and max times of D2 dataset
sd1 = nanmin(D2.TIME(:,7));
sd2 = nanmax(D2.TIME(:,7));
L2 = size(D2.TIME,1);

%%% check to see if the two datasets overlap
td1 = nanmin(D1.TIME(:,7));
td2 = nanmax(D1.TIME(:,7));
L1 = size(D1.TIME,1);




if td1>sd2 || td2 < sd1
    disp('D1 and D2 do not overlap.  Gridding was not done.  Expand D1')
else
    
    t1 = find(D1.TIME(:,7)>=sd1,1,'first');
    t2 = find(D1.TIME(:,7)<=sd2,1,'last');
    
    
    
    %%% cycle through variable names in D1 and check if any matches in D2
    for j=1:numel(names1)
        if nanmax(strcmp(char(names1(j)), 'TIME'))==0
            if nanmax(strcmp(char(names1(j)), names2))==1
                % then we have a match!
                
                f1 = getfield(D1,char(names1(j)));      % grab current field in D1
                f2 = getfield(D2,char(names1(j)));      % grab same field in D2
                
                lf1 = size(f1,1);
                wf1 = size(f1,2);
                
                if size(f2,1)==L2
                    % then it is the correct length!
                    
                    D2TIME = D2.TIME(:,7);
                    
                    
                    if max_int==0
                        %%% use quick direct insertion via intersect.m
                        
                        %%% at this point, there should be no repeats in
                        %%% either D1.TIME(:,7) or D2.TIME(:,7). this is
                        %%% important for intersect.m
                        
                        %%% get matching indices
                        [~,ia,ib] = intersect(D1.TIME(t1:t2,7),D2.TIME(:,7));
                        
                        %%% initialize f3
                        f3 = zeros(size(D1.TIME(t1:t2,:),1), size(f2,2))*NaN;
                                
                        
                        %%% make f3
                        f3(ia,:) = f2(ib,:);
                        
                        
                        
                    else
                        %%% check if direct insertion is possible (ideal approach)
                        rflag = 0;
                        
                        if isempty(t1)==0 && isempty(t2)==0
                            if size(D1.TIME(t1:t2,:),1) == size(D2TIME,1)
                                if nanmax(nanmax(D1.TIME(t1:t2,7)-D2TIME))==0
                                    % then the time matrices align and we can use direct insertion
                                    rflag=1;
                                    r1 = find(D2TIME==sd1,1,'first');
                                    r2 = find(D2TIME==sd2,1,'last');
                                    
                                    f3 = f2(r1:r2,:);
                                    disp('...gridding with direct insertion')
                                end
                            end
                        end
                        
                        
                        
                        if rflag ==0
                            %%% then we will have to grid the data via interpolation
                            disp('...gridding with interpolation')
                            
                            
                            try
                                f3 = zeros(size(D1.TIME(t1:t2,:),1), size(f2,2))*NaN;
                                
                                for k = 1:size(f2,2)
                                    f3(:,k) = interp1(D2TIME,f2(:,k),D1.TIME(t1:t2,7));
                                end
                                
                                
                                
                                %%% note that you may lose some values when
                                %%% interpolating with NaNs in the dataset.  (e.g.,
                                %%% when interplating between a real number and a
                                %%% NaN, the result is NaN).
                                %%% We will now attempt to recover any lost values
                                %%% but only at time steps that are exactly the
                                %%% same in D1 and D2.  This is achieved with
                                %%% direct insertion at any time steps that align
                                
                                for k=1:size(D2.TIME,1)
                                    a = find(D1.TIME(t1:t2,7)==D2.TIME(k,7));
                                    
                                    if isempty(a)==0
                                        f3(a,:) = f2(k,:);
                                    end
                                end
                                
                                
                            catch
                                save dout.mat
                                error('here')
                            end
                            
                            
                            %%% check max_int
                            if max_int>0
                                disp('.....constraining interpolation length')
                                
                                %%% find gaps that exceed max_int
                                DTIME2sort = sortrows(D2.TIME,7);
                                DTIME2diff = diff(DTIME2sort(:,7));
                                
                                D2maxint = find(DTIME2diff>max_int/24);
                                
                                if isempty(D2maxint)==0
                                    d2mi_nan = [];
                                    for d2mi=1:size(D2maxint,1)
                                        d2mi_nan = [d2mi_nan; find(D1.TIME(t1:t2,7) > DTIME2sort(D2maxint(d2mi),7) & D1.TIME(t1:t2,7) < DTIME2sort(D2maxint(d2mi)+1,7))];
                                    end
                                    f3(d2mi_nan,:) = NaN;
                                end
                            end
                            
                        end
                    end
                    
                    %%% find what width of new matrix will be
                    newwidth = add_col+size(f2,2)-1;
                    
                    
                    %%% now bring the gridded data into the master structure
                    if wf1<newwidth
                        %%% need to increase the size of D1 variable
                        eval(['D1.' char(names1(j)) '= addcol(D1.' char(names1(j)) ', wf1+1, newwidth-wf1);'])
                    end
                    eval(['D1.' char(names1(j)) '(t1:t2,add_col:newwidth)=f3;'])
                    
                    
                    
                    clear f1 f2 f3
                end
            end
        end
    end
end

end


%% subfunction: duplicate time steps


function D = remedy_repeat_steps(D, repeat_time)

L = size(D.TIME,1);

repeat_t = find_repeat(D.TIME(:,7));

if isempty(repeat_t)==1
    % do nothing... return D
else
    
    
    dlist = [];
    
    for k=1:numel(repeat_t)
        A = find(D.TIME(:,7)==repeat_t(k));
        R.ind(:,k) = A;
        Arest = A(2:end);
        dlist = [dlist; Arest];     % rows to delete afterward
    end
    
    
    
    if repeat_time==1
        error('Repeat time steps detected, but no direction provided.')
    elseif repeat_time==2
        %%% average the repeat time steps
        disp('...repeat steps found... averaging data')
        
        
        D.TIME = delrow(D.TIME, dlist);
        
        names1 = fieldnames(D);
        
        for j=1:numel(names1)
            if nanmax(strcmp(char(names1(j)), 'TIME'))==0
                
                
                f1 = getfield(D,char(names1(j)));      % grab current field in D
                lf1 = size(f1,1);
                
                if lf1==L
                    
                    for k=1:numel(repeat_t)
                        A = R.ind(:,k);
                        f1(A(1),:) = nanmean(f1(A,:));
                    end
                    
                    f1 = delrow(f1, dlist);
                    eval(['D.' char(names1(j)) '=f1;'])
                    
                end
                
                
            end
        end
        
        
        
    end
    
    
    
end


end




