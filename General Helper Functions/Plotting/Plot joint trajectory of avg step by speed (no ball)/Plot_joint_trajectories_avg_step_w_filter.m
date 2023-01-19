function Plot_joint_trajectories_avg_step_w_filter(steps, idxs, walkingData, legs, joints, connected, param, colorFilter, filterVar, filterNumBins)

% for leg = 1:param.numLegs; idxs{leg} = {1:height(steps.leg(leg).meta)}; end
% legs = {'L1','L2','L3', 'R1','R2','R3'};
% joints = {'A','B','C','D','E'};
% Plot_joint_trajectories_avg_step_w_filter(steps, idxs, walkingData, legs, joints, false, param, true, 'avg_speed_x', 4)

% for leg = 1:param.numLegs; idxs{leg} = {find(steps.leg(leg).meta.avg_speed_y > 3)}; end
% legs = {'L1','L2','L3', 'R1','R2','R3'};
% joints = {'A','B','C','D','E'};
% Plot_joint_trajectories_avg_step_w_filter(steps, idxs, walkingData, legs, joints, false, param, true, 'avg_speed_y', 5)

% Plot average joint position x phase for a set of steps. Can connect the joints
% to plot leg traces, or keep them seperate to just see how the joints move 
% through space. Can plot any set of steps. To only plot specific speeds,  
% filter before running this function. 
% 
% params:
% idxs = indices in steps.leg(#).meta , needs indices for each leg, can leave a leg nan if not plotting that leg. 
%     Ex: idxs = {{1:100}, {2:200}, {1:150}, {1}, {4:400}, {7:600}}  --> order is: {{L1}, {L2}, {L3}, {R1}, {R2}, {R3}}
% steps = steps structure, output of steps(...).m
% walkingData = parquet summary file where bout number != nan.
% connected = t/f: true connects the joints (plots leg trajectories), false plots trajectory of the joints. 
% legs = legs to plot. ex: legs = {'L1','L2','L3','R2','R3'};
% joints = joints to plot. ex: joints = {'A','B','C','D','E'};
% param = output from  DLC_load_params
% colorFilter = t/f. true = plots the data with color as the filter. false = plots the data with color corresponding to the leg/joint. 
% filterVar = a var name in steps.leg().meta such as 'avg_speed_x' or even 'step_length'
% filterNumBins = number of bins for filtering by filterVar e.g. 3
%
% Sarah Walling-Bell
% Spring, 2022

minInBin = 50; %the min number of steps in a filter bin for it to be plotted. 

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
LW = 2;
alpha = 1;


%phase bins
phaseBinEdges = [-pi:0.25:pi, pi];
phaseColors = jet(width(phaseBinEdges)-1);

%filter var bins
minFilt = min(steps.leg(1).meta.(filterVar)); 
maxFilt = max(steps.leg(1).meta.(filterVar));
for leg = 2:param.numLegs
    if min(steps.leg(leg).meta.(filterVar)) < minFilt
        minFilt = min(steps.leg(leg).meta.(filterVar));
    end
    if max(steps.leg(leg).meta.(filterVar)) > maxFilt
        maxFilt = max(steps.leg(leg).meta.(filterVar));
    end   
end
filterBinEdges = linspace(minFilt,maxFilt,filterNumBins+1); 
filterColors = jet(filterNumBins);
newIdxs = []; % leg x bins matrix with indices into steps
for leg = 1:width(idxs)
    for filt = 1:filterNumBins
        newIdxs{leg, filt} = intersect(cell2mat(idxs{leg})', find(steps.leg(leg).meta.(filterVar) >= filterBinEdges(filt) & steps.leg(leg).meta.(filterVar) < filterBinEdges(filt+1)));
    end
end


%plot the data 
fig = fullfig; hold on 
for leg = 1:width(legs)
    legNum = find(contains(param.legs, legs(leg)));
    if connected %plot joints connected 
        for jnt = 1:width(joints)-1
            for filt = 1:filterNumBins
                
                %check that there are at least 100 steps in this filter bin
                if height(newIdxs{legNum, filt}) > minInBin
                
                    E_y_phase = vertcat(steps.leg(legNum).meta.tarsus_y_phase{newIdxs{legNum, filt}})'; %tarsi tip phase 

                    X1 = walkingData.([legs{leg} joints{jnt} '_x'])([steps.leg(legNum).meta.walkingDataStepIdxs{newIdxs{legNum, filt}}])';
                    X2 = walkingData.([legs{leg} joints{jnt+1} '_x'])([steps.leg(legNum).meta.walkingDataStepIdxs{newIdxs{legNum, filt}}])';
                    Y1 = walkingData.([legs{leg} joints{jnt} '_y'])([steps.leg(legNum).meta.walkingDataStepIdxs{newIdxs{legNum, filt}}])';
                    Y2 = walkingData.([legs{leg} joints{jnt+1} '_y'])([steps.leg(legNum).meta.walkingDataStepIdxs{newIdxs{legNum, filt}}])';
                    Z1 = walkingData.([legs{leg} joints{jnt} '_z'])([steps.leg(legNum).meta.walkingDataStepIdxs{newIdxs{legNum, filt}}])';
                    Z2 = walkingData.([legs{leg} joints{jnt+1} '_z'])([steps.leg(legNum).meta.walkingDataStepIdxs{newIdxs{legNum, filt}}])';

                    phase_avg_x1 = nan(1,width(phaseBinEdges)-1);
                    phase_avg_x2 = nan(1,width(phaseBinEdges)-1);
                    phase_avg_y1 = nan(1,width(phaseBinEdges)-1);
                    phase_avg_y2 = nan(1,width(phaseBinEdges)-1);
                    phase_avg_z1 = nan(1,width(phaseBinEdges)-1);
                    phase_avg_z2 = nan(1,width(phaseBinEdges)-1);

                    for ph = 1:width(phase_avg_x1) %plot avg leg segment across each phase bin 
                        if colorFilter %plot each line with corresponding phase color
                            line([mean(X1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(X2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
                                [mean(Y1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(Y2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
                                [mean(Z1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(Z2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
                                'Color', [filterColors(filt, :), alpha]);                        

    %                         line([mean(X1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(X2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
    %                              [mean(Y1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(Y2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
    %                              [mean(Z1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(Z2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
    %                              'Color', [phaseColors(ph,:), alpha]);
                        else %plot each line with leg/joint color below
                            line([mean(X1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(X2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
                                [mean(Y1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(Y2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
                                [mean(Z1(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1))); mean(Z2(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)))], ...
                                'Color', [[kolor(:,jnt,leg)]', alpha]);
                        end
                    end
                end
            end
        end
    else %plot joints seperated
        for jnt = 1:width(joints)
            for filt = 1:filterNumBins
                
                %check that there are at least 100 steps in this filter bin
                if height(newIdxs{legNum, filt}) > minInBin
                
                    E_y_phase = vertcat(steps.leg(legNum).meta.tarsus_y_phase{newIdxs{legNum, filt}})'; %tarsi tip phase 
                    X = walkingData.([legs{leg} joints{jnt} '_x'])([steps.leg(legNum).meta.walkingDataStepIdxs{newIdxs{legNum, filt}}])';
                    Y = walkingData.([legs{leg} joints{jnt} '_y'])([steps.leg(legNum).meta.walkingDataStepIdxs{newIdxs{legNum, filt}}])';
                    Z = walkingData.([legs{leg} joints{jnt} '_z'])([steps.leg(legNum).meta.walkingDataStepIdxs{newIdxs{legNum, filt}}])';

                    phase_avg_x = nan(1,width(phaseBinEdges)-1);
                    phase_avg_y = nan(1,width(phaseBinEdges)-1);
                    phase_avg_z = nan(1,width(phaseBinEdges)-1);
                    for ph = 1:width(phase_avg_x) %plot avg joint trajectory for each phase bin
                        phase_avg_x(ph) = mean(X(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)));
                        phase_avg_y(ph) = mean(Y(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)));
                        phase_avg_z(ph) = mean(Z(E_y_phase >=phaseBinEdges(ph) & E_y_phase < phaseBinEdges(ph+1)));
                    end

                    if colorFilter %plot with phase color 
                        for ph = 1:width(phase_avg_x)-1
                            plot3(phase_avg_x, phase_avg_y, phase_avg_z,'linewidth', LW, 'color', [filterColors(filt, :), alpha]);
    %                        plot3([phase_avg_x(ph),phase_avg_x(ph+1)], [phase_avg_y(ph),phase_avg_y(ph+1)], [phase_avg_z(ph),phase_avg_z(ph+1)], 'linewidth', LW, 'color', [phaseColors(ph,:), alpha]);
                        end
                    else %plot with leg/jnt color
                        plot3(phase_avg_x, phase_avg_y, phase_avg_z,'linewidth', LW, 'color', [[kolor(:,jnt,leg)]', alpha]);
                    end
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

if colorFilter
   colormap(filterColors)
   cb = colorbar('Ticks', (filterBinEdges+abs(min(filterBinEdges)))/max(filterBinEdges+abs(min(filterBinEdges))), 'TickLabels',string(filterBinEdges), 'FontSize', 20, 'color', Color(param.baseColor), 'Box', 'off');
   cb.Label.String = strrep(filterVar, '_', ' ');
end


fig = formatFig(fig, true);


