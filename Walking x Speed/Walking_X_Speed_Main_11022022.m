%Walking x speed analysis updated for new data preprocessing
%Sarah Walling-Bell
%November 2022

%% Load in processed data
% [data, walkingData, param, steps] = loadReadyData('sh_control_all_intact_onball');
[data, walkingData, param, steps] = loadReadyData('split_half_control_all_intact_onball');
[numReps, numConds, flyList, flyIndices] = DLC_extract_flies(data);
initial_vars = who;
%% 
%%%%%%%%%%% Walking Overview %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

%% 
%%%%%%%%%%% Walking x Forward Velocity %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
flies = flyList.flyid;

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_y';

order = 'raw';
type = 'avg';
normed = 'n';

numSpeedBins = 10; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

fig_name = ['\all_joints_x_leg_phase_allLegs_averages_binnedByForwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'speed range x_abs_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_abs_below_' num2str(z_max_abs) ...
            ' - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed, ...
                                           '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN Joint x Phase, all joints, all legs, single fly, color by Foward speed - cartesian coordinates 

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flyNums = [2,3]; %adjust this 
flies = flyList.flyid(flyNums,:); % flies = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_y';

order = 'raw';
type = 'avg';
normed = 'n';

numSpeedBins = 10; 
minAvgSteps = 20; 
numPhaseBins = 20;
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

%format fly names for fig_name
flyNames = [];
for fly = 1:height(flies)
    flyNames = [flyNames, flies{fly}, ' - '];
end
flyNames = flyNames(1:end-3);

fig_name = ['\all_joints_x_leg_phase_allLegs_averages_binnedByForwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'speed range x_abs_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_abs_below_' num2str(z_max_abs) ...
            ' - ' flyNames ' - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed, ...
                                           '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN NORMED Joint x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_y';

order = 'raw';
type = 'avg';
normed = 'y';

numSpeedBins = 10; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

fig_name = ['\all_joints_x_leg_phase_allLegs_averagesNormed_binnedByForwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'speed range x_abs_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_abs_below_' num2str(z_max_abs) ...
            ' - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed, ...
                                           '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% STD Joint x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_y';

order = 'raw';
type = 'std';
normed = 'n';

numSpeedBins = 10; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

fig_name = ['\all_joints_x_leg_phase_allLegs_std_binnedByForwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'speed range x_abs_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_abs_below_' num2str(z_max_abs) ...
            ' - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed, ...
                                           '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% VELOCITY of Joint x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_y';

order = 'velocity';
type = 'avg';
normed = 'n';

numSpeedBins = 10; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

fig_name = ['\all_joints_x_leg_phase_allLegs_averageVelocity_binnedByForwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'speed range x_abs_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_abs_below_' num2str(z_max_abs) ...
            ' - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed, ...
                                           '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% ACCELERATION of Joint x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_y';

order = 'acceleration';
type = 'avg';
normed = 'n';

numSpeedBins = 10; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

fig_name = ['\all_joints_x_leg_phase_allLegs_averageAcceleration_binnedByForwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'speed range x_abs_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_abs_below_' num2str(z_max_abs) ...
            ' - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed, ...
                                           '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% JERK of Joint x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_y';

order = 'jerk';
type = 'avg';
normed = 'n';

numSpeedBins = 10; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

fig_name = ['\all_joints_x_leg_phase_allLegs_averageJerk_binnedByForwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'speed range x_abs_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_abs_below_' num2str(z_max_abs) ...
            ' - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed, ...
                                           '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% 
% ABDUCTION & ROTATIONS
%% MEAN of Joint Rotation & Abduction x Phase, all joints, all legs, across flies, color by Foward speed - polar & cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_y';

order = 'raw';
type = 'avg';
normed = 'n';

numSpeedBins = 10; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

fig_name = ['\all_jointAbduct&Rots_x_leg_phase_allLegs_averages_binnedByForwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'speed range x_abs_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_abs_below_' num2str(z_max_abs) ...
            ' - allFlies - polarCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed, ...
                                           '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN NORMED of Joint Rotation & Abduction x Phase, all joints, all legs, across flies, color by Foward speed - polar & cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_y';

order = 'raw';
type = 'avg';
normed = 'y';

numSpeedBins = 10; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

fig_name = ['\all_jointAbduct&Rots_x_leg_phase_allLegs_averagesNormed_binnedByForwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'speed range x_abs_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_abs_below_' num2str(z_max_abs) ...
            ' - allFlies - polarCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed, ...
                                           '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% STD of Joint Rotation & Abduction x Phase, all joints, all legs, across flies, color by Foward speed - polar & cartesian coordinates
% note: I'm not sure if taking standard deviation normally works for
% rotation data that wraps. the wrapping parts might create higher standard
% deviations. Look into this -> how to do std of rotational data. 

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_y';

order = 'raw';
type = 'std';
normed = 'n';

numSpeedBins = 10; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

fig_name = ['\all_jointAbduct&Rots_x_leg_phase_allLegs_std_binnedByForwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'speed range x_abs_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_abs_below_' num2str(z_max_abs) ...
            ' - allFlies - polarCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed, ...
                                           '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% VELOCITY of Joint Rotation and Abduction x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_abduct', 'A_rot_unwrapped', 'B_rot_unwrapped', 'C_rot_unwrapped'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_y';

order = 'velocity';
type = 'avg';
normed = 'n';

numSpeedBins = 10; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

fig_name = ['\all_jointAbduct&Rots_x_leg_phase_allLegs_averageVelocity_binnedByForwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'speed range x_abs_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_abs_below_' num2str(z_max_abs) ...
            ' - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed, ...
                                           '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% ACCELERATION of Joint Rotation and Abduction x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_abduct', 'A_rot_unwrapped', 'B_rot_unwrapped', 'C_rot_unwrapped'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_y';

order = 'acceleration';
type = 'avg';
normed = 'n';

numSpeedBins = 10; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

fig_name = ['\all_jointAbduct&Rots_x_leg_phase_allLegs_averageAcceleration_binnedByForwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'speed range x_abs_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_abs_below_' num2str(z_max_abs) ...
            ' - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed, ...
                                           '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% JERK of Joint Rotation and Abduction x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_abduct', 'A_rot_unwrapped', 'B_rot_unwrapped', 'C_rot_unwrapped'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_y';

order = 'jerk';
type = 'avg';
normed = 'n';

numSpeedBins = 10; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

fig_name = ['\all_jointAbduct&Rots_x_leg_phase_allLegs_averageJerk_binnedByForwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'speed range x_abs_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_abs_below_' num2str(z_max_abs) ...
            ' - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed, ...
                                           '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% 
% STEP METRICS
%% STEP LENGTH x Forward Velocity, all legs, across flies.
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

metric = 'step_length';
velocity = 'avg_speed_y';

numSpeedBins = 10; 
minAvgSteps = 200; 
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

fig_name = ['\' metric '_average_x_forwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'speed range x_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_below_' num2str(z_max_abs) ...
            ' - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotStepMetricsxVelocity(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, ... 
                                '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% STEP LENGTH x Forward Velocity, all legs, some flies.
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flyNums = [2]; %adjust this 
flies = flyList.flyid(flyNums,:); % flies = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 

metric = 'step_length';
velocity = 'avg_speed_y';

numSpeedBins = 10; 
minAvgSteps = 20; 
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

%format fly names for fig_name
flyNames = [];
for fly = 1:height(flies)
    flyNames = [flyNames, flies{fly}, ' - '];
end
flyNames = flyNames(1:end-3);

fig_name = ['\' metric '_average_x_forwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'speed range x_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_below_' num2str(z_max_abs) ...
            ' - ' flyNames ' - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotStepMetricsxVelocity(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, ... 
                                '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% STEP DURATION x Forward Velocity, all legs, across flies.
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

metric = 'step_duration';
velocity = 'avg_speed_y';

numSpeedBins = 10; 
minAvgSteps = 200; 
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

fig_name = ['\' metric '_average_x_forwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'speed range x_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_below_' num2str(z_max_abs) ...
            ' - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotStepMetricsxVelocity(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, ... 
                                '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% STEP DURATION x Forward Velocity, all legs, some flies.
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flyNums = [2]; %adjust this 
flies = flyList.flyid(flyNums,:); % flies = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 

metric = 'step_duration';
velocity = 'avg_speed_y';

numSpeedBins = 10; 
minAvgSteps = 20; 
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

%format fly names for fig_name
flyNames = [];
for fly = 1:height(flies)
    flyNames = [flyNames, flies{fly}, ' - '];
end
flyNames = flyNames(1:end-3);

fig_name = ['\' metric '_average_x_forwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'speed range x_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_below_' num2str(z_max_abs) ...
            ' - ' flyNames ' - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotStepMetricsxVelocity(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, ... 
                                '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% SWING DURATION x Forward Velocity, all legs, across flies.
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

metric = 'swing_duration';
velocity = 'avg_speed_y';

numSpeedBins = 10; 
minAvgSteps = 200; 
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

fig_name = ['\' metric '_average_x_forwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'speed range x_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_below_' num2str(z_max_abs) ...
            ' - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotStepMetricsxVelocity(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, ... 
                                '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% SWING DURATION x Forward Velocity, all legs, some flies.
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flyNums = [2]; %adjust this 
flies = flyList.flyid(flyNums,:); % flies = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 

metric = 'swing_duration';
velocity = 'avg_speed_y';

numSpeedBins = 10; 
minAvgSteps = 20; 
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

%format fly names for fig_name
flyNames = [];
for fly = 1:height(flies)
    flyNames = [flyNames, flies{fly}, ' - '];
end
flyNames = flyNames(1:end-3);

fig_name = ['\' metric '_average_x_forwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'speed range x_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_below_' num2str(z_max_abs) ...
            ' - ' flyNames ' - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotStepMetricsxVelocity(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, ... 
                                '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% STANCE DURATION x Forward Velocity, all legs, across flies.
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

metric = 'stance_duration';
velocity = 'avg_speed_y';

numSpeedBins = 10; 
minAvgSteps = 200; 
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

fig_name = ['\' metric '_average_x_forwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'speed range x_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_below_' num2str(z_max_abs) ...
            ' - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotStepMetricsxVelocity(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, ... 
                                '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% STANCE DURATION x Forward Velocity, all legs, some flies.
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flyNums = [2]; %adjust this 
flies = flyList.flyid(flyNums,:); % flies = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 

metric = 'stance_duration';
velocity = 'avg_speed_y';

numSpeedBins = 10; 
minAvgSteps = 20; 
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

%format fly names for fig_name
flyNames = [];
for fly = 1:height(flies)
    flyNames = [flyNames, flies{fly}, ' - '];
end
flyNames = flyNames(1:end-3);

fig_name = ['\' metric '_average_x_forwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'speed range x_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_below_' num2str(z_max_abs) ...
            ' - ' flyNames ' - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotStepMetricsxVelocity(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, ... 
                                '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% AEP & PEP x Forward Velocity, all legs, across flies - ONE plot. 
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

velocity = 'avg_speed_y';
onePlot = 'y';
type = '2D';

numSpeedBins = 10; 
minAvgSteps = 200; 
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

fig_name = ['\AEP_&_PEP_average_x_forwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'speed range x_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_below_' num2str(z_max_abs) ...
            ' - allFlies - graphCoords - onePlot - ' type ' - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotAEPnPEPxVelocity(steps, param, velocity, type, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, onePlot, ... 
                                '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% AEP & PEP x Forward Velocity, all legs, some flies - ONE plot. 
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flyNums = [2]; %adjust this 
flies = flyList.flyid(flyNums,:); % flies = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 

velocity = 'avg_speed_y';
onePlot = 'y';
type = '2D';

numSpeedBins = 10; 
minAvgSteps = 20; 
maxSpeed = 30;

x_max_abs = 3;
y_min = 10; 
z_max_abs = 3;

%format fly names for fig_name
flyNames = [];
for fly = 1:height(flies)
    flyNames = [flyNames, flies{fly}, ' - '];
end
flyNames = flyNames(1:end-3);

fig_name = ['\AEP_&_PEP_average_x_forwardSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'speed range x_below_' num2str(x_max_abs) ' y_above_' num2str(y_min) ' z_below_' num2str(z_max_abs) ...
            ' - ' flyNames ' - graphCoords - onePlot - ' type ' - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotAEPnPEPxVelocity(steps, param, velocity, type, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, onePlot, ... 
                                '-x_max_abs', x_max_abs, '-y_min', y_min, '-z_max_abs', z_max_abs);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% 
%%%%%%%%%%% Walking x Rotational Velocity %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 
% ANGLES
%% MEAN Joint x Phase, all joints, all legs, across flies, color by Rotational speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_z';

order = 'raw';
type = 'avg';
normed = 'n';

numSpeedBins = 20; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 40;


fig_name = ['\all_joints_x_leg_phase_allLegs_averages_binnedByRotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'no speed range - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN Joint x Phase, all joints, all legs, single fly, color by Rotational speed - cartesian coordinates 

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flyNums = [2,3]; %adjust this 
flies = flyList.flyid(flyNums,:); % flies = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_z';

order = 'raw';
type = 'avg';
normed = 'n';

numSpeedBins = 20; 
minAvgSteps = 20; 
numPhaseBins = 20;
maxSpeed = 40;

%format fly names for fig_name
flyNames = [];
for fly = 1:height(flies)
    flyNames = [flyNames, flies{fly}, ' - '];
end
flyNames = flyNames(1:end-3);

fig_name = ['\all_joints_x_leg_phase_allLegs_averages_binnedByRotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'no speed range - ' flyNames ' - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN NORMED Joint x Phase, all joints, all legs, across flies, color by Rotational speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_z';

order = 'raw';
type = 'avg';
normed = 'y';

numSpeedBins = 20; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 40;

fig_name = ['\all_joints_x_leg_phase_allLegs_averagesNormed_binnedByRotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'no speed range - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% STD Joint x Phase, all joints, all legs, across flies, color by Rotational speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_z';

order = 'raw';
type = 'std';
normed = 'n';

numSpeedBins = 20; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 40;

fig_name = ['\all_joints_x_leg_phase_allLegs_std_binnedByRotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'no speed range - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% VELOCITY of Joint x Phase, all joints, all legs, across flies, color by Rotaional speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_z';

order = 'velocity';
type = 'avg';
normed = 'n';

numSpeedBins = 20; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 40;

fig_name = ['\all_joints_x_leg_phase_allLegs_averageVelocity_binnedByRotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'no speed range - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% ACCELERATION of Joint x Phase, all joints, all legs, across flies, color by Rotational speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_z';

order = 'acceleration';
type = 'avg';
normed = 'n';

numSpeedBins = 20; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 40;

fig_name = ['\all_joints_x_leg_phase_allLegs_averageAcceleration_binnedByRotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'no speed range - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% JERK of Joint x Phase, all joints, all legs, across flies, color by Rotational speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_z';

order = 'jerk';
type = 'avg';
normed = 'n';

numSpeedBins = 20; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 40;

fig_name = ['\all_joints_x_leg_phase_allLegs_averageJerk_binnedByRotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'no speed range - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% 
% ABDUCTION & ROTATIONS
%% MEAN of Joint Rotation & Abduction x Phase, all joints, all legs, across flies, color by Rotational speed - polar & cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_z';

order = 'raw';
type = 'avg';
normed = 'n';

numSpeedBins = 20; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 40;

fig_name = ['\all_jointAbduct&Rots_x_leg_phase_allLegs_averages_binnedByRotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'no speed range - allFlies - polarCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN NORMED of Joint Rotation & Abduction x Phase, all joints, all legs, across flies, color by Rotational speed - polar & cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_z';

order = 'raw';
type = 'avg';
normed = 'y';

numSpeedBins = 20; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 40;

fig_name = ['\all_jointAbduct&Rots_x_leg_phase_allLegs_averagesNormed_binnedByRotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'no speed range - allFlies - polarCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% STD of Joint Rotation & Abduction x Phase, all joints, all legs, across flies, color by Rotational speed - polar & cartesian coordinates
% note: I'm not sure if taking standard deviation normally works for
% rotation data that wraps. the wrapping parts might create higher standard
% deviations. Look into this -> how to do std of rotational data. 

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_abduct', 'A_rot', 'B_rot', 'C_rot'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_z';

order = 'raw';
type = 'std';
normed = 'n';

numSpeedBins = 20; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 40;

fig_name = ['\all_jointAbduct&Rots_x_leg_phase_allLegs_std_binnedByRotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'no speed range - allFlies - polarCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% VELOCITY of Joint Rotation and Abduction x Phase, all joints, all legs, across flies, color by Rotational speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_abduct', 'A_rot_unwrapped', 'B_rot_unwrapped', 'C_rot_unwrapped'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_z';

order = 'velocity';
type = 'avg';
normed = 'n';

numSpeedBins = 20; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 40;

fig_name = ['\all_jointAbduct&Rots_x_leg_phase_allLegs_averageVelocity_binnedByRotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'no speed range - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% ACCELERATION of Joint Rotation and Abduction x Phase, all joints, all legs, across flies, color by Rotational speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_abduct', 'A_rot_unwrapped', 'B_rot_unwrapped', 'C_rot_unwrapped'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_z';

order = 'acceleration';
type = 'avg';
normed = 'n';

numSpeedBins = 20; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 40;

fig_name = ['\all_jointAbduct&Rots_x_leg_phase_allLegs_averageAcceleration_binnedByRotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'no speed range - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% JERK of Joint Rotation and Abduction x Phase, all joints, all legs, across flies, color by Rotational speed - cartesian coordinates
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

joints = {'A_abduct', 'A_rot_unwrapped', 'B_rot_unwrapped', 'C_rot_unwrapped'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};

velocity = 'avg_speed_z';

order = 'jerk';
type = 'avg';
normed = 'n';

numSpeedBins = 20; 
minAvgSteps = 200; 
numPhaseBins = 20;
maxSpeed = 40;

fig_name = ['\all_jointAbduct&Rots_x_leg_phase_allLegs_averageJerk_binnedByRotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(numPhaseBins) '_phasebins - ' num2str(maxSpeed) '_maxSpeed - '...
            'no speed range - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

%plot
plotJointxVelocityOverview(data, steps, param, flies, joints, phases, velocity, fig_name, order, type, normed, ...
                                           numSpeedBins, numPhaseBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% 
% ABDUCTION & ROTATIONS
%% 
% STEP METRICS
%% STEP LENGTH x Rotational Velocity, all legs, across flies.
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

metric = 'step_length';
velocity = 'avg_speed_z';

numSpeedBins = 20; 
minAvgSteps = 200; 
maxSpeed = 40;

fig_name = ['\' metric '_average_x_rotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'no speed range - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotStepMetricsxVelocity(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% STEP LENGTH x Rotational Velocity, all legs, some flies.
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flyNums = [2]; %adjust this 
flies = flyList.flyid(flyNums,:); % flies = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 

metric = 'step_length';
velocity = 'avg_speed_z';

numSpeedBins = 20; 
minAvgSteps = 20; 
maxSpeed = 40;

%format fly names for fig_name
flyNames = [];
for fly = 1:height(flies)
    flyNames = [flyNames, flies{fly}, ' - '];
end
flyNames = flyNames(1:end-3);

fig_name = ['\' metric '_average_x_rotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'no speed range - ' flyNames ' - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotStepMetricsxVelocity(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% STEP DURATION x Rotational Velocity, all legs, across flies.
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

metric = 'step_duration';
velocity = 'avg_speed_z';

numSpeedBins = 10; 
minAvgSteps = 200; 
maxSpeed = 30;

fig_name = ['\' metric '_average_x_rotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'no speed range - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotStepMetricsxVelocity(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% STEP DURATION x Rotational Velocity, all legs, some flies.
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flyNums = [2]; %adjust this 
flies = flyList.flyid(flyNums,:); % flies = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 

metric = 'step_duration';
velocity = 'avg_speed_z';

numSpeedBins = 20; 
minAvgSteps = 20; 
maxSpeed = 40;

%format fly names for fig_name
flyNames = [];
for fly = 1:height(flies)
    flyNames = [flyNames, flies{fly}, ' - '];
end
flyNames = flyNames(1:end-3);

fig_name = ['\' metric '_average_x_rotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'no speed range - ' flyNames ' - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotStepMetricsxVelocity(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% SWING DURATION x Rotational Velocity, all legs, across flies.
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

metric = 'swing_duration';
velocity = 'avg_speed_z';

numSpeedBins = 20; 
minAvgSteps = 200; 
maxSpeed = 40;

fig_name = ['\' metric '_average_x_rotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'no speed range - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotStepMetricsxVelocity(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% SWING DURATION x Rotational Velocity, all legs, some flies.
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flyNums = [2]; %adjust this 
flies = flyList.flyid(flyNums,:); % flies = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 

metric = 'swing_duration';
velocity = 'avg_speed_z';

numSpeedBins = 20; 
minAvgSteps = 20; 
maxSpeed = 40;

%format fly names for fig_name
flyNames = [];
for fly = 1:height(flies)
    flyNames = [flyNames, flies{fly}, ' - '];
end
flyNames = flyNames(1:end-3);

fig_name = ['\' metric '_average_x_rotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'no speed range - ' flyNames ' - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotStepMetricsxVelocity(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% STANCE DURATION x Rotational Velocity, all legs, across flies.
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

metric = 'stance_duration';
velocity = 'avg_speed_z';

numSpeedBins = 20; 
minAvgSteps = 200; 
maxSpeed = 40;

fig_name = ['\' metric '_average_x_rotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'no speed range - allFlies - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotStepMetricsxVelocity(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% STANCE DURATION x Rotational Velocity, all legs, some flies.
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flyNums = [2]; %adjust this 
flies = flyList.flyid(flyNums,:); % flies = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 

metric = 'stance_duration';
velocity = 'avg_speed_z';

numSpeedBins = 20; 
minAvgSteps = 20; 
maxSpeed = 40;

%format fly names for fig_name
flyNames = [];
for fly = 1:height(flies)
    flyNames = [flyNames, flies{fly}, ' - '];
end
flyNames = flyNames(1:end-3);

fig_name = ['\' metric '_average_x_rotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'no speed range - ' flyNames ' - graphCoords - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotStepMetricsxVelocity(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% AEP & PEP x Rotational Velocity, all legs, across flies - ONE plot. 
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flies = flyList.flyid;

velocity = 'avg_speed_z';
onePlot = 'y';
type = '2D';

numSpeedBins = 20; 
minAvgSteps = 200; 
maxSpeed = 40;

fig_name = ['\AEP_&_PEP_average_x_rotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'no speed range - allFlies - graphCoords - onePlot - ' type ' - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotAEPnPEPxVelocity(steps, param, velocity, type, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, onePlot);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% AEP & PEP x Rotational Velocity, all legs, some flies - ONE plot. 
clearvars('-except',initial_vars{:}); initial_vars = who;

%params
flyNums = [2]; %adjust this 
flies = flyList.flyid(flyNums,:); % flies = flyList.flyid{flyNum}(1:end-2); %for wtBerlin temp exps 

velocity = 'avg_speed_z';
onePlot = 'y';
type = '2D';

numSpeedBins = 20; 
minAvgSteps = 20; 
maxSpeed = 40;

%format fly names for fig_name
flyNames = [];
for fly = 1:height(flies)
    flyNames = [flyNames, flies{fly}, ' - '];
end
flyNames = flyNames(1:end-3);

fig_name = ['\AEP_&_PEP_average_x_rotationalSpeed - ' ...
            num2str(numSpeedBins) '_speedbins - ' num2str(maxSpeed) '_maxSpeed - ' ...
            'no speed range - ' flyNames ' - graphCoords - onePlot - ' type ' - tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps'];

plotAEPnPEPxVelocity(steps, param, velocity, type, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, onePlot);

clearvars('-except',initial_vars{:}); initial_vars = who;
