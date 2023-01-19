function plotStepMetricsxVelocity(steps, param, metric, velocity, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, varargin)

% ex: plotStepMetricsxVelocity(steps, param, 'step_length', 'avg_speed_y', flyList.flyid, 'figName', 10, 200, 30);

% plot a step metric speed binned across forward velocity 
% Sarah Walling-Bell 
% November 2022

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
    
%begin plotting code

color = velocity; %var in steps.meta

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
if contains(velocity, 'y')
    binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;
elseif contains(velocity, 'z')
    binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;
end

dotSize = 100;

for leg = 1:param.numLegs
    subplot(2,3,legOrder(leg)); 

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
            end
            %normal min
            tempIdxs = find(steps.leg(leg).meta.(['avg_speed_' dir]) > vararginList.Var(speed_var));
            stepIdxs = intersect(stepIdxs,tempIdxs);
        elseif contains(varName, 'max')
            if contains(varName, 'abs')
                %max abs
                tempIdxs = find(abs(steps.leg(leg).meta.(['avg_speed_' dir])) < vararginList.Var(speed_var));
                stepIdxs = intersect(stepIdxs,tempIdxs);
            end
            %normal max
            tempIdxs = find(steps.leg(leg).meta.(['avg_speed_' dir]) < vararginList.Var(speed_var));
            stepIdxs = intersect(stepIdxs,tempIdxs);
        end
    end

    %get speed data & bin it
    leg_data = steps.leg(leg).meta.(metric)(stepIdxs);
    speed_data = steps.leg(leg).meta.(color)(stepIdxs);
    [bins,binEdges] = discretize(speed_data, binEdges);
    

    %counting flies
    fly_data = steps.leg(leg).meta.fly(stepIdxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data = NaN(numSpeedBins, 1);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data = leg_data(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data(sb) = mean(binned_leg_data, 'omitnan');
        numTrials(sb) = height(binned_leg_data);
    end
    
    %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
    for sb = 1:numSpeedBins
        if mean(numTrials(sb)) < minAvgSteps
            mean_leg_data(sb) = NaN; %'erase' these values so they aren't plotted
        end
    end
    
    %colors for plotting speed binned averages
    colors = jet(numSpeedBins); %order: slow to fast

    %plot speed binned averages
    cmap = colormap(colors);
    scatter(binEdges(2:end), mean_leg_data, dotSize, 'filled'); hold on
    
    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        ylabel([strrep(metric, '_', ' ') ' (L1 coxa length)']);
        if contains(velocity, 'x')
            xlabel('Sideslip velocity (mm/s)')
        elseif contains(velocity, 'y')
            xlabel('Forward velocity (mm/s)')
        elseif contains(velocity, 'z')
            xlabel('Rotational velocity (mm/s)')
        end
    end
    title(param.legs{leg});

    hold off
end

fig = formatFig(fig, true, [2,3]);      

hold off

%save 
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

end