% Load data with the old and updated reference frames and check if new 
% reference frame fixes left/right BC joint angle asymmetry 
%
% Sarah Walling-Bell

close all; clear all; clc;

%% datasets to compare

%path to datasets
path = 'G:\.shortcut-targets-by-id\10pxdlRXtzFB-abwDGi0jOGOFFNm3pmFK\Tuthill Lab Shared\Pierre\summaries\v3-b5\days\'; 

%dataset names
data1_oldRF_name = 'all_5.13.21.parquet';
data1_newRF_name = 'all_5.13.21_newframe.parquet';

data2_oldRF_name = 'all_5.10.22.parquet';
data2_newRF_name = 'all_5.10.22_newframe.parquet';


%% load the data

data1_oldRF = parquetread([path data1_oldRF_name]);
data1_newRF = parquetread([path data1_newRF_name]);
data2_oldRF = parquetread([path data2_oldRF_name]);
data2_newRF = parquetread([path data2_newRF_name]);

initial_vars = who;
%% fix anipose output

data1_oldRF_p = preprocess_data_reference_frame_comparison(data1_oldRF);
data1_newRF_p = preprocess_data_reference_frame_comparison(data1_newRF);
data2_oldRF_p = preprocess_data_reference_frame_comparison(data2_oldRF);
data2_newRF_p = preprocess_data_reference_frame_comparison(data2_newRF);

initial_vars = who;
%% 5.13.21 data old RF 

idxs = 1:1000; %indices in the data to plot
joints = {'A_abduct', 'A_flex', 'B_flex', 'C_flex', 'D_flex'}; %joints to plot

legs = {'L1', 'L2', 'L3', 'R1', 'R2', 'R3'};
numLegPairs = 3; 
plotOrder = [1,4,7,10,13, 2,5,8,11,14, 3,6,9,12,15, 1,4,7,10,13, 2,5,8,11,14, 3,6,9,12,15];

fig = fullfig;
i = 0;
for leg = 1:6
    for joint = 1:width(joints)
        i = i+1;
        subplot(width(joints), numLegPairs, plotOrder(i)); hold on
        
        %plot old refernce frame
        plot(data1_oldRF_p.([legs{leg} joints{joint}])(idxs), 'LineWidth', 1.5);

        %label
        if leg < 4
            title(['T' num2str(leg) ' ' strrep(joints{joint}, '_', ' ')])
        end
        if leg == 1
            xlabel('Time (f)');
        end

    end
end
legend({'left', 'right'});

fig = formatFig(fig, true, [width(joints), numLegPairs]);

hold off

%save
fig_path = 'G:\.shortcut-targets-by-id\10pxdlRXtzFB-abwDGi0jOGOFFNm3pmFK\Tuthill Lab Shared\Sarah\Weekly Meetings\23_1_17\figs\';
fig_name = 'reference_frame_05132021_data_old_RF';
save_figure(fig, [fig_path fig_name], '-pdf');

%% 5.13.21 data new RF 

idxs = 1:1000; %indices in the data to plot
joints = {'A_abduct', 'A_flex', 'B_flex', 'C_flex', 'D_flex'}; %joints to plot

legs = {'L1', 'L2', 'L3', 'R1', 'R2', 'R3'};
numLegPairs = 3; 
plotOrder = [1,4,7,10,13, 2,5,8,11,14, 3,6,9,12,15, 1,4,7,10,13, 2,5,8,11,14, 3,6,9,12,15];

fig = fullfig;
i = 0;
for leg = 1:6
    for joint = 1:width(joints)
        i = i+1;
        subplot(width(joints), numLegPairs, plotOrder(i)); hold on
        
        %plot old refernce frame
        plot(data1_newRF_p.([legs{leg} joints{joint}])(idxs), 'LineWidth', 1.5);

        %label
        if leg < 4
            title(['T' num2str(leg) ' ' strrep(joints{joint}, '_', ' ')])
        end
        if leg == 1
            xlabel('Time (f)');
        end

    end
end
legend({'left', 'right'});

fig = formatFig(fig, true, [width(joints), numLegPairs]);

hold off

%save
fig_path = 'G:\.shortcut-targets-by-id\10pxdlRXtzFB-abwDGi0jOGOFFNm3pmFK\Tuthill Lab Shared\Sarah\Weekly Meetings\23_1_17\figs\';
fig_name = 'reference_frame_05132021_data_new_RF';
save_figure(fig, [fig_path fig_name], '-pdf');

%% 5.13.21 data both RF 

idxs = 1:1000; %indices in the data to plot
joints = {'A_abduct', 'A_flex', 'B_flex', 'C_flex', 'D_flex'}; %joints to plot

legs = {'L1', 'L2', 'L3', 'R1', 'R2', 'R3'};
numLegPairs = 3; 
plotOrder = [1,4,7,10,13, 2,5,8,11,14, 3,6,9,12,15, 1,4,7,10,13, 2,5,8,11,14, 3,6,9,12,15];

fig = fullfig;
i = 0;
for leg = 1:6
    for joint = 1:width(joints)
        i = i+1;
        subplot(width(joints), numLegPairs, plotOrder(i)); hold on
        
        %plot old refernce frame
        plot(data1_oldRF_p.([legs{leg} joints{joint}])(idxs), 'LineWidth', 1.5); 
        plot(data1_newRF_p.([legs{leg} joints{joint}])(idxs), 'LineWidth', 1.5);


        %label
        if leg < 4
            title(['T' num2str(leg) ' ' strrep(joints{joint}, '_', ' ')])
        end
        if leg == 1
            xlabel('Time (f)');
        end

    end
