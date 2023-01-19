clear all; close all; clc;

% Select and load parquet file (the fly data)
[FilePaths, version] = DLC_select_parquet_evynData();
data = [];
for file = 1:width(FilePaths)
    data = [data; parquetread(FilePaths{file})];
end
columns = data.Properties.VariableNames;
for j = 1:width(columns)
    column_names{j} = strrep(columns{j}, '_', '-');
end
[numReps, numConds, flyList, flyIndices] = DLC_extract_flies_evynData(columns, data);
param = DLC_load_params(version, flyList);
%override laser params - Evyn's data had 7 laser lengths 
param.lasers = {0, 0.03, 0.06, 0.09, 0.18, 0.32, 0.72};
param.allLasers = [0, 0.03, 0.06, 0.09, 0.18, 0.32, 0.72, 0, 0.03, 0.06, 0.09, 0.18, 0.32, 0.72, 0, 0.03, 0.06, 0.09, 0.18, 0.32, 0.72, 0, 0.03, 0.06, 0.09, 0.18, 0.32, 0.72];
param.laserIdx = [1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7,1,2,3,4,5,6,7];
param.numLasers = width(param.lasers);
param.stimRegions = DLC_getStimRegions(data, param);

param.numReps = numReps;
param.numConds = numConds; 
% param.flyList = flyList;
param.flyIndices = flyIndices;
param.columns = columns; 
param.column_names = column_names;
param.parquet = FilePaths;

param.forward_rot_thresh = 15; %inst_dir within this (degrees) of 0 or 360 is considered 'forward'
data.forward_rotation = DLC_forward_rotation(data, param.forward_rot_thresh,param); % extract forward rotation. 

walkingData = data(~isnan(data.walking_bout_number),:); 

% Organize data for plotting 
joint_data = DLC_org_joint_data_EvynData(data, param);
joint_data_byFly = DLC_org_joint_data_byFly_EvynData(data, param);

beginning_vars = who; 
initial_vars = who; 



%% PLOTS!!!
%%%%%%%%%%%
%% Plot all joints, all lasers, one leg 
leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};

% fig = figure;
fig = fullfig;
pltIdx = 0;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
       elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
       elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
       elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
       end
       %plot the data!
       for vid = 1:width(temp)
          d = temp{vid};
          d(end) = []; %evyn's data has 601 frames
          if height(d) == 600
            plot(param.x, d); 
          end
       end
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
       
      %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.06 sec');
       elseif pltIdx == 4
           title('0.09 sec');
       elseif pltIdx == 5
           title('0.18 sec');
       elseif pltIdx == 6
           title('0.32 sec');
       elseif pltIdx == 7
           title('0.72 sec');
       elseif pltIdx == 8  
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 15
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 22
           ylabel(['TiTa (' char(176) ')']);
       end
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, param.darkFig, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Raw Joint Angles');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_overview'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
  
clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot all joints, all lasers, one leg - DENSITY PLOT (not great)
leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};

% fig = figure;
fig = fullfig;
pltIdx = 0;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
       elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
       elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
       elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
       end
       %plot the data!
       all_data = NaN(width(temp), param.vid_len_f);
       for vid = 1:width(temp)
          d = temp{vid};
          d(end) = []; %evyn's data has 601 frames
          if height(d) == 600
            all_data(vid,:) = d; 
            %plot(param.x, d); 
          end
       end
       %find num points in angle bins across time for plotting
       binWidth = 5; %num degrees per bin 
       binEdges = (0:binWidth:180);
       numBins = width(binEdges)-1;
       data2plot = zeros(numBins,600);
       
       
       binning = discretize(all_data, binEdges);
       binned = histcounts(all_data, binEdges);
       
       for t = 1:600
           data2plot(:,t) = histcounts(all_data(:,t), binEdges);
       end
               
               
       scatter_x = repmat(param.x, 1, numBins);
       scatter_y = repmat(binEdges(2:end), 1, 600);
       scatter(scatter_x, scatter_y, [10], data2plot(:), 'filled');
       
%        scatter(scatter_x, all_data(:)); 
%        hist3([scatter_x.', all_data(:)]);
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
       
      %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.06 sec');
       elseif pltIdx == 4
           title('0.09 sec');
       elseif pltIdx == 5
           title('0.18 sec');
       elseif pltIdx == 6
           title('0.32 sec');
       elseif pltIdx == 7
           title('0.72 sec');
       elseif pltIdx == 8  
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 15
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 22
           ylabel(['TiTa (' char(176) ')']);
       end
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, param.darkFig, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Raw Joint Angles');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_overview'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
  
clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot all joints, all lasers, one leg -- mean & sem 

leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};
fig = fullfig;
pltIdx = 0;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
       elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
       elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
       elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
       end
       %plot the data!
       all_data = NaN(width(temp), param.vid_len_f);
       for vid = 1:width(temp) %CHANGE when plotting days 
          d = temp{vid};
          d(end)=[];%evyn's data has 601 frames, eliminate one from the end
          if height(d) == 600 
%               a = d(param.laser_on);
%               d = d-a; 
              all_data(vid, :) = d;
          end
       end
       %calculate mean and standard error of the mean 
       yMean = nanmean(all_data, 1);
       ySEM = sem(all_data, 1, nan, height(flyList));
       
       %plot
       plot(param.x, yMean, 'color', Color(param.jointColors{joint}), 'linewidth', 1.5);
       fill_data = error_fill(param.x, yMean, ySEM);
       h = fill(fill_data.X, fill_data.Y, get_color(param.jointColors{joint}), 'EdgeColor','none');
       set(h, 'facealpha', param.jointFillWeights{joint});
       
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
        
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.06 sec');
       elseif pltIdx == 4
           title('0.09 sec');
       elseif pltIdx == 5
           title('0.18 sec');
       elseif pltIdx == 6
           title('0.32 sec');
       elseif pltIdx == 7
           title('0.72 sec');
       elseif pltIdx == 8  
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 15
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 22
           ylabel(['TiTa (' char(176) ')']);
       end
       
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [legs{leg} ' Aligned Joint Angle Mean & SEM']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_overview_mean&SEM'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot all joints, all lasers, one leg -- subtract baseline angle 
leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};

fig = fullfig;
pltIdx = 0;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
       elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
       elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
       elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
       end
       %plot the data!
       for vid = 1:width(temp)
          d = temp{vid};
          d(end) = []; %evyn's data has 601 frames
          if height(d) == 600
              a = d(param.laser_on);
              d = d-a;
              plot(param.x, d); 
          end
       end
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
       
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.06 sec');
       elseif pltIdx == 4
           title('0.09 sec');
       elseif pltIdx == 5
           title('0.18 sec');
       elseif pltIdx == 6
           title('0.32 sec');
       elseif pltIdx == 7
           title('0.72 sec');
       elseif pltIdx == 8  
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 15
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 22
           ylabel(['TiTa (' char(176) ')']);
       end
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, 'L1 Aligned Joint Angles');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_overview_aligned'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot all joints, all lasers, one leg -- subtract baseline angle -- mean & sem 

leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};
fig = fullfig;
pltIdx = 0;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
       elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
       elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
       elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
       end
       %plot the data!
       all_data = NaN(width(temp), param.vid_len_f);
       for vid = 1:width(temp) %CHANGE when plotting days 
          d = temp{vid};
          d(end)=[];%evyn's data has 601 frames, eliminate one from the end
          if height(d) == 600 
              a = d(param.laser_on);
              d = d-a; 
              all_data(vid, :) = d;
%               plot(param.x, d); 
          end
       end
%        fprintf(['\n' num2str(height(all_data))]);
       %calculate mean and standard error of the mean 
       yMean = nanmean(all_data, 1);
       ySEM = sem(all_data, 1, nan, height(flyList));
       
       %plot
       plot(param.x, yMean, 'color', Color(param.jointColors{joint}), 'linewidth', 1.5);
       fill_data = error_fill(param.x, yMean, ySEM);
       h = fill(fill_data.X, fill_data.Y, get_color(param.jointColors{joint}), 'EdgeColor','none');
       set(h, 'facealpha', param.jointFillWeights{joint});
       
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
        
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.06 sec');
       elseif pltIdx == 4
           title('0.09 sec');
       elseif pltIdx == 5
           title('0.18 sec');
       elseif pltIdx == 6
           title('0.32 sec');
       elseif pltIdx == 7
           title('0.72 sec');
       elseif pltIdx == 8  
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 15
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 22
           ylabel(['TiTa (' char(176) ')']);
       end
       
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, false, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [legs{leg} ' Aligned Joint Angle Mean & SEM']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_overview_mean&SEM_aligned'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot all joints, all lasers, one leg -- mean ANGLE CHANGE 
leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};

fig = fullfig;
pltIdx = 0;
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
       elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
       elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
       elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
       end
       %plot the data!
       for vid = 1:width(temp)
          d = temp{vid};
          all_data(vid, :) = diff(d);
          plot(param.x(1:end), diff(d)); 
       end
       
       %calculate mean and standard error of the mean 
       yMean = nanmean(all_data, 1);
%        plot(param.x(1:end), yMean); 
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % plot laser region 
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.1 sec');
       elseif pltIdx == 4
           title('0.33 sec');
       elseif pltIdx == 5    
           title('1 sec');
       elseif pltIdx == 6
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 11
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 16
            ylabel(['TiTa (' char(176) ')']);
       end
   end
end

fig = formatFig(fig, true, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Joint Angle Change');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))


hold off;

fig_name = ['\' param.legs{leg} '_overview_angleChange'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot all legs, all lasers, one joint -- subtract baseline angle 
joint = param.joints{listdlg('ListString', param.joints, 'PromptString','Select laser:', 'SelectionMode','single', 'ListSize', [100 100])};

fig = fullfig;
pltIdx = 0;
AX = [];
for laser = 1:param.numLasers
    light_on = 0;
    light_off =(param.fps*param.lasers{laser})/param.fps;
   for leg = 1:param.numLegs
       pltIdx = pltIdx+1;
       AX(pltIdx) = subplot(param.numLasers, param.numLegs, pltIdx); hold on;
       %extract the joint data 
       if strcmp(joint, 'BC')
           temp = joint_data.leg(leg).laser(laser).BC.joint;      
       elseif strcmp(joint, 'CF')
           temp = joint_data.leg(leg).laser(laser).CF.joint;      
       elseif strcmp(joint, 'FTi')
           temp = joint_data.leg(leg).laser(laser).FTi.joint;      
       elseif strcmp(joint, 'TiTa')
           temp = joint_data.leg(leg).laser(laser).TiTa.joint;      
       end       %plot the data!
       for vid = 1:width(temp)
          d = temp{vid};
          d(end) = [];
          a = d(param.laser_on);
          d = d-a;
          plot(param.x, d); 
       end
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
          
       %label
       if pltIdx == 1
           ylabel('0 sec');
           xlabel('Time (s)');
           title('L1');
       elseif pltIdx == 2
           title('L2');
       elseif pltIdx == 3
           title('L3');
       elseif pltIdx == 4
           title('R1');
       elseif pltIdx == 5    
           title('R2');
       elseif pltIdx == 6
           title('R3');
       elseif pltIdx == 7
           ylabel('0.03 sec');
       elseif pltIdx == 13
           ylabel('0.06 sec');
       elseif pltIdx == 19
            ylabel('0.09 sec');
       elseif pltIdx == 25
            ylabel('0.18 sec');         
       elseif pltIdx == 31
            ylabel('0.32 sec');    
       elseif pltIdx == 37
            ylabel('0.72 sec');    
       end
       
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numLasers, param.numLegs, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.numLasers, param.numLegs]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [joint ' Aligned Joint Angles']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' joint '_overview_aligned'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot all legs, all lasers, one joint -- subtract baseline angle -- mean & sem 
joint = param.joints{listdlg('ListString', param.joints, 'PromptString','Select laser:', 'SelectionMode','single', 'ListSize', [100 100])};

fig = fullfig;
pltIdx = 0;
AX = [];
for laser = 1:param.numLasers
    light_on = 0;
    light_off =(param.fps*param.lasers{laser})/param.fps;
   for leg = 1:param.numLegs
       pltIdx = pltIdx+1;
       AX(pltIdx) = subplot(param.numLasers, param.numLegs, pltIdx); hold on;
       %extract the joint data 
       if strcmp(joint, 'BC')
           temp = joint_data.leg(leg).laser(laser).BC.joint;      
       elseif strcmp(joint, 'CF')
           temp = joint_data.leg(leg).laser(laser).CF.joint;      
       elseif strcmp(joint, 'FTi')
           temp = joint_data.leg(leg).laser(laser).FTi.joint;      
       elseif strcmp(joint, 'TiTa')
           temp = joint_data.leg(leg).laser(laser).TiTa.joint;      
       end       %plot the data!
       all_data = NaN( width(temp), param.vid_len_f);
       for vid = 1:width(temp)
          d = temp{vid};
          d(end) = []; %evyn's data is 601 frames
          if height(d) == 600
              a = d(param.laser_on);
              d = d-a;
              all_data(vid, :) = d;
          end
       end
       %calculate mean and standard error of the mean 
       yMean = nanmean(all_data, 1);
       ySEM = sem(all_data, 1, nan, height(flyList));
       
       %plot
       plot(param.x, yMean, 'color', Color(param.jointColors{find(contains(param.joints, joint))}), 'linewidth', 1.5);
       fill_data = error_fill(param.x, yMean, ySEM);
       h = fill(fill_data.X, fill_data.Y, get_color(param.jointColors{find(contains(param.joints, joint))}), 'EdgeColor','none');
       set(h, 'facealpha', param.jointFillWeights{find(contains(param.joints, joint))});
       
      
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
       
       %label
       if pltIdx == 1
           ylabel('0 sec');
           xlabel('Time (s)');
           title('L1');
       elseif pltIdx == 2
           title('L2');
       elseif pltIdx == 3
           title('L3');
       elseif pltIdx == 4
           title('R1');
       elseif pltIdx == 5    
           title('R2');
       elseif pltIdx == 6
           title('R3');
       elseif pltIdx == 7
           ylabel('0.03 sec');
       elseif pltIdx == 13
           ylabel('0.06 sec');
       elseif pltIdx == 19
            ylabel('0.09 sec');
       elseif pltIdx == 25
            ylabel('0.18 sec');         
       elseif pltIdx == 31
            ylabel('0.32 sec');    
       elseif pltIdx == 37
            ylabel('0.72 sec');    
       end
       
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numLasers, param.numLegs, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.numLasers, param.numLegs]);
 
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [joint ' Aligned Joint Angle Mean & SEM']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' joint '_overview_mean&SEM_aligned'];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;




%% PLOT CONTROL LASER VS EXP LASER -- subtract baseline angle -- mean & sem

exp_laser = 0.3600;
ctl_laser = 0;

leg = 1; 
joint = 3;
joint_str = [param.legs{leg}, '_', param.joints{joint}];

exp_data = data(data.stimlen == exp_laser,:);
ctl_data = data(data.stimlen == ctl_laser,:);
% 
% temp = double(diff(exp_data.fnum)*-1);
% [~,loc] = findpeaks(temp);
% exp_vid_idxs = [1;loc;height(temp)+1]; %a vid start is num, that vid end is next num -1
% temp = double(diff(ctl_data.fnum)*-1);
% [~,loc] = findpeaks(temp);
% ctl_vid_idxs = [;loc;height(temp)+1]; %a vid start is num, that vid end is next num -1

exp_vid_starts = find(exp_data.fnum == 0); 
exp_vid_ends = find(exp_data.fnum == 600); 

ctl_vid_starts = find(ctl_data.fnum == 0); 
ctl_vid_ends = find(ctl_data.fnum == 600); 


ctl_data_aligned = NaN(height(ctl_vid_starts), param.vid_len_f);
exp_data_aligned = NaN(height(exp_vid_starts), param.vid_len_f);
for vid = 1:height(ctl_vid_starts)-1
    ctl_data_aligned(vid,:) = ctl_data.(joint_str)(ctl_vid_starts(vid)+1:ctl_vid_ends(vid)) - ctl_data.(joint_str)(ctl_vid_starts(vid)+1+param.laser_on);
end
for vid = 1:height(exp_vid_starts)-1
    exp_data_aligned(vid,:) = exp_data.(joint_str)(exp_vid_starts(vid)+1:exp_vid_ends(vid)) - exp_data.(joint_str)(exp_vid_starts(vid)+1+param.laser_on);
end

numFlies = height(flyList);
numTrialsCtl = height(ctl_data_aligned);
numTrialsExp = height(exp_data_aligned);

ctl_mean = nanmean(ctl_data_aligned,1);
ctl_sem = sem(ctl_data_aligned, 1, nan, height(flyList));

exp_mean = nanmean(exp_data_aligned,1);
exp_sem = sem(exp_data_aligned, 1, nan, height(flyList));



fig = fullfig; hold on

%plot laser
laser_off = param.laser_on + (exp_laser * param.fps);
y1 = rangeLine(fig);
x_points = [param.laser_on, param.laser_on, laser_off, laser_off];  
% y_points = [20, 120, 120, 20];
y_points = [-20, 20, 20, -20];
color = Color(param.laserColor);
a = fill(x_points, y_points, color);
a.FaceAlpha = 0.7;
a.EdgeColor = 'none';

%plot ctl
plot(ctl_mean, 'color', Color('black'), 'linewidth', 1.5); 
fill_data = error_fill([1:600], ctl_mean, ctl_sem);
h = fill(fill_data.X, fill_data.Y, get_color('black'), 'EdgeColor','none');
set(h, 'facealpha', param.jointFillWeights{joint});

%plot exp
plot(exp_mean, 'color', Color(param.jointColors{joint}), 'linewidth', 1.5);
fill_data = error_fill([1:600], exp_mean, exp_sem);
h = fill(fill_data.X, fill_data.Y, get_color(param.jointColors{joint}), 'EdgeColor','none');
set(h, 'facealpha', param.jointFillWeights{joint});


ylim([-30, 30]);
xticks([0, 150, 300, 450, 600]);
xticklabels({'-0.5', '0', '', '1', ''});

hold off

fig = formatFig(fig, false);


%save 
fig_name = ['\' joint_str '_Mean&SEM_' num2str(ctl_laser) '-laser_vs_' num2str(exp_laser) '-laser']; 
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


clearvars('-except',initial_vars{:}); initial_vars = who;

%% PLOT single trace of one leg + joint angle
leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};
joint = 3; 
fly = '2_0';
date = '11.20.19';
rep = 1;
cond = 6;

this_vid_idxs = strcmpi(data.fly, fly) & strcmpi(data.date_parsed, date) & data.rep == rep & data.condnum == cond;
joint_str = [leg_str '_' param.joints{joint}];

% fig = figure;
fig = fullfig; hold on 

%plot laser
laser_off = param.laser_on + (param.allLasers(cond) * param.fps);
y1 = rangeLine(fig);
x_points = [param.laser_on, param.laser_on, laser_off, laser_off];  
y_points = [20, 120, 120, 20];
color = Color(param.laserColor);
a = fill(x_points, y_points, color);
a.FaceAlpha = 0.7;
a.EdgeColor = 'none';

%plot data
plot(data.(joint_str)(this_vid_idxs), 'linewidth', 2, 'color', Color(param.expColor)); 
axis tight
ylim([20 130]);
xlim([1 400]);
xticks([1, 150, 300]);
xticklabels({-0.5, 0, 0.5});
hold off

fig = formatFig(fig, false);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Raw Joint Angles');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

%save 
fig_name = ['\SingleTrace_' joint_str '_' date '_fly' fly '_R' num2str(rep) 'C' num2str(cond)];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);



%% Get behaviors of each fly 
param.thresh = 0.1; %0.5; %threshold for behavior prediction 
behavior = DLC_behavior_predictor(data, param); 
behavior_byBout = DLC_behavior_predictor_byBoutNum (data, param);

initial_vars = who;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% Behaviors %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Behavior breakdown - all data

behaviorColumns = find(contains(columns, 'number'));
behaviorData = table2array(data(:,behaviorColumns));
behaviorNums = sum(~isnan(behaviorData),1);

behaviorLabels = column_names(behaviorColumns);
behaviorLabels = cellfun(@(behaviorLabels) behaviorLabels(1:end-12), behaviorLabels, 'Uniform', 0);
displayedBehaviors = find(behaviorNums > 0);

% behaviorColors = parula(width(behaviorColumns));
fun = @sRGB_to_CAM02UCS; % default = UCS
behaviorColors = maxdistcolor(width(behaviorColumns),fun, 'sort', 'hue', 'Lmin',0.4, 'Lmax',0.6, 'exc',[0,0,0], 'Cmin',0.5, 'Cmax',0.6); % Exclude black (e.g. background).

fig = fullfig; 
p = pie(behaviorNums(displayedBehaviors), '%.2g%%'); %pie3 makes it 3D

%match colors to standardized colors
PatchArr = findobj(p, 'Type','patch');              % Find ‘Patch’ Objects
for bb = 1:width(displayedBehaviors)
    bb_idx = displayedBehaviors(bb);
    PatchArr(bb).FaceColor = behaviorColors(bb_idx,:);  
end
    
%add percentage text
pText = findobj(p,'Type','text');
pColor = findobj(p,'Type', 'color');
for txt = 1:length(pText)
    thisTxt = pText(txt);
    thisTxt.Color = param.baseColor;
    thisTxt.FontSize = 20;
end
fig = formatFig(fig, true);

%delete percent values <1 so they don't overlap
pText = findobj(p,'Type','text');
isSmall = startsWith({pText.String}, '<');  
delete(pText(isSmall));
title('Behavior of all data', 'FontSize', 30);

lgd = legend(behaviorLabels(displayedBehaviors), 'Location', 'eastoutside', 'TextColor', param.baseColor, 'FontSize', 20);
lgd.Position(1) = 0.75;

%save
fig_name = ['\Behavior_Breakdown_AllData'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
clearvars('-except',initial_vars{:}); initial_vars = who;

 %% Behavior breakdown - by fly

plotting = numSubplots(height(flyList)+1);
fig = fullfig; 

behaviorColumns = find(contains(columns, 'number'));
behaviorLabels = column_names(behaviorColumns);
behaviorLabels = cellfun(@(behaviorLabels) behaviorLabels(1:end-12), behaviorLabels, 'Uniform', 0);

% behaviorColors = parula(width(behaviorColumns));
fun = @sRGB_to_CAM02UCS; % default = UCS
behaviorColors = maxdistcolor(width(behaviorColumns),fun, 'sort', 'hue', 'Lmin',0.4, 'Lmax',0.6, 'exc',[0,0,0], 'Cmin',0.5, 'Cmax',0.6); % Exclude black (e.g. background).


for fly = 1:height(flyList)
    subplot(plotting(1), plotting(2), fly);
    behaviorData = table2array(data((strcmpi(data.fly, flyList{fly,1}) & strcmpi(data.date_parsed, flyList{fly,2})),behaviorColumns));
    behaviorNums = sum(~isnan(behaviorData),1);
    displayedBehaviors = find(behaviorNums > 0);
    
    p = pie(behaviorNums(displayedBehaviors), '%.2g%%'); %pie3 makes it 3D
    
    %match colors across fly pie charts 
    PatchArr = findobj(p, 'Type','patch');              % Find ‘Patch’ Objects
    for bb = 1:width(displayedBehaviors)
        bb_idx = displayedBehaviors(bb);
        PatchArr(bb).FaceColor = behaviorColors(bb_idx,:);  
    end
    
    %add percentage text
    pText = findobj(p,'Type','text');
    pColor = findobj(p,'Type', 'color');
    for txt = 1:length(pText)
        thisTxt = pText(txt);
        thisTxt.Color = param.baseColor;
        thisTxt.FontSize = 20;
    end
    
    %delete percent values <1 so they don't overlap
    pText = findobj(p,'Type','text');
    isSmall = startsWith({pText.String}, '<');  
    delete(pText(isSmall));
    %only keep values with 2 chars
    pText = findobj(p,'Type','text');
    L = cellfun(@length, {pText.String});
    isMedium = (L == 2);
    delete(pText(isMedium));
    %delete values with a dot (smaller values)    
    pText = findobj(p,'Type','text');
    hasDot = contains({pText.String}, '.');  
    delete(pText(hasDot));
    
    t = title(strcat("Fly ", strrep(flyList{fly,1}, '_', '-'), " from ", flyList{fly,2}), 'FontSize', 30, 'Position', [0, 1.5]);
end
subplot(plotting(1), plotting(2), fly+1);
p = pie(zeros(1,width(behaviorLabels)));
PatchArr = findobj(p, 'Type','patch');              % Find ‘Patch’ Objects
for bb = 1:width(behaviorLabels)
    bb_idx = bb;
    PatchArr(bb).FaceColor = behaviorColors(bb_idx,:);  
end
fig = formatFig(fig, true, plotting);
lgd = legend(behaviorLabels, 'Location', 'west', 'TextColor', param.baseColor, 'FontSize', 20,  'NumColumns', 2);
% lgd.Position(1) = 0.7;
lgd.Position(2) = 0.1;

%save
fig_name = ['\Behavior_Breakdown_byFly'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% clearvars('-except',initial_vars{:}); initial_vars = who;

%% Select trials by BEHAVIOR 

clearvars('-except',initial_vars{:});

behaviors = {'Walking' 'Stationary' 'Any'};
preBehavior = behaviors{listdlg('ListString', behaviors, 'PromptString','Pre-stim behavior:', 'SelectionMode','single', 'ListSize', [100 100])};
postBehavior = behaviors{listdlg('ListString', behaviors, 'PromptString','Post-stim behavior:', 'SelectionMode','single', 'ListSize', [100 100])};

% preBehavior = 'Stationary'; % Options: 'Walking', 'Stationary', 'Any'
% postBehavior = 'Any'; % Options: 'Walking', 'Stationary', 'Any'
jointAngle = 'Any'; % Options: 'Obtuse', 'Acute', 'Any'

% Find indices in data for all vids where fly has desired behavior
[behaviordata, enough_vids] = DLC_selectBehaviorData(behavior, preBehavior, postBehavior, jointAngle); 
behaviorDataIdxs = DLC_selectBehaviorDataIdxs(behaviordata, enough_vids, param); 

initial_vars = who;

%% SELECTED BEHAVIOR: Plot all joints, all lasers, one leg -- subtract baseline angle -- mean & sem 
leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};

fig = fullfig;
pltIdx = 0;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; jnt = [leg_str '_BC'];
       elseif joint == 2; jnt = [leg_str '_CF'];
       elseif joint == 3; jnt = [leg_str '_FTi'];
       elseif joint == 4; jnt = [leg_str '_TiTa'];
       end
       jntIdx = find(contains(columns, jnt));

       %plot the data!
       all_data = NaN(height(behaviordata), param.vid_len_f);
       num_vids = 0;
       for vid = 1:height(behaviordata)
          if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
              num_vids = num_vids + 1;
              start_idx = behaviordata{vid,9};
              end_idx = behaviordata{vid,10};

              d = data{start_idx:end_idx, jntIdx};
              if height(d == 600)
                  a = d(param.laser_on);
                  d = d-a;
%                   plot(param.x,d);
                  all_data(vid, :) = d;
              end
          end
       end
       numVids(joint, laser) = num_vids;
       %calculate mean and standard error of the mean 
       yMean = nanmean(all_data, 1);
       ySEM = sem(all_data, 1, nan, height(flyList));
       
       %plot
       plot(param.x, yMean, 'color', Color(param.jointColors{joint}), 'linewidth', 1.5);
       fill_data = error_fill(param.x, yMean, ySEM);
       h = fill(fill_data.X, fill_data.Y, get_color(param.jointColors{joint}), 'EdgeColor','none');
       set(h, 'facealpha',param.jointFillWeights{joint});
       
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
        
              %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.06 sec');
       elseif pltIdx == 4
           title('0.09 sec');
       elseif pltIdx == 5
           title('0.18 sec');
       elseif pltIdx == 6
           title('0.32 sec');
       elseif pltIdx == 7
           title('0.72 sec');
       elseif pltIdx == 8  
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 15
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 22
           ylabel(['TiTa (' char(176) ')']);
       end
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Aligned Joint Angle Mean & SEM');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_overview_mean&SEM_aligned_' preBehavior '2' postBehavior];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot all joints, all lasers, one leg 
leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};

