function Plot_joint_trajectories_multiple_avgs_step(steps, idxs, data, legs, joints, connected, param, plotColors)

% Plot average joint position x phase for a set of steps. Can connect the joints
% to plot leg traces, or keep them seperate to just see how the joints move 
% through space. Can plot any set of steps. To only plot specific speeds,  
% filter before running this function. 
% 
% params:
% idxs = mxn cell where m is a set of steps to be averaged together (i.e. control or experimental steps) and n is for each leg. 
%     Ex: for leg = 1:param.numLegs
%             idxs{1,leg} = find(steps.leg(leg).meta.avg_stim == 0); %ctl steps
%             idxs{2,leg} = find(steps.leg(leg).meta.avg_stim > 0); %exp steps
%         end
% steps = steps structure, output of steps(...).m
% walkingData = parquet summary file where bout number != nan.
% connected = t/f: true connects the joints (plots leg trajectories), false plots trajectory of the joints. 
% legs = legs to plot. ex: legs = {'L1','L2','L3','R2','R3'};
% joints = joints to plot. ex: joints = {'A','B','C','D','E'};
% param = output from  DLC_load_params
% plotColors = a set of colors for plotting the set of averages. Can set to empty cell {}
%       to plot each leg it's own color, but this won't distinguish btw
%       avgs. If using plotColors, there should be as many colors as m (the
%       height of idxs). 
%           Ex: plotColors = {'white', 'red'};
%           Ex: plotColors = {};
%
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
            for group = 1:height(idxs) %set could be exp vs ctl
            
%                 E_y_phase = vertcat(steps.leg(legNum).meta.tarsus_y_phase{idxs{group,legNum}})'; %tarsi tip phase 
                E_y_phase = data.([legs{leg} 'E_y_phase'])(vertcat(steps.leg(legNum).meta.dataStepIdxs{idxs{group,legNum}}))';

                X1 = data.([legs{leg} joints{jnt} '_x'])(vertcat(steps.leg(legNum).meta.dataStepIdxs{idxs{group,legNum}}))';
                X2 = data.([legs{leg} joints{jnt+1} '_x'])(vertcat(steps.leg(legNum).meta.dataStepIdxs{idxs{group,legNum}}))';
                Y1 = data.([legs{leg} joints{jnt} '_y'])(vertcat(steps.leg(legNum).meta.dataStepIdxs{idxs{group,legNum}}))';
                Y2 = data.([legs{leg} joints{jnt+1} '_y'])(vertcat(steps.leg(legNum).meta.dataStepIdxs{idxs{group,legNum}}))';
                Z1 = data.([legs{leg} joints{jnt} '_z'])(vertcat(steps.leg(legNum).meta.dataStepIdxs{idxs{group,legNum}}))';
                Z2 = data.([legs{leg} joints{jnt+1} '_z'])(vertcat(steps.leg(legNum).meta.dataStepIdxs{idxs{group,legNum}}))';

                phase_avg_x1 = nan(1,width(phaseBinEdges)-1);
                phase_avg_x2 = nan(1,width(phaseBinEdges)-1);
                phase_avg_y1 = nan(1,width(phaseBinEdges)-1);
                phase_avg_y2 = nan(1,width(phaseBinEdges)-1);
                phase_avg_z1 = nan(1,width(phaseBinEdges)-1);
                phase_avg_z2 = nan(1,width(phaseBinEdges)-1);

                for ph = 1:width(phase_avg_x1) %plot avg leg segment across each phase bin 
                    if ~isempty(plotColors) %plot each line with corresponding group color
                        line([mean(X1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(X2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
                             [mean(Y1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(Y2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
                             [mean(Z1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(Z2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
                             'Color', [Color(plotColors{group}), alpha]);
                    else %plot each line with leg/joint color below
                        line([mean(X1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(X2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
                            [mean(Y1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(Y2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
                            [mean(Z1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(Z2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
                            'Color', [[kolor(:,jnt,leg)]', alpha]);
                    end
                end
            end
        end
    else %plot joints seperated
        for jnt = 1:width(joints)
            for group = 1:height(idxs) %set could be exp vs ctl

                E_y_phase = data.([legs{leg} 'E_y_phase'])(vertcat(steps.leg(legNum).meta.dataStepIdxs{idxs{group,legNum}}))';
                X = data.([legs{leg} joints{jnt} '_x'])(vertcat(steps.leg(legNum).meta.dataStepIdxs{idxs{group,legNum}}))';
                Y = data.([legs{leg} joints{jnt} '_y'])(vertcat(steps.leg(legNum).meta.dataStepIdxs{idxs{group,legNum}}))';
                Z = data.([legs{leg} joints{jnt} '_z'])(vertcat(steps.leg(legNum).meta.dataStepIdxs{idxs{group,legNum}}))';

                phase_avg_x = nan(1,width(phaseBinEdges)-1);
                phase_avg_y = nan(1,width(phaseBinEdges)-1);
                phase_avg_z = nan(1,width(phaseBinEdges)-1);
                for ph = 1:width(phase_avg_x) %plot avg joint trajectory for each phase bin
                    phase_avg_x(ph) = mean(X(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)));
                    phase_avg_y(ph) = mean(Y(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)));
                    phase_avg_z(ph) = mean(Z(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)));
                end

                if  ~isempty(plotColors) %plot each line with corresponding group color
                    for ph = 1:width(phase_avg_x)-1
                       plot3([phase_avg_x(ph),phase_avg_x(ph+1)], [phase_avg_y(ph),phase_avg_y(ph+1)], [phase_avg_z(ph),phase_avg_z(ph+1)], 'linewidth', LW, 'color', [Color(plotColors{group}), alpha]);
                    end
                else %plot with leg/jnt color
                    plot3(phase_avg_x, phase_avg_y, phase_avg_z,'linewidth', LW, 'color', [[kolor(:,jnt,leg)]', alpha]);
                end
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

fig = formatFig(fig, true);

