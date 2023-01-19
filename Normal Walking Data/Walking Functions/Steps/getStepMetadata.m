function [data, steps] = getStepMetadata(data, param)

% Collect metadata for each step, saved in steps struct. 
% Calculate phase for many joints, save as new columns in data. 
% 
% Sarah Walling-Bell
% November, 2022


warning('off','MATLAB:table:RowsAddedExistingVars') %turn off warning for filling only sub columns at a time for each row. 

%legs and joints to take phase of 
joints = {'A_abduct', 'A_flex', 'A_rot', 'A_rot_unwrapped', 'B_flex', 'B_rot', 'B_rot_unwrapped', 'C_flex', 'C_rot', 'C_rot_unwrapped', 'D_flex', 'E_x', 'E_y', 'E_z'};
for leg = 1:param.numLegs
    for joint = 1:width(joints)
        data.([param.legs{leg} joints{joint} '_phase']) = NaN(height(data),1);
    end
end

% define butterworth filter for hilbert transform.
[A,B,C,D] = butter(1,[0.02 0.4],'bandpass');
sos = ss2sos(A,B,C,D);

steps = struct;
for leg = 1:param.numLegs
    steps.leg(leg).meta = table('Size', [0,31], ...
        'VariableTypes',{'string', 'cell', 'double', 'double', ...
                         'double', 'double', 'double','double', 'double', ...
                         'double', 'double', 'double', ...
                         'double', 'double', 'double','double', 'double', 'double', ...
                         'double', 'double' ,'double', 'double', ...
                         'double', 'double', 'double', 'double', ...
                         'double', 'string', 'double', 'string', 'double'}, ...
        'VariableNames',{'fly', 'dataStepIdxs', 'dataStanceEndIdx', 'boutNum', ...
                         'stepNum', 'rep', 'cond' 'step_duration', 'step_frequency', ...
                         'step_length', 'swing_duration', 'stance_duration', ...
                         'AEP_E_x', 'AEP_E_y', 'AEP_E_z', 'PEP_E_x' , 'PEP_E_y', 'PEP_E_z'...
                         'avg_speed_x', 'avg_speed_y', 'avg_speed_z', 'avg_acceleration_x', ...
                         'avg_acceleration_y', 'avg_acceleration_z', 'avg_heading', 'avg_temp', ...
                         'percent_stim', 'stim_on_region', 'stim_on_phase_E_y', 'stim_off_region', 'stim_off_phase_E_y'});
end

leg_step_idxs = [0, 0, 0, 0, 0, 0]; %row idxs for saving data in steps struct

