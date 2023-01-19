% FeCO headless and offball analysis
% Sarah Walling-Bell
% November 2022

% close all; clear all; clc;

%% Data to analyze

%%%%%%%%%%%% ALL DATASETS (for quick access) %%%%%%%%%%%%%
% {'claw_flexion_activation_intact_offball', 'split_half_control_activation_intact_offball'}, ... 
% {'claw_extension_activation_intact_offball', 'split_half_control_activation_intact_offball'}, ... 
% {'hook_flexion_activation_intact_offball', 'split_half_control_activation_intact_offball'}, ... 
% {'hook_extension_activation_intact_offball', 'split_half_control_activation_intact_offball'}, ... 
% {'club_JR175_activation_intact_offball', 'split_half_control_activation_intact_offball'}, ... 
% {'club_JR299_activation_intact_offball', 'split_half_control_activation_intact_offball'}, ... 
% {'iav_activation_intact_offball', 'split_half_control_activation_intact_offball'}, ... 
% {'claw_flexion_silencing_intact_offball', 'split_half_control_silencing_intact_offball'}, ... 
% {'claw_extension_silencing_intact_offball', 'split_half_control_silencing_intact_offball'}, ... 
% {'hook_flexion_silencing_intact_offball', 'split_half_control_silencing_intact_offball'}, ... 
% {'hook_extension_silencing_intact_offball', 'split_half_control_silencing_intact_offball'}, ... 
% {'club_JR175_silencing_intact_offball','split_half_control_silencing_intact_offball'}, ... % not processed! error thrown  
% {'club_JR299_silencing_intact_offball', 'split_half_control_silencing_intact_offball'}, ... 
% {'iav_silencing_intact_offball', 'split_half_control_silencing_intact_offball'}, ...
% {'claw_flexion_activation_headless_offball', 'split_half_control_activation_headless_offball'}, ... 
% {'claw_extension_activation_headless_offball', 'split_half_control_activation_headless_offball'}, ... 
% {'hook_flexion_activation_headless_offball', 'split_half_control_activation_headless_offball'}, ... 
% {'hook_extension_activation_headless_offball', 'split_half_control_activation_headless_offball'}, ... 
% {'club_JR175_activation_headless_offball', 'split_half_control_activation_headless_offball'}, ... 
% {'club_JR299_activation_headless_offball', 'split_half_control_activation_headless_offball'}, ... 
% {'iav_activation_headless_offball', 'split_half_control_activation_headless_offball'}, ... 
% {'claw_flexion_silencing_headless_offball', 'split_half_control_silencing_headless_offball'}, ... 
% {'claw_extension_silencing_headless_offball', 'split_half_control_silencing_headless_offball'}, ... 
% {'hook_flexion_silencing_headless_offball', 'split_half_control_silencing_headless_offball'}, ... 
% {'hook_extension_silencing_headless_offball', 'split_half_control_silencing_headless_offball'}, ... 
% {'club_JR175_silencing_headless_offball', 'split_half_control_silencing_headless_offball'}, ... 
% {'club_JR299_silencing_headless_offball', 'split_half_control_silencing_headless_offball'}, ... 
% {'iav_silencing_headless_offball', 'split_half_control_silencing_headless_offball'}, ...
% {'claw_flexion_activation_headless_onball', 'split_half_control_activation_headless_onball'}, ... 
% {'claw_extension_activation_headless_onball', 'split_half_control_activation_headless_onball'}, ... 
% {'hook_flexion_activation_headless_onball', 'split_half_control_activation_headless_onball'}, ... 
% {'hook_extension_activation_headless_onball', 'split_half_control_activation_headless_onball'}, ... 
% {'club_JR175_activation_headless_onball', 'split_half_control_activation_headless_onball'}, ... 
% {'club_JR299_activation_headless_onball', 'split_half_control_activation_headless_onball'}, ... 
% {'iav_activation_headless_onball', 'split_half_control_activation_headless_onball'}, ... 
% {'claw_flexion_silencing_headless_onball', 'split_half_control_silencing_headless_onball'}, ... 
% {'claw_extension_silencing_headless_onball', 'split_half_control_silencing_headless_onball'}, ... 
% {'hook_flexion_silencing_headless_onball', 'split_half_control_silencing_headless_onball'}, ... 
% {'hook_extension_silencing_headless_onball', 'split_half_control_silencing_headless_onball'}, ... 
% {'club_JR175_silencing_headless_onball', 'split_half_control_silencing_headless_onball'}, ... 
% {'club_JR299_silencing_headless_onball', 'split_half_control_silencing_headless_onball'}, ... 
% {'iav_silencing_headless_onball', 'split_half_control_silencing_headless_onball'}, ...
% {'club_JR175_silencing_intact_offball','split_half_control_silencing_intact_offball'}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% choose which datasets to loop through and analyze (paired with corresponding control dataset) 
datasets = {{'hook_extension_activation_headless_offball', 'split_half_control_activation_headless_offball'}, ...
            {'hook_extension_activation_headless_onball', 'split_half_control_activation_headless_onball'}};

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
    [data, param] = loadReadyDataNonWalking(exp_dataset);
    [numReps, numConds, flyList, flyIndices] = DLC_extract_flies(data);
    if ~exist('param.laserColor', 'var') 
        if contains(exp_dataset, '_act'); param.laserColor = 'red'; else; param.laserColor = 'green'; end
    end
