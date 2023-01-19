function joint_x_phase_plot_rot_vel_binned_exp_minus_ctl(data, steps, flies, param, joint, phase, tossSmallBins, minNumSteps, velocityBins, laserColor, fig_name, varargin)

% plot average joint x speed for ctl vs stim binned by forward velocity. 
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
            add = true;
            switch lower(varargin{ii}(2:end))
                case 'ctl_data'
                    data_ctl = varargin{ii+1}; add = false;
                case 'ctl_steps'
                    steps_ctl = varargin{ii+1}; add = false;
                case 'ctl_flies'
                    flies_ctl = varargin{ii+1}; add = false;
                case 'ctl_param'
                    param_ctl = varargin{ii+1}; add = false;
            end
            if add
                vararginList.Var(idx) = varargin{ii+1}; 
                vararginList.VarName{idx} = lower(varargin{ii}(2:end)); 
                idx = idx+1;
            end
            

        end
    end
end
if ~exist("vararginList", "var"); numArgs = 0; 
else; numArgs = width(vararginList.Var); end

%determine whether plotting ctl data
if exist('data_ctl', 'var') & exist('steps_ctl', 'var') & exist('flies_ctl', 'var') & exist('param_ctl', 'var')
    plot_ctl_data = true; 
else
    plot_ctl_data = false; 
end


numSpeedBins = width(velocityBins)-1;
numSpeedBinsCW = sum(velocityBins <= 0)-1; 
numSpeedBinsCCW = sum(velocityBins >= 0)-1;
numSpeedBinsStraight = numSpeedBins - (numSpeedBinsCW+numSpeedBinsCCW);
colors = {};
cidx = 0;
for c = 1:numSpeedBinsCW; cidx=cidx+1; colors{cidx} = 'yellow'; end
for c = 1:numSpeedBinsStraight; cidx=cidx+1; colors{cidx} = 'green'; end
for c = 1:numSpeedBinsCCW; cidx=cidx+1; colors{cidx} = 'DodgerBlue'; end

alphas = [linspace(1, 0.4, numSpeedBinsCW), linspace(0.4, 0.4, numSpeedBinsStraight), linspace(0.4, 1, numSpeedBinsCCW)];
% alphas = linspace(0.4, 1, numSpeedBins);

fig = fullfig; 
legOrder = [4,5,6,1,2,3];

