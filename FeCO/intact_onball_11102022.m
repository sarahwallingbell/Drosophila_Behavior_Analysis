% FeCO intact onball analysis
% Sarah Walling-Bell
% November 2022

close all; clear all; clc;

%% Data to analyze

%%%%%%%%%%%% ALL DATASETS (for quick access) %%%%%%%%%%%%%
% {'claw_flexion_activation_intact_onball', 'split_half_control_activation_intact_onball'}, ... 
% {'claw_extension_activation_intact_onball', 'split_half_control_activation_intact_onball'}, ... 
% {'hook_flexion_activation_intact_onball', 'split_half_control_activation_intact_onball'}, ... 
% {'hook_extension_activation_intact_onball', 'split_half_control_activation_intact_onball'}, ... 
% {'club_JR175_activation_intact_onball', 'split_half_control_activation_intact_onball'}, ... 
% {'club_JR299_activation_intact_onball', 'split_half_control_activation_intact_onball'}, ... 
% {'iav_activation_intact_onball', 'split_half_control_activation_intact_onball'}, ... 
% {'claw_flexion_silencing_intact_onball', 'split_half_control_silencing_intact_onball'}, ... 
% {'claw_extension_silencing_intact_onball', 'split_half_control_silencing_intact_onball'}, ... 
% {'hook_flexion_silencing_intact_onball', 'split_half_control_silencing_intact_onball'}, ... 
% {'hook_extension_silencing_intact_onball', 'split_half_control_silencing_intact_onball'}, ... 
% {'club_JR175_silencing_intact_onball', 'split_half_control_silencing_intact_onball'}, ... 
% {'club_JR299_silencing_intact_onball', 'split_half_control_silencing_intact_onball'}, ... 
% {'iav_silencing_intact_onball', 'split_half_control_silencing_intact_onball'}                       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% choose which datasets to loop through and analyze (paired with corresponding control dataset) 
datasets = {{'claw_flexion_activation_intact_onball', 'split_half_control_activation_intact_onball'}};

initial_vars = who;
%% Loop through all datasets and run analysis 
exp_dataset = '';
ctl_dataset = '';
initial_vars = who; 
initial_vars{end+1} = 'd';
for d = 1:width(datasets)
    clearvars('-except',initial_vars{:}); initial_vars = who;
    fprintf(['\n' datasets{d}{1} ' & ' datasets{d}{2}]);

    %pick the next exp dataset, check that it's different than the previous one
    if strcmp(exp_dataset, datasets{d}{1}); loadExp = false; 
    else; exp_dataset = datasets{d}{1}; loadExp = true; end

    %pick the next ctl dataset, check that it's different than the previous one
    if strcmp(ctl_dataset, datasets{d}{2}); loadCtl = false; 
    else; ctl_dataset = datasets{d}{2}; loadCtl = true; end

%% Load in processed data
if loadExp
    [data, walkingData, param, steps] = loadReadyData(exp_dataset);
    [numReps, numConds, flyList, flyIndices] = DLC_extract_flies(data);
    if ~exist('param.laserColor', 'var') 
        if contains(exp_dataset, '_act'); param.laserColor = 'red'; else; param.laserColor = 'green'; end
    end
end

if loadCtl
    [dataCtl, walkingDataCtl, paramCtl, stepsCtl] = loadReadyData(ctl_dataset); %load control data
    [numRepsCtl, numCondsCtl, flyListCtl, flyIndicesCtl] = DLC_extract_flies(dataCtl);
    if ~exist('paramCtl.laserColor', 'var') 
        if contains(ctl_dataset, '_act'); paramCtl.laserColor = 'red'; else; paramCtl.laserColor = 'green'; end
    end
end

initial_vars = who;
%% HEATMAPS OF TIMESERIES DATA
%%%%%%%%%%%%%%%%%%%%%%%%

%% Heatmap of normed timeseries flex joint averages exp minus ctl - 1 sec laser length 

clearvars('-except',initial_vars{:}); initial_vars = who;

%exp data
idxs = data.stimlen == 1; 
data_exp = data(idxs, :);

%ctl data 1 (intra fly)
idxs = data.stimlen == 0; 
data_ctl_in = data(idxs, :);

%ctl data 2 (genotype)
idxs = dataCtl.stimlen == 1; 
data_ctl_out = dataCtl(idxs, :);

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};