end

if loadCtl
    [dataCtl, paramCtl] = loadReadyDataNonWalking(ctl_dataset); %load control data
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

if height(data_exp) > param.vid_len_f & height(data_ctl_in) > param.vid_len_f & height(data_ctl_out) > param.vid_len_f
    timeseries_plot(data_exp, param, joints, normalize, sameAxes, param.laserColor, plotSEM, fig_name, '-data_ctl_in', data_ctl_in, '-data_ctl_out', data_ctl_out, '-param_ctl_out', paramCtl);
end

clearvars('-except',initial_vars{:}); initial_vars = who;


%% MEAN abduct + rot joints x all legs x 1 second laser length - normed, sameAxes, plotSEM
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
sameAxes = 1;
plotSEM = 1;

fig_name = '\timeseries_allLegs_allAbductRotJoints_mean&SEM_axesAligned_1secLaser_anyBehavior';

if height(data_exp) > param.vid_len_f & height(data_ctl_in) > param.vid_len_f & height(data_ctl_out) > param.vid_len_f
    timeseries_plot(data_exp, param, joints, normalize, sameAxes, param.laserColor, plotSEM, fig_name, '-data_ctl_in', data_ctl_in, '-data_ctl_out', data_ctl_out, '-param_ctl_out', paramCtl);
end

clearvars('-except',initial_vars{:}); initial_vars = who;

if false
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

if height(data_exp) > param.vid_len_f 
    timeseries_plot_laser_lengths(data_exp, param, joints, normalize, sameAxes, plotSEM, param.laserColor, colorByLaser, fig_name);
end

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN flex joints x all legs x 1 second laser length - L1 FTi still & < 90 deg - normed, sameAxes, plotSEM
clearvars('-except',initial_vars{:}); initial_vars = who;

jnt = 'L1C_flex'; %joint to select is still and < angle
angle = 90; %angle (degrees) for filtering jnt data
still_thresh = 50; %threshold (deg/s) for the joint being 'still'

%exp data
stim_idxs = find(data.stimlen == 1 & data.fnum == param.laser_on & ...
                 [abs(diff(data.(jnt))/(1/param.fps)); NaN] < still_thresh & data.(jnt) < angle); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_exp = data(idxs, :);

%ctl data 1 (intra fly)
stim_idxs = find(data.stimlen == 0 & data.fnum == param.laser_on & ...
                 [abs(diff(data.(jnt))/(1/param.fps)); NaN] < still_thresh & data.(jnt) < angle); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_ctl_in = data(idxs, :);

