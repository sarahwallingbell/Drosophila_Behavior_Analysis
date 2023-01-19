% Lab Meeting July 2022 Code, updated throught hte fall 2022: WT Berlin data - walking intro and walking x speed

%% Load % orgnaize the data 
clear all; close all; clc;

% Select and load parquet file (the fly data)
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

%add stim regions to data
data = addStimRegions(data);

%fix anipose joint data output
data = fixAniposeJointOutput(data, param, flyList); 

%save walking data 
walkingData = data(~isnan(data.walking_bout_number),:); 

%fix fictrac output
[data, walkingData] = fixFictracOutput(data, walkingData, flyList); 

%parse walking bouts and find swing stance
% boutMap = boutMap_with_swing_stance(walkingData,param);
clear boutMap
boutMap = boutMap(walkingData,param); 

%parse steps and step metrics
clear steps
steps = steps(boutMap, walkingData, param);

% Organize data for plotting 
joint_data = DLC_org_joint_data(data, param);
joint_data_byFly = DLC_org_joint_data_byFly(data, param);

% Get behaviors of each fly 
param.thresh = 0.1; %0.5; %thres hold for behavior prediction 
behavior = DLC_behavior_predictor(data, param); 
behavior_byBout = DLC_behavior_predictor_byBoutNum (data, param);

initial_vars = who; 


%% %%%%%%%% Walking Overview %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% All joint angles over time for a walking bout 
clearvars('-except',initial_vars{:}); initial_vars = who;

%param:
bout = 6; %row num in boutMap

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

idxs = boutMap.walkingDataIdxs{bout};

%plot
fig = fullfig; hold on 
plot(walkingData.L1A_flex(idxs), 'linewidth', 2, 'color', Color(param.jointColors{1}));
plot(walkingData.L1B_flex(idxs), 'linewidth', 2, 'color', Color(param.jointColors{2}));
plot(walkingData.L1C_flex(idxs), 'linewidth', 2, 'color', Color(param.jointColors{3}));
plot(walkingData.L1D_flex(idxs), 'linewidth', 2, 'color', Color(param.jointColors{4}));
hold off

fig = formatFig(fig, true);

%legend
l = legend({'L1 body-coxa angle', 'L1 coxa-femur angle', 'L1 femur-tibia angle', 'L1 tibia-tarsus angle'});
l.Location = 'bestoutside';
l.TextColor = 'white';
l.FontSize = 20;

ax=gca;
ax.FontSize = 20;

ylabel(['Angle (' char(176) ')'], 'FontSize', 30);
xlabel('Time (frames)', 'FontSize', 30);

%save 
fig_name = ['\L1_joint_angles_walking_bout_' num2str(bout)];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% All joint angles all legs over time for a walking bout 
clearvars('-except',initial_vars{:}); initial_vars = who;

%param:
bout = 69; %row num in boutMap

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

idxs = boutMap.walkingDataIdxs{bout};

%plot
order = [4,5,6,1,2,3];
fig = fullfig; hold on 
for leg = 1:param.numLegs
    subplot(2,3,order(leg)); hold on;
    for joint = 1:param.numJoints
        plot(walkingData.([param.legs{leg} '' param.jointLetters{joint} '_flex'])(idxs), 'linewidth', 2, 'color', Color(param.jointColors{joint})); 
    end
    title(param.legs{leg}, 'FontSize', 30);
    ax=gca;
    ax.FontSize = 20;
    xlim('tight');
    hold off
end

fig = formatFig(fig, true, [2 3]);

%legend
l = legend({'BC', 'CF', 'FTi', 'TiTa'});
l.Location = 'best';
l.TextColor = 'white';
l.FontSize = 20;

ax=gca;
ax.FontSize = 20;

ylabel(['Angle (' char(176) ')'], 'FontSize', 30);
xlabel('Time (frames)', 'FontSize', 30);

%save 
fig_name = ['\L1_joint_angles_walking_bout_' num2str(bout)];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% All joint abduction and rotations all legs over time for a walking bout 
clearvars('-except',initial_vars{:}); initial_vars = who;

%param:
bout = 72; %row num in boutMap

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

idxs = boutMap.walkingDataIdxs{bout};

%plot
order = [4,5,6,1,2,3];
jointType = {'A_abduct', 'A_rot_unwrapped', 'B_rot_unwrapped', 'C_rot_unwrapped'};
fig = fullfig; hold on 
for leg = 1:param.numLegs
    subplot(2,3,order(leg)); hold on;
    for joint = 1:width(jointType)
        if joint == 1 %abduct, plot raw
            plot(walkingData.([param.legs{leg} '' jointType{joint}])(idxs), 'linewidth', 2, 'color', Color(param.jointColors{joint})); 
        else %rotation, plot diff
            plot(diff(walkingData.([param.legs{leg} '' jointType{joint}])(idxs)), 'linewidth', 2, 'color', Color(param.jointColors{joint})); 
        end
    end
    title(param.legs{leg});
    ax=gca;
    ax.FontSize = 20;
    xlim('tight');
    hold off
end

fig = formatFig(fig, true, [2 3]);

%legend
l = legend(strrep(jointType, '_', ' '));
l.Location = 'best';
l.TextColor = 'white';
l.FontSize = 20;

ax=gca;
ax.FontSize = 20;

ylabel(['Angle (' char(176) ')'], 'FontSize', 30);
xlabel('Time (frames)', 'FontSize', 30);

%save 
fig_name = ['\L1_joint_angles_walking_bout_' num2str(bout)];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% B & C joint rotations all legs over time for a walking bout 
clearvars('-except',initial_vars{:}); initial_vars = who;

%param:
bout = 1; %6; %row num in boutMap

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

idxs = boutMap.walkingDataIdxs{bout};

%plot
order = [4,5,6,1,2,3];
jointType = {'B_rot', 'C_rot'};
fig = fullfig; hold on 
for leg = 1:param.numLegs
    subplot(2,3,order(leg)); hold on;
    for joint = 1:width(jointType)
        %rotation, plot diff
        plot(diff(walkingData.([param.legs{leg} '' jointType{joint}])(idxs)), 'linewidth', 2, 'color', Color(param.jointColors{joint})); 
    end
    title(param.legs{leg});
    ax=gca;
    ax.FontSize = 20;
    xlim('tight');
    hold off
end

fig = formatFig(fig, true, [2 3]);

%legend
l = legend(strrep(jointType, '_', ' '));
l.Location = 'best';
l.TextColor = 'white';
l.FontSize = 20;

ax=gca;
ax.FontSize = 20;

ylabel(['Angle (' char(176) ')'], 'FontSize', 30);
xlabel('Time (frames)', 'FontSize', 30);

%save 
fig_name = ['\L1_joint_angles_walking_bout_' num2str(bout)];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% 3D joint traces across phase avg 

%params
colorPhase = false; %true colors by phase, false colors by leg/joint
connected = false; %true plots les, false plots joints

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for leg = 1:param.numLegs; idxs{leg} = {1:height(steps.leg(leg).meta)}; end
legs = {'L1','L2','L3', 'R1','R2','R3'};
joints = {'A','B','C','D','E'};
Plot_joint_trajectories_avg_step(steps, idxs, walkingData, legs, joints, connected, param, colorPhase);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% %%%%%%%% Walking x Forward Velocity %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 
% ANGLES
%% MEAN single Joint x Phase, all legs, across flies, color by Foward speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %5; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %10; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joint = 'FTi';
% phase = 'FTi_phase';
phase = 'E_y_phase';


max_speed_x = 3;
min_speed_y = 10; %3; 
max_speed_z = 3;

