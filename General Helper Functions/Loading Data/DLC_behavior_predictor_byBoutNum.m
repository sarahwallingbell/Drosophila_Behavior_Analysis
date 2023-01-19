function behavior = DLC_behavior_predictor_byBoutNum(data, param)
% Determines behavior at stim onset by bout number (or other if no bout
% number currently)
% S Walling-Bell
% University of Washington, 2021

    vidLength = param.vid_len_f; % length of vids in frames

    % Get unique flies in this line
    numReps = param.numReps; 
    numConds = param.numConds; 
    flyList = param.flyList; 
    flyIndices = param.flyIndices;
    
    bout_num_idxs = find(contains(param.columns,'bout_num'));

    % For each unique fly, classify behavior for each cond/rep and save to struct. 
    behavior.data = cell((height(flyList)*numReps*numConds), 8); 
    behavior.labels = {'date', 'fly', 'cond', 'rep', 'preBehavior', 'postBehavior', 'jntAngle', 'phase', 'data_start_idx', 'data_end_idx'};
    behaviorIdx = 0; %for iterating through behavior.data
    for fly = 1:height(flyList)
        % select fly data
        flyData = data(flyIndices(fly):(flyIndices(fly+1)-1), :);
        [A, ib, ~] = unique(flyData.filename);
        flyVids = A(1:end-5, :); % Get rid of dummy vids 
        flyVidIdx = ib(1:end-5, :); % Get rid of dummy vid idxs 
        
        %classify behavior for all vids of fly 
        for vid = 1:height(flyVids)
            behaviorIdx = behaviorIdx+1;
            start_idx = flyVidIdx(vid);
            end_idx = start_idx + vidLength - 1;
            if end_idx > height(flyData); end_idx = height(flyData); end %added when a video in iav x gtacr1 was 599 frames. 
            if end_idx - start_idx > 5 %vid must have at least 5 frames. troubleshooting thing. 

                vidData = flyData(start_idx:end_idx, :);

                % find behavior at ROIpre
                boutNumsPRE = vidData(150, bout_num_idxs);
                possible_behaviors = find(~ismissing(boutNumsPRE));
                if isempty(possible_behaviors)
                    %no behavior has a bout... mark it as 'other'
                    behaviorPRE = 'other'; 
                elseif width(possible_behaviors) > 1
                    %there are multiple bouts going on
                    behaviorPRE = 'other'; %TODO pick one of the behaviors based on probability?
                else
                    %there is only one behavior bout happening
                    column_num = bout_num_idxs(possible_behaviors);
                    behaviorPRE = param.columns{column_num}(1:end-12);
                end

                % find behavior at ROIpost
    %             behaviorPOST = 'NaN'; % behavior_pred(vidData, ROIpost, param.thresh);

                % find joint angle at stim 
                jntAngle = vidData.L1_FTi(param.laser_on);

                % find phase at stim 
                if strcmpi(behaviorPRE, 'walking')
                    %find phase of step cycle at stim onset

                    %get walking bout that occured during stim onset
                    walkingBoutNum = vidData{param.laser_on, column_num};
                    boutIdxs = find(vidData{:,column_num} == walkingBoutNum);
                    boutData = vidData.L1_FTi(boutIdxs);

                    %calculate phase
                    boutData = boutData - mean(boutData); 
                    h_data = hilbert(boutData); %hilbert transform 
                    ph_data = angle(h_data); %phase of data

                    %find phase at stim on 
                    jntPhase = ph_data(param.laser_on-boutIdxs(1));

                else
                    jntPhase = 'NaN'; 
                end

                % find cond and rep
                this_rep = vidData.rep(1);
                this_cond = vidData.condnum(1);

                % save classifications to behavior.data
                behavior.data{behaviorIdx, 1} = flyList{fly,1};
                behavior.data{behaviorIdx, 2} = flyList{fly,2};
                behavior.data{behaviorIdx, 3} = this_cond;
                behavior.data{behaviorIdx, 4} = this_rep;
                behavior.data{behaviorIdx, 5} = behaviorPRE;
                behavior.data{behaviorIdx, 6} = 'NaN';
                behavior.data{behaviorIdx, 7} = 'NaN'; %jntAngle; 
                behavior.data{behaviorIdx, 8} = 'NaN'; %jntPhase;
                behavior.data{behaviorIdx, 9} = (start_idx+(param.flyIndices(fly)-1)); %start idx for this vid in 'data'
                behavior.data{behaviorIdx, 10} = (end_idx+(param.flyIndices(fly)-1)); %end idx for this vid in 'data'
            end
        end
    end
end