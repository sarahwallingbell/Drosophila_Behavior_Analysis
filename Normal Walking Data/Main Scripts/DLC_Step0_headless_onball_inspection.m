clear all; close all; clc;

% Select and load parquet file (the fly data)
[FilePath, version] = DLC_select_parquet();
[data, columns, column_names, path] = DLC_extract_parquet(FilePath);
[numReps, numConds, flyList] = DLC_extract_flies(columns, data);
param = DLC_load_params(version, flyList);
param.numReps = numReps;
param.numConds = numConds; 
% param.flyList = flyList;
param.columns = columns; 
param.column_names = column_names;
param.parquet = path;

% Organize data for plotting
joint_data = DLC_org_joint_data(data, param);
joint_data_byFly = DLC_org_joint_data_byFly(data, param);

initial_vars = who;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% One leg %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot all joints, all lasers, one leg 
leg = 1;
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
          if height(temp{vid}) == 600
            plot(param.x, temp{vid}); 
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

%% Plot all joints, all lasers, one leg -- mean & 95% CI 
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
       all_data = NaN( width(temp), param.vid_len_f);
       for vid = 1:width(temp)
          all_data(vid, :) = temp{vid};
%           plot(param.x, temp{vid}); 
       end
       
%        N = size(all_data, 1);  % Number of ‘Experiments’ In Data Set (numVids)
       N = height(flyList);    % Number of ‘Experiments’ In Data Set (numFlies)
       yMean = nanmean(all_data); % Mean Of All Experiments At Each Value Of ‘x’
       ySEM = std(all_data)/sqrt(N); % Compute ‘Standard Error Of The Mean’ Of All Experiments At Each Value Of ‘x’
       
       CI95 = tinv([0.025 0.975], N-1);  % Calculate 95% Probability Intervals Of t-Distribution
       yCI95 = bsxfun(@times, ySEM, CI95(:));  % Calculate 95% Confidence Intervals Of All Experiments At Each Value Of ‘x’
       
       plot(param.x, yMean, 'color', Color(param.expColor), 'linewidth', 1.5);
%        plot(param.x, yCI95+yMean);
       fill_data = error_fill(param.x, yMean, yCI95);
       h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
       set(h, 'facealpha', 0.2);
       
       
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
title(han, ' L1 Raw Joint Angle Mean & 95% CI');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

hold off;

fig_name = ['\' param.legs{leg} '_overview_mean&95CI'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all joints, all lasers, one leg -- mean & sem 
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
       all_data = NaN( width(temp), param.vid_len_f);
       for vid = 1:width(temp)
          all_data(vid, :) = temp{vid};
       end
       %calculate mean and standard error of the mean 
       yMean = nanmean(all_data, 1);
       ySEM = sem(all_data, 1, nan, height(flyList));
       
       %plot
       plot(param.x, yMean, 'color', Color(param.expColor), 'linewidth', 1.5);
       fill_data = error_fill(param.x, yMean, ySEM);
       h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
       set(h, 'facealpha', 0.2);
       
       
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
title(han, 'L1 Raw Joint Angle Mean & SEM');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

hold off;

fig_name = ['\' param.legs{leg} '_overview_mean&SEM'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all joints, all lasers, one leg -- subtract baseline angle 

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

%% Plot all joints, all lasers, one leg -- subtract baseline angle -- mean & sem 
fig = fullfig;
pltIdx = 0;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       this_numVids = 0;
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
       all_data = NaN( width(temp), param.vid_len_f);
       for vid = 1:width(temp) %CHANGE when plotting days 
          d = temp{vid};
          if height(d) == 600
              this_numVids = this_numVids +1;
              a = d(param.laser_on);
              d = d-a; 
              all_data(vid, :) = d;
          end
       end
       numVids(joint, laser) = this_numVids;
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
title(han, ' L1 Aligned Joint Angle Mean & SEM');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_overview_mean&SEM_aligned'];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all joints, all lasers, one leg -- ANGLE CHANGE 

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
          plot(param.x(1:end-1), diff(temp{vid})); 
       end
       
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

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% One Laser %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot all joints, all legs, one laser 
laser = listdlg('ListString', cellfun(@num2str,param.lasers,'un',0), 'PromptString','Select laser:', 'SelectionMode','single', 'ListSize', [100 100]);

light_on = 0;
light_off =(param.fps*param.lasers{laser})/param.fps;
fig = fullfig;
pltIdx = 0;
for joint = 1:param.numJoints
   for leg = 1:param.numLegs
       pltIdx = pltIdx+1;
       subplot(param.numJoints, param.numLegs, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
       elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
       elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
       elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
       end
       %plot the data!
       for vid = 1:width(temp)
          plot(param.x, temp{vid}); 
       end
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       
       % plot laser region 
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
          
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
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
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 13
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 19
            ylabel(['TiTa (' char(176) ')']);
       end
   end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]);
 

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [num2str(param.lasers{laser}) 'sec Laser Raw Joint Angles']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))