%ctl data 2 (genotype)
stim_idxs = find(dataCtl.stimlen == 1 & dataCtl.fnum == param.laser_on & ...
                 [abs(diff(dataCtl.(jnt))/(1/paramCtl.fps)); NaN] < still_thresh & dataCtl.(jnt) < angle); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-paramCtl.laser_on:stim_idxs(i)+(paramCtl.vid_len_f-param.laser_on-1)]; end
data_ctl_out = dataCtl(idxs, :);

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
normalize = 1;
sameAxes = 1;
plotSEM = 1;

fig_name = ['\timeseries_allLegs_allFlexJoints_mean&SEM_axesAligned_1secLaser_stillAndFlexed_delta' jnt '_below_' num2str(still_thresh) '_' jnt '_below_' num2str(angle)];

if height(data_exp) > param.vid_len_f & height(data_ctl_in) > param.vid_len_f & height(data_ctl_out) > param.vid_len_f
    timeseries_plot(data_exp, param, joints, normalize, sameAxes, param.laserColor, plotSEM, fig_name, '-data_ctl_in', data_ctl_in, '-data_ctl_out', data_ctl_out, '-param_ctl_out', paramCtl);
end

clearvars('-except',initial_vars{:}); initial_vars = who;


%% MEAN flex joints x all legs x 1 second laser length - L1 FTi still & > 90 deg - normed, sameAxes, plotSEM
clearvars('-except',initial_vars{:}); initial_vars = who;

jnt = 'L1C_flex'; %joint to select is still and > angle
angle = 90; %angle (degrees) for filtering jnt data
still_thresh = 50; %threshold (deg/s) for the joint being 'still'

%exp data
stim_idxs = find(data.stimlen == 1 & data.fnum == param.laser_on & ...
                 [abs(diff(data.(jnt))/(1/param.fps)); NaN] < still_thresh & data.(jnt) > angle); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_exp = data(idxs, :);

%ctl data 1 (intra fly)
stim_idxs = find(data.stimlen == 0 & data.fnum == param.laser_on & ...
                 [abs(diff(data.(jnt))/(1/param.fps)); NaN] < still_thresh & data.(jnt) > angle); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_ctl_in = data(idxs, :);

%ctl data 2 (genotype)
stim_idxs = find(dataCtl.stimlen == 1 & dataCtl.fnum == param.laser_on & ...
                 [abs(diff(dataCtl.(jnt))/(1/paramCtl.fps)); NaN] < still_thresh & dataCtl.(jnt) > angle); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-paramCtl.laser_on:stim_idxs(i)+(paramCtl.vid_len_f-param.laser_on-1)]; end
data_ctl_out = dataCtl(idxs, :);

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
normalize = 1;
sameAxes = 1;
plotSEM = 1;

fig_name = ['\timeseries_allLegs_allFlexJoints_mean&SEM_axesAligned_1secLaser_stillAndExtended_delta' jnt '_below_' num2str(still_thresh) '_' jnt '_above_' num2str(angle)];

if height(data_exp) > param.vid_len_f & height(data_ctl_in) > param.vid_len_f & height(data_ctl_out) > param.vid_len_f
    timeseries_plot(data_exp, param, joints, normalize, sameAxes, param.laserColor, plotSEM, fig_name, '-data_ctl_in', data_ctl_in, '-data_ctl_out', data_ctl_out, '-param_ctl_out', paramCtl);
end

clearvars('-except',initial_vars{:}); initial_vars = who;
%% MEAN flex joints x all legs x 1 second laser length - L1 FTi moving & < 90 deg - normed, sameAxes, plotSEM
clearvars('-except',initial_vars{:}); initial_vars = who;

jnt = 'L1C_flex'; %joint to select is still and < angle
angle = 90; %angle (degrees) for filtering jnt data
still_thresh = 100; %threshold (deg/s) for the joint 'moving'

