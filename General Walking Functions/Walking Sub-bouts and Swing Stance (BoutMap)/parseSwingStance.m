function data = parseSwingStance(data, param)

% For each walking bout identified by the behavior classifier, 
% parse steps, identify swing and stance, take phase of tarsus tip y position.
% Add all this info to the data parquet file. 
% 
% Info added to data for each leg:
% - (leg)_swing_stance: 0 for stance, 1 for swing. 
% - (leg)_step_num: which step num this is in the bout. (these are unique for each bout but not for the whole dataset) 
% - (leg)_num_steps: how many total steps there are in this bout. 
% - (leg)_phase: (leg)_E_y phase (hilbert transform) for this walking bout 
% 
% Sarah Walling-Bell
% November, 2022


%min number of frames for a walking bout
minBoutLength = 100;

%get walking bouts
boutNums = unique(data.walking_bout_number);

% define butterworth filter for hilbert transform.
[A,B,C,D] = butter(1,[0.02 0.4],'bandpass');
sos = ss2sos(A,B,C,D);

%there are multiple of the same walking_bout_numbers in the same file, so 
%detect when there's a break in frame number and map old to new bout id
trueBoutNum = 0;

%add columns to fill in data
data.true_walking_bout_number = NaN(height(data),1);
for leg = 1:param.numLegs
    data.([param.legs{leg} '_swing_stance']) = NaN(height(data),1);
    data.([param.legs{leg} '_step_num']) = NaN(height(data),1); %unique step num
    data.([param.legs{leg} '_num_steps']) = NaN(height(data),1); %num steps this leg takes in this bout
    data.([param.legs{leg} '_phase']) = NaN(height(data),1); %E_y phase
end

for bout = 1:height(boutNums)
    %get idxs of all data with this 'walking_bout_number'
    boutIdxs = find(data.walking_bout_number == boutNums(bout)); 
    if height(boutIdxs) > minBoutLength % a walking bout must be at least n=minBoutLength frames. 
        %find where the frame number jumps, indicating multiple walking bouts with same 'walking_bout_number'
        [~, locs] = findpeaks(diff(boutIdxs), 'MinPeakProminence', 2);
        %find how many walking bout have same bout number 
        if isempty(locs); numSubBouts = 1; else; numSubBouts = height(locs)+1; end
        locs = [0; locs; height(boutIdxs)];

        for subBout = 1:numSubBouts
            
           % make sure there's more than n=minBoutLength frames in the subbout
           if width(boutIdxs(locs(subBout)+1):boutIdxs(locs(subBout+1))) > minBoutLength

               %get bout idxs in data
               subBoutIdxs = boutIdxs(locs(subBout)+1):boutIdxs(locs(subBout+1));
               
               %map old bout num to new bout num
               trueBoutNum = trueBoutNum + 1; 
               data.true_walking_bout_number(subBoutIdxs) = trueBoutNum; %save unique bout num 
               
               for leg = 1:param.numLegs
                   %calcualte swing and stance: 
                   %set full bout to NaN
                   swing_stance = NaN(width(subBoutIdxs), 1);
                   step_num = NaN(width(subBoutIdxs), 1);
                   num_steps = 0;
                   
                   %get joint data, determine swing and stance regions and fill in
                   %with ones and zeros respectively 
                   tarsus_y_position = [param.legs{leg} 'E_y'];
                   tarsus_z_position = [param.legs{leg} 'E_z'];
                   this_data_tar_y_pos = data.(tarsus_y_position)(subBoutIdxs);
                   this_data_tar_z_pos = data.(tarsus_z_position)(subBoutIdxs);
                       
                   prom_y = 0.2;
                   [ssPks_y, ssPkLocs_y] = findpeaks(this_data_tar_y_pos, 'MinPeakProminence', prom_y);
                   [ssTrs_y, ssTrLocs_y] = findpeaks(this_data_tar_y_pos*-1, 'MinPeakProminence', prom_y); %for T1: min E_y position = stance end
                   
                   prom_z = 0.1; 
                   [ssPks_z, ssPkLocs_z] = findpeaks(smooth(this_data_tar_z_pos), 'MinPeakProminence', prom_z);
                   [ssTrs_z, ssTrLocs_z] = findpeaks(smooth(this_data_tar_z_pos)*-1, 'MinPeakProminence', prom_z); %for T1: min E_z position = stance start
                   
                   prom_diff_z = 0.1; %0.03; 
                   [ssPks_diff_z, ssPkLocs_diff_z] = findpeaks(diff(smooth(this_data_tar_z_pos)), 'MinPeakProminence', prom_diff_z);
                   [ssTrs_diff_z, ssTrLocs_diff_z] = findpeaks(diff(smooth(this_data_tar_z_pos))*-1, 'MinPeakProminence', prom_diff_z); %for T1: min E_z position = stance start
                                      
                   %classify swing stance
                   nan_leg = false; %for detecting if step parsing went wrong
                   if contains(param.legs{leg}, '1') %T1 legs
                      % min E_z position = stance start (ssTrLocs_z)
                      % min E_y position = stance end (ssTrLocs_y)
                      
                      for pk = 1:height(ssTrLocs_z)-1
                         stance_start = ssTrLocs_z(pk);
                         stance_end = ssTrLocs_y(find(ssTrLocs_y > stance_start, 1, 'first'));
                         swing_start = stance_end+1;
                         swing_end = ssTrLocs_z(pk+1)-1;
                         
                         if isempty(stance_start) | isempty(stance_end) | isempty(swing_start)| isempty(swing_end)
                             %something went wrong with finding steps, nan
                             %this whole legs to ease future analyses
                             nan_leg = true;
                         else
                              num_steps = num_steps+1;
                              swing_stance(stance_start:stance_end) = 0; %stance 
                              swing_stance(swing_start:swing_end) = 1; %swing
                              step_num(stance_start:swing_end) = num_steps; %this step number 
                          end
                      end
                      
