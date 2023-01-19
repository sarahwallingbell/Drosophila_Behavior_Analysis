function Plot_joint_trajectories_avg_step(steps, idxs, walkingData, legs, joints, connected, param, colorPhase)

% for leg = 1:param.numLegs; idxs{leg} = {1:height(steps.leg(leg).meta)}; end
% legs = {'L1','L2','L3', 'R1','R2','R3'};
% joints = {'A','B','C','D','E'};
% Plot_joint_trajectories_avg_step(steps, idxs, walkingData, legs, joints, true, param, true)


% Plot average joint position x phase for a set of steps. Can connect the joints
% to plot leg traces, or keep them seperate to just see how the joints move 
% through space. Can plot any set of steps. To only plot specific speeds,  
% filter before running this function. 
% 
% params:
% idxs = indices in steps.leg(#).meta , needs indices for each leg, can leave a leg nan if not plotting that leg. 
%     Ex: idxs = {{1:100}, {2:200}, {1:150}, {1}, {4:400}, {7:600}}  --> order is: {{L1}, {L2}, {L3}, {R1}, {R2}, {R3}}
%     Ex: for leg = 1:param.numLegs; idxs{leg} = {1:height(steps.leg(leg).meta)}; end
% steps = steps structure, output of steps(...).m
% walkingData = parquet summary file where bout number != nan.
% connected = t/f: true connects the joints (plots leg trajectories), false plots trajectory of the joints. 
% legs = legs to plot. ex: legs = {'L1','L2','L3','R2','R3'}; ex: legs = {'L1','L2','L3', 'R1','R2','R3'};
% joints = joints to plot. ex: joints = {'A','B','C','D','E'};
% param = output from  DLC_load_params
% colorPhase = t/f. true = plots the data with color as phase. false = plots the data with color corresponding to the leg/joint. 
% Sarah Walling-Bell
% Spring, 2022

%color scheme for legs and joints 
leg_colors = {'blue', 'yellow', 'orange', 'purple', 'white', 'cyan'}; %each leg has its own color
% leg_colors = {'blue', 'orange', 'blue', 'orange', 'blue', 'orange'}; %e ach TRIPOD has its own color
joint_saturations = [0.1, 0.3, 0.5, 0.7, 0.9];
% joint_saturations = [0.1, 0.3, 0.1, 0.3, 0.9];
for leg = 1:6
   this_leg_hsv = rgb2hsv(Color(leg_colors{leg}));
   for joint = 1:5
       this_joint_hsv = [this_leg_hsv(1), joint_saturations(joint), this_leg_hsv(3)]; 
       kolor(:,joint,leg) = hsv2rgb(this_joint_hsv); 
   end
end
LW = 2;
alpha = 1;

%phase bins
phaseBinEdges = [-pi:0.1:pi, pi];
phaseColors = jet(width(phaseBinEdges)-1);

%plot the data 
fig = fullfig; hold on 
for leg = 1:width(legs)
    legNum = find(contains(param.legs, legs(leg)));
    if connected %plot joints connected 
        for jnt = 1:width(joints)-1   
            
            E_y_phase = vertcat(steps.leg(legNum).meta.tarsus_y_phase{idxs{legNum}{:}})'; %tarsi tip phase 
            
            X1 = walkingData.([legs{leg} joints{jnt} '_x'])([steps.leg(legNum).meta.walkingDataStepIdxs{idxs{legNum}{:}}])';
            X2 = walkingData.([legs{leg} joints{jnt+1} '_x'])([steps.leg(legNum).meta.walkingDataStepIdxs{idxs{legNum}{:}}])';
            Y1 = walkingData.([legs{leg} joints{jnt} '_y'])([steps.leg(legNum).meta.walkingDataStepIdxs{idxs{legNum}{:}}])';
            Y2 = walkingData.([legs{leg} joints{jnt+1} '_y'])([steps.leg(legNum).meta.walkingDataStepIdxs{idxs{legNum}{:}}])';
            Z1 = walkingData.([legs{leg} joints{jnt} '_z'])([steps.leg(legNum).meta.walkingDataStepIdxs{idxs{legNum}{:}}])';
            Z2 = walkingData.([legs{leg} joints{jnt+1} '_z'])([steps.leg(legNum).meta.walkingDataStepIdxs{idxs{legNum}{:}}])';
            
            phase_avg_x1 = nan(1,width(phaseBinEdges)-1);
            phase_avg_x2 = nan(1,width(phaseBinEdges)-1);
            phase_avg_y1 = nan(1,width(phaseBinEdges)-1);
            phase_avg_y2 = nan(1,width(phaseBinEdges)-1);
            phase_avg_z1 = nan(1,width(phaseBinEdges)-1);
            phase_avg_z2 = nan(1,width(phaseBinEdges)-1);

            for ph = 1:width(phase_avg_x1) %plot avg leg segment across each phase bin 
                if colorPhase %plot each line with corresponding phase color
                    line([mean(X1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(X2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
                         [mean(Y1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(Y2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
                         [mean(Z1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(Z2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
                         'Color', [phaseColors(ph,:), alpha]);
                else %plot each line with leg/joint color below
                    line([mean(X1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(X2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
                        [mean(Y1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(Y2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
                        [mean(Z1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(Z2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
                        'Color', [[kolor(:,jnt,leg)]', alpha]);
                end
            end
        end
    else %plot joints seperated
        for jnt = 1:width(joints)
            E_y_phase = vertcat(steps.leg(legNum).meta.tarsus_y_phase{idxs{legNum}{:}})'; %tarsi tip phase 
            X = walkingData.([legs{leg} joints{jnt} '_x'])([steps.leg(legNum).meta.walkingDataStepIdxs{idxs{legNum}{:}}])';
            Y = walkingData.([legs{leg} joints{jnt} '_y'])([steps.leg(legNum).meta.walkingDataStepIdxs{idxs{legNum}{:}}])';
            Z = walkingData.([legs{leg} joints{jnt} '_z'])([steps.leg(legNum).meta.walkingDataStepIdxs{idxs{legNum}{:}}])';

            phase_avg_x = nan(1,width(phaseBinEdges)-1);
            phase_avg_y = nan(1,width(phaseBinEdges)-1);
            phase_avg_z = nan(1,width(phaseBinEdges)-1);
            for ph = 1:width(phase_avg_x) %plot avg joint trajectory for each phase bin
                phase_avg_x(ph) = mean(X(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)));
                phase_avg_y(ph) = mean(Y(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)));
                phase_avg_z(ph) = mean(Z(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)));
            end
            
            if colorPhase %plot with phase color 
                for ph = 1:width(phase_avg_x)-1
                   plot3([phase_avg_x(ph),phase_avg_x(ph+1)], [phase_avg_y(ph),phase_avg_y(ph+1)], [phase_avg_z(ph),phase_avg_z(ph+1)], 'linewidth', LW, 'color', [phaseColors(ph,:), alpha]);
                end
            else %plot with leg/jnt color
                plot3(phase_avg_x, phase_avg_y, phase_avg_z,'linewidth', LW, 'color', [[kolor(:,jnt,leg)]', alpha]);
            end
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

if colorPhase
   colormap jet
   cb = colorbar('Ticks',[0, 0.5, 1],'TickLabels',{'~swing start', '~swing to stance', '~stance end'}, 'FontSize', 20, 'color', Color(param.baseColor), 'Box', 'off');
end


fig = formatFig(fig, true);