%exp data
stim_idxs = find(data.stimlen == 1 & data.fnum == param.laser_on & ...
                 [abs(diff(data.(jnt))/(1/param.fps)); NaN] > still_thresh & data.(jnt) < angle); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_exp = data(idxs, :);

%ctl data 1 (intra fly)
stim_idxs = find(data.stimlen == 0 & data.fnum == param.laser_on & ...
                 [abs(diff(data.(jnt))/(1/param.fps)); NaN] > still_thresh & data.(jnt) < angle); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_ctl_in = data(idxs, :);

%ctl data 2 (genotype)
stim_idxs = find(dataCtl.stimlen == 1 & dataCtl.fnum == param.laser_on & ...
                 [abs(diff(dataCtl.(jnt))/(1/paramCtl.fps)); NaN] > still_thresh & dataCtl.(jnt) < angle); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-paramCtl.laser_on:stim_idxs(i)+(paramCtl.vid_len_f-param.laser_on-1)]; end
data_ctl_out = dataCtl(idxs, :);

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
normalize = 1;
sameAxes = 1;
plotSEM = 1;

fig_name = ['\timeseries_allLegs_allFlexJoints_mean&SEM_axesAligned_1secLaser_movingAndFlexed_delta' jnt '_above_' num2str(still_thresh) '_' jnt '_below_' num2str(angle)];

if height(data_exp) > param.vid_len_f & height(data_ctl_in) > param.vid_len_f & height(data_ctl_out) > param.vid_len_f
    timeseries_plot(data_exp, param, joints, normalize, sameAxes, param.laserColor, plotSEM, fig_name, '-data_ctl_in', data_ctl_in, '-data_ctl_out', data_ctl_out, '-param_ctl_out', paramCtl);
end

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN flex joints x all legs x 1 second laser length - L1 FTi moving & > 90 deg - normed, sameAxes, plotSEM
clearvars('-except',initial_vars{:}); initial_vars = who;

jnt = 'L1C_flex'; %joint to select is still and > angle
angle = 90; %angle (degrees) for filtering jnt data
still_thresh = 100; %threshold (deg/s) for the joint 'moving'

%exp data
stim_idxs = find(data.stimlen == 1 & data.fnum == param.laser_on & ...
                 [abs(diff(data.(jnt))/(1/param.fps)); NaN] > still_thresh & data.(jnt) > angle); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_exp = data(idxs, :);

%ctl data 1 (intra fly)
stim_idxs = find(data.stimlen == 0 & data.fnum == param.laser_on & ...
                 [abs(diff(data.(jnt))/(1/param.fps)); NaN] > still_thresh & data.(jnt) > angle); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_ctl_in = data(idxs, :);

%ctl data 2 (genotype)
stim_idxs = find(dataCtl.stimlen == 1 & dataCtl.fnum == param.laser_on & ...
                 [abs(diff(dataCtl.(jnt))/(1/paramCtl.fps)); NaN] > still_thresh & dataCtl.(jnt) > angle); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-paramCtl.laser_on:stim_idxs(i)+(paramCtl.vid_len_f-param.laser_on-1)]; end
data_ctl_out = dataCtl(idxs, :);

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
normalize = 1;
sameAxes = 1;
plotSEM = 1;

fig_name = ['\timeseries_allLegs_allFlexJoints_mean&SEM_axesAligned_1secLaser_movingAndExtended_delta' jnt '_above_' num2str(still_thresh) '_' jnt '_above_' num2str(angle)];

if height(data_exp) > param.vid_len_f & height(data_ctl_in) > param.vid_len_f & height(data_ctl_out) > param.vid_len_f
    timeseries_plot(data_exp, param, joints, normalize, sameAxes, param.laserColor, plotSEM, fig_name, '-data_ctl_in', data_ctl_in, '-data_ctl_out', data_ctl_out, '-param_ctl_out', paramCtl);
end

clearvars('-except',initial_vars{:}); initial_vars = who;
%% MEAN flex joints x all legs x 1 second laser length - L1 FTi flexing - normed, sameAxes, plotSEM
clearvars('-except',initial_vars{:}); initial_vars = who;

