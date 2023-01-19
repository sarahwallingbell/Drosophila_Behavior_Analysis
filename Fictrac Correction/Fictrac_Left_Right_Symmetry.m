 clear all; close all; clc;

% Select parquet file (the fly data)
[FilePaths, version] = DLC_select_parquet(); 

% Load behavior and fictrac data
columns = {'walking_bout_number','flyid', ...
    'fictrac_delta_rot_lab_x_mms','fictrac_delta_rot_lab_y_mms','fictrac_delta_rot_lab_z_mms'};

data = [];
for file = 1:width(FilePaths)
    data = [data; parquetread(FilePaths{file}, 'SelectedVariableNames', columns)];
end

% select only walking data
walkingData = data(~isnan(data.walking_bout_number),:); 
walkingFlies = unique(walkingData.flyid);

walkingDates = [];
for fly = 1:height(walkingFlies)
    walkingDates{fly,1} = walkingFlies{fly}(1:end-8);
    walkingDates{fly,2} = datenum(walkingFlies{fly}(1:end-8), 'mm.dd.yy');
end
dateNums = [walkingDates{:,2}];
[sortedDates, sortedDatesIdxs] = sort(dateNums);
sortedFlies = walkingFlies(sortedDatesIdxs);
[~, ~, ic] = unique(sortedDates);
sortedDateColors = ic;



%% All data
fig = fullfig;
subplot(3,1,1); 
histogram(walkingData.fictrac_delta_rot_lab_x_mms, 'FaceColor', 'r', 'EdgeColor', 'r'); hold on;
m = mean(walkingData.fictrac_delta_rot_lab_x_mms, 'omitnan');
xlim([-50 50]);
vline(m, 'w');
XL = get(gca, 'XLim'); x = XL(2);
YL = get(gca, 'YLim'); y = YL(2);
text(m,y, [' mean = ' num2str(m)], 'vert','top', 'Color', 'w', 'FontSize', 20);
text(x-(x/5), y-(y/5), ['n = ' num2str(height(walkingFlies)) ' flies'], 'Color', 'w', 'FontSize', 20);
xlabel('sideslip velocity (mm/s)');
hold off;

subplot(3,1,2); 
histogram(walkingData.fictrac_delta_rot_lab_y_mms, 'FaceColor', 'g', 'EdgeColor', 'g'); hold on;
m = mean(walkingData.fictrac_delta_rot_lab_y_mms, 'omitnan');
xlim([-50 50]);
vline(m, 'w'); 
YL = get(gca, 'YLim'); y = YL(2);
text(m,y, [' mean = ' num2str(m)], 'vert','top', 'Color', 'w', 'FontSize', 20);
ylabel('count');
xlabel('forward velocity (mm/s)');
xlim([-50 50]);

subplot(3,1,3); 
histogram(walkingData.fictrac_delta_rot_lab_z_mms, 'FaceColor', 'b', 'EdgeColor', 'b'); hold on;
m = mean(walkingData.fictrac_delta_rot_lab_z_mms, 'omitnan');
xlim([-50 50]);
vline(m, 'w'); 
YL = get(gca, 'YLim'); y = YL(2);
text(m,y, [' mean = ' num2str(m)], 'vert','top', 'Color', 'w', 'FontSize', 20);
xlabel('rotational velocity (mm/s)');
xlim([-50 50]);
hold off;

fig = formatFig(fig, true, [3,1]);

%save
fig_name = '\fictrac_velocity_histograms_allWalkingData_allFlies';
path = 'G:\My Drive\Tuthill Lab Shared\Sarah\Weekly Meetings\22_4_5\figs';
save_figure(fig, [path fig_name], '-png');

%% By fly

for fly = 9:height(walkingFlies)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
flyWalkingData = walkingData(strcmpi(walkingData.flyid, walkingFlies{fly}), :);

fig = fullfig;
subplot(3,1,1); 
histogram(flyWalkingData.fictrac_delta_rot_lab_x_mms, 'FaceColor', 'r', 'EdgeColor', 'r'); hold on;
m = mean(flyWalkingData.fictrac_delta_rot_lab_x_mms, 'omitnan');
xlim([-50 50]);
vline(m, 'w');
YL = get(gca, 'YLim'); y = YL(2);
text(m,y, [' mean = ' num2str(m)], 'vert','top', 'Color', 'w', 'FontSize', 20);
xlabel('sideslip velocity (mm/s)');
hold off;