fig_name = '\timeseries_heatmap_allLegs_allFlexJoints_1secLaser_anyBehavior';

timeseries_heatmap_plot(data_exp, param, joints, fig_name, data_ctl_in, data_ctl_out, paramCtl);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% Heatmap of normed timeseries all joint averages exp minus ctl - 1 sec laser length 

clearvars('-except',initial_vars{:}); initial_vars = who;

%exp data
idxs = data.stimlen == 1; 
data_exp = data(idxs, :);

%ctl data 1 (intra fly)
idxs = data.stimlen == 0; 
data_ctl_in = data(idxs, :);

%ctl data 2 (genotype)

idxs = dataCtl.stimlen == 1; 
data_ctl_out = dataCtl(idxs, :);

joints = {'A_abduct', 'A_rot', 'A_flex', 'B_rot', 'B_flex', 'C_rot', 'C_flex', 'D_flex'};

fig_name = '\timeseries_heatmap_allLegs_allJoints_1secLaser_anyBehavior';

timeseries_heatmap_plot(data_exp, param, joints, fig_name, data_ctl_in, data_ctl_out, paramCtl);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% JOINT TIMESERIES ANALYSES
%%%%%%%%%%%%%%%%%%%%%%%%

%% MEAN flex joints x all legs x 1 second laser length - normed, sameAxes, plotSEM
clearvars('-except',initial_vars{:}); initial_vars = who;

%exp data
idxs = data.stimlen == 1; 
data_exp = data(idxs, :);

%ctl data 1 (intra fly)
idxs = data.stimlen == 0; 
data_ctl_in = data(idxs, :);

%ctl data 2 (genotype)
idxs = dataCtl.stimlen == 1; 
data_ctl_out = dataCtl(idxs, :);

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
normalize = 1;
sameAxes = 1;
plotSEM = 1;

fig_name = '\timeseries_allLegs_allFlexJoints_mean&SEM_axesAligned_1secLaser_anyBehavior';

timeseries_plot(data_exp, param, joints, normalize, sameAxes, param.laserColor, plotSEM, fig_name, '-data_ctl_in', data_ctl_in, '-data_ctl_out', data_ctl_out, '-param_ctl_out', paramCtl);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% MEAN flex joints x all legs x 1 second laser length - WALKING @ stim - normed, sameAxes, plotSEM
clearvars('-except',initial_vars{:}); initial_vars = who;

%speed limits
min_speed_y = 5; 
max_abs_speed_z = 3; 

