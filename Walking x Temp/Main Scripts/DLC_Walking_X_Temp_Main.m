clear all; close all; clc;

% Select and load parquet file (the fly data)
[FilePath, version] = DLC_select_parquet();
[data, columns, column_names, path] = DLC_extract_parquet(FilePath);
[numReps, numConds, flyList, flyIndices] = DLC_extract_flies(columns, data);
param = DLC_load_params(data, version, flyList);
param.basler_length = 40;
param.vid_len_s = param.basler_length;
param.vid_len_f = param.vid_len_s * param.fps;
param.numReps = numReps;
param.numConds = numConds; 
param.flyList = flyList;
param.stimRegions = DLC_getStimRegions(data, param);
param.flyIndices = flyIndices;
param.columns = columns; 
param.column_names = column_names;
param.parquet = path;

initial_vars = who;

%%%%%%% CORRECT FICTRAC (TODO: delete once Pierre integrates correction)

camX = data.fictrac_delta_rot_cam_x;
camY = data.fictrac_delta_rot_cam_y; 
camZ = data.fictrac_delta_rot_cam_z;

%here are the coefficients from the linear regression for predicting each of the 3 variables:
%(random aside: it's cool that these coeffs mostly just swap the y and z axes and invert the y axis data like we did as a proxy!)
X_coeffs = [1.55417630179922e-19;0.998639999999997;0.0174592000000008;0.0491229999999999]; %for predicting fictrac_delta_rot_lab_x
Y_coeffs = [-2.54561126765530e-17;0.0491875999999992;-0.00328832000000049;-0.998784000000000]; %for predicting fictrac_delta_rot_lab_y
Z_coeffs = [6.79693102653525e-17;-0.0172764000000011;0.999841999999992;-0.00414261999999977]; %for predicting fictrac_delta_rot_lab_z

%predict delta rotations in lab coords
predicted_labX = X_coeffs(1) + camX*X_coeffs(2) + camY*X_coeffs(3) + camZ*X_coeffs(4); %fictrac_delta_rot_lab_x
predicted_labY = Y_coeffs(1) + camX*Y_coeffs(2) + camY*Y_coeffs(3) + camZ*Y_coeffs(4); %fictrac_delta_rot_lab_y
predicted_labZ = Z_coeffs(1) + camX*Z_coeffs(2) + camY*Z_coeffs(3) + camZ*Z_coeffs(4); %fictrac_delta_rot_lab_z

%compute other fictrac variables
[speed, direction, fwd, side, intx, inty, heading] = Fictrac_Variables(predicted_labX, predicted_labY, predicted_labZ);

%convert variable units to milimeters, seconds, and degrees
[speed, direction, fwd, side, intx, inty, heading, dr_lab_x, dr_lab_y, dr_lab_z] = convert_fictrac_units(speed, direction, fwd, side, intx, inty, heading, predicted_labX, predicted_labY, predicted_labZ, param.sarah_ball_r, param.fictrac_fps);

%override bad fictrac vars with good fictrac vars in data
data.fictrac_delta_rot_lab_x = dr_lab_x*-1; %sign flip so fly mvmt left is negative and right is positive. 
data.fictrac_delta_rot_lab_y = dr_lab_y; %fly mvmt backward is negative and forward is positive. 
data.fictrac_delta_rot_lab_z = dr_lab_z*-1; %sign flip so fly mvmt ccw is negative and cw is positive. 
data.fictrac_speed = speed';
data.fictrac_inst_dir = direction'; 
data.fictrac_int_forward = fwd'; 
data.fictrac_int_side = side'; 
data.fictrac_int_x = intx'; 
data.fictrac_int_y = inty'; 
data.fictrac_heading = heading';

% %%%%%%%

% param.forward_rot_thresh = 15; %inst_dir within this (degrees) of 0 or 360 is considered 'forward'
% data.forward_rotation = DLC_forward_rotation(data, param.forward_rot_thresh,param); % extract forward rotation. 
walkingData = data(~isnan(data.walking_bout_number),:); 

% Organize data for plotting 
joint_data = DLC_org_joint_data(data, param);
joint_data_byFly = DLC_org_joint_data_byFly(data, param);

% Extract step info
step = steps_walking_x_temp('-data', data, '-param', param);

initial_vars{end+1} = 'joint_data';
initial_vars{end+1} = 'joint_data_byFly';
initial_vars{end+1} = 'walkingData';
initial_vars{end+1} = 'step';

clearvars('-except',initial_vars{:}); initial_vars = who;
%% %%%%%%%%%%%% BEHAVIOR BREAKDOWN %%%%%%%%%%%%%%%

%% Behavior breakdown - Pie - all data - only displayed behaviors

behaviorColumns = find(contains(columns, '_number'));
behaviorData = table2array(data(:,behaviorColumns));
behaviorNums = sum(~isnan(behaviorData),1);

behaviorLabels = column_names(behaviorColumns);
behaviorLabels = cellfun(@(behaviorLabels) behaviorLabels(1:end-12), behaviorLabels, 'Uniform', 0);
displayedBehaviors = find(behaviorNums > 0);

fig = fullfig;
colormap(getPyPlot_cMap('tab10_r'));

p = pie(behaviorNums(displayedBehaviors), '%.2g%%'); %pie3 makes it 3D
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

%save
fig_name = ['\Behavior_Breakdown_onlyDisplayedBehaviors_AllData_Pie'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
clearvars('-except',initial_vars{:}); initial_vars = who;
%% Behavior breakdown - Pie - all data 

behaviorData = table2array(data(:,param.behaviorColumns));
behaviorNums = sum(~isnan(behaviorData),1);

fig = fullfig;
colormap(param.behaviorColors)

p = pie(behaviorNums, '%.2g%%'); %pie3 makes it 3D
pText = findobj(p,'Type','text');
pColor = findobj(p,'Type', 'color');
for txt = 1:length(pText)
    thisTxt = pText(txt);
    thisTxt.Color = param.baseColor;
    thisTxt.FontSize = 20;
end
%delete percent values <1 so they don't overlap
isSmall = startsWith({pText.String}, '<') | strcmp({pText.String}, '0%') | strcmp({pText.String}, '1%') | strcmp({pText.String}, '2%');  
delete(pText(isSmall));
fig = formatFig(fig, true);

%delete percent values <1 so they don't overlap
pText = findobj(p,'Type','text');
isSmall = startsWith({pText.String}, '<');  
delete(pText(isSmall));
title('Behavior of all data', 'FontSize', 30);

lgd = legend(param.behaviorLabels, 'Location', 'eastoutside', 'TextColor', param.baseColor, 'FontSize', 20);

%save
fig_name = ['\Behavior_Breakdown_AllData_Pie'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
clearvars('-except',initial_vars{:}); initial_vars = who;
%% Behavior breakdown - Pie - by temp - only displayed behaviors

behaviorColumns = find(contains(columns, '_number'));
behaviorDataLow = table2array(data(contains(data.StimulusProcedure, 'low'),behaviorColumns));
behaviorDataMed = table2array(data(contains(data.StimulusProcedure, 'med'),behaviorColumns));
behaviorDataHigh = table2array(data(contains(data.StimulusProcedure, 'high'),behaviorColumns));

behaviorNumsLow = sum(~isnan(behaviorDataLow),1);
behaviorNumsMed = sum(~isnan(behaviorDataMed),1);
behaviorNumsHigh = sum(~isnan(behaviorDataHigh),1);

behaviorLabels = column_names(behaviorColumns);
behaviorLabels = cellfun(@(behaviorLabels) behaviorLabels(1:end-12), behaviorLabels, 'Uniform', 0);
displayedBehaviors = find(behaviorNumsLow > 0 | behaviorNumsMed > 0 | behaviorNumsHigh > 0);

fig = fullfig;
t = tiledlayout(1,3,'TileSpacing','compact');
colormap(getPyPlot_cMap('tab10_r'));

% Create pie charts
ax1 = nexttile;
p  = pie(ax1,behaviorNumsLow(displayedBehaviors));
title('76-79F', 'FontSize', 30, 'Color', param.baseColor);
pText = findobj(p,'Type','text');
for txt = 1:length(pText)
    thisTxt = pText(txt);
    thisTxt.Color = param.baseColor;
    thisTxt.FontSize = 20;
end% 
%delete percent values <1 so they don't overlap
isSmall = startsWith({pText.String}, '<') | strcmp({pText.String}, '0%') | strcmp({pText.String}, '1%') | strcmp({pText.String}, '2%');  
delete(pText(isSmall));

ax2 = nexttile;
p = pie(ax2,behaviorNumsMed(displayedBehaviors));
title('80-84F', 'FontSize', 30, 'Color', param.baseColor);
pText = findobj(p,'Type','text');
for txt = 1:length(pText)
    thisTxt = pText(txt);
    thisTxt.Color = param.baseColor;
    thisTxt.FontSize = 20;
end% 
%delete percent values <1 so they don't overlap
isSmall = startsWith({pText.String}, '<') | strcmp({pText.String}, '0%') | strcmp({pText.String}, '1%') | strcmp({pText.String}, '2%');  
delete(pText(isSmall));

ax3 = nexttile;
p = pie(ax3,behaviorNumsHigh(displayedBehaviors));
t3 = title('85-89F', 'FontSize', 30, 'Color', param.baseColor);
pText = findobj(p,'Type','text');
for txt = 1:length(pText)
    thisTxt = pText(txt);
    thisTxt.Color = param.baseColor;
    thisTxt.FontSize = 20;
end% 
%delete percent values <1 so they don't overlap
isSmall = startsWith({pText.String}, '<') | strcmp({pText.String}, '0%') | strcmp({pText.String}, '1%') | strcmp({pText.String}, '2%');  
delete(pText(isSmall));

fig = formatFig(fig, true);
t3.FontSize = 30; %fix size of last title

% Create legend
lgd = legend(behaviorLabels(displayedBehaviors), 'TextColor', param.baseColor, 'FontSize', 20);
lgd.Layout.Tile = 'east';


han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, 'Behavior by temp', 'FontSize', 40, 'Color', param.baseColor);

%save
fig_name = ['\Behavior_Breakdown_onlyDisplayedBehaviors_AllData_ByTemp_Pie'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
clearvars('-except',initial_vars{:}); initial_vars = who;
%% Behavior breakdown - Pie - by temp

% behaviorColumns = find(contains(columns, '_number'));
behaviorDataLow = table2array(data(contains(data.StimulusProcedure, 'low'),param.behaviorColumns));
behaviorDataMed = table2array(data(contains(data.StimulusProcedure, 'med'),param.behaviorColumns));
behaviorDataHigh = table2array(data(contains(data.StimulusProcedure, 'high'),param.behaviorColumns));

behaviorNumsLow = sum(~isnan(behaviorDataLow),1);
behaviorNumsMed = sum(~isnan(behaviorDataMed),1);
behaviorNumsHigh = sum(~isnan(behaviorDataHigh),1);

fig = fullfig;
t = tiledlayout(1,3,'TileSpacing','compact');
colormap(param.behaviorColors)

% Create pie charts
ax1 = nexttile;
p  = pie(ax1,behaviorNumsLow);
title('76-79F', 'FontSize', 30, 'Color', param.baseColor);
pText = findobj(p,'Type','text');
for txt = 1:length(pText)
    thisTxt = pText(txt);
    thisTxt.Color = param.baseColor;
    thisTxt.FontSize = 20;
end% 
%delete percent values <1 so they don't overlap
isSmall = startsWith({pText.String}, '<') | strcmp({pText.String}, '0%') | strcmp({pText.String}, '1%') | strcmp({pText.String}, '2%');  
delete(pText(isSmall));

ax2 = nexttile;
p = pie(ax2,behaviorNumsMed);
title('80-84F', 'FontSize', 30, 'Color', param.baseColor);
pText = findobj(p,'Type','text');
for txt = 1:length(pText)
    thisTxt = pText(txt);
    thisTxt.Color = param.baseColor;
    thisTxt.FontSize = 20;
end% 
%delete percent values <1 so they don't overlap
isSmall = startsWith({pText.String}, '<') | strcmp({pText.String}, '0%') | strcmp({pText.String}, '1%') | strcmp({pText.String}, '2%');  
delete(pText(isSmall));

ax3 = nexttile;
p = pie(ax3,behaviorNumsHigh);
t3 = title('85-89F', 'FontSize', 30, 'Color', param.baseColor);
pText = findobj(p,'Type','text');
for txt = 1:length(pText)
    thisTxt = pText(txt);
    thisTxt.Color = param.baseColor;
    thisTxt.FontSize = 20;
end% 
%delete percent values <1 so they don't overlap
isSmall = startsWith({pText.String}, '<') | strcmp({pText.String}, '0%') | strcmp({pText.String}, '1%') | strcmp({pText.String}, '2%');  
delete(pText(isSmall));

fig = formatFig(fig, true);
t3.FontSize = 30; %fix size of last title

% Create legend
lgd = legend(param.behaviorLabels, 'TextColor', param.baseColor, 'FontSize', 20);
lgd.Layout.Tile = 'east';


han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, 'Behavior by temp', 'FontSize', 40, 'Color', param.baseColor);

%save
fig_name = ['\Behavior_Breakdown_AllData_ByTemp_Pie'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
clearvars('-except',initial_vars{:}); initial_vars = who;
%% Behavior breakdown - Pie - by temp - one fly

fly = 1; %row in flyList
flyid = flyList.flyid{fly}(1:end-2); 

flyData = data(contains(data.flyid, flyid),:);

% behaviorColumns = find(contains(columns, '_number'));
behaviorDataLow = table2array(flyData(contains(flyData.StimulusProcedure, 'low'),param.behaviorColumns));
behaviorDataMed = table2array(flyData(contains(flyData.StimulusProcedure, 'med'),param.behaviorColumns));
behaviorDataHigh = table2array(flyData(contains(flyData.StimulusProcedure, 'high'),param.behaviorColumns));

behaviorNumsLow = sum(~isnan(behaviorDataLow),1);
behaviorNumsMed = sum(~isnan(behaviorDataMed),1);
behaviorNumsHigh = sum(~isnan(behaviorDataHigh),1);

fig = fullfig;
t = tiledlayout(1,3,'TileSpacing','compact');
colormap(param.behaviorColors)

% Create pie charts
ax1 = nexttile;
p  = pie(ax1,behaviorNumsLow);
title('76-79F', 'FontSize', 30, 'Color', param.baseColor);
pText = findobj(p,'Type','text');
for txt = 1:length(pText)
    thisTxt = pText(txt);
    thisTxt.Color = param.baseColor;
    thisTxt.FontSize = 20;
end% 
%delete percent values <1 so they don't overlap
isSmall = startsWith({pText.String}, '<') | strcmp({pText.String}, '0%') | strcmp({pText.String}, '1%') | strcmp({pText.String}, '2%');  
delete(pText(isSmall));

ax2 = nexttile;
p = pie(ax2,behaviorNumsMed);
title('80-84F', 'FontSize', 30, 'Color', param.baseColor);
pText = findobj(p,'Type','text');
for txt = 1:length(pText)
    thisTxt = pText(txt);
    thisTxt.Color = param.baseColor;
    thisTxt.FontSize = 20;
end% 
%delete percent values <1 so they don't overlap
isSmall = startsWith({pText.String}, '<') | strcmp({pText.String}, '0%') | strcmp({pText.String}, '1%') | strcmp({pText.String}, '2%');  
delete(pText(isSmall));

ax3 = nexttile;
p = pie(ax3,behaviorNumsHigh);
t3 = title('85-89F', 'FontSize', 30, 'Color', param.baseColor);
pText = findobj(p,'Type','text');
for txt = 1:length(pText)
    thisTxt = pText(txt);
    thisTxt.Color = param.baseColor;
    thisTxt.FontSize = 20;
end% 
%delete percent values <1 so they don't overlap
isSmall = startsWith({pText.String}, '<') | strcmp({pText.String}, '0%') | strcmp({pText.String}, '1%') | strcmp({pText.String}, '2%');  
delete(pText(isSmall));

fig = formatFig(fig, true);
t3.FontSize = 30; %fix size of last title

% Create legend
lgd = legend(param.behaviorLabels, 'TextColor', param.baseColor, 'FontSize', 20);
lgd.Layout.Tile = 'east';


han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, 'Behavior by temp', 'FontSize', 40, 'Color', param.baseColor);

%save
fig_name = ['\Behavior_Breakdown_' strrep(flyid, ' ', '_') '_ByTemp_Pie'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% clearvars('-except',initial_vars{:}); initial_vars = who;
%% Behavior breakdown - Bar Stacked Count - by temp - by fly

%get flies
flyNums = flyList.flyid;
for fly = 1:height(flyList)
    flyNums(fly) = flyNums{fly}(1:end-2);
end
flyNums = unique(flyNums);

%get temps
temps = unique(data.StimulusProcedure);
[~,stringLength] = sort(cellfun(@length,temps),'ascend');
temps = temps(stringLength);

for fly = 1:height(flyNums)
    flyData = data(contains(data.flyid, flyNums(fly)), :);
    for temp = 1:height(temps) %low, med, high
        %matrix of bout numbers for all behaviors
        flyTempData = table2array(flyData(contains(flyData.StimulusProcedure, temps{temp}),param.behaviorColumns)); %matrix of bout numbers for all behaviors
        %turn all bout numbers to 1 so I can sum matrix to get behavior percents
        flyTempData(~isnan(flyTempData)) = 1;
        %get percent of each behavior in total behavior space. 
        stackData(fly, temp, :) = nansum(flyTempData, 1);
    end
    groupLabels(fly) = flyNums(fly);
end

fig = plotBarStackGroups(stackData, groupLabels, param, param.behaviorColumns);

%save
fig_name = ['\Behavior_Breakdown_ByFly_ByTemp_BarStackedCount'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
clearvars('-except',initial_vars{:}); initial_vars = who;
%% Behavior breakdown - Bar Stacked Percent - by temp - by fly

%get flies
flyNums = flyList.flyid;
for fly = 1:height(flyList)
    flyNums(fly) = flyNums{fly}(1:end-2);
end
flyNums = unique(flyNums);

%get temps
temps = unique(data.StimulusProcedure);
[~,stringLength] = sort(cellfun(@length,temps),'ascend');
temps = temps(stringLength);

for fly = 1:height(flyNums)
    flyData = data(contains(data.flyid, flyNums(fly)), :);
    for temp = 1:height(temps) %low, med, high
        %matrix of bout numbers for all behaviors
        flyTempData = table2array(flyData(contains(flyData.StimulusProcedure, temps{temp}),param.behaviorColumns)); %matrix of bout numbers for all behaviors
        %turn all bout numbers to 1 so I can sum matrix to get behavior percents
        flyTempData(~isnan(flyTempData)) = 1;
        %get percent of each behavior in total behavior space. 
        stackData(fly, temp, :) = nansum(flyTempData, 1)/height(flyTempData);
    end
    groupLabels(fly) = flyNums(fly);
end

fig = plotBarStackGroups(stackData, groupLabels, param, param.behaviorColumns);

%save
fig_name = ['\Behavior_Breakdown_ByFly_ByTemp_BarStackedPercent'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
clearvars('-except',initial_vars{:}); initial_vars = who;
%% Single behavior breakdown - Bar Stacked Count - by temp - by fly

behavior = 'walking_bout_number'; %must be a bout_number column name in data

%get flies
flyNums = flyList.flyid;
for fly = 1:height(flyList)
    flyNums(fly) = flyNums{fly}(1:end-2);
end
flyNums = unique(flyNums);

%get temps
temps = unique(data.StimulusProcedure);
[~,stringLength] = sort(cellfun(@length,temps),'ascend'); %sort from low to high
temps = temps(stringLength);

%get behavior
behaviorColumn = param.behaviorColumns(strcmpi(param.behaviorNames, behavior));

for fly = 1:height(flyNums)
    flyData = data(contains(data.flyid, flyNums(fly)), :);
    for temp = 1:height(temps) %low, med, high
        %matrix of bout numbers for all behaviors
        flyTempData = table2array(flyData(contains(flyData.StimulusProcedure, temps{temp}),behaviorColumn)); %matrix of bout numbers for all behaviors
        %turn all bout numbers to 1 so I can sum matrix to get behavior percents
        flyTempData(~isnan(flyTempData)) = 1;
        %get percent of each behavior in total behavior space. 
        stackData(fly, temp, :) = nansum(flyTempData, 1);
    end
    groupLabels(fly) = flyNums(fly);
end

fig = plotBarStackGroups(stackData, groupLabels, param, behaviorColumn);

%save
fig_name = ['\Behavior_Breakdown_onlyWalking_ByFly_ByTemp_BarStackedCount'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
clearvars('-except',initial_vars{:}); initial_vars = who;
%% Single behavior breakdown - Bar Stacked Percent - by temp - by fly

behavior = 'walking_bout_number'; %must be a bout_number column name in data


%get flies
flyNums = flyList.flyid;
for fly = 1:height(flyList)
    flyNums(fly) = flyNums{fly}(1:end-2);
end
flyNums = unique(flyNums);

%get temps
temps = unique(data.StimulusProcedure);
[~,stringLength] = sort(cellfun(@length,temps),'ascend'); %sort from low to high
temps = temps(stringLength);


%get behavior
behaviorColumn = param.behaviorColumns(strcmpi(param.behaviorNames, behavior));


for fly = 1:height(flyNums)
    flyData = data(contains(data.flyid, flyNums(fly)), :);
    for temp = 1:height(temps) %low, med, high
        %matrix of bout numbers for all behaviors
        flyTempData = table2array(flyData(contains(flyData.StimulusProcedure, temps{temp}),behaviorColumn)); %matrix of bout numbers for all behaviors
        %turn all bout numbers to 1 so I can sum matrix to get behavior percents
        flyTempData(~isnan(flyTempData)) = 1;
        %get percent of each behavior in total behavior space. 
        stackData(fly, temp, :) = nansum(flyTempData, 1)/height(flyTempData);
    end
    groupLabels(fly) = flyNums(fly);
end

fig = plotBarStackGroups(stackData, groupLabels, param, behaviorColumn);

%save
fig_name = ['\Behavior_Breakdown_onlyWalking_ByFly_ByTemp_BarStackedPercent'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
clearvars('-except',initial_vars{:}); initial_vars = who;

%% %%%%%%%%%%%% SPEED X TEMP X FLY %%%%%%%%%%%%%%%

%% plot - ALL flies - x,y,z ball speeds x temp for steps of a leg, forward speed [5-35mm/s], color by fly, lsline

% for leg = 1:param.numLegs
leg = 1;

good_steps = find(step(leg).speed_y >= 5 & step(leg).speed_y < 35); % filter for forward walking

fig = fullfig;
nRows = 2; 
nCols = 3; 
speeds = {'speed_x', 'speed_y', 'speed_z'};
speed_names = {'Sideslip velocity (mm/s)', 'Forward velocity (mm/s)', 'Rotational velocity (mm/s)'};
[~,~,colors] = unique(step(leg).fly);
for s = 1:width(speeds)
    subplot(nRows, nCols, s);
    scatter(step(leg).temp(good_steps), step(leg).(speeds{s})(good_steps), [0.5], colors(good_steps));
    lsline 
    colormap lines
    if s == 2
        xlabel('Temp (c)', 'FontSize', 20); 
    end
    ylabel(speed_names{s}, 'FontSize', 20); 
%     title([param.legs{leg} ' steps: speeds x temp']);

    ax(s) = gca;
    ax(s).FontSize = 20; 
end

fig = formatFig(fig, true, [nRows, nCols]); 

for s = 1:width(speeds)
    ax(s).FontSize = 20; 
end

%save 
fig_name = ['\' param.legs{leg} ' steps - speeds x temp - colored by fly with lsline - all flies'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
    
% end
%% plot - ALL flies - x,y,z ball speeds x temp for steps of a leg, forward speed [5-35mm/s], color by metric, lsline

metric = 'stance_dur'; %column name in step

% for leg = 1:param.numLegs
leg = 1;
    
    good_steps = find(step(leg).speed_y >= 5 & step(leg).speed_y < 35); % filter for forward walking

    fig = fullfig;
    nRows = 2; 
    nCols = 3; 
    speeds = {'speed_x', 'speed_y', 'speed_z'};
    
    for s = 1:width(speeds)
        subplot(nRows, nCols, s);
        scatter(step(leg).temp(good_steps), step(leg).(speeds{s})(good_steps), [0.5], step(leg).(metric)(good_steps));
        lsline 
        colormap jet
        xlabel('temp (c)'); 
        ylabel(strrep(speeds{s}, '_', ' ')); 
        title([param.legs{leg} ' steps: speeds x temp']);
        caxis manual
        caxis([min(step(leg).(metric)) max(step(leg).(metric))]);
        ax = gca;
        ax.FontSize = 16; 
    end
    c = colorbar;
    c.Color = 'white';
    fig = formatFig(fig, true, [nRows, nCols]);  
    
    %save 
    fig_name = ['\' param.legs{leg} ' steps - speeds x temp - colored by ' metric ' with lsline - all flies'];
    save_figure(fig, [param.googledrivesave fig_name], param.fileType);

    clearvars('-except',initial_vars{:}); initial_vars = who;
    
% end
%% plot - ONE flies - x,y,z ball speeds x temp for steps of a leg, forward speed [5-35mm/s], color by metric, lsline

metric = 'freq'; %column name in step
fly = 3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%get flies
flyNums = flyList.flyid;
for f = 1:height(flyList)
    flyNums(f) = flyNums{f}(1:end-2);
end
flyNums = unique(flyNums);
flyid = flyNums(fly); %use extract steps from this fly 


% for leg = 1:param.numLegs
leg = 1;
    
    good_steps = find(step(leg).speed_y >= 5 & step(leg).speed_y < 35 & contains(step(leg).fly, flyid)); % filter for forward walking and fly num

    fig = fullfig;
    nRows = 2; 
    nCols = 3; 
    speeds = {'speed_x', 'speed_y', 'speed_z'};
    
    for s = 1:width(speeds)
        subplot(nRows, nCols, s);
        scatter(step(leg).temp(good_steps), step(leg).(speeds{s})(good_steps), [0.5], step(leg).(metric)(good_steps));
        lsline 
        colormap jet
        xlabel('temp (c)'); 
        ylabel(strrep(speeds{s}, '_', ' ')); 
        title([param.legs{leg} ' steps: speeds x temp']);
        caxis manual
        caxis([min(step(leg).(metric)) max(step(leg).(metric))]);
        ax = gca;
        ax.FontSize = 16; 
    end
    c = colorbar;
    c.Color = 'white';
    fig = formatFig(fig, true, [nRows, nCols]);  
    
    %save 
    fig_name = ['\' param.legs{leg} ' steps - speeds x temp - colored by ' metric ' with lsline - ' flyid{:}];
    save_figure(fig, [param.googledrivesave fig_name], param.fileType);

    clearvars('-except',initial_vars{:}); initial_vars = who;
    
% end

%% plot - ALL flies - x,y,z ball speeds x temp for steps of a leg, forward speed [5-35mm/s], side and rot speeds < 5mm/s, color by fly, lsline

% for leg = 1:param.numLegs
leg = 1;

good_steps = find(step(leg).speed_y >= 5 & ...
                  step(leg).speed_y < 35 & ...
              abs(step(leg).speed_x) < 3 & ...
              abs(step(leg).speed_z) < 3); % filter for forward walking

fig = fullfig;
nRows = 2; 
nCols = 3; 
speeds = {'speed_x', 'speed_y', 'speed_z'};
speed_names = {'Sideslip velocity (mm/s)', 'Forward velocity (mm/s)', 'Rotational velocity (mm/s)'};
[~,~,colors] = unique(step(leg).fly);
for s = 1:width(speeds)
    subplot(nRows, nCols, s);
    scatter(step(leg).temp(good_steps), step(leg).(speeds{s})(good_steps), [0.5], colors(good_steps));
    lsline 
    colormap lines
    if s == 2
        xlabel('Temp (c)', 'FontSize', 20); 
    end
    ylabel(speed_names{s}, 'FontSize', 20); 
%     title([param.legs{leg} ' steps: speeds x temp']);

    ax(s) = gca;
    ax(s).FontSize = 20; 
end

fig = formatFig(fig, true, [nRows, nCols]); 

for s = 1:width(speeds)
    ax(s).FontSize = 20; 
end

%save 
fig_name = ['\' param.legs{leg} ' steps - speeds x temp - colored by fly with lsline - all flies - sideslip & rot vels < 3'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
    
% end
%% plot - ALL flies - x,y,z ball speeds x temp for steps of a leg, forward speed [5-35mm/s], side and rot speeds < 5mm/s, color by fly, lsline

metric = 'length'; %column name in step


% for leg = 1:param.numLegs
leg = 1;

good_steps = find(step(leg).speed_y >= 5 & ...
                  step(leg).speed_y < 35 & ...
              abs(step(leg).speed_x) < 5 & ...
              abs(step(leg).speed_z) < 5); % filter for forward walking

fig = fullfig;
nRows = 2; 
nCols = 3; 
speeds = {'speed_x', 'speed_y', 'speed_z'};
speed_names = {'Sideslip velocity (mm/s)', 'Forward velocity (mm/s)', 'Rotational velocity (mm/s)'};
for s = 1:width(speeds)
    subplot(nRows, nCols, s);
    scatter(step(leg).temp(good_steps), step(leg).(speeds{s})(good_steps), [0.5], step(leg).(metric)(good_steps));
   
    if s == 2
        xlabel('Temp (c)', 'FontSize', 20); 
    end
    ylabel(speed_names{s}, 'FontSize', 20); 

    lsline 
    colormap jet
    caxis manual
    caxis([min(step(leg).(metric)) max(step(leg).(metric))]);
    ax(s) = gca;
    ax(s).FontSize = 16; 
end
    c = colorbar;
    c.Color = 'white';
    c.Label.String = strrep(metric, '_', ' ');
    fig = formatFig(fig, true, [nRows, nCols]);  

for s = 1:width(speeds)
    ax(s).FontSize = 20; 
end

%save 
fig_name = ['\' param.legs{leg} ' steps - speeds x temp - colored by ' metric ' with lsline - all flies - sideslip & rot vels < 3'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
    
% end



%% plot steps in 3D speed area, color by fly 
%% plot steps in 3D speed area, color by temp 

fig = fullfig;
nRows = 2; 
nCols = 3; 
order = [4,5,6,1,2,3];
for leg = 1:param.numLegs
    subplot(nRows, nCols, order(leg));
    scatter3(step(leg).speed_x, step(leg).speed_y, step(leg).speed_z, [0.3], step(leg).temp);
    xlabel('side speed'); 
    ylabel('forward speed'); 
    zlabel('turn speed');
    title(param.legs{leg});
end

fig = formatFig3D(fig, true, [nRows, nCols]);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% plot ball speed x temp for steps 

fig = fullfig;
nRows = 2; 
nCols = 3; 
order = [4,5,6,1,2,3];
for leg = 1:param.numLegs
    subplot(nRows, nCols, order(leg));
    scatter(step(leg).temp, step(leg).speed_z);
    xlabel('temp (c)'); 
    ylabel('side speed'); 
    title(param.legs{leg});
end

fig = formatFig(fig, true, [nRows, nCols]);  
clearvars('-except',initial_vars{:}); initial_vars = who;

%% %%%%%%%%%%%% SPEED RANGE X TEMP X FLY %%%%%%%%%%%%%%%

%% plot - ALL flies - step metric x temp for a speed range (x,y,z)

metric = 'freq';

%get speed ranges
[x_out, x_L, x_U, x_C] = isoutlier(step(1).speed_x, 'percentile', [35 55]); %bounds for speed_x
[z_out, z_L, z_U, z_C] = isoutlier(step(1).speed_z, 'percentile', [35 55]); %bounds for speed_z
y_L = 15; %lower bound for speed_y
y_U = 20; %upper bound for speed_y

%toggle for manual x, z speed bounds
x_L = -1; %lower bound for speed_y
x_U = 1; %upper bound for speed_y
z_L = -1; %lower bound for speed_y
z_U = 1; %upper bound for speed_y

leg = 1;

good_steps = find(step(leg).speed_x > x_L & step(leg).speed_x < x_U & ... 
                  step(leg).speed_y > y_L & step(leg).speed_y < y_U & ... 
                  step(leg).speed_z > z_L & step(leg).speed_z < z_U);
              
 fig = fullfig; 
 rows = 2;
 cols = 3; 
 
 %color by x speed
 subplot(rows, cols, 1); hold on
 scatter(step(leg).temp(good_steps), step(leg).(metric)(good_steps), [], step(leg).speed_x(good_steps), 'filled'); lsline;           
 colormap(gca,'jet')
 xlabel('temp (c)'); 
 ylabel(metric); 
 title('sideslip velocity');
 ax = gca;
 ax.FontSize = 16; 
 c = colorbar; 
 c.Color = 'white';
 hold off
 
 %color by y speed
 subplot(rows, cols, 2); hold on
 scatter(step(leg).temp(good_steps), step(leg).(metric)(good_steps), [], step(leg).speed_y(good_steps), 'filled'); lsline;           
 colormap(gca,'jet')
 xlabel('temp (c)'); 
 ylabel(metric); 
 title('forward velocity');
 ax = gca;
 ax.FontSize = 16; 
 c = colorbar; 
 c.Color = 'white';
 hold off
 
 %color by z speed
 subplot(rows, cols, 3);
 scatter(step(leg).temp(good_steps), step(leg).(metric)(good_steps), [], step(leg).speed_z(good_steps), 'filled'); lsline;           
 colormap(gca,'jet')
 xlabel('temp (c)'); 
 ylabel(metric); 
 title('rotational velocity');
 ax = gca;
 ax.FontSize = 16; 
 c = colorbar; 
 c.Color = 'white';
 
 %color by fly 
 subplot(rows, cols, 4);
 [~,~,colors] = unique(step(leg).fly);
 scatter(step(leg).temp(good_steps), step(leg).(metric)(good_steps), [], colors(good_steps), 'filled'); lsline;           
 xlabel('temp (c)'); 
 ylabel(metric); 
 title('fly');
 t = TextLocation(['n=' num2str(height(good_steps)) ' steps'],'Location','best');
 t.FontSize = 16;
 ax = gca;
 ax.FontSize = 16; 
 c = colorbar;
 c.Color = 'white';
 cmap = lines(height(unique(colors)));
 colormap(gca, cmap);

 fig = formatFig(fig, true, [rows, cols]);
 
 
%save 
fig_name = ['\' param.legs{leg} ' steps - step ' metric ' x temp - speed range x(' num2str(x_L) ',' num2str(x_U) ') y(' num2str(y_L) ',' num2str(y_U) ') z(' num2str(z_L) ',' num2str(z_U) ') - colored by speeds and fly num with lsline - all flies'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

    
% A work in progress to plot the ball movement during the steps plotted
% above. Need to rotate the steps to align them... still working on that
% part. Ask BP for help. 

% %now plot the aligned ball movement for all of these steps
% fig = fullfig; hold on;
% for s = 1:height(good_steps)
%    idxs = step(leg).step_start_idx(s):step(leg).step_end_idx(s);
%    int_x = data.fictrac_int_x(idxs) - data.fictrac_int_x(idxs(1));
%    int_y = data.fictrac_int_y(idxs) - data.fictrac_int_y(idxs(1));
%    
%    %%%Angle Between Two Line%%%
%     % Line 1: point(0,0) to (0,1)
%     % Line 2: point(0,0) to (3,0)
%     v1=[0,30]-[0,0]; 
%     v2=[0,0]-[data.fictrac_int_x(idxs(2)),data.fictrac_int_y(idxs(2))];
%     a1 = mod(atan2( det([v1;v2;]) , dot(v1,v2) ), 2*pi );
%    
%    theta = deg2rad(a1);
%    R = [cos(theta) -sin(theta); sin(theta) cos(theta)]; %rotation matrix for ccw rotation
%    
%    new_xy =  R * [int_x'; int_y'];
%    new_int_x = new_xy(1,:);
%    new_int_y = new_xy(2,:);
%    
%    plot(int_x, int_y); hold on
%    plot(new_int_x, new_int_y); hold off
% 
%    
%    
% end
% hold off

clearvars('-except',initial_vars{:}); initial_vars = who;
%% plot - ONE fly - step metric x temp for a speed range (x,y,z)

leg = 1;
max_speed_x = 3;
min_speed_y = 14;
max_speed_y = 16;
max_speed_z = 3;
metric = 'stance_dur';

fig = fullfig; 

for f = 1:height(flyList)
    fly = flyList.flyid{f}(1:end-2);
    good_steps = find(strcmpi(step(leg).fly, fly) & ...
                          abs(step(leg).speed_x) < max_speed_x & ... 
                              step(leg).speed_y > min_speed_y & step(leg).speed_y < max_speed_y & ... 
                          abs(step(leg).speed_z) < max_speed_z);
     %color by y speed
     scatter(step(leg).temp(good_steps), step(leg).(metric)(good_steps), [], step(leg).speed_y(good_steps), 'filled'); hold on; lsline;            
end

colormap(gca,'jet')
xlabel('Temperature (c)'); 
ylabel(metric); 
title('Forward velocity (mm/s)');
ax = gca;
ax.FontSize = 20; 
c = colorbar; 
c.Color = 'white';
 
fig = formatFig(fig, true); 
 
%save 
fig_name = ['\' param.legs{leg} ' steps - step ' metric ' x temp - speed range x_below_' num2str(max_speed_x) ' y_btw_' num2str(min_speed_y) ',' num2str(max_speed_y) ' z_above_' num2str(max_speed_z) ' - colored by speed y with lsline - all flies'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% plot all ball speeds x temp for steps of a leg, dscatter - TODO: density units???

for leg = 1:param.numLegs
    
    fig = fullfig;
    nRows = 1; 
    nCols = 3; 
    speeds = {'speed_x', 'speed_y', 'speed_z'};
    [~,~,colors] = unique(step(leg).fly);
    for s = 1:width(speeds)
        subplot(nRows, nCols, s);
        dscatter(step(leg).temp, step(leg).(speeds{s}));
        xlabel('temp (c)'); 
        ylabel(strrep(speeds{s}, '_', ' ')); 
        title([param.legs{leg} ' steps: speeds x temp']);
    end

    fig = formatFig(fig, true, [nRows, nCols]);  

    %save 
    fig_name = ['\' param.legs{leg} ' steps - speeds x temp - density scatter'];
    save_figure(fig, [param.googledrivesave fig_name], param.fileType);

    clearvars('-except',initial_vars{:}); initial_vars = who;
    
end
%% Get indices of steps walking forward vs turning
%% Set thresholds for 'straight' walking vs 'turning'

% straight_thresh_x = 





for leg = 1:param.numLegs
    % forward walking is delta_y > 3mm/s, delta_x < 1mm/s, delta_z < 1mm/s
    forward_idxs{leg} = abs(step(leg).speed_x) < 2 & step(leg).speed_y > 10 & step(leg).speed_y < 12 & abs(step(leg).speed_z) < 2;
    
    % turning  is delta_y < 1mm/s, delta_x < 1mm/s, delta_z > 3mm/s
    left_turn_idxs{leg} = abs(step(leg).speed_x) < 1 & step(leg).speed_y < 1 & step(leg).speed_z < -3;
    right_turn_idxs{leg} = abs(step(leg).speed_x) < 1 & step(leg).speed_y < 1 & step(leg).speed_z > 3;
end

%% Plot step metrics in these speeds across temps



scatter(step(leg).temp(forward_idxs{leg}),  step(leg).freq(forward_idxs{leg}));
scatter(step(leg).temp(forward_idxs{leg}),  step(leg).length(forward_idxs{leg}));





%% %%%%%%%%%%%% COVARIANCE MATRICES %%%%%%%%%%%%%%%

%% Covariance matrix for walking data (ANLGES)

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1_BC'));
endJnt = find(contains(columns, 'R3E_z'));
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

%normalize data
%1) subtract mean 
jointWalkingData = jointWalkingData - nanmean(jointWalkingData);
%2) divide by std
jointWalkingData = jointWalkingData ./ nanstd(jointWalkingData);


%calculate covariance 
C = cov(jointWalkingData);

%plot covariance matrix
fig = fullfig;
h = heatmap(C); 
h.Title = 'Covariance of joint angles during walking';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = parula;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Walking'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Covariance matrix for walking data (positions x angles - for BP)

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1_BC'));
endJnt = find(contains(columns, 'R3E_z'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = {'L1E_x', 'L1E_y', 'L1E_z', 'L2E_x', 'L2E_y', 'L2E_z', 'L3E_x', 'L3E_y', 'L3E_z', 'R1E_x', 'R1E_y', 'R1E_z', 'R2E_x', 'R2E_y', 'R2E_z', 'R3E_x', 'R3E_y', 'R3E_z','L1_BC', 'L1_CF', 'L1_FTi', 'L1_TiTa','L2_BC', 'L2_CF', 'L2_FTi', 'L2_TiTa', 'L3_BC', 'L3_CF', 'L3_FTi', 'L3_TiTa', 'R1_BC', 'R1_CF', 'R1_FTi', 'R1_TiTa','R2_BC', 'R2_CF', 'R2_FTi', 'R2_TiTa', 'R3_BC', 'R3_CF', 'R3_FTi', 'R3_TiTa'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 

% subData = 1:24; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');
% 
% invert T3 and T2 signals so peaks correspond to stance start like for T1
% invertJnts = find(contains(jointLabels, '3-') | contains(jointLabels, '2-'));

jointWalkingData = table2array(jointWalkingData);
% jointWalkingData(:,invertJnts) = jointWalkingData(:,invertJnts)*-1;

%normalize data
%1) subtract mean 
jointWalkingData = jointWalkingData - nanmean(jointWalkingData);
%2) divide by std
jointWalkingData = jointWalkingData ./ nanstd(jointWalkingData);


%calculate covariance 
C = cov(jointWalkingData);

%plot covariance matrix
fig = fullfig;
h = heatmap(C); 
h.Title = 'Covariance of joint angles during walking';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_&_Positions_Walking_forBP'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Covariance matrix for walking data (positions x angles CROPPED - for BP)

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1_BC'));
endJnt = find(contains(columns, 'R3E_z'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = {'L1E_x', 'L1E_y', 'L1E_z', 'L2E_x', 'L2E_y', 'L2E_z', 'L3E_x', 'L3E_y', 'L3E_z', 'R1E_x', 'R1E_y', 'R1E_z', 'R2E_x', 'R2E_y', 'R2E_z', 'R3E_x', 'R3E_y', 'R3E_z','L1_BC', 'L1_CF', 'L1_FTi', 'L1_TiTa','L2_BC', 'L2_CF', 'L2_FTi', 'L2_TiTa', 'L3_BC', 'L3_CF', 'L3_FTi', 'L3_TiTa', 'R1_BC', 'R1_CF', 'R1_FTi', 'R1_TiTa','R2_BC', 'R2_CF', 'R2_FTi', 'R2_TiTa', 'R3_BC', 'R3_CF', 'R3_FTi', 'R3_TiTa'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 

% subData = 1:24; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');
% 
% invert T3 and T2 signals so peaks correspond to stance start like for T1
% invertJnts = find(contains(jointLabels, '3-') | contains(jointLabels, '2-'));

jointWalkingData = table2array(jointWalkingData);
% jointWalkingData(:,invertJnts) = jointWalkingData(:,invertJnts)*-1;

%normalize data
%1) subtract mean 
jointWalkingData = jointWalkingData - nanmean(jointWalkingData);
%2) divide by std
jointWalkingData = jointWalkingData ./ nanstd(jointWalkingData);


%calculate covariance 
C = cov(jointWalkingData);

numYaxis = 18; %num joint positions or whateber goes on y axis 

C = C(1:numYaxis, numYaxis+1:end);

%plot covariance matrix
fig = fullfig;
h = heatmap(C); 
h.Title = 'Covariance of joint angles during walking';
h.XDisplayLabels = jointLabels(numYaxis+1:end);
h.YDisplayLabels = jointLabels(1:numYaxis);
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels(1:numYaxis)), width(jointLabels(numYaxis+1:end))]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_&_Positions_Walking_CROPPED_forBP'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Covariance matrix for walking data (y positions x fti angles - for BP)

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1_BC'));
endJnt = find(contains(columns, 'R3E_z'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = {'L1E_y', 'L2E_y', 'L3E_y', 'R1E_y', 'R2E_y', 'R3E_y', 'L1_FTi', 'L2_FTi', 'L3_FTi', 'R1_FTi', 'R2_FTi', 'R3_FTi'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
% subData = 1:24; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

% invert T3 and T2 signals so peaks correspond to stance start like for T1
% invertJnts = find(contains(jointLabels, '3-') | contains(jointLabels, '2-'));

jointWalkingData = table2array(jointWalkingData);
% jointWalkingData(:,invertJnts) = jointWalkingData(:,invertJnts)*-1;

%normalize data
%1) subtract mean 
jointWalkingData = jointWalkingData - nanmean(jointWalkingData);
%2) divide by std
jointWalkingData = jointWalkingData ./ nanstd(jointWalkingData);


%calculate covariance 
C = cov(jointWalkingData);

%plot covariance matrix
fig = fullfig;
h = heatmap(C); 
h.Title = 'Covariance of during walking';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_TarsiYPositions_x_FTiAnglesOnly_Walking_BP'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Covariance matrix for walking data (y positions x fti angles CROPPED - for BP)

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1_BC'));
endJnt = find(contains(columns, 'R3E_z'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = {'L1E_y', 'L2E_y', 'L3E_y', 'R1E_y', 'R2E_y', 'R3E_y', 'L1_FTi', 'L2_FTi', 'L3_FTi', 'R1_FTi', 'R2_FTi', 'R3_FTi'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
% subData = 1:24; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

% invert T3 and T2 signals so peaks correspond to stance start like for T1
% invertJnts = find(contains(jointLabels, '3-') | contains(jointLabels, '2-'));

jointWalkingData = table2array(jointWalkingData);
% jointWalkingData(:,invertJnts) = jointWalkingData(:,invertJnts)*-1;

%normalize data
%1) subtract mean 
jointWalkingData = jointWalkingData - nanmean(jointWalkingData);
%2) divide by std
jointWalkingData = jointWalkingData ./ nanstd(jointWalkingData);


%calculate covariance 
C = cov(jointWalkingData);

numYaxis = 6; %num joint positions or whateber goes on y axis 

C = C(1:numYaxis, numYaxis+1:end);

%plot covariance matrix
fig = fullfig;
h = heatmap(C); 
h.Title = 'Covariance of during walking';
h.XDisplayLabels = jointLabels(numYaxis+1:end);
h.YDisplayLabels = jointLabels(1:numYaxis);
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels(1:numYaxis)), width(jointLabels(numYaxis+1:end))]);
%save 
fig_name = ['\Covariance_Matix_TarsiYPositions_x_FTiAnglesOnly_Walking_Cropped_BP'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Covariance matrix for walking data (y positions x t1&t3 fti angles and t2 cf rot - for BP)
%Problem is that angles x angles have super high covariance because they
%change a lot, even more than y positions and y positions because the angle numbers (degrees) are larger values than the position numbers.   
%TODO normalize data first!!!! (subtract mean and divide by std.)
% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1_BC'));
endJnt = find(contains(columns, 'R3E_z'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = {'L1E_y', 'L2E_y', 'L3E_y', 'R1E_y', 'R2E_y', 'R3E_y', 'L1_FTi', 'L2B_rot', 'L3_FTi', 'R1_FTi', 'R2B_rot', 'R3_FTi'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
% subData = 1:24; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%fix any wraparound issues for rotation data
wrapJnts = find(contains(jointLabels, 'rot'));
jointWalkingData = table2array(jointWalkingData);
for w = 1:width(wrapJnts)
    temp = jointWalkingData(:,wrapJnts(w));
    temp(temp<0) = temp(temp<0)+360;
    jointWalkingData(:,wrapJnts(w)) = temp;
end

%normalize data
%1) subtract mean 
jointWalkingData = jointWalkingData - nanmean(jointWalkingData);
%2) divide by std
jointWalkingData = jointWalkingData ./ nanstd(jointWalkingData);

%calculate covariance 
C = cov(jointWalkingData);
p = symrcm(C);
R = C(p,p);

%plot covariance matrix
fig = fullfig;
h = heatmap(R); 
h.Title = 'Covariance during walking';
h.XDisplayLabels = jointLabels(p);
h.YDisplayLabels = jointLabels(p);
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels(p)), width(jointLabels(p))]);
%save 
fig_name = ['Covariance_Matix_TarsiTips_x_FTi_Walking_sorted_BP'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Covariance matrix for walking data (y positions x t1&t3 fti angles and t2 cf rot CROPPED - for BP)

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1_BC'));
endJnt = find(contains(columns, 'R3E_z'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = {'L1E_y', 'L2E_y', 'L3E_y', 'R1E_y', 'R2E_y', 'R3E_y', 'L1_FTi', 'L2B_rot', 'L3_FTi', 'R1_FTi', 'R2B_rot', 'R3_FTi'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
% subData = 1:24; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%fix any wraparound issues for rotation data
wrapJnts = find(contains(jointLabels, 'rot'));
jointWalkingData = table2array(jointWalkingData);
for w = 1:width(wrapJnts)
    temp = jointWalkingData(:,wrapJnts(w));
    temp(temp<0)+360;
    jointWalkingData(:,wrapJnts(w)) = temp;
end

%normalize data
%1) subtract mean 
jointWalkingData = jointWalkingData - nanmean(jointWalkingData);
%2) divide by std
jointWalkingData = jointWalkingData ./ nanstd(jointWalkingData);


%calculate covariance 
C = cov(jointWalkingData);

numYaxis = 6; %num joint positions or whatever goes on y axis 

C = C(1:numYaxis, numYaxis+1:end);

%plot covariance matrix
fig = fullfig;
h = heatmap(C); 
h.Title = 'Covariance during walking';
h.XDisplayLabels = jointLabels(numYaxis+1:end);
h.YDisplayLabels = jointLabels(1:numYaxis);
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels(1:numYaxis)), width(jointLabels(numYaxis+1:end))]);
%save 
fig_name = ['Covariance_Matix_TarsiTips_x_FTi_Walking_Cropped_BP'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Covariance matrix for walking data (L1 positions x L1 all joint data - for BP)
%Problem is that angles x angles have super high covariance because they
%change a lot, even more than y positions and y positions because the angle numbers (degrees) are larger values than the position numbers.   
%TODO normalize data first!!!! (subtract mean and divide by std.)
% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1_BC'));
endJnt = find(contains(columns, 'R3E_z'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = {'L1E_y', 'L1E_x', 'L1E_z', 'L1A_abduct', 'L1A_flex', 'L1A_rot', 'L1B_flex', 'L1B_rot', 'L1C_flex', 'L1C_rot','L1D_flex'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
% subData = 1:24; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%fix any wraparound issues for rotation data
wrapJnts = find(contains(jointLabels, 'rot'));
jointWalkingData = table2array(jointWalkingData);
for w = 1:width(wrapJnts)
    temp = jointWalkingData(:,wrapJnts(w));
    temp(temp<0) = temp(temp<0)+360;
    jointWalkingData(:,wrapJnts(w)) = temp;
end

%normalize data
%1) subtract mean 
jointWalkingData = jointWalkingData - nanmean(jointWalkingData);
%2) divide by std
jointWalkingData = jointWalkingData ./ nanstd(jointWalkingData);

%calculate covariance 
C = cov(jointWalkingData);

%plot covariance matrix
fig = fullfig;
h = heatmap(C); 
h.Title = 'Covariance during walking';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['Covariance_Matix_L1TarsiPos_x_L1allJoints_Walking_BP'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Covariance matrix for walking data (L1 positions x L1 all joint data - for BP)
%Problem is that angles x angles have super high covariance because they
%change a lot, even more than y positions and y positions because the angle numbers (degrees) are larger values than the position numbers.   
%TODO normalize data first!!!! (subtract mean and divide by std.)
% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1_BC'));
endJnt = find(contains(columns, 'R3E_z'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = {'L2E_y', 'L2E_x', 'L2E_z', 'L2A_abduct', 'L2A_flex', 'L2A_rot', 'L2B_flex', 'L2B_rot', 'L2C_flex', 'L2C_rot','L2D_flex'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
% subData = 1:24; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%fix any wraparound issues for rotation data
wrapJnts = find(contains(jointLabels, 'rot'));
jointWalkingData = table2array(jointWalkingData);
for w = 1:width(wrapJnts)
    temp = jointWalkingData(:,wrapJnts(w));
    temp(temp<0) = temp(temp<0)+360;
    jointWalkingData(:,wrapJnts(w)) = temp;
end

%normalize data
%1) subtract mean 
jointWalkingData = jointWalkingData - nanmean(jointWalkingData);
%2) divide by std
jointWalkingData = jointWalkingData ./ nanstd(jointWalkingData);

%calculate covariance 
C = cov(jointWalkingData);

%plot covariance matrix
fig = fullfig;
h = heatmap(C); 
h.Title = 'Covariance during walking';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['Covariance_Matix_L2TarsiPos_x_L2allJoints_Walking_BP'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Covariance matrix for walking data (Tarsi positions - for BP)
%Problem is that angles x angles have super high covariance because they
%change a lot, even more than y positions and y positions because the angle numbers (degrees) are larger values than the position numbers.   
%TODO normalize data first!!!! (subtract mean and divide by std.)
% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1_BC'));
endJnt = find(contains(columns, 'R3E_z'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = {'L1E_x', 'L1E_y', 'L1E_z', 'L2E_x', 'L2E_y', 'L2E_z', 'L3E_x', 'L3E_y', 'L3E_z', 'R1E_x', 'R1E_y', 'R1E_z', 'R2E_x', 'R2E_y', 'R2E_z', 'R3E_x', 'R3E_y', 'R3E_z'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
% subData = 1:24; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%normalize data
jointWalkingData = table2array(jointWalkingData);
%1) subtract mean 
jointWalkingData = jointWalkingData - nanmean(jointWalkingData);
%2) divide by std
jointWalkingData = jointWalkingData ./ nanstd(jointWalkingData);

%calculate covariance 
C = cov(jointWalkingData);
p = symrcm(C);
R = C(p,p);

%plot covariance matrix
fig = fullfig;
h = heatmap(R); 
h.Title = 'Covariance during walking';
h.XDisplayLabels = jointLabels(p);
h.YDisplayLabels = jointLabels(p);
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels(p)), width(jointLabels(p))]);
%save 
fig_name = ['Covariance_Matix_AllTarsiPositions_Walking'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% Covariance matrix for walking data (ANLGES)

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1_BC'));
endJnt = find(contains(columns, 'R3E_z'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = {'L1E_y', 'L2E_y', 'L3E_y', 'R1E_y','R2E_y', 'R3E_y', 'L1_FTi', 'L2B_rot','L3_FTi', 'R1_FTi', 'R2B_rot','R3_FTi'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
% subData = 1:24; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%invert T3 and T2 signals so peaks correspond to stance start like for T1
invertJnts = find(contains(jointLabels, '3') | contains(jointLabels, '2'));

jointWalkingData = table2array(jointWalkingData);
jointWalkingData(:,invertJnts) = jointWalkingData(:,invertJnts)*-1;

%calculate covariance 
C = cov(jointWalkingData);

%plot covariance matrix
fig = fullfig;
h = heatmap(C); 
h.Title = 'Covariance of joint angles during walking';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Walking'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% Covariance matrix for walking data (ROTATION)

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
allData = 58:219; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = find(contains(jointWalkingData.Properties.VariableNames, 'rot')); %only BC,CF, FTi, TiTa joint ROTATION of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%fix wraparound 
jointWalkingData{:,:} = jointWalkingData{:,:} + 360;
%normalize by mean?
% jointWalkingData = normalize(join  tWalkingData); %default is normed by std of z-score. I think this norm makes it the same as correlation coefs. 

%calculate covariance 
C = cov(jointWalkingData{:,:});

%plot covariance matrix
fig = fullfig;
h = heatmap(C);
h.Title = 'Covariance of joint poistions during walking';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = parula;
h.ColorScaling = 'scaled';
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);

%save 
fig_name = ['\Covariance_Matix_JointRotation_Walking'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
clearvars('-except',initial_vars{:}); initial_vars = who;
%% Covariance matrix for walking data (POSITIONS)

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1_BC'));
endJnt = find(contains(columns, 'R3E_z'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = alldata(contains(jointWalkingData, '_x') | contains(jointWalkingData, '_y') |contains(jointWalkingData, '_z')); %only BC,CF, FTi, TiTa joint ROTATION of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%calculate covariance 
C = cov(jointWalkingData{:,:});

%plot covariance matrix
fig = fullfig;
h = heatmap(C);
h.Title = 'Covariance of joint positions during walking';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = parula;
h.ColorScaling = 'scaled';
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);

%save 
fig_name = ['\Covariance_Matix_JointPositions_Walking'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
clearvars('-except',initial_vars{:}); initial_vars = who;
%% Covariance matrix for walking data (ANGLES) - by Temperature

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);
walkingDataLow = walkingData(strcmpi(walkingData.Temp, '76-79'),:);
walkingDataMed = walkingData(strcmpi(walkingData.Temp, '80-84'),:);
walkingDataHigh = walkingData(strcmpi(walkingData.Temp, '85-89'),:);

%select a subset of joint data
allData = 58:81; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingDataLow = walkingDataLow(:,allData);
jointWalkingDataMed = walkingDataMed(:,allData);
jointWalkingDataHigh = walkingDataHigh(:,allData);
jointLabels = strrep(jointWalkingDataLow.Properties.VariableNames, '_', '-');

%invert T3 and T2 signals so peaks correspond to stance start like for T1
invertJnts = find(contains(jointLabels, '3') | contains(jointLabels, '2'));

jointWalkingDataLow = table2array(jointWalkingDataLow);
jointWalkingDataMed = table2array(jointWalkingDataMed);
jointWalkingDataHigh = table2array(jointWalkingDataHigh);
jointWalkingDataLow(:,invertJnts) = jointWalkingDataLow(:,invertJnts)*-1;
jointWalkingDataMed(:,invertJnts) = jointWalkingDataMed(:,invertJnts)*-1;
jointWalkingDataHigh(:,invertJnts) = jointWalkingDataHigh(:,invertJnts)*-1;

%calculate covariance 
Clow = cov(jointWalkingDataLow);
Cmed = cov(jointWalkingDataMed);
Chigh = cov(jointWalkingDataHigh);

%plot covariance matrix
fig = fullfig;
subplot(131)
h = heatmap(Clow); 
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Title = '75-79F';
h.Colormap = parula;
h.FontColor = param.baseColor;

subplot(132)
h = heatmap(Cmed); 
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Title = '80-84F';
h.Colormap = parula;
h.FontColor = param.baseColor;

subplot(133)
h = heatmap(Chigh); 
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Title = '85-89F';
h.Colormap = parula;
h.FontColor = param.baseColor;

fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, 'Covariance of joint angles while walking in different temperatures');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))


%save 
fig_name = ['\Covariance_Matix_JointAngles_Walking_byTemp'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
clearvars('-except',initial_vars{:});initial_vars = who;
%% Covariance matrix for walking data (Y POSITIONS) - by Temperature

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);
jntData = find(contains(walkingData.Properties.VariableNames, '_y')); %only BC,CF, FTi, TiTa joint ANGLES of each leg 

jointWalkingDataLow = walkingData(strcmpi(walkingData.Temp, '76-79'),jntData);
jointWalkingDataMed = walkingData(strcmpi(walkingData.Temp, '80-84'),jntData);
jointWalkingDataHigh = walkingData(strcmpi(walkingData.Temp, '85-89'),jntData);

jointLabels = strrep(jointWalkingDataLow.Properties.VariableNames, '_', '-');

jointWalkingDataLow = table2array(jointWalkingDataLow);
jointWalkingDataMed = table2array(jointWalkingDataMed);
jointWalkingDataHigh = table2array(jointWalkingDataHigh);

%calculate covariance 
Clow = cov(jointWalkingDataLow);
Cmed = cov(jointWalkingDataMed);
Chigh = cov(jointWalkingDataHigh);

%plot covariance matrix
fig = fullfig;
subplot(131)
h = heatmap(Clow); 
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Title = '75-79F';
h.Colormap = parula;
h.FontColor = param.baseColor;

subplot(132)
h = heatmap(Cmed); 
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Title = '80-84F';
h.Colormap = parula;
h.FontColor = param.baseColor;

subplot(133)
h = heatmap(Chigh); 
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Title = '85-89F';
h.Colormap = parula;
h.FontColor = param.baseColor;

fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, 'Covariance of joint Y positions while walking in different temperatures');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))


%save 
fig_name = ['\Covariance_Matix_JointYPositions_Walking_byTemp'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
clearvars('-except',initial_vars{:});initial_vars = who;

%% %%%%%%%%%%%% CORRELATION COEFFICIENTS %%%%%%%%%%%%%%%

%% Correlation coefficients for walking data (ANGLES)

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);

%select a subset of joint data
subData = {'L1_BC', 'L1_CF', 'L1_FTi', 'L1_TiTa','L2_BC', 'L2_CF', 'L2_FTi', 'L2_TiTa','L3_BC', 'L3_CF', 'L3_FTi', 'L3_TiTa','R1_BC', 'R1_CF', 'R1_FTi', 'R1_TiTa','R2_BC', 'R2_CF', 'R2_FTi', 'R2_TiTa','R3_BC', 'R3_CF', 'R3_FTi', 'R3_TiTa'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
% subData = 1:24; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = walkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%invert T3 and T2 signals so peaks correspond to stance start like for T1
invertJnts = find(contains(jointLabels, '3') | contains(jointLabels, '2'));

jointWalkingData = table2array(jointWalkingData);
jointWalkingData(:,invertJnts) = jointWalkingData(:,invertJnts)*-1;
% jointWalkingData = array2table(jointWalkingData);

%calculate covariance 
% [R,P] = corrcoef(jointWalkingData);
%plot covariance matrix
% fig = fullfig;
% h = plotmatrix(R); 
% [Rho P] = fcnCorrMatrixPlot(jointWalkingData, jointLabels, 'Corr Coeffs');
[mainfig, figlgd] = mycorrplot_1(jointWalkingData,jointLabels,'B', 1,1);

%save 
fig_name = ['\Correlation_Coefficients_JointAngles_Walking'];
save_figure(mainfig, [param.googledrivesave fig_name], param.fileType);
fig_name = ['\Correlation_Coefficients_JointAngles_Walking_Legend'];
save_figure(figlgd, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Correlation coefficients for walking data (FTi ANGLES)

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
allData = 58:219; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = find(contains(jointWalkingData.Properties.VariableNames, 'FTi')); %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%invert T3 and T2 signals so peaks correspond to stance start like for T1
invertJnts = find(contains(jointLabels, '3') | contains(jointLabels, '2'));

jointWalkingData = table2array(jointWalkingData);
jointWalkingData(:,invertJnts) = jointWalkingData(:,invertJnts)*-1;

%calculate and plot correlation coefficients 
[mainfig, figlgd] = mycorrplot_1(jointWalkingData,jointLabels,'B', 1,1);

%save 
fig_name = ['\Correlation_Coefficients_JointFTiAngles_Walking'];
save_figure(mainfig, [param.googledrivesave fig_name], param.fileType);
fig_name = ['\Correlation_Coefficients_JointFTiAngles_Walking_Legend'];
save_figure(figlgd, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Correlation coefficients for walking data (FTi ANGLES) - by temp

% temp = 'low'; tempRange = '76-79'; 
% temp = 'med'; tempRange = '80-84'; 
temp = 'high'; tempRange = '85-89'; 

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);
walkingData = walkingData(strcmpi(walkingData.Temp, tempRange),:);

%select joint data from walkingData
allData = 58:219; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = find(contains(jointWalkingData.Properties.VariableNames, 'FTi')); %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%invert T3 and T2 signals so peaks correspond to stance start like for T1
invertJnts = find(contains(jointLabels, '3') | contains(jointLabels, '2'));

jointWalkingData = table2array(jointWalkingData);
jointWalkingData(:,invertJnts) = jointWalkingData(:,invertJnts)*-1;

%calculate and plot correlation coefficients 
[mainfig, figlgd] = mycorrplot_1(jointWalkingData,jointLabels,'B', 1,1);

%save 
fig_name = ['\Correlation_Coefficients_JointFTiAngles_Walking_' temp 'Temp'];
save_figure(mainfig, [param.googledrivesave fig_name], param.fileType);
fig_name = ['\Correlation_Coefficients_JointFTiAngles_Walking_' temp 'Temp_Legend'];
save_figure(figlgd, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% %%%%%%%%%%%% SPEED X TEMP %%%%%%%%%%%%%%%

%% Speed X Temp when walking with best fit line. 

%speed is in radians/frame. Ball radius is 4.495 mm. Fictrac is 30 fps.
%so speed in mm/s = (data.speed * 4.495 * 30)
speed = data.speed * param.sarah_ball_r * param.fictrac_fps;
format long
x = data.temp(~isnan(data.walking_bout_number));
y = speed(~isnan(data.walking_bout_number));
% cd = data.flyid(~isnan(data.walking_bout_number));
% cu = unique(cd);
% [~,c] = ismember(cd, cu);
p = polyfit(x,y,1);
f = polyval(p,x); 
fig = fullfig;
colormap('jet')
scatter(x,y,[1],'filled'); hold on
plot(x,f,'-', 'LineWidth',5); hold off

fig = formatFig(fig, true);
%save 
fig_name = ['\Walking_Speed_X_Temp_With_Best_Fit_Line'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Speed X Temp when walking with best fit line. - Color by fly  

%speed is in radians/frame. Ball radius is 4.495 mm. Fictrac is 30 fps.
%so speed in mm/s = (data.speed * 4.495 * 30)
speed = data.speed * param.sarah_ball_r * param.fictrac_fps;
format long
x = data.temp(~isnan(data.walking_bout_number));
y = speed(~isnan(data.walking_bout_number));

%color by fly 
cd = data.flyid(~isnan(data.walking_bout_number));
cu = unique(cd);
cd = split(cd, {' ' '_'});
cu = split(cu, {' ' '_'});
cd = cd(:, [1,3]);
cu = cu(:, [1,3]);
cu = unique(cu, 'rows');
[~,c] = ismember(cd, cu, 'rows');

%best fit line
p = polyfit(x,y,1);
f = polyval(p,x); 
fig = fullfig;
colormap('jet');
scatter(x,y,[1],c,'filled'); hold on
plot(x,f,'-', 'LineWidth',5); hold off

%label
ylabel('Speed (mm/s)');
xlabel('Time (s)');

fig = formatFig(fig, true);
%save 
fig_name = ['\Walking_Speed_X_Temp_With_Best_Fit_Line'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Speed X Temp when walking with best fit line. - Each fly in its own plot, color by temp

%speed is in radians/frame. Ball radius is 4.495 mm. Fictrac is 30 fps.
%so speed in mm/s = (data.speed * 4.495 * 30)
speed = data.speed * param.sarah_ball_r * param.fictrac_fps;

%get number of flies (not trials)
cd = data.flyid(~isnan(data.walking_bout_number));
cu = unique(cd);
cu = split(cu, {' ' '_'});
cu = cu(:, [1,3]);
cu = unique(cu, 'rows');

plotting = numSubplots(height(cu));
fig = fullfig;
for fly = 1:height(cu)
    subplot(plotting(1), plotting(2), fly)
    
    %data
    x_0 = data.temp(~isnan(data.walking_bout_number) & strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),"_0")));
    y_0 = speed(~isnan(data.walking_bout_number) & strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),"_0")));
    x_1 = data.temp(~isnan(data.walking_bout_number) & strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),"_1")));
    y_1 = speed(~isnan(data.walking_bout_number) & strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),"_1")));
    x_2 = data.temp(~isnan(data.walking_bout_number) & strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),"_2")));
    y_2 = speed(~isnan(data.walking_bout_number) & strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),"_2")));
    
    %best fit line
    x = [x_0;x_1;x_2];
    y = [y_0;y_1;y_2];
    p = polyfit(x,y,1);
    f = polyval(p,x); 

    %plot
    scatter(x_0, y_0, [3], 'filled'); hold on 
    scatter(x_1, y_1, [3], 'filled'); 
    scatter(x_2, y_2, [3], 'filled'); 
    plot(x,f,'-', 'LineWidth',3); 
    
    %label
    title(['Fly ' num2str(cu(fly,2)) ' from ' num2str(cu(fly, 1))], 'Color', param.baseColor);
    if fly == 1
        ylabel('Speed (mm/s)');
        xlabel('Temp (C)');
    end
    hold off
