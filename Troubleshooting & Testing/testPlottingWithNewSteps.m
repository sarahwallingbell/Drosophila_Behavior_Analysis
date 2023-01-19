




%% MEAN Joint x Phase, all joints, all legs, across flies, color by Foward speed - cartesian coordinates

clearvars('-except',initial_vars{:}); initial_vars = who;

%params
numSpeedBins = 10; %THIS IS THE PARAMETER FOR NUMBER OF SPEED BINS TO HAVE!!! 
tossSmallBins = true; % doesn't plot data for speed bins with little data. Makes for a cleaner looking plot. 
minAvgSteps = 200; %if tossSmallBins == true, the speed bin must average this many data points across phases to plot it

joints = {'A_flex', 'B_flex', 'C_flex', 'D_flex'};
% phases = {'BC_phase', 'CF_phase', 'FTi_phase', 'TiTa_phase'};
phases = {'E_y_phase', 'E_y_phase', 'E_y_phase', 'E_y_phase'};


max_speed_x = 3;
min_speed_y = 10; 
max_speed_z = 3;

numPhaseBins = 20;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = 'avg_speed_y'; %var in steps.meta

fig = fullfig; 
legOrder = [1,7,13,19,2,8,14,20,3,9,15,21,4,10,16,22,5,11,17,23,6,12,18,24];
maxSpeed = 30;
binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;

%phase bins to take averages in
binWidth = 2*pi/numPhaseBins;
phaseBins = -pi:binWidth:pi;
phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot

i = 0;
for leg = 1:param.numLegs

    % get step idxs for this leg witin speed range
    stepIdxs = find(abs(steps.leg(leg).meta.avg_speed_x) < max_speed_x & ...
                        steps.leg(leg).meta.avg_speed_y > min_speed_y & ...
                    abs(steps.leg(leg).meta.avg_speed_z) < max_speed_z);
    
    %get speed data & bin it
    speed_data = steps.leg(leg).meta.(color)(stepIdxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    for joint = 1:param.numJoints
        i = i+1;
        subplot(param.numJoints,param.numLegs,legOrder(i)); 

        %structs to fill with joint data 
        mean_joint_x_phase = NaN(numSpeedBins, numPhaseBins);
        numTrials = zeros(numSpeedBins, numPhaseBins);
        numFlies = zeros(numSpeedBins, 1);
        numSteps = zeros(numSpeedBins, 1);

        for sb = 1:numSpeedBins
            %get frame idxs in data for steps within this speed bin 
            these_step_idxs = stepIdxs(bins == sb); %TODO does this work or do I need to select btw binEdges?
            dataIdxs = vertcat(steps.leg(leg).meta.dataStepIdxs{these_step_idxs});

            %data
            joint_data = data.([param.legs{leg} joints{joint}])(dataIdxs);
            phase_data = data.([param.legs{leg} phases{joint}])(dataIdxs);
            fly_data = {steps.leg(leg).meta.fly{bins == sb}};
            
            %how many steps from how many flies 
            numSteps(sb) = sum(bins == sb);
            numFlies(sb) = width(unique(fly_data));
    
            for pb = 1:numPhaseBins
                %note: the way I average now could include multiple joint angles from a step within a phaseBin average
                mean_joint_x_phase(sb,pb) = mean(joint_data(phase_data >= phaseBins(pb) & phase_data < phaseBins(pb+1)), 'omitnan');
                numTrials(sb,pb) = height(joint_data(phase_data >= phaseBins(pb) & phase_data < phaseBins(pb+1)));
            end
        end
        
        if tossSmallBins
            %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
            for sb = 1:numSpeedBins
                if mean(numTrials(sb,:)) < minAvgSteps
                    mean_joint_x_phase(sb,:) = NaN; %'erase' these values so they aren't plotted
                end
            end
        end
    
        %colors for plotting speed binned averages
        colors = jet(numSpeedBins); %order: slow to fast
    
        %plot speed binned averages
        cmap = colormap(colors);
        for sb = 1:numSpeedBins
    %         p = polarplot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
%             plot(phaseBinCenters, smooth(mean_joint_x_phase(sb,:)), 'color', colors(sb,:), 'linewidth', 2);hold on
            plot(phaseBinCenters, mean_joint_x_phase(sb,:), 'color', colors(sb,:), 'linewidth', 2);hold on
        end
    
        
        ax = gca;
        ax.FontSize = 20;
        xticks([-pi, 0, pi]);
        
        if leg == 1
            ylabel([joints{joint} ' (' char(176) ')']);

        end
        if joint == 4
            xlabel(param.legs{leg});
            xticklabels({'-\pi','0', '\pi'});
        else
            xticklabels([]);
        end
        hold off
    end
end

fig = formatFig(fig, true, [param.numJoints, param.numLegs]); 

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    tickLabels{t} = num2str(binEdges(t)); 
end
c = colorbar(h,'Position',[0.92 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
c.Label.String = 'Forward velocity (mm/s)';
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        

hold off

%save 
fig_name = ['\all_joints_x_leg_phase_allLegs_averages_binnedByForwardSpeed - ' num2str(numSpeedBins) '_bins - speed range x_below_' num2str(max_speed_x) ' y_above_' num2str(min_speed_y) ' z_below_' num2str(max_speed_z) ' - allFlies - graphCoords'];
if tossSmallBins; fig_name = [fig_name, '_tossedSpeedBinsUnder' num2str(minAvgSteps) 'Steps']; end
save_figure(fig, [param.googledrivesave fig_name], param.fileType);
% save_figure(fig, [path fig_name], param.fileType);

clearvars('-except',initial_vars{:}); initial_vars = who;



