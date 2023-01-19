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
% November, 2021

warning('off','MATLAB:table:RowsAddedExistingVars') %turn off warning for filling only sub columns at a time for each row. 

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
    if height(boutIdxs) > 10 % a walking bout must be at least 10 frames. 
        %find where the frame number jumps, indicating multiple walking bouts with same 'walking_bout_number'
        [~, locs] = findpeaks(diff(boutIdxs), 'MinPeakProminence', 2);
        %find how many walking bout have same bout number 
        if isempty(locs); numSubBouts = 1; else; numSubBouts = height(locs)+1; end
        locs = [0; locs; height(boutIdxs)];

        for subBout = 1:numSubBouts
            
           % make sure there's more than 10 frames in the subbout
           if width(boutIdxs(locs(subBout)+1):boutIdxs(locs(subBout+1))) > 10
               
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
                   this_leg_str = [param.legs{leg} 'E_y'];
                   this_data = walkingData.(this_leg_str)(boutMap.walkingDataIdxs{trueBoutNum});

                   prom = 0.2;
                   [ssPks, ssPkLocs] = findpeaks(this_data, 'MinPeakProminence', prom);
                   [ssTrs, ssTrLocs] = findpeaks(this_data*-1, 'MinPeakProminence', prom);

                   for pk = 1:height(ssPks)-1
                       step_start = ssPkLocs(pk); 
                       step_end = ssPkLocs(pk+1);
                       step_mid = ssTrLocs(ssTrLocs < step_end & ssTrLocs > step_start);
                       swing_stance(step_start:step_mid-1) = 0; %stance 
                       swing_stance(step_mid:step_end) = 1; %swing
                   end           
                   this_leg_ss_string = [param.legs{leg} '_swing_stance'];
                   boutMap.(this_leg_ss_string)(trueBoutNum) = {swing_stance};
                   
                                      
                   %calcualte phase (hilbert transform):
                   joint_data = walkingData.([param.legs{leg} 'E_y'])(boutMap.walkingDataIdxs{trueBoutNum}); %calculate phase from tarsi y position data
                   normed_data = (joint_data-nanmean(joint_data))/nanstd(joint_data);
                   bfilt_data = sosfilt(sos, normed_data);  %bandpass frequency filter for hilbert transform            
                   boutMap.([param.legs{leg} '_phase']){trueBoutNum} = angle(hilbert(bfilt_data));
            
               end
           end
        end
    end
end

% Save num steps for each leg. 
for bout = 1:height(boutMap)
    this_swing_stance = [boutMap.L1_swing_stance{bout}, boutMap.L2_swing_stance{bout}, boutMap.L3_swing_stance{bout},boutMap.R1_swing_stance{bout}, boutMap.R2_swing_stance{bout}, boutMap.R3_swing_stance{bout}];
    numSteps = sum(diff(this_swing_stance(:,:)) == 1);
    boutMap.num_steps(bout) = {numSteps};
end









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