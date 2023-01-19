% FeCO intact onball laser power analysis
% Sarah Walling-Bell
% November 2022

% close all; clear all; clc;

%% Data to analyze

%%%%%%%%%%%% ALL DATASETS (for quick access) %%%%%%%%%%%%%
% {'claw_flexion_activation_intact_onball_laser_power', 'split_half_control_activation_intact_onball_laser_power'}, ...
% {'claw_extension_activation_intact_onball_laser_power', 'split_half_control_activation_intact_onball_laser_power'}, ... 
% {'hook_flexion_activation_intact_onball_laser_power', 'split_half_control_activation_intact_onball_laser_power'}, ... 
% {'hook_extension_activation_intact_onball_laser_power', 'split_half_control_activation_intact_onball_laser_power'}, ... 
% {'club_JR175_activation_intact_onball_laser_power', 'split_half_control_activation_intact_onball_laser_power'}, ... 
% {'club_JR299_activation_intact_onball_laser_power', 'split_half_control_activation_intact_onball_laser_power'}, ... 
% {'iav_activation_intact_onball_laser_power', 'split_half_control_activation_intact_onball_laser_power'}, ... 
% {'claw_flexion_silencing_intact_onball_laser_power', 'split_half_control_silencing_intact_onball_laser_power'}, ... 
% {'claw_extension_silencing_intact_onball_laser_power', 'split_half_control_silencing_intact_onball_laser_power'}, ... 
% {'hook_flexion_silencing_intact_onball_laser_power', 'split_half_control_silencing_intact_onball_laser_power'}, ... 
% {'hook_extension_silencing_intact_onball_laser_power', 'split_half_control_silencing_intact_onball_laser_power'}, ... %TODO not analyzed becasue file doesn't exist!!!
% {'club_JR175_silencing_intact_onball_laser_power', 'split_half_control_silencing_intact_onball_laser_power'}, ... 
% {'club_JR299_silencing_intact_onball_laser_power', 'split_half_control_silencing_intact_onball_laser_power'}, ... 
% {'iav_silencing_intact_onball_laser_power', 'split_half_control_silencing_intact_onball_laser_power'} %TODO not analyzed becasue file doesn't exist???
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% choose which datasets to loop through and analyze (paired with corresponding control dataset) 
datasets = {{'claw_flexion_activation_intact_onball_laser_power', 'split_half_control_activation_intact_onball_laser_power'}};

initial_vars = who;
%% Loop through all datasets and run analysis 
exp_dataset = '';
ctl_dataset = '';
initial_vars = who; 
initial_vars{end+1} = 'd';
for d = 1:width(datasets)
    clearvars('-except',initial_vars{:}); initial_vars = who;
    fprintf(['\n' datasets{d}{1} ' & ' datasets{d}{2} '\n']);

    %pick the next exp dataset, check that it's different than the previous one
    if strcmp(exp_dataset, datasets{d}{1}); loadExp = false; 
    else; exp_dataset = datasets{d}{1}; loadExp = true; end

    %pick the next ctl dataset, check that it's different than the previous one
    if strcmp(ctl_dataset, datasets{d}{2}); loadCtl = false; 
    else; ctl_dataset = datasets{d}{2}; loadCtl = true; end

%% Load in processed data
if loadExp
    [dataPwr, walkingDataPwr, paramPwr, stepsPwr] = loadReadyData(exp_dataset); %load control data
    [numRepsPwr, numCondsPwr, flyListPwr, flyIndicesPwr] = DLC_extract_flies(dataPwr);
    if ~exist('paramPwr.laserColor', 'var') 
        if contains(exp_dataset, '_act'); paramPwr.laserColor = 'red'; else; paramPwr.laserColor = 'green'; end
    end
end

if loadCtl
    [dataPwrCtl, walkingDataPwrCtl, paramPwrCtl, stepsPwrCtl] = loadReadyData(ctl_dataset); %load control data
    [numRepsPwrCtl, numCondsPwrCtl, flyListPwrCtl, flyIndicesPwrCtl] = DLC_extract_flies(dataPwrCtl);
    if ~exist('paramPwrCtl.laserColor', 'var') 
        if contains(ctl_dataset, '_act'); paramPwrCtl.laserColor = 'red'; else; paramPwrCtl.laserColor = 'green'; end
    end
