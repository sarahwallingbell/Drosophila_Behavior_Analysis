% Testing the joint angles across legs. When plotting BC and CF angles
% across phase and binned by speed, I found differences btw left and right
% legs. Here I'm trying to figure out if these differences are real, or a
% bug in my code somewhere (probably steps function). 


%% For a walking bout, plot joint angles for all legs over time

bout_idxs = find(walkingData.walking_bout_number == 1 & strcmpi(walkingData.filename, "05132021_fly1_0 R1C1  str-cw-0 sec")); %fly 1
% bout_idxs = find(walkingData.walking_bout_number == 348 & strcmpi(walkingData.filename, "05132021_fly2_1 R1C1  str-cw-0 sec")); %fly 2

joint = 'A_flex';

leg_colors = {'red','green','purple', 'blue','orange','yellow'};
speed_colors = {'red', 'blue', 'yellow'};


fig = fullfig;
%front legs
subplot(4,1,1); hold on
for leg = [1,4]
    plot(walkingData.([param.legs{leg} '' joint])(bout_idxs), 'color', Color(leg_colors{leg}), 'linewidth', 2); 
end
legend('L1', 'R1', 'Color', 'none', 'TextColor', 'w', 'Box', 'off', 'Location', 'best', 'FontSize', 14);
hold off
%mid legs
subplot(4,1,2); hold on
for leg = [2,5]
    plot(walkingData.([param.legs{leg} '' joint])(bout_idxs), 'color', Color(leg_colors{leg}), 'linewidth', 2); 
end
legend('L2', 'R2', 'Color', 'none', 'TextColor', 'w', 'Box', 'off', 'Location', 'best', 'FontSize', 14);
hold off
%hind legs
subplot(4,1,3); hold on
for leg = [3,6]
    plot(walkingData.([param.legs{leg} '' joint])(bout_idxs), 'color', Color(leg_colors{leg}), 'linewidth', 2); 
end
legend('L3', 'R3', 'Color', 'none', 'TextColor', 'w', 'Box', 'off', 'Location', 'best', 'FontSize', 14);
hold off
%speeds
subplot(4,1,4); hold on
plot(walkingData.('fictrac_delta_rot_lab_x_mms')(bout_idxs), 'color', Color(speed_colors{1}), 'linewidth', 2); 
plot(walkingData.('fictrac_delta_rot_lab_y_mms')(bout_idxs), 'color', Color(speed_colors{2}), 'linewidth', 2); 
plot(walkingData.('fictrac_delta_rot_lab_z_mms')(bout_idxs), 'color', Color(speed_colors{3}), 'linewidth', 2); 
hold off
legend('sideslip', 'forward', 'rotation', 'Color', 'none', 'TextColor', 'w', 'Box', 'off', 'Location', 'best', 'FontSize', 14);
fig = formatFig(fig, true, [4,1]);


%% For a fly, plot left-right offset of mean of joint angles

fly_idxs = find(strcmpi(walkingData.filename, "05132021_fly1_0 R1C1  str-cw-0 sec")); %fly 1
% fly_idxs = find(strcmpi(walkingData.filename, "05132021_fly2_1 R1C1  str-cw-0 sec")); %fly 2

% joints = {'A_flex','A_abduct','A_rot','B_flex','B_rot','C_flex','C_rot','D_flex'};
% joints = {'A_flex','A_abduct','B_flex','C_flex','D_flex'};
joints = {'_BC','_CF','_FTi','_TiTa'};
leg_colors = {'red','orange','yellow'}; %leg pair colors T1, T2, T3
offset = 0.1;

fig = fullfig; hold on
%front legs
for joint = 1:width(joints)
    x = joint-offset;
    y = mean(walkingData.([param.legs{1} '' joints{joint}])(fly_idxs)) - mean(walkingData.([param.legs{4} '' joints{joint}])(fly_idxs)); %L-R
    s = scatter(x,y, [], Color(leg_colors{1}), 'filled'); 
end
l = [];
l(end+1) = s;
%mid legs
for joint = 1:width(joints)
    x = joint;
    y = mean(walkingData.([param.legs{2} '' joints{joint}])(fly_idxs)) - mean(walkingData.([param.legs{5} '' joints{joint}])(fly_idxs)); %L-R
    s = scatter(x,y, [], Color(leg_colors{2}), 'filled'); 
end
l(end+1) = s;
%hind legs
for joint = 1:width(joints)
    x = joint+offset;
    y = mean(walkingData.([param.legs{3} '' joints{joint}])(fly_idxs)) - mean(walkingData.([param.legs{6} '' joints{joint}])(fly_idxs)); %L-R
    s = scatter(x,y, [], Color(leg_colors{3}), 'filled'); 
end
l(end+1) = s;
legend(l, 'T1','T2','T3', 'Color', 'none', 'TextColor', 'w', 'Location', 'best', 'FontSize', 14);
hold off
fig = formatFig(fig, true);

hline(0, 'w');
xticks([1:width(joints)]);
xticklabels(strrep(joints, '_', ' '));
ylabel('Left - Right');