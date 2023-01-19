function steps = steps(boutMap, walkingData, param)    
    
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
%                               'boutNum' - the 'newBout' id in boutMap
%                                   that this step comes from. 
%                               'stepNum' - the step number in the bout.
%                                   Ex: 1 = first step in bout. 5 = fifth step
%                                   in bout. 
%                               'step_frequency' - step frequency (Hz) of this step
%                               'step_duration' - duration of the step (seconds). 
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
%                               'avg_acceleration' - average acceleration 
%                                   (mm/s^2) of fly during this step. 
%                               'avg_angular_velocity' - average angular
%                                   velocity (deg/s) of fly during this step. 
%                               'avg_temp' - average temperature (C) of ball area 
%                                   during this time.
%                               'avg_stim' - percent of step that occured
%                                   during laser stim. 0 = no laser on during
%                                   step. 1 = step occured entirely during
%                                   laser. 
%                               'stim_on_region' - if stim comes on
%                                   during step, which region does it come on 
%                                   during, 'swing' or 'stance'. 
%                               'stim_on_phase' - if stim comes on
%                                   during step, what phase (hilbert) of
%                                   step does it come on during. A table with 
%                                   phase of every joint at stim onset.
% 
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

warning('off','MATLAB:table:RowsAddedExistingVars') %turn off warning for filling only sub columns at a time for each row. 

%legs and joints to add data of 
% joints = {'_BC', '_CF', '_FTi', '_TiTa', 'B_rot', 'E_x', 'E_y', 'E_z'};
joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex', 'A_abduct', 'A_rot', 'B_rot', 'C_rot', 'A_rot_unwrapped', 'B_rot_unwrapped', 'C_rot_unwrapped', 'E_x', 'E_y', 'E_z'}; %changed to ABCD joints (oct 2022)
joint_names = {'BC', 'CF', 'FTi', 'TiTa', 'A_abduct', 'A_rot', 'B_rot', 'C_rot', 'A_rot_unwrapped', 'B_rot_unwrapped', 'C_rot_unwrapped', 'E_x', 'E_y', 'E_z'}; %can keep the same names. 

% define butterworth filter for hilbert transform.
[A,B,C,D] = butter(1,[0.02 0.4],'bandpass');
sos = ss2sos(A,B,C,D);

steps = struct;
for leg = 1:param.numLegs
    steps.leg(leg).meta = table('Size', [0,35], ...
        'VariableTypes',{'string','cell', 'cell', 'cell', 'double', ...
                         'double','double', 'double','double', 'double', ...
                         'double', 'double', 'double', ...
                         'double','double', 'double','double', 'double', 'double', ...
                         'cell', 'double', 'double' ,'double', 'double', ...
                         'double', 'double', 'double', 'double','cell', ...
                         'double', 'double', 'string', 'cell', 'string', 'cell'}, ...
        'VariableNames',{'fly', 'walkingDataStepIdxs', 'walkingDataSwingIdxs', 'walkingDataStanceIdxs', 'boutNum', ...
                         'stepNum', 'rep', 'cond' 'step_duration', 'step_frequency', ...
                         'step_length', 'swing_duration', 'stance_duration', ...
                         'AEP_E_x', 'AEP_E_y', 'AEP_E_z', 'PEP_E_x' , 'PEP_E_y', 'PEP_E_z'...
                         'tarsus_y_phase', 'avg_speed_x', 'avg_speed_y', 'avg_speed_z', 'avg_acceleration_x', ...
                         'avg_acceleration_y', 'avg_acceleration_z', 'avg_heading', 'avg_temp', 'stim', ...
                         'avg_stim', 'stim_length', 'stim_on_region', 'stim_on_phase', 'stim_off_region', 'stim_off_phase'});
end