jnt = 'L1C_flex'; %joint to select is flexing
still_thresh = -100; %threshold (deg/s) for the joint 'flexing'

%exp data
stim_idxs = find(data.stimlen == 1 & data.fnum == param.laser_on & ...
                 [diff(data.(jnt))/(1/param.fps); NaN] < still_thresh); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_exp = data(idxs, :);

%ctl data 1 (intra fly)
stim_idxs = find(data.stimlen == 0 & data.fnum == param.laser_on & ...
                 [diff(data.(jnt))/(1/param.fps); NaN] < still_thresh); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_ctl_in = data(idxs, :);

%ctl data 2 (genotype)
stim_idxs = find(dataCtl.stimlen == 1 & dataCtl.fnum == param.laser_on & ...
                 [diff(dataCtl.(jnt))/(1/paramCtl.fps); NaN] < still_thresh); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-paramCtl.laser_on:stim_idxs(i)+(paramCtl.vid_len_f-param.laser_on-1)]; end
data_ctl_out = dataCtl(idxs, :);

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
normalize = 1;
sameAxes = 1;
plotSEM = 1;

fig_name = ['\timeseries_allLegs_allFlexJoints_mean&SEM_axesAligned_1secLaser_flexing_delta' jnt '_below_' num2str(still_thresh)];

if height(data_exp) > param.vid_len_f & height(data_ctl_in) > param.vid_len_f & height(data_ctl_out) > param.vid_len_f
    timeseries_plot(data_exp, param, joints, normalize, sameAxes, param.laserColor, plotSEM, fig_name, '-data_ctl_in', data_ctl_in, '-data_ctl_out', data_ctl_out, '-param_ctl_out', paramCtl);
end

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN flex joints x all legs x 1 second laser length - L1 FTi extending - normed, sameAxes, plotSEM
clearvars('-except',initial_vars{:}); initial_vars = who;

jnt = 'L1C_flex'; %joint to select is extending
still_thresh = 100; %threshold (deg/s) for the joint 'flexing'

%exp data
stim_idxs = find(data.stimlen == 1 & data.fnum == param.laser_on & ...
                 [diff(data.(jnt))/(1/param.fps); NaN] > still_thresh); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_exp = data(idxs, :);

%ctl data 1 (intra fly)
stim_idxs = find(data.stimlen == 0 & data.fnum == param.laser_on & ...
                 [diff(data.(jnt))/(1/param.fps); NaN] > still_thresh); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-param.laser_on:stim_idxs(i)+(param.vid_len_f-param.laser_on-1)]; end
data_ctl_in = data(idxs, :);

%ctl data 2 (genotype)
stim_idxs = find(dataCtl.stimlen == 1 & dataCtl.fnum == param.laser_on & ...
                 [diff(dataCtl.(jnt))/(1/paramCtl.fps); NaN] > still_thresh); 
idxs = []; for i = 1:height(stim_idxs); idxs = [idxs, stim_idxs(i)-paramCtl.laser_on:stim_idxs(i)+(paramCtl.vid_len_f-param.laser_on-1)]; end
data_ctl_out = dataCtl(idxs, :);

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
normalize = 1;
sameAxes = 1;
plotSEM = 1;

fig_name = ['\timeseries_allLegs_allFlexJoints_mean&SEM_axesAligned_1secLaser_extending_delta' jnt '_above_' num2str(still_thresh)];

if height(data_exp) > param.vid_len_f & height(data_ctl_in) > param.vid_len_f & height(data_ctl_out) > param.vid_len_f
    timeseries_plot(data_exp, param, joints, normalize, sameAxes, param.laserColor, plotSEM, fig_name, '-data_ctl_in', data_ctl_in, '-data_ctl_out', data_ctl_out, '-param_ctl_out', paramCtl);
end

clearvars('-except',initial_vars{:}); initial_vars = who;
%% End analysis for this dataset
end
end
fprintf('\nDone! Analyzed all datasets.');