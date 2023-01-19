function step = steps_walking_x_temp(varargin)

% Given some data, extract walking bouts and parse steps by tarsi y positions. 
% Calculate several step metrics and save average speed and temperature for each step. 
% 
% Required Params:
%     data = a parquet summary file of data
%     param = param struct from DLC_load_params.m
%     
% Optional Params:
%     threshold = a vector of prominence thresholds for detecting the tarsi y position peaks 
%         and troughs. For [L1, L2, L3, R1, R2, R3] legs. Default is 0.2 for all legs. 
%         
% Returns: 
%     step = a structure with step metrics for every leg. 
%     
% The step metrics calculated are:
%     - step frequency (Hz)
%     - step length (Euclidean distance between tarsi position, not sure of units yet)
%     - swing duration (s) 
%     - stance duration (s)
%     - speed x (mm/s; sideslip velocity, fly moving right is positive.) 
%     - speed y (mm/s; forward velocity, fly moving forward is positive.) 
%     - speed z (mm/s; rotational velocity, fly moving cw is positive.) 
%     - temp (C) 
%     - fly (date and num) 
%     - idxs (indices of step in data so I can find the video in the
%     vizualizer)
%     
% Sarah Walling-Bell, January 2022
%     
    
    

positionPThresh = [0.2, 0.2, 0.2, 0.2, 0.2, 0.2]; %prominence threshold for peak detection of tarsi y position data for parsing steps
% parse input params
for ii = 1:nargin
        if ischar(varargin{ii}) && ~isempty(varargin{ii})
            if varargin{ii}(1) == '-' %find command descriptions
                switch lower(varargin{ii}(2:end))
                    case 'data'
                        data = varargin{ii+1};
                    case 'param'
                        param = varargin{ii+1};
                    case 'threshold'
                        positionPThresh = varargin{ii+1};
                end
            end
        end
    end
if ~exist('data','var') | ~exist('param','var')
    error('Missing required parameter(s)');
end
    
%get walking data
walkingData = data(~isnan(data.walking_bout_number),:); 
walkingDataIdxs = find(~isnan(data.walking_bout_number)); %indices of walkingData in data

%calculate step frequency on all data (then select forward walking after)
%(findpeaks)
% freqDeterms = {'L1_FTi', 'L2B_rot', 'L3_FTi', 'R1_FTi', 'R2B_rot', 'R3_FTi'}; %a joint variable for each leg that will be used to calculate step frequency
% freqPThresh = [20,10,20,20,10,20];
% positionPThresh = [0.2, 0.2, 0.2, 0.2, 0.2, 0.2];
format long
% instdirData = rad2deg(walkingData.inst_dir);

% boutData = walkingData.walking_bout_number;
tempData = walkingData.temp; 
speed_x = walkingData.fictrac_delta_rot_lab_x; 
speed_y = walkingData.fictrac_delta_rot_lab_y; 
speed_z = walkingData.fictrac_delta_rot_lab_z; 
fly_num = walkingData.flyid; 
procedure = walkingData.StimulusProcedure;


%flies from different days can have the same bout number, so rename
%bouts to have unique numbers:
subBouts = boutMap(walkingData,param);

for leg = 1:6
%     jntData = smooth(abs(walkingData.(freqDeterms{leg}))); %abs corrects wrap around of rotation data
    tarsiPosition = [walkingData.([param.legs{leg} 'E_x']), walkingData.([param.legs{leg} 'E_y']), walkingData.([param.legs{leg} 'E_z'])];
    if contains(param.legs(leg), '3') | contains(param.legs(leg), 'L2')
            %for T3 troughs are stance start - so invert signal to make peaks stance starts
            %for L2, stance is positive values, so trough to peak, so
            %invert so peaks are stance starts. 
%             jntData = jntData *-1;
            tarsiPosition = tarsiPosition *-1;
    end

    step(leg).freq = []; %step frequency 
    step(leg).length = []; %step length
    step(leg).swing_dur = []; %swing duration 
    step(leg).stance_dur = []; %stance duration 
    step(leg).speed_x = []; %delta_rot_lab_x (crabwalking)
    step(leg).speed_y = []; %delta_rot_lab_y (forward/backward)
    step(leg).speed_z = []; %delta_rot_lab_z (turning)
    step(leg).temp = []; %temp (avg per step)
    step(leg).fly = []; %the index of the fly in flyList (aka fly num)
    step(leg).procedure = []; %low, medium, high temp
    step(leg).step_start_idx = []; %first idx of step in data
    step(leg).step_end_idx = []; %last idx of step in data
    
%     for bout = 1:max(boutData)
    for bout = 1:height(subBouts)
        