% fig = figure;
fig = fullfig;
pltIdx = 0;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; jnt = [leg_str '_BC'];
       elseif joint == 2; jnt = [leg_str '_CF'];
       elseif joint == 3; jnt = [leg_str '_FTi'];
       elseif joint == 4; jnt = [leg_str '_TiTa'];
       end
       jntIdx = find(contains(columns, jnt));
       
       
       %plot the data!
       for vid = 1:height(behaviordata)
          if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
              start_idx = behaviordata{vid,9};
              end_idx = behaviordata{vid,10};

              vid_data = data{start_idx:end_idx, jntIdx};
              if height(vid_data == 600)
                plot(param.x, vid_data); 
              end
          end
       end
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
       
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.06 sec');
       elseif pltIdx == 4
           title('0.09 sec');
       elseif pltIdx == 5
           title('0.18 sec');
       elseif pltIdx == 6
           title('0.32 sec');
       elseif pltIdx == 7
           title('0.72 sec');
       elseif pltIdx == 8  
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 15
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 22
           ylabel(['TiTa (' char(176) ')']);
       end
       
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, param.darkFig, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Raw Joint Angles');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_overview_' preBehavior '2' postBehavior];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Select regions where fly is walking during each vid
clearvars('-except',initial_vars{:});
% 
% %check for walking struct in folder and load, otherwise make it
% filename = [param.googledrivesave 'walking.mat'];
% if isfile(filename)
%    fprintf('\nLoading walking.m...\n');
%    load(filename);
% else 
    fprintf('\nPopulating walking.m...\n');
    %select walking bouts
    %walking = DLC_select_walking_bouts(data, behavior.data, behavior, param); %finds walking bouts (not probs) %behaviordata for just walking to walking data
    walking = DLC_select_walking_bouts(data, behavior_byBout.data, behavior_byBout, param); %finds walking bouts (not probs) %behaviordata for just walking to walking data

    %parse steps 
    walking = DLC_parse_steps(walking, param, 1); %1 to parse steps by max angle, -1 to parse by min angle
%     
%     %save walking and steps structs
%     fprintf('\nSaving walking.m...\n');
%     save(filename, 'walking', '-v7.3');
% end

%format steps to make plotting easier
steps = DLC_format_steps(walking); 

initial_vars = who;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% Joint x Phase %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ORGANIZE DATA: joint data during steps as fn of phase
% Exp datapoints are only those that occur during stim
% This answers the question: does the actual stim itself shift the
%   joint angle across all parts of the step cycle or just parts. It's a
%   more specific plot than the one above, because exp datapoints are more
%   conservatively chosen. 
clearvars('-except',initial_vars{:});

XFrames = 100; %The number of frames post stim onset to include in the withinXFrames column (column 4) of ctl_data and exp_data
myPhase = 0; %1=use my phase calculation that aligns peaks, 0=use hilbert transform.
oversample = 0; interpFactor = 4; %oversample=1 oversamples the angle and phase data by a factor of interpFactor

clear exp_data ctl_data
for leg = 1:6
    for joint = 1:4
        %get data
        %ctl
        ctl_joint = steps.control.leg{leg}.joint{joint};
        
%         ctl_jointRateOfChange = steps.control.leg{leg}.jointRateOfChange{joint};
%         ctl_jointRateOfChange(end+1,:) = NaN;
        
        jnt = find(contains(steps.control.leg{leg}.phase_labels, param.joints{joint}));
        if myPhase; ctl_phase = steps.control.leg{leg}.myPhase{jnt};
        else; ctl_phase = steps.control.leg{leg}.phase{jnt}; end
        
        %oversample each step if indicated
        if oversample
            cj_temp = NaN(height(ctl_joint), (width(ctl_joint)*interpFactor));
            cp_temp = NaN(height(ctl_phase), (width(ctl_phase)*interpFactor));
            for i = 1:height(cj_temp)
               %skip if not at least 9 datapoints (needed for interp fn)
               cj_not_nans = ~isnan(ctl_joint(i,:)); 
               cp_not_nans = ~isnan(ctl_phase(i,:));    
               if sum(cj_not_nans)>=9 & sum(cp_not_nans)>= 9
                   %leg data
                   cj_interp = interp (ctl_joint(i,cj_not_nans), interpFactor);
                   cj_temp(i,:) = [cj_interp, NaN(1,width(cj_temp)-width(cj_interp))];
                   %phase
                   cp_interp = interp(ctl_phase(i,cp_not_nans), interpFactor);
                   cp_temp(i,:) = [cp_interp, NaN(1,width(cp_temp)-width(cp_interp))];
               end
            end
            ctl_joint = cj_temp;
            ctl_phase = cp_temp;
        end
                
        ctl_flies = [steps.control.leg{leg}.bout_meta(:).flyNum]';
        for i = 2:width(ctl_joint)
            ctl_flies(:,i) = ctl_flies(:,1);
        end
        ctl_withinXframes = DLC_withinXFrames(ctl_joint, steps.control.leg{leg}.step_meta, XFrames); %1=datapoint is within 50 frames after stim onset time, 0=it's not.
        
        %exp
        exp_joint = steps.experiment.leg{leg}.joint{joint};
                
%         exp_jointRateOfChange = steps.experiment.leg{leg}.jointRateOfChange{joint};
%         exp_jointRateOfChange(end+1,:) = NaN;
        
        jnt = find(contains(steps.experiment.leg{leg}.phase_labels, param.joints{joint}));
        if myPhase; exp_phase = steps.experiment.leg{leg}.myPhase{jnt};
        else; exp_phase = steps.experiment.leg{leg}.phase{jnt}; end
        exp_flies = [steps.experiment.leg{leg}.bout_meta(:).flyNum]';
        for i = 2:width(exp_joint)
            exp_flies(:,i) = exp_flies(:,1);
        end
        exp_withinXframes = DLC_withinXFrames(exp_joint, steps.experiment.leg{leg}.step_meta, XFrames); %1=datapoint is within 50 frames after stim onset time, 0=it's not.

        
        
        %format data from matrix to vector
        ctl_joint = ctl_joint(:);
        ctl_phase = ctl_phase(:);
        ctl_flies = ctl_flies(:);
        ctl_withinXframes = ctl_withinXframes(:);
%         ctl_jointRateOfChange = ctl_jointRateOfChange(:);
        
        exp_joint = exp_joint(:);
        exp_phase = exp_phase(:);
        exp_flies = exp_flies(:);
        exp_withinXframes = exp_withinXframes(:);
%         exp_jointRateOfChange = exp_jointRateOfChange(:);
        
        %delete rows where data = nan
        ctl_nan = find(isnan(ctl_joint));
        ctl_joint(ctl_nan,:) = [];
        ctl_phase(ctl_nan,:) = [];
        ctl_flies(ctl_nan,:) = [];
        ctl_withinXframes(ctl_nan,:) = [];
%         ctl_jointRateOfChange(ctl_nan,:) = [];

        exp_nan = find(isnan(exp_joint));
        exp_joint(exp_nan,:) = [];
        exp_phase(exp_nan,:) = [];
        exp_flies(exp_nan,:) = [];
        exp_withinXframes(exp_nan,:) = [];
%         exp_jointRateOfChange(exp_nan,:) = [];

        % Bin phase
        % ctl_phase = round(ctl_phase,2);
        % exp_phase = round(exp_phase,2);

        %save this leg+joint data
        ctl_data{leg, joint} = [ctl_joint, ctl_phase, ctl_flies, ctl_withinXframes];
        exp_data{leg, joint} = [exp_joint, exp_phase, exp_flies, exp_withinXframes];
    end
end
initial_vars{height(initial_vars)+1} = 'ctl_data';
initial_vars{height(initial_vars)+1} = 'exp_data';
initial_vars{height(initial_vars)+1} = 'XFrames';
initial_vars{height(initial_vars)+1} = 'myPhase';
clearvars('-except',initial_vars{:}); initial_vars = who;

%%
leg = 1; 
joint = 3;
% sigdig = 2; sigstep = 0.01; %sigstep should be rounded to sigdig
sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig

if sigdig == 1; dotSize = 20; elseif sigdig == 2; dotSize = 3; end

%% PLOT peaks and troughs... to test step alignment in the phase calculation

% leg = 1;
% joint = 3; 

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig; hold on
plotting.nRows = 1; 
plotting.nCols = 2; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

%control
subplot(plotting.nRows, plotting.nCols,1); 
[max_pks, max_locs, max_w, max_p] = findpeaks(ctl_data{leg,joint}(:,1),'MinPeakProminence',10);
[min_pks, min_locs, min_w, min_p] = findpeaks(ctl_data{leg,joint}(:,1)*-1,'MinPeakProminence',10);

% plot(ctl_data{leg,joint}(:,1)); hold on; scatter(max_locs,max_pks); hold off;

polarscatter(ctl_data{leg,joint}(max_locs,2), ctl_data{leg,joint}(max_locs,1), [3], ctl_data{leg,joint}(max_locs,3),'filled');

title('Peaks')
% pax = gca;
% pax.FontSize = 14;
% pax.RColor = Color(param.baseColor);
% pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45, 90,135, 180])
thetaticks([0, 90, 180, 270]);


%experimental
subplot(plotting.nRows, plotting.nCols,2); 
polarscatter(ctl_data{leg,joint}(min_locs,2), ctl_data{leg,joint}(min_locs,1), [3], ctl_data{leg,joint}(min_locs,3),'filled');
title('Troughs')
% pax = gca;
% pax.FontSize = 14;
% pax.RColor = [0.8, 0.8, 0.8];
% pax.ThetaColor = [0.8, 0.8, 0.8];
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' step peaks x phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' step peaks x phase'];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT peaks and troughs as DENSITY... to test step alignment in the phase calculation

% polarscatter(phase,joint,vector4size,vector4color,'filled');
% 
% leg = 1;
% joint = 3; 
smooth_avgs = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 1; 
plotting.nCols = 2; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 20; elseif sigdig == 2; dotSize = 3; end

[max_pks, max_locs, max_w, max_p] = findpeaks(ctl_data{leg,joint}(:,1),'MinPeakProminence',10);
[min_pks, min_locs, min_w, min_p] = findpeaks(ctl_data{leg,joint}(:,1)*-1,'MinPeakProminence',10);

max_phase_binned = round(ctl_data{leg,joint}(max_locs,2),sigdig);
min_phase_binned = round(ctl_data{leg,joint}(min_locs,2),sigdig);
max_joint =max_locs;
min_joint = ctl_data{leg,joint}(min_locs,1);
max_flies = ctl_data{leg,joint}(max_locs,3);
min_flies = ctl_data{leg,joint}(min_locs,3);




%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
angle_bins = [0:2:180];
%make a matrix of phase for plotting 
phase_matrix = phase_bins;
for b = 2:width(angle_bins)-1
   phase_matrix(:,end+1) = phase_bins;
end

