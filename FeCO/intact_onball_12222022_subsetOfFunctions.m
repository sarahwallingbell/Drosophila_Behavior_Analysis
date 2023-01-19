% FeCO intact onball analysis
% Sarah Walling-Bell
% November 2022

% close all; clear all; clc;

%% Data to analyze

datasets = {{'claw_flexion_silencing_intact_onball', 'split_half_control_silencing_intact_onball'}, ...
            {'claw_extension_silencing_intact_onball', 'split_half_control_silencing_intact_onball'}, ...
            {'hook_flexion_silencing_intact_onball', 'split_half_control_silencing_intact_onball'}, ...
            {'hook_extension_silencing_intact_onball', 'split_half_control_silencing_intact_onball'}, ...
            {'club_JR299_silencing_intact_onball', 'split_half_control_silencing_intact_onball'}, ...
            {'club_JR175_silencing_intact_onball', 'split_half_control_silencing_intact_onball'}, ...
            {'iav_silencing_intact_onball', 'split_half_control_silencing_intact_onball'}, ...
            {'claw_flexion_activation_intact_onball', 'split_half_control_activation_intact_onball'}, ...
            {'claw_extension_activation_intact_onball', 'split_half_control_activation_intact_onball'}, ...
            {'hook_flexion_activation_intact_onball', 'split_half_control_activation_intact_onball'}, ...
            {'hook_extension_activation_intact_onball', 'split_half_control_activation_intact_onball'}, ...
            {'club_JR299_activation_intact_onball', 'split_half_control_activation_intact_onball'}, ...
            {'club_JR175_activation_intact_onball', 'split_half_control_activation_intact_onball'}, ...
            {'iav_activation_intact_onball', 'split_half_control_activation_intact_onball'}};

initial_vars = who;
%% Loop through all datasets and run analysis 
% exp_dataset = '';
% ctl_dataset = '';
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


%% MEAN abd & rot joints x all legs x 1 second laser length - normed, sameAxes, plotSEM
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

%% End analysis for this dataset
end

fprintf('\nDone! Analyzed all datasets.');