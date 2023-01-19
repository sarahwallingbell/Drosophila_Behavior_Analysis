function plot_data_by_arena(data, var, param)
    
% Finds how many arena conditions there are. Plots a histogram of the 'var' 
% for each arena condition. A possible use is to see if the delta_rotation_lab_z 
% (aka turning velocity) distribution fits the turning arena conditions. 
% 
% Params: 
%     data = a table of data from a parquet file. 
%     var = a string that is a variable name in data. 
%     param = output from DLC_load_params.m
%     
% Example:
%     plotDataByArena(walkingData, 'fictrac_delta_rot_lab_z');
% 
%     
% Sarah Walling-Bell, January 2022

fig = fullfig;
arenas = unique(table(data.type, data.dir), 'rows'); %param.numConds includes different types of lasers

plotting = numSubplots(height(arenas));

for arena = 1:height(arenas)
    cond_data = data.(var)(strcmp(data.type, arenas{arena, 1}) & strcmp(data.dir, arenas{arena, 2}));
    AX(arena) = subplot(plotting(1), plotting(2), arena); hold on
    histogram(cond_data); 
    xlabel(strrep(var, '_', ' ')); 
    ylabel('Count (frames)'); 
    title(['Arena: ' convertStringsToChars(arenas{arena, 1}) ' ' convertStringsToChars(arenas{arena, 2})]);
    hold off
end


if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    %make the center of the x axis 0
    allXLim = get(AX, {'XLim'});
    allXLim = cat(2, allXLim{:});
    set(AX, 'XLim', [max(abs(allXLim))*-1, max(abs(allXLim))]);
end

fig = formatFig(fig, true, plotting);

% 
fig_name = ['\' strrep(var, '_', '-') '_by_arena'];
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

end