numPhaseBins = 20; %50;

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
%         plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
        plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
    end

    
    ax = gca;
    ax.FontSize = 30;
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
fig_name = ['\' joint '_x_' phase '_allLegs_averages_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% MEAN Joint x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 10; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                        steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                    abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
            ylabel([joints{joint} ' (' char(176) ')']);

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
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
fig_name = ['\all_joints_x_leg_phase_allLegs_averages_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;



%% MEAN Joint x Phase, all joints, all legs, single fly, color by Foward speed - cartesian coordinates 
clearvars('-except',initial_vars{:}); initial_vars = who;

flyNum = 2; %adjust this 
fly = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 
fullfly = flyList.flyid{flyNum};

%params
numSpeedBins = 10; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 20; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(contains(steps.leg(leg).meta.fly, fly) & ...
                     abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                         steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                     abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on

        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
            ylabel([joints{joint} ' (' char(176) ')']);

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
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
fig_name = ['\all_joints_x_leg_phase_allLegs_averages_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - ' fullfly ' - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;






%% MEAN NORMED Joint x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates
% angle difference from average across speeds. 

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                        steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                    abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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

        %calculate average step, across speed bins, for this joint
        avg_step = NaN(1,numPhaseBins);
        for pb = 1:numPhaseBins
            avg_step(pb) = mean(joint_data(phase_data >= phaseBins(pb) & phase_data < phaseBins(pb+1)), 'omitnan');
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
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)-avg_step), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, (mean_joint_x_phase(sb,:)-avg_step), 'color', colors(sb,:), 'linewidth', 2);hold on
        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
            ylabel(['\Delta' joints{joint} ' (' char(176) ')']);

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
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
fig_name = ['\all_joints_x_leg_phase_allLegs_averagesNormedByAvgStep_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% STD Joint x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                        steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                    abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
        binWidth = 2*pi/numPhaseBins;
        phaseBins = -pi:binWidth:pi;
        phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot
    
        std_joint_x_phase = NaN(numSpeedBins, numPhaseBins);
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
                std_joint_x_phase(sb,pb) = std(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
                numTrials(sb,pb) = height(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)));
            end
        end
    
        if tossSmallBins
            %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
            for sb = 1:numSpeedBins
                if mean(numTrials(sb,:)) < minAvgSteps
                    std_joint_x_phase(sb,:) = NaN; %'erase' these values so they aren't plotted
                end
            end
        end
    
        %colors for plotting speed binned averages
        colors = jet(numSpeedBins); %order: slow to fast
    
        %plot speed binned averages
        cmap = colormap(colors);
        for sb = 1:numSpeedBins
    %         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth(std_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, std_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
            ylabel([joints{joint} ' (' char(176) ')']);

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
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
fig_name = ['\all_joints_x_leg_phase_allLegs_averageStandardDeviations_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;










%% VELOCITY of Joint x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                        steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                    abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);

        %take derivative of data to get velocity 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth([diff(mean_joint_x_phase(sb,:)), NaN]), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth([diff(mean_joint_x_phase(sb,:)/(1/param.fps)), NaN]), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, [diff(mean_joint_x_phase(sb,:)), NaN], 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on

        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
            ylabel([joints{joint} ' (' char(176) '/s)']);

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
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
fig_name = ['\all_joints_x_leg_phase_allLegs_averageAngleVelocity_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% ACCELERATION of Joint x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                        steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                    abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);

        %take derivative of data to get velocity 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
        %take derivative of data to get acceleration 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth([diff(mean_joint_x_phase(sb,:)), NaN]), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters(1:end-2), smooth([diff(velocity/(1/param.fps))]), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, [diff(mean_joint_x_phase(sb,:)), NaN], 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on


        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
            ylabel([joints{joint} ' (' char(176) '/s^2)']);

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
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
fig_name = ['\all_joints_x_leg_phase_allLegs_averageAngleAcceleration_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% JERK of Joint x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                        steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                    abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);

        %take derivative of data to get velocity 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
        %take derivative of data to get acceleration 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
        %take derivative of data to get jerk 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];

        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth([diff(mean_joint_x_phase(sb,:)), NaN]), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters(1:end-2), smooth([diff(velocity/(1/param.fps))]), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, [diff(mean_joint_x_phase(sb,:)), NaN], 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on


        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
            ylabel([joints{joint} ' (' char(176) '/s^3)']);

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
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
fig_name = ['\all_joints_x_leg_phase_allLegs_averageAngleJerk_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% 
% ABDUCTION & ROTATIONS
%% MEAN of Joint Rotation & Abduction x Phase, all joints, all legs, across flies, color by Foward speed - polar & cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numJoints = width(joints);

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19, 2,8,14,20, 3,9,15,21, 4,10,16,22, 5,11,17,23, 6,12,18,24];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                    steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    for joint = 1:numJoints
        i = i+1;
        subplot(numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            if contains(joints{joint}, 'rot')
                polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
            else
                plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2); hold on
            end
        end

        %limit rho for polar plots so negative values get plotted correctly
        %and data is as large as possible
        if contains(joints{joint}, 'rot')
            rmin = min(min(mean_joint_x_phase(:,:)));
            rmax = max(max(mean_joint_x_phase(:,:)));
            rlim([rmin rmax]);
        end
    
        if contains(joints{joint}, 'rot')
            pax = gca;
            % pax.FontSize = 30;
            pax.RColor = Color(param.baseColor);
            pax.ThetaColor = Color(param.baseColor);
            % rlim([0 180])
            % rticks([0,45,90,135,180])
            % rticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
            rtickangle(pax, 45);
            thetaticks([0, 90, 180, 270]);
            thetaticklabels({'0', '\pi/2', '\pi', '3\pi/4'});
        else
            ax = gca;
            ax.FontSize = 20;
            xticks([-pi, 0, pi]);
            xticklabels({'-\pi','0', '\pi'});
        end

        if joint == 1 & leg == 1
            title([param.legs{leg} ' ' strrep(joints{joint}, '_', ' ')]);
        elseif joint == 1 & leg > 1
            title([param.legs{leg}]);
        elseif leg == 1
            title(strrep(joints{joint}, '_', ' '));
        end

        if leg == 1
            %TODO label the joint 
        end
        
        if contains(joints{joint}, 'rot')
            fig = formatFigPolar(fig, true);
        else
            fig = formatFig(fig, true);
        end



        hold off
    end
end

% fig = formatFigPolar(fig, true, [numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
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
fig_name = ['\all_joints_x_leg_phase_allLegs_rotation&abduction_averages_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - polarCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% MEAN NORMED of Joint Rotation & Abduction x Phase, all joints, all legs, across flies, color by Foward speed - polar & cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numJoints = width(joints);

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19, 2,8,14,20, 3,9,15,21, 4,10,16,22, 5,11,17,23, 6,12,18,24];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                    steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    for joint = 1:numJoints
        i = i+1;
        subplot(numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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

        %calculate average step, across speed bins, for this joint
        avg_step = NaN(1,numPhaseBins);
        for pb = 1:numPhaseBins
            avg_step(pb) = mean(joint_data(phase_data >= phaseBins(pb) & phase_data < phaseBins(pb+1)), 'omitnan');
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
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            if contains(joints{joint}, 'rot')
                polarplot(phaseBinCenters, mean_joint_x_phase(sb,:)-avg_step, 'color', colors(sb,:), 'linewidth', 2);hold on
            else
                plot(phaseBinCenters, mean_joint_x_phase(sb,:)-avg_step, 'color', colors(sb,:), 'linewidth', 2); hold on
            end
        end

        %limit rho for polar plots so negative values get plotted correctly
        %and data is as large as possible
        if contains(joints{joint}, 'rot')
            rmin = min(min(mean_joint_x_phase(:,:)-avg_step));
            rmax = max(max(mean_joint_x_phase(:,:)-avg_step));
            rlim([rmin rmax]);
        end
    
        if contains(joints{joint}, 'rot')
            pax = gca;
            % pax.FontSize = 30;
            pax.RColor = Color(param.baseColor);
            pax.ThetaColor = Color(param.baseColor);
            % rlim([0 180])
            % rticks([0,45,90,135,180])
            % rticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
            rtickangle(pax, 45);
            thetaticks([0, 90, 180, 270]);
            thetaticklabels({'0', '\pi/2', '\pi', '3\pi/4'});
        else
            ax = gca;
            ax.FontSize = 20;
            xticks([-pi, 0, pi]);
            xticklabels({'-\pi','0', '\pi'});
        end

        if joint == 1 & leg == 1
            title([param.legs{leg} ' \Delta' strrep(joints{joint}, '_', ' ')]);
        elseif joint == 1 & leg > 1
            title([param.legs{leg}]);
        elseif leg == 1
            title(['\Delta' strrep(joints{joint}, '_', ' ')]);
        end

        if leg == 1
            %TODO label the joint 
        end
        
        if contains(joints{joint}, 'rot')
            fig = formatFigPolar(fig, true);
        else
            fig = formatFig(fig, true);
        end



        hold off
    end
end

% fig = formatFigPolar(fig, true, [numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
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
fig_name = ['\all_joints_x_leg_phase_allLegs_rotation&abduction_averagesNormedByAvgStep_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - polarCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;



%% STD of Joint Rotation & Abduction x Phase, all joints, all legs, across flies, color by Foward speed - polar & cartesian coordinates
% note: I'm not sure if taking standard deviation normally works for
% rotation data that wraps. the wrapping parts might create higher standard
% deviations. Look into this -> how to do std of rotational data. 


clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numJoints = width(joints);

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19, 2,8,14,20, 3,9,15,21, 4,10,16,22, 5,11,17,23, 6,12,18,24];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                    steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    for joint = 1:numJoints
        i = i+1;
        subplot(numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
        binWidth = 2*pi/numPhaseBins;
        phaseBins = -pi:binWidth:pi;
        phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot
    
        std_joint_x_phase = NaN(numSpeedBins, numPhaseBins);
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
                std_joint_x_phase(sb,pb) = std(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
%                 mean_joint_x_phase(sb,pb) = mean(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
                numTrials(sb,pb) = height(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)));
            end
        end
    
        if tossSmallBins
            %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
            for sb = 1:numSpeedBins
                if mean(numTrials(sb,:)) < minAvgSteps
                    std_joint_x_phase(sb,:) = NaN; %'erase' these values so they aren't plotted
                end
            end
        end
    
        %colors for plotting speed binned averages
        colors = jet(numSpeedBins); %order: slow to fast
    
        %plot speed binned averages
        cmap = colormap(colors);
        for sb = 1:numSpeedBins
    %         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            if contains(joints{joint}, 'rot')
                polarplot(phaseBinCenters, std_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
            else
                plot(phaseBinCenters, std_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2); hold on
            end
        end
    
        if contains(joints{joint}, 'rot')
            pax = gca;
            % pax.FontSize = 30;
            pax.RColor = Color(param.baseColor);
            pax.ThetaColor = Color(param.baseColor);
            % rlim([0 180])
            % rticks([0,45,90,135,180])
            % rticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
            rtickangle(pax, 45);
            thetaticks([0, 90, 180, 270]);
            thetaticklabels({'0', '\pi/2', '\pi', '3\pi/4'});
        else
            ax = gca;
            ax.FontSize = 20;
            xticks([-pi, 0, pi]);
            xticklabels({'-\pi','0', '\pi'});
        end

        if joint == 1 & leg == 1
            title([param.legs{leg} ' ' strrep(joints{joint}, '_', ' ')]);
        elseif joint == 1 & leg > 1
            title([param.legs{leg}]);
        elseif leg == 1
            title(strrep(joints{joint}, '_', ' '));
        end

        if leg == 1
            %TODO label the joint 
        end
        
        if contains(joints{joint}, 'rot')
            fig = formatFigPolar(fig, true);
        else
            fig = formatFig(fig, true);
        end



        hold off
    end
end

% fig = formatFigPolar(fig, true, [numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
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
fig_name = ['\all_joints_x_leg_phase_allLegs_rotation&abduction_averageStandardDeviations_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - polarCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;



%% MEAN of Joint Rotation x Phase, all joints, all legs, across flies, color by Foward speed - polar coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'A_rot', 'B_rot', 'C_rot'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numJoints = width(joints);

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,2,8,14,3,9,15,4,10,16,5,11,17,6,12,18];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                    steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    for joint = 1:numJoints
        i = i+1;
        subplot(numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
        end
    
        
        pax = gca;
        % pax.FontSize = 30;
        pax.RColor = Color(param.baseColor);
        pax.ThetaColor = Color(param.baseColor);
        % rlim([0 180])
        % rticks([0,45,90,135,180])
        % rticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
        rtickangle(pax, 45);
        thetaticks([0, 90, 180, 270]);
        thetaticklabels({'0', '\pi/2', '\pi', '3\pi/4'});

        if joint == 1 & leg == 1
            title([param.legs{leg} ' ' strrep(joints{joint}, '_', ' ')]);
        elseif joint == 1 & leg > 1
            title([param.legs{leg}]);
        elseif leg == 1
            title(strrep(joints{joint}, '_', ' '));
        end

        if leg == 1
            %TODO label the joint 
        end




        hold off
    end
end

fig = formatFigPolar(fig, true, [numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
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
fig_name = ['\all_joints_x_leg_phase_allLegs_rotation_averages_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - polarCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% MEAN NORMED of Joint Rotation x Phase, all joints, all legs, across flies, color by Foward speed - polar coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'A_rot', 'B_rot', 'C_rot'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numJoints = width(joints);

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,2,8,14,3,9,15,4,10,16,5,11,17,6,12,18];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                    steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    for joint = 1:numJoints
        i = i+1;
        subplot(numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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

        %calculate average step, across speed bins, for this joint
        avg_step = NaN(1,numPhaseBins);
        for pb = 1:numPhaseBins
            avg_step(pb) = mean(joint_data(phase_data >= phaseBins(pb) & phase_data < phaseBins(pb+1)), 'omitnan');
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
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            polarplot(phaseBinCenters, mean_joint_x_phase(sb,:)-avg_step, 'color', colors(sb,:), 'linewidth', 2);hold on
        end
    
        
        pax = gca;
        % pax.FontSize = 30;
        pax.RColor = Color(param.baseColor);
        pax.ThetaColor = Color(param.baseColor);
        % rlim([0 180])
        % rticks([0,45,90,135,180])
        % rticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
        rtickangle(pax, 45);
        thetaticks([0, 90, 180, 270]);
        thetaticklabels({'0', '\pi/2', '\pi', '3\pi/4'});

        if joint == 1 & leg == 1
            title([param.legs{leg} ' \Delta' strrep(joints{joint}, '_', ' ')]);
        elseif joint == 1 & leg > 1
            title([param.legs{leg}]);
        elseif leg == 1
            title(['\Delta' strrep(joints{joint}, '_', ' ')]);
        end

        if leg == 1
            %TODO label the joint 
        end




        hold off
    end
end

fig = formatFigPolar(fig, true, [numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
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
fig_name = ['\all_joints_x_leg_phase_allLegs_rotation_averagesNormedByAvgStep_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - polarCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% VELOCITY of Joint Rotation and Abduction x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

% joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
joints = {'A_abduct', 'A_rot_unwrapped', 'B_rot_unwrapped', 'C_rot_unwrapped'};
% phases = {'A_abduct_phase', 'A_rot_phase', 'B_rot_phase', 'C_rot_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                    steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);

        %take derivative of data to get velocity 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
%             if joint == 1 %abduction
%                 ylabel([strrep(joints{joint}, '_', ' ') ' (' char(176) ')']);
%             else % change in rotation 
                ylabel([strrep(joints{joint}, '_', ' ') ' (' char(176) '/s)']);
%             end

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
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
fig_name = ['\all_joints_x_leg_phase_allLegs_rotation&abduction_averageVelocity_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% VELOCITY NORMED Joint Abduct & Rotations x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates
% angle difference from average across speeds. 

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'A_abduct', 'A_rot_unwrapped', 'B_rot_unwrapped', 'C_rot_unwrapped'};
% phases = {'A_abduct_phase', 'A_rot_phase', 'B_rot_phase', 'C_rot_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                        steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                    abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);

        %take derivative of data to get velocity 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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

        %calculate average step, across speed bins, for this joint
        avg_step = NaN(1,numPhaseBins);
        for pb = 1:numPhaseBins
            avg_step(pb) = mean(joint_data(phase_data >= phaseBins(pb) & phase_data < phaseBins(pb+1)), 'omitnan');
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
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)-avg_step), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, (mean_joint_x_phase(sb,:)-avg_step), 'color', colors(sb,:), 'linewidth', 2);hold on

        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
%             if joint == 1 %abduction
%                 ylabel([strrep(joints{joint}, '_', ' ') ' (' char(176) ')']);
%             else % change in rotation 
                ylabel([strrep(joints{joint}, '_', ' ') ' (' char(176) '/s)']);
%             end

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
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
fig_name = ['\all_joints_x_leg_phase_allLegs_rotation&abductiony_averageVelocityNormedByAvgStep_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% STD of VELOCITY of Joint Abduct & Rotations x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'A_abduct', 'A_rot_unwrapped', 'B_rot_unwrapped', 'C_rot_unwrapped'};
% phases = {'A_abduct_phase', 'A_rot_phase', 'B_rot_phase', 'C_rot_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                        steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                    abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);

        %take derivative of data to get velocity 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
        binWidth = 2*pi/numPhaseBins;
        phaseBins = -pi:binWidth:pi;
        phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot
    
        std_joint_x_phase = NaN(numSpeedBins, numPhaseBins);
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
                std_joint_x_phase(sb,pb) = std(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
                numTrials(sb,pb) = height(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)));
            end
        end
    
        if tossSmallBins
            %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
            for sb = 1:numSpeedBins
                if mean(numTrials(sb,:)) < minAvgSteps
                    std_joint_x_phase(sb,:) = NaN; %'erase' these values so they aren't plotted
                end
            end
        end
    
        %colors for plotting speed binned averages
        colors = jet(numSpeedBins); %order: slow to fast
    
        %plot speed binned averages
        cmap = colormap(colors);
        for sb = 1:numSpeedBins
    %         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth(std_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, std_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
%              if joint == 1 %abduction
%                 ylabel([strrep(joints{joint}, '_', ' ') ' (' char(176) ')']);
%             else % change in rotation 
                ylabel([strrep(joints{joint}, '_', ' ') ' (' char(176) '/s)']);
%             end

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
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
fig_name = ['\all_joints_x_leg_phase_allLegs_rotation&abduction_averageVelocityStandardDeviations_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;




%% ACCELERATION of Joint Rotation & Abduction x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'A_abduct', 'A_rot_unwrapped', 'B_rot_unwrapped', 'C_rot_unwrapped'};
% phases = {'A_abduct_phase', 'A_rot_phase', 'B_rot_phase', 'C_rot_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                    steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);

        %take derivative of data to get velocity 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
        %take derivative of data to get acceleration 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
            
        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
%             if joint == 1 %abduction
%                 ylabel([strrep(joints{joint}, '_', ' ') ' (' char(176) '/s)']);
%             else % change in rotation 
                ylabel([strrep(joints{joint}, '_', ' ') ' (' char(176) '/s^2)']);
%             end

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
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
fig_name = ['\all_joints_x_leg_phase_allLegs_rotation&abduction_averageAccelerations_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% JERK of Joint Rotation & Abduction x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'A_abduct', 'A_rot_unwrapped', 'B_rot_unwrapped', 'C_rot_unwrapped'};
% phases = {'A_abduct_phase', 'A_rot_phase', 'B_rot_phase', 'C_rot_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                    steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);

        %take derivative of data to get velocity 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
        %take derivative of data to get acceleration 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
        %take derivative of data to get jerk 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
            
        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
%             if joint == 1 %abduction
%                 ylabel([strrep(joints{joint}, '_', ' ') ' (' char(176) '/s)']);
%             else % change in rotation 
                ylabel([strrep(joints{joint}, '_', ' ') ' (' char(176) '/s^3)']);
%             end

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
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
fig_name = ['\all_joints_x_leg_phase_allLegs_rotation&abduction_averageJerk_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% 
% STEP METRICS
%% STEP LENGTH x Forward Velocity, all legs, across flies. 

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

metric = 'step_length'; 
dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                        steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                    abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    

    subplot(2,3,legOrder(leg)); 
  
    %bin data
    leg_data = steps.leg(leg).meta.(metric)(idxs);
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data = NaN(numSpeedBins, 1);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data = leg_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data(sb) = mean(binned_leg_data, 'omitnan');
        numTrials(sb) = height(binned_leg_data);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data(sb) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = jet(numSpeedBins); %order: slow to fast

    %plot speed binned averages
    cmap = colormap(colors);
    scatter(binEdges(2:end), mean_leg_data, dotSize, 'filled'); hold on
    
    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        ylabel([strrep(metric, '_', ' ') ' (L1 coxa length)']);
        xlabel('Forward velocity (mm/s)')
    end
    title(param.legs{leg});

    hold off
end

fig = formatFig(fig, true, [2,3]);      

hold off

%save 
fig_name = ['\' metric '_average_x_forwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% STEP LENGTH x Forward Velocity, all legs, single fly. 

clearvars('-except',initial_vars{:}); initial_vars = who;

flyNum = 2; %adjust this 
fly = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 
fullfly = flyList.flyid{flyNum};

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 20; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

metric = 'step_length'; 
dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(contains(steps.leg(leg).meta.fly, fly) & ...
                     abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                         steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                     abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    

    subplot(2,3,legOrder(leg)); 
  
    %bin data
    leg_data = steps.leg(leg).meta.(metric)(idxs);
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data = NaN(numSpeedBins, 1);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data = leg_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data(sb) = mean(binned_leg_data, 'omitnan');
        numTrials(sb) = height(binned_leg_data);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data(sb) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = jet(numSpeedBins); %order: slow to fast

    %plot speed binned averages
    cmap = colormap(colors);
    scatter(binEdges(2:end), mean_leg_data, dotSize, 'filled'); hold on
    
    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        ylabel([strrep(metric, '_', ' ') ' (L1 coxa length)']);
        xlabel('Forward velocity (mm/s)')
    end
    title(param.legs{leg});

    hold off
end

fig = formatFig(fig, true, [2,3]);      

hold off

%save 

fig_name = ['\' metric '_average_x_forwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - ' fullfly ' - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% STEP DURATION x Forward Velocity, all legs, across flies. 

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

metric = 'step_duration'; 
dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                        steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                    abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    

    subplot(2,3,legOrder(leg)); 
  
    %bin data
    leg_data = steps.leg(leg).meta.(metric)(idxs);
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data = NaN(numSpeedBins, 1);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data = leg_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data(sb) = mean(binned_leg_data, 'omitnan');
        numTrials(sb) = height(binned_leg_data);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data(sb) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = jet(numSpeedBins); %order: slow to fast

    %plot speed binned averages
    cmap = colormap(colors);
    scatter(binEdges(2:end), mean_leg_data, dotSize, 'filled'); hold on
    
    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        ylabel([strrep(metric, '_', ' ') ' (s)']);
        xlabel('Forward velocity (mm/s)')
    end
    title(param.legs{leg});

    hold off
end

fig = formatFig(fig, true, [2,3]);      

hold off

%save 
fig_name = ['\' metric '_average_x_forwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% STEP DURATION x Forward Velocity, all legs, single fly. 

clearvars('-except',initial_vars{:}); initial_vars = who;

flyNum = 2; %adjust this 
fly = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 
fullfly = flyList.flyid{flyNum};

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 20; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

metric = 'step_duration'; 
dotSize = 100; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(contains(steps.leg(leg).meta.fly, fly) & ...
                     abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                         steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                     abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    

    subplot(2,3,legOrder(leg)); 
  
    %bin data
    leg_data = steps.leg(leg).meta.(metric)(idxs);
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data = NaN(numSpeedBins, 1);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data = leg_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data(sb) = mean(binned_leg_data, 'omitnan');
        numTrials(sb) = height(binned_leg_data);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data(sb) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = jet(numSpeedBins); %order: slow to fast

    %plot speed binned averages
    cmap = colormap(colors);
    scatter(binEdges(2:end), mean_leg_data, dotSize, 'filled'); hold on
    
    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        ylabel([strrep(metric, '_', ' ') ' (s)']);
        xlabel('Forward velocity (mm/s)')
    end
    title(param.legs{leg});

    hold off
end

fig = formatFig(fig, true, [2,3]);      

hold off

%save 

fig_name = ['\' metric '_average_x_forwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - ' fullfly ' - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% SWING DURATION x Forward Velocity, all legs, across flies. 

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

metric = 'swing_duration'; 
dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                        steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                    abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    

    subplot(2,3,legOrder(leg)); 
  
    %bin data
    leg_data = steps.leg(leg).meta.(metric)(idxs);
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data = NaN(numSpeedBins, 1);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data = leg_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data(sb) = mean(binned_leg_data, 'omitnan');
        numTrials(sb) = height(binned_leg_data);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data(sb) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = jet(numSpeedBins); %order: slow to fast

    %plot speed binned averages
    cmap = colormap(colors);
    scatter(binEdges(2:end), mean_leg_data, dotSize, 'filled'); hold on
    
    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        ylabel([strrep(metric, '_', ' ') ' (s)']);
        xlabel('Forward velocity (mm/s)')
    end
    title(param.legs{leg});

    hold off
end

fig = formatFig(fig, true, [2,3]);      

hold off

%save 
fig_name = ['\' metric '_average_x_forwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% SWING DURATION x Forward Velocity, all legs, single fly. 

clearvars('-except',initial_vars{:}); initial_vars = who;

flyNum = 2; %adjust this 
fly = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 
fullfly = flyList.flyid{flyNum};

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 20; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

metric = 'swing_duration'; 
dotSize = 100; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(contains(steps.leg(leg).meta.fly, fly) & ...
                     abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                         steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                     abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    

    subplot(2,3,legOrder(leg)); 
  
    %bin data
    leg_data = steps.leg(leg).meta.(metric)(idxs);
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data = NaN(numSpeedBins, 1);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data = leg_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data(sb) = mean(binned_leg_data, 'omitnan');
        numTrials(sb) = height(binned_leg_data);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data(sb) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = jet(numSpeedBins); %order: slow to fast

    %plot speed binned averages
    cmap = colormap(colors);
    scatter(binEdges(2:end), mean_leg_data, dotSize, 'filled'); hold on
    
    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        ylabel([strrep(metric, '_', ' ') ' (s)']);
        xlabel('Forward velocity (mm/s)')
    end
    title(param.legs{leg});

    hold off
end

fig = formatFig(fig, true, [2,3]);      

hold off

%save 

fig_name = ['\' metric '_average_x_forwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - ' fullfly ' - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% STANCE DURATION x Forward Velocity, all legs, across flies. 

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

metric = 'stance_duration'; 
dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                        steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                    abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    

    subplot(2,3,legOrder(leg)); 
  
    %bin data
    leg_data = steps.leg(leg).meta.(metric)(idxs);
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data = NaN(numSpeedBins, 1);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data = leg_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data(sb) = mean(binned_leg_data, 'omitnan');
        numTrials(sb) = height(binned_leg_data);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data(sb) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = jet(numSpeedBins); %order: slow to fast

    %plot speed binned averages
    cmap = colormap(colors);
    scatter(binEdges(2:end), mean_leg_data, dotSize, 'filled'); hold on
    
    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        ylabel([strrep(metric, '_', ' ') ' (s)']);
        xlabel('Forward velocity (mm/s)')
    end
    title(param.legs{leg});

    hold off
end

fig = formatFig(fig, true, [2,3]);      

hold off

%save 
fig_name = ['\' metric '_average_x_forwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% STANCE DURATION x Forward Velocity, all legs, single fly. 

clearvars('-except',initial_vars{:}); initial_vars = who;

flyNum = 2; %adjust this 
fly = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 
fullfly = flyList.flyid{flyNum};

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 20; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

metric = 'stance_duration'; 
dotSize = 100; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(contains(steps.leg(leg).meta.fly, fly) & ...
                     abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                         steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                     abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    

    subplot(2,3,legOrder(leg)); 
  
    %bin data
    leg_data = steps.leg(leg).meta.(metric)(idxs);
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data = NaN(numSpeedBins, 1);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data = leg_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data(sb) = mean(binned_leg_data, 'omitnan');
        numTrials(sb) = height(binned_leg_data);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data(sb) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = jet(numSpeedBins); %order: slow to fast

    %plot speed binned averages
    cmap = colormap(colors);
    scatter(binEdges(2:end), mean_leg_data, dotSize, 'filled'); hold on
    
    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        ylabel([strrep(metric, '_', ' ') ' (s)']);
        xlabel('Forward velocity (mm/s)')
    end
    title(param.legs{leg});

    hold off
end

fig = formatFig(fig, true, [2,3]);      

hold off

%save 

fig_name = ['\' metric '_average_x_forwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - ' fullfly ' - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;



%% AEP & PEP x Forward Velocity, all legs, across flies. 

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

metricA = 'AEP';
metricB = 'PEP';
type = '2D'; %plot 2D or 3D (2D is x,y)

dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

directions = {'x', 'y', 'z'}; 

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                        steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                    abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    

    subplot(2,3,legOrder(leg)); 

    clear leg_data_A leg_data_B
  
    %bin data
    for d = 1:width(directions)
        leg_data_A(:,d) = steps.leg(leg).meta.([metricA '_E_' directions{d}])(idxs);
        leg_data_B(:,d) = steps.leg(leg).meta.([metricB '_E_' directions{d}])(idxs);
    end
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data_A = NaN(numSpeedBins, 3);
    mean_leg_data_B = NaN(numSpeedBins, 3);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data_A = leg_data_A(bins == sb, :);
        binned_leg_data_B = leg_data_B(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data_A);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data_A(sb,:) = mean(binned_leg_data_A, 'omitnan');
        mean_leg_data_B(sb,:) = mean(binned_leg_data_B, 'omitnan');
        numTrials(sb) = height(binned_leg_data_A);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data_A(sb,:) = NaN; %'erase' these values so they aren't plotted
                mean_leg_data_B(sb,:) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = jet(numSpeedBins); %order: slow to fast

    %plot speed binned averages
    cmap = colormap(colors);

    if contains(type, '3D')
        scatter3(mean_leg_data_A(:,1), mean_leg_data_A(:,2), mean_leg_data_A(:,3), dotSize, 1:numSpeedBins, "o"); hold on; 
        scatter3(mean_leg_data_B(:,1), mean_leg_data_B(:,2), mean_leg_data_B(:,3), dotSize, 1:numSpeedBins, 'filled', 'square'); hold on
    elseif contains(type, '2D')
        scatter(mean_leg_data_A(:,2), mean_leg_data_A(:,1), dotSize, 1:numSpeedBins, "o", 'filled'); hold on; 
        scatter(mean_leg_data_B(:,2), mean_leg_data_B(:,1), dotSize, 1:numSpeedBins, 'filled', 'diamond'); hold on
    end

    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        xlabel('L1/L3 axis (L1 coxa length)');
        ylabel('L1/R1 axis (L1 coxa length)');
        if contains(type, '3D')
            zlabel('Vertical axis (L1 coxa length)');
        end
    end
    title(param.legs{leg});

    set(gca, 'XDir','reverse');

    hold off
end

fig = formatFig(fig, true, [2,3]);      

h = axes(fig,'visible','off'); 
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

% %save 
fig_name = ['\' metricA '_&_' metricB '_' type '_average_x_forwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% AEP & PEP x Forward Velocity, all legs, single flies. 

clearvars('-except',initial_vars{:}); initial_vars = who;

flyNum = 2; %adjust this 
fly = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 
fullfly = flyList.flyid{flyNum};

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 20; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

metricA = 'AEP';
metricB = 'PEP';
type='2D'; %plot 2D or 3D (2D is x,y)

dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

directions = {'x', 'y', 'z'}; 

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(contains(steps.leg(leg).meta.fly, fly) & ...
                     abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                         steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                     abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    

    subplot(2,3,legOrder(leg)); 

    clear leg_data_A leg_data_B
  
    %bin data
    for d = 1:width(directions)
        leg_data_A(:,d) = steps.leg(leg).meta.([metricA '_E_' directions{d}])(idxs);
        leg_data_B(:,d) = steps.leg(leg).meta.([metricB '_E_' directions{d}])(idxs);
    end
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data_A = NaN(numSpeedBins, 3);
    mean_leg_data_B = NaN(numSpeedBins, 3);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data_A = leg_data_A(bins == sb, :);
        binned_leg_data_B = leg_data_B(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data_A);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data_A(sb,:) = mean(binned_leg_data_A, 'omitnan');
        mean_leg_data_B(sb,:) = mean(binned_leg_data_B, 'omitnan');
        numTrials(sb) = height(binned_leg_data_A);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data_A(sb,:) = NaN; %'erase' these values so they aren't plotted
                mean_leg_data_B(sb,:) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = jet(numSpeedBins); %order: slow to fast

    %plot speed binned averages
    cmap = colormap(colors);
    
    if contains(type, '3D')
        scatter3(mean_leg_data_A(:,1), mean_leg_data_A(:,2), mean_leg_data_A(:,3), dotSize, 1:numSpeedBins, "o"); hold on; 
        scatter3(mean_leg_data_B(:,1), mean_leg_data_B(:,2), mean_leg_data_B(:,3), dotSize, 1:numSpeedBins, 'filled', 'square'); hold on
    elseif contains(type, '2D')
        scatter(mean_leg_data_A(:,2), mean_leg_data_A(:,1), dotSize, 1:numSpeedBins, "o", 'filled'); hold on; 
        scatter(mean_leg_data_B(:,2), mean_leg_data_B(:,1), dotSize, 1:numSpeedBins, 'filled', 'diamond'); hold on
    end

    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        xlabel('L1/L3 axis (L1 coxa length)');
        ylabel('L1/R1 axis (L1 coxa length)');
        if contains(type, '3D')
            zlabel('Vertical axis (L1 coxa length)');
        end
    end
    title(param.legs{leg});

    set(gca, 'XDir','reverse')

    hold off
end

fig = formatFig(fig, true, [2,3]);      

h = axes(fig,'visible','off'); 
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

% %save 
fig_name = ['\' metricA '_&_' metricB '_' type '_average_x_forwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - ' fullfly ' - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% AEP & PEP x Forward Velocity, all legs, across flies - ONE plot. 

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

metricA = 'AEP';
metricB = 'PEP';
type = '2D'; %plot 2D or 3D (2D is x,y)

dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

directions = {'x', 'y', 'z'}; 

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                        steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                    abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    

    clear leg_data_A leg_data_B
  
    %bin data
    for d = 1:width(directions)
        leg_data_A(:,d) = steps.leg(leg).meta.([metricA '_E_' directions{d}])(idxs);
        leg_data_B(:,d) = steps.leg(leg).meta.([metricB '_E_' directions{d}])(idxs);
    end
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data_A = NaN(numSpeedBins, 3);
    mean_leg_data_B = NaN(numSpeedBins, 3);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data_A = leg_data_A(bins == sb, :);
        binned_leg_data_B = leg_data_B(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data_A);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data_A(sb,:) = mean(binned_leg_data_A, 'omitnan');
        mean_leg_data_B(sb,:) = mean(binned_leg_data_B, 'omitnan');
        numTrials(sb) = height(binned_leg_data_A);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data_A(sb,:) = NaN; %'erase' these values so they aren't plotted
                mean_leg_data_B(sb,:) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = jet(numSpeedBins); %order: slow to fast

    %plot speed binned averages
    cmap = colormap(colors);

    if contains(type, '3D')
        scatter3(mean_leg_data_A(:,1), mean_leg_data_A(:,2), mean_leg_data_A(:,3), dotSize, 1:numSpeedBins, "o"); hold on; 
        scatter3(mean_leg_data_B(:,1), mean_leg_data_B(:,2), mean_leg_data_B(:,3), dotSize, 1:numSpeedBins, 'filled', 'square'); hold on
    elseif contains(type, '2D')
        scatter(mean_leg_data_A(:,2), mean_leg_data_A(:,1), dotSize, 1:numSpeedBins, "o", 'filled'); hold on; 
        scatter(mean_leg_data_B(:,2), mean_leg_data_B(:,1), dotSize, 1:numSpeedBins, 'filled', 'diamond'); hold on
    end

    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        xlabel('L1/L3 axis (L1 coxa length)');
        ylabel('L1/R1 axis (L1 coxa length)');
        if contains(type, '3D')
            zlabel('Vertical axis (L1 coxa length)');
        end
    end

    set(gca, 'XDir','reverse');

end
hold off

fig = formatFig(fig, true);      

h = axes(fig,'visible','off'); 
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

% %save 
fig_name = ['\' metricA '_&_' metricB '_' type '_average_x_forwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords - onePlot'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% AEP & PEP x Forward Velocity, all legs, single flies - ONE plot. 

clearvars('-except',initial_vars{:}); initial_vars = who;

flyNum = 2; %adjust this 
fly = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 
fullfly = flyList.flyid{flyNum};

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 20; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

metricA = 'AEP';
metricB = 'PEP';
type='2D'; %plot 2D or 3D (2D is x,y)

dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

directions = {'x', 'y', 'z'}; 

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(contains(steps.leg(leg).meta.fly, fly) & ...
                     abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                         steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                     abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    

    clear leg_data_A leg_data_B
  
    %bin data
    for d = 1:width(directions)
        leg_data_A(:,d) = steps.leg(leg).meta.([metricA '_E_' directions{d}])(idxs);
        leg_data_B(:,d) = steps.leg(leg).meta.([metricB '_E_' directions{d}])(idxs);
    end
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data_A = NaN(numSpeedBins, 3);
    mean_leg_data_B = NaN(numSpeedBins, 3);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data_A = leg_data_A(bins == sb, :);
        binned_leg_data_B = leg_data_B(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data_A);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data_A(sb,:) = mean(binned_leg_data_A, 'omitnan');
        mean_leg_data_B(sb,:) = mean(binned_leg_data_B, 'omitnan');
        numTrials(sb) = height(binned_leg_data_A);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data_A(sb,:) = NaN; %'erase' these values so they aren't plotted
                mean_leg_data_B(sb,:) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = jet(numSpeedBins); %order: slow to fast

    %plot speed binned averages
    cmap = colormap(colors);
    
    if contains(type, '3D')
        scatter3(mean_leg_data_A(:,1), mean_leg_data_A(:,2), mean_leg_data_A(:,3), dotSize, 1:numSpeedBins, "o"); hold on; 
        scatter3(mean_leg_data_B(:,1), mean_leg_data_B(:,2), mean_leg_data_B(:,3), dotSize, 1:numSpeedBins, 'filled', 'square'); hold on
    elseif contains(type, '2D')
        scatter(mean_leg_data_A(:,2), mean_leg_data_A(:,1), dotSize, 1:numSpeedBins, "o", 'filled'); hold on; 
        scatter(mean_leg_data_B(:,2), mean_leg_data_B(:,1), dotSize, 1:numSpeedBins, 'filled', 'diamond'); hold on
    end

    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        xlabel('L1/L3 axis (L1 coxa length)');
        ylabel('L1/R1 axis (L1 coxa length)');
        if contains(type, '3D')
            zlabel('Vertical axis (L1 coxa length)');
        end
    end

    set(gca, 'XDir','reverse')

end

hold off

fig = formatFig(fig, true);      

h = axes(fig,'visible','off'); 
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

% %save 
fig_name = ['\' metricA '_&_' metricB '_' type '_average_x_forwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - ' fullfly ' - graphCoords - onePlot'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% %%%%%%%% Walking x Rotational Velocity %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 
% ANGLES
%% MEAN single Joint x Phase, all legs, across flies, color by Rotational speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joint = 'FTi';
phase = 'FTi_phase';

max_speed_x = 100;
max_speed_y = 500; 
min_speed_z = 3;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 40;
binEdges = unique([linspace(-1*maxSpeed, 0, (numSpeedBins/2)+1) linspace(0, maxSpeed, (numSpeedBins/2)+1)]);

for leg = 1:param.numLegs
    subplot(2,3,legOrder(leg)); 

    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                    steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
                abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);

    %bin data
    joint_data = steps.leg(leg).(joint)(idxs, :);
    phase_data = steps.leg(leg).(phase)(idxs, :);
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    %phase bins to take averages in
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
    
    cmap = colormap(redblue(numSpeedBins*2));
    c = redblue(numSpeedBins, [maxSpeed*-1, maxSpeed]);
    
    for sb = 1:numSpeedBins
        plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', c(sb,:), 'linewidth', 2);hold on
    end

    ax = gca;
    ax.FontSize = 30;
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
colormap(c);
cb = colorbar(h,'Position',[0.92 0.168 0.022 0.7], 'XTick', [0,0.5,1], ...
    'XTickLabel',{['-' num2str(maxSpeed) ' (right)'], ['0'], [num2str(maxSpeed) ' (left)']});
cb.Label.String = 'Rotational velocity (mm/s)';
cb.FontSize = 15;
cb.Label.FontSize = 30;

cb.Color = param.baseColor;
cb.Box = 'off';        
hold off

%save 
fig_name = ['\' joint '_x_' phase '_allLegs_averages_binnedByRotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_below_' num2str(max_speed_y) ' z_above_' num2str(min_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN Joint x Phase, all joints, all legs, across flies, color by Rotational speed - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

% min_speed_x = 5; 
% min_speed_y = 5; 
min_speed_z = 0;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
        colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?
    
        %plot speed binned averages
        cmap = colormap(colors); 
        for sb = 1:numSpeedBins
    %         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
            ylabel([joints{joint} ' (' char(176) ')']);

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1 
        tickLabels{t} = '(CW)'; 
    elseif t == width(binEdges)
        tickLabels{t} = '(CCW)'; 
    else
        tickLabels{t} = num2str(binEdges(t)); 
    end
end
c = colorbar(h,'Position',[0.91 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        

hold off

%save 
fig_name = ['\all_joints_x_leg_phase_allLegs_averages_binnedByRotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;



 



%% MEAN Joint x Phase, all joints, all legs, single fly, color by Rotational speed - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

flyNum = 2; %adjust this 
fly = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 
fullfly = flyList.flyid{flyNum};

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 40; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

% max_speed_x = 1000; 
% max_speed_y = 10; 
min_speed_z = 0;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(contains(steps.leg(leg).meta.fly, fly) & abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(contains(steps.leg(leg).meta.fly, fly) & ...
%                      abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                          steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                      abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
        colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?
    
        %plot speed binned averages
        cmap = colormap(colors); 
        for sb = 1:numSpeedBins
    %         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
            ylabel([joints{joint} ' (' char(176) ')']);

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1 
        tickLabels{t} = '(CW)'; 
    elseif t == width(binEdges)
        tickLabels{t} = '(CCW)'; 
    else
        tickLabels{t} = num2str(binEdges(t)); 
    end
end
c = colorbar(h,'Position',[0.91 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        

hold off

%save 
fig_name = ['\all_joints_x_leg_phase_allLegs_averages_binnedByRotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - ' fullfly ' - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% MEAN NORMED Joint x Phase, all joints, all legs, across flies, color by Rotational speed - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

% max_speed_x = 300; 
% max_speed_y = 200; 
min_speed_z = 0;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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


        %calculate average step, across speed bins, for this joint
        avg_step = NaN(1,numPhaseBins);
        for pb = 1:numPhaseBins
            avg_step(pb) = mean(joint_data(phase_data >= phaseBins(pb) & phase_data < phaseBins(pb+1)), 'omitnan');
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
        colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?
    
        %plot speed binned averages
        cmap = colormap(colors); 
        for sb = 1:numSpeedBins
    %         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, mean_joint_x_phase(sb,:)-avg_step, 'color', colors(sb,:), 'linewidth', 2);hold on
        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
            ylabel(['\Delta' joints{joint} ' (' char(176) ')']);

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1 
        tickLabels{t} = '(CW)'; 
    elseif t == width(binEdges)
        tickLabels{t} = '(CCW)'; 
    else
        tickLabels{t} = num2str(binEdges(t)); 
    end
end
c = colorbar(h,'Position',[0.91 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        

hold off

%save 
fig_name = ['\all_joints_x_leg_phase_allLegs_averagesNormedByAvgStep_binnedByRotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;



 



%% STD Joint x Phase, all joints, all legs, across flies, color by Rotational speed - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

% max_speed_x = 300; 
% max_speed_y = 200; 
min_speed_z = 0;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
        binWidth = 2*pi/numPhaseBins;
        phaseBins = -pi:binWidth:pi;
        phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot
    
        std_joint_x_phase = NaN(numSpeedBins, numPhaseBins);
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
%                 mean_joint_x_phase(sb,pb) = mean(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
                std_joint_x_phase(sb,pb) = std(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
                numTrials(sb,pb) = height(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)));
            end
        end
    
        if tossSmallBins
            %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
            for sb = 1:numSpeedBins
                if mean(numTrials(sb,:)) < minAvgSteps
                    std_joint_x_phase(sb,:) = NaN; %'erase' these values so they aren't plotted
                end
            end
        end
    
        %colors for plotting speed binned averages
        colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?
    
        %plot speed binned averages
        cmap = colormap(colors); 
        for sb = 1:numSpeedBins
    %         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, std_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
            ylabel([joints{joint} ' (' char(176) ')']);

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1 
        tickLabels{t} = '(CW)'; 
    elseif t == width(binEdges)
        tickLabels{t} = '(CCW)'; 
    else
        tickLabels{t} = num2str(binEdges(t)); 
    end
end
c = colorbar(h,'Position',[0.91 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        

hold off

%save 
fig_name = ['\all_joints_x_leg_phase_allLegs_averageStandardDeviations_binnedByRotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;



 




%% VELOCITY of Joint x Phase, all joints, all legs, across flies, color by Rotational speed - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

% max_speed_x = 300; 
% max_speed_y = 200; 
min_speed_z = 0;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);

        %take derivative of data to get velocity 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
        colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?
    
        %plot speed binned averages
        cmap = colormap(colors); 
        for sb = 1:numSpeedBins
    %         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on

        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
            ylabel([joints{joint} ' (' char(176) '/s)']);

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1 
        tickLabels{t} = '(CW)'; 
    elseif t == width(binEdges)
        tickLabels{t} = '(CCW)'; 
    else
        tickLabels{t} = num2str(binEdges(t)); 
    end
end
c = colorbar(h,'Position',[0.91 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        

hold off

%save 
fig_name = ['\all_joints_x_leg_phase_allLegs_averageAngleVelocity_binnedByRotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;



 




%% ACCELERATION of Joint x Phase, all joints, all legs, across flies, color by Rotational speed - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

% max_speed_x = 300; 
% max_speed_y = 200; 
min_speed_z = 0;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);

        %take derivative of data to get velocity 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
        %take derivative of data to get acceleration 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
        colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?
    
        %plot speed binned averages
        cmap = colormap(colors); 
        for sb = 1:numSpeedBins
    %         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on

        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
            ylabel([joints{joint} ' (' char(176) '/s^2)']);

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1 
        tickLabels{t} = '(CW)'; 
    elseif t == width(binEdges)
        tickLabels{t} = '(CCW)'; 
    else
        tickLabels{t} = num2str(binEdges(t)); 
    end
end
c = colorbar(h,'Position',[0.91 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        

hold off

%save 
fig_name = ['\all_joints_x_leg_phase_allLegs_averageAngleAcceleration_binnedByRotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;



 




%% JERK of Joint x Phase, all joints, all legs, across flies, color by Rotational speed - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

% max_speed_x = 300; 
% max_speed_y = 200; 
min_speed_z = 0;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);

        %take derivative of data to get velocity 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
        %take derivative of data to get acceleration 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
        %take derivative of data to get jerk 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
        colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?
    
        %plot speed binned averages
        cmap = colormap(colors); 
        for sb = 1:numSpeedBins
    %         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on

        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
            ylabel([joints{joint} ' (' char(176) '/s^3)']);

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1 
        tickLabels{t} = '(CW)'; 
    elseif t == width(binEdges)
        tickLabels{t} = '(CCW)'; 
    else
        tickLabels{t} = num2str(binEdges(t)); 
    end
end
c = colorbar(h,'Position',[0.91 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        

hold off

%save 
fig_name = ['\all_joints_x_leg_phase_allLegs_averageAngleJerk_binnedByRotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;



%% 
% ABDUCTION & ROTATIONS
%% MEAN of Joint Rotation & Abduction x Phase, all joints, all legs, across flies, color by Rotational speed - polar & cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


% max_speed_x = 300; 
% max_speed_y = 200; 
min_speed_z = 0;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numJoints = width(joints);

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19, 2,8,14,20, 3,9,15,21, 4,10,16,22, 5,11,17,23, 6,12,18,24];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
    
    for joint = 1:numJoints
        i = i+1;
        subplot(numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
        colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?
        
        %plot speed binned averages
        cmap = colormap(colors);
        for sb = 1:numSpeedBins
    %         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            if contains(joints{joint}, 'rot')
                polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
            else
                plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2); hold on
            end
        end
        
        %limit rho for polar plots so negative values get plotted correctly
        %and data is as large as possible
        if contains(joints{joint}, 'rot')
            rmin = min(min(mean_joint_x_phase(:,:)));
            rmax = max(max(mean_joint_x_phase(:,:)));
            rlim([rmin rmax]);
        end
    
        if contains(joints{joint}, 'rot')
            pax = gca;
            % pax.FontSize = 30;
            pax.RColor = Color(param.baseColor);
            pax.ThetaColor = Color(param.baseColor);
            % rlim([0 180])
            % rticks([0,45,90,135,180])
            % rticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
            rtickangle(pax, 45);
            thetaticks([0, 90, 180, 270]);
            thetaticklabels({'0', '\pi/2', '\pi', '3\pi/4'});
        else
            ax = gca;
            ax.FontSize = 20;
            xticks([-pi, 0, pi]);
            xticklabels({'-\pi','0', '\pi'});
        end

        if joint == 1 & leg == 1
            title([param.legs{leg} ' ' strrep(joints{joint}, '_', ' ')]);
        elseif joint == 1 & leg > 1
            title([param.legs{leg}]);
        elseif leg == 1
            title(strrep(joints{joint}, '_', ' '));
        end

        if leg == 1
            %TODO label the joint 
        end
        
        if contains(joints{joint}, 'rot')
            fig = formatFigPolar(fig, true);
        else
            fig = formatFig(fig, true);
        end



        hold off
    end
end

% fig = formatFigPolar(fig, true, [numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1 
        tickLabels{t} = '(CW)'; 
    elseif t == width(binEdges)
        tickLabels{t} = '(CCW)'; 
    else
        tickLabels{t} = num2str(binEdges(t)); 
    end
end
c = colorbar(h,'Position',[0.91 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        

hold off


%save 
fig_name = ['\all_joints_x_leg_phase_allLegs_rotation&abduction_averages_binnedByRotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - allFlies - polarCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% MEAN NORMED of Joint Rotation & Abduction x Phase, all joints, all legs, across flies, color by Rotational speed - polar & cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


% max_speed_x = 300; 
% max_speed_y = 200; 
min_speed_z = 0;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numJoints = width(joints);

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19, 2,8,14,20, 3,9,15,21, 4,10,16,22, 5,11,17,23, 6,12,18,24];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
    
    for joint = 1:numJoints
        i = i+1;
        subplot(numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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


        %calculate average step, across speed bins, for this joint
        avg_step = NaN(1,numPhaseBins);
        for pb = 1:numPhaseBins
            avg_step(pb) = mean(joint_data(phase_data >= phaseBins(pb) & phase_data < phaseBins(pb+1)), 'omitnan');
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
        colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?
        
        %plot speed binned averages
        cmap = colormap(colors);
        for sb = 1:numSpeedBins
    %         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            if contains(joints{joint}, 'rot')
                polarplot(phaseBinCenters, mean_joint_x_phase(sb,:)-avg_step, 'color', colors(sb,:), 'linewidth', 2);hold on
            else
                plot(phaseBinCenters, mean_joint_x_phase(sb,:)-avg_step, 'color', colors(sb,:), 'linewidth', 2); hold on
            end
        end
        
        %limit rho for polar plots so negative values get plotted correctly
        %and data is as large as possible
        if contains(joints{joint}, 'rot')
            rmin = min(min(mean_joint_x_phase(:,:)-avg_step));
            rmax = max(max(mean_joint_x_phase(:,:)-avg_step));
            rlim([rmin rmax]);
        end


        if contains(joints{joint}, 'rot')
            pax = gca;
            % pax.FontSize = 30;
            pax.RColor = Color(param.baseColor);
            pax.ThetaColor = Color(param.baseColor);
            % rlim([0 180])
            % rticks([0,45,90,135,180])
            % rticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
            rtickangle(pax, 45);
            thetaticks([0, 90, 180, 270]);
            thetaticklabels({'0', '\pi/2', '\pi', '3\pi/4'});
        else
            ax = gca;
            ax.FontSize = 20;
            xticks([-pi, 0, pi]);
            xticklabels({'-\pi','0', '\pi'});
        end

        if joint == 1 & leg == 1
            title([param.legs{leg} ' ' strrep(joints{joint}, '_', ' ')]);
        elseif joint == 1 & leg > 1
            title([param.legs{leg}]);
        elseif leg == 1
            title(strrep(joints{joint}, '_', ' '));
        end

        if leg == 1
            %TODO label the joint 
        end
        
        if contains(joints{joint}, 'rot')
            fig = formatFigPolar(fig, true);
        else
            fig = formatFig(fig, true);
        end



        hold off
    end
end

% fig = formatFigPolar(fig, true, [numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1 
        tickLabels{t} = '(CW)'; 
    elseif t == width(binEdges)
        tickLabels{t} = '(CCW)'; 
    else
        tickLabels{t} = num2str(binEdges(t)); 
    end
end
c = colorbar(h,'Position',[0.91 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        

hold off


%save 
fig_name = ['\all_joints_x_leg_phase_allLegs_rotation&abduction_averageNormedByAvgStep_binnedByRotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - allFlies - polarCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% STD of Joint Rotation & Abduction x Phase, all joints, all legs, across flies, color by Rotational speed - polar & cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


% max_speed_x = 300; 
% max_speed_y = 200; 
min_speed_z = 0;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numJoints = width(joints);

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19, 2,8,14,20, 3,9,15,21, 4,10,16,22, 5,11,17,23, 6,12,18,24];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
    
    for joint = 1:numJoints
        i = i+1;
        subplot(numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
        binWidth = 2*pi/numPhaseBins;
        phaseBins = -pi:binWidth:pi;
        phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot
    
        std_joint_x_phase = NaN(numSpeedBins, numPhaseBins);
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
                std_joint_x_phase(sb,pb) = std(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
%                 mean_joint_x_phase(sb,pb) = mean(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)), 'omitnan');
                numTrials(sb,pb) = height(binned_joint_data(binned_phase_data >= phaseBins(pb) & binned_phase_data < phaseBins(pb+1)));
            end
        end
    
        if tossSmallBins
            %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
            for sb = 1:numSpeedBins
                if mean(numTrials(sb,:)) < minAvgSteps
                    std_joint_x_phase(sb,:) = NaN; %'erase' these values so they aren't plotted
                end
            end
        end
    
        %colors for plotting speed binned averages
        colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?
        
        %plot speed binned averages
        cmap = colormap(colors);
        for sb = 1:numSpeedBins
    %         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            if contains(joints{joint}, 'rot')
                polarplot(phaseBinCenters, std_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
            else
                plot(phaseBinCenters, std_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2); hold on
            end
        end
    
        if contains(joints{joint}, 'rot')
            pax = gca;
            % pax.FontSize = 30;
            pax.RColor = Color(param.baseColor);
            pax.ThetaColor = Color(param.baseColor);
            % rlim([0 180])
            % rticks([0,45,90,135,180])
            % rticklabels({['0' char(176)], ['45' char(176)], ['90' char(176)], ['135' char(176)], ['180' char(176)],});
            rtickangle(pax, 45);
            thetaticks([0, 90, 180, 270]);
            thetaticklabels({'0', '\pi/2', '\pi', '3\pi/4'});
        else
            ax = gca;
            ax.FontSize = 20;
            xticks([-pi, 0, pi]);
            xticklabels({'-\pi','0', '\pi'});
        end

        if joint == 1 & leg == 1
            title([param.legs{leg} ' ' strrep(joints{joint}, '_', ' ')]);
        elseif joint == 1 & leg > 1
            title([param.legs{leg}]);
        elseif leg == 1
            title(strrep(joints{joint}, '_', ' '));
        end

        if leg == 1
            %TODO label the joint 
        end
        
        if contains(joints{joint}, 'rot')
            fig = formatFigPolar(fig, true);
        else
            fig = formatFig(fig, true);
        end



        hold off
    end
end

% fig = formatFigPolar(fig, true, [numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1 
        tickLabels{t} = '(CW)'; 
    elseif t == width(binEdges)
        tickLabels{t} = '(CCW)'; 
    else
        tickLabels{t} = num2str(binEdges(t)); 
    end
end
c = colorbar(h,'Position',[0.91 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        

hold off


%save 
fig_name = ['\all_joints_x_leg_phase_allLegs_rotation&abduction_averageStandardDeviations_binnedByRotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - allFlies - polarCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% VELOCITY of Joint Rotation and Abduction x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps =200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

% joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
joints = {'A_abduct', 'A_rot_unwrapped', 'B_rot_unwrapped', 'C_rot_unwrapped'};
% phases = {'A_abduct_phase', 'A_rot_phase', 'B_rot_phase', 'C_rot_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


% max_speed_x = 300; 
% max_speed_y = 200; 
min_speed_z = 0;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);

        %take derivative of data to get velocity 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];

        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
        colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?
        
        %plot speed binned averages
        cmap = colormap(colors);
        for sb = 1:numSpeedBins
    %         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
%             if joint == 1 %abduction
%                 ylabel([strrep(joints{joint}, '_', ' ') ' (' char(176) ')']);
%             else % change in rotation 
                ylabel([strrep(joints{joint}, '_', ' ') ' (' char(176) '/s)']);
%             end

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1 
        tickLabels{t} = '(CW)'; 
    elseif t == width(binEdges)
        tickLabels{t} = '(CCW)'; 
    else
        tickLabels{t} = num2str(binEdges(t)); 
    end
end
c = colorbar(h,'Position',[0.91 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        

hold off

%save 
fig_name = ['\all_joints_x_leg_phase_allLegs_rotation&abduction_averageVelocity_binnedByRotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% VELOCITY NORMED Joint Rotation and Abduction x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps =200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

% joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
joints = {'A_abduct', 'A_rot_unwrapped', 'B_rot_unwrapped', 'C_rot_unwrapped'};
% phases = {'A_abduct_phase', 'A_rot_phase', 'B_rot_phase', 'C_rot_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


% max_speed_x = 300; 
% max_speed_y = 200; 
min_speed_z = 0;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);

        %take derivative of data to get velocity 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];

        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
        
        %calculate average step, across speed bins, for this joint
        avg_step = NaN(1,numPhaseBins);
        for pb = 1:numPhaseBins
            avg_step(pb) = mean(joint_data(phase_data >= phaseBins(pb) & phase_data < phaseBins(pb+1)), 'omitnan');
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
        colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?
        
        %plot speed binned averages
        cmap = colormap(colors);
        for sb = 1:numSpeedBins
    %         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, mean_joint_x_phase(sb,:)-avg_step, 'color', colors(sb,:), 'linewidth', 2);hold on
        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
%             if joint == 1 %abduction
%                 ylabel([strrep(joints{joint}, '_', ' ') ' (' char(176) ')']);
%             else % change in rotation 
                ylabel(['\Delta' strrep(joints{joint}, '_', ' ') ' (' char(176) '/s)']);
%             end

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1 
        tickLabels{t} = '(CW)'; 
    elseif t == width(binEdges)
        tickLabels{t} = '(CCW)'; 
    else
        tickLabels{t} = num2str(binEdges(t)); 
    end
end
c = colorbar(h,'Position',[0.91 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        

hold off

%save 
fig_name = ['\all_joints_x_leg_phase_allLegs_rotation&abduction_averageVelocityNormedByAvgStep_binnedByRotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% ACCELERATION of Joint Rotation and Abduction x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps =200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

% joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
joints = {'A_abduct', 'A_rot_unwrapped', 'B_rot_unwrapped', 'C_rot_unwrapped'};
% phases = {'A_abduct_phase', 'A_rot_phase', 'B_rot_phase', 'C_rot_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


% max_speed_x = 300; 
% max_speed_y = 200; 
min_speed_z = 0;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);

        %take derivative of data to get velocity 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
        %take derivative of data to get acceleration 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];

        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
        colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?
        
        %plot speed binned averages
        cmap = colormap(colors);
        for sb = 1:numSpeedBins
    %         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
%             if joint == 1 %abduction
%                 ylabel([strrep(joints{joint}, '_', ' ') ' (' char(176) ')']);
%             else % change in rotation 
                ylabel([strrep(joints{joint}, '_', ' ') ' (' char(176) '/s^2)']);
%             end

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1 
        tickLabels{t} = '(CW)'; 
    elseif t == width(binEdges)
        tickLabels{t} = '(CCW)'; 
    else
        tickLabels{t} = num2str(binEdges(t)); 
    end
end
c = colorbar(h,'Position',[0.91 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        

hold off

%save 
fig_name = ['\all_joints_x_leg_phase_allLegs_rotation&abduction_averageAcceleration_binnedByRotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% JERK of Joint Rotation and Abduction x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps =200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

% joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
joints = {'A_abduct', 'A_rot_unwrapped', 'B_rot_unwrapped', 'C_rot_unwrapped'};
% phases = {'A_abduct_phase', 'A_rot_phase', 'B_rot_phase', 'C_rot_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


% max_speed_x = 300; 
% max_speed_y = 200; 
min_speed_z = 0;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);

        %take derivative of data to get velocity 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
        %take derivative of data to get acceleration 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];
        %take derivative of data to get jerk 
        joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data), 1)];

        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
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
        colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?
        
        %plot speed binned averages
        cmap = colormap(colors);
        for sb = 1:numSpeedBins
    %         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
%             if joint == 1 %abduction
%                 ylabel([strrep(joints{joint}, '_', ' ') ' (' char(176) ')']);
%             else % change in rotation 
                ylabel([strrep(joints{joint}, '_', ' ') ' (' char(176) '/s^3)']);
%             end

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1 
        tickLabels{t} = '(CW)'; 
    elseif t == width(binEdges)
        tickLabels{t} = '(CCW)'; 
    else
        tickLabels{t} = num2str(binEdges(t)); 
    end
end
c = colorbar(h,'Position',[0.91 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        

hold off

%save 
fig_name = ['\all_joints_x_leg_phase_allLegs_rotation&abduction_averageJerk_binnedByRotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% 
% STEP METRICS
%% STEP LENGTH x Rotational Velocity, all legs, across flies. 

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

% max_speed_x = 1000; 
% max_speed_y = 10; 
min_speed_z = 0;

metric = 'step_length'; 
dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);

    subplot(2,3,legOrder(leg)); 
  
    %bin data
    leg_data = steps.leg(leg).meta.(metric)(idxs);
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data = NaN(numSpeedBins, 1);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data = leg_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data(sb) = mean(binned_leg_data, 'omitnan');
        numTrials(sb) = height(binned_leg_data);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data(sb) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?

    %plot speed binned averages
    cmap = colormap(colors); 
    scatter(binEdges(2:end), mean_leg_data, dotSize, 'filled'); hold on
    
    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        ylabel([strrep(metric, '_', ' ') ' (L1 coxa length)']);
        xlabel('Rotational velocity (mm/s)')
        xl = xticklabels; %returns the x-axis tick labels for the current axes.
        xl(1) = {'(CW)'};
        xl(end) = {'(CCW)'};
        xticklabels(xl)
    end
    title(param.legs{leg});
    


    hold off
end

fig = formatFig(fig, true, [2,3]);      

hold off

%save 
fig_name = ['\' metric '_average_x_rotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% STEP LENGTH x Rotational Velocity, all legs, single flies. 

clearvars('-except',initial_vars{:}); initial_vars = who; 

flyNum = 2; %adjust this 
fly = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 
fullfly = flyList.flyid{flyNum};

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 20; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

% max_speed_x = 1000; 
% max_speed_y = 10; 
min_speed_z = 0;

metric = 'step_length'; 
dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(contains(steps.leg(leg).meta.fly, fly) & abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(contains(steps.leg(leg).meta.fly, fly) & ...
%                      abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                          steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                      abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);

    subplot(2,3,legOrder(leg)); 
  
    %bin data
    leg_data = steps.leg(leg).meta.(metric)(idxs);
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data = NaN(numSpeedBins, 1);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data = leg_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data(sb) = mean(binned_leg_data, 'omitnan');
        numTrials(sb) = height(binned_leg_data);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data(sb) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?

    %plot speed binned averages
    cmap = colormap(colors); 
    scatter(binEdges(2:end), mean_leg_data, dotSize, 'filled'); hold on
    
    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        ylabel([strrep(metric, '_', ' ') ' (L1 coxa length)']);
        xlabel('Rotational velocity (mm/s)')
        xl = xticklabels; %returns the x-axis tick labels for the current axes.
        xl(1) = {'(CW)'};
        xl(end) = {'(CCW)'};
        xticklabels(xl)
    end
    title(param.legs{leg});
    


    hold off
end

fig = formatFig(fig, true, [2,3]);      

hold off

%save 
fig_name = ['\' metric '_average_x_rotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - ' fullfly ' - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% STEP DURATION x Rotational Velocity, all legs, across flies. 

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

% max_speed_x = 1000; 
% max_speed_y = 10; 
min_speed_z = 0;

metric = 'step_duration'; 
dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);

    subplot(2,3,legOrder(leg)); 
  
    %bin data
    leg_data = steps.leg(leg).meta.(metric)(idxs);
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data = NaN(numSpeedBins, 1);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data = leg_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data(sb) = mean(binned_leg_data, 'omitnan');
        numTrials(sb) = height(binned_leg_data);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data(sb) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?

    %plot speed binned averages
    cmap = colormap(colors); 
    scatter(binEdges(2:end), mean_leg_data, dotSize, 'filled'); hold on
    
    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        ylabel([strrep(metric, '_', ' ') ' (s)']);
        xlabel('Rotational velocity (mm/s)')
        xl = xticklabels; %returns the x-axis tick labels for the current axes.
        xl(1) = {'(CW)'};
        xl(end) = {'(CCW)'};
        xticklabels(xl)
    end
    title(param.legs{leg});
    


    hold off
end

fig = formatFig(fig, true, [2,3]);      

hold off

%save 
fig_name = ['\' metric '_average_x_rotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% STEP DURATION x Rotational Velocity, all legs, single flies. 

clearvars('-except',initial_vars{:}); initial_vars = who; 

flyNum = 2; %adjust this 
fly = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 
fullfly = flyList.flyid{flyNum};

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 20; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

% max_speed_x = 1000; 
% max_speed_y = 10; 
min_speed_z = 0;

metric = 'step_duration'; 
dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(contains(steps.leg(leg).meta.fly, fly) & abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(contains(steps.leg(leg).meta.fly, fly) & ...
%                      abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                          steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                      abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);

    subplot(2,3,legOrder(leg)); 
  
    %bin data
    leg_data = steps.leg(leg).meta.(metric)(idxs);
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data = NaN(numSpeedBins, 1);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data = leg_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data(sb) = mean(binned_leg_data, 'omitnan');
        numTrials(sb) = height(binned_leg_data);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data(sb) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?

    %plot speed binned averages
    cmap = colormap(colors); 
    scatter(binEdges(2:end), mean_leg_data, dotSize, 'filled'); hold on
    
    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        ylabel([strrep(metric, '_', ' ') ' (s)']);
        xlabel('Rotational velocity (mm/s)')
        xl = xticklabels; %returns the x-axis tick labels for the current axes.
        xl(1) = {'(CW)'};
        xl(end) = {'(CCW)'};
        xticklabels(xl)
    end
    title(param.legs{leg});
    


    hold off
end

fig = formatFig(fig, true, [2,3]);      

hold off

%save 
fig_name = ['\' metric '_average_x_rotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - ' fullfly ' - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% SWING DURATION x Rotational Velocity, all legs, across flies. 

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

% max_speed_x = 1000; 
% max_speed_y = 10; 
min_speed_z = 0;

metric = 'swing_duration'; 
dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);

    subplot(2,3,legOrder(leg)); 
  
    %bin data
    leg_data = steps.leg(leg).meta.(metric)(idxs);
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data = NaN(numSpeedBins, 1);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data = leg_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data(sb) = mean(binned_leg_data, 'omitnan');
        numTrials(sb) = height(binned_leg_data);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data(sb) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?

    %plot speed binned averages
    cmap = colormap(colors); 
    scatter(binEdges(2:end), mean_leg_data, dotSize, 'filled'); hold on
    
    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        ylabel([strrep(metric, '_', ' ') ' (s)']);
        xlabel('Rotational velocity (mm/s)')
        xl = xticklabels; %returns the x-axis tick labels for the current axes.
        xl(1) = {'(CW)'};
        xl(end) = {'(CCW)'};
        xticklabels(xl)
    end
    title(param.legs{leg});
    


    hold off
end

fig = formatFig(fig, true, [2,3]);      

hold off

%save 
fig_name = ['\' metric '_average_x_rotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% SWING DURATION x Rotational Velocity, all legs, single flies. 

clearvars('-except',initial_vars{:}); initial_vars = who; 

flyNum = 2; %adjust this 
fly = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 
fullfly = flyList.flyid{flyNum};

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 20; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

% max_speed_x = 1000; 
% max_speed_y = 10; 
min_speed_z = 0;

metric = 'swing_duration'; 
dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(contains(steps.leg(leg).meta.fly, fly) & abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(contains(steps.leg(leg).meta.fly, fly) & ...
%                      abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                          steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                      abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);

    subplot(2,3,legOrder(leg)); 
  
    %bin data
    leg_data = steps.leg(leg).meta.(metric)(idxs);
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data = NaN(numSpeedBins, 1);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data = leg_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data(sb) = mean(binned_leg_data, 'omitnan');
        numTrials(sb) = height(binned_leg_data);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data(sb) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?

    %plot speed binned averages
    cmap = colormap(colors); 
    scatter(binEdges(2:end), mean_leg_data, dotSize, 'filled'); hold on
    
    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        ylabel([strrep(metric, '_', ' ') ' (s)']);
        xlabel('Rotational velocity (mm/s)')
        xl = xticklabels; %returns the x-axis tick labels for the current axes.
        xl(1) = {'(CW)'};
        xl(end) = {'(CCW)'};
        xticklabels(xl)
    end
    title(param.legs{leg});
    


    hold off
end

fig = formatFig(fig, true, [2,3]);      

hold off

%save 
fig_name = ['\' metric '_average_x_rotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - ' fullfly ' - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% STANCE DURATION x Rotational Velocity, all legs, across flies. 

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

% max_speed_x = 1000; 
% max_speed_y = 10; 
min_speed_z = 0;

metric = 'stance_duration'; 
dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);

    subplot(2,3,legOrder(leg)); 
  
    %bin data
    leg_data = steps.leg(leg).meta.(metric)(idxs);
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data = NaN(numSpeedBins, 1);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data = leg_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data(sb) = mean(binned_leg_data, 'omitnan');
        numTrials(sb) = height(binned_leg_data);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data(sb) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?

    %plot speed binned averages
    cmap = colormap(colors); 
    scatter(binEdges(2:end), mean_leg_data, dotSize, 'filled'); hold on
    
    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        ylabel([strrep(metric, '_', ' ') ' (s)']);
        xlabel('Rotational velocity (mm/s)')
        xl = xticklabels; %returns the x-axis tick labels for the current axes.
        xl(1) = {'(CW)'};
        xl(end) = {'(CCW)'};
        xticklabels(xl)
        xtickangle(0)
    end
    title(param.legs{leg});
    


    hold off
end

fig = formatFig(fig, true, [2,3]);      

hold off

%save 
fig_name = ['\' metric '_average_x_rotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% STANCE DURATION x Rotational Velocity, all legs, single flies. 

clearvars('-except',initial_vars{:}); initial_vars = who; 

flyNum = 2; %adjust this 
fly = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 
fullfly = flyList.flyid{flyNum};

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 20; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

% max_speed_x = 1000; 
% max_speed_y = 10; 
min_speed_z = 0;

metric = 'stance_duration'; 
dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(contains(steps.leg(leg).meta.fly, fly) & abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(contains(steps.leg(leg).meta.fly, fly) & ...
%                      abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                          steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                      abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);

    subplot(2,3,legOrder(leg)); 
  
    %bin data
    leg_data = steps.leg(leg).meta.(metric)(idxs);
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data = NaN(numSpeedBins, 1);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data = leg_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data(sb) = mean(binned_leg_data, 'omitnan');
        numTrials(sb) = height(binned_leg_data);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data(sb) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?

    %plot speed binned averages
    cmap = colormap(colors); 
    scatter(binEdges(2:end), mean_leg_data, dotSize, 'filled'); hold on
    
    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        ylabel([strrep(metric, '_', ' ') ' (s)']);
        xlabel('Rotational velocity (mm/s)')
        xl = xticklabels; %returns the x-axis tick labels for the current axes.
        xl(1) = {'(CW)'};
        xl(end) = {'(CCW)'};
        xticklabels(xl)
    end
    title(param.legs{leg});
    


    hold off
end

fig = formatFig(fig, true, [2,3]);      

hold off

%save 
fig_name = ['\' metric '_average_x_rotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - ' fullfly ' - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% AEP & PEP x Rotational Velocity, all legs, across flies. 

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

% max_speed_x = 1000; 
% max_speed_y = 10; 
min_speed_z = 0;

metricA = 'AEP';
metricB = 'PEP';
type = '2D'; %2D or 3D (2D is y,x)

dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

directions = {'x', 'y', 'z'}; 

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);

    

    subplot(2,3,legOrder(leg)); 

    clear leg_data_A leg_data_B
  
    %bin data
    for d = 1:width(directions)
        leg_data_A(:,d) = steps.leg(leg).meta.([metricA '_E_' directions{d}])(idxs);
        leg_data_B(:,d) = steps.leg(leg).meta.([metricB '_E_' directions{d}])(idxs);
    end
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data_A = NaN(numSpeedBins, 3);
    mean_leg_data_B = NaN(numSpeedBins, 3);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data_A = leg_data_A(bins == sb, :);
        binned_leg_data_B = leg_data_B(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data_A);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data_A(sb,:) = mean(binned_leg_data_A, 'omitnan');
        mean_leg_data_B(sb,:) = mean(binned_leg_data_B, 'omitnan');
        numTrials(sb) = height(binned_leg_data_A);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data_A(sb,:) = NaN; %'erase' these values so they aren't plotted
                mean_leg_data_B(sb,:) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?

    %plot speed binned averages
    cmap = colormap(colors); 

    if contains(type, '3D')
        scatter3(mean_leg_data_A(:,1), mean_leg_data_A(:,2), mean_leg_data_A(:,3), dotSize, 1:numSpeedBins, "o"); hold on; 
        scatter3(mean_leg_data_B(:,1), mean_leg_data_B(:,2), mean_leg_data_B(:,3), dotSize, 1:numSpeedBins, 'filled', 'square'); hold on
    elseif contains(type, '2D')
        scatter(mean_leg_data_A(:,2), mean_leg_data_A(:,1), dotSize, 1:numSpeedBins, "o", 'filled'); hold on; 
        scatter(mean_leg_data_B(:,2), mean_leg_data_B(:,1), dotSize, 1:numSpeedBins, 'filled', 'diamond'); hold on
    end

    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        xlabel('L1/L3 axis (L1 coxa length)');
        ylabel('L1/R1 axis (L1 coxa length)');
        if contains(type, '3D')
            zlabel('Vertical axis (L1 coxa length)');
        end
    end
    title(param.legs{leg});

    set(gca, 'XDir','reverse');

    hold off
end

fig = formatFig(fig, true, [2,3]);      

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1 
        tickLabels{t} = '(CW)'; 
    elseif t == width(binEdges)
        tickLabels{t} = '(CCW)'; 
    else
        tickLabels{t} = num2str(binEdges(t)); 
    end
end
c = colorbar(h,'Position',[0.92 0.168 0.01 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        
       


hold off

% %save 
fig_name = ['\' metricA '_&_' metricB '_' type '_average_x_rotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% AEP & PEP x Rotational Velocity, all legs, single flies. 

clearvars('-except',initial_vars{:}); initial_vars = who;

flyNum = 2; %adjust this 
fly = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 
fullfly = flyList.flyid{flyNum};

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 20; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

% max_speed_x = 1000; 
% max_speed_y = 10; 
min_speed_z = 0;

metricA = 'AEP';
metricB = 'PEP';
type='2D'; %plot 2D or 3D (2D is x,y)

dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

directions = {'x', 'y', 'z'}; 

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);


    subplot(2,3,legOrder(leg)); 

    clear leg_data_A leg_data_B
  
    %bin data
    for d = 1:width(directions)
        leg_data_A(:,d) = steps.leg(leg).meta.([metricA '_E_' directions{d}])(idxs);
        leg_data_B(:,d) = steps.leg(leg).meta.([metricB '_E_' directions{d}])(idxs);
    end
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data_A = NaN(numSpeedBins, 3);
    mean_leg_data_B = NaN(numSpeedBins, 3);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data_A = leg_data_A(bins == sb, :);
        binned_leg_data_B = leg_data_B(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data_A);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data_A(sb,:) = mean(binned_leg_data_A, 'omitnan');
        mean_leg_data_B(sb,:) = mean(binned_leg_data_B, 'omitnan');
        numTrials(sb) = height(binned_leg_data_A);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data_A(sb,:) = NaN; %'erase' these values so they aren't plotted
                mean_leg_data_B(sb,:) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?

    %plot speed binned averages
    cmap = colormap(colors); 
    
    if contains(type, '3D')
        scatter3(mean_leg_data_A(:,1), mean_leg_data_A(:,2), mean_leg_data_A(:,3), dotSize, 1:numSpeedBins, "o"); hold on; 
        scatter3(mean_leg_data_B(:,1), mean_leg_data_B(:,2), mean_leg_data_B(:,3), dotSize, 1:numSpeedBins, 'filled', 'square'); hold on
    elseif contains(type, '2D')
        scatter(mean_leg_data_A(:,2), mean_leg_data_A(:,1), dotSize, 1:numSpeedBins, "o", 'filled'); hold on; 
        scatter(mean_leg_data_B(:,2), mean_leg_data_B(:,1), dotSize, 1:numSpeedBins, 'filled', 'diamond'); hold on
    end

    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        xlabel('L1/L3 axis (L1 coxa length)');
        ylabel('L1/R1 axis (L1 coxa length)');
        if contains(type, '3D')
            zlabel('Vertical axis (L1 coxa length)');
        end
    end
    title(param.legs{leg});

    set(gca, 'XDir','reverse');

    hold off
end

fig = formatFig(fig, true, [2,3]);      

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1 
        tickLabels{t} = '(CW)'; 
    elseif t == width(binEdges)
        tickLabels{t} = '(CCW)'; 
    else
        tickLabels{t} = num2str(binEdges(t)); 
    end
end
c = colorbar(h,'Position',[0.91 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        
       


hold off

% %save 
fig_name = ['\' metricA '_&_' metricB '_' type '_average_x_rotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - ' fullfly ' - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% AEP & PEP x Rotational Velocity, all legs, across flies - ONE plot. 

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

% max_speed_x = 1000; 
% max_speed_y = 10; 
min_speed_z = 0;

metricA = 'AEP';
metricB = 'PEP';
type = '2D'; %2D or 3D (2D is y,x)

dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

directions = {'x', 'y', 'z'}; 

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);

   
    clear leg_data_A leg_data_B
  
    %bin data
    for d = 1:width(directions)
        leg_data_A(:,d) = steps.leg(leg).meta.([metricA '_E_' directions{d}])(idxs);
        leg_data_B(:,d) = steps.leg(leg).meta.([metricB '_E_' directions{d}])(idxs);
    end
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data_A = NaN(numSpeedBins, 3);
    mean_leg_data_B = NaN(numSpeedBins, 3);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data_A = leg_data_A(bins == sb, :);
        binned_leg_data_B = leg_data_B(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data_A);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data_A(sb,:) = mean(binned_leg_data_A, 'omitnan');
        mean_leg_data_B(sb,:) = mean(binned_leg_data_B, 'omitnan');
        numTrials(sb) = height(binned_leg_data_A);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data_A(sb,:) = NaN; %'erase' these values so they aren't plotted
                mean_leg_data_B(sb,:) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?

    %plot speed binned averages
    cmap = colormap(colors); 

    if contains(type, '3D')
        scatter3(mean_leg_data_A(:,1), mean_leg_data_A(:,2), mean_leg_data_A(:,3), dotSize, 1:numSpeedBins, "o"); hold on; 
        scatter3(mean_leg_data_B(:,1), mean_leg_data_B(:,2), mean_leg_data_B(:,3), dotSize, 1:numSpeedBins, 'filled', 'square'); hold on
    elseif contains(type, '2D')
        scatter(mean_leg_data_A(:,2), mean_leg_data_A(:,1), dotSize, 1:numSpeedBins, "o", 'filled'); hold on; 
        scatter(mean_leg_data_B(:,2), mean_leg_data_B(:,1), dotSize, 1:numSpeedBins, 'filled', 'diamond'); hold on
    end

    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        xlabel('L1/L3 axis (L1 coxa length)');
        ylabel('L1/R1 axis (L1 coxa length)');
        if contains(type, '3D')
            zlabel('Vertical axis (L1 coxa length)');
        end
    end

    set(gca, 'XDir','reverse');

end

hold off


fig = formatFig(fig, true);      

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1 
        tickLabels{t} = '(CW)'; 
    elseif t == width(binEdges)
        tickLabels{t} = '(CCW)'; 
    else
        tickLabels{t} = num2str(binEdges(t)); 
    end
end
c = colorbar(h,'Position',[0.92 0.168 0.01 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        
       


hold off

% %save 
fig_name = ['\' metricA '_&_' metricB '_' type '_average_x_rotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - allFlies - graphCoords - onePlot'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% AEP & PEP x Rotational Velocity, all legs, single flies - ONE plot. 

clearvars('-except',initial_vars{:}); initial_vars = who;

flyNum = 2; %adjust this 
fly = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 
fullfly = flyList.flyid{flyNum};

%params
numSpeedBins = 20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 20; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

% max_speed_x = 1000; 
% max_speed_y = 10; 
min_speed_z = 0;

metricA = 'AEP';
metricB = 'PEP';
type='2D'; %plot 2D or 3D (2D is x,y)

dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_z'; %var in steps.meta

directions = {'x', 'y', 'z'}; 

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
maxSpeed = 40;
binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;

for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);
%     idxs = find(abs(steps.leg(leg).meta.avg_speed_z) < max_speed_x & ...
%                     steps.leg(leg).meta.avg_speed_y < max_speed_y & ...
%                 abs(steps.leg(leg).meta.avg_speed_z) > min_speed_z);


    clear leg_data_A leg_data_B
  
    %bin data
    for d = 1:width(directions)
        leg_data_A(:,d) = steps.leg(leg).meta.([metricA '_E_' directions{d}])(idxs);
        leg_data_B(:,d) = steps.leg(leg).meta.([metricB '_E_' directions{d}])(idxs);
    end
    speed_data = steps.leg(leg).meta.(color)(idxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(idxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data_A = NaN(numSpeedBins, 3);
    mean_leg_data_B = NaN(numSpeedBins, 3);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data_A = leg_data_A(bins == sb, :);
        binned_leg_data_B = leg_data_B(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data_A);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data_A(sb,:) = mean(binned_leg_data_A, 'omitnan');
        mean_leg_data_B(sb,:) = mean(binned_leg_data_B, 'omitnan');
        numTrials(sb) = height(binned_leg_data_A);
    end
    
    if tossSmallBins
        %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
        for sb = 1:numSpeedBins
            if mean(numTrials(sb)) < minAvgSteps
                mean_leg_data_A(sb,:) = NaN; %'erase' these values so they aren't plotted
                mean_leg_data_B(sb,:) = NaN; %'erase' these values so they aren't plotted
            end
        end
    end
    
    %colors for plotting speed binned averages
    colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?

    %plot speed binned averages
    cmap = colormap(colors); 
    
    if contains(type, '3D')
        scatter3(mean_leg_data_A(:,1), mean_leg_data_A(:,2), mean_leg_data_A(:,3), dotSize, 1:numSpeedBins, "o"); hold on; 
        scatter3(mean_leg_data_B(:,1), mean_leg_data_B(:,2), mean_leg_data_B(:,3), dotSize, 1:numSpeedBins, 'filled', 'square'); hold on
    elseif contains(type, '2D')
        scatter(mean_leg_data_A(:,2), mean_leg_data_A(:,1), dotSize, 1:numSpeedBins, "o", 'filled'); hold on; 
        scatter(mean_leg_data_B(:,2), mean_leg_data_B(:,1), dotSize, 1:numSpeedBins, 'filled', 'diamond'); hold on
    end

    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        xlabel('L1/L3 axis (L1 coxa length)');
        ylabel('L1/R1 axis (L1 coxa length)');
        if contains(type, '3D')
            zlabel('Vertical axis (L1 coxa length)');
        end
    end

    set(gca, 'XDir','reverse');

end

hold off

fig = formatFig(fig, true);      

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    if t == 1 
        tickLabels{t} = '(CW)'; 
    elseif t == width(binEdges)
        tickLabels{t} = '(CCW)'; 
    else
        tickLabels{t} = num2str(binEdges(t)); 
    end
end
c = colorbar(h,'Position',[0.91 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Rotational velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        
       


hold off

% %save 
fig_name = ['\' metricA '_&_' metricB '_' type '_average_x_rotationalSpeed - ' num2str(numSpeedBins) '_bins - speed range z_above_' num2str(min_speed_z) ' - ' fullfly ' - graphCoords - onePlot'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% %%%%%%%% EXPLORING THE SPEED SPACE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Work in progress... plotting step freq x 3D speed space... 

% trying... step freq heatmap with x,y,z speed axes... 

scatter3(steps.leg(1).meta.avg_speed_x, steps.leg(1).meta.avg_speed_y, steps.leg(1).meta.avg_speed_z, [], steps.leg(1).meta.step_frequency);

idxs = find(steps.leg(1).meta.avg_speed_y < 30 & ...
        abs(steps.leg(1).meta.avg_speed_x) < 40);

nBins = 25; 
[xData, xBinEdges] = discretize(steps.leg(1).meta.avg_speed_x(idxs), nBins); 
[yData, yBinEdges] = discretize(steps.leg(1).meta.avg_speed_y(idxs), nBins); 
[zData, zBinEdges] = discretize(steps.leg(1).meta.avg_speed_z(idxs), nBins);
cData = steps.leg(1).meta.step_frequency(idxs);

pltData = table(xData, yData, zData, cData);

fig = fullfig;
h = heatmap(pltData, 'xData', 'yData', 'ColorVariable', 'cData');
h.XLabel = num2str(xBinEdges(1:end-1)); 
h.YLabel = yBinEdges(1:end-1);
colors = jet(nBins); %order: slow to fast
cmap = colormap(colors);
fig = formatFig(fig, true);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
idxs = find(steps.leg(1).meta.avg_speed_y > 5 & steps.leg(1).meta.avg_speed_y < 40 & ...
        abs(steps.leg(1).meta.avg_speed_x) < 40 & abs(steps.leg(1).meta.avg_speed_z) < 40);

xBinEdges = -40:5:40; 
yBinEdges = 5:5:40;
zBinEdges = -40:5:40;

threshold = false; 
minNumSteps = 20;

stepMetricData = NaN(height(idxs), 4); 
stepMetricData(:,1) = discretize(steps.leg(1).meta.avg_speed_x(idxs), xBinEdges);
stepMetricData(:,2) = discretize(steps.leg(1).meta.avg_speed_y(idxs), yBinEdges);
stepMetricData(:,3) = discretize(steps.leg(1).meta.avg_speed_z(idxs), zBinEdges);
stepMetricData(:,4) = steps.leg(1).meta.step_frequency(idxs);

for x = 1:width(xBinEdges)-1
    for y = 1:width(yBinEdges)-1
        for z = 1:width(zBinEdges)-1
            plotData = stepMetricData(stepMetricData(:,1) == x & ...
                                   stepMetricData(:,2) == y & ...
                                   stepMetricData(:,3) == z, 4);
            if threshold
                if height(plotData) >= minNumSteps
                    scatter(xBinEdges(x), yBinEdges(y), [], height(plotData), 'filled'); hold on
                end
            else
                    scatter(xBinEdges(x), yBinEdges(y), [], height(plotData), 'filled'); hold on
            end
        end
    end
end




%%  TESTING ROTATIONAL VELOCITY PLOTS 
%% MEAN Joint x Phase, all legs, across flies, color by Rotational speed - cartesian coordinates%% MEAN Joint x phase, one leg, across flies, color by Foward speed - polar coordinates 
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
    p = polarplot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
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
fig_name = ['\' joint '_x_' phase '_' param.legs{leg} '_leg_averages_binnedByForwardSpeed - ' numSpeedBins '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - polar coords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);
%% MEAN Joint x phase, one leg, across flies, color by Rotational speed - polar coordinates
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
    polarplot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
    
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
fig_name = ['\' joint '_x_' phase '_' param.legs{leg} '_leg_averages_binnedByRotationalSpeed - speed range x_below_' num2str(max_speed_x) ' y_below_' num2str(max_speed_y) ' z_above_' num2str(min_speed_z) ' - allFlies - polar coords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);
%% MEAN Joint x phase, one leg, across flies, color by Sideslip speed - polar coordinates
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
    polarplot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
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
fig_name = ['\' joint '_x_' phase '_' param.legs{leg} '_leg_averages_binnedBySideslipSpeed - speed range x_above_' num2str(min_speed_x) ' y_below_' num2str(max_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - polar coords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

%% 3D MEAN joint traces across forward velocity
max_speed_x = 3;
min_speed_y = 3; 
max_speed_z = 3;

for leg = 1:param.numLegs
    idxs{leg} = {find(steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                  abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ... 
                  abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z)}; 
end
legs = {'L1','L2','L3', 'R1','R2','R3'};
joints = {'A','B','C','D','E'};
Plot_joint_trajectories_avg_step_w_filter(steps, idxs, walkingData, legs, joints, false, param, true, 'avg_speed_y', 10)
%% 3D MEAN joint traces across rotational velocity
for leg = 1:param.numLegs; idxs{leg} = {1:height(steps.leg(leg).meta)}; end
legs = {'L1','L2','L3', 'R1','R2','R3'};
joints = {'A','B','C','D','E'};
Plot_joint_trajectories_avg_step_w_filter(steps, idxs, walkingData, legs, joints, false, param, true, 'avg_speed_z', 4)
%% 3D MEAN joint traces across sideslip velocity (Don't use this unless better than rotation)
for leg = 1:param.numLegs; idxs{leg} = {1:height(steps.leg(leg).meta)}; end
legs = {'L1','L2','L3', 'R1','R2','R3'};
joints = {'A','B','C','D','E'};
Plot_joint_trajectories_avg_step_w_filter(steps, idxs, walkingData, legs, joints, false, param, true, 'avg_speed_x', 4)


%% %%%%%%%%%%%%%%%%TESTING PLOTTING: plot MEAN joint x phase in polar coords no rho range limit
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
%% %%%%%%%%%%%%%%%%TESTING PLOTTING: plot MEAN joint x phase in graph coords. 
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


%% 
% Testing: why is there L2/R2 difference?
%% 
bout = 1;
plot(walkingData.R2_FTi(boutMap.walkingDataIdxs{bout})); hold on;
plot(walkingData.L2_FTi(boutMap.walkingDataIdxs{bout}));
plot(walkingData.fictrac_delta_rot_lab_z_mms(boutMap.walkingDataIdxs{bout}));


hold off;

%%
bout = 1;
filterLen = 100000;
[L2upper,L2lower] = envelope(walkingData.L2_FTi(boutMap.walkingDataIdxs{bout}), filterLen);
[R2upper,R2lower] = envelope(walkingData.R2_FTi(boutMap.walkingDataIdxs{bout}), filterLen);

plot(walkingData.L2_FTi(boutMap.walkingDataIdxs{bout})); hold on;
plot(L2upper);

hold off;

%% 
bout = 1;

prom = 10;
[L2pks, L2pksLocs] = findpeaks((walkingData.L2_FTi(boutMap.walkingDataIdxs{bout})), 'MinPeakProminence', prom);
[L2trs, L2trsLocs] = findpeaks((walkingData.L2_FTi(boutMap.walkingDataIdxs{bout})*-1), 'MinPeakProminence', prom);
[R2pks, R2pksLocs] = findpeaks((walkingData.R2_FTi(boutMap.walkingDataIdxs{bout})), 'MinPeakProminence', prom);
[R2trs, R2trsLocs] = findpeaks((walkingData.R2_FTi(boutMap.walkingDataIdxs{bout})*-1), 'MinPeakProminence', prom);



% plot(walkingData.L2_FTi(boutMap.walkingDataIdxs{bout}));
plot(L2pksLocs, L2pks, 'r'); hold on;
plot(L2trsLocs, L2trs*-1, 'r');
% plot(walkingData.R2_FTi(boutMap.walkingDataIdxs{bout}));
plot(R2pksLocs, R2pks, 'b');
plot(R2trsLocs, R2trs*-1, 'b');
hold off;
%% 
leg = 5;
sz = 1; c = [];
for s = 1:height(steps.leg(leg).meta)
    scatter(steps.leg(leg).FTi_phase(s,:), steps.leg(leg).FTi(s,:), sz,'filled'); hold on;
end
hold off;

plot(steps.leg(leg).FTi_phase', steps.leg(2).FTi');

%how many steps are there where total joint angle change is almost none?
plot(steps.leg(leg).FTi_phase(:, 1:end-1)', diff(steps.leg(2).FTi'));
%% MEAN Joint x Phase, all joints, all legs, across flies, left vs right - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 20; %20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 50; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
% phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
% legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
legOrder = [1,4,7,10,2,5,8,11,3,6,9,12,1,4,7,10,2,5,8,11,3,6,9,12];
legColor = {'blue', 'orange'};
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;
axs = [];
i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                        steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                    abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs/2,legOrder(i)); hold on;
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
        numPhaseBins = 25;
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
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
            if contains(param.legs{leg}, 'L'); clr = 1; else; clr = 2; end
            a = plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', Color(legColor{clr}), 'linewidth', 2);hold on

        end

        if joint == 1 & contains(param.legs{leg}, '1')
            axs(end+1) = a;
        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
            ylabel([joints{joint} ' (' char(176) ')']);
        end
        if joint == 4
            xlabel(['T' param.legs{leg}(end)]);
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end


fig = formatFig(fig, true, [param.numJoints, param.numLegs/2]); 

% h = axes(fig,'visible','off'); 
% ticks = 0:1/numSpeedBins:1;
% tickLabels = {};
% for t = 1:width(binEdges)
%     tickLabels{t} = num2str(binEdges(t)); 
% end
% c = colorbar(h,'Position',[0.92 0.168 0.022 0.7], 'XTick', ticks, ...
%     'XTickLabel',tickLabels);
% c.Label.String = 'Forward velocity (mm/s)';
% c.FontSize = 15;
% c.Label.FontSize = 30;
% 
% c.Color = param.baseColor;
% c.Box = 'off';    

l = legend(axs, {'Left' 'Right'}, 'location', 'best', 'TextColor', 'white');



hold off

%save 
fig_name = ['\all_joints_x_all_phase_allLegs_averages_binnedByForwardSpeed - ' numSpeedBins '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;



%% MEAN Joint x Phase, all joints, all legs, single fly, left vs right - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

fly = flyList.flyid{7}(1:end-2);

%params
numSpeedBins = 1; %20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 50; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
% phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
% legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
legOrder = [1,4,7,10,2,5,8,11,3,6,9,12,1,4,7,10,2,5,8,11,3,6,9,12];
legColor = {'blue', 'orange'};
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;
axs = [];
i = 0;
for leg = 1:param.numLegs
    % get step idxs for this leg witin speed range
    idxs = find(contains(steps.leg(leg).meta.fly, fly) & ...
                     abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                         steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                     abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs/2,legOrder(i)); hold on;
  
        %bin data
        joint_data = steps.leg(leg).(joints{joint})(idxs, :);
        phase_data = steps.leg(leg).(phases{joint})(idxs, :);
        speed_data = steps.leg(leg).meta.(color)(idxs);
        [bins,binEdges] = discretize(speed_data, binEdges);
    
        %counting flies
        fly_data = steps.leg(leg).meta.fly(idxs);
        for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
    
        %phase bins to take averages in
        numPhaseBins = 25;
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
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
            if contains(param.legs{leg}, 'L'); clr = 1; else; clr = 2; end
            a = plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', Color(legColor{clr}), 'linewidth', 2);hold on

        end

        if joint == 1 & contains(param.legs{leg}, '1')
            axs(end+1) = a;
        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
            ylabel([joints{joint} ' (' char(176) ')']);
        end
        if joint == 4
            xlabel(['T' param.legs{leg}(end)]);
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end


fig = formatFig(fig, true, [param.numJoints, param.numLegs/2]); 

% h = axes(fig,'visible','off'); 
% ticks = 0:1/numSpeedBins:1;
% tickLabels = {};
% for t = 1:width(binEdges)
%     tickLabels{t} = num2str(binEdges(t)); 
% end
% c = colorbar(h,'Position',[0.92 0.168 0.022 0.7], 'XTick', ticks, ...
%     'XTickLabel',tickLabels);
% c.Label.String = 'Forward velocity (mm/s)';
% c.FontSize = 15;
% c.Label.FontSize = 30;
% 
% c.Color = param.baseColor;
% c.Box = 'off';    

l = legend(axs, {'Left' 'Right'}, 'location', 'best', 'TextColor', 'white');



hold off

%save 
fig_name = ['\all_joints_x_all_phase_allLegs_averages_binnedByForwardSpeed - ' numSpeedBins '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% MEAN Joint x Phase, all joints, all legs, each fly, left vs right - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

% flyIdxs = [1,4,7,10,13,16];
flyIdxs = 1:23;

% flyIdxs = [1];


%params
numSpeedBins = 1; %20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 10; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
% legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
% legOrder = [1,4,7,10,2,5,8,11,3,6,9,12,1,4,7,10,2,5,8,11,3,6,9,12];
legColor = {'blue', 'orange'};
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;
axs = [];
% i = 0;
for f = 1:width(flyIdxs) %each fly
    fly = flyList.flyid{flyIdxs(f)}(1:end-2);
    i = 0;
    legOrder = [1,4,7,10,2,5,8,11,3,6,9,12,1,4,7,10,2,5,8,11,3,6,9,12];

    for leg = 1:param.numLegs
%     for f = 1:width(flyIdxs) %each fly 

        % get step idxs for this leg witin speed range
        idxs = find(contains(steps.leg(leg).meta.fly, fly) & ...
                         abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                             steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                         abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
        
        for joint = 1:param.numJoints
            i = i+1;
            subplot(param.numJoints,param.numLegs/2,legOrder(i)); hold on;
      
            %bin data
            joint_data = steps.leg(leg).(joints{joint})(idxs, :);
            phase_data = steps.leg(leg).(phases{joint})(idxs, :);
            speed_data = steps.leg(leg).meta.(color)(idxs);
            [bins,binEdges] = discretize(speed_data, binEdges);
        
            %counting flies
            fly_data = steps.leg(leg).meta.fly(idxs);
            for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
        
            %phase bins to take averages in
            numPhaseBins = 25;
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
    %             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
    %             plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
                if contains(param.legs{leg}, 'L'); clr = 1; else; clr = 2; end
                a = plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', Color(legColor{clr}), 'linewidth', 2);hold on
    
            end
    
            if joint == 1 & contains(param.legs{leg}, '1')
                axs(end+1) = a;
            end
        
            
            ax = gca;
            ax.FontSize = 20;
            xticks([-pi, 0, pi]);
            
            if leg == 1
                ylabel([joints{joint} ' (' char(176) ')']);
            end
            if joint == 4
                xlabel(['T' param.legs{leg}(end)]);
                xticklabels({'-\pi','0', '\pi'});
            else
                xticklabels([]);
            end
            hold off
        end
    end
end


fig = formatFig(fig, true, [param.numJoints, param.numLegs/2]); 

% h = axes(fig,'visible','off'); 
% ticks = 0:1/numSpeedBins:1;
% tickLabels = {};
% for t = 1:width(binEdges)
%     tickLabels{t} = num2str(binEdges(t)); 
% end
% c = colorbar(h,'Position',[0.92 0.168 0.022 0.7], 'XTick', ticks, ...
%     'XTickLabel',tickLabels);
% c.Label.String = 'Forward velocity (mm/s)';
% c.FontSize = 15;
% c.Label.FontSize = 30;
% 
% c.Color = param.baseColor;
% c.Box = 'off';    

l = legend(axs, {'Left' 'Right'}, 'location', 'best', 'TextColor', 'white');



hold off

%save 
fig_name = ['\all_joints_x_leg_phase_allLegs_angleAverages_leftVSright_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


%% MEAN Joint Abduct & Rot x Phase, all joints, all legs, each fly, left vs right - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

% flyIdxs = [1,4,7,10,13,16];
flyIdxs = 1:23;

%params
numSpeedBins = 1; %20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 50; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
% phases = {'A_abduct_phase', 'A_rot_phase', 'B_rot_phase', 'C_rot_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
% legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
% legOrder = [1,4,7,10,2,5,8,11,3,6,9,12,1,4,7,10,2,5,8,11,3,6,9,12];
legColor = {'blue', 'orange'};
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;
axs = [];
% i = 0;
for f = 1:width(flyIdxs) %each fly
    fly = flyList.flyid{flyIdxs(f)}(1:end-2);
    i = 0;
    legOrder = [1,4,7,10,2,5,8,11,3,6,9,12,1,4,7,10,2,5,8,11,3,6,9,12];

    for leg = 1:param.numLegs
%     for f = 1:width(flyIdxs) %each fly 

        % get step idxs for this leg within speed range
        idxs = find(contains(steps.leg(leg).meta.fly, fly) & ...
                         abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                             steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                         abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
        
        for joint = 1:param.numJoints
            i = i+1;
            subplot(param.numJoints,param.numLegs/2,legOrder(i)); hold on;
      
            %bin data
            joint_data = steps.leg(leg).(joints{joint})(idxs, :);
            if contains(joints{joint}, 'rot') %if rotation, take diff of data
                joint_data = [diff(joint_data, 1, 2)/(1/param.fps), NaN(height(joint_data),1)]; %pad with a zero to keep array size 
            end
            phase_data = steps.leg(leg).(phases{joint})(idxs, :);
            speed_data = steps.leg(leg).meta.(color)(idxs);
            [bins,binEdges] = discretize(speed_data, binEdges);
        
            %counting flies
            fly_data = steps.leg(leg).meta.fly(idxs);
            for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
        
            %phase bins to take averages in
            numPhaseBins = 25;
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
    %             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
    %             plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
                if contains(param.legs{leg}, 'L'); clr = 1; else; clr = 2; end
                a = plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', Color(legColor{clr}), 'linewidth', 2);hold on
    
            end
    
            if joint == 1 & contains(param.legs{leg}, '1')
                axs(end+1) = a;
            end
        
            
            ax = gca;
            ax.FontSize = 20;
            xticks([-pi, 0, pi]);
            
            if leg == 1
                if joint == 1
                    ylabel([strrep(joints{joint}, '_', ' ') ' (' char(176) ')']);
                else
                    ylabel([strrep(joints{joint}, '_', ' ') ' (' char(176) '/s)']);
                end
            end
            if joint == 4
                xlabel(['T' param.legs{leg}(end)]);
                xticklabels({'-\pi','0', '\pi'});
            else
                xticklabels([]);
            end
            hold off
        end
    end
end


fig = formatFig(fig, true, [param.numJoints, param.numLegs/2]); 

% h = axes(fig,'visible','off'); 
% ticks = 0:1/numSpeedBins:1;
% tickLabels = {};
% for t = 1:width(binEdges)
%     tickLabels{t} = num2str(binEdges(t)); 
% end
% c = colorbar(h,'Position',[0.92 0.168 0.022 0.7], 'XTick', ticks, ...
%     'XTickLabel',tickLabels);
% c.Label.String = 'Forward velocity (mm/s)';
% c.FontSize = 15;
% c.Label.FontSize = 30;
% 
% c.Color = param.baseColor;
% c.Box = 'off';    

l = legend(axs, {'Left' 'Right'}, 'location', 'best', 'TextColor', 'white');



hold off

%save 
fig_name = ['\all_joints_x_leg_phase_allLegs_rotVels&abductAverages_leftVSright_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;






%% MEAN Joint x Phase, all joints, all legs, each fly, left vs right - cartesian coordinates - turning ONE WAY

clearvars('-except',initial_vars{:}); initial_vars = who;

flyIdxs = [1,4,7,10,13,16];

%params
numSpeedBins = 1; %20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 10; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = -3; %3;
min_speed_y = 5; 
max_speed_z = -3; %3;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
% legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
% legOrder = [1,4,7,10,2,5,8,11,3,6,9,12,1,4,7,10,2,5,8,11,3,6,9,12];
legColor = {'blue', 'orange'};
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;
axs = [];
% i = 0;
for f = 1:width(flyIdxs) %each fly
    fly = flyList.flyid{flyIdxs(f)}(1:end-2);
    i = 0;
    legOrder = [1,4,7,10,2,5,8,11,3,6,9,12,1,4,7,10,2,5,8,11,3,6,9,12];

    for leg = 1:param.numLegs
%     for f = 1:width(flyIdxs) %each fly 

        % get step idxs for this leg witin speed range
        idxs = find(contains(steps.leg(leg).meta.fly, fly) & ...
                             steps.leg(leg).meta.avg_speed_x < max_speed_x & ...
                             steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                             steps.leg(leg).meta.avg_speed_z < max_speed_z);
        
        for joint = 1:param.numJoints
            i = i+1;
            subplot(param.numJoints,param.numLegs/2,legOrder(i)); hold on;
      
            %bin data
            joint_data = steps.leg(leg).(joints{joint})(idxs, :);
            phase_data = steps.leg(leg).(phases{joint})(idxs, :);
            speed_data = steps.leg(leg).meta.(color)(idxs);
            [bins,binEdges] = discretize(speed_data, binEdges);
        
            %counting flies
            fly_data = steps.leg(leg).meta.fly(idxs);
            for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
        
            %phase bins to take averages in
            numPhaseBins = 25;
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
    %             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
    %             plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
                if contains(param.legs{leg}, 'L'); clr = 1; else; clr = 2; end
                a = plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', Color(legColor{clr}), 'linewidth', 2);hold on
    
            end
    
            if joint == 1 & contains(param.legs{leg}, '1')
                axs(end+1) = a;
            end
        
            
            ax = gca;
            ax.FontSize = 20;
            xticks([-pi, 0, pi]);
            
            if leg == 1
                ylabel([joints{joint} ' (' char(176) ')']);
            end
            if joint == 4
                xlabel(['T' param.legs{leg}(end)]);
                xticklabels({'-\pi','0', '\pi'});
            else
                xticklabels([]);
            end
            hold off
        end
    end
end


fig = formatFig(fig, true, [param.numJoints, param.numLegs/2]); 

% h = axes(fig,'visible','off'); 
% ticks = 0:1/numSpeedBins:1;
% tickLabels = {};
% for t = 1:width(binEdges)
%     tickLabels{t} = num2str(binEdges(t)); 
% end
% c = colorbar(h,'Position',[0.92 0.168 0.022 0.7], 'XTick', ticks, ...
%     'XTickLabel',tickLabels);
% c.Label.String = 'Forward velocity (mm/s)';
% c.FontSize = 15;
% c.Label.FontSize = 30;
% 
% c.Color = param.baseColor;
% c.Box = 'off';    

l = legend(axs, {'Left' 'Right'}, 'location', 'best', 'TextColor', 'white');



hold off

%save 
fig_name = ['\all_joints_x_all_phase_allLegs_averages_binnedByForwardSpeed - ' numSpeedBins '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;



%% MEAN Joint x Phase, all joints, all legs, each fly, left vs right - cartesian coordinates - turning THE OTHER WAY

clearvars('-except',initial_vars{:}); initial_vars = who;

flyIdxs = [1,4,7,10,13,16];

%params
numSpeedBins = 1; %20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 10; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


min_speed_x = 3; %3;
min_speed_y = 5; 
min_speed_z = 3; %3;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
% legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
% legOrder = [1,4,7,10,2,5,8,11,3,6,9,12,1,4,7,10,2,5,8,11,3,6,9,12];
legColor = {'blue', 'orange'};
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;
axs = [];
% i = 0;
for f = 1:width(flyIdxs) %each fly
    fly = flyList.flyid{flyIdxs(f)}(1:end-2);
    i = 0;
    legOrder = [1,4,7,10,2,5,8,11,3,6,9,12,1,4,7,10,2,5,8,11,3,6,9,12];

    for leg = 1:param.numLegs
%     for f = 1:width(flyIdxs) %each fly 

        % get step idxs for this leg witin speed range
        idxs = find(contains(steps.leg(leg).meta.fly, fly) & ...
                             steps.leg(leg).meta.avg_speed_x > min_speed_x & ...
                             steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                             steps.leg(leg).meta.avg_speed_z > min_speed_z);
        
        for joint = 1:param.numJoints
            i = i+1;
            subplot(param.numJoints,param.numLegs/2,legOrder(i)); hold on;
      
            %bin data
            joint_data = steps.leg(leg).(joints{joint})(idxs, :);
            phase_data = steps.leg(leg).(phases{joint})(idxs, :);
            speed_data = steps.leg(leg).meta.(color)(idxs);
            [bins,binEdges] = discretize(speed_data, binEdges);
        
            %counting flies
            fly_data = steps.leg(leg).meta.fly(idxs);
            for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
        
            %phase bins to take averages in
            numPhaseBins = 25;
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
    %             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
    %             plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
                if contains(param.legs{leg}, 'L'); clr = 1; else; clr = 2; end
                a = plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', Color(legColor{clr}), 'linewidth', 2);hold on
    
            end
    
            if joint == 1 & contains(param.legs{leg}, '1')
                axs(end+1) = a;
            end
        
            
            ax = gca;
            ax.FontSize = 20;
            xticks([-pi, 0, pi]);
            
            if leg == 1
                ylabel([joints{joint} ' (' char(176) ')']);
            end
            if joint == 4
                xlabel(['T' param.legs{leg}(end)]);
                xticklabels({'-\pi','0', '\pi'});
            else
                xticklabels([]);
            end
            hold off
        end
    end
end


fig = formatFig(fig, true, [param.numJoints, param.numLegs/2]); 

% h = axes(fig,'visible','off'); 
% ticks = 0:1/numSpeedBins:1;
% tickLabels = {};
% for t = 1:width(binEdges)
%     tickLabels{t} = num2str(binEdges(t)); 
% end
% c = colorbar(h,'Position',[0.92 0.168 0.022 0.7], 'XTick', ticks, ...
%     'XTickLabel',tickLabels);
% c.Label.String = 'Forward velocity (mm/s)';
% c.FontSize = 15;
% c.Label.FontSize = 30;
% 
% c.Color = param.baseColor;
% c.Box = 'off';    

l = legend(axs, {'Left' 'Right'}, 'location', 'best', 'TextColor', 'white');



hold off

%save 
% fig_name = ['\all_joints_x_all_phase_allLegs_averages_binnedByForwardSpeed - ' numSpeedBins '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
% if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
% save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;




%% MEAN Joint x Phase, all joints, all legs, each fly, left vs right - cartesian coordinates - turning left vs right 

clearvars('-except',initial_vars{:}); initial_vars = who;

flyIdxs = [1,4,7,10,13,16];

%params
numSpeedBins = 1; %20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 10; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'BC', 'CF', 'FTi', 'TiTa'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


% thresh_speed_x = 10; 
min_speed_y = 5; 
thresh_speed_z = 10;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
% legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
% legOrder = [1,4,7,10,2,5,8,11,3,6,9,12,1,4,7,10,2,5,8,11,3,6,9,12];
legColor = {'blue', 'purple', 'orange', 'yellow'};
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;
axs = [];
% i = 0;
for f = 1:width(flyIdxs) %each fly
    fly = flyList.flyid{flyIdxs(f)}(1:end-2);
    i = 0;
    legOrder = [1,4,7,10,2,5,8,11,3,6,9,12,1,4,7,10,2,5,8,11,3,6,9,12];

    for leg = 1:param.numLegs
%     for f = 1:width(flyIdxs) %each fly 

        % get step idxs for this leg witin speed range
        idxs{1} = find(contains(steps.leg(leg).meta.fly, fly) & ...
                                steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                                steps.leg(leg).meta.avg_speed_z < (thresh_speed_z*-1));
        idxs{2} = find(contains(steps.leg(leg).meta.fly, fly) & ...
                                steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                                steps.leg(leg).meta.avg_speed_z > thresh_speed_z);
        
        for joint = 1:param.numJoints
            i = i+1;
            subplot(param.numJoints,param.numLegs/2,legOrder(i)); hold on;
            for t = 1:2 %plot extreme left and right turning 
                %bin data
                joint_data = steps.leg(leg).(joints{joint})(idxs{t}, :);
                phase_data = steps.leg(leg).(phases{joint})(idxs{t}, :);
                speed_data = steps.leg(leg).meta.(color)(idxs{t});
                [bins,binEdges] = discretize(speed_data, binEdges);
            
                %counting flies
                fly_data = steps.leg(leg).meta.fly(idxs{t});
                for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
            
                %phase bins to take averages in
                numPhaseBins = 25;
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
        %             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
        %             plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
                    if contains(param.legs{leg}, 'L')
                        if t == 1; clr = 1; 
                        else; clr = 2; 
                        end
                    else
                        if t == 1; clr = 3;
                        else; clr = 4;
                        end
                    end
                    a = plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', Color(legColor{clr}), 'linewidth', 2);hold on
        
                end
            end
    
            if joint == 1 & contains(param.legs{leg}, '1')
                axs(end+1) = a;
            end
        
            
            ax = gca;
            ax.FontSize = 20;
            xticks([-pi, 0, pi]);
            
            if leg == 1
                ylabel([joints{joint} ' (' char(176) ')']);
            end
            if joint == 4
                xlabel(['T' param.legs{leg}(end)]);
                xticklabels({'-\pi','0', '\pi'});
            else
                xticklabels([]);
            end
            hold off
        end
    end
end


fig = formatFig(fig, true, [param.numJoints, param.numLegs/2]); 

% h = axes(fig,'visible','off'); 
% ticks = 0:1/numSpeedBins:1;
% tickLabels = {};
% for t = 1:width(binEdges)
%     tickLabels{t} = num2str(binEdges(t)); 
% end
% c = colorbar(h,'Position',[0.92 0.168 0.022 0.7], 'XTick', ticks, ...
%     'XTickLabel',tickLabels);
% c.Label.String = 'Forward velocity (mm/s)';
% c.FontSize = 15;
% c.Label.FontSize = 30;
% 
% c.Color = param.baseColor;
% c.Box = 'off';    

l = legend(axs, {'Left' 'Right'}, 'location', 'best', 'TextColor', 'white');



hold off

%save 
% fig_name = ['\all_joints_x_all_phase_allLegs_averages_binnedByForwardSpeed - ' numSpeedBins '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
% if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
% save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;





%% MEAN Joint Abduct & Rot x Phase, all joints, all legs, each fly, left vs right - cartesian coordinates - turning left vs right 

clearvars('-except',initial_vars{:}); initial_vars = who;

flyIdxs = [1,4,7,10,13,16];

%params
numSpeedBins = 1; %20; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 10; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


% thresh_speed_x = 10; 
min_speed_y = 5; 
thresh_speed_z = 10;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
% legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
% legOrder = [1,4,7,10,2,5,8,11,3,6,9,12,1,4,7,10,2,5,8,11,3,6,9,12];
legColor = {'blue', 'purple', 'orange', 'yellow'};
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;
axs = [];
% i = 0;
for f = 1:width(flyIdxs) %each fly
    fly = flyList.flyid{flyIdxs(f)}(1:end-2);
    i = 0;
    legOrder = [1,4,7,10,2,5,8,11,3,6,9,12,1,4,7,10,2,5,8,11,3,6,9,12];

    for leg = 1:param.numLegs
%     for f = 1:width(flyIdxs) %each fly 

        % get step idxs for this leg witin speed range
        idxs{1} = find(contains(steps.leg(leg).meta.fly, fly) & ...
                                steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                                steps.leg(leg).meta.avg_speed_z < (thresh_speed_z*-1));
        idxs{2} = find(contains(steps.leg(leg).meta.fly, fly) & ...
                                steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                                steps.leg(leg).meta.avg_speed_z > thresh_speed_z);
        
        for joint = 1:param.numJoints
            i = i+1;
            subplot(param.numJoints,param.numLegs/2,legOrder(i)); hold on;
            for t = 1:2 %plot extreme left and right turning 
                %bin data
                joint_data = steps.leg(leg).(joints{joint})(idxs{t}, :);
                if contains(joints{joint}, 'rot')
                    joint_data = [diff(joint_data,1,2), NaN(height(joint_data), 1)];
                end
                phase_data = steps.leg(leg).(phases{joint})(idxs{t}, :);
                speed_data = steps.leg(leg).meta.(color)(idxs{t});
                [bins,binEdges] = discretize(speed_data, binEdges);
            
                %counting flies
                fly_data = steps.leg(leg).meta.fly(idxs{t});
                for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end
            
                %phase bins to take averages in
                numPhaseBins = 25;
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
        %             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
        %             plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
                    if contains(param.legs{leg}, 'L')
                        if t == 1; clr = 1; 
                        else; clr = 2; 
                        end
                    else
                        if t == 1; clr = 3;
                        else; clr = 4;
                        end
                    end
                    a = plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', Color(legColor{clr}), 'linewidth', 2);hold on
        
                end
            end
    
            if joint == 1 & contains(param.legs{leg}, '1')
                axs(end+1) = a;
            end
        
            
            ax = gca;
            ax.FontSize = 20;
            xticks([-pi, 0, pi]);
            
            if leg == 1
                ylabel([joints{joint} ' (' char(176) ')']);
            end
            if joint == 4
                xlabel(['T' param.legs{leg}(end)]);
                xticklabels({'-\pi','0', '\pi'});
            else
                xticklabels([]);
            end
            hold off
        end
    end
end


fig = formatFig(fig, true, [param.numJoints, param.numLegs/2]); 

% h = axes(fig,'visible','off'); 
% ticks = 0:1/numSpeedBins:1;
% tickLabels = {};
% for t = 1:width(binEdges)
%     tickLabels{t} = num2str(binEdges(t)); 
% end
% c = colorbar(h,'Position',[0.92 0.168 0.022 0.7], 'XTick', ticks, ...
%     'XTickLabel',tickLabels);
% c.Label.String = 'Forward velocity (mm/s)';
% c.FontSize = 15;
% c.Label.FontSize = 30;
% 
% c.Color = param.baseColor;
% c.Box = 'off';    

l = legend(axs, {'Left' 'Right'}, 'location', 'best', 'TextColor', 'white');



hold off

%save 
% fig_name = ['\all_joints_x_all_phase_allLegs_averages_binnedByForwardSpeed - ' numSpeedBins '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
% if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
% save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;






%%
bout = 400;
fig = fullfig;
joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
order = [1,4,7,10,2,5,8,11,3,6,9,12];
i = 0;
for leg = 1:3
    for joint = 1:4
        i = i+1;
        Ljnt = ['L' num2str(leg) '' joints{joint}];
        Rjnt = ['R' num2str(leg) '' joints{joint}];
        subplot(4,3,order(i));
        plot(walkingData.(Ljnt)(boutMap.walkingDataIdxs{bout}), 'color', Color('blue')); hold on;
        plot(walkingData.(Rjnt)(boutMap.walkingDataIdxs{bout}), 'color', Color('orange'));
        hold off;
        title(['T' num2str(leg) '' strrep(joints{joint}, '_', ' ')]);
    end
end
legend({'left', 'right'}, 'Location', 'best');

%%
bout = 300;
fig = fullfig;
joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
order = [1,4,7,10,2,5,8,11,3,6,9,12];
i = 0;
for leg = 1:3
    for joint = 1:4
        i = i+1;
        Ljnt = ['L' num2str(leg) '' joints{joint}];
        Rjnt = ['R' num2str(leg) '' joints{joint}];
        subplot(4,3,order(i));
        plot(walkingData.(Ljnt)(boutMap.walkingDataIdxs{bout}), 'color', Color('blue')); hold on;
        plot(walkingData.(Rjnt)(boutMap.walkingDataIdxs{bout}), 'color', Color('orange'));
        hold off;
        title(['T' num2str(leg) '' strrep(joints{joint}, '_', ' ')]);
    end
end
legend({'left', 'right'}, 'Location', 'best');


%%
bout = 300;
fig = fullfig;
joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
order = [1,4,7,10,2,5,8,11,3,6,9,12];
idxs = 2500:3000;
i = 0;
for leg = 1:3
    for joint = 1:4
        i = i+1;
        Ljnt = ['L' num2str(leg) '' joints{joint}];
        Rjnt = ['R' num2str(leg) '' joints{joint}];
        subplot(4,3,order(i));
        plot(diff(walkingData.(Ljnt)(boutMap.walkingDataIdxs{bout}(idxs))), 'color', Color('blue')); hold on;
        plot(diff(walkingData.(Rjnt)(boutMap.walkingDataIdxs{bout}(idxs))), 'color', Color('orange'));
        hold off;
        title(['T' num2str(leg) '' strrep(joints{joint}, '_', ' ')]);
    end
end
legend({'left', 'right'}, 'Location', 'best');


%%
idxs = [1:1000];
plot(data.L2A_abduct(idxs)); hold on;
plot(data.L2A_flex(idxs)); 
plot(data.L2A_rot(idxs));
hold off;

plot(tempData.L2A_abduct(idxs)); hold on;
plot(tempData.L2A_flex(idxs)); 
plot(tempData.L2A_rot(idxs));
hold off;

%%

idxs = [10000:13000];
i = 0;
for leg = 1:param.numLegs
    for joint = 1:param.numJoints-1
        i = i+1;
        subplot(param.numLegs, param.numJoints-1, i);
        jnt = [param.legs{leg} '' param.jointLetters{joint} '_rot'];
        plot(data.(jnt)(idxs)); hold on;
        plot(tempData.(jnt)(idxs)); hold off;
        title(strrep(jnt, '_', ' '));
    end
end

temp = data.(jnt);
fixed = unwrap(temp, 160);
plot(temp); hold on; plot(fixed); hold off;


%make sure that the only time there are big jumps is between vids
plot(abs(diff(fixed))); hold on; xline(find(data.fnum==0)); hold off;

idxs = find(abs(diff(fixed)) > 100);
plot(data.fnum(idxs));



%%

flies = [1,4,7,10,13,16];
fig = fullfig; hold on;
for f = 1:width(flies)
    idx = find(contains(data.flyid, flyList.flyid{f}), 1, 'first'); 
    %plot x,y axes 
    ctr = [data.L1A_x(idx), data.L1A_y(idx), data.L1A_z(idx)]; 
    x = [data.R1A_x(idx), data.R1A_y(idx), data.R1A_z(idx)]; 
    y = [data.L3A_x(idx), data.L3A_y(idx), data.L3A_z(idx)]; 
    xaxis=[x;ctr];
    yaxis=[y;ctr];
    plot3(xaxis(:,1),xaxis(:,2),xaxis(:,3),'y', 'LineWidth', 3); hold on
    plot3(yaxis(:,1),yaxis(:,2),yaxis(:,3),'k', 'LineWidth', 3);
    %plot BC joints 
    plot3(data.L1A_x(idx), data.L1A_y(idx), data.L1A_z(idx), 'ow', 'MarkerSize', 10, 'MarkerFaceColor', Color('blue'));
    plot3(data.L2A_x(idx), data.L2A_y(idx), data.L2A_z(idx), 'ow', 'MarkerSize', 10, 'MarkerFaceColor', Color('orange'));
    plot3(data.L3A_x(idx), data.L3A_y(idx), data.L3A_z(idx), 'ow', 'MarkerSize', 10, 'MarkerFaceColor', Color('green'));
    plot3(data.R1A_x(idx), data.R1A_y(idx), data.R1A_z(idx), 'ow', 'MarkerSize', 10, 'MarkerFaceColor', Color('red'));
    plot3(data.R2A_x(idx), data.R2A_y(idx), data.R2A_z(idx), 'ow', 'MarkerSize', 10, 'MarkerFaceColor', Color('purple'));
    plot3(data.R3A_x(idx), data.R3A_y(idx), data.R3A_z(idx), 'ow', 'MarkerSize', 10, 'MarkerFaceColor', Color('brown'));
end
hold off;













%





%%



f = 1; 
fly = flyList.flyid{1}(1:end-2);
d_idxs = contains(data.flyid, fly);
w_idxs = contains(walkingData.flyid, fly);

hist(walkingDataOld.fictrac_delta_rot_lab_z_mms(d_idxs), 20); hold on;
hist(walkingData.fictrac_delta_rot_lab_z_mms(d_idxs), 20);




%% All joint angles all legs over time for a walking bout 
clearvars('-except',initial_vars{:}); initial_vars = who;

%param:
bout = 68; %row num in boutMap

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

idxs = boutMap.walkingDataIdxs{bout};

joints = {'A_abduct', 'A_flex', 'B_flex', 'C_flex', 'D_flex'};

%plot
order = [1,4,7,10,13,2,5,8,11,14,3,6,9,12,15,1,4,7,10,13,2,5,8,11,14,3,6,9,12,15];
fig = fullfig; hold on 
i = 0;
for leg = 1:param.numLegs
    for joint = 1:5
        i = i+1;
        subplot(5,3,order(i)); hold on;
        if leg < 4
            c = 'green';
        else
            c = 'orange'; 
        end
        plot(walkingData.([param.legs{leg} '' joints{joint}])(idxs), 'linewidth', 2, 'color', Color(c)); 

        if joint == 1 & leg < 4
            title(['T' num2str(leg)]);
        end
        if leg == 1 
            ylabel(joints(joint));
        end
    end
    title(param.legs{leg}, 'FontSize', 30);
    ax=gca;
    ax.FontSize = 20;
    xlim('tight');
    
end

hold off

fig = formatFig(fig, true, [5 3]);

%legend
l = legend({'left', 'right'});
l.Location = 'best';
l.TextColor = 'white';
l.FontSize = 20;

ax=gca;
ax.FontSize = 20;

ylabel(['Angle (' char(176) ')'], 'FontSize', 30);
xlabel('Time (frames)', 'FontSize', 30);

%save 
fig_name = ['\L1_joint_angles_walking_bout_' num2str(bout)];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;


