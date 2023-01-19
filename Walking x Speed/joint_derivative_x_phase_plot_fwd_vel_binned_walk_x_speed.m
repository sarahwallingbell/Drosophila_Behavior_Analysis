function joint_derivative_x_phase_plot_fwd_vel_binned_walk_x_speed(data, steps, flies, param, joint, phase, derivative, tossSmallBins, minNumSteps, velocityBins, fig_name, varargin)

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
% alphas = linspace(0.4, 1, numSpeedBins);

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
    %colors for plotting speed binned averages
    colors = jet(numSpeedBins); %order: slow to fast

    %plot speed binned averages
    cmap = colormap(colors);

    for speed = 1:numSpeedBins

        idxs = find(steps.leg(leg).meta.avg_speed_y > velocityBins(speed) & ...
                    steps.leg(leg).meta.avg_speed_y < velocityBins(speed+1)); %steps with this forward speed bin
        idxs = intersect(stepIdxs, idxs); %steps with this forward speed bin also with previous speed & fly binning

        numSteps(leg, speed) = height(idxs);

        plotSpeedData = true;
        if tossSmallBins
            if numSteps(leg,speed) < minNumSteps
                plotSpeedData = false; %don't plot data in this speed bin since some of the data has too few steps
            end
        end

        if plotSpeedData
            %bin data
            joint_data = data.([param.legs{leg} joint])(vertcat(steps.leg(leg).meta.dataStepIdxs{idxs}));
            phase_data = data.([param.legs{leg} phase])(vertcat(steps.leg(leg).meta.dataStepIdxs{idxs}));

            %take derivative
            for d = 1:derivative
                joint_data = [diff(joint_data)/(1/param.fps); NaN];
            end
            
            %phase bins to take averages in
            numPhaseBins = 50;
            binWidth = 2*pi/numPhaseBins;
            phaseBins = -pi:binWidth:pi;
            phaseBinCenters = [-pi,phaseBins(2:end-2)+(binWidth/2),pi]; %set first and last to +-pi so line is full circle in plot
    
            mean_joint_x_phase = NaN(1,numPhaseBins);
            numTrials = zeros(numPhaseBins);
    
            for ph = 1:numPhaseBins
                mean_joint_x_phase(ph) = mean(joint_data(phase_data >= phaseBins(ph) & phase_data < phaseBins(ph+1)));
            end
    
            %plot!
            plt(leg,speed) = plot(phaseBinCenters, smooth(mean_joint_x_phase), 'color', colors(speed,:), 'linewidth', 2);hold on
            
            %save num steps
            numStepLabels{leg,speed} = [num2str(numSteps(leg, speed)) ' steps'];
            speedBinLabels{speed} = [num2str(velocityBins(speed)) '-' num2str(velocityBins(speed+1)) ' mm/s'];
            
            %colors to plot fake points for legend fig
            fakePlot{leg,speed} = colors(speed,:);

        end
    end
        
    ax = gca;
    ax.FontSize = 30;
    xticks([-pi, 0, pi]);
    xticklabels({'-\pi','0', '\pi'});
    
    if leg == 1
        if derivative == 0
            ylabel([strrep(joint, '_', ' ') ' (' char(176) ')']);
        elseif derivative == 1
            ylabel([strrep(joint, '_', ' ') ' (' char(176) '/s)']);
        elseif derivative == 2
            ylabel([strrep(joint, '_', ' ') ' (' char(176) '/s^2)']);
        elseif derivative == 3
            ylabel([strrep(joint, '_', ' ') ' (' char(176) '/s^3)']);
        end
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%new figure for fig metadata (step nums, speed bins) 
figMeta = fullfig; 
metaOrder = [5,6,7,1,2,3,4,8];
%plot leg step numbers
for leg = 1:param.numLegs
    subplot(2,4,metaOrder(leg));
    %plot dummy points
    s = 0; 
    for speed = 1:width(fakePlot(leg,:))
        if ~isempty(fakePlot{leg,speed})
            s = s+1;
            plott(s) = plot(0,0,'color',fakePlot{leg,speed}, 'LineWidth', 5); hold on
        end
    end
    labels = numStepLabels(leg, :);
    labels(~cellfun(@ischar,labels)) = [];
    legend(plott, labels, 'TextColor', 'white', 'FontSize', 15, 'Location', 'best',  'NumColumns', 2);
    legend('boxoff');
    title(param.legs{leg}, 'Color', param.baseColor, 'FontSize', 14);
    axis off
end

%plot ctl + exp speed bins
subplot(2,4,metaOrder(leg+1))
s = 0; 
for speed = 1:width(fakePlot(leg,:))
    if ~isempty(fakePlot{leg,speed})
        s = s+1;
        pplot(s) = plot(0,0,'color',fakePlot{leg,speed}, 'LineWidth', 5); hold on
    end
end
labels = speedBinLabels;
labels(~cellfun(@ischar,labels)) = [];
legend(pplot, labels, 'TextColor', 'white', 'FontSize', 15, 'Location', 'best', 'NumColumns', 2);
legend('boxoff');
title('Speed bins', 'Color', param.baseColor, 'FontSize', 14);
axis off

figMeta = formatFig(figMeta, true, [2,4]); 
h = axes(figMeta,'visible','off'); 
hold off

%save
save_figure(figMeta, [param.googledrivesave fig_name '_meta'], param.fileType);



end