end

initial_vars = who;
%% add laser power column if not present
if ~any(contains(dataPwr.Properties.VariableNames, 'laserPower'))
    dataPwr = addLaserPower(dataPwr);
end
if ~any(contains(dataPwrCtl.Properties.VariableNames, 'laserPower'))
    dataPwrCtl = addLaserPower(dataPwrCtl);
end

%% JOINT TIMESERIES ANALYSES
%%%%%%%%%%%%%%%%%%%%%%%%

%% MEAN flex joints x all legs x 1 second laser length - normed, sameAxes, plotSEM - binned by LASER POWER

clearvars('-except',initial_vars{:}); initial_vars = who;

%exp data
idxs = dataPwr.stimlen == 1; 
data_exp = dataPwr(idxs, :);

if contains(paramPwr.dataset, 'act'); laserColor = 'red'; else; laserColor = 'green'; end

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
normalize = 1;
sameAxes = 1;
plotSEM = 1;
colorByLaser = 1; % 0 to color by joint

fig_name = '\timeseries_allLegs_allFlexJoints_mean&SEM_axesAligned_1secLaser_allLaserPowers_anyBehavior';

timeseries_plot_laser_powers(data_exp, paramPwr, joints, normalize, sameAxes, plotSEM, laserColor, colorByLaser, fig_name);


clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN flex joints x all legs x 1 second laser length - WALKING @ stim - normed, sameAxes, plotSEM - binned by LASER POWER

clearvars('-except',initial_vars{:}); initial_vars = who;

%speed limits
min_speed_y = 5; 
max_abs_speed_z = 3; 

