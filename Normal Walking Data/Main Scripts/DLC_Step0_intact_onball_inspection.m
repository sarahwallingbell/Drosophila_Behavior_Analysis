%%
% clear all; close all; clc;

% Select and load parquet file (the fly data)
[FilePaths, version] = DLC_select_parquet(); 
[data, columns, column_names, path] = DLC_extract_parquet(FilePaths);
[numReps, numConds, flyList, flyIndices] = DLC_extract_flies(columns, data);
param = DLC_load_params(data, version, flyList);
param.numReps = numReps;
param.numConds = numConds; 
% param.flyList = flyList; 
param.stimRegions = DLC_getStimRegions(data, param);
param.flyIndices = flyIndices;
param.columns = columns; 
param.column_names = column_names; 
param.parquet = path;

% TODO: only use ABCD joints

%Fix Anipose joint output
L1_coxa_length = pdist2([data.L1A_x(1), data.L1A_y(1), data.L1A_z(1)], [data.L1B_x(1), data.L1B_y(1), data.L1B_z(1)]);
for leg = 1:param.numLegs
    % In Anipose output, A_abduct and A_flex are flipped. Swap them back.
    temp = data.([param.legs{leg} 'A_abduct']);
    data.([param.legs{leg} 'A_abduct']) = data.([param.legs{leg} 'A_flex']);
    data.([param.legs{leg} 'A_flex']) = temp;
    
    % In Anipose output, C_flex is negative. Take absolute value of C_flex
    data.([param.legs{leg} 'C_flex']) = abs(data.([param.legs{leg} 'C_flex']));
    
    % TODO fix the jumps in rotation angles (especially for taking derivatives)
    
    
    % Change position units to body length proxy: L1 coxa length 
    dims = {'x', 'y', 'z'};
    for jnt = 1:width(param.jointLetters)
        for dim = 1:width(dims)
            data.([param.legs{leg} param.jointLetters{jnt} '_' dims{dim}]) = ...
                data.([param.legs{leg} param.jointLetters{jnt} '_' dims{dim}])/L1_coxa_length;
        end
    end
    
end
 
initial_vars = who; 
%save walking data 
walkingData = data(~isnan(data.walking_bout_number),:); 

% Normalize rot and side speed to center around zero
data.fictrac_delta_rot_lab_x_mms = data.fictrac_delta_rot_lab_x_mms-mean(walkingData.fictrac_delta_rot_lab_x_mms);
walkingData.fictrac_delta_rot_lab_x_mms = walkingData.fictrac_delta_rot_lab_x_mms-mean(walkingData.fictrac_delta_rot_lab_x_mms);
data.fictrac_delta_rot_lab_z_mms = data.fictrac_delta_rot_lab_z_mms-mean(walkingData.fictrac_delta_rot_lab_z_mms);
walkingData.fictrac_delta_rot_lab_z_mms = walkingData.fictrac_delta_rot_lab_z_mms-mean(walkingData.fictrac_delta_rot_lab_z_mms);

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
initial_vars = who;
%% Get behaviors of each fly 
param.thresh = 0.1; %0.5; %thres hold for behavior prediction 
behavior = DLC_behavior_predictor(data, param); 
behavior_byBout = DLC_behavior_predictor_byBoutNum (data, param);

initial_vars = who; 
clearvars('-except',initial_vars{:}); initial_vars = who;






%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% Behaviors %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Behavior breakdown - all data

behaviorColumns = find(contains(columns, 'bout_number'));
behaviorData = table2array(data(:,behaviorColumns));
behaviorNums = sum(~isnan(behaviorData),1);

behaviorLabels = column_names(behaviorColumns);
behaviorLabels = cellfun(@(behaviorLabels) behaviorLabels(1:end-12), behaviorLabels, 'Uniform', 0);
displayedBehaviors = find(behaviorNums > 0);

% behaviorColors = parula(width(behaviorColumns));
fun = @sRGB_to_CAM02UCS; % default = UCS
behaviorColors = maxdistcolor(width(behaviorColumns),fun, 'sort', 'hue', 'Lmin',0.4, 'Lmax',0.6, 'exc',[0,0,0], 'Cmin',0.5, 'Cmax',0.6); % Exclude black (e.g. background).

fig = fullfig; 
p = pie(behaviorNums(displayedBehaviors), '%.2g%%'); %pie3 makes it 3D

%match colors to standardized colors
PatchArr = findobj(p, 'Type','patch');              % Find ‘Patch’ Objects
for bb = 1:width(displayedBehaviors)
    bb_idx = displayedBehaviors(bb);
    PatchArr(bb).FaceColor = behaviorColors(bb_idx,:);  
end
    
%add percentage text
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
lgd.Position(1) = 0.75;

%save
fig_name = ['\Behavior_Breakdown_AllData'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
clearvars('-except',initial_vars{:}); initial_vars = who;

 %% Behavior breakdown - by fly

plotting = numSubplots(height(flyList)+1);
fig = fullfig; 

behaviorColumns = find(contains(columns, 'bout_number'));
behaviorLabels = column_names(behaviorColumns);
behaviorLabels = cellfun(@(behaviorLabels) behaviorLabels(1:end-12), behaviorLabels, 'Uniform', 0);

% behaviorColors = parula(width(behaviorColumns));
fun = @sRGB_to_CAM02UCS; % default = UCS
behaviorColors = maxdistcolor(width(behaviorColumns),fun, 'sort', 'hue', 'Lmin',0.4, 'Lmax',0.6, 'exc',[0,0,0], 'Cmin',0.5, 'Cmax',0.6); % Exclude black (e.g. background).


for fly = 1:height(flyList)
    subplot(plotting(1), plotting(2), fly);
    behaviorData = table2array(data((strcmpi(data.fly, flyList{fly,1}) & strcmpi(data.date_parsed, flyList{fly,2})),behaviorColumns));
    behaviorNums = sum(~isnan(behaviorData),1);
    displayedBehaviors = find(behaviorNums > 0);
    
    p = pie(behaviorNums(displayedBehaviors), '%.2g%%'); %pie3 makes it 3D
    
    %match colors across fly pie charts 
    PatchArr = findobj(p, 'Type','patch');              % Find ‘Patch’ Objects
    for bb = 1:width(displayedBehaviors)
        bb_idx = displayedBehaviors(bb);
        PatchArr(bb).FaceColor = behaviorColors(bb_idx,:);  
    end
    
    %add percentage text
    pText = findobj(p,'Type','text');
    pColor = findobj(p,'Type', 'color');
    for txt = 1:length(pText)
        thisTxt = pText(txt);
        thisTxt.Color = param.baseColor;
        thisTxt.FontSize = 20;
    end
    
    %delete percent values <1 so they don't overlap
    pText = findobj(p,'Type','text');
    isSmall = startsWith({pText.String}, '<');  
    delete(pText(isSmall));
    %only keep values with 2 chars
    pText = findobj(p,'Type','text');
    L = cellfun(@length, {pText.String});
    isMedium = (L == 2);
    delete(pText(isMedium));
    %delete values with a dot (smaller values)    
    pText = findobj(p,'Type','text');
    hasDot = contains({pText.String}, '.');  
    delete(pText(hasDot));
    
    t = title(strcat("Fly ", strrep(flyList{fly,1}, '_', '-'), " from ", flyList{fly,2}), 'FontSize', 30, 'Position', [0, 1.5]);
end
subplot(plotting(1), plotting(2), fly+1);
p = pie(zeros(1,width(behaviorLabels)));
PatchArr = findobj(p, 'Type','patch');              % Find ‘Patch’ Objects
for bb = 1:width(behaviorLabels)
    bb_idx = bb;
    PatchArr(bb).FaceColor = behaviorColors(bb_idx,:);  
end
fig = formatFig(fig, true, plotting);
lgd = legend(behaviorLabels, 'Location', 'west', 'TextColor', param.baseColor, 'FontSize', 20,  'NumColumns', 2);
lgd.Position(1) = 0.7;
lgd.Position(2) = 0.1;

%save
fig_name = ['\Behavior_Breakdown_byFly'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
clearvars('-except',initial_vars{:}); initial_vars = who;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% JOINT TRACES BY BEHAVIOR %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Select trials by BEHAVIOR 
clearvars('-except',initial_vars{:}); initial_vars = who;

behaviors = {'Walking' 'Stationary' 'Any'};
preBehavior = behaviors{listdlg('ListString', behaviors, 'PromptString','Pre-stim behavior:', 'SelectionMode','single', 'ListSize', [100 100])};
postBehavior = behaviors{listdlg('ListString', behaviors, 'PromptString','Post-stim behavior:', 'SelectionMode','single', 'ListSize', [100 100])};

% preBehavior = 'Stationary'; % Options: 'Walking', 'Stationary', 'Any'
% postBehavior = 'Any'; % Options: 'Walking', 'Stationary', 'Any'
jointAngle = 'Any'; % Options: 'Obtuse', 'Acute', 'Any'

% Find indices in data for all vids where fly has desired behavior
[behaviordata, enough_vids] = DLC_selectBehaviorData(behavior, preBehavior, postBehavior, jointAngle); 
behaviorDataIdxs = DLC_selectBehaviorDataIdxs(behaviordata, enough_vids, param);
initial_vars{end+1} = 'preBehavior';
initial_vars{end+1} = 'postBehavior';
initial_vars{end+1} = 'behaviordata';
initial_vars{end+1} = 'behaviorDataIdxs';
clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot a single trace of a joint angle during a video - (R01 figs)
joint_str = {'L1_BC', 'L1_CF', 'L1_FTi', 'L1_TiTa'}; % L1_FTi L1E_y
%date = '1.7.21'; fly = '2_0'; rep = 2; cond = 5; %iav x gtacr1
% %claw f x chR ???
% date = '1.28.21'; fly = '2_0'; rep = 3; cond = 4; %claw f x gtacr1 ---------------
% date = '10.8.20'; fly = '5_0'; rep = 2; cond = 4; %claw e x chR ---------------

%------------------------------------------------------------------
% date = '8.12.21'; fly = '2_0'; rep = 5; cond = 6; %claw f x gtacr1

% date = '10.6.20'; fly = '2_0'; rep = 1; cond = 4; %claw f x chR
% date = '10.8.20'; fly = '5_1'; rep = 10; cond = 4; %claw f x gtacr1
% date = '1.4.21'; fly = '2_1'; rep = 10; cond = 4; %claw f x gtacr1
% date = '10.7.20'; fly = '1_1'; rep = 2; cond = 9; %claw f x gtacr1
% date = '9.8.21'; fly = '2_0'; rep = 4; cond = 5; %claw f x gtacr1
% date = '1.28.21'; fly = '1_1'; rep = 3; cond = 9; %claw f x gtacr1

date = '8.12.21'; fly = '2_0'; rep = 5; cond = 6; %JR343 L2 silencing




% this_vid_data = data.(joint_str)(strcmpi(data.date_parsed, date) & strcmpi(data.fly, fly) & data.rep == rep & data.condnum == cond);
this_vid_data = find(strcmpi(data.date_parsed, date) & strcmpi(data.fly, fly) & data.rep == rep & data.condnum == cond);

%plot
fig = fullfig; hold on;
for jnt = 1:width(joint_str)
    plot(param.x(1:height(this_vid_data)), data.(joint_str{jnt})(this_vid_data), 'linewidth', 2); 
    lgd{jnt} = strrep(joint_str{jnt}, '_', ' ');
end
% plot(param.x(1:height(this_vid_data)), this_vid_data, 'linewidth', 2); hold on 
laser_on = 0;
laser_off = param.allLasers(cond);
y1 = rangeLine(fig);
pl = plot([laser_on, laser_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
hold off;

% xlim([-0.5,0.5]);

fig = formatFig(fig, true);

l = legend(lgd);
l.Color = 'white'; 
l.Location = 'best';

%save
fig_name = ['\Single_Trace_' date '_fly' fly '_R' num2str(rep) 'C' num2str(cond) '_' joint_str];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% path = 'G:\My Drive\Tuthill Lab Shared\Sarah\Presentations\Lab Meetings\2021.10.28\Figures\FeCO\Claw flex silencing';
save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot a single trace of a joint angle during a video with three speed vectors 
joint_str = {'L1_BC', 'L1_CF', 'L1_FTi', 'L1_TiTa'}; % L1_FTi L1E_y
% joint_str = {'R1_BC', 'R1_CF', 'R1_FTi', 'R1_TiTa'}; % L1_FTi L1E_y

%date = '1.7.21'; fly = '2_0'; rep = 2; cond = 5; %iav x gtacr1
% %claw f x chR ???
% date = '1.28.21'; fly = '2_0'; rep = 3; cond = 4; %claw f x gtacr1 ---------------
% date = '10.8.20'; fly = '5_0'; rep = 2; cond = 4; %claw e x chR ---------------

%------------------------------------------------------------------

% date = '8.12.21'; fly = '1_0'; rep = 2; cond = 5; %claw f x gtacr1 -WALKING 1
% % date = '8.12.21'; fly = '2_0'; rep = 5; cond = 6; %claw f x gtacr1 -WALKING 2
% date = '8.12.21'; fly = '2_0'; rep = 5; cond = 12; %claw f x gtacr1 -WALKING 2

date = '8.12.21'; fly = '1_0'; rep = 1; cond = 15; % 6 claw f x gtacr1 -STANDING
% date = '8.16.21'; fly = '1_0'; rep = 1; cond = 2; %claw f x gtacr1 -STANDING 2 WALKING

% date = '8.12.21'; fly = '2_0'; rep = 1; cond = 20; %claw f x gtacr1 -STANDING


% this_vid_data = data.(joint_str)(strcmpi(data.date_parsed, date) & strcmpi(data.fly, fly) & data.rep == rep & data.condnum == cond);
this_vid_data = find(strcmpi(data.date_parsed, date) & strcmpi(data.fly, fly) & data.rep == rep & data.condnum == cond);

%plot
fig = fullfig;
subplot(2,1,1); hold on
for jnt = 1:width(joint_str)
    plot(param.x(1:height(this_vid_data)), data.(joint_str{jnt})(this_vid_data), 'linewidth', 2); 
    lgd{jnt} = strrep(joint_str{jnt}, '_', ' ');
end
% plot(param.x(1:height(this_vid_data)), this_vid_data, 'linewidth', 2); hold on 
laser_on = 0;
laser_off = param.allLasers(cond);
y1 = rangeLine(fig);
pl = plot([laser_on, laser_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
ylabel(['Joint angle (' char(176) ')'])
xlabel('Time (s)');
hold off;

l = legend(lgd);
l.Color = 'white'; 
l.Location = 'best';

subplot(2,1,2); hold on
yline(0, ':w')
f = plot(param.x(1:height(this_vid_data)), data.forward_velocity(this_vid_data)*-1, 'linewidth', 2); 
s = plot(param.x(1:height(this_vid_data)), data.sideslip_velocity(this_vid_data), 'linewidth', 2); 
a = plot(param.x(1:height(this_vid_data)), data.angular_velocity(this_vid_data)*-1, 'linewidth', 2); 

% f = plot(param.x(1:height(this_vid_data)), (data.fictrac_delta_rot_cam_z(this_vid_data)*-1*param.sarah_ball_r)*param.fictrac_fps, 'linewidth', 2); 
% s = plot(param.x(1:height(this_vid_data)), (data.fictrac_delta_rot_cam_x(this_vid_data)*param.sarah_ball_r)*param.fictrac_fps, 'linewidth', 2); 
% a = plot(param.x(1:height(this_vid_data)), (data.fictrac_delta_rot_cam_y(this_vid_data)*-1*param.sarah_ball_r)*param.fictrac_fps, 'linewidth', 2); 
ylabel('Velocity (mm/s)')
xlabel('Time (s)');
hold off

l = legend([f,s,a],{'forward', 'sideslip', 'angular'});
l.Color = 'white'; 
l.Location = 'best';

% xlim([-0.5,0.5]);

fig = formatFig(fig, true, [2,1]);



%save
fig_name = ['\Single_Trace_' date '_fly' fly '_R' num2str(rep) 'C' num2str(cond) '_' joint_str];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% path = 'G:\My Drive\Tuthill Lab Shared\Sarah\Presentations\Lab Meetings\2021.10.28\Figures\FeCO\Claw flex silencing';
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot single trace of one leg + joint angle
leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};
joint = 3; 
laser = 4;

% fig = figure;
fig = fullfig; 

subplot(1,2,1); hold on;

light_on = 0;
light_off =(param.fps*param.lasers{laser})/param.fps;
%extract the joint data 
if joint == 1; jnt = [leg_str '_BC'];
elseif joint == 2; jnt = [leg_str '_CF'];
elseif joint == 3; jnt = [leg_str '_FTi'];
elseif joint == 4; jnt = [leg_str '_TiTa'];
end
jntIdx = find(contains(columns, jnt));


% laser region 
y1 = rangeLine(fig);

x_points = [light_on, light_on, light_off, light_off];  
y_points = [20, 120, 120, 20];
color = Color(param.laserColor);

hold on;
a = fill(x_points, y_points, color);
a.FaceAlpha = 0.7;
a.EdgeColor = 'none';
% pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
% ha = area([light_on, light_off], [120,120]);





%plot the data!
vidStart = 280;
for vid = vidStart:vidStart+20 %height(behaviordata)
% vid = 384; %claw flex silencing 
% vid = 217; %claw flex activation
% vid = 36; %claw ext activation
vid = 297; %claw ext silencing (v7)

  if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
      start_idx = behaviordata{vid,9};
      end_idx = behaviordata{vid,10};

      vid_data = data{start_idx:end_idx, jntIdx};
%       if height(vid_data == 600)
%         plot(param.x(1:300), vid_data(1:300), 'color', Color(param.expColor), 'linewidth', 3); 
        plot(param.x(1:300), vid_data(1:300),  'linewidth', 2); 

%       end 
  end
end

if param.xlimit; xlim(param.xlim); end
if param.ylimit; ylim(param.ylim); end

%label
ylabel([param.joints{joint} ' (' char(176) ')']);
xlabel('Time (s)');
title([num2str(param.lasers{laser}) ' sec']);

hold off;

fig = formatFig(fig, false);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Raw Joint Angles');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_single-trace_' preBehavior '2' postBehavior];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all joints, all lasers, one leg 
leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};

% fig = figure;
fig = fullfig;
pltIdx = 0;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; jnt = [leg_str '_BC'];
       elseif joint == 2; jnt = [leg_str '_CF'];
       elseif joint == 3; jnt = [leg_str '_FTi'];
       elseif joint == 4; jnt = [leg_str '_TiTa'];
       end
       jntIdx = find(contains(columns, jnt));
       
       
       %plot the data!
       for vid = 1:height(behaviordata)
          if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
              start_idx = behaviordata{vid,9};
              end_idx = behaviordata{vid,10};

              vid_data = data{start_idx:end_idx, jntIdx};
              if height(vid_data == 600)
                plot(param.x, vid_data); 
              end
          end
       end
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
       
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.1 sec');
       elseif pltIdx == 4
           title('0.33 sec');
       elseif pltIdx == 5    
           title('1 sec');
       elseif pltIdx == 6
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 11
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 16
            ylabel(['TiTa (' char(176) ')']);
       end
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, param.darkFig, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Raw Joint Angles');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_overview_' preBehavior '2' postBehavior];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all joints, all lasers, one leg -- mean & 95% CI 
fig = fullfig;
pltIdx = 0;

for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; jnt = [leg_str '_BC'];
       elseif joint == 2; jnt = [leg_str '_CF'];
       elseif joint == 3; jnt = [leg_str '_FTi'];
       elseif joint == 4; jnt = [leg_str '_TiTa'];
       end
       jntIdx = find(contains(columns, jnt));
       
       %plot the data!
       all_data = NaN(height(behaviordata), param.vid_len_f);
       for vid = 1:height(behaviordata)
          if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
              start_idx = behaviordata{vid,9};
              end_idx = behaviordata{vid,10};

              vid_data = data{start_idx:end_idx, jntIdx};
              if height(vid_data == 600)
                all_data(vid, :) = vid_data;
              end
          end
       end

%        N = size(all_data, 1);  % Number of ‘Experiments’ In Data Set (numVids)
       N = height(flyList);    % Number of ‘Experiments’ In Data Set (numFlies)
       yMean = nanmean(all_data); % Mean Of All Experiments At Each Value Of ‘x’
       ySEM = nanstd(all_data)/sqrt(N); % Compute ‘Standard Error Of The Mean’ Of All Experiments At Each Value Of ‘x’
       
       CI95 = tinv([0.025 0.975], N-1);  % Calculate 95% Probability Intervals Of t-Distribution
       yCI95 = bsxfun(@times, ySEM, CI95(:));  % Calculate 95% Confidence Intervals Of All Experiments At Each Value Of ‘x’
       
       plot(param.x, yMean, 'color', Color(param.expColor), 'linewidth', 1.5);
%        plot(param.x, yCI95+yMean);
       fill_data = error_fill(param.x, yMean, yCI95);
       h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
       set(h, 'facealpha', 0.2);
       
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % plot laser region 
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.1 sec');
       elseif pltIdx == 4
           title('0.33 sec');
       elseif pltIdx == 5    
           title('1 sec');
       elseif pltIdx == 6
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 11
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 16
            ylabel(['TiTa (' char(176) ')']);
       end
   end
end

fig = formatFig(fig, true, [param.numJoints, param.numLasers]);


han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Raw Joint Angle Mean & 95% CI');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

hold off;

fig_name = ['\' param.legs{leg} '_overview_mean&95CI_' preBehavior '2' postBehavior];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all joints, all lasers, one leg -- mean & sem 
fig = fullfig;
pltIdx = 0;
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; jnt = [leg_str '_BC'];
       elseif joint == 2; jnt = [leg_str '_CF'];
       elseif joint == 3; jnt = [leg_str '_FTi'];
       elseif joint == 4; jnt = [leg_str '_TiTa'];
       end
       jntIdx = find(contains(columns, jnt));
       
       %plot the data!
       all_data = NaN(height(behaviordata), param.vid_len_f);
       for vid = 1:height(behaviordata)
          if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
              start_idx = behaviordata{vid,9};
              end_idx = behaviordata{vid,10};

              vid_data = data{start_idx:end_idx, jntIdx};
              if height(vid_data == 600)
                all_data(vid, :) = vid_data;
              end
          end
       end
       
       %calculate mean and standard error of the mean 
       yMean = nanmean(all_data, 1);
       ySEM = sem(all_data, 1, nan, height(flyList));
       
       %plot
       plot(param.x, yMean, 'color', Color(param.expColor), 'linewidth', 1.5);
       fill_data = error_fill(param.x, yMean, ySEM);
       h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
       set(h, 'facealpha', 0.2);
       
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % plot laser region 
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.1 sec');
       elseif pltIdx == 4
           title('0.33 sec');
       elseif pltIdx == 5    
           title('1 sec');
       elseif pltIdx == 6
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 11
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 16
            ylabel(['TiTa (' char(176) ')']);
       end
   end
end

fig = formatFig(fig, true, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, 'L1 Raw Joint Angle Mean & SEM');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

hold off;

fig_name = ['\' param.legs{leg} '_overview_mean&SEM_' preBehavior '2' postBehavior];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all joints, all lasers, one leg -- subtract baseline angle 

fig = fullfig;
pltIdx = 0;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; jnt = [leg_str '_BC'];
       elseif joint == 2; jnt = [leg_str '_CF'];
       elseif joint == 3; jnt = [leg_str '_FTi'];
       elseif joint == 4; jnt = [leg_str '_TiTa'];
       end
       jntIdx = find(contains(columns, jnt));

       %plot the data!
       for vid = 1:height(behaviordata)
          if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
              start_idx = behaviordata{vid,9};
              end_idx = behaviordata{vid,10};

              d = data{start_idx:end_idx, jntIdx};
              if height(d == 600)
                  a = d(param.laser_on);
                  d = d-a;
                  plot(param.x, d);
              end
          end
       end
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
        
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.1 sec');
       elseif pltIdx == 4
           title('0.33 sec');
       elseif pltIdx == 5    
           title('1 sec');
       elseif pltIdx == 6
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 11
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 16
            ylabel(['TiTa (' char(176) ')']);
       end
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, 'L1 Aligned Joint Angles');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_overview_aligned_' preBehavior '2' postBehavior];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all joints, all lasers, one leg -- subtract baseline angle -- mean & sem 
fig = fullfig;
pltIdx = 0;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; jnt = [leg_str '_BC'];
       elseif joint == 2; jnt = [leg_str '_CF'];
       elseif joint == 3; jnt = [leg_str '_FTi'];
       elseif joint == 4; jnt = [leg_str '_TiTa'];
       end
       jntIdx = find(contains(columns, jnt));

       %plot the data!
       all_data = NaN(height(behaviordata), param.vid_len_f);
       num_vids = 0;
       for vid = 1:height(behaviordata)
          if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
              num_vids = num_vids + 1;
              start_idx = behaviordata{vid,9};
              end_idx = behaviordata{vid,10};

              d = data{start_idx:end_idx, jntIdx};
              if height(d) == 600
%                   fprintf(['\njoint:' num2str(joint) ' laser:' num2str(laser) ' vid:' num2str(vid)]);
                  a = d(param.laser_on);
                  d = d-a;
                  all_data(vid, :) = d;
              end
          end
       end
       numVids(joint, laser) = num_vids;
       %calculate mean and standard error of the mean 
       yMean = nanmean(all_data, 1);
       ySEM = sem(all_data, 1, nan, height(flyList));
       
       %plot
       plot(param.x, yMean, 'color', Color(param.jointColors{joint}), 'linewidth', 1.5);
       fill_data = error_fill(param.x, yMean, ySEM);
       h = fill(fill_data.X, fill_data.Y, get_color(param.jointColors{joint}), 'EdgeColor','none');
       set(h, 'facealpha',param.jointFillWeights{joint});
       
       title([num2str(num_vids) ' trials']);
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
        
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
%            title('0 sec');
       elseif pltIdx == 2
%            title('0.03 sec');
       elseif pltIdx == 3
%            title('0.1 sec');
       elseif pltIdx == 4
%            title('0.33 sec');
       elseif pltIdx == 5    
%            title('1 sec');
       elseif pltIdx == 6
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 11
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 16
           ylabel(['TiTa (' char(176) ')']);
       end
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Aligned Joint Angle Mean & SEM');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_overview_mean&SEM_aligned_' preBehavior '2' postBehavior];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot FTi joint, # lasers, L1 leg -- subtract baseline angle -- mean & sem - (R01 figs)
fig = figure; hold on
leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};
% lasers = [1,2,3,4,5]; 
lasers = [1,4]; 

pltIdx = 1;
light_ons = [];
light_offs = [];
AX = [];
numData = [];
lines = [];
joint = 3; jnt = [leg_str '_FTi'];
clear numVids
for ll = 1:width(lasers)
   laser = lasers(ll);

   light_on = 0;
   light_off =(param.fps*param.lasers{laser})/param.fps;
   
   light_ons(ll) = light_on; 
   light_offs(ll) = light_off;
%    AX(pltIdx) = subplot(1, 1, pltIdx); hold on;

%     if ll == 2
%         % laser region 
%         y1 = rangeLine(fig);
%         x_points = [light_on, light_on, light_off, light_off];  
%         y_points = [-40, 40, 40, -40];
%         color = Color(param.laserColor);
%         hold on;
%         a = fill(x_points, y_points, color);
%         a.FaceAlpha = 0.3;
%         a.EdgeColor = 'none';
%     end

   jntIdx = find(contains(columns, jnt));

   %plot the data!
   all_data = NaN(height(behaviordata), param.vid_len_f);
   num_vids = 0;
   for vid = 1:height(behaviordata)
      if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
          num_vids = num_vids+1;
          
          start_idx = behaviordata{vid,9};
          end_idx = behaviordata{vid,10};

          d = data{start_idx:end_idx, jntIdx};
          if height(d == 600)
              a = d(param.laser_on);
              d = d-a;
              all_data(vid, :) = d;
          end
      end
   end
   numVids(ll) = num_vids; 
   
   %calculate mean and standard error of the mean 
   yMean = nanmean(all_data, 1);
   ySEM = sem(all_data, 1, nan, height(flyList));
   
   numData(ll) = sum(~isnan(all_data(:,1)));
   
   if laser == 1
       c = 'black'; %param.baseColor;
   else
       c = param.jointColors{joint};
   end
   %plot
   fill_data = error_fill(param.x, yMean, ySEM);
   h = fill(fill_data.X, fill_data.Y, get_color(c), 'EdgeColor','none');
   set(h, 'facealpha',param.jointFillWeights{joint});
   lines(ll) = plot(param.x, yMean, 'color', Color(c), 'linewidth', 1.5);
   

   if param.xlimit; xlim(param.xlim); end
   if param.ylimit; ylim([-40,80]); yticks([-40, 0, 40, 80]); end

   %label
   if pltIdx == 1
       ylabel(['Femur-tibia angle (' char(176) ')'],  'FontSize', 40);
       xlabel('Time (s)',  'FontSize', 40);
%        title('0 sec');
   end
   
   xlim([-0.5 1]);
   ylim([-40 80]);
   
   
   pltIdx = pltIdx+1;

end

legend(lines, num2str(numData(1)), num2str(numData(2)));

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
        %plot lasers
    for p = 1:pltIdx-1 
%         subplot(1,1, p); hold on
        y1 = rangeLine(fig);
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
%         hold off
    end

end

fig = formatFig(fig, false);

hold off;


% han=axes(fig,'visible','off'); 
% han.Title.Visible='on';
% title(han, ' L1 Aligned Joint Angle Mean & SEM');
% set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

set(gca, 'fontsize', 20);


fig_name = [param.legs{leg} '_overview_mean&SEM_aligned_' preBehavior '2' postBehavior '_' 'Lasers' num2str(param.lasers{lasers(1)}) '&' num2str(param.lasers{lasers(2)})];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], '-pdf');

%% Plot all joints, all lasers, one leg -- ANGLE CHANGE 

fig = fullfig;
pltIdx = 0;
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data  
       if joint == 1; jnt = [leg_str '_BC'];
       elseif joint == 2; jnt = [leg_str '_CF'];
       elseif joint == 3; jnt = [leg_str '_FTi'];
       elseif joint == 4; jnt = [leg_str '_TiTa'];
       end
       jntIdx = find(contains(columns, jnt));

       %plot the data!
       for vid = 1:height(behaviordata)
          if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
              start_idx = behaviordata{vid,9};
              end_idx = behaviordata{vid,10};

              d = data{start_idx:end_idx, jntIdx};
              if height(d == 600)
                  plot(param.x(1:end-1), diff(d)); 
              end
          end
       end
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % plot laser region 
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.1 sec');
       elseif pltIdx == 4
           title('0.33 sec');
       elseif pltIdx == 5    
           title('1 sec');
       elseif pltIdx == 6
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 11
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 16
            ylabel(['TiTa (' char(176) ')']);
       end
   end
end

fig = formatFig(fig, true, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Joint Angle Change');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))


hold off;

fig_name = ['\' param.legs{leg} '_overview_angleChange_' preBehavior '2' postBehavior];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% Lab Mtg 2021 Plots %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%% JOINT TRAJECTORIES - TIME SERIES DATA %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot: all joints, all lasers, one leg -- subtract baseline angle -- mean & sem - all walking 

%param
leg = 1; 

%%%%%%%%%%%%%%%
legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; 
leg_str = legs{leg};

fig = fullfig;
pltIdx = 0;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; jnt = [leg_str 'A_flex'];
       elseif joint == 2; jnt = [leg_str 'B_flex'];
       elseif joint == 3; jnt = [leg_str 'C_flex'];
       elseif joint == 4; jnt = [leg_str 'D_flex'];
       end
       jntIdx = find(contains(columns, jnt));

       %plot the data!
       all_data = NaN(height(behaviordata), param.vid_len_f);
       num_vids = 0;
       for vid = 1:height(behaviordata)
          if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
              start_idx = behaviordata{vid,9};
              end_idx = behaviordata{vid,10};

              d = data{start_idx:end_idx, jntIdx};
              if height(d) == 600
                  num_vids = num_vids + 1;
%                   fprintf(['\njoint:' num2str(joint) ' laser:' num2str(laser) ' vid:' num2str(vid)]);
                  a = d(param.laser_on);
                  d = d-a;
                  all_data(vid, :) = d;
              end
          end
       end
       numVids(joint, laser) = num_vids;
       %calculate mean and standard error of the mean 
       yMean = nanmean(all_data, 1);
       ySEM = sem(all_data, 1, nan, height(flyList));
       
       %plot
       plot(param.x, yMean, 'color', Color(param.jointColors{joint}), 'linewidth', 1.5);
       fill_data = error_fill(param.x, yMean, ySEM);
       h = fill(fill_data.X, fill_data.Y, get_color(param.jointColors{joint}), 'EdgeColor','none');
       set(h, 'facealpha',param.jointFillWeights{joint});
       
       title([num2str(num_vids) ' trials']);
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
        
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
%            title('0 sec');
       elseif pltIdx == 2
%            title('0.03 sec');
       elseif pltIdx == 3
%            title('0.1 sec');
       elseif pltIdx == 4
%            title('0.33 sec');
       elseif pltIdx == 5    
%            title('1 sec');
       elseif pltIdx == 6
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 11
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 16
           ylabel(['TiTa (' char(176) ')']);
       end
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Aligned Joint Angle Mean & SEM');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_overview_mean&SEM_aligned_' preBehavior '2' postBehavior];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Plot: all joints, all lasers, one leg -- subtract baseline angle -- mean & sem - forward walking & forward velocity > 1 mm/s

leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};

fig = fullfig;
pltIdx = 0;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; jnt = [leg_str '_BC'];
       elseif joint == 2; jnt = [leg_str '_CF'];
       elseif joint == 3; jnt = [leg_str '_FTi'];
       elseif joint == 4; jnt = [leg_str '_TiTa'];
       end
       jntIdx = find(contains(columns, jnt));

       %plot the data!
       all_data = NaN(height(behaviordata), param.vid_len_f);
       num_vids = 0;
       for vid = 1:height(behaviordata)
          if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
              start_idx = behaviordata{vid,9};
              end_idx = behaviordata{vid,10};

              d = data{start_idx:end_idx, jntIdx};
              if height(d) == 600
                  %only save if forward walking and forward_velocity > 3 mm/s
                  if data.forward_rotation(start_idx+param.laser_on) & data.forward_velocity(start_idx+param.laser_on) > 1
                      num_vids = num_vids + 1;
%                     fprintf(['\njoint:' num2str(joint) ' laser:' num2str(laser) ' vid:' num2str(vid)]);
                      a = d(param.laser_on);
                      d = d-a;
                      all_data(vid, :) = d;
                  end
              end
          end
       end
       numVids(joint, laser) = num_vids;
       %calculate mean and standard error of the mean 
       yMean = nanmean(all_data, 1);
       ySEM = sem(all_data, 1, nan, height(flyList));
       
       %plot
       plot(param.x, yMean, 'color', Color(param.jointColors{joint}), 'linewidth', 1.5);
       fill_data = error_fill(param.x, yMean, ySEM);
       h = fill(fill_data.X, fill_data.Y, get_color(param.jointColors{joint}), 'EdgeColor','none');
       set(h, 'facealpha',param.jointFillWeights{joint});
       
       title([num2str(num_vids) ' trials']);
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
        
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
%            title('0 sec');
       elseif pltIdx == 2
%            title('0.03 sec');
       elseif pltIdx == 3
%            title('0.1 sec');
       elseif pltIdx == 4
%            title('0.33 sec');
       elseif pltIdx == 5    
%            title('1 sec');
       elseif pltIdx == 6
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 11
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 16
           ylabel(['TiTa (' char(176) ')']);
       end
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Aligned Joint Angle Mean & SEM');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_overview_mean&SEM_aligned_' preBehavior '2' postBehavior '_forward walking_&_forward velocity_over_1'];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Plot: all joints, all lasers, one leg -- subtract baseline angle -- mean & sem - forward walking & forward velocity > 1 mm/s - speed binned

leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};
speed_colors = {'red', 'orange', 'green', 'white'};

fig = fullfig;
pltIdx = 0;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; jnt = [leg_str '_BC'];
       elseif joint == 2; jnt = [leg_str '_CF'];
       elseif joint == 3; jnt = [leg_str '_FTi'];
       elseif joint == 4; jnt = [leg_str '_TiTa'];
       end
       jntIdx = find(contains(columns, jnt));

       %plot the data!
       numVids = [];
       for speed_bin = 2:height(unique(data.speed_bin))-1
           all_data = NaN(height(behaviordata), param.vid_len_f);
           num_vids = 0;
           for vid = 1:height(behaviordata)
              if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
                  start_idx = behaviordata{vid,9};
                  end_idx = behaviordata{vid,10};

                  d = data{start_idx:end_idx, jntIdx};
                  if height(d) == 600
                      %only save if forward walking
                      if data.forward_rotation(start_idx+param.laser_on) && data.forward_velocity(start_idx+param.laser_on) > 1 & data.speed_bin(start_idx+param.laser_on) == speed_bin
                          num_vids = num_vids + 1;
    %                     fprintf(['\njoint:' num2str(joint) ' laser:' num2str(laser) ' vid:' num2str(vid)]);
                          a = d(param.laser_on);
                          d = d-a;
                          all_data(vid, :) = d;
                      end
                  end
              end
           end
%            numVids(joint, laser, speed_bin) = num_vids;
           %calculate mean and standard error of the mean 
           yMean = nanmean(all_data, 1);
           ySEM = sem(all_data, 1, nan, height(flyList));

           %plot
           plot(param.x, yMean, 'color', Color(speed_colors{speed_bin}), 'linewidth', 1.5);
           fill_data = error_fill(param.x, yMean, ySEM);
           h = fill(fill_data.X, fill_data.Y, Color(speed_colors{speed_bin}), 'EdgeColor','none');
           set(h, 'facealpha',param.jointFillWeights{joint});
       
           numVids(end+1) = num_vids;
       end
       
       title(['slow ' num2str(numVids(1)) ' med ' num2str(numVids(2))]);
%        title(['slow ' num2str(numVids(1)) ' med ' num2str(numVids(2)) ' fast ' num2str(numVids(3))]);
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
        
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
%            title('0 sec');
       elseif pltIdx == 2
%            title('0.03 sec');
       elseif pltIdx == 3
%            title('0.1 sec');
       elseif pltIdx == 4
%            title('0.33 sec');
       elseif pltIdx == 5    
%            title('1 sec');
       elseif pltIdx == 6
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 11
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 16
           ylabel(['TiTa (' char(176) ')']);
       end
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Aligned Joint Angle Mean & SEM');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_overview_mean&SEM_aligned_' preBehavior '2' postBehavior '_forward walking_&_forward velocity_over_1_speed_binned'];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Plot: all joints, all lasers, one leg -- subtract baseline angle -- mean & sem - speed_bin = 2 - turning binned

leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};
turn_colors = parula(4);

fig = fullfig;
pltIdx = 0;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; jnt = [leg_str '_BC'];
       elseif joint == 2; jnt = [leg_str '_CF'];
       elseif joint == 3; jnt = [leg_str '_FTi'];
       elseif joint == 4; jnt = [leg_str '_TiTa'];
       end
       jntIdx = find(contains(columns, jnt));

       %plot the data!
       numVids = [];
       for turn_bin = 5:8
           all_data = NaN(height(behaviordata), param.vid_len_f);
           num_vids = 0;
           for vid = 1:height(behaviordata)
              if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
                  start_idx = behaviordata{vid,9};
                  end_idx = behaviordata{vid,10};

                  d = data{start_idx:end_idx, jntIdx};
                  if height(d) == 600
                      %only save if forward walking
                      if data.speed_bin(start_idx+param.laser_on) == 2 & data.heading_bin(start_idx+param.laser_on) == turn_bin
                          num_vids = num_vids + 1;
    %                     fprintf(['\njoint:' num2str(joint) ' laser:' num2str(laser) ' vid:' num2str(vid)]);
                          a = d(param.laser_on);
                          d = d-a;
                          all_data(vid, :) = d;
                      end
                  end
              end
           end
%            numVids(joint, laser, speed_bin) = num_vids;
           %calculate mean and standard error of the mean 
           yMean = nanmean(all_data, 1);
           ySEM = sem(all_data, 1, nan, height(flyList));

           %plot
           plot(param.x, yMean, 'color', turn_colors(turn_bin-4,:), 'linewidth', 1.5);
           fill_data = error_fill(param.x, yMean, ySEM);
           h = fill(fill_data.X, fill_data.Y, turn_colors(turn_bin-4,:), 'EdgeColor','none');
           set(h, 'facealpha',param.jointFillWeights{joint});
       
           numVids(end+1) = num_vids;
       end
       
       title(['left ' num2str(numVids(1)) ' ' num2str(numVids(2)) ' ' num2str(numVids(3)) ' ' num2str(numVids(4)) ' right']);
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
        
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
%            title('0 sec');
       elseif pltIdx == 2
%            title('0.03 sec');
       elseif pltIdx == 3
%            title('0.1 sec');
       elseif pltIdx == 4
%            title('0.33 sec');
       elseif pltIdx == 5    
%            title('1 sec');
       elseif pltIdx == 6
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 11
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 16
           ylabel(['TiTa (' char(176) ')']);
       end
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Aligned Joint Angle Mean & SEM');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_overview_mean&SEM_aligned_' preBehavior '2' postBehavior '_speed_bin=2_&_turning_binned'];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Plot: group mean and sem of single joint across lasers. - all walking
joint = 'L1_FTi'; %what to plot

fig = fullfig;
plotting = numSubplots(param.numLasers);

for laser = 1:param.numLasers
    vid_num = 0;
    this_laser_conds = find(param.laserIdx == laser);
    this_laser = find(ismember([behaviordata{:,3}],this_laser_conds));
    flyMeans = NaN(height(flyList), param.vid_len_f);
    flySems = NaN(height(flyList), param.vid_len_f);
    this_data_starts = behaviordata(this_laser, 9);
    this_data_ends = behaviordata(this_laser, 10);
    all_vids = NaN(height(this_data_starts), param.vid_len_f);
    for vid = 1:height(this_data_starts)
        vid_num = vid_num+1;
        this_vid_len = width(this_data_starts{vid}:this_data_ends{vid});
        %normalized
        all_vids(vid,1:this_vid_len) = data.(joint)(this_data_starts{vid}:this_data_ends{vid}) - data.(joint)(this_data_starts{vid}+param.laser_on);
    end
    AX(laser) = subplot(plotting(1), plotting(2), laser); hold on
    grandMean = nanmean(all_vids); 
    grandSem = sem(all_vids, 1, nan, height(flyList));
    
    %plot grand mean & sem
    plot(param.x, grandMean, 'color', Color(param.expColor), 'linewidth', 2);
    fill_data = error_fill(param.x, grandMean, grandSem);
    h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
    set(h, 'facealpha', 0.2);
    
    % laser region 
    if param.sameAxes
       %save light length for plotting after syching lasers
       light_ons(laser) = 0;
       light_offs(laser) = param.lasers{laser};
    else
       %plot laser
       y1 = rangeLine(fig);
       pl = plot([0, param.lasers{laser}], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
    end
    
    title([num2str(vid_num) ' trials']);
    
    
    hold off


end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:laser  
        subplot(plotting(1), plotting(2), p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, plotting);

%save
fig_name = ['\' joint '_trajectory_group_mean_&_sem'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Plot: one fly single traces and mean of single joint across lasers. 
joint = 'L1_FTi'; %what to plot
fly = 1; %indexs into flyList

fig = fullfig;
plotting = numSubplots(param.numLasers);

for laser = 1:param.numLasers
    this_laser_conds = find(param.laserIdx == laser);
    this_laser = find(ismember([behaviordata{:,3}],this_laser_conds));    flyMeans = NaN(height(flyList), param.vid_len_f);
    this_fly = find(strcmpi([behaviordata{:,11}], flyList.flyid(fly)));
    this_fly_starts = behaviordata(intersect(this_fly,this_laser), 9);
    this_fly_ends = behaviordata(intersect(this_fly,this_laser), 10);
    all_vids = NaN(height(this_fly_starts), param.vid_len_f);
    for vid = 1:height(this_fly_starts)
        this_vid_len = width(this_fly_starts{vid}:this_fly_ends{vid});
        %raw
%             all_vids(vid,1:this_vid_len) = data.(joint)(this_fly_starts{vid}:this_fly_ends{vid});
        %normalized
        all_vids(vid,1:this_vid_len) = data.(joint)(this_fly_starts{vid}:this_fly_ends{vid}) - data.(joint)(this_fly_starts{vid}+param.laser_on);
    end
    flyMean = nanmean(all_vids);
    flySem = sem(all_vids, 1, nan, 1);
    AX(laser) = subplot(plotting(1), plotting(2), laser);
    
    %plot fly trajectories
    plot(param.x,all_vids', 'color', Color('grey')); hold on;
    %plot grand mean & sem
    plot(param.x, flyMean, 'color', Color(param.expColor), 'linewidth', 2);
%     fill_data = error_fill(param.x, grandMean, grandSem);
%     h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
%     set(h, 'facealpha', 0.2);
    
    % laser region 
    if param.sameAxes
       %save light length for plotting after syching lasers
       light_ons(laser) = 0;
       light_offs(laser) = param.lasers{laser};
    else
       %plot laser
       y1 = rangeLine(fig);
       pl = plot([0, param.lasers{laser}], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
    end
    
    
    hold off


end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:laser  
        subplot(plotting(1), plotting(2), p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, plotting);

%save
fig_name = ['\' joint '_trajectory_' flyList.flyid{fly} '_single_traces_&_mean'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Plot: one fly single traces and mean of single joint across lasers. - only forward walking at onset
joint = 'L1_FTi'; %what to plot
fly = 1; %indexs into flyList

fig = fullfig;
plotting = numSubplots(param.numLasers);

for laser = 1:param.numLasers
    this_laser_conds = find(param.laserIdx == laser);
    this_laser = find(ismember([behaviordata{:,3}],this_laser_conds));    flyMeans = NaN(height(flyList), param.vid_len_f);
    this_fly = find(strcmpi([behaviordata{:,11}], flyList.flyid(fly)));
    this_fly_starts = behaviordata(intersect(this_fly,this_laser), 9);
    this_fly_ends = behaviordata(intersect(this_fly,this_laser), 10);
    all_vids = NaN(height(this_fly_starts), param.vid_len_f);
    for vid = 1:height(this_fly_starts)
        if data.forward_rotation(this_fly_starts{vid}+param.laser_on)
            this_vid_len = width(this_fly_starts{vid}:this_fly_ends{vid});
            %raw
    %             all_vids(vid,1:this_vid_len) = data.(joint)(this_fly_starts{vid}:this_fly_ends{vid});
            %normalized
            all_vids(vid,1:this_vid_len) = data.(joint)(this_fly_starts{vid}:this_fly_ends{vid}) - data.(joint)(this_fly_starts{vid}+param.laser_on);
        end
    end
    flyMean = nanmean(all_vids);
    flySem = sem(all_vids, 1, nan, 1);
    AX(laser) = subplot(plotting(1), plotting(2), laser);
    
    %plot fly trajectories
    plot(param.x,all_vids', 'color', Color('grey')); hold on;
    %plot grand mean & sem
    plot(param.x, flyMean, 'color', Color(param.expColor), 'linewidth', 2);
%     fill_data = error_fill(param.x, grandMean, grandSem);
%     h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
%     set(h, 'facealpha', 0.2);
    
    % laser region 
    if param.sameAxes
       %save light length for plotting after syching lasers
       light_ons(laser) = 0;
       light_offs(laser) = param.lasers{laser};
    else
       %plot laser
       y1 = rangeLine(fig);
       pl = plot([0, param.lasers{laser}], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
    end
    
    
    hold off


end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:laser  
        subplot(plotting(1), plotting(2), p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, plotting);

%save
fig_name = ['\' joint '_trajectory_' flyList.flyid{fly} '_single_traces_&_mean_forward_walking'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Plot: fly and grand means of single joint across lasers. 
joint = 'L1_FTi'; %what to plot

fig = fullfig;
plotting = numSubplots(param.numLasers);

for laser = 1:param.numLasers
    this_laser_conds = find(param.laserIdx == laser);
    this_laser = find(ismember([behaviordata{:,3}],this_laser_conds));    flyMeans = NaN(height(flyList), param.vid_len_f);
    flySems = NaN(height(flyList), param.vid_len_f);
    for fly = 1:height(flyList)
        this_fly = find(strcmpi([behaviordata{:,11}], flyList.flyid(fly)));
        this_fly_starts = behaviordata(intersect(this_fly,this_laser), 9);
        this_fly_ends = behaviordata(intersect(this_fly,this_laser), 10);
        all_vids = NaN(height(this_fly_starts), param.vid_len_f);
        for vid = 1:height(this_fly_starts)
            this_vid_len = width(this_fly_starts{vid}:this_fly_ends{vid});
            %raw
%             all_vids(vid,1:this_vid_len) = data.(joint)(this_fly_starts{vid}:this_fly_ends{vid});
            %normalized
            all_vids(vid,1:this_vid_len) = data.(joint)(this_fly_starts{vid}:this_fly_ends{vid}) - data.(joint)(this_fly_starts{vid}+param.laser_on);
        end
        flyMeans(fly,:) = nanmean(all_vids);
        flySems(fly,:) = sem(all_vids, 1, nan, 1);
    end
    AX(laser) = subplot(plotting(1), plotting(2), laser);
    grandMean = nanmean(flyMeans); 
    grandSem = sem(flySems, 1, nan, height(flyList));
    
    %plot fly means
    plot(param.x,flyMeans', 'color', Color('grey')); hold on;
    %plot grand mean & sem
    plot(param.x, grandMean, 'color', Color(param.expColor), 'linewidth', 2);
%     fill_data = error_fill(param.x, grandMean, grandSem);
%     h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
%     set(h, 'facealpha', 0.2);
    
    % laser region 
    if param.sameAxes
       %save light length for plotting after syching lasers
       light_ons(laser) = 0;
       light_offs(laser) = param.lasers{laser};
    else
       %plot laser
       y1 = rangeLine(fig);
       pl = plot([0, param.lasers{laser}], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
    end
    
    
    hold off


end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:laser  
        subplot(plotting(1), plotting(2), p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, plotting);

%save
fig_name = ['\' joint '_trajectory_fly_&_grand_means'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Plot: fly and grand means of single joint across lasers. - only forward walking at onset
joint = 'L1_FTi'; %what to plot

fig = fullfig;
plotting = numSubplots(param.numLasers);

for laser = 1:param.numLasers
    this_laser_conds = find(param.laserIdx == laser);
    this_laser = find(ismember([behaviordata{:,3}],this_laser_conds));    
    flyMeans = NaN(height(flyList), param.vid_len_f);
    flySems = NaN(height(flyList), param.vid_len_f);
    for fly = 1:height(flyList)
        this_fly = find(strcmpi([behaviordata{:,11}], flyList.flyid(fly)));
        this_fly_starts = behaviordata(intersect(this_fly,this_laser), 9);
        this_fly_ends = behaviordata(intersect(this_fly,this_laser), 10);
        all_vids = NaN(height(this_fly_starts), param.vid_len_f);
        for vid = 1:height(this_fly_starts)
            %make sure fly is walking forward
            if data.forward_rotation(this_fly_starts{vid}+param.laser_on)
                this_vid_len = width(this_fly_starts{vid}:this_fly_ends{vid});
                all_vids(vid,1:this_vid_len) = data.(joint)(this_fly_starts{vid}:this_fly_ends{vid}) - data.(joint)(this_fly_starts{vid}+param.laser_on);
            end
        end
        flyMeans(fly,:) = nanmean(all_vids);
        flySems(fly,:) = sem(all_vids, 1, nan, 1);
    end
    AX(laser) = subplot(plotting(1), plotting(2), laser);
    grandMean = nanmean(flyMeans); 
    grandSem = sem(flySems, 1, nan, height(flyList));
    
    %plot fly means
    plot(param.x,flyMeans', 'color', Color('grey')); hold on;
    %plot grand mean & sem
    plot(param.x, grandMean, 'color', Color(param.expColor), 'linewidth', 2);
%     fill_data = error_fill(param.x, grandMean, grandSem);
%     h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
%     set(h, 'facealpha', 0.2);
    
    % laser region 
    if param.sameAxes
       %save light length for plotting after syching lasers
       light_ons(laser) = 0;
       light_offs(laser) = param.lasers{laser};
    else
       %plot laser
       y1 = rangeLine(fig);
       pl = plot([0, param.lasers{laser}], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
    end
    
    
    hold off


end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:laser  
        subplot(plotting(1), plotting(2), p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, plotting);

%save
fig_name = ['\' joint '_trajectory_fly_&_grand_means_forward_walking'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% %%%%%%%%%%%%%%%%%% Organize Steps %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% (Lab Mtg 2021) CALCULATE: swing stance for all walking bouts
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
boutMap = table('Size', [0,10], 'VariableTypes',{'double', 'double', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'cell', 'double'},'VariableNames',{'oldBout','newBout','walkingDataIdxs','L1_swing_stance','L2_swing_stance','L3_swing_stance','R1_swing_stance','R2_swing_stance','R3_swing_stance', 'enough_steps'});
for bout = 1:height(boutNums)
    %get idxs of all data with this 'walking_bout_number'
    boutIdxs = find(walkingData.walking_bout_number == boutNums(bout)); 
    if height(boutIdxs) > 10 % a walking bout must be at least 10 frames. 
        %find where the frame number jumps, indicating multiple walking bouts with same 'walking_bout_number'
        [~, locs] = findpeaks(diff(boutIdxs), 'MinPeakProminence', 2);
        %find how many walking bout have same bout number 
        if isempty(locs); numSubBouts = 1; else; numSubBouts = height(locs)+1; end
        locs = [0; locs; height(boutIdxs)];

        for subBout = 1:numSubBouts
            
           % make sure there's more than 10 frames in the subbout
           if width(boutIdxs(locs(subBout)+1):boutIdxs(locs(subBout+1))) > 10
               
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
        boutMap.enough_steps(bout) = 0;
    else
        %there's enough steps, select forward walking and get rid of the first and last steps.
        boutMap.enough_steps(bout) = 1;
%         this_forward_rot = walkingData.forward_rotation(boutMap.walkingDataIdxs{bout});
%         not_forward_rot = find(this_forward_rot ~= 1);
%         boutMap.forward_rotation{bout} = walkingData.forward_rotation(boutMap.walkingDataIdxs{bout});
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
%% (Lab Mtg 2021) NEW (for Lab Mtg 2021) (filter by forward after metrics) - CALCULATE: step freq, speed, temp, heading dir, step length, stance dur, swing dur from BOUTMAP
clear steps

%legs and joints to add data of 
joints = {'_FTi', 'B_rot', 'E_x', 'E_y', 'E_z'};
joint_names = {'FTi', 'B_rot', 'E_x', 'E_y', 'E_z'};

% define butterworth filter for hilbert transform.
[A,B,C,D] = butter(1,[0.02 0.4],'bandpass');
sos = ss2sos(A,B,C,D);

%get a list of bouts where ther were enough steps in 'swing stance' screening
% goodBouts=find(~cellfun('isempty', boutMap{:,'forward_rotation'}));
goodBouts = find(boutMap.enough_steps == 1);

steps = struct;
for leg = 1:param.numLegs
    steps.leg(leg).meta = table('Size', [0,15], 'VariableTypes',{'string','cell','double', 'double','double', 'double','double', 'double','double', 'double','double', 'double','double', 'double','double'},'VariableNames',{'fly', 'walkingDataIdxs', 'step_frequency', 'step_length', 'swing_duration', 'stance_duration', 'avg_heading_angle', 'avg_heading_bin', 'avg_forward_rotation', 'avg_speed', 'avg_speed_bin', 'avg_forward_velocity', 'avg_angular_velocity', 'avg_temp', 'avg_stim'});
%     steps.leg(leg).FTi = NaN(1, 100);
end

leg_step_idxs = [0, 0, 0, 0, 0, 0]; %row idxs for saving data in steps struct
for bout = 1:height(goodBouts)
    this_bout = goodBouts(bout); %idx in boutMap
    this_bout_idxs = boutMap.walkingDataIdxs{this_bout}; %idxs in walkingData
    
    % calculate metrics that are the same across legs
    % fly number
    this_fly = walkingData.flyid{this_bout_idxs(1)};
    % opto stim region 
    this_laser_length = param.allLasers(walkingData.condnum(this_bout_idxs(1))); %in seconds
    this_stim = zeros(width(this_bout_idxs),1); % 0 = no stim; 1 = stim
    this_fnum = walkingData.fnum(this_bout_idxs);
    laser_off = param.laser_on+(this_laser_length*param.fps);
    if this_laser_length > 0 & ~(this_fnum(1) > laser_off | this_fnum(end) < param.laser_on) %TODO check that this is correct logic
        this_stim(this_fnum >=param.laser_on & this_fnum < laser_off) = 1;
    end
    
    for leg = 1:param.numLegs
        %indexes within bout
        this_swing_stance = boutMap.([param.legs{leg} '_swing_stance']){this_bout}; %swing = 1; stance = 0
        this_stance_starts = [find(this_swing_stance == 0,1,'first'); find(diff(this_swing_stance) == -1)+1; find(this_swing_stance == 1,1,'last');]; %first idxs of stance
        this_stance_ends = find(diff(this_swing_stance) == 1); %last idxs of stances
        %same indexes in walkingData - add start idx of bout in walkingData to convert from bout to walkingData idxs
        this_stance_starts_walkingData = this_stance_starts + this_bout_idxs(1); %TODO check this
%         this_stance_ends_walkingData = this_stance_ends + this_bout_idxs(1); %TODO check this

        %Get all of the joint data
        jointTable = table;
        phaseTable = table;
        for joint = 1:width(joints)
            joint_str = [param.legs{leg} joints{joint}];
            jointTable.(joint_str) = walkingData.(joint_str)(this_bout_idxs);
            %calcualte phase (hilbert transform)
            normed_data = (jointTable.(joint_str)-nanmean(jointTable.(joint_str)))/nanstd(jointTable.(joint_str));
            bfilt_data = sosfilt(sos, normed_data);  %bandpass frequency filter for hilbert transform            
            phaseTable.(joint_str) = angle(hilbert(bfilt_data));
        end
   
        %calculate and save metrics and data for each step    
        for st = 1:height(this_stance_ends)
            % step idxs in bout - for indexing into jointTable
            this_step_idxs = this_stance_starts(st):this_stance_starts(st+1);
            this_stance = this_stance_starts(st):this_stance_ends(st);
            this_swing = this_stance_ends(st)+1:this_stance_starts(st+1);
            
            % step idxs in walkingData
            this_step_idxs_walkingData = this_stance_starts_walkingData(st):this_stance_starts_walkingData(st+1);
%             this_stance_walkingData = this_stance_starts_walkingData(st):this_stance_ends_walkingData(st);
%             this_swing_walkingData = this_stance_ends_walkingData(st)+1:this_stance_starts_walkingData(st+1);

            %calculate step frequency
            step_freq =  1./(width(this_step_idxs)/param.fps);
            
            %calculate step length - TODO what are the units?
            shift_val = 10; %add to each position value to make them all positive. 0 point from anipose is L1_BC position.
            start_positions = [jointTable.([param.legs{leg} 'E_x'])(this_stance(1)), jointTable.([param.legs{leg} 'E_y'])(this_stance(1)), jointTable.([param.legs{leg} 'E_z'])(this_stance(1))];
            end_positions = [jointTable.([param.legs{leg} 'E_x'])(this_stance(end)), jointTable.([param.legs{leg} 'E_y'])(this_stance(end)), jointTable.([param.legs{leg} 'E_z'])(this_stance(end))];
            start_positions = start_positions + shift_val;
            end_positions = end_positions + shift_val;
            step_length = sqrt((end_positions(1)-start_positions(1))^2 + (end_positions(2)-start_positions(2))^2 + (end_positions(3)-start_positions(3))^2);            
           
            %calculate swing and stance duration 
            swing_duration = width(this_swing)/param.fps;
            stance_duration = width(this_stance)/param.fps;
            
            %calculate avgs: heading, speed, temp,
            avg_heading_angle = nanmean(walkingData.heading_angle(this_step_idxs_walkingData));
            avg_speed = nanmean(walkingData.speed(this_step_idxs_walkingData));
            avg_forward_velocity = nanmean(walkingData.forward_velocity(this_step_idxs_walkingData));
            avg_angular_velocity = nanmean(walkingData.angular_velocity(this_step_idxs_walkingData));
            avg_sideslip_velocity = nanmean(walkingData.sideslip_velocity(this_step_idxs_walkingData));
            avg_temp = nanmean(walkingData.temp(this_step_idxs_walkingData));
            
            %calcualte avg bins: percent forward & avg speed bin 
            avg_speed_bin = nanmean(walkingData.speed_bin(this_step_idxs_walkingData));
            avg_forward_rotation = nanmean(walkingData.forward_rotation(this_step_idxs_walkingData)); %(0 = fully not forward, 1 = fully forward)
            avg_heading_bin = nanmean(walkingData.heading_bin(this_step_idxs_walkingData));
            
            %calculate percent opto (0 = fully no stim, 1 = fully stim)
            avg_stim = nanmean(this_stim(this_step_idxs));
                
            %save everything! - all metrics + joint and phase variables. 
            leg_step_idxs(leg) = leg_step_idxs(leg)+1; %update leg step idx.
            for joint = 1:width(joints)
                joint_str = [param.legs{leg} joints{joint}];
                steps.leg(leg).(joint_names{joint})(leg_step_idxs(leg),1:width(this_step_idxs)) = jointTable.(joint_str)(this_step_idxs);
                steps.leg(leg).([joint_names{joint} '_phase'])(leg_step_idxs(leg),1:width(this_step_idxs)) = phaseTable.(joint_str)(this_step_idxs);
            end
            steps.leg(leg).meta.fly(leg_step_idxs(leg)) = this_fly;
            steps.leg(leg).meta.walkingDataIdxs{leg_step_idxs(leg)} = this_step_idxs_walkingData;
            steps.leg(leg).meta.step_frequency(leg_step_idxs(leg)) = step_freq;
            steps.leg(leg).meta.step_length(leg_step_idxs(leg)) = step_length;
            steps.leg(leg).meta.swing_duration(leg_step_idxs(leg)) = swing_duration;
            steps.leg(leg).meta.stance_duration(leg_step_idxs(leg)) = stance_duration;
            steps.leg(leg).meta.avg_heading_angle(leg_step_idxs(leg)) = avg_heading_angle;
            steps.leg(leg).meta.avg_heading_bin(leg_step_idxs(leg)) = avg_heading_bin;
            steps.leg(leg).meta.avg_forward_rotation(leg_step_idxs(leg)) = avg_forward_rotation;
            steps.leg(leg).meta.avg_speed(leg_step_idxs(leg)) = avg_speed;
            steps.leg(leg).meta.avg_speed_bin(leg_step_idxs(leg)) = avg_speed_bin;
            steps.leg(leg).meta.avg_forward_velocity(leg_step_idxs(leg)) = avg_forward_velocity;
            steps.leg(leg).meta.avg_angular_velocity(leg_step_idxs(leg)) = avg_angular_velocity; 
            steps.leg(leg).meta.avg_sideslip_velocity(leg_step_idxs(leg)) = avg_sideslip_velocity; 
            steps.leg(leg).meta.avg_temp(leg_step_idxs(leg)) = avg_temp;
            steps.leg(leg).meta.avg_stim(leg_step_idxs(leg)) = avg_stim;         
        end
        
    end
end

%find where this_joint_data is zero and replace with NaN
for leg = 1:param.numLegs 
    for joint = 1:width(joints)
        [rows,cols]=find(~steps.leg(leg).(joint_names{joint}));
        if ~isempty(rows)
            for val = 1:height(rows)
                steps.leg(leg).(joint_names{joint})(rows(val),cols(val)) = NaN;
                steps.leg(leg).([joint_names{joint} '_phase'])(rows(val),cols(val)) = NaN;
            end
        end
    end
end

initial_vars{end+1} = 'steps';
clearvars('-except',initial_vars{:}); initial_vars = who;

%% %%%&&&%%%%%%% STEP ANALYSES - JOINT X PHASE %%&&&&&%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Organize data for plotting joint x phase - single fly data and gand means
clear ctl_grandmean exp_grandmean ctl_fly_means exp_fly_means phase_bins

leg = 2; 
joint = 'E_y'; %'FTi';

%calculate mean joint data across phase
phasesigdig = 2; phasesigstep = 0.01; %sigstep should be rounded to sigdig
jointsigdig = 1; jointsigstep = 0.1; %sigstep should be rounded to sigdig
phase_bins = round([-3.15:phasesigstep:3.15]',phasesigdig);
angle_bins = [0:jointsigstep:180];

ctl_fly_means = NaN(height(flyList), height(phase_bins));
exp_fly_means = NaN(height(flyList), height(phase_bins));

numSteps = table('Size', [0,2], 'VariableTypes', {'double', 'double'}, 'VariableNames', {'control', 'stim'});;

for fly = 1:height(flyList)

    goodStepsCtl = find(strcmpi(steps.leg(leg).meta.fly, flyList.flyid(fly)) & steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 0);
    goodStepsExp = find(strcmpi(steps.leg(leg).meta.fly, flyList.flyid(fly)) & steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 1);

    this_joint_data_ctl = steps.leg(leg).(joint)(goodStepsCtl,:);
    this_phase_data_ctl = steps.leg(leg).([joint '_phase'])(goodStepsCtl,:);
    this_joint_data_exp = steps.leg(leg).(joint)(goodStepsExp,:);
    this_phase_data_exp = steps.leg(leg).([joint '_phase'])(goodStepsExp,:);
    
    numSteps.ctl(fly) = height(this_joint_data_ctl);
    numSteps.exp(fly) = height(this_joint_data_exp);
    
    %bin angle data
    ctl_joint_bin_idxs = discretize(this_joint_data_ctl(:), angle_bins); %this won't work until joint data is correct.
    exp_joint_bin_idxs = discretize(this_joint_data_exp(:), angle_bins);   
    
    %bin phase data
    %get bin idxs
    ctl_phase_bin_idxs = discretize(this_phase_data_ctl(:), phase_bins);
    exp_phase_bin_idxs = discretize(this_phase_data_exp(:), phase_bins);
    
    % For density plot of phase x angle.  
    joint_phase_matrices.fly(fly).ctl = NaN(height(phase_bins)-1, width(angle_bins)); %phase x angle bin matrix to fill with counts
    joint_phase_matrices.fly(fly).exp = NaN(height(phase_bins)-1, width(angle_bins)); %phase x angle bin matrix to fill with counts
    for ang = 1:height(ctl_phase_bin_idxs)
        if ~isnan(ctl_joint_bin_idxs(ang))
            this_phase = ctl_phase_bin_idxs(ang);
            this_angle = ctl_joint_bin_idxs(ang);        
            joint_phase_matrices.fly(fly).ctl(this_phase, this_angle) = joint_phase_matrices.fly(fly).ctl(this_phase, this_angle)+1;
        end
    end
    for ang = 1:height(exp_phase_bin_idxs)
        if ~isnan(exp_phase_bin_idxs(ang))
            this_phase = exp_phase_bin_idxs(ang);
            this_angle = exp_phase_bin_idxs(ang);        
            joint_phase_matrices.fly(fly).exp(this_phase, this_angle) = joint_phase_matrices.fly(fly).exp(this_phase, this_angle)+1;
        end
    end
    
    
    % For fly mean (used to make grand mean)
    ctl_joint_data_temp = this_joint_data_ctl(:);
    exp_joint_data_temp = this_joint_data_exp(:);
    for ph = 1:height(phase_bins)-1
        ctl_fly_means(fly,ph) = nanmean(ctl_joint_data_temp(ctl_phase_bin_idxs == ph));
        exp_fly_means(fly,ph) = nanmean(exp_joint_data_temp(exp_phase_bin_idxs == ph));
    end
        
end %fly 

ctl_grandmean = smoothdata(nanmean(ctl_fly_means, 1), 'gaussian', 100);
exp_grandmean = smoothdata(nanmean(exp_fly_means, 1), 'gaussian', 100);

initial_vars{end+1} = 'ctl_grandmean'; 
initial_vars{end+1} = 'exp_grandmean';
initial_vars{end+1} = 'ctl_fly_means';
initial_vars{end+1} = 'exp_fly_means';
initial_vars{end+1} = 'joint_phase_matrices';
initial_vars{end+1} = 'phase_bins';
initial_vars{end+1} = 'leg';
initial_vars{end+1} = 'joint';
initial_vars{end+1} = 'numSteps';

clearvars('-except', initial_vars{:}); initial_vars = who;
%% Plot: joint angle x phase - ctl vs stim - means for each fly

% plotting = numSubplots(height(flyList));
% fig = fullfig; 
% fly_idx = 0;
for fly = 1:height(flyList)
%     if nansum(smoothdata(ctl_fly_means(fly,:))) > 0 & nansum(smoothdata(exp_fly_means(fly,:))) > 0
%         fly_idx = fly_idx+1;
%         subplot(plotting(1), plotting(2), fly_idx);
        fig = fullfig; 
        polarplot(phase_bins, smoothdata(ctl_fly_means(fly,:), 'gaussian', 50), 'Color', Color(param.baseColor), 'LineWidth', 2); hold on
        polarplot(phase_bins, smoothdata(exp_fly_means(fly,:), 'gaussian', 50), 'Color', Color(param.expColor), 'LineWidth', 2); hold off
        pax = gca;
        pax.FontSize = 14;
        pax.RColor = Color(param.baseColor);
        pax.ThetaColor = Color(param.baseColor);
%         rlim([0 180])
%         rticks([0,45,90,135,180])
%         thetaticks([0, 90, 180, 270]);
        
        title([num2str(numSteps.ctl(fly)) ' Ctl steps '  num2str(numSteps.exp(fly)) ' Exp steps']);
        
        fig = formatFigPolar(fig, true);
        %save
        fig_name = ['\' param.legs{leg} '_' joint '_x_phase_' flyList.flyid{fly}];
        save_figure(fig, [param.googledrivesave fig_name], param.fileType);
%     end
end

clearvars('-except',initial_vars{:}); initial_vars = who;
%% Plot: joint angle x phase - ctl vs stim - grand means

fig = fullfig; 
polarplot(phase_bins, ctl_grandmean, 'Color', Color(param.baseColor), 'LineWidth', 2); hold on
polarplot(phase_bins, exp_grandmean, 'Color', Color(param.expColor), 'LineWidth', 2); hold off
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

title([num2str(sum(numSteps.ctl(:))) ' Ctl steps '  num2str(sum(numSteps.exp(:))) ' Exp steps']);


fig = formatFigPolar(fig, true);
%save
fig_name = ['\' param.legs{leg} '_' joint '_x_phase_grandMeans'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


clearvars('-except',initial_vars{:}); initial_vars = who;

%% %%%%%%%%%%%%%%% STEP ANALYSES - STEP METRICS %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% all flies all legs
%% Plot: Step Frequency x avg_spded, avg_forward_velocity, and avg_angular_velocity - ctl vs stim - forward walking steps

fig = fullfig;
plotting = [param.numLegs, 3]; %rows x speed types
idx = 1;
for leg = 1:param.numLegs

    % select steps that are forward walking and hav min speed bin of 2
    ctl_step_idxs = find(steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 0);
    stim_step_idxs = find(steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 1);
    
    % step freq x AVG_SPEED
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.step_frequency(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.step_frequency(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor)); 
    hold off
    
    % step freq x AVG_FORWARD_VELOCITY
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_forward_velocity(ctl_step_idxs),steps.leg(leg).meta.step_frequency(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_forward_velocity(stim_step_idxs),steps.leg(leg).meta.step_frequency(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor));
    hold off
   
    % step freq x AVG_ANGULAR_VELOCITY
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_angular_velocity(ctl_step_idxs),steps.leg(leg).meta.step_frequency(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_angular_velocity(stim_step_idxs),steps.leg(leg).meta.step_frequency(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor));
    hold off
end

fig = formatFig(fig, true, plotting);

% save
fig_name = ['\Step_Frequency_x_avgSpeed_avgForwardVelocity_avgAngularVelocity_forwardWalkingOnly'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
%% Plot: Step Frequency x avg_spded, best fit lines - ctl vs stim - forward walking steps

fig = fullfig;
plotting = [param.numLegs, 2]; %rows x speed types
idx = 1;
for leg = 1:param.numLegs

    % select steps that are forward walking and hav min speed bin of 2
    ctl_step_idxs = find(steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 0);
    stim_step_idxs = find(steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 1);
    
    % step freq x AVG_SPEED
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.step_frequency(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.step_frequency(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor)); 
    hold off
    
    % step freq x AVG_SPEED
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.step_frequency(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    h = lsline;
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.step_frequency(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor)); 
    h = lsline;
    
    set(h(2),'color',Color(param.baseColor));
    set(h(2),'linewidth',2);
    set(h(1),'color',Color(param.laserColor));
    set(h(1),'linewidth',2);
    
    hold off
    
    title(param.legs{leg});
    xlabel('Speed (mm/s)');
    ylabel('Step Frequency (Hz)');
   
end

fig = formatFig(fig, true, plotting);

% save
fig_name = ['\Step_Frequency_x_avgSpeed_forwardWalkingOnly_bestfitlines'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
%% Plot: Step Length x avg_spded, avg_forward_velocity, and avg_angular_velocity - ctl vs stim - forward walking steps

fig = fullfig;
plotting = [param.numLegs, 3]; %rows x speed types
idx = 1;
for leg = 1:param.numLegs

    % select steps that are forward walking and hav min speed bin of 2
    ctl_step_idxs = find(steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 0);
    stim_step_idxs = find(steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 1);
    
    % step freq x AVG_SPEED
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.step_length(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.step_length(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor)); 
    hold off
    
    % step freq x AVG_FORWARD_VELOCITY
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_forward_velocity(ctl_step_idxs),steps.leg(leg).meta.step_length(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_forward_velocity(stim_step_idxs),steps.leg(leg).meta.step_length(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor));
    hold off
   
    % step freq x AVG_ANGULAR_VELOCITY
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_angular_velocity(ctl_step_idxs),steps.leg(leg).meta.step_length(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_angular_velocity(stim_step_idxs),steps.leg(leg).meta.step_length(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor));
    hold off
end

fig = formatFig(fig, true, plotting);

% save
fig_name = ['\Step_Length_x_avgSpeed_avgForwardVelocity_avgAngularVelocity_forwardWalkingOnly'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
%% Plot: Step Length x avg_spded, best fit lines - ctl vs stim - forward walking steps

fig = fullfig;
plotting = [param.numLegs, 2]; %rows x speed types
idx = 1;
for leg = 1:param.numLegs

    % select steps that are forward walking and hav min speed bin of 2
    ctl_step_idxs = find(steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 0);
    stim_step_idxs = find(steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 1);
    
    % step freq x AVG_SPEED
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.step_length(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.step_length(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor)); 
    hold off
    
    % step freq x AVG_SPEED
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.step_length(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    h = lsline;
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.step_length(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor)); 
    h = lsline;
    
    set(h(2),'color',Color(param.baseColor));
    set(h(2),'linewidth',2);
    set(h(1),'color',Color(param.laserColor));
    set(h(1),'linewidth',2);
    
    hold off
    
    title(param.legs{leg});
    xlabel('Speed (mm/s)');
    ylabel('Step Length (mm)');
end

fig = formatFig(fig, true, plotting);

% save
fig_name = ['\Step_Length_x_avgSpeed_forwardWalkingOnly_bestfitlines'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
%% Plot: Swing Duration x avg_spded, avg_forward_velocity, and avg_angular_velocity - ctl vs stim - forward walking steps

fig = fullfig;
plotting = [param.numLegs, 3]; %rows x speed types
idx = 1;
for leg = 1:param.numLegs

    % select steps that are forward walking and hav min speed bin of 2
    ctl_step_idxs = find(steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 0);
    stim_step_idxs = find(steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 1);
    
    % step freq x AVG_SPEED
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.swing_duration(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.swing_duration(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor)); 
    hold off
    
    % step freq x AVG_FORWARD_VELOCITY
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_forward_velocity(ctl_step_idxs),steps.leg(leg).meta.swing_duration(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_forward_velocity(stim_step_idxs),steps.leg(leg).meta.swing_duration(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor));
    hold off
   
    % step freq x AVG_ANGULAR_VELOCITY
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_angular_velocity(ctl_step_idxs),steps.leg(leg).meta.swing_duration(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_angular_velocity(stim_step_idxs),steps.leg(leg).meta.swing_duration(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor));
    hold off
end

fig = formatFig(fig, true, plotting);

% save
fig_name = ['\Swing_Duration_x_avgSpeed_avgForwardVelocity_avgAngularVelocity_forwardWalkingOnly'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
%% Plot: Swing Duration x avg_spded, best fit lines - ctl vs stim - forward walking steps

fig = fullfig;
plotting = [param.numLegs, 2]; %rows x speed types
idx = 1;
for leg = 1:param.numLegs

    % select steps that are forward walking and hav min speed bin of 2
    ctl_step_idxs = find(steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 0);
    stim_step_idxs = find(steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 1);
    
    % step freq x AVG_SPEED
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.swing_duration(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.swing_duration(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor)); 
    hold off
    
    % step freq x AVG_SPEED
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.swing_duration(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    h = lsline;
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.swing_duration(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor)); 
    h = lsline;
    
    set(h(2),'color',Color(param.baseColor));
    set(h(2),'linewidth',2);
    set(h(1),'color',Color(param.laserColor));
    set(h(1),'linewidth',2);
    
    hold off
    
    title(param.legs{leg});
    xlabel('Speed (mm/s)');
    ylabel('Swing Duration (s)');
    
    
    ylim([0 0.1]);
end

fig = formatFig(fig, true, plotting);

% save
fig_name = ['\Swing_Duration_x_avgSpeed_forwardWalkingOnly_bestfitlines'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
%% Plot: Stance Duration x avg_spded, avg_forward_velocity, and avg_angular_velocity - ctl vs stim - forward walking steps

fig = fullfig;
plotting = [param.numLegs, 3]; %rows x speed types
idx = 1;
for leg = 1:param.numLegs

    % select steps that are forward walking and hav min speed bin of 2
    ctl_step_idxs = find(steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 0);
    stim_step_idxs = find(steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 1);
    
    % step freq x AVG_SPEED
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.stance_duration(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.stance_duration(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor)); 
    hold off
    
    % step freq x AVG_FORWARD_VELOCITY
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_forward_velocity(ctl_step_idxs),steps.leg(leg).meta.stance_duration(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_forward_velocity(stim_step_idxs),steps.leg(leg).meta.stance_duration(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor));
    hold off
   
    % step freq x AVG_ANGULAR_VELOCITY
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_angular_velocity(ctl_step_idxs),steps.leg(leg).meta.stance_duration(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_angular_velocity(stim_step_idxs),steps.leg(leg).meta.stance_duration(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor));
    hold off
end

fig = formatFig(fig, true, plotting);

% save
fig_name = ['\Stance_Duration_x_avgSpeed_avgForwardVelocity_avgAngularVelocity_forwardWalkingOnly'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
%% Plot: Stance Duration x avg_spded, best fit lines - ctl vs stim - forward walking steps

fig = fullfig;
plotting = [param.numLegs, 2]; %rows x speed types
idx = 1;
for leg = 1:param.numLegs

    % select steps that are forward walking and hav min speed bin of 2
    ctl_step_idxs = find(steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 0);
    stim_step_idxs = find(steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 1);
    
    % step freq x AVG_SPEED
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.stance_duration(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.stance_duration(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor)); 
    hold off
    
    
    % step freq x AVG_SPEED
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.stance_duration(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    h = lsline;
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.stance_duration(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor)); 
    h = lsline;
    
    set(h(2),'color',Color(param.baseColor));
    set(h(2),'linewidth',2);
    set(h(1),'color',Color(param.laserColor));
    set(h(1),'linewidth',2);
    
    hold off
    
    title(param.legs{leg});
    xlabel('Speed (mm/s)');
    ylabel('Stance Duration (s)');
end

fig = formatFig(fig, true, plotting);

% save
fig_name = ['\Stance_Duration_x_avgSpeed_forwardWalkingOnly_bestfitlines'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
%% single flies one leg
%% Plot: Step Frequency x avg_speed, avg_forward_velocity, and avg_angular_velocity - ctl vs stim - forward walking steps

leg = 1;
flies = 1:height(flyList); %or select a subset of flies
numFlies = width(flies);

fig = fullfig;
plotting = [numFlies, 3]; %rows x speed types
idx = 1;
for fly = 1:numFlies
    
    % select steps that are forward walking and hav min speed bin of 2
    ctl_step_idxs = find(strcmpi(steps.leg(leg).meta.fly, flyList.flyid(flies(fly))) & steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 0);
    stim_step_idxs = find(strcmpi(steps.leg(leg).meta.fly, flyList.flyid(flies(fly))) & steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 1);
    
    % step freq x AVG_SPEED
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.step_frequency(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.step_frequency(stim_step_idxs), 'filled','MarkerEdgeColor', Color(param.laserColor),'MarkerFaceColor', Color(param.laserColor)); 
    title(strrep(flyList.flyid(flies(fly)), '_', ' '));
    if fly == 1; ylabel('Step frequency (Hz)'); xlabel('Avg speed (mm/s)'); end
    hold off
    
    % step freq x AVG_FORWARD_VELOCITY
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_forward_velocity(ctl_step_idxs),steps.leg(leg).meta.step_frequency(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_forward_velocity(stim_step_idxs),steps.leg(leg).meta.step_frequency(stim_step_idxs), 'filled','MarkerEdgeColor', Color(param.laserColor),'MarkerFaceColor', Color(param.laserColor)); 
    if fly == 1; xlabel('Avg forward velocity (mm/s)'); end
    hold off
   
    % step freq x AVG_ANGULAR_VELOCITY
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_angular_velocity(ctl_step_idxs),steps.leg(leg).meta.step_frequency(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_angular_velocity(stim_step_idxs),steps.leg(leg).meta.step_frequency(stim_step_idxs), 'filled','MarkerEdgeColor', Color(param.laserColor),'MarkerFaceColor', Color(param.laserColor)); 
    if fly == 1; xlabel('Avg angular velocity (°/s)'); end
    hold off    
end

fig = formatFig(fig, true, plotting);

% save
fig_name = ['\Step_Frequency_x_avgSpeed_avgForwardVelocity_avgAngularVelocity_forwardWalkingOnly_byfly'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
%% Plot: Step Frequency x avg_speed, best fit lines - ctl vs stim - forward walking steps

leg = 1;
flies = 1:height(flyList); %or select a subset of flies
numFlies = width(flies);

fig = fullfig;
plotting = [numFlies, 2]; %rows x speed types
idx = 1;
for fly = 1:numFlies
    
    % select steps that are forward walking and hav min speed bin of 2
    ctl_step_idxs = find(strcmpi(steps.leg(leg).meta.fly, flyList.flyid(flies(fly))) & steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 0);
    stim_step_idxs = find(strcmpi(steps.leg(leg).meta.fly, flyList.flyid(flies(fly))) & steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 1);
    
    % step freq x AVG_SPEED
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.step_frequency(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.step_frequency(stim_step_idxs), 'filled','MarkerEdgeColor', Color(param.laserColor),'MarkerFaceColor', Color(param.laserColor)); 
    title(strrep(flyList.flyid(flies(fly)), '_', ' '));
    if fly == 1; ylabel('Step frequency (Hz)'); xlabel('Avg speed (mm/s)'); end
    hold off
    
    % step freq x AVG_SPEED best fit lines
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.step_frequency(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    h = lsline;
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.step_frequency(stim_step_idxs), 'filled','MarkerEdgeColor', Color(param.laserColor),'MarkerFaceColor', Color(param.laserColor)); 
    h = lsline;
    if fly == 1; xlabel('Avg forward velocity (mm/s)'); end
    set(h(1),'color',Color(param.laserColor));
    set(h(1),'linewidth',2);
    set(h(2),'color',Color(param.baseColor));
    set(h(2),'linewidth',2);
    hold off

end

fig = formatFig(fig, true, plotting);

% save
fig_name = ['\Step_Frequency_x_avgSpeed_avgForwardVelocity_avgAngularVelocity_forwardWalkingOnly_byfly_bestFitLines'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
%% Plot: Step Frequency x avg_speed, best fit lines - ctl vs stim - forward walking steps

leg = 1;
flies = 1:height(flyList); %or select a subset of flies
numFlies = width(flies);

fig = fullfig;
plotting = [numFlies, 2]; %rows x speed types
idx = 1;
for fly = 1:numFlies
    
    % select steps that are forward walking and hav min speed bin of 2
    ctl_step_idxs = find(strcmpi(steps.leg(leg).meta.fly, flyList.flyid(flies(fly))) & steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 0);
    stim_step_idxs = find(strcmpi(steps.leg(leg).meta.fly, flyList.flyid(flies(fly))) & steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 1);
    
    % step length x AVG_SPEED
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.step_length(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.step_length(stim_step_idxs), 'filled','MarkerEdgeColor', Color(param.laserColor),'MarkerFaceColor', Color(param.laserColor)); 
    title(strrep(flyList.flyid(flies(fly)), '_', ' '));
    if fly == 1; ylabel('Step frequency (Hz)'); xlabel('Avg speed (mm/s)'); end
    hold off
    
    % step freq x AVG_SPEED best fit lines
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.step_length(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    h = lsline;
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.step_length(stim_step_idxs), 'filled','MarkerEdgeColor', Color(param.laserColor),'MarkerFaceColor', Color(param.laserColor)); 
    h = lsline;
    if fly == 1; xlabel('Avg forward velocity (mm/s)'); end
    set(h(1),'color',Color(param.laserColor));
    set(h(1),'linewidth',2);
    set(h(2),'color',Color(param.baseColor));
    set(h(2),'linewidth',2);
    hold off

end

fig = formatFig(fig, true, plotting);

% save
fig_name = ['\Step_Length_x_avgSpeed_avgForwardVelocity_avgAngularVelocity_forwardWalkingOnly_byfly_bestFitLines'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot: Step Length x avg_spded, avg_forward_velocity, and avg_angular_velocity - ctl vs stim - forward walking steps

leg = 1;
flies = 1:5; %1:height(flyList); %or select a subset of flies
numFlies = width(flies);

fig = fullfig;
plotting = [numFlies, 3]; %rows x speed types
idx = 1;
for fly = 1:numFlies
    
    % select steps that are forward walking and hav min speed bin of 2
    ctl_step_idxs = find(strcmpi(steps.leg(leg).meta.fly, flyList.flyid(flies(fly))) & steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 0);
    stim_step_idxs = find(strcmpi(steps.leg(leg).meta.fly, flyList.flyid(flies(fly))) & steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 1);
    
    % step freq x AVG_SPEED
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.step_length(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.step_length(stim_step_idxs), 'filled','MarkerEdgeColor', Color(param.laserColor),'MarkerFaceColor', Color(param.laserColor)); 
    title(strrep(flyList.flyid(flies(fly)), '_', ' '));
    if fly == 1; ylabel('Step length (?)'); xlabel('Avg speed (mm/s)'); end
    hold off
    
    % step freq x AVG_FORWARD_VELOCITY
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_forward_velocity(ctl_step_idxs),steps.leg(leg).meta.step_length(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_forward_velocity(stim_step_idxs),steps.leg(leg).meta.step_length(stim_step_idxs), 'filled','MarkerEdgeColor', Color(param.laserColor),'MarkerFaceColor', Color(param.laserColor)); 
    if fly == 1; xlabel('Avg forward velocity (mm/s)'); end
    hold off
   
    % step freq x AVG_ANGULAR_VELOCITY
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_angular_velocity(ctl_step_idxs),steps.leg(leg).meta.step_length(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_angular_velocity(stim_step_idxs),steps.leg(leg).meta.step_length(stim_step_idxs), 'filled','MarkerEdgeColor', Color(param.laserColor),'MarkerFaceColor', Color(param.laserColor)); 
    if fly == 1; xlabel('Avg angular velocity (°/s)'); end
    hold off    
end

fig = formatFig(fig, true, plotting);

% save
fig_name = ['\Step_Length_x_avgSpeed_avgForwardVelocity_avgAngularVelocity_forwardWalkingOnly_byfly'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
%% Plot: Swing Duration x avg_spded, avg_forward_velocity, and avg_angular_velocity - ctl vs stim - forward walking steps

leg = 1;
flies = 1:5; %1:height(flyList); %or select a subset of flies
numFlies = width(flies);

fig = fullfig;
plotting = [numFlies, 3]; %rows x speed types
idx = 1;
for fly = 1:numFlies
    
    % select steps that are forward walking and hav min speed bin of 2
    ctl_step_idxs = find(strcmpi(steps.leg(leg).meta.fly, flyList.flyid(flies(fly))) & steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 0);
    stim_step_idxs = find(strcmpi(steps.leg(leg).meta.fly, flyList.flyid(flies(fly))) & steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 1);
    
    % step freq x AVG_SPEED
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.swing_duration(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.swing_duration(stim_step_idxs), 'filled','MarkerEdgeColor', Color(param.laserColor),'MarkerFaceColor', Color(param.laserColor)); 
    title(strrep(flyList.flyid(flies(fly)), '_', ' '));
    if fly == 1; ylabel('Swing duration (s)'); xlabel('Avg speed (mm/s)'); end
    hold off
    
    % step freq x AVG_FORWARD_VELOCITY
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_forward_velocity(ctl_step_idxs),steps.leg(leg).meta.swing_duration(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_forward_velocity(stim_step_idxs),steps.leg(leg).meta.swing_duration(stim_step_idxs), 'filled','MarkerEdgeColor', Color(param.laserColor),'MarkerFaceColor', Color(param.laserColor)); 
    if fly == 1; xlabel('Avg forward velocity (mm/s)'); end
    hold off
   
    % step freq x AVG_ANGULAR_VELOCITY
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_angular_velocity(ctl_step_idxs),steps.leg(leg).meta.swing_duration(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_angular_velocity(stim_step_idxs),steps.leg(leg).meta.swing_duration(stim_step_idxs), 'filled','MarkerEdgeColor', Color(param.laserColor),'MarkerFaceColor', Color(param.laserColor)); 
    if fly == 1; xlabel('Avg angular velocity (°/s)'); end
    hold off    
end

fig = formatFig(fig, true, plotting);

% save
fig_name = ['\Swing_Duration_x_avgSpeed_avgForwardVelocity_avgAngularVelocity_forwardWalkingOnly_byfly'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
%% Plot: Stance Duration x avg_spded, avg_forward_velocity, and avg_angular_velocity - ctl vs stim - forward walking steps

leg = 1;
flies = 1:5; %1:height(flyList); %or select a subset of flies
numFlies = width(flies);

fig = fullfig;
plotting = [numFlies, 3]; %rows x speed types
idx = 1;
for fly = 1:numFlies
    
    % select steps that are forward walking and hav min speed bin of 2
    ctl_step_idxs = find(strcmpi(steps.leg(leg).meta.fly, flyList.flyid(flies(fly))) & steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 0);
    stim_step_idxs = find(strcmpi(steps.leg(leg).meta.fly, flyList.flyid(flies(fly))) & steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 1);
    
    % step freq x AVG_SPEED
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.stance_duration(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.stance_duration(stim_step_idxs), 'filled','MarkerEdgeColor', Color(param.laserColor),'MarkerFaceColor', Color(param.laserColor)); 
    title(strrep(flyList.flyid(flies(fly)), '_', ' '));
    if fly == 1; ylabel('Stance duration (s)'); xlabel('Avg speed (mm/s)'); end
    hold off
    
    % step freq x AVG_FORWARD_VELOCITY
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_forward_velocity(ctl_step_idxs),steps.leg(leg).meta.stance_duration(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_forward_velocity(stim_step_idxs),steps.leg(leg).meta.stance_duration(stim_step_idxs), 'filled','MarkerEdgeColor', Color(param.laserColor),'MarkerFaceColor', Color(param.laserColor)); 
    if fly == 1; xlabel('Avg forward velocity (mm/s)'); end
    hold off
   
    % step freq x AVG_ANGULAR_VELOCITY
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_angular_velocity(ctl_step_idxs),steps.leg(leg).meta.stance_duration(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  hold on
    scatter(steps.leg(leg).meta.avg_angular_velocity(stim_step_idxs),steps.leg(leg).meta.stance_duration(stim_step_idxs), 'filled','MarkerEdgeColor', Color(param.laserColor),'MarkerFaceColor', Color(param.laserColor)); 
    if fly == 1; xlabel('Avg angular velocity (°/s)'); end
    hold off    
end

fig = formatFig(fig, true, plotting);

% save
fig_name = ['\Stance_Duration_x_avgSpeed_avgForwardVelocity_avgAngularVelocity_forwardWalkingOnly_byfly'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% %%%%%%%%%%%%%%% GAIT - COVARIANCE %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Covariance matrix for walking data (ANLGES) - Ctl vs Stim - FTi angles only 

setDiagonalToZero = 0; %1= sets diagonal of C matrix to zero for better colormap scaling. 

% get stim regions (1 = laser on)
stimRegions = DLC_getStimRegions(data, param);

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);
walkingDataStim = stimRegions(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1_BC'));
endJnt = find(contains(columns, 'R3E_z'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = {'L1_FTi', 'L2B_rot','L3_FTi', 'R1_FTi','R2B_rot','R3_FTi'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
% subData = 1:24; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%invert T3 and T2 signals so peaks correspond to stance start like for T1
invertJnts = find(contains(jointLabels, '3') | contains(jointLabels, 'L2'));

jointWalkingData = table2array(jointWalkingData);
jointWalkingData(:,invertJnts) = jointWalkingData(:,invertJnts)*-1;

%separate stim vs control regions
jointWalkingDataControl = jointWalkingData((walkingDataStim == 0), :);
jointWalkingDataStim = jointWalkingData((walkingDataStim == 1), :);

%noramlize data
%1) subtract mean 
jointWalkingDataControl = jointWalkingDataControl - nanmean(jointWalkingDataControl);
jointWalkingDataStim = jointWalkingDataStim - nanmean(jointWalkingDataStim);
%2) divide by std
jointWalkingDataControl = jointWalkingDataControl ./ nanstd(jointWalkingDataControl);
jointWalkingDataStim = jointWalkingDataStim ./ nanstd(jointWalkingDataStim);


%calculate covariance 
Cctl = cov(jointWalkingDataControl);
Cexp = cov(jointWalkingDataStim);


%plot covariance matrix - control
fig = fullfig;
h = heatmap(Cctl); 
h.Title = 'Covariance of joint angles during walking (control)';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Walking_FTi_angles_&_T2B_rot_Ctl'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


%plot covariance matrix - stim
fig = fullfig;
h = heatmap(Cexp); 
h.Title = 'Covariance of joint angles during walking (stim)';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Walking_FTi_angles_&_T2B_rot_Stim'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

% 
% %plot covariance matrix - control vs stim 
% fig = fullfig;
% h = heatmap(C); 
% h.Title = 'Covariance of joint angles during walking (control - stim)';
% h.XDisplayLabels = jointLabels;
% h.YDisplayLabels = jointLabels;
% h.Colormap = redblue;
% h.FontColor = 'w';
% fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
% %save 
% fig_name = ['\Covariance_Matix_JointAngles_Walking_FTi_angles_Ctl_vs_Stim'];
% if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
% save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% 
clearvars('-except',initial_vars{:}); initial_vars = who;



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% One leg %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot all joints, all lasers, one leg 
leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};

% fig = figure;
fig = fullfig;
pltIdx = 0;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
       elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
       elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
       elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
       end
       %plot the data!
       for vid = 1:width(temp)
          if height(temp{vid}) == 600
            plot(param.x, temp{vid}); 
          end
       end
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
       
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.1 sec');
       elseif pltIdx == 4
           title('0.33 sec');
       elseif pltIdx == 5    
           title('1 sec');
       elseif pltIdx == 6
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 11
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 16
            ylabel(['TiTa (' char(176) ')']);
       end
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, param.darkFig, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Raw Joint Angles');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_overview'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all joints, all lasers, one leg -- mean & 95% CI 
fig = fullfig;
pltIdx = 0;
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
       elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
       elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
       elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
       end
       %plot the data!
       all_data = NaN( width(temp), param.vid_len_f);
       for vid = 1:width(temp)
          all_data(vid, :) = temp{vid};
%           plot(param.x, temp{vid}); 
       end
       
%        N = size(all_data, 1);  % Number of ‘Experiments’ In Data Set (numVids)
       N = height(flyList);    % Number of ‘Experiments’ In Data Set (numFlies)
       yMean = nanmean(all_data); % Mean Of All Experiments At Each Value Of ‘x’
       ySEM = std(all_data)/sqrt(N); % Compute ‘Standard Error Of The Mean’ Of All Experiments At Each Value Of ‘x’
       
       CI95 = tinv([0.025 0.975], N-1);  % Calculate 95% Probability Intervals Of t-Distribution
       yCI95 = bsxfun(@times, ySEM, CI95(:));  % Calculate 95% Confidence Intervals Of All Experiments At Each Value Of ‘x’
       
       plot(param.x, yMean, 'color', Color(param.expColor), 'linewidth', 1.5);
%        plot(param.x, yCI95+yMean);
       fill_data = error_fill(param.x, yMean, yCI95);
       h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
       set(h, 'facealpha', 0.2);
       
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % plot laser region 
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.1 sec');
       elseif pltIdx == 4
           title('0.33 sec');
       elseif pltIdx == 5    
           title('1 sec');
       elseif pltIdx == 6
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 11
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 16
            ylabel(['TiTa (' char(176) ')']);
       end
   end
end

fig = formatFig(fig, true, [param.numJoints, param.numLasers]);


han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Raw Joint Angle Mean & 95% CI');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

hold off;

fig_name = ['\' param.legs{leg} '_overview_mean&95CI'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all joints, all lasers, one leg -- mean & sem 
fig = fullfig;
pltIdx = 0;
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
       elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
       elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
       elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
       end
       %plot the data!
       all_data = NaN( width(temp), param.vid_len_f);
       for vid = 1:width(temp)
          all_data(vid, :) = temp{vid};
       end
       %calculate mean and standard error of the mean 
       yMean = nanmean(all_data, 1);
       ySEM = sem(all_data, 1, nan, height(flyList));
       
       %plot
       plot(param.x, yMean, 'color', Color(param.expColor), 'linewidth', 1.5);
       fill_data = error_fill(param.x, yMean, ySEM);
       h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
       set(h, 'facealpha', 0.2);
       
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % plot laser region 
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.1 sec');
       elseif pltIdx == 4
           title('0.33 sec');
       elseif pltIdx == 5    
           title('1 sec');
       elseif pltIdx == 6
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 11
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 16
            ylabel(['TiTa (' char(176) ')']);
       end
   end
end

fig = formatFig(fig, true, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, 'L1 Raw Joint Angle Mean & SEM');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

hold off;

fig_name = ['\' param.legs{leg} '_overview_mean&SEM'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all joints, all lasers, one leg -- subtract baseline angle 

fig = fullfig;
pltIdx = 0;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
       elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
       elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
       elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
       end
       %plot the data!
       for vid = 1:width(temp)
          d = temp{vid};
          if height(d) == 600
              a = d(param.laser_on);
              d = d-a;
              plot(param.x, d); 
          end
       end
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
       
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.1 sec');
       elseif pltIdx == 4
           title('0.33 sec');
       elseif pltIdx == 5    
           title('1 sec');
       elseif pltIdx == 6
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 11
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 16
            ylabel(['TiTa (' char(176) ')']);
       end
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, 'L1 Aligned Joint Angles');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_overview_aligned'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all joints, all lasers, one leg -- subtract baseline angle -- mean & sem 
fig = fullfig;
pltIdx = 0;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
       elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
       elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
       elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
       end
       %plot the data!
       all_data = NaN(width(temp), param.vid_len_f);
       for vid = 1:width(temp) %CHANGE when plotting days 
          d = temp{vid};
          if height(d) == 600
              a = d(param.laser_on);
              d = d-a; 
              all_data(vid, :) = d;
          end
       end
       %calculate mean and standard error of the mean 
       yMean = nanmean(all_data, 1);
       ySEM = sem(all_data, 1, nan, height(flyList));
       
       %plot
       plot(param.x, yMean, 'color', Color(param.jointColors{joint}), 'linewidth', 1.5);
       fill_data = error_fill(param.x, yMean, ySEM);
       h = fill(fill_data.X, fill_data.Y, get_color(param.jointColors{joint}), 'EdgeColor','none');
       set(h, 'facealpha', param.jointFillWeights{joint});
       
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
        
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.1 sec');
       elseif pltIdx == 4
           title('0.33 sec');
       elseif pltIdx == 5    
           title('1 sec');
       elseif pltIdx == 6
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 11
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 16
           ylabel(['TiTa (' char(176) ')']);
       end
       
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Aligned Joint Angle Mean & SEM');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_overview_mean&SEM_aligned'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot FTi joint, # lasers, L1 leg -- subtract baseline angle -- mean & sem 
fig = figure;
lasers = [1,2,3,4,5]; 
pltIdx = 1;
AX = [];
clear numVids
joint = 3; jnt = [leg_str '_FTi'];
for ll = 1:width(lasers)
   laser = lasers(ll);
   light_on = 0;
   light_off =(param.fps*param.lasers{laser})/param.fps;
   AX(pltIdx) = subplot(1,1, pltIdx); hold on;
   %extract the joint data 
   temp = joint_data.leg(leg).laser(laser).FTi.joint;
   num_vids = 0;
   %plot the data!
   all_data = NaN(width(temp), param.vid_len_f);
   for vid = 1:width(temp) %CHANGE when plotting days 
      d = temp{vid};
      if height(d) == 600
          num_vids = num_vids +1; 
          a = d(param.laser_on);
          d = d-a; 
          all_data(vid, :) = d;
      end
   end
   numVids(ll) = num_vids;
   %calculate mean and standard error of the mean 
   yMean = nanmean(all_data, 1);
   ySEM = sem(all_data, 1, nan, height(flyList));
    
   if laser == 1
       c = param.baseColor;
   else
       c = param.jointColors{joint};
   end
   %plot
   plot(param.x, yMean, 'color', Color(c), 'linewidth', 1.5);
   fill_data = error_fill(param.x, yMean, ySEM);
   h = fill(fill_data.X, fill_data.Y, get_color(c), 'EdgeColor','none');
   set(h, 'facealpha', param.jointFillWeights{joint});


   if param.xlimit; xlim(param.xlim); end
   if param.ylimit; ylim([-40,80]); yticks([-40, 0, 40, 80]); end

   % laser region 
   if param.sameAxes
       %save light length for plotting after syching lasers
       light_ons(pltIdx) = light_on;
       light_offs(pltIdx) = light_off;
   else
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
   end

   %label
   if pltIdx == 1
       ylabel(['Femur-tibia angle (' char(176) ')']);
       xlabel('Time (s)');
%        title('0 sec');
   elseif pltIdx == 2
       title('0.03 sec');
   elseif pltIdx == 3
       title('0.1 sec');
   elseif pltIdx == 4
       title('0.33 sec');
   elseif pltIdx == 5    
       title('1 sec');
   elseif pltIdx == 6
       ylabel(['CF (' char(176) ')']);
   elseif pltIdx == 11
       ylabel(['FTi (' char(176) ')']);
   elseif pltIdx == 16
       ylabel(['TiTa (' char(176) ')']);
   end

   hold off;
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(1,1, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(1,1, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [1,1]);
% 
% han=axes(fig,'visible','off'); 
% han.Title.Visible='on';
% title(han, ' L1 Aligned Joint Angle Mean & SEM');
% set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))
set(gca, 'fontsize', 20);

fig_name = ['\' param.legs{leg} '_overview_mean&SEM_aligned_' num2str(width(lasers)) 'Lasers'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name]);

%% Plot all joints, all lasers, one leg -- ANGLE CHANGE 

fig = fullfig;
pltIdx = 0;
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
       elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
       elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
       elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
       end
       %plot the data!
       for vid = 1:width(temp)
          plot(param.x(1:end-1), diff(temp{vid})); 
       end
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % plot laser region 
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.1 sec');
       elseif pltIdx == 4
           title('0.33 sec');
       elseif pltIdx == 5    
           title('1 sec');
       elseif pltIdx == 6
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 11
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 16
            ylabel(['TiTa (' char(176) ')']);
       end
   end
end

fig = formatFig(fig, true, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Joint Angle Change');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))


hold off;

fig_name = ['\' param.legs{leg} '_overview_angleChange'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% One joint %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
joint = param.joints{listdlg('ListString', param.joints, 'PromptString','Select laser:', 'SelectionMode','single', 'ListSize', [100 100])};
%% Plot all legs, all lasers, one joint 
% joint = 'FTi'; %'BC' 'CF' 'FTi' TiTa' 
joint = param.joints{listdlg('ListString', param.joints, 'PromptString','Select laser:', 'SelectionMode','single', 'ListSize', [100 100])};

fig = fullfig;
pltIdx = 0;
AX = [];
for laser = 1:param.numLasers
    light_on = 0;
    light_off =(param.fps*param.lasers{laser})/param.fps;
   for leg = 1:param.numLegs
       pltIdx = pltIdx+1;
       AX(pltIdx) = subplot(param.numLasers, param.numLegs, pltIdx); hold on;
       %extract the joint data 
       if strcmp(joint, 'BC')
           temp = joint_data.leg(leg).laser(laser).BC.joint;      
       elseif strcmp(joint, 'CF')
           temp = joint_data.leg(leg).laser(laser).CF.joint;      
       elseif strcmp(joint, 'FTi')
           temp = joint_data.leg(leg).laser(laser).FTi.joint;      
       elseif strcmp(joint, 'TiTa')
           temp = joint_data.leg(leg).laser(laser).TiTa.joint;      
       end
       %plot the data!
       for vid = 1:width(temp)
          plot(param.x, temp{vid}); 
       end
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
          
       %label
       if pltIdx == 1
           ylabel('0 sec');
           xlabel('Time (s)');
           title('L1');
       elseif pltIdx == 2
           title('L2');
       elseif pltIdx == 3
           title('L3');
       elseif pltIdx == 4
           title('R1');
       elseif pltIdx == 5    
           title('R2');
       elseif pltIdx == 6
           title('R3');
       elseif pltIdx == 7
           ylabel('0.03 sec');
       elseif pltIdx == 13
           ylabel('0.1 sec');
       elseif pltIdx == 19
            ylabel('0.33 sec');
       elseif pltIdx == 25
            ylabel('1 sec');            
       end
       
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numLasers, param.numLegs, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.numLasers, param.numLegs]);
 
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [joint ' Raw Joint Angles']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' joint '_overview'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all legs, all lasers, one joint -- mean & 95% CI 

fig = fullfig;
pltIdx = 0;
for laser = 1:param.numLasers
    light_on = 0;
    light_off =(param.fps*param.lasers{laser})/param.fps;
   for leg = 1:param.numLegs
       pltIdx = pltIdx+1;
       subplot(param.numLasers, param.numLegs, pltIdx); hold on;
       %extract the joint data 
       if strcmp(joint, 'BC')
           temp = joint_data.leg(leg).laser(laser).BC.joint;      
       elseif strcmp(joint, 'CF')
           temp = joint_data.leg(leg).laser(laser).CF.joint;      
       elseif strcmp(joint, 'FTi')
           temp = joint_data.leg(leg).laser(laser).FTi.joint;      
       elseif strcmp(joint, 'TiTa')
           temp = joint_data.leg(leg).laser(laser).TiTa.joint;      
       end       %plot the data!
       all_data = NaN( width(temp), param.vid_len_f);
       for vid = 1:width(temp)
          all_data(vid, :) = temp{vid};
%           plot(param.x, temp{vid}); 
       end
       
%        N = size(all_data, 1);  % Number of ‘Experiments’ In Data Set (numVids)
       N = height(flyList);    % Number of ‘Experiments’ In Data Set (numFlies)
       yMean = nanmean(all_data); % Mean Of All Experiments At Each Value Of ‘x’
       ySEM = std(all_data)/sqrt(N); % Compute ‘Standard Error Of The Mean’ Of All Experiments At Each Value Of ‘x’
       
       CI95 = tinv([0.025 0.975], N-1);  % Calculate 95% Probability Intervals Of t-Distribution
       yCI95 = bsxfun(@times, ySEM, CI95(:));  % Calculate 95% Confidence Intervals Of All Experiments At Each Value Of ‘x’
       
       plot(param.x, yMean, 'color', Color(param.expColor), 'linewidth', 1.5);
%        plot(param.x, yCI95+yMean);
       fill_data = error_fill(param.x, yMean, yCI95);
       h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
       set(h, 'facealpha', 0.2);
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % plot laser region 
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
%        ylim([0,180]);
          
       %label
       if pltIdx == 1
           ylabel('0 sec');
           xlabel('Time (s)');
           title('L1');
       elseif pltIdx == 2
           title('L2');
       elseif pltIdx == 3
           title('L3');
       elseif pltIdx == 4
           title('R1');
       elseif pltIdx == 5    
           title('R2');
       elseif pltIdx == 6
           title('R3');
       elseif pltIdx == 7
           ylabel('0.03 sec');
       elseif pltIdx == 13
           ylabel('0.1 sec');
       elseif pltIdx == 19
            ylabel('0.33 sec');
       elseif pltIdx == 25
            ylabel('1 sec');            
       end
   end
end

 fig = formatFig(fig, true, [param.numLasers, param.numLegs]);
 
 
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [joint ' Raw Joint Angle Mean & 95% CI']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))


hold off;

fig_name = ['\' joint '_overview_mean&95CI'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all legs, all lasers, one joint -- mean & sem  

fig = fullfig;
pltIdx = 0;
for laser = 1:param.numLasers
    light_on = 0;
    light_off =(param.fps*param.lasers{laser})/param.fps;
   for leg = 1:param.numLegs
       pltIdx = pltIdx+1;
       subplot(param.numLasers, param.numLegs, pltIdx); hold on;
       %extract the joint data 
       if strcmp(joint, 'BC')
           temp = joint_data.leg(leg).laser(laser).BC.joint;      
       elseif strcmp(joint, 'CF')
           temp = joint_data.leg(leg).laser(laser).CF.joint;      
       elseif strcmp(joint, 'FTi')
           temp = joint_data.leg(leg).laser(laser).FTi.joint;      
       elseif strcmp(joint, 'TiTa')
           temp = joint_data.leg(leg).laser(laser).TiTa.joint;      
       end       %plot the data!
       all_data = NaN( width(temp), param.vid_len_f);
       for vid = 1:width(temp)
          all_data(vid, :) = temp{vid};
       end
       %calculate mean and standard error of the mean 
       yMean = nanmean(all_data, 1);
       ySEM = sem(all_data, 1, nan, height(flyList));
       
       %plot
       plot(param.x, yMean, 'color', Color(param.expColor), 'linewidth', 1.5);
       fill_data = error_fill(param.x, yMean, ySEM);
       h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
       set(h, 'facealpha', 0.2);
       
      
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % plot laser region 
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
%        ylim([0,180]);
          
       %label
       if pltIdx == 1
           ylabel('0 sec');
           xlabel('Time (s)');
           title('L1');
       elseif pltIdx == 2
           title('L2');
       elseif pltIdx == 3
           title('L3');
       elseif pltIdx == 4
           title('R1');
       elseif pltIdx == 5    
           title('R2');
       elseif pltIdx == 6
           title('R3');
       elseif pltIdx == 7
           ylabel('0.03 sec');
       elseif pltIdx == 13
           ylabel('0.1 sec');
       elseif pltIdx == 19
            ylabel('0.33 sec');
       elseif pltIdx == 25
            ylabel('1 sec');            
       end
   end
end

 fig = formatFig(fig, true, [param.numLasers, param.numLegs]);
 
 
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [joint ' Raw Joint Angle Mean & SEM']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))



hold off;

fig_name = ['\' joint '_overview_mean&SEM'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all legs, all lasers, one joint -- subtract baseline angle 
fig = fullfig;
pltIdx = 0;
AX = [];
for laser = 1:param.numLasers
    light_on = 0;
    light_off =(param.fps*param.lasers{laser})/param.fps;
   for leg = 1:param.numLegs
       pltIdx = pltIdx+1;
       AX(pltIdx) = subplot(param.numLasers, param.numLegs, pltIdx); hold on;
       %extract the joint data 
       if strcmp(joint, 'BC')
           temp = joint_data.leg(leg).laser(laser).BC.joint;      
       elseif strcmp(joint, 'CF')
           temp = joint_data.leg(leg).laser(laser).CF.joint;      
       elseif strcmp(joint, 'FTi')
           temp = joint_data.leg(leg).laser(laser).FTi.joint;      
       elseif strcmp(joint, 'TiTa')
           temp = joint_data.leg(leg).laser(laser).TiTa.joint;      
       end       %plot the data!
       for vid = 1:width(temp)
          d = temp{vid};
          a = d(param.laser_on);
          d = d-a;
          plot(param.x, d); 
       end
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
          
       %label
       if pltIdx == 1
           ylabel('0 sec');
           xlabel('Time (s)');
           title('L1');
       elseif pltIdx == 2
           title('L2');
       elseif pltIdx == 3
           title('L3');
       elseif pltIdx == 4
           title('R1');
       elseif pltIdx == 5    
           title('R2');
       elseif pltIdx == 6
           title('R3');
       elseif pltIdx == 7
           ylabel('0.03 sec');
       elseif pltIdx == 13
           ylabel('0.1 sec');
       elseif pltIdx == 19
            ylabel('0.33 sec');
       elseif pltIdx == 25
            ylabel('1 sec');            
       end
       
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numLasers, param.numLegs, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.numLasers, param.numLegs]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [joint ' Aligned Joint Angles']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' joint '_overview_aligned'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all legs, all lasers, one joint -- subtract baseline angle -- mean & sem 

fig = fullfig;
pltIdx = 0;
AX = [];
for laser = 1:param.numLasers
    light_on = 0;
    light_off =(param.fps*param.lasers{laser})/param.fps;
   for leg = 1:param.numLegs
       pltIdx = pltIdx+1;
       AX(pltIdx) = subplot(param.numLasers, param.numLegs, pltIdx); hold on;
       %extract the joint data 
       if strcmp(joint, 'BC')
           temp = joint_data.leg(leg).laser(laser).BC.joint;      
       elseif strcmp(joint, 'CF')
           temp = joint_data.leg(leg).laser(laser).CF.joint;      
       elseif strcmp(joint, 'FTi')
           temp = joint_data.leg(leg).laser(laser).FTi.joint;      
       elseif strcmp(joint, 'TiTa')
           temp = joint_data.leg(leg).laser(laser).TiTa.joint;      
       end       %plot the data!
       all_data = NaN( width(temp), param.vid_len_f);
       for vid = 1:width(temp)
          d = temp{vid};
          if height(d) == 600
              a = d(param.laser_on);
              d = d-a;
              all_data(vid, :) = d;
          end
       end
       %calculate mean and standard error of the mean 
       yMean = nanmean(all_data, 1);
       ySEM = sem(all_data, 1, nan, height(flyList));
       
       %plot
       plot(param.x, yMean, 'color', Color(param.jointColors{find(contains(param.joints, joint))}), 'linewidth', 1.5);
       fill_data = error_fill(param.x, yMean, ySEM);
       h = fill(fill_data.X, fill_data.Y, get_color(param.jointColors{find(contains(param.joints, joint))}), 'EdgeColor','none');
       set(h, 'facealpha', param.jointFillWeights{find(contains(param.joints, joint))});
       
      
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
       
       %label
       if pltIdx == 1
           ylabel('0 sec');
           xlabel('Time (s)');
           title('L1');
       elseif pltIdx == 2
           title('L2');
       elseif pltIdx == 3
           title('L3');
       elseif pltIdx == 4
           title('R1');
       elseif pltIdx == 5    
           title('R2');
       elseif pltIdx == 6
           title('R3');
       elseif pltIdx == 7
           ylabel('0.03 sec');
       elseif pltIdx == 13
           ylabel('0.1 sec');
       elseif pltIdx == 19
            ylabel('0.33 sec');
       elseif pltIdx == 25
            ylabel('1 sec');            
       end
       
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numLasers, param.numLegs, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.numLasers, param.numLegs]);
 
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [joint ' Aligned Joint Angle Mean & SEM']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' joint '_overview_mean&SEM_aligned'];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all legs, all lasers, one joint -- ANGLE CHANGE 
joint = 'FTi';
fig = fullfig;
pltIdx = 0;
for laser = 1:param.numLasers
    light_on = 0;
    light_off =(param.fps*param.lasers{laser})/param.fps;
   for leg = 1:param.numLegs
       pltIdx = pltIdx+1;
       subplot(param.numLasers, param.numLegs, pltIdx); hold on;
       %extract the joint data 
       if strcmp(joint, 'BC')
           temp = joint_data.leg(leg).laser(laser).BC.joint;      
       elseif strcmp(joint, 'CF')
           temp = joint_data.leg(leg).laser(laser).CF.joint;      
       elseif strcmp(joint, 'FTi')
           temp = joint_data.leg(leg).laser(laser).FTi.joint;      
       elseif strcmp(joint, 'TiTa')
           temp = joint_data.leg(leg).laser(laser).TiTa.joint;      
       end       %plot the data!
       for vid = 1:width(temp)
          plot(param.x(1:end-1), diff(temp{vid})); 
       end
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % plot laser region 
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
%        ylim([0,180]);
          
       %label
       if pltIdx == 1
           ylabel('0 sec');
           xlabel('Time (s)');
           title('L1');
       elseif pltIdx == 2
           title('L2');
       elseif pltIdx == 3
           title('L3');
       elseif pltIdx == 4
           title('R1');
       elseif pltIdx == 5    
           title('R2');
       elseif pltIdx == 6
           title('R3');
       elseif pltIdx == 7
           ylabel('0.03 sec');
       elseif pltIdx == 13
           ylabel('0.1 sec');
       elseif pltIdx == 19
            ylabel('0.33 sec');
       elseif pltIdx == 25
            ylabel('1 sec');            
       end
   end
end

 fig = formatFig(fig, true, [param.numLasers, param.numLegs]);

 han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [joint ' Joint Angle Change']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

 
hold off;

fig_name = ['\' joint '_overview_angleChange'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

joint = param.joints{listdlg('ListString', param.joints, 'PromptString','Select laser:', 'SelectionMode','single', 'ListSize', [100 100])};

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% All joints %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot all joints, all lasers, one leg -- subtract baseline angle -- mean & sem 
fig = fullfig;
pltIdx = 0;
AX = [];
for leg = 1:param.numLegs
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numLegs, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       for joint = 1:param.numJoints
           if joint == 1; temp = joint_data.leg(leg).laser(laser).BC.joint;
           elseif joint == 2; temp = joint_data.leg(leg).laser(laser).CF.joint;
           elseif joint == 3; temp = joint_data.leg(leg).laser(laser).FTi.joint;
           elseif joint == 4; temp = joint_data.leg(leg).laser(laser).TiTa.joint; 
           end
           %plot the data!
           all_data = NaN( width(temp), param.vid_len_f);
           for vid = 1:width(temp) %CHANGE when plotting days 
              d = temp{vid};
              if height(d) == 600
                  a = d(param.laser_on);
                  d = d-a; 
                  all_data(vid, :) = d;
              end
           end
           %calculate mean and standard error of the mean 
           yMean = nanmean(all_data, 1);
           ySEM = sem(all_data, 1, nan, height(flyList));

           %plot
           plot(param.x, yMean, 'color', Color(param.jointColors{joint}), 'linewidth', 1.5);
           fill_data = error_fill(param.x, yMean, ySEM);
           h = fill(fill_data.X, fill_data.Y, get_color(param.jointColors{joint}), 'EdgeColor','none');
           set(h, 'facealpha', param.jointFillWeights{joint});
       end
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
       
       %label
       if pltIdx == 1
           ylabel('L1');
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.1 sec');
       elseif pltIdx == 4
           title('0.33 sec');
       elseif pltIdx == 5    
           title('1 sec');
       elseif pltIdx == 6
           ylabel('L2');
       elseif pltIdx == 11
           ylabel('L3');
       elseif pltIdx == 16
           ylabel('R1');
       elseif pltIdx == 21
           ylabel('R2');
       elseif pltIdx == 26
           ylabel('R3');
       end
       hold off;

   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numLegs, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.numLegs, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, 'All Joint Angle Means & SEMs Aligned');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\allLegs_allJoints_overview_mean&SEM_aligned'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
if param.sameAxes; fig_name = [fig_name, '_axesAligned']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% Individual Flies %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot all joints, all lasers, one leg -- subtract baseline angle -- mean & sem 
fig = fullfig;
pltIdx = 0;
leg = 1;
AX = [];
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       for fly = 1:height(param.flyList)
           %extract the joint data 
           if joint == 1; temp = joint_data_byFly.fly(fly).leg(leg).laser(laser).BC.joint;
           elseif joint == 2; temp = joint_data_byFly.fly(fly).leg(leg).laser(laser).CF.joint;
           elseif joint == 3; temp = joint_data_byFly.fly(fly).leg(leg).laser(laser).FTi.joint;
           elseif joint == 4; temp = joint_data_byFly.fly(fly).leg(leg).laser(laser).TiTa.joint; 
           end
           %plot the data!
           all_data = NaN( width(temp), param.vid_len_f);
           for vid = 1:width(temp) %CHANGE when plotting days 
              d = temp{vid};
              if height(d) == 600
                  a = d(param.laser_on);
                  d = d-a; 
                  all_data(vid, :) = d;
              end
           end
           %calculate mean and standard error of the mean 
           yMean = nanmean(all_data, 1);
           ySEM = sem(all_data, 1, nan, height(flyList));

           %plot
           plot(param.x, yMean, 'color', param.flyColors(fly,:), 'linewidth', 1.5);
%            fill_data = error_fill(param.x, yMean, ySEM);
%            h = fill(fill_data.X, fill_data.Y, get_color(param.flyColors{fly}), 'EdgeColor','none');
%            set(h, 'facealpha', 0.2);
       end

       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end

       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end

       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.1 sec');
       elseif pltIdx == 4
           title('0.33 sec');
       elseif pltIdx == 5    
           title('1 sec');
       elseif pltIdx == 6
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 11
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 16
           ylabel(['TiTa (' char(176) ')']);
       end
   end
   hold off;
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLasers]);


han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Aligned Joint Angle Mean & SEM of Individual Flies');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

% hold off;

fig_name = ['\' param.legs{leg} '_overview_mean&SEM_aligned_byFly'];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot all legs, all lasers, one joint -- subtract baseline angle -- mean & sem 
joint = param.joints{listdlg('ListString', param.joints, 'PromptString','Select laser:', 'SelectionMode','single', 'ListSize', [100 100])};

fig = fullfig;
pltIdx = 0;
AX = [];
for laser = 1:param.numLasers
    light_on = 0;
    light_off =(param.fps*param.lasers{laser})/param.fps;
   for leg = 1:param.numLegs
       pltIdx = pltIdx+1;
       AX(pltIdx) = subplot(param.numLasers, param.numLegs, pltIdx); hold on;
       for fly = 1:height(param.flyList)
           %extract the joint data 
           if strcmp(joint, 'BC')
               temp = joint_data_byFly.fly(fly).leg(leg).laser(laser).BC.joint;      
           elseif strcmp(joint, 'CF')
               temp = joint_data_byFly.fly(fly).leg(leg).laser(laser).CF.joint;      
           elseif strcmp(joint, 'FTi')
               temp = joint_data_byFly.fly(fly).leg(leg).laser(laser).FTi.joint;      
           elseif strcmp(joint, 'TiTa')
               temp = joint_data_byFly.fly(fly).leg(leg).laser(laser).TiTa.joint;      
           end       %plot the data!
           all_data = NaN( width(temp), param.vid_len_f);
           for vid = 1:width(temp)
              d = temp{vid};
              if height(d) == 600
                  a = d(param.laser_on);
                  d = d-a;
                  all_data(vid, :) = d;
              end
           end
           %calculate mean and standard error of the mean 
           yMean = nanmean(all_data, 1);
           ySEM = sem(all_data, 1, nan, height(flyList));

           %plot
           plot(param.x, yMean, 'color', param.flyColors(fly,:), 'linewidth', 1.5);
%            fill_data = error_fill(param.x, yMean, ySEM);
%            h = fill(fill_data.X, fill_data.Y, get_color(param.flyColors{fly}), 'EdgeColor','none');
%            set(h, 'facealpha', 0.2);
       
       end
      
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
      % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
          
       %label
       if pltIdx == 1
           ylabel('0 sec');
           xlabel('Time (s)');
           title('L1');
       elseif pltIdx == 2
           title('L2');
       elseif pltIdx == 3
           title('L3');
       elseif pltIdx == 4
           title('R1');
       elseif  pltIdx == 5    
           title('R2');
       elseif pltIdx == 6
           title('R3');  
       elseif pltIdx == 7
           ylabel('0.03 sec');
       elseif pltIdx == 13
           ylabel('0.1 sec');
       elseif pltIdx == 19
            ylabel('0.33 sec');
       elseif pltIdx == 25
            ylabel('1 sec');            
       end
       hold off;
   end
end


if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numLasers, param.numLegs, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

 fig = formatFig(fig, true, [param.numLasers, param.numLegs]);
 
 
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [joint ' Aligned Joint Angle Mean & SEM of Individual Flies']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' joint '_overview_mean&SEM_aligned_byFly'];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);  

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% STEP ANALYSIS %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Select regions where fly is walking during each vid
clearvars('-except',initial_vars{:});
% 
% %check for walking struct in folder and load, otherwise make it
% filename = [param.googledrivesave 'walking.mat'];
% if isfile(filename)
%    fprintf('\nLoading walking.m...\n');
%    load(filename);
% else
    fprintf('\nPopulating walking.m...\n');
    %select walking bouts
    %walking = DLC_select_walking_bouts(data, behavior.data, behavior, param); %finds walking bouts (not probs) %behaviordata for just walking to walking data
    walking = DLC_select_walking_bouts(data, behavior_byBout.data, behavior_byBout, param); %finds walking bouts (not probs) %behaviordata for just walking to walking data

    %parse steps 
    walking = DLC_parse_steps(walking, param, 1); %1 to parse steps by max angle, -1 to parse by min angle
% 
%     %save walking and steps structs
%     fprintf('\nSaving walking.m...\n' );
%     save(filename, 'walking', '-v7.3');
% end

%format steps to make plotting easier
steps = DLC_format_steps(walking); 

initial_vars = who;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% One joint %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PLOT raw steps, all legs, one joint, with mean & SEM 

joint = listdlg('ListString', param.joints, 'PromptString','Select laser:', 'SelectionMode','single', 'ListSize', [100 100]);
joint_str = param.joints{joint};
fig = fullfig;
plotting.order = [1, 7, 13, 4, 10, 16];
plotting.nRows = 3;
plotting.nCols = 6;
for leg = 1:6
    pltIdx = plotting.order(leg);
    
    %find number of ctl flies 
    ctl_flies = [steps.control.leg{leg}.bout_meta.flyNum];
    ctl_numFlies = width(unique(ctl_flies));
    %extract ctl data
    ctl_steps = steps.control.leg{leg}.joint{joint};
    ctl_yMean = nanmean(ctl_steps,1); 
    ctl_ySEM = sem(ctl_steps, 1, nan, ctl_numFlies);
    num_ctl_steps = num2str(height(ctl_steps));
    
    %find number of exp flies 
    exp_flies = [steps.experiment.leg{leg}.bout_meta.flyNum];
    exp_numFlies = width(unique(exp_flies));
    %extract ctl data
    exp_steps = steps.experiment.leg{leg}.joint{joint};
    exp_yMean = nanmean(exp_steps,1); 
    exp_ySEM = sem(exp_steps, 1, nan, exp_numFlies);
    num_exp_steps = num2str(height(exp_steps));
    
    %plot ctl data
    subplot(plotting.nRows, plotting.nCols, pltIdx); hold on
    plot(ctl_steps');
    hold off; 
    %label
    if pltIdx == 1
           xlabel('Time (frames)');
           title(['L1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 2
           title(['L1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 3
           title('L1 Mean & SEM');
       elseif pltIdx == 4
           title(['R1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 5    
           title(['R1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 6
           title('R1 Mean & SEM');
       elseif pltIdx == 7
           ylabel([joint_str ' (' char(176) ')']);
           title(['L2 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 8
           title(['L2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 9
           title('L2 Mean & SEM');
       elseif pltIdx == 10
           title(['R2 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 11   
           title(['R2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 12
           title('R2 Mean & SEM');
         elseif pltIdx == 13
           title(['L3 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 14
           title(['L3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 15
           title('L3 Mean & SEM');
       elseif pltIdx == 16
           title(['R3 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 17
           title(['R3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 18
           title('R3 Mean & SEM');
    end   
    ylim([0,180]);
    yticks([0,45,90,135,180]);
    pltIdx = pltIdx+1;
    
    %plot exp data
    subplot(plotting.nRows, plotting.nCols, pltIdx); hold on;
    plot(exp_steps');
    hold off; 
    %label
    if pltIdx == 1
           xlabel('Time (frames)');
           title(['L1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 2
           title(['L1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 3
           title('L1 Mean & SEM');
       elseif pltIdx == 4
           title(['R1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 5    
           title(['R1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 6
           title('R1 Mean & SEM');
       elseif pltIdx == 7
           ylabel([joint_str ' (' char(176) ')']);
           title(['L2 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 8
           title(['L2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 9
           title('L2 Mean & SEM');
       elseif pltIdx == 10
           title(['R2 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 11   
           title(['R2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 12
           title('R2 Mean & SEM');
         elseif pltIdx == 13
           title(['L3 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 14
           title(['L3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 15
           title('L3 Mean & SEM');
       elseif pltIdx == 16
           title(['R3 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 17
           title(['R3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 18
           title('R3 Mean & SEM');
    end   
    ylim([0,180]);
    yticks([0,45,90,135,180]);
    pltIdx = pltIdx+1;
    
    %plot mean + sem
    subplot(plotting.nRows, plotting.nCols, pltIdx); hold on;
    plot(ctl_yMean, 'color', Color(param.baseColor), 'linewidth', 1.5);
    SEM_nans = find(isnan(ctl_ySEM)); 
    if ~isempty(SEM_nans) %get rid of nans due to uneven step lengths
        ctl_yMean = ctl_yMean(1:(SEM_nans(1)-1)); 
        ctl_ySEM = ctl_ySEM(1:(SEM_nans(1)-1)); 
    end
    fill_data = error_fill([1:1:width(ctl_ySEM)], ctl_yMean, ctl_ySEM);
    h = fill(fill_data.X, fill_data.Y, get_color(param.baseColor), 'EdgeColor','none');
    set(h, 'facealpha', 0.2);
    plot(exp_yMean, 'color', Color(param.expColor), 'linewidth', 1.5);
    SEM_nans = find(isnan(exp_ySEM)); 
    if ~isempty(SEM_nans) %get rid of nans due to uneven step lengths
        exp_yMean = exp_yMean(1:(SEM_nans(1)-1)); 
        exp_ySEM = exp_ySEM(1:(SEM_nans(1)-1)); 
    end
    fill_data = error_fill([1:1:width(exp_ySEM)], exp_yMean, exp_ySEM);
    h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
    set(h, 'facealpha', 0.2);
    hold off;
    %label
    if pltIdx == 1
           xlabel('Time (frames)');
           title(['L1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 2
           title(['L1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 3
           title('L1 Mean & SEM');
       elseif pltIdx == 4
           title(['R1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 5    
           title(['R1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 6
           title('R1 Mean & SEM');
       elseif pltIdx == 7
           ylabel([joint_str ' (' char(176) ')']);
           title(['L2 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 8
           title(['L2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 9
           title('L2 Mean & SEM');
       elseif pltIdx == 10
           title(['R2 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 11   
           title(['R2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 12
           title('R2 Mean & SEM');
         elseif pltIdx == 13
           title(['L3 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 14
           title(['L3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 15
           title('L3 Mean & SEM');
       elseif pltIdx == 16
           title(['R3 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 17
           title(['R3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 18
           title('R3 Mean & SEM');
    end   
    ylim([0,180]);
    yticks([0,45,90,135,180]);
    
end
fig = formatFig(fig, true, [plotting.nRows, plotting.nCols]);


%full figure title
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ['Raw Step ' joint_str ' Joint Angles ']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

%Save!
fig_name = ['\step_' joint_str '_overview_raw'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT stretched steps, all legs, one joint, with mean & SEM 

joint = listdlg('ListString', param.joints, 'PromptString','Select laser:', 'SelectionMode','single', 'ListSize', [100 100]);
joint_str = param.joints{joint};

color_by = listdlg('ListString', ["step duration","start angle"], 'PromptString','Color by:', 'SelectionMode','single', 'ListSize', [100 100]);
color_by_str = ["duration" "angle"]; color_by_str = convertStringsToChars(color_by_str(color_by));
c = parula; %colormap

fig = fullfig;
plotting.order = [1, 7, 13, 4, 10, 16];
plotting.nRows = 3;
plotting.nCols = 6;
for leg = 1:6
    clear ctl_step_lengths
    clear exp_step_lengths
    pltIdx = plotting.order(leg);
    
    %extract ctl and exp steps and calculate longest step for coloring plots
    ctl_steps = steps.control.leg{leg}.joint{joint};
    exp_steps = steps.experiment.leg{leg}.joint{joint};
%     %filter out long steps...
%     for step = 1:height(ctl_steps)
%        ctl_step_lengths(step) = width(find(~isnan(ctl_steps(step,:)))); 
%     end
%     ctl_step_outliers = isoutlier(ctl_step_lengths);
%     for step = 1: height(exp_steps)
%        exp_step_lengths(step) = width(find(~isnan(exp_steps(step,:)))); 
%     end
%     exp_step_outliers = isoutlier(exp_step_lengths);
%     %take out outliers
%     ctl_steps = ctl_steps(~ctl_step_outliers,:);
%     exp_steps = exp_steps(~exp_step_outliers,:);
%     %take off columnns with all nans
%     ctl_steps = ctl_steps(:,~all(isnan(ctl_steps)));
%     exp_steps = exp_steps(:,~all(isnan(exp_steps)));
    max_step_length = max(width(ctl_steps), width(exp_steps));
    
    %find number of ctl flies 
    ctl_flies = [steps.control.leg{leg}.bout_meta.flyNum];
%     ctl_flies = ctl_flies(~ctl_step_outliers);
    ctl_numFlies = width(unique(ctl_flies));
    %extract ctl data
%     ctl_steps = steps.control.leg{leg}.joint{joint};
    % step color
    for step = 1:height(ctl_steps)
       angle_at_onset = ctl_steps(step,1);
       if strcmpi(color_by_str, 'duration')
           step_nan = find(isnan(ctl_steps(step,:)));
           if ~isempty(step_nan)
               step_len = step_nan(1)-1;
           else
               step_len = width(ctl_steps);
           end
           ctl_color_idx(step) = ceil((step_len/max_step_length) * height(c));
       elseif strcmpi(color_by_str, 'angle')
           ctl_color_idx(step) = ceil((angle_at_onset/180) * height(c));
       end
    end
    ctl_steps = DLC_stretch_steps('-steps', ctl_steps, '-max_step', max_step_length); %STRETCH STEPS
    ctl_yMean = nanmean(ctl_steps,1); 
    ctl_ySEM = sem(ctl_steps, 1, nan, ctl_numFlies);
    num_ctl_steps = num2str(height(ctl_steps));
    
    %find number of exp flies 
    exp_flies = [steps.experiment.leg{leg}.bout_meta.flyNum];
%     exp_flies = exp_flies(~exp_step_outliers);
    exp_numFlies = width(unique(exp_flies));
    %extract ctl data
%     exp_steps = steps.experiment.leg{leg}.joint{joint};
    % step color
    for step = 1:height(exp_steps)
       angle_at_onset = exp_steps(step,1);
       if strcmpi(color_by_str, 'duration')
           step_nan = find(isnan(exp_steps(step,:)));
           if ~isempty(step_nan)
               step_len = step_nan(1)-1;
           else
               step_len = width(exp_steps);
           end
           exp_color_idx(step) = ceil((step_len/max_step_length) * height(c));
       elseif strcmpi(color_by_str, 'angle')
           exp_color_idx(step) = ceil((angle_at_onset/180) * height(c));
       end
    end
    exp_steps = DLC_stretch_steps('-steps', exp_steps, '-max_step', max_step_length); %STRETCH STEPS
    exp_yMean = nanmean(exp_steps,1); 
    exp_ySEM = sem(exp_steps, 1, nan, exp_numFlies);
    num_exp_steps = num2str(height(exp_steps));
    
    %plot ctl data
    subplot(plotting.nRows, plotting.nCols, pltIdx); hold on
    for step = 1:height(ctl_steps)
       plot(ctl_steps(step,:), 'color',c(ctl_color_idx(step),:)); 
    end
%     plot(ctl_steps');
    hold off; 
    %label
    if pltIdx == 1
           xlabel('Time');
           title(['L1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 2
           title(['L1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 3
           title('L1 Mean & SEM');
       elseif pltIdx == 4
           title(['R1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 5    
           title(['R1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 6
           title('R1 Mean & SEM');
       elseif pltIdx == 7
           ylabel([joint_str ' (' char(176) ')']);
           title(['L2 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 8
           title(['L2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 9
           title('L2 Mean & SEM');
       elseif pltIdx == 10
           title(['R2 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 11   
           title(['R2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 12
           title('R2 Mean & SEM');
         elseif pltIdx == 13
           title(['L3 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 14
           title(['L3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 15
           title('L3 Mean & SEM');
       elseif pltIdx == 16
           title(['R3 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 17
           title(['R3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 18
           title('R3 Mean & SEM');
    end   
    ylim([0,180]);
    yticks([0,45,90,135,180]);
    pltIdx = pltIdx+1;
    
    %plot exp data
    subplot(plotting.nRows, plotting.nCols, pltIdx); hold on;
    for step = 1:height(exp_steps)
       plot(exp_steps(step,:), 'color',c(exp_color_idx(step),:)); 
    end
%     plot(exp_steps');
    hold off; 
    %label
    if pltIdx == 1
           xlabel('Time');
           title(['L1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 2
           title(['L1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 3
           title('L1 Mean & SEM');
       elseif pltIdx == 4
           title(['R1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 5    
           title(['R1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 6
           title('R1 Mean & SEM');
       elseif pltIdx == 7
           ylabel([joint_str ' (' char(176) ')']);
           title(['L2 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 8
           title(['L2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 9
           title('L2 Mean & SEM');
       elseif pltIdx == 10
           title(['R2 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 11   
           title(['R2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 12
           title('R2 Mean & SEM');
         elseif pltIdx == 13
           title(['L3 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 14
           title(['L3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 15
           title('L3 Mean & SEM');
       elseif pltIdx == 16
           title(['R3 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 17
           title(['R3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 18
           title('R3 Mean & SEM');
    end   
    ylim([0,180]);
    yticks([0,45,90,135,180]);
    pltIdx = pltIdx+1;
    
    %plot mean + sem
    subplot(plotting.nRows, plotting.nCols, pltIdx); hold on;
    plot(ctl_yMean, 'color', Color(param.baseColor), 'linewidth', 1.5);
    SEM_nans = find(isnan(ctl_ySEM)); 

    fill_data = error_fill([1:1:width(ctl_ySEM)], ctl_yMean, ctl_ySEM);
    h = fill(fill_data.X, fill_data.Y, get_color(param.baseColor), 'EdgeColor','none');
    set(h, 'facealpha', 0.2);
    plot(exp_yMean, 'color', Color(param.expColor), 'linewidth', 1.5);
    SEM_nans = find(isnan(exp_ySEM)); 

    fill_data = error_fill([1:1:width(exp_ySEM)], exp_yMean, exp_ySEM);
    h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
    set(h, 'facealpha', 0.2);
    hold off;
    %label
    if pltIdx == 1
           xlabel('Time');
           title(['L1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 2
           title(['L1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 3
           title('L1 Mean & SEM');
       elseif pltIdx == 4
           title(['R1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 5    
           title(['R1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 6
           title('R1 Mean & SEM');
       elseif pltIdx == 7
           ylabel([joint_str ' (' char(176) ')']);
           title(['L2 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 8
           title(['L2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 9
           title('L2 Mean & SEM');
       elseif pltIdx == 10
           title(['R2 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 11   
           title(['R2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 12
           title('R2 Mean & SEM');
         elseif pltIdx == 13
           title(['L3 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 14
           title(['L3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 15
           title('L3 Mean & SEM');
       elseif pltIdx == 16
           title(['R3 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 17
           title(['R3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 18
           title('R3 Mean & SEM');
    end   
    ylim([0,180]);
    yticks([0,45,90,135,180]);
    
end
fig = formatFig(fig, true, [plotting.nRows, plotting.nCols]);

%full figure title
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ['Stretched Step ' joint_str ' Joint Angles ']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))


%color bar legend
 if strcmpi(color_by_str, 'duration')
     max_len_str = num2str(ceil(max_step_length/param.fps*1000));
     mid_len_str = num2str(ceil(max_step_length/2/param.fps*1000));
     cb = colorbar('Ticks',[0, 0.5, 1],...
         'TickLabels',{'0', mid_len_str, max_len_str}, 'color', Color(param.baseColor));
     pos = get(cb,'Position');
      cb.Position = [0.92 pos(2) pos(3) pos(4)]; % to change its position
      cb.Label.String = 'Step duration (ms)';
      cb.Label.Color = Color(param.baseColor);
 elseif strcmpi(color_by_str, 'angle')
      cb = colorbar('eastoutside','Ticks',[0, 0.5, 1],...
         'TickLabels',{'0', '90', '180'}, 'color', Color(param.baseColor));
      pos = get(cb,'Position');
      cb.Position = [0.92 pos(2) pos(3) pos(4)]; % to change its position
      cb.Label.String = ['Angle at step start (' char(176) ')'];
      cb.Label.Color = Color(param.baseColor);
 end
     

%Save!
fig_name = ['\step_' joint_str '_overview_stretched_colorby' color_by_str];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT stretched steps, all legs, one joint, with mean & SEM - filter out long steps

joint = listdlg('ListString', param.joints, 'PromptString','Select laser:', 'SelectionMode','single', 'ListSize', [100 100]);
joint_str = param.joints{joint};

color_by = listdlg('ListString', ["step duration","start angle"], 'PromptString','Color by:', 'SelectionMode','single', 'ListSize', [100 100]);
color_by_str = ["duration" "angle"]; color_by_str = convertStringsToChars(color_by_str(color_by));
c = parula; %colormap

fig = fullfig;
plotting.order = [1, 7, 13, 4, 10, 16];
plotting.nRows = 3;
plotting.nCols = 6;
for leg = 1:6
    clear ctl_step_lengths
    clear exp_step_lengths
    pltIdx = plotting.order(leg);
    
    %extract ctl and exp steps and calculate longest step for coloring plots
    ctl_steps = steps.control.leg{leg}.joint{joint};
    exp_steps = steps.experiment.leg{leg}.joint{joint};
    %filter out long steps...
    for step = 1:height(ctl_steps)
       ctl_step_lengths(step) = width(find(~isnan(ctl_steps(step,:)))); 
    end
    ctl_step_outliers = isoutlier(ctl_step_lengths);
    for step = 1: height(exp_steps)
       exp_step_lengths(step) = width(find(~isnan(exp_steps(step,:)))); 
    end
    exp_step_outliers = isoutlier(exp_step_lengths);
    %take out outliers
    ctl_steps = ctl_steps(~ctl_step_outliers,:);
    exp_steps = exp_steps(~exp_step_outliers,:);
    %take off columnns with all nans
    ctl_steps = ctl_steps(:,~all(isnan(ctl_steps)));
    exp_steps = exp_steps(:,~all(isnan(exp_steps)));
    max_step_length = max(width(ctl_steps), width(exp_steps));
    
    %find number of ctl flies 
    ctl_flies = [steps.control.leg{leg}.bout_meta.flyNum];
    ctl_flies = ctl_flies(~ctl_step_outliers);
    ctl_numFlies = width(unique(ctl_flies));
    %extract ctl data
%     ctl_steps = steps.control.leg{leg}.joint{joint};
    % step color
    for step = 1:height(ctl_steps)
       angle_at_onset = ctl_steps(step,1);
       if strcmpi(color_by_str, 'duration')
           step_nan = find(isnan(ctl_steps(step,:)));
           if ~isempty(step_nan)
               step_len = step_nan(1)-1;
           else
               step_len = width(ctl_steps);
           end
           ctl_color_idx(step) = ceil((step_len/max_step_length) * height(c));
       elseif strcmpi(color_by_str, 'angle')
           ctl_color_idx(step) = ceil((angle_at_onset/180) * height(c));
       end
    end
    ctl_steps = DLC_stretch_steps('-steps', ctl_steps, '-max_step', max_step_length); %STRETCH STEPS
    ctl_yMean = nanmean(ctl_steps,1); 
    ctl_ySEM = sem(ctl_steps, 1, nan, ctl_numFlies);
    num_ctl_steps = num2str(height(ctl_steps));
    
    %find number of exp flies 
    exp_flies = [steps.experiment.leg{leg}.bout_meta.flyNum];
    exp_flies = exp_flies(~exp_step_outliers);
    exp_numFlies = width(unique(exp_flies));
    %extract ctl data
%     exp_steps = steps.experiment.leg{leg}.joint{joint};
    % step color
    for step = 1:height(exp_steps)
       angle_at_onset = exp_steps(step,1);
       if strcmpi(color_by_str, 'duration')
           step_nan = find(isnan(exp_steps(step,:)));
           if ~isempty(step_nan)
               step_len = step_nan(1)-1;
           else
               step_len = width(exp_steps);
           end
           exp_color_idx(step) = ceil((step_len/max_step_length) * height(c));
       elseif strcmpi(color_by_str, 'angle')
           exp_color_idx(step) = ceil((angle_at_onset/180) * height(c));
       end
    end
    exp_steps = DLC_stretch_steps('-steps', exp_steps, '-max_step', max_step_length); %STRETCH STEPS
    exp_yMean = nanmean(exp_steps,1); 
    exp_ySEM = sem(exp_steps, 1, nan, exp_numFlies);
    num_exp_steps = num2str(height(exp_steps));
    
    %plot ctl data
    subplot(plotting.nRows, plotting.nCols, pltIdx); hold on
    for step = 1:height(ctl_steps)
       plot(ctl_steps(step,:), 'color',c(ctl_color_idx(step),:)); 
    end
%     plot(ctl_steps');
    hold off; 
    %label
    if pltIdx == 1
           xlabel('Time');
           title(['L1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 2
           title(['L1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 3
           title('L1 Mean & SEM');
       elseif pltIdx == 4
           title(['R1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 5    
           title(['R1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 6
           title('R1 Mean & SEM');
       elseif pltIdx == 7
           ylabel([joint_str ' (' char(176) ')']);
           title(['L2 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 8
           title(['L2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 9
           title('L2 Mean & SEM');
       elseif pltIdx == 10
           title(['R2 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 11   
           title(['R2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 12
           title('R2 Mean & SEM');
         elseif pltIdx == 13
           title(['L3 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 14
           title(['L3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 15
           title('L3 Mean & SEM');
       elseif pltIdx == 16
           title(['R3 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 17
           title(['R3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 18
           title('R3 Mean & SEM');
    end   
    ylim([0,180]);
    yticks([0,45,90,135,180]);
    pltIdx = pltIdx+1;
    
    %plot exp data
    subplot(plotting.nRows, plotting.nCols, pltIdx); hold on;
    for step = 1:height(exp_steps)
       plot(exp_steps(step,:), 'color',c(exp_color_idx(step),:)); 
    end
%     plot(exp_steps');
    hold off; 
    %label
    if pltIdx == 1
           xlabel('Time');
           title(['L1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 2
           title(['L1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 3
           title('L1 Mean & SEM');
       elseif pltIdx == 4
           title(['R1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 5    
           title(['R1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 6
           title('R1 Mean & SEM');
       elseif pltIdx == 7
           ylabel([joint_str ' (' char(176) ')']);
           title(['L2 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 8
           title(['L2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 9
           title('L2 Mean & SEM');
       elseif pltIdx == 10
           title(['R2 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 11   
           title(['R2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 12
           title('R2 Mean & SEM');
         elseif pltIdx == 13
           title(['L3 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 14
           title(['L3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 15
           title('L3 Mean & SEM');
       elseif pltIdx == 16
           title(['R3 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 17
           title(['R3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 18
           title('R3 Mean & SEM');
    end   
    ylim([0,180]);
    yticks([0,45,90,135,180]);
    pltIdx = pltIdx+1;
    
    %plot mean + sem
    subplot(plotting.nRows, plotting.nCols, pltIdx); hold on;
    plot(ctl_yMean, 'color', Color(param.baseColor), 'linewidth', 1.5);
    SEM_nans = find(isnan(ctl_ySEM)); 

    fill_data = error_fill([1:1:width(ctl_ySEM)], ctl_yMean, ctl_ySEM);
    h = fill(fill_data.X, fill_data.Y, get_color(param.baseColor), 'EdgeColor','none');
    set(h, 'facealpha', 0.2);
    plot(exp_yMean, 'color', Color(param.expColor), 'linewidth', 1.5);
    SEM_nans = find(isnan(exp_ySEM)); 

    fill_data = error_fill([1:1:width(exp_ySEM)], exp_yMean, exp_ySEM);
    h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
    set(h, 'facealpha', 0.2);
    hold off;
    %label
    if pltIdx == 1
           xlabel('Time');
           title(['L1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 2
           title(['L1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 3
           title('L1 Mean & SEM');
       elseif pltIdx == 4
           title(['R1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 5    
           title(['R1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 6
           title('R1 Mean & SEM');
       elseif pltIdx == 7
           ylabel([joint_str ' (' char(176) ')']);
           title(['L2 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 8
           title(['L2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 9
           title('L2 Mean & SEM');
       elseif pltIdx == 10
           title(['R2 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 11   
           title(['R2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 12
           title('R2 Mean & SEM');
         elseif pltIdx == 13
           title(['L3 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 14
           title(['L3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 15
           title('L3 Mean & SEM');
       elseif pltIdx == 16
           title(['R3 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 17
           title(['R3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 18
           title('R3 Mean & SEM');
    end   
    ylim([0,180]);
    yticks([0,45,90,135,180]);
    
end
fig = formatFig(fig, true, [plotting.nRows, plotting.nCols]);

%full figure title
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ['Stretched Step ' joint_str ' Joint Angles ']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))


%color bar legend
 if strcmpi(color_by_str, 'duration')
     max_len_str = num2str(ceil(max_step_length/param.fps*1000));
     mid_len_str = num2str(ceil(max_step_length/2/param.fps*1000));
     cb = colorbar('Ticks',[0, 0.5, 1],...
         'TickLabels',{'0', mid_len_str, max_len_str}, 'color', Color(param.baseColor));
     pos = get(cb,'Position');
      cb.Position = [0.92 pos(2) pos(3) pos(4)]; % to change its position
      cb.Label.String = 'Step duration (ms)';
      cb.Label.Color = Color(param.baseColor);
 elseif strcmpi(color_by_str, 'angle')
      cb = colorbar('eastoutside','Ticks',[0, 0.5, 1],...
         'TickLabels',{'0', '90', '180'}, 'color', Color(param.baseColor));
      pos = get(cb,'Position');
      cb.Position = [0.92 pos(2) pos(3) pos(4)]; % to change its position
      cb.Label.String = ['Angle at step start (' char(176) ')'];
      cb.Label.Color = Color(param.baseColor);
 end
     

%Save!
fig_name = ['\step_' joint_str '_overview_stretched_colorby' color_by_str '_longStepsRemoved'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT stretched steps aligned to laser at onset, all legs, one joint, with mean & SEM 

joint = listdlg('ListString', param.joints, 'PromptString','Select joint:', 'SelectionMode','single', 'ListSize', [100 100]);
joint_str = param.joints{joint};

color_by = listdlg('ListString', ["step duration","start angle"], 'PromptString','Color by:', 'SelectionMode','single', 'ListSize', [100 100]);
color_by_str = ["duration", "angle"]; color_by_str = convertStringsToChars(color_by_str(color_by));
c = parula; %colormap

fig = fullfig;
plotting.order = [1, 7, 13, 4, 10, 16];
plotting.nRows = 3;
plotting.nCols = 6;
for leg = 1:6
    pltIdx = plotting.order(leg);
    
    %extract ctl and exp steps and calculate longest step for coloring plots
    ctl_steps = steps.control.leg{leg}.joint{joint};
    exp_steps = steps.experiment.leg{leg}.joint{joint};
    max_step_length = max(width(ctl_steps), width(exp_steps));
    
    %find number of ctl flies 
    ctl_flies = [steps.control.leg{leg}.bout_meta.flyNum];
    ctl_numFlies = width(unique(ctl_flies));
    %align steps
    for step = 1:height(ctl_steps)
       angle_at_onset = ctl_steps(step,1);
       angle_aligned_step = ctl_steps(step,:) - angle_at_onset;
       ctl_steps(step,:) = angle_aligned_step;
       %color
       if strcmpi(color_by_str, 'duration')
           step_nan = find(isnan(ctl_steps(step,:)));
           if ~isempty(step_nan)
               step_len = step_nan(1)-1;
           else
               step_len = width(ctl_steps);
           end
           ctl_color_idx(step) = ceil((step_len/max_step_length) * height(c));
       elseif strcmpi(color_by_str, 'angle')
           ctl_color_idx(step) = ceil((angle_at_onset/180) * height(c));
       end
    end
    ctl_steps = DLC_stretch_steps('-steps', ctl_steps); %STRETCH STEPS
    ctl_yMean = nanmean(ctl_steps,1); 
    ctl_ySEM = sem(ctl_steps, 1, nan, ctl_numFlies);
    num_ctl_steps = num2str(height(ctl_steps));
    
    %find number of exp flies 
    exp_flies = [steps.experiment.leg{leg}.bout_meta.flyNum];
    exp_numFlies = width(unique(exp_flies));
    %align steps 
    for step = 1:height(exp_steps)
       angle_at_onset = exp_steps(step,1);
       angle_aligned_step = exp_steps(step,:) - angle_at_onset;
       exp_steps(step,:) = angle_aligned_step;
       %color
       if strcmpi(color_by_str, 'duration')
           step_nan = find(isnan(exp_steps(step,:)));
           if ~isempty(step_nan)
               step_len = step_nan(1)-1;
           else
               step_len = width(exp_steps);
           end
           exp_color_idx(step) = ceil((step_len/max_step_length) * height(c));
       elseif strcmpi(color_by_str, 'angle')
           exp_color_idx(step) = ceil((angle_at_onset/180) * height(c));
       end
    end
    exp_steps = DLC_stretch_steps('-steps', exp_steps); %STRETCH STEPS
    exp_yMean = nanmean(exp_steps,1); 
    exp_ySEM = sem(exp_steps, 1, nan, exp_numFlies);
    num_exp_steps = num2str(height(exp_steps));
    
    %plot ctl data
    subplot(plotting.nRows, plotting.nCols, pltIdx); hold on
    for step = 1:height(ctl_steps)
       plot(ctl_steps(step,:), 'color',c(ctl_color_idx(step),:)); 
    end
%     plot(ctl_steps');
    hold off; 
    %label
    if pltIdx == 1
           xlabel('Time');
           title(['L1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 2
           title(['L1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 3
           title('L1 Mean & SEM');
       elseif pltIdx == 4
           title(['R1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 5    
           title(['R1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 6
           title('R1 Mean & SEM');
       elseif pltIdx == 7
           ylabel([joint_str ' (' char(176) ')']);
           title(['L2 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 8
           title(['L2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 9
           title('L2 Mean & SEM');
       elseif pltIdx == 10
           title(['R2 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 11   
           title(['R2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 12
           title('R2 Mean & SEM');
         elseif pltIdx == 13
           title(['L3 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 14
           title(['L3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 15
           title('L3 Mean & SEM');
       elseif pltIdx == 16
           title(['R3 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 17
           title(['R3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 18
           title('R3 Mean & SEM');
    end   
    ylim([0,180]);
    yticks([0,45,90,135,180]);
    pltIdx = pltIdx+1;
    
    %plot exp data
    subplot(plotting.nRows, plotting.nCols, pltIdx); hold on;
    for step = 1:height(exp_steps)
       plot(exp_steps(step,:), 'color',c(exp_color_idx(step),:)); 
    end
%     plot(exp_steps');
    hold off; 
    %label
    if pltIdx == 1
           xlabel('Time');
           title(['L1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 2
           title(['L1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 3
           title('L1 Mean & SEM');
       elseif pltIdx == 4
           title(['R1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 5    
           title(['R1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 6
           title('R1 Mean & SEM');
       elseif pltIdx == 7
           ylabel([joint_str ' (' char(176) ')']);
           title(['L2 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 8
           title(['L2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 9
           title('L2 Mean & SEM');
       elseif pltIdx == 10
           title(['R2 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 11   
           title(['R2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 12
           title('R2 Mean & SEM');
         elseif pltIdx == 13
           title(['L3 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 14
           title(['L3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 15
           title('L3 Mean & SEM');
       elseif pltIdx == 16
           title(['R3 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 17
           title(['R3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 18
           title('R3 Mean & SEM');
    end 
    ylim([0,180]);
    yticks([0,45,90,135,180]);
    pltIdx = pltIdx+1;
    
    %plot mean + sem
    subplot(plotting.nRows, plotting.nCols, pltIdx); hold on;
    plot(ctl_yMean, 'color', Color(param.baseColor), 'linewidth', 1.5);
    SEM_nans = find(isnan(ctl_ySEM)); 

    fill_data = error_fill([1:1:width(ctl_ySEM)], ctl_yMean, ctl_ySEM);
    h = fill(fill_data.X, fill_data.Y, get_color(param.baseColor), 'EdgeColor','none');
    set(h, 'facealpha', 0.2);
    plot(exp_yMean, 'color', Color(param.expColor), 'linewidth', 1.5);
    SEM_nans = find(isnan(exp_ySEM)); 

    fill_data = error_fill([1:1:width(exp_ySEM)], exp_yMean, exp_ySEM);
    h = fill(fill_data.X, fill_data.Y, get_color(param.expColor), 'EdgeColor','none');
    set(h, 'facealpha', 0.2);
    hold off;
    %label
    if pltIdx == 1
           xlabel('Time');
           title(['L1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 2
           title(['L1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 3
           title('L1 Mean & SEM');
       elseif pltIdx == 4
           title(['R1 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 5    
           title(['R1 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 6
           title('R1 Mean & SEM');
       elseif pltIdx == 7
           ylabel([joint_str ' (' char(176) ')']);
           title(['L2 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 8
           title(['L2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 9
           title('L2 Mean & SEM');
       elseif pltIdx == 10
           title(['R2 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 11   
           title(['R2 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 12
           title('R2 Mean & SEM');
         elseif pltIdx == 13
           title(['L3 Control (n=' num_ctl_steps ')']);
        elseif pltIdx == 14
           title(['L3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 15
           title('L3 Mean & SEM');
       elseif pltIdx == 16
           title(['R3 Control (n=' num_ctl_steps ')']);
       elseif pltIdx == 17
           title(['R3 Experiment (n=' num_exp_steps ')']);
       elseif pltIdx == 18
           title('R3 Mean & SEM');
    end   
    ylim([0,180]);
    yticks([0,45,90,135,180]);
end
fig = formatFig(fig, true, [plotting.nRows, plotting.nCols]);

%full figure title
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ['Stretched Step ' joint_str ' Joint Angles ']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

%color bar legend
 if strcmpi(color_by_str, 'duration')
     max_len_str = num2str(ceil(max_step_length/param.fps*1000));
     mid_len_str = num2str(ceil(max_step_length/2/param.fps*1000));
     cb = colorbar('Ticks',[0, 0.5, 1],...
         'TickLabels',{'0', mid_len_str, max_len_str}, 'color', Color(param.baseColor));
     pos = get(cb,'Position');
      cb.Position = [0.92 pos(2) pos(3) pos(4)]; % to change its position
      cb.Label.String = 'Step duration (ms)';
      cb.Label.Color = Color(param.baseColor);
 elseif strcmpi(color_by_str, 'angle')
      cb = colorbar('eastoutside','Ticks',[0, 0.5, 1],...
         'TickLabels',{'0', '90', '180'}, 'color', Color(param.baseColor));
      pos = get(cb,'Position');
      cb.Position = [0.92 pos(2) pos(3) pos(4)]; % to change its position
      cb.Label.String = ['Angle at step start (' char(176) ')'];
      cb.Label.Color = Color(param.baseColor);
 end
     
     
%Save!
fig_name = ['\step_' joint_str '_overview_stretched_laserAligned_colorby' color_by_str];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT exp steps aligned to laser onset, all legs, one joint, with mean & SEM 

joint = listdlg('ListString', param.joints, 'PromptString','Select laser:', 'SelectionMode','single', 'ListSize', [100 100]);
joint_str = param.joints{joint};

color_by = listdlg('ListString', ['phase at stim onset'; 'angle at stim onset'], 'PromptString','Color by:', 'SelectionMode','single', 'ListSize', [120 100]);
color_by_str = ["phase", "angle"]; color_by_str = convertStringsToChars(color_by_str(color_by));

fig = fullfig;
c = parula; %color scheme for plot
plotting.order = [1, 3, 5, 2, 4, 6];
plotting.nRows = 3;
plotting.nCols = 2;
for leg = 1:6
    pltIdx = plotting.order(leg);

    %find number of exp flies 
    exp_flies = [steps.experiment.leg{leg}.bout_meta.flyNum];
    exp_numFlies = width(unique(exp_flies));
    %extract ctl data
    exp_steps = steps.experiment.leg{leg}.joint{joint};
    exp_meta = steps.experiment.leg{leg}.step_meta;
    
    [aligned_steps, step_phase] = DLC_align_steps_onset(exp_steps, exp_meta, param); 
    num_steps = num2str(height(aligned_steps));
 
    %plot exp data
    subplot(plotting.nRows, plotting.nCols, pltIdx); hold on;
    %plot laser on 
    xline(param.laser_on, '--', 'color',Color(param.laserColor));
    %plot data
    for step = 1:height(aligned_steps)
       if strcmpi(color_by_str, 'phase')
           color_idx = ceil(step_phase(step)*height(c));
       elseif strcmpi(color_by_str, 'angle')
          color_idx = ceil((aligned_steps(step,150)/180) * height(c));
       end
       plot(aligned_steps(step,:), 'color',c(color_idx,:)); 
    end
    hold off; 
    %label
    if pltIdx == 1
           xlabel('Time');
           title(['L1 (n=' num_steps ')']);
       elseif pltIdx == 2
           title(['R1 (n=' num_steps ')']);
       elseif pltIdx == 3
           ylabel([joint_str ' (' char(176) ')']);
           title(['L2 (n=' num_steps ')']);
       elseif pltIdx == 4
           title(['R2 (n=' num_steps ')']);
       elseif pltIdx == 5
           title(['L3 (n=' num_steps ')']);
       elseif pltIdx == 6 
           title(['R3 (n=' num_steps ')']);
    end    
    
end
fig = formatFig(fig, true, [plotting.nRows, plotting.nCols]);

%full figure title
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ['Aligned Experimental Step ' joint_str ' Joint Angles ']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))


%color bar legend
if strcmpi(color_by_str, 'phase')
    cb = colorbar('eastoutside','Ticks',[0,1],...
             'TickLabels',{'step start', 'step end'}, 'color', Color(param.baseColor));
    pos = get(cb,'Position');
    cb.Position = [0.92 pos(2) pos(3) pos(4)]; % to change its position
    cb.Label.String = 'Phase at laser onset';
    cb.Label.Color = Color(param.baseColor);
elseif strcmpi(color_by_str, 'angle')
    cb = colorbar('eastoutside','Ticks',[0, 0.5, 1],...
             'TickLabels',{'0', '90', '180'}, 'color', Color(param.baseColor));
    pos = get(cb,'Position');
    cb.Position = [0.92 pos(2) pos(3) pos(4)]; % to change its position
    cb.Label.String = ['Angle at laser onset (' char(176) ')'];
    cb.Label.Color = Color(param.baseColor);
end

%Save!
fig_name = ['\step_' joint_str '_overview_aligned_colorby' color_by_str];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT exp steps aligned to laser onset AND angle at onset, all legs, one joint, with mean & SEM 

joint = listdlg('ListString', param.joints, 'PromptString','Select laser:', 'SelectionMode','single', 'ListSize', [100 100]);
joint_str = param.joints{joint};

color_by = listdlg('ListString', ['phase at stim onset'; 'angle at stim onset'], 'PromptString','Color by:', 'SelectionMode','single', 'ListSize', [120 100]);
color_by_str = ["phase", "angle"]; color_by_str = convertStringsToChars(color_by_str(color_by));

fig = fullfig;
c = parula; %color scheme for plot
plotting.order = [1, 3, 5, 2, 4, 6];
plotting.nRows = 3;
plotting.nCols = 2;
for leg = 1:6
    pltIdx = plotting.order(leg);

    %find number of exp flies 
    exp_flies = [steps.experiment.leg{leg}.bout_meta.flyNum];
    exp_numFlies = width(unique(exp_flies));
    %extract ctl data
    exp_steps = steps.experiment.leg{leg}.joint{joint};
    exp_meta = steps.experiment.leg{leg}.step_meta;
    
    [aligned_steps, step_phase] = DLC_align_steps_onset(exp_steps, exp_meta, param); 
    num_steps = num2str(height(aligned_steps));
 
    %plot exp data
    subplot(plotting.nRows, plotting.nCols, pltIdx); hold on;
    %plot laser on 
    xline(param.laser_on, '--', 'color',Color(param.laserColor));
    %plot data
    for step = 1:height(aligned_steps)
       if strcmpi(color_by_str, 'phase')
           color_idx = ceil(step_phase(step)*height(c));
       elseif strcmpi(color_by_str, 'angle')
          color_idx = ceil((aligned_steps(step,150)/180) * height(c));
       end
       angle_at_onset = aligned_steps(step,param.laser_on);
       angle_aligned_step = aligned_steps(step,:) - angle_at_onset;
       plot(angle_aligned_step, 'color',c(color_idx,:)); 
    end
    hold off; 
    %label
    if pltIdx == 1
           xlabel('Time');
           title(['L1 (n=' num_steps ')']);
       elseif pltIdx == 2
           title(['R1 (n=' num_steps ')']);
       elseif pltIdx == 3
           ylabel([joint_str ' (' char(176) ')']);
           title(['L2 (n=' num_steps ')']);
       elseif pltIdx == 4
           title(['R2 (n=' num_steps ')']);
       elseif pltIdx == 5
           title(['L3 (n=' num_steps ')']);
       elseif pltIdx == 6 
           title(['R3 (n=' num_steps ')']);
    end    
    
end
fig = formatFig(fig, true, [plotting.nRows, plotting.nCols]);

%full figure title
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ['Aligned Experimental Step ' joint_str ' Joint Angles ']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

%color bar legend
if strcmpi(color_by_str, 'phase')
    cb = colorbar('eastoutside','Ticks',[0,1],...
             'TickLabels',{'step start', 'step end'}, 'color', Color(param.baseColor));
    pos = get(cb,'Position');
    cb.Position = [0.92 pos(2) pos(3) pos(4)]; % to change its position
    cb.Label.String = 'Phase at laser onset';
    cb.Label.Color = Color(param.baseColor);
elseif strcmpi(color_by_str, 'angle')
    cb = colorbar('eastoutside','Ticks',[0, 0.5, 1],...
             'TickLabels',{'0', '90', '180'}, 'color', Color(param.baseColor));
    pos = get(cb,'Position');
    cb.Position = [0.92 pos(2) pos(3) pos(4)]; % to change its position
    cb.Label.String = ['Angle at laser onset (' char(176) ')'];
    cb.Label.Color = Color(param.baseColor);
end

%Save!
fig_name = ['\step_' joint_str '_overview_aligned_laserAligned_colorby' color_by_str];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT jnt angle distribution over time

joint = listdlg('ListString', param.joints, 'PromptString','Select laser:', 'SelectionMode','single', 'ListSize', [100 100]);
joint_str = param.joints{joint};
fig = fullfig;
plotting.order = [1, 3, 5, 2, 4, 6];
plotting.nRows = 3;
plotting.nCols = 2;
for leg = 1:6
    pltIdx = plotting.order(leg);
    
    %find number of ctl flies 
    ctl_flies = [steps.control.leg{leg}.bout_meta.flyNum];
    ctl_numFlies = width(unique(ctl_flies));
    %extract ctl data
    ctl_steps = steps.control.leg{leg}.joint{joint};
    ctl_num_steps = num2str(height(ctl_steps));
       
    %find number of exp flies 
    exp_flies = [steps.experiment.leg{leg}.bout_meta.flyNum];
    exp_numFlies = width(unique(exp_flies));
    %extract ctl data
    exp_steps = steps.experiment.leg{leg}.joint{joint};
    exp_num_steps = num2str(height(exp_steps));
    
    %plot data
    subplot(plotting.nRows, plotting.nCols, pltIdx); hold on
    binEdges = linspace(0,180,37);
    histogram(ctl_steps, binEdges, 'Normalization', 'probability', 'FaceColor', Color(param.baseColor), 'EdgeColor', Color(param.baseColor));
    histogram(exp_steps, binEdges, 'Normalization', 'probability', 'FaceColor', Color(param.expColor), 'EdgeColor', Color(param.expColor));
    hold off;
    %label
    if pltIdx == 1
           xlabel([joint_str ' (' char(176) ')']);
           title(['L1 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 2
           title(['R1 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 3
           ylabel('Probability');
           title(['L2 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 4
           title(['R2 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 5
           title(['L3 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 6 
           title(['R3 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
    end    
    
end
fig = formatFig(fig, true, [plotting.nRows, plotting.nCols]);


%full figure title
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ['Step ' joint_str ' Joint Angle Distribution']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

%Save!
fig_name = ['\step_' joint_str '_distribution_overview'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT jnt angle distribution over time - filter out long steps

joint = listdlg('ListString', param.joints, 'PromptString','Select laser:', 'SelectionMode','single', 'ListSize', [100 100]);
joint_str = param.joints{joint};
fig = fullfig;
plotting.order = [1, 3, 5, 2, 4, 6];
plotting.nRows = 3;
plotting.nCols = 2;
for leg = 1:6
    clear ctl_step_lengths exp_step_lengths
    pltIdx = plotting.order(leg);
    
    %find flies and steps
    ctl_flies = [steps.control.leg{leg}.bout_meta.flyNum];
    exp_flies = [steps.experiment.leg{leg}.bout_meta.flyNum];
    ctl_steps = steps.control.leg{leg}.joint{joint};
    exp_steps = steps.experiment.leg{leg}.joint{joint};
    
    %filter out long steps...
    for step = 1:height(ctl_steps)
       ctl_step_lengths(step) = width(find(~isnan(ctl_steps(step,:)))); 
    end
    ctl_step_outliers = isoutlier(ctl_step_lengths);
    for step = 1: height(exp_steps)
       exp_step_lengths(step) = width(find(~isnan(exp_steps(step,:)))); 
    end
    exp_step_outliers = isoutlier(exp_step_lengths);
    %take out outliers
    ctl_steps = ctl_steps(~ctl_step_outliers,:);
    exp_steps = exp_steps(~exp_step_outliers,:);
    %take off columnns with all nans
    ctl_steps = ctl_steps(:,~all(isnan(ctl_steps)));
    exp_steps = exp_steps(:,~all(isnan(exp_steps)));
    
    %find number of flies and steps
    exp_numFlies = width(unique(exp_flies));
    exp_num_steps = num2str(height(exp_steps));
    ctl_num_steps = num2str(height(ctl_steps));
    ctl_numFlies = width(unique(ctl_flies));

    
    %plot data
    subplot(plotting.nRows, plotting.nCols, pltIdx); hold on
    binEdges = linspace(0,180,37);
    histogram(ctl_steps, binEdges, 'Normalization', 'probability', 'FaceColor', Color(param.baseColor), 'EdgeColor', Color(param.baseColor));
    histogram(exp_steps, binEdges, 'Normalization', 'probability', 'FaceColor', Color(param.expColor), 'EdgeColor', Color(param.expColor));
    hold off;
    %label
    if pltIdx == 1
           xlabel([joint_str ' (' char(176) ')']);
           title(['L1 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 2
           title(['R1 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 3
           ylabel('Probability');
           title(['L2 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 4
           title(['R2 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 5
           title(['L3 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 6 
           title(['R3 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
    end    
    
end
fig = formatFig(fig, true, [plotting.nRows, plotting.nCols]);


%full figure title
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ['Step ' joint_str ' Joint Angle Distribution']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

%Save!
fig_name = ['\step_' joint_str '_distribution_overview_longStepsRemoved'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT AEA % PEA in control vs exp across legs

joint = listdlg('ListString', param.joints, 'PromptString','Select laser:', 'SelectionMode','single', 'ListSize', [100 100]);
joint_str = param.joints{joint};
fig = fullfig;
plotting.order = [1, 3, 5, 2, 4, 6];
plotting.nRows = 3;
plotting.nCols = 2;
for leg = 1:6
    pltIdx = plotting.order(leg);
    
    %extract ctl data
    ctl_steps = steps.control.leg{leg}.joint{joint};
    ctl_aeas = ctl_steps(:,1);
    for step = 1:height(ctl_steps)
       ctl_peas(step) = min(ctl_steps(step,:));
    end
    mean_ctl_aea = mean(ctl_aeas);
    mean_ctl_pea = mean(ctl_peas);
    
    ctl_num_steps = num2str(height(ctl_steps));
       
    %extract ctl data
    exp_steps = steps.experiment.leg{leg}.joint{joint};
    exp_aeas = exp_steps(:,1);
    for step = 1:height(exp_steps)
       exp_peas(step) = min(exp_steps(step,:));
    end
    mean_exp_aea = mean(exp_aeas);
    mean_exp_pea = mean(exp_peas);
    
    exp_num_steps = num2str(height(exp_steps));
    
    %plot data
    subplot(plotting.nRows, plotting.nCols, pltIdx); hold on
    ctl_x_aea = linspace(1,1,height(ctl_aeas));
    exp_x_aea = linspace(2,2,height(exp_aeas));
    ctl_x_pea = linspace(3,3,height(ctl_peas));
    exp_x_pea = linspace(4,4,height(exp_peas));
    plot(ctl_x_aea, ctl_aeas, '.', 'color', Color(param.baseColor));
    plot(exp_x_aea, exp_aeas, '.', 'color', Color(param.expColor));
    plot(ctl_x_pea, ctl_peas, '.', 'color', Color(param.baseColor));
    plot(exp_x_pea, exp_peas, '.', 'color', Color(param.expColor));
    
    mean_aea_x = [1,2];
    mean_pea_x = [3,4];
    plot(mean_aea_x, [mean_ctl_aea, mean_exp_aea], '.-', 'color', Color('orange'));
    plot(mean_pea_x, [mean_ctl_pea, mean_exp_pea], '.-', 'color', Color('orange'));
    
    hold off;
%     label
    if pltIdx == 1
           title(['L1 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 2
           title(['R1 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 3
           ylabel([joint_str ' (' char(176) ')']);
           title(['L2 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 4
           title(['R2 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 5
           title(['L3 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 6 
           title(['R3 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
    end    
    xlim([0,5]);
    xticks([1 2 3 4]);
    xticklabels({'Control AEA','Experimental AEA','Control PEA','Experimental PEA'});
    
    
end
fig = formatFig(fig, true, [plotting.nRows, plotting.nCols]);


%full figure title
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ['Step ' joint_str ' Joint Angle Anterior and Posterior Extreme Angles']);
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

%Save!
fig_name = ['step_' joint_str '_AEA&PEA_overview'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT step duration/frequency control vs exp across legs 

joint = listdlg('ListString', param.joints, 'PromptString','Select laser:', 'SelectionMode','single', 'ListSize', [100 100]);
joint_str = param.joints{joint};
fig = fullfig;
plotting.order = [1, 3, 5, 2, 4, 6];
plotting.nRows = 3;
plotting.nCols = 2;
for leg = 1:6
    pltIdx = plotting.order(leg);
    
    %extract ctl data
    ctl_steps = steps.control.leg{leg}.joint{joint};
    for step = 1:height(ctl_steps)
       nans = find(isnan(ctl_steps(step,:)));
       if ~isempty(nans)
           ctl_durs(step) = (nans(1)-1)/param.fps*1000;
       else
           ctl_durs(step) = (width(ctl_steps))/param.fps*1000;
       end
    end
    mean_ctl_dur = mean(ctl_durs);
    
    ctl_num_steps = num2str(height(ctl_steps));
       
    %extract ctl data
    exp_steps = steps.experiment.leg{leg}.joint{joint};
    for step = 1:height(exp_steps)
       nans = find(isnan(exp_steps(step,:)));
       if ~isempty(nans)
           exp_durs(step) = (nans(1)-1)/param.fps*1000;
       else
           exp_durs(step) = (width(exp_steps))/param.fps*1000;
       end
    end
    mean_exp_dur = mean(exp_durs);
    
    exp_num_steps = num2str(height(exp_steps));
    
    %plot data
    subplot(plotting.nRows, plotting.nCols, pltIdx); hold on
    ctl_x_dur = linspace(1,1,width(ctl_durs));
    exp_x_dur = linspace(2,2,width(exp_durs));

    plot(ctl_x_dur, ctl_durs', '.', 'color', Color(param.baseColor));
    plot(exp_x_dur, exp_durs', '.', 'color', Color(param.expColor));
  
    mean_dur_x = [1,2];
    plot(mean_dur_x, [mean_ctl_dur, mean_exp_dur], '.-', 'color', Color('orange'));
    
    hold off;
%     label
    if pltIdx == 1
           title(['L1 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 2
           title(['R1 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 3
           ylabel('Duration (ms)');
           title(['L2 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 4
           title(['R2 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 5
           title(['L3 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
       elseif pltIdx == 6 
           title(['R3 (n control=' ctl_num_steps ', n experimental=' exp_num_steps ')']);
    end    
    xlim([0,3]);
    xticks([1 2]);
    xticklabels({'Control Duration','Experimental Duration',});

end
fig = formatFig(fig, true, [plotting.nRows, plotting.nCols]);


%full figure title
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, 'Step Duration');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

%Save!
fig_name = ['\step_duration_overview'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% One leg %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% Joint x Phase %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ORGANIZE DATA: joint data during steps as fn of phase
% Exp datapoints are only those that occur during stim
% This answers the question: does the actual stim itself shift the
%   joint angle across all parts of the step cycle or just parts. It's a
%   more specific plot than the one above, because exp datapoints are more
%   conservatively chosen. 
clearvars('-except',initial_vars{:});

XFrames = 100; %The number of frames post stim onset to include in the withinXFrames column (column 4) of ctl_data and exp_data
myPhase = 0; %1=use my phase calculation that aligns peaks, 0=use hilbert transform.
oversample = 0; interpFactor = 4; %oversample=1 oversamples the angle and phase data by a factor of interpFactor

clear exp_data ctl_data
for leg = 1:6
    for joint = 1:4
        %get data
        %ctl
        ctl_joint = steps.control.leg{leg}.joint{joint};
        jnt = find(contains(steps.control.leg{leg}.phase_labels, param.joints{joint}));
        if myPhase; ctl_phase = steps.control.leg{leg}.myPhase{jnt};
        else; ctl_phase = steps.control.leg{leg}.phase{jnt}; end
        
        %oversample each step if indicated
        if oversample
            cj_temp = NaN(height(ctl_joint), (width(ctl_joint)*interpFactor));
            cp_temp = NaN(height(ctl_phase), (width(ctl_phase)*interpFactor));
            for i = 1:height(cj_temp)
               %skip if not at least 9 datapoints (needed for interp fn)
               cj_not_nans = ~isnan(ctl_joint(i,:)); 
               cp_not_nans = ~isnan(ctl_phase(i,:));    
               if sum(cj_not_nans)>=9 & sum(cp_not_nans)>= 9
                   %leg data
                   cj_interp = interp (ctl_joint(i,cj_not_nans), interpFactor);
                   cj_temp(i,:) = [cj_interp, NaN(1,width(cj_temp)-width(cj_interp))];
                   %phase
                   cp_interp = interp(ctl_phase(i,cp_not_nans), interpFactor);
                   cp_temp(i,:) = [cp_interp, NaN(1,width(cp_temp)-width(cp_interp))];
               end
            end
            ctl_joint = cj_temp;
            ctl_phase = cp_temp;
        end
                
        ctl_flies = [steps.control.leg{leg}.bout_meta(:).flyNum]';
        for i = 2:width(ctl_joint)
            ctl_flies(:,i) = ctl_flies(:,1);
        end
        ctl_withinXframes = DLC_withinXFrames(ctl_joint, steps.control.leg{leg}.step_meta, XFrames); %1=datapoint is within 50 frames after stim onset time, 0=it's not.
        
        %exp
        exp_joint = steps.experiment.leg{leg}.joint{joint};
        jnt = find(contains(steps.experiment.leg{leg}.phase_labels, param.joints{joint}));
        if myPhase; exp_phase = steps.experiment.leg{leg}.myPhase{jnt};
        else; exp_phase = steps.experiment.leg{leg}.phase{jnt}; end
        exp_flies = [steps.experiment.leg{leg}.bout_meta(:).flyNum]';
        for i = 2:width(exp_joint)
            exp_flies(:,i) = exp_flies(:,1);
        end
        exp_withinXframes = DLC_withinXFrames(exp_joint, steps.experiment.leg{leg}.step_meta, XFrames); %1=datapoint is within 50 frames after stim onset time, 0=it's not.

        
        
        %format data from matrix to vector
        ctl_joint = ctl_joint(:);
        ctl_phase = ctl_phase(:);
        ctl_flies = ctl_flies(:);
        ctl_withinXframes = ctl_withinXframes(:);
        
        exp_joint = exp_joint(:);
        exp_phase = exp_phase(:);
        exp_flies = exp_flies(:);
        exp_withinXframes = exp_withinXframes(:);
        
        %delete rows where data = nan
        ctl_nan = find(isnan(ctl_joint));
        ctl_joint(ctl_nan,:) = [];
        ctl_phase(ctl_nan,:) = [];
        ctl_flies(ctl_nan,:) = [];
        ctl_withinXframes(ctl_nan,:) = [];

        exp_nan = find(isnan(exp_joint));
        exp_joint(exp_nan,:) = [];
        exp_phase(exp_nan,:) = [];
        exp_flies(exp_nan,:) = [];
        exp_withinXframes(exp_nan,:) = [];

        % Bin phase
        % ctl_phase = round(ctl_phase,2);
        % exp_phase = round(exp_phase,2);

        %save this leg+joint data
        ctl_data{leg, joint} = [ctl_joint, ctl_phase, ctl_flies, ctl_withinXframes];
        exp_data{leg, joint} = [exp_joint, exp_phase, exp_flies, exp_withinXframes];
    end
end
initial_vars{height(initial_vars)+1} = 'ctl_data';
initial_vars{height(initial_vars)+1} = 'exp_data';
initial_vars{height(initial_vars)+1} = 'XFrames';
initial_vars{height(initial_vars)+1} = 'myPhase';
clearvars('-except',initial_vars{:}); initial_vars = who;

%%
leg = 1; 
joint = 3;
% sigdig = 2; sigstep = 0.01; %sigstep should be rounded to sigdig
sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig

if sigdig == 1; dotSize = 20; elseif sigdig == 2; dotSize = 3; end

%% PLOT peaks and troughs... to test step alignment in the phase calculation

% leg = 1;
% joint = 3; 

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig; hold on
plotting.nRows = 1; 
plotting.nCols = 2; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

%control
subplot(plotting.nRows, plotting.nCols,1); 
[max_pks, max_locs, max_w, max_p] = findpeaks(ctl_data{leg,joint}(:,1),'MinPeakProminence',10);
[min_pks, min_locs, min_w, min_p] = findpeaks(ctl_data{leg,joint}(:,1)*-1,'MinPeakProminence',10);

% plot(ctl_data{leg,joint}(:,1)); hold on; scatter(max_locs,max_pks); hold off;

polarscatter(ctl_data{leg,joint}(max_locs,2), ctl_data{leg,joint}(max_locs,1), [3], ctl_data{leg,joint}(max_locs,3),'filled');

title('Peaks')
% pax = gca;
% pax.FontSize = 14;
% pax.RColor = Color(param.baseColor);
% pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45, 90,135, 180])
thetaticks([0, 90, 180, 270]);


%experimental
subplot(plotting.nRows, plotting.nCols,2); 
polarscatter(ctl_data{leg,joint}(min_locs,2), ctl_data{leg,joint}(min_locs,1), [3], ctl_data{leg,joint}(min_locs,3),'filled');
title('Troughs')
% pax = gca;
% pax.FontSize = 14;
% pax.RColor = [0.8, 0.8, 0.8];
% pax.ThetaColor = [0.8, 0.8, 0.8];
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' step peaks x phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' step peaks x phase'];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT peaks and troughs as DENSITY... to test step alignment in the phase calculation

% polarscatter(phase,joint,vector4size,vector4color,'filled');
% 
% leg = 1;
% joint = 3; 
smooth_avgs = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 1; 
plotting.nCols = 2; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 20; elseif sigdig == 2; dotSize = 3; end

[max_pks, max_locs, max_w, max_p] = findpeaks(ctl_data{leg,joint}(:,1),'MinPeakProminence',10);
[min_pks, min_locs, min_w, min_p] = findpeaks(ctl_data{leg,joint}(:,1)*-1,'MinPeakProminence',10);

max_phase_binned = round(ctl_data{leg,joint}(max_locs,2),sigdig);
min_phase_binned = round(ctl_data{leg,joint}(min_locs,2),sigdig);
max_joint =max_locs;
min_joint = ctl_data{leg,joint}(min_locs,1);
max_flies = ctl_data{leg,joint}(max_locs,3);
min_flies = ctl_data{leg,joint}(min_locs,3);




%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
angle_bins = [0:2:180];
%make a matrix of phase for plotting 
phase_matrix = phase_bins;
for b = 2:width(angle_bins)-1
   phase_matrix(:,end+1) = phase_bins;
end

max_byPhase = NaN(height(phase_bins), height(phase_bins));
max_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
max_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    max_idxs = find(max_phase_binned == phase_bins(ph));
    max_dataPerPhase(ph) = height(max_idxs); %how many data points per frame
    max_theseAngles = max_joint(max_idxs)';
    max_byPhase(ph,1:width(max_joint(max_idxs)')) = max_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(max_theseAngles > angle_bins(b) & max_theseAngles <= angle_bins(b+1));
       if isempty(count)
           max_anglePlot(ph,b) = NaN;
           max_angleCount(ph,b) = NaN;
       else
           max_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           max_angleCount(ph,b) = sum(count);
       end
       
    end
end
max_mean = nanmean(max_byPhase,2);
max_sem = sem(max_byPhase, 2, nan, height(unique(max_flies)));


min_byPhase = NaN(height(phase_bins), height(phase_bins));
min_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
min_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    min_idxs = find(min_phase_binned == phase_bins(ph));
    min_dataPerPhase(ph) = height(min_idxs); %how many data points per frame
    min_theseAngles = min_joint(min_idxs)';
    min_byPhase(ph,1:width(min_joint(min_idxs)')) = min_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(min_theseAngles > angle_bins(b) & min_theseAngles <= angle_bins(b+1));
       if isempty(count)
           min_anglePlot(ph,b) = NaN;
           min_angleCount(ph,b) = NaN;
       else
           min_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           min_angleCount(ph,b) = sum(count);
       end
       
    end
end
min_mean = nanmean(min_byPhase,2);
min_sem = sem(min_byPhase, 2, nan, height(unique(ctl_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
% polarscatter(ctl_phase_binned, ctl_joint, [3], ctl_flies,'filled');
polarscatter(phase_matrix(:), ctl_anglePlot(:), [dotSize], ctl_angleCount(:),'filled');

title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


%color bar legend
 max_len = max(ctl_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(ctl_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
%   cb.Position = [0.35 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);


%minerimental
subplot(plotting.nRows, plotting.nCols,2); 
% polarscatter(min_phase_binned, min_joint, [3], min_flies,'filled');
polarscatter(phase_matrix(:), min_anglePlot(:), [dotSize], min_angleCount(:),'filled');

title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);



%color bar legend
 max_len = max(min_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(min_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
%   cb.Position = [0.63 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' step peaks x phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' step peaks x phase - density'];
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT Raw scatter, joint x phase for con and exp 

% leg = 1;
% joint = 3; 

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig; hold on
plotting.nRows = 1; 
plotting.nCols = 2; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

%control
subplot(plotting.nRows, plotting.nCols,1); 
polarscatter(ctl_data{leg,joint}(:,2), ctl_data{leg,joint}(:,1), [3], ctl_data{leg,joint}(:,3),'filled');
title('Control')
% pax = gca;
% pax.FontSize = 14;
% pax.RColor = Color(param.baseColor);
% pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45, 90,135, 180])
thetaticks([0, 90, 180, 270]);


%experimental
subplot(plotting.nRows, plotting.nCols,2); 
polarscatter(exp_data{leg,joint}(:,2), exp_data{leg,joint}(:,1), [3], exp_data{leg,joint}(:,3),'filled');
title('Experimental')
% pax = gca;
% pax.FontSize = 14;
% pax.RColor = [0.8, 0.8, 0.8];
% pax.ThetaColor = [0.8, 0.8, 0.8];
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase'];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase + mean (TODO sem) of exp and con data
% 
% leg = 1;
% joint = 3; 
smooth_avgs = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 1; 
plotting.nCols = 3; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

sigdig = 2; sigstep = 0.01; %sigstep should be rounded to sigdig
ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);

ctl_byPhase = NaN(height(phase_bins), height(phase_bins));
for ph = 1:height(phase_bins)
    ctl_idxs = find(ctl_phase_binned == phase_bins(ph));
    ctl_dataPerPhase(ph) = height(ctl_idxs); %how many data points per frame
    ctl_byPhase(ph,1:width(ctl_joint(ctl_idxs)')) = ctl_joint(ctl_idxs)';
end
ctl_mean = nanmean(ctl_byPhase,2);
ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));


exp_byPhase = NaN(height(phase_bins), height(phase_bins));
for ph = 1:height(phase_bins)
    exp_idxs = find(exp_phase_binned == phase_bins(ph));
    exp_dataPerPhase(ph) = height(exp_idxs); %how many data points per frame
    exp_byPhase(ph,1:width(exp_joint(exp_idxs)')) = exp_joint(exp_idxs)';
end
exp_mean = nanmean(exp_byPhase,2);
exp_sem = sem(exp_byPhase, 2, nan, height(unique(ctl_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
polarscatter(ctl_phase_binned, ctl_joint, [3], ctl_flies,'filled');
title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


%experimental
subplot(plotting.nRows, plotting.nCols,2); 
polarscatter(exp_phase_binned, exp_joint, [3], exp_flies,'filled');
title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%averages
subplot(plotting.nRows, plotting.nCols, 3);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
hold on
polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
if smooth_avgs
    title('Smoothed Averages');
else
    title('Averages');
end
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
% rlim([0 180])
% rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned+means'];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase + mean (TODO sem) of exp and con data - GRAND MEAN
% 
% leg = 1;
% joint = 3;  
smooth_avgs = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 1; 
plotting.nCols = 3; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 20; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
%control
for f = 1:param.numFlies
    ctl_byPhase = NaN(height(phase_bins), 5000);
    this_fly_idxs = find(ctl_flies == f);
    this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
    this_fly_joint = ctl_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
        ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
        if height(ctl_idxs) >= 1
            % enough data points to have a good average, so save data
            ctl_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = this_fly_joint(ctl_idxs)';
        end
    end
    ctl_means(:,f) = nanmean(ctl_byPhase,2);
    ctl_sems(:,f) = sem(ctl_byPhase, 2, nan, 1);
    ctl_fly_phase_binned{f} = this_fly_phase_binned;
    ctl_fly_joint{f} = this_fly_joint;
end
%take the grand mean (mean of fly means)
ctl_mean = nanmean(ctl_means,2);
ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%experimental
for f = 1:param.numFlies
    exp_byPhase = NaN(height(phase_bins), 5000);
    this_fly_idxs = find(exp_flies == f);
    this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
    this_fly_joint = exp_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
        exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
        if height(exp_idxs) >= 1
            % enough data points to have a good average, so save data
            exp_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = this_fly_joint(exp_idxs)';
        end
    end
    exp_means(:,f) = nanmean(exp_byPhase,2);
    exp_sems(:,f) = sem(exp_byPhase, 2, nan, 1);
    exp_fly_phase_binned{f} = this_fly_phase_binned;
    exp_fly_joint{f} = this_fly_joint;
end
%take the grand mean (mean of fly means)
exp_mean = nanmean(exp_means,2);
exp_sem = sem(exp_byPhase, 2, nan, height(unique(exp_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
polarscatter(ctl_phase_binned, ctl_joint, [dotSize], ctl_flies,'filled');
title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%experimental
subplot(plotting.nRows, plotting.nCols,2); 
polarscatter(exp_phase_binned, exp_joint, [dotSize], exp_flies,'filled');
title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%averages
subplot(plotting.nRows, plotting.nCols, 3);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
hold on
polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
if smooth_avgs
    title('Smoothed Averages');
else
    title('Averages');
end
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
if param.sameAxes
    rlim([0 180])
    rticks([0,45,90,135,180])
end
thetaticks([0, 90, 180, 270]);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned+GRANDmeans'];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.sameAxes; fig_name = [fig_name, '_sameAxes']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase + mean (TODO sem) of exp and con data - GRAND MEAN & MEAN DIFFERENCE
% 
% leg = 1;
% joint = 3;  
smooth_avgs = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 2; 
plotting.nCols = 2; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 2; sigstep = 0.01; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 30; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
%control
for f = 1:param.numFlies
    ctl_byPhase = NaN(height(phase_bins), 50000);
    this_fly_idxs = find(ctl_flies == f);
    this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
    this_fly_joint = ctl_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
        ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
        if height(ctl_idxs) >= 1
            % enough data points to have a good average, so save data
            ctl_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = this_fly_joint(ctl_idxs)';
        end
    end
    ctl_means(:,f) = nanmean(ctl_byPhase,2);
    ctl_sems(:,f) = sem(ctl_byPhase, 2, nan, 1);
    ctl_fly_phase_binned{f} = this_fly_phase_binned;
    ctl_fly_joint{f} = this_fly_joint;
end
%take the grand mean (mean of fly means)
ctl_mean = nanmean(ctl_means,2);
ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%experimental
for f = 1:param.numFlies
    exp_byPhase = NaN(height(phase_bins), 50000);
    this_fly_idxs = find(exp_flies == f);
    this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
    this_fly_joint = exp_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
        exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
        if height(exp_idxs) >= 1
            % enough data points to have a good average, so save data
            exp_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = this_fly_joint(exp_idxs)';
        end
    end
    exp_means(:,f) = nanmean(exp_byPhase,2);
    exp_sems(:,f) = sem(exp_byPhase, 2, nan, 1);
    exp_fly_phase_binned{f} = this_fly_phase_binned;
    exp_fly_joint{f} = this_fly_joint;
end
%take the grand mean (mean of fly means)
exp_mean = nanmean(exp_means,2);
exp_sem = sem(exp_byPhase, 2, nan, height(unique(exp_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
polarscatter(ctl_phase_binned, ctl_joint, [dotSize], ctl_flies,'filled');
title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%experimental
subplot(plotting.nRows, plotting.nCols,2); 
polarscatter(exp_phase_binned, exp_joint, [dotSize], exp_flies,'filled');
title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%averages
subplot(plotting.nRows, plotting.nCols, 3);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
hold on
polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
if smooth_avgs
    title('Smoothed Averages');
else
    title('Averages');
end
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
% rlim([0 180])
% rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);



%mean difference
subplot(plotting.nRows, plotting.nCols, 4);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
mean_diff = ctl_mean - exp_mean;
ydata = phase_bins; %todo add 2pi to negative vals to match polar plot labels 

polarplot(phase_bins, mean_diff, 'color', '#ff8b3d', 'lineWidth', 2);
title('Mean difference (ctl-exp)');
pax = gca;
pax.FontSize = 14;
% pax.RColor = Color(param.baseColor);
% pax.ThetaColor = Color(param.baseColor);
rlim([-50 50])
% % rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned+GRANDmeans+meanDIFFERENCE'];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


%plot just the mean difference in it's own figure 
fig = fullfig;
neg_phase = phase_bins < 0;
pos_phase = phase_bins >= 0;
new_phase_bins = [phase_bins(pos_phase); phase_bins(neg_phase)];
neg_new_phase = new_phase_bins < 0;
new_phase_bins(neg_new_phase) = new_phase_bins(neg_new_phase) + (2*pi);
new_mean_diff = [mean_diff(pos_phase); mean_diff(neg_phase)];
plot(new_phase_bins, new_mean_diff, 'color', '#ff8b3d', 'lineWidth', 2);
hold on
plot(new_phase_bins, smooth(new_mean_diff), 'color', Color(param.baseColor), 'lineWidth', 2)
title('Mean difference (ctl-exp)');
pax = gca;
pax.FontSize = 14;
ylim([-50 50]);
xlim([0 (2*pi)]);
xticks([0 pi/2 pi 3*pi/2 2*pi])
xticklabels({'0','\pi/2','\pi','3\pi/2','2\pi'})

fig = formatFig(fig, true);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase - mean difference'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_meanDIFFERENCE'];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase + mean (TODO sem) of exp and con data - GRAND MEAN - only first X frames post stim onset
% 
% leg = 1;
% joint = 3;  
smooth_avgs = 0;
ctl_onlyWithinXFrames = 0; %1= ctl frames are also only those within 150 - 150+X frames in video. 

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 1; 
plotting.nCols = 3; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 30; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);
ctl_withinXFrames = ctl_data{leg,joint}(:,4);
exp_withinXFrames = exp_data{leg,joint}(:,4);

%only keep datapoints that are within 50 frames of stim onset
if ctl_onlyWithinXFrames
    ctl_phase_binned = ctl_phase_binned(find(ctl_withinXFrames));
    ctl_joint = ctl_joint(find(ctl_withinXFrames));
    ctl_flies = ctl_flies(find(ctl_withinXFrames));
end
exp_phase_binned = exp_phase_binned(find(exp_withinXFrames));
exp_joint = exp_joint(find(exp_withinXFrames));
exp_flies = exp_flies(find(exp_withinXFrames));

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
%control
for f = 1:param.numFlies
    ctl_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(ctl_flies == f);
    this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
    this_fly_joint = ctl_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
        ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
        if height(ctl_idxs) >= 1
            % enough data points to have a good average, so save data
            ctl_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = this_fly_joint(ctl_idxs)';
        end
    end
    ctl_means(:,f) = nanmean(ctl_byPhase,2);
    ctl_sems(:,f) = sem(ctl_byPhase, 2, nan, 1);
    ctl_fly_phase_binned{f} = this_fly_phase_binned;
    ctl_fly_joint{f} = this_fly_joint;
end
%take the grand mean (mean of fly means)
ctl_mean = nanmean(ctl_means,2);
ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%experimental
for f = 1:param.numFlies
    exp_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(exp_flies == f);
    this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
    this_fly_joint = exp_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
        exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
        if height(exp_idxs) >= 1
            % enough data points to have a good average, so save data
            exp_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = this_fly_joint(exp_idxs)';
        end
    end
    exp_means(:,f) = nanmean(exp_byPhase,2);
    exp_sems(:,f) = sem(exp_byPhase, 2, nan, 1);
    exp_fly_phase_binned{f} = this_fly_phase_binned;
    exp_fly_joint{f} = this_fly_joint;
end
%take the grand mean (mean of fly means)
exp_mean = nanmean(exp_means,2);
exp_sem = sem(exp_byPhase, 2, nan, height(unique(exp_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
polarscatter(ctl_phase_binned, ctl_joint, [dotSize], ctl_flies,'filled');
title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%experimental
subplot(plotting.nRows, plotting.nCols,2); 
polarscatter(exp_phase_binned, exp_joint, [dotSize], exp_flies,'filled');
title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%averages
subplot(plotting.nRows, plotting.nCols, 3);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 3);
hold on
polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 3);
if smooth_avgs
    title('Smoothed Averages');
else
    title('Averages');
end
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
if param.sameAxes
    rlim([0 180])
    rticks([0,45,90,135,180])
end
thetaticks([0, 90, 180, 270]);


% 
% %mean difference
% subplot(plotting.nRows, plotting.nCols, 4);
% if smooth_avgs
%     ctl_mean_plot = smoothdata(ctl_mean);
%     exp_mean_plot = smoothdata(exp_mean);
% else
%     ctl_mean_plot = ctl_mean;
%     exp_mean_plot = exp_mean;
% end
% mean_diff = ctl_mean - exp_mean;
% ydata = phase_bins; %todo add 2pi to negative vals to match polar plot labels 
% 
% polarplot(phase_bins, mean_diff, 'color', '#ff8b3d', 'lineWidth', 2);
% title('Mean difference (ctl-exp)');
% pax = gca;
% pax.FontSize = 14;
% % pax.RColor = Color(param.baseColor);
% % pax.ThetaColor = Color(param.baseColor);
% rlim([-50 50])
% % % rticks([0,45,90,135,180])
% thetaticks([0, 90, 180, 270]);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase: ' num2str(XFrames) ' frames post stim onset'], 'color', Color(param.baseColor));
han.FontSize = 30;

if ctl_onlyWithinXFrames
    type_str = '_ofALLdata';
else
    type_str = '_ofEXPdata';
end

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned+GRANDmeans_OnlyFirst' num2str(XFrames) 'FramesPostStimOnset' type_str];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.sameAxes; fig_name = [fig_name, '_sameAxes']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase + mean (TODO sem) of exp and con data - GRAND MEAN & MEAN DIFFERENCE - only first X frames post stim onset
% 
% leg = 1;
% joint = 3;  
smooth_avgs = 0;
ctl_onlyWithinXFrames = 0; %1= ctl frames are also only those within 150 - 150+X frames in video. 

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 2; 
plotting.nCols = 2; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 2; sigstep = 0.01; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 30; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);
ctl_withinXFrames = ctl_data{leg,joint}(:,4);
exp_withinXFrames = exp_data{leg,joint}(:,4);

%only keep datapoints that are within 50 frames of stim onset
if ctl_onlyWithinXFrames
    ctl_phase_binned = ctl_phase_binned(find(ctl_withinXFrames));
    ctl_joint = ctl_joint(find(ctl_withinXFrames));
    ctl_flies = ctl_flies(find(ctl_withinXFrames));
end
exp_phase_binned = exp_phase_binned(find(exp_withinXFrames));
exp_joint = exp_joint(find(exp_withinXFrames));
exp_flies = exp_flies(find(exp_withinXFrames));

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
%control
for f = 1:param.numFlies
    ctl_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(ctl_flies == f);
    this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
    this_fly_joint = ctl_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
        ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
        if height(ctl_idxs) >= 1
            % enough data points to have a good average, so save data
            ctl_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = this_fly_joint(ctl_idxs)';
        end
    end
    ctl_means(:,f) = nanmean(ctl_byPhase,2);
    ctl_sems(:,f) = sem(ctl_byPhase, 2, nan, 1);
    ctl_fly_phase_binned{f} = this_fly_phase_binned;
    ctl_fly_joint{f} = this_fly_joint;
end
%take the grand mean (mean of fly means)
ctl_mean = nanmean(ctl_means,2);
ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%experimental
for f = 1:param.numFlies
    exp_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(exp_flies == f);
    this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
    this_fly_joint = exp_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
        exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
        if height(exp_idxs) >= 1
            % enough data points to have a good average, so save data
            exp_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = this_fly_joint(exp_idxs)';
        end
    end
    exp_means(:,f) = nanmean(exp_byPhase,2);
    exp_sems(:,f) = sem(exp_byPhase, 2, nan, 1);
    exp_fly_phase_binned{f} = this_fly_phase_binned;
    exp_fly_joint{f} = this_fly_joint;
end
%take the grand mean (mean of fly means)
exp_mean = nanmean(exp_means,2);
exp_sem = sem(exp_byPhase, 2, nan, height(unique(exp_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
polarscatter(ctl_phase_binned, ctl_joint, [dotSize], ctl_flies,'filled');
title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%experimental
subplot(plotting.nRows, plotting.nCols,2); 
polarscatter(exp_phase_binned, exp_joint, [dotSize], exp_flies,'filled');
title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

%averages
subplot(plotting.nRows, plotting.nCols, 3);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 3);
hold on
polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 3);
if smooth_avgs
    title('Smoothed Averages');
else
    title('Averages');
end
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
if param.sameAxes
    rlim([0 180])
    rticks([0,45,90,135,180])
end
thetaticks([0, 90, 180, 270]);



%mean difference
subplot(plotting.nRows, plotting.nCols, 4);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
mean_diff = ctl_mean - exp_mean;
ydata = phase_bins; %todo add 2pi to negative vals to match polar plot labels 

polarplot(phase_bins, mean_diff, 'color', '#ff8b3d', 'lineWidth', 2);
title('Mean difference (ctl-exp)');
pax = gca;
pax.FontSize = 14;
% pax.RColor = Color(param.baseColor);
% pax.ThetaColor = Color(param.baseColor);
rlim([-50 50])
% % rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase: ' num2str(XFrames) ' frames post stim onset'], 'color', Color(param.baseColor));
han.FontSize = 30;

if ctl_onlyWithinXFrames
    type_str = '_ofALLdata';
else
    type_str = '_ofEXPdata';
end

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned+GRANDmeans+meanDIFFERENCE_OnlyFirst' num2str(XFrames) 'FramesPostStimOnset' type_str];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.sameAxes; fig_name = [fig_name, '_sameAxes']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


%plot just the mean difference in it's own figure 
fig = fullfig;
neg_phase = phase_bins < 0;
pos_phase = phase_bins >= 0;
new_phase_bins = [phase_bins(pos_phase); phase_bins(neg_phase)];
neg_new_phase = new_phase_bins < 0;
new_phase_bins(neg_new_phase) = new_phase_bins(neg_new_phase) + (2*pi);
new_mean_diff = [mean_diff(pos_phase); mean_diff(neg_phase)];
plot(new_phase_bins, new_mean_diff, 'color', '#ff8b3d', 'lineWidth', 2);
hold on
plot(new_phase_bins, smooth(new_mean_diff), 'color', Color(param.baseColor), 'lineWidth', 2)
title('Mean difference');
pax = gca;
pax.FontSize = 14;
ylim([-50 50]);
xlim([0 (2*pi)]);
xticks([0 pi/2 pi 3*pi/2 2*pi])
xticklabels({'0','\pi/2','\pi','3\pi/2','2\pi'})

fig = formatFig(fig, true);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase - mean difference: ' num2str(XFrames) ' frames post stim onset'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_meanDIFFERENCE_OnlyFirst50FramesPostStimOnset' type_str];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

 %% PLOT joint x phase, binned phase + mean (TODO sem) of exp and con data - BY FLY 
% 
% leg = 1;
% joint = 3; 
smooth_avgs = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 3; 
plotting.nCols = param.numFlies; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 15; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);

for f = 1:param.numFlies
    ctl_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(ctl_flies == f);
    this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
    this_fly_joint = ctl_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
        ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
        ctl_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = this_fly_joint(ctl_idxs)';
    end
    ctl_mean{f} = nanmean(ctl_byPhase,2);
    ctl_sem{f} = sem(ctl_byPhase, 2, nan, 1);
    ctl_fly_phase_binned{f} = this_fly_phase_binned;
    ctl_fly_joint{f} = this_fly_joint;
end

for f = 1:param.numFlies
    exp_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(exp_flies == f);
    this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
    this_fly_joint = exp_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
        exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
        exp_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = this_fly_joint(exp_idxs)';
    end
    exp_mean{f} = nanmean(exp_byPhase,2);
    exp_sem{f} = sem(exp_byPhase, 2, nan, 1);
    exp_fly_phase_binned{f} = this_fly_phase_binned;
    exp_fly_joint{f} = this_fly_joint;
end

%plot for each fly
idx = 0;
for fly = 1:param.numFlies
    %control
    idx = idx+1;
    this_fly_idxs = find(ctl_flies == fly);
    ss = subplot(plotting.nRows, plotting.nCols,idx);
    polarscatter(ctl_fly_phase_binned{fly}, ctl_fly_joint{fly}, [dotSize], Color(param.baseColor),'filled');
    title([char(param.flyList{fly,1}) ' fly ' char(strrep(param.flyList{fly,2}, '_', '-'))]);
    rlim([0 180])
    rticks([0,45,90,135,180])
    thetaticks([0, 90, 180, 270]);


    %experimental
    this_fly_idxs = find(exp_flies == fly);
    subplot(plotting.nRows, plotting.nCols,idx+param.numFlies); 
    polarscatter(exp_phase_binned(this_fly_idxs), exp_joint(this_fly_idxs), [dotSize], exp_flies(this_fly_idxs),'filled');
%     title('Experimental')
    rlim([0 180])
    rticks([0,45,90,135,180])
    thetaticks([0, 90, 180, 270]);

    %averages
    subplot(plotting.nRows, plotting.nCols, idx+param.numFlies+param.numFlies);
    if smooth_avgs
        ctl_mean_plot = smoothdata(ctl_mean{fly});
        exp_mean_plot = smoothdata(exp_mean{fly});
    else
        ctl_mean_plot = ctl_mean{fly};
        exp_mean_plot = exp_mean{fly};
    end
    polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
    hold on
    polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
%     if smooth_avgs
%         title('Smoothed Averages');
%     else
%         title('Averages');
%     end
%     pax = gca;
%     pax.FontSize = 14;
%     pax.RColor = Color(param.baseColor);
%     pax.ThetaColor = Color(param.baseColor);
if param.sameAxes
    rlim([0 180])
    rticks([0,45,90,135,180])
end
    thetaticks([0, 90, 180, 270]);

    hold off

end

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor), 'position', param.titlePosition);
han.FontSize = 20;




%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned+means_byFLY'];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.sameAxes; fig_name = [fig_name, '_sameAxes']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase, binned angle for con and exp
% polarscatter(phase,joint,vector4size,vector4color,'filled');
% 
% leg = 1;
% joint = 3; 
smooth_avgs = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 1; 
plotting.nCols = 2; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 20; elseif sigdig == 2; dotSize = 3; end
ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
angle_bins = [0:2:180];
%make a matrix of phase for plotting 
phase_matrix = phase_bins;
for b = 2:width(angle_bins)-1
   phase_matrix(:,end+1) = phase_bins;
end

ctl_byPhase = NaN(height(phase_bins), height(phase_bins));
ctl_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
ctl_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    ctl_idxs = find(ctl_phase_binned == phase_bins(ph));
    ctl_dataPerPhase(ph) = height(ctl_idxs); %how many data points per frame
    ctl_theseAngles = ctl_joint(ctl_idxs)';
    ctl_byPhase(ph,1:width(ctl_joint(ctl_idxs)')) = ctl_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(ctl_theseAngles > angle_bins(b) & ctl_theseAngles <= angle_bins(b+1));
       if isempty(count)
           ctl_anglePlot(ph,b) = NaN;
           ctl_angleCount(ph,b) = NaN;
       else
           ctl_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           ctl_angleCount(ph,b) = sum(count);
       end
       
    end
end
ctl_mean = nanmean(ctl_byPhase,2);
ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));


exp_byPhase = NaN(height(phase_bins), height(phase_bins));
exp_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
exp_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    exp_idxs = find(exp_phase_binned == phase_bins(ph));
    exp_dataPerPhase(ph) = height(exp_idxs); %how many data points per frame
    exp_theseAngles = exp_joint(exp_idxs)';
    exp_byPhase(ph,1:width(exp_joint(exp_idxs)')) = exp_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(exp_theseAngles > angle_bins(b) & exp_theseAngles <= angle_bins(b+1));
       if isempty(count)
           exp_anglePlot(ph,b) = NaN;
           exp_angleCount(ph,b) = NaN;
       else
           exp_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           exp_angleCount(ph,b) = sum(count);
       end
       
    end
end
exp_mean = nanmean(exp_byPhase,2);
exp_sem = sem(exp_byPhase, 2, nan, height(unique(ctl_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
% polarscatter(ctl_phase_binned, ctl_joint, [3], ctl_flies,'filled');
polarscatter(phase_matrix(:), ctl_anglePlot(:), [dotSize], ctl_angleCount(:),'filled');

title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


%color bar legend
 max_len = max(ctl_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(ctl_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
%   cb.Position = [0.35 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);


%experimental
subplot(plotting.nRows, plotting.nCols,2); 
% polarscatter(exp_phase_binned, exp_joint, [3], exp_flies,'filled');
polarscatter(phase_matrix(:), exp_anglePlot(:), [dotSize], exp_angleCount(:),'filled');

title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);



%color bar legend
 max_len = max(exp_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(exp_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
%   cb.Position = [0.63 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned_angleBinned'];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase, binned angle + mean (TODO sem) of exp and con data
% polarscatter(phase,joint,vector4size,vector4color,'filled');
% 
% leg = 1;
% joint = 3; 
smooth_avgs = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 1; 
plotting.nCols = 3; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 30; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
angle_bins = [0:2:180];
%make a matrix of phase for plotting 
phase_matrix = phase_bins;
for b = 2:width(angle_bins)-1
   phase_matrix(:,end+1) = phase_bins;
end

ctl_byPhase = NaN(height(phase_bins), height(phase_bins));
ctl_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
ctl_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    ctl_idxs = find(ctl_phase_binned == phase_bins(ph));
    ctl_dataPerPhase(ph) = height(ctl_idxs); %how many data points per frame
    ctl_theseAngles = ctl_joint(ctl_idxs)';
    ctl_byPhase(ph,1:width(ctl_joint(ctl_idxs)')) = ctl_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(ctl_theseAngles > angle_bins(b) & ctl_theseAngles <= angle_bins(b+1));
       if isempty(count)
           ctl_anglePlot(ph,b) = NaN;
           ctl_angleCount(ph,b) = NaN;
       else
           ctl_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           ctl_angleCount(ph,b) = sum(count);
       end
       
    end
end
ctl_mean = nanmean(ctl_byPhase,2);
ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));


exp_byPhase = NaN(height(phase_bins), height(phase_bins));
exp_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
exp_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    exp_idxs = find(exp_phase_binned == phase_bins(ph));
    exp_dataPerPhase(ph) = height(exp_idxs); %how many data points per frame
    exp_theseAngles = exp_joint(exp_idxs)';
    exp_byPhase(ph,1:width(exp_joint(exp_idxs)')) = exp_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(exp_theseAngles > angle_bins(b) & exp_theseAngles <= angle_bins(b+1));
       if isempty(count)
           exp_anglePlot(ph,b) = NaN;
           exp_angleCount(ph,b) = NaN;
       else
           exp_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           exp_angleCount(ph,b) = sum(count);
       end
       
    end
end
exp_mean = nanmean(exp_byPhase,2);
exp_sem = sem(exp_byPhase, 2, nan, height(unique(ctl_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
% polarscatter(ctl_phase_binned, ctl_joint, [3], ctl_flies,'filled');
polarscatter(phase_matrix(:), ctl_anglePlot(:), [dotSize], ctl_angleCount(:),'filled');

title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


%color bar legend
 max_len = max(ctl_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(ctl_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
  cb.Position = [0.35 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);


%experimental
subplot(plotting.nRows, plotting.nCols,2); 
% polarscatter(exp_phase_binned, exp_joint, [3], exp_flies,'filled');
polarscatter(phase_matrix(:), exp_anglePlot(:), [dotSize], exp_angleCount(:),'filled');

title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);



%color bar legend
 max_len = max(exp_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(exp_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
  cb.Position = [0.63 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);

%averages
subplot(plotting.nRows, plotting.nCols, 3);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
hold on
polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
if smooth_avgs
    title('Smoothed Averages');
else
    title('Averages');
end
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
% rlim([0 180])
% rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned_angleBinned+means'];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase, binned angle + mean (TODO sem) of  exp and con data - GRAND MEAN
% polarscatter(phase,joint,vector4size,vector4color,'filled');
% 
% leg = 1;
% joint = 3; 
smooth_avgs = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 1; 
plotting.nCols = 3; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 2; sigstep = 0.01; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 30; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
angle_bins = [0:2:180];
%make a matrix of phase for plotting 
phase_matrix = phase_bins;
for b = 2:width(angle_bins)-1
   phase_matrix(:,end+1) = phase_bins;
end

%control - grand mean
for f = 1:param.numFlies
    ctl_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(ctl_flies == f);
    this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
    this_fly_joint = ctl_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
%         ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
        if height(ctl_idxs) >= 1
            % enough data points to have a good average, so save data
            ctl_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = this_fly_joint(ctl_idxs)';
        end
    end
    ctl_means(:,f) = nanmean(ctl_byPhase,2);
    ctl_sems(:,f) = sem(ctl_byPhase, 2, nan, 1);
end
%take the grand mean (mean of fly means)
ctl_mean = nanmean(ctl_means,2);
ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%control - binned angle x phase
ctl_byPhase = NaN(height(phase_bins), height(phase_bins));
ctl_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
ctl_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    ctl_idxs = find(ctl_phase_binned == phase_bins(ph));
    ctl_dataPerPhase(ph) = height(ctl_idxs); %how many data points per frame
    ctl_theseAngles = ctl_joint(ctl_idxs)';
    ctl_byPhase(ph,1:width(ctl_joint(ctl_idxs)')) = ctl_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(ctl_theseAngles > angle_bins(b) & ctl_theseAngles <= angle_bins(b+1));
       if isempty(count)
           ctl_anglePlot(ph,b) = NaN;
           ctl_angleCount(ph,b) = NaN;
       else
           ctl_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           ctl_angleCount(ph,b) = sum(count);
       end
       
    end
end
% ctl_mean = nanmean(ctl_byPhase,2);
% ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%experimenal - grand mean 
for f = 1:param.numFlies
    exp_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(exp_flies == f);
    this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
    this_fly_joint = exp_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
%         exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
        if height(exp_idxs) >= 1
            % enough data points to have a good average, so save data
            exp_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = this_fly_joint(exp_idxs)';
        end
    end
    exp_means(:,f) = nanmean(exp_byPhase,2);
    exp_sems(:,f) = sem(exp_byPhase, 2, nan, 1);
end
%take the grand mean (mean of fly means)
exp_mean = nanmean(exp_means,2);
exp_sem = sem(exp_byPhase, 2, nan, height(unique(exp_flies)));

%experimental - binned angle x phase 
exp_byPhase = NaN(height(phase_bins), height(phase_bins));
exp_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
exp_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    exp_idxs = find(exp_phase_binned == phase_bins(ph));
    exp_dataPerPhase(ph) = height(exp_idxs); %how many data points per frame
    exp_theseAngles = exp_joint(exp_idxs)';
    exp_byPhase(ph,1:width(exp_joint(exp_idxs)')) = exp_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(exp_theseAngles > angle_bins(b) & exp_theseAngles <= angle_bins(b+1));
       if isempty(count)
           exp_anglePlot(ph,b) = NaN;
           exp_angleCount(ph,b) = NaN;
       else
           exp_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           exp_angleCount(ph,b) = sum(count);
       end
       
    end
end
% exp_mean = nanmean(exp_byPhase,2);
% exp_sem = sem(exp_byPhase, 2, nan, height(unique(ctl_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
% polarscatter(ctl_phase_binned, ctl_joint, [3], ctl_flies,'filled');
polarscatter(phase_matrix(:), ctl_anglePlot(:), [dotSize], ctl_angleCount(:),'filled');

title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


%color bar legend
 max_len = max(ctl_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(ctl_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
  cb.Position = [0.35 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);


%experimental
subplot(plotting.nRows, plotting.nCols,2); 
% polarscatter(exp_phase_binned, exp_joint, [3], exp_flies,'filled');
polarscatter(phase_matrix(:), exp_anglePlot(:), [dotSize], exp_angleCount(:),'filled');

title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);



%color bar legend
 max_len = max(exp_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(exp_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
  cb.Position = [0.63 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);

%averages
subplot(plotting.nRows, plotting.nCols, 3);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
hold on
polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
if smooth_avgs
    title('Smoothed Averages');
else
    title('Averages');
end
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
% rlim([30 135]); Rzoom = 'Rzoomin_30-135';
% rlim([30 150]); Rzoom = 'Rzoomin_30-150';
% rlim([20 150]); Rzoom = 'Rzoomin_20-150';
% rlim([0 180]);  Rzoom = 'Rzoomout_0-180'; rticks([0,45,90,135,180])
Rzoom = '';
thetaticks([0, 90, 180, 270]);


hold off

fig = formatFigPolar(fig, false, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned_angleBinned+GRANDmeans_' Rzoom];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase, binned angle + mean (TODO sem) of exp and con data - GRAND MEAN - only first X frames post stim onset
% polarscatter(phase,joint,vector4size,vector4color,'filled');
% 
% leg = 1;
% joint = 3; 
smooth_avgs = 0;
ctl_onlyWithinXFrames = 0; %1= ctl frames are also only those within 150 - 150+X frames in video. 

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 1; 
plotting.nCols = 3; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems

% sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 30; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);
ctl_withinXFrames = ctl_data{leg,joint}(:,4);
exp_withinXFrames = exp_data{leg,joint}(:,4);

%only keep datapoints that are within 50 frames of stim onset
if ctl_onlyWithinXFrames
    ctl_phase_binned = ctl_phase_binned(find(ctl_withinXFrames));
    ctl_joint = ctl_joint(find(ctl_withinXFrames));
    ctl_flies = ctl_flies(find(ctl_withinXFrames));
end
exp_phase_binned = exp_phase_binned(find(exp_withinXFrames));
exp_joint = exp_joint(find(exp_withinXFrames));
exp_flies = exp_flies(find(exp_withinXFrames));

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
angle_bins = [0:2:180];
%make a matrix of phase for plotting 
phase_matrix = phase_bins;
for b = 2:width(angle_bins)-1
   phase_matrix(:,end+1) = phase_bins;
end

%control - grand mean
for f = 1:param.numFlies
    ctl_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(ctl_flies == f);
    this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
    this_fly_joint = ctl_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
%         ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
        if height(ctl_idxs) >= 1
            % enough data points to have a good average, so save data
            ctl_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = this_fly_joint(ctl_idxs)';
        end
    end
    ctl_means(:,f) = nanmean(ctl_byPhase,2);
    ctl_sems(:,f) = sem(ctl_byPhase, 2, nan, 1);
end
%take the grand mean (mean of fly means)
ctl_mean = nanmean(ctl_means,2);
ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%control - binned angle x phase
ctl_byPhase = NaN(height(phase_bins), height(phase_bins));
ctl_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
ctl_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    ctl_idxs = find(ctl_phase_binned == phase_bins(ph));
    ctl_dataPerPhase(ph) = height(ctl_idxs); %how many data points per frame
    ctl_theseAngles = ctl_joint(ctl_idxs)';
    ctl_byPhase(ph,1:width(ctl_joint(ctl_idxs)')) = ctl_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(ctl_theseAngles > angle_bins(b) & ctl_theseAngles <= angle_bins(b+1));
       if isempty(count)
           ctl_anglePlot(ph,b) = NaN;
           ctl_angleCount(ph,b) = NaN;
       else
           ctl_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           ctl_angleCount(ph,b) = sum(count);
       end
       
    end
end
% ctl_mean = nanmean(ctl_byPhase,2);
% ctl_sem = sem(ctl_byPhase, 2, nan, height(unique(ctl_flies)));

%experimenal - grand mean 
for f = 1:param.numFlies
    exp_byPhase = NaN(height(phase_bins), 50000); 
    this_fly_idxs = find(exp_flies == f);
    this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
    this_fly_joint = exp_joint(this_fly_idxs);
    for ph = 1:height(phase_bins)
        exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
%         exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
        if height(exp_idxs) >= 1
            % enough data points to have a good average, so save data
            exp_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = this_fly_joint(exp_idxs)';
        end
    end
    exp_means(:,f) = nanmean(exp_byPhase,2);
    exp_sems(:,f) = sem(exp_byPhase, 2, nan, 1);
end
%take the grand mean (mean of fly means)
exp_mean = nanmean(exp_means,2);
exp_sem = sem(exp_byPhase, 2, nan, height(unique(exp_flies)));

%experimental - binned angle x phase 
exp_byPhase = NaN(height(phase_bins), height(phase_bins));
exp_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
exp_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    exp_idxs = find(exp_phase_binned == phase_bins(ph));
    exp_dataPerPhase(ph) = height(exp_idxs); %how many data points per frame
    exp_theseAngles = exp_joint(exp_idxs)';
    exp_byPhase(ph,1:width(exp_joint(exp_idxs)')) = exp_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(exp_theseAngles > angle_bins(b) & exp_theseAngles <= angle_bins(b+1));
       if isempty(count)
           exp_anglePlot(ph,b) = NaN;
           exp_angleCount(ph,b) = NaN;
       else
           exp_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           exp_angleCount(ph,b) = sum(count);
       end
       
    end
end
% exp_mean = nanmean(exp_byPhase,2);
% exp_sem = sem(exp_byPhase, 2, nan, height(unique(ctl_flies)));


%control
subplot(plotting.nRows, plotting.nCols,1);
% polarscatter(ctl_phase_binned, ctl_joint, [3], ctl_flies,'filled');
polarscatter(phase_matrix(:), ctl_anglePlot(:), [dotSize], ctl_angleCount(:),'filled');

title('Control')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


%color bar legend
 max_len = max(ctl_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(ctl_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
  cb.Position = [0.35 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);


%experimental
subplot(plotting.nRows, plotting.nCols,2); 
% polarscatter(exp_phase_binned, exp_joint, [3], exp_flies,'filled');
polarscatter(phase_matrix(:), exp_anglePlot(:), [dotSize], exp_angleCount(:),'filled');

title('Experimental')
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);



%color bar legend
 max_len = max(exp_angleCount, [], 'all'); max_len_str = num2str(max_len);
 min_len = min(exp_angleCount, [], 'all'); min_len_str = num2str(min_len);
 mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
%  cb = colorbar('Ticks',[0, 0.5, 1],...
%      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 cb = colorbar('Ticks',[min_len, mid_len, max_len],...
     'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
 pos = get(cb,'Position');
  cb.Position = [0.63 pos(2) pos(3) pos(4)]; % to change its position
%   cb.Label.String = 'Count';
  cb.Label.Color = Color(param.baseColor);

%averages
subplot(plotting.nRows, plotting.nCols, 3);
if smooth_avgs
    ctl_mean_plot = smoothdata(ctl_mean);
    exp_mean_plot = smoothdata(exp_mean);
else
    ctl_mean_plot = ctl_mean;
    exp_mean_plot = exp_mean;
end
polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
hold on
polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
if smooth_avgs
    title('Smoothed Averages');
else
    title('Averages');
end
pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
% rlim([0 180])
% rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


hold off

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase: ' num2str(XFrames) ' frames post stim onset'], 'color', Color(param.baseColor));
han.FontSize = 30;


if ctl_onlyWithinXFrames
    type_str = '_ofALLdata';
else
    type_str = '_ofEXPdata';
end

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned_angleBinned+GRANDmeans_OnlyFirst' num2str(XFrames) 'FramesPostStimOnset' type_str];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase, binned angle + mean (TODO sem) of exp and con data - BY FLY
% leg = 1;
% joint = 3; 
smooth_avgs = 0;
withColorBar = 1;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

fig = fullfig;
plotting.nRows = 3; 
plotting.nCols = param.numFlies; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems ctl_byPhase exp_byPhase ctl_angleCount exp_angleCount ctl_anglePlot exp_anglePlot

% sigdig = 2; sigstep = 0.01; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 15; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
angle_bins = [0:2:180];
%make a matrix of phase for plotting 
phase_matrix = phase_bins;
for b = 2:width(angle_bins)-1
   phase_matrix(:,end+1) = phase_bins;
end

%control data wrangling
for f = 1:param.numFlies
    fly_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
    fly_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
    this_fly_idxs = find(ctl_flies == f);
    this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
    this_fly_joint = ctl_joint(this_fly_idxs);
    fly_byPhase = NaN(height(phase_bins), height(this_fly_joint));

    
    for ph = 1:height(phase_bins)
        ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
        ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
        ctl_theseAngles = this_fly_joint(ctl_idxs)';
        fly_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = ctl_theseAngles;
        for b = 1:width(angle_bins)-1
           count = find(ctl_theseAngles > angle_bins(b) & ctl_theseAngles <= angle_bins(b+1));
           if isempty(count)
               fly_anglePlot(ph,b) = NaN;
               fly_angleCount(ph,b) = NaN;
           else
               fly_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
               fly_angleCount(ph,b) = sum(count);
           end      
        end
    end
    ctl_means{f} = nanmean(fly_byPhase,2);
    ctl_sems{f} = sem(fly_byPhase, 2, nan, height(unique(ctl_flies)));
    ctl_byPhase{f} = fly_byPhase;
    ctl_angleCount{f} = fly_angleCount;
    ctl_anglePlot{f} = fly_anglePlot;
end

%experiemental data wrangling
for f = 1:param.numFlies
    fly_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
    fly_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
    this_fly_idxs = find(exp_flies == f);
    this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
    this_fly_joint = exp_joint(this_fly_idxs);
    fly_byPhase = NaN(height(phase_bins), height(this_fly_joint));
    
    for ph = 1:height(phase_bins)
        exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
        exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
        exp_theseAngles = this_fly_joint(exp_idxs)';
        fly_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = exp_theseAngles;
        for b = 1:width(angle_bins)-1
           count = find(exp_theseAngles > angle_bins(b) & exp_theseAngles <= angle_bins(b+1));
           if isempty(count)
               fly_anglePlot(ph,b) = NaN;
               fly_angleCount(ph,b) = NaN;
           else
               fly_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
               fly_angleCount(ph,b) = sum(count);
           end      
        end
    end
    exp_means{f} = nanmean(fly_byPhase,2);
    exp_sems{f} = sem(fly_byPhase, 2, nan, height(unique(exp_flies)));
    exp_byPhase{f} = fly_byPhase;
    exp_angleCount{f} = fly_angleCount;
    exp_anglePlot{f} = fly_anglePlot;
end

%plot the data
idx = 0;
for f = 1:param.numFlies
    %control
    idx = idx+1;
    subplot(plotting.nRows, plotting.nCols, idx);
    % polarscatter(ctl_phase_binned, ctl_joint, [3], ctl_flies,'filled');
    polarscatter(phase_matrix(:), ctl_anglePlot{f}(:), [dotSize], ctl_angleCount{f}(:),'filled');

    title('Control')
    pax = gca;
    pax.FontSize = 14;
    pax.RColor = Color(param.baseColor);
    pax.ThetaColor = Color(param.baseColor);
    rlim([0 180])
    rticks([0,45,90,135,180])
    thetaticks([0, 90, 180, 270]);

    if withColorBar
        %color bar legend
         max_len = max(ctl_angleCount{f}, [], 'all'); max_len_str = num2str(max_len);
         min_len = min(ctl_angleCount{f}, [], 'all'); min_len_str = num2str(min_len);
         mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
        %  cb = colorbar('Ticks',[0, 0.5, 1],...
        %      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
         cb = colorbar('Ticks',[min_len, mid_len, max_len],...
             'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
         pos = get(cb,'Position');
    %       cb.Position = [0.35 pos(2) pos(3) pos(4)]; % to change its position
        %   cb.Label.String = 'Count';
          cb.Label.Color = Color(param.baseColor);
    end

    %experimental
    subplot(plotting.nRows, plotting.nCols,idx+param.numFlies); 
    % polarscatter(exp_phase_binned, exp_joint, [3], exp_flies,'filled');
    polarscatter(phase_matrix(:), exp_anglePlot{f}(:), [dotSize], exp_angleCount{f}(:),'filled');

    title('Experimental')
    pax = gca;
    pax.FontSize = 14;
    pax.RColor = Color(param.baseColor);
    pax.ThetaColor = Color(param.baseColor);
    rlim([0 180])
    rticks([0,45,90,135,180])
    thetaticks([0, 90, 180, 270]);
    
    if withColorBar 
        %color bar legend
         max_len = max(exp_angleCount{f}, [], 'all'); max_len_str = num2str(max_len);
         min_len = min(exp_angleCount{f}, [], 'all'); min_len_str = num2str(min_len);
         mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
        %  cb = colorbar('Ticks',[0, 0.5, 1],...
        %      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
         cb = colorbar('Ticks',[min_len, mid_len, max_len],...
             'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
         pos = get(cb,'Position');
    %       cb.Position = [0.63 pos(2) pos(3) pos(4)]; % to change its position
        %   cb.Label.String = 'Count';
          cb.Label.Color = Color(param.baseColor);
    end

    %averages
    subplot(plotting.nRows, plotting.nCols, idx+param.numFlies+param.numFlies);
    if smooth_avgs
        ctl_mean_plot = smoothdata(ctl_means{f});
        exp_mean_plot = smoothdata(exp_means{f});
    else
        ctl_mean_plot = ctl_means{f};
        exp_mean_plot = exp_means{f};
    end
    polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
    hold on
    polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
    if smooth_avgs
        title('Smoothed Averages');
    else
        title('Averages');
    end
    pax = gca;
    pax.FontSize = 14;
    pax.RColor = Color(param.baseColor);
    pax.ThetaColor = Color(param.baseColor);
    if param.sameAxes
        rlim([0 180])
        rticks([0,45,90,135,180])
    end
    thetaticks([0, 90, 180, 270]);

    hold off
end

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned_angleBinned+means_byFLY'];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if withColorBar; fig_name = [fig_name, '_wColorBar']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.sameAxes; fig_name = [fig_name, '_sameAxes']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT joint x phase, binned phase, binned angle + mean (TODO sem) of exp and con data - BY FLY - only first X frames post stim onset
% leg = 1;
% joint = 3; 
smooth_avgs = 0;
withColorBar = 0;

leg_str = param.legs{leg};
joint_str = param.joints{joint};

ctl_onlyWithinXFrames = 0;

fig = fullfig;
plotting.nRows = 3; 
plotting.nCols = param.numFlies; 
clear ctl_mean ctl_means ctl_sem ctl_sems exp_mean exp_means exp_sem exp_sems ctl_byPhase exp_byPhase ctl_angleCount exp_angleCount ctl_anglePlot exp_anglePlot

% sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig
% if sigdig == 1; dotSize = 15; elseif sigdig == 2; dotSize = 3; end

ctl_phase_binned = round(ctl_data{leg,joint}(:,2),sigdig);
exp_phase_binned = round(exp_data{leg,joint}(:,2),sigdig);
ctl_joint = ctl_data{leg,joint}(:,1);
exp_joint = exp_data{leg,joint}(:,1);
ctl_flies = ctl_data{leg,joint}(:,3);
exp_flies = exp_data{leg,joint}(:,3);
ctl_withinXFrames = ctl_data{leg,joint}(:,4);
exp_withinXFrames = exp_data{leg,joint}(:,4);

%only keep datapoints that are within 50 frames of stim onset
if ctl_onlyWithinXFrames
    ctl_phase_binned = ctl_phase_binned(find(ctl_withinXFrames));
    ctl_joint = ctl_joint(find(ctl_withinXFrames));
    ctl_flies = ctl_flies(find(ctl_withinXFrames));
end
exp_phase_binned = exp_phase_binned(find(exp_withinXFrames));
exp_joint = exp_joint(find(exp_withinXFrames));
exp_flies = exp_flies(find(exp_withinXFrames));

%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
angle_bins = [0:2:180];
%make a matrix of phase for plotting 
phase_matrix = phase_bins;
for b = 2:width(angle_bins)-1
   phase_matrix(:,end+1) = phase_bins;
end

%control data wrangling
for f = 1:param.numFlies
    fly_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
    fly_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
    this_fly_idxs = find(ctl_flies == f);
    this_fly_phase_binned = ctl_phase_binned(this_fly_idxs);
    this_fly_joint = ctl_joint(this_fly_idxs);
    fly_byPhase = NaN(height(phase_bins), height(this_fly_joint));

    for ph = 1:height(phase_bins)
        ctl_idxs = find(this_fly_phase_binned == phase_bins(ph));
        ctl_dataPerPhase(ph,f) = height(ctl_idxs); %how many data points per frame
        ctl_theseAngles = this_fly_joint(ctl_idxs)';
        fly_byPhase(ph,1:width(this_fly_joint(ctl_idxs)')) = ctl_theseAngles;
        for b = 1:width(angle_bins)-1
           count = find(ctl_theseAngles > angle_bins(b) & ctl_theseAngles <= angle_bins(b+1));
           if isempty(count)
               fly_anglePlot(ph,b) = NaN;
               fly_angleCount(ph,b) = NaN;
           else
               fly_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
               fly_angleCount(ph,b) = sum(count);
           end      
        end
    end
    ctl_means{f} = nanmean(fly_byPhase,2);
    ctl_sems{f} = sem(fly_byPhase, 2, nan, height(unique(ctl_flies)));
    ctl_byPhase{f} = fly_byPhase;
    ctl_angleCount{f} = fly_angleCount;
    ctl_anglePlot{f} = fly_anglePlot;
end

%experiemental data wrangling
for f = 1:param.numFlies
%     fly_byPhase = NaN(height(phase_bins), height(phase_bins));
    fly_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
    fly_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
    this_fly_idxs = find(exp_flies == f);
    this_fly_phase_binned = exp_phase_binned(this_fly_idxs);
    this_fly_joint = exp_joint(this_fly_idxs);
    fly_byPhase = NaN(height(phase_bins), height(this_fly_joint));

    for ph = 1:height(phase_bins)
        exp_idxs = find(this_fly_phase_binned == phase_bins(ph));
        exp_dataPerPhase(ph,f) = height(exp_idxs); %how many data points per frame
        exp_theseAngles = this_fly_joint(exp_idxs)';
        fly_byPhase(ph,1:width(this_fly_joint(exp_idxs)')) = exp_theseAngles;
        for b = 1:width(angle_bins)-1
           count = find(exp_theseAngles > angle_bins(b) & exp_theseAngles <= angle_bins(b+1));
           if isempty(count)
               fly_anglePlot(ph,b) = NaN;
               fly_angleCount(ph,b) = NaN;
           else
               fly_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
               fly_angleCount(ph,b) = sum(count);
           end      
        end
    end
    exp_means{f} = nanmean(fly_byPhase,2);
    exp_sems{f} = sem(fly_byPhase, 2, nan, height(unique(exp_flies)));
    exp_byPhase{f} = fly_byPhase;
    exp_angleCount{f} = fly_angleCount;
    exp_anglePlot{f} = fly_anglePlot;
end

%plot the data
idx = 0;
for f = 1:param.numFlies
    %control
    idx = idx+1;
    subplot(plotting.nRows, plotting.nCols, idx);
    % polarscatter(ctl_phase_binned, ctl_joint, [3], ctl_flies,'filled');
    polarscatter(phase_matrix(:), ctl_anglePlot{f}(:), [dotSize], ctl_angleCount{f}(:),'filled');

    title('Control')
    pax = gca;
    pax.FontSize = 14;
    pax.RColor = Color(param.baseColor);
    pax.ThetaColor = Color(param.baseColor);
    rlim([0 180])
    rticks([0,45,90,135,180])
    thetaticks([0, 90, 180, 270]);

    if withColorBar
        %color bar legend
         max_len = max(ctl_angleCount{f}, [], 'all'); max_len_str = num2str(max_len);
         min_len = min(ctl_angleCount{f}, [], 'all'); min_len_str = num2str(min_len);
         mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
        %  cb = colorbar('Ticks',[0, 0.5, 1],...
        %      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
         cb = colorbar('Ticks',[min_len, mid_len, max_len],...
             'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
         pos = get(cb,'Position');
    %       cb.Position = [0.35 pos(2) pos(3) pos(4)]; % to change its position
        %   cb.Label.String = 'Count';
          cb.Label.Color = Color(param.baseColor);
    end

    %experimental
    subplot(plotting.nRows, plotting.nCols,idx+param.numFlies); 
    % polarscatter(exp_phase_binned, exp_joint, [3], exp_flies,'filled');
    polarscatter(phase_matrix(:), exp_anglePlot{f}(:), [dotSize], exp_angleCount{f}(:),'filled');

    title('Experimental')
    pax = gca;
    pax.FontSize = 14;
    pax.RColor = Color(param.baseColor);
    pax.ThetaColor = Color(param.baseColor);
    rlim([0 180])
    rticks([0,45,90,135,180])
    thetaticks([0, 90, 180, 270]);
    
    if withColorBar 
        %color bar legend
         max_len = max(exp_angleCount{f}, [], 'all'); max_len_str = num2str(max_len);
         min_len = min(exp_angleCount{f}, [], 'all'); min_len_str = num2str(min_len);
         mid_len = ceil((max_len - min_len)/2); mid_len_str = num2str(mid_len);
        %  cb = colorbar('Ticks',[0, 0.5, 1],...
        %      'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
         cb = colorbar('Ticks',[min_len, mid_len, max_len],...
             'TickLabels',{min_len_str, mid_len_str, max_len_str}, 'color', Color(param.baseColor));
         pos = get(cb,'Position');
    %       cb.Position = [0.63 pos(2) pos(3) pos(4)]; % to change its position
        %   cb.Label.String = 'Count';
          cb.Label.Color = Color(param.baseColor);
    end

    %averages
    subplot(plotting.nRows, plotting.nCols, idx+param.numFlies+param.numFlies);
    if smooth_avgs
        ctl_mean_plot = smoothdata(ctl_means{f});
        exp_mean_plot = smoothdata(exp_means{f});
    else
        ctl_mean_plot = ctl_means{f};
        exp_mean_plot = exp_means{f};
    end
    polarplot(phase_bins, ctl_mean_plot, 'color', Color(param.baseColor), 'lineWidth', 2);
    hold on
    polarplot(phase_bins, exp_mean_plot, 'color', Color(param.expColor), 'lineWidth', 2);
    if smooth_avgs
        title('Smoothed Averages');
    else
        title('Averages');
    end
    pax = gca;
    pax.FontSize = 14;
    pax.RColor = Color(param.baseColor);
    pax.ThetaColor = Color(param.baseColor);
    if param.sameAxes
        rlim([0 180])
        rticks([0,45,90,135,180])
    end
    thetaticks([0, 90, 180, 270]);

    hold off
end

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, [leg_str ' ' joint_str ' angle by step phase'], 'color', Color(param.baseColor));
han.FontSize = 30;


if ctl_onlyWithinXFrames
    type_str = '_ofALLdata';
else
    type_str = '_ofEXPdata';
end

%Save!
fig_name = [leg_str ' ' joint_str ' angle by step phase_phaseBinned_angleBinned+means_byFLY_OnlyFirst' num2str(XFrames) 'FramesPostStimOnset' type_str];
fig_name = [fig_name, ['_sigdig_' num2str(sigdig) '_sigstep_' num2str(sigstep)]];
if myPhase; fig_name = [fig_name, '_myPhase']; 
else fig_name = [fig_name, '_hilbertPhase']; end
if withColorBar; fig_name = [fig_name, '_wColorBar']; end
if smooth_avgs; fig_name = [fig_name, '_smoothAvgs']; end
if param.sameAxes; fig_name = [fig_name, '_sameAxes']; end
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% NEW Joint x Phase %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%basically I'm just doing it by walking bout here instead of by step b/c
%idk if doing it by step was actually right... it didn't look like smooth
%walking data. 

%% Choose a leg and joint and get the appropriate indices into walking struct

leg = 1; 
joint = 3; 
data_idx = [param.legs{leg} '_' param.joints{joint}];
phase_idx = [data_idx '_phase'];

%% Plot a single step over phase

fig = fullfig;
bout = 1;
step = 3;
phase_data = walking.bouts{bout}.(phase_idx);
joint_data = walking.bouts{bout}.(data_idx);

%get peaks of bout and select step 
[max_pks, max_locs, ~, ~] = findpeaks(joint_data, 'MinPeakProminence', 10);
step_data = joint_data(max_locs(step):max_locs(step+1));
step_phase = phase_data(max_locs(step):max_locs(step+1));

%plot the step
polarplot(step_phase, step_data); hold on;

%plot min and max points 
polarscatter(phase_data(max_locs(step)), max_pks(step), [], 'filled');
[min_pks, min_locs, ~, ~] = findpeaks(step_data*-1, 'MinPeakProminence', 10);
polarscatter(step_phase(min_locs), min_pks*-1, [], 'filled');

pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor); 
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


hold off;
fig = formatFigPolar(fig, true); %black background 


%Save!
fig_name = [strrep(data_idx, '_', ' ') ' single step - bout ' num2str(bout) ' step ' num2str(step)];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Plot a single walking bout over phase

fig = fullfig;
bout = 2;
trim = 3; %trim this number of frames off start/end of bout to have a cleaner plot
phase_data = walking.bouts{bout}.(phase_idx)(trim:end-trim);
joint_data = walking.bouts{bout}.(data_idx)(trim:end-trim);
polarplot(phase_data, joint_data); hold on;

pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


hold off;
fig = formatFigPolar(fig, true); %black background 


%Save!
fig_name = [strrep(data_idx, '_', ' ') ' walking bout ' num2str(bout)];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


% 
% %Trying to plot the line with color = time... but it's pretty hard. 
% % Convert data coordinates to cartesian: 
% phase_data = walking.bouts{bout}.(phase_idx);
% joint_data = walking.bouts{bout}.(data_idx);
% [x,y] = pol2cart(phase_data, joint_data);
% t = [1:height(y)]';
% LineWidth = 1;
% % Matlab does not have a function to plot color-gradient lines. So we trick Matlab 
% % by plotting a surface:
% h = surface([x';x'],[y';y'],[ones(size(x'));ones(size(x'))],[t';t'],...
%         'facecolor','none',...
%         'edgecolor','interp',...
%         'linewidth',LineWidth);    

%This function has a workaround using 'surface'... i've messed with the
%function a bit but it's kinda useful. 
% spiral(walking.bouts{bout}.(phase_idx)(1:end-1), walking.bouts{bout}.(data_idx)(1:end-1));

%% Plot a single walking bout over phase - with peaks!

fig = fullfig;
bout = 1;
trim = 3; %trim this number of frames off start/end of bout to have a cleaner plot
phase_data = walking.bouts{bout}.(phase_idx)(trim:end-trim);
joint_data = walking.bouts{bout}.(data_idx)(trim:end-trim);
polarplot(phase_data, joint_data); hold on;

[max_pks, max_locs, max_w, max_p] = findpeaks(joint_data, 'MinPeakProminence', 10);
polarscatter(phase_data(max_locs), joint_data(max_locs), [], 'filled');

[min_pks, min_locs, min_w, min_p] = findpeaks(joint_data*-1, 'MinPeakProminence', 10);
polarscatter(phase_data(min_locs), joint_data(min_locs), [], 'filled');

pax = gca;
pax.FontSize = 14;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);


hold off;
fig = formatFigPolar(fig, true); %black background 

% han=axes(fig,'visible','off'); 
% han.Title.Visible='on';
% title(han, [strrep(data_idx, '_', ' ') ' walking bout with peaks'], 'color', Color(param.baseColor));
% han.FontSize = 20;

%Save!
fig_name = [strrep(data_idx, '_', ' ') ' walking bout ' num2str(bout) ' with peaks'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

% 
% %Trying to plot the line with color = time... but it's pretty hard. 
% % Convert data coordinates to cartesian: 
% phase_data = walking.bouts{bout}.(phase_idx);
% joint_data = walking.bouts{bout}.(data_idx);
% [x,y] = pol2cart(phase_data, joint_data);
% t = [1:height(y)]';
% LineWidth = 1;
% % Matlab does not have a function to plot color-gradient lines. So we trick Matlab 
% % by plotting a surface:
% h = surface([x';x'],[y';y'],[ones(size(x'));ones(size(x'))],[t';t'],...
%         'facecolor','none',...
%         'edgecolor','interp',...
%         'linewidth',LineWidth);    

%This function has a workaround using 'surface'... i've messed with the
%function a bit but it's kinda useful. 
% spiral(walking.bouts{bout}.(phase_idx)(1:end-1), walking.bouts{bout}.(data_idx)(1:end-1));

%% Plot many walking bouts over phase - with peaks!

fig = fullfig;
plotting.nRows = 10; 
plotting.nCols = 10; 
numBouts = height(walking.bouts);


for bout = 1:100
    subplot(plotting.nRows, plotting.nCols,bout);

    trim = 3; %trim this number of frames off start/end of bout to have a cleaner plot
    phase_data = walking.bouts{bout}.(phase_idx)(trim:end-trim);
    joint_data = walking.bouts{bout}.(data_idx)(trim:end-trim);
    polarplot(phase_data, joint_data); hold on;

    [max_pks, max_locs, max_w, max_p] = findpeaks(joint_data, 'MinPeakProminence', 10);
    polarscatter(phase_data(max_locs), joint_data(max_locs), [], 'filled');

    [min_pks, min_locs, min_w, min_p] = findpeaks(joint_data*-1, 'MinPeakProminence', 10);
    polarscatter(phase_data(min_locs), joint_data(min_locs), [], 'filled');

    pax = gca;
    pax.FontSize = 8;
    pax.RColor = Color(param.baseColor);
    pax.ThetaColor = Color(param.baseColor);
    rlim([0 180])
    rticks([0,180])
    thetaticks([0, 180]);


    hold off;
    
end
    fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]); %black background 

    % han=axes(fig,'visible','off'); 
    % han.Title.Visible='on';
    % title(han, [strrep(data_idx, '_', ' ') ' walking bout with peaks'], 'color', Color(param.baseColor));
    % han.FontSize = 20;

    %Save!
    fig_name = [strrep(data_idx, '_', ' ') ' walking ' num2str(bout) ' bouts with peaks'];
    save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Peaks and troughs x phase (DENSITY PLOT)

%get all peaks and troughs from walking bouts, and corresponding phases
peak_joint = [];
peak_phase = [];
trough_joint = [];
trough_phase = [];
for bout = 1:height(walking.bouts)
    trim = 3; %trim this number of frames off start/end of bout to have a cleaner plot
    phase_data = walking.bouts{bout}.(phase_idx)(trim:end-trim);
    joint_data = walking.bouts{bout}.(data_idx)(trim:end-trim);

    [max_pks, max_locs, max_w, max_p] = findpeaks(joint_data, 'MinPeakProminence', 10);
    [min_pks, min_locs, min_w, min_p] = findpeaks(joint_data*-1, 'MinPeakProminence', 10);
    
    peak_joint = [peak_joint; joint_data(max_locs)]; 
    peak_phase = [peak_phase; phase_data(max_locs)]; 
    trough_joint = [trough_joint; joint_data(min_locs)]; 
    trough_phase = [trough_phase; phase_data(min_locs)];
end

%bin phase and angle to compute density 

sigdig = 1; sigstep = 0.1; %sigstep should be rounded to sigdig
% sigdig = 2; sigstep = 0.01; %sigstep should be rounded to sigdig
if sigdig == 1; dotSize = 20; elseif sigdig == 2; dotSize = 3; end

peak_phase_binned = round(peak_phase, sigdig);
trough_phase_binned = round(trough_phase, sigdig);


%calculate mean joint data across phase
phase_bins = round([-3.14:sigstep:3.14]',sigdig);
angle_bins = [0:2:180];
%make a matrix of phase for plotting 
phase_matrix = phase_bins;
for b = 2:width(angle_bins)-1
   phase_matrix(:,end+1) = phase_bins;
end

%PEAK density 
peak_byPhase = NaN(height(phase_bins), height(phase_bins));
peak_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
peak_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    peak_idxs = find(peak_phase_binned == phase_bins(ph));
    peak_dataPerPhase(ph) = height(peak_idxs); %how many data points per frame
    peak_theseAngles = peak_joint(peak_idxs)';
    peak_byPhase(ph,1:width(peak_joint(peak_idxs)')) = peak_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(peak_theseAngles > angle_bins(b) & peak_theseAngles <= angle_bins(b+1));
       if isempty(count)
           peak_anglePlot(ph,b) = NaN;
           peak_angleCount(ph,b) = NaN;
       else
           peak_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           peak_angleCount(ph,b) = sum(count);
       end
       
    end
end

%TROUGH density 
trough_byPhase = NaN(height(phase_bins), height(phase_bins));
trough_angleCount = NaN(height(phase_bins), width(angle_bins)-1); %Num data in ea. phase/angle bin 
trough_anglePlot = NaN(height(phase_bins), width(angle_bins)-1); %NaN or angle bin to plot
for ph = 1:height(phase_bins)
    trough_idxs = find(trough_phase_binned == phase_bins(ph));
    trough_dataPerPhase(ph) = height(trough_idxs); %how many data points per frame
    trough_theseAngles = trough_joint(trough_idxs)';
    trough_byPhase(ph,1:width(trough_joint(trough_idxs)')) = trough_theseAngles;
    for b = 1:width(angle_bins)-1
       count = find(trough_theseAngles > angle_bins(b) & trough_theseAngles <= angle_bins(b+1));
       if isempty(count)
           trough_anglePlot(ph,b) = NaN;
           trough_angleCount(ph,b) = NaN;
       else
           trough_anglePlot(ph,b) = (angle_bins(b) + angle_bins(b+1))/2; 
           trough_angleCount(ph,b) = sum(count);
       end
       
    end
end


%plot
fig = fullfig;
plotting.nRows = 1;
plotting.nCols = 2;

subplot(plotting.nRows,plotting.nCols,1);
polarscatter(phase_matrix(:), peak_anglePlot(:), [dotSize], peak_angleCount(:),'filled');
title('Peaks')
pax = gca;
pax.FontSize = 20;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

subplot(plotting.nRows,plotting.nCols,2);
polarscatter(phase_matrix(:), trough_anglePlot(:), [dotSize], trough_angleCount(:),'filled');
title('Troughs')
pax = gca;
pax.FontSize = 20;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
rlim([0 180])
rticks([0,45,90,135,180])
thetaticks([0, 90, 180, 270]);

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]); %black background 

%Save!
fig_name = [strrep(data_idx, '_', ' ') ' walking bout peaks and troughs x phase (DENSITY)'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Peaks and troughs x phase (HISTOGRAM PLOT)

%get all peaks and troughs from walking bouts, and corresponding phases
peak_phase = [];
trough_phase = [];
for bout = 1:height(walking.bouts)
    trim = 3; %trim this number of frames off start/end of bout to have a cleaner plot
    phase_data = walking.bouts{bout}.(phase_idx)(trim:end-trim);
    joint_data = walking.bouts{bout}.(data_idx)(trim:end-trim);

    [max_pks, max_locs, max_w, max_p] = findpeaks(joint_data, 'MinPeakProminence', 10);
    [min_pks, min_locs, min_w, min_p] = findpeaks(joint_data*-1, 'MinPeakProminence', 10);
    
    peak_phase = [peak_phase; phase_data(max_locs)]; 
    trough_phase = [trough_phase; phase_data(min_locs)];
end

%plot
fig = fullfig;
plotting.nRows = 1;
plotting.nCols = 2;

subplot(plotting.nRows,plotting.nCols,1);
% histogram(peak_phase, 100);
polarhistogram(peak_phase,100);
title('Peaks')
pax = gca;
pax.FontSize = 20;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
thetaticks([0, 45, 90, 135, 180, 225, 270,315]);

subplot(plotting.nRows,plotting.nCols,2);
% histogram(trough_phase, 100);
polarhistogram(trough_phase, 100);
title('Troughs')
pax = gca;
pax.FontSize = 20;
pax.RColor = Color(param.baseColor);
pax.ThetaColor = Color(param.baseColor);
thetaticks([0, 45, 90, 135, 180, 225, 270, 315]);

fig = formatFigPolar(fig, true, [plotting.nRows, plotting.nCols]); %black background 

%Save!
fig_name = [strrep(data_idx, '_', ' ') ' walking bout peaks and troughs x phase (HISTOGRAM)'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% Offset btw troughs of joint data and troughs of phase, and btw peaks of joint data and zeros of phase
% look to see if the offsets are gaussian 


%get all peaks and troughs from walking bouts, and corresponding phases
peak_offsets = [];
trough_offsets = [];
for bout = 1:height(walking.bouts)
    trim = 3; %trim this number of frames off start/end of bout to have a cleaner plot
    phase_data = walking.bouts{bout}.(phase_idx)(trim:end-trim);
    joint_data = walking.bouts{bout}.(data_idx)(trim:end-trim);

     [max_j_pks, max_j_locs, max_j_w, max_j_p] = findpeaks(joint_data, 'MinPeakProminence', 10);
    [min_j_pks, min_j_locs, min_j_w, min_j_p] = findpeaks(joint_data*-1, 'MinPeakProminence', 10);
    
    [max_p_pks, max_p_locs, max_p_w, max_p_p] = findpeaks(abs(phase_data)*-1, 'MinPeakProminence', 3);
    [min_p_pks, min_p_locs, min_p_w, min_p_p] = findpeaks(phase_data*-1, 'MinPeakProminence', 3);
    
    if height(min_j_locs) == height(min_p_locs)
        trough_offsets = [trough_offsets; min_j_locs - min_p_locs];
    end
    if height(max_j_locs) == height(max_p_locs)
        peak_offsets = [peak_offsets; max_j_locs - max_p_locs];
    end
    
end

%plot
fig = fullfig;
plotting.nRows = 1;
plotting.nCols = 2;

subplot(plotting.nRows,plotting.nCols,1);
histogram(peak_offsets, 100);
title('Peak offsets')

subplot(plotting.nRows,plotting.nCols,2);
histogram(trough_offsets, 100);
title('Trough offsets')


fig = formatFig(fig, true, [plotting.nRows, plotting.nCols]); %black background 

%Save!
fig_name = [strrep(data_idx, '_', ' ') ' walking bout joint troughs & peaks offsets from phase peaks & zeros (HISTOGRAM)'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% Phase Offsets %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CALCULATE Phase offsets between legs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars('-except',initial_vars{:});
initial_vars = who;

comp_leg = 4; %comparison leg 
T2_rot = 1; %1 if use rotation phase for T2 legs, 0 if use angle phase like T1 and T3 legs (results are much better when T2_rot == 1)
joint = 3; jnt_str = param.joints{joint}; %joint phase to compare TODO compare rotation for T2? TODO do tarsi y postition instead?

trim = 3; %frames to trim off beginning and end of walking bout for better data quality 
   
phase_offsets = NaN(1,8);
start_idx = 0; 
for bout = 1:height(walking.bouts)
    %get unwrapped phase for comparison leg
    ph_idx = [param.legs{comp_leg} '_' param.joints{joint} '_phase'];
    comp_phase = unwrap(walking.bouts{bout}.(ph_idx));
     
    for leg = 1:6
        if T2_rot & (leg == 2 | leg == 5)
            ph_idx = [param.legs{leg} 'B_rot_phase']; % Be careful! I only have rotation for B (CF) joint
        else
            ph_idx = [param.legs{leg} '_' param.joints{joint} '_phase'];
        end
        this_phase = unwrap(walking.bouts{bout}.(ph_idx));
        ph_offset = comp_phase - this_phase;
        h = height(ph_offset);
        phase_offsets(start_idx+1:start_idx+h, leg) = ph_offset;
    end
    
    %add stim vs control (0 = control, 1 = stim)
    this_laser = walking.meta.boutinfo(bout).laser;
    laser_endIdx = param.laser_on +(param.fps * this_laser);
    bout_startIdx = walking.meta.boutinfo(bout).startIdx;
    bout_endIdx = walking.meta.boutinfo(bout).endIdx;
    condition = zeros(h,1);
    if this_laser == 0 | bout_startIdx >= laser_endIdx | bout_endIdx <= param.laser_on
        condition = zeros(h,1);
    else
        condition = zeros(h,1);
        %the laser is on for some portion of the walking bout 
        startStim = max(param.laser_on, bout_startIdx); 
        endStim = min(laser_endIdx, bout_endIdx);
        endStim = endStim - startStim+1; %convert from idx in vid to idx in bout
        startStim = startStim - startStim+1;
        condition(startStim:endStim,1) = 1;
    end
    phase_offsets(start_idx+1:start_idx+h, 7) = condition;  
    
    %add fly number
    phase_offsets(start_idx+1:start_idx+h, 8) = ones(h,1)*walking.meta.boutinfo(bout).flyNum;  

    
    start_idx = start_idx + h;
end

%% PLOT phase offsets across flies 
fig = fullfig;
param.nRows = 2; 
param.nCols = 3;
phase_table = array2table(phase_offsets); 
phase_table.Properties.VariableNames = {'L1','L2','L3','R1','R2','R3','stimOn','fly'};
order = [4,5,6,1,2,3];
for leg = 1:6
    subplot(param.nRows, param.nCols, order(leg));
    h1 = polarhistogram(phase_table{phase_table.stimOn == 0,leg}, 'Normalization', 'pdf'); hold on;
    h2 = polarhistogram(phase_table{phase_table.stimOn == 1,leg}, 'Normalization', 'pdf'); 
    h1.FaceColor = param.baseColor;
    h2.FaceColor = Color(param.expColor);
    title(param.legs(leg));
    pax = gca;
    pax.FontSize = 14;
    pax.RColor = Color(param.baseColor);
    pax.ThetaColor = Color(param.baseColor); 
    thetaticks([0, 90, 180, 270]);
    hold off;
end

fig = formatFigPolar(fig, true, [param.nRows, param.nCols]);


%Save!
fig_name = ['Phase offsets from ' param.legs{comp_leg}];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT phase offsets for each fly 
fly = 5 ; % alter this to plot different flies 

fig = fullfig;
param.nRows = 2; 
param.nCols = 3;
phase_table = array2table(phase_offsets); 
phase_table.Properties.VariableNames = {'L1','L2','L3','R1','R2','R3','stimOn','fly'};
order = [4,5,6,1,2,3];
for leg = 1:6
    subplot(param.nRows, param.nCols, order(leg));
    h1 = polarhistogram(phase_table{phase_table.stimOn == 0 & phase_table.fly == fly,leg}, 'Normalization', 'pdf'); hold on;
    h2 = polarhistogram(phase_table{phase_table.stimOn == 1 & phase_table.fly == fly,leg}, 'Normalization', 'pdf'); 
    h1.FaceColor = param.baseColor;
    h2.FaceColor = Color(param.expColor);
    title(param.legs(leg));
    pax = gca;
    pax.FontSize = 14;
    pax.RColor = Color(param.baseColor);
    pax.ThetaColor = Color(param.baseColor); 
    thetaticks([0, 90, 180, 270]);
    hold off;
end

fig = formatFigPolar(fig, true, [param.nRows, param.nCols]);

%Save!
fig_name = ['Phase offsets from ' param.legs{comp_leg} ' fly ' num2str(fly)];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% AEP & PEP %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get AEP and PEP for all steps 





%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% Gait Analysis %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Calculate phase 

through_exp = []; %walking bouts through stim onset (portion before stim)
through_con = []; %walking bouts through stim onset (portion after stim)
through_stim = {}; % phase of L1 at stim onset.
before_con = []; %walking bouts before stim onset
after_exp = []; %walking bouts after stim onset

through_stim_idx = 0;
for bout = 1:height(walking.bouts)
    this_bout = walking.bouts{bout};
    this_bout_meta = walking.meta.boutinfo(bout);
    
    if this_bout_meta.laser == 0 | this_bout_meta.endIdx <= param.laser_on %TODO make just < ?
        % walking bout occured before stim onset(or no laser in this trial)
        [~, before_con] = [before_con; DLC_phase_hilbertTransform(this_bout, walking.meta.bout_labels)];
        
    elseif this_bout_meta.startIdx >= param.laser_on %TODO make just > ?
        % walking bout occured after stim onset
        [~, after_exp] = [after_exp; DLC_phase_hilbertTransform(this_bout, walking.meta.bout_labels)];

    else % walking bout occured through stim onset 
        stim_on_frame = param.laser_on - this_bout_meta.startIdx;
        [~, through_con] = [through_con; DLC_phase_hilbertTransform(this_bout(1:stim_on_frame-1,:), walking.meta.bout_labels)];
        [~, through_exp] = [through_exp; DLC_phase_hilbertTransform(this_bout(stim_on_frame:end,:), walking.meta.bout_labels)];
        % save L1 phase at stim onset 
        L1_FTi_angle_data = this_bout{:,3};
        L1_diff = diff(L1_FTi_angle_data); 
        through_stim_idx = through_stim_idx+1;
        if L1_diff(stim_on_frame) >= 0 
            through_stim{through_stim_idx} = 'swing'; 
        else
            through_stim{through_stim_idx} = 'stance'; 
        end
    end
end
%remove nans (places where L1 didn't take steps)
before_con = before_con(~isnan(before_con(:,1)),:);
after_exp = after_exp(~isnan(after_exp(:,1)),:);
through_con = through_con(~isnan(through_con(:,1)),:);
through_exp = through_exp(~isnan(through_exp(:,1)),:);

%% PLOT phase: all bouts (histogram)
fig = fullfig;
plotting.subplot_order = [1,3,5,2,4,6];
plotting.subplot_titles = {'L1', 'L2', 'L3', 'R1', 'R2', 'R3'};
plotting.nRows = 3;
plotting.nCols = 2;
for leg = 1:6
    subplot(plotting.nRows,plotting.nCols,plotting.subplot_order(leg)); hold on
    edges = (0:5:360);
    all_con = [before_con(:,leg); through_con(:,leg)];
    all_exp = [after_exp(:,leg); through_exp(:,leg)];
    histogram(all_con, edges, 'Normalization', 'probability', 'FaceColor', 'white', 'EdgeColor', 'white');
    histogram(all_exp, edges, 'Normalization', 'probability', 'FaceColor', 'cyan', 'EdgeColor', 'white');
    
    %label plot
    title(plotting.subplot_titles{leg});
    xticks([0 90 180 270 360])
    axis tight 
    if leg == 1
        xlabel(['Offset (' char(176) ')']) 
%         legend('pre stim onset', 'post stim onset');
    elseif leg == 2
        ylabel('Probability') 
    end
    
    hold off
end

fig = formatFig(fig, true, [plotting.nRows, plotting.nCols]);

%full figure title
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, 'Phase Offset: all bouts');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))


%save
fig_name = '\phase_overview_allBouts';
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT phase: bouts during stim onset (histogram)
fig = fullfig;
plotting.subplot_order = [1,3,5,2,4,6];
plotting.subplot_titles = {'L1', 'L2', 'L3', 'R1', 'R2', 'R3'};
plotting.nRows = 3;
plotting.nCols = 2;
for leg = 1:6
    subplot(plotting.nRows,plotting.nCols,plotting.subplot_order(leg)); hold on
    edges = [0:5:360];
    histogram(through_con(:,leg), edges, 'Normalization', 'probability', 'FaceColor', 'white', 'EdgeColor', 'white');
    histogram(through_exp(:,leg), edges, 'Normalization', 'probability', 'FaceColor', 'cyan', 'EdgeColor', 'white');
    title(plotting.subplot_titles{leg});
    
    %label plot
    title(plotting.subplot_titles{leg});
    xticks([0 90 180 270 360])
    axis tight 
    if leg == 1
        xlabel(['Offset (' char(176) ')']) 
    elseif leg == 2
        ylabel('Probability') 
    end
    
    hold off
end

fig = formatFig(fig, true, [plotting.nRows, plotting.nCols]);

%full figure title
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, 'Phase Offset: bouts during stim onset');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

%save
fig_name = '\phase_overview_stimBouts';
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT phase: all bouts PDF
fig = fullfig;
plotting.subplot_order = [1,3,5,2,4,6];
plotting.subplot_titles = {'L1', 'L2', 'L3', 'R1', 'R2', 'R3'};
plotting.nRows = 3;
plotting.nCols = 2;
for leg = 1:6
    subplot(plotting.nRows,plotting.nCols,plotting.subplot_order(leg)); hold on
    edges = (0:5:360);
    all_con = [before_con(:,leg); through_con(:,leg)];
    all_exp = [after_exp(:,leg); through_exp(:,leg)];
    
    
    pd_kernel_con = fitdist(all_con,'Kernel');
    pd_kernel_exp = fitdist(all_exp,'Kernel');
    
    x = 0:1:360;
    pdf_kernel_con = pdf(pd_kernel_con,x);
    pdf_kernel_exp = pdf(pd_kernel_exp,x);

    plot(x,pdf_kernel_con,'Color','white','LineWidth',2);
    plot(x,pdf_kernel_exp,'Color','cyan','LineWidth',2);
%     
%     histogram(all_con, edges, 'Normalization', 'probability', 'FaceColor', 'white', 'EdgeColor', 'white');
%     histogram(all_exp, edges, 'Normalization', 'probability', 'FaceColor', 'cyan', 'EdgeColor', 'white');
    
    %label plot
    title(plotting.subplot_titles{leg});
    xticks([0 90 180 270 360])
    axis tight 
    if leg == 1
        xlabel(['Offset (' char(176) ')']) 
%         legend('pre stim onset', 'post stim onset');
    elseif leg == 2
        ylabel('PDF') 
    end
    
    hold off
end

fig = formatFig(fig, true, [plotting.nRows, plotting.nCols]);

%full figure title
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, 'Phase Offset: all bouts');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))


%save
fig_name = '\phase_overview_allBouts_PDF';
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT phase: bouts during stim onset PDF
fig = fullfig;
plotting.subplot_order = [1,3,5,2,4,6];
plotting.subplot_titles = {'L1', 'L2', 'L3', 'R1', 'R2', 'R3'};
plotting.nRows = 3;
plotting.nCols = 2;
for leg = 1:6
    subplot(plotting.nRows,plotting.nCols,plotting.subplot_order(leg)); hold on
    edges = [0:5:360];
    
    
    pd_kernel_con = fitdist(through_con(:,leg),'Kernel');
    pd_kernel_exp = fitdist(through_exp(:,leg),'Kernel');
    
    x = 0:1:360;
    pdf_kernel_con = pdf(pd_kernel_con,x);
    pdf_kernel_exp = pdf(pd_kernel_exp,x);

    plot(x,pdf_kernel_con,'Color','white','LineWidth',2);
    plot(x,pdf_kernel_exp,'Color','cyan','LineWidth',2);
% %     
%     
%     histogram(through_con(:,leg), edges, 'Normalization', 'probability', 'FaceColor', 'white', 'EdgeColor', 'white');
%     histogram(through_exp(:,leg), edges, 'Normalization', 'probability', 'FaceColor', 'cyan', 'EdgeColor', 'white');
    title(plotting.subplot_titles{leg});
    
    %label plot
    title(plotting.subplot_titles{leg});
    xticks([0 90 180 270 360])
    axis tight 
    if leg == 1
        xlabel(['Offset (' char(176) ')']) 
    elseif leg == 2
        ylabel('PDF') 
    end
    
    hold off
end

fig = formatFig(fig, true, [plotting.nRows, plotting.nCols]);

%full figure title
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, 'Phase Offset: bouts during stim onset');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

%save
fig_name = '\phase_overview_stimBouts_PDF';
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% Behavior Analysis %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Determine behavior at stim onset (by bout number)
% behavior_byBout = DLC_behavior_predictor_byBoutNum(data, param);

%% PLOT mean and sem joint angles for each behavior (indicate n trials)

leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};
joint = 3; jnt = [leg_str '_FTi']; joint_str = param.joints{joint};

behaviorNames = param.columns(find(contains(param.columns,'bout_num')));
behaviorNames = strrep(behaviorNames, '_bout_number', '');  
numBehaviors = width(find(contains(param.columns,'bout_num')));
numValidBehaviors = 0; 

%DATA WRANGLING
for bb = 1:numBehaviors
    %get vid idxs with this behavior
    all_data = {behavior_byBout.data{:,find(contains(behavior_byBout.labels, 'preBehavior'))}};
    this_behavior_idxs = find(contains(all_data, behaviorNames{bb}));
    if isempty(this_behavior_idxs); enough_vids = false; 
    else; enough_vids = true; end
    
    %select vid rows with this behavior at stim onset
    this_behaviordata = behavior_byBout.data(this_behavior_idxs,:);
    
    
    %filter out behaviors with no vids for some laser lengths
    this_behavior_conds = [this_behaviordata{:,find(contains(behavior_byBout.labels, 'cond'))}];
    this_behavior_lasers = param.laserIdx(this_behavior_conds); 
    this_behavior_uniqueLasers = unique(this_behavior_lasers);
    if width(this_behavior_uniqueLasers) < param.numLasers | width(this_behavior_lasers) < 30
        enough_vids = false;
    end
    
    %save info needed for plotting
    if enough_vids
        numValidBehaviors = numValidBehaviors +1; 
        validBehaviors(numValidBehaviors) = bb;
        all_behaviordata{numValidBehaviors} = this_behaviordata;
    end
end

%DATA PLOTTING
fig = fullfig;
pltIdx = 0;
AX = [];
param.nRows = numValidBehaviors; 
param.nCols = param.numLasers;
for bb = 1:numValidBehaviors
    behaviordata = all_behaviordata{bb};
%     if enough_vids
        for laser = 1:param.numLasers
           pltIdx = pltIdx+1;
           light_on = 0;
           light_off =(param.fps*param.lasers{laser})/param.fps;
           AX(pltIdx) = subplot(param.nRows, param.nCols, pltIdx); hold on;
           %extract the joint data 
           jntIdx = find(contains(columns, jnt));

           %plot the data!
           all_data = NaN(height(behaviordata), param.vid_len_f);
           num_vids = 0;
           for vid = 1:height(behaviordata)
              if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
                  num_vids = num_vids + 1;
                  start_idx = behaviordata{vid,9};
                  end_idx = behaviordata{vid,10};

                  d = data{start_idx:end_idx, jntIdx};
                  if height(d == 600)
                      a = d(param.laser_on);
                      d = d-a;
                      all_data(vid, :) = d;
                  end
              end
           end
           numVids(joint, laser) = num_vids;
           %calculate mean and standard error of the mean 
           yMean = nanmean(all_data, 1);
           ySEM = sem(all_data, 1, nan, height(flyList));

           %plot
           p = plot(param.x, yMean, 'color', Color(param.jointColors{joint}), 'linewidth', 1.5);
           fill_data = error_fill(param.x, yMean, ySEM);
           h = fill(fill_data.X, fill_data.Y, get_color(param.jointColors{joint}), 'EdgeColor','none');
           set(h, 'facealpha',param.jointFillWeights{joint});


           if param.xlimit; xlim(param.xlim); end
           if param.ylimit; ylim(param.ylim); end


           % laser region 
           if param.sameAxes
               %save light length for plotting after syching lasers
               light_ons(pltIdx) = light_on;
               light_offs(pltIdx) = light_off;
           else
               y1 = rangeLine(fig);
               pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
           end

           %label
           if mod((pltIdx+param.numLasers-1),5) == 0
               ylabel(strrep(behaviorNames{validBehaviors(bb)}, '_', ' '));
           end
           if pltIdx == 1
               xlabel('Time (s)');
               title('0 sec');
           elseif pltIdx == 2
               title('0.03 sec');
           elseif pltIdx == 3
               title('0.1 sec');
           elseif pltIdx == 4
               title('0.33 sec');
           elseif pltIdx == 5    
               title('1 sec');
           end
%            TextLocation('N=','Location','best');
           text(0.8,1,['n = ' num2str(num_vids)],'Units','normalized', 'color', Color(param.baseColor));

           hold off;
        end
%     end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.nRows, param.nCols, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, true, [param.nRows, param.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 FTi Aligned Joint Angle Mean & SEM');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))


%save
fig_name = [leg_str ' ' joint_str ' _angle_overview_mean+sem_forAllBehaviors'];
if param.xlimit; fig_name = [fig_name, '_Xzoom']; end
if param.ylimit; fig_name = [fig_name, '_Yzoom']; end
if param.filter; fig_name = [fig_name, '_filtered']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% Behavior Analysis %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%% PLOT mean and sem joint angles for walking by phase of stim onset (indicate n trials)

% Find indices in data for all vids where fly has desired behavior
[behaviordata, enough_vids] = DLC_selectBehaviorData(behavior_byBout, 'Walking', 'Any', 'NaN');
% initial_vars = who;
% clearvars('-except',initial_vars{:}); initial_vars = who;
%% PLOT ALL joints, all lasers, one leg - mean and sem jnt angle x PHASE at stim onset 
leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};

% fig = figure;
fig = fullfig;
pltIdx = 0;
AX = [];
c = parula;
for joint = 1:param.numJoints
   for laser = 1:param.numLasers
       pltIdx = pltIdx+1;
       light_on = 0;
       light_off =(param.fps*param.lasers{laser})/param.fps;
       AX(pltIdx) = subplot(param.numJoints, param.numLasers, pltIdx); hold on;
       %extract the joint data 
       if joint == 1; jnt = [leg_str '_BC'];
       elseif joint == 2; jnt = [leg_str '_CF'];
       elseif joint == 3; jnt = [leg_str '_FTi'];
       elseif joint == 4; jnt = [leg_str '_TiTa'];
       end
       jntIdx = find(contains(columns, jnt));
       
       
       %plot the data!
       for vid = 1:height(behaviordata)
          if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
              start_idx = behaviordata{vid,9};
              end_idx = behaviordata{vid,10};
              phase = behaviordata{vid, 8};
              %get color for phase
              if phase < 0; phase = phase + (2*pi); end
              percentPhase = phase/(2*pi); 
              colorIdx = round(percentPhase * height(c));

              vid_data = data{start_idx:end_idx, jntIdx};
              if height(vid_data == 600)                plot(param.x, vid_data, 'color', c(colorIdx,:)); 
              end
          end
       end
       
       if param.xlimit; xlim(param.xlim); end
       if param.ylimit; ylim(param.ylim); end
       
       % laser region 
       if param.sameAxes
           %save light length for plotting after syching lasers
           light_ons(pltIdx) = light_on;
           light_offs(pltIdx) = light_off;
       else
           y1 = rangeLine(fig);
           pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
       end
       
       %label
       if pltIdx == 1
           ylabel(['BC (' char(176) ')']);
           xlabel('Time (s)');
           title('0 sec');
       elseif pltIdx == 2
           title('0.03 sec');
       elseif pltIdx == 3
           title('0.1 sec');
       elseif pltIdx == 4
           title('0.33 sec');
       elseif pltIdx == 5    
           title('1 sec');
       elseif pltIdx == 6
           ylabel(['CF (' char(176) ')']);
       elseif pltIdx == 11
           ylabel(['FTi (' char(176) ')']);
       elseif pltIdx == 16
            ylabel(['TiTa (' char(176) ')']);
       end
       hold off;
   end
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.numJoints, param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, param.darkFig, [param.numJoints, param.numLasers]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Raw Joint Angles');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

fig_name = ['\' param.legs{leg} '_overview_' preBehavior '2' postBehavior 'PHASEPHASEPHASE'];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT ONE joint, all lasers, one leg - mean and sem jnt angle x PHASE at stim onset 
leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};

% fig = figure;
fig = fullfig;
pltIdx = 0;
AX = [];
c = parula;
phases4color = linspace(-pi,pi,height(c));
joint = 3; joint_str = param.joints{joint};
param.nRows = 5;
param.nCols = 1;
for laser = 1:param.numLasers
   pltIdx = pltIdx+1;
   light_on = 0;
   light_off =(param.fps*param.lasers{laser})/param.fps;
   AX(pltIdx) = subplot(param.nRows, param.nCols, pltIdx); hold on;
   %extract the joint data 
   if joint == 1; jnt = [leg_str '_BC'];
   elseif joint == 2; jnt = [leg_str '_CF'];
   elseif joint == 3; jnt = [leg_str '_FTi'];
   elseif joint == 4; jnt = [leg_str '_TiTa'];
   end
   jntIdx = find(contains(columns, jnt));


   %plot the data!
   for vid = 1:height(behaviordata)
      if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
          start_idx = behaviordata{vid,9};
          end_idx = behaviordata{vid,10};
          phase = behaviordata{vid, 8};
          %get color for phase
%           [~,colorIdx] = (min(abs(phases4color - phase)));
          
%           phase = phase + pi;
           if phase < 0; phase = phase + (2*pi); end
           percentPhase = phase/(2*pi); 
%           if percentPhase < 0
%               percentPhase = percentPhase +1; 
%           end

          colorIdx = round(percentPhase * height(c));
          
          if colorIdx == 0
              colorIdx = 1;
          end

          vid_data = data{start_idx:end_idx, jntIdx};
          if height(vid_data == 600)           
              plot(param.x, vid_data, 'color', c(colorIdx,:)); 
          end
      end
   end

   if param.xlimit; xlim(param.xlim); end
   if param.ylimit; ylim(param.ylim); end

   % laser region 
   if param.sameAxes
       %save light length for plotting after syching lasers
       light_ons(pltIdx) = light_on;
       light_offs(pltIdx) = light_off;
   else
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
   end

   %label
   if pltIdx == 1
       ylabel([ leg_str '' joint_str ' (' char(176) ')']);
       xlabel('Time (s)');
       title('0 sec');
   elseif pltIdx == 2
       title('0.03 sec');
   elseif pltIdx == 3
       title('0.1 sec');
   elseif pltIdx == 4
       title('0.33 sec');
   elseif pltIdx == 5    
       title('1 sec');
   elseif pltIdx == 6
%        ylabel(['CF (' char(176) ')']);
   elseif pltIdx == 11
%        ylabel(['FTi (' char(176) ')']);
   elseif pltIdx == 16
%         ylabel(['TiTa (' char(176) ')']);
   end
   hold off;
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.nRows, param.nCols, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, param.darkFig, [param.nRows, param.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Raw Joint Angles');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

 %color bar legend
 cb = colorbar('Ticks',[0, 0.5, 1],...
         'TickLabels',{'stance (flexion) start', 'stance end/swing start', 'swing (extension) end'}, 'color', Color(param.baseColor));
     pos = get(cb,'Position');
       cb.Position = [0.93 pos(2) pos(3) pos(4)]; % to change its position
    %   cb.Label.String = 'Count';
      cb.Label.Color = Color(param.baseColor);


fig_name = ['\' leg_str '_' joint_str '_walking_colorByPHASE'];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT ONE joint, all lasers, one leg - mean and sem jnt angle x PHASE at stim onset - XZOOM
leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};

% fig = figure;
fig = fullfig;
pltIdx = 0;
AX = [];
c = parula;
joint = 3;
param.nRows = 5;
param.nCols = 1;
xlimit = [-0.2, 0.5];
for laser = 1:param.numLasers
   pltIdx = pltIdx+1;
   light_on = 0;
   light_off =(param.fps*param.lasers{laser})/param.fps;
   AX(pltIdx) = subplot(param.nRows, param.nCols, pltIdx); hold on;
   %extract the joint data 
   if joint == 1; jnt = [leg_str '_BC'];
   elseif joint == 2; jnt = [leg_str '_CF'];
   elseif joint == 3; jnt = [leg_str '_FTi'];
   elseif joint == 4; jnt = [leg_str '_TiTa'];
   end
   jntIdx = find(contains(columns, jnt));


   %plot the data!
   for vid = 1:height(behaviordata)
      if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
          start_idx = behaviordata{vid,9};
          end_idx = behaviordata{vid,10};
          phase = behaviordata{vid, 8};
          %get color for phase
          if phase < 0; phase = phase + (2*pi); end
           percentPhase = phase/(2*pi); 
%           if percentPhase < 0
%               percentPhase = percentPhase +1; 
%           end

          colorIdx = round(percentPhase * height(c));
          
          if colorIdx == 0; colorIdx = 1; end

          vid_data = data{start_idx:end_idx, jntIdx};
          if height(vid_data == 600)                
              plot(param.x, vid_data, 'color', c(colorIdx,:)); 
          end
      end
   end

   xlim(xlimit); 

   % laser region 
   if param.sameAxes
       %save light length for plotting after syching lasers
       light_ons(pltIdx) = light_on;
       light_offs(pltIdx) = light_off;
   else
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
   end

   %label
   if pltIdx == 1
       ylabel(['BC (' char(176) ')']);
       xlabel('Time (s)');
       title('0 sec');
   elseif pltIdx == 2
       title('0.03 sec');
   elseif pltIdx == 3
       title('0.1 sec');
   elseif pltIdx == 4
       title('0.33 sec');
   elseif pltIdx == 5    
       title('1 sec');
   elseif pltIdx == 6
       ylabel(['CF (' char(176) ')']);
   elseif pltIdx == 11
       ylabel(['FTi (' char(176) ')']);
   elseif pltIdx == 16
        ylabel(['TiTa (' char(176) ')']);
   end
   hold off;
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.nRows, param.nCols, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, param.darkFig, [param.nRows, param.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Raw Joint Angles');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

 %color bar legend
 cb = colorbar('Ticks',[0, 0.5, 1],...
         'TickLabels',{'0', '\pi', '2\pi'}, 'color', Color(param.baseColor));
     pos = get(cb,'Position');
       cb.Position = [0.93 pos(2) pos(3) pos(4)]; % to change its position
    %   cb.Label.String = 'Count';
      cb.Label.Color = Color(param.baseColor);


fig_name = ['\' leg_str '_' joint_str '_walking_colorByPHASE_Zoomed'];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT ONE joint, all lasers, one leg - mean and sem jnt angle x PHASE at stim onset - PHASE BINNED
leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};

% fig = figure;
fig = fullfig;
pltIdx = 0;
AX = [];
c = parula;
joint = 3;
param.nRows = 5;
param.nCols = 1;
xlimit = [-0.1, 0.2];
phaseBins = [(-pi-0.01):(pi/8):pi];
for laser = 1:param.numLasers
   pltIdx = pltIdx+1;
   light_on = 0;
   light_off =(param.fps*param.lasers{laser})/param.fps;
   AX(pltIdx) = subplot(param.nRows, param.nCols, pltIdx); hold on;
   %extract the joint data 
   if joint == 1; jnt = [leg_str '_BC'];
   elseif joint == 2; jnt = [leg_str '_CF'];
   elseif joint == 3; jnt = [leg_str '_FTi'];
   elseif joint == 4; jnt = [leg_str '_TiTa'];
   end
   jntIdx = find(contains(columns, jnt));


   %plot the data!
   for ph = 1:width(phaseBins)-1
       this_phase_idx = 0;
       for vid = 1:height(behaviordata)
          if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
              start_idx = behaviordata{vid,9};
              end_idx = behaviordata{vid,10};
              phase = behaviordata{vid, 8};
              if phase > phaseBins(ph) & phase <= phaseBins(ph+1)
                  this_phase_idx = this_phase_idx + 1;
                  vid_data = data{start_idx:end_idx, jntIdx};
                  binned_phase(:,this_phase_idx) = vid_data;
              end
          end
       end
       %mean and sem for steps in this phase
       mean_trace = nanmean(binned_phase, 2);
       
       
      %get color for phase
      percentPhase = ph/(width(phaseBins)-1); 
      colorIdx = round(percentPhase * height(c));

      if height(vid_data == 600)                
          plot(param.x, mean_trace, 'color', c(colorIdx,:)); 
      end

   end

%    xlim(xlimit); 

   % laser region 
   if param.sameAxes
       %save light length for plotting after syching lasers
       light_ons(pltIdx) = light_on;
       light_offs(pltIdx) = light_off;
   else
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
   end

   %label
   if pltIdx == 1
       ylabel(['BC (' char(176) ')']);
       xlabel('Time (s)');
       title('0 sec');
   elseif pltIdx == 2
       title('0.03 sec');
   elseif pltIdx == 3
       title('0.1 sec');
   elseif pltIdx == 4
       title('0.33 sec');
   elseif pltIdx == 5    
       title('1 sec');
   elseif pltIdx == 6
       ylabel(['CF (' char(176) ')']);
   elseif pltIdx == 11
       ylabel(['FTi (' char(176) ')']);
   elseif pltIdx == 16
        ylabel(['TiTa (' char(176) ')']);
   end
   hold off;
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.nRows, param.nCols, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, param.darkFig, [param.nRows, param.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Raw Joint Angles');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

 %color bar legend
 cb = colorbar('Ticks',[0, 0.5, 1],...
         'TickLabels',{'0', '\pi', '2\pi'}, 'color', Color(param.baseColor));
     pos = get(cb,'Position');
       cb.Position = [0.93 pos(2) pos(3) pos(4)]; % to change its position
    %   cb.Label.String = 'Count';
      cb.Label.Color = Color(param.baseColor);


fig_name = ['\' param.legs{leg} '_overview_' preBehavior '2' postBehavior];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%% PLOT ONE joint, all lasers, one leg - mean and sem jnt angle x ANGLE at stim onset 
leg = 1; legs = {'L1' 'L2' 'L3' 'R1' 'R2' 'R3'}; leg_str = legs{leg};

% fig = figure;
fig = fullfig;
pltIdx = 0;
AX = [];
c = parula;
joint = 3;
param.nRows = 5;
param.nCols = 1;
jointAtStims = [behaviordata{:, 7}];
maxJnt = max(jointAtStims);
minJnt = min(jointAtStims);
for laser = 1:param.numLasers
   pltIdx = pltIdx+1;
   light_on = 0;
   light_off =(param.fps*param.lasers{laser})/param.fps;
   AX(pltIdx) = subplot(param.nRows, param.nCols, pltIdx); hold on;
   %extract the joint data 
   if joint == 1; jnt = [leg_str '_BC'];
   elseif joint == 2; jnt = [leg_str '_CF'];
   elseif joint == 3; jnt = [leg_str '_FTi'];
   elseif joint == 4; jnt = [leg_str '_TiTa'];
   end
   jntIdx = find(contains(columns, jnt));


   %plot the data!
   for vid = 1:height(behaviordata)
      if  param.laserIdx(behaviordata{vid,3}) == laser% check that vid has laser this length.
          start_idx = behaviordata{vid,9};
          end_idx = behaviordata{vid,10};
          joint = behaviordata{vid, 7};
          %get color for phase
          if joint == minJnt
              colorIdx = 1;
          else
              percent = (joint-minJnt)/(maxJnt-minJnt); 
              colorIdx = round(percent * height(c));
          end

          vid_data = data{start_idx:end_idx, jntIdx};
          if height(vid_data == 600)                
              plot(param.x, vid_data, 'color', c(colorIdx,:)); 
          end
      end
   end

   if param.xlimit; xlim(param.xlim); end
   if param.ylimit; ylim(param.ylim); end

   % laser region 
   if param.sameAxes
       %save light length for plotting after syching lasers
       light_ons(pltIdx) = light_on;
       light_offs(pltIdx) = light_off;
   else
       y1 = rangeLine(fig);
       pl = plot([light_on, light_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
   end

   %label
   if pltIdx == 1
       ylabel(['BC (' char(176) ')']);
       xlabel('Time (s)');
       title('0 sec');
   elseif pltIdx == 2
       title('0.03 sec');
   elseif pltIdx == 3
       title('0.1 sec');
   elseif pltIdx == 4
       title('0.33 sec');
   elseif pltIdx == 5    
       title('1 sec');
   elseif pltIdx == 6
       ylabel(['CF (' char(176) ')']);
   elseif pltIdx == 11
       ylabel(['FTi (' char(176) ')']);
   elseif pltIdx == 16
        ylabel(['TiTa (' char(176) ')']);
   end
   hold off;
end

if param.sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:pltIdx  
        subplot(param.nRows, param.nCols, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
        hold off
    end
end

fig = formatFig(fig, param.darkFig, [param.nRows, param.nCols]);

han=axes(fig,'visible','off'); 
han.Title.Visible='on';
title(han, ' L1 Raw Joint Angles');
set(get(gca,'title'),'Position', param.titlePosition, 'FontSize', param.titleFontSize, 'color', Color(param.baseColor))

 %color bar legend
 cb = colorbar('Ticks',[0, 1],...
         'TickLabels',{num2str(minJnt),num2str(maxJnt)}, 'color', Color(param.baseColor));
     pos = get(cb,'Position');
       cb.Position = [0.93 pos(2) pos(3) pos(4)]; % to change its position
    %   cb.Label.String = 'Count';
      cb.Label.Color = Color(param.baseColor);


fig_name = ['\' param.legs{leg} '_overview_' preBehavior '2' postBehavior];
fig_name = format_fig_name(fig_name, param);
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


 

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% COVARIANCE MATRICES %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Covariance matrix for walking data (ANLGES) - ALL conds - All angles

setDiagonalToZero = 1; %1= sets diagonal of C matrix to zero for better colormap scaling. 

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1A_abduct'));
endJnt = find(contains(columns, 'R3_TiTa'));
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

%calculate covariance 
C = cov(jointWalkingData);

if setDiagonalToZero
    %set primary diagonal of C matrix to zero for better color scaling
    C = C - diag(diag(C));
end

%plot covariance matrix
fig = fullfig;
h = heatmap(C); 
h.Title = 'Covariance of joint angles during walking';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
% h.Colormap = parula;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Walking'];
if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% Covariance matrix for walking data (ANLGES) - Ctl vs Stim - All angles

setDiagonalToZero = 0; %1= sets diagonal of C matrix to zero for better colormap scaling. 

% get stim regions (1 = laser on)
stimRegions = DLC_getStimRegions(data, param);

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);
walkingDataStim = stimRegions(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1A_abduct'));
endJnt = find(contains(columns, 'R3_TiTa'));
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

%separate stim vs control regions
jointWalkingDataControl = jointWalkingData((walkingDataStim == 0), :);
jointWalkingDataStim = jointWalkingData((walkingDataStim == 1), :);

%calculate covariance 
Ccontrol = cov(jointWalkingDataControl);
Cstim = cov(jointWalkingDataStim);

if setDiagonalToZero
    %set primary diagonal of C matrix to zero for better color scaling
    Ccontrol = Ccontrol - diag(diag(Ccontrol));
    Cstim = Cstim - diag(diag(Cstim));
end

diffSigns = find(sign(Ccontrol) ~= sign(Cstim));
C = Ccontrol - Cstim; 
C(diffSigns) = -C(diffSigns);

%plot covariance matrix - control
fig = fullfig;
h = heatmap(Ccontrol); 
h.Title = 'Covariance of joint angles during walking (control)';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Walking_Ctl'];
if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


%plot covariance matrix - stim
fig = fullfig;
h = heatmap(Cstim); 
h.Title = 'Covariance of joint angles during walking (stim)';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Walking_Stim'];
if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


%plot covariance matrix - control vs stim 
fig = fullfig;
h = heatmap(C); 
h.Title = 'Covariance of joint angles during walking (control - stim)';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Walking_Ctl_vs_Stim'];
if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% Covariance matrix for walking data (ANLGES) - Ctl vs Stim - FTi angles only 

setDiagonalToZero = 0; %1= sets diagonal of C matrix to zero for better colormap scaling. 

% get stim regions (1 = laser on)
stimRegions = DLC_getStimRegions(data, param);

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);
walkingDataStim = stimRegions(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1_BC'));
endJnt = find(contains(columns, 'R3E_z'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = {'L1_FTi', 'L2B_rot','L3_FTi', 'R1_FTi','R2B_rot','R3_FTi'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
% subData = 1:24; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%invert T3 and T2 signals so peaks correspond to stance start like for T1
invertJnts = find(contains(jointLabels, '3') | contains(jointLabels, 'L2'));

jointWalkingData = table2array(jointWalkingData);
jointWalkingData(:,invertJnts) = jointWalkingData(:,invertJnts)*-1;

%separate stim vs control regions
jointWalkingDataControl = jointWalkingData((walkingDataStim == 0), :);
jointWalkingDataStim = jointWalkingData((walkingDataStim == 1), :);

%noramlize data
%1) subtract mean 
jointWalkingDataControl = jointWalkingDataControl - nanmean(jointWalkingDataControl);
jointWalkingDataStim = jointWalkingDataStim - nanmean(jointWalkingDataStim);
%2) divide by std
jointWalkingDataControl = jointWalkingDataControl ./ nanstd(jointWalkingDataControl);
jointWalkingDataStim = jointWalkingDataStim ./ nanstd(jointWalkingDataStim);


%calculate covariance 
Cctl = cov(jointWalkingDataControl);
Cexp = cov(jointWalkingDataStim);


%plot covariance matrix - control
fig = fullfig;
h = heatmap(Cctl); 
h.Title = 'Covariance of joint angles during walking (control)';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Walking_FTi_angles_Ctl'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


%plot covariance matrix - stim
fig = fullfig;
h = heatmap(Cexp); 
h.Title = 'Covariance of joint angles during walking (stim)';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Covariance_Matix_JointAngles_Walking_FTi_angles_Stim'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

% 
% %plot covariance matrix - control vs stim 
% fig = fullfig;
% h = heatmap(C); 
% h.Title = 'Covariance of joint angles during walking (control - stim)';
% h.XDisplayLabels = jointLabels;
% h.YDisplayLabels = jointLabels;
% h.Colormap = redblue;
% h.FontColor = 'w';
% fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
% %save 
% fig_name = ['\Covariance_Matix_JointAngles_Walking_FTi_angles_Ctl_vs_Stim'];
% if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
% save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% 
clearvars('-except',initial_vars{:}); initial_vars = who;


%% Covariance matrix for walking data (all angles - normalized)
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
subData = {'L1_BC', 'L1_CF', 'L1_FTi', 'L1_TiTa','L2_BC', 'L2_CF', 'L2_FTi', 'L2_TiTa','L3_BC', 'L3_CF', 'L3_FTi', 'L3_TiTa','R1_BC', 'R1_CF', 'R1_FTi', 'R1_TiTa','R2_BC', 'R2_CF', 'R2_FTi', 'R2_TiTa','R3_BC', 'R3_CF', 'R3_FTi', 'R3_TiTa'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
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
fig_name = ['Covariance_Matix_AllAngles_Walking'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% CORRELATION COEFFICIENTS %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Correlation coefficients for walking data (ANGLES) - Ctl vs Stim - All angles 

setDiagonalToZero = 1; %1= sets diagonal of C matrix to zero for better colormap scaling. 

% get stim regions (1 = laser on)
stimRegions = DLC_getStimRegions(data, param);

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);
walkingDataStim = stimRegions(~isnan(data.walking_bout_number),:);

%select joint data from walkingData
startJnt = find(contains(columns, 'L1A_abduct'));
endJnt = find(contains(columns, 'R3_TiTa'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
% allData = 58:219; %all data: joint angles, abductions, rotations, and positions. 
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

%separate stim vs control regions
jointWalkingDataControl = jointWalkingData((walkingDataStim == 0), :);
jointWalkingDataStim = jointWalkingData((walkingDataStim == 1), :);

%calculate correlation coeffs
if setDiagonalToZero
    %set primary diagonal of C matrix to zero for better color scaling
    [Rcontrol,~] = corrcoef(jointWalkingDataControl);
    [Rstim,~] = corrcoef(jointWalkingDataStim);
end

diffSigns = find(sign(Rcontrol) ~= sign(Rstim));
R = Rcontrol - Rstim; 
R(diffSigns) = -R(diffSigns);

if setDiagonalToZero
    %set primary diagonal of C matrix to zero for better color scaling
    R = R - diag(diag(R));
end

%plot covariance matrix - control
fig = fullfig;
h = heatmap(Rcontrol); 
h.Title = 'Correlation coefficients of joint angles during walking (control)';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Correlation_Coefficients_JointAngles_Walking_Ctl'];
if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


%plot covariance matrix - stim
fig = fullfig;
h = heatmap(Rstim); 
h.Title = 'Correlation coefficients of joint angles during walking (stim)';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Correlation_Coefficients_JointAngles_Walking_Stim'];
if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


%plot covariance matrix - control vs stim 
fig = fullfig;
h = heatmap(R); 
h.Title = 'Correlation coefficients of joint angles during walking (control - stim)';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);
%save 
fig_name = ['\Correlation_Coefficients_JointAngles_Walking_Ctl_vs_Stim'];
if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% Correlation coefficients for walking data (ANGLES) - Ctl vs Stim - FTi angles only 

setDiagonalToZero = 1; %1= sets diagonal of C matrix to zero for better colormap scaling. 

% extract walking data
walkingData = data(~isnan(data.walking_bout_number),:);

%select joint data from walkingData

startJnt = find(contains(columns, 'L1A_abduct'));
endJnt = find(contains(columns, 'R3_TiTa'));
allData = startJnt:endJnt; %all data: joint angles, abductions, rotations, and positions. 
% allData = 58:219; %all data: joint angles, abductions, rotations, and positions. 
jointWalkingData = walkingData(:,allData);

%select a subset of joint data
subData = {'L1_FTi', 'L2_FTi', 'L3_FTi', 'R1_FTi', 'R2_FTi', 'R3_FTi'}; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
% subData = 1:24; %only BC,CF, FTi, TiTa joint ANGLES of each leg 
jointWalkingData = jointWalkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%invert T3 and T2 signals so peaks correspond to stance start like for T1
invertJnts = find(contains(jointLabels, '3') | contains(jointLabels, '2'));

jointWalkingData = table2array(jointWalkingData);
jointWalkingData(:,invertJnts) = jointWalkingData(:,invertJnts)*-1;
% jointWalkingData = array2table(jointWalkingData);

%calculate covariance 
[R,P] = corrcoef(jointWalkingData);

if setDiagonalToZero
    %set primary diagonal of C matrix to zero for better color scaling
    R = R - diag(diag(R));
end

% plot covariance matrix
fig = fullfig;
% h = plotmatrix(R); 
h = heatmap(R); 
h.Title = 'Correlation coefficients of joint angles during walking';
h.XDisplayLabels = jointLabels;
h.YDisplayLabels = jointLabels;
% h.Colormap = parula;
h.Colormap = redblue;
h.FontColor = 'w';
fig = formatFig(fig, true, [width(jointLabels), width(jointLabels)]);

%save 
fig_name = ['\Correlation_Coefficients_JointAngles_Walking_FTi_angles'];
if setDiagonalToZero; fig_name = [fig_name '_zeroDiagonal']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;
 


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% JOINT POSITION TRAJECTORIES (IN 3D) %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Basic plotting of joint positions in 3D

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
bout_to_plot = stim_bouts(1);
%get bout indices for plotting
bout_idxs = find(walkingData.walking_bout_number == bout_to_plot);
ctl_bout_idxs = bout_idxs(walkingDataStim(bout_idxs) == 0);
stim_bout_idxs = bout_idxs(walkingDataStim(bout_idxs) == 1);
% divide ctl into pre and post stim 
pre_ctl_bout_idxs = []; post_ctl_bout_idxs = [];
pre_ctl_bout_idxs = [ctl_bout_idxs(ctl_bout_idxs < stim_bout_idxs(1)); stim_bout_idxs(1)]; %append first frame of stim so that the lines will connect 
post_ctl_bout_idxs = [stim_bout_idxs(end); ctl_bout_idxs(ctl_bout_idxs > stim_bout_idxs(end))]; 



%select joint data from walkingData
subData = [columns(contains(columns, '_x')), columns(contains(columns, '_y')),columns(contains(columns, '_z'))];
jointWalkingData = walkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');


fig = fullfig; 
plotting.rows = param.numJoints+1; 
plotting.cols = param.numLegs; 
idx = 1;
for joint = 1:param.numJoints+1 %add one for tarsus tips
    for leg = 1:param.numLegs

% leg = 1; joint = 5;
       dataCols = subData(contains(subData, [param.legs{leg} param.jointLetters{joint}]));
       
       subplot(plotting.rows, plotting.cols, idx);
       %plot pre-stim ctl portion 
       plot3(jointWalkingData.(dataCols{1})(pre_ctl_bout_idxs), jointWalkingData.(dataCols{2})(pre_ctl_bout_idxs), jointWalkingData.(dataCols{3})(pre_ctl_bout_idxs), 'Color', Color(param.backgroundColor), 'LineWidth', 2); hold on;
       %plot stim portion 
       plot3(jointWalkingData.(dataCols{1})(stim_bout_idxs), jointWalkingData.(dataCols{2})(stim_bout_idxs), jointWalkingData.(dataCols{3})(stim_bout_idxs), 'Color', Color(param.laserColor), 'LineWidth', 2);
       %plot post-stim ctl portion 
       plot3(jointWalkingData.(dataCols{1})(post_ctl_bout_idxs), jointWalkingData.(dataCols{2})(post_ctl_bout_idxs), jointWalkingData.(dataCols{3})(post_ctl_bout_idxs), 'Color', Color(param.backgroundColor), 'LineWidth', 2); hold off;

       idx = idx+1;
    end
end






%        clinep(jointWalkingData.(dataCols{1})(bout_idxs), jointWalkingData.(dataCols{2})(bout_idxs), jointWalkingData.(dataCols{3})(bout_idxs), [walkingDataStim(bout_idxs)])









clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot joint positions with the ball.... basic 

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
bout_to_plot = stim_bouts(1);
%get bout indices for plotting
bout_idxs = find(walkingData.walking_bout_number == bout_to_plot);
ctl_bout_idxs = bout_idxs(walkingDataStim(bout_idxs) == 0);
stim_bout_idxs = bout_idxs(walkingDataStim(bout_idxs) == 1);
% divide ctl into pre and post stim 
pre_ctl_bout_idxs = []; post_ctl_bout_idxs = [];
pre_ctl_bout_idxs = [ctl_bout_idxs(ctl_bout_idxs < stim_bout_idxs(1)); stim_bout_idxs(1)]; %append first frame of stim so that the lines will connect 
post_ctl_bout_idxs = [stim_bout_idxs(end); ctl_bout_idxs(ctl_bout_idxs > stim_bout_idxs(end))]; 



%select joint data from walkingData
subData = [columns(contains(columns, '_x')), columns(contains(columns, '_y')),columns(contains(columns, '_z'))];
jointWalkingData = walkingData(:,subData);
jointLabels = strrep(jointWalkingData.Properties.VariableNames, '_', '-');

%Ball fit to joint E position... then plot all data in 3D from there. (need
%offsets of limb segment lengths?) 


%Ball fit to E joint position

ballFitJoint = 5; %tarsus 
LP = ballFitJoint; %leg point = tarsus
rMin = 1.0;     % min radius constraint
rMax = 3.0;     % max radius constraint
thresh = 0.01;  % percent threshold for 'ground'
leg_colors = {'blue', 'red', 'orange', 'purple', 'green', 'cyan'};
for leg = 1:6
   kolor(leg,:) = Color(leg_colors{leg}); 
end
SZ = 20; % size of scatter plot points
LW = 1;         % line width for plots


%get the data for fitting: x, y, z positions of tarsus tip of each leg
the_min = 0; %find min val of all the data for fitting and move all data into a positive space
for leg = 1:param.numLegs
   dataCols = subData(contains(subData, [param.legs{leg} param.jointLetters{ballFitJoint}]));
   ballFitData(leg).raw = [jointWalkingData.(dataCols{1}), jointWalkingData.(dataCols{2}), jointWalkingData.(dataCols{3})];
   the_min = min(min(ballFitData(leg).raw(:)), the_min);
end
%move all data into a positive space
for leg = 1:param.numLegs
   ballFitData(leg).raw = ballFitData(leg).raw + abs(the_min);
end

%isolate stance regions and quadruple those points in the dataset for best fitting. 
for leg = 1:param.numLegs
    ballFitData(leg).stance = ballFitData(leg).raw(diff(ballFitData(leg).raw(:,2)) <= 0, :);
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
% 
% trial(cond,rep).cloud = cloud;
% trial(cond,rep).Center = Center;
% trial(cond,rep).Radius = Radius;

set(0,'DefaultFigureVisible','on');  %Turn figures back on:
% --- Figure of ball with full step cycles ---- 
LW = 1.5;

%left plot with the data on the ball 
fig = getfig;
subplot(1,2,1)
for leg = 1:6
    input = ballFitData(leg).raw;
    plot3(input(:,1), input(:,2), input(:,3), 'linewidth', LW, 'color', kolor(leg,:)); hold on
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



%right plot of data close up with stance in grey swing in color
R = Radius*(1+thresh); % increase threshold
% find the distance from the center of the sphere to the tarsus and greater
% than the radius value equates to swing:
subplot(1,2,2)
for leg = 1:6
    input = ballFitData(leg).raw;
    e_dist = pdist2(Center,input);
    stance_loc = e_dist<=R;
    swing_loc = e_dist>R; 
    scatter3(input(stance_loc,1),input(stance_loc,2),input(stance_loc,3), SZ, Color('grey'), 'filled')
    hold on
    scatter3(input(swing_loc,1),input(swing_loc,2),input(swing_loc,3), SZ, kolor(leg,:), 'filled')
end
title(['Walking bout ' num2str(bout_to_plot)], 'color', param.baseColor);
axis vis3d % sets the aspect ratio for 3d rotation
ax = gca;               % get the current axis
ax.Clipping = 'off';


fig = formatFig(fig, true);





clearvars('-except',initial_vars{:}); initial_vars = who;



% 
% fig = fullfig; 
% plotting.rows = param.numJoints+1; 
% plotting.cols = param.numLegs; 
% idx = 1;
% for joint = 1:param.numJoints+1 %add one for tarsus tips
%     for leg = 1:param.numLegs
% 
% % leg = 1; joint = 5;
%        dataCols = subData(contains(subData, [param.legs{leg} param.jointLetters{joint}]));
%        
%        subplot(plotting.rows, plotting.cols, idx);
%        %plot pre-stim ctl portion 
%        plot3(jointWalkingData.(dataCols{1})(pre_ctl_bout_idxs), jointWalkingData.(dataCols{2})(pre_ctl_bout_idxs), jointWalkingData.(dataCols{3})(pre_ctl_bout_idxs), 'Color', Color(param.backgroundColor), 'LineWidth', 2); hold on;
%        %plot stim portion 
%        plot3(jointWalkingData.(dataCols{1})(stim_bout_idxs), jointWalkingData.(dataCols{2})(stim_bout_idxs), jointWalkingData.(dataCols{3})(stim_bout_idxs), 'Color', Color(param.laserColor), 'LineWidth', 2);
%        %plot post-stim ctl portion 
%        plot3(jointWalkingData.(dataCols{1})(post_ctl_bout_idxs), jointWalkingData.(dataCols{2})(post_ctl_bout_idxs), jointWalkingData.(dataCols{3})(post_ctl_bout_idxs), 'Color', Color(param.backgroundColor), 'LineWidth', 2); hold off;
% 
%        idx = idx+1;
%     end
% end

%% Plot joint positions with the ball.... better plotting


%%%%%%%%%%%%%%%%%%%%%%%%%%% PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%TODO currently cannot have laser_indicated for datatypes 1 and 2... 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% how much data to plot
data_type = 3; %1 = all data, 2 = a region of data, 3 = one walking bout
if data_type == 2
    startFrame = 100;
    endFrame = 600;
elseif data_type == 3
    boutType = 'stim'; %'stim' = bout with stim in int, 'control'  = bout without stim in it
    boutNum = 661; %53; 
end
% indicate the laser region?
laser_indicated = 1; %1 = color stim region param.laserColor, 0 = don't color stim region 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
if (data_type == 1) & laser_indicated
    %TODO 
    
elseif (data_type == 2) & laser_indicated
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
        if laser_indicated
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
        if ~laser_indicated %plotting without indicating laser
            if data_type == 1 %plot all data
                plot3(input(:,1), input(:,2), input(:,3), 'linewidth', LW, 'color', [[kolor(:,joint,leg)]', alpha]); hold on
            elseif data_type == 2 %plot region of data
                plot3(input(startFrame:endFrame,1), input(startFrame:endFrame,2), input(startFrame:endFrame,3), 'linewidth', LW, 'color', [[kolor(:,joint,leg)]', alpha]); hold on
            elseif data_type == 3 %plot bout of data
                plot3(input(bout_idxs,1), input(bout_idxs,2), input(bout_idxs,3), 'linewidth', LW, 'color', [[kolor(:,joint,leg)]', alpha]); hold on
            end 
        elseif laser_indicated %plotting wtih indicating laser
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

% title(['Walking bout ' num2str(bout_to_plot)], 'color', param.baseColor);

% clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot in a video 

%%%%%%%%%%%%%%%%%%%%%% PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
leg_colors = {'blue', 'red', 'orange', 'purple', 'green', 'cyan'}; %each leg has its own color
plottingFrames = 38500:38800;
joint = 5;
fadeOut = 1; %1 = delete plotted data after some time so that I can plot lots of data and not have it occlude itself
fadeLimit = 500; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%fit the ball and get formatted data for plotting 
[Center, Radius, ballFitData] = DLC_ballFit(data, param);

%PLOT
fig = fullfig;

%plot the ball
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

for leg = 1:param.numLegs
    %get animated lines for each leg 
    animatedLines(leg) = animatedline(ax, 'Color', Color(leg_colors(leg))); 
    %get the data for each leg
    draw(leg).data = ballFitData(leg).(param.legNodes{joint})(plottingFrames,:);
end

%plot data on ball 
for frame = 1:height(draw(1).data) 
    set(gca,'visible','off') %turn off axes
    %plot frame for each leg 
    for leg = 1:param.numLegs
        if frame > fadeLimit
           %get current points, clear animation, and add all but the last data point
           [x,y,z] = getpoints(animatedLines(leg));
           clearpoints(animatedLines(leg));
           addpoints(animatedLines(leg), x(2:end), y(2:end), z(2:end));
        end
        addpoints(animatedLines(leg), draw(leg).data(frame,1), draw(leg).data(frame,2), draw(leg).data(frame,3));
    end
    drawnow
%     pause(0.1); %control plotting speed
end
    




%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% VELOCITY %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Plot avg speed for each laser condition when fly is walking at stim onset

normalize = 1; %normalize to speed at stim onset. So y axis is change in speed. 

%speed is in radians/frame. Ball radius is 4.495 mm. Fictrac is 30 fps.
%so speed in mm/s = (data.speed * 4.495 * 30)
speed = data.speed * 4.495 * 30;

vidStarts = find(data.fnum == 0);
vidLasers = data.stimlen(vidStarts);

fig = fullfig;
for laser = 1:param.numLasers
    laserVids = vidStarts(round(vidLasers, 2) == round(param.lasers{laser}, 2));
    laserData = [];
    for vid = 1:height(laserVids)
        if ~isnan(data.walking_bout_number(laserVids(vid))) %only look at flies walking at stim onset
            if normalize
                laserData(vid,:) = (speed(laserVids(vid):laserVids(vid)+param.vid_len_f-1))-(speed(laserVids(vid)+param.laser_on));
            else
                laserData(vid,:) = speed(laserVids(vid):laserVids(vid)+param.vid_len_f-1);
            end
        else 
            laserData(vid,:) = NaN(1,param.vid_len_f);
        end
    end
    speedMean(laser,:) = nanmean(laserData);
    speedSEM(laser,:) = sem(laserData, 1, nan, height(flyList));
    
    AX(laser) = subplot(1, param.numLasers, laser); hold on;
           
   %plot
   legendPlot(laser) = plot(param.x, speedMean(laser,:), 'linewidth', 2);
   fill_data = error_fill(param.x, speedMean(laser,:), speedSEM(laser,:));
   h = fill(fill_data.X, fill_data.Y, get_color('blue'), 'EdgeColor','none');
   set(h, 'facealpha',0.4); 
   
   %save light length for plotting after syching lasers
   light_on = 0;
   light_off =(param.fps*param.lasers{laser})/param.fps;
   light_ons(laser) = light_on;
   light_offs(laser) = light_off;
           
   %save num trials for legend 
   numTrials(laser) = sum(~isnan(laserData(:,1)));
   hold off;
end

% make all axes the same
allYLim = get(AX, {'YLim'});
allYLim = cat(2, allYLim{:});
set(AX, 'YLim', [min(allYLim), max(allYLim)]);

y1 = rangeLine(fig);

%plot lasers and legends 
for p = 1:param.numLasers  
    subplot(1, param.numLasers, p); hold on
    plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
    legend(legendPlot(p), ['n = ' num2str(height(flyList)) ' flies, ' num2str(numTrials(p)) ' trials'], 'TextColor', param.baseColor, 'FontSize', 12);
    legend('boxoff');
    hold off
end

%turn background black
fig = formatFig(fig, true, [1,param.numLasers]);

%save 
fig_name = ['\Avg_Velocity_Walking'];
if normalize; fig_name = [fig_name '_Normalized']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot avg speed for each laser condition when fly is walking AND STANDING at stim onset

normalize = 1; %normalize to speed at stim onset. So y axis is change in speed. 

%speed is in radians/frame. Ball radius is 4.495 mm. Fictrac is 30 fps.
%so speed in mm/s = (data.speed * 4.495 * 30)
speed = data.speed * 4.495 * 30;

vidStarts = find(data.fnum == 0);
vidLasers = data.stimlen(vidStarts);

fig = fullfig;
for laser = 1:param.numLasers
    laserVids = vidStarts(round(vidLasers, 2) == round(param.lasers{laser}, 2));
    
    %get data for walking and standing
    laserDataWalking = NaN(height(laserVids), param.vid_len_f);
    laserDataStanding = NaN(height(laserVids), param.vid_len_f);
    for vid = 1:height(laserVids)
        if ~isnan(data.walking_bout_number(laserVids(vid))) %only look at flies walking at stim onset
            if normalize
                laserDataWalking(vid,:) = (speed(laserVids(vid):laserVids(vid)+param.vid_len_f-1))-(speed(laserVids(vid)+param.laser_on));
            else
                laserDataWalking(vid,:) = speed(laserVids(vid):laserVids(vid)+param.vid_len_f-1);
            end
        elseif ~isnan(data.standing_bout_number(laserVids(vid))) %only look at flies walking at stim onset
            if normalize
                laserDataStanding(vid,:) = (speed(laserVids(vid):laserVids(vid)+param.vid_len_f-1))-(speed(laserVids(vid)+param.laser_on));
            else
                laserDataStanding(vid,:) = speed(laserVids(vid):laserVids(vid)+param.vid_len_f-1);
            end
        end
    end
    speedMeanWalking(laser,:) = nanmean(laserDataWalking);
    speedSEMWalking(laser,:) = sem(laserDataWalking, 1, nan, height(flyList));
    speedMeanStanding(laser,:) = nanmean(laserDataStanding);
    speedSEMStanding(laser,:) = sem(laserDataStanding, 1, nan, height(flyList));

   %plot walking 
   AX(laser) = subplot(2, param.numLasers, laser); hold on;
   legendPlot(laser) = plot(param.x, speedMeanWalking(laser,:), 'linewidth', 2, 'Color', 'blue');
   fill_data = error_fill(param.x, speedMeanWalking(laser,:), speedSEMWalking(laser,:));
   h = fill(fill_data.X, fill_data.Y, get_color('blue'), 'EdgeColor','none');
   set(h, 'facealpha',0.4); 
           
   %plot standing 
   AX(laser+param.numLasers) = subplot(2, param.numLasers, laser+param.numLasers); hold on;
   legendPlot(laser+param.numLasers) = plot(param.x, speedMeanStanding(laser,:), 'linewidth', 2, 'Color', Color('orange'));
   fill_data = error_fill(param.x, speedMeanStanding(laser,:), speedSEMStanding(laser,:));
   h = fill(fill_data.X, fill_data.Y, get_color('orange'), 'EdgeColor','none');
   set(h, 'facealpha',0.4); 
   
   %save light length for plotting after syching lasers
   light_on = 0;
   light_off =(param.fps*param.lasers{laser})/param.fps;
   light_ons(laser) = light_on;
   light_ons(laser+param.numLasers) = light_on;
   light_offs(laser) = light_off;
   light_offs(laser+param.numLasers) = light_off; 
           
   %save num trials for legend 
   numTrials(laser) = sum(~isnan(laserDataWalking(:,1)));
   numTrials(laser+param.numLasers) = sum(~isnan(laserDataStanding(:,1)));
   hold off;
end

% make all axes the same
allYLim = get(AX, {'YLim'});
allYLim = cat(2, allYLim{:});
set(AX, 'YLim', [min(allYLim), max(allYLim)]);

%plot lasers, legends & labels 
y1 = rangeLine(fig);
for p = 1:param.numLasers*2  
    subplot(2, param.numLasers, p); hold on
    plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
    legend(legendPlot(p), ['n = ' num2str(height(flyList)) ' flies, ' num2str(numTrials(p)) ' trials'], 'TextColor', param.baseColor, 'FontSize', 12, 'Location', 'best');
    legend('boxoff');
    if p == 1; ylabel('Walking at stim onset', 'Color', Color(param.baseColor));
    elseif p == param.numLasers+1; ylabel('Standing at stim onset', 'Color', Color(param.baseColor)); end
    hold off
end

%turn background black 
fig = formatFig(fig, true, [2,param.numLasers]);

%common x and y labels
han=axes(fig,'visible','off'); 
han.Title.Visible='on';
han.XLabel.Visible='on';
han.YLabel.Visible='on';
ylbl = ylabel(han,'Velocity (?m/s)', 'Color', Color(param.baseColor), 'FontSize', 12);
ylbl.Position(1) = ylbl.Position(1) - 0.03;
xlabel(han,'Time (s)', 'Color', Color(param.baseColor), 'FontSize', 12);
title(han,'Avg velocity x behavior', 'Color', Color(param.baseColor), 'FontSize', 14);

%save 
fig_name = ['\Avg_Velocity_Walking_&_Standing'];
if normalize; fig_name = [fig_name '_Normalized']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% JOINT ANGLES X VELOCITY %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 %% TODO ... Joint angle over time binned by velocity

vidStarts = find(data.fnum == 0);
vidLasers = data.stimlen(vidStarts);

numBins = 5; 
leg = 1;
jnt = 3;
jntStr = [param.legs{leg} param.jointLetters{jnt} '_angle'];

fig = fullfig;
for laser = 1:param.numLasers
    laserVids = vidStarts(round(vidLasers, 2) == round(param.lasers{laser}, 2));
    speedData = NaN(height(laserVids), 1); %speed at laser onset for binning joint data
    jointData = NaN(height(laserVids), param.vid_len_f); %joint data for plotting 
    
    for vid = 1:height(laserVids)
%         if ~isnan(data.walking_bout_number(laserVids(vid))) %only look at flies walking at stim onset
            speedData(vid,1) = data.speed(laserVids(vid)+param.laser_on);
            jointData(vid,:) = data.(jointStr)(laserVids(vid):laserVids(vid)+param.vid_len_f-1);
%         end
    end
    speedMean(laser,:) = nanmean(laserData);
    speedSEM(laser,:) = sem(laserData, 1, nan, height(flyList));
    
    AX(laser) = subplot(1, param.numLasers, laser); hold on;
           
   %plot
   legendPlot(laser) = plot(param.x, speedMean(laser,:), 'linewidth', 2);
   fill_data = error_fill(param.x, speedMean(laser,:), speedSEM(laser,:));
   h = fill(fill_data.X, fill_data.Y, get_color('blue'), 'EdgeColor','none');
   set(h, 'facealpha',0.4); 
   
   %save light length for plotting after syching lasers
   light_on = 0;
   light_off =(param.fps*param.lasers{laser})/param.fps;
   light_ons(laser) = light_on;
   light_offs(laser) = light_off;
           
   %save num trials for legend 
   numTrials(laser) = sum(~isnan(laserData(:,1)));
   hold off;
end

% make all axes the same
allYLim = get(AX, {'YLim'});
allYLim = cat(2, allYLim{:});
set(AX, 'YLim', [min(allYLim), max(allYLim)]);

y1 = rangeLine(fig);

%plot lasers and legends 
for p = 1:param.numLasers  
    subplot(1, param.numLasers, p); hold on
    plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
    legend(legendPlot(p), ['n = ' num2str(height(flyList)) ' flies, ' num2str(numTrials(p)) ' trials'], 'TextColor', param.baseColor, 'FontSize', 12);
    legend('boxoff');
    hold off
end

%turn background black
fig = formatFig(fig, true, [1,param.numLasers]);
% 
% %save 
% fig_name = ['\Avg_Jnt_Angle_Binned_By_Velocity'];
% save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% 
% clearvars('-except',initial_vars{:}); initial_vars = who;






%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Swing Stance and Filtered Step Metrics %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% (Lab Mtg 2021) CALCULATE: swing stance for all walking bouts
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
    if height(boutIdxs) > 10 % a walking bout must be at least 10 frames. 
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
%% OLD (filter by forward after metrics) - CALCULATE: step freq, speed, temp, heading dir, step length, stance dur, swing dur from BOUTMAP
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
    step(leg).stim = []; %1=stim on during entire step. 0=no stim on during step. 0.5 = some stim on during step. 
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
           this_stim_fnum = walkingData.fnum(boutIdxsNotNan); 
           this_stim_laser = param.allLasers(walkingData.condnum(boutIdxsNotNan(1)));
           this_stim = zeros(width(boutIdxsNotNan),1);
           if this_stim_laser ~= 0 
               %there was some stim this vid... check if it occured during bout
               laser_off = param.laser_on+(this_stim_laser*param.vid_len_f);
               if ~(this_stim_fnum(end) < param.laser_on | this_stim_fnum(1) > laser_off)
                   %the video has frams during the laser
                   stim_frames = find(this_stim_fnum > param.laser_on & this_stim_fnum < laser_off);
                   this_stim(stim_frames) = 1;
               end
           end
           
           %only look at bout if there were enough steps by each leg (5) to save forward rotation info
           if ~isempty(this_forward)
               if contains(param.legs{leg}, '3') | contains(param.legs{leg}, 'L2')
                    %for T3 troughs are stance start - so invert signal to make peaks stance starts
                    %for L2, stance is positive values, so trough to peak, so invert so peaks are stance starts. 
                    this_data = this_data *-1;
               end
               
               % TODO: Calculate Hilbert transform (phase) of the whole bout 

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
               step_stim = [];
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
                     step_stim = [step_stim; sum(this_stim(pkLocs(st):pkLocs(st+1)))/height(this_stim(pkLocs(st):pkLocs(st+1)))]; %1 = full step in stim; 0 = no stim in step; fraction = some step has stim.
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
                step(leg).stim = [step(leg).stim; step_stim];
           end
       
       end  
    end
end

initial_vars{end+1} = 'step';
clearvars('-except',initial_vars{:}); initial_vars = who;
%% (Lab Mtg 2021) NEW (for Lab Mtg 2021) (filter by forward after metrics) - CALCULATE: step freq, speed, temp, heading dir, step length, stance dur, swing dur from BOUTMAP
clear steps

%legs and joints to add data of 
joints = {'_FTi', 'B_rot', 'E_x', 'E_y', 'E_z'};
joint_names = {'FTi', 'B_rot', 'E_x', 'E_y', 'E_z'};

% define butterworth filter for hilbert transform.
[A,B,C,D] = butter(1,[0.02 0.4],'bandpass');
sos = ss2sos(A,B,C,D);

%get a list of bouts where ther were enough steps in 'swing stance' screening
goodBouts=find(~cellfun('isempty', boutMap{:,'forward_rotation'}));

steps = struct;
for leg = 1:param.numLegs
    steps.leg(leg).meta = table('Size', [0,15], 'VariableTypes',{'string','cell','double', 'double','double', 'double','double', 'double','double', 'double','double', 'double','double', 'double','double'},'VariableNames',{'fly', 'walkingDataIdxs', 'step_frequency', 'step_length', 'swing_duration', 'stance_duration', 'avg_heading_angle', 'avg_heading_bin', 'avg_forward_rotation', 'avg_speed', 'avg_speed_bin', 'avg_forward_velocity', 'avg_angular_velocity', 'avg_temp', 'avg_stim'});
%     steps.leg(leg).FTi = NaN(1, 100);
end

leg_step_idxs = [0, 0, 0, 0, 0, 0]; %row idxs for saving data in steps struct
for bout = 1:100 %height(goodBouts)
    this_bout = goodBouts(bout); %idx in boutMap
    this_bout_idxs = boutMap.walkingDataIdxs{this_bout}; %idxs in walkingData
    
    % calculate metrics that are the same across legs
    % fly number
    this_fly = walkingData.flyid{this_bout_idxs(1)};
    % opto stim region 
    this_laser_length = param.allLasers(walkingData.condnum(this_bout_idxs(1))); %in seconds
    this_stim = zeros(width(this_bout_idxs),1); % 0 = no stim; 1 = stim
    this_fnum = walkingData.fnum(this_bout_idxs);
    laser_off = param.laser_on+(this_laser_length*param.fps);
    if this_laser_length > 0 & ~(this_fnum(1) > laser_off | this_fnum(end) < param.laser_on) %TODO check that this is correct logic
        this_stim(this_fnum >=param.laser_on & this_fnum < laser_off) = 1;
    end
    
    for leg = 1:param.numLegs
        %indexes within bout
        this_swing_stance = boutMap.([param.legs{leg} '_swing_stance']){this_bout}; %swing = 1; stance = 0
        this_stance_starts = [find(this_swing_stance == 0,1,'first'); find(diff(this_swing_stance) == -1)+1; find(this_swing_stance == 1,1,'last');]; %first idxs of stance
        this_stance_ends = find(diff(this_swing_stance) == 1); %last idxs of stances
        %same indexes in walkingData - add start idx of bout in walkingData to convert from bout to walkingData idxs
        this_stance_starts_walkingData = this_stance_starts + this_bout_idxs(1); %TODO check this
%         this_stance_ends_walkingData = this_stance_ends + this_bout_idxs(1); %TODO check this

        %Get all of the joint data
        jointTable = table;
        phaseTable = table;
        for joint = 1:width(joints)
            joint_str = [param.legs{leg} joints{joint}];
            jointTable.(joint_str) = walkingData.(joint_str)(this_bout_idxs);
            %calcualte phase (hilbert transform)
            normed_data = (jointTable.(joint_str)-nanmean(jointTable.(joint_str)))/nanstd(jointTable.(joint_str));
            bfilt_data = sosfilt(sos, normed_data);  %bandpass frequency filter for hilbert transform            
            phaseTable.(joint_str) = angle(hilbert(bfilt_data));
        end
   
        %calculate and save metrics and data for each step    
        for st = 1:height(this_stance_ends)
            % step idxs in bout - for indexing into jointTable
            this_step_idxs = this_stance_starts(st):this_stance_starts(st+1);
            this_stance = this_stance_starts(st):this_stance_ends(st);
            this_swing = this_stance_ends(st)+1:this_stance_starts(st+1);
            
            % step idxs in walkingData
            this_step_idxs_walkingData = this_stance_starts_walkingData(st):this_stance_starts_walkingData(st+1);
%             this_stance_walkingData = this_stance_starts_walkingData(st):this_stance_ends_walkingData(st);
%             this_swing_walkingData = this_stance_ends_walkingData(st)+1:this_stance_starts_walkingData(st+1);

            %calculate step frequency
            step_freq =  1./(width(this_step_idxs)/param.fps);
            
            %calculate step length - TODO what are the units?
            shift_val = 10; %add to each position value to make them all positive. 0 point from anipose is L1_BC position.
            start_positions = [jointTable.([param.legs{leg} 'E_x'])(this_stance(1)), jointTable.([param.legs{leg} 'E_y'])(this_stance(1)), jointTable.([param.legs{leg} 'E_z'])(this_stance(1))];
            end_positions = [jointTable.([param.legs{leg} 'E_x'])(this_stance(end)), jointTable.([param.legs{leg} 'E_y'])(this_stance(end)), jointTable.([param.legs{leg} 'E_z'])(this_stance(end))];
            start_positions = start_positions + shift_val;
            end_positions = end_positions + shift_val;
            step_length = sqrt((end_positions(1)-start_positions(1))^2 + (end_positions(2)-start_positions(2))^2 + (end_positions(3)-start_positions(3))^2);            
           
            %calculate swing and stance duration 
            swing_duration = width(this_swing)/param.fps;
            stance_duration = width(this_stance)/param.fps;
            
            %calculate avgs: heading, speed, temp,
            avg_heading_angle = nanmean(walkingData.heading_angle(this_step_idxs_walkingData));
            avg_speed = nanmean(walkingData.speed(this_step_idxs_walkingData));
            avg_forward_velocity = nanmean(walkingData.forward_velocity(this_step_idxs_walkingData));
            avg_angular_velocity = nanmean(walkingData.angular_velocity(this_step_idxs_walkingData));
            avg_temp = nanmean(walkingData.temp(this_step_idxs_walkingData));
            
            %calcualte avg bins: percent forward & avg speed bin 
            avg_speed_bin = nanmean(walkingData.speed_bin(this_step_idxs_walkingData));
            avg_forward_rotation = nanmean(walkingData.forward_rotation(this_step_idxs_walkingData)); %(0 = fully not forward, 1 = fully forward)
            avg_heading_bin = nanmean(walkingData.heading_bin(this_step_idxs_walkingData));
            
            %calculate percent opto (0 = fully no stim, 1 = fully stim)
            avg_stim = nanmean(this_stim(this_step_idxs));
                
            %save everything! - all metrics + joint and phase variables. 
            leg_step_idxs(leg) = leg_step_idxs(leg)+1; %update leg step idx.
            for joint = 1:width(joints)
                joint_str = [param.legs{leg} joints{joint}];
                steps.leg(leg).(joint_names{joint})(leg_step_idxs(leg),1:width(this_step_idxs)) = jointTable.(joint_str)(this_step_idxs);
                steps.leg(leg).([joint_names{joint} '_phase'])(leg_step_idxs(leg),1:width(this_step_idxs)) = phaseTable.(joint_str)(this_step_idxs);
            end
            steps.leg(leg).meta.fly(leg_step_idxs(leg)) = this_fly;
            steps.leg(leg).meta.walkingDataIdxs{leg_step_idxs(leg)} = this_step_idxs_walkingData;
            steps.leg(leg).meta.step_frequency(leg_step_idxs(leg)) = step_freq;
            steps.leg(leg).meta.step_length(leg_step_idxs(leg)) = step_length;
            steps.leg(leg).meta.swing_duration(leg_step_idxs(leg)) = swing_duration;
            steps.leg(leg).meta.stance_duration(leg_step_idxs(leg)) = stance_duration;
            steps.leg(leg).meta.avg_heading_angle(leg_step_idxs(leg)) = avg_heading_angle;
            steps.leg(leg).meta.avg_heading_bin(leg_step_idxs(leg)) = avg_heading_bin;
            steps.leg(leg).meta.avg_forward_rotation(leg_step_idxs(leg)) = avg_forward_rotation;
            steps.leg(leg).meta.avg_speed(leg_step_idxs(leg)) = avg_speed;
            steps.leg(leg).meta.avg_speed_bin(leg_step_idxs(leg)) = avg_speed_bin;
            steps.leg(leg).meta.avg_forward_velocity(leg_step_idxs(leg)) = avg_forward_velocity;
            steps.leg(leg).meta.avg_angular_velocity(leg_step_idxs(leg)) = avg_angular_velocity; 
            steps.leg(leg).meta.avg_temp(leg_step_idxs(leg)) = avg_temp;
            steps.leg(leg).meta.avg_stim(leg_step_idxs(leg)) = avg_stim;         
        end
        
    end
end

%find where this_joint_data is zero and replace with NaN
for leg = 1:param.numLegs 
    for joint = 1:width(joints)
        [rows,cols]=find(~steps.leg(leg).(joint_names{joint}));
        if ~isempty(rows)
            for val = 1:height(rows)
                steps.leg(leg).(joint_names{joint})(rows(val),cols(val)) = NaN;
                steps.leg(leg).([joint_names{joint} '_phase'])(rows(val),cols(val)) = NaN;
            end
        end
    end
end

initial_vars{end+1} = 'steps';
clearvars('-except',initial_vars{:}); initial_vars = who;


%% find bout map with a particular idx in it
date = '8.12.21'; fly = '2_0'; rep = 5; cond = 6; 

this_vid_data = find(strcmpi(walkingData.date_parsed, date) & strcmpi(walkingData.fly, fly) & walkingData.rep == rep & walkingData.condnum == cond);
idx = this_vid_data(2);
clear bout
for b = 1:height(boutMap)
   if any(boutMap.walkingDataIdxs{b} == idx)
       bout = b;
   end
end



%% Plot: Joint angles and swing stance plot

bout = 1516; %walking bout to plot (newBout in boutMap)

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

% subplot(5,1,2);
% %plot the swing stance plot
% imagesc(this_swing_stance'); colormap([Color(param.backgroundColor); Color(param.baseColor); 0.5 0.5 0.5;]); 
% yticklabels({'L1', 'L2', 'L3', 'R1', 'R2', 'R3'});
% ylabel('swing stance')

subplot(4,1,2);
%plot speed 
plot(walkingData.forward_velocity(boutMap.walkingDataIdxs{bout})); 
ylabel('forward velocity (mm/s)');
axis tight
% ylim([0 20]);


% subplot(4,1,4)
% %plot inst_dir
% plot(walkingData.heading_angle(boutMap.walkingDataIdxs{bout})); 
% ylabel(['heading (deg)']);
% axis tight

subplot(4,1,3);
%plot speed 
plot(walkingData.angular_velocity(boutMap.walkingDataIdxs{bout})); 
ylabel('angular velocity (mm/s)');
axis tight
% ylim([0 20]);


subplot(4,1,4);
%plot speed 
plot(walkingData.sideslip_velocity(boutMap.walkingDataIdxs{bout})); 
ylabel('sideslip velocity (mm/s)');
axis tight
% ylim([0 20]);

first_frame = walkingData.fnum(x(1));
date = walkingData.date_parsed{first_frame};
fly = walkingData.fly{first_frame};
rep = walkingData.rep(first_frame);
cond = walkingData.condnum(first_frame);

%save
fig_name = ['\Swing stance plots - date ' date ' - fly ' fly ' - R' num2str(rep) 'C' num2str(cond) ' - bout ' num2str(bout) ' - first frame ' num2str(first_frame)];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% clearvars('-except',initial_vars{:}); initial_vars = who;

%% Plot: Joint angles and swing stance plot

date = '8.12.21'; fly = '2_0'; rep = 5; cond = 6; 
this_vid_data = find(strcmpi(data.date_parsed, date) & strcmpi(data.fly, fly) & data.rep == rep & data.condnum == cond);

%get swing stance data for this bout 
fig = fullfig;
subplot(4,1,1);
%plot the joint data
plot(data.L1E_y(this_vid_data)); hold on
plot(data.L2E_y(this_vid_data));
plot(data.L3E_y(this_vid_data));
plot(data.R1E_y(this_vid_data));
plot(data.R2E_y(this_vid_data));
plot(data.R3E_y(this_vid_data));
legend('L1E-y', 'L2E-y', 'L3E-y', 'R1E-y', 'R2E-y', 'R3E-y', 'Location', 'best', 'NumColumns', 6);
ylabel('tarsi y positions');
axis tight
hold off

% subplot(5,1,2);
% %plot the swing stance plot
% imagesc(this_swing_stance'); colormap([Color(param.backgroundColor); Color(param.baseColor); 0.5 0.5 0.5;]); 
% yticklabels({'L1', 'L2', 'L3', 'R1', 'R2', 'R3'});
% ylabel('swing stance')

subplot(4,1,2);
%plot speed 
plot(data.sideslip_velocity(this_vid_data)); 
ylabel('sideslip velocity (mm/s)');
axis tight
% ylim([0 20]);


% subplot(4,1,4)
% %plot inst_dir
% plot(walkingData.heading_angle(boutMap.walkingDataIdxs{bout})); 
% ylabel(['heading (deg)']);
% axis tight

subplot(4,1,3);
%plot speed 
plot(data.angular_velocity(this_vid_data)); 
ylabel('angular velocity (mm/s)');
axis tight
% ylim([0 20]);


subplot(4,1,4);
%plot speed 
plot(data.forward_velocity(this_vid_data)); 
ylabel('forward velocity (mm/s)');
axis tight
% ylim([0 20]);
% 
% first_frame = walkingData.fnum(x(1));
% date = walkingData.date_parsed{first_frame};
% fly = walkingData.fly{first_frame};
% rep = walkingData.rep(first_frame);
% cond = walkingData.condnum(first_frame);
% 
% %save
% fig_name = ['\Swing stance plots - date ' date ' - fly ' fly ' - R' num2str(rep) 'C' num2str(cond) ' - bout ' num2str(bout) ' - first frame ' num2str(first_frame)];
% save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% % clearvars('-except',initial_vars{:}); initial_vars = who;


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
%% PLOT: STEP FREQUENCY x speed x opto

%%%%% PARAMS %%%%%
speedThresh = 1; %max speed, since not all temps go to higher speeds it may distort lslines. 
%%%%%%%%%%%%%%%%%%


%plot step freq x temp for all data
fig = fullfig;
plotting = numSubplots(param.numLegs);
for leg = 1:param.numLegs
    subplot(plotting(1), plotting(2), leg);
    
    % data to plot
    goodCtl = step(leg).speed > speedThresh & step(leg).stim == 0;
    goodExp = step(leg).speed > speedThresh & step(leg).stim == 1;
    xctl = step(leg).speed(goodCtl);
    yctl = step(leg).freq(goodCtl); 
    xexp = step(leg).speed(goodExp);
    yexp = step(leg).freq(goodExp);     
    
    %plot data
    scatter(xctl, yctl , 'filled'); hold on; %lsline; % sp eed x step freq
    scatter(xexp, yexp , 'filled'); %hold on; lsline; % sp eed x step freq

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
%% PLOT: STEP LENGTH x speed x opto

%%%%% PARAMS %%%%%
speedThresh = 1; %max speed, since not all temps go to higher speeds it may distort lslines. 
%%%%%%%%%%%%%%%%%%


%plot step freq x temp for all data
fig = fullfig;
plotting = numSubplots(param.numLegs);
for leg = 1:param.numLegs
    subplot(plotting(1), plotting(2), leg);
    
    % data to plot
    goodCtl = step(leg).speed > speedThresh & step(leg).stim == 0;
    goodExp = step(leg).speed > speedThresh & step(leg).stim == 1;
    xctl = step(leg).speed(goodCtl);
    yctl = step(leg).length(goodCtl); 
    xexp = step(leg).speed(goodExp);
    yexp = step(leg).length(goodExp);     
    
    %plot data
    scatter(xctl, yctl , 'filled'); hold on; %lsline; % sp eed x step freq
    scatter(xexp, yexp , 'filled'); %hold on; lsline; % sp eed x step freq

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
%% PLOT: SWING DURATION x speed x opto

%%%%% PARAMS %%%%%
speedThresh = 1; %max speed, since not all temps go to higher speeds it may distort lslines. 
%%%%%%%%%%%%%%%%%%


%plot step freq x temp for all data
fig = fullfig;
plotting = numSubplots(param.numLegs);
for leg = 1:param.numLegs
    subplot(plotting(1), plotting(2), leg);
    
    % data to plot
    goodCtl = step(leg).speed > speedThresh & step(leg).stim == 0;
    goodExp = step(leg).speed > speedThresh & step(leg).stim == 1;
    xctl = step(leg).speed(goodCtl);
    yctl = step(leg).swing_dur(goodCtl); 
    xexp = step(leg).speed(goodExp);
    yexp = step(leg).swing_dur(goodExp);     
    
    %plot data
    scatter(xctl, yctl , 'filled'); hold on; %lsline; % sp eed x step freq
    scatter(xexp, yexp , 'filled'); %hold on; lsline; % sp eed x step freq

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
%% PLOT: STANCE DURATION x speed x opto

%%%%% PARAMS %%%%%
speedThresh = 1; %max speed, since not all temps go to higher speeds it may distort lslines. 
%%%%%%%%%%%%%%%%%%


%plot step freq x temp for all data
fig = fullfig;
plotting = numSubplots(param.numLegs);
for leg = 1:param.numLegs
    subplot(plotting(1), plotting(2), leg);
    
    % data to plot
    goodCtl = step(leg).speed > speedThresh & step(leg).stim == 0;
    goodExp = step(leg).speed > speedThresh & step(leg).stim == 1;
    xctl = step(leg).speed(goodCtl);
    yctl = step(leg).stance_dur(goodCtl); 
    xexp = step(leg).speed(goodExp);
    yexp = step(leg).stance_dur(goodExp);     
    
    %plot data
    scatter(xctl, yctl , 'filled'); hold on; %lsline; % sp eed x step freq
    scatter(xexp, yexp , 'filled'); %hold on; lsline; % sp eed x step freq

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

clearvars('-except',initial_vars{:}); initial_vars = who
%% PLOT: SWING DURATION x  STANCE DURATION x opto

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
    goodCtl = step(leg).speed > speedThresh & step(leg).stim == 0;
    goodExp = step(leg).speed > speedThresh & step(leg).stim == 1;
    xctl = step(leg).stance_dur(goodCtl);
    yctl = step(leg).swing_dur(goodCtl); 
    xexp = step(leg).stance_dur(goodExp);
    yexp = step(leg).swing_dur(goodExp);     
    
    %plot data
    scatter(xctl, yctl , 'filled'); hold on; %lsline; % sp eed x step freq
    scatter(xexp, yexp , 'filled'); %hold on; lsline; % sp eed x step freq

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

clearvars('-except',initial_vars{:}); initial_vars = who

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Joint angle traces binned by speed at stim onset %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Select data for plotting by forward rotation and speed
speed_thresh = 1;

vidStarts = find(data.fnum == 0);
jointMeta = table('Size', [height(vidStarts),6], 'VariableTypes',{'cell', 'cell', 'double', 'double', 'double', 'double'},'VariableNames',{'vidStart','vidEnd','speedAtStimOn','walkingAtStimOn','forwardAtStimOn', 'laser'});
jointMeta.vidStart = vidStarts;
jointMeta.vidEnd = [vidStarts(2:end)-1; height(data)]; 
jointMeta.speedAtStimOn = data.fictrac_speed(vidStarts+(param.laser_on-1)) * param.sarah_ball_r * param.fictrac_fps;
jointMeta.walkingAtStimOn = data.walking_bout_number(vidStarts+(param.laser_on-1));
jointMeta.forwardAtStimOn = data.forward_rotation(vidStarts+(param.laser_on-1));
jointMeta.laser = param.allLasers(data.condnum(vidStarts+(param.laser_on-1)))';
jointData = cell(param.numLegs, param.numJoints); 
for leg = 1:param.numLegs
    for joint = 1:param.numJoints
        joint_str = [param.legs{leg} '_' param.joints{joint}];
        thisData = NaN(height(jointMeta), param.vid_len_f);
        for vid = 1:height(thisData)
            thisData(vid,:) = [data.(joint_str)(jointMeta.vidStart(vid):jointMeta.vidEnd(vid)); NaN(param.vid_len_f-height(data.(joint_str)(jointMeta.vidStart(vid):jointMeta.vidEnd(vid))),1)]';
        end
        jointData{leg, joint} = thisData;
    end
end

allWalking = ~isnan(jointMeta.walkingAtStimOn);
walkingForward = allWalking & jointMeta.forwardAtStimOn == 1; 
walkingSpeedy = allWalking & jointMeta.speedAtStimOn > speed_thresh;
walkingForwardSpeedy = walkingForward & walkingSpeedy;

%% PLOT: All lasers, All joints, One leg
leg = 1;
walkingIdxs = walkingSpeedy;

fig = fullfig;
numCols = param.numLasers;
numRows = param.numJoints;
idx = 0;
for joint = 1:param.numJoints
    for laser = 1:param.numLasers
        idx = idx+1;
        subplot(numRows, numCols, idx)
        
        %get mean and sem of joint data
        thisLaser = jointMeta.laser == param.lasers{laser};
        thisData = jointData{leg, joint}(walkingIdxs & thisLaser,:) - jointData{leg, joint}(walkingIdxs & thisLaser,param.laser_on);
        meanData = nanmean(thisData, 1);
        semData = sem(thisData, 1, nan, height(flyList));
        plot(meanData);

        %plot joint data
        plot(param.x, meanData, 'color', Color(param.jointColors{joint}), 'linewidth', 1.5); hold on
        fill_data = error_fill(param.x, meanData, semData);
        h = fill(fill_data.X, fill_data.Y, get_color(param.jointColors{joint}), 'EdgeColor','none');
        set(h, 'facealpha',param.jointFillWeights{joint});

        %plot laser
        y1 = rangeLine(fig);
        laser_on = 0;
        laser_off = laser_on + param.lasers{laser};
        pl = plot([laser_on, laser_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
    end
end

fig = formatFig(fig, true, [numRows, numCols]);
%% PLOT: All lasers, One joint, All legs
joint = 3;
walkingIdxs = walkingSpeedy;

fig = fullfig;
numCols = param.numLasers;
numRows = param.numLegs;
idx = 0;
for leg = 1:param.numLegs
    for laser = 1:param.numLasers
        idx = idx+1;
        subplot(numRows, numCols, idx)
        
        %get mean and sem of joint data
        thisLaser = jointMeta.laser == param.lasers{laser};
        thisData = jointData{leg, joint}(walkingIdxs & thisLaser,:) - jointData{leg, joint}(walkingIdxs & thisLaser,param.laser_on);
        meanData = nanmean(thisData, 1);
        semData = sem(thisData, 1, nan, height(flyList));
        plot(meanData);

        %plot joint data
        plot(param.x, meanData, 'color', Color(param.jointColors{joint}), 'linewidth', 1.5); hold on
        fill_data = error_fill(param.x, meanData, semData);
        h = fill(fill_data.X, fill_data.Y, get_color(param.jointColors{joint}), 'EdgeColor','none');
        set(h, 'facealpha',param.jointFillWeights{joint});

        %plot laser
        y1 = rangeLine(fig);
        laser_on = 0;
        laser_off = laser_on + param.lasers{laser};
        pl = plot([laser_on, laser_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
    end
end

fig = formatFig(fig, true, [numRows, numCols]);





%% TODO check if fit lines are correct... Plot: Step Frequency x avg_spded, avg_forward_velocity, and avg_angular_velocity - WITH FIT LINES - ctl vs stim - forward walking steps

fig = fullfig;
plotting = [param.numLegs, 3*2]; %rows x (speed types*3 plots for opto & stim, bestfitlines)
idx = 1;
for leg = 1:param.numLegs

    % select steps that are forward walking and hav min speed bin of 2
    ctl_step_idxs = find(steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 0);
    stim_step_idxs = find(steps.leg(leg).meta.avg_forward_rotation == 1 & steps.leg(leg).meta.avg_speed_bin >= 2 & steps.leg(leg).meta.avg_stim == 1);
    
    % step freq x AVG_SPEED
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.step_frequency(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));
    hold on
    scatter(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.step_frequency(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor)); 
    hold off
    %best fit lines
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    FitCtl = polyfit(steps.leg(leg).meta.avg_speed(ctl_step_idxs),steps.leg(leg).meta.step_frequency(ctl_step_idxs),1); % x = x data, y = y data, 1 = order of the polynomial i.e a straight line 
    FitStim = polyfit(steps.leg(leg).meta.avg_speed(stim_step_idxs),steps.leg(leg).meta.step_frequency(stim_step_idxs),1); % x = x data, y = y data, 1 = order of the polynomial i.e a straight line 
    x = linspace(2,30);
    plot(x,polyval(FitCtl,x), 'color', Color(param.baseColor), 'linewidth', 2); hold on
    plot(x,polyval(FitStim,x), 'color', Color(param.laserColor), 'linewidth', 2); hold off
    
    
    % step freq x AVG_FORWARD_VELOCITY
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_forward_velocity(ctl_step_idxs),steps.leg(leg).meta.step_frequency(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor)); 
    hold on
    scatter(steps.leg(leg).meta.avg_forward_velocity(stim_step_idxs),steps.leg(leg).meta.step_frequency(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor));
    hold off
    %best fit lines
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    FitCtl = polyfit(steps.leg(leg).meta.avg_forward_velocity(ctl_step_idxs),steps.leg(leg).meta.step_frequency(ctl_step_idxs),1); % x = x data, y = y data, 1 = order of the polynomial i.e a straight line 
    FitStim = polyfit(steps.leg(leg).meta.avg_forward_velocity(stim_step_idxs),steps.leg(leg).meta.step_frequency(stim_step_idxs),1); % x = x data, y = y data, 1 = order of the polynomial i.e a straight line 
    x = linspace(2,8);
    plot(x,polyval(FitCtl,x), 'color', Color(param.baseColor), 'linewidth', 2); hold on
    plot(x,polyval(FitStim,x), 'color', Color(param.laserColor), 'linewidth', 2); hold off
    
    % step freq x AVG_ANGULAR_VELOCITY
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    scatter(steps.leg(leg).meta.avg_angular_velocity(ctl_step_idxs),steps.leg(leg).meta.step_frequency(ctl_step_idxs), 'MarkerEdgeColor', Color(param.baseColor));  
    hold on
    scatter(steps.leg(leg).meta.avg_angular_velocity(stim_step_idxs),steps.leg(leg).meta.step_frequency(stim_step_idxs), 'MarkerEdgeColor', Color(param.laserColor));
    hold off
    %best fit lines
    subplot(plotting(1), plotting(2), idx);
    idx = idx+1;
    FitCtl = polyfit(steps.leg(leg).meta.avg_angular_velocity(ctl_step_idxs),steps.leg(leg).meta.step_frequency(ctl_step_idxs),2); % x = x data, y = y data, 1 = order of the polynomial i.e a straight line 
    FitStim = polyfit(steps.leg(leg).meta.avg_angular_velocity(stim_step_idxs),steps.leg(leg).meta.step_frequency(stim_step_idxs),2); % x = x data, y = y data, 1 = order of the polynomial i.e a straight line 
    x = linspace(-100,100);
    plot(x,polyval(FitCtl,x), 'color', Color(param.baseColor), 'linewidth', 2); hold on
    plot(x,polyval(FitStim,x), 'color', Color(param.laserColor), 'linewidth', 2); hold off
end

fig = formatFig(fig, true, plotting);

% save
fig_name = ['\Step_Frequency_x_avgSpeed_avgForwardVelocity_avgAngularVelocity_forwardWalkingOnly_bestFitLines'];
save_figure(fig, [param.googledrivesave fig_name], param.fileType);



%% fictrac data plots for wkly mtg 
path = 'G:\My Drive\Tuthill Lab Shared\Sarah\Weekly Meetings\21_10_26\figs\';
fig = fullfig;
histogram(data.fictrac_inst_dir, 'FaceColor', Color('magenta'), 'EdgeColor', Color('magenta'));
%  xlim([0, 20]);
fig = formatFig(fig, true);
fig_name = 'data_inst_dir';
save_figure(fig, [path fig_name], '-png');









%% 
idxs = [75001:75577];% find(data.walking_bout_number == 692);
joints = {'L1E', 'L2E', 'L3E', 'R1E', 'R2E', 'R3E', 'L1D', 'L2D', 'L3D', 'R1D', 'R2D', 'R3D'};
Plot_3D_Joint_Position_Trajectory('-data', data, '-param', param, '-indices', idxs, '-joints', joints, '-path', param.googledrivesave);



%% Figure out fictrac
% date = '8.12.21'; fly = '1_0'; rep = 1; cond = 1; %claw f x gtacr1 -BALL PUSH 1
% date = '8.12.21'; fly = '1_0'; rep = 2; cond = 1; %claw f x gtacr1 -BALL PUSH 2
% date = '8.12.21'; fly = '1_0'; rep = 4; cond = 16; %claw f x gtacr1 -BALL PUSH 3
% date = '8.12.21'; fly = '1_0'; rep = 5; cond = 11; %claw f x gtacr1 -BALL PUSH 4
% date = '8.12.21'; fly = '1_0'; rep = 7; cond = 6; %claw f x gtacr1 -BALL PUSH 5


% date = '8.12.21'; fly = '1_0'; rep = 2; cond = 5; %claw f x gtacr1 -WALKING 1
% % date = '8.12.21'; fly = '2_0'; rep = 5; cond = 6; %claw f x gtacr1 -WALKING 2
% date = '8.12.21'; fly = '2_0'; rep = 5; cond = 12; %claw f x gtacr1 -WALKING 2

% date = '8.12.21'; fly = '1_0'; rep = 1; cond = 6; %claw f x gtacr1 -STANDING
date = '8.16.21'; fly = '1_0'; rep = 1; cond = 2; %claw f x gtacr1 -STANDING 2 WALKING

% var_name = {'fictrac_sphere_orientation_cam_x','fictrac_sphere_orientation_cam_y','fictrac_sphere_orientation_cam_z'};
var_name = {'fictrac_delta_rot_cam_x','fictrac_delta_rot_cam_y','fictrac_delta_rot_cam_z'};

% var_name = {'fictrac_delta_rot_cam_x','fictrac_delta_rot_cam_y','fictrac_delta_rot_cam_z', 'fictrac_int_forward', 'fictrac_int_side', 'fictrac_heading'};
% var_name = {'fictrac_int_x','fictrac_int_y', 'fictrac_speed'};


this_vid_data = find(strcmpi(data.date_parsed, date) & strcmpi(data.fly, fly) & data.rep == rep & data.condnum == cond);

%plot
fig = fullfig; hold on;
var_names_lgd = {};
for var = 1:width(var_name)
%     plot((data.(var_name{var})(this_vid_data)), 'linewidth', 2); 
%     plot((data.(var_name{var})(this_vid_data)*param.sarah_ball_r)/(1/param.fictrac_fps), 'linewidth', 2); 
    window = 20;
    %undo this       plot((smoothdata(data.(var_name{var})(this_vid_data), 'gaussian', window)*param.sarah_ball_r)/(1/param.fictrac_fps), 'linewidth', 2); 
%     plot(cumtrapz((smoothdata(data.(var_name{var})(this_vid_data), 'gaussian', window)*param.sarah_ball_r)), 'linewidth', 2); 

% if var < 4
%     plot(cumsum(data.(var_name{var})(this_vid_data)), 'linewidth', 2); 
% else
%     plot((data.(var_name{var})(this_vid_data)), 'linewidth', 2); 
% end
%     plot(param.x(1:height(this_vid_data)-1), diff(data.(var_name{var})(this_vid_data))/(1/param.fps), 'linewidth', 2);
%     plot(param.x(1:height(this_vid_data)-1), diff(unwrap(data.(var_name{var})(this_vid_data))/(1/param.fps)), 'linewidth', 2); 
%         plot(param.x(1:height(this_vid_data)-1), unwrap(diff(data.(var_name{var})(this_vid_data)), 0.1), 'linewidth', 2); 
%         plot(param.x(1:height(this_vid_data)-2), diff(diff(data.(var_name{var})(this_vid_data))), 'linewidth', 2); 
%         plot(diff(diff(data.(var_name{var})(this_vid_data))), 'linewidth', 2); 

%     plot(param.x(1:height(this_vid_data)-1), smooth((diff(data.(var_name{var})(this_vid_data))*param.sarah_ball_r)*param.fps), 'linewidth', 2);
%     plot(smooth((diff(data.(var_name{var})(this_vid_data))*param.sarah_ball_r)*param.fictrac_fps), 'linewidth', 2);

%     plot(param.x(1:height(this_vid_data)-1), smoothdata((diff(data.(var_name{var})(this_vid_data))*param.sarah_ball_r)*param.fps, 'gaussian', 30), 'linewidth', 2); 

    var_names_lgd{end+1} = strrep(var_name{var}, '_', ' ');
%     var_names_lgd{end+1} = [strrep(var_name{var}, '_', ' '), ' smoothed gaussian ' num2str(window)];

end
 
% plot(param.x(1:height(this_vid_data)-1), (data.speed(this_vid_data(1:end-1))), 'linewidth', 2); 
% plot(param.x(1:height(this_vid_data)), (data.speed(this_vid_data)), 'linewidth', 2);
% plot((data.speed(this_vid_data)), 'linewidth', 2); 
% var_names_lgd{end+1} = 'speed';
% 
% plot((data.fictrac_speed(this_vid_data)*param.sarah_ball_r)/(1/param.fictrac_fps), 'linewidth', 2); 
plot(data.fictrac_speed(this_vid_data),'linewidth', 2);
 var_names_lgd{end+1} = 'fictrac speed';

%plot((data.heading_angle(this_vid_data)), 'linewidth', 2); 
%var_names_lgd{end+1} = 'heading';
% 
%plot(rad2deg(data.fictrac_heading(this_vid_data)), 'linewidth', 2); 
%var_names_lgd{end+1} = 'rad2deg of fictrac heading';

%plot(cumtrapz((smoothdata(data.fictrac_delta_rot_cam_y(this_vid_data), 'gaussian', window)*param.sarah_ball_r)), 'linewidth', 2); 
%var_names_lgd{end+1} = 'integral of fictrac delta rot cam y';
% 
%plot(((data.fictrac_sphere_orientation_cam_y(this_vid_data))*param.sarah_ball_r)/(1/param.fictrac_fps), 'linewidth', 2); 
%var_names_lgd{end+1} = 'fictrac sphere orientation cam y';

% 
% plot((data.fictrac_sphere_orientation_cam_x(this_vid_data)), 'linewidth', 2); 
% var_names_lgd{end+1} = 'fictrac sphere orientation cam x';
% plot((data.fictrac_sphere_orientation_cam_y(this_vid_data)), 'linewidth', 2); 
% var_names_lgd{end+1} = 'fictrac sphere orientation cam y';
% plot((data.fictrac_sphere_orientation_cam_z(this_vid_data)), 'linewidth', 2); 
% var_names_lgd{end+1} = 'fictrac sphere orientation cam z';

laser_on = 0;
laser_off = param.allLasers(cond);
y1 = rangeLine(fig);
pl = plot([laser_on, laser_off], [y1,y1],'color',Color(param.laserColor), 'linewidth', 5);
hold off;

legend(var_names_lgd, 'Location', 'best');

% xlim([-0.5,0.5]);

fig = formatFig(fig, true);

% %save
% fig_name = ['\Single_Trace_' date '_fly' fly '_R' num2str(rep) 'C' num2str(cond) '_' joint_str];
% save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% path = 'G:\My Drive\Tuthill Lab Shared\Sarah\Presentations\Lab Meetings\2021.10.28\Figures\FeCO\Claw flex silencing';
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;

%%
% date = '8.12.21'; fly = '1_0'; rep = 2; cond = 5; %claw f x gtacr1
% date = '8.12.21'; fly = '2_0'; rep = 5; cond = 6; %claw f x gtacr1
date = '8.16.21'; fly = '1_0'; rep = 1; cond = 2; %claw f x gtacr1 -STANDING 2 WALKING

this_vid_data = find(strcmpi(data.date_parsed, date) & strcmpi(data.fly, fly) & data.rep == rep & data.condnum == cond);


c = parula(height(this_vid_data));
fig = fullfig; hold on
x_data = cumtrapz((smoothdata(data.fictrac_delta_rot_cam_x(this_vid_data), 'gaussian', window)*param.sarah_ball_r));
y_data = cumtrapz((smoothdata(data.fictrac_delta_rot_cam_z(this_vid_data), 'gaussian', window)*param.sarah_ball_r));

for frame = 1:height(this_vid_data)-1
%     plot(data.fictrac_int_x(this_vid_data(frame:frame+1)), data.fictrac_int_y(this_vid_data(frame:frame+1)), 'color', c(frame,:)); 
      plot(x_data(frame:frame+1), y_data(frame:frame+1), 'color', c(frame,:)); 

end
%     plot3(data.fictrac_int_x(this_vid_data), data.fictrac_int_y(this_vid_data), data.fnum(this_vid_data)); 

hold off
fig = formatFig(fig, true);

c = colorbar();
c.Color = 'white';
c.TickLabels = {num2str(data.fnum(1)), num2str(data.fnum(end))};
c.Ticks = [0, 1];



%% step metrics with better fictrac

flies = {'8.12.21 Fly 2_0'; '8.13.21 Fly 1_0'; '8.13.21 Fly 2_0'; '8.16.21 Fly 1_0'; '8.16.21 Fly 2_0'};
leg = 1; 

%step freq x forward velocity
max_step_freq = 15;
idxs = find(contains(steps.leg(leg).meta.fly, flies) & steps.leg(leg).meta.step_frequency < max_step_freq);
[~, ~, flyColor] = unique(steps.leg(leg).meta.fly(idxs), 'stable');
ydata = steps.leg(leg).meta.step_frequency(idxs);
xdata = steps.leg(leg).meta.avg_forward_velocity(idxs)*-1;
cdata = flyColor;
% cdata = steps.leg(leg).meta.avg_angular_velocity(idxs)*-1;
%plot
fig = fullfig;
scatter(xdata, ydata, [], cdata); hold on
lsline 
hold off
fig = formatFig(fig, true);
c = colorbar;
c.Color = 'white';
c.Label.FontSize = 12;
ylabel('step frequency (Hz)');
xlabel('forward speed (mm/s)');


%step length x forward velocity
ydata = steps.leg(leg).meta.step_length(idxs);
%plot
fig = fullfig;
scatter(xdata, ydata, [], cdata); hold on
lsline 
hold off
fig = formatFig(fig, true);
c = colorbar;
c.Color = 'white';
c.Label.FontSize = 12;
ylabel('step length');
xlabel('forward speed (mm/s)');


%stance dur x forward velocity
ydata = steps.leg(leg).meta.stance_duration(idxs);
%plot
fig = fullfig;
scatter(xdata, ydata, [], cdata); hold on
lsline 
hold off
fig = formatFig(fig, true);
c = colorbar;
c.Color = 'white';
c.Label.FontSize = 12;
ylabel('stance duration (s)');
xlabel('forward speed (mm/s)');


%swing dur x forward velocity
ydata = steps.leg(leg).meta.swing_duration(idxs);
%plot
fig = fullfig;
scatter(xdata, ydata, [], cdata); hold on
lsline 
hold off
fig = formatFig(fig, true);
c = colorbar;
c.Color = 'white';
c.Label.FontSize = 12;
ylabel('swing duration (s)');
xlabel('forward speed (mm/s)');


%% calculate fictrac vars from rotation vectors in animal coords
% % sarah--rv12-HookFlexion-JR252-gal4xUAS-gtACR1.pq
% date = '8.12.21'; fly = '2_0'; rep = 5; cond = 6; %claw f x gtacr1 -WALKING 2

% evyn--9A-20257-gal4xUAS-csChrimson.pq
date = '5.12.20'; fly = '1_0'; rep  = 1; cond = 2; %claw f x gtacr1 -WALKING 2
% date = '5.12.20'; fly = '1_0'; rep  = 1; cond = 14; %claw f x gtacr1 -WALKING 2

this_vid_data = find(strcmpi(data.date_parsed, date) & strcmpi(data.fly, fly) & data.rep == rep & data.condnum == cond);


deltaX = data.fictrac_delta_rot_lab_x(this_vid_data);
deltaY = data.fictrac_delta_rot_lab_y(this_vid_data);
deltaZ = data.fictrac_delta_rot_lab_z(this_vid_data);

fictrac_speed = data.fictrac_speed(this_vid_data);
fictrac_dir = data.fictrac_inst_dir(this_vid_data);
fictrac_int_x = data.fictrac_int_x(this_vid_data);
fictrac_int_y = data.fictrac_int_y(this_vid_data);
fictrac_heading = data.fictrac_heading(this_vid_data);
fictrac_orientation_z = data.fictrac_sphere_orientation_lab_z(this_vid_data);

[speed, direction, intx, inty, heading, intxx, intyy] = Fictrac_Variables(deltaX, deltaY, deltaZ);


fig = fullfig; hold on;
plot(fictrac_speed); 
plot(speed); 
hold off

fig = fullfig; hold on;
plot(fictrac_dir); 
plot(direction); 
hold off

fig = fullfig; hold on;
plot(normalize(fictrac_int_x));
plot(normalize(intx)*-1); 
% plot((fictrac_int_x)); 
% plot((intx)*-1); 
% plot((intx)); 
% plot(deltaX);
% plot(intx'./deltaX);
% plot((fictrac_int_x-(fictrac_int_x(1))));
% plot(((intx*-1)-(intx(1)*-1))*0.08);
% plot((intx*-1)*0.08);
% plot((fictrac_int_x-(fictrac_int_x(1)))./((intx'*-1)-(intx(1)'*-1)));
% plot(intxx);
hold off
% 
% fig = fullfig; hold on;
% plot((fictrac_int_y)); 
% plot((inty)); 
% plot(normalize(fictrac_int_y)); 
% plot(normalize(inty)); 
% % plot(intyy);
% hold off
% 
fig = fullfig; hold on;
% plot((fictrac_int_x), (fictrac_int_y)); hold on
% plot((intx)*-1, (inty));


plot(normalize(fictrac_int_x), normalize(fictrac_int_y)); hold on
plot(normalize(inty)*-1, normalize(intx));
hold off


% 
fig = fullfig; hold on;
plot(fictrac_heading); 
% plot(diff(heading))
% plot(fictrac_orientation_z);
% plot(headingg*-1);
plot(headingg*-1*(1/10));

% plot(heading); 
% plot(headingg*-1+fictrac_orientation_z);

plot(deltaZ);
% plot(normalize(deltaZ)*-1);
% plot(normalize(fictrac_heading));
% plot(normalize(headingg)*-1);
% plot(fictrac_heading./(headingg*-1));
% plot(fictrac_heading-(headingg*-1));
% plot((fictrac_int_x-(fictrac_int_x(1)))./((intx'*-1)-(intx(1)'*-1)));

hold off



direction and turning are different. 
Direction is the angle the animal is moving. 
Turning is the change in the angle the animal is moving over time. 
As a sanity check, derivative of direction should be Turning.

To get the 2D fictive path. I use the velocity vector (which is speed and direction) 
and add the turning to it, and rotate the vecotr. Then I take the integral to go from a velocity
trace to a position trace. 


%% Convert cam to lab coords via linear regression
% evyn--9A-20257-gal4xUAS-csChrimson.pq
date = '5.12.20'; fly = '1_0'; rep  = 1; cond = 2; 
this_vid_data = find(strcmpi(data.date_parsed, date) & strcmpi(data.fly, fly) & data.rep == rep & data.condnum == cond);

deltaXcam = data.fictrac_delta_rot_cam_x(this_vid_data);
deltaYcam = data.fictrac_delta_rot_cam_y(this_vid_data);
deltaZcam = data.fictrac_delta_rot_cam_z(this_vid_data);

deltaXlab = data.fictrac_delta_rot_lab_x(this_vid_data);
deltaYlab = data.fictrac_delta_rot_lab_y(this_vid_data);
deltaZlab = data.fictrac_delta_rot_lab_z(this_vid_data);

cam2animal(deltaXcam, deltaYcam, deltaZcam, deltaXlab, deltaYlab, deltaZlab);