end
%turn background black 
fig = formatFig(fig, true, plotting);

%save 
fig_name = ['\Walking_Speed_X_Temp_With_Best_Fit_Line_Per_Fly'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% %%%%%%%%%%%% PERCENT WALKING X TEMP %%%%%%%%%%%%%%%

%% Percent Walking X Temp when walking with best fit line. - Each fly in its own plot, color by temp

%speed is in radians/frame. Ball radius is 4.495 mm. Fictrac is 30 fps.
%so speed in mm/s = (data.speed * 4.495 * 30)
speed = data.speed * 4.495 * 30;

%get number of flies (not trials)
cd = data.flyid(~isnan(data.walking_bout_number));
cu = unique(cd);
cu = split(cu, {' ' '_'});
cu = cu(:, [1,3]);
cu = unique(cu, 'rows');

plotting = numSubplots(height(cu));
fig = fullfig;
for fly = 1:height(cu)
    subplot(plotting(1), plotting(2), fly)
    
    %data
    x_0 = mean(data.temp(~isnan(data.walking_bout_number) & strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),"_0"))));
    total_0 = height(data.flyid(strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),"_0"))));
    walk_0 = height(data.flyid(~isnan(data.walking_bout_number) & strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),"_0"))));
    y_0 = walk_0/total_0;
    x_1 = mean(data.temp(~isnan(data.walking_bout_number) & strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),"_1"))));
    total_1 = height(data.flyid(strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),"_1"))));
    walk_1 = height(data.flyid(~isnan(data.walking_bout_number) & strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),"_1"))));
    y_1 = walk_1/total_1;
    x_2 = mean(data.temp(~isnan(data.walking_bout_number) & strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),"_2"))));
    total_2 = height(data.flyid(strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),"_2"))));
    walk_2 = height(data.flyid(~isnan(data.walking_bout_number) & strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),"_2"))));
    y_2 = walk_2/total_2;
    
    %best fit line
    x = [x_0;x_1;x_2];
    y = [y_0;y_1;y_2];
    p = polyfit(x,y,1);
    f = polyval(p,x); 

    %plot
    scatter(x_0, y_0, 'filled'); hold on 
    scatter(x_1, y_1, 'filled'); 
    scatter(x_2, y_2, 'filled'); 
    plot(x,f,'-', 'LineWidth',3); 
    
    %label
    title(['Fly ' num2str(cu(fly,2)) ' from ' num2str(cu(fly, 1))], 'Color', param.baseColor);
    if fly == 1
        ylabel('Percent Walking');
        xlabel('Avg Temp (C)');
    end
    hold off
