function Plot_joint_trajectories(data, idxs, legs, joints, connected)

% Plot raw joint positions for a set of idxs in data. Can connect the joints
% to plot leg traces, or keep them seperate to just see how the joints move 
% through space. Can plot any of the data, regardless of behavior or speed. 
% To only plot specific speeds or behaviors, filter before running this function 
% and input the corresponding indices into data. 
% params:
% idxs = indices in walkingData to plot
%     Ex: idxs = find(data.walking_bout_number == 1 & strcmpi(data.filename, "05132021_fly1_0 R1C1  str-cw-0 sec"));
% data = parquet summary file 
% connected = t/f: true connects the joints (plots leg trajectories), false plots trajectory of the joints. 
% legs = legs to plot. ex: legs = {'L1','L2','L3','R1','R2','R3'};
% joints = joints to plot. ex: joints = {'A','B','C','D','E'};
% 
% Sarah Walling-Bell
% Spring, 2022

%color scheme for legs and joints 
leg_colors = {'blue', 'yellow', 'orange', 'purple', 'white', 'cyan'}; %each leg has its own color
% leg_colors = {'blue', 'orange', 'blue', 'orange', 'blue', 'orange'}; %each TRIPOD has its own color
joint_saturations = [0.1, 0.3, 0.5, 0.7, 0.9];
% joint_saturations = [0.1, 0.3, 0.1, 0.3, 0.9];
for leg = 1:6
   this_leg_hsv = rgb2hsv(Color(leg_colors{leg}));
   for joint = 1:5
       this_joint_hsv = [this_leg_hsv(1), joint_saturations(joint), this_leg_hsv(3)]; 
       kolor(:,joint,leg) = hsv2rgb(this_joint_hsv); 
   end
end
LW = 1.5;
alpha = 0.5;

%plot the data 
fig = fullfig; hold on
for leg = 1:width(legs)
    if connected %plot joints connected 
        for jnt = 1:width(joints)-1         
            X1 = data.([legs{leg} joints{jnt} '_x'])(idxs)';
            X2 = data.([legs{leg} joints{jnt+1} '_x'])(idxs)';
            Y1 = data.([legs{leg} joints{jnt} '_y'])(idxs)';
            Y2 = data.([legs{leg} joints{jnt+1} '_y'])(idxs)';
            Z1 = data.([legs{leg} joints{jnt} '_z'])(idxs)';
            Z2 = data.([legs{leg} joints{jnt+1} '_z'])(idxs)';

            line([X1; X2], [Y1; Y2], [Z1; Z2], 'Color', [[kolor(:,jnt,leg)]', alpha]);
        end
    else %plot joints seperated
        for jnt = 1:width(joints)
        plot3(data.([legs{leg} joints{jnt} '_x'])(idxs), ...
              data.([legs{leg} joints{jnt} '_y'])(idxs), ...
              data.([legs{leg} joints{jnt} '_z'])(idxs), ...
              'linewidth', LW, 'color', [[kolor(:,jnt,leg)]', alpha]);
        end
    end
end

hold off


axis tight
box off
set(gca,'visible','off')
axis vis3d % sets the aspect ratio for 3d rotation
ax = gca;               % get the current axis
ax.Clipping = 'off';


fig = formatFig(fig, true);