%                       plot(this_data_tar_y_pos); hold on; ... 
%                       plot(this_data_tar_z_pos); ...
%                       scatter(ssTrLocs_y, ssTrs_y); ... 
%                       scatter(ssTrLocs_z, ssTrs_z); ... 
%                       plot(swing_stance); ...
%                       hold off;

                   elseif  contains(param.legs{leg}, '2') %T2 legs


                      % max E_y position or min E_z position close by = stance start (ssPkLocs_y or ssTrLocs_z)
                      % min E_y position = stance end (ssTrLocs_y)

                      for pk = 1:height(ssPkLocs_y)-1
                         fixLastStanceEnd = false; 
                         stance_start = ssPkLocs_y(pk);
                         %check if there's an ssTrLocs_z min within a few frames after the current stance_start. 
                         %ssPkLocs_y often predicts stance start a few frames too early, so using the ssTrLocs_z if possible is more accurate. 
                         numFramesToLook = 5; %TODO assess this for other bouts
                         idxsToSearch = stance_start+1:stance_start+numFramesToLook; 
                         [localPks, localLocs] = findpeaks(this_data_tar_z_pos(idxsToSearch)*-1); %check if there are any z position mins a few frames after the current stance start (max y)
                         if ~isempty(localPks) 
                             stance_start = stance_start + localLocs(1); %shift stance start to the first z min
                             %need to update the previous swing end if there is one
                             if pk > 1
                                 fixLastStanceEnd = true;
                             end
                         end
                         stance_end = ssTrLocs_y(find(ssTrLocs_y > stance_start, 1, 'first'));
                         swing_start = stance_end+1;
                         swing_end = ssPkLocs_y(pk+1)-1;
                         
                         if isempty(stance_start) | isempty(stance_end) | isempty(swing_start)| isempty(swing_end)
                             %something went wrong with finding steps, nan
                             %this whole legs to ease future analyses
                             nan_leg = true;
                         else
                              num_steps = num_steps+1;
                              swing_stance(stance_start:stance_end) = 0; %stance 
                              swing_stance(swing_start:swing_end) = 1; %swing
                              step_num(stance_start:swing_end) = num_steps; %this step number 
                              if fixLastStanceEnd
                                swing_stance(stance_start-localLocs(1):stance_start) = 1; %swing (fill in end of last swing since true stance start for this step is after y max, where last swing ended). 
                                step_num(stance_start-localLocs(1):stance_start) = num_steps; %this step number 
                              end
                          end
                      end