leg_step_idxs = [0, 0, 0, 0, 0, 0]; %row idxs for saving data in steps struct
for bout = 1:height(boutMap) %bout is boutNum
    try % try this bout, if there's an error, skip and move onto the next bout. 
        
        
        % calculate metrics that are the same across legs:

        % idxs in walkingData
        this_bout_idxs = boutMap.walkingDataIdxs{bout};

        % fly number  
        this_fly = walkingData.flyid{this_bout_idxs(1)}; 

        % opto stim region in bout
        this_laser_length = param.allLasers(walkingData.condnum(this_bout_idxs(1))); %in seconds
        this_stim = zeros(width(this_bout_idxs),1); % array of length bout where 0 = no stim and 1 = stim
        this_fnum = walkingData.fnum(this_bout_idxs);
        laser_off = param.laser_on+(this_laser_length*param.fps);
        if this_laser_length > 0 %TODO delete this if things work: & ~(this_fnum(1) > laser_off | this_fnum(end) < param.laser_on)
            % set any frames between laser onset and offset to 1
            this_stim(this_fnum >=param.laser_on & this_fnum < laser_off) = 1;
        end

        rep = walkingData.rep(this_bout_idxs(1)); 
        cond = walkingData.condnum(this_bout_idxs(1)); 

        for leg = 1:param.numLegs
            %indices within bout
            this_swing_stance = boutMap.([param.legs{leg} '_swing_stance']){bout}; %swing = 1; stance = 0

            if ~(sum(isnan(this_swing_stance)) == height(this_swing_stance)) %if no steps, only nans, skip this leg 
                this_stance_starts = [find(this_swing_stance == 0,1,'first'); find(diff(this_swing_stance) == -1)+1; find(this_swing_stance == 1,1,'last');]; %first idxs of stance
                this_stance_ends = find(diff(this_swing_stance) == 1); %last  idxs of stances
                %indices in walkingData - add start idx of bout in walkingData to convert from bout to walkingData idxs
                this_stance_starts_walkingData = this_stance_starts + this_bout_idxs(1); %TODO check this
                this_stance_ends_walkingData = this_stance_ends + this_bout_idxs(1); %TODO check this

                %Get all of the joint data
                jointTable = table;
                phaseTable = table;
                for joint = 1:width(joints)
                    %parse joint data
                    joint_str = [param.legs{leg} joints{joint}];
                    jointTable.(joint_str) = walkingData.(joint_str)(this_bout_idxs);
                    %calcualte phase (hilbert transform)
                    normed_data = (jointTable.(joint_str)-mean(jointTable.(joint_str), 'omitnan'))/std(jointTable.(joint_str), 'omitnan');
                    bfilt_data = sosfilt(sos, normed_data);  %bandpass frequency filter for hilbert transform            
                    phaseTable.(joint_str) = angle(hilbert(bfilt_data));
                end

                %calculate and save metrics and data for each step    
                for st = 1:height(this_stance_ends)-1 %this is stepNum
                    % step idxs in bout - for indexing into jointTable
                    this_step_idxs = this_stance_starts(st):this_stance_starts(st+1)-1;
                    this_stance = this_stance_starts(st):this_stance_ends(st);
                    this_swing = this_stance_ends(st)+1:this_stance_starts(st+1)-1;

                    % step idxs in walkingData
                    this_step_idxs_walkingData = this_stance_starts_walkingData(st):this_stance_starts_walkingData(st+1)-1;
                    this_stance_idxs_walkingData = this_stance_starts_walkingData(st):this_stance_ends_walkingData(st);
                    this_swing_idxs_walkingData = this_stance_ends_walkingData(st)+1:this_stance_starts_walkingData(st+1)-1;

                    %calculate step duration 
                    step_dur = width(this_step_idxs)/param.fps;

                    %calculate step frequency
                    step_freq = 1/step_dur;

                    %calculate step length
                    shift_val = 10; %add to each position value to make them all positive. 0 point from anipose is L1_BC position.
                    start_positions_raw = [jointTable.([param.legs{leg} 'E_x'])(this_stance(1)), jointTable.([param.legs{leg} 'E_y'])(this_stance(1)), jointTable.([param.legs{leg} 'E_z'])(this_stance(1))];
                    end_positions_raw = [jointTable.([param.legs{leg} 'E_x'])(this_stance(end)), jointTable.([param.legs{leg} 'E_y'])(this_stance(end)), jointTable.([param.legs{leg} 'E_z'])(this_stance(end))];
                    start_positions = start_positions_raw + shift_val;
                    end_positions = end_positions_raw + shift_val;
                    step_length = sqrt((end_positions(1)-start_positions(1))^2 + (end_positions(2)-start_positions(2))^2 + (end_positions(3)-start_positions(3))^2);            

                    %AEP PEP
                    AEP_E_x = start_positions_raw(1);
                    AEP_E_y = start_positions_raw(2);
                    AEP_E_z = start_positions_raw(3);
                    PEP_E_x = end_positions_raw(1);
                    PEP_E_y = end_positions_raw(2);
                    PEP_E_z = end_positions_raw(3);

                    %calculate swing and stance duration 
                    swing_duration = width(this_swing)/param.fps;
                    stance_duration = width(this_stance)/param.fps;

                    %calculate avgs: heading, speed, acceleration, temp
                    avg_heading = mean(walkingData.fictrac_heading_deg(this_step_idxs_walkingData), 'omitnan');
                    avg_speed_x = mean(walkingData.fictrac_delta_rot_lab_x_mms(this_step_idxs_walkingData), 'omitnan');
                    avg_speed_y = mean(walkingData.fictrac_delta_rot_lab_y_mms(this_step_idxs_walkingData), 'omitnan');
                    avg_speed_z = mean(walkingData.fictrac_delta_rot_lab_z_mms(this_step_idxs_walkingData), 'omitnan');
                    avg_acceleration_x = mean(diff(walkingData.fictrac_delta_rot_lab_x_mms(this_step_idxs_walkingData))/(width(this_step_idxs_walkingData)/param.fps), 'omitnan');
                    avg_acceleration_y = mean(diff(walkingData.fictrac_delta_rot_lab_y_mms(this_step_idxs_walkingData))/(width(this_step_idxs_walkingData)/param.fps), 'omitnan');
                    avg_acceleration_z = mean(diff(walkingData.fictrac_delta_rot_lab_z_mms(this_step_idxs_walkingData))/(width(this_step_idxs_walkingData)/param.fps), 'omitnan');
                    avg_temp = mean(walkingData.temp(this_step_idxs_walkingData), 'omitnan');

                    %phase of step (tarsi y position phase)
                    hilbert_phase = phaseTable.([param.legs{leg} 'E_y'])(this_step_idxs);

                    %calculate percent opto and onset (0 = fully no stim, 1 = fully stim)
                    avg_stim = mean(this_stim(this_step_idxs), 'omitnan'); %percent stim 
                    full_stim = this_stim(this_step_idxs); %stim during this step
                    stim_length = walkingData.stimlen(this_step_idxs_walkingData(1)); %stim length for the vid this step is in: 0, 0.033, 0.1, 0.33, 1 sec
                    %default stim on off vals
                    stim_on_region = NaN;
                    stim_on_phase = {};
                    stim_off_region = NaN;
                    stim_off_phase = {};
                    %set stim on and off vals
                    if any(diff(this_stim(this_step_idxs)) == 1) %stim comes on during step
                        stim_on_idx = this_step_idxs(1) + find(diff(this_stim(this_step_idxs)) == 1)+1;
                        regions = {'stance', 'swing'};
                        stim_on_region = regions{this_swing_stance(stim_on_idx)+1};
                        stim_on_phase = phaseTable(stim_on_idx,:);
                    end
                    if any(diff(this_stim(this_step_idxs)) == -1) %stim turns off during step
                        stim_off_idx = this_step_idxs(1) + find(diff(this_stim(this_step_idxs)) == -1);
                        regions = {'stance', 'swing'};
                        stim_off_region = regions{this_swing_stance(stim_off_idx)+1};
                        stim_off_phase = phaseTable(stim_off_idx,:);
                    end

                    %save everything! - all metrics + joint and phase variables. 
                    leg_step_idxs(leg) = leg_step_idxs(leg)+1; %update leg step idx.
                    for joint = 1:width(joints)
                        joint_str = [param.legs{leg} joints{joint}];
                        steps.leg(leg).(joint_names{joint})(leg_step_idxs(leg),1:width(this_step_idxs)) = jointTable.(joint_str)(this_step_idxs);
                        steps.leg(leg).([joint_names{joint} '_phase'])(leg_step_idxs(leg),1:width(this_step_idxs)) = phaseTable.(joint_str)(this_step_idxs);
                    end
                    steps.leg(leg).meta.fly(leg_step_idxs(leg)) = this_fly;
                    steps.leg(leg).meta.walkingDataStepIdxs{leg_step_idxs(leg)} = this_step_idxs_walkingData;
                    steps.leg(leg).meta.walkingDataStanceIdxs{leg_step_idxs(leg)} = this_stance_idxs_walkingData;
                    steps.leg(leg).meta.walkingDataSwingIdxs{leg_step_idxs(leg)} = this_swing_idxs_walkingData;
                    steps.leg(leg).meta.boutNum(leg_step_idxs(leg)) = bout;
                    steps.leg(leg).meta.stepNum(leg_step_idxs(leg)) = st;
                    steps.leg(leg).meta.rep(leg_step_idxs(leg)) = rep;
                    steps.leg(leg).meta.cond(leg_step_idxs(leg)) = cond;            
                    steps.leg(leg).meta.step_frequency(leg_step_idxs(leg)) = step_freq;
                    steps.leg(leg).meta.step_duration(leg_step_idxs(leg)) = step_dur;
                    steps.leg(leg).meta.step_length(leg_step_idxs(leg)) = step_length;
                    steps.leg(leg).meta.swing_duration(leg_step_idxs(leg)) = swing_duration;
                    steps.leg(leg).meta.stance_duration(leg_step_idxs(leg)) = stance_duration;
                    steps.leg(leg).meta.AEP_E_x(leg_step_idxs(leg)) = AEP_E_x;
                    steps.leg(leg).meta.AEP_E_y(leg_step_idxs(leg)) = AEP_E_y;
                    steps.leg(leg).meta.AEP_E_z(leg_step_idxs(leg)) = AEP_E_z;
                    steps.leg(leg).meta.PEP_E_x(leg_step_idxs(leg)) = PEP_E_x;
                    steps.leg(leg).meta.PEP_E_y(leg_step_idxs(leg)) = PEP_E_y;
                    steps.leg(leg).meta.PEP_E_z(leg_step_idxs(leg)) = PEP_E_z;
                    steps.leg(leg).meta.tarsus_y_phase{leg_step_idxs(leg)} = hilbert_phase;
                    steps.leg(leg).meta.avg_heading(leg_step_idxs(leg)) = avg_heading;
                    steps.leg(leg).meta.avg_speed_x(leg_step_idxs(leg)) = avg_speed_x;
                    steps.leg(leg).meta.avg_speed_y(leg_step_idxs(leg)) = avg_speed_y;
                    steps.leg(leg).meta.avg_speed_z(leg_step_idxs(leg)) = avg_speed_z;
                    steps.leg(leg).meta.avg_acceleration_x(leg_step_idxs(leg)) = avg_acceleration_x;
                    steps.leg(leg).meta.avg_acceleration_y(leg_step_idxs(leg)) = avg_acceleration_y;
                    steps.leg(leg).meta.avg_acceleration_z(leg_step_idxs(leg)) = avg_acceleration_z;
                    steps.leg(leg).meta.avg_temp(leg_step_idxs(leg)) = avg_temp;
                    steps.leg(leg).meta.stim{leg_step_idxs(leg)} = full_stim; 
                    steps.leg(leg).meta.avg_stim(leg_step_idxs(leg)) = avg_stim; 
                    steps.leg(leg).meta.stim_length(leg_step_idxs(leg)) = stim_length;
                    steps.leg(leg).meta.stim_on_region(leg_step_idxs(leg)) = stim_on_region; 
                    steps.leg(leg).meta.stim_on_phase{leg_step_idxs(leg)} = stim_on_phase; 
                    steps.leg(leg).meta.stim_off_region(leg_step_idxs(leg)) = stim_off_region; 
                    steps.leg(leg).meta.stim_off_phase{leg_step_idxs(leg)} = stim_off_phase;             
                end        
            end
        end
    catch
        %do nothing, go to next bout. 
    end
end

%find where this_joint_data is zero and replace with NaN
%(need to do this because steps are diff lengths, so Matlab appends zeros
%on the end. Turn to NaNs so they aren't confused as part of joint data.)
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