for leg = 1:param.numLegs
    subplot(2,3,legOrder(leg));
    yline(0, ':', 'Color', 'white', 'LineWidth', 2); hold on; %plot 0 line


     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % get step idxs for this leg within any speed range provided (optional)
    stepIdxs = find(contains(steps.leg(leg).meta.fly, flies)); %step from chosen flies
    if plot_ctl_data; stepIdxsCtl = find(contains(steps_ctl.leg(leg).meta.fly, flies_ctl)); end %step from chosen flies
    for speed_var = 1:numArgs
        varName = vararginList.VarName{speed_var};
        dir = varName(1);
        if contains(varName, 'min')
            if contains(varName, 'abs')
                %min abs
                tempIdxs = find(abs(steps.leg(leg).meta.(['avg_speed_' dir])) > vararginList.Var(speed_var));
                stepIdxs = intersect(stepIdxs,tempIdxs);
                if plot_ctl_data
                    tempIdxsCtl = find(abs(steps_ctl.leg(leg).meta.(['avg_speed_' dir])) > vararginList.Var(speed_var));
                    stepIdxsCtl = intersect(stepIdxsCtl,tempIdxsCtl);
                end
            else
                %normal min
                tempIdxs = find(steps.leg(leg).meta.(['avg_speed_' dir]) > vararginList.Var(speed_var));
                stepIdxs = intersect(stepIdxs,tempIdxs);
                if plot_ctl_data
                    tempIdxsCtl = find(steps_ctl.leg(leg).meta.(['avg_speed_' dir]) > vararginList.Var(speed_var));
                    stepIdxsCtl = intersect(stepIdxsCtl,tempIdxsCtl);
                end
            end
        elseif contains(varName, 'max')
            if contains(varName, 'abs')
                %max abs
                tempIdxs = find(abs(steps.leg(leg).meta.(['avg_speed_' dir])) < vararginList.Var(speed_var));
                stepIdxs = intersect(stepIdxs,tempIdxs);
                if plot_ctl_data
                    tempIdxsCtl = find(abs(steps_ctl.leg(leg).meta.(['avg_speed_' dir])) < vararginList.Var(speed_var));
                    stepIdxsCtl = intersect(stepIdxsCtl,tempIdxsCtl);
                end
            else
                %normal max
                tempIdxs = find(steps.leg(leg).meta.(['avg_speed_' dir]) < vararginList.Var(speed_var));
                stepIdxs = intersect(stepIdxs,tempIdxs);
                if plot_ctl_data
                    tempIdxsCtl = find(steps_ctl.leg(leg).meta.(['avg_speed_' dir]) < vararginList.Var(speed_var));
                    stepIdxsCtl = intersect(stepIdxsCtl,tempIdxsCtl);
                end
            end
        end
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    for speed = 1:numSpeedBins

        idxs_ctl = find(steps.leg(leg).meta.avg_speed_z > velocityBins(speed) & ...
                        steps.leg(leg).meta.avg_speed_z < velocityBins(speed+1) & ...
                        steps.leg(leg).meta.percent_stim == 0); %steps with this forward speed bin
        idxs_ctl = intersect(stepIdxs, idxs_ctl); %steps with this forward speed bin also with previous speed & fly binning
        idxs_exp = find(steps.leg(leg).meta.avg_speed_z > velocityBins(speed) & ...
                        steps.leg(leg).meta.avg_speed_z < velocityBins(speed+1) & ...
                        steps.leg(leg).meta.percent_stim > 0); %steps with this forward speed bin
        idxs_exp = intersect(stepIdxs, idxs_exp); %steps with this forward speed bin also with previous speed & fly binning
        
        if plot_ctl_data
           idxs_ctl_ctl = find(steps_ctl.leg(leg).meta.avg_speed_z > velocityBins(speed) & ...
                           steps_ctl.leg(leg).meta.avg_speed_z < velocityBins(speed+1) & ...
                           steps_ctl.leg(leg).meta.percent_stim == 0); %steps with this forward speed bin
            idxs_ctl_ctl = intersect(stepIdxsCtl, idxs_ctl_ctl); %steps with this forward speed bin also with previous speed & fly binning
            idxs_exp_ctl = find(steps_ctl.leg(leg).meta.avg_speed_z > velocityBins(speed) & ...
                            steps_ctl.leg(leg).meta.avg_speed_z < velocityBins(speed+1) & ...
                            steps_ctl.leg(leg).meta.percent_stim > 0); %steps with this forward speed bin
            idxs_exp_ctl = intersect(stepIdxsCtl, idxs_exp_ctl); %steps with this forward speed bin also with previous speed & fly binning
        end 

        numSteps(leg, speed, 2) = height(idxs_exp);    
        numSteps(leg, speed, 1) = height(idxs_ctl);  
        numStepsCtl(leg, speed, 2) = height(idxs_exp_ctl);    
        numStepsCtl(leg, speed, 1) = height(idxs_ctl_ctl);  
        
        plotSpeedData = true;
        if tossSmallBins
            if numSteps(leg,speed,1) < minNumSteps | numSteps(leg,speed,2) < minNumSteps | ...
               numStepsCtl(leg,speed,1) < minNumSteps | numStepsCtl(leg,speed,2) < minNumSteps
                plotSpeedData = false; %don't plot data in this speed bin since some of the data has too few steps
            end
        end

        if plotSpeedData
            %bin data
            joint_data_exp = data.([param.legs{leg} joint])(vertcat(steps.leg(leg).meta.dataStepIdxs{idxs_exp}));
            phase_data_exp = data.([param.legs{leg} phase])(vertcat(steps.leg(leg).meta.dataStepIdxs{idxs_exp}));
            joint_data_ctl = data.([param.legs{leg} joint])(vertcat(steps.leg(leg).meta.dataStepIdxs{idxs_ctl}));
            phase_data_ctl = data.([param.legs{leg} phase])(vertcat(steps.leg(leg).meta.dataStepIdxs{idxs_ctl}));
            if plot_ctl_data
                joint_data_exp_ctl = data_ctl.([param.legs{leg} joint])(vertcat(steps_ctl.leg(leg).meta.dataStepIdxs{idxs_exp_ctl}));
                phase_data_exp_ctl = data_ctl.([param.legs{leg} phase])(vertcat(steps_ctl.leg(leg).meta.dataStepIdxs{idxs_exp_ctl}));
                joint_data_ctl_ctl = data_ctl.([param.legs{leg} joint])(vertcat(steps_ctl.leg(leg).meta.dataStepIdxs{idxs_ctl_ctl}));
                phase_data_ctl_ctl = data_ctl.([param.legs{leg} phase])(vertcat(steps_ctl.leg(leg).meta.dataStepIdxs{idxs_ctl_ctl}));
            end

            %phase bins to take averages in
            numPhaseBins = 50;
            binWidth = 2*pi/numPhaseBins;
            phaseBins = -pi:binWidth:pi;
            phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot
    
            mean_joint_x_phase_ctl = NaN(1,numPhaseBins);
            mean_joint_x_phase_exp = NaN(1,numPhaseBins);
            numTrials = zeros(2, numPhaseBins);
            if plot_ctl_data
                mean_joint_x_phase_ctl_ctl = NaN(1,numPhaseBins);
                mean_joint_x_phase_exp_ctl = NaN(1,numPhaseBins);
                numTrials_ctl = zeros(2, numPhaseBins);
            end
    
            for ph = 1:numPhaseBins
                mean_joint_x_phase_ctl(ph) = mean(joint_data_ctl(phase_data_ctl >= phaseBins(ph) & phase_data_ctl < phaseBins(ph+1)));
                mean_joint_x_phase_exp(ph) = mean(joint_data_exp(phase_data_exp >= phaseBins(ph) & phase_data_exp < phaseBins(ph+1)));
                if plot_ctl_data
                    mean_joint_x_phase_ctl_ctl(ph) = mean(joint_data_ctl_ctl(phase_data_ctl_ctl >= phaseBins(ph) & phase_data_ctl_ctl < phaseBins(ph+1)));
                    mean_joint_x_phase_exp_ctl(ph) = mean(joint_data_exp_ctl(phase_data_exp_ctl >= phaseBins(ph) & phase_data_exp_ctl < phaseBins(ph+1)));
                end
            end
    
            %plot!
            ctlplt(speed) = plot(phaseBinCenters, smooth(smooth(mean_joint_x_phase_exp_ctl)-smooth(mean_joint_x_phase_ctl_ctl)), ':', 'color', [Color(colors{speed}) alphas(speed)], 'linewidth', 2); hold on;
            expplt(speed) = plot(phaseBinCenters, smooth(smooth(mean_joint_x_phase_exp)-smooth(mean_joint_x_phase_ctl)), 'color', [Color(colors{speed}) alphas(speed)], 'linewidth', 2);
            
            %save num steps
            numStepLabels{leg,speed,1} = [num2str(numSteps(leg, speed, 1)) ' ctl, ' num2str(numSteps(leg, speed, 2)) ' exp steps'];
            numStepLabels{leg,speed,2} = [num2str(numStepsCtl(leg, speed, 1)) ' ctl, ' num2str(numStepsCtl(leg, speed, 2)) ' exp steps'];
            speedBinLabels{speed} = [num2str(velocityBins(speed)) '-' num2str(velocityBins(speed+1)) ' mm/s'];
            
            %colors to plot fake points for legend fig
            fakePlot{leg,speed,1} = [Color(colors{speed}) alphas(speed)];
            fakePlot{leg,speed,2} = [Color(colors{speed}) alphas(speed)];
        
        end
    end
    
    ax = gca;
    ax.FontSize = 30;
    xticks([-pi, 0, pi]);
    xticklabels({'-\pi','0', '\pi'});
    
    if leg == 1
        ylabel(['\Delta' strrep(joint, '_', ' ') ' (' char(176) ')']);
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
            ctlplot(speed) = plot(0,0, ':','color',fakePlot{leg,speed,1}, 'LineWidth', 5); hold on
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
        cplot(speed) = plot(0,0,':','color',fakePlot{leg,speed,1}, 'LineWidth', 5); hold on
        eplot(speed) = plot(0,0,'color',fakePlot{leg,speed,2}, 'LineWidth', 5); hold on
    end
end
labels = [speedBinLabels speedBinLabels];
labels(~cellfun(@ischar,labels)) = [];
legend([cplot eplot], labels, 'TextColor', 'white', 'FontSize', 15, 'Location', 'best');legend('boxoff');
title('Speed bins', 'Color', param.baseColor, 'FontSize', 14);
axis off

figMeta = formatFig(figMeta, true, [2,4]); 
h = axes(figMeta,'visible','off'); 
hold off

%save
save_figure(figMeta, [param.googledrivesave fig_name '_meta'], param.fileType);


end