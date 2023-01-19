function [numReps, numConds, flyList, flyIndices] = DLC_extract_flies(data)
    numReps = max(data.rep); 
    numConds = max(data.condnum);

    % Get list of flies for data
    [C,ia,~] = unique([data.fly, data.date_parsed], 'rows');
%     [C,ia,~] = unique([data.Fly_, data.date_parsed], 'rows'); %some files the 'fly' var is missing? So have to use this 'Fly_' var instead. 

    % add other info to C
    C(:,end+1) = data.FlyLine(ia);
    C(:,end+1) = data.Sex(ia);
    C(:,end+1) = data.Head(ia);
    C(:,end+1) = data.Ball(ia);
    C(:,end+1) = data.StimulusProcedure(ia);
    C(:,end+1) = data.flyid(ia);

    flies_nomissing = rmmissing(C(:,1));
    dates_nomissing = rmmissing(C(:,2));
    
    var_names = {'fly', 'date', 'line', 'sex', 'head', 'ball', 'procedure','flyid'};
    
    flyList = rmmissing(C);
    for fly = 1:height(flyList)
       %get index of fly 
       dateIdx = find(strcmpi(flyList{fly,2}, dates_nomissing'));
       flyIdx = find(strcmpi(flyList{fly,1}, flies_nomissing'));
       idx = intersect(flyIdx, dateIdx);

       flyIndices(fly) = ia(idx, :);
    end
    
    %if info in flyList is not in order by date (oldest to newest) 
    %then indices in flyIndices will not be correct (they will not be in
    %order (first to last frame). If this is the case, re-order them. 
   [newFlyIndices,oldIdxs] = sort(flyIndices);
   newFlyList = flyList(oldIdxs,:);
   
   %add last frame to mark end of data for last fly 
   newFlyIndices(end+1) = height(data); 
   
   
   %save flyList and flyIndices
%    flyList = table(newFlyList(:,1), newFlyList(:,2));
   flyList = [];
   for var = 1:width(newFlyList)
       flyList = [flyList, table(newFlyList(:,var),'VariableNames',var_names(var))];
   end
   flyIndices = newFlyIndices;


end