function Plot_joint_trajectories_steps(steps, idxs, walkingData, legs, joints, connected, param)

% Plot raw joint position for a set of steps. Can connect the joints
% to plot leg traces, or keep them seperate to just see how the joints move 
% through space. Can plot any set of steps. To only plot specific speeds,  
% filter before running this function. 
% 
% params:
% idxs = indices in steps.leg(#).meta , needs indices for each leg, can leave a leg nan if not plotting that leg. 
%     Ex: idxs = {{1:100}, {2:200}, {1:150}, {nan}, {4:400}, {7:600}}  --> order is: {{L1}, {L2}, {L3}, {R1}, {R2}, {R3}}
% steps = steps structure, output of steps(...).m
% walkingData = parquet summary file where bout number != nan.
% connected = t/f: true connects the joints (plots leg trajectories), false plots trajectory of the joints. 
% legs = legs to plot. ex: legs = {'L1','L2','L3','R2','R3'};
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
    legNum = find(contains(param.legs, legs(leg)));
    if connected %plot joints connected 
        for jnt = 1:width(joints)-1   
            X1 = walkingData.([legs{leg} joints{jnt} '_x'])([steps.leg(legNum).meta.walkingDataStepIdxs{idxs{legNum}{:}}])';
            X2 = walkingData.([legs{leg} joints{jnt+1} '_x'])([steps.leg(legNum).meta.walkingDataStepIdxs{idxs{legNum}{:}}])';
            Y1 = walkingData.([legs{leg} joints{jnt} '_y'])([steps.leg(legNum).meta.walkingDataStepIdxs{idxs{legNum}{:}}])';
            Y2 = walkingData.([legs{leg} joints{jnt+1} '_y'])([steps.leg(legNum).meta.walkingDataStepIdxs{idxs{legNum}{:}}])';
            Z1 = walkingData.([legs{leg} joints{jnt} '_z'])([steps.leg(legNum).meta.walkingDataStepIdxs{idxs{legNum}{:}}])';
            Z2 = walkingData.([legs{leg} joints{jnt+1} '_z'])([steps.leg(legNum).meta.walkingDataStepIdxs{idxs{legNum}{:}}])';

            line([X1; X2], [Y1; Y2], [Z1; Z2], 'Color', [[kolor(:,jnt,leg)]', alpha]);
        end
    else %plot joints seperated
        for jnt = 1:width(joints)
        plot3(walkingData.([legs{leg} joints{jnt} '_x'])([steps.leg(legNum).meta.walkingDataStepIdxs{idxs{legNum}{:}}]), ...
              walkingData.([legs{leg} joints{jnt} '_y'])([steps.leg(legNum).meta.walkingDataStepIdxs{idxs{legNum}{:}}]), ...
              walkingData.([legs{leg} joints{jnt} '_z'])([steps.leg(legNum).meta.walkingDataStepIdxs{idxs{legNum}{:}}]), ...
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