%exp data
stim_idxs = find(data.stimlen == 1 & data.fnum == param.laser_on & ~isnan(data.walking_bout_number) & ...
                 data.fictrac_delta_rot_lab_y_mms > min_speed_y & abs(data.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_exp = data(idxs, :);

%ctl data 1 (intra fly)
stim_idxs = find(data.stimlen == 0 & data.fnum == param.laser_on & ~isnan(data.walking_bout_number)  & ...
                 data.fictrac_delta_rot_lab_y_mms > min_speed_y & abs(data.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_ctl_in = data(idxs, :);

%ctl data 2 (genotype)
stim_idxs = find(dataCtl.stimlen == 1 & dataCtl.fnum == paramCtl.laser_on & ~isnan(dataCtl.walking_bout_number)  & ...
                 dataCtl.fictrac_delta_rot_lab_y_mms > min_speed_y & abs(dataCtl.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-paramCtl.laser_on:stim_idxs(i)+(paramCtl.vid_len_f-param.laser_on-1)]; end
data_ctl_out = dataCtl(idxs, :);

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
normalize = 1;
sameAxes = 0;
plotSEM = 1;

fig_name = ['\timeseries_allLegs_allFlexJoints_mean&SEM_axesAligned_1secLaser_walkingAtStimOnset_minFwdVel_' num2str(min_speed_y) '_maxAbsRotVel_' num2str(max_abs_speed_z)];

timeseries_plot(data_exp, param, joints, normalize, sameAxes, param.laserColor, plotSEM, fig_name, '-data_ctl_in', data_ctl_in, '-data_ctl_out', data_ctl_out, '-param_ctl_out', paramCtl);


clearvars('-except',initial_vars{:}); initial_vars = who;
%% MEAN flex joints x all legs x 1 second laser length - STANDING @ stim - normed, sameAxes, plotSEM
clearvars('-except',initial_vars{:}); initial_vars = who;

%speed limits
max_speed_y = 3; 
max_abs_speed_z = 3; 
max_abs_speed_x = 3; 

%exp data
stim_idxs = find(data.stimlen == 1 & data.fnum == param.laser_on & ~isnan(data.standing_bout_number) & ...
                 data.fictrac_delta_rot_lab_y_mms < max_speed_y & abs(data.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z & abs(data.fictrac_delta_rot_lab_x_mms) < max_abs_speed_x); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_exp = data(idxs, :);

%ctl data 1 (intra fly)
stim_idxs = find(data.stimlen == 0 & data.fnum == param.laser_on & ~isnan(data.standing_bout_number)  & ...
                 data.fictrac_delta_rot_lab_y_mms < max_speed_y & abs(data.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z & abs(data.fictrac_delta_rot_lab_x_mms) < max_abs_speed_x); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_ctl_in = data(idxs, :);

%ctl data 2 (genotype)
stim_idxs = find(dataCtl.stimlen == 1 & dataCtl.fnum == paramCtl.laser_on & ~isnan(dataCtl.standing_bout_number)  & ...
                 dataCtl.fictrac_delta_rot_lab_y_mms < max_speed_y & abs(dataCtl.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z & abs(dataCtl.fictrac_delta_rot_lab_x_mms) < max_abs_speed_x); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-paramCtl.laser_on:stim_idxs(i)+(paramCtl.vid_len_f-param.laser_on-1)]; end
data_ctl_out = dataCtl(idxs, :);

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
normalize = 1;
sameAxes = 1;
plotSEM = 1;

fig_name = ['\timeseries_allLegs_allFlexJoints_mean&SEM_axesAligned_1secLaser_standingAtStimOnset_maxFwdVel_' num2str(max_speed_y) '_maxAbsRotVel_' num2str(max_abs_speed_z) '_maxAbsSideVel_' num2str(max_abs_speed_x)];

timeseries_plot(data_exp, param, joints, normalize, sameAxes, param.laserColor, plotSEM, fig_name, '-data_ctl_in', data_ctl_in, '-data_ctl_out', data_ctl_out, '-param_ctl_out', paramCtl);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN abduct & rot joints x all legs x 1 second laser length - normed, sameAxes, plotSEM
clearvars('-except',initial_vars{:}); initial_vars = who;

%exp data
idxs = data.stimlen == 1; 
data_exp = data(idxs, :);

%ctl data 1 (intra fly)
idxs = data.stimlen == 0; 
data_ctl_in = data(idxs, :);

%ctl data 2 (genotype)
idxs = dataCtl.stimlen == 1; 
data_ctl_out = dataCtl(idxs, :);

joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
normalize = 1;
sameAxes = 0;
plotSEM = 1;

fig_name = '\timeseries_allLegs_allAbductRotJoints_mean&SEM_axesAligned_1secLaser_anyBehavior';

timeseries_plot(data_exp, param, joints, normalize, sameAxes, param.laserColor, plotSEM, fig_name, '-data_ctl_in', data_ctl_in, '-data_ctl_out', data_ctl_out, '-param_ctl_out', paramCtl);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN flex joints x all legs x all lasers lengths - normed, sameAxes, plotSEM - binned by LASER LENGTH

clearvars('-except',initial_vars{:}); initial_vars = who;

%exp data
data_exp = data;

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
normalize = 1;
sameAxes = 1;
plotSEM = 1;
colorByLaser = 1; % 0 to color by joint

fig_name = '\timeseries_allLegs_allFlexJoints_mean&SEM_axesAligned_allLasers_anyBehavior';

timeseries_plot_laser_lengths(data_exp, param, joints, normalize, sameAxes, plotSEM, param.laserColor, colorByLaser, fig_name);


clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN flex joints x all legs x all lasers lengths - WALKING @ stim - normed, sameAxes, plotSEM - binned by LASER LENGTH
clearvars('-except',initial_vars{:}); initial_vars = who;

%speed limits
min_speed_y = 5; 
max_abs_speed_z = 3; 

%exp data
stim_idxs = find(data.fnum == param.laser_on & ~isnan(data.walking_bout_number) & ...
                 data.fictrac_delta_rot_lab_y_mms > min_speed_y & abs(data.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_exp = data(idxs, :);

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
normalize = 1;
sameAxes = 1;
plotSEM = 1;
colorByLaser = 1; % 0 to color by joint

fig_name = ['\timeseries_allLegs_allFlexJoints_mean&SEM_axesAligned_allLasers_walkingAtStimOnset_minFwdVel_' num2str(min_speed_y) '_maxAbsRotVel_' num2str(max_abs_speed_z)];

timeseries_plot_laser_lengths(data_exp, param, joints, normalize, sameAxes, plotSEM, param.laserColor, colorByLaser, fig_name);


clearvars('-except',initial_vars{:}); initial_vars = who;
%% MEAN flex joints x all legs x all lasers lengths - STANDING @ stim - normed, sameAxes, plotSEM - binned by LASER LENGTH
clearvars('-except',initial_vars{:}); initial_vars = who;

%speed limits
max_speed_y = 3; 
max_abs_speed_z = 3; 
max_abs_speed_x = 3; 

%exp data
stim_idxs = find(data.fnum == param.laser_on & ~isnan(data.standing_bout_number) & ...
                 data.fictrac_delta_rot_lab_y_mms < max_speed_y & abs(data.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z & abs(data.fictrac_delta_rot_lab_x_mms) < max_abs_speed_x); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_exp = data(idxs, :);

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
normalize = 1;
sameAxes = 1;
plotSEM = 1;
colorByLaser = 1; % 0 to color by joint

fig_name = ['\timeseries_allLegs_allFlexJoints_mean&SEM_axesAligned_allLasers_standingAtStimOnset_maxFwdVel_' num2str(max_speed_y) '_maxAbsRotVel_' num2str(max_abs_speed_z) '_maxAbsSideVel_' num2str(max_abs_speed_x)];

timeseries_plot_laser_lengths(data_exp, param, joints, normalize, sameAxes, plotSEM, param.laserColor, colorByLaser, fig_name);


clearvars('-except',initial_vars{:}); initial_vars = who;
%% VELOCITY TIMESERIES ANALYSES
%%%%%%%%%%%%%%%%%%%%%%%%

%% MEAN velocities x all laser lengths - normed, sameAxes, plotSEM

clearvars('-except',initial_vars{:}); initial_vars = who;

%exp data
idxs = data.stimlen > 0; 
data_exp = data(idxs, :);

%ctl data 1 (intra fly)
idxs = data.stimlen == 0; 
data_ctl_in = data(idxs, :);

%ctl data 2 (genotype)
idxs = dataCtl.stimlen > 0; 
data_ctl_out = dataCtl(idxs, :);

normalize = 1;
sameAxes = 1;
plotSEM = 1;

fig_name = '\velocity_timeseries_mean&SEM_axesAligned_allLasers_anyBehavior';

velocity_timeseries_plot(data_exp, param, normalize, sameAxes, plotSEM, param.laserColor, fig_name, '-data_ctl_in', data_ctl_in, '-data_ctl_out', data_ctl_out, '-param_ctl_out', paramCtl);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN velocities x all laser lengths - WALKING @ stim - normed, sameAxes, plotSEM

clearvars('-except',initial_vars{:}); initial_vars = who;

%speed limits
min_speed_y = 5; 
max_abs_speed_z = 3; 

%exp data
stim_idxs = find(data.stimlen > 0 & data.fnum == param.laser_on & ~isnan(data.walking_bout_number) & ...
                 data.fictrac_delta_rot_lab_y_mms > min_speed_y & abs(data.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_exp = data(idxs, :);

%ctl data 1 (intra fly)
stim_idxs = find(data.stimlen == 0 & data.fnum == param.laser_on & ~isnan(data.walking_bout_number)  & ...
                 data.fictrac_delta_rot_lab_y_mms > min_speed_y & abs(data.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_ctl_in = data(idxs, :);

%ctl data 2 (genotype)
stim_idxs = find(dataCtl.stimlen > 0 & dataCtl.fnum == paramCtl.laser_on & ~isnan(dataCtl.walking_bout_number)  & ...
                 dataCtl.fictrac_delta_rot_lab_y_mms > min_speed_y & abs(dataCtl.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-paramCtl.laser_on:stim_idxs(i)+(paramCtl.vid_len_f-param.laser_on-1)]; end
data_ctl_out = dataCtl(idxs, :);

normalize = 1;
sameAxes = 1;
plotSEM = 1;

fig_name = ['\velocity_timeseries_mean&SEM_axesAligned_allLasers_walkingAtStimOnset_minFwdVel_' num2str(min_speed_y) '_maxAbsRotVel_' num2str(max_abs_speed_z)];

velocity_timeseries_plot(data_exp, param, normalize, sameAxes, plotSEM, param.laserColor, fig_name, '-data_ctl_in', data_ctl_in, '-data_ctl_out', data_ctl_out, '-param_ctl_out', paramCtl);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN velocities x all laser lengths - STANDING @ stim - normed, sameAxes, plotSEM

clearvars('-except',initial_vars{:}); initial_vars = who;

%speed limits
max_speed_y = 3; 
max_abs_speed_z = 3; 
max_abs_speed_x = 3; 

%exp data
stim_idxs = find(data.stimlen > 0 & data.fnum == param.laser_on & ~isnan(data.standing_bout_number) & ...
                 data.fictrac_delta_rot_lab_y_mms < max_speed_y & abs(data.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z & abs(data.fictrac_delta_rot_lab_x_mms) < max_abs_speed_x); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_exp = data(idxs, :);

%ctl data 1 (intra fly)
stim_idxs = find(data.stimlen == 0 & data.fnum == param.laser_on & ~isnan(data.standing_bout_number)  & ...
                 data.fictrac_delta_rot_lab_y_mms < max_speed_y & abs(data.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z & abs(data.fictrac_delta_rot_lab_x_mms) < max_abs_speed_x); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_ctl_in = data(idxs, :);

%ctl data 2 (genotype)
stim_idxs = find(dataCtl.stimlen > 0 & dataCtl.fnum == paramCtl.laser_on & ~isnan(dataCtl.standing_bout_number)  & ...
                 dataCtl.fictrac_delta_rot_lab_y_mms < max_speed_y & abs(dataCtl.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z & abs(dataCtl.fictrac_delta_rot_lab_x_mms) < max_abs_speed_x); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-paramCtl.laser_on:stim_idxs(i)+(paramCtl.vid_len_f-param.laser_on-1)]; end
data_ctl_out = dataCtl(idxs, :);

normalize = 1;
sameAxes = 1;
plotSEM = 1;

fig_name = ['\velocity_timeseries_mean&SEM_axesAligned_allLasers_standingAtStimOnset_maxFwdVel_' num2str(max_speed_y) '_maxAbsRotVel_' num2str(max_abs_speed_z) '_maxAbsSideVel_' num2str(max_abs_speed_x)];

velocity_timeseries_plot(data_exp, param, normalize, sameAxes, plotSEM, param.laserColor, fig_name, '-data_ctl_in', data_ctl_in, '-data_ctl_out', data_ctl_out, '-param_ctl_out', paramCtl);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% JOINT X PHASE ANALYSES
%%%%%%%%%%%%%%%%%%%%%%%%

%% MEAN FTi joint x E y phase x ctl vs stim x FORWARD vel - ALL steps
clearvars('-except',initial_vars{:}); initial_vars = who;

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 100; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

velocityBins = 5:5:30;

fig_name = ['\avg_' joint '_x_' phase '_ctl_vs_stim_binnedByForwardVel_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

joint_x_phase_plot_fwd_vel_binned(data, steps, flyList.flyid, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins, param.laserColor, fig_name)

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN FTi joint x E y phase x ctl vs stim x FORWARD vel - FORWARD steps
clearvars('-except',initial_vars{:}); initial_vars = who;

y_min = 5; %mm/s
z_max_abs = 3; %mm/s

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = false; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 20; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

velocityBins = 5:5:20;

fig_name = ['\avg_' joint '_x_' phase '_ctl_vs_stim_binnedByForwardVel_fwdSteps_allFlies_yMin_' num2str(y_min) '_zMaxAbs_' num2str(z_max_abs) '_minAvgSteps_' num2str(minAvgSteps)];

joint_x_phase_plot_fwd_vel_binned(data, steps, flyList.flyid, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins, param.laserColor, fig_name, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN FTi joint x E y phase x ctl vs stim x FORWARD vel - exp minus ctl - ALL steps
clearvars('-except',initial_vars{:}); initial_vars = who;

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 10; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

velocityBins = 5:5:30;

fig_name = ['\avg_' joint '_x_' phase '_stim_minus_ctl_binnedByForwardVel_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

joint_x_phase_plot_fwd_vel_binned_exp_minus_ctl(data, steps, flyList.flyid, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins, param.laserColor, fig_name, '-ctl_data', dataCtl, '-ctl_steps', stepsCtl, '-ctl_flies', flyListCtl.flyid, '-ctl_param', paramCtl);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN FTi joint x E y phase x ctl vs stim x FORWARD vel - exp minus ctl - FORWARD steps
clearvars('-except',initial_vars{:}); initial_vars = who;

y_min = 5; %mm/s
z_max_abs = 3; %mm/s

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 10; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

velocityBins = 5:5:30;

fig_name = ['\avg_' joint '_x_' phase '_stim_minus_ctl_binnedByForwardVel_fwdSteps_allFlies_yMin_' num2str(y_min) '_zMaxAbs_' num2str(z_max_abs) '_minAvgSteps_' num2str(minAvgSteps)];

joint_x_phase_plot_fwd_vel_binned_exp_minus_ctl(data, steps, flyList.flyid, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins, param.laserColor, fig_name, '-ctl_data', dataCtl, '-ctl_steps', stepsCtl, '-ctl_flies', flyListCtl.flyid, '-ctl_param', paramCtl, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN FTi joint x E y phase x ctl vs stim x ROTATIONAL vel - exp minus ctl - ALL steps
clearvars('-except',initial_vars{:}); initial_vars = who;

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = false; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 10; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

velocityBins = -30:10:30;

fig_name = ['\avg_' joint '_x_' phase '_stim_minus_ctl_binnedByRotationalVel_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

joint_x_phase_plot_rot_vel_binned_exp_minus_ctl(data, steps, flyList.flyid, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins, param.laserColor, fig_name, '-ctl_data', dataCtl, '-ctl_steps', stepsCtl, '-ctl_flies', flyListCtl.flyid, '-ctl_param', paramCtl);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN FTi joint x E y phase x ctl vs stim x ROTATIONAL vel - exp minus ctl - ROTATING steps
clearvars('-except',initial_vars{:}); initial_vars = who;

y_max = 10; %mm/s
z_min_abs = 3; %mm/s

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = false; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 10; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

velocityBins = -30:10:30;

fig_name = ['\avg_' joint '_x_' phase '_stim_minus_ctl_binnedByRotationalVel_fwdSteps_allFlies_yMax_' num2str(y_max) '_zMinAbs_' num2str(z_min_abs) '_minAvgSteps_' num2str(minAvgSteps)];

joint_x_phase_plot_rot_vel_binned_exp_minus_ctl(data, steps, flyList.flyid, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins, param.laserColor, fig_name, '-ctl_data', dataCtl, '-ctl_steps', stepsCtl, '-ctl_flies', flyListCtl.flyid, '-ctl_param', paramCtl, '-y_max', y_max, '-z_min_abs', z_min_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% MEAN FTi joint VELOCITY x E y phase x ctl vs stim x FORWARD vel - exp minus ctl - ALL steps 
clearvars('-except',initial_vars{:}); initial_vars = who;

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 10; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

velocityBins = 5:5:30;

fig_name = ['\avg_' joint '_velocity_x_' phase '_stim_minus_ctl_binnedByForwardVel_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

joint_velocity_x_phase_plot_fwd_vel_binned_exp_minus_ctl(data, steps, flyList.flyid, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins, param.laserColor, fig_name, '-ctl_data', dataCtl, '-ctl_steps', stepsCtl, '-ctl_flies', flyListCtl.flyid, '-ctl_param', paramCtl);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% MEAN FTi joint VELOCITY x E y phase x ctl vs stim x FORWARD vel - exp minus ctl - FORWARD steps 
clearvars('-except',initial_vars{:}); initial_vars = who;

y_min = 5; %mm/s
z_max_abs = 3; %mm/s

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 10; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

velocityBins = 5:5:30;

fig_name = ['\avg_' joint '_velocity_x_' phase '_stim_minus_ctl_binnedByForwardVel_fwdSteps_allFlies_yMin_' num2str(y_min) '_zMaxAbs_' num2str(z_max_abs) '_minAvgSteps_' num2str(minAvgSteps)];

joint_velocity_x_phase_plot_fwd_vel_binned_exp_minus_ctl(data, steps, flyList.flyid, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins, param.laserColor, fig_name, '-ctl_data', dataCtl, '-ctl_steps', stepsCtl, '-ctl_flies', flyListCtl.flyid, '-ctl_param', paramCtl, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN FTi joint VELOCITY x E y phase x ctl vs stim x ROTATIONAL vel - exp minus ctl - ALL steps 

clearvars('-except',initial_vars{:}); initial_vars = who;

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = false; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 10; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

velocityBins = -30:10:30;

fig_name = ['\avg_' joint '_velocity_x_' phase '_stim_minus_ctl_binnedByRotationalVel_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

joint_velocity_x_phase_plot_rot_vel_binned_exp_minus_ctl(data, steps, flyList.flyid, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins, param.laserColor, fig_name, '-ctl_data', dataCtl, '-ctl_steps', stepsCtl, '-ctl_flies', flyListCtl.flyid, '-ctl_param', paramCtl);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% MEAN FTi joint VELOCITY x E y phase x ctl vs stim x ROTATIONAL vel - exp minus ctl - ROTATING steps 

clearvars('-except',initial_vars{:}); initial_vars = who;

y_max = 10; %mm/s
z_min_abs = 3; %mm/s

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = false; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 10; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

velocityBins = -30:10:30;

fig_name = ['\avg_' joint '_velocity_x_' phase '_stim_minus_ctl_binnedByRotationalVel_fwdSteps_allFlies_yMax_' num2str(y_max) '_zMinAbs_' num2str(z_min_abs) '_minAvgSteps_' num2str(minAvgSteps)];

joint_velocity_x_phase_plot_rot_vel_binned_exp_minus_ctl(data, steps, flyList.flyid, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins, param.laserColor, fig_name, '-ctl_data', dataCtl, '-ctl_steps', stepsCtl, '-ctl_flies', flyListCtl.flyid, '-ctl_param', paramCtl, '-y_max', y_max, '-z_min_abs', z_min_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% STEP METRICS
%%%%%%%%%%%%%%%%%%%%%%%%%

%% STEP LENGTH x Forward Vel x stim vs ctl - FORWARD steps

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

metric = 'step_length';
velocity = 'avg_speed_y';

numSpeedBins = 10; 
minAvgSteps = 10; 
maxSpeed = 30;

y_min = 5; 
z_max_abs = 5;

fig_name = ['\avg_' metric '_x_' velocity '_ctl_vs_stim_fwdSteps_allFlies_yMin_' num2str(y_min) '_zMaxAbs_' num2str(z_max_abs) '_minAvgSteps_' num2str(minAvgSteps)];

plotStepMetricsxVelocityxStimvsCtl(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, ... 
                                '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% STEP DURATION x Forward Vel x stim vs ctl - FORWARD steps

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

metric = 'step_duration';
velocity = 'avg_speed_y';

numSpeedBins = 10; 
minAvgSteps = 10; 
maxSpeed = 30;

y_min = 5; 
z_max_abs = 5;

fig_name = ['\avg_' metric '_x_' velocity '_ctl_vs_stim_fwdSteps_allFlies_yMin_' num2str(y_min) '_zMaxAbs_' num2str(z_max_abs) '_minAvgSteps_' num2str(minAvgSteps)];

plotStepMetricsxVelocityxStimvsCtl(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, ... 
                                '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% SWING DURATION x Forward Vel x stim vs ctl - FORWARD steps

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

metric = 'swing_duration';
velocity = 'avg_speed_y';

numSpeedBins = 10; 
minAvgSteps = 10; 
maxSpeed = 30;

y_min = 5; 
z_max_abs = 5;

fig_name = ['\avg_' metric '_x_' velocity '_ctl_vs_stim_fwdSteps_allFlies_yMin_' num2str(y_min) '_zMaxAbs_' num2str(z_max_abs) '_minAvgSteps_' num2str(minAvgSteps)];

plotStepMetricsxVelocityxStimvsCtl(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, ... 
                                '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% STANCE DURATION x Forward Vel x stim vs ctl - FORWARD steps

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

metric = 'stance_duration';
velocity = 'avg_speed_y';

numSpeedBins = 10; 
minAvgSteps = 10; 
maxSpeed = 30;

y_min = 5; 
z_max_abs = 5;

fig_name = ['\avg_' metric '_x_' velocity '_ctl_vs_stim_fwdSteps_allFlies_yMin_' num2str(y_min) '_zMaxAbs_' num2str(z_max_abs) '_minAvgSteps_' num2str(minAvgSteps)];

plotStepMetricsxVelocityxStimvsCtl(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, ... 
                                '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% AEP & PEP x Forward Vel x stim vs ctl - FORWARD STEPS - one plot
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

velocity = 'avg_speed_y';
onePlot = 'y';
type = '2D';

numSpeedBins = 10; 
minAvgSteps = 10; 
maxSpeed = 30;

y_min = 5; 
z_max_abs = 5;

fig_name = ['\avg_AEP_&_PEP_x_' velocity '_ctl_vs_stim_fwdSteps_allFlies_yMin_' num2str(y_min) '_zMaxAbs_' num2str(z_max_abs) '_minAvgSteps_' num2str(minAvgSteps)];

plotAEPnPEPxVelocityStimvsCtl(steps, param, velocity, type, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, onePlot, ... 
                                '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% STEP LENGTH x Rotational Vel x stim vs ctl - ALL steps


%params
flies = flyList.flyid;

metric = 'step_length';
velocity = 'avg_speed_z';

numSpeedBins = 20; 
minAvgSteps = 20; 
maxSpeed = 40;

fig_name = ['\avg_' metric '_x_' velocity '_ctl_vs_stim_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

plotStepMetricsxVelocityxStimvsCtl(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% STEP DURATION x Rotational Vel x stim vs ctl - ALL steps

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

metric = 'step_duration';
velocity = 'avg_speed_z';

numSpeedBins = 20; 
minAvgSteps = 20; 
maxSpeed = 40;

fig_name = ['\avg_' metric '_x_' velocity '_ctl_vs_stim_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

plotStepMetricsxVelocityxStimvsCtl(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% SWING DURATION x Rotational Vel x stim vs ctl - ALL steps

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

metric = 'swing_duration';
velocity = 'avg_speed_z';

numSpeedBins = 20; 
minAvgSteps = 20; 
maxSpeed = 40;

fig_name = ['\avg_' metric '_x_' velocity '_ctl_vs_stim_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

plotStepMetricsxVelocityxStimvsCtl(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% STANCE DURATION x Rotational Vel x stim vs ctl - ALL steps

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

metric = 'stance_duration';
velocity = 'avg_speed_z';

numSpeedBins = 20; 
minAvgSteps = 20; 
maxSpeed = 40;

fig_name = ['\avg_' metric '_x_' velocity '_ctl_vs_stim_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

plotStepMetricsxVelocityxStimvsCtl(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% AEP & PEP x Rotational Vel x stim vs ctl - ALL STEPS - one plot
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

velocity = 'avg_speed_z';
onePlot = 'y';
type = '2D';

numSpeedBins = 10; 
minAvgSteps = 10; 
maxSpeed = 30;

fig_name = ['\avg_AEP_&_PEP_x_' velocity '_ctl_vs_stim_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

plotAEPnPEPxVelocityStimvsCtl(steps, param, velocity, type, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, onePlot);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% 3D TARSUS TRAJECTORIES
%%%%%%%%%%%%%%%%%%%%%%%%%

%% 3D joint traces ctl vs stim
% clearvars('-except',initial_vars{:}); initial_vars = who;
% 
% %params
% connected = true; %true plots legs, false plots joints
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% for leg = 1:param.numLegs
%             idxs{1,leg} = find(steps.leg(leg).meta.percent_stim == 0); %ctl steps
%             idxs{2,leg} = find(steps.leg(leg).meta.percent_stim > 0); %exp steps
% end
% legs = {'L1','L2','L3','R1','R2','R3'};
% 
% joints = {'A','B','C','D','E'};
% plotColors = {'white', param.laserColor};
% 
% Plot_joint_trajectories_multiple_avgs_step(steps, idxs, data, legs, joints, connected, param, plotColors)
% 
% clearvars('-except',initial_vars{:}); initial_vars = who;

%% End analysis for this dataset
end

fprintf('\nDone! Analyzed all datasets.');