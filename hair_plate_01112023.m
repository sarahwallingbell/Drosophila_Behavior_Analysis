%% Script for analyzing effect of optogenetically perturbing 
% L1 coxa hair plate 8 cells on L1 body-coxa angles. 

% Sarah Walling-Bell
% January 2023

close all; clear all; clc;

%% Data to analyze

% pairs of experimental and control datasets to be analyzed together
datasets = {{'R48A07AD;R20C06DBD_silencing_intact_onball', 'hair_plate_split_half_control_silencing_intact_onball'}, ...
            {'R48A07AD;R20C06DBD_activation_intact_onball', 'hair_plate_split_half_control_activation_intact_onball'}, ...
            {'R48A07AD;R20C06DBD_silencing_headless_onball', 'hair_plate_split_half_control_silencing_headless_onball'}, ...
            {'R48A07AD;R20C06DBD_activation_headless_onball', 'hair_plate_split_half_control_activation_headless_onball'}};

pathToDatasets = 'G:\.shortcut-targets-by-id\15uXSKut68NlHyR8OywpWbt0zXFWyC-43\Sarah\Analysis\'; %Update path to point to this directory when running on a different computer

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

if loadCtl

    %load the data 
    dataCtl = parquetread([pathToDatasets ctl_dataset '\' ctl_dataset '.parquet']);
    walkingDataCtl = dataCtl(~isnan(dataCtl.walking_bout_number),:); 
    load([pathToDatasets ctl_dataset '\' ctl_dataset '_metadata.mat'], "param", "steps");
%     load([pathToDatasets ctl_dataset '\' ctl_dataset '_metadata.mat'], "param"); %USE THIS FOR HEADLESS DATA (no steps struct) 

    paramCtl = param; clear param;
%     stepsCtl = steps; clear steps;
    
    %find flies and laser color
    [numRepsCtl, numCondsCtl, flyListCtl, flyIndicesCtl] = DLC_extract_flies(dataCtl);
    if ~exist('paramCtl.laserColor', 'var') 
        if contains(ctl_dataset, '_act'); paramCtl.laserColor = 'red'; else; paramCtl.laserColor = 'green'; end
    end
end


if loadExp

    %load the data 
    data = parquetread([pathToDatasets exp_dataset '\' exp_dataset '.parquet']);
    walkingData = data(~isnan(data.walking_bout_number),:); 
    load([pathToDatasets exp_dataset '\' exp_dataset '_metadata.mat'], "param", "steps");
%     load([pathToDatasets exp_dataset '\' exp_dataset '_metadata.mat'], "param"); %USE THIS FOR HEADLESS DATA (no steps struct) 

    %find flies and laser color
    [numReps, numConds, flyList, flyIndices] = DLC_extract_flies(data);
    if ~exist('param.laserColor', 'var') 
        if contains(exp_dataset, '_act'); param.laserColor = 'red'; else; param.laserColor = 'green'; end
    end
end

initial_vars = who;
%% TIMESERIES FIGURES
%%%%%%%%%%%%%%%%%%%%%

%% Timeseries: mean L1 BC angles abduction & flexion x 1 second laser length - normed, plotSEM - ANY BEHAVIOR
clearvars('-except',initial_vars{:}); initial_vars = who;

%exp data (hair plate flies with 1 second laser) 
idxs = data.stimlen == 1; 
data_exp = data(idxs, :);

%ctl data 1 (hair plate flies with no laser - internal control)
idxs = data.stimlen == 0; 
data_ctl_in = data(idxs, :);

%ctl data 2 (split half control flies with 1 second laser - external control (check for light effect))
idxs = dataCtl.stimlen == 1; 
data_ctl_out = dataCtl(idxs, :);

joints = {'A_abduct', 'A_rot', 'A_flex'}; %TODO: I would plot the rotation angle data in polar coordinates to eliminate the wrap around effect. 
normalize = 1;
sameAxes = 0;
plotSEM = 1;

fig_name = '\timeseries_L1_BC_abduct_rot_flex_mean&SEM_1secLaser_anyBehavior';

timeseries_plot_hair_plate(data_exp, param, joints, normalize, sameAxes, param.laserColor, plotSEM, fig_name, '-data_ctl_in', data_ctl_in, '-data_ctl_out', data_ctl_out, '-param_ctl_out', paramCtl);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% Timeseries: mean L1 BC angles abduction & flexion x 1 second laser length - normed, plotSEM - WALKING at stim onset
clearvars('-except',initial_vars{:}); initial_vars = who;

%speed limits
min_speed_y = 5; % forward velocity min
max_abs_speed_z = 3; % rotational velocity absolute value max

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

joints = {'A_abduct', 'A_rot', 'A_flex'}; %TODO: I would plot the rotation angle data in polar coordinates to eliminate the wrap around effect. 
normalize = 1;
sameAxes = 0;
plotSEM = 1;

fig_name = ['\timeseries_L1_BC_abduct_rot_flex_mean&SEM_1secLaser_walkingAtStimOnset_minSpeedY_' num2str(min_speed_y) '_maxAbsSpeedZ_' num2str(max_abs_speed_z)];

timeseries_plot_hair_plate(data_exp, param, joints, normalize, sameAxes, param.laserColor, plotSEM, fig_name, '-data_ctl_in', data_ctl_in, '-data_ctl_out', data_ctl_out, '-param_ctl_out', paramCtl);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% Timeseries: mean L1 BC angles abduction & flexion x 1 second laser length - normed, plotSEM - STANDING at stim onset
clearvars('-except',initial_vars{:}); initial_vars = who;

%speed limits 
%TODO: play with these values
max_speed_y = 5; %forward velocity max
max_abs_speed_z = 5; %rotational velocity absolute value max
max_abs_speed_x = 5; %sideslip velocity absolute value max

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

joints = {'A_abduct', 'A_rot', 'A_flex'}; %TODO: I would plot the rotation angle data in polar coordinates to eliminate the wrap around effect. 
normalize = 1;
sameAxes = 0;
plotSEM = 1;

fig_name = ['\timeseries_L1_BC_abduct_rot_flex_mean&SEM_1secLaser_standingAtStimOnset_maxSpeedY_' num2str(max_speed_y) '_maxAbsSpeedZ_' num2str(max_abs_speed_z)  '_maxAbsSpeedX_' num2str(max_abs_speed_x)];

timeseries_plot_hair_plate(data_exp, param, joints, normalize, sameAxes, param.laserColor, plotSEM, fig_name, '-data_ctl_in', data_ctl_in, '-data_ctl_out', data_ctl_out, '-param_ctl_out', paramCtl);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% JOINT ANGLE X PHASE FIGURES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Wouldn't run these on headless data!
%% MEAN BC abduction angle x E y phase x ctl vs stim x FORWARD vel - ALL steps
clearvars('-except',initial_vars{:}); initial_vars = who;

joint = 'A_abduct';
phase = 'E_y_phase'; %phase of the leg calculated using the y position (along the length of the body) of the tarsus tip (which is the 5th (AKA 'E') tracked point on the leg))

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 50; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

velocityBins = [5,30]; % 5:5:30; %Play with this to have different velocity bins if you want, currentlyt I have no velocity bins

fig_name = ['\avg_' joint '_x_' phase '_ctl_vs_stim_binnedByForwardVel_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

joint_x_phase_plot_fwd_vel_binned(data, steps, flyList.flyid, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins, param.laserColor, fig_name)

clearvars('-except',initial_vars{:}); initial_vars = who;
%% MEAN BC flexion angle x E y phase x ctl vs stim x FORWARD vel - ALL steps
clearvars('-except',initial_vars{:}); initial_vars = who;

joint = 'A_flex';
phase = 'E_y_phase'; %phase of the leg calculated using the y position (along the length of the body) of the tarsus tip (which is the 5th (AKA 'E') tracked point on the leg))

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 50; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

velocityBins = [5,30]; % 5:5:30; %Play with this to have different velocity bins if you want, currentlyt I have no velocity bins

fig_name = ['\avg_' joint '_x_' phase '_ctl_vs_stim_binnedByForwardVel_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

joint_x_phase_plot_fwd_vel_binned(data, steps, flyList.flyid, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins, param.laserColor, fig_name)

clearvars('-except',initial_vars{:}); initial_vars = who;

%% End analysis for this dataset
end

fprintf('\nDone! Analyzed all datasets.');