bouts = unique(data.true_walking_bout_number(~isnan(data.true_walking_bout_number))); 
for bout = 1:height(bouts) %bout is boutNum
    try % try this bout, if there's an error, skip and move onto the next bout. 
        thisBoutNum = bouts(bout); 
       
        % idxs in data
        this_bout_idxs = find(data.true_walking_bout_number == thisBoutNum); %idx into data

        % calculate metrics that are the same across legs:

        % fly number  
        this_fly = data.flyid{this_bout_idxs(1)}; 

        rep = data.rep(this_bout_idxs(1)); 
        cond = data.condnum(this_bout_idxs(1)); 

        for leg = 1:param.numLegs
            %indices within bout
            this_swing_stance = data.([param.legs{leg} '_swing_stance'])(this_bout_idxs);
            this_step_nums = data.([param.legs{leg} '_step_num'])(this_bout_idxs);
            this_unique_steps = unique(this_step_nums(~isnan(this_step_nums))); %to ensure this all still works if a step num is skipped. 

            if ~(sum(isnan(this_swing_stance)) == height(this_swing_stance)) %if no steps, only nans, skip this leg 
                %add joint phases to data
                for joint = 1:width(joints)
                    joint_data = data.([param.legs{leg} joints{joint}])(this_bout_idxs);
                    %calculate phase (hilbert transform)
                    normed_data = (joint_data-mean(joint_data, 'omitnan'))/std(joint_data, 'omitnan');
                    bfilt_data = sosfilt(sos, normed_data);  %bandpass frequency filter for hilbert transform            
                    phase_data = angle(hilbert(bfilt_data));
                    data.([param.legs{leg} joints{joint} '_phase'])(this_bout_idxs) = phase_data; %save phase data
                end
                    
                %calculate and save metrics and data for each step    
                for st = 1:height(this_unique_steps)
                    this_step_num = this_unique_steps(st); 
                    %step idxs in data
                    this_step_idxs = this_bout_idxs(this_step_nums == this_step_num); %idx into data
                    this_stance_idxs = this_step_idxs(data.([param.legs{leg} '_swing_stance'])(this_step_idxs) == 0); %idx into data
                    this_swing_idxs = this_step_idxs(data.([param.legs{leg} '_swing_stance'])(this_step_idxs) == 1); %idx into data

                    %calculate step duration 
                    step_duration = height(this_step_idxs)/param.fps;

                    %calculate step frequency
                    step_frequency = 1/step_duration;

                    %calculate step length 
                    shift_val = 10; %add to each position value to make them all positive. 0 point from anipose is L1_BC position.
                    start_positions_raw = [data.([param.legs{leg} 'E_x'])(this_stance_idxs(1)), data.([param.legs{leg} 'E_y'])(this_stance_idxs(1)), data.([param.legs{leg} 'E_z'])(this_stance_idxs(1))];
                    end_positions_raw = [data.([param.legs{leg} 'E_x'])(this_stance_idxs(end)), data.([param.legs{leg} 'E_y'])(this_stance_idxs(end)), data.([param.legs{leg} 'E_z'])(this_stance_idxs(end))];
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
                    swing_duration = height(this_swing_idxs)/param.fps;
                    stance_duration = height(this_stance_idxs)/param.fps;

                    %calculate avgs: heading, speed, acceleration, temp
                    avg_heading = mean(data.fictrac_heading_deg(this_step_idxs), 'omitnan');
                    avg_speed_x = mean(data.fictrac_delta_rot_lab_x_mms(this_step_idxs), 'omitnan');
                    avg_speed_y = mean(data.fictrac_delta_rot_lab_y_mms(this_step_idxs), 'omitnan');
                    avg_speed_z = mean(data.fictrac_delta_rot_lab_z_mms(this_step_idxs), 'omitnan');
                    avg_acceleration_x = mean(diff(data.fictrac_delta_rot_lab_x_mms(this_step_idxs))/step_duration, 'omitnan');
                    avg_acceleration_y = mean(diff(data.fictrac_delta_rot_lab_y_mms(this_step_idxs))/step_duration, 'omitnan');
                    avg_acceleration_z = mean(diff(data.fictrac_delta_rot_lab_z_mms(this_step_idxs))/step_duration, 'omitnan');
                    avg_temp = mean(data.temp(this_step_idxs), 'omitnan');

                    %calculate percent opto and onset (0 = fully no stim, 1 = fully stim)
                    this_stim = data.stim(this_step_idxs);
                    percent_stim = mean(this_stim, 'omitnan');  
                    %default stim on off vals
                    stim_on_region = NaN;
                    stim_on_phase_E_y = NaN;
                    stim_off_region = NaN;
                    stim_off_phase_E_y = NaN;
                    %set stim on and off vals
                    if any(diff(this_stim) == 1) %stim comes on during step
                        stim_on_idx = this_step_idxs(diff(this_stim) == 1)+1; %idx in data
                        regions = {'stance', 'swing'};
                        stim_on_region = regions{data.([param.legs{leg} '_swing_stance'])(stim_on_idx)+1};
                        stim_on_phase_E_y = data.([param.legs{leg} 'E_y_phase'])(stim_on_idx)+1;
                    end
                    if any(diff(this_stim) == -1) %stim turns off during step
                        stim_off_idx = this_step_idxs(diff(this_stim) == -1)+1; %idx in data
                        regions = {'stance', 'swing'};
                        stim_off_region = regions{data.([param.legs{leg} '_swing_stance'])(stim_off_idx)+1};
                        stim_off_phase =  data.([param.legs{leg} 'E_y_phase'])(stim_off_idx)+1;
                    end

                    %save everything! - all metrics + joint and phase variables. 
                    leg_step_idxs(leg) = leg_step_idxs(leg)+1; %update leg step idx.

                    steps.leg(leg).meta.fly(leg_step_idxs(leg)) = this_fly;
                    steps.leg(leg).meta.dataStepIdxs{leg_step_idxs(leg)} = this_step_idxs;
                    steps.leg(leg).meta.dataStanceEndIdx(leg_step_idxs(leg)) = this_stance_idxs(end); %last frame of stance
                    steps.leg(leg).meta.boutNum(leg_step_idxs(leg)) = thisBoutNum;
                    steps.leg(leg).meta.stepNum(leg_step_idxs(leg)) = this_step_num;
                    steps.leg(leg).meta.rep(leg_step_idxs(leg)) = rep;
                    steps.leg(leg).meta.cond(leg_step_idxs(leg)) = cond;            
                    steps.leg(leg).meta.step_frequency(leg_step_idxs(leg)) = step_frequency;
                    steps.leg(leg).meta.step_duration(leg_step_idxs(leg)) = step_duration;
                    steps.leg(leg).meta.step_length(leg_step_idxs(leg)) = step_length;
                    steps.leg(leg).meta.swing_duration(leg_step_idxs(leg)) = swing_duration;
                    steps.leg(leg).meta.stance_duration(leg_step_idxs(leg)) = stance_duration;
                    steps.leg(leg).meta.AEP_E_x(leg_step_idxs(leg)) = AEP_E_x;
                    steps.leg(leg).meta.AEP_E_y(leg_step_idxs(leg)) = AEP_E_y;
                    steps.leg(leg).meta.AEP_E_z(leg_step_idxs(leg)) = AEP_E_z;
                    steps.leg(leg).meta.PEP_E_x(leg_step_idxs(leg)) = PEP_E_x;
                    steps.leg(leg).meta.PEP_E_y(leg_step_idxs(leg)) = PEP_E_y;
                    steps.leg(leg).meta.PEP_E_z(leg_step_idxs(leg)) = PEP_E_z;
                    steps.leg(leg).meta.avg_heading(leg_step_idxs(leg)) = avg_heading;
                    steps.leg(leg).meta.avg_speed_x(leg_step_idxs(leg)) = avg_speed_x;
                    steps.leg(leg).meta.avg_speed_y(leg_step_idxs(leg)) = avg_speed_y;
                    steps.leg(leg).meta.avg_speed_z(leg_step_idxs(leg)) = avg_speed_z;
                    steps.leg(leg).meta.avg_acceleration_x(leg_step_idxs(leg)) = avg_acceleration_x;
                    steps.leg(leg).meta.avg_acceleration_y(leg_step_idxs(leg)) = avg_acceleration_y;
                    steps.leg(leg).meta.avg_acceleration_z(leg_step_idxs(leg)) = avg_acceleration_z;
                    steps.leg(leg).meta.avg_temp(leg_step_idxs(leg)) = avg_temp;
                    steps.leg(leg).meta.percent_stim(leg_step_idxs(leg)) = percent_stim; 
                    steps.leg(leg).meta.stim_on_region(leg_step_idxs(leg)) = stim_on_region; 
                    steps.leg(leg).meta.stim_on_phase_E_y(leg_step_idxs(leg)) = stim_on_phase_E_y; 
                    steps.leg(leg).meta.stim_off_region(leg_step_idxs(leg)) = stim_off_region; 
                    steps.leg(leg).meta.stim_off_phase_E_y(leg_step_idxs(leg)) = stim_off_phase_E_y;             
                end        
            end
        end
    catch
        %do nothing, go to next bout. 
        fprintf(['\nerror: bout ' num2str(bout) ' leg ' num2str(leg) ' st ' num2str(st)]);
    end
end


end