hold off;

fig_name = ['\' num2str(param.lasers{laser}) 'sec_overview'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all joints, all legs, one laser -- mean & 95% CI 

light_on = 0;
light_off =(param.fps*param.lasers{laser})/param.fps;
fig = fullfig;
pltIdx = 0;
for joint = 1:param.numJoints
   for leg = 1:param.numLegs
       pltIdx = pltIdx+1;
       subplot(param.numJoints, param.numLegs, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
       elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
       elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
       elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
       end
       %plot the data!
       all_data = NaN( width(temp), param.vid_len_f);
       for vid = 1:width(temp)
          all_data(vid, :) = temp{vid};
%           plot(param.x, temp{vid}); 
       end
       
%        N = size(all_data, 1);  % Number of ‘Experiments’ In Data Set (numVids)
       N = height(flyList);    % Number of ‘Experiments’ In Data Set (numFlies)
       yMean = nanmean(all_data); % Mean Of All Experiments At Each Value Of ‘x’
       ySEM = std(all_data)/sqrt(N); % Compute ‘Standard Error Of The Mean’ Of All Experiments At Each Value Of ‘x’
       
       CI95 = tinv([0.025 0.975], N-1);  % Calculate 95% Probability Intervals Of t-Distribution
       yCI95 = bsxfun(@times, ySEM, CI95(:));  % Calculate 95% Confidence Intervals Of All Experiments At Each Value Of ‘x’
       
       plot(param.x, yMean, 'color', Color(param.expColor), 'linewidth', 1.5);
%        plot(param.x, yCI95+yMean);
       fill_data = error_fill(param.x, yMean, yCI95);
       h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
       set(h, 'facealpha', 0.2);
       
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % plot laser region 
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
          
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
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
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 13
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 19
            ylabel(['TiTa (' char(176) ')']);
       end
   end
end

 fig = formatFig(fig, true, [param.numJoints, param.numLegs]);

 
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [num2str(param.lasers{laser}) 'sec Laser Raw Joint Angle Mean & 95% CI']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

hold off;

fig_name = ['\' num2str(param.lasers{laser}) 'sec_overview_mean&95CI'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all joints, all legs, one laser -- mean & sem 

light_on = 0;
light_off =(param.fps*param.lasers{laser})/param.fps;
fig = fullfig;
pltIdx = 0;
for joint = 1:param.numJoints
   for leg = 1:param.numLegs
       pltIdx = pltIdx+1;
       subplot(param.numJoints, param.numLegs, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
       elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
       elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
       elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
       end
       %plot the data!
       all_data = NaN( width(temp), param.vid_len_f);
       for vid = 1:width(temp)
          all_data(vid, :) = temp{vid};
       end
       %calculate mean and standard error of the mean 
       yMean = nanmean(all_data, 1);
       ySEM = sem(all_data, 1, nan, height(flyList));
       
       %plot
       plot(param.x, yMean, 'color', Color(param.expColor), 'linewidth', 1.5);
       fill_data = error_fill(param.x, yMean, ySEM);
       h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
       set(h, 'facealpha', 0.2);
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
      
       % plot laser region 
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
          
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
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
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 13
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 19
            ylabel(['TiTa (' char(176) ')']);
       end
   end
end

 fig = formatFig(fig, true, [param.numJoints, param.numLegs]);
 
  
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [num2str(param.lasers{laser}) 'sec Laser Raw Joint Angle Mean & SEM']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))


hold off;

fig_name = ['\' num2str(param.lasers{laser}) 'sec_overview_mean&SEM'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all joints, all legs, one laser -- subtract baseline angle 

light_on = 0;
light_off =(param.fps*param.lasers{laser})/param.fps;
fig = fullfig;
pltIdx = 0;
for joint = 1:param.numJoints
   for leg = 1:param.numLegs
       pltIdx = pltIdx+1;
       subplot(param.numJoints, param.numLegs, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
       elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
       elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
       elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
       end
       %plot the data!
       for vid = 1:width(temp)
          d = temp{vid};
          a = d(param.laser_on);
          d = d-a;
          plot(param.x, d); 
       end
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % plot laser region 
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
          
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
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
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 13
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 19
            ylabel(['TiTa (' char(176) ')']);
       end
   end
end

 fig = formatFig(fig, true, [param.numJoints, param.numLegs]);
 
 
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [num2str(param.lasers{laser}) 'sec Laser Aligned Joint Angles']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))


hold off;

fig_name = ['\' num2str(param.lasers{laser}) 'sec_overview_aligned'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all joints, all legs, one laser -- subtract baseline angle -- mean & sem 

light_on = 0;
light_off =(param.fps*param.lasers{laser})/param.fps;
fig = fullfig;
pltIdx = 0;
for joint = 1:param.numJoints
   for leg = 1:param.numLegs
       pltIdx = pltIdx+1;
       subplot(param.numJoints, param.numLegs, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
       elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
       elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
       elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
       end
       %plot the data!
       all_data = NaN( width(temp), param.vid_len_f);
       for vid = 1:width(temp)
          d = temp{vid};
          a = d(param.laser_on);
          d = d-a;
          all_data(vid, :) = d;
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
      
       % plot laser region 
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
          
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
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
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 13
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 19
            ylabel(['TiTa (' char(176) ')']);
       end
   end
end

 fig = formatFig(fig, true, [param.numJoints, param.numLegs]);
 
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [num2str(param.lasers{laser}) 'sec Laser Aligned Joint Angle Mean & SEM']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

hold off;

fig_name = ['\' num2str(param.lasers{laser}) 'sec_overview_mean&SEM_aligned'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all joints, all legs, one laser -- ANGLE CHANGE 

light_on = 0;
light_off =(param.fps*param.lasers{laser})/param.fps;
fig = fullfig;
pltIdx = 0;
for joint = 1:param.numJoints
   for leg = 1:param.numLegs
       pltIdx = pltIdx+1;
       subplot(param.numJoints, param.numLegs, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
       elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
       elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
       elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
       end
       %plot the data!
       for vid = 1:width(temp)
          plot(param.x(1:end-1), diff(temp{vid})); 
       end
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % plot laser region 
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
          
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
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
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 13
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 19
            ylabel(['TiTa (' char(176) ')']);
       end
   end
end

 fig = formatFig(fig, true, [param.numJoints, param.numLegs]);

 han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [num2str(param.lasers{laser}) 'sec Laser Joint Angle Change']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

 
hold off;

fig_name = ['\' num2str(param.lasers{laser}) 'sec_overview_angleChange'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% One joint %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
joint = param.joints{listdlg('ListString', param.joints, 'PromptString','Select laser:', 'SelectionMode','single', 'ListSize', [100 100])};
%% Plot all legs, all lasers, one joint 
% joint = 'FTi'; %'BC' 'CF' 'FTi' TiTa' 
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
       end
       %plot the data!
       for vid = 1:width(temp)
          plot(param.x, temp{vid}); 
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
           ylabel('0.1 sec');
       elseif pltIdx == 19
            ylabel('0.33 sec');
       elseif pltIdx == 25
            ylabel('1 sec');            
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
title(han, [joint ' Raw Joint Angles']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' joint '_overview'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all legs, all lasers, one joint -- mean & 95% CI 

fig = fullfig;
pltIdx = 0;
for laser = 1:param.numLasers
    light_on = 0;
    light_off =(param.fps*param.lasers{laser})/param.fps;
   for leg = 1:param.numLegs
       pltIdx = pltIdx+1;
       subplot(param.numLasers, param.numLegs, pltIdx); hold on;
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
          all_data(vid, :) = temp{vid};
%           plot(param.x, temp{vid}); 
       end
       
%        N = size(all_data, 1);  % Number of ‘Experiments’ In Data Set (numVids)
       N = height(flyList);    % Number of ‘Experiments’ In Data Set (numFlies)
       yMean = nanmean(all_data); % Mean Of All Experiments At Each Value Of ‘x’
       ySEM = std(all_data)/sqrt(N); % Compute ‘Standard Error Of The Mean’ Of All Experiments At Each Value Of ‘x’
       
       CI95 = tinv([0.025 0.975], N-1);  % Calculate 95% Probability Intervals Of t-Distribution
       yCI95 = bsxfun(@times, ySEM, CI95(:));  % Calculate 95% Confidence Intervals Of All Experiments At Each Value Of ‘x’
       
       plot(param.x, yMean, 'color', Color(param.expColor), 'linewidth', 1.5);
%        plot(param.x, yCI95+yMean);
       fill_data = error_fill(param.x, yMean, yCI95);
       h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
       set(h, 'facealpha', 0.2);
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % plot laser region 
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
%        ylim([0,180]);
          
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
           ylabel('0.1 sec');
       elseif pltIdx == 19
            ylabel('0.33 sec');
       elseif pltIdx == 25
            ylabel('1 sec');            
       end
   end
end

 fig = formatFig(fig, true, [param.numLasers, param.numLegs]);
 
 
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [joint ' Raw Joint Angle Mean & 95% CI']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))


hold off;

fig_name = ['\' joint '_overview_mean&95CI'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all legs, all lasers, one joint -- mean & sem  

fig = fullfig;
pltIdx = 0;
for laser = 1:param.numLasers
    light_on = 0;
    light_off =(param.fps*param.lasers{laser})/param.fps;
   for leg = 1:param.numLegs
       pltIdx = pltIdx+1;
       subplot(param.numLasers, param.numLegs, pltIdx); hold on;
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
          all_data(vid, :) = temp{vid};
       end
       %calculate mean and standard error of the mean 
       yMean = nanmean(all_data, 1);
       ySEM = sem(all_data, 1, nan, height(flyList));
       
       %plot
       plot(param.x, yMean, 'color', Color(param.expColor), 'linewidth', 1.5);
       fill_data = error_fill(param.x, yMean, ySEM);
       h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
       set(h, 'facealpha', 0.2);
       
      
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % plot laser region 
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
%        ylim([0,180]);
          
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
           ylabel('0.1 sec');
       elseif pltIdx == 19
            ylabel('0.33 sec');
       elseif pltIdx == 25
            ylabel('1 sec');            
       end
   end
end

 fig = formatFig(fig, true, [param.numLasers, param.numLegs]);
 
 
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [joint ' Raw Joint Angle Mean & SEM']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))



hold off;

fig_name = ['\' joint '_overview_mean&SEM'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all legs, all lasers, one joint -- subtract baseline angle 
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
           ylabel('0.1 sec');
       elseif pltIdx == 19
            ylabel('0.33 sec');
       elseif pltIdx == 25
            ylabel('1 sec');            
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

%% Plot all legs, all lasers, one joint -- subtract baseline angle -- mean & sem 

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
           ylabel('0.1 sec');
       elseif pltIdx == 19
            ylabel('0.33 sec');
       elseif pltIdx == 25
            ylabel('1 sec');            
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
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all legs, all lasers, one joint -- ANGLE CHANGE 
fig = fullfig;
pltIdx = 0;
for laser = 1:param.numLasers
    light_on = 0;
    light_off =(param.fps*param.lasers{laser})/param.fps;
   for leg = 1:param.numLegs
       pltIdx = pltIdx+1;
       subplot(param.numLasers, param.numLegs, pltIdx); hold on;
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
          plot(param.x(1:end-1), diff(temp{vid})); 
       end
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % plot laser region 
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
%        ylim([0,180]);
          
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
           ylabel('0.1 sec');
       elseif pltIdx == 19
            ylabel('0.33 sec');
       elseif pltIdx == 25
            ylabel('1 sec');            
       end
   end
end

 fig = formatFig(fig, true, [param.numLasers, param.numLegs]);

 han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [joint ' Joint Angle Change']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

 
hold off;

fig_name = ['\' joint '_overview_angleChange'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

joint = param.joints{listdlg('ListString', param.joints, 'PromptString','Select laser:', 'SelectionMode','single', 'ListSize', [100 100])};

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% All joints %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot all joints, all lasers, one leg -- subtract baseline angle -- mean & sem 
fig = fullfig;
pltIdx = 0;
AX = [];
for leg = 1:param.numLegs
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numLegs, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       for joint = 1:param.numJoints
           if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
           elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
           elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
           elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
           end
           %plot the data!
           all_data = NaN( width(temp), param.vid_len_f);
           for vid = 1:width(temp) %CHANGE when plotting days 
              d = temp{vid};
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
           plot(param.x, yMean, 'color', Color(param.jointColors{joint}), 'linewidth', 1.5);
           fill_data = error_fill(param.x, yMean, ySEM);
           h = fill(fill_data.X, fill_data.Y, get_color(param.jointColors{joint}), 'EdgeColor','none');
           set(h, 'facealpha', param.jointFillWeights{joint});
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
           ylabel('L1');
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
           ylabel('L2');
       elseif pltIdx == 11
           ylabel('L3');
       elseif pltIdx == 16
           ylabel('R1');
       elseif pltIdx == 21
           ylabel('R2');
       elseif pltIdx == 26
           ylabel('R3');
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
        subplot(param.numLegs, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.numLegs, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, 'All Joint Angle Means & SEMs Aligned');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\allLegs_allJoints_overview_mean&SEM_aligned'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% Individual Flies %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot all joints, all lasers, one leg -- subtract baseline angle -- mean & sem 
fig = fullfig;
pltIdx = 0;
leg = 1;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       for fly = 1:height(param.flyList)
           %extract the joint data 
           if joint == 1; temp = joint_data_byFly.fly(fly).leg(leg).laser(laser).BC.joint;
           elseif joint == 2; temp = joint_data_byFly.fly(fly).leg(leg).laser(laser).CF.joint;
           elseif joint == 3; temp = joint_data_byFly.fly(fly).leg(leg).laser(laser).FTi.joint;
           elseif joint == 4; temp = joint_data_byFly.fly(fly).leg(leg).laser(laser).TiTa.joint; 
           end
           %plot the data!
           all_data = NaN( width(temp), param.vid_len_f);
           for vid = 1:width(temp) %CHANGE when plotting days 
              d = temp{vid};
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
           plot(param.x, yMean, 'color', param.flyColors(fly,:), 'linewidth', 1.5);
%            fill_data = error_fill(param.x, yMean, ySEM);
%            h = fill(fill_data.X, fill_data.Y, get_color(param.flyColors{fly}), 'EdgeColor','none');
%            set(h, 'facealpha', 0.2);
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
   hold off;
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
title(han, ' L1 Aligned Joint Angle Mean & SEM of Individual Flies');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

% hold off;

fig_name = ['\' param.legs{leg} '_overview_mean&SEM_aligned_byFly'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

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
       for fly = 1:height(param.flyList)
           %extract the joint data 
           if strcmp(joint, 'BC')
               temp = joint_data_byFly.fly(fly).leg(leg).laser(laser).BC.joint;      
           elseif strcmp(joint, 'CF')
               temp = joint_data_byFly.fly(fly).leg(leg).laser(laser).CF.joint;      
           elseif strcmp(joint, 'FTi')
               temp = joint_data_byFly.fly(fly).leg(leg).laser(laser).FTi.joint;      
           elseif strcmp(joint, 'TiTa')
               temp = joint_data_byFly.fly(fly).leg(leg).laser(laser).TiTa.joint;      
           end       %plot the data!
           all_data = NaN( width(temp), param.vid_len_f);
           for vid = 1:width(temp)
              d = temp{vid};
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
           plot(param.x, yMean, 'color', param.flyColors(fly,:), 'linewidth', 1.5);
%            fill_data = error_fill(param.x, yMean, ySEM);
%            h = fill(fill_data.X, fill_data.Y, get_color(param.flyColors{fly}), 'EdgeColor','none');
%            set(h, 'facealpha', 0.2);
       
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
       elseif  pltIdx == 5    
           title('R2');
       elseif pltIdx == 6
           title('R3');  
       elseif pltIdx == 7
           ylabel('0.03 sec');
       elseif pltIdx == 13
           ylabel('0.1 sec');
       elseif pltIdx == 19
            ylabel('0.33 sec');
       elseif pltIdx == 25
            ylabel('1 sec');            
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
title(han, [joint ' Aligned Joint Angle Mean & SEM of Individual Flies']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' joint '_overview_mean&SEM_aligned_byFly'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);  

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% Look at differences btw flies %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot all joints, all lasers, one leg -- subtract baseline angle 

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
          if height(d) == 600
              a = d(param.laser_on);
              d = d-a;
              plot(param.x, d); 
          end
       end
       
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
title(han, 'L1 Aligned Joint Angles');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))
hold off;

fig_name = ['\' param.legs{leg} '_overview_aligned'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all joints, all lasers, one leg -- subtract baseline angle -- mean & sem 
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
       all_data = NaN( width(temp), param.vid_len_f);
       for vid = 1:width(temp) %CHANGE when plotting days 
          d = temp{vid};
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
       plot(param.x, yMean, 'color', Color(param.expColor), 'linewidth', 1.5);
       fill_data = error_fill(param.x, yMean, ySEM);
       h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
       set(h, 'facealpha', 0.2);
       
       
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
title(han, ' L1 Aligned Joint Angle Mean & SEM');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

hold off;

fig_name = ['\' param.legs{leg} '_overview_mean&SEM_aligned'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