%                       plot(this_data_tar_z_pos); hold on; ...
%                       plot(this_data_tar_z_pos_abs_diff_smooth); ...
%                       scatter(ssPkLocs_diff_z, ssPks_diff_z); ...
%                       scatter(ssTrLocs_diff_z, ssTrs_diff_z); ...
%                       plot(swing_stance);
%                       hold off;
%                        
%                           
%           plot(this_data_tar_z_pos); hold on; plot(diff(smooth(this_data_tar_z_pos))); ...
%           plot(abs(diff(smooth(this_data_tar_z_pos)))); plot(swing_stance); ... 
%           plot(this_data_tar_y_pos); plot(data.([param.legs{leg} 'E_x'])(subBoutIdxs)); scatter(ssTrLocs_diff_z, ssTrs_diff_z);hold off
%                     

                      
                   elseif  contains(param.legs{leg}, '3') %T3 legs
                      %  max E_y position = stance start (ssPkLocs_y)
                      %  min E_z position = stance end (ssTrLocs_z) 
                      
                      for pk = 1:height(ssPkLocs_y)-1
                         stance_start = ssPkLocs_y(pk);
                         stance_end = ssTrLocs_z(find(ssTrLocs_z > stance_start, 1, 'first'));
                         swing_start = stance_end+1;
                         swing_end = ssPkLocs_y(pk+1)-1;
                         
                         if isempty(stance_start) | isempty(stance_end) | isempty(swing_start)| isempty(swing_end)
                             %something went wrong with finding steps, nan
                             %this whole legs to ease future analyses
                             nan_leg = true;
                         else
                              num_steps = num_steps+1;
                              swing_stance(stance_start:stance_end) = 0; %stance 
                              swing_stance(swing_start:swing_end) = 1; %swing
                              step_num(stance_start:swing_end) = num_steps; %this step number 
                          end
                      end
                      
%                       plot(this_data_tar_y_pos); hold on; ... 
%                       plot(this_data_tar_z_pos*-1); ...
%                       scatter(ssPkLocs_y, ssPks_y); ... 
%                       scatter(ssTrLocs_z, ssTrs_z); ... 
%                       plot(swing_stance); ...
%                       hold off;
                      
                      
                   else
                       error('not a leg');
                   end
                   
                   %clear leg if step parsing went wrong
                   if nan_leg
                       swing_stance = NaN(width(subBoutIdxs), 1);
                   end
                   
                   data.([param.legs{leg} '_swing_stance'])(subBoutIdxs) = swing_stance; %save swing/stance
                   data.([param.legs{leg} '_step_num'])(subBoutIdxs) = step_num; %save unique step numbers within a bout
                   data.([param.legs{leg} '_num_steps'])(subBoutIdxs) = max(step_num); %save total number of steps this leg takes in this bout
                                                         
                   %calcualte phase (hilbert transform):
                   joint_data = data.([param.legs{leg} 'E_y'])(subBoutIdxs); %calculate phase from tarsi y position data
                   normed_data = (joint_data-mean(joint_data, 'omitnan'))/std(joint_data, 'omitnan');
                   bfilt_data = sosfilt(sos, normed_data);  %bandpass frequency filter for hilbert transform     

                   data.([param.legs{leg} '_phase'])(subBoutIdxs) = angle(hilbert(bfilt_data)); %save E_y phase
            
               end
           end
        end
    end
end

% Make sure each leg took at least m=minStepsPerLeg steps. (otherwise it probably wasn't very good walking)
minStepsPerLeg = 3;
boutTooShortIdxs = find(data.L1_num_steps < minStepsPerLeg | data.L2_num_steps < minStepsPerLeg | data.L3_num_steps < minStepsPerLeg | ...
                data.R1_num_steps < minStepsPerLeg | data.R2_num_steps < minStepsPerLeg | data.R3_num_steps < minStepsPerLeg);
%NaN bouts with too few steps per leg
data.true_walking_bout_number(boutTooShortIdxs) = NaN;
for leg = 1:param.numLegs
    data.([param.legs{leg} '_swing_stance'])(boutTooShortIdxs) = NaN;
    data.([param.legs{leg} '_step_num'])(boutTooShortIdxs) = NaN; %unique step num
    data.([param.legs{leg} '_num_steps'])(boutTooShortIdxs) = NaN; %num steps this leg takes in this bout
    data.([param.legs{leg} '_phase'])(boutTooShortIdxs) = NaN; %E_y phase
end


end