%         this_data = jntData(boutMap.walkingDataIdxs{bout}); 
        this_tarsiPos = tarsiPosition(subBouts.walkingDataIdxs{bout},:);
        this_speed_x = speed_x(subBouts.walkingDataIdxs{bout});
        this_speed_y = speed_y(subBouts.walkingDataIdxs{bout});
        this_speed_z = speed_z(subBouts.walkingDataIdxs{bout});
        this_temp = tempData(subBouts.walkingDataIdxs{bout});
        this_fly = fly_num(subBouts.walkingDataIdxs{bout});
        this_idxs = walkingDataIdxs(subBouts.walkingDataIdxs{bout});
        this_procedure = procedure(subBouts.walkingDataIdxs{bout});
        
        if ~isempty(this_tarsiPos)
%             [pks, plocs] = findpeaks(this_data,'MinPeakProminence',freqPThresh(leg)); %peaks = stance starts
%             [trs, tlocs] = findpeaks(this_data*-1,'MinPeakProminence',freqPThresh(leg)); %troughs = swing starts
%             
            [tarsi_pks, tarsi_plocs] = findpeaks(this_tarsiPos(:,2),'MinPeakProminence',positionPThresh(leg)); %peaks = stance starts
            [tarsi_trs, tarsi_tlocs] = findpeaks(this_tarsiPos(:,2)*-1,'MinPeakProminence',positionPThresh(leg)); %troughs = swing starts
            
            if height(tarsi_plocs) > 3 % filter out bouts with fewer steps
                %calculate step frequency 
%                 this_freq = 1./(diff(plocs)/param.fps); %from joint data
                this_freq = 1./(diff(tarsi_plocs)/param.fps); %from tarsi y position 

                step_speed_x = [];
                step_speed_y = [];
                step_speed_z = [];
                step_temp = [];
                this_step_length = [];
                step_fly = {};
                step_start_idx = [];
                step_end_idx = [];
                step_procedure = {};
                
                for st = 1:height(tarsi_plocs)-1
                    %calc avg speeds per step
                    step_speed_x(st,1) = nanmean(this_speed_x(tarsi_plocs(st):tarsi_plocs(st+1))); %avg speed x for each step 
                    step_speed_y(st,1) = nanmean(this_speed_y(tarsi_plocs(st):tarsi_plocs(st+1))); %avg speed y for each step 
                    step_speed_z(st,1) = nanmean(this_speed_z(tarsi_plocs(st):tarsi_plocs(st+1))); %avg speed z for each step 
                    
                    %calc avg temp per step 
                    step_temp(st,1) = nanmean(this_temp(tarsi_plocs(st):tarsi_plocs(st+1))); %avg temperature for each step 
                    
                    %calculate step length (3D euclidian distance) 
                    this_step_length(st,1) = sqrt(sum((this_tarsiPos(tarsi_plocs(st),:) - this_tarsiPos(tarsi_tlocs(st),:)).^2, 2));
                    
                    %fly num 
                    step_fly{st, 1} = this_fly{tarsi_plocs(st)}(1:end-2); %take off end which is trial num
                    
                    %get procedure type
                    step_procedure{st, 1} = this_procedure{tarsi_plocs(st)};
                    
                    %idxs in data 
                    step_start_idx(st, 1) = this_idxs(tarsi_plocs(st));
                    step_end_idx(st, 1) = this_idxs(tarsi_plocs(st+1)-1);
                    
                end
                
                %swing and stance dur
                if tarsi_tlocs(1) < tarsi_plocs(1)
                    % trim off first trough so data starts with peak. 
                    % must do this so step data aligns with other vars
                    % which are calculated on first peak to last peak of the data. 
                    tarsi_tlocs = tarsi_tlocs(2:end);
                end
                if tarsi_tlocs(end) > tarsi_plocs(end)
                    % trim off last trough so data ends with peak. 
                    % must do this so step data aligns with other vars
                    % which are calculated on first peak to last peak of the data. 
                    tarsi_tlocs = tarsi_tlocs(1:end-1);
                end
                all_peaksNtroughs = sort([tarsi_plocs; tarsi_tlocs]);
                all_durations = diff(all_peaksNtroughs)/param.fps; 
                %first duration is peak to trough, which is stance. 
                this_stance_dur = all_durations(1:2:end); %odds
                this_swing_dur = all_durations(2:2:end); %evens
                
                %save data
                step(leg).freq = [step(leg).freq; this_freq];
                step(leg).length = [step(leg).length; this_step_length];
                step(leg).stance_dur = [step(leg).stance_dur; this_stance_dur]; 
                step(leg).swing_dur = [step(leg).swing_dur; this_swing_dur]; 
                step(leg).speed_x = [step(leg).speed_x; step_speed_x];
                step(leg).speed_y = [step(leg).speed_y; step_speed_y];
                step(leg).speed_z = [step(leg).speed_z; step_speed_z];
                step(leg).temp = [step(leg).temp; step_temp];
                step(leg).fly = [step(leg).fly; step_fly];
                step(leg).procedure = [step(leg).procedure; step_procedure];
                step(leg).step_start_idx = [step(leg).step_start_idx; step_start_idx];
                step(leg).step_end_idx = [step(leg).step_end_idx; step_end_idx];
            end
        end
    end
end




end