end
legend({'left old rf', 'left new rf', 'right old rf', 'right new rf'});

fig = formatFig(fig, true, [width(joints), numLegPairs]);

hold off

%save
fig_path = 'G:\.shortcut-targets-by-id\10pxdlRXtzFB-abwDGi0jOGOFFNm3pmFK\Tuthill Lab Shared\Sarah\Weekly Meetings\23_1_17\figs\';
fig_name = 'reference_frame_05132021_data_both_RF';
save_figure(fig, [fig_path fig_name], '-pdf');
%% 5.10.22 data old RF 

idxs = 1:1000; %indices in the data to plot
joints = {'A_abduct', 'A_flex', 'B_flex', 'C_flex', 'D_flex'}; %joints to plot

legs = {'L1', 'L2', 'L3', 'R1', 'R2', 'R3'};
numLegPairs = 3; 
plotOrder = [1,4,7,10,13, 2,5,8,11,14, 3,6,9,12,15, 1,4,7,10,13, 2,5,8,11,14, 3,6,9,12,15];

fig = fullfig;
i = 0;
for leg = 1:6
    for joint = 1:width(joints)
        i = i+1;
        subplot(width(joints), numLegPairs, plotOrder(i)); hold on
        
        %plot old refernce frame
        plot(data2_oldRF_p.([legs{leg} joints{joint}])(idxs), 'LineWidth', 1.5);

        %label
        if leg < 4
            title(['T' num2str(leg) ' ' strrep(joints{joint}, '_', ' ')])
        end
        if leg == 1
            xlabel('Time (f)');
        end

    end
end
legend({'left', 'right'});

fig = formatFig(fig, true, [width(joints), numLegPairs]);

hold off

%save
fig_path = 'G:\.shortcut-targets-by-id\10pxdlRXtzFB-abwDGi0jOGOFFNm3pmFK\Tuthill Lab Shared\Sarah\Weekly Meetings\23_1_17\figs\';
fig_name = 'reference_frame_05102022_data_old_RF';
save_figure(fig, [fig_path fig_name], '-pdf');
%% 5.10.22 data new RF 

idxs = 1:1000; %indices in the data to plot
joints = {'A_abduct', 'A_flex', 'B_flex', 'C_flex', 'D_flex'}; %joints to plot

legs = {'L1', 'L2', 'L3', 'R1', 'R2', 'R3'};
numLegPairs = 3; 
plotOrder = [1,4,7,10,13, 2,5,8,11,14, 3,6,9,12,15, 1,4,7,10,13, 2,5,8,11,14, 3,6,9,12,15];

fig = fullfig;
i = 0;
for leg = 1:6
    for joint = 1:width(joints)
        i = i+1;
        subplot(width(joints), numLegPairs, plotOrder(i)); hold on
        
        %plot old refernce frame
        plot(data2_newRF_p.([legs{leg} joints{joint}])(idxs), 'LineWidth', 1.5);

        %label
        if leg < 4
            title(['T' num2str(leg) ' ' strrep(joints{joint}, '_', ' ')])
        end
        if leg == 1
            xlabel('Time (f)');
        end

    end
end
legend({'left', 'right'});

fig = formatFig(fig, true, [width(joints), numLegPairs]);

hold off

%save
fig_path = 'G:\.shortcut-targets-by-id\10pxdlRXtzFB-abwDGi0jOGOFFNm3pmFK\Tuthill Lab Shared\Sarah\Weekly Meetings\23_1_17\figs\';
fig_name = 'reference_frame_05102022_data_new_RF';
save_figure(fig, [fig_path fig_name], '-pdf');
%% 5.10.22 data both RF 

idxs = 1:1000; %indices in the data to plot
joints = {'A_abduct', 'A_flex', 'B_flex', 'C_flex', 'D_flex'}; %joints to plot

legs = {'L1', 'L2', 'L3', 'R1', 'R2', 'R3'};
numLegPairs = 3; 
plotOrder = [1,4,7,10,13, 2,5,8,11,14, 3,6,9,12,15, 1,4,7,10,13, 2,5,8,11,14, 3,6,9,12,15];

fig = fullfig;
i = 0;
for leg = 1:6
    for joint = 1:width(joints)
        i = i+1;
        subplot(width(joints), numLegPairs, plotOrder(i)); hold on
        
        %plot old refernce frame
        plot(data2_oldRF_p.([legs{leg} joints{joint}])(idxs), 'LineWidth', 1.5); 
        plot(data2_newRF_p.([legs{leg} joints{joint}])(idxs), 'LineWidth', 1.5);


        %label
        if leg < 4
            title(['T' num2str(leg) ' ' strrep(joints{joint}, '_', ' ')])
        end
        if leg == 1
            xlabel('Time (f)');
        end

    end
end
legend({'left old rf', 'left new rf', 'right old rf', 'right new rf'});

fig = formatFig(fig, true, [width(joints), numLegPairs]);

hold off

%save
fig_path = 'G:\.shortcut-targets-by-id\10pxdlRXtzFB-abwDGi0jOGOFFNm3pmFK\Tuthill Lab Shared\Sarah\Weekly Meetings\23_1_17\figs\';
fig_name = 'reference_frame_05102022_data_both_RF';
save_figure(fig, [fig_path fig_name], '-pdf');