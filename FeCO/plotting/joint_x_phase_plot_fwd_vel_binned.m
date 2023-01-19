function joint_x_phase_plot_fwd_vel_binned(data, steps, flies, param, joint, phase, tossSmallBins, minNumSteps, velocityBins, laserColor, fig_name, varargin)

%plot average joint x speed for ctl vs stim binned by forward velocity. 
%
% Optional params:
%     '-x_min' = minimum sideslip velocity for steps 
%     '-x_max' = maximum sideslip velocity for steps 
%     '-x_min_abs' = minimum abs val of sideslip velocity for steps 
%     '-x_max_abs' = maximum abs val of sideslip velocity for steps 
%     -same as above for y (forward velocity) and z (rotational velocity) 

%parse optional params    
idx = 1;
for ii = 1:width(varargin)
    if ischar(varargin{ii}) && ~isempty(varargin{ii})
        if varargin{ii}(1) == '-' %find command descriptions
            vararginList.Var(idx) = varargin{ii+1}; 
            vararginList.VarName{idx} = lower(varargin{ii}(2:end)); 
            idx = idx+1;
        end
    end
end
if ~exist("vararginList", "var"); numArgs = 0; 
else; numArgs = width(vararginList.Var); end




numSpeedBins = width(velocityBins)-1;
alphas = linspace(0.4, 1, numSpeedBins);

fig = fullfig; 
legOrder = [4,5,6,1,2,3];

for leg = 1:param.numLegs
    AX(leg) = subplot(2,3,legOrder(leg)); 

     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % get step idxs for this leg within any speed range provided (optional)
    stepIdxs = find(contains(steps.leg(leg).meta.fly, flies)); %step from chosen flies
    for speed_var = 1:numArgs
        varName = vararginList.VarName{speed_var};
        dir = varName(1);
        if contains(varName, 'min')
            if contains(varName, 'abs')
                %min abs
                tempIdxs = find(abs(steps.leg(leg).meta.(['avg_speed_' dir])) > vararginList.Var(speed_var));
                stepIdxs = intersect(stepIdxs,tempIdxs);
            else
                %normal min
                tempIdxs = find(steps.leg(leg).meta.(['avg_speed_' dir]) > vararginList.Var(speed_var));
                stepIdxs = intersect(stepIdxs,tempIdxs);
            end
        elseif contains(varName, 'max')
            if contains(varName, 'abs')
                %max abs
                tempIdxs = find(abs(steps.leg(leg).meta.(['avg_speed_' dir])) < vararginList.Var(speed_var));
                stepIdxs = intersect(stepIdxs,tempIdxs);
            else
                %normal max
                tempIdxs = find(steps.leg(leg).meta.(['avg_speed_' dir]) < vararginList.Var(speed_var));
                stepIdxs = intersect(stepIdxs,tempIdxs);
            end
        end
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    for speed = 1:numSpeedBins

        idxs_ctl = find(steps.leg(leg).meta.avg_speed_y > velocityBins(speed) & ...
                        steps.leg(leg).meta.avg_speed_y < velocityBins(speed+1) & ...
                        steps.leg(leg).meta.percent_stim == 0); %steps with this forward speed bin
        idxs_ctl = intersect(stepIdxs, idxs_ctl); %steps with this forward speed bin also with previous speed & fly binning
        idxs_exp = find(steps.leg(leg).meta.avg_speed_y > velocityBins(speed) & ...
                        steps.leg(leg).meta.avg_speed_y < velocityBins(speed+1) & ...
                        steps.leg(leg).meta.percent_stim > 0); %steps with this forward speed bin
        idxs_exp = intersect(stepIdxs, idxs_exp); %steps with this forward speed bin also with previous speed & fly binning

        numSteps(leg, speed, 2) = height(idxs_exp);    
        numSteps(leg, speed, 1) = height(idxs_ctl);  
        
        plotSpeedData = true;
        if tossSmallBins
            if numSteps(leg,speed,1) < minNumSteps | numSteps(leg,speed,2) < minNumSteps
                plotSpeedData = false; %don't plot data in this speed bin since some of the data has too few steps
            end
        end

        if plotSpeedData
            %bin data
            joint_data_exp = data.([param.legs{leg} joint])(vertcat(steps.leg(leg).meta.dataStepIdxs{idxs_exp}));
            phase_data_exp = data.([param.legs{leg} phase])(vertcat(steps.leg(leg).meta.dataStepIdxs{idxs_exp}));
            joint_data_ctl = data.([param.legs{leg} joint])(vertcat(steps.leg(leg).meta.dataStepIdxs{idxs_ctl}));
            phase_data_ctl = data.([param.legs{leg} phase])(vertcat(steps.leg(leg).meta.dataStepIdxs{idxs_ctl}));
            
            %phase bins to take averages in
            numPhaseBins = 50;
            binWidth = 2*pi/numPhaseBins;
            phaseBins = -pi:binWidth:pi;
            phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot
    
            mean_joint_x_phase_ctl = NaN(1,numPhaseBins);
            mean_joint_x_phase_exp = NaN(1,numPhaseBins);
            numTrials = zeros(2, numPhaseBins);
    
            for ph = 1:numPhaseBins
                mean_joint_x_phase_ctl(ph) = mean(joint_data_ctl(phase_data_ctl >= phaseBins(ph) & phase_data_ctl < phaseBins(ph+1)));
                mean_joint_x_phase_exp(ph) = mean(joint_data_exp(phase_data_exp >= phaseBins(ph) & phase_data_exp < phaseBins(ph+1)));
            end
    
            %plot!
            ctlplt(leg,speed) = plot(phaseBinCenters, smooth(mean_joint_x_phase_ctl), 'color', [Color(param.baseColor) alphas(speed)], 'linewidth', 2);hold on
            expplt(leg,speed) = plot(phaseBinCenters, smooth(mean_joint_x_phase_exp), 'color', [Color(laserColor) alphas(speed)], 'linewidth', 2);
            
            %save num steps
            numStepLabels{leg,speed,1} = [num2str(numSteps(leg, speed, 1)) ' ctl steps'];
            numStepLabels{leg,speed,2} = [num2str(numSteps(leg, speed, 2)) ' exp steps'];
            speedBinLabels{speed} = [num2str(velocityBins(speed)) '-' num2str(velocityBins(speed+1)) ' mm/s'];
            
            %colors to plot fake points for legend fig
            fakePlot{leg,speed,1} = [Color(param.baseColor) alphas(speed)];
            fakePlot{leg,speed,2} = [Color(laserColor) alphas(speed)];

        end
    end
        
    ax = gca;
    ax.FontSize = 30;
    xticks([-pi, 0, pi]);
    xticklabels({'-\pi','0', '\pi'});
    
    if leg == 1
        ylabel([strrep(joint, '_', ' ') ' (' char(176) ')']);
        xlabel(strrep(phase, '_', ' '));
    end
    
    title(param.legs{leg});
    hold off
