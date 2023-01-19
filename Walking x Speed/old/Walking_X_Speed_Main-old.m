%% How does walking change across velcocity?
% Sarah Walling-Bell
% April, 2022
%% Load & orgnaize the data 
clear all; close all; clc;

% select and load parquet file (the fly data)
[FilePaths, version] = DLC_select_parquet(); 
[data, columns, column_names, path] = DLC_extract_parquet(FilePaths);
[numReps, numConds, flyList, flyIndices] = DLC_extract_flies(columns, data);
param = DLC_load_params(data, version, flyList);
param.numReps = numReps;
param.numConds = numConds; 
param.stimRegions = DLC_getStimRegions(data, param);
param.flyIndices = flyIndices;

param.columns = columns; 
param.column_names = column_names;  
param.parquet = path;   
 
% save walking data 
walkingData = data(~isnan(data.walking_bout_number),:); 

% parse walking bouts and find swing stance
% boutMap = boutMap_with_swing_stance(walkingData,param);
clear boutMap
boutMap = boutMap(walkingData,param); 

% parse steps and step metrics
clear steps
steps = steps(boutMap, walkingData, param);

% organize data for plotting 
joint_data = DLC_org_joint_data(data, param);
joint_data_byFly = DLC_org_joint_data_byFly(data, param);

% get behaviors of each fly 
param.thresh = 0.1; %0.5; %thres hold for behavior prediction 
behavior = DLC_behavior_predictor(data, param); 
behavior_byBout = DLC_behavior_predictor_byBoutNum (data, param);

initial_vars = who; 

%% Q1: Do joint angles change across the step cycle as a fn of velocity? 
%% %%% A1a: Looking at one fly, and 1D velocity directions. 
 
%% PLOT RAW JOINT X PHASE COLORED BY A VELOCITY - single fly 
%% Plot a joint x phase for all data of a fly, color by Foward speed
clearvars('-except',initial_vars{:}); initial_vars = who;

fly = flyList.flyid{5};
leg = 1;
joint_data = 'FTi';
phase_data = 'FTi_phase';

max_speed_x = 3;
min_speed_y = 3; 
max_speed_z = 3;