subplot(3,1,2); 
histogram(flyWalkingData.fictrac_delta_rot_lab_y_mms, 'FaceColor', 'g', 'EdgeColor', 'g'); hold on;
m = mean(flyWalkingData.fictrac_delta_rot_lab_y_mms, 'omitnan');
xlim([-50 50]);
vline(m, 'w'); 
YL = get(gca, 'YLim'); y = YL(2);
text(m,y, [' mean = ' num2str(m)], 'vert','top', 'Color', 'w', 'FontSize', 20);
ylabel('count');
xlabel('forward velocity (mm/s)');
xlim([-50 50]);

subplot(3,1,3); 
histogram(flyWalkingData.fictrac_delta_rot_lab_z_mms, 'FaceColor', 'b', 'EdgeColor', 'b'); hold on;
m = mean(flyWalkingData.fictrac_delta_rot_lab_z_mms, 'omitnan');
xlim([-50 50]);
vline(m, 'w'); 
YL = get(gca, 'YLim'); y = YL(2);
text(m,y, [' mean = ' num2str(m)], 'vert','top', 'Color', 'w', 'FontSize', 20);
xlabel('rotational velocity (mm/s)');
xlim([-50 50]);
hold off;

fig = formatFig(fig, true, [3,1]);

%save
fig_name = ['\fictrac_velocity_histograms_allWalkingData_' walkingFlies{fly}];
path = 'G:\My Drive\Tuthill Lab Shared\Sarah\Weekly Meetings\22_4_5\figs';
save_figure(fig, [path fig_name], '-png');


end


%%
mean_x = [];
mean_y = [];
mean_z = [];
for fly = 1:height(walkingFlies)
    flyWalkingData = walkingData(strcmpi(walkingData.flyid, walkingFlies{fly}), :);
    mean_x = [mean_x; mean(flyWalkingData.fictrac_delta_rot_lab_x_mms, 'omitnan')];
    mean_y = [mean_y; mean(flyWalkingData.fictrac_delta_rot_lab_y_mms, 'omitnan')];
    mean_z = [mean_z; mean(flyWalkingData.fictrac_delta_rot_lab_z_mms, 'omitnan')];

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fig = fullfig;
subplot(3,1,1); 
scatter(mean_x, zeros(height(mean_x),1), [], 'r');
xlabel('sideslip velocity (mm/s)');

subplot(3,1,2); 
scatter(mean_y, zeros(height(mean_y),1), [], 'g');
xlabel('forward velocity (mm/s)');

subplot(3,1,3); 
scatter(mean_z, zeros(height(mean_z),1), [], 'b');
xlabel('rotational velocity (mm/s)');

fig = formatFig(fig, true, [3,1]);

%save
fig_name = '\fictrac_velocity_means_allWalkingData_allFlies';
path = 'G:\My Drive\Tuthill Lab Shared\Sarah\Weekly Meetings\22_4_5\figs';
save_figure(fig, [path fig_name], '-png');



%%


mean_x = [];
mean_y = [];
mean_z = [];
for fly = 1:height(sortedFlies)
    flyWalkingData = walkingData(strcmpi(walkingData.flyid, sortedFlies{fly}), :);
    mean_x = [mean_x; mean(flyWalkingData.fictrac_delta_rot_lab_x_mms, 'omitnan')];
    mean_y = [mean_y; mean(flyWalkingData.fictrac_delta_rot_lab_y_mms, 'omitnan')];
    mean_z = [mean_z; mean(flyWalkingData.fictrac_delta_rot_lab_z_mms, 'omitnan')];

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fig = fullfig;
tiledlayout(3,1); 
nexttile
scatter(mean_x, zeros(height(mean_x),1), [], sortedDateColors);
xlabel('sideslip velocity (mm/s)');
fig = formatFig(fig, true);


nexttile
scatter(mean_y, zeros(height(mean_y),1), [], sortedDateColors);
xlabel('forward velocity (mm/s)');
fig = formatFig(fig, true);


nexttile
scatter(mean_z, zeros(height(mean_z),1), [], sortedDateColors);
xlabel('rotational velocity (mm/s)');

fig = formatFig(fig, true);

cb = colorbar('southoutside', 'Ticks',[min(sortedDateColors), max(sortedDateColors)],...
             'TickLabels',{sortedFlies{1}(1:end-8), sortedFlies{end}(1:end-8)}, 'color', Color('white'));
cb.Layout.Tile = 'east';


%save
fig_name = '\fictrac_velocity_means_allWalkingData_allFlies_colorByDate';
path = 'G:\My Drive\Tuthill Lab Shared\Sarah\Weekly Meetings\22_4_5\figs';
save_figure(fig, [path fig_name], '-png');



