function behavior = DLC_behavior_predictor(data, param, ROIpre, ROIpost)
% Determines behavior before stim, after stim, & leg joint angle at stim
% S Walling-Bell
% University of Washington, 2020

% classify behavior of each fly 

    if nargin < 3
        ROIpre = 100:150; % if no ROIs given, assess 50 frames before & after stim onset
        ROIpost = 150:200;
    end
    vidLength = param.vid_len_f; % length of vids in frames

    % Get unique flies in this line
    numReps = param.numReps; 
    numConds = param.numConds; 
    flyList = param.flyList; 
    flyIndices = param.flyIndices;

    % For each unique fly, classify behavior for each cond/rep and save to struct. 
    behavior.data = cell((height(flyList)*numReps*numConds), 9); 
    behavior.labels = {'date', 'fly', 'cond', 'rep', 'preBehavior', 'postBehavior', 'jntAngle', 'phase', 'data_start_idx', 'data_end_idx', 'flyid', 'procedure'};
    behaviorIdx = 0; %for iterating through behavior.data
    for fly = 1:height(flyList)
        % select fly data
        flyData = data(flyIndices(fly):(flyIndices(fly+1)-1), :);
        [A, ib, ~] = unique(flyData.filename);
        flyVids = A(1:end-5, :); % Get rid of dummy vids 
        flyVidIdx = ib(1:end-5, :); % Get rid of dummy vid idxs 
        
        %classify behavior for all vids of fly 
        for vid = 1:height(flyVids)
%             fprintf(['\nFly: ' num2str(fly) ' vid: ' num2str(vid)]);
            behaviorIdx = behaviorIdx+1;
            start_idx = flyVidIdx(vid);
            end_idx = start_idx + vidLength - 1;
            if end_idx > height(flyData); end_idx = height(flyData); end %added when a video in iav x gtacr1 was 599 frames. 
            if end_idx - start_idx > 5 %vid must have at least 5 frames. troubleshooting thing. 
                vidData = flyData(start_idx:end_idx, :);
%                 fprintf(['\nFly: ' num2str(fly) ' vid: ' num2str(vid)]);
                % find behavior at ROIpre
                behaviorPRE = behavior_pred(vidData, ROIpre, param.thresh);

                % find behavior at ROIpost
                behaviorPOST = behavior_pred(vidData, ROIpost, param.thresh);

                % find joint angle at stim 
                jntAngle = 'NaN'; %vidData.L1_FTi(param.laser_on);

                % find phase at stim 
                jntPhase = 'NaN'; %TODO calculate this if fly is walking... 

                % find cond and rep
                this_rep = vidData.rep(1);
                this_cond = vidData.condnum(1);

                % save classifications to behavior.data
                behavior.data{behaviorIdx, 1} = flyList{fly,1};
                behavior.data{behaviorIdx, 2} = flyList{fly,2};
                behavior.data{behaviorIdx, 3} = this_cond;
                behavior.data{behaviorIdx, 4} = this_rep;
                behavior.data{behaviorIdx, 5} = behaviorPRE;
                behavior.data{behaviorIdx, 6} = behaviorPOST;
                behavior.data{behaviorIdx, 7} = jntAngle; 
                behavior.data{behaviorIdx, 8} = jntPhase;
                behavior.data{behaviorIdx, 9} = (start_idx+(param.flyIndices(fly)-1)); %start idx for this vid in 'data'
                behavior.data{behaviorIdx, 10} = (end_idx+(param.flyIndices(fly)-1)); %end idx for this vid in 'data'
                behavior.data{behaviorIdx, 11} = flyData.flyid(start_idx);
                behavior.data{behaviorIdx, 12} = flyData.StimulusProcedure(start_idx);
            end
        end
    end
end