end
%turn background black 
fig = formatFig(fig, true, plotting);

%save 
fig_name = ['\Percent_Walking_X_Temp_With_Best_Fit_Line_Per_Fly'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Percent Walking X Temp when walking with best fit line. - Each fly in its own plot, seperate vids, color by temp

numTrials = 3; % 3 different temps
numVids = 3; %3 vids per trial 

%speed is in radians/frame. Ball radius is 4.495 mm. Fictrac is 30 fps.
%so speed in mm/s = (data.speed * 4.495 * 30)
speed = data.speed * 4.495 * 30;

%get number of flies (not trials)
cd = data.flyid(~isnan(data.walking_bout_number));
cu = unique(cd);
cu = split(cu, {' ' '_'});
cu = cu(:, [1,3]);
cu = unique(cu, 'rows');

%Trial colors
kolors = {'blue', 'orange', 'yellow'};

plotting = numSubplots(height(cu));
fig = fullfig;
for fly = 1:height(cu)
    subplot(plotting(1), plotting(2), fly)
    
    %data
    %Trial 1
    xs = []; ys = []; 
    for trial = 1:numTrials
        trialStr = ['_' num2str(trial-1)];
        for vid = 1:numVids
            total = []; walk = [];
            xs(trial, vid) = mean(data.temp(~isnan(data.walking_bout_number) & strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),trialStr)) & data.rep == vid));
            total = height(data.flyid(strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),trialStr)) & data.rep == vid));
            walk = height(data.flyid(~isnan(data.walking_bout_number) & strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),trialStr)) & data.rep == vid));
            ys(trial,vid) = walk/total;
        end
    end
     
    %best fit line
    x = xs(:);
    y = ys(:);
    p = polyfit(x,y,1);
    f = polyval(p,x); 

    %plot
    for trial = 1:numTrials
        for vid = 1:numVids
            scatter(xs(trial,vid), ys(trial,vid), vid*10, Color(kolors{trial}), 'filled'); hold on 
        end 
    end
    plot(x,f,'-', 'LineWidth',3, 'Color', Color('purple')); 
    
    %label
    title(['Fly ' num2str(cu(fly,2)) ' from ' num2str(cu(fly, 1))], 'Color', param.baseColor);
    if fly == 1
        ylabel('Percent Walking');
        xlabel('Avg Temp (C)');
    end
    hold off
