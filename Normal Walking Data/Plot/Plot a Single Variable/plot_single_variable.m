function plot_single_variable(data, var, idxs, param)

% Plot a single 'variable' in 'data' for given 'idxs'. Basically the simplest plot. 
% Assumes the x axis is time (with fps from param) and y axis is var. 
% 
% Params: 
%     data = a table of data from a parquet file. 
%     var = a string that is a variable name in data. 
%     idxs = a set of indexes into 'data' for which to plot 'var'.(assumes contiguous values)
%     param = output from DLC_load_params.m
%     save = t/f for saving the plot. If yes, it'll be saved to param.googledrivesave with the name being the 'variable' with'_single_variable' appended. 
%       TODO: could change this to save with the fly, date, rep, cond of the first Idx. 
%     
% Example:
%     plot_single_variable(data, 'fictrac_delta_rot_lab_z', [1:600], param, false);
% 
% Sarah Walling-Bell, January 2022

%TODO: could add that it looks at the laser condition for this var and sets
%the x ticks to have 0 be where a stim comes on. 
%TODO: could make it so you can input a set of idxs to loop through and
%plot the avg. 


fig = fullfig;
x = [1:max(size(idxs))]/param.fps;
plot(x, data.(var)(idxs), 'linewidth', 2);
ylabel(strrep(var, '_', ' ')); 
xlabel('Time (s)'); 
title(['Idxs: ' num2str(idxs(1)) ':' num2str(idxs(end))]);
hold off

fig = formatFig(fig, true);

%give option to save
fig_name = ['\' strrep(var, '_', '-') '_single_variable'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);




end