end

fig = formatFig(fig, true, [2,3]); 
h = axes(fig,'visible','off'); 

hold off

%save 
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%new figure for fig metadata (step nums, speed bins) 
figMeta = fullfig; 
metaOrder = [5,6,7,1,2,3,4,8];
%plot leg step numbers
for leg = 1:param.numLegs
    subplot(2,4,metaOrder(leg));
    %plot dummy points
    for speed = 1:width(fakePlot(leg,:,1))
        if ~isempty(fakePlot{leg,speed,1})
            ctlplot(speed) = plot(0,0,'color',fakePlot{leg,speed,1}, 'LineWidth', 5); hold on
            expplot(speed) = plot(0,0,'color',fakePlot{leg,speed,2}, 'LineWidth', 5);
        end
    end
    labels = [numStepLabels(leg, :, 1) numStepLabels(leg, :, 2)];
    labels(~cellfun(@ischar,labels)) = [];
    legend([ctlplot expplot],labels, 'TextColor', 'white', 'FontSize', 15, 'Location', 'best');
    legend('boxoff');
    title(param.legs{leg}, 'Color', param.baseColor, 'FontSize', 14);
    axis off
end

%plot ctl + exp speed bins
subplot(2,4,metaOrder(leg+1))
for speed = 1:width(fakePlot(leg,:,1))
    if ~isempty(fakePlot{leg,speed,1})
        cplot(speed) = plot(0,0,'color',fakePlot{leg,speed,1}, 'LineWidth', 5); hold on
        eplot(speed) = plot(0,0,'color',fakePlot{leg,speed,2}, 'LineWidth', 5); hold on
    end
end
labels = [speedBinLabels speedBinLabels];
labels(~cellfun(@ischar,labels)) = [];
legend([cplot eplot],labels, 'TextColor', 'white', 'FontSize', 15, 'Location', 'best');
legend('boxoff');
title('Speed bins', 'Color', param.baseColor, 'FontSize', 14);
axis off

figMeta = formatFig(figMeta, true, [2,4]); 
h = axes(figMeta,'visible','off'); 
hold off

%save
save_figure(figMeta, [param.googledrivesave fig_name '_meta'], param.fileType);



end