end
%turn background black 
fig = formatFig(fig, true, plotting);

%save 
fig_name = ['\Percent_Walking_X_Temp_With_Best_Fit_Line_Per_Fly_Seperate_Vids'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Percent Walking X Temp when walking with best fit line.

numTrials = 3; % 3 different temps
numVids = 3; %3 vids per trial 

%speed is in radians/frame. Ball radius is 4.495 mm. Fictrac is 30 fps.
%so speed in mm/s = (data.speed * 4.495 * 30)
speed = data.speed * 4.495 * 30;

%get number of flies (not trials)
cd = data.flyid(~isnan(data.walking_bout_number));
cu = unique(cd);
cu = split(cu, {' ' '_'});
cu = cu(:, [1,3]);
cu = unique(cu, 'rows');

%Trial colors
kolors = {'blue', 'orange', 'yellow'};
%Trial conditions
conds = {'low', 'med', 'high'};

plotting = numSubplots(height(cu));
fig = fullfig; hold on;    
xs = []; ys = []; 
for fly = 1:height(cu)
    %data
    %Trial 1
    for trial = 1:numTrials
        trialStr = ['_' num2str(trial-1)];
        for vid = 1:numVids
            total = []; walk = [];
            xs(fly, trial, vid) = mean(data.temp(~isnan(data.walking_bout_number) & strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),trialStr)) & data.rep == vid));
            total = height(data.flyid(strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),trialStr)) & data.rep == vid));
            walk = height(data.flyid(~isnan(data.walking_bout_number) & strcmpi(data.date_parsed, cu(fly,1)) & strcmpi(data.fly, strcat(cu(fly,2),trialStr)) & data.rep == vid));
            ys(fly, trial,vid) = walk/total;
        end
    end
     


    %plot data for this fly 
    for trial = 1:numTrials
        for vid = 1:numVids
    %         scatter(xs(fly,trial,vid), ys(fly,trial,vid), [],Color(kolors{trial}), 'filled'); hold on 
            scatter(xs(fly,trial,vid), ys(fly,trial, vid),'filled'); hold on 
            %color is currently by the order the vids were taken, not which
            %temp they are... I can change this by getting if there's
            %'low,'med',of 'high' in data.StimulusProcedure using conds
        end
    end
    
    %label
    if fly == 1
        ylabel('Percent Walking');
        xlabel('Avg Temp (C)');
    end
