function Plot_Joint_Trajectories_on_Ball(data, frames, joints, show_stim)


% data = parquet summary file
% frames = indices into data
% joints = joints to plot
% (((((legs = legs to plot %don't use this, just joints)))))
% show_stim = t/f for plotting laser region in different color if there is one. 
% 
% Sarah Walling-Bell, February 2022


% TODO! the code below is copied from DLC_Step0_intact_onball_inspection.m
%   Need to make it work with the params above so I can easily call it from
%   various scrips. 



alpha = 0.5;

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);
walkingDataStim = param.stimRegions(~isnan(data.walking_bout_number),:);

%find bouts that contain some stim, vs those that don't
stim_bouts = [];
control_bouts = [];
for bout = min(walkingData.walking_bout_number):max(walkingData.walking_bout_number)
   this_bout_idxs = find(walkingData.walking_bout_number == bout);
   if ~isempty(this_bout_idxs)
      if sum(walkingDataStim(this_bout_idxs)) > 0
         %the laser is on during this walking bout
         stim_bouts(end+1) = bout; 
      else %the laser is not on during this walking bout
         control_bouts(end+1) = bout; 
      end
   end
end

%select bout to plot
if (data_type == 1) & show_stim
    %TODO 
    
elseif (data_type == 2) & show_stim
    %TODO 
    region_idxs = [startFrame:endFrame];
    ctl_region_idxs = region_idxs(walkingDataStim(region_idxs) == 0);
%     stim_region_idxs = region_idxs(walkingDataStim(region_idxs) == 1);
%     % divide ctl into pre and post stim 
%     pre_ctl_region_idxs = []; post_ctl_bout_idxs = [];
%     pre_ctl_bout_idxs = [ctl_bout_idxs(ctl_bout_idxs < stim_bout_idxs(1)); stim_bout_idxs(1)]; %append first frame of stim so that the lines will connect 
%     post_ctl_bout_idxs = [stim_bout_idxs(end); ctl_bout_idxs(ctl_bout_idxs > stim_bout_idxs(end))]; 
    
elseif data_type == 3
    if strcmpi(boutType, 'stim')
        bout_to_plot = stim_bouts(boutNum);
        %get bout indices for plotting
        bout_idxs = find(walkingData.walking_bout_number == bout_to_plot);
        if show_stim
            ctl_bout_idxs = bout_idxs(walkingDataStim(bout_idxs) == 0);
            stim_bout_idxs = bout_idxs(walkingDataStim(bout_idxs) == 1);
            % divide ctl into pre and post stim 
            pre_ctl_bout_idxs = []; post_ctl_bout_idxs = [];
            pre_ctl_bout_idxs = [ctl_bout_idxs(ctl_bout_idxs < stim_bout_idxs(1)); stim_bout_idxs(1)]; %append first frame of stim so that the lines will connect 
            post_ctl_bout_idxs = [stim_bout_idxs(end); ctl_bout_idxs(ctl_bout_idxs > stim_bout_idxs(end))]; 
        end
    elseif strcmpi(boutType, 'control')
        bout_to_plot = control_bouts(boutNum);
        %get bout indices for plotting
        bout_idxs = find(walkingData.walking_bout_number == bout_to_plot);
    end
end

%select joint data from walkingData
subData = [columns(contains(columns, '_x')), columns(contains(columns, '_y')),columns(contains(columns, '_z'))];
jointWalkingData = walkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%Ball fit to joint E position... then plot all data in 3D from there. (need
%offsets of limb segment lengths?) 


%Ball fit to E joint position

% ballFitJoint = 5; %tarsus 
% LP = ballFitJoint; %leg point = tarsus
rMin = 1.0;     % min radius constraint
rMax = 3.0;     % max radius constraint
thresh = 0.01;  % percent threshold for 'ground'
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
SZ = 10; % size of scatter plot points
LW = 1;         % line width for plots


%get the data for fitting: x, y, z positions of tarsus tip of each leg
the_min = 0; %find min val of all the data for fitting and move all data into a positive space
for leg = 1:param.numLegs
   %format joint data for ball fit and plotting
   for joint = 1:param.numJoints+1
      dataCols = subData(contains(subData, [param.legs{leg} param.jointLetters{joint}]));
      ballFitData(leg).(param.legNodes{joint}) = [jointWalkingData.(dataCols{1}), jointWalkingData.(dataCols{2}), jointWalkingData.(dataCols{3})];
      the_min = min(min(ballFitData(leg).(param.legNodes{joint})(:)), the_min);   
   end
end
%move all data into a positive space
for leg = 1:param.numLegs
   for joint = 1:param.numJoints+1
      ballFitData(leg).(param.legNodes{joint}) = ballFitData(leg).(param.legNodes{joint}) + abs(the_min);
   end
end

%isolate stance regions and quadruple those points in the dataset for best fitting. 
for leg = 1:param.numLegs
    ballFitData(leg).stance = ballFitData(leg).Ta(diff(ballFitData(leg).Ta(:,2)) <= 0, :);
end

all_stance = [ballFitData(1).stance; ballFitData(2).stance; ballFitData(3).stance; ballFitData(4).stance; ballFitData(5).stance; ballFitData(6).stance];
cloud = [all_stance; all_stance; all_stance]; % triple up on 'good' data points

% SPHERE FIT
%RMSE with minimum optimization function: 
objective = @(XX) sqrt(mean((pdist2([XX(1),XX(2),XX(3)],cloud)-XX(4)).^2,2));
x0 = [0,0,0,1.3]; % starting guess [center-x,center-y,center-z,radius]
[A,b,Aeq,beq] = deal([]);   %empty values
lb = [-inf,-inf,-inf,rMin];  %lower bounds
ub = [inf,inf, 0, rMax];     %upper bounds
XX = fmincon(objective,x0,A,b,Aeq,beq,lb,ub);
Center = [XX(1),XX(2),XX(3)];
Radius = XX(4);
disp(['Radius: ' num2str(Radius)])

% disp number of points that hit the threshold:
R = Radius*thresh;             % 3-percent threshold
dist = pdist2(Center, cloud);  % find the euclidian distances
err = (sum(dist>(Radius-R) & dist<(Radius+R),2)/length(cloud))*100; %percent of points 'on' the sphere
disp(['Points on ball: ' num2str(err) '%'])


set(0,'DefaultFigureVisible','on');  %Turn figures back on:
% --- Figure of ball with full step cycles ---- 
LW = 1.5;
%alpha = 0.5;
% startFrame = 1; 
% endFrame = 1000;

%left plot with the data on the ball 
% fig = getfig;
fig = fullfig;
for leg = 1:6
    for joint = 1:param.numJoints+1
        input = ballFitData(leg).(param.legNodes{joint});
        if ~show_stim %plotting without indicating laser
            if data_type == 1 %plot all data
                plot3(input(:,1), input(:,2), input(:,3), 'linewidth', LW, 'color', [[kolor(:,joint,leg)]', alpha]); hold on
            elseif data_type == 2 %plot region of data
                plot3(input(startFrame:endFrame,1), input(startFrame:endFrame,2), input(startFrame:endFrame,3), 'linewidth', LW, 'color', [[kolor(:,joint,leg)]', alpha]); hold on
            elseif data_type == 3 %plot bout of data
                plot3(input(bout_idxs,1), input(bout_idxs,2), input(bout_idxs,3), 'linewidth', LW, 'color', [[kolor(:,joint,leg)]', alpha]); hold on
            end 
        elseif show_stim %plotting wtih indicating laser
            if data_type == 1 %plot all data
                
            elseif data_type == 2 %plot region of data
                
            elseif data_type == 3 %plot bout of data
                if strcmpi(boutType, 'stim') %it's a stim bout
                    plot3(input(pre_ctl_bout_idxs,1), input(pre_ctl_bout_idxs,2), input(pre_ctl_bout_idxs,3), 'linewidth', LW, 'color', [[kolor(:,joint,leg)]', alpha]); hold on
                    plot3(input(stim_bout_idxs,1), input(stim_bout_idxs,2), input(stim_bout_idxs,3), 'linewidth', LW, 'color', [Color(param.laserColor), alpha]); hold on
                    plot3(input(post_ctl_bout_idxs,1), input(post_ctl_bout_idxs,2), input(post_ctl_bout_idxs,3), 'linewidth', LW, 'color', [[kolor(:,joint,leg)]', alpha]); hold on
                elseif strcmpi(boutType, 'control') %it's a control bout (so no laser to plot)
                    plot3(input(bout_idxs,1), input(bout_idxs,2), input(bout_idxs,3), 'linewidth', LW, 'color', [[kolor(:,joint,leg)]', alpha]); hold on
                end
            end 
        end
    end
end
axis tight
box off
set(gca,'visible','off')
[x,y,z] = sphere;
s = surf(Radius*x+Center(1), Radius*y+Center(2), Radius*z+Center(3));
set(s, 'FaceColor', Color('grey'))
alpha 0.2
axis vis3d % sets the aspect ratio for 3d rotation
ax = gca;               % get the current axis
ax.Clipping = 'off';


fig = formatFig(fig, true);





end