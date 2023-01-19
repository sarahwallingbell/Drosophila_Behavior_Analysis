function boutMap = boutMap(walkingData,param)

% Create a table with all walking bouts. Give them each a unique bout number, 
% since their bout number in summary parquet files are not necesarily unique.
% Save the old bout number 'Walking_Bout_Num', the new unique bout num, the 
% indices of the bout in the parquet file, and the swing and stance portions
% of the bout for each leg (zeros are stance, ones are swing).
% 
% Required Params:
%     'walkingData' = rows of 'data' parquet summary file where walking_bout_number is not nan.
%         data(~isnan(data.walking_bout_number),:); 
%     'param' - param struct from DLC_load_params.m
% 
% Output:
%     'boutMap' - a table of every walking bout with a bout id, walkingData indices, 
%                 and swing stance regions for each leg. 
%         - boutMap.oldBout = bout num as labelled in 'data'.
%         - boutMap.newBout = new bout number where each bout num is unique.
%         - boutMap.walkingDataIdxs = row nums in 'walkingData'.
%         - boutMap.L1_swing_stance = swing stance regions for this leg in walking bout. 
%                 NaN = not a step (i.e. at the beginning or end of a walking bout, 
%                       before the first stance start or after the last swing end. 
%                 0 = stance. 
%                 1 = swing.
%         - boutMap.num_steps = list of num steps for each leg. Order is: [L1, L2, L3, R1, R2, R3]
%     
% % Filtering conditions & info:
%     - A set of frames with the same walking_bout_number (may contain multiple 
%       walking bouts) must be at least 10 frames long.
%     - A subBout (one of the bouts with given walking_bout_number) must
%       have more than 10 frames. 
%     - Swing and stance are parsed from 'E_y' (tarsi tip y position - along
%       the head-thorax axis). Peak to tough is stance. Trough to peak is swing.
%
% Example uses:
%     - Plot the number of legs in stance at a time across speeds. 
%     - Make swing stance raster plots of a given bout. 
%     - Feed into Steps.m to parse steps. 
% 
%
% Sarah Walling-Bell
% November 2021, updated fall 2022

warning('off','MATLAB:table:RowsAddedExistingVars') %turn off warning for filling only sub columns at a time for each row. 

%min number of frames for a walking bout
minBoutLength = 100;

%get walking bouts
boutNums = unique(walkingData.walking_bout_number);

% define butterworth filter for hilbert transform.
[A,B,C,D] = butter(1,[0.02 0.4],'bandpass');
sos = ss2sos(A,B,C,D);

%there are multiple of the same walking_bout_numbers in the same file, so 
%detect when there's a break in frame number and map old to new bout id
trueBoutNum = 0;
% boutMap = table('Size', [0,10], 'VariableTypes',{'double', 'double', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell'},'VariableNames',{'oldBout','newBout','walkingDataIdxs','L1_swing_stance','L2_swing_stance','L3_swing_stance','R1_swing_stance','R2_swing_stance','R3_swing_stance', 'num_steps'});
boutMap = table('Size', [0,16], 'VariableTypes',{'double', 'double', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell'},'VariableNames',{'oldBout','newBout','walkingDataIdxs','L1_swing_stance','L2_swing_stance','L3_swing_stance','R1_swing_stance','R2_swing_stance','R3_swing_stance', 'num_steps', 'L1_phase','L2_phase','L3_phase','R1_phase','R2_phase','R3_phase'});

for bout = 1:height(boutNums)
    %get idxs of all data with this 'walking_bout_number'
    boutIdxs = find(walkingData.walking_bout_number == boutNums(bout)); 
    if height(boutIdxs) > minBoutLength % a walking bout must be at least n=minBoutLength frames. 
        %find where the frame number jumps, indicating multiple walking bouts with same 'walking_bout_number'
        [~, locs] = findpeaks(diff(boutIdxs), 'MinPeakProminence', 2);
        %find how many walking bout have same bout number 
        if isempty(locs); numSubBouts = 1; else; numSubBouts = height(locs)+1; end
        locs = [0; locs; height(boutIdxs)];

        for subBout = 1:numSubBouts
            
           % make sure there's more than n=minBoutLength frames in the subbout
           if width(boutIdxs(locs(subBout)+1):boutIdxs(locs(subBout+1))) > minBoutLength
               
               %map old bout num to new bout num
               trueBoutNum = trueBoutNum + 1; 
               boutMap.oldBout(trueBoutNum) = boutNums(bout); %bout num as labelled in 'data'
               boutMap.newBout(trueBoutNum) = trueBoutNum; %new bout number where each bout num is unique
               boutMap.walkingDataIdxs(trueBoutNum) = {boutIdxs(locs(subBout)+1):boutIdxs(locs(subBout+1))}; %row nums in 'WalkingData'
               
               
               for leg = 1:param.numLegs
                   %calcualte swing and stance: 
                   %set full bout to NaN
                   swing_stance = NaN(width(boutMap.walkingDataIdxs{trueBoutNum}), 1);
                   
                   %get joint data, determine swing and stance regions and fill in
                   %with ones and zeros respectively 
                   tarsus_y_position = [param.legs{leg} 'E_y'];
                   tarsus_z_position = [param.legs{leg} 'E_z'];
                   this_data_tar_y_pos = walkingData.(tarsus_y_position)(boutMap.walkingDataIdxs{trueBoutNum});
                   this_data_tar_z_pos = walkingData.(tarsus_z_position)(boutMap.walkingDataIdxs{trueBoutNum});
%                    
%                    femur_rot = [param.legs{leg} 'B_rot'];
%                    this_data_femur_rot = walkingData.(femur_rot)(boutMap.walkingDataIdxs{trueBoutNum});
%                       
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
                              swing_stance(stance_start:stance_end) = 0; %stance 
                              swing_stance(swing_start:swing_end) = 1; %swing
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
                              swing_stance(stance_start:stance_end) = 0; %stance 
                              swing_stance(swing_start:swing_end) = 1; %swing
                              if fixLastStanceEnd
                                swing_stance(stance_start-localLocs(1):stance_start) = 1; %swing (fill in end of last swing since true stance start for this step is after y max, where last swing ended). 
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
%           plot(this_data_tar_y_pos); plot(walkingData.([param.legs{leg} 'E_x'])(boutMap.walkingDataIdxs{trueBoutNum})); scatter(ssTrLocs_diff_z, ssTrs_diff_z);hold off
%                     

%%%%%%%%%%%%%%%%%%%%%%%%%%%% OLD METHOD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       % first point of abs(diff(smooth(this_data_tar_z_pos))) between a min diff(E_z) and max diff(E_z)
%                       % that is below stance_threshold is stance start, and the last point with the same criteria is stance end. 
%                       stance_threshold = 0.04;
% 
%                       this_data_tar_z_pos_abs_diff_smooth = abs(diff(smooth(this_data_tar_z_pos)));
%                       for pk = 1:height(ssTrLocs_diff_z)-1
%                           stance_ballpark = ssTrLocs_diff_z(pk): ssPkLocs_diff_z(find(ssPkLocs_diff_z > ssTrLocs_diff_z(pk), 1, 'first'));
%                           stance_start = find(this_data_tar_z_pos_abs_diff_smooth(stance_ballpark) < stance_threshold, 1, 'first') + stance_ballpark(1);
%                           stance_end = find(this_data_tar_z_pos_abs_diff_smooth(stance_ballpark) < stance_threshold, 1, 'last') + stance_ballpark(1);
%                           swing_start = stance_end+1;
%                           
%                           next_stance_ballpark = ssTrLocs_diff_z(pk+1): height(this_data_tar_z_pos_abs_diff_smooth);
%                           swing_end = find(this_data_tar_z_pos_abs_diff_smooth(next_stance_ballpark) < stance_threshold, 1, 'first') + next_stance_ballpark(1)-1;
%                           
%                           if isempty(stance_start) | isempty(stance_end) | isempty(swing_start)| isempty(swing_end)
%                              %something went wrong with finding steps, nan
%                              %this whole legs to ease future analyses
%                              nan_leg = true;
% %                              fprintf(['\npk ' num2str(pk)])
%                           else
%                               swing_stance(stance_start:stance_end) = 0; %stance 
%                               swing_stance(swing_start:swing_end) = 1; %swing
%                           end
%                       end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                      
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
                              swing_stance(stance_start:stance_end) = 0; %stance 
                              swing_stance(swing_start:swing_end) = 1; %swing
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
                       swing_stance = NaN(width(boutMap.walkingDataIdxs{trueBoutNum}), 1);
                   end
                   
                   this_leg_ss_string = [param.legs{leg} '_swing_stance'];
                   boutMap.(this_leg_ss_string)(trueBoutNum) = {swing_stance};
                                                         
                   %calcualte phase (hilbert transform):
                   joint_data = walkingData.([param.legs{leg} 'E_y'])(boutMap.walkingDataIdxs{trueBoutNum}); %calculate phase from tarsi y position data
                   normed_data = (joint_data-mean(joint_data, 'omitnan'))/std(joint_data, 'omitnan');
                   bfilt_data = sosfilt(sos, normed_data);  %bandpass frequency filter for hilbert transform            
                   boutMap.([param.legs{leg} '_phase']){trueBoutNum} = angle(hilbert(bfilt_data));
            
               end
           end
        end
    end
end

% Save num steps for each leg. 
% Make sure each leg took at least m=minStepsPerLeg steps. (otherwise it probably wasn't very good walking)
minStepsPerLeg = 3;
badBouts = []; %bouts that don't have enough steps. 
for bout = 1:height(boutMap)
    this_swing_stance = [boutMap.L1_swing_stance{bout}, boutMap.L2_swing_stance{bout}, boutMap.L3_swing_stance{bout},boutMap.R1_swing_stance{bout}, boutMap.R2_swing_stance{bout}, boutMap.R3_swing_stance{bout}];
    numSteps = sum(diff(this_swing_stance(:,:)) == 1);
    boutMap.num_steps(bout) = {numSteps};
    
    %check that there were enough steps in the bout to save it. 
    if any(numSteps < minStepsPerLeg)
        %there weren't enough steps, it's probably not very good walking, so discard this bout. 
        badBouts(end+1) = bout;
    end
end
boutMap(badBouts,:) = []; %delete bad bouts. 

%update new bout numbers to be sequential after deleting some bouts. 
boutMap.newBout = (1:height(boutMap))';







%%%%%%%%%%%%%% OLD %%%%%%%%%%%%%%%
% %set all swing stances to nan if any legs are nan
% % set all to nan if any leg takes less than 5 steps
% for bout = 1:height(boutMap)
%     this_swing_stance = [boutMap.L1_swing_stance{bout}, boutMap.L2_swing_stance{bout}, boutMap.L3_swing_stance{bout},boutMap.R1_swing_stance{bout}, boutMap.R2_swing_stance{bout}, boutMap.R3_swing_stance{bout}];
%     minNumSteps = min(sum(diff(this_swing_stance(:,:)) == 1));
%     if (minNumSteps < 7)
%         %not enough steps by each leg so set all data to NaN
%         nanIdxs = 1:height(this_swing_stance); 
%         boutMap.L1_swing_stance{bout}(nanIdxs) = NaN;
%         boutMap.L2_swing_stance{bout}(nanIdxs) = NaN;
%         boutMap.L3_swing_stance{bout}(nanIdxs) = NaN;
%         boutMap.R1_swing_stance{bout}(nanIdxs) = NaN;
%         boutMap.R2_swing_stance{bout}(nanIdxs) = NaN;
%         boutMap.R3_swing_stance{bout}(nanIdxs) = NaN;
%         boutMap.enough_steps(bout) = 0;
%     else
%         %there's enough steps, select forward walking and get rid of the first and last steps.
%         boutMap.enough_steps(bout) = 1;
% %         this_forward_rot = walkingData.forward_rotation(boutMap.walkingDataIdxs{bout});
% %         not_forward_rot = find(this_forward_rot ~= 1);
% %         boutMap.forward_rotation{bout} = walkingData.forward_rotation(boutMap.walkingDataIdxs{bout});
%         for leg = 1:param.numLegs
%             end_steps = find(diff(this_swing_stance(:,leg)) == -1); 
%             end_first_step = end_steps(1);
%             start_last_step = end_steps(end);
%             leg_str = [param.legs{leg} '_swing_stance'];
%             boutMap.(leg_str){bout}(1:end_first_step) = NaN; 
%             boutMap.(leg_str){bout}(start_last_step:end) = NaN; 
% %             boutMap.(leg_str){bout}(not_forward_rot) = NaN;
%         end
%     end
% end
% 





end