color = 'avg_speed_y'; %var in steps.meta
idxs = find(strcmpi(steps.leg(leg).meta.fly, fly) & ...
                abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                    steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
fig = fullfig; 
maxSpeed = (ceil(max(steps.leg(leg).meta.(color)(idxs, :))));
minSpeed = (floor(min(steps.leg(leg).meta.(color)(idxs, :))));
cmap = colormap(jet(maxSpeed));
for s = 1:height(idxs)
    color_idx = round(steps.leg(leg).meta.(color)(idxs(s), :)); 
    if color_idx == 0; color_idx = 1; end
    polarplot(steps.leg(leg).(phase_data)(idxs(s), :)', steps.leg(leg).(joint_data)(idxs(s), :)', 'color', cmap(color_idx, :));hold on
end

fig = formatFigPolar(fig, true);

c = colorbar('XTick', [0,1], ...
    'XTickLabel',{num2str(minSpeed),[num2str(maxSpeed) ' (' num2str(height(idxs)) ' steps)']});
c.Label.String = 'Forward velocity (mm/s)';
c.Label.FontSize = 30;
c.Color = param.baseColor;
c.Box = 'off';

pax = gca;
pax.FontSize = 30;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
rticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
rtickangle(pax, 45);
thetaticks([0, 90, 180, 270]);
thetaticklabels({'0', '\pi/2', '\pi', '3\pi/4'});


hold off



%save 
fig_name = ['\' joint_data '_x_' phase_data '_' param.legs{leg} '_leg_coloredByForwardSpeed - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - ' strrep(fly, '.', '_')];
% save_figure(fig, [param.googledrivesave fig_name], param.fileType);
save_figure(fig, [path fig_name], param.fileType);


clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot a joint x phase for all data of a fly, color by Sideslip speed
clearvars('-except',initial_vars{:}); initial_vars = who;

fly = flyList.flyid{5};
leg = 3;
joint_data = 'FTi';
phase_data = 'FTi_phase';

min_speed_x = 0;
max_speed_y = 10; 
max_speed_z = 10;

color = 'avg_speed_x'; %var in steps.meta
idxs = find(strcmpi(steps.leg(leg).meta.fly, fly) & ...
                    abs(steps.leg(leg).meta.avg_speed_x) > min_speed_x & ...
                    steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
                abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
fig = fullfig; 
maxSpeed = (ceil(max(abs(steps.leg(leg).meta.(color)(idxs, :)))));
cmap = colormap(redblue(maxSpeed*2));

c = redblue(256, [maxSpeed*-1, maxSpeed]);


for s = 1:height(idxs)
    polarplot(steps.leg(leg).(phase_data)(idxs(s), :)', steps.leg(leg).(joint_data)(idxs(s), :)', ...
        'color', c((round(steps.leg(leg).meta.(color)(idxs(s))/maxSpeed*(height(c)/2))+height(c)/2),:));hold on
end

colormap(c);

fig = formatFigPolar(fig, true);

cb = colorbar('XTick', [0,0.5,1], ...
    'XTickLabel',{['-' num2str(maxSpeed) ' (right)'], ['0 (' num2str(height(idxs)) ' steps)'], [num2str(maxSpeed) ' (left)']});

cb.Label.String = 'Sideslip velocity (mm/s)';
cb.Label.FontSize = 30;
cb.Color = param.baseColor;
cb.Box = 'off';

pax = gca;
pax.FontSize = 30;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
rticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
rtickangle(pax, 45);
thetaticks([0, 90, 180, 270]);
thetaticklabels({'0', '\pi/2', '\pi', '3\pi/4'});

hold off

%save 
fig_name = ['\' joint_data '_x_' phase_data '_' param.legs{leg} '_leg_coloredBySideslipSpeed - speed range x_above_' num2str(min_speed_x) ' y_below_' num2str(max_speed_y) ' z_below_' num2str(max_speed_z) ' - ' strrep(fly, '.', '_')];
% save_figure(fig, [param.googledrivesave fig_name], param.fileType);
save_figure(fig, [path fig_name], param.fileType);


clearvars('-except',initial_vars{:}); initial_vars = who;


%% Plot a joint x phase for all data of a fly, color by Rotational speed
clearvars('-except',initial_vars{:}); initial_vars = who;

fly = flyList.flyid{5};
leg = 1;
joint_data = 'CF';
phase_data = 'CF_phase';

max_speed_y = 1; 

color = 'avg_speed_z'; %var in steps.meta
idxs = find(strcmpi(steps.leg(leg).meta.fly, fly) & ...
                    steps.leg(leg).meta.avg_speed_y  > max_speed_y);
                
                
max_speed_x = 10;
max_speed_y = 10; 
min_speed_z = 0;

color = 'avg_speed_x'; %var in steps.meta
idxs = find(strcmpi(steps.leg(leg).meta.fly, fly) & ...
                    abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                    steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
                abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
                
                
                
fig = fullfig; 
maxSpeed = (ceil(max(abs(steps.leg(leg).meta.(color)(idxs, :)))));
cmap = colormap(redblue(maxSpeed*2));

c = redblue(256, [maxSpeed*-1, maxSpeed]);


for s = 1:height(idxs)
    polarplot(steps.leg(leg).(phase_data)(idxs(s), :)', steps.leg(leg).(joint_data)(idxs(s), :)', ...
        'color', c((round(steps.leg(leg).meta.(color)(idxs(s))/maxSpeed*(height(c)/2))+height(c)/2),:));hold on
end

colormap(c);

fig = formatFigPolar(fig, true);

cb = colorbar('XTick', [0,0.5,1], ...
    'XTickLabel',{['-' num2str(maxSpeed) ' (ccw)'], ['0 (' num2str(height(idxs)) ' steps)'], [num2str(maxSpeed) ' (cw)']});
cb.Label.String = 'Rotational velocity (mm/s)';
cb.Label.FontSize = 30;
cb.Color = param.baseColor;
cb.Box = 'off';

pax = gca;
pax.FontSize = 30;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
rticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
rtickangle(pax, 45);
thetaticks([0, 90, 180, 270]);
thetaticklabels({'0', '\pi/2', '\pi', '3\pi/4'});


hold off

%save 
fig_name = ['\' joint_data '_x_' phase_data '_' param.legs{leg} '_leg_coloredByRotationalSpeed - speed range x_below_' num2str(max_speed_x) ' y_below_' num2str(max_speed_y) ' z_above_' num2str(min_speed_z) ' - ' strrep(fly, '.', '_')];
% save_figure(fig, [param.googledrivesave fig_name], param.fileType);
save_figure(fig, [path fig_name], param.fileType);


clearvars('-except',initial_vars{:}); initial_vars = who;

%% PLOT AVG JOINT X PHASE, BINNED BY A VELOCITY - single fly 
%% Plot a joint x phase for all data of a fly, color by Foward speed
clearvars('-except',initial_vars{:}); initial_vars = who;

numSpeedBins = 3; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = false; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 5; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

fly = flyList.flyid{1};
leg = 1;
joint = 'FTi';
phase = 'FTi_phase';

max_speed_x = 3;
min_speed_y = 0; 
max_speed_z = 3;

color = 'avg_speed_y'; %var in steps.meta
idxs = find(strcmpi(steps.leg(leg).meta.fly, fly) & ...
                abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                    steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
            
%bin data
joint_data = steps.leg(leg).(joint)(idxs, :);
phase_data = steps.leg(leg).(phase)(idxs, :);
speed_data = steps.leg(leg).meta.(color)(idxs);
[bins,binEdges] = discretize(speed_data, numSpeedBins);

%phase bins to take averages in
numPhaseBins = 50;
binWidth = 2*pi/numPhaseBins;
phaseBins = -pi:binWidth:pi;
phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot

mean_joint_x_phase = NaN(numSpeedBins, numPhaseBins);
numTrials = zeros(numSpeedBins, numPhaseBins);
numSteps = zeros(numSpeedBins, 1);
for sb = 1:numSpeedBins
    %align steps by phase
    binned_joint_data = joint_data(bins == sb, :);
    binned_phase_data = phase_data(bins == sb, :);
    numSteps(sb) = height(binned_joint_data);
    for pb = 1:numPhaseBins
        %note: the way I average now could include multiple joint angles from a step within a phaseBin average
        mean_joint_x_phase(sb,pb) = mean(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
        numTrials(sb,pb) = height(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)));
    end
end

if tossSmallBins
    %if any speed bin has avg number of trials < 50, don't plot this data. 
    for sb = 1:numSpeedBins
        if mean(numTrials(sb,:)) < minAvgSteps
            mean_joint_x_phase(sb,:) = NaN; %'erase' these values so they aren't plotted
        end
    end
end


%colors for plotting speed binned averages
colors = jet(numSpeedBins); %order: slow to fast

%plot speed binned averages
fig = fullfig; 
cmap = colormap(colors);
for sb = 1:numSpeedBins
    polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
    
end

fig = formatFigPolar(fig, true);
c = colorbar();
ticks = (binEdges-min(binEdges))/max(binEdges-min(binEdges));
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1;  tickLabels{t} = num2str(binEdges(t)); 
    else; tickLabels{t} = [num2str(binEdges(t)) ' (' num2str(numSteps(t-1)) ' steps)']; end
end
c = colorbar('XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Forward velocity (mm/s)';
c.Label.FontSize = 30;
c.Color = param.baseColor;
c.Box = 'off';

pax = gca;
pax.FontSize = 30;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
rticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
rtickangle(pax, 45);
thetaticks([0, 90, 180, 270]);
thetaticklabels({'0', '\pi/2', '\pi', '3\pi/4'});

hold off

%save 
fig_name = ['\' joint '_x_' phase '_' param.legs{leg} '_leg_averages_binnedByForwardSpeed - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - ' strrep(fly, '.', '_')];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);


clearvars('-except',initial_vars{:}); initial_vars = who;



%% Plot a joint x phase for all data of a fly, color by Sideslip speed
clearvars('-except',initial_vars{:}); initial_vars = who;

numSpeedBins = 4; % should be an even number,otherwise will add one. 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 5; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

fly = flyList.flyid{1};
leg = 6;
joint = 'FTi';
phase = 'FTi_phase';

min_speed_x = 0;
max_speed_y = 10; 
max_speed_z = 10;

color = 'avg_speed_x'; %var in steps.meta
idxs = find(strcmpi(steps.leg(leg).meta.fly, fly) & ...
                    abs(steps.leg(leg).meta.avg_speed_x) > min_speed_x & ...
                    steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
                abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
            
%bin data
joint_data = steps.leg(leg).(joint)(idxs, :);
phase_data = steps.leg(leg).(phase)(idxs, :);
speed_data = steps.leg(leg).meta.(color)(idxs);

peakSpeed = ceil(max(abs(speed_data)));
if bitget(numSpeedBins,1); numSpeedBins = numSpeedBins+1; end %make num bins even 
binWidth = peakSpeed*2/numSpeedBins;
binEdges = peakSpeed*-1:binWidth:peakSpeed;
[bins,~] = discretize(speed_data, binEdges);

%phase bins to take averages in
numPhaseBins = 50;
binWidth = 2*pi/numPhaseBins;
phaseBins = -pi:binWidth:pi;
phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot

mean_joint_x_phase = NaN(numSpeedBins, numPhaseBins);
numTrials = zeros(numSpeedBins, numPhaseBins);
numSteps = zeros(numSpeedBins, 1);
for sb = 1:numSpeedBins
    %align steps by phase
    binned_joint_data = joint_data(bins == sb, :);
    binned_phase_data = phase_data(bins == sb, :);
    numSteps(sb) = height(binned_joint_data);
    for pb = 1:numPhaseBins
        %note: the way I average now could include multiple joint angles from a step within a phaseBin average
        mean_joint_x_phase(sb,pb) = mean(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
        numTrials(sb,pb) = height(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)));
    end
end

if tossSmallBins
    %if any speed bin has avg number of trials < 50, don't plot this data. 
    for sb = 1:numSpeedBins
        if mean(numTrials(sb,:)) < minAvgSteps
            mean_joint_x_phase(sb,:) = NaN; %'erase' these values so they aren't plotted
        end
    end
end

%plot speed binned averages
fig = fullfig; 
colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?
colormap(colors);
for sb = 1:numSpeedBins
    polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
    
end

fig = formatFigPolar(fig, true);
c = colorbar();
ticks = (binEdges-min(binEdges))/max(binEdges-min(binEdges));
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1;  tickLabels{t} = num2str(binEdges(t)); 
    else; tickLabels{t} = [num2str(binEdges(t)) ' (' num2str(numSteps(t-1)) ' steps)']; end
end
c = colorbar('XTick', ticks, 'XTickLabel',tickLabels);
c.Label.String = 'Sideslip velocity (mm/s)';
c.Label.FontSize = 30;
c.Color = param.baseColor;
c.Box = 'off';

pax = gca;
pax.FontSize = 30;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
rticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
rtickangle(pax, 45);
thetaticks([0, 90, 180, 270]);
thetaticklabels({'0', '\pi/2', '\pi', '3\pi/4'});

hold off

%save 
fig_name = ['\' joint '_x_' phase '_' param.legs{leg} '_leg_averages_binnedBySideslipSpeed - speed range x_above_' num2str(min_speed_x) ' y_below_' num2str(max_speed_y) ' z_below_' num2str(max_speed_z) ' - ' strrep(fly, '.', '_')];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);


clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot a joint x phase for all data of a fly, color by Rotational speed
clearvars('-except',initial_vars{:}); initial_vars = who;

numSpeedBins = 5; % should be an even number,otherwise will add one. 
tossSmallBins = false; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 5; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

fly = flyList.flyid{1};
leg = 6;
joint = 'FTi';
phase = 'FTi_phase';

max_speed_x = 10;
max_speed_y = 10; 
min_speed_z = 0;

color = 'avg_speed_z'; %var in steps.meta
idxs = find(strcmpi(steps.leg(leg).meta.fly, fly) & ...
                    abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                    steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
                abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
            
%bin data
joint_data = steps.leg(leg).(joint)(idxs, :);
phase_data = steps.leg(leg).(phase)(idxs, :);
speed_data = steps.leg(leg).meta.(color)(idxs);

peakSpeed = ceil(max(abs(speed_data)));
if bitget(numSpeedBins,1); numSpeedBins = numSpeedBins+1; end %make num bins even 
binWidth = peakSpeed*2/numSpeedBins;
binEdges = peakSpeed*-1:binWidth:peakSpeed;
[bins,~] = discretize(speed_data, binEdges);

%phase bins to take averages in
numPhaseBins = 50;
binWidth = 2*pi/numPhaseBins;
phaseBins = -pi:binWidth:pi;
phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot

mean_joint_x_phase = NaN(numSpeedBins, numPhaseBins);
numTrials = zeros(numSpeedBins, numPhaseBins);
numSteps = zeros(numSpeedBins, 1);
for sb = 1:numSpeedBins
    %align steps by phase
    binned_joint_data = joint_data(bins == sb, :);
    binned_phase_data = phase_data(bins == sb, :);
    numSteps(sb) = height(binned_joint_data);
    for pb = 1:numPhaseBins
        %note: the way I average now could include multiple joint angles from a step within a phaseBin average
        mean_joint_x_phase(sb,pb) = mean(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
        numTrials(sb,pb) = height(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)));
    end
end

if tossSmallBins
    %if any speed bin has avg number of trials < 50, don't plot this data. 
    for sb = 1:numSpeedBins
        if mean(numTrials(sb,:)) < minAvgSteps
            mean_joint_x_phase(sb,:) = NaN; %'erase' these values so they aren't plotted
        end
    end
end

%plot speed binned averages
fig = fullfig; 
colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?
colormap(colors);
for sb = 1:numSpeedBins
    polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
    
end

fig = formatFigPolar(fig, true);
c = colorbar();
ticks = (binEdges-min(binEdges))/max(binEdges-min(binEdges));
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1;  tickLabels{t} = num2str(binEdges(t)); 
    else; tickLabels{t} = [num2str(binEdges(t)) ' (' num2str(numSteps(t-1)) ' steps)']; end
end
c = colorbar('XTick', ticks, 'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.Label.FontSize = 30;
c.Color = param.baseColor;
c.Box = 'off';

pax = gca;
pax.FontSize = 30;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
rticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
rtickangle(pax, 45);
thetaticks([0, 90, 180, 270]);
thetaticklabels({'0', '\pi/2', '\pi', '3\pi/4'});

hold off

%save 
fig_name = ['\' joint '_x_' phase '_' param.legs{leg} '_leg_averages_binnedByRotationalSpeed - speed range x_below_' num2str(max_speed_x) ' y_below_' num2str(max_speed_y) ' z_above_' num2str(min_speed_z) ' - ' strrep(fly, '.', '_')];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);


clearvars('-except',initial_vars{:}); initial_vars = who;


%% %%% A1b: Looking across a population of flies, and 1D velocity directions. 

%% PLOT AVG JOINT X PHASE, BINNED BY A VELOCITY - all flies
%% Plot a joint x phase for all data of a fly, color by Foward speed
clearvars('-except',initial_vars{:}); initial_vars = who;

numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 10; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

leg = 1;
joint = 'FTi';
phase = 'FTi_phase';

max_speed_x = 3;
min_speed_y = 0; 
max_speed_z = 3;

color = 'avg_speed_y'; %var in steps.meta
idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
            abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
            
%bin data
joint_data = steps.leg(leg).(joint)(idxs, :);
phase_data = steps.leg(leg).(phase)(idxs, :);
speed_data = steps.leg(leg).meta.(color)(idxs);
[bins,binEdges] = discretize(speed_data, numSpeedBins);

%counting flies
fly_data = steps.leg(leg).meta.fly(idxs);
for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
%phase bins to take averages in
numPhaseBins = 50;
binWidth = 2*pi/numPhaseBins;
phaseBins = -pi:binWidth:pi;
phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot

mean_joint_x_phase = NaN(numSpeedBins, numPhaseBins);
numTrials = zeros(numSpeedBins, numPhaseBins);
numFlies = zeros(numSpeedBins, 1);
numSteps = zeros(numSpeedBins, 1);
for sb = 1:numSpeedBins
    %align steps by phase
    binned_joint_data = joint_data(bins == sb, :);
    binned_phase_data = phase_data(bins == sb, :);
    binned_fly_data = fly_data(bins == sb, :);
    
    numSteps(sb) = height(binned_joint_data);
    numFlies(sb) = height(unique(binned_fly_data));
    
    for pb = 1:numPhaseBins
        %note: the way I average now could include multiple joint angles from a step within a phaseBin average
        mean_joint_x_phase(sb,pb) = mean(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
        numTrials(sb,pb) = height(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)));
    end
end

if tossSmallBins
    %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
    for sb = 1:numSpeedBins
        if mean(numTrials(sb,:)) < minAvgSteps
            mean_joint_x_phase(sb,:) = NaN; %'erase' these values so they aren't plotted
        end
    end
end

%colors for plotting speed binned averages
colors = jet(numSpeedBins); %order: slow to fast

%plot speed binned averages
fig = fullfig; 
cmap = colormap(colors);
for sb = 1:numSpeedBins
    p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
end

fig = formatFigPolar(fig, true);
c = colorbar();
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1;  tickLabels{t} = num2str(binEdges(t)); 
    else; tickLabels{t} = [num2str(binEdges(t)) ' (' num2str(numSteps(t-1)) ' steps, ' num2str(numFlies(t-1)) ' flies)']; end
end
c = colorbar('XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Forward velocity (mm/s)';
c.Label.FontSize = 30;
c.Color = param.baseColor;
c.Box = 'off';

pax = gca;
pax.FontSize = 30;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
rticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
rtickangle(pax, 45);
thetaticks([0, 90, 180, 270]);
thetaticklabels({'0', '\pi/2', '\pi', '3\pi/4'});

hold off

%save 
fig_name = ['\' joint '_x_' phase '_' param.legs{leg} '_leg_averages_binnedByForwardSpeed - ' numSpeedBins '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot a joint x phase for all data of a fly, color by Sideslip speed
clearvars('-except',initial_vars{:}); initial_vars = who;

numSpeedBins = 30; % should be an even number,otherwise will add one. 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 40; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

leg = 1;
joint = 'FTi';
phase = 'FTi_phase';

min_speed_x = 0;
max_speed_y = 10; 
max_speed_z = 10;

color = 'avg_speed_x'; %var in steps.meta
idxs = find(abs(steps.leg(leg).meta.avg_speed_x) > min_speed_x & ...
                steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
            abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
            
%bin data
joint_data = steps.leg(leg).(joint)(idxs, :);
phase_data = steps.leg(leg).(phase)(idxs, :);
speed_data = steps.leg(leg).meta.(color)(idxs);

%counting flies
fly_data = steps.leg(leg).meta.fly(idxs);
for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

peakSpeed = ceil(max(abs(speed_data)));
if bitget(numSpeedBins,1); numSpeedBins = numSpeedBins+1; end %make num bins even 
binWidth = peakSpeed*2/numSpeedBins;
binEdges = peakSpeed*-1:binWidth:peakSpeed;
[bins,~] = discretize(speed_data, binEdges);

%phase bins to take averages in
numPhaseBins = 50;
binWidth = 2*pi/numPhaseBins;
phaseBins = -pi:binWidth:pi;
phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot

mean_joint_x_phase = NaN(numSpeedBins, numPhaseBins);
numTrials = zeros(numSpeedBins, numPhaseBins);
numFlies = zeros(numSpeedBins, 1);
numSteps = zeros(numSpeedBins, 1);
for sb = 1:numSpeedBins
    %align steps by phase
    binned_joint_data = joint_data(bins == sb, :);
    binned_phase_data = phase_data(bins == sb, :);
    binned_fly_data = fly_data(bins == sb, :);
    
    numSteps(sb) = height(binned_joint_data);
    numFlies(sb) = height(unique(binned_fly_data));
    
    for pb = 1:numPhaseBins
        %note: the way I average now could include multiple joint angles from a step within a phaseBin average
        mean_joint_x_phase(sb,pb) = mean(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
        numTrials(sb,pb) = height(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)));
    end
end

if tossSmallBins
    %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
    for sb = 1:numSpeedBins
        if mean(numTrials(sb,:)) < minAvgSteps
            mean_joint_x_phase(sb,:) = NaN; %'erase' these values so they aren't plotted
        end
    end
end


%plot speed binned averages
fig = fullfig; 

%colors for plotting speed binned averages
colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?
colormap(colors);
for sb = 1:numSpeedBins
    polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
end

fig = formatFigPolar(fig, true);
c = colorbar();
ticks = (binEdges-min(binEdges))/max(binEdges-min(binEdges));
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1;  tickLabels{t} = num2str(binEdges(t)); 
    else; tickLabels{t} = [num2str(binEdges(t)) ' (' num2str(numSteps(t-1)) ' steps, ' num2str(numFlies(t-1)) ' flies)']; end
end
c = colorbar('XTick', ticks, 'XTickLabel',tickLabels);
c.Label.String = 'Sideslip velocity (mm/s)';
c.Label.FontSize = 30;
c.Color = param.baseColor;
c.Box = 'off';

pax = gca;
pax.FontSize = 30;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
rticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
rtickangle(pax, 45);
thetaticks([0, 90, 180, 270]);
thetaticklabels({'0', '\pi/2', '\pi', '3\pi/4'});

hold off

%save 
fig_name = ['\' joint '_x_' phase '_' param.legs{leg} '_leg_averages_binnedBySideslipSpeed - speed range x_above_' num2str(min_speed_x) ' y_below_' num2str(max_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot a joint x phase for all data of a fly, color by Rotational speed
clearvars('-except',initial_vars{:}); initial_vars = who;

numSpeedBins = 30; % should be an even number,otherwise will add one. 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 50; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

leg = 1;
joint = 'FTi';
phase = 'FTi_phase';

max_speed_x = 10;
max_speed_y = 10; 
min_speed_z = 0;

color = 'avg_speed_z'; %var in steps.meta
idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
            abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
            
%bin data
joint_data = steps.leg(leg).(joint)(idxs, :);
phase_data = steps.leg(leg).(phase)(idxs, :);
speed_data = steps.leg(leg).meta.(color)(idxs);

%counting flies
fly_data = steps.leg(leg).meta.fly(idxs);
for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

peakSpeed = ceil(max(abs(speed_data)));
if bitget(numSpeedBins,1); numSpeedBins = numSpeedBins+1; end %make num bins even 
binWidth = peakSpeed*2/numSpeedBins;
binEdges = peakSpeed*-1:binWidth:peakSpeed;
[bins,~] = discretize(speed_data, binEdges);

%phase bins to take averages in
numPhaseBins = 50;
binWidth = 2*pi/numPhaseBins;
phaseBins = -pi:binWidth:pi;
phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot


mean_joint_x_phase = NaN(numSpeedBins, numPhaseBins);
numTrials = zeros(numSpeedBins, numPhaseBins);
numFlies = zeros(numSpeedBins, 1);
numSteps = zeros(numSpeedBins, 1);
for sb = 1:numSpeedBins
    %align steps by phase
    binned_joint_data = joint_data(bins == sb, :);
    binned_phase_data = phase_data(bins == sb, :);
    binned_fly_data = fly_data(bins == sb, :);
    
    numSteps(sb) = height(binned_joint_data);
    numFlies(sb) = height(unique(binned_fly_data));
    
    for pb = 1:numPhaseBins
        %note: the way I average now could include multiple joint angles from a step within a phaseBin average
        mean_joint_x_phase(sb,pb) = mean(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
        numTrials(sb,pb) = height(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)));
    end
end

if tossSmallBins
    %if any speed bin has avg number of trials < 50, don't plot this data. 
    for sb = 1:numSpeedBins
        if mean(numTrials(sb,:)) < minAvgSteps
            mean_joint_x_phase(sb,:) = NaN; %'erase' these values so they aren't plotted
        end
    end
end

%plot speed binned averages
fig = fullfig; 

%colors for plotting speed binned averages
colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?
colormap(colors);
for sb = 1:numSpeedBins
    polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
    
end

fig = formatFigPolar(fig, true);
c = colorbar();
ticks = (binEdges-min(binEdges))/max(binEdges-min(binEdges));
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1;  tickLabels{t} = num2str(binEdges(t)); 
    else; tickLabels{t} = [num2str(binEdges(t)) ' (' num2str(numSteps(t-1)) ' steps, ' num2str(numFlies(t-1)) ' flies)']; end
end
c = colorbar('XTick', ticks, 'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.Label.FontSize = 30;
c.Color = param.baseColor;
c.Box = 'off';

pax = gca;
pax.FontSize = 30;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
rticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
rtickangle(pax, 45);
thetaticks([0, 90, 180, 270]);
thetaticklabels({'0', '\pi/2', '\pi', '3\pi/4'});

hold off

%save 
fig_name = ['\' joint '_x_' phase '_' param.legs{leg} '_leg_averages_binnedByRotationalSpeed - speed range x_below_' num2str(max_speed_x) ' y_below_' num2str(max_speed_y) ' z_above_' num2str(min_speed_z) ' - allFlies'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% PLOT AVG JOINT X PHASE, BINNED BY A VELOCITY - all flies - all legs - graph coordinates
%% Plot a joint x phase for all data of a fly, color by Foward speed
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 10; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joint = 'FTi';
phase = 'FTi_phase';

max_speed_x = 3;
min_speed_y = 0; 
max_speed_z = 3;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    subplot(2,3,legOrder(leg)); 

    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                    steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);

    %bin data
    joint_data = steps.leg(leg).(joint)(idxs, :);
    phase_data = steps.leg(leg).(phase)(idxs, :);
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    %phase bins to take averages in
    numPhaseBins = 50;
    binWidth = 2*pi/numPhaseBins;
    phaseBins = -pi:binWidth:pi;
    phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot

    mean_joint_x_phase = NaN(numSpeedBins, numPhaseBins);
    numTrials = zeros(numSpeedBins, numPhaseBins);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_joint_data = joint_data(bins == sb, :);
        binned_phase_data = phase_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_joint_data);
        numFlies(sb) = height(unique(binned_fly_data));

        for pb = 1:numPhaseBins
            %note: the way I average now could include multiple joint angles from a step within a phaseBin average
            mean_joint_x_phase(sb,pb) = mean(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
            numTrials(sb,pb) = height(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)));
        end
    end

    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb,:)) < minAvgSteps
                mean_joint_x_phase(sb,:) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end

    %colors for plotting speed binned averages
    colors = jet(numSpeedBins); %order: slow to fast

    %plot speed binned averages
    cmap = colormap(colors);
    for sb = 1:numSpeedBins
%         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
        plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
    end

    
    ax = gca;
    ax.FontSize = 30;
    % ax.RColor = Color(param.baseColor);
    % ax.ThetaColor = Color(param.baseColor);
    % ylim([0 180])
    % yticks([0,45,90,135,180])
    % yticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
    xticks([-pi, 0, pi]);
    xticklabels({'-\pi','0', '\pi'});
    
    if leg == 1
        ylabel([joint ' (' char(176) ')']);
        xlabel(strrep(phase, '_', ' '));
    end
    title(param.legs{leg});
    hold off
end

fig = formatFig(fig, true, [2,3]); 

h = axes(fig,'visible','off'); 
% h.Title.Visible = 'on';
% h.XLabel.Visible = 'on';
% h.YLabel.Visible = 'on';
% ylabel(h,'yaxis','FontWeight','bold');
% xlabel(h,'xaxis','FontWeight','bold');
% title(h,'title');
% c = colorbar(h,'Position',[0.93 0.168 0.022 0.7]);  % attach colorbar to h
% colormap(c,'jet')
% caxis(h,[minColorLimit,maxColorLimit]);             % set colorbar limits

% 
% 
% 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    tickLabels{t} = num2str(binEdges(t)); 
end
c = colorbar(h,'Position',[0.92 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Forward velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        

hold off

%save 
fig_name = ['\' joint '_x_' phase '_allLegs_averages_binnedByForwardSpeed - ' numSpeedBins '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% TODO: Plot a joint x phase for all data of a fly, color by Sideslip speed
clearvars('-except',initial_vars{:}); initial_vars = who;

numSpeedBins = 30; % should be an even number,otherwise will add one. 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 40; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

color = 'avg_speed_x'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
% maxSpeed = 0;
% for leg = 1:param.numLegs
%     maxSpeed = max(maxSpeed, max(steps.leg(leg).meta.(color)));
% end
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    subplot(2,3,legOrder(leg)); 

    joint = 'FTi';
    phase = 'FTi_phase';

    min_speed_x = 0;
    max_speed_y = 10;  
    max_speed_z = 10;

    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) > min_speed_x & ...
                steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
            abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);

    %bin data 
    joint_data = steps.leg(leg).(joint)(idxs, :);
    phase_data = steps.leg(leg).(phase)(idxs, :);
    speed_data = steps.leg(leg).meta.(color)(idxs);
  
    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    peakSpeed = ceil(max(abs(speed_data)));
    if bitget(numSpeedBins,1); numSpeedBins = numSpeedBins+1; end %make num bins even 
    binWidth = peakSpeed*2/numSpeedBins;
    binEdges = peakSpeed*-1:binWidth:peakSpeed;
    [bins,~] = discretize(speed_data, binEdges);

    %phase bins to take averages in
    numPhaseBins = 50;
    binWidth = 2*pi/numPhaseBins;
    phaseBins = -pi:binWidth:pi;
    phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot

    mean_joint_x_phase = NaN(numSpeedBins, numPhaseBins);
    numTrials = zeros(numSpeedBins, numPhaseBins);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_joint_data = joint_data(bins == sb, :);
        binned_phase_data = phase_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_joint_data);
        numFlies(sb) = height(unique(binned_fly_data));

        for pb = 1:numPhaseBins
            %note: the way I average now could include multiple joint angles from a step within a phaseBin average
            mean_joint_x_phase(sb,pb) = mean(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
            numTrials(sb,pb) = height(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)));
        end
    end

    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb,:)) < minAvgSteps
                mean_joint_x_phase(sb,:) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end

    %colors for plotting speed binned averages
    colors = jet(numSpeedBins); %order: slow to fast

    %plot speed binned averages
    cmap = colormap(colors);
    for sb = 1:numSpeedBins
%         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
        plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
    end

    
    ax = gca;
    ax.FontSize = 30;
    % ax.RColor = Color(param.baseColor);
    % ax.ThetaColor = Color(param.baseColor);
    % ylim([0 180])
    % yticks([0,45,90,135,180])
    % yticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
    xticks([-pi, 0, pi]);
    xticklabels({'-\pi','0', '\pi'});
    
    if leg == 1
        ylabel([joint ' (' char(176) ')']);
        xlabel(strrep(phase, '_', ' '));
    end
    title(param.legs{leg});
    hold off
end

fig = formatFig(fig, true, [2,3]); 

h = axes(fig,'visible','off'); 
% h.Title.Visible = 'on';
% h.XLabel.Visible = 'on';
% h.YLabel.Visible = 'on';
% ylabel(h,'yaxis','FontWeight','bold');
% xlabel(h,'xaxis','FontWeight','bold');
% title(h,'title');
% c = colorbar(h,'Position',[0.93 0.168 0.022 0.7]);  % attach colorbar to h
% colormap(c,'jet')
% caxis(h,[minColorLimit,maxColorLimit]);             % set colorbar limits

% 
% 
% 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    tickLabels{t} = num2str(binEdges(t)); 
end
c = colorbar(h,'Position',[0.92 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Forward velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        

hold off

%save 
fig_name = ['\' joint '_x_' phase '_allLegs_averages_binnedByForwardSpeed - ' numSpeedBins '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% TODO: Plot a joint x phase for all data of a fly, color by Rotational speed
clearvars('-except',initial_vars{:}); initial_vars = who;

numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 50; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
% maxSpeed = 0;
% for leg = 1:param.numLegs
%     maxSpeed = max(maxSpeed, max(steps.leg(leg).meta.(color)));
% end
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    subplot(2,3,legOrder(leg)); 

    joint = 'FTi';
    phase = 'FTi_phase';

    max_speed_x = 3;
    min_speed_y = 0; 
    max_speed_z = 3;

    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                    steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);

    %bin data
    joint_data = steps.leg(leg).(joint)(idxs, :);
    phase_data = steps.leg(leg).(phase)(idxs, :);
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    %phase bins to take averages in
    numPhaseBins = 50;
    binWidth = 2*pi/numPhaseBins;
    phaseBins = -pi:binWidth:pi;
    phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot

    mean_joint_x_phase = NaN(numSpeedBins, numPhaseBins);
    numTrials = zeros(numSpeedBins, numPhaseBins);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_joint_data = joint_data(bins == sb, :);
        binned_phase_data = phase_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_joint_data);
        numFlies(sb) = height(unique(binned_fly_data));

        for pb = 1:numPhaseBins
            %note: the way I average now could include multiple joint angles from a step within a phaseBin average
            mean_joint_x_phase(sb,pb) = mean(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
            numTrials(sb,pb) = height(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)));
        end
    end

    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb,:)) < minAvgSteps
                mean_joint_x_phase(sb,:) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end

    %colors for plotting speed binned averages
    colors = jet(numSpeedBins); %order: slow to fast

    %plot speed binned averages
    cmap = colormap(colors);
    for sb = 1:numSpeedBins
%         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
        plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
    end

    
    ax = gca;
    ax.FontSize = 30;
    % ax.RColor = Color(param.baseColor);
    % ax.ThetaColor = Color(param.baseColor);
    % ylim([0 180])
    % yticks([0,45,90,135,180])
    % yticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
    xticks([-pi, 0, pi]);
    xticklabels({'-\pi','0', '\pi'});
    
    if leg == 1
        ylabel([joint ' (' char(176) ')']);
        xlabel(strrep(phase, '_', ' '));
    end
    title(param.legs{leg});
    hold off
end

fig = formatFig(fig, true, [2,3]); 

h = axes(fig,'visible','off'); 
% h.Title.Visible = 'on';
% h.XLabel.Visible = 'on';
% h.YLabel.Visible = 'on';
% ylabel(h,'yaxis','FontWeight','bold');
% xlabel(h,'xaxis','FontWeight','bold');
% title(h,'title');
% c = colorbar(h,'Position',[0.93 0.168 0.022 0.7]);  % attach colorbar to h
% colormap(c,'jet')
% caxis(h,[minColorLimit,maxColorLimit]);             % set colorbar limits

% 
% 
% 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    tickLabels{t} = num2str(binEdges(t)); 
end
c = colorbar(h,'Position',[0.92 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Forward velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        

hold off

%save 
fig_name = ['\' joint '_x_' phase '_allLegs_averages_binnedByForwardSpeed - ' numSpeedBins '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% TODO %%% A1c: Looking at one fly, and 3D velocity directions. 
%% TODO %%% A1d: Looking across a population of flies, and 3D velocity directions. 

%% Q2: Do joint angles become more stereotyped across the step cycle as velocity increases?
%% %%% A2a: Looking across a population of flies, and 1D velocity directions. 

%% Plot a joint x phase for all data of a fly, color by Foward speed - w/ speed binned jnt variance @ chosen phase
clearvars('-except',initial_vars{:}); initial_vars = who;

numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 50; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

phases = [0]; %(radians), phase(s) to plot speed-binned variances of
phaseBinWidth = deg2rad(2); %how wide to make bin(s) (centered at phases)
numJointBins = 20; %number of bins for joint histogram at phases

leg = 1;
joint = 'FTi';
phase = 'FTi_phase';

max_speed_x = 3;
min_speed_y = 0; 
max_speed_z = 3;

color = 'avg_speed_y'; %var in steps.meta
idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
            abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
            
%bin data
joint_data = steps.leg(leg).(joint)(idxs, :);
phase_data = steps.leg(leg).(phase)(idxs, :);
speed_data = steps.leg(leg).meta.(color)(idxs);
[bins,binEdges] = discretize(speed_data, numSpeedBins);

%counting flies
fly_data = steps.leg(leg).meta.fly(idxs);
for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
%phase bins to take averages in
numPhaseBins = 50;
binWidth = 2*pi/numPhaseBins;
phaseBins = -pi:binWidth:pi;
phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot

mean_joint_x_phase = NaN(numSpeedBins, numPhaseBins);
numTrials = zeros(numSpeedBins, numPhaseBins);
numFlies = zeros(numSpeedBins, 1);
numSteps = zeros(numSpeedBins, 1);
for sb = 1:numSpeedBins
    %align steps by phase
    binned_joint_data = joint_data(bins == sb, :);
    binned_phase_data = phase_data(bins == sb, :);
    binned_fly_data = fly_data(bins == sb, :);
    
    numSteps(sb) = height(binned_joint_data);
    numFlies(sb) = height(unique(binned_fly_data));
    
    for pb = 1:numPhaseBins
        %note: the way I average now could include multiple joint angles from a step within a phaseBin average
        mean_joint_x_phase(sb,pb) = mean(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
        numTrials(sb,pb) = height(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)));
    end
end

tossedBins = [];
if tossSmallBins
    %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
    for sb = 1:numSpeedBins
        if mean(numTrials(sb,:)) < minAvgSteps
            mean_joint_x_phase(sb,:) = NaN; %'erase' these values so they aren't plotted
            tossedBins = [tossedBins, sb];
        end
    end
end

%colors for plotting speed binned averages
colors = jet(numSpeedBins); %order: slow to fast

%plot speed binned averages
fig = fullfig; 
cmap = colormap(colors);
for sb = 1:numSpeedBins
    p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
end

fig = formatFigPolar(fig, true);
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1;  tickLabels{t} = num2str(binEdges(t)); 
    else; tickLabels{t} = [num2str(binEdges(t)) ' (' num2str(numSteps(t-1)) ' steps, ' num2str(numFlies(t-1)) ' flies)']; end
end
c = colorbar('XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Forward velocity (mm/s)';
c.Label.FontSize = 30;
c.Color = param.baseColor;
c.Box = 'off';

pax = gca;
pax.FontSize = 30;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
rticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
rtickangle(pax, 45);
thetaticks([0, 90, 180, 270]);
thetaticklabels({'0', '\pi/2', '\pi', '3\pi/4'});

hold off

%save 
fig_name = ['\' joint '_x_' phase '_' param.legs{leg} '_leg_averages_binnedByForwardSpeed - ' numSpeedBins '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);


%now plot the speed-binned phase variance plots 
for ph = 1:width(phases)
    
    fig = fullfig; hold on;
    for sb = 1:numSpeedBins
        if ~ismember(tossedBins, sb)
            speed_idxs = find(bins == sb);
            speed_ph_data = phase_data(speed_idxs,:);
            speed_jnt_data = joint_data(speed_idxs,:);

            ph_joint_data = speed_jnt_data(speed_ph_data < phases(ph)+(phaseBinWidth/2) & speed_ph_data >= phases(ph)-(phaseBinWidth/2));
 
%             histogram(ph_joint_data, numJointBins, 'FaceColor', colors(sb,:), 'Normalization', 'pdf');
            h = histfit(ph_joint_data, numJointBins);
            h(1).Visible = 'off'; %don't plot histogram
            h(2).Color = colors(sb,:);%color distribution fit line 


        end
    end
    hold off;
    fig = formatFig(fig, true);
    
    cmap = colormap(colors);
    c = colorbar('XTick', ticks, ...
        'XTickLabel',tickLabels);
    c.Label.String = 'Forward velocity (mm/s)';
    c.Label.FontSize = 30;
    c.Color = param.baseColor;
    c.Box = 'off';
    
    title(['Phase = ' num2str(phases(ph))], 'Color', 'w', 'FontSize', 30);
    xlabel([param.legs{leg} ' ' joint ' angle (' char(176)  ')'], 'FontSize', 20);

    %save
    fig_name = ['\' joint '_x_' phase '_' param.legs{leg} '_leg_variance@phase' num2str(phases(ph)) '_phaseBinWidth' num2str(phaseBinWidth) '_binnedByForwardSpeed - ' numSpeedBins '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies'];
    if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
    save_figure(fig, [param.googledrivesave fig_name], param.fileType);
end

clearvars('-except',initial_vars{:}); initial_vars = who;

%% %%%%%%%%%%%%%%%%TESTING PLOTTING: plot joint x phase in polar coords no rho range limit
clearvars('-except',initial_vars{:}); initial_vars = who;

numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 50; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

phases = [0]; %(radians), phase(s) to plot speed-binned variances of
phaseBinWidth = deg2rad(2); %how wide to make bin(s) (centered at phases)
numJointBins = 20; %number of bins for joint histogram at phases

leg = 1;
joint = 'FTi';
phase = 'FTi_phase';

max_speed_x = 3;
min_speed_y = 0; 
max_speed_z = 3;

color = 'avg_speed_y'; %var in steps.meta
idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
            abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
            
%bin data
joint_data = steps.leg(leg).(joint)(idxs, :);
phase_data = steps.leg(leg).(phase)(idxs, :);
speed_data = steps.leg(leg).meta.(color)(idxs);
[bins,binEdges] = discretize(speed_data, numSpeedBins);

%counting flies
fly_data = steps.leg(leg).meta.fly(idxs);
for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
%phase bins to take averages in
numPhaseBins = 50;
binWidth = 2*pi/numPhaseBins;
phaseBins = -pi:binWidth:pi;
phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot

mean_joint_x_phase = NaN(numSpeedBins, numPhaseBins);
numTrials = zeros(numSpeedBins, numPhaseBins);
numFlies = zeros(numSpeedBins, 1);
numSteps = zeros(numSpeedBins, 1);
for sb = 1:numSpeedBins
    %align steps by phase
    binned_joint_data = joint_data(bins == sb, :);
    binned_phase_data = phase_data(bins == sb, :);
    binned_fly_data = fly_data(bins == sb, :);
    
    numSteps(sb) = height(binned_joint_data);
    numFlies(sb) = height(unique(binned_fly_data));
    
    for pb = 1:numPhaseBins
        %note: the way I average now could include multiple joint angles from a step within a phaseBin average
        mean_joint_x_phase(sb,pb) = mean(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
        numTrials(sb,pb) = height(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)));
    end
end

tossedBins = [];
if tossSmallBins
    %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
    for sb = 1:numSpeedBins
        if mean(numTrials(sb,:)) < minAvgSteps
            mean_joint_x_phase(sb,:) = NaN; %'erase' these values so they aren't plotted
            tossedBins = [tossedBins, sb];
        end
    end
end

%colors for plotting speed binned averages
colors = jet(numSpeedBins); %order: slow to fast

%plot speed binned averages
fig = fullfig; 
cmap = colormap(colors);
for sb = 1:numSpeedBins
    p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
end

fig = formatFigPolar(fig, true);
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1;  tickLabels{t} = num2str(binEdges(t)); 
    else; tickLabels{t} = [num2str(binEdges(t)) ' (' num2str(numSteps(t-1)) ' steps, ' num2str(numFlies(t-1)) ' flies)']; end
end
c = colorbar('XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Forward velocity (mm/s)';
c.Label.FontSize = 30;
c.Color = param.baseColor;
c.Box = 'off';

pax = gca;
pax.FontSize = 30;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
% rlim([0 180])
% rticks([0,45,90,135,180])
% rticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
rtickangle(pax, 45);
thetaticks([0, 90, 180, 270]);
thetaticklabels({'0', '\pi/2', '\pi', '3\pi/4'});

hold off

%save 
fig_name = ['\' joint '_x_' phase '_' param.legs{leg} '_leg_averages_binnedByForwardSpeed - ' numSpeedBins '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);


%now plot the speed-binned phase variance plots 
for ph = 1:width(phases)
    
    fig = fullfig; hold on;
    for sb = 1:numSpeedBins
        if ~ismember(tossedBins, sb)
            speed_idxs = find(bins == sb);
            speed_ph_data = phase_data(speed_idxs,:);
            speed_jnt_data = joint_data(speed_idxs,:);

            ph_joint_data = speed_jnt_data(speed_ph_data < phases(ph)+(phaseBinWidth/2) & speed_ph_data >= phases(ph)-(phaseBinWidth/2));
             
            histogram(ph_joint_data, numJointBins, 'FaceColor', colors(sb,:), 'EdgeColor', colors(sb,:), 'Normalization', 'pdf');

%             histogram(ph_joint_data, numJointBins, 'EdgeColor', colors(sb,:), 'Normalization', 'pdf', 'DisplayStyle', 'stairs');
%             h = histfit(ph_joint_data, numJointBins, 'kernel');
%             h(1).Visible = 'off'; %don't plot histogram
%             h(2).Color = colors(sb,:);%color distribution fit line 

% 
%             [counts, edges] = histcounts(ph_joint_data, numJointBins);
%             locs = movmean(edges, 2, 'Endpoints', 'discard');
%             plot(locs, counts, 'LineWidth', 3, 'Color', colors(sb,:));


        end
    end
    hold off;
    fig = formatFig(fig, true);
    
    cmap = colormap(colors);
    c = colorbar('XTick', ticks, ...
        'XTickLabel',tickLabels);
    c.Label.String = 'Forward velocity (mm/s)';
    c.Label.FontSize = 30;
    c.Color = param.baseColor;
    c.Box = 'off';
    
    title(['Phase = ' num2str(phases(ph))], 'Color', 'w', 'FontSize', 30);
    xlabel([param.legs{leg} ' ' joint ' angle (' char(176)  ')'], 'FontSize', 20);

    %save
    fig_name = ['\' joint '_x_' phase '_' param.legs{leg} '_leg_variance@phase' num2str(phases(ph)) '_phaseBinWidth' num2str(phaseBinWidth) '_binnedByForwardSpeed - ' numSpeedBins '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies'];
    if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
    save_figure(fig, [param.googledrivesave fig_name], param.fileType);
end

clearvars('-except',initial_vars{:}); initial_vars = who;

%% %%%%%%%%%%%%%%%%TESTING PLOTTING: plot joint x phase in graph coords. 
clearvars('-except',initial_vars{:}); initial_vars = who;

numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 50; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

phases = [0]; %(radians), phase(s) to plot speed-binned variances of
phaseBinWidth = deg2rad(2); %how wide to make bin(s) (centered at phases)
numJointBins = 20; %number of bins for joint histogram at phases

leg = 1;
joint = 'FTi';
phase = 'E_y_phase';

max_speed_x = 3;
min_speed_y = 0; 
max_speed_z = 3;

color = 'avg_speed_y'; %var in steps.meta
idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
            abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
            
%bin data
joint_data = steps.leg(leg).(joint)(idxs, :);
phase_data = steps.leg(leg).(phase)(idxs, :);
speed_data = steps.leg(leg).meta.(color)(idxs);
[bins,binEdges] = discretize(speed_data, numSpeedBins);

%counting flies
fly_data = steps.leg(leg).meta.fly(idxs);
for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
%phase bins to take averages in
numPhaseBins = 50;
binWidth = 2*pi/numPhaseBins;
phaseBins = -pi:binWidth:pi;
phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot

mean_joint_x_phase = NaN(numSpeedBins, numPhaseBins);
numTrials = zeros(numSpeedBins, numPhaseBins);
numFlies = zeros(numSpeedBins, 1);
numSteps = zeros(numSpeedBins, 1);
for sb = 1:numSpeedBins
    %align steps by phase
    binned_joint_data = joint_data(bins == sb, :);
    binned_phase_data = phase_data(bins == sb, :);
    binned_fly_data = fly_data(bins == sb, :);
    
    numSteps(sb) = height(binned_joint_data);
    numFlies(sb) = height(unique(binned_fly_data));
    
    for pb = 1:numPhaseBins
        %note: the way I average now could include multiple joint angles from a step within a phaseBin average
        mean_joint_x_phase(sb,pb) = mean(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
        numTrials(sb,pb) = height(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)));
    end
end

tossedBins = [];
if tossSmallBins
    %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
    for sb = 1:numSpeedBins
        if mean(numTrials(sb,:)) < minAvgSteps
            mean_joint_x_phase(sb,:) = NaN; %'erase' these values so they aren't plotted
            tossedBins = [tossedBins, sb];
        end
    end
end

%colors for plotting speed binned averages
colors = jet(numSpeedBins); %order: slow to fast

%plot speed binned averages
fig = fullfig; 
cmap = colormap(colors);
for sb = 1:numSpeedBins
%     p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
    plot(rad2deg(phaseBinCenters), smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2); hold on

end

fig = formatFig(fig, true);
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1;  tickLabels{t} = num2str(binEdges(t)); 
    else; tickLabels{t} = [num2str(binEdges(t)) ' (' num2str(numSteps(t-1)) ' steps, ' num2str(numFlies(t-1)) ' flies)']; end
end
c = colorbar('XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Forward velocity (mm/s)';
c.Label.FontSize = 30;
c.Color = param.baseColor;
c.Box = 'off';

ax = gca;
ax.FontSize = 30;
% ax.RColor = Color(param.baseColor);
% ax.ThetaColor = Color(param.baseColor);
% ylim([0 180])
% yticks([0,45,90,135,180])
% yticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
xticks([-180, -90, 0, 90, 180]);
xticklabels({'-\pi', '-\pi/2','0', '\pi/2', '\pi'});
xlim([-180 180]);

ylabel([param.legs{leg} ' ' joint ' (' char(176) ')']);
xlabel(strrep(phase, '_', ' '));

hold off

%save 
fig_name = ['\' joint '_x_' phase '_' param.legs{leg} '_leg_averages_binnedByForwardSpeed - ' numSpeedBins '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;















%% 








%% Overview: all legs, all joints, all flies, avg joint angle x phase binned by fwd vel
clearvars('-except',initial_vars{:}); initial_vars = who;





%clearvars('-except',initial_vars{:}); initial_vars = who;








