function steps = steps(boutMap, walkingData, param)

For each bout, calculate the swing and stance portions across legs, and 
various step metrics:
    Step frequency
    Step period -TODO
    Step length
    Swing duration 
    Stance duration
    
    
% DESCRIPTION
% 
% Required Params:
%     'boutMap' - a table of walking bout data from boutMap.m
%     'walkingData' = rows of 'data' parquet summary file where walking_bout_number is not nan.
%         data(~isnan(data.walking_bout_number),:); 
%     'param' - param struct from DLC_load_params.m
% 
% Output:
%     'steps' - a table for each leg with all of its steps and various
%               metadata. 
%         - steps.leg(#).meta = table with various metadata for each step: 
%                               'fly' - flyid param in walkingData.
%                               'walkingDataIdxs' - indices of step in walkingData.
%              TODO                 'boutNum' - the 'newBout' id in boutMap
%                                   that this step comes from. 
%                 TODO              'stepNum' - the step number in the bout.
%                                   Ex: 1 = first step in bout. 5 = fifth step
%                                   in bout. 
%                               'step_frequency' - step frequency (Hz) of this step
%        TODO                       'step_duration' - duration of the step (seconds). 
%                               'step_length' - euclidian distance (3D)
%                                   between tarsi tip position of a leg at AEP
%                                   to PEP (unknown units).
%                               'swing_duration' - duration (seconds) of swing.
%                               'stance_duration' - duration (seconds) of stance.
%                               'avg_heading_angle' - average heading angle
%                                   (degrees) of fly during this step. 
%                               'avg_heading_bin' - average heading angle
%                                   bin of fly during this step. 
%                               'avg_forward_rotation' - forward rotation
%                                   is 1 if fly's heading direction is within 
%                                   param.forward_rot_thresh of forward (zero).
%                                   So, avg_forward_rotation is a fraction indicating 
%                                   the percent of the step that has a heading 
%                                   angle within that threshold (1 = entire step 
%                                   is forward, 0 = none of the step is forward). 
%                               'avg_speed' - average speed (mm/s) of fly
%                                   during this step. 
%                               'avg_speed_bin' - average speed bin of fly
%                                   during this step. 
%             TODO                  'avg_acceleration' - average acceleration 
%                                   (mm/s^2) of fly during this step. 
%                               'avg_angular_velocity' - average angular
%                                   velocity (deg/s) of fly during this step. 
%                               'avg_temp' - average temperature (C) of ball area 
%                                   during this time.
%                               'avg_stim' - percent of step that occured
%                                   during laser stim. 0 = no laser on during
%                                   step. 1 = step occured entirely during
%                                   laser. 
%           TODO                    'stim_on_region' - if stim comes on
%                                   during step, which region does it come on 
%                                   during, 'swing' or 'stance. 
%          TODO                     'stim_on_phase' - if sti mcomes on
%                                   during step, what phase (hilbert) of
%                                   step does it come on during. 

%         
%
% Filtering conditions & info:
%     - 
%
% Example uses:
%     - 
% 
%
% Sarah Walling-Bell
% November, 2021


% (Lab Mtg 2021) NEW (for Lab Mtg 2021) (filter by forward after metrics) - CALCULATE: step freq, speed, temp, heading dir, step length, stance dur, swing dur from BOUTMAP


warning('off','MATLAB:table:RowsAddedExistingVars') %turn off warning for filling only sub columns at a time for each row. 

%legs and joints to add data of 
joints = {'_FTi', 'B_rot', 'E_x', 'E_y', 'E_z'};
joint_names = {'FTi', 'B_rot', 'E_x', 'E_y', 'E_z'};

% define butterworth filter for hilbert transform.
[A,B,C,D] = butter(1,[0.02 0.4],'bandpass');
sos = ss2sos(A,B,C,D);

%get a list of bouts where ther were enough steps in 'swing stance' screening
% goodBouts=find(~cellfun('isempty', boutMap{:,'forward_rotation'}));
goodBouts = find(boutMap.enough_steps == 1);

steps = struct;
for leg = 1:param.numLegs
    steps.leg(leg).meta = table('Size', [0,15], ...
        'VariableTypes',{'string','cell','double', 'double','double', 'double','double', ...
        'double','double', 'double','double', 'double','double', 'double','double'}, ...
        'VariableNames',{'fly', 'walkingDataIdxs', 'step_frequency', 'step_length', 
        'swing_duration', 'stance_duration', 'avg_heading_angle', 'avg_heading_bin', ...
        'avg_forward_rotation', 'avg_speed', 'avg_speed_bin', 'avg_forward_velocity', ...
        'avg_angular_velocity', 'avg_temp', 'avg_stim'});
    
%     steps.leg(leg).FTi = NaN(1, 100);
end

leg_step_idxs = [0, 0, 0, 0, 0, 0]; %row idxs for saving data in steps struct
for bout = 1:height(goodBouts)
    this_bout = goodBouts(bout); %idx in boutMap
    this_bout_idxs = boutMap.walkingDataIdxs{this_bout}; %idxs in walkingData
    
    % calculate metrics that are the same across legs
    % fly number
    this_fly = walkingData.flyid{this_bout_idxs(1)};
    % opto stim region 
    this_laser_length = param.allLasers(walkingData.condnum(this_bout_idxs(1))); %in seconds
    this_stim = zeros(width(this_bout_idxs),1); % 0 = no stim; 1 = stim
    this_fnum = walkingData.fnum(this_bout_idxs);
    laser_off = param.laser_on+(this_laser_length*param.fps);
    if this_laser_length > 0 & ~(this_fnum(1) > laser_off | this_fnum(end) < param.laser_on) %TODO check that this is correct logic
        this_stim(this_fnum >=param.laser_on & this_fnum < laser_off) = 1;
    end
    
    for leg = 1:param.numLegs
        %indexes within bout
        this_swing_stance = boutMap.([param.legs{leg} '_swing_stance']){this_bout}; %swing = 1; stance = 0
        this_stance_starts = [find(this_swing_stance == 0,1,'first'); find(diff(this_swing_stance) == -1)+1; find(this_swing_stance == 1,1,'last');]; %first idxs of stance
        this_stance_ends = find(diff(this_swing_stance) == 1); %last idxs of stances
        %same indexes in walkingData - add start idx of bout in walkingData to convert from bout to walkingData idxs
        this_stance_starts_walkingData = this_stance_starts + this_bout_idxs(1); %TODO check this
%         this_stance_ends_walkingData = this_stance_ends + this_bout_idxs(1); %TODO check this

        %Get all of the joint data
        jointTable = table;
        phaseTable = table;
        for joint = 1:width(joints)
            joint_str = [param.legs{leg} joints{joint}];
            jointTable.(joint_str) = walkingData.(joint_str)(this_bout_idxs);
            %calcualte phase (hilbert transform)
            normed_data = (jointTable.(joint_str)-nanmean(jointTable.(joint_str)))/nanstd(jointTable.(joint_str));
            bfilt_data = sosfilt(sos, normed_data);  %bandpass frequency filter for hilbert transform            
            phaseTable.(joint_str) = angle(hilbert(bfilt_data));
        end
   
        %calculate and save metrics and data for each step    
        for st = 1:height(this_stance_ends)
            % step idxs in bout - for indexing into jointTable
            this_step_idxs = this_stance_starts(st):this_stance_starts(st+1);
            this_stance = this_stance_starts(st):this_stance_ends(st);
            this_swing = this_stance_ends(st)+1:this_stance_starts(st+1);
            
            % step idxs in walkingData
            this_step_idxs_walkingData = this_stance_starts_walkingData(st):this_stance_starts_walkingData(st+1);
%             this_stance_walkingData = this_stance_starts_walkingData(st):this_stance_ends_walkingData(st);
%             this_swing_walkingData = this_stance_ends_walkingData(st)+1:this_stance_starts_walkingData(st+1);

            %calculate step frequency
            step_freq =  1./(width(this_step_idxs)/param.fps);
            
            %calculate step length - TODO what are the units?
            shift_val = 10; %add to each position value to make them all positive. 0 point from anipose is L1_BC position.
            start_positions = [jointTable.([param.legs{leg} 'E_x'])(this_stance(1)), jointTable.([param.legs{leg} 'E_y'])(this_stance(1)), jointTable.([param.legs{leg} 'E_z'])(this_stance(1))];
            end_positions = [jointTable.([param.legs{leg} 'E_x'])(this_stance(end)), jointTable.([param.legs{leg} 'E_y'])(this_stance(end)), jointTable.([param.legs{leg} 'E_z'])(this_stance(end))];
            start_positions = start_positions + shift_val;
            end_positions = end_positions + shift_val;
            step_length = sqrt((end_positions(1)-start_positions(1))^2 + (end_positions(2)-start_positions(2))^2 + (end_positions(3)-start_positions(3))^2);            
           
            %calculate swing and stance duration 
            swing_duration = width(this_swing)/param.fps;
            stance_duration = width(this_stance)/param.fps;
            
            %calculate avgs: heading, speed, temp,
            avg_heading_angle = nanmean(walkingData.heading_angle(this_step_idxs_walkingData));
            avg_speed = nanmean(walkingData.speed(this_step_idxs_walkingData));
            %avg_forward_velocity = nanmean(walkingData.forward_velocity(this_step_idxs_walkingData));
            avg_angular_velocity = nanmean(walkingData.angular_velocity(this_step_idxs_walkingData));
            avg_temp = nanmean(walkingData.temp(this_step_idxs_walkingData));
            
            %calcualte avg bins: percent forward & avg speed bin 
            avg_speed_bin = nanmean(walkingData.speed_bin(this_step_idxs_walkingData));
            avg_forward_rotation = nanmean(walkingData.forward_rotation(this_step_idxs_walkingData)); %(0 = fully not forward, 1 = fully forward)
            avg_heading_bin = nanmean(walkingData.heading_bin(this_step_idxs_walkingData));
            
            %calculate percent opto (0 = fully no stim, 1 = fully stim)
            avg_stim = nanmean(this_stim(this_step_idxs));
                
            %save everything! - all metrics + joint and phase variables. 
            leg_step_idxs(leg) = leg_step_idxs(leg)+1; %update leg step idx.
            for joint = 1:width(joints)
                joint_str = [param.legs{leg} joints{joint}];
                steps.leg(leg).(joint_names{joint})(leg_step_idxs(leg),1:width(this_step_idxs)) = jointTable.(joint_str)(this_step_idxs);
                steps.leg(leg).([joint_names{joint} '_phase'])(leg_step_idxs(leg),1:width(this_step_idxs)) = phaseTable.(joint_str)(this_step_idxs);
            end
            steps.leg(leg).meta.fly(leg_step_idxs(leg)) = this_fly;
            steps.leg(leg).meta.walkingDataIdxs{leg_step_idxs(leg)} = this_step_idxs_walkingData;
            steps.leg(leg).meta.step_frequency(leg_step_idxs(leg)) = step_freq;
            steps.leg(leg).meta.step_length(leg_step_idxs(leg)) = step_length;
            steps.leg(leg).meta.swing_duration(leg_step_idxs(leg)) = swing_duration;
            steps.leg(leg).meta.stance_duration(leg_step_idxs(leg)) = stance_duration;
            steps.leg(leg).meta.avg_heading_angle(leg_step_idxs(leg)) = avg_heading_angle;
            steps.leg(leg).meta.avg_heading_bin(leg_step_idxs(leg)) = avg_heading_bin;
            steps.leg(leg).meta.avg_forward_rotation(leg_step_idxs(leg)) = avg_forward_rotation;
            steps.leg(leg).meta.avg_speed(leg_step_idxs(leg)) = avg_speed;
            steps.leg(leg).meta.avg_speed_bin(leg_step_idxs(leg)) = avg_speed_bin;
            %steps.leg(leg).meta.avg_forward_velocity(leg_step_idxs(leg)) = avg_forward_velocity;
            steps.leg(leg).meta.avg_angular_velocity(leg_step_idxs(leg)) = avg_angular_velocity; 
            steps.leg(leg).meta.avg_temp(leg_step_idxs(leg)) = avg_temp;
            steps.leg(leg).meta.avg_stim(leg_step_idxs(leg)) = avg_stim;         
        end
        
    end
end

%find where this_joint_data is zero and replace with NaN
for leg = 1:param.numLegs 
    for joint = 1:width(joints)
        [rows,cols]=find(~steps.leg(leg).(joint_names{joint}));
        if ~isempty(rows)
            for val = 1:height(rows)
                steps.leg(leg).(joint_names{joint})(rows(val),cols(val)) = NaN;
                steps.leg(leg).([joint_names{joint} '_phase'])(rows(val),cols(val)) = NaN;
            end
        end
    end
end


end