max_byPhase = NaN(height(phase_bins), height(phase_bins));
max_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
max_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    max_idxs = find(max_phase_binned == phase_bins(ph));
    max_dataPerPhase(ph) = height(max_idxs); %how many data points per frame
    max_theseAngles = max_joint(max_idxs)';
    max_byPhase(ph,1:width(max_joint(max_idxs)')) = max_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(max_theseAngles > angle_bins(b) & max_theseAngles <= angle_bins(b+1));
       if isempty(count)
           max_anglePlot(ph,b) = NaN;
           max_angleCount(ph,b) = NaN;
       else
           max_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           max_angleCount(ph,b) = sum(count);
       end
       
    end
end
max_mean = nanmean(max_byPhase,2);
max_sem = sem(max_byPhase, 2, nan, height(unique(max_flies)));


min_byPhase = NaN(height(phase_bins), height(phase_bins));
min_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
min_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    min_idxs = find(min_phase_binned == phase_bins(ph));
    min_dataPerPhase(ph) = height(min_idxs); %how many data points per frame
    min_theseAngles = min_joint(min_idxs)';
    min_byPhase(ph,1:width(min_joint(min_idxs)')) = min_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(min_theseAngles > angle_bins(b) & min_theseAngles <= angle_bins(b+1));
       if isempty(count)
           min_anglePlot(ph,b) = NaN;
           min_angleCount(ph,b) = NaN;
       else
           min_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           min_angleCount(ph,b) = sum(count);
       end
       
    end
end
min_mean = nanmean(min_byPhase,2);
min_sem = sem(min_byPhase, 2, nan, height(unique(ctl_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
% polarscatter(ctl_phase_binned, ctl_joint, [3], ctl_flies,'filled');
polarscatter(phase_matrix(:), ctl_anglePlot(:), [dotSize], ctl_angleCount(:),'filled');

title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


%color bar legend
 max_len = max(ctl_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(ctl_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
%   cb.Position = [0.35 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);


%minerimental
subplot(plotting.nRows, plotting.nCols,2); 
% polarscatter(min_phase_binned, min_joint, [3], min_flies,'filled');
polarscatter(phase_matrix(:), min_anglePlot(:), [dotSize], min_angleCount(:),'filled');

title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);



%color bar legend
 max_len = max(min_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(min_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
%   cb.Position = [0.63 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' step peaks x phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' step peaks x phase - density'];
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT Raw scatter, joint x phase for con and exp 

% leg = 1;
% joint = 3; 

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig; hold on
plotting.nRows = 1; 
plotting.nCols = 2; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

%control
subplot(plotting.nRows, plotting.nCols,1); 
polarscatter(ctl_data{leg,joint}(:,2), ctl_data{leg,joint}(:,1), [3], ctl_data{leg,joint}(:,3),'filled');
title('Control')
% pax = gca;
% pax.FontSize = 14;
% pax.RColor = Color(param.baseColor);
% pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45, 90,135, 180])
thetaticks([0, 90, 180, 270]);


%experimental
subplot(plotting.nRows, plotting.nCols,2); 
polarscatter(exp_data{leg,joint}(:,2), exp_data{leg,joint}(:,1), [3], exp_data{leg,joint}(:,3),'filled');
title('Experimental')
% pax = gca;
% pax.FontSize = 14;
% pax.RColor = [0.8, 0.8, 0.8];
% pax.ThetaColor = [0.8, 0.8, 0.8];
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase'];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase + mean (TODO sem) of exp and con data
% 
% leg = 1;
% joint = 3; 
smooth_avgs = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 1; 
plotting.nCols = 3; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

sigdig = 2; sigstep = 0.01; %sigstep should be rounded to sigdig
ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);

ctl_byPhase = NaN(height(phase_bins), height(phase_bins));
for ph = 1:height(phase_bins)
    ctl_idxs = find(ctl_phase_binned == phase_bins(ph));
    ctl_dataPerPhase(ph) = height(ctl_idxs); %how many data points per frame
    ctl_byPhase(ph,1:width(ctl_joint(ctl_idxs)')) = ctl_joint(ctl_idxs)';
end
ctl_mean = nanmean(ctl_byPhase,2);
ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));


exp_byPhase = NaN(height(phase_bins), height(phase_bins));
for ph = 1:height(phase_bins)
    exp_idxs = find(exp_phase_binned == phase_bins(ph));
    exp_dataPerPhase(ph) = height(exp_idxs); %how many data points per frame
    exp_byPhase(ph,1:width(exp_joint(exp_idxs)')) = exp_joint(exp_idxs)';
end
exp_mean = nanmean(exp_byPhase,2);
exp_sem = sem(exp_byPhase, 2, nan, height(unique(ctl_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
polarscatter(ctl_phase_binned, ctl_joint, [3], ctl_flies,'filled');
title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


%experimental
subplot(plotting.nRows, plotting.nCols,2); 
polarscatter(exp_phase_binned, exp_joint, [3], exp_flies,'filled');
title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%averages
subplot(plotting.nRows, plotting.nCols, 3);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
hold on
polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
if smooth_avgs
    title('Smoothed Averages');
else
    title('Averages');
end
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
% rlim([0 180])
% rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned+means'];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase + mean (TODO sem) of exp and con data - GRAND MEAN
% 
% leg = 1;
% joint = 3;  
smooth_avgs = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 1; 
plotting.nCols = 3; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 20; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
%control
for f = 1:param.numFlies
    ctl_byPhase = NaN(height(phase_bins), 5000);
    this_fly_idxs = find(ctl_flies == f);
    this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
    this_fly_joint = ctl_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
        ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
        if height(ctl_idxs) >= 1
            % enough data points to have a good average, so save data
            ctl_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = this_fly_joint(ctl_idxs)';
        end
    end
    ctl_means(:,f) = nanmean(ctl_byPhase,2);
    ctl_sems(:,f) = sem(ctl_byPhase, 2, nan, 1);
    ctl_fly_phase_binned{f} = this_fly_phase_binned;
    ctl_fly_joint{f} = this_fly_joint;
end
%take the grand mean (mean of fly means)
ctl_mean = nanmean(ctl_means,2);
ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%experimental
for f = 1:param.numFlies
    exp_byPhase = NaN(height(phase_bins), 5000);
    this_fly_idxs = find(exp_flies == f);
    this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
    this_fly_joint = exp_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
        exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
        if height(exp_idxs) >= 1
            % enough data points to have a good average, so save data
            exp_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = this_fly_joint(exp_idxs)';
        end
    end
    exp_means(:,f) = nanmean(exp_byPhase,2);
    exp_sems(:,f) = sem(exp_byPhase, 2, nan, 1);
    exp_fly_phase_binned{f} = this_fly_phase_binned;
    exp_fly_joint{f} = this_fly_joint;
end
%take the grand mean (mean of fly means)
exp_mean = nanmean(exp_means,2);
exp_sem = sem(exp_byPhase, 2, nan, height(unique(exp_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
polarscatter(ctl_phase_binned, ctl_joint, [dotSize], ctl_flies,'filled');
title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%experimental
subplot(plotting.nRows, plotting.nCols,2); 
polarscatter(exp_phase_binned, exp_joint, [dotSize], exp_flies,'filled');
title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%averages
subplot(plotting.nRows, plotting.nCols, 3);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
hold on
polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
if smooth_avgs
    title('Smoothed Averages');
else
    title('Averages');
end
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
if param.sameAxes
    rlim([0 180])
    rticks([0,45,90,135,180])
end
thetaticks([0, 90, 180, 270]);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned+GRANDmeans'];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.sameAxes; fig_name = [fig_name, '_sameAxes']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase + mean (TODO sem) of exp and con data - GRAND MEAN & MEAN DIFFERENCE
% 
% leg = 1;
% joint = 3;  
smooth_avgs = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 2; 
plotting.nCols = 2; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 2; sigstep = 0.01; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 30; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
%control
for f = 1:param.numFlies
    ctl_byPhase = NaN(height(phase_bins), 50000);
    this_fly_idxs = find(ctl_flies == f);
    this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
    this_fly_joint = ctl_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
        ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
        if height(ctl_idxs) >= 1
            % enough data points to have a good average, so save data
            ctl_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = this_fly_joint(ctl_idxs)';
        end
    end
    ctl_means(:,f) = nanmean(ctl_byPhase,2);
    ctl_sems(:,f) = sem(ctl_byPhase, 2, nan, 1);
    ctl_fly_phase_binned{f} = this_fly_phase_binned;
    ctl_fly_joint{f} = this_fly_joint;
end
%take the grand mean (mean of fly means)
ctl_mean = nanmean(ctl_means,2);
ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%experimental
for f = 1:param.numFlies
    exp_byPhase = NaN(height(phase_bins), 50000);
    this_fly_idxs = find(exp_flies == f);
    this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
    this_fly_joint = exp_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
        exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
        if height(exp_idxs) >= 1
            % enough data points to have a good average, so save data
            exp_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = this_fly_joint(exp_idxs)';
        end
    end
    exp_means(:,f) = nanmean(exp_byPhase,2);
    exp_sems(:,f) = sem(exp_byPhase, 2, nan, 1);
    exp_fly_phase_binned{f} = this_fly_phase_binned;
    exp_fly_joint{f} = this_fly_joint;
end
%take the grand mean (mean of fly means)
exp_mean = nanmean(exp_means,2);
exp_sem = sem(exp_byPhase, 2, nan, height(unique(exp_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
polarscatter(ctl_phase_binned, ctl_joint, [dotSize], ctl_flies,'filled');
title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%experimental
subplot(plotting.nRows, plotting.nCols,2); 
polarscatter(exp_phase_binned, exp_joint, [dotSize], exp_flies,'filled');
title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%averages
subplot(plotting.nRows, plotting.nCols, 3);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
hold on
polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
if smooth_avgs
    title('Smoothed Averages');
else
    title('Averages');
end
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
% rlim([0 180])
% rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);



%mean difference
subplot(plotting.nRows, plotting.nCols, 4);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
mean_diff = ctl_mean - exp_mean;
ydata = phase_bins; %todo add 2pi to negative vals to match polar plot labels 

polarplot(phase_bins, mean_diff, 'color', '#ff8b3d', 'lineWidth', 2);
title('Mean difference (ctl-exp)');
pax = gca;
pax.FontSize = 14;
% pax.RColor = Color(param.baseColor);
% pax.ThetaColor = Color(param.baseColor);
rlim([-50 50])
% % rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned+GRANDmeans+meanDIFFERENCE'];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


%plot just the mean difference in it's own figure 
fig = fullfig;
neg_phase = phase_bins < 0;
pos_phase = phase_bins >= 0;
new_phase_bins = [phase_bins(pos_phase); phase_bins(neg_phase)];
neg_new_phase = new_phase_bins < 0;
new_phase_bins(neg_new_phase) = new_phase_bins(neg_new_phase) + (2*pi);
new_mean_diff = [mean_diff(pos_phase); mean_diff(neg_phase)];
plot(new_phase_bins, new_mean_diff, 'color', '#ff8b3d', 'lineWidth', 2);
hold on
plot(new_phase_bins, smooth(new_mean_diff), 'color', Color(param.baseColor), 'lineWidth', 2)
title('Mean difference (ctl-exp)');
pax = gca;
pax.FontSize = 14;
ylim([-50 50]);
xlim([0 (2*pi)]);
xticks([0 pi/2 pi 3*pi/2 2*pi])
xticklabels({'0','\pi/2','\pi','3\pi/2','2\pi'})

fig = formatFig(fig, true);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase - mean difference'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_meanDIFFERENCE'];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase + mean (TODO sem) of exp and con data - GRAND MEAN - only first X frames post stim onset
% 
% leg = 1;
% joint = 3;  
smooth_avgs = 0;
ctl_onlyWithinXFrames = 0; %1= ctl frames are also only those within 150 - 150+X frames in video. 

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 1; 
plotting.nCols = 3; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 30; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);
ctl_withinXFrames = ctl_data{leg,joint}(:,4);
exp_withinXFrames = exp_data{leg,joint}(:,4);

%only keep datapoints that are within 50 frames of stim onset
if ctl_onlyWithinXFrames
    ctl_phase_binned = ctl_phase_binned(find(ctl_withinXFrames));
    ctl_joint = ctl_joint(find(ctl_withinXFrames));
    ctl_flies = ctl_flies(find(ctl_withinXFrames));
end
exp_phase_binned = exp_phase_binned(find(exp_withinXFrames));
exp_joint = exp_joint(find(exp_withinXFrames));
exp_flies = exp_flies(find(exp_withinXFrames));

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
%control
for f = 1:param.numFlies
    ctl_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(ctl_flies == f);
    this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
    this_fly_joint = ctl_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
        ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
        if height(ctl_idxs) >= 1
            % enough data points to have a good average, so save data
            ctl_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = this_fly_joint(ctl_idxs)';
        end
    end
    ctl_means(:,f) = nanmean(ctl_byPhase,2);
    ctl_sems(:,f) = sem(ctl_byPhase, 2, nan, 1);
    ctl_fly_phase_binned{f} = this_fly_phase_binned;
    ctl_fly_joint{f} = this_fly_joint;
end
%take the grand mean (mean of fly means)
ctl_mean = nanmean(ctl_means,2);
ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%experimental
for f = 1:param.numFlies
    exp_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(exp_flies == f);
    this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
    this_fly_joint = exp_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
        exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
        if height(exp_idxs) >= 1
            % enough data points to have a good average, so save data
            exp_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = this_fly_joint(exp_idxs)';
        end
    end
    exp_means(:,f) = nanmean(exp_byPhase,2);
    exp_sems(:,f) = sem(exp_byPhase, 2, nan, 1);
    exp_fly_phase_binned{f} = this_fly_phase_binned;
    exp_fly_joint{f} = this_fly_joint;
end
%take the grand mean (mean of fly means)
exp_mean = nanmean(exp_means,2);
exp_sem = sem(exp_byPhase, 2, nan, height(unique(exp_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
polarscatter(ctl_phase_binned, ctl_joint, [dotSize], ctl_flies,'filled');
title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%experimental
subplot(plotting.nRows, plotting.nCols,2); 
polarscatter(exp_phase_binned, exp_joint, [dotSize], exp_flies,'filled');
title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%averages
subplot(plotting.nRows, plotting.nCols, 3);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 3);
hold on
polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 3);
if smooth_avgs
    title('Smoothed Averages');
else
    title('Averages');
end
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
if param.sameAxes
    rlim([0 180])
    rticks([0,45,90,135,180])
end
thetaticks([0, 90, 180, 270]);


% 
% %mean difference
% subplot(plotting.nRows, plotting.nCols, 4);
% if smooth_avgs
%     ctl_mean_plot = smoothdata(ctl_mean);
%     exp_mean_plot = smoothdata(exp_mean);
% else
%     ctl_mean_plot = ctl_mean;
%     exp_mean_plot = exp_mean;
% end
% mean_diff = ctl_mean - exp_mean;
% ydata = phase_bins; %todo add 2pi to negative vals to match polar plot labels 
% 
% polarplot(phase_bins, mean_diff, 'color', '#ff8b3d', 'lineWidth', 2);
% title('Mean difference (ctl-exp)');
% pax = gca;
% pax.FontSize = 14;
% % pax.RColor = Color(param.baseColor);
% % pax.ThetaColor = Color(param.baseColor);
% rlim([-50 50])
% % % rticks([0,45,90,135,180])
% thetaticks([0, 90, 180, 270]);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase: ' num2str(XFrames) ' frames post stim onset'], 'color', Color(param.baseColor));
han.FontSize = 30;

if ctl_onlyWithinXFrames
    type_str = '_ofALLdata';
else
    type_str = '_ofEXPdata';
end

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned+GRANDmeans_OnlyFirst' num2str(XFrames) 'FramesPostStimOnset' type_str];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.sameAxes; fig_name = [fig_name, '_sameAxes']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase + mean (TODO sem) of exp and con data - GRAND MEAN & MEAN DIFFERENCE - only first X frames post stim onset
% 
% leg = 1;
% joint = 3;  
smooth_avgs = 0;
ctl_onlyWithinXFrames = 0; %1= ctl frames are also only those within 150 - 150+X frames in video. 

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 2; 
plotting.nCols = 2; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 2; sigstep = 0.01; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 30; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);
ctl_withinXFrames = ctl_data{leg,joint}(:,4);
exp_withinXFrames = exp_data{leg,joint}(:,4);

%only keep datapoints that are within 50 frames of stim onset
if ctl_onlyWithinXFrames
    ctl_phase_binned = ctl_phase_binned(find(ctl_withinXFrames));
    ctl_joint = ctl_joint(find(ctl_withinXFrames));
    ctl_flies = ctl_flies(find(ctl_withinXFrames));
end
exp_phase_binned = exp_phase_binned(find(exp_withinXFrames));
exp_joint = exp_joint(find(exp_withinXFrames));
exp_flies = exp_flies(find(exp_withinXFrames));

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
%control
for f = 1:param.numFlies
    ctl_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(ctl_flies == f);
    this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
    this_fly_joint = ctl_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
        ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
        if height(ctl_idxs) >= 1
            % enough data points to have a good average, so save data
            ctl_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = this_fly_joint(ctl_idxs)';
        end
    end
    ctl_means(:,f) = nanmean(ctl_byPhase,2);
    ctl_sems(:,f) = sem(ctl_byPhase, 2, nan, 1);
    ctl_fly_phase_binned{f} = this_fly_phase_binned;
    ctl_fly_joint{f} = this_fly_joint;
end
%take the grand mean (mean of fly means)
ctl_mean = nanmean(ctl_means,2);
ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%experimental
for f = 1:param.numFlies
    exp_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(exp_flies == f);
    this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
    this_fly_joint = exp_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
        exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
        if height(exp_idxs) >= 1
            % enough data points to have a good average, so save data
            exp_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = this_fly_joint(exp_idxs)';
        end
    end
    exp_means(:,f) = nanmean(exp_byPhase,2);
    exp_sems(:,f) = sem(exp_byPhase, 2, nan, 1);
    exp_fly_phase_binned{f} = this_fly_phase_binned;
    exp_fly_joint{f} = this_fly_joint;
end
%take the grand mean (mean of fly means)
exp_mean = nanmean(exp_means,2);
exp_sem = sem(exp_byPhase, 2, nan, height(unique(exp_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
polarscatter(ctl_phase_binned, ctl_joint, [dotSize], ctl_flies,'filled');
title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%experimental
subplot(plotting.nRows, plotting.nCols,2); 
polarscatter(exp_phase_binned, exp_joint, [dotSize], exp_flies,'filled');
title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%averages
subplot(plotting.nRows, plotting.nCols, 3);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 3);
hold on
polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 3);
if smooth_avgs
    title('Smoothed Averages');
else
    title('Averages');
end
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
if param.sameAxes
    rlim([0 180])
    rticks([0,45,90,135,180])
end
thetaticks([0, 90, 180, 270]);



%mean difference
subplot(plotting.nRows, plotting.nCols, 4);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
mean_diff = ctl_mean - exp_mean;
ydata = phase_bins; %todo add 2pi to negative vals to match polar plot labels 

polarplot(phase_bins, mean_diff, 'color', '#ff8b3d', 'lineWidth', 2);
title('Mean difference (ctl-exp)');
pax = gca;
pax.FontSize = 14;
% pax.RColor = Color(param.baseColor);
% pax.ThetaColor = Color(param.baseColor);
rlim([-50 50])
% % rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase: ' num2str(XFrames) ' frames post stim onset'], 'color', Color(param.baseColor));
han.FontSize = 30;

if ctl_onlyWithinXFrames
    type_str = '_ofALLdata';
else
    type_str = '_ofEXPdata';
end

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned+GRANDmeans+meanDIFFERENCE_OnlyFirst' num2str(XFrames) 'FramesPostStimOnset' type_str];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.sameAxes; fig_name = [fig_name, '_sameAxes']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


%plot just the mean difference in it's own figure 
fig = fullfig;
neg_phase = phase_bins < 0;
pos_phase = phase_bins >= 0;
new_phase_bins = [phase_bins(pos_phase); phase_bins(neg_phase)];
neg_new_phase = new_phase_bins < 0;
new_phase_bins(neg_new_phase) = new_phase_bins(neg_new_phase) + (2*pi);
new_mean_diff = [mean_diff(pos_phase); mean_diff(neg_phase)];
plot(new_phase_bins, new_mean_diff, 'color', '#ff8b3d', 'lineWidth', 2);
hold on
plot(new_phase_bins, smooth(new_mean_diff), 'color', Color(param.baseColor), 'lineWidth', 2)
title('Mean difference');
pax = gca;
pax.FontSize = 14;
ylim([-50 50]);
xlim([0 (2*pi)]);
xticks([0 pi/2 pi 3*pi/2 2*pi])
xticklabels({'0','\pi/2','\pi','3\pi/2','2\pi'})

fig = formatFig(fig, true);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase - mean difference: ' num2str(XFrames) ' frames post stim onset'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_meanDIFFERENCE_OnlyFirst50FramesPostStimOnset' type_str];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

 %% PLOT joint x phase, binned phase + mean (TODO sem) of exp and con data - BY FLY 
% 
% leg = 1;
% joint = 3; 
smooth_avgs = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 3; 
plotting.nCols = param.numFlies; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 15; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);

for f = 1:param.numFlies
    ctl_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(ctl_flies == f);
    this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
    this_fly_joint = ctl_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
        ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
        ctl_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = this_fly_joint(ctl_idxs)';
    end
    ctl_mean{f} = nanmean(ctl_byPhase,2);
    ctl_sem{f} = sem(ctl_byPhase, 2, nan, 1);
    ctl_fly_phase_binned{f} = this_fly_phase_binned;
    ctl_fly_joint{f} = this_fly_joint;
end

for f = 1:param.numFlies
    exp_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(exp_flies == f);
    this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
    this_fly_joint = exp_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
        exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
        exp_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = this_fly_joint(exp_idxs)';
    end
    exp_mean{f} = nanmean(exp_byPhase,2);
    exp_sem{f} = sem(exp_byPhase, 2, nan, 1);
    exp_fly_phase_binned{f} = this_fly_phase_binned;
    exp_fly_joint{f} = this_fly_joint;
end

%plot for each fly
idx = 0;
for fly = 1:param.numFlies
    %control
    idx = idx+1;
    this_fly_idxs = find(ctl_flies == fly);
    ss = subplot(plotting.nRows, plotting.nCols,idx);
    polarscatter(ctl_fly_phase_binned{fly}, ctl_fly_joint{fly}, [dotSize], Color(param.baseColor),'filled');
    title([char(param.flyList{fly,1}) ' fly ' char(strrep(param.flyList{fly,2}, '_', '-'))]);
    rlim([0 180])
    rticks([0,45,90,135,180])
    thetaticks([0, 90, 180, 270]);


    %experimental
    this_fly_idxs = find(exp_flies == fly);
    subplot(plotting.nRows, plotting.nCols,idx+param.numFlies); 
    polarscatter(exp_phase_binned(this_fly_idxs), exp_joint(this_fly_idxs), [dotSize], exp_flies(this_fly_idxs),'filled');
%     title('Experimental')
    rlim([0 180])
    rticks([0,45,90,135,180])
    thetaticks([0, 90, 180, 270]);

    %averages
    subplot(plotting.nRows, plotting.nCols, idx+param.numFlies+param.numFlies);
    if smooth_avgs
        ctl_mean_plot = smoothdata(ctl_mean{fly});
        exp_mean_plot = smoothdata(exp_mean{fly});
    else
        ctl_mean_plot = ctl_mean{fly};
        exp_mean_plot = exp_mean{fly};
    end
    polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
    hold on
    polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
%     if smooth_avgs
%         title('Smoothed Averages');
%     else
%         title('Averages');
%     end
%     pax = gca;
%     pax.FontSize = 14;
%     pax.RColor = Color(param.baseColor);
%     pax.ThetaColor = Color(param.baseColor);
if param.sameAxes
    rlim([0 180])
    rticks([0,45,90,135,180])
end
    thetaticks([0, 90, 180, 270]);

    hold off

end

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor), 'position', param.titlePosition);
han.FontSize = 20;




%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned+means_byFLY'];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.sameAxes; fig_name = [fig_name, '_sameAxes']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase, binned angle for con and exp
% polarscatter(phase,joint,vector4size,vector4color,'filled');
% 
% leg = 1;
% joint = 3; 
smooth_avgs = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 1; 
plotting.nCols = 2; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 20; elseif sigdig == 2; dotSize = 3; end
ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
angle_bins = [0:2:180];
%make a matrix of phase for plotting 
phase_matrix = phase_bins;
for b = 2:width(angle_bins)-1
   phase_matrix(:,end+1) = phase_bins;
end

ctl_byPhase = NaN(height(phase_bins), height(phase_bins));
ctl_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
ctl_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    ctl_idxs = find(ctl_phase_binned == phase_bins(ph));
    ctl_dataPerPhase(ph) = height(ctl_idxs); %how many data points per frame
    ctl_theseAngles = ctl_joint(ctl_idxs)';
    ctl_byPhase(ph,1:width(ctl_joint(ctl_idxs)')) = ctl_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(ctl_theseAngles > angle_bins(b) & ctl_theseAngles <= angle_bins(b+1));
       if isempty(count)
           ctl_anglePlot(ph,b) = NaN;
           ctl_angleCount(ph,b) = NaN;
       else
           ctl_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           ctl_angleCount(ph,b) = sum(count);
       end
       
    end
end
ctl_mean = nanmean(ctl_byPhase,2);
ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));


exp_byPhase = NaN(height(phase_bins), height(phase_bins));
exp_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
exp_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    exp_idxs = find(exp_phase_binned == phase_bins(ph));
    exp_dataPerPhase(ph) = height(exp_idxs); %how many data points per frame
    exp_theseAngles = exp_joint(exp_idxs)';
    exp_byPhase(ph,1:width(exp_joint(exp_idxs)')) = exp_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(exp_theseAngles > angle_bins(b) & exp_theseAngles <= angle_bins(b+1));
       if isempty(count)
           exp_anglePlot(ph,b) = NaN;
           exp_angleCount(ph,b) = NaN;
       else
           exp_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           exp_angleCount(ph,b) = sum(count);
       end
       
    end
end
exp_mean = nanmean(exp_byPhase,2);
exp_sem = sem(exp_byPhase, 2, nan, height(unique(ctl_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
% polarscatter(ctl_phase_binned, ctl_joint, [3], ctl_flies,'filled');
polarscatter(phase_matrix(:), ctl_anglePlot(:), [dotSize], ctl_angleCount(:),'filled');

title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


%color bar legend
 max_len = max(ctl_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(ctl_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
%   cb.Position = [0.35 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);


%experimental
subplot(plotting.nRows, plotting.nCols,2); 
% polarscatter(exp_phase_binned, exp_joint, [3], exp_flies,'filled');
polarscatter(phase_matrix(:), exp_anglePlot(:), [dotSize], exp_angleCount(:),'filled');

title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);



%color bar legend
 max_len = max(exp_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(exp_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
%   cb.Position = [0.63 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned_angleBinned'];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase, binned angle + mean (TODO sem) of exp and con data
% polarscatter(phase,joint,vector4size,vector4color,'filled');
% 
% leg = 1;
% joint = 3; 
smooth_avgs = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 1; 
plotting.nCols = 3; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 30; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
angle_bins = [0:2:180];
%make a matrix of phase for plotting 
phase_matrix = phase_bins;
for b = 2:width(angle_bins)-1
   phase_matrix(:,end+1) = phase_bins;
end

ctl_byPhase = NaN(height(phase_bins), height(phase_bins));
ctl_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
ctl_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    ctl_idxs = find(ctl_phase_binned == phase_bins(ph));
    ctl_dataPerPhase(ph) = height(ctl_idxs); %how many data points per frame
    ctl_theseAngles = ctl_joint(ctl_idxs)';
    ctl_byPhase(ph,1:width(ctl_joint(ctl_idxs)')) = ctl_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(ctl_theseAngles > angle_bins(b) & ctl_theseAngles <= angle_bins(b+1));
       if isempty(count)
           ctl_anglePlot(ph,b) = NaN;
           ctl_angleCount(ph,b) = NaN;
       else
           ctl_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           ctl_angleCount(ph,b) = sum(count);
       end
       
    end
end
ctl_mean = nanmean(ctl_byPhase,2);
ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));


exp_byPhase = NaN(height(phase_bins), height(phase_bins));
exp_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
exp_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    exp_idxs = find(exp_phase_binned == phase_bins(ph));
    exp_dataPerPhase(ph) = height(exp_idxs); %how many data points per frame
    exp_theseAngles = exp_joint(exp_idxs)';
    exp_byPhase(ph,1:width(exp_joint(exp_idxs)')) = exp_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(exp_theseAngles > angle_bins(b) & exp_theseAngles <= angle_bins(b+1));
       if isempty(count)
           exp_anglePlot(ph,b) = NaN;
           exp_angleCount(ph,b) = NaN;
       else
           exp_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           exp_angleCount(ph,b) = sum(count);
       end
       
    end
end
exp_mean = nanmean(exp_byPhase,2);
exp_sem = sem(exp_byPhase, 2, nan, height(unique(ctl_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
% polarscatter(ctl_phase_binned, ctl_joint, [3], ctl_flies,'filled');
polarscatter(phase_matrix(:), ctl_anglePlot(:), [dotSize], ctl_angleCount(:),'filled');

title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


%color bar legend
 max_len = max(ctl_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(ctl_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
  cb.Position = [0.35 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);


%experimental
subplot(plotting.nRows, plotting.nCols,2); 
% polarscatter(exp_phase_binned, exp_joint, [3], exp_flies,'filled');
polarscatter(phase_matrix(:), exp_anglePlot(:), [dotSize], exp_angleCount(:),'filled');

title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);



%color bar legend
 max_len = max(exp_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(exp_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
  cb.Position = [0.63 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);

%averages
subplot(plotting.nRows, plotting.nCols, 3);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
hold on
polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
if smooth_avgs
    title('Smoothed Averages');
else
    title('Averages');
end
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
% rlim([0 180])
% rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned_angleBinned+means'];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase, binned angle + mean (TODO sem) of  exp and con data - GRAND MEAN
% polarscatter(phase,joint,vector4size,vector4color,'filled');
% 
% leg = 1;
% joint = 3; 
smooth_avgs = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 1; 
plotting.nCols = 3; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 2; sigstep = 0.01; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 30; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
angle_bins = [0:2:180];
%make a matrix of phase for plotting 
phase_matrix = phase_bins;
for b = 2:width(angle_bins)-1
   phase_matrix(:,end+1) = phase_bins;
end

%control - grand mean
for f = 1:param.numFlies
    ctl_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(ctl_flies == f);
    this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
    this_fly_joint = ctl_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
%         ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
        if height(ctl_idxs) >= 1
            % enough data points to have a good average, so save data
            ctl_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = this_fly_joint(ctl_idxs)';
        end
    end
    ctl_means(:,f) = nanmean(ctl_byPhase,2);
    ctl_sems(:,f) = sem(ctl_byPhase, 2, nan, 1);
end
%take the grand mean (mean of fly means)
ctl_mean = nanmean(ctl_means,2);
ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%control - binned angle x phase
ctl_byPhase = NaN(height(phase_bins), height(phase_bins));
ctl_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
ctl_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    ctl_idxs = find(ctl_phase_binned == phase_bins(ph));
    ctl_dataPerPhase(ph) = height(ctl_idxs); %how many data points per frame
    ctl_theseAngles = ctl_joint(ctl_idxs)';
    ctl_byPhase(ph,1:width(ctl_joint(ctl_idxs)')) = ctl_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(ctl_theseAngles > angle_bins(b) & ctl_theseAngles <= angle_bins(b+1));
       if isempty(count)
           ctl_anglePlot(ph,b) = NaN;
           ctl_angleCount(ph,b) = NaN;
       else
           ctl_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           ctl_angleCount(ph,b) = sum(count);
       end
       
    end
end
% ctl_mean = nanmean(ctl_byPhase,2);
% ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%experimenal - grand mean 
for f = 1:param.numFlies
    exp_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(exp_flies == f);
    this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
    this_fly_joint = exp_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
%         exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
        if height(exp_idxs) >= 1
            % enough data points to have a good average, so save data
            exp_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = this_fly_joint(exp_idxs)';
        end
    end
    exp_means(:,f) = nanmean(exp_byPhase,2);
    exp_sems(:,f) = sem(exp_byPhase, 2, nan, 1);
end
%take the grand mean (mean of fly means)
exp_mean = nanmean(exp_means,2);
exp_sem = sem(exp_byPhase, 2, nan, height(unique(exp_flies)));

%experimental - binned angle x phase 
exp_byPhase = NaN(height(phase_bins), height(phase_bins));
exp_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
exp_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    exp_idxs = find(exp_phase_binned == phase_bins(ph));
    exp_dataPerPhase(ph) = height(exp_idxs); %how many data points per frame
    exp_theseAngles = exp_joint(exp_idxs)';
    exp_byPhase(ph,1:width(exp_joint(exp_idxs)')) = exp_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(exp_theseAngles > angle_bins(b) & exp_theseAngles <= angle_bins(b+1));
       if isempty(count)
           exp_anglePlot(ph,b) = NaN;
           exp_angleCount(ph,b) = NaN;
       else
           exp_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           exp_angleCount(ph,b) = sum(count);
       end
       
    end
end
% exp_mean = nanmean(exp_byPhase,2);
% exp_sem = sem(exp_byPhase, 2, nan, height(unique(ctl_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
% polarscatter(ctl_phase_binned, ctl_joint, [3], ctl_flies,'filled');
polarscatter(phase_matrix(:), ctl_anglePlot(:), [dotSize], ctl_angleCount(:),'filled');

title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


%color bar legend
 max_len = max(ctl_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(ctl_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
  cb.Position = [0.35 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);


%experimental
subplot(plotting.nRows, plotting.nCols,2); 
% polarscatter(exp_phase_binned, exp_joint, [3], exp_flies,'filled');
polarscatter(phase_matrix(:), exp_anglePlot(:), [dotSize], exp_angleCount(:),'filled');

title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);



%color bar legend
 max_len = max(exp_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(exp_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
  cb.Position = [0.63 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);

%averages
subplot(plotting.nRows, plotting.nCols, 3);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
hold on
polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
if smooth_avgs
    title('Smoothed Averages');
else
    title('Averages');
end
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
% rlim([0 180])
% rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned_angleBinned+GRANDmeans'];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
% if param.rlimit; fig_name = [fig_name, '_Rzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase, binned angle + mean (TODO sem) of  exp and con data - GRAND MEAN & SEM
% polarscatter(phase,joint,vector4size,vector4color,'filled');
% 
% leg = 1;
% joint = 3; 
smooth_avgs = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 2; 
plotting.nCols = 2; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 2; sigstep = 0.01; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 30; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
angle_bins = [0:2:180];
%make a matrix of phase for plotting 
phase_matrix = phase_bins;
for b = 2:width(angle_bins)-1
   phase_matrix(:,end+1) = phase_bins;
end

%control - grand mean
for f = 1:param.numFlies
    ctl_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(ctl_flies == f);
    this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
    this_fly_joint = ctl_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
%         ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
        if height(ctl_idxs) >= 1
            % enough data points to have a good average, so save data
            ctl_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = this_fly_joint(ctl_idxs)';
        end
    end
    ctl_means(:,f) = nanmean(ctl_byPhase,2);
    ctl_sems(:,f) = sem(ctl_byPhase, 2, nan, 1);
end
%take the grand mean (mean of fly means)
ctl_mean = nanmean(ctl_means,2);
ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%control - binned angle x phase
ctl_byPhase = NaN(height(phase_bins), height(phase_bins));
ctl_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
ctl_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    ctl_idxs = find(ctl_phase_binned == phase_bins(ph));
    ctl_dataPerPhase(ph) = height(ctl_idxs); %how many data points per frame
    ctl_theseAngles = ctl_joint(ctl_idxs)';
    ctl_byPhase(ph,1:width(ctl_joint(ctl_idxs)')) = ctl_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(ctl_theseAngles > angle_bins(b) & ctl_theseAngles <= angle_bins(b+1));
       if isempty(count)
           ctl_anglePlot(ph,b) = NaN;
           ctl_angleCount(ph,b) = NaN;
       else
           ctl_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           ctl_angleCount(ph,b) = sum(count);
       end
       
    end
end
% ctl_mean = nanmean(ctl_byPhase,2);
% ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%experimenal - grand mean 
for f = 1:param.numFlies
    exp_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(exp_flies == f);
    this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
    this_fly_joint = exp_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
%         exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
        if height(exp_idxs) >= 1
            % enough data points to have a good average, so save data
            exp_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = this_fly_joint(exp_idxs)';
        end
    end
    exp_means(:,f) = nanmean(exp_byPhase,2);
    exp_sems(:,f) = sem(exp_byPhase, 2, nan, 1);
end
%take the grand mean (mean of fly means)
exp_mean = nanmean(exp_means,2);
exp_sem = sem(exp_byPhase, 2, nan, height(unique(exp_flies)));

%experimental - binned angle x phase 
exp_byPhase = NaN(height(phase_bins), height(phase_bins));
exp_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
exp_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    exp_idxs = find(exp_phase_binned == phase_bins(ph));
    exp_dataPerPhase(ph) = height(exp_idxs); %how many data points per frame
    exp_theseAngles = exp_joint(exp_idxs)';
    exp_byPhase(ph,1:width(exp_joint(exp_idxs)')) = exp_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(exp_theseAngles > angle_bins(b) & exp_theseAngles <= angle_bins(b+1));
       if isempty(count)
           exp_anglePlot(ph,b) = NaN;
           exp_angleCount(ph,b) = NaN;
       else
           exp_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           exp_angleCount(ph,b) = sum(count);
       end
       
    end
end
% exp_mean = nanmean(exp_byPhase,2);
% exp_sem = sem(exp_byPhase, 2, nan, height(unique(ctl_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
% polarscatter(ctl_phase_binned, ctl_joint, [3], ctl_flies,'filled');
polarscatter(phase_matrix(:), ctl_anglePlot(:), [dotSize], ctl_angleCount(:),'filled');
% polarscatter(phase_matrix(:), ctl_anglePlot(:), ctl_angleCount(:)/10000, ctl_angleCount(:),'filled');

title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


%color bar legend
 max_len = max(ctl_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(ctl_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
%   cb.Position = [0.35 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);


%experimental
subplot(plotting.nRows, plotting.nCols,2); 
% polarscatter(exp_phase_binned, exp_joint, [3], exp_flies,'filled');
polarscatter(phase_matrix(:), exp_anglePlot(:), [dotSize], exp_angleCount(:),'filled');
% polarscatter(phase_matrix(:), exp_anglePlot(:), exp_angleCount(:)/1000, exp_angleCount(:),'filled');

title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);



%color bar legend
 max_len = max(exp_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(exp_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
%   cb.Position = [0.63 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);

%averages
subplot(plotting.nRows, plotting.nCols, 3);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
hold on
polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
if smooth_avgs
    title('Smoothed Averages');
else
    title('Averages');
end
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
% rlim([0 180])
% rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


%averages
subplot(plotting.nRows, plotting.nCols, 4);

polarplot(phase_bins, ctl_sem, 'color', Color(param.baseColor), 'lineWidth', 2);
hold on
polarplot(phase_bins, exp_sem, 'color', Color(param.expColor), 'lineWidth', 2);
title('SEMs');
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
% rlim([0 180])
% rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned_angleBinned+GRANDmeans+StandardDev'];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
% if param.rlimit; fig_name = [fig_name, '_Rzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase, binned angle + mean (TODO sem) of  exp and con data - GRAND MEAN - SINGLE FLY

fly = 7; %fly to plot

% 
% leg = 1;
% joint = 3; 
smooth_avgs = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 1; 
plotting.nCols = 3; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 2; sigstep = 0.01; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 30; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
angle_bins = [0:2:180];
%make a matrix of phase for plotting 
phase_matrix = phase_bins;
for b = 2:width(angle_bins)-1
   phase_matrix(:,end+1) = phase_bins;
end

%control - grand mean
f = fly;
ctl_byPhase = NaN(height(phase_bins), 50000); 
this_fly_idxs = find(ctl_flies == f);
this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
this_fly_joint = ctl_joint(this_fly_idxs);
for ph = 1:height(phase_bins)
    ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
%         ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
    if height(ctl_idxs) >= 1
        % enough data points to have a good average, so save data
        ctl_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = this_fly_joint(ctl_idxs)';
    end
end
ctl_mean = nanmean(ctl_byPhase,2);
ctl_sem = sem(ctl_byPhase, 2, nan, 1);

%     
%     %take the grand mean (mean of fly means)
% ctl_mean = nanmean(ctl_means,2);
% ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%control - binned angle x phase
ctl_byPhase = NaN(height(phase_bins), height(phase_bins));
ctl_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
ctl_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    ctl_idxs = find(ctl_phase_binned(this_fly_idxs) == phase_bins(ph));
    ctl_dataPerPhase(ph) = height(ctl_idxs); %how many data points per frame
    ctl_theseAngles = ctl_joint(ctl_idxs)';
    ctl_byPhase(ph,1:width(ctl_joint(ctl_idxs)')) = ctl_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(ctl_theseAngles > angle_bins(b) & ctl_theseAngles <= angle_bins(b+1));
       if isempty(count)
           ctl_anglePlot(ph,b) = NaN;
           ctl_angleCount(ph,b) = NaN;
       else
           ctl_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           ctl_angleCount(ph,b) = sum(count);
       end
       
    end
end
% ctl_mean = nanmean(ctl_byPhase,2);
% ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%experimenal - grand mean 
f = fly;
exp_byPhase = NaN(height(phase_bins), 50000); 
this_fly_idxs = find(exp_flies == f);
this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
this_fly_joint = exp_joint(this_fly_idxs);
for ph = 1:height(phase_bins)
    exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
%         exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
    if height(exp_idxs) >= 1
        % enough data points to have a good average, so save data
        exp_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = this_fly_joint(exp_idxs)';
    end
end
exp_mean = nanmean(exp_byPhase,2);
exp_sem = sem(exp_byPhase, 2, nan, 1);
% 
% %take the grand mean (mean of fly means)
% exp_mean = nanmean(exp_means,2);
% exp_sem = sem(exp_byPhase, 2, nan, height(unique(exp_flies)));

%experimental - binned angle x phase 
exp_byPhase = NaN(height(phase_bins), height(phase_bins));
exp_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
exp_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    exp_idxs = find(exp_phase_binned(this_fly_idxs) == phase_bins(ph));
    exp_dataPerPhase(ph) = height(exp_idxs); %how many data points per frame
    exp_theseAngles = exp_joint(exp_idxs)';
    exp_byPhase(ph,1:width(exp_joint(exp_idxs)')) = exp_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(exp_theseAngles > angle_bins(b) & exp_theseAngles <= angle_bins(b+1));
       if isempty(count)
           exp_anglePlot(ph,b) = NaN;
           exp_angleCount(ph,b) = NaN;
       else
           exp_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           exp_angleCount(ph,b) = sum(count);
       end
       
    end
end
% exp_mean = nanmean(exp_byPhase,2);
% exp_sem = sem(exp_byPhase, 2, nan, height(unique(ctl_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
% polarscatter(ctl_phase_binned, ctl_joint, [3], ctl_flies,'filled');
polarscatter(phase_matrix(:), ctl_anglePlot(:), [dotSize], ctl_angleCount(:),'filled');

title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


%color bar legend
 max_len = max(ctl_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(ctl_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
  cb.Position = [0.35 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);


%experimental
subplot(plotting.nRows, plotting.nCols,2); 
% polarscatter(exp_phase_binned, exp_joint, [3], exp_flies,'filled');
polarscatter(phase_matrix(:), exp_anglePlot(:), [dotSize], exp_angleCount(:),'filled');

title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);



%color bar legend
 max_len = max(exp_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(exp_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
  cb.Position = [0.63 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);

%averages
subplot(plotting.nRows, plotting.nCols, 3);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
hold on
polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
if smooth_avgs
    title('Smoothed Averages');
else
    title('Averages');
end
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
% rlim([0 180])
% rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned_angleBinned+GRANDmeans - fly ' num2str(fly)];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase, binned angle + mean (TODO sem) of exp and con data - GRAND MEAN - only first X frames post stim onset
% polarscatter(phase,joint,vector4size,vector4color,'filled');
% 
% leg = 1;
% joint = 3; 
smooth_avgs = 0;
ctl_onlyWithinXFrames = 0; %1= ctl frames are also only those within 150 - 150+X frames in video. 

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 1; 
plotting.nCols = 3; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 30; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);
ctl_withinXFrames = ctl_data{leg,joint}(:,4);
exp_withinXFrames = exp_data{leg,joint}(:,4);

%only keep datapoints that are within 50 frames of stim onset
if ctl_onlyWithinXFrames
    ctl_phase_binned = ctl_phase_binned(find(ctl_withinXFrames));
    ctl_joint = ctl_joint(find(ctl_withinXFrames));
    ctl_flies = ctl_flies(find(ctl_withinXFrames));
end
exp_phase_binned = exp_phase_binned(find(exp_withinXFrames));
exp_joint = exp_joint(find(exp_withinXFrames));
exp_flies = exp_flies(find(exp_withinXFrames));

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
angle_bins = [0:2:180];
%make a matrix of phase for plotting 
phase_matrix = phase_bins;
for b = 2:width(angle_bins)-1
   phase_matrix(:,end+1) = phase_bins;
end

%control - grand mean
for f = 1:param.numFlies
    ctl_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(ctl_flies == f);
    this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
    this_fly_joint = ctl_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
%         ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
        if height(ctl_idxs) >= 1
            % enough data points to have a good average, so save data
            ctl_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = this_fly_joint(ctl_idxs)';
        end
    end
    ctl_means(:,f) = nanmean(ctl_byPhase,2);
    ctl_sems(:,f) = sem(ctl_byPhase, 2, nan, 1);
end
%take the grand mean (mean of fly means)
ctl_mean = nanmean(ctl_means,2);
ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%control - binned angle x phase
ctl_byPhase = NaN(height(phase_bins), height(phase_bins));
ctl_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
ctl_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    ctl_idxs = find(ctl_phase_binned == phase_bins(ph));
    ctl_dataPerPhase(ph) = height(ctl_idxs); %how many data points per frame
    ctl_theseAngles = ctl_joint(ctl_idxs)';
    ctl_byPhase(ph,1:width(ctl_joint(ctl_idxs)')) = ctl_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(ctl_theseAngles > angle_bins(b) & ctl_theseAngles <= angle_bins(b+1));
       if isempty(count)
           ctl_anglePlot(ph,b) = NaN;
           ctl_angleCount(ph,b) = NaN;
       else
           ctl_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           ctl_angleCount(ph,b) = sum(count);
       end
       
    end
end
% ctl_mean = nanmean(ctl_byPhase,2);
% ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%experimenal - grand mean 
for f = 1:param.numFlies
    exp_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(exp_flies == f);
    this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
    this_fly_joint = exp_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
%         exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
        if height(exp_idxs) >= 1
            % enough data points to have a good average, so save data
            exp_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = this_fly_joint(exp_idxs)';
        end
    end
    exp_means(:,f) = nanmean(exp_byPhase,2);
    exp_sems(:,f) = sem(exp_byPhase, 2, nan, 1);
end
%take the grand mean (mean of fly means)
exp_mean = nanmean(exp_means,2);
exp_sem = sem(exp_byPhase, 2, nan, height(unique(exp_flies)));

%experimental - binned angle x phase 
exp_byPhase = NaN(height(phase_bins), height(phase_bins));
exp_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
exp_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    exp_idxs = find(exp_phase_binned == phase_bins(ph));
    exp_dataPerPhase(ph) = height(exp_idxs); %how many data points per frame
    exp_theseAngles = exp_joint(exp_idxs)';
    exp_byPhase(ph,1:width(exp_joint(exp_idxs)')) = exp_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(exp_theseAngles > angle_bins(b) & exp_theseAngles <= angle_bins(b+1));
       if isempty(count)
           exp_anglePlot(ph,b) = NaN;
           exp_angleCount(ph,b) = NaN;
       else
           exp_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           exp_angleCount(ph,b) = sum(count);
       end
       
    end
end
% exp_mean = nanmean(exp_byPhase,2);
% exp_sem = sem(exp_byPhase, 2, nan, height(unique(ctl_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
% polarscatter(ctl_phase_binned, ctl_joint, [3], ctl_flies,'filled');
polarscatter(phase_matrix(:), ctl_anglePlot(:), [dotSize], ctl_angleCount(:),'filled');

title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


%color bar legend
 max_len = max(ctl_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(ctl_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
  cb.Position = [0.35 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);


%experimental
subplot(plotting.nRows, plotting.nCols,2); 
% polarscatter(exp_phase_binned, exp_joint, [3], exp_flies,'filled');
polarscatter(phase_matrix(:), exp_anglePlot(:), [dotSize], exp_angleCount(:),'filled');

title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);



%color bar legend
 max_len = max(exp_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(exp_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
  cb.Position = [0.63 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);

%averages
subplot(plotting.nRows, plotting.nCols, 3);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
hold on
polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
if smooth_avgs
    title('Smoothed Averages');
else
    title('Averages');
end
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
% rlim([0 180])
% rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase: ' num2str(XFrames) ' frames post stim onset'], 'color', Color(param.baseColor));
han.FontSize = 30;


if ctl_onlyWithinXFrames
    type_str = '_ofALLdata';
else
    type_str = '_ofEXPdata';
end

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned_angleBinned+GRANDmeans_OnlyFirst' num2str(XFrames) 'FramesPostStimOnset' type_str];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase, binned angle + mean (TODO sem) of exp and con data - BY FLY
% leg = 1;
% joint = 3; 
smooth_avgs = 0;
withColorBar = 1;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 3; 
plotting.nCols = param.numFlies; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems ctl_byPhase exp_byPhase ctl_angleCount exp_angleCount ctl_anglePlot exp_anglePlot

% sigdig = 2; sigstep = 0.01; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 15; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
angle_bins = [0:2:180];
%make a matrix of phase for plotting 
phase_matrix = phase_bins;
for b = 2:width(angle_bins)-1
   phase_matrix(:,end+1) = phase_bins;
end

%control data wrangling
for f = 1:param.numFlies
    fly_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
    fly_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
    this_fly_idxs = find(ctl_flies == f);
    this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
    this_fly_joint = ctl_joint(this_fly_idxs);
    fly_byPhase = NaN(height(phase_bins), height(this_fly_joint));

    
    for ph = 1:height(phase_bins)
        ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
        ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
        ctl_theseAngles = this_fly_joint(ctl_idxs)';
        fly_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = ctl_theseAngles;
        for b = 1:width(angle_bins)-1
           count = find(ctl_theseAngles > angle_bins(b) & ctl_theseAngles <= angle_bins(b+1));
           if isempty(count)
               fly_anglePlot(ph,b) = NaN;
               fly_angleCount(ph,b) = NaN;
           else
               fly_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
               fly_angleCount(ph,b) = sum(count);
           end      
        end
    end
    ctl_means{f} = nanmean(fly_byPhase,2);
    ctl_sems{f} = sem(fly_byPhase, 2, nan, height(unique(ctl_flies)));
    ctl_byPhase{f} = fly_byPhase;
    ctl_angleCount{f} = fly_angleCount;
    ctl_anglePlot{f} = fly_anglePlot;
end

%experiemental data wrangling
for f = 1:param.numFlies
    fly_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
    fly_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
    this_fly_idxs = find(exp_flies == f);
    this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
    this_fly_joint = exp_joint(this_fly_idxs);
    fly_byPhase = NaN(height(phase_bins), height(this_fly_joint));
    
    for ph = 1:height(phase_bins)
        exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
        exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
        exp_theseAngles = this_fly_joint(exp_idxs)';
        fly_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = exp_theseAngles;
        for b = 1:width(angle_bins)-1
           count = find(exp_theseAngles > angle_bins(b) & exp_theseAngles <= angle_bins(b+1));
           if isempty(count)
               fly_anglePlot(ph,b) = NaN;
               fly_angleCount(ph,b) = NaN;
           else
               fly_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
               fly_angleCount(ph,b) = sum(count);
           end      
        end
    end
    exp_means{f} = nanmean(fly_byPhase,2);
    exp_sems{f} = sem(fly_byPhase, 2, nan, height(unique(exp_flies)));
    exp_byPhase{f} = fly_byPhase;
    exp_angleCount{f} = fly_angleCount;
    exp_anglePlot{f} = fly_anglePlot;
end

%plot the data
idx = 0;
for f = 1:param.numFlies
    %control
    idx = idx+1;
    subplot(plotting.nRows, plotting.nCols, idx);
    % polarscatter(ctl_phase_binned, ctl_joint, [3], ctl_flies,'filled');
    polarscatter(phase_matrix(:), ctl_anglePlot{f}(:), [dotSize], ctl_angleCount{f}(:),'filled');

    title('Control')
    pax = gca;
    pax.FontSize = 14;
    pax.RColor = Color(param.baseColor);
    pax.ThetaColor = Color(param.baseColor);
    rlim([0 180])
    rticks([0,45,90,135,180])
    thetaticks([0, 90, 180, 270]);

    if withColorBar
        %color bar legend
         max_len = max(ctl_angleCount{f}, [], 'all'); max_len_str = num2str(max_len);
         min_len = min(ctl_angleCount{f}, [], 'all'); min_len_str = num2str(min_len);
         mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
        %  cb = colorbar('Ticks',[0, 0.5, 1],...
        %      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
         cb = colorbar('Ticks',[min_len, mid_len, max_len],...
             'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
         pos = get(cb,'Position');
    %       cb.Position = [0.35 pos(2) pos(3) pos(4)]; % to change its position
        %   cb.Label.String = 'Count';
          cb.Label.Color = Color(param.baseColor);
    end

    %experimental
    subplot(plotting.nRows, plotting.nCols,idx+param.numFlies); 
    % polarscatter(exp_phase_binned, exp_joint, [3], exp_flies,'filled');
    polarscatter(phase_matrix(:), exp_anglePlot{f}(:), [dotSize], exp_angleCount{f}(:),'filled');

    title('Experimental')
    pax = gca;
    pax.FontSize = 14;
    pax.RColor = Color(param.baseColor);
    pax.ThetaColor = Color(param.baseColor);
    rlim([0 180])
    rticks([0,45,90,135,180])
    thetaticks([0, 90, 180, 270]);
    
    if withColorBar 
        %color bar legend
         max_len = max(exp_angleCount{f}, [], 'all'); max_len_str = num2str(max_len);
         min_len = min(exp_angleCount{f}, [], 'all'); min_len_str = num2str(min_len);
         mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
        %  cb = colorbar('Ticks',[0, 0.5, 1],...
        %      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
         cb = colorbar('Ticks',[min_len, mid_len, max_len],...
             'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
         pos = get(cb,'Position');
    %       cb.Position = [0.63 pos(2) pos(3) pos(4)]; % to change its position
        %   cb.Label.String = 'Count';
          cb.Label.Color = Color(param.baseColor);
    end

    %averages
    subplot(plotting.nRows, plotting.nCols, idx+param.numFlies+param.numFlies);
    if smooth_avgs
        ctl_mean_plot = smoothdata(ctl_means{f});
        exp_mean_plot = smoothdata(exp_means{f});
    else
        ctl_mean_plot = ctl_means{f};
        exp_mean_plot = exp_means{f};
    end
    polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
    hold on
    polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
    if smooth_avgs
        title('Smoothed Averages');
    else
        title('Averages');
    end
    pax = gca;
    pax.FontSize = 14;
    pax.RColor = Color(param.baseColor);
    pax.ThetaColor = Color(param.baseColor);
    if param.sameAxes
        rlim([0 180])
        rticks([0,45,90,135,180])
    end
    thetaticks([0, 90, 180, 270]);

    hold off
end

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned_angleBinned+means_byFLY'];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if withColorBar; fig_name = [fig_name, '_wColorBar']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.sameAxes; fig_name = [fig_name, '_sameAxes']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase, binned angle + mean (TODO sem) of exp and con data - BY FLY - only first X frames post stim onset
% leg = 1;
% joint = 3; 
smooth_avgs = 0;
withColorBar = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

ctl_onlyWithinXFrames = 0;

fig = fullfig;
plotting.nRows = 3; 
plotting.nCols = param.numFlies; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems ctl_byPhase exp_byPhase ctl_angleCount exp_angleCount ctl_anglePlot exp_anglePlot

% sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 15; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);
ctl_withinXFrames = ctl_data{leg,joint}(:,4);
exp_withinXFrames = exp_data{leg,joint}(:,4);

%only keep datapoints that are within 50 frames of stim onset
if ctl_onlyWithinXFrames
    ctl_phase_binned = ctl_phase_binned(find(ctl_withinXFrames));
    ctl_joint = ctl_joint(find(ctl_withinXFrames));
    ctl_flies = ctl_flies(find(ctl_withinXFrames));
end
exp_phase_binned = exp_phase_binned(find(exp_withinXFrames));
exp_joint = exp_joint(find(exp_withinXFrames));
exp_flies = exp_flies(find(exp_withinXFrames));

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
angle_bins = [0:2:180];
%make a matrix of phase for plotting 
phase_matrix = phase_bins;
for b = 2:width(angle_bins)-1
   phase_matrix(:,end+1) = phase_bins;
end

%control data wrangling
for f = 1:param.numFlies
    fly_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
    fly_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
    this_fly_idxs = find(ctl_flies == f);
    this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
    this_fly_joint = ctl_joint(this_fly_idxs);
    fly_byPhase = NaN(height(phase_bins), height(this_fly_joint));

    for ph = 1:height(phase_bins)
        ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
        ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
        ctl_theseAngles = this_fly_joint(ctl_idxs)';
        fly_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = ctl_theseAngles;
        for b = 1:width(angle_bins)-1
           count = find(ctl_theseAngles > angle_bins(b) & ctl_theseAngles <= angle_bins(b+1));
           if isempty(count)
               fly_anglePlot(ph,b) = NaN;
               fly_angleCount(ph,b) = NaN;
           else
               fly_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
               fly_angleCount(ph,b) = sum(count);
           end      
        end
    end
    ctl_means{f} = nanmean(fly_byPhase,2);
    ctl_sems{f} = sem(fly_byPhase, 2, nan, height(unique(ctl_flies)));
    ctl_byPhase{f} = fly_byPhase;
    ctl_angleCount{f} = fly_angleCount;
    ctl_anglePlot{f} = fly_anglePlot;
end

%experiemental data wrangling
for f = 1:param.numFlies
%     fly_byPhase = NaN(height(phase_bins), height(phase_bins));
    fly_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
    fly_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
    this_fly_idxs = find(exp_flies == f);
    this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
    this_fly_joint = exp_joint(this_fly_idxs);
    fly_byPhase = NaN(height(phase_bins), height(this_fly_joint));

    for ph = 1:height(phase_bins)
        exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
        exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
        exp_theseAngles = this_fly_joint(exp_idxs)';
        fly_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = exp_theseAngles;
        for b = 1:width(angle_bins)-1
           count = find(exp_theseAngles > angle_bins(b) & exp_theseAngles <= angle_bins(b+1));
           if isempty(count)
               fly_anglePlot(ph,b) = NaN;
               fly_angleCount(ph,b) = NaN;
           else
               fly_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
               fly_angleCount(ph,b) = sum(count);
           end      
        end
    end
    exp_means{f} = nanmean(fly_byPhase,2);
    exp_sems{f} = sem(fly_byPhase, 2, nan, height(unique(exp_flies)));
    exp_byPhase{f} = fly_byPhase;
    exp_angleCount{f} = fly_angleCount;
    exp_anglePlot{f} = fly_anglePlot;
end

%plot the data
idx = 0;
for f = 1:param.numFlies
    %control
    idx = idx+1;
    subplot(plotting.nRows, plotting.nCols, idx);
    % polarscatter(ctl_phase_binned, ctl_joint, [3], ctl_flies,'filled');
    polarscatter(phase_matrix(:), ctl_anglePlot{f}(:), [dotSize], ctl_angleCount{f}(:),'filled');

    title('Control')
    pax = gca;
    pax.FontSize = 14;
    pax.RColor = Color(param.baseColor);
    pax.ThetaColor = Color(param.baseColor);
    rlim([0 180])
    rticks([0,45,90,135,180])
    thetaticks([0, 90, 180, 270]);

    if withColorBar
        %color bar legend
         max_len = max(ctl_angleCount{f}, [], 'all'); max_len_str = num2str(max_len);
         min_len = min(ctl_angleCount{f}, [], 'all'); min_len_str = num2str(min_len);
         mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
        %  cb = colorbar('Ticks',[0, 0.5, 1],...
        %      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
         cb = colorbar('Ticks',[min_len, mid_len, max_len],...
             'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
         pos = get(cb,'Position');
    %       cb.Position = [0.35 pos(2) pos(3) pos(4)]; % to change its position
        %   cb.Label.String = 'Count';
          cb.Label.Color = Color(param.baseColor);
    end

    %experimental
    subplot(plotting.nRows, plotting.nCols,idx+param.numFlies); 
    % polarscatter(exp_phase_binned, exp_joint, [3], exp_flies,'filled');
    polarscatter(phase_matrix(:), exp_anglePlot{f}(:), [dotSize], exp_angleCount{f}(:),'filled');

    title('Experimental')
    pax = gca;
    pax.FontSize = 14;
    pax.RColor = Color(param.baseColor);
    pax.ThetaColor = Color(param.baseColor);
    rlim([0 180])
    rticks([0,45,90,135,180])
    thetaticks([0, 90, 180, 270]);
    
    if withColorBar 
        %color bar legend
         max_len = max(exp_angleCount{f}, [], 'all'); max_len_str = num2str(max_len);
         min_len = min(exp_angleCount{f}, [], 'all'); min_len_str = num2str(min_len);
         mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
        %  cb = colorbar('Ticks',[0, 0.5, 1],...
        %      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
         cb = colorbar('Ticks',[min_len, mid_len, max_len],...
             'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
         pos = get(cb,'Position');
    %       cb.Position = [0.63 pos(2) pos(3) pos(4)]; % to change its position
        %   cb.Label.String = 'Count';
          cb.Label.Color = Color(param.baseColor);
    end

    %averages
    subplot(plotting.nRows, plotting.nCols, idx+param.numFlies+param.numFlies);
    if smooth_avgs
        ctl_mean_plot = smoothdata(ctl_means{f});
        exp_mean_plot = smoothdata(exp_means{f});
    else
        ctl_mean_plot = ctl_means{f};
        exp_mean_plot = exp_means{f};
    end
    polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
    hold on
    polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
    if smooth_avgs
        title('Smoothed Averages');
    else
        title('Averages');
    end
    pax = gca;
    pax.FontSize = 14;
    pax.RColor = Color(param.baseColor);
    pax.ThetaColor = Color(param.baseColor);
    if param.sameAxes
        rlim([0 180])
        rticks([0,45,90,135,180])
    end
    thetaticks([0, 90, 180, 270]);

    hold off
end

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;


if ctl_onlyWithinXFrames
    type_str = '_ofALLdata';
else
    type_str = '_ofEXPdata';
end

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned_angleBinned+means_byFLY_OnlyFirst' num2str(XFrames) 'FramesPostStimOnset' type_str];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if withColorBar; fig_name = [fig_name, '_wColorBar']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.sameAxes; fig_name = [fig_name, '_sameAxes']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% NEW Joint x Phase %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%basically I'm just doing it by walking bout here instead of by step b/c
%idk if doing it by step was actually right... it didn't look like smooth
%walking data. 

%% Choose a leg and joint and get the appropriate indices into walking struct

leg = 1; 
joint = 3; 
data_idx = [param.legs{leg} '_' param.joints{joint}];
phase_idx = [data_idx '_phase'];

%% Plot a single step over phase

fig = fullfig;
bout = 1;
step = 3;
phase_data = walking.bouts{bout}.(phase_idx);
joint_data = walking.bouts{bout}.(data_idx);

%get peaks of bout and select step 
[max_pks, max_locs, ~, ~] = findpeaks(joint_data, 'MinPeakProminence', 10);
step_data = joint_data(max_locs(step):max_locs(step+1));
step_phase = phase_data(max_locs(step):max_locs(step+1));

%plot the step
polarplot(step_phase, step_data); hold on;

%plot min and max points 
polarscatter(phase_data(max_locs(step)), max_pks(step), [], 'filled');
[min_pks, min_locs, ~, ~] = findpeaks(step_data*-1, 'MinPeakProminence', 10);
polarscatter(step_phase(min_locs), min_pks*-1, [], 'filled');

pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor); 
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


hold off;
fig = formatFigPolar(fig, true); %black background 


%Save!
fig_name = [strrep(data_idx, '_', ' ') ' single step - bout ' num2str(bout) ' step ' num2str(step)];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot a single walking bout over phase

fig = fullfig;
bout = 2;
trim = 3; %trim this number of frames off start/end of bout to have a cleaner plot
phase_data = walking.bouts{bout}.(phase_idx)(trim:end-trim);
joint_data = walking.bouts{bout}.(data_idx)(trim:end-trim);
polarplot(phase_data, joint_data); hold on;

pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


hold off;
fig = formatFigPolar(fig, true); %black background 


%Save!
fig_name = [strrep(data_idx, '_', ' ') ' walking bout ' num2str(bout)];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


% 
% %Trying to plot the line with color = time... but it's pretty hard. 
% % Convert data coordinates to cartesian: 
% phase_data = walking.bouts{bout}.(phase_idx);
% joint_data = walking.bouts{bout}.(data_idx);
% [x,y] = pol2cart(phase_data, joint_data);
% t = [1:height(y)]';
% LineWidth = 1;
% % Matlab does not have a function to plot color-gradient lines. So we trick Matlab 
% % by plotting a surface:
% h = surface([x';x'],[y';y'],[ones(size(x'));ones(size(x'))],[t';t'],...
%         'facecolor','none',...
%         'edgecolor','interp',...
%         'linewidth',LineWidth);    

%This function has a workaround using 'surface'... i've messed with the
%function a bit but it's kinda useful. 
% spiral(walking.bouts{bout}.(phase_idx)(1:end-1), walking.bouts{bout}.(data_idx)(1:end-1));

%% Plot a single walking bout over phase - with peaks!

fig = fullfig;
bout = 1;
trim = 3; %trim this number of frames off start/end of bout to have a cleaner plot
phase_data = walking.bouts{bout}.(phase_idx)(trim:end-trim);
joint_data = walking.bouts{bout}.(data_idx)(trim:end-trim);
polarplot(phase_data, joint_data); hold on;

[max_pks, max_locs, max_w, max_p] = findpeaks(joint_data, 'MinPeakProminence', 10);
polarscatter(phase_data(max_locs), joint_data(max_locs), [], 'filled');

[min_pks, min_locs, min_w, min_p] = findpeaks(joint_data*-1, 'MinPeakProminence', 10);
polarscatter(phase_data(min_locs), joint_data(min_locs), [], 'filled');

pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


hold off;
fig = formatFigPolar(fig, true); %black background 

% han=axes(fig,'visible','off'); 
% han.Title.Visible='on';
% title(han, [strrep(data_idx, '_', ' ') ' walking bout with peaks'], 'color', Color(param.baseColor));
% han.FontSize = 20;

%Save!
fig_name = [strrep(data_idx, '_', ' ') ' walking bout ' num2str(bout) ' with peaks'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

% 
% %Trying to plot the line with color = time... but it's pretty hard. 
% % Convert data coordinates to cartesian: 
% phase_data = walking.bouts{bout}.(phase_idx);
% joint_data = walking.bouts{bout}.(data_idx);
% [x,y] = pol2cart(phase_data, joint_data);
% t = [1:height(y)]';
% LineWidth = 1;
% % Matlab does not have a function to plot color-gradient lines. So we trick Matlab 
% % by plotting a surface:
% h = surface([x';x'],[y';y'],[ones(size(x'));ones(size(x'))],[t';t'],...
%         'facecolor','none',...
%         'edgecolor','interp',...
%         'linewidth',LineWidth);    

%This function has a workaround using 'surface'... i've messed with the
%function a bit but it's kinda useful. 
% spiral(walking.bouts{bout}.(phase_idx)(1:end-1), walking.bouts{bout}.(data_idx)(1:end-1));

%% Plot many walking bouts over phase - with peaks!

fig = fullfig;
plotting.nRows = 10; 
plotting.nCols = 10; 
numBouts = height(walking.bouts);


for bout = 1:100
    subplot(plotting.nRows, plotting.nCols,bout);

    trim = 3; %trim this number of frames off start/end of bout to have a cleaner plot
    phase_data = walking.bouts{bout}.(phase_idx)(trim:end-trim);
    joint_data = walking.bouts{bout}.(data_idx)(trim:end-trim);
    polarplot(phase_data, joint_data); hold on;

    [max_pks, max_locs, max_w, max_p] = findpeaks(joint_data, 'MinPeakProminence', 10);
    polarscatter(phase_data(max_locs), joint_data(max_locs), [], 'filled');

    [min_pks, min_locs, min_w, min_p] = findpeaks(joint_data*-1, 'MinPeakProminence', 10);
    polarscatter(phase_data(min_locs), joint_data(min_locs), [], 'filled');

    pax = gca;
    pax.FontSize = 8;
    pax.RColor = Color(param.baseColor);
    pax.ThetaColor = Color(param.baseColor);
    rlim([0 180])
    rticks([0,180])
    thetaticks([0, 180]);


    hold off;
    
end
    fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]); %black background 

    % han=axes(fig,'visible','off'); 
    % han.Title.Visible='on';
    % title(han, [strrep(data_idx, '_', ' ') ' walking bout with peaks'], 'color', Color(param.baseColor));
    % han.FontSize = 20;

    %Save!
    fig_name = [strrep(data_idx, '_', ' ') ' walking ' num2str(bout) ' bouts with peaks'];
    save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Peaks and troughs x phase (DENSITY PLOT)

%get all peaks and troughs from walking bouts, and corresponding phases
peak_joint = [];
peak_phase = [];
trough_joint = [];
trough_phase = [];
for bout = 1:height(walking.bouts)
    trim = 3; %trim this number of frames off start/end of bout to have a cleaner plot
    phase_data = walking.bouts{bout}.(phase_idx)(trim:end-trim);
    joint_data = walking.bouts{bout}.(data_idx)(trim:end-trim);

    [max_pks, max_locs, max_w, max_p] = findpeaks(joint_data, 'MinPeakProminence', 10);
    [min_pks, min_locs, min_w, min_p] = findpeaks(joint_data*-1, 'MinPeakProminence', 10);
    
    peak_joint = [peak_joint; joint_data(max_locs)]; 
    peak_phase = [peak_phase; phase_data(max_locs)]; 
    trough_joint = [trough_joint; joint_data(min_locs)]; 
    trough_phase = [trough_phase; phase_data(min_locs)];
end

%bin phase and angle to compute density 

sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig
% sigdig = 2; sigstep = 0.01; %sigstep should be rounded to sigdig
if sigdig == 1; dotSize = 20; elseif sigdig == 2; dotSize = 3; end

peak_phase_binned = round(peak_phase, sigdig);
trough_phase_binned = round(trough_phase, sigdig);


%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
angle_bins = [0:2:180];
%make a matrix of phase for plotting 
phase_matrix = phase_bins;
for b = 2:width(angle_bins)-1
   phase_matrix(:,end+1) = phase_bins;
end

%PEAK density 
peak_byPhase = NaN(height(phase_bins), height(phase_bins));
peak_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
peak_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    peak_idxs = find(peak_phase_binned == phase_bins(ph));
    peak_dataPerPhase(ph) = height(peak_idxs); %how many data points per frame
    peak_theseAngles = peak_joint(peak_idxs)';
    peak_byPhase(ph,1:width(peak_joint(peak_idxs)')) = peak_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(peak_theseAngles > angle_bins(b) & peak_theseAngles <= angle_bins(b+1));
       if isempty(count)
           peak_anglePlot(ph,b) = NaN;
           peak_angleCount(ph,b) = NaN;
       else
           peak_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           peak_angleCount(ph,b) = sum(count);
       end
       
    end
end

%TROUGH density 
trough_byPhase = NaN(height(phase_bins), height(phase_bins));
trough_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
trough_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    trough_idxs = find(trough_phase_binned == phase_bins(ph));
    trough_dataPerPhase(ph) = height(trough_idxs); %how many data points per frame
    trough_theseAngles = trough_joint(trough_idxs)';
    trough_byPhase(ph,1:width(trough_joint(trough_idxs)')) = trough_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(trough_theseAngles > angle_bins(b) & trough_theseAngles <= angle_bins(b+1));
       if isempty(count)
           trough_anglePlot(ph,b) = NaN;
           trough_angleCount(ph,b) = NaN;
       else
           trough_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           trough_angleCount(ph,b) = sum(count);
       end
       
    end
end


%plot
fig = fullfig;
plotting.nRows = 1;
plotting.nCols = 2;

subplot(plotting.nRows,plotting.nCols,1);

max_pk = max(peak_angleCount(:)); max_pk_str = num2str(max_pk);
min_pk = min(peak_angleCount(:)); min_pk_str = num2str(min_pk);

% ps = polarscatter(phase_matrix(:), peak_anglePlot(:), [dotSize], peak_angleCount(:),'filled');
ps = polarscatter(phase_matrix(:), peak_anglePlot(:), peak_angleCount(:)/(max_pk/40), peak_angleCount(:),'filled');

title('Peaks')
pax = gca;
pax.FontSize = 20;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%color bar legend
cb = colorbar('Ticks',[min_pk, max_pk],...
      'TickLabels',{min_pk_str, max_pk_str}, 'color', Color(param.baseColor));

subplot(plotting.nRows,plotting.nCols,2);

max_tr = max(trough_angleCount(:)); max_tr_str = num2str(max_tr);
min_tr = min(trough_angleCount(:)); min_tr_str = num2str(min_tr);

% polarscatter(phase_matrix(:), trough_anglePlot(:), [dotSize], trough_angleCount(:),'filled');
polarscatter(phase_matrix(:), trough_anglePlot(:), trough_angleCount(:)/(max_tr/40), trough_angleCount(:),'filled');


title('Troughs')
pax = gca;
pax.FontSize = 20;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%color bar legend
cb = colorbar('Ticks',[min_tr, max_tr],...
      'TickLabels',{min_tr_str, max_tr_str}, 'color', Color(param.baseColor));

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]); %black background 

%Save!
fig_name = [strrep(data_idx, '_', ' ') ' walking bout peaks and troughs x phase (DENSITY)'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Peaks and troughs x phase (HISTOGRAM PLOT)

%get all peaks and troughs from walking bouts, and corresponding phases
peak_phase = [];
trough_phase = [];
for bout = 1:height(walking.bouts)
    trim = 3; %trim this number of frames off start/end of bout to have a cleaner plot
    phase_data = walking.bouts{bout}.(phase_idx)(trim:end-trim);
    joint_data = walking.bouts{bout}.(data_idx)(trim:end-trim);

    [max_pks, max_locs, max_w, max_p] = findpeaks(joint_data, 'MinPeakProminence', 10);
    [min_pks, min_locs, min_w, min_p] = findpeaks(joint_data*-1, 'MinPeakProminence', 10);
    
    peak_phase = [peak_phase; phase_data(max_locs)]; 
    trough_phase = [trough_phase; phase_data(min_locs)];
end

%plot
fig = fullfig;
plotting.nRows = 1;
plotting.nCols = 2;

subplot(plotting.nRows,plotting.nCols,1);
% histogram(peak_phase, 100);
ph = polarhistogram(peak_phase,100);
title('Peaks')
pax = gca;
pax.FontSize = 20;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
thetaticks([0, 45, 90, 135, 180, 225, 270,315]);

subplot(plotting.nRows,plotting.nCols,2);
% histogram(trough_phase, 100);
ph = polarhistogram(trough_phase, 100);
title('Troughs')
pax = gca;
pax.FontSize = 20;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
thetaticks([0, 45, 90, 135, 180, 225, 270, 315]);

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]); %black background 

%Save!
fig_name = [strrep(data_idx, '_', ' ') ' walking bout peaks and troughs x phase (HISTOGRAM)'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Offset btw troughs of joint data and troughs of phase, and btw peaks of joint data and zeros of phase
% look to see if the offsets are gaussian 


%get all peaks and troughs from walking bouts, and corresponding phases
peak_offsets = [];
trough_offsets = [];
for bout = 1:height(walking.bouts)
    trim = 3; %trim this number of frames off start/end of bout to have a cleaner plot
    phase_data = walking.bouts{bout}.(phase_idx)(trim:end-trim);
    joint_data = walking.bouts{bout}.(data_idx)(trim:end-trim);

     [max_j_pks, max_j_locs, max_j_w, max_j_p] = findpeaks(joint_data, 'MinPeakProminence', 10);
    [min_j_pks, min_j_locs, min_j_w, min_j_p] = findpeaks(joint_data*-1, 'MinPeakProminence', 10);
    
    [max_p_pks, max_p_locs, max_p_w, max_p_p] = findpeaks(abs(phase_data)*-1, 'MinPeakProminence', 3);
    [min_p_pks, min_p_locs, min_p_w, min_p_p] = findpeaks(phase_data*-1, 'MinPeakProminence', 3);
    
    if height(min_j_locs) == height(min_p_locs)
        trough_offsets = [trough_offsets; min_j_locs - min_p_locs];
    end
    if height(max_j_locs) == height(max_p_locs)
        peak_offsets = [peak_offsets; max_j_locs - max_p_locs];
    end
    
end

%plot
fig = fullfig;
plotting.nRows = 1;
plotting.nCols = 2;

subplot(plotting.nRows,plotting.nCols,1);
histogram(peak_offsets, 100);
title('Peak offsets')

subplot(plotting.nRows,plotting.nCols,2);
histogram(trough_offsets, 100);
title('Trough offsets')


fig = formatFig(fig, true, [plotting.nRows, plotting.nCols]); %black background 

%Save!
fig_name = [strrep(data_idx, '_', ' ') ' walking bout joint troughs & peaks offsets from phase peaks & zeros (HISTOGRAM)'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% Phase Offsets %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CALCULATE Phase offsets between legs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars('-except',initial_vars{:});
initial_vars = who;

comp_leg = 4; %comparison leg 
T2_rot = 1; %1 if use rotation phase for T2 legs, 0 if use angle phase like T1 and T3 legs (results are much better when T2_rot == 1)
joint = 3; jnt_str = param.joints{joint}; %joint phase to compare TODO compare rotation for T2? TODO do tarsi y postition instead?

trim = 3; %frames to trim off beginning and end of walking bout for better data quality 
   
phase_offsets = NaN(1,8);
start_idx = 0; 
for bout = 1:height(walking.bouts)
    %get unwrapped phase for comparison leg
    ph_idx = [param.legs{comp_leg} '_' param.joints{joint} '_phase'];
    comp_phase = unwrap(walking.bouts{bout}.(ph_idx));
     
    for leg = 1:6
        if T2_rot & (leg == 2 | leg == 5)
            ph_idx = [param.legs{leg} 'B_rot_phase']; % Be careful! I only have rotation for B (CF) joint
        else
            ph_idx = [param.legs{leg} '_' param.joints{joint} '_phase'];
        end
        this_phase = unwrap(walking.bouts{bout}.(ph_idx));
        ph_offset = comp_phase - this_phase;
        h = height(ph_offset);
        phase_offsets(start_idx+1:start_idx+h, leg) = ph_offset;
    end
    
    %add stim vs control (0 = control, 1 = stim)
    this_laser = walking.meta.boutinfo(bout).laser;
    laser_endIdx = param.laser_on +(param.fps * this_laser);
    bout_startIdx = walking.meta.boutinfo(bout).startIdx;
    bout_endIdx = walking.meta.boutinfo(bout).endIdx;
    condition = zeros(h,1);
    if this_laser == 0 | bout_startIdx >= laser_endIdx | bout_endIdx <= param.laser_on
        condition = zeros(h,1);
    else
        condition = zeros(h,1);
        %the laser is on for some portion of the walking bout 
        startStim = max(param.laser_on, bout_startIdx); 
        endStim = min(laser_endIdx, bout_endIdx);
        endStim = endStim - startStim+1; %convert from idx in vid to idx in bout
        startStim = startStim - startStim+1;
        condition(startStim:endStim,1) = 1;
    end
    phase_offsets(start_idx+1:start_idx+h, 7) = condition;  
    
    %add fly number
    phase_offsets(start_idx+1:start_idx+h, 8) = ones(h,1)*walking.meta.boutinfo(bout).flyNum;  

    
    start_idx = start_idx + h;
end

%% PLOT phase offsets across flies 
fig = fullfig;
param.nRows = 2; 
param.nCols = 3;
phase_table = array2table(phase_offsets); 
phase_table.Properties.VariableNames = {'L1','L2','L3','R1','R2','R3','stimOn','fly'};
order = [4,5,6,1,2,3];
for leg = 1:6
    subplot(param.nRows, param.nCols, order(leg));
    h1 = polarhistogram(phase_table{phase_table.stimOn == 0,leg}, 'Normalization', 'pdf'); hold on;
    h2 = polarhistogram(phase_table{phase_table.stimOn == 1,leg}, 'Normalization', 'pdf'); 
    h1.FaceColor = param.baseColor;
    h2.FaceColor = Color(param.expColor);
    title(param.legs(leg));
    pax = gca;
    pax.FontSize = 14;
    pax.RColor = Color(param.baseColor);
    pax.ThetaColor = Color(param.baseColor); 
    thetaticks([0, 90, 180, 270]);
    hold off;
end

fig = formatFigPolar(fig, true, [param.nRows, param.nCols]);


%Save!
fig_name = ['Phase offsets from ' param.legs{comp_leg}];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT phase offsets for each fly 
fly = 8; % alter this to plot different flies 

fig = fullfig;
param.nRows = 2; 
param.nCols = 3;
phase_table = array2table(phase_offsets); 
phase_table.Properties.VariableNames = {'L1','L2','L3','R1','R2','R3','stimOn','fly'};
order = [4,5,6,1,2,3];
for leg = 1:6
    subplot(param.nRows, param.nCols, order(leg));
    h1 = polarhistogram(phase_table{phase_table.stimOn == 0 & phase_table.fly == fly,leg}, 'Normalization', 'pdf'); hold on;
    h2 = polarhistogram(phase_table{phase_table.stimOn == 1 & phase_table.fly == fly,leg}, 'Normalization', 'pdf'); 
    h1.FaceColor = param.baseColor;
    h2.FaceColor = Color(param.expColor);
    title(param.legs(leg));
    pax = gca;
    pax.FontSize = 14;
    pax.RColor = Color(param.baseColor);
    pax.ThetaColor = Color(param.baseColor); 
    thetaticks([0, 90, 180, 270]);
    hold off;
end

fig = formatFigPolar(fig, true, [param.nRows, param.nCols]);

%Save!
fig_name = ['Phase offsets from ' param.legs{comp_leg} ' fly ' num2str(fly)];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% Joint Speed %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%if the joint angle is more flexed, and the size of the range of joints it 
%moves through per step is the same, then if the phase offset isn't
%different, the speed of the joint angle change has to be changing. 

%% PLOT jnt angle distribution 

joint = listdlg('ListString', param.joints, 'PromptString','Select laser:', 'SelectionMode','single', 'ListSize', [100 100]);
joint_str = param.joints{joint};
fig = fullfig;
plotting.order = [1, 3, 5, 2, 4, 6];
plotting.nRows = 3;
plotting.nCols = 2;
for leg = 1:6
    pltIdx = plotting.order(leg);
    
    %find number of ctl flies 
    ctl_flies = [steps.control.leg{leg}.bout_meta.flyNum];
    ctl_numFlies = width(unique(ctl_flies));
    %extract ctl data
    ctl_steps = steps.control.leg{leg}.joint{joint};
    ctl_num_steps = num2str(height(ctl_steps));
       
    %find number of exp flies 
    exp_flies = [steps.experiment.leg{leg}.bout_meta.flyNum];
    exp_numFlies = width(unique(exp_flies));
    %extract ctl data
    exp_steps = steps.experiment.leg{leg}.joint{joint};
    exp_num_steps = num2str(height(exp_steps));
    
    %plot data
    subplot(plotting.nRows, plotting.nCols, pltIdx); hold on
    binEdges = linspace(0,180,37);
    h1 = histogram(ctl_steps(~isnan(ctl_steps)), binEdges, 'Normalization', 'probability', 'FaceColor', Color(param.baseColor), 'EdgeColor', Color(param.baseColor));
    h2 = histogram(exp_steps(~isnan(exp_steps)), binEdges, 'Normalization', 'probability', 'FaceColor', Color(param.expColor), 'EdgeColor', Color(param.expColor)); 
    hold off;
    %label
    if pltIdx == 1
           xlabel([joint_str ' (' char(176) ')']);
           title(['L1 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 2
           title(['R1 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 3
           ylabel('Probability');
           title(['L2 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 4
           title(['R2 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 5
           title(['L3 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 6 
           title(['R3 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
    end    
    
end
fig = formatFig(fig, true, [plotting.nRows, plotting.nCols]);


%full figure title
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ['Step ' joint_str ' Joint Angle Distribution']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

%Save!
fig_name = ['\step_' joint_str '_distribution_overview'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Joint data x phase 
leg = 1; 
joint = 3; 

legJntStr = [param.legs{leg} '_' param.joints{joint}];
data = [];
phase = [];
trim = 1;
for bout = 1:height(walking.bouts)
    data = [data; walking.bouts{bout}.(legJntStr)];
    phase = [phase; walking.bouts{bout}.([legJntStr '_phase'])];
end

%get rid of data where phase is nan
goodData = ~isnan(phase);
phase = phase(goodData);
data = data(goodData);

phase_bins = linspace(-pi,pi,param.phaseStep);
angle_bins = [0:2:180]';

[counts] = histcounts2(phase,data,phase_bins,angle_bins);
counts(counts==0) = NaN;

plot_phase = repmat(conv(phase_bins, [0.5 0.5], 'valid'),1,width(counts));
plot_data = repmat(conv(angle_bins, [0.5 0.5], 'valid')', height(counts),1);

fig = fullfig;
polarscatter(plot_phase(:), plot_data(:), counts(:)/5, counts(:), 'filled');

title('All data')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%color bar legend
mini = min(counts(:));
maxi = max(counts(:));
colorbar('Ticks',[mini, maxi],...
      'TickLabels',{num2str(mini), num2str(maxi)}, 'color', Color(param.baseColor));

fig = formatFigPolar(fig, true);

%  histogram2(phase, data); 

%Save!
fig_name = [param.legs{leg} ' ' param.joints{joint} ' x phase (by bout) - all data'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Joint data x phase - control vs stim 
leg = 1; 
joint = 3; 

fig = fullfig;
plotting.nRows = 1; 
plotting.nCols = 2; 

legJntStr = [param.legs{leg} '_' param.joints{joint}];
data = [];
phase = [];
fly = [];
stim = [];
for bout = 1:height(walking.bouts)
    data = [data; walking.bouts{bout}.(legJntStr)];
    phase = [phase; walking.bouts{bout}.([legJntStr '_phase'])];
    fly = [fly; ones(height(walking.bouts{bout}.(legJntStr)),1) * walking.meta.boutinfo(bout).flyNum];
    stim = [stim; DLC_calculate_stim(walking.meta.boutinfo(bout).startIdx, walking.meta.boutinfo(bout).endIdx, walking.meta.boutinfo(bout).laser, param)];
end

%get rid of data where phase is nan
goodData = ~isnan(phase);
phase = phase(goodData);
data = data(goodData);
fly = fly(goodData);
stim = stim(goodData);

phase_bins = linspace(-pi,pi,param.phaseStep);
angle_bins = [0:2:180]';


%control 
subplot(plotting.nRows, plotting.nCols, 1);

[counts_ctl] = histcounts2(phase(stim == 0),data(stim == 0),phase_bins,angle_bins);
counts_ctl(counts_ctl==0) = NaN;

plot_phase_ctl = repmat(conv(phase_bins, [0.5 0.5], 'valid'),1,width(counts_ctl));
plot_data_ctl = repmat(conv(angle_bins, [0.5 0.5], 'valid')', height(counts_ctl),1);

polarscatter(plot_phase_ctl(:), plot_data_ctl(:), counts_ctl(:)/5, counts_ctl(:), 'filled'); hold on;

title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%color bar legend
min_ctl = min(counts_ctl(:));
max_ctl = max(counts_ctl(:));
cb = colorbar('Ticks',[min_ctl, max_ctl],...
      'TickLabels',{num2str(min_ctl), num2str(max_ctl)}, 'color', Color(param.baseColor));

%experimental 
subplot(plotting.nRows, plotting.nCols, 2);

[counts_exp] = histcounts2(phase(stim == 1),data(stim == 1),phase_bins,angle_bins);
counts_exp(counts_exp==0) = NaN;

plot_phase_exp = repmat(conv(phase_bins, [0.5 0.5], 'valid'),1,width(counts_exp));
plot_data_exp = repmat(conv(angle_bins, [0.5 0.5], 'valid')', height(counts_exp),1);

polarscatter(plot_phase_exp(:), plot_data_exp(:), counts_exp(:), counts_exp(:), 'filled');

title('Stim')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%color bar legend
min_exp = min(counts_exp(:));
max_exp = max(counts_exp(:));
cb = colorbar('Ticks',[min_exp, max_exp],...
      'TickLabels',{num2str(min_exp), num2str(max_exp)}, 'color', Color(param.baseColor));

hold off;

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

%  histogram2(phase, data); 

%Save!
fig_name = [param.legs{leg} ' ' param.joints{joint} ' x phase (by bout) - ctl vs stim'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Joint data x phase - control vs stim - with mean & std
leg = 1; 
joint = 3; 

fig = fullfig;
plotting.nRows = 2; 
plotting.nCols = 2; 

legJntStr = [param.legs{leg} '_' param.joints{joint}];
data = [];
phase = [];
fly = [];
stim = [];
for bout = 1:height(walking.bouts)
    data = [data; walking.bouts{bout}.(legJntStr)];
    phase = [phase; walking.bouts{bout}.([legJntStr '_phase'])];
    fly = [fly; ones(height(walking.bouts{bout}.(legJntStr)),1) * walking.meta.boutinfo(bout).flyNum];
    stim = [stim; DLC_calculate_stim(walking.meta.boutinfo(bout).startIdx, walking.meta.boutinfo(bout).endIdx, walking.meta.boutinfo(bout).laser, param)];
end

%get rid of data where phase is nan
goodData = ~isnan(phase);
phase = phase(goodData);
data = data(goodData);
fly = fly(goodData);
stim = stim(goodData);

phase_bins = linspace(-pi,pi,param.phaseStep);
angle_bins = [0:2:180]';


%control 
subplot(plotting.nRows, plotting.nCols, 1);

[counts_ctl] = histcounts2(phase(stim == 0),data(stim == 0),phase_bins,angle_bins);
counts_ctl(counts_ctl==0) = NaN;

plot_phase_ctl = repmat(conv(phase_bins, [0.5 0.5], 'valid'),1,width(counts_ctl));
plot_data_ctl = repmat(conv(angle_bins, [0.5 0.5], 'valid')', height(counts_ctl),1);

polarscatter(plot_phase_ctl(:), plot_data_ctl(:), counts_ctl(:)/5, counts_ctl(:), 'filled'); hold on;

title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%color bar legend
min_ctl = min(counts_ctl(:));
max_ctl = max(counts_ctl(:));
cb = colorbar('Ticks',[min_ctl, max_ctl],...
      'TickLabels',{num2str(min_ctl), num2str(max_ctl)}, 'color', Color(param.baseColor));
  
%experimental 
subplot(plotting.nRows, plotting.nCols, 2);

[counts_exp] = histcounts2(phase(stim == 1),data(stim == 1),phase_bins,angle_bins);
counts_exp(counts_exp==0) = NaN;

plot_phase_exp = repmat(conv(phase_bins, [0.5 0.5], 'valid'),1,width(counts_exp));
plot_data_exp = repmat(conv(angle_bins, [0.5 0.5], 'valid')', height(counts_exp),1);

polarscatter(plot_phase_exp(:), plot_data_exp(:), counts_exp(:), counts_exp(:), 'filled');

title('Stim')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%color bar legend
min_exp = min(counts_exp(:));
max_exp = max(counts_exp(:));
cb = colorbar('Ticks',[min_exp, max_exp],...
      'TickLabels',{num2str(min_exp), num2str(max_exp)}, 'color', Color(param.baseColor));

%means and std
subplot(plotting.nRows, plotting.nCols, 3);

%bin data by phase
data_bins = discretize(phase, phase_bins); 

%take the mean of the data in each phase bin 
ctl_data_means = NaN(1,width(phase_bins)); 
exp_data_means = NaN(1,width(phase_bins)); 
ctl_data_std = NaN(1,width(phase_bins)); 
exp_data_std = NaN(1,width(phase_bins)); 
for ph = 1:width(phase_bins)
    ctl_data_means(1,ph) = nanmean(data(stim == 0 & data_bins == ph));
    exp_data_means(1,ph) = nanmean(data(stim == 1 & data_bins == ph));
    
    ctl_data_std(1,ph) = nanstd(data(stim == 0 & data_bins == ph));
    exp_data_std(1,ph) = nanstd(data(stim == 1 & data_bins == ph));
end

%plot mean
polarplot(phase_bins, ctl_data_means, 'Color', param.baseColor, 'LineWidth', 1); hold on;
polarplot(phase_bins, exp_data_means, 'Color', Color(param.expColor), 'LineWidth', 1);
title('Mean')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
thetaticks([0, 90, 180, 270]);
rlim([0 180])
rticks([0,45,90,135,180])
hold off;

%plot std
subplot(plotting.nRows, plotting.nCols, 4);
polarplot(phase_bins, ctl_data_std, 'Color', param.baseColor, 'LineWidth', 1); hold on;
polarplot(phase_bins, smooth(exp_data_std), 'Color', Color(param.expColor), 'LineWidth', 1);
title('Standard Deviation')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
thetaticks([0, 90, 180, 270]);
hold off;

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

%  histogram2(phase, data); 

%Save!
fig_name = [param.legs{leg} ' ' param.joints{joint} ' x phase (by bout) - ctl vs stim - with mean and std - Rzoom'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
 
%% Velocity data x phase
leg = 1; 
joint = 3; 

legJntStr = [param.legs{leg} '_' param.joints{joint}];
data = [];
phase = [];
trim = 1;
for bout = 1:height(walking.bouts)
    data = [data; walking.bouts{bout}.([legJntStr '_velocity'])];
    phase = [phase; walking.bouts{bout}.([legJntStr '_phase'])];
end

%get rid of data where phase is nan
goodData = ~isnan(phase);
phase = phase(goodData);
data = data(goodData);

phase_bins = linspace(-pi,pi,param.phaseStep);
velocity_bins = [-20:0.5:20]';

[counts] = histcounts2(phase,data,phase_bins,velocity_bins);
counts(counts==0) = NaN;

plot_phase = repmat(conv(phase_bins, [0.5 0.5], 'valid'),1,width(counts));
plot_data = repmat(conv(velocity_bins, [0.5 0.5], 'valid')', height(counts),1);

fig = fullfig;
ps = polarscatter(plot_phase(:), plot_data(:), counts(:)/5, counts(:), 'filled');

title('All data')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([min(velocity_bins) max(velocity_bins)])
thetaticks([0, 90, 180, 270]);

%color bar legend
mini = min(counts(:));
maxi = max(counts(:));
colorbar('Ticks',[mini, maxi],...
      'TickLabels',{num2str(mini), num2str(maxi)}, 'color', Color(param.baseColor));

fig = formatFigPolar(fig, true);

%Save!
fig_name = [param.legs{leg} ' ' param.joints{joint} ' velocity x phase (by bout) - all data'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Velocity data x phase - control vs stim 
leg = 1; 
joint = 3; 

fig = fullfig;
plotting.nRows = 1; 
plotting.nCols = 2; 

legJntStr = [param.legs{leg} '_' param.joints{joint}];
data = [];
phase = [];
fly = [];
stim = [];
for bout = 1:height(walking.bouts)
    data = [data; walking.bouts{bout}.([legJntStr '_velocity'])];
    phase = [phase; walking.bouts{bout}.([legJntStr '_phase'])];
    fly = [fly; ones(height(walking.bouts{bout}.(legJntStr)),1) * walking.meta.boutinfo(bout).flyNum];
    stim = [stim; DLC_calculate_stim(walking.meta.boutinfo(bout).startIdx, walking.meta.boutinfo(bout).endIdx, walking.meta.boutinfo(bout).laser, param)];
end

%get rid of data where phase is nan
goodData = ~isnan(phase);
phase = phase(goodData);
data = data(goodData);
fly = fly(goodData);
stim = stim(goodData);

phase_bins = linspace(-pi,pi,param.phaseStep);
velocity_bins = [-20:0.5:20]';


%control 
subplot(plotting.nRows, plotting.nCols, 1);

[counts_ctl] = histcounts2(phase(stim == 0),data(stim == 0),phase_bins,velocity_bins);
counts_ctl(counts_ctl==0) = NaN;

plot_phase_ctl = repmat(conv(phase_bins, [0.5 0.5], 'valid'),1,width(counts_ctl));
plot_data_ctl = repmat(conv(velocity_bins, [0.5 0.5], 'valid')', height(counts_ctl),1);

polarscatter(plot_phase_ctl(:), plot_data_ctl(:), counts_ctl(:)/5, counts_ctl(:), 'filled'); hold on;

title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([min(velocity_bins) max(velocity_bins)])
thetaticks([0, 90, 180, 270]);

%color bar legend
min_ctl = min(counts_ctl(:));
max_ctl = max(counts_ctl(:));
cb = colorbar('Ticks',[min_ctl, max_ctl],...
      'TickLabels',{num2str(min_ctl), num2str(max_ctl)}, 'color', Color(param.baseColor));

%experimental 
subplot(plotting.nRows, plotting.nCols, 2);

[counts_exp] = histcounts2(phase(stim == 1),data(stim == 1),phase_bins,velocity_bins);
counts_exp(counts_exp==0) = NaN;

plot_phase_exp = repmat(conv(phase_bins, [0.5 0.5], 'valid'),1,width(counts_exp));
plot_data_exp = repmat(conv(velocity_bins, [0.5 0.5], 'valid')', height(counts_exp),1);

polarscatter(plot_phase_exp(:), plot_data_exp(:), counts_exp(:), counts_exp(:), 'filled');

title('Stim')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([min(velocity_bins) max(velocity_bins)])
thetaticks([0, 90, 180, 270]);

%color bar legend
min_exp = min(counts_exp(:));
max_exp = max(counts_exp(:));
cb = colorbar('Ticks',[min_exp, max_exp],...
      'TickLabels',{num2str(min_exp), num2str(max_exp)}, 'color', Color(param.baseColor));

hold off;

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

%  histogram2(phase, data); 


%Save!
fig_name = [param.legs{leg} ' ' param.joints{joint} ' velocity x phase (by bout) - ctl vs stim'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Velocity data x phase - control vs stim - with mean & std 
leg = 1; 
joint = 3; 

fig = fullfig;
plotting.nRows = 2; 
plotting.nCols = 2; 

legJntStr = [param.legs{leg} '_' param.joints{joint}];
data = [];
phase = [];
fly = [];
stim = [];
for bout = 1:height(walking.bouts)
    data = [data; walking.bouts{bout}.([legJntStr '_velocity'])];
    phase = [phase; walking.bouts{bout}.([legJntStr '_phase'])];
    fly = [fly; ones(height(walking.bouts{bout}.(legJntStr)),1) * walking.meta.boutinfo(bout).flyNum];
    stim = [stim; DLC_calculate_stim(walking.meta.boutinfo(bout).startIdx, walking.meta.boutinfo(bout).endIdx, walking.meta.boutinfo(bout).laser, param)];
end

%get rid of data where phase is nan
goodData = ~isnan(phase);
phase = phase(goodData);
data = data(goodData);
fly = fly(goodData);
stim = stim(goodData);

phase_bins = linspace(-pi,pi,param.phaseStep);
velocity_bins = [-20:0.5:20]';


%control 
subplot(plotting.nRows, plotting.nCols, 1);

[counts_ctl] = histcounts2(phase(stim == 0),data(stim == 0),phase_bins,velocity_bins);
counts_ctl(counts_ctl==0) = NaN;

plot_phase_ctl = repmat(conv(phase_bins, [0.5 0.5], 'valid'),1,width(counts_ctl));
plot_data_ctl = repmat(conv(velocity_bins, [0.5 0.5], 'valid')', height(counts_ctl),1);

polarscatter(plot_phase_ctl(:), plot_data_ctl(:), counts_ctl(:)/5, counts_ctl(:), 'filled'); hold on;

title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([min(velocity_bins) max(velocity_bins)])
thetaticks([0, 90, 180, 270]);

%color bar legend
min_ctl = min(counts_ctl(:));
max_ctl = max(counts_ctl(:));
cb = colorbar('Ticks',[min_ctl, max_ctl],...
      'TickLabels',{num2str(min_ctl), num2str(max_ctl)}, 'color', Color(param.baseColor));

%experimental 
subplot(plotting.nRows, plotting.nCols, 2);

[counts_exp] = histcounts2(phase(stim == 1),data(stim == 1),phase_bins,velocity_bins);
counts_exp(counts_exp==0) = NaN;

plot_phase_exp = repmat(conv(phase_bins, [0.5 0.5], 'valid'),1,width(counts_exp));
plot_data_exp = repmat(conv(velocity_bins, [0.5 0.5], 'valid')', height(counts_exp),1);

polarscatter(plot_phase_exp(:), plot_data_exp(:), counts_exp(:), counts_exp(:), 'filled');

title('Stim')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([min(velocity_bins) max(velocity_bins)])
thetaticks([0, 90, 180, 270]);

%color bar legend
min_exp = min(counts_exp(:));
max_exp = max(counts_exp(:));
cb = colorbar('Ticks',[min_exp, max_exp],...
      'TickLabels',{num2str(min_exp), num2str(max_exp)}, 'color', Color(param.baseColor));


%means and std
subplot(plotting.nRows, plotting.nCols, 3);

%bin data by phase
data_bins = discretize(phase, phase_bins); 

%take the mean of the data in each phase bin 
ctl_data_means = NaN(1,width(phase_bins)); 
exp_data_means = NaN(1,width(phase_bins)); 
ctl_data_std = NaN(1,width(phase_bins)); 
exp_data_std = NaN(1,width(phase_bins)); 
for ph = 1:width(phase_bins)
    ctl_data_means(1,ph) = nanmean(data(stim == 0 & data_bins == ph));
    exp_data_means(1,ph) = nanmean(data(stim == 1 & data_bins == ph));
    
    ctl_data_std(1,ph) = nanstd(data(stim == 0 & data_bins == ph));
    exp_data_std(1,ph) = nanstd(data(stim == 1 & data_bins == ph));
end

%plot mean
polarplot(phase_bins, ctl_data_means, 'Color', param.baseColor, 'LineWidth', 1); hold on;
polarplot(phase_bins, exp_data_means, 'Color', Color(param.expColor), 'LineWidth', 1);
title('Mean')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([min([ctl_data_means(:); exp_data_means(:)])-2 max([ctl_data_means(:); exp_data_means(:)])+2])
thetaticks([0, 90, 180, 270]);
hold off;

%plot std
subplot(plotting.nRows, plotting.nCols, 4);
polarplot(phase_bins, smooth(ctl_data_std), 'Color', param.baseColor, 'LineWidth', 1); hold on;
polarplot(phase_bins, smooth(exp_data_std), 'Color', Color(param.expColor), 'LineWidth', 1);
title('Standard Deviation')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([min([ctl_data_std(:); exp_data_std(:)])-2 max([ctl_data_std(:); exp_data_std(:)])+2])
thetaticks([0, 90, 180, 270]);
hold off;

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

%  histogram2(phase, data); 


%Save!
fig_name = [param.legs{leg} ' ' param.joints{joint} ' velocity x phase (by bout) - ctl vs stim -  - with mean and std'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Speed data x phase - control vs stim - with mean & std 
leg = 1; 
joint = 3; 

fig = fullfig;
plotting.nRows = 2; 
plotting.nCols = 2; 

legJntStr = [param.legs{leg} '_' param.joints{joint}];
data = [];
phase = [];
fly = [];
stim = [];
for bout = 1:height(walking.bouts)
    data = [data; abs(walking.bouts{bout}.([legJntStr '_velocity']))]; %speed = abs(velocity)
    phase = [phase; walking.bouts{bout}.([legJntStr '_phase'])];
    fly = [fly; ones(height(walking.bouts{bout}.(legJntStr)),1) * walking.meta.boutinfo(bout).flyNum];
    stim = [stim; DLC_calculate_stim(walking.meta.boutinfo(bout).startIdx, walking.meta.boutinfo(bout).endIdx, walking.meta.boutinfo(bout).laser, param)];
end

%get rid of data where phase is nan
goodData = ~isnan(phase);
phase = phase(goodData);
data = data(goodData);
fly = fly(goodData);
stim = stim(goodData);

phase_bins = linspace(-pi,pi,param.phaseStep);
velocity_bins = [-10:0.5:20]';


%control 
subplot(plotting.nRows, plotting.nCols, 1);

[counts_ctl] = histcounts2(phase(stim == 0),data(stim == 0),phase_bins,velocity_bins);
counts_ctl(counts_ctl==0) = NaN;

plot_phase_ctl = repmat(conv(phase_bins, [0.5 0.5], 'valid'),1,width(counts_ctl));
plot_data_ctl = repmat(conv(velocity_bins, [0.5 0.5], 'valid')', height(counts_ctl),1);

polarscatter(plot_phase_ctl(:), plot_data_ctl(:), counts_ctl(:)/(max(counts_ctl(:))/param.maxPolarDot), counts_ctl(:), 'filled'); hold on;

title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([min(velocity_bins) max(velocity_bins)])
thetaticks([0, 90, 180, 270]);

%color bar legend
min_ctl = min(counts_ctl(:));
max_ctl = max(counts_ctl(:));
cb = colorbar('Ticks',[min_ctl, max_ctl],...
      'TickLabels',{num2str(min_ctl), num2str(max_ctl)}, 'color', Color(param.baseColor));

%experimental 
subplot(plotting.nRows, plotting.nCols, 2);

[counts_exp] = histcounts2(phase(stim == 1),data(stim == 1),phase_bins,velocity_bins);
counts_exp(counts_exp==0) = NaN;

plot_phase_exp = repmat(conv(phase_bins, [0.5 0.5], 'valid'),1,width(counts_exp));
plot_data_exp = repmat(conv(velocity_bins, [0.5 0.5], 'valid')', height(counts_exp),1);

polarscatter(plot_phase_exp(:), plot_data_exp(:), counts_exp(:)/(max(counts_exp(:))/param.maxPolarDot), counts_exp(:), 'filled');

title('Stim')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([min(velocity_bins) max(velocity_bins)])
thetaticks([0, 90, 180, 270]);

%color bar legend
min_exp = min(counts_exp(:));
max_exp = max(counts_exp(:));
cb = colorbar('Ticks',[min_exp, max_exp],...
      'TickLabels',{num2str(min_exp), num2str(max_exp)}, 'color', Color(param.baseColor));


%means and std
subplot(plotting.nRows, plotting.nCols, 3);

%bin data by phase
data_bins = discretize(phase, phase_bins); 

%take the mean of the data in each phase bin 
ctl_data_means = NaN(1,width(phase_bins)); 
exp_data_means = NaN(1,width(phase_bins)); 
ctl_data_std = NaN(1,width(phase_bins)); 
exp_data_std = NaN(1,width(phase_bins)); 
for ph = 1:width(phase_bins)
    ctl_data_means(1,ph) = nanmean(data(stim == 0 & data_bins == ph));
    exp_data_means(1,ph) = nanmean(data(stim == 1 & data_bins == ph));
    
    ctl_data_std(1,ph) = nanstd(data(stim == 0 & data_bins == ph));
    exp_data_std(1,ph) = nanstd(data(stim == 1 & data_bins == ph));
end

%plot mean
polarplot(phase_bins, ctl_data_means, 'Color', param.baseColor, 'LineWidth', 1); hold on;
polarplot(phase_bins, exp_data_means, 'Color', Color(param.expColor), 'LineWidth', 1);
title('Mean')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([min([ctl_data_means(:); exp_data_means(:)])-2 max([ctl_data_means(:); exp_data_means(:)])+2])
thetaticks([0, 90, 180, 270]);
hold off;

%plot std
subplot(plotting.nRows, plotting.nCols, 4);
polarplot(phase_bins, smooth(ctl_data_std), 'Color', param.baseColor, 'LineWidth', 1); hold on;
polarplot(phase_bins, smooth(exp_data_std), 'Color', Color(param.expColor), 'LineWidth', 1);
title('Standard Deviation')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([min([ctl_data_std(:); exp_data_std(:)])-2 max([ctl_data_std(:); exp_data_std(:)])+2])
thetaticks([0, 90, 180, 270]);
hold off;

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

%  histogram2(phase, data); 


%Save!
fig_name = [param.legs{leg} ' ' param.joints{joint} ' speed x phase (by bout) - ctl vs stim -  - with mean and std'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Acceleration data x phase - control vs stim - with mean & std 
leg = 1; 
joint = 3; 

fig = fullfig;
plotting.nRows = 2; 
plotting.nCols = 2; 

legJntStr = [param.legs{leg} '_' param.joints{joint}];
data = [];
phase = [];
fly = [];
stim = [];
for bout = 1:height(walking.bouts)
    this_data = diff(walking.bouts{bout}.([legJntStr '_velocity']));
    data = [data; this_data/(height(this_data)/param.fps)]; %acceleration = diff(velocity) / diff(time)
    phase = [phase; walking.bouts{bout}.([legJntStr '_phase'])(1:end-1)];
    fly = [fly; ones(height(walking.bouts{bout}.(legJntStr)),1) * walking.meta.boutinfo(bout).flyNum];
    stim = [stim; DLC_calculate_stim(walking.meta.boutinfo(bout).startIdx, walking.meta.boutinfo(bout).endIdx, walking.meta.boutinfo(bout).laser, param)];
end

%get rid of data where phase is nan
goodData = ~isnan(phase);
phase = phase(goodData);
data = data(goodData);
fly = fly(goodData);
stim = stim(goodData);

phase_bins = linspace(-pi,pi,param.phaseStep);
velocity_bins = [-5:0.5:5]';


%control 
subplot(plotting.nRows, plotting.nCols, 1);

[counts_ctl] = histcounts2(phase(stim == 0),data(stim == 0),phase_bins,velocity_bins);
counts_ctl(counts_ctl==0) = NaN;

plot_phase_ctl = repmat(conv(phase_bins, [0.5 0.5], 'valid'),1,width(counts_ctl));
plot_data_ctl = repmat(conv(velocity_bins, [0.5 0.5], 'valid')', height(counts_ctl),1);

polarscatter(plot_phase_ctl(:), plot_data_ctl(:), counts_ctl(:)/(max(counts_ctl(:))/param.maxPolarDot), counts_ctl(:), 'filled'); hold on;

title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([min(velocity_bins) max(velocity_bins)])
thetaticks([0, 90, 180, 270]);

%color bar legend
min_ctl = min(counts_ctl(:));
max_ctl = max(counts_ctl(:));
cb = colorbar('Ticks',[min_ctl, max_ctl],...
      'TickLabels',{num2str(min_ctl), num2str(max_ctl)}, 'color', Color(param.baseColor));

%experimental 
subplot(plotting.nRows, plotting.nCols, 2);

[counts_exp] = histcounts2(phase(stim == 1),data(stim == 1),phase_bins,velocity_bins);
counts_exp(counts_exp==0) = NaN;

plot_phase_exp = repmat(conv(phase_bins, [0.5 0.5], 'valid'),1,width(counts_exp));
plot_data_exp = repmat(conv(velocity_bins, [0.5 0.5], 'valid')', height(counts_exp),1);

polarscatter(plot_phase_exp(:), plot_data_exp(:), counts_exp(:)/(max(counts_exp(:))/param.maxPolarDot), counts_exp(:), 'filled');

title('Stim')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([min(velocity_bins) max(velocity_bins)])
thetaticks([0, 90, 180, 270]);

%color bar legend
min_exp = min(counts_exp(:));
max_exp = max(counts_exp(:));
cb = colorbar('Ticks',[min_exp, max_exp],...
      'TickLabels',{num2str(min_exp), num2str(max_exp)}, 'color', Color(param.baseColor));


%means and std
subplot(plotting.nRows, plotting.nCols, 3);

%bin data by phase
data_bins = discretize(phase, phase_bins); 

%take the mean of the data in each phase bin 
ctl_data_means = NaN(1,width(phase_bins)); 
exp_data_means = NaN(1,width(phase_bins)); 
ctl_data_std = NaN(1,width(phase_bins)); 
exp_data_std = NaN(1,width(phase_bins)); 
for ph = 1:width(phase_bins)
    ctl_data_means(1,ph) = nanmean(data(stim == 0 & data_bins == ph));
    exp_data_means(1,ph) = nanmean(data(stim == 1 & data_bins == ph));
    
    ctl_data_std(1,ph) = nanstd(data(stim == 0 & data_bins == ph));
    exp_data_std(1,ph) = nanstd(data(stim == 1 & data_bins == ph));
end

%plot mean
polarplot(phase_bins, smooth(ctl_data_means), 'Color', param.baseColor, 'LineWidth', 1); hold on;
polarplot(phase_bins, smooth(exp_data_means), 'Color', Color(param.expColor), 'LineWidth', 1);
title('Mean')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([min([ctl_data_means(:); exp_data_means(:)])-2 max([ctl_data_means(:); exp_data_means(:)])+2])
thetaticks([0, 90, 180, 270]);
hold off;

%plot std
subplot(plotting.nRows, plotting.nCols, 4);
polarplot(phase_bins, smooth(ctl_data_std), 'Color', param.baseColor, 'LineWidth', 1); hold on;
polarplot(phase_bins, smooth(exp_data_std), 'Color', Color(param.expColor), 'LineWidth', 1);
title('Standard Deviation')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([min([ctl_data_std(:); exp_data_std(:)])-2 max([ctl_data_std(:); exp_data_std(:)])+2])
thetaticks([0, 90, 180, 270]);
hold off;

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

%  histogram2(phase, data); 

%Save!
fig_name = [param.legs{leg} ' ' param.joints{joint} ' acceleration x phase (by bout) - ctl vs stim -  - with mean and std'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Jerk data x phase - control vs stim - with mean & std 
leg = 1; 
joint = 3; 

fig = fullfig;
plotting.nRows = 2; 
plotting.nCols = 2; 

legJntStr = [param.legs{leg} '_' param.joints{joint}];
data = [];
phase = [];
fly = [];
stim = [];
for bout = 1:height(walking.bouts)
    this_data = walking.bouts{bout}.([legJntStr '_velocity']);
    this_acceleration = diff(this_data)/(height(this_data)/param.fps); %acceleration = diff(velocity) / diff(time)
    data = [data; diff(this_acceleration)/(height(this_acceleration)/param.fps)]; %jerk = diff(acceleration) / diff(time)
    phase = [phase; walking.bouts{bout}.([legJntStr '_phase'])(1:end-2)];
    fly = [fly; ones(height(walking.bouts{bout}.(legJntStr)),1) * walking.meta.boutinfo(bout).flyNum];
    stim = [stim; DLC_calculate_stim(walking.meta.boutinfo(bout).startIdx, walking.meta.boutinfo(bout).endIdx, walking.meta.boutinfo(bout).laser, param)];
end

%get rid of data where phase is nan
goodData = ~isnan(phase);
phase = phase(goodData);
data = data(goodData);
fly = fly(goodData);
stim = stim(goodData);

phase_bins = linspace(-pi,pi,param.phaseStep);
velocity_bins = [-2:0.05:2]';


%control 
subplot(plotting.nRows, plotting.nCols, 1);

[counts_ctl] = histcounts2(phase(stim == 0),data(stim == 0),phase_bins,velocity_bins);
counts_ctl(counts_ctl==0) = NaN;

plot_phase_ctl = repmat(conv(phase_bins, [0.5 0.5], 'valid'),1,width(counts_ctl));
plot_data_ctl = repmat(conv(velocity_bins, [0.5 0.5], 'valid')', height(counts_ctl),1);

polarscatter(plot_phase_ctl(:), plot_data_ctl(:), counts_ctl(:)/(max(counts_ctl(:))/param.maxPolarDot), counts_ctl(:), 'filled'); hold on;

title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([min(velocity_bins) max(velocity_bins)])
thetaticks([0, 90, 180, 270]);

%color bar legend
min_ctl = min(counts_ctl(:));
max_ctl = max(counts_ctl(:));
cb = colorbar('Ticks',[min_ctl, max_ctl],...
      'TickLabels',{num2str(min_ctl), num2str(max_ctl)}, 'color', Color(param.baseColor));

%experimental 
subplot(plotting.nRows, plotting.nCols, 2);

[counts_exp] = histcounts2(phase(stim == 1),data(stim == 1),phase_bins,velocity_bins);
counts_exp(counts_exp==0) = NaN;

plot_phase_exp = repmat(conv(phase_bins, [0.5 0.5], 'valid'),1,width(counts_exp));
plot_data_exp = repmat(conv(velocity_bins, [0.5 0.5], 'valid')', height(counts_exp),1);

polarscatter(plot_phase_exp(:), plot_data_exp(:), counts_exp(:)/(max(counts_exp(:))/param.maxPolarDot), counts_exp(:), 'filled');

title('Stim')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([min(velocity_bins) max(velocity_bins)])
thetaticks([0, 90, 180, 270]);

%color bar legend
min_exp = min(counts_exp(:));
max_exp = max(counts_exp(:));
cb = colorbar('Ticks',[min_exp, max_exp],...
      'TickLabels',{num2str(min_exp), num2str(max_exp)}, 'color', Color(param.baseColor));


%means and std
subplot(plotting.nRows, plotting.nCols, 3);

%bin data by phase
data_bins = discretize(phase, phase_bins); 

%take the mean of the data in each phase bin 
ctl_data_means = NaN(1,width(phase_bins)); 
exp_data_means = NaN(1,width(phase_bins)); 
ctl_data_std = NaN(1,width(phase_bins)); 
exp_data_std = NaN(1,width(phase_bins)); 
for ph = 1:width(phase_bins)
    ctl_data_means(1,ph) = nanmean(data(stim == 0 & data_bins == ph));
    exp_data_means(1,ph) = nanmean(data(stim == 1 & data_bins == ph));
    
    ctl_data_std(1,ph) = nanstd(data(stim == 0 & data_bins == ph));
    exp_data_std(1,ph) = nanstd(data(stim == 1 & data_bins == ph));
end

%plot mean
polarplot(phase_bins, smooth(ctl_data_means), 'Color', param.baseColor, 'LineWidth', 1); hold on;
polarplot(phase_bins, smooth(exp_data_means), 'Color', Color(param.expColor), 'LineWidth', 1);
title('Mean')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([min([ctl_data_means(:); exp_data_means(:)])-2 max([ctl_data_means(:); exp_data_means(:)])+2])
thetaticks([0, 90, 180, 270]);
hold off;

%plot std
subplot(plotting.nRows, plotting.nCols, 4);
polarplot(phase_bins, smooth(ctl_data_std), 'Color', param.baseColor, 'LineWidth', 1); hold on;
polarplot(phase_bins, smooth(exp_data_std), 'Color', Color(param.expColor), 'LineWidth', 1);
title('Standard Deviation')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([min([ctl_data_std(:); exp_data_std(:)])-2 max([ctl_data_std(:); exp_data_std(:)])+2])
thetaticks([0, 90, 180, 270]);
hold off;

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

%  histogram2(phase, data); 


%Save!
fig_name = [param.legs{leg} ' ' param.joints{joint} ' jerk x phase (by bout) - ctl vs stim -  - with mean and std'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% AEP & PEP %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Plot AEP and PEP - ctl vs stim 
joint = 5; %5;%(tari tip positions)

%get x y z coordinates for each bout
fig = fullfig;
for leg = 1:6 
    legJntStr = [param.legs{leg} param.jointLetters{joint}];
    dataX = [];
    dataY = [];
    dataZ = [];
    fly = []; 
    stim = []; 
    trim = 1;
    for bout = 1:height(walking.bouts)
        dataX = [dataX; walking.bouts{bout}.([legJntStr '_x'])];
        dataY = [dataY; walking.bouts{bout}.([legJntStr '_y'])];
        dataZ = [dataZ; walking.bouts{bout}.([legJntStr '_z'])];
        fly = [fly; ones(height(walking.bouts{bout}.([legJntStr '_x'])),1) * walking.meta.boutinfo(bout).flyNum];
        stim = [stim; DLC_calculate_stim(walking.meta.boutinfo(bout).startIdx, walking.meta.boutinfo(bout).endIdx, walking.meta.boutinfo(bout).laser, param)];
    end

    %get peaks and troughs of dataY (AEP and PEP) 
    [AEPs, AEPlocs, AEPw, AEPp] = findpeaks(dataY, 'MinPeakProminence', 0.04); 
    [PEPs, PEPlocs, PEPw, PEPp] = findpeaks(dataY*-1, 'MinPeakProminence', 0.04); 
    AEPidxs = zeros(height(dataY),1); AEPidxs(AEPlocs) = 1;
    PEPidxs = zeros(height(dataY),1); PEPidxs(PEPlocs) = 1;

    %ctl data
    AEP_mean_ctl = [nanmean(dataX(AEPidxs == 1 & stim == 0)), nanmean(dataY(AEPidxs == 1 & stim == 0)), nanmean(dataZ(AEPidxs == 1 & stim == 0))];
    AEP_std_ctl = [nanstd(dataX(AEPidxs == 1 & stim == 0)), nanstd(dataY(AEPidxs == 1 & stim == 0)), nanstd(dataZ(AEPidxs == 1 & stim == 0))];
    PEP_mean_ctl = [nanmean(dataX(PEPidxs == 1 & stim == 0)), nanmean(dataY(PEPidxs == 1 & stim == 0)), nanmean(dataZ(PEPidxs == 1 & stim == 0))];
    PEP_std_ctl = [nanstd(dataX(PEPidxs == 1 & stim == 0)), nanstd(dataY(PEPidxs == 1 & stim == 0)), nanstd(dataZ(PEPidxs == 1 & stim == 0))];
    %exp data
    AEP_mean_exp = [nanmean(dataX(AEPidxs == 1 & stim == 1)), nanmean(dataY(AEPidxs == 1 & stim == 1)), nanmean(dataZ(AEPidxs == 1 & stim == 1))];
    AEP_std_exp = [nanstd(dataX(AEPidxs == 1 & stim == 1)), nanstd(dataY(AEPidxs == 1 & stim == 1)), nanstd(dataZ(AEPidxs == 1 & stim == 1))];
    PEP_mean_exp = [nanmean(dataX(PEPidxs == 1 & stim == 1)), nanmean(dataY(PEPidxs == 1 & stim == 1)), nanmean(dataZ(PEPidxs == 1 & stim == 1))];
    PEP_std_exp= [nanstd(dataX(PEPidxs == 1 & stim == 1)), nanstd(dataX(PEPidxs == 1 & stim == 1)), nanstd(dataZ(PEPidxs == 1 & stim == 1))];
    
    %PLOT!
    
    %AEP ctl 
    e = errorbar(AEP_mean_ctl(1), AEP_mean_ctl(2), AEP_std_ctl(1), 'horizontal', '^'); hold on; %AEP ctl x error
    e.Color = param.baseColor;
    e = errorbar(AEP_mean_ctl(1), AEP_mean_ctl(2), AEP_std_ctl(2), 'vertical', '^'); %AEPctl y error
    e.Color = param.baseColor;
    %AEP exp 
    e = errorbar(AEP_mean_exp(1), AEP_mean_exp(2), AEP_std_exp(1), 'horizontal', '^'); hold on; %AEP ctl x error
    e.Color = Color(param.expColor);
    e = errorbar(AEP_mean_exp(1), AEP_mean_exp(2), AEP_std_exp(2), 'vertical', '^'); %AEPctl y error
    e.Color = Color(param.expColor);

    %PEP ctl 
    e = errorbar(PEP_mean_ctl(1), PEP_mean_ctl(2), PEP_std_ctl(1), 'horizontal', 'v'); hold on; %AEP ctl x error
    e.Color = param.baseColor;
    e = errorbar(PEP_mean_ctl(1), PEP_mean_ctl(2), PEP_std_ctl(2), 'vertical', 'v'); %AEPctl y error
    e.Color = param.baseColor;
    %PEP exp 
    e = errorbar(PEP_mean_exp(1), PEP_mean_exp(2), PEP_std_exp(1), 'horizontal', 'v'); hold on; %AEP ctl x error
    e.Color = Color(param.expColor);
    e = errorbar(PEP_mean_exp(1), PEP_mean_exp(2), PEP_std_exp(2), 'vertical', 'v'); %AEPctl y error
    e.Color = Color(param.expColor);
    
end

fig = formatFig(fig, true);

hold off;

%Save!
fig_name = ['all legs joint ' param.jointLetters{joint} ' AEP & PEP - ctl vs stim'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot stance trajectories... TODO this doesn't work yet, might not be needed. 

joint = 5; %(tari tip positions)

%get x y z coordinates for each bout
fig = fullfig;
for leg = 1:6 
    legJntStr = [param.legs{leg} param.jointLetters{joint}];
    dataX = [];
    dataY = [];
    dataZ = [];
    fly = []; 
    stim = []; 
    trim = 1;
    for bout = 1:height(walking.bouts)
        dataX = [dataX; walking.bouts{bout}.([legJntStr '_x'])];
        dataY = [dataY; walking.bouts{bout}.([legJntStr '_y'])];
        dataZ = [dataZ; walking.bouts{bout}.([legJntStr '_z'])];
        fly = [fly; ones(height(walking.bouts{bout}.([legJntStr '_x'])),1) * walking.meta.boutinfo(bout).flyNum];
        stim = [stim; DLC_calculate_stim(walking.meta.boutinfo(bout).startIdx, walking.meta.boutinfo(bout).endIdx, walking.meta.boutinfo(bout).laser, param)];
    end

    %get peaks and troughs of dataY (AEP and PEP) 
    [AEPs, AEPlocs, AEPw, AEPp] = findpeaks(dataY, 'MinPeakProminence', 0.04); 
    [PEPs, PEPlocs, PEPw, PEPp] = findpeaks(dataY*-1, 'MinPeakProminence', 0.04); 
    
    %get stance sections: AEP to PEP
    if AEPlocs(1) > PEPlocs(1)
        AEPlocs = AEPlocs(2:end);
    end
    if height(AEPlocs) ~= height(PEPlocs)
       newLength = min(height(AEPlocs), height(PEPlocs)); 
       AEPlocs = AEPlocs(1:newLength);
       PEPlocs = PEPlocs(1:newLength);
    end
    
%     stancelocs = zeros(height(dataY),1); 
    stanceX = NaN(height(AEPlocs), max(PEPlocs - AEPlocs)+1);
    stanceY = NaN(height(AEPlocs), max(PEPlocs - AEPlocs)+1);
    stanceZ = NaN(height(AEPlocs), max(PEPlocs - AEPlocs)+1);
    for st = 1:height(AEPlocs)
        
       plot(dataX(AEPlocs(st):PEPlocs(st)), dataY(AEPlocs(st):PEPlocs(st))); hold on;
%         
%         
%        st_width = PEPlocs(st)-AEPlocs(st)+1;
%        stanceX(st,1:st_width) = dataX(AEPlocs(st):PEPlocs(st))';
%        stanceY(st,1:st_width) = dataY(AEPlocs(st):PEPlocs(st))';
%        stanceZ(st,1:st_width) = dataZ(AEPlocs(st):PEPlocs(st))';
        
    end
    
    
    %PLOT!
 
end

fig = formatFig(fig, true);

hold off;

%Save!
fig_name = ['all legs joint ' param.jointLetters{joint} ' stance trajectories - ctl vs stim'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);




%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% Swing Stance Plot %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Find swing stance for all walking bouts
% zeros are stance
% ones are swing

ss_bouts = NaN(param.vid_len_f,param.numLegs,height(walking.bouts));

for bout = 1:height(walking.bouts)
    for leg = 1:param.numLegs
        ss_this_bout = zeros(height(walking.bouts{bout, 1}), 1);
        this_leg_str = [param.legs{leg} 'E_y'];
        ss_this_bout(diff(walking.bouts{bout, 1}.(this_leg_str)) >= 0) = 1;
        ss_bouts(1:height(ss_this_bout),leg,bout) = ss_this_bout;
    end
end

%% Plot: Single swing stance plot


bout = 90; %walking bout to plot

%get swing stance data for this bout 
this_bout_data = ss_bouts(:,:,bout); 
this_bout_data = this_bout_data(~isnan(this_bout_data(:,1)),:); 

%create laser signal
this_bout_start = walking.meta.boutinfo(bout).startIdx;
this_bout_end = walking.meta.boutinfo(bout).endIdx;
this_bout_laser = param.fps*walking.meta.boutinfo(bout).laser;
laser_sig = ones(param.vid_len_f,1);
laser_sig = laser_sig*0.5;
if this_bout_laser > 0
    laser_sig(param.laser_on:param.laser_on+this_bout_laser) = 2;
end
laser_sig = laser_sig(this_bout_start:this_bout_end);

%plot
fig = fullfig; 
if any(laser_sig == 2)
    imagesc([this_bout_data, laser_sig]'); colormap([Color(param.backgroundColor); 0.5 0.5 0.5; Color(param.baseColor); Color(param.laserColor)]); 
else
    imagesc([this_bout_data, laser_sig]'); colormap([Color(param.backgroundColor); 0.5 0.5 0.5; Color(param.baseColor)]); 
end
set(gca,'YDir','normal') 

title(['bout ' num2str(bout)], 'color', Color(param.baseColor));
set(gca,'YTick',[1,2,3,4,5,6,7]);
set(gca,'YTickLabel',[param.legs 'laser']);
xlabel('Time (s)');
ylabel('Legs');

fig = formatFig(fig, true);



%save
fig_name = ['\Swing stance plots - bout ' num2str(bout)];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot: Several swing stance plots

%%%% PARAMETERS %%%%
first_bout = 1; %which bout to start at
num_bouts = 132; %number of bouts to plot
view_full_video = 1; %1 = plot full 600 frame vid. 0 = just plot the walking bout.
%%%%%%%%%%%%%%%%%%%%

%sort vids by laser length 
all_lasers = [walking.meta.boutinfo(first_bout:end).laser];
[~,order] = sort(all_lasers);


plotting = numSubplots(num_bouts);
fig = fullfig; 
% for the_bout = first_bout:first_bout+num_bouts-1
the_bout = first_bout;
bout_counter = 1;
while bout_counter < num_bouts 
    bout = order(the_bout);
    
    
    %get swing stance data for this bout 
    this_bout_data = ss_bouts(:,:,bout); 
    if ~view_full_video
        this_bout_data = this_bout_data(~isnan(this_bout_data(:,1)),:); %comment out to view full 600 vid
    end
    
    %create laser signal
    this_bout_start = walking.meta.boutinfo(bout).startIdx;
    this_bout_end = walking.meta.boutinfo(bout).endIdx;
    this_bout_laser = param.fps*walking.meta.boutinfo(bout).laser;
    laser_sig = ones(param.vid_len_f,1);
    laser_sig = laser_sig*0.5;
    if this_bout_laser > 0
        laser_sig(param.laser_on:param.laser_on+this_bout_laser) = 2;
    end
    if ~view_full_video
        laser_sig = laser_sig(this_bout_start:this_bout_end);           %comment out to view full 600 vid
    end
    
    %figure out if this is a good bout to plot (if stim occurs during walking bout, or if there's no stim it's still good)
    good_bout = 1; %assume bout is good. 
    if this_bout_end < param.laser_on | this_bout_start > param.laser_on+this_bout_laser
        good_bout = 0;
    end
    
    if good_bout
        %plot
        ax(bout_counter) = subplot(plotting(1), plotting(2), bout_counter); hold on;
        if any(laser_sig == 2)
            imagesc([this_bout_data,laser_sig]'); colormap(ax(bout_counter), [Color(param.backgroundColor); 0.5 0.5 0.5; Color(param.baseColor); Color(param.laserColor)]); hold off;
        else
            imagesc([this_bout_data,laser_sig]'); colormap(ax(bout_counter), [Color(param.backgroundColor); 0.5 0.5 0.5; Color(param.baseColor)]); hold off;
        end
        
%         title(['bout ' num2str(order(bout))], 'color', Color(param.baseColor));
        title(['bout ' num2str(order(the_bout))], 'color', Color(param.baseColor));
        set(gca,'YTickLabel',[]);
        if view_full_video; set(gca,'XTick',[0,param.vid_len_f]); set(gca,'XTickLabel',[0,param.vid_len_f]); end

        %increment bout_counter since this bout was a success!
        bout_counter = bout_counter + 1;
    end
    
    %increment the_bout - regardless of successs we need to check the next bout. 
    the_bout = the_bout + 1;
    
end

fig = formatFig(fig, true, plotting);



%save
fig_name = ['\Swing stance plots - ' num2str(bout_counter-1) ' bouts'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% clearvars('-except',initial_vars{:}); initial_vars = who;




%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% COVARIANCE MATRICES %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Covariance matrix for walking data (ANLGES) - ALL conds - All angles

setDiagonalToZero = 1; %1= sets diagonal of C matrix to zero for better colormap scaling. 

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1A_abduct'));
endJnt = find(contains(columns, 'R3_TiTa'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = {'L1_BC', 'L1_CF', 'L1_FTi', 'L1_TiTa','L2_BC', 'L2_CF', 'L2_FTi', 'L2_TiTa','L3_BC', 'L3_CF', 'L3_FTi', 'L3_TiTa','R1_BC', 'R1_CF', 'R1_FTi', 'R1_TiTa','R2_BC', 'R2_CF', 'R2_FTi', 'R2_TiTa','R3_BC', 'R3_CF', 'R3_FTi', 'R3_TiTa'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
% subData = 1:24; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%invert T3 and T2 signals so peaks correspond to stance start like for T1
invertJnts = find(contains(jointLabels, '3') | contains(jointLabels, '2'));

jointWalkingData = table2array(jointWalkingData);
jointWalkingData(:,invertJnts) = jointWalkingData(:,invertJnts)*-1;

%calculate covariance 
C = cov(jointWalkingData);

if setDiagonalToZero
    %set primary diagonal of C matrix to zero for better color scaling
    C = C - diag(diag(C));
end

%plot covariance matrix
fig = fullfig;
h = heatmap(C); 
h.Title = 'Covariance of joint angles during walking';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
% h.Colormap = parula;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Walking'];
if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% Covariance matrix for walking data (ANLGES) - Ctl vs Stim - All angles

setDiagonalToZero = 0; %1= sets diagonal of C matrix to zero for better colormap scaling. 

% get stim regions (1 = laser on)
stimRegions = DLC_getStimRegions(data, param);

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);
walkingDataStim = stimRegions(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1A_abduct'));
endJnt = find(contains(columns, 'R3_TiTa'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = {'L1_BC', 'L1_CF', 'L1_FTi', 'L1_TiTa','L2_BC', 'L2_CF', 'L2_FTi', 'L2_TiTa','L3_BC', 'L3_CF', 'L3_FTi', 'L3_TiTa','R1_BC', 'R1_CF', 'R1_FTi', 'R1_TiTa','R2_BC', 'R2_CF', 'R2_FTi', 'R2_TiTa','R3_BC', 'R3_CF', 'R3_FTi', 'R3_TiTa'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
% subData = 1:24; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%invert T3 and T2 signals so peaks correspond to stance start like for T1
invertJnts = find(contains(jointLabels, '3') | contains(jointLabels, '2'));

jointWalkingData = table2array(jointWalkingData);
jointWalkingData(:,invertJnts) = jointWalkingData(:,invertJnts)*-1;

%separate stim vs control regions
jointWalkingDataControl = jointWalkingData((walkingDataStim == 0), :);
jointWalkingDataStim = jointWalkingData((walkingDataStim == 1), :);

%calculate covariance 
Ccontrol = cov(jointWalkingDataControl);
Cstim = cov(jointWalkingDataStim);

if setDiagonalToZero
    %set primary diagonal of C matrix to zero for better color scaling
    Ccontrol = Ccontrol - diag(diag(Ccontrol));
    Cstim = Cstim - diag(diag(Cstim));
end

diffSigns = find(sign(Ccontrol) ~= sign(Cstim));
C = Ccontrol - Cstim; 
C(diffSigns) = -C(diffSigns);

%plot covariance matrix - control
fig = fullfig;
h = heatmap(Ccontrol); 
h.Title = 'Covariance of joint angles during walking (control)';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Walking_Ctl'];
if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


%plot covariance matrix - stim
fig = fullfig;
h = heatmap(Cstim); 
h.Title = 'Covariance of joint angles during walking (stim)';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Walking_Stim'];
if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


%plot covariance matrix - control vs stim 
fig = fullfig;
h = heatmap(C); 
h.Title = 'Covariance of joint angles during walking (control - stim)';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Walking_Ctl_vs_Stim'];
if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% Covariance matrix for walking data (ANLGES) - Ctl vs Stim - FTi angles only 

setDiagonalToZero = 0; %1= sets diagonal of C matrix to zero for better colormap scaling. 

% get stim regions (1 = laser on)
stimRegions = DLC_getStimRegions(data, param);

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);
walkingDataStim = stimRegions(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1A_abduct'));
endJnt = find(contains(columns, 'R3_TiTa'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = {'L1_BC', 'L1_CF', 'L1_FTi', 'L1_TiTa','L2_BC', 'L2_CF', 'L2_FTi', 'L2_TiTa','L3_BC', 'L3_CF', 'L3_FTi', 'L3_TiTa','R1_BC', 'R1_CF', 'R1_FTi', 'R1_TiTa','R2_BC', 'R2_CF', 'R2_FTi', 'R2_TiTa','R3_BC', 'R3_CF', 'R3_FTi', 'R3_TiTa'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
% subData = 1:24; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%invert T3 and T2 signals so peaks correspond to stance start like for T1
invertJnts = find(contains(jointLabels, '3') | contains(jointLabels, '2'));

jointWalkingData = table2array(jointWalkingData);
jointWalkingData(:,invertJnts) = jointWalkingData(:,invertJnts)*-1;

%separate stim vs control regions
jointWalkingDataControl = jointWalkingData((walkingDataStim == 0), :);
jointWalkingDataStim = jointWalkingData((walkingDataStim == 1), :);

%calculate covariance 
Ccontrol = cov(jointWalkingDataControl);
Cstim = cov(jointWalkingDataStim);

if setDiagonalToZero
    %set primary diagonal of C matrix to zero for better color scaling
    Ccontrol = Ccontrol - diag(diag(Ccontrol));
    Cstim = Cstim - diag(diag(Cstim));
end

diffSigns = find(sign(Ccontrol) ~= sign(Cstim));
C = Ccontrol - Cstim; 
C(diffSigns) = -C(diffSigns);

%plot covariance matrix - control
fig = fullfig;
h = heatmap(Ccontrol); 
h.Title = 'Covariance of joint angles during walking (control)';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Walking_FTi_angles_Ctl'];
if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


%plot covariance matrix - stim
fig = fullfig;
h = heatmap(Cstim); 
h.Title = 'Covariance of joint angles during walking (stim)';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Walking_FTi_angles_Stim'];
if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


%plot covariance matrix - control vs stim 
fig = fullfig;
h = heatmap(C); 
h.Title = 'Covariance of joint angles during walking (control - stim)';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Walking_FTi_angles_Ctl_vs_Stim'];
if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% CORRELATION COEFFICIENTS %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Correlation coefficients for walking data (ANGLES) - Ctl vs Stim - All angles 

setDiagonalToZero = 1; %1= sets diagonal of C matrix to zero for better colormap scaling. 

% get stim regions (1 = laser on)
stimRegions = DLC_getStimRegions(data, param);

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);
walkingDataStim = stimRegions(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1A_abduct'));
endJnt = find(contains(columns, 'R3_TiTa'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
% allData = 58:219; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = {'L1_BC', 'L1_CF', 'L1_FTi', 'L1_TiTa','L2_BC', 'L2_CF', 'L2_FTi', 'L2_TiTa','L3_BC', 'L3_CF', 'L3_FTi', 'L3_TiTa','R1_BC', 'R1_CF', 'R1_FTi', 'R1_TiTa','R2_BC', 'R2_CF', 'R2_FTi', 'R2_TiTa','R3_BC', 'R3_CF', 'R3_FTi', 'R3_TiTa'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
% subData = 1:24; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%invert T3 and T2 signals so peaks correspond to stance start like for T1
invertJnts = find(contains(jointLabels, '3') | contains(jointLabels, '2'));

jointWalkingData = table2array(jointWalkingData);
jointWalkingData(:,invertJnts) = jointWalkingData(:,invertJnts)*-1;

%separate stim vs control regions
jointWalkingDataControl = jointWalkingData((walkingDataStim == 0), :);
jointWalkingDataStim = jointWalkingData((walkingDataStim == 1), :);

%calculate correlation coeffs
if setDiagonalToZero
    %set primary diagonal of C matrix to zero for better color scaling
    [Rcontrol,~] = corrcoef(jointWalkingDataControl);
    [Rstim,~] = corrcoef(jointWalkingDataStim);
end

diffSigns = find(sign(Rcontrol) ~= sign(Rstim));
R = Rcontrol - Rstim; 
R(diffSigns) = -R(diffSigns);

if setDiagonalToZero
    %set primary diagonal of C matrix to zero for better color scaling
    R = R - diag(diag(R));
end

%plot covariance matrix - control
fig = fullfig;
h = heatmap(Rcontrol); 
h.Title = 'Correlation coefficients of joint angles during walking (control)';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Correlation_Coefficients_JointAngles_Walking_Ctl'];
if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


%plot covariance matrix - stim
fig = fullfig;
h = heatmap(Rstim); 
h.Title = 'Correlation coefficients of joint angles during walking (stim)';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Correlation_Coefficients_JointAngles_Walking_Stim'];
if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


%plot covariance matrix - control vs stim 
fig = fullfig;
h = heatmap(R); 
h.Title = 'Correlation coefficients of joint angles during walking (control - stim)';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Correlation_Coefficients_JointAngles_Walking_Ctl_vs_Stim'];
if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% Correlation coefficients for walking data (ANGLES) - Ctl vs Stim - FTi angles only 

setDiagonalToZero = 1; %1= sets diagonal of C matrix to zero for better colormap scaling. 

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);

%select joint data from walkingData

startJnt = find(contains(columns, 'L1A_abduct'));
endJnt = find(contains(columns, 'R3_TiTa'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
% allData = 58:219; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = {'L1_FTi', 'L2_FTi', 'L3_FTi', 'R1_FTi', 'R2_FTi', 'R3_FTi'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
% subData = 1:24; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%invert T3 and T2 signals so peaks correspond to stance start like for T1
invertJnts = find(contains(jointLabels, '3') | contains(jointLabels, '2'));

jointWalkingData = table2array(jointWalkingData);
jointWalkingData(:,invertJnts) = jointWalkingData(:,invertJnts)*-1;
% jointWalkingData = array2table(jointWalkingData);

%calculate covariance 
[R,P] = corrcoef(jointWalkingData);

if setDiagonalToZero
    %set primary diagonal of C matrix to zero for better color scaling
    R = R - diag(diag(R));
end

% plot covariance matrix
fig = fullfig;
% h = plotmatrix(R); 
h = heatmap(R); 
h.Title = 'Correlation coefficients of joint angles during walking';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
% h.Colormap = parula;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);

%save 
fig_name = ['\Correlation_Coefficients_JointAngles_Walking_FTi_angles'];
if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
 


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% JOINT POSITION TRAJECTORIES (IN 3D) %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Basic plotting of joint positions in 3D

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);
walkingDataStim = param.stimRegions(~isnan(data.walking_bout_number),:);

%find bouts that contain some stim, vs those that don't
stim_bouts = [];
control_bouts = [];
for bout = min(walkingData.walking_bout_number):max(walkingData.walking_bout_number)
   this_bout_idxs = find(walkingData.walking_bout_number == bout);
   if ~isempty(this_bout_idxs)
      if sum(walkingDataStim(this_bout_idxs)) > 0
         %the laser is on during this walking bout
         stim_bouts(end+1) = bout; 
      else %the laser is not on during this walking bout
         control_bouts(end+1) = bout; 
      end
   end
end

%select bout to plot
bout_to_plot = stim_bouts(1);
%get bout indices for plotting
bout_idxs = find(walkingData.walking_bout_number == bout_to_plot);
ctl_bout_idxs = bout_idxs(walkingDataStim(bout_idxs) == 0);
stim_bout_idxs = bout_idxs(walkingDataStim(bout_idxs) == 1);
% divide ctl into pre and post stim 
pre_ctl_bout_idxs = []; post_ctl_bout_idxs = [];
pre_ctl_bout_idxs = [ctl_bout_idxs(ctl_bout_idxs < stim_bout_idxs(1)); stim_bout_idxs(1)]; %append first frame of stim so that the lines will connect 
post_ctl_bout_idxs = [stim_bout_idxs(end); ctl_bout_idxs(ctl_bout_idxs > stim_bout_idxs(end))]; 



%select joint data from walkingData
subData = [columns(contains(columns, '_x')), columns(contains(columns, '_y')),columns(contains(columns, '_z'))];
jointWalkingData = walkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');


fig = fullfig; 
plotting.rows = param.numJoints+1; 
plotting.cols = param.numLegs; 
idx = 1;
for joint = 1:param.numJoints+1 %add one for tarsus tips
    for leg = 1:param.numLegs

% leg = 1; joint = 5;
       dataCols = subData(contains(subData, [param.legs{leg} param.jointLetters{joint}]));
       
       subplot(plotting.rows, plotting.cols, idx);
       %plot pre-stim ctl portion 
       plot3(jointWalkingData.(dataCols{1})(pre_ctl_bout_idxs), jointWalkingData.(dataCols{2})(pre_ctl_bout_idxs), jointWalkingData.(dataCols{3})(pre_ctl_bout_idxs), 'Color', Color(param.backgroundColor), 'LineWidth', 2); hold on;
       %plot stim portion 
       plot3(jointWalkingData.(dataCols{1})(stim_bout_idxs), jointWalkingData.(dataCols{2})(stim_bout_idxs), jointWalkingData.(dataCols{3})(stim_bout_idxs), 'Color', Color(param.laserColor), 'LineWidth', 2);
       %plot post-stim ctl portion 
       plot3(jointWalkingData.(dataCols{1})(post_ctl_bout_idxs), jointWalkingData.(dataCols{2})(post_ctl_bout_idxs), jointWalkingData.(dataCols{3})(post_ctl_bout_idxs), 'Color', Color(param.backgroundColor), 'LineWidth', 2); hold off;

       idx = idx+1;
    end
end






%        clinep(jointWalkingData.(dataCols{1})(bout_idxs), jointWalkingData.(dataCols{2})(bout_idxs), jointWalkingData.(dataCols{3})(bout_idxs), [walkingDataStim(bout_idxs)])









clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot joint positions with the ball.... basic 

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);
walkingDataStim = param.stimRegions(~isnan(data.walking_bout_number),:);

%find bouts that contain some stim, vs those that don't
stim_bouts = [];
control_bouts = [];
for bout = min(walkingData.walking_bout_number):max(walkingData.walking_bout_number)
   this_bout_idxs = find(walkingData.walking_bout_number == bout);
   if ~isempty(this_bout_idxs)
      if sum(walkingDataStim(this_bout_idxs)) > 0
         %the laser is on during this walking bout
         stim_bouts(end+1) = bout; 
      else %the laser is not on during this walking bout
         control_bouts(end+1) = bout; 
      end
   end
end

%select bout to plot
bout_to_plot = stim_bouts(1);
%get bout indices for plotting
bout_idxs = find(walkingData.walking_bout_number == bout_to_plot);
ctl_bout_idxs = bout_idxs(walkingDataStim(bout_idxs) == 0);
stim_bout_idxs = bout_idxs(walkingDataStim(bout_idxs) == 1);
% divide ctl into pre and post stim 
pre_ctl_bout_idxs = []; post_ctl_bout_idxs = [];
pre_ctl_bout_idxs = [ctl_bout_idxs(ctl_bout_idxs < stim_bout_idxs(1)); stim_bout_idxs(1)]; %append first frame of stim so that the lines will connect 
post_ctl_bout_idxs = [stim_bout_idxs(end); ctl_bout_idxs(ctl_bout_idxs > stim_bout_idxs(end))]; 



%select joint data from walkingData
subData = [columns(contains(columns, '_x')), columns(contains(columns, '_y')),columns(contains(columns, '_z'))];
jointWalkingData = walkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%Ball fit to joint E position... then plot all data in 3D from there. (need
%offsets of limb segment lengths?) 


%Ball fit to E joint position

ballFitJoint = 5; %tarsus 
LP = ballFitJoint; %leg point = tarsus
rMin = 1.0;     % min radius constraint
rMax = 3.0;     % max radius constraint
thresh = 0.01;  % percent threshold for 'ground'
leg_colors = {'blue', 'red', 'orange', 'purple', 'green', 'cyan'};
for leg = 1:6
   kolor(leg,:) = Color(leg_colors{leg}); 
end
SZ = 20; % size of scatter plot points
LW = 1;         % line width for plots


%get the data for fitting: x, y, z positions of tarsus tip of each leg
the_min = 0; %find min val of all the data for fitting and move all data into a positive space
for leg = 1:param.numLegs
   dataCols = subData(contains(subData, [param.legs{leg} param.jointLetters{ballFitJoint}]));
   ballFitData(leg).raw = [jointWalkingData.(dataCols{1}), jointWalkingData.(dataCols{2}), jointWalkingData.(dataCols{3})];
   the_min = min(min(ballFitData(leg).raw(:)), the_min);
end
%move all data into a positive space
for leg = 1:param.numLegs
   ballFitData(leg).raw = ballFitData(leg).raw + abs(the_min);
end

%isolate stance regions and quadruple those points in the dataset for best fitting. 
for leg = 1:param.numLegs
    ballFitData(leg).stance = ballFitData(leg).raw(diff(ballFitData(leg).raw(:,2)) <= 0, :);
end

all_stance = [ballFitData(1).stance; ballFitData(2).stance; ballFitData(3).stance; ballFitData(4).stance; ballFitData(5).stance; ballFitData(6).stance];


cloud = [all_stance; all_stance; all_stance]; % triple up on 'good' data points

% SPHERE FIT
%RMSE with minimum optimization function: 
objective = @(XX) sqrt(mean((pdist2([XX(1),XX(2),XX(3)],cloud)-XX(4)).^2,2));
x0 = [0,0,0,1.3]; % starting guess [center-x,center-y,center-z,radius]
[A,b,Aeq,beq] = deal([]);   %empty values
lb = [-inf,-inf,-inf,rMin];  %lower bounds
ub = [inf,inf, 0, rMax];     %upper bounds
XX = fmincon(objective,x0,A,b,Aeq,beq,lb,ub);
Center = [XX(1),XX(2),XX(3)];
Radius = XX(4);
disp(['Radius: ' num2str(Radius)])

% disp number of points that hit the threshold:
R = Radius*thresh;             % 3-percent threshold
dist = pdist2(Center, cloud);  % find the euclidian distances
err = (sum(dist>(Radius-R) & dist<(Radius+R),2)/length(cloud))*100; %percent of points 'on' the sphere
disp(['Points on ball: ' num2str(err) '%'])
% 
% trial(cond,rep).cloud = cloud;
% trial(cond,rep).Center = Center;
% trial(cond,rep).Radius = Radius;

set(0,'DefaultFigureVisible','on');  %Turn figures back on:
% --- Figure of ball with full step cycles ---- 
LW = 1.5;

%left plot with the data on the ball 
fig = getfig;
subplot(1,2,1)
for leg = 1:6
    input = ballFitData(leg).raw;
    plot3(input(:,1), input(:,2), input(:,3), 'linewidth', LW, 'color', kolor(leg,:)); hold on
end
axis tight
box off
set(gca,'visible','off')
[x,y,z] = sphere;
s = surf(Radius*x+Center(1), Radius*y+Center(2), Radius*z+Center(3));
set(s, 'FaceColor', Color('grey'))
alpha 0.2
axis vis3d % sets the aspect ratio for 3d rotation
ax = gca;               % get the current axis
ax.Clipping = 'off';



%right plot of data close up with stance in grey swing in color
R = Radius*(1+thresh); % increase threshold
% find the distance from the center of the sphere to the tarsus and greater
% than the radius value equates to swing:
subplot(1,2,2)
for leg = 1:6
    input = ballFitData(leg).raw;
    e_dist = pdist2(Center,input);
    stance_loc = e_dist<=R;
    swing_loc = e_dist>R; 
    scatter3(input(stance_loc,1),input(stance_loc,2),input(stance_loc,3), SZ, Color('grey'), 'filled')
    hold on
    scatter3(input(swing_loc,1),input(swing_loc,2),input(swing_loc,3), SZ, kolor(leg,:), 'filled')
end
title(['Walking bout ' num2str(bout_to_plot)], 'color', param.baseColor);
axis vis3d % sets the aspect ratio for 3d rotation
ax = gca;               % get the current axis
ax.Clipping = 'off';


fig = formatFig(fig, true);





clearvars('-except',initial_vars{:}); initial_vars = who;



% 
% fig = fullfig; 
% plotting.rows = param.numJoints+1; 
% plotting.cols = param.numLegs; 
% idx = 1;
% for joint = 1:param.numJoints+1 %add one for tarsus tips
%     for leg = 1:param.numLegs
% 
% % leg = 1; joint = 5;
%        dataCols = subData(contains(subData, [param.legs{leg} param.jointLetters{joint}]));
%        
%        subplot(plotting.rows, plotting.cols, idx);
%        %plot pre-stim ctl portion 
%        plot3(jointWalkingData.(dataCols{1})(pre_ctl_bout_idxs), jointWalkingData.(dataCols{2})(pre_ctl_bout_idxs), jointWalkingData.(dataCols{3})(pre_ctl_bout_idxs), 'Color', Color(param.backgroundColor), 'LineWidth', 2); hold on;
%        %plot stim portion 
%        plot3(jointWalkingData.(dataCols{1})(stim_bout_idxs), jointWalkingData.(dataCols{2})(stim_bout_idxs), jointWalkingData.(dataCols{3})(stim_bout_idxs), 'Color', Color(param.laserColor), 'LineWidth', 2);
%        %plot post-stim ctl portion 
%        plot3(jointWalkingData.(dataCols{1})(post_ctl_bout_idxs), jointWalkingData.(dataCols{2})(post_ctl_bout_idxs), jointWalkingData.(dataCols{3})(post_ctl_bout_idxs), 'Color', Color(param.backgroundColor), 'LineWidth', 2); hold off;
% 
%        idx = idx+1;
%     end
% end

%% Plot joint positions with the ball.... better plotting


%%%%%%%%%%%%%%%%%%%%%%%%%%% PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%TODO currently cannot have laser_indicated for datatypes 1 and 2... 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% how much data to plot
data_type = 3; %1 = all data, 2 = a region of data, 3 = one walking bout
if data_type == 2
    startFrame = 100;
    endFrame = 600;
elseif data_type == 3
    boutType = 'stim'; %'stim' = bout with stim in int, 'control' = bout without stim in it
    boutNum = 53; 
end
% indicate the laser region?
laser_indicated = 1; %1 = color stim region param.laserColor, 0 = don't color stim region 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);
walkingDataStim = param.stimRegions(~isnan(data.walking_bout_number),:);

%find bouts that contain some stim, vs those that don't
stim_bouts = [];
control_bouts = [];
for bout = min(walkingData.walking_bout_number):max(walkingData.walking_bout_number)
   this_bout_idxs = find(walkingData.walking_bout_number == bout);
   if ~isempty(this_bout_idxs)
      if sum(walkingDataStim(this_bout_idxs)) > 0
         %the laser is on during this walking bout
         stim_bouts(end+1) = bout; 
      else %the laser is not on during this walking bout
         control_bouts(end+1) = bout; 
      end
   end
end

%select bout to plot
if (data_type == 1) & laser_indicated
    %TODO 
    
elseif (data_type == 2) & laser_indicated
    %TODO 
    region_idxs = [startFrame:endFrame];
    ctl_region_idxs = region_idxs(walkingDataStim(region_idxs) == 0);
%     stim_region_idxs = region_idxs(walkingDataStim(region_idxs) == 1);
%     % divide ctl into pre and post stim 
%     pre_ctl_region_idxs = []; post_ctl_bout_idxs = [];
%     pre_ctl_bout_idxs = [ctl_bout_idxs(ctl_bout_idxs < stim_bout_idxs(1)); stim_bout_idxs(1)]; %append first frame of stim so that the lines will connect 
%     post_ctl_bout_idxs = [stim_bout_idxs(end); ctl_bout_idxs(ctl_bout_idxs > stim_bout_idxs(end))]; 
    
elseif data_type == 3
    if strcmpi(boutType, 'stim')
        bout_to_plot = stim_bouts(boutNum);
        %get bout indices for plotting
        bout_idxs = find(walkingData.walking_bout_number == bout_to_plot);
        if laser_indicated
            ctl_bout_idxs = bout_idxs(walkingDataStim(bout_idxs) == 0);
            stim_bout_idxs = bout_idxs(walkingDataStim(bout_idxs) == 1);
            % divide ctl into pre and post stim 
            pre_ctl_bout_idxs = []; post_ctl_bout_idxs = [];
            pre_ctl_bout_idxs = [ctl_bout_idxs(ctl_bout_idxs < stim_bout_idxs(1)); stim_bout_idxs(1)]; %append first frame of stim so that the lines will connect 
            post_ctl_bout_idxs = [stim_bout_idxs(end); ctl_bout_idxs(ctl_bout_idxs > stim_bout_idxs(end))]; 
        end
    elseif strcmpi(boutType, 'control')
        bout_to_plot = control_bouts(boutNum);
        %get bout indices for plotting
        bout_idxs = find(walkingData.walking_bout_number == bout_to_plot);
    end
end

%select joint data from walkingData
subData = [columns(contains(columns, '_x')), columns(contains(columns, '_y')),columns(contains(columns, '_z'))];
jointWalkingData = walkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%Ball fit to joint E position... then plot all data in 3D from there. (need
%offsets of limb segment lengths?) 


%Ball fit to E joint position

% ballFitJoint = 5; %tarsus 
% LP = ballFitJoint; %leg point = tarsus
rMin = 1.0;     % min radius constraint
rMax = 3.0;     % max radius constraint
thresh = 0.01;  % percent threshold for 'ground'
% leg_colors = {'blue', 'yellow', 'orange', 'purple', 'white', 'cyan'}; %each leg has its own color
leg_colors = {'blue', 'orange', 'blue', 'orange', 'blue', 'orange'}; %each TRIPOD has its own color
joint_saturations = [0.1, 0.3, 0.5, 0.7, 0.9];
% joint_saturations = [0.1, 0.3, 0.1, 0.3, 0.9];

for leg = 1:6
   this_leg_hsv = rgb2hsv(Color(leg_colors{leg}));
   for joint = 1:5
       this_joint_hsv = [this_leg_hsv(1), joint_saturations(joint), this_leg_hsv(3)]; 
       kolor(:,joint,leg) = hsv2rgb(this_joint_hsv); 
   end
end
SZ = 10; % size of scatter plot points
LW = 1;         % line width for plots


%get the data for fitting: x, y, z positions of tarsus tip of each leg
the_min = 0; %find min val of all the data for fitting and move all data into a positive space
for leg = 1:param.numLegs
   %format joint data for ball fit and plotting
   for joint = 1:param.numJoints+1
      dataCols = subData(contains(subData, [param.legs{leg} param.jointLetters{joint}]));
      ballFitData(leg).(param.legNodes{joint}) = [jointWalkingData.(dataCols{1}), jointWalkingData.(dataCols{2}), jointWalkingData.(dataCols{3})];
      the_min = min(min(ballFitData(leg).(param.legNodes{joint})(:)), the_min);   
   end
end
%move all data into a positive space
for leg = 1:param.numLegs
   for joint = 1:param.numJoints+1
      ballFitData(leg).(param.legNodes{joint}) = ballFitData(leg).(param.legNodes{joint}) + abs(the_min);
   end
end

%isolate stance regions and quadruple those points in the dataset for best fitting. 
for leg = 1:param.numLegs
    ballFitData(leg).stance = ballFitData(leg).Ta(diff(ballFitData(leg).Ta(:,2)) <= 0, :);
end

all_stance = [ballFitData(1).stance; ballFitData(2).stance; ballFitData(3).stance; ballFitData(4).stance; ballFitData(5).stance; ballFitData(6).stance];


cloud = [all_stance; all_stance; all_stance]; % triple up on 'good' data points

% SPHERE FIT
%RMSE with minimum optimization function: 
objective = @(XX) sqrt(mean((pdist2([XX(1),XX(2),XX(3)],cloud)-XX(4)).^2,2));
x0 = [0,0,0,1.3]; % starting guess [center-x,center-y,center-z,radius]
[A,b,Aeq,beq] = deal([]);   %empty values
lb = [-inf,-inf,-inf,rMin];  %lower bounds
ub = [inf,inf, 0, rMax];     %upper bounds
XX = fmincon(objective,x0,A,b,Aeq,beq,lb,ub);
Center = [XX(1),XX(2),XX(3)];
Radius = XX(4);
disp(['Radius: ' num2str(Radius)])

% disp number of points that hit the threshold:
R = Radius*thresh;             % 3-percent threshold
dist = pdist2(Center, cloud);  % find the euclidian distances
err = (sum(dist>(Radius-R) & dist<(Radius+R),2)/length(cloud))*100; %percent of points 'on' the sphere
disp(['Points on ball: ' num2str(err) '%'])


set(0,'DefaultFigureVisible','on');  %Turn figures back on:
% --- Figure of ball with full step cycles ---- 
LW = 1.5;
alpha = 0.5;
% startFrame = 1; 
% endFrame = 1000;

%left plot with the data on the ball 
% fig = getfig;
fig = fullfig;
for leg = 1:6
    for joint = 1:param.numJoints+1
        input = ballFitData(leg).(param.legNodes{joint});
        if ~laser_indicated %plotting without indicating laser
            if data_type == 1 %plot all data
                plot3(input(:,1), input(:,2), input(:,3), 'linewidth', LW, 'color', [[kolor(:,joint,leg)]', alpha]); hold on
            elseif data_type == 2 %plot region of data
                plot3(input(startFrame:endFrame,1), input(startFrame:endFrame,2), input(startFrame:endFrame,3), 'linewidth', LW, 'color', [[kolor(:,joint,leg)]', alpha]); hold on
            elseif data_type == 3 %plot bout of data
                plot3(input(bout_idxs,1), input(bout_idxs,2), input(bout_idxs,3), 'linewidth', LW, 'color', [[kolor(:,joint,leg)]', alpha]); hold on
            end 
        elseif laser_indicated %plotting wtih indicating laser
            if data_type == 1 %plot all data
                
            elseif data_type == 2 %plot region of data
                
            elseif data_type == 3 %plot bout of data
                if strcmpi(boutType, 'stim') %it's a stim bout
                    plot3(input(pre_ctl_bout_idxs,1), input(pre_ctl_bout_idxs,2), input(pre_ctl_bout_idxs,3), 'linewidth', LW, 'color', [[kolor(:,joint,leg)]', alpha]); hold on
                    plot3(input(stim_bout_idxs,1), input(stim_bout_idxs,2), input(stim_bout_idxs,3), 'linewidth', LW, 'color', [Color(param.laserColor), alpha]); hold on
                    plot3(input(post_ctl_bout_idxs,1), input(post_ctl_bout_idxs,2), input(post_ctl_bout_idxs,3), 'linewidth', LW, 'color', [[kolor(:,joint,leg)]', alpha]); hold on
                elseif strcmpi(boutType, 'control') %it's a control bout (so no laser to plot)
                    plot3(input(bout_idxs,1), input(bout_idxs,2), input(bout_idxs,3), 'linewidth', LW, 'color', [[kolor(:,joint,leg)]', alpha]); hold on
                end
            end 
        end
    end
end
axis tight
box off
set(gca,'visible','off')
[x,y,z] = sphere;
s = surf(Radius*x+Center(1), Radius*y+Center(2), Radius*z+Center(3));
set(s, 'FaceColor', Color('grey'))
alpha 0.2
axis vis3d % sets the aspect ratio for 3d rotation
ax = gca;               % get the current axis
ax.Clipping = 'off';


fig = formatFig(fig, true);

% title(['Walking bout ' num2str(bout_to_plot)], 'color', param.baseColor);

clearvars('-except',initial_vars{:}); initial_vars = who;












