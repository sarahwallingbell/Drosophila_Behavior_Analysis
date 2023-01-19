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
bout = 1; %true_walking_bout_number value

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

idxs = data.true_walking_bout_number == bout;

%plot
fig = fullfig; hold on 
plot(data.L1A_flex(idxs), 'linewidth', 2, 'color', Color(param.jointColors{1}));
plot(data.L1B_flex(idxs), 'linewidth', 2, 'color', Color(param.jointColors{2}));
plot(data.L1C_flex(idxs), 'linewidth', 2, 'color', Color(param.jointColors{3}));
plot(data.L1D_flex(idxs), 'linewidth', 2, 'color', Color(param.jointColors{4}));
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
bout = 1; %true_walking_bout_number value

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

idxs = data.true_walking_bout_number == bout;

%plot
order = [4,5,6,1,2,3];
fig = fullfig; hold on 
for leg = 1:param.numLegs
    subplot(2,3,order(leg)); hold on;
    for joint = 1:param.numJoints
        plot(data.([param.legs{leg} '' param.jointLetters{joint} '_flex'])(idxs), 'linewidth', 2, 'color', Color(param.jointColors{joint})); 
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

%p%param:
bout = 1; %true_walking_bout_number value

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

idxs = data.true_walking_bout_number == bout;

%plot
order = [4,5,6,1,2,3];
jointType = {'A_abduct', 'A_rot_unwrapped', 'B_rot_unwrapped', 'C_rot_unwrapped'};
fig = fullfig; hold on 
for leg = 1:param.numLegs
    subplot(2,3,order(leg)); hold on;
    for joint = 1:width(jointType)
        if joint == 1 %abduct, plot raw
            plot(data.([param.legs{leg} '' jointType{joint}])(idxs), 'linewidth', 2, 'color', Color(param.jointColors{joint})); 
        else %rotation, plot diff
            plot(diff(data.([param.legs{leg} '' jointType{joint}])(idxs)), 'linewidth', 2, 'color', Color(param.jointColors{joint})); 
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

%pa%p%param:
bout = 1; %true_walking_bout_number value

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

idxs = data.true_walking_bout_number == bout;

%plot
order = [4,5,6,1,2,3];
jointType = {'B_rot', 'C_rot'};
fig = fullfig; hold on 
for leg = 1:param.numLegs
    subplot(2,3,order(leg)); hold on;
    for joint = 1:width(jointType)
        %rotation, plot diff
        plot(diff(data.([param.legs{leg} '' jointType{joint}])(idxs)), 'linewidth', 2, 'color', Color(param.jointColors{joint})); 
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
% 
% %params
% colorPhase = false; %true colors by phase, false colors by leg/joint
% connected = false; %true plots les, false plots joints
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% for leg = 1:param.numLegs; idxs{leg} = {1:height(steps.leg(leg).meta)}; end
% legs = {'L1','L2','L3', 'R1','R2','R3'};
% joints = {'A','B','C','D','E'};
% Plot_joint_trajectories_avg_step(steps, idxs, walkingData, legs, joints, connected, param, colorPhase);
% 
% clearvars('-except',initial_vars{:}); initial_vars = who;

%% 
%%%%%%%%%%% Walking x Forward Velocity %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 
% ANGLES

%% MEAN FTi joint x E y phase x ctl vs stim x FORWARD vel - ALL steps
clearvars('-except',initial_vars{:}); initial_vars = who;

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 100; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

maxSpeed = 30;
numSpeedBins = 20; 
velocityBins = 0:maxSpeed/numSpeedBins:maxSpeed;