%exp data
stim_idxs = find(dataPwr.stimlen == 1 & dataPwr.fnum == paramPwr.laser_on & ~isnan(dataPwr.walking_bout_number) & ...
                 dataPwr.fictrac_delta_rot_lab_y_mms > min_speed_y & abs(dataPwr.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-paramPwr.laser_on:stim_idxs(i)+(paramPwr.vid_len_f-paramPwr.laser_on-1)]; end
data_exp = dataPwr(idxs, :);

if contains(paramPwr.dataset, 'act'); laserColor = 'red'; else; laserColor = 'green'; end

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
normalize = 1;
sameAxes = 1;
plotSEM = 1;
colorByLaser = 1; % 0 to color by joint

fig_name = ['\timeseries_allLegs_allFlexJoints_mean&SEM_axesAligned_1secLaser_allLaserPowers_walkingAtStimOnset_minFwdVel_' num2str(min_speed_y) '_maxAbsRotVel_' num2str(max_abs_speed_z)'];

timeseries_plot_laser_powers(data_exp, paramPwr, joints, normalize, sameAxes, plotSEM, laserColor, colorByLaser, fig_name);


clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN flex joints x all legs x 1 second laser length - STANDING @ stim - normed, sameAxes, plotSEM - binned by LASER POWER

clearvars('-except',initial_vars{:}); initial_vars = who;

%speed limits
max_speed_y = 3; 
max_abs_speed_z = 3; 
max_abs_speed_x = 3; 

%exp data
stim_idxs = find(dataPwr.stimlen == 1 & dataPwr.fnum == paramPwr.laser_on & ~isnan(dataPwr.standing_bout_number) & ...
                 dataPwr.fictrac_delta_rot_lab_y_mms < max_speed_y & abs(dataPwr.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z & abs(dataPwr.fictrac_delta_rot_lab_x_mms) < max_abs_speed_x); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-paramPwr.laser_on:stim_idxs(i)+(paramPwr.vid_len_f-paramPwr.laser_on-1)]; end
data_exp = dataPwr(idxs, :);

if contains(paramPwr.dataset, 'act'); laserColor = 'red'; else; laserColor = 'green'; end

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
normalize = 1;
sameAxes = 1;
plotSEM = 1;
colorByLaser = 1; % 0 to color by joint

fig_name = ['\timeseries_allLegs_allFlexJoints_mean&SEM_axesAligned_1secLaser_allLaserPowers_standingAtStimOnset_maxFwdVel_' num2str(max_speed_y) '_maxAbsRotVel_' num2str(max_abs_speed_z) '_maxAbsSideVel_' num2str(max_abs_speed_x)];

timeseries_plot_laser_powers(data_exp, paramPwr, joints, normalize, sameAxes, plotSEM, laserColor, colorByLaser, fig_name);


clearvars('-except',initial_vars{:}); initial_vars = who;
%% MEAN flex joints x one legs x all laser lengths - normed, sameAxes, plotSEM - binned by LASER POWER

clearvars('-except',initial_vars{:}); initial_vars = who;

leg = 1;

%exp data
data_exp = dataPwr;

if contains(paramPwr.dataset, 'act'); laserColor = 'red'; else; laserColor = 'green'; end

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
normalize = 1;
sameAxes = 1;
plotSEM = 1;
colorByLaser = 1; % 0 to color by joint

fig_name = ['\timeseries_' paramPwr.legs{leg} 'Leg_allFlexJoints_mean&SEM_axesAligned_1secLaser_allLaserPowers_anyBehavior'];

timeseries_plot_laser_powers_one_leg(data_exp, paramPwr, leg, joints, normalize, sameAxes, plotSEM, laserColor, colorByLaser, fig_name);


clearvars('-except',initial_vars{:}); initial_vars = who;


%% MEAN flex joints x one legs x all laser lengths - WALKING @ stim - normed, sameAxes, plotSEM - binned by LASER POWER

clearvars('-except',initial_vars{:}); initial_vars = who;

leg = 1;

%speed limits
min_speed_y = 5; 
max_abs_speed_z = 3; 

%exp data
stim_idxs = find(dataPwr.fnum == paramPwr.laser_on & ~isnan(dataPwr.walking_bout_number) & ...
                 dataPwr.fictrac_delta_rot_lab_y_mms > min_speed_y & abs(dataPwr.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-paramPwr.laser_on:stim_idxs(i)+(paramPwr.vid_len_f-paramPwr.laser_on-1)]; end
data_exp = dataPwr(idxs, :);

if contains(paramPwr.dataset, 'act'); laserColor = 'red'; else; laserColor = 'green'; end

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
normalize = 1;
sameAxes = 1;
plotSEM = 1;
colorByLaser = 1; % 0 to color by joint

fig_name = ['\timeseries_' paramPwr.legs{leg} 'Leg_allFlexJoints_mean&SEM_axesAligned_1secLaser_allLaserPowers_walkingAtStimOnset_minFwdVel_' num2str(min_speed_y) '_maxAbsRotVel_' num2str(max_abs_speed_z)'];

timeseries_plot_laser_powers_one_leg(data_exp, paramPwr, leg, joints, normalize, sameAxes, plotSEM, laserColor, colorByLaser, fig_name);


clearvars('-except',initial_vars{:}); initial_vars = who;


%% MEAN flex joints x one legs x all laser lengths - STANDING @ stim - normed, sameAxes, plotSEM - binned by LASER POWER

clearvars('-except',initial_vars{:}); initial_vars = who;

leg = 1;

%speed limits
max_speed_y = 3; 
max_abs_speed_z = 3; 
max_abs_speed_x = 3; 

%exp data
stim_idxs = find(dataPwr.fnum == paramPwr.laser_on & ~isnan(dataPwr.standing_bout_number) & ...
                 dataPwr.fictrac_delta_rot_lab_y_mms < max_speed_y & abs(dataPwr.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z & abs(dataPwr.fictrac_delta_rot_lab_x_mms) < max_abs_speed_x); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-paramPwr.laser_on:stim_idxs(i)+(paramPwr.vid_len_f-paramPwr.laser_on-1)]; end
data_exp = dataPwr(idxs, :);

if contains(paramPwr.dataset, 'act'); laserColor = 'red'; else; laserColor = 'green'; end

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
normalize = 1;
sameAxes = 1;
plotSEM = 1;
colorByLaser = 1; % 0 to color by joint

fig_name = ['\timeseries_' paramPwr.legs{leg} 'Leg_allFlexJoints_mean&SEM_axesAligned_1secLaser_allLaserPowers_standingAtStimOnset_maxFwdVel_' num2str(max_speed_y) '_maxAbsRotVel_' num2str(max_abs_speed_z) '_maxAbsSideVel_' num2str(max_abs_speed_x)];

timeseries_plot_laser_powers_one_leg(data_exp, paramPwr, leg, joints, normalize, sameAxes, plotSEM, laserColor, colorByLaser, fig_name);


clearvars('-except',initial_vars{:}); initial_vars = who;
%% VELOCITY TIMESERIES ANALYSES
%%%%%%%%%%%%%%%%%%%%%%%%
%% MEAN velocities x all laser lengths - normed, sameAxes, plotSEM - binned by LASER POWER

clearvars('-except',initial_vars{:}); initial_vars = who;

%exp data
data_exp = dataPwr;

if contains(paramPwr.dataset, 'act'); laserColor = 'red'; else; laserColor = 'green'; end
normalize = 1;
sameAxes = 1;
plotSEM = 1;
colorByLaser = 1; % 0 to color by vel

fig_name = '\velocity_timeseries_mean&SEM_axesAligned_allLaserLengths_allLaserPowers_anyBehavior';

velocity_timeseries_plot_laser_power(data_exp, paramPwr, normalize, sameAxes, plotSEM, laserColor, colorByLaser, fig_name);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN velocities x all laser lengths - WALKING @ stim - normed, sameAxes, plotSEM - binned by LASER POWER

clearvars('-except',initial_vars{:}); initial_vars = who;

%speed limits
min_speed_y = 5; 
max_abs_speed_z = 3; 

%exp data
stim_idxs = find(dataPwr.fnum == paramPwr.laser_on & ~isnan(dataPwr.walking_bout_number) & ...
                 dataPwr.fictrac_delta_rot_lab_y_mms > min_speed_y & abs(dataPwr.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-paramPwr.laser_on:stim_idxs(i)+(paramPwr.vid_len_f-paramPwr.laser_on-1)]; end
data_exp = dataPwr(idxs, :);

if contains(paramPwr.dataset, 'act'); laserColor = 'red'; else; laserColor = 'green'; end
normalize = 1;
sameAxes = 1;
plotSEM = 1;
colorByLaser = 1; % 0 to color by vel

fig_name = ['\velocity_timeseries_mean&SEM_axesAligned_allLaserLengths_allLaserPowers_walkingAtStimOnset_minFwdVel_' num2str(min_speed_y) '_maxAbsRotVel_' num2str(max_abs_speed_z)'];

velocity_timeseries_plot_laser_power(data_exp, paramPwr, normalize, sameAxes, plotSEM, laserColor, colorByLaser, fig_name);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% MEAN velocities x all laser lengths - STANDING @ stim - normed, sameAxes, plotSEM - binned by LASER POWER

clearvars('-except',initial_vars{:}); initial_vars = who;

%speed limits
max_speed_y = 3; 
max_abs_speed_z = 3; 
max_abs_speed_x = 3; 

%exp data
stim_idxs = find(dataPwr.fnum == paramPwr.laser_on & ~isnan(dataPwr.standing_bout_number) & ...
                 dataPwr.fictrac_delta_rot_lab_y_mms < max_speed_y & abs(dataPwr.fictrac_delta_rot_lab_z_mms) < max_abs_speed_z & abs(dataPwr.fictrac_delta_rot_lab_x_mms) < max_abs_speed_x); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-paramPwr.laser_on:stim_idxs(i)+(paramPwr.vid_len_f-paramPwr.laser_on-1)]; end
data_exp = dataPwr(idxs, :);

if contains(paramPwr.dataset, 'act'); laserColor = 'red'; else; laserColor = 'green'; end
normalize = 1;
sameAxes = 1;
plotSEM = 1;
colorByLaser = 1; % 0 to color by vel

fig_name = ['\velocity_timeseries_mean&SEM_axesAligned_allLaserLengths_allLaserPowers_standingAtStimOnset_maxFwdVel_' num2str(max_speed_y) '_maxAbsRotVel_' num2str(max_abs_speed_z) '_maxAbsSideVel_' num2str(max_abs_speed_x)];

velocity_timeseries_plot_laser_power(data_exp, paramPwr, normalize, sameAxes, plotSEM, laserColor, colorByLaser, fig_name);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% End analysis for this dataset
end

fprintf('\nDone! Analyzed all datasets.');