end

%best fit line
x = xs(:);
y = ys(:);
p = polyfit(x,y,1);
f = polyval(p,x); 
%plot best fit line 
plot(x,f,'-', 'LineWidth',3, 'Color', Color('purple')); 

%turn background black 
fig = formatFig(fig, true); 
hold off;

%save 
fig_name = ['\Percent_Walking_X_Temp_With_Best_Fit_Line_Per_Fly_Seperate_Vids'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% TODO, other comparisonsn  
scatter(data.temp(~isnan(data.walking_bout_number)), data.speed(~isnan(data.walking_bout_number)))
scatter(data.temp, data.inst_dir)
scatter(data.temp, data.heading)
scatter(data.speed, data.heading)
scatter(data.inst_dir, data.heading)


%% %%%%%%%%%%%% GAIT X TEMP %%%%%%%%%%%%%%%
% Does a fly walking at same speed but two different temps have same leg kinematics?
%% Covariance of all angles all legs with each other at three temps same speed. 
%todo... use Box's M test to check whether the covariance changes: https://www.statisticshowto.com/boxs-m-test/
%todo... invert L2 and T3 and use T2 rotation instead to more easily see tripod gait?


%params
speed_range = [5,7]; %min and max mm/s
hide_variance = 1; %1 == don't show variance (covar with variable and itself); 0 == do show it. 
fly = 1; %fly to look at (intrafly analysis)
% subData = {'L1_BC', 'L1_CF', 'L1_FTi', 'L1_TiTa','L2_BC', 'L2_CF', 'L2_FTi', 'L2_TiTa','L3_BC', 'L3_CF', 'L3_FTi', 'L3_TiTa','R1_BC', 'R1_CF', 'R1_FTi', 'R1_TiTa','R2_BC', 'R2_CF', 'R2_FTi', 'R2_TiTa','R3_BC', 'R3_CF', 'R3_FTi', 'R3_TiTa'}; %angles to calculate covariance of  
subData = {'L1_FTi', 'L2B_rot', 'L3_FTi', 'R1_FTi', 'R2B_rot', 'R3_FTi'}; %angles to calculate covariance of  

%get list of flies (not trials)
cd = data.flyid(~isnan(data.walking_bout_number));
cu = unique(cd);
cu = split(cu, {' ' '_'});
cu = cu(:, [1,3]);
cu = unique(cu, 'rows');

%get this fly data
flyData = data(strcmpi(cu(fly,1),data.date_parsed) & contains(data.fly, [num2str(fly) '_']), :);

%get data in speed range
flyData.speed = flyData.speed * 4.495 * 30; %speed from rad/frame to mm/s
flyData = flyData(flyData.speed > speed_range(1) & flyData.speed < speed_range(2),:);

%get temps
% hist(flyData.temp, 100);
%TODO will need to adjust this by hand, or find a clever dynamic method 
temp_range = [25,30]; %divide data into three groups, below, between, and above temp_range values

%get joint data
flyTemp = flyData.temp;
flyData = flyData(:,subData);
jointLabels = strrep(flyData.Properties.VariableNames, '_', '-');

%invert T3 and T2 signals so peaks correspond to stance start like for T1
invertJnts = find(contains(jointLabels, '3') | contains(jointLabels, 'L2'));
flyData = table2array(flyData);
flyData(:,invertJnts) = flyData(:,invertJnts)*-1;
flyData = array2table(flyData);

%get covariance per group
Clow = cov(table2array(flyData(flyTemp < temp_range(1), :)));
Cmed = cov(table2array(flyData(flyTemp >= temp_range(1) & flyTemp <= temp_range(2), :)));
Chigh = cov(table2array(flyData(flyTemp > temp_range(2), :)));

%print num datapoints
numDataLow = height(table2array(flyData(flyTemp < temp_range(1), :)));
numDataMed = height(table2array(flyData(flyTemp >= temp_range(1) & flyTemp <= temp_range(2), :)));
numDataHigh = height(table2array(flyData(flyTemp > temp_range(2), :)));
fprintf(['\nClow: ' num2str(numDataLow) ' datapoints']);
fprintf(['\nCmed: ' num2str(numDataMed) ' datapoints']);
fprintf(['\nChigh: ' num2str(numDataHigh) ' datapoints\n']);

if hide_variance
   Clow = Clow - diag(diag(Clow));
   Cmed = Cmed - diag(diag(Cmed));
   Chigh = Chigh - diag(diag(Chigh));
end

%plot covariance matrix - LOW TEMP
fig = fullfig;
h = heatmap(Clow); 
h.Title = ['Covariance of joint angles: speed ' num2str(speed_range(1)) '-' num2str(speed_range(2)) 'mm/s & temp < ' num2str(temp_range(1)) 'C - (' num2str(numDataLow) ' datapoints) - Fly ' num2str(cu(fly,2)) ' from ' cu{fly,1}];
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Speed_' num2str(speed_range(1)) 'to' num2str(speed_range(2)) '_lowTemp-under' num2str(temp_range(1)) ' - Fly ' num2str(cu(fly,2)) ' from ' cu{fly,1}];
if hide_variance; fig_name = [fig_name '_hideVariance']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%plot covariance matrix - MED TEMP
fig = fullfig;
h = heatmap(Cmed); 
h.Title = ['Covariance of joint angles: speed ' num2str(speed_range(1)) '-' num2str(speed_range(2)) 'mm/s & temp ' num2str(temp_range(1)) '-' num2str(temp_range(2)) 'C - (' num2str(numDataMed) ' datapoints) - Fly ' num2str(cu(fly,2)) ' from ' cu{fly,1}];
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Speed_' num2str(speed_range(1)) 'to' num2str(speed_range(2)) '_medTemp-' num2str(temp_range(1)) 'to' num2str(temp_range(2)) ' - Fly ' num2str(cu(fly,2)) ' from ' cu{fly,1}];
if hide_variance; fig_name = [fig_name '_hideVariance']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%plot covariance matrix - HIGH TEMP
fig = fullfig;
h = heatmap(Chigh); 
h.Title = ['Covariance of joint angles: speed ' num2str(speed_range(1)) '-' num2str(speed_range(2)) 'mm/s & temp > ' num2str(temp_range(2)) 'C - (' num2str(numDataHigh) ' datapoints) - Fly ' num2str(cu(fly,2)) ' from ' cu{fly,1}];
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Speed_' num2str(speed_range(1)) 'to' num2str(speed_range(2)) '_highTemp-over' num2str(temp_range(2)) ' - Fly ' num2str(cu(fly,2)) ' from ' cu{fly,1}];
if hide_variance; fig_name = [fig_name '_hideVariance']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Correlation Coeffecients of all angles all legs with each other at three temps same speed. 
%todo... use Box's M test to check whether the covariance changes: https://www.statisticshowto.com/boxs-m-test/
%todo... invert L2 and T3 and use T2 rotation instead to more easily see tripod gait?


%params
speed_range = [5,7]; %min and max mm/s
hide_variance = 1; %1 == don't show variance (covar with variable and itself); 0 == do show it. 
fly = 1; %fly to look at (intrafly analysis)
% subData = {'L1_BC', 'L1_CF', 'L1_FTi', 'L1_TiTa','L2_BC', 'L2_CF', 'L2_FTi', 'L2_TiTa','L3_BC', 'L3_CF', 'L3_FTi', 'L3_TiTa','R1_BC', 'R1_CF', 'R1_FTi', 'R1_TiTa','R2_BC', 'R2_CF', 'R2_FTi', 'R2_TiTa','R3_BC', 'R3_CF', 'R3_FTi', 'R3_TiTa'}; %angles to calculate covariance of  
subData = {'L1_FTi', 'L2B_rot', 'L3_FTi', 'R1_FTi', 'R2B_rot', 'R3_FTi'}; %angles to calculate covariance of  

%get list of flies (not trials)
cd = data.flyid(~isnan(data.walking_bout_number));
cu = unique(cd);
cu = split(cu, {' ' '_'});
cu = cu(:, [1,3]);
cu = unique(cu, 'rows');

%get this fly data
flyData = data(strcmpi(cu(fly,1),data.date_parsed) & contains(data.fly, [num2str(fly) '_']), :);

%get data in speed range
flyData.speed = flyData.speed * 4.495 * 30; %speed from rad/frame to mm/s
flyData = flyData(flyData.speed > speed_range(1) & flyData.speed < speed_range(2),:);

%get temps
% hist(flyData.temp, 100);
%TODO will need to adjust this by hand, or find a clever dynamic method 
temp_range = [25,30]; %divide data into three groups, below, between, and above temp_range values

%get joint data
flyTemp = flyData.temp;
flyData = flyData(:,subData);
jointLabels = strrep(flyData.Properties.VariableNames, '_', '-');

%invert T3 and T2 signals so peaks correspond to stance start like for T1
invertJnts = find(contains(jointLabels, '3') | contains(jointLabels, 'L2'));
flyData = table2array(flyData);
flyData(:,invertJnts) = flyData(:,invertJnts)*-1;
flyData = array2table(flyData);

%get correlation coeffs per group
[Rlow,Plow] = corrcoef(table2array(flyData(flyTemp < temp_range(1), :)));
[Rmed,Pmed] = corrcoef(table2array(flyData(flyTemp >= temp_range(1) & flyTemp <= temp_range(2), :)));
[Rhigh,Phigh] = corrcoef(table2array(flyData(flyTemp > temp_range(2), :)));

%print num datapoints
numDataLow = height(table2array(flyData(flyTemp < temp_range(1), :)));
numDataMed = height(table2array(flyData(flyTemp >= temp_range(1) & flyTemp <= temp_range(2), :)));
numDataHigh = height(table2array(flyData(flyTemp > temp_range(2), :)));
fprintf(['\nClow: ' num2str(numDataLow) ' datapoints']);
fprintf(['\nCmed: ' num2str(numDataMed) ' datapoints']);
fprintf(['\nChigh: ' num2str(numDataHigh) ' datapoints\n']);

%plot covariance matrix - LOW TEMP
fig = fullfig;
h = heatmap(Rlow); 
h.Title = ['Correlation coeffs of joint angles: speed ' num2str(speed_range(1)) '-' num2str(speed_range(2)) 'mm/s & temp < ' num2str(temp_range(1)) 'C - (' num2str(numDataLow) ' datapoints) - Fly ' num2str(cu(fly,2)) ' from ' cu{fly,1}];
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\CorrelationCoeffs_Matix_JointAngles_Speed_' num2str(speed_range(1)) 'to' num2str(speed_range(2)) '_lowTemp-under' num2str(temp_range(1)) ' - Fly ' num2str(cu(fly,2)) ' from ' cu{fly,1}];
if hide_variance; fig_name = [fig_name '_hideVariance']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%plot covariance matrix - MED TEMP
fig = fullfig;
h = heatmap(Rmed); 
h.Title = ['Correlation coeffs of joint angles: speed ' num2str(speed_range(1)) '-' num2str(speed_range(2)) 'mm/s & temp ' num2str(temp_range(1)) '-' num2str(temp_range(2)) 'C - (' num2str(numDataMed) ' datapoints) - Fly ' num2str(cu(fly,2)) ' from ' cu{fly,1}];
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\CorrelationCoeffs_Matix_JointAngles_Speed_' num2str(speed_range(1)) 'to' num2str(speed_range(2)) '_medTemp-' num2str(temp_range(1)) 'to' num2str(temp_range(2)) ' - Fly ' num2str(cu(fly,2)) ' from ' cu{fly,1}];
if hide_variance; fig_name = [fig_name '_hideVariance']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%plot covariance matrix - HIGH TEMP
fig = fullfig;
h = heatmap(Rhigh); 
h.Title = ['Correlation coeffs of joint angles: speed ' num2str(speed_range(1)) '-' num2str(speed_range(2)) 'mm/s & temp > ' num2str(temp_range(2)) 'C - (' num2str(numDataHigh) ' datapoints) - Fly ' num2str(cu(fly,2)) ' from ' cu{fly,1}];
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\CorrelationCoeffs_Matix_JointAngles_Speed_' num2str(speed_range(1)) 'to' num2str(speed_range(2)) '_highTemp-over' num2str(temp_range(2)) ' - Fly ' num2str(cu(fly,2)) ' from ' cu{fly,1}];
if hide_variance; fig_name = [fig_name '_hideVariance']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

% clearvars('-except',initial_vars{:}); initial_vars = who;


%% %%%%%%%%%%%% SPEED HISTOGRAMS %%%%%%%%%%%%%%%

%% Plot speed histo for all data 

%speed is in radians/frame. Ball radius is 4.495 mm. Fictrac is 30 fps.
%so speed in mm/s = (data.speed * 4.495 * 30)
speed = data.speed * param.sarah_ball_r * param.fictrac_fps;
fig = fullfig;
hist(speed, 100);


%turn background black 
fig = formatFig(fig, true);

%label
title('Speed of all data', 'Color', param.baseColor);
xlabel('Speed (mm/s)'); 
ylabel('Count');

%save 
fig_name = ['\Speed_Histo_all_data'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Plot speed histo for walking data 
%speed is in radians/frame. Ball radius is 4.495 mm. Fictrac is 30 fps.
%so speed in mm/s = (data.speed * 4.495 * 30)
speed = data.speed * param.sarah_ball_r * param.fictrac_fps;

%plot
fig = fullfig;
hist(speed(~isnan(data.walking_bout_number)), 100);

%turn background black 
fig = formatFig(fig, true);

%label
title('Speed of walking data', 'Color', param.baseColor);
xlabel('Speed (mm/s)'); 
ylabel('Count');

%save 
fig_name = ['\Speed_Histo_walking_data'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Plot speed histo for standing data 
%speed is in radians/frame. Ball radius is 4.495 mm. Fictrac is 30 fps.
%so speed in mm/s = (data.speed * 4.495 * 30)
speed = data.speed * param.sarah_ball_r * param.fictrac_fps;

%plot
fig = fullfig;
hist(speed(~isnan(data.standing_bout_number)), 100);

%turn background black 
fig = formatFig(fig, true);
 
%label
title('Speed of standing data', 'Color', param.baseColor);
xlabel('Speed (mm/s)'); 
ylabel('Count');

%save 
fig_name = ['\Speed_Histo_standing_data'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% %%%%%%%%%%%% STEP METRICS X SPEED AT DIFF TEMPS %%%%%%%%%%%%%%%

 %% CALCULATE: step freq, speed, temp, heading dir, step length, stance dur, swing dur
clear step; clearvars('-except',initial_vars{:}); initial_vars = who;

%get walking data
walkingData = data(~isnan(data.walking_bout_number),:); 

%calculate step frequency on all data (then select forward walking after)
%(findpeaks)
% freqDeterms = {'L1_FTi', 'L2B_rot', 'L3_FTi', 'R1_FTi', 'R2B_rot', 'R3_FTi'}; %a joint variable for each leg that will be used to calculate step frequency
% freqPThresh = [20,10,20,20,10,20];
positionPThresh = [0.2, 0.2, 0.2, 0.2, 0.2, 0.2];
format long
% instdirData = rad2deg(walkingData.inst_dir);

boutData = walkingData.walking_bout_number;
tempData = walkingData.temp; 
speed_x = walkingData.fictrac_delta_rot_lab_x; 
speed_y = walkingData.fictrac_delta_rot_lab_y; 
speed_z = walkingData.fictrac_delta_rot_lab_z; 
fly_num = walkingData.flyid; 
for leg = 1:6
%     jntData = smooth(abs(walkingData.(freqDeterms{leg}))); %abs corrects wrap around of rotation data
    tarsiPosition = [walkingData.([param.legs{leg} 'E_x']), walkingData.([param.legs{leg} 'E_y']), walkingData.([param.legs{leg} 'E_z'])];
    if contains(param.legs(leg), '3') | contains(param.legs(leg), 'L2')
            %for T3 troughs are stance start - so invert signal to make peaks stance starts
            %for L2, stance is positive values, so trough to peak, so
            %invert so peaks are stance starts. 
%             jntData = jntData *-1;
            tarsiPosition = tarsiPosition *-1;
    end

    step(leg).freq = []; %step frequency 
    step(leg).length = []; %step length
    step(leg).swing_dur = []; %swing duration 
    step(leg).stance_dur = []; %stance duration 
    step(leg).speed_x = []; %delta_rot_lab_x (crabwalking)
    step(leg).speed_y = []; %delta_rot_lab_y (forward/backward)
    step(leg).speed_z = []; %delta_rot_lab_z (turning)
    step(leg).temp = []; %temp (avg per step)
    step(leg).fly = []; %the index of the fly in flyList (aka fly num)
    for bout = 1:max(boutData)
        
%         this_data = jntData(boutData == bout); 
        this_tarsiPos = tarsiPosition(boutData == bout,:);
        this_speed_x = speed_x(boutData == bout);
        this_speed_y = speed_y(boutData == bout);
        this_speed_z = speed_z(boutData == bout);
        this_temp = tempData(boutData == bout);
        this_fly = fly_num(boutData == bout);
        if ~isempty(this_tarsiPos)
%             [pks, plocs] = findpeaks(this_data,'MinPeakProminence',freqPThresh(leg)); %peaks = stance starts
%             [trs, tlocs] = findpeaks(this_data*-1,'MinPeakProminence',freqPThresh(leg)); %troughs = swing starts
%             
            [tarsi_pks, tarsi_plocs] = findpeaks(this_tarsiPos(:,2),'MinPeakProminence',positionPThresh(leg)); %peaks = stance starts
            [tarsi_trs, tarsi_tlocs] = findpeaks(this_tarsiPos(:,2)*-1,'MinPeakProminence',positionPThresh(leg)); %troughs = swing starts
            
            if height(tarsi_plocs) > 10 % filter out bouts with fewer steps
                %calculate step frequency 
%                 this_freq = 1./(diff(plocs)/param.fps); %from joint data
                this_freq = 1./(diff(tarsi_plocs)/param.fps); %from tarsi y position 

                step_speed_x = [];
                step_speed_y = [];
                step_speed_z = [];
                step_temp = [];
                this_step_length = [];
                step_fly = [];
                
                for st = 1:height(tarsi_plocs)-1
                    %calc avg speeds per step
                    step_speed_x(st,1) = nanmean(this_speed_x(tarsi_plocs(st):tarsi_plocs(st+1))); %avg speed x for each step 
                    step_speed_y(st,1) = nanmean(this_speed_y(tarsi_plocs(st):tarsi_plocs(st+1))); %avg speed y for each step 
                    step_speed_z(st,1) = nanmean(this_speed_z(tarsi_plocs(st):tarsi_plocs(st+1))); %avg speed z for each step 
                    
                    %calc avg temp per step 
                    step_temp(st,1) = nanmean(this_temp(tarsi_plocs(st):tarsi_plocs(st+1))); %avg temperature for each step 
                    
                    %calculate step length (3D euclidian distance) 
                    this_step_length(st,1) = sqrt(sum((this_tarsiPos(tarsi_plocs(st),:) - this_tarsiPos(tarsi_tlocs(st),:)).^2, 2));
                    
                    %fly num 
                    step_fly(st, 1) = this_fly(tarsi_plocs(st));
                end
                
                %swing and stance dur
                if tarsi_tlocs(1) < tarsi_plocs(1)
                    % trim off first trough so data starts with peak. 
                    % must do this so step data aligns with other vars
                    % which are calculated on first peak to last peak of the data. 
                    tarsi_tlocs = tarsi_tlocs(2:end);
                end
                if tarsi_tlocs(end) > tarsi_plocs(end)
                    % trim off last trough so data ends with peak. 
                    % must do this so step data aligns with other vars
                    % which are calculated on first peak to last peak of the data. 
                    tarsi_tlocs = tarsi_tlocs(1:end-1);
                end
                all_peaksNtroughs = sort([tarsi_plocs; tarsi_tlocs]);
                all_durations = diff(all_peaksNtroughs)/param.fps; 
                %first duration is peak to trough, which is stance. 
                this_stance_dur = all_durations(1:2:end); %odds
                this_swing_dur = all_durations(2:2:end); %evens

                %save data
                step(leg).freq = [step(leg).freq; this_freq];
                step(leg).length = [step(leg).length; this_step_length];
                step(leg).stance_dur = [step(leg).stance_dur; this_stance_dur]; 
                step(leg).swing_dur = [step(leg).swing_dur; this_swing_dur]; 
                step(leg).speed_x = [step(leg).speed_x; step_speed_x];
                step(leg).speed_y = [step(leg).speed_y; step_speed_y];
                step(leg).speed_z = [step(leg).speed_z; step_speed_z];
                step(leg).temp = [step(leg).temp; step_temp];
                step(leg).fly = [step(leg).fly; step_fly];
            end
        end
    end
end

initial_vars{end+1} = 'step';
clearvars('-except',initial_vars{:}); initial_vars = who;

%% PLOT: STEP FREQUENCY x speed

%%%%% PARAMS %%%%%
speedThresh = 1; %max speed, since not all temps go to higher speeds it may distort lslines. 
%%%%%%%%%%%%%%%%%%


%plot step freq x temp for all data
fig = fullfig;
plotting = numSubplots(param.numLegs);
for leg = 1:param.numLegs
    subplot(plotting(1), plotting(2), leg);
    
    % data to plot
    goodData = step(leg).speed > speedThresh;
    x = step(leg).speed(goodData);
    y = step(leg).freq(goodData); 
    
    %plot data
    scatter(x, y , 'filled'); hold on; lsline; % sp eed x step freq
%     hist3([x,y], 'Nbins', [50,50],'CdataMode','auto'); hold on; colorbar; view(2);

    if leg == 1
        ylabel('Step frequency (Hz)');
        xlabel('Speed (mm/s)');
    end
    title(param.legs{leg});
end

fig = formatFig(fig,true,plotting);


%save 
fig_name = ['\Step_Frequency_X_Speed'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% PLOT: STEP FREQUENCY x speed x temp

%%%%% PARAMS %%%%%
headingThresh = 10; %degrees from straight ahead (180) included in 'forward' walking
%%%%%%%%%%%%%%%%%%


%plot step freq x temp for all data
fig = fullfig;
plotting = numSubplots(param.numLegs);
for leg = 1:param.numLegs
    subplot(plotting(1), plotting(2), leg);
    
    % data to plot
    goodData = step(leg).heading > 180-headingThresh & step(leg).heading < 180+headingThresh; %confine to 'forward' walking
    x = step(leg).speed(goodData);
    y = step(leg).freq(goodData); 
    c = step(leg).temp(goodData);
    
    %plot data
    scatter(x, y , [], c, 'filled'); hold on; lsline; % sp eed x step freq
    cb = colorbar; 
    cb.Color = param.baseColor;
%     hist3([x,y], 'Nbins', [50,50],'CdataMode','auto'); hold on; colorbar; view(2);

    if leg == 1
        ylabel('Step frequency (Hz)');
        xlabel('Speed (mm/s)');
    end
    title(param.legs{leg});
end

fig = formatFig(fig,true,plotting);


%save 
fig_name = ['\Step_Frequency_X_Speed_X_Temp'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% PLOT: STEP FREQUENCY x speed x temp - one lsline per temp bin 

%%%%% PARAMS %%%%%
headingThresh = 10; %degrees from straight ahead (180) included in 'forward' walking
tempEdges = 10:1:40; % edges of bins for binning temp data
%%%%%%%%%%%%%%%%%%

%plot step freq x temp for all data
fig = fullfig;
plotting = numSubplots(param.numLegs);
for leg = 1:param.numLegs
    clear h;
    subplot(plotting(1), plotting(2), leg);
    
    % data to plot
%     goodData = step(leg).heading > 180-headingThresh & step(leg).heading < 180+headingThresh; %confine to 'forward' walking
%     x = step(leg).speed(goodData);
%     y = step(leg).freq(goodData); 
%     c = step(leg).temp(goodData);
%     
    x = step(leg).speed;
    y = step(leg).freq; 
    c = step(leg).temp;
    
    
    
%     cbin = discretize(c,tempEdges);
    [~,edges,cbin] = histcounts(c,tempEdges);
    bins = unique(cbin); 
    numBins = height(bins);
    binColors = parula(numBins);
    this_edges = [edges(bins),edges(max(bins)+1)];
    
    %plot data
    for bin = 1:numBins
        scatter(x(cbin == bins(bin)), y(cbin == bins(bin)), [20], binColors(bin,:)); hold on; 
        h = lsline; % speed x step freq
    end

    %color lsline to match temp bins
    b = numBins;
    for bin = 1:numBins
        set(h(b),'color',binColors(bin,:));
        set(h(b),'linewidth',2);
        b = b-1;
    end
    
    %colorbar for temp
    colormap(binColors)
    cb = colorbar('Ticks', [0:1/numBins:1],'TickLabels',this_edges);
    cb.Color = param.baseColor;
   

    if leg == 1
        ylabel('Step frequency (Hz)');
        xlabel('Speed (mm/s)');
    end
    title(param.legs{leg});
end

fig = formatFig(fig,true,plotting);

%save 
fig_name = ['\Step_Frequency_X_Speed_X_Temp_binnedFitLines'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% PLOT: STEP LENGTH x speed

%%%%% PARAMS %%%%%
speedThresh = 1; %max speed, since not all temps go to higher speeds it may distort lslines. 
%%%%%%%%%%%%%%%%%%


%plot step freq x temp for all data
fig = fullfig;
plotting = numSubplots(param.numLegs);
for leg = 1:param.numLegs
    subplot(plotting(1), plotting(2), leg);
    
    % data to plot
    goodData = step(leg).speed > speedThresh;
    x = step(leg).speed(goodData);
    y = step(leg).length(goodData); 
    
    %plot data
    scatter(x, y , 'filled'); hold on; lsline; % sp eed x step freq
%     hist3([x,y], 'Nbins', [50,50],'CdataMode','auto'); hold on; colorbar; view(2);

    if leg == 1
        ylabel('Step length (mm?)');
        xlabel('Speed (mm/s)');
    end
    title(param.legs{leg});
end

fig = formatFig(fig,true,plotting);

%save 
fig_name = ['\Step_Length_X_Speed'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% PLOT: STEP LENGTH x speed x temp - one lsline per temp bin 

%%%%% PARAMS %%%%%
headingThresh = 10; %degrees from straight ahead (180) included in 'forward' walking
tempEdges = 10:1:40; % edges of bins for binning temp data
% speedThresh = 15; %max speed, since not all temps go to higher speeds it may distort lslines. 
%%%%%%%%%%%%%%%%%%


%plot step freq x temp for all data
fig = fullfig;
plotting = numSubplots(param.numLegs);
for leg = 1:param.numLegs
    clear h;
    subplot(plotting(1), plotting(2), leg);
    
    % data to plot
    goodData = step(leg).heading > 180-headingThresh & step(leg).heading < 180+headingThresh; %confine to 'forward' walking
%     goodData = step(leg).heading > 180-headingThresh & step(leg).heading < 180+headingThresh & step(leg).speed <= speedThresh; %confine to 'forward' walking
    x = step(leg).speed(goodData);
    y = step(leg).length(goodData); 
    c = step(leg).temp(goodData);
    
%     cbin = discretize(c,tempEdges);
    [~,edges,cbin] = histcounts(c,tempEdges);
    bins = unique(cbin); 
    numBins = height(bins);
    binColors = parula(numBins);
    this_edges = [edges(bins),edges(max(bins)+1)];
    
    %plot data
    for bin = 1:numBins
        scatter(x(cbin == bins(bin)), y(cbin == bins(bin)), [20], binColors(bin,:)); hold on; 
        h = lsline; % speed x step freq
    end

    %color lsline to match temp bins
    b = numBins;
    for bin = 1:numBins
        set(h(b),'color',binColors(bin,:));
        set(h(b),'linewidth',2);
        b = b-1;
    end
    
    %colorbar for temp
    colormap(binColors)
    cb = colorbar('Ticks', [0:1/numBins:1],'TickLabels',this_edges);
    cb.Color = param.baseColor;
   

    if leg == 1
        ylabel('Step length (mm?)');
        xlabel('Speed (mm/s)');
    end
    title(param.legs{leg});
end

fig = formatFig(fig,true,plotting);

%save 
fig_name = ['\Step_Length_X_Speed_X_Temp_binnedFitLines'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% PLOT: SWING DURATION x speed

%%%%% PARAMS %%%%%
speedThresh = 1; %max speed, since not all temps go to higher speeds it may distort lslines. 
%%%%%%%%%%%%%%%%%%


%plot step freq x temp for all data
fig = fullfig;
plotting = numSubplots(param.numLegs);
for leg = 1:param.numLegs
    subplot(plotting(1), plotting(2), leg);
    
    % data to plot
    goodData = step(leg).speed > speedThresh;
    x = step(leg).speed(goodData);
    y = step(leg).swing_dur(goodData); 
    
    %plot data
    scatter(x, y , 'filled'); hold on; lsline; % sp eed x step freq
%     hist3([x,y], 'Nbins', [50,50],'CdataMode','auto'); hold on; colorbar; view(2);

    if leg == 1
        ylabel('Swing duration (?)');
        xlabel('Speed (mm/s)');
    end
    title(param.legs{leg});
end

fig = formatFig(fig,true,plotting);
%save 
fig_name = ['\Swing_Duration_X_Speed'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% PLOT: SWING DURATION x speed x temp - one lsline per temp bin 

%%%%% PARAMS %%%%%
headingThresh = 10; %degrees from straight ahead (180) included in 'forward' walking
tempEdges = 10:1:40; % edges of bins for binning temp data
%%%%%%%%%%%%%%%%%%


%plot step freq x temp for all data
fig = fullfig;
plotting = numSubplots(param.numLegs);
for leg = 1:param.numLegs
    clear h;
    subplot(plotting(1), plotting(2), leg);
    
    % data to plot
    goodData = step(leg).heading > 180-headingThresh & step(leg).heading < 180+headingThresh; %confine to 'forward' walking
    x = step(leg).speed(goodData);
    y = step(leg).swing_dur(goodData); 
    c = step(leg).temp(goodData);
    
%     cbin = discretize(c,tempEdges);
    [~,edges,cbin] = histcounts(c,tempEdges);
    bins = unique(cbin); 
    numBins = height(bins);
    binColors = parula(numBins);
    this_edges = [edges(bins),edges(max(bins)+1)];
    
    %plot data
    for bin = 1:numBins
        scatter(x(cbin == bins(bin)), y(cbin == bins(bin)), [20], binColors(bin,:)); hold on; 
        h = lsline; % speed x step freq
    end

    %color lsline to match temp bins
    b = numBins;
    for bin = 1:numBins
        set(h(b),'color',binColors(bin,:));
        set(h(b),'linewidth',2);
        b = b-1;
    end
    
    %colorbar for temp
    colormap(binColors)
    cb = colorbar('Ticks', [0:1/numBins:1],'TickLabels',this_edges);
    cb.Color = param.baseColor;
   

    if leg == 1
        ylabel('Swing duration (s)');
        xlabel('Speed (mm/s)');
    end
    title(param.legs{leg});
end

fig = formatFig(fig,true,plotting);

%save 
fig_name = ['\Swing_Duration_X_Speed_X_Temp_binnedFitLines'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% PLOT: STANCE DURATION x speed

%%%%% PARAMS %%%%%
speedThresh = 1; %max speed, since not all temps go to higher speeds it may distort lslines. 
%%%%%%%%%%%%%%%%%%


%plot step freq x temp for all data
fig = fullfig;
plotting = numSubplots(param.numLegs);
for leg = 1:param.numLegs
    subplot(plotting(1), plotting(2), leg);
    
    % data to plot
    goodData = step(leg).speed > speedThresh;
    x = step(leg).speed(goodData);
    y = step(leg).stance_dur(goodData); 
    
    %plot data
    scatter(x, y , 'filled'); hold on; lsline; % sp eed x step freq
%     hist3([x,y], 'Nbins', [50,50],'CdataMode','auto'); hold on; colorbar; view(2);

    if leg == 1
        ylabel('Stance duration (?)');
        xlabel('Speed (mm/s)');
    end
    title(param.legs{leg});
end

fig = formatFig(fig,true,plotting);

%save 
fig_name = ['\Stance_Duration_X_Speed'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% PLOT: STANCE DURATION x speed x temp - one lsline per temp bin 

%%%%% PARAMS %%%%%
headingThresh = 10; %degrees from straight ahead (180) included in 'forward' walking
tempEdges = 10:1:40; % edges of bins for binning temp data
%%%%%%%%%%%%%%%%%%


%plot step freq x temp for all data
fig = fullfig;
plotting = numSubplots(param.numLegs);
for leg = 1:param.numLegs
    clear h;
    subplot(plotting(1), plotting(2), leg);
    
    % data to plot
    goodData = step(leg).heading > 180-headingThresh & step(leg).heading < 180+headingThresh; %confine to 'forward' walking
    x = step(leg).speed(goodData);
    y = step(leg).stance_dur(goodData); 
    c = step(leg).temp(goodData);
    
%     cbin = discretize(c,tempEdges);
    [~,edges,cbin] = histcounts(c,tempEdges);
    bins = unique(cbin); 
    numBins = height(bins);
    binColors = parula(numBins);
    this_edges = [edges(bins),edges(max(bins)+1)];
    
    %plot data
    for bin = 1:numBins
        scatter(x(cbin == bins(bin)), y(cbin == bins(bin)), [20], binColors(bin,:)); hold on; 
        h = lsline; % speed x step freq
    end

    %color lsline to match temp bins
    b = numBins;
    for bin = 1:numBins
        set(h(b),'color',binColors(bin,:));
        set(h(b),'linewidth',2);
        b = b-1;
    end
    
    %colorbar for temp
    colormap(binColors)
    cb = colorbar('Ticks', [0:1/numBins:1],'TickLabels',this_edges);
    cb.Color = param.baseColor;
   

    if leg == 1
        ylabel('Stance duration (s)');
        xlabel('Speed (mm/s)');
    end
    title(param.legs{leg});
end

fig = formatFig(fig,true,plotting);

%save 
fig_name = ['\Stance_Duration_X_Speed_X_Temp_binnedFitLines'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% PLOT: TEMPERATURE x speed

%%%%% PARAMS %%%%%
headingThresh = 10; %degrees from straight ahead (180) included in 'forward' walking
%%%%%%%%%%%%%%%%%%


%plot step freq x temp for all data
fig = fullfig;
plotting = numSubplots(param.numLegs);
for leg = 1:param.numLegs
    subplot(plotting(1), plotting(2), leg);
    
    % data to plot
    goodData = step(leg).heading > 180-headingThresh & step(leg).heading < 180+headingThresh; %confine to 'forward' walking
    x = step(leg).speed(goodData);
    y = step(leg).temp(goodData); 
    
    %plot data
    scatter(x, y , 'filled'); hold on; lsline; % sp eed x step freq
%     hist3([x,y], 'Nbins', [50,50],'CdataMode','auto'); hold on; colorbar; view(2);

    if leg == 1
        ylabel('Temperature (C)');
        xlabel('Speed (mm/s)');
    end
    title(param.legs{leg});
end

fig = formatFig(fig,true,plotting);


%save 
fig_name = ['\Speed_X_Temp'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who; 

%% PLOT: DATA DISTRIBUTION across temp bins and speed

%%%%% PARAMS %%%%%
speedThresh = 3; %max speed, since not all temps go to higher speeds it may distort lslines. 
tempEdges = 0:2:40; % edges of bins for binning temp data
binEdges = [0, 2, 4, 6, 8, 10, 15, 25, 40];
%%%%%%%%%%%%%%%%%%

%plot step freq x temp for all data
fig = fullfig;
plotting = numSubplots(param.numLegs);
for leg = 1:param.numLegs
    subplot(plotting(1), plotting(2), leg);
    
    % data to plot
    goodData = step(leg).speed > speedThresh;
    x = step(leg).speed(goodData);
    y = step(leg).stance_dur(goodData); 
    c = step(leg).temp(goodData);
    
    %temp bins
    [~,edges,cbin] = histcounts(c,binEdges);
    bins = unique(cbin); 
    this_edges = [edges(bins),edges(max(bins)+1)];
    
    %speed 
    histogram(c, this_edges); hold on; 
    histogram(x, 10);


    if leg == 1
        ylabel('Count');
        xlabel('Blue: Temp (C) - Orange: Speed (mm/s)');
    end
    title(param.legs{leg});
end

fig = formatFig(fig,true,plotting);


%save 
fig_name = ['\Step_Distributions_for_Temp_&_Speed'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% PLOT: SWING DURATION x  STANCE DURATION

%%%%% PARAMS %%%%%
tempEdges = [0, 2, 4, 6, 8, 10, 15, 25, 40]; %0:2:40; % edges of bins for binning temp data
speedThresh = 1; %max speed, since not all temps go to higher speeds it may distort lslines. 
%%%%%%%%%%%%%%%%%%

%plot step freq x temp for all data
fig = fullfig; 
plotting = numSubplots(param.numLegs);
for leg = 1:param.numLegs
    clear h;
    subplot(plotting(1), plotting(2), leg);  hold on
    
        % data to plot
    goodData = step(leg).speed > speedThresh;
    x = step(leg).stance_dur(goodData);
    y = step(leg).swing_dur(goodData); 
    c = step(leg).speed(goodData);
    
    %filter out longest swing and stance
    stance_dur_thresh = 0.2;
    swing_dur_thresh = 0.06;
    
    for s = 1:height(x)
        if x(s) > stance_dur_thresh | y(s) > swing_dur_thresh
            x(s) = NaN; y(s) = NaN; c(s) = NaN;
        end
    end
    x = x(~isnan(x)); 
    y = y(~isnan(y));
    c = c(~isnan(c));
        
%     cbin = discretize(c,tempEdges);
    [~,edges,cbin] = histcounts(c,tempEdges);
    bins = unique(cbin); 
    numBins = height(bins);
    binColors = parula(numBins);
    this_edges = [edges(bins),edges(max(bins)+1)];
    
    %plot data
    for bin = 1:numBins
%         scatter(x(cbin == bins(bin)), y(cbin == bins(bin)), [20], binColors(bin,:)); hold on; 
%         h = lsline; % speed x step freq
        errorbar(nanmean(x(cbin == bins(bin))),nanmean(y(cbin == bins(bin))), ...
            nanstd(y(cbin == bins(bin))), nanstd(y(cbin == bins(bin))), ...
            nanstd(x(cbin == bins(bin))), nanstd(x(cbin == bins(bin))),'-ro','MarkerSize',10, 'Color',binColors(bin,:),'MarkerEdgeColor',binColors(bin,:),'MarkerFaceColor',binColors(bin,:)); %<- this shows mean with standard deviation
    end

%     %color lsline to match temp bins
%     b = numBins;
%     for bin = 1:numBins
%         set(h(b),'color',binColors(bin,:));
%         set(h(b),'linewidth',2);
%         b = b-1;
%     end
    
    %colorbar for temp
    colormap(binColors)
    cb = colorbar('Ticks', [0:1/numBins:1],'TickLabels',this_edges);
    cb.Color = param.baseColor;
    
%     ylim([0 0.1]);
%     xlim([0 0.2]);

    if leg == 1
        ylabel('Swing duration (s)');
        xlabel('Stance duration (s)');
    end
    title(param.legs{leg});
end

fig = formatFig(fig,true,plotting);

%save 
fig_name = ['\Swing_Duration_X_Stance_Duration'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% Swing Stance Plot %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CALCULATE: swing stance for all walking bouts
% zeros are stance
% ones are swing
% data is stored in boutMap
clear boutMap steps
%get walking data
walkingData = data(~isnan(data.walking_bout_number),:); 
boutNums = unique(walkingData.walking_bout_number);
%there are multiple of the same walking_bout_numbers in the same file, so 
%detect when there's a break in frame number and map old to new id
trueBoutNum = 0;
boutMap = table('Size', [0,10], 'VariableTypes',{'double', 'double', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell'},'VariableNames',{'oldBout','newBout','walkingDataIdxs','L1_swing_stance','L2_swing_stance','L3_swing_stance','R1_swing_stance','R2_swing_stance','R3_swing_stance', 'forward_rotation'});
for bout = 1:height(boutNums)
    %get idxs of all data with this 'walking_bout_number'
    boutIdxs = find(walkingData.walking_bout_number == boutNums(bout)); 
    %find where the frame number jumps, indicating multiple walking bouts with same 'walking_bout_number'
    [~, locs] = findpeaks(diff(boutIdxs), 'MinPeakProminence', 2);
    %find how many walking bout have same bout number 
    if isempty(locs); numSubBouts = 1; else; numSubBouts = height(locs)+1; end
    locs = [0; locs; height(boutIdxs)];

    for subBout = 1:numSubBouts
       %map old bout num to new bout num
       trueBoutNum = trueBoutNum + 1; 
       boutMap.oldBout(trueBoutNum) = boutNums(bout); %bout num as labelled in 'data'
       boutMap.newBout(trueBoutNum) = trueBoutNum; %new bout number where each bout num is unique
       boutMap.walkingDataIdxs(trueBoutNum) = {boutIdxs(locs(subBout)+1):boutIdxs(locs(subBout+1))}; %row nums in 'data'
   
       %calcualte swing and stance 
       for leg = 1:6
           %set full bout to 3
           swing_stance = NaN(width(boutMap.walkingDataIdxs{trueBoutNum}), 1);
           %get joint data, determine swing and stance regions and fill in
           %with ones and zeros respectively 
           this_leg_str = [param.legs{leg} 'E_y'];
           this_data = walkingData.(this_leg_str)(boutMap.walkingDataIdxs{trueBoutNum});
           
           prom = 0.2;
           [ssPks, ssPkLocs] = findpeaks(this_data, 'MinPeakProminence', prom);
           [ssTrs, ssTrLocs] = findpeaks(this_data*-1, 'MinPeakProminence', prom);
           
           for pk = 1:height(ssPks)-1
               step_start = ssPkLocs(pk); 
               step_end = ssPkLocs(pk+1);
               step_mid = ssTrLocs(ssTrLocs < step_end & ssTrLocs > step_start);
               swing_stance(step_start:step_mid-1) = 0; %stance 
               swing_stance(step_mid:step_end) = 1; %swing
           end           
           this_leg_ss_string = [param.legs{leg} '_swing_stance'];
           boutMap.(this_leg_ss_string)(trueBoutNum) = {swing_stance};
           
       end
    end
end

%set all swing stances to nan if any legs are nan
% set all to nan if any leg takes less than 5 steps
for bout = 1:height(boutMap)
    this_swing_stance = [boutMap.L1_swing_stance{bout}, boutMap.L2_swing_stance{bout}, boutMap.L3_swing_stance{bout},boutMap.R1_swing_stance{bout}, boutMap.R2_swing_stance{bout}, boutMap.R3_swing_stance{bout}];
    minNumSteps = min(sum(diff(this_swing_stance(:,:)) == 1));
    if (minNumSteps < 7)
        %not enough steps by each leg so set all data to NaN
        nanIdxs = 1:height(this_swing_stance); 
        boutMap.L1_swing_stance{bout}(nanIdxs) = NaN;
        boutMap.L2_swing_stance{bout}(nanIdxs) = NaN;
        boutMap.L3_swing_stance{bout}(nanIdxs) = NaN;
        boutMap.R1_swing_stance{bout}(nanIdxs) = NaN;
        boutMap.R2_swing_stance{bout}(nanIdxs) = NaN;
        boutMap.R3_swing_stance{bout}(nanIdxs) = NaN;
    else
        %there's enough steps, select forward walking and get rid of the first and last steps.
%         this_forward_rot = walkingData.forward_rotation(boutMap.walkingDataIdxs{bout});
%         not_forward_rot = find(this_forward_rot ~= 1);
        boutMap.forward_rotation{bout} = walkingData.forward_rotation(boutMap.walkingDataIdxs{bout});
        for leg = 1:param.numLegs
            end_steps = find(diff(this_swing_stance(:,leg)) == -1); 
            end_first_step = end_steps(1);
            start_last_step = end_steps(end);
            leg_str = [param.legs{leg} '_swing_stance'];
            boutMap.(leg_str){bout}(1:end_first_step) = NaN; 
            boutMap.(leg_str){bout}(start_last_step:end) = NaN; 
%             boutMap.(leg_str){bout}(not_forward_rot) = NaN;
        end
    end
end

initial_vars{end+1} = 'boutMap';
initial_vars{end+1} = 'walkingData';
clearvars('-except',initial_vars{:}); initial_vars = who;
%% SubBouts (filter by forward before metrics) - CALCULATE: step freq, speed, temp, heading dir, step length, stance dur, swing dur from BOUTMAP
% this one calculates step metrics for each subBout of forward walking
% within a bout of walking. 
clear step

%get speed for walkingData
%speed is in radians/frame. Ball radius is 4.495 mm. Fictrac is 30 fps.
%so speed in mm/s = (data.speed * 4.495 * 30)
speed = walkingData.fictrac_speed * param.sarah_ball_r * param.fictrac_fps;

for leg = 1:6
    step(leg).freq = []; %step frequency 
    step(leg).length = []; %step length
    step(leg).speed = []; %walking speed (avg per step)
    step(leg).heading = []; %heading direction 
    step(leg).swing_dur = []; %swing duration 
    step(leg).stance_dur = []; %stance duration 
    step(leg).temp = []; %temp (avg per step)
    step(leg).forward = []; %1 = ball is rotating forward; 0 = it's not. 
    
    for bout = 1:height(boutMap)
       boutIdxs = boutMap.walkingDataIdxs{bout}; %this bout in walkingData
       leg_ss_str = [param.legs{leg} '_swing_stance'];
       boutIdxsNotNan = boutIdxs(~isnan(boutMap.(leg_ss_str){bout})); %good walking idxs in walkingData
       if ~isempty(boutIdxsNotNan) & width(boutIdxsNotNan) > 5 %only procede if there's good walking data
           %because I've only selected forward walking, there can be
           %multuple chunks of good (not nan) walking in this bout. Loop
           %through all of these chunks and compute walking metrics. 
           [~,subBoutEndIdxs] = findpeaks(diff(boutIdxsNotNan), 'Threshold', 2);
           if ~isempty(subBoutEndIdxs)
               %there are multiple subBouts
               subBoutStartIdxs = subBoutEndIdxs + 1; 
               subBoutStartIdxs = [boutIdxsNotNan(1), boutIdxsNotNan(subBoutStartIdxs)];
               subBoutEndIdxs = [boutIdxsNotNan(subBoutEndIdxs), boutIdxsNotNan(end)];
               numSubBouts = width(subBoutStartIdxs);
           else
               %there is only one subBout of walking 
               numSubBouts = 1;
               subBoutStartIdxs = boutIdxsNotNan(1);
               subBoutEndIdxs = boutIdxsNotNan(end);
           end
           for subBout = 1:numSubBouts
               %get data for this sub bout
               this_subBout_idxs_in_walkingData = subBoutStartIdxs(subBout):subBoutEndIdxs(subBout);
               [~,this_subBout_idxs_in_boutMap] = ismember(this_subBout_idxs_in_walkingData,boutMap.walkingDataIdxs{bout});
               
               this_swing_stance_str = [param.legs{leg} '_swing_stance'];
               this_swing_stance = boutMap.(this_swing_stance_str){bout}(this_subBout_idxs_in_boutMap); this_swing_stance = this_swing_stance(~isnan(this_swing_stance));
               this_data_str = [param.legs{leg} 'E_y'];
               this_data = walkingData.(this_data_str)(this_subBout_idxs_in_walkingData);
               this_speed = speed(this_subBout_idxs_in_walkingData);
               this_heading = rad2deg(walkingData.fictrac_inst_dir(this_subBout_idxs_in_walkingData));
               this_temp = walkingData.temp(this_subBout_idxs_in_walkingData);
               if contains(param.legs{leg}, '3') | contains(param.legs{leg}, 'L2')
                    %for T3 troughs are stance start - so invert signal to make peaks stance starts
                    %for L2, stance is positive values, so trough to peak, so invert so peaks are stance starts. 
                    this_data = this_data *-1;
               end
           
               pkLocs = find(diff(this_swing_stance) == 1);
               trLocs = find(diff(this_swing_stance) == -1);
               
               if height(pkLocs) > 3 & height(trLocs) > 3 %make sure this subBout has enough steps to calculate step metrics
               
               
               
%            %%%%%%%%%%%%%%%%%%%%%%%%%%%
%            %get data for this bout
%            this_swing_stance_str = [param.legs{leg} '_swing_stance'];
%            this_swing_stance = boutMap.(this_swing_stance_str){bout}; this_swing_stance = this_swing_stance(~isnan(this_swing_stance));
%            this_data_str = [param.legs{leg} 'E_y'];
%            this_data = walkingData.(this_data_str)(boutIdxsNotNan);
%            this_speed = speed(boutIdxsNotNan);
%            this_heading = rad2deg(walkingData.fictrac_inst_dir(boutIdxsNotNan));
%            this_temp = walkingData.temp(boutIdxsNotNan);
%            if contains(param.legs{leg}, '3') | contains(param.legs{leg}, 'L2')
%                 %for T3 troughs are stance start - so invert signal to make peaks stance starts
%                 %for L2, stance is positive values, so trough to peak, so invert so peaks are stance starts. 
%                 this_data = this_data *-1;
%            end
%            
%            pkLocs = find(diff(this_swing_stance) == 1);
%            trLocs = find(diff(this_swing_stance) == -1);
%            
% %            if height(pkLocs) > 10 %I already filter by number of steps when making boutNum, but could be stricter here if I want. 

                   %calculate step freq
                   step_freq = [];
                   step_freq = 1./(diff(pkLocs)/param.fps); %from tarsi y position 

                   %calc avg speed and heading per step
                   bout_speed = [];
                   bout_heading = [];
                   bout_temp = [];
                   for st = 1:height(pkLocs)-1
                       bout_speed(st,1) = nanmean(this_speed(pkLocs(st):pkLocs(st+1))); %avg speed for each step 
                       bout_heading(st,1) = nanmean(this_heading(pkLocs(st):pkLocs(st+1))); %avg heading for each step 
                       bout_temp(st,1) = nanmean(this_temp(pkLocs(st):pkLocs(st+1))); %avg temperature for each step 
                   end

                    %calculate step length (3D euclidian distance) 
                    this_step_length = [];
                    for st = 1:height(pkLocs)-1
                        this_step_length(st,1) = sqrt(sum((this_data(pkLocs(st),:) - this_data(trLocs(st),:)).^2, 2));
                    end

                    %swing and stance dur %TODO I can do this easier now!!! bwlabel?
                    all_peaksNtroughs = sort([pkLocs; trLocs]);
                    peak_first = 0;
                    if pkLocs(1) < trLocs(1); peak_first = 1; end
                    all_durations = diff(all_peaksNtroughs)/param.fps; 
                    if peak_first
                        %first duration is peak to trough, which is stance. 
                        this_stance_dur = all_durations(1:2:end); %odds
                        this_swing_dur = all_durations(2:2:end); %evens
                    else
                        %first duration is trough to peak, which is swing. 
                        this_stance_dur = all_durations(2:2:end); %evens
                        this_swing_dur = all_durations(1:2:end); %odds
                    end 
                    
                    
                    

                    %save data
                    step(leg).freq = [step(leg).freq; step_freq];
                    step(leg).length = [step(leg).length; this_step_length];
                    step(leg).speed = [step(leg).speed; bout_speed];
                    step(leg).heading = [step(leg).heading; bout_heading];
                    step(leg).stance_dur = [step(leg).stance_dur; this_stance_dur]; 
                    step(leg).swing_dur = [step(leg).swing_dur; this_swing_dur]; 
                    step(leg).temp = [step(leg).temp; bout_temp];
               end
           end
       end  
    end
end

initial_vars{end+1} = 'step';
clearvars('-except',initial_vars{:}); initial_vars = who;
%% OG - CALCULATE: step freq, speed, temp, heading dir, step length, stance dur, swing dur from BOUTMAP
clear step

%get speed for walkingData
%speed is in radians/frame. Ball radius is 4.495 mm. Fictrac is 30 fps.
%so speed in mm/s = (data.speed * 4.495 * 30)
speed = walkingData.fictrac_speed * param.sarah_ball_r * param.fictrac_fps;

for leg = 1:6
    step(leg).freq = []; %step frequency 
    step(leg).length = []; %step length
    step(leg).speed = []; %walking speed (avg per step)
    step(leg).heading = []; %heading direction 
    step(leg).swing_dur = []; %swing duration 
    step(leg).stance_dur = []; %stance duration 
    step(leg).temp = []; %temp (avg per step)
    
    for bout = 1:height(boutMap)
       boutIdxs = boutMap.walkingDataIdxs{bout}; %this bout in walkingData
       leg_ss_str = [param.legs{leg} '_swing_stance'];
       boutIdxsNotNan = boutIdxs(~isnan(boutMap.(leg_ss_str){bout})); %good walking idxs in walkingData
       if ~isempty(boutIdxsNotNan) %only procede if there's good walking data
           %get data for this bout
           this_swing_stance_str = [param.legs{leg} '_swing_stance'];
           this_swing_stance = boutMap.(this_swing_stance_str){bout}; this_swing_stance = this_swing_stance(~isnan(this_swing_stance));
           this_data_str = [param.legs{leg} 'E_y'];
           this_data = walkingData.(this_data_str)(boutIdxsNotNan);
           this_speed = speed(boutIdxsNotNan);
           this_heading = rad2deg(walkingData.fictrac_inst_dir(boutIdxsNotNan));
           this_temp = walkingData.temp(boutIdxsNotNan);
           if contains(param.legs{leg}, '3') | contains(param.legs{leg}, 'L2')
                %for T3 troughs are stance start - so invert signal to make peaks stance starts
                %for L2, stance is positive values, so trough to peak, so invert so peaks are stance starts. 
                this_data = this_data *-1;
           end
           
           pkLocs = find(diff(this_swing_stance) == 1);
           trLocs = find(diff(this_swing_stance) == -1);
           
%            if height(pkLocs) > 10 %I already filter by number of steps when making boutNum, but could be stricter here if I want. 

           %calculate step freq
           step_freq = [];
           step_freq = 1./(diff(pkLocs)/param.fps); %from tarsi y position 
           
           %calc avg speed and heading per step
           bout_speed = [];
           bout_heading = [];
           bout_temp = [];
           for st = 1:height(pkLocs)-1
               bout_speed(st,1) = nanmean(this_speed(pkLocs(st):pkLocs(st+1))); %avg speed for each step 
               bout_heading(st,1) = nanmean(this_heading(pkLocs(st):pkLocs(st+1))); %avg heading for each step 
               bout_temp(st,1) = nanmean(this_temp(pkLocs(st):pkLocs(st+1))); %avg temperature for each step 
           end
           
            %calculate step length (3D euclidian distance) 
            this_step_length = [];
            for st = 1:height(pkLocs)-1
                this_step_length(st,1) = sqrt(sum((this_data(pkLocs(st),:) - this_data(trLocs(st),:)).^2, 2));
            end

            %swing and stance dur %TODO I can do this easier now!!! bwlabel?
            all_peaksNtroughs = sort([pkLocs; trLocs]);
            peak_first = 0;
            if pkLocs(1) < trLocs(1); peak_first = 1; end
            all_durations = diff(all_peaksNtroughs)/param.fps; 
            if peak_first
                %first duration is peak to trough, which is stance. 
                this_stance_dur = all_durations(1:2:end); %odds
                this_swing_dur = all_durations(2:2:end); %evens
            else
                %first duration is trough to peak, which is swing. 
                this_stance_dur = all_durations(2:2:end); %evens
                this_swing_dur = all_durations(1:2:end); %odds
            end 

            %save data
            step(leg).freq = [step(leg).freq; step_freq];
            step(leg).length = [step(leg).length; this_step_length];
            step(leg).speed = [step(leg).speed; bout_speed];
            step(leg).heading = [step(leg).heading; bout_heading];
            step(leg).stance_dur = [step(leg).stance_dur; this_stance_dur]; 
            step(leg).swing_dur = [step(leg).swing_dur; this_swing_dur]; 
            step(leg).temp = [step(leg).temp; bout_temp];
           
       
       end  
    end
end

initial_vars{end+1} = 'step';
clearvars('-except',initial_vars{:}); initial_vars = who;
%% NEW (filter by forward after metrics) - CALCULATE: step freq, speed, temp, heading dir, step length, stance dur, swing dur from BOUTMAP
clear step

%get speed for walkingData
%speed is in radians/frame. Ball radius is 4.495 mm. Fictrac is 30 fps.
%so speed in mm/s = (data.speed * 4.495 * 30)
speed = walkingData.fictrac_speed * param.sarah_ball_r * param.fictrac_fps;

for leg = 1:6
    step(leg).freq = []; %step frequency 
    step(leg).length = []; %step length
    step(leg).speed = []; %walking speed (avg per step)
    step(leg).heading = []; %heading direction 
    step(leg).swing_dur = []; %swing duration 
    step(leg).stance_dur = []; %stance duration 
    step(leg).temp = []; %temp (avg per step)
%     step(leg).forward = []; %1 = forward rotation of the ball
    
    for bout = 1:height(boutMap)
       boutIdxs = boutMap.walkingDataIdxs{bout}; %this bout in walkingData
       leg_ss_str = [param.legs{leg} '_swing_stance'];
       boutIdxsNotNan = boutIdxs(~isnan(boutMap.(leg_ss_str){bout})); %good walking idxs in walkingData
       if ~isempty(boutIdxsNotNan) %only procede if there's good walking data
           %get data for this bout
           this_swing_stance_str = [param.legs{leg} '_swing_stance'];
           this_swing_stance = boutMap.(this_swing_stance_str){bout}; 
           this_swing_stance_noNaN = this_swing_stance(~isnan(this_swing_stance));
           this_data_str = [param.legs{leg} 'E_y'];
           this_data = walkingData.(this_data_str)(boutIdxsNotNan);
           this_speed = speed(boutIdxsNotNan);
           this_heading = rad2deg(walkingData.fictrac_inst_dir(boutIdxsNotNan));
           this_temp = walkingData.temp(boutIdxsNotNan);
           this_forward = boutMap.forward_rotation{bout};
           
           %only look at bout if there were enough steps by each leg (5) to save forward rotation info
           if ~isempty(this_forward)
               if contains(param.legs{leg}, '3') | contains(param.legs{leg}, 'L2')
                    %for T3 troughs are stance start - so invert signal to make peaks stance starts
                    %for L2, stance is positive values, so trough to peak, so invert so peaks are stance starts. 
                    this_data = this_data *-1;
               end

               pkLocs = find(diff(this_swing_stance_noNaN) == 1);
               trLocs = find(diff(this_swing_stance_noNaN) == -1);
               
               %go through each step, determine if it's forward walking,
               %and if so calculate metrics
               step_freq = [];
               step_speed = [];
               step_heading = [];
               step_temp = [];
               step_length = [];
               swing_duration = [];
               stance_duration = [];
               for st = 1:height(pkLocs)-1
                  %is this forward walking
                  fwrd = this_forward(pkLocs(st):pkLocs(st+1));
                  if sum(fwrd) == height(fwrd)
                     %the whole step is forward walking, so calculate metrics
                     step_freq = [step_freq; 1./((pkLocs(st+1)-pkLocs(st))/param.fps)]; %step frequency 
                     step_speed = [step_speed; nanmean(this_speed(pkLocs(st):pkLocs(st+1)))]; %avg speed for each step 
                     step_heading = [step_heading; nanmean(this_heading(pkLocs(st):pkLocs(st+1)))]; %avg heading for each step 
                     step_temp = [step_temp; nanmean(this_temp(pkLocs(st):pkLocs(st+1)))]; %avg temperature for each step 
                     step_length = [step_length; sqrt(sum((this_data(pkLocs(st),:) - this_data(trLocs(st),:)).^2, 2))];
                     this_trough = find(trLocs > pkLocs(st) & trLocs < pkLocs(st+1)); %gives idx in trLocs
                     swing_duration = [swing_duration; (trLocs(this_trough)-pkLocs(st))/param.fps];
                     stance_duration = [stance_duration; (pkLocs(st+1)-trLocs(this_trough))/param.fps]; %duration in seconds
                  end
               end
               
                %save data
                step(leg).freq = [step(leg).freq; step_freq];
                step(leg).length = [step(leg).length; step_length];
                step(leg).speed = [step(leg).speed; step_speed];
                step(leg).heading = [step(leg).heading; step_heading];
                step(leg).stance_dur = [step(leg).stance_dur; stance_duration]; 
                step(leg).swing_dur = [step(leg).swing_dur; swing_duration]; 
                step(leg).temp = [step(leg).temp; step_temp];
           end
       
       end  
    end
end

initial_vars{end+1} = 'step';
clearvars('-except',initial_vars{:}); initial_vars = who;


 %% Plot: Joint angles and swing stance plot

bout = 709; %walking bout to plot (newBout in boutMap)

%get swing stance data for this bout 
this_swing_stance = [boutMap.L1_swing_stance{bout}, boutMap.L2_swing_stance{bout}, boutMap.L3_swing_stance{bout},boutMap.R1_swing_stance{bout}, boutMap.R2_swing_stance{bout}, boutMap.R3_swing_stance{bout}];
for leg = 1:6
    nanIdxs = find(isnan(this_swing_stance(:,leg)));
    this_swing_stance(nanIdxs,leg) = 3;
end

 %x data for plotting true to video frames if desired
x = boutMap.walkingDataIdxs{bout}(1)+1:boutMap.walkingDataIdxs{bout}(end);

fig = fullfig;
subplot(4,1,1);
%plot the joint data
plot(walkingData.L1E_y(boutMap.walkingDataIdxs{bout})); hold on
plot(walkingData.L2E_y(boutMap.walkingDataIdxs{bout}));
plot(walkingData.L3E_y(boutMap.walkingDataIdxs{bout}));
plot(walkingData.R1E_y(boutMap.walkingDataIdxs{bout}));
plot(walkingData.R2E_y(boutMap.walkingDataIdxs{bout}));
plot(walkingData.R3E_y(boutMap.walkingDataIdxs{bout}));
legend('L1E-y', 'L2E-y', 'L3E-y', 'R1E-y', 'R2E-y', 'R3E-y', 'Location', 'best', 'NumColumns', 6);
ylabel('tarsi y positions');
axis tight
hold off

subplot(4,1,2);
%plot the swing stance plot
imagesc(this_swing_stance'); colormap([Color(param.backgroundColor); Color(param.baseColor); 0.5 0.5 0.5;]); 
yticklabels({'L1', 'L2', 'L3', 'R1', 'R2', 'R3'});
ylabel('swing stance')

subplot(4,1,3);
%plot speed 
speed_data = walkingData.fictrac_speed(boutMap.walkingDataIdxs{bout}) * param.sarah_ball_r * param.fictrac_fps;
plot(speed_data); hold on;
plot(smoothdata(speed_data, 'gaussian', 100)); 
ylabel('speed (mm/s)');
legend('raw', 'smoothed');
axis tight
ylim([0 20]);


subplot(4,1,4)
%plot inst_dir
yline(180, '--'); hold on
inst_dir_data = rad2deg(walkingData.fictrac_inst_dir(boutMap.walkingDataIdxs{bout}));
% true_inst_dir = downsample(inst_dir_data,param.fictrac_fps, param.fictrac_fps-1);
% true_x = [1, downsample([1,x],param.fictrac_fps, param.fictrac_fps-1)];
% 
% 
% true_inst_dir = downsample(data.heading(x),param.fictrac_fps, param.fictrac_fps-1);
% true_x = downsample(x,param.fictrac_fps, param.fictrac_fps-1);

plot(inst_dir_data); hold on; 
% plot(true_x(1:end-1),true_inst_dir);
% plot(smoothdata(inst_dir_data, 'gaussian', 100)); hold off; 
legend('raw');
ylabel(['heading (deg)']);
axis tight
hold off

first_frame = walkingData.fnum(x(1));
date = walkingData.date_parsed{first_frame};
fly = walkingData.fly{first_frame};
rep = walkingData.rep(first_frame);
cond = walkingData.condnum(first_frame);

%save
fig_name = ['\Swing stance plots - date ' date ' - fly ' fly ' - R' num2str(rep) 'C' num2str(cond) ' - bout ' num2str(bout) ' - first frame ' num2str(first_frame)];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% clearvars('-except',initial_vars{:}); initial_vars = who;













%% %%%%%%%%%%%% TROUBLESHOOTING %%%%%%%%%%%%%%%

%% relationships btw joints


walkingData = data(data.walking_bout_number == 1,:);

plot(data.L2B_rot(1:500)); hold on
plot(data.L1C_flex(1:500)); 
plot(data.L2B_y(1:500)); hold off

legend('L2B-rot', 'L1C-flex', 'L2B-y', 'Location', 'best');


plot((data.L2B_rot(1:500)- mean(data.L2B_rot(1:500)))/std(data.L2B_rot(1:500))); hold on
plot((data.L2E_y(1:500)- mean(data.L2E_y(1:500)))/std(data.L2E_y(1:500))); 
% plot((data.L2B_y(1:500)- mean(data.L2B_y(1:500)))/std(data.L2B_y(1:500))); 
plot((data.L1E_y(1:500)- mean(data.L1E_y(1:500)))/std(data.L1E_y(1:500))); 
plot((data.L1_FTi(1:500)- mean(data.L1_FTi(1:500)))/std(data.L1_FTi(1:500))); 
hold off

legend('L2B-rot', 'L2E-y','L1E-y', 'L1-FTi', 'Location', 'best');



 



scatter(data.L2B_rot(1:500), data.L2B_y(1:500)); hold on 
xlabel('L2B-rot');
ylabel('L2B-y'); hold off


scatter(data.L2B_rot(1:500), data.L1C_flex(1:500)); hold on 
xlabel('L2B-rot');
ylabel('L1C-flex'); hold off


scatter(data.L1E_y(1:500), data.L2B_rot(1:500)); hold on 
xlabel('L1E-y');
ylabel('L2B-rot'); hold off


scatter(data.L2B_y(1:500), data.L1C_flex(1:500)); hold on 
xlabel('L2B-y');
ylabel('L1C-flex'); hold off


scatter(data.L1_FTi(1:500), data.L1C_flex(1:500)); hold on 
xlabel('L1-FTi');
ylabel('L1C-flex'); hold off
%% fixing rotation wrap around

%some rotation data
plot(data.L2B_rot)

%method 1 from Pierre: +- 360 if difference btw datapoints is
%larger/smaller than 160 degrees
s = zeros(size(data.L2B_rot));
d = [0; diff(data.L2B_rot)]; 
s(d > 160) = -360; 
s(d < -160) = 360; 
out = cumsum(s) + data.L2B_rot;

% method 2 from pierre: 
d = [0; diff(data.L2B_rot)];
d(abs(d) > 20) = 0; 
out = cumsum(d) + data.L2B_rot(1);
    

% if data is < 360, add 360 ... i think this works!
out = data.L2B_rot;
out(out < 0) = out(out < 0) + 360;
%% inst_dir


plot(data.L1_FTi(data.walking_bout_number == 1)); hold on; 
plot(data.inst_dir(data.walking_bout_number == 1)); hold off;

%okay so I think that data.inst_dir is the heading direction I want. and pi
%is forward walking I'm pretty sure. so I need to select data with inst_dir
%in some range of pi. 

%% make sure that speed and inst_dir match up with the videos...
% vid: http://128.95.10.233:5000/#5.13.21/Fly%201_0/05132021_fly1_0%20R1C1%20%20str-cw-0%20sec

% x = 3350:3700; %starts walking ~3517
% x = 1900:2100; %stops walking ~2000
x = 1:12000; %all vid
scale = 30;

abd_groom = ~isnan(data.abdomen_grooming_bout_number(x));
walk = ~isnan(data.walking_bout_number(x));
t1_groom = ~isnan(data.t1_grooming_bout_number(x));
stand = ~isnan(data.standing_bout_number(x));

a = area(walk*scale);hold on
a.FaceAlpha = 0.2;
a = area(abd_groom*scale);
a.FaceAlpha = 0.2;
a = area(t1_groom*scale);
a.FaceAlpha = 0.2;
a = area(stand*scale);
a.FaceAlpha = 0.2;
plot(x,data.speed(x)* param.sarah_ball_r * param.fictrac_fps, 'linewidth', 2); 
plot(x,data.inst_dir(x), 'linewidth', 2); 
plot(x(1:end-1), diff(data.inst_dir(x)), 'linewidth', 2);
plot(x,data.heading(x), 'linewidth', 2); 
true_heading = downsample(data.heading(x),param.fictrac_fps, param.fictrac_fps-1);
true_x = downsample(x,param.fictrac_fps, param.fictrac_fps-1);
plot(true_x,unwrap(true_heading), 'linewidth', 2); 
plot(true_x(1:end-1),diff(unwrap(true_heading)), 'linewidth', 2); 



legend('walk', 'abd groom', 't1 groom', 'stand', 'speed', 'inst dir', 'diff inst dir', 'heading', 'unwrapped heading', 'diff unwrapped heading','Location', 'best');
hold off;

% polarplot(data.heading(x), x)

% 
% polarplot(data.inst_dir(x(1:200)), x(1:200))
% %downsample since fictrac is 30 fps
% true_inst_dir = downsample(data.inst_dir(x),10);
% true_x = downsample(x, 10);
% polarplot(true_inst_dir(1:200), true_x(1:200))
% 
%% TODO: load in fictrac data for a video with obvious straight walking and turning 
%  make sure that I know what vars are.
%  is 'speed' a mix of rotations? does it contain rotational velocity for all three axes?

%http://128.95.10.233:5000/#6.4.21/Fly%201_0/06042021_fly1_0%20R1C11%20%20rot-cw-0%20sec
%6.4.21
%1_0
%R1
%C11
fictrac_path = 'G:\My Drive\Tuthill Lab Shared\Sarah\Data\FicTrac Raw Data\6.4.21\Fly 1_0\FicTrac Data\06042021_fly1_0data_out.dat';
parquet_path = 'G:\My Drive\Tuthill Lab Shared\Pierre\summaries\v3-b3\days\all_6.4.21.parquet';

f_data = load(fictrac_path);
p_data = parquetread(parquet_path);

%Fictrac labels
f_labels.frame_counter = 1;          %frame count of the recording
f_labels.X = 6;                      %X rotation of the ball=right to left
f_labels.Y = 7;                      %Y rotation of the ball=down side to up-side
f_labels.Z = 8;                      %Z rotation of the ball=forward and backward
f_labels.int_x = 15;                 %integrated x position of the fly (incorporates animal heading)
f_labels.int_y = 16;                 %integrated y position of the fly (incorporates animal heading)
f_labels.heading = 17;               %overall direction that the fly is heading
f_labels.inst_dir = 18;              %direction of the fly in that frame (in radians)
f_labels.speed = 19;                 %the fly's walking speed
f_labels.diffheading = 24; 

this_vid = strcmpi(p_data.flyid, "6.4.21 Fly 1_0") & p_data.rep == 1 & p_data.condnum == 11;
this_p_data = p_data(this_vid,:);

%% Gaussian filter for speed
% vid: http://128.95.10.233:5000/#5.13.21/Fly%201_0/05132021_fly1_0%20R1C1%20%20str-cw-0%20sec

% x = 3350:3700; %starts walking ~3517
% x = 1900:2100; %stops walking ~2000
x = 1:12000; %all vid
scale = 30;

abd_groom = ~isnan(data.abdomen_grooming_bout_number(x));
walk = ~isnan(data.walking_bout_number(x));
t1_groom = ~isnan(data.t1_grooming_bout_number(x));
stand = ~isnan(data.standing_bout_number(x));

a = area(walk*scale);hold on
a.FaceAlpha = 0.2;
a = area(abd_groom*scale);
a.FaceAlpha = 0.2;
a = area(t1_groom*scale);
a.FaceAlpha = 0.2;
a = area(stand*scale);
a.FaceAlpha = 0.2;
speed_data = data.speed(x)* param.sarah_ball_r * param.fictrac_fps;
plot(x,speed_data, 'linewidth', 2); 
smooth_speed_data = smoothdata(speed_data,'gaussian',100);
plot(x,smooth_speed_data, 'linewidth', 2); 


legend('walk', 'abd groom', 't1 groom', 'stand', 'speed', 'smooth speed', 'Location', 'best');
hold off;
 
%% check all fictrac variables against a known vid 
% vid: http://128.95.10.233:5000/#5.13.21/Fly%201_0/05132021_fly1_0%20R1C1%20%20str-cw-0%20sec

% x = 3350:3700; %starts walking ~3517
% x = 1900:2100; %stops walking ~2000
x = 1:12000; %all vid
scale = 30;

abd_groom = ~isnan(data.abdomen_grooming_bout_number(x));
walk = ~isnan(data.walking_bout_number(x));
t1_groom = ~isnan(data.t1_grooming_bout_number(x));
stand = ~isnan(data.standing_bout_number(x));

a = area(walk*scale);hold on
a.FaceAlpha = 0.2;
a = area(abd_groom*scale);
a.FaceAlpha = 0.2;
a = area(t1_groom*scale);
a.FaceAlpha = 0.2;
a = area(stand*scale);
a.FaceAlpha = 0.2;

fictracVars = find(contains(data.Properties.VariableNames, 'fictrac'));
numFictracVars = width(fictracVars);
var_names = {};
var_names{end+1} = 'walk';
var_names{end+1} = 'abd groom';
var_names{end+1} = 't1 groom';
var_names{end+1} = 'stand';
for var = 2:numFictracVars-2
%     plot(x, (data{x, fictracVars(var)}-mean(data{x, fictracVars(var)}))/std(data{x, fictracVars(var)}));

    if var ~= 5 %don't plot delta rotation score
        plot(x, data{x, fictracVars(var)});
        var_names{end+1} = strrep(data.Properties.VariableNames{fictracVars(var)}, '_', ' ');
    end
end

% plot(data.fictrac_int_x(x), data.fictrac_int_y(x));
% plot(data.fictrac_heading(x));

legend(var_names,'Location', 'best');
hold off;


%% Find forward roation 

vid_starts = find(data.fnum == 0);
vid_ends = vid_starts-1; 
vid_ends = [vid_ends(2:end); height(data)]; 

%over 30 frames, check whether at least half are forward walking. 
win = 30; %window size
stp = 1; %step size 
thresh = 20; %degrees from 0 or 180 to count as forward walking 
forward_rotation = NaN(height(data), 1);
for vid = 1:height(vid_starts)
   this_vid_idxs = vid_starts(vid):vid_ends(vid);
   this_vid_inst_dir = rad2deg(data.fictrac_inst_dir(this_vid_idxs)); 
   numWindows = floor((height(this_vid_inst_dir)-win)/stp);
   i = 1; %start idx for window
   j = win/2; %first window result will go here. 
   this_vid_forward = NaN(height(this_vid_inst_dir), 1);
   for window = 1:numWindows
      this_win = this_vid_inst_dir(i:i+win);
      %get data within thresh 
      this_forward = this_win < thresh | this_win > 360-thresh;
      if(sum(this_forward)/width(this_forward) < 0.5)
          %less than half the frames were forward rotation, so it's not forward rotation
          this_vid_forward(j) = 0; 
      else
          %at least half frames were forward, so it's forward rotation
          this_vid_forward(j) = 1;
      end
      i = i+stp;
      j = j+stp;
   end
   %save this_vid_forward
   forward_rotation(this_vid_idxs) = this_vid_forward;
end
data.forward_rotation = forward_rotation; 






