fig_name = ['\avg_' joint '_x_' phase '_binnedByForwardVel_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

joint_x_phase_plot_fwd_vel_binned_walk_x_speed(data, steps, flyList.flyid, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins,  fig_name)

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN FTi joint x E y phase x ctl vs stim x FORWARD vel - FORWARD steps
clearvars('-except',initial_vars{:}); initial_vars = who;

y_min = 5; %mm/s
z_max_abs = 3; %mm/s

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 100; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

maxSpeed = 30;
numSpeedBins = 20; 
velocityBins = 0:maxSpeed/numSpeedBins:maxSpeed;

fig_name = ['\avg_' joint '_x_' phase '_binnedByForwardVel_forwardSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

joint_x_phase_plot_fwd_vel_binned_walk_x_speed(data, steps, flyList.flyid, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins,  fig_name, '-y_min', y_min, '-z_max_abs', z_max_abs)

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN FTi joint x E y phase x ctl vs stim x FORWARD vel - ALL steps - SINGLE FLY
clearvars('-except',initial_vars{:}); initial_vars = who;

fly = flyList(1,:).flyid; %choose fly here - row in flyList

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 10; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

maxSpeed = 30;
numSpeedBins = 20; 
velocityBins = 0:maxSpeed/numSpeedBins:maxSpeed;

fig_name = ['\avg_' joint '_x_' phase '_binnedByForwardVel_allSteps_' fly '_minAvgSteps_' num2str(minAvgSteps)];

joint_x_phase_plot_fwd_vel_binned_walk_x_speed(data, steps, fly, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins,  fig_name)

clearvars('-except',initial_vars{:}); initial_vars = who;


%% MEAN FTi joint x E y phase x ctl vs stim x FORWARD vel - ALL steps - NORMED by average step
clearvars('-except',initial_vars{:}); initial_vars = who;

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 100; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

maxSpeed = 30;
numSpeedBins = 20; 
velocityBins = 0:maxSpeed/numSpeedBins:maxSpeed;

fig_name = ['\avg_' joint '_x_' phase '_binnedByForwardVel_normedByAverageStep_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

joint_x_phase_plot_fwd_vel_binned_walk_x_speed_normed(data, steps, flyList.flyid, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins,  fig_name)

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN FTi joint VELOCITY x E y phase x ctl vs stim x FORWARD vel - ALL steps
clearvars('-except',initial_vars{:}); initial_vars = who;

derivative = 1; %number of derivatives of joint angle data to take. 

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 100; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

maxSpeed = 30;
numSpeedBins = 20; 
velocityBins = 0:maxSpeed/numSpeedBins:maxSpeed;

fig_name = ['\avg_' joint '_velocity_x_' phase '_binnedByForwardVel_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

joint_derivative_x_phase_plot_fwd_vel_binned_walk_x_speed(data, steps, flyList.flyid, param, joint, phase, derivative, tossSmallBins, minAvgSteps, velocityBins,  fig_name)

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN FTi joint ACCELERATION x E y phase x ctl vs stim x FORWARD vel - ALL steps
clearvars('-except',initial_vars{:}); initial_vars = who;

derivative = 2; %number of derivatives of joint angle data to take. 

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 100; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

maxSpeed = 30;
numSpeedBins = 20; 
velocityBins = 0:maxSpeed/numSpeedBins:maxSpeed;

fig_name = ['\avg_' joint '_acceleration_x_' phase '_binnedByForwardVel_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

joint_derivative_x_phase_plot_fwd_vel_binned_walk_x_speed(data, steps, flyList.flyid, param, joint, phase, derivative, tossSmallBins, minAvgSteps, velocityBins,  fig_name)

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN FTi joint JERK x E y phase x ctl vs stim x FORWARD vel - ALL steps
clearvars('-except',initial_vars{:}); initial_vars = who;

derivative = 3; %number of derivatives of joint angle data to take. 

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 100; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

maxSpeed = 30;
numSpeedBins = 20; 
velocityBins = 0:maxSpeed/numSpeedBins:maxSpeed;

fig_name = ['\avg_' joint '_jerk_x_' phase '_binnedByForwardVel_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

joint_derivative_x_phase_plot_fwd_vel_binned_walk_x_speed(data, steps, flyList.flyid, param, joint, phase, derivative, tossSmallBins, minAvgSteps, velocityBins,  fig_name)

clearvars('-except',initial_vars{:}); initial_vars = who;
%% STD FTi joint x E y phase x ctl vs stim x FORWARD vel - ALL steps
clearvars('-except',initial_vars{:}); initial_vars = who;

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 100; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

maxSpeed = 30;
numSpeedBins = 20; 
velocityBins = 0:maxSpeed/numSpeedBins:maxSpeed;

fig_name = ['\std_' joint '_x_' phase '_binnedByForwardVel_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

std_joint_x_phase_plot_fwd_vel_binned_walk_x_speed(data, steps, flyList.flyid, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins,  fig_name)

clearvars('-except',initial_vars{:}); initial_vars = who;


%% 
% ABDUCTION & ROTATIONS

%% TODO  
% PLOT the same as above but for abduction and rotation data. 
% For rotation angles, plot in polar coordiantes. 

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
flyNums = [6]; %adjust this 
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

%% MEAN FTi joint x E y phase x ctl vs stim x ROTATIONAL vel - ALL steps
clearvars('-except',initial_vars{:}); initial_vars = who;

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 100; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

maxSpeed = 30;
numSpeedBins = 15; 
velocityBins = maxSpeed*-1:maxSpeed/numSpeedBins:maxSpeed;

fig_name = ['\avg_' joint '_x_' phase '_binnedByRotationalVel_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

joint_x_phase_plot_rot_vel_binned_walk_x_speed(data, steps, flyList.flyid, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins,  fig_name)

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN FTi joint x E y phase x ctl vs stim x ROTATIONAL vel - ALL steps - NORMED by avg step 
clearvars('-except',initial_vars{:}); initial_vars = who;

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 100; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

maxSpeed = 30;
numSpeedBins = 15; 
velocityBins = maxSpeed*-1:maxSpeed/numSpeedBins:maxSpeed;

fig_name = ['\avg_' joint '_x_' phase '_binnedByRotationalVel_normedByAvgStep_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

joint_x_phase_plot_rot_vel_binned_walk_x_speed_normed(data, steps, flyList.flyid, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins,  fig_name)

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN FTi joint VELOCITY x E y phase x ctl vs stim x ROTATIONAL vel - ALL steps
clearvars('-except',initial_vars{:}); initial_vars = who;

derivative = 1;

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 100; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

maxSpeed = 30;
numSpeedBins = 15; 
velocityBins = maxSpeed*-1:maxSpeed/numSpeedBins:maxSpeed;

fig_name = ['\avg_' joint '_velocity_x_' phase '_binnedByRotationalVel_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

joint_derivative_x_phase_plot_rot_vel_binned_walk_x_speed(data, steps, flyList.flyid, param, joint, phase, derivative, tossSmallBins, minAvgSteps, velocityBins,  fig_name)

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN FTi joint ACCELERATION x E y phase x ctl vs stim x ROTATIONAL vel - ALL steps
clearvars('-except',initial_vars{:}); initial_vars = who;

derivative = 2;

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 100; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

maxSpeed = 30;
numSpeedBins = 15; 
velocityBins = maxSpeed*-1:maxSpeed/numSpeedBins:maxSpeed;

fig_name = ['\avg_' joint '_acceleration_x_' phase '_binnedByRotationalVel_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

joint_derivative_x_phase_plot_rot_vel_binned_walk_x_speed(data, steps, flyList.flyid, param, joint, phase, derivative, tossSmallBins, minAvgSteps, velocityBins,  fig_name)

clearvars('-except',initial_vars{:}); initial_vars = who;

%% MEAN FTi joint JERK x E y phase x ctl vs stim x ROTATIONAL vel - ALL steps
clearvars('-except',initial_vars{:}); initial_vars = who;

derivative = 3;

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 100; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

maxSpeed = 30;
numSpeedBins = 15; 
velocityBins = maxSpeed*-1:maxSpeed/numSpeedBins:maxSpeed;

fig_name = ['\avg_' joint '_jerk_x_' phase '_binnedByRotationalVel_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

joint_derivative_x_phase_plot_rot_vel_binned_walk_x_speed(data, steps, flyList.flyid, param, joint, phase, derivative, tossSmallBins, minAvgSteps, velocityBins,  fig_name)

clearvars('-except',initial_vars{:}); initial_vars = who;

%% STD FTi joint x E y phase x ctl vs stim x ROTATIONAL vel - ALL steps
clearvars('-except',initial_vars{:}); initial_vars = who;

joint = 'C_flex';
phase = 'E_y_phase';

tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 100; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

maxSpeed = 30;
numSpeedBins = 15; 
velocityBins = maxSpeed*-1:maxSpeed/numSpeedBins:maxSpeed;

fig_name = ['\std_' joint '_x_' phase '_binnedByRotationalVel_allSteps_allFlies_minAvgSteps_' num2str(minAvgSteps)];

std_joint_x_phase_plot_rot_vel_binned_walk_x_speed(data, steps, flyList.flyid, param, joint, phase, tossSmallBins, minAvgSteps, velocityBins,  fig_name)

clearvars('-except',initial_vars{:}); initial_vars = who;
%% 
% ABDUCTION & ROTATIONS

%% TODO  
% PLOT the same as above but for abduction and rotation data. 
% For rotation angles, plot in polar coordiantes. 

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
