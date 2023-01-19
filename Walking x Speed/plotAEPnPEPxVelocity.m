function plotAEPnPEPxVelocity(steps, param, velocity, type, flies, fig_name, numSpeedBins, minAvgSteps, maxSpeed, onePlot, varargin)

% plot AEP and PEP x velocity 
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

metricA = 'AEP';
metricB = 'PEP';

dotSize = 100;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

color = velocity; %var in steps.meta

directions = {'x', 'y', 'z'}; 

fig = fullfig; 
legOrder = [4,5,6,1,2,3];
if contains(velocity, 'y')
    binEdges = 0:maxSpeed/numSpeedBins:maxSpeed;
elseif contains(velocity, 'z')
    binEdges = (maxSpeed*-1):(maxSpeed*2)/numSpeedBins:maxSpeed;
end

for leg = 1:param.numLegs
    if contains(onePlot, 'n')
        subplot(2,3,legOrder(leg)); 
    end

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

    
    clear leg_data_A leg_data_B
  
    %bin data
    for d = 1:width(directions)
        leg_data_A(:,d) = steps.leg(leg).meta.([metricA '_E_' directions{d}])(stepIdxs);
        leg_data_B(:,d) = steps.leg(leg).meta.([metricB '_E_' directions{d}])(stepIdxs);
    end
    speed_data = steps.leg(leg).meta.(color)(stepIdxs);
    [bins,binEdges] = discretize(speed_data, binEdges);

    %counting flies
    fly_data = steps.leg(leg).meta.fly(stepIdxs);
    for f = 1:height(fly_data); fly_data{f} = fly_data{f}(1:end-2); end

    mean_leg_data_A = NaN(numSpeedBins, 3);
    mean_leg_data_B = NaN(numSpeedBins, 3);
    numTrials = zeros(numSpeedBins, 1);
    numFlies = zeros(numSpeedBins, 1);
    numSteps = zeros(numSpeedBins, 1);
    for sb = 1:numSpeedBins
        %align steps by phase
        binned_leg_data_A = leg_data_A(bins == sb, :);
        binned_leg_data_B = leg_data_B(bins == sb, :);
        binned_fly_data = fly_data(bins == sb, :);

        numSteps(sb) = height(binned_leg_data_A);
        numFlies(sb) = height(unique(binned_fly_data));

        mean_leg_data_A(sb,:) = mean(binned_leg_data_A, 'omitnan');
        mean_leg_data_B(sb,:) = mean(binned_leg_data_B, 'omitnan');
        numTrials(sb) = height(binned_leg_data_A);
    end
    
    %if any speed bin has avg number of trials < minAvgSteps, don't plot this data. 
    for sb = 1:numSpeedBins
        if mean(numTrials(sb)) < minAvgSteps
            mean_leg_data_A(sb,:) = NaN; %'erase' these values so they aren't plotted
            mean_leg_data_B(sb,:) = NaN; %'erase' these values so they aren't plotted
        end
    end
    
    %colors for plotting speed binned averages
    if contains(velocity, 'y')
        colors = jet(numSpeedBins); %order: slow to fast
    else
        colors = redblue(numSpeedBins, [min(binEdges), max(binEdges)]); %order: l2r or r2l?
    end

    %plot speed binned averages
    cmap = colormap(colors);

    if contains(type, '3D')
        scatter3(mean_leg_data_A(:,1), mean_leg_data_A(:,2), mean_leg_data_A(:,3), dotSize, 1:numSpeedBins, "o"); hold on; 
        scatter3(mean_leg_data_B(:,1), mean_leg_data_B(:,2), mean_leg_data_B(:,3), dotSize, 1:numSpeedBins, 'filled', 'square'); hold on
    elseif contains(type, '2D')
        scatter(mean_leg_data_A(:,2), mean_leg_data_A(:,1), dotSize, 1:numSpeedBins, "o", 'filled'); hold on; 
        scatter(mean_leg_data_B(:,2), mean_leg_data_B(:,1), dotSize, 1:numSpeedBins, 'filled', 'diamond'); hold on
    end

    ax = gca;
    ax.FontSize = 20;
    
    if leg == 1
        xlabel('L1/L3 axis (L1 coxa length)');
        ylabel('L1/R1 axis (L1 coxa length)');
        if contains(type, '3D')
            zlabel('Vertical axis (L1 coxa length)');
        end
    end

    set(gca, 'XDir','reverse');

end
hold off

if contains(onePlot, 'y')
    fig = formatFig(fig, true);  
else
    fig = formatFig(fig, true, [2,3]);   
end

h = axes(fig,'visible','off'); 
ticks = 0:1/numSpeedBins:1;
tickLabels = {};
for t = 1:width(binEdges)
    tickLabels{t} = num2str(binEdges(t)); 
end
c = colorbar(h,'Position',[0.92 0.168 0.022 0.7], 'XTick', ticks, ...
    'XTickLabel',tickLabels);
if contains(velocity, 'x')
    c.Label.String = 'Sideslip velocity (mm/s)';
elseif contains(velocity, 'y')
    c.Label.String = 'Forward velocity (mm/s)';
elseif contains(velocity, 'z')
    c.Label.String = 'Rotational velocity (mm/s)';
end
c.FontSize = 15;
c.Label.FontSize = 30;

c.Color = param.baseColor;
c.Box = 'off';        


hold off

% %save 
save_figure(fig, [param.googledrivesave fig_name], param.fileType);













end