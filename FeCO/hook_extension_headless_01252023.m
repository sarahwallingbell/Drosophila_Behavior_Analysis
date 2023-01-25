% Hook extension activation headless analysis - which flies had behavioral
% response to the laser. 
% Sarah Walling-Bell
% January 2023

% close all; clear all; clc;

%% Data to analyze


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
%% Single fly response to stim 
%%%%%%%%%%%%%%%%%%%%%%%%

%% raw joint angle traces
for fly = 1:height(flyList)
flyid = flyList.flyid{fly}; %param to update

fig = fullfig; 

i = 0;
for leg = 1:param.numLegs
    for laser = 1:param.numLasers
        i = i+1;
        subplot(param.numLegs, param.numLasers, i);
   
        %extract relevant data (this fly and laser length)
        idxs = find(strcmp(data.flyid, flyid) & round(data.stimlen, 2) == round(param.lasers(laser), 2)); 
        plot_data = data(idxs, :);
    
        %organize data 
        starts = find(plot_data.fnum == 0);
        starts(starts+param.vid_len_f-1 > height(plot_data)) = []; %delete any ctl starts that are less than param.vid_len_f frames from the end of this data
        frames = starts+[0:param.vid_len_f-1]; %each row is a vid, containing idx of the vid in data

        this_leg_data = plot_data.([param.legs{leg} 'C_flex'])(frames);

        %plot
        plot(this_leg_data');
        
        %label
        if laser == 1
            ylabel(strrep([param.legs{leg} ' C_flex'], '_', ' '));
            if leg == 1
                xlabel('Time (frames)');
            end
        end
        if leg == 1
            title(['Laser ' num2str(param.lasers(laser)) ' s']);
        end
    end
end

fig = formatFig(fig, true, [param.numLegs, param.numLasers]);
sgtitle(strrep(flyid, '_', '-'), 'Color', 'white', 'FontSize', 14);

%save
fig_name = ['\hook_extension_activation_headless_onball_' flyid '_allLegs_FTi_rawTraces'];
param.googledrivesave = 'G:\My Drive\hook_extension_activation_headless\onBall';
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


end


%% normed joint angle traces
for fly = 1:height(flyList)
flyid = flyList.flyid{fly}; %param to update

fig = fullfig; 

i = 0;
for leg = 1:param.numLegs
    for laser = 1:param.numLasers
        i = i+1;
        subplot(param.numLegs, param.numLasers, i);
   
        %extract relevant data (this fly and laser length)
        idxs = find(strcmp(data.flyid, flyid) & round(data.stimlen, 2) == round(param.lasers(laser), 2)); 
        plot_data = data(idxs, :);
    
        %organize data 
        starts = find(plot_data.fnum == 0);
        starts(starts+param.vid_len_f-1 > height(plot_data)) = []; %delete any ctl starts that are less than param.vid_len_f frames from the end of this data
        frames = starts+[0:param.vid_len_f-1]; %each row is a vid, containing idx of the vid in data

        this_leg_data = plot_data.([param.legs{leg} 'C_flex'])(frames);

        this_leg_data_normed = this_leg_data - this_leg_data(:,150);

        %plot
        plot(this_leg_data_normed');
        
        %label
        if laser == 1
            ylabel(strrep([param.legs{leg} ' C_flex'], '_', ' '));
            if leg == 1
                xlabel('Time (frames)');
            end
        end
        if leg == 1
            title(['Laser ' num2str(param.lasers(laser)) ' s']);
        end
    end
end

fig = formatFig(fig, true, [param.numLegs, param.numLasers]);
sgtitle(strrep(flyid, '_', '-'), 'Color', 'white', 'FontSize', 14);

%save
fig_name = ['\hook_extension_activation_headless_onball_' flyid '_allLegs_FTi_normedTraces'];
param.googledrivesave = 'G:\My Drive\hook_extension_activation_headless\onBall';
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


end


end
fprintf('\nDone! Analyzed all datasets.');