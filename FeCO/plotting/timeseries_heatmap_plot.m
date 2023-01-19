function timeseries_heatmap_plot(data, param, joints, fig_name, data_ctl_in, data_ctl_out, param_ctl_out)

% Plot a heatmap that sumarizes joint x leg timeseries data. 
% Heatmap color is: 
% A = exp to ctlIn area post stim onset
% B = exp to ctlIn area pre stim onset
% C = exp to ctlOut area post stim onset
% D = exp to ctlOut area pre stim onset
% mean(A-B, C-D)
% 
% Sarah Walling-Bell
% December 2022

%find vid starts
%exp data
starts = find(data.fnum == 0);
starts(starts+param.vid_len_f-1 > height(data)) = []; %delete any ctl starts that are less than param.vid_len_f frames from the end of this data
frames = starts+[0:param.vid_len_f-1]; %each row is a vid, containing idx of the vid in data
numFlies = height(unique(data.flyid(starts)));
%ctl data
%intra-fly ctl data
starts_ctl_in = find(data_ctl_in.fnum == 0);
starts_ctl_in(starts_ctl_in+param.vid_len_f-1 > height(data_ctl_in)) = []; %delete any ctl starts that are less than param.vid_len_f frames from the end of this data
frames_ctl_in = starts_ctl_in+[0:param.vid_len_f-1]; %each row is a vid, containing idx of the vid in data
numFlies_ctl_in = height(unique(data_ctl_in.flyid(starts_ctl_in)));
%extra-fly ctl data
starts_ctl_out = find(data_ctl_out.fnum == 0);
starts_ctl_out(starts_ctl_out+param.vid_len_f-1 > height(data_ctl_out)) = []; %delete any ctl starts that are less than param.vid_len_f frames from the end of this data
frames_ctl_out = starts_ctl_out+[0:param_ctl_out.vid_len_f-1]; %each row is a vid, containing idx of the vid in data
numFlies_ctl_out = height(unique(data_ctl_out.flyid(starts_ctl_out)));

%start plotting
plotOrder = [];
for l = 1:param.numLegs
    for j = 1:width(joints)
        plotOrder(end+1) = l+((j-1)*param.numLegs);
    end
end

color_value = NaN(width(joints), param.numLegs);
for leg = 1:param.numLegs
    flyMatrix = data.flyid(frames(:,1)); %for reporting n flies
    flyMatrixCtlIn = data_ctl_in.flyid(frames_ctl_in(:,1));
    flyMatrixCtlOut = data_ctl_out.flyid(frames_ctl_out(:,1));
    
    for joint = 1:width(joints)
        %pool data
        dataMatrix = data.([param.legs{leg}, joints{joint}])(frames);
        dataMatrixCtlIn = data_ctl_in.([param.legs{leg}, joints{joint}])(frames_ctl_in);
        dataMatrixCtlOut = data_ctl_out.([param_ctl_out.legs{leg}, joints{joint}])(frames_ctl_out);

        %normalize
        dataMatrix = dataMatrix-dataMatrix(:,param.laser_on);
        dataMatrixCtlIn = dataMatrixCtlIn-dataMatrixCtlIn(:,param.laser_on);
        dataMatrixCtlOut = dataMatrixCtlOut-dataMatrixCtlOut(:,param_ctl_out.laser_on);

        %averages
        exp_mean_pre = mean(dataMatrix(:,1:param.laser_on), 1, 'omitnan');
        exp_mean_post = mean(dataMatrix(:,param.laser_on+1:end), 1, 'omitnan');

        ctlIn_mean_pre = mean(dataMatrixCtlIn(:,1:param.laser_on), 1, 'omitnan');
        ctlIn_mean_post = mean(dataMatrixCtlIn(:,param.laser_on+1:end), 1, 'omitnan');

        ctlOut_mean_pre = mean(dataMatrixCtlOut(:,1:param.laser_on), 1, 'omitnan');
        ctlOut_mean_post = mean(dataMatrixCtlOut(:,param.laser_on+1:end), 1, 'omitnan');

        %areas
        exp_ctlIn_area_pre = trapz(exp_mean_pre) - trapz(ctlIn_mean_pre);
        exp_ctlIn_area_post = trapz(exp_mean_post) - trapz(ctlIn_mean_post);
        exp_ctlOut_area_pre = trapz(exp_mean_pre) - trapz(ctlOut_mean_pre);
        exp_ctlOut_area_post = trapz(exp_mean_post) - trapz(ctlOut_mean_post);
        
        %sems
        ySEMavg_exp = mean(sem(dataMatrix, 1, nan, numFlies));
        ySEMavg_ctlIn = mean(sem(dataMatrixCtlIn, 1, nan, numFlies_ctl_in));
        ySEMavg_ctlOut = mean(sem(dataMatrixCtlOut, 1, nan, numFlies_ctl_out));
        ySEMavg = mean([ySEMavg_exp, ySEMavg_ctlIn, ySEMavg_ctlOut]);

        %heatmap value
        % average difference btw pre and post stim offset exp and control average joint traces for internal vs external fly control 
        % avg((exp_ctlIn_diff_postStim - exp_ctlIn_diff_preStim),(exp_ctlOut_diff_postStim - exp_ctlOut_diff_preStim))
        color_value_1(joint, leg) = ((exp_ctlIn_area_post-exp_ctlIn_area_pre) + (exp_ctlOut_area_post-exp_ctlOut_area_pre))/2;
        
        %same as above but divided by the average standard error of the
        %mean of exp data across the video. 
        color_value_2(joint, leg) = ((exp_ctlIn_area_post-exp_ctlIn_area_pre) + (exp_ctlOut_area_post-exp_ctlOut_area_pre))/2/ySEMavg;

    end
    
end

%color function 1
fig = fullfig;

%plot heatmap
customCMap = custom_colormap(height(color_value_1(:)), color_value_1, 0, [1 0 0], [1 1 1], [0 0 1]);
% colormap(customCMap);
colormap('cool');
img = imagesc(color_value_1);        % draw image and scale colormap to values range
c = colorbar;          % show color scale
c.Label.String = 'Average (\Delta pre stim exp-ctl area, \Delta post stim exp-ctl area)  (deg*sec)';
% clim([max(max(abs(color_value_1)))*-1 max(max(abs(color_value_1)))]); %limit range to center 0 in colorbar
clim([-10000 10000]); %limit range to center 0 in colorbar - SAME ACROSS GENOTYPES

%label axes
yticks(1:1:width(joints));
xticklabels(param.legs);
yticklabels(strrep(joints, '_', ' '));

%save
% save_figure(fig, [param.googledrivesave fig_name '_colorFn1'], param.fileType);
save_figure(fig, [param.googledrivesave fig_name '_colorFn1_normed'], param.fileType);



%color function 2
fig = fullfig;

%plot heatmap
customCMap = custom_colormap(height(color_value_2(:)), color_value_2, 0, [1 0 0], [1 1 1], [0 0 1]);
% colormap(customCMap);
colormap('cool');
img = imagesc(color_value_2);        % draw image and scale colormap to values range
c = colorbar;          % show color scale
c.Label.String = 'Average (\Delta pre stim exp-ctl area, \Delta post stim exp-ctl area) / average SEM  (deg*sec/deg)';
% clim([max(max(abs(color_value_2)))*-1 max(max(abs(color_value_2)))]); %limit range to center 0 in colorbar
clim([-700 700]); %limit range to center 0 in colorbar - SAME ACROSS GENOTYPES

%label axes
yticks(1:1:width(joints));
xticklabels(param.legs);
yticklabels(strrep(joints, '_', ' '));

%save
% save_figure(fig, [param.googledrivesave fig_name '_colorFn2'], param.fileType);
save_figure(fig, [param.googledrivesave fig_name '_colorFn2_normed'], param.fileType);


end