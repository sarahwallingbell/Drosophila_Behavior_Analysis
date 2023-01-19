function plotJointDistributionDuringBehavior(data, param, behavior, joint, numBins, fig_name)

% ex: plotJointDistributionDuringBehavior(data, param, 'standing', 'C_flex', 50, 'FTi_distribution_standing');
% 
% Plot distribution of a joint angle across legs for a behavior. 
% 
% Sarah Walling-Bell
% November, 2022


behaviorData = data(~isnan(data.([behavior '_bout_number'])),:); 
if strcmp(behavior, 'standing')
    %make sure all velocities are < 1 mm/s
    maxSpeed = 1; %mm/s
    idxs = abs(behaviorData.fictrac_delta_rot_lab_x_mms) < maxSpeed & ...
               behaviorData.fictrac_delta_rot_lab_y_mms < maxSpeed & ...
           abs(behaviorData.fictrac_delta_rot_lab_z_mms) < maxSpeed; 
    behaviorData = behaviorData(idxs,:);
elseif strcmp(behaivor, 'walking')
    %make sure forward velocity is > 5 mm/s
    minFwdSpeed = 5; %mm/s
    idxs = behaviorData.fictrac_delta_rot_lab_y_mms > minFwdSpeed; 
    behaviorData = behaviorData(idxs,:);
end

fig = fullfig; 
order = [4,5,6,1,2,3];
for leg = 1:param.numLegs
    subplot(2,3,order(leg));
    
    hist(behaviorData.([param.legs{leg} joint]), numBins);

    title(param.legs{leg});
    if leg == 1
        ylabel('Count (frames)');
        xlabel([strrep(joint, '_', ' ') ' (' char(176) ')']);
    end
    ax = gca;
    ax.FontSize = 20;

    xlim([0,180]);
    xticks(0:10:180);
    xticklabels({'0', '', '20', '', '40', '', '60', '', '80', '', '100', '', '120', '', '140', '', '160', '', '180'});

end

fig = formatFig(fig, true, [2,3]);

%save 
save_figure(fig, [param.googledrivesave fig_name], param.fileType);

end