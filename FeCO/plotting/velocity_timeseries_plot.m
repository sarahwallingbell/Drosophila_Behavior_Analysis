function velocity_timeseries_plot(data, param, normalize, sameAxes, plotSEM, laserColor, fig_name, varargin)

% plot avg fwd, rot and sideslip velocities for every laser length. 
% can plot with internal (0 sec laser) control and external (diff fly
% genotype) controls. 

% data = subset of data for (exp) data to plot. 
% param = param struct for the data
% normalize = 1 (normalize all data by angle at stim onset) 0 (don't normalize)
% sameAxes = 1 (make y axis same for all plots) 0 (don't change axes)
% plotSEM = 1 (plot sem around avgate) 0 (don't plot sem)
% colorByLaser = 1 (color by laser) 0 (color by joint)
%
% Sarah Walling-Bell
% November 2022

%parse optional params    
idx = 0;
for ii = 1:width(varargin)
    if ischar(varargin{ii}) && ~isempty(varargin{ii})
        if varargin{ii}(1) == '-' %find command descriptions 
            switch lower(varargin{ii}(2:end))
            case 'data_ctl_in'
                data_ctl_in = varargin{ii+1}; idx = idx+1; vararginList.VarName{idx} = lower(varargin{ii}(2:end)); 
            case 'data_ctl_out'
                data_ctl_out = varargin{ii+1}; idx = idx+1; vararginList.VarName{idx} = lower(varargin{ii}(2:end)); 
            case 'param_ctl_out'
                param_ctl_out = varargin{ii+1}; idx = idx+1; vararginList.VarName{idx} = lower(varargin{ii}(2:end)); 
            end

        end
    end
end
if ~exist("vararginList", "var"); numArgs = 0; 
else; numArgs = width(vararginList.VarName); end


%start plotting
fig = fullfig;
plotOrder = [1,5,9, 2,6,10, 3,7,11, 4,8,12];
velColors = [Color('orange'); Color('green'); Color('purple')];
velWeights = [0.2, 0.2, 0.2];

% laserPowers = unique(data.laserPower);
% numLaserPowers = height(laserPowers);

lasers = param.lasers(2:end); 
controlLaser = param.lasers(1);
velocities = {'fictrac_delta_rot_lab_x_mms', 'fictrac_delta_rot_lab_y_mms', 'fictrac_delta_rot_lab_z_mms'};
velocityNames = {'Sideslip velocity', 'Forward velocity', 'Rotational velocity'};
numVelocities = width(velocities); %fwd, side, rot

i = 0;
for laserlength = 1:width(lasers)
    idxs = round(data.stimlen,2) == round(lasers(laserlength), 2);
    laser_data = data(idxs, :); %data with this laser length
    if any(contains(vararginList.VarName, 'data_ctl_in'))
        %intra-fly ctl data
       idxs = round(data_ctl_in.stimlen,2) == round(controlLaser, 2);
       laser_data_ctl_in = data_ctl_in(idxs, :); %data with this laser length
    end
    if any(contains(vararginList.VarName, 'data_ctl_out'))
        %extra-fly ctl data
        idxs = round(data_ctl_out.stimlen,2) == round(lasers(laserlength), 2);
        laser_data_ctl_out = data_ctl_out(idxs, :); %data with this laser length
    end
    
    %exp data
    starts = find(laser_data.fnum == 0);
    starts(starts+param.vid_len_f-1 > height(laser_data)) = []; %delete any ctl starts that are less than param.vid_len_f frames from the end of this data
    frames = starts+[0:param.vid_len_f-1]; %each row is a vid, containing idx of the vid in data
    numFlies = height(unique(laser_data.flyid(starts)));
    flyMatrix = laser_data.flyid(frames(:,1)); %for reporting n flies
    if any(contains(vararginList.VarName, 'data_ctl_in'))
        %intra-fly ctl data
        starts_ctl_in = find(laser_data_ctl_in.fnum == 0);
        starts_ctl_in(starts_ctl_in+param.vid_len_f-1 > height(laser_data_ctl_in)) = []; %delete any ctl starts that are less than param.vid_len_f frames from the end of this data
        frames_ctl_in = starts_ctl_in+[0:param.vid_len_f-1]; %each row is a vid, containing idx of the vid in data
        numFlies_ctl_in = height(unique(laser_data_ctl_in.flyid(starts_ctl_in)));
        flyMatrix_ctl_in = laser_data_ctl_in.flyid(frames_ctl_in(:,1)); %for reporting n flies

    end
    if any(contains(vararginList.VarName, 'data_ctl_out'))
        %extra-fly ctl data
        starts_ctl_out = find(laser_data_ctl_out.fnum == 0);
        starts_ctl_out(starts_ctl_out+param.vid_len_f-1 > height(laser_data_ctl_out)) = []; %delete any ctl starts that are less than param.vid_len_f frames from the end of this data
        frames_ctl_out = starts_ctl_out+[0:param_ctl_out.vid_len_f-1]; %each row is a vid, containing idx of the vid in data
        numFlies_ctl_out = height(unique(laser_data_ctl_out.flyid(starts_ctl_out)));
        flyMatrix_ctl_out = laser_data_ctl_out.flyid(frames_ctl_out(:,1)); %for reporting n flies
    end


    for vel = 1:numVelocities
        i = i+1;
        AX(i) = subplot(numVelocities, width(lasers), plotOrder(i));

        %pool data
        dataMatrix = laser_data.(velocities{vel})(frames);
        if any(contains(vararginList.VarName, 'data_ctl_in'))
            dataMatrix_ctl_in = laser_data_ctl_in.(velocities{vel})(frames_ctl_in);
        end
        if any(contains(vararginList.VarName, 'data_ctl_out'))
            dataMatrix_ctl_out = laser_data_ctl_out.(velocities{vel})(frames_ctl_out);
        end

        %normalize
        if normalize
            dataMatrix = dataMatrix-dataMatrix(:,param.laser_on);
            if any(contains(vararginList.VarName, 'data_ctl_in'))
                dataMatrix_ctl_in = dataMatrix_ctl_in-dataMatrix_ctl_in(:,param.laser_on);
            end
            if any(contains(vararginList.VarName, 'data_ctl_out'))
                dataMatrix_ctl_out = dataMatrix_ctl_out-dataMatrix_ctl_out(:,param.laser_on);
            end
        end

        %avg & sem
        yMean = mean(dataMatrix, 1, 'omitnan');
        ySEM = sem(dataMatrix, 1, nan, numFlies);
        if any(contains(vararginList.VarName, 'data_ctl_in'))
            yMeanCtlIn = mean(dataMatrix_ctl_in, 1, 'omitnan');
            ySEMCtlIn = sem(dataMatrix_ctl_in, 1, nan, numFlies_ctl_in);
        end
        if any(contains(vararginList.VarName, 'data_ctl_out'))
            yMeanCtlOut = mean(dataMatrix_ctl_out, 1, 'omitnan');
            ySEMCtlOut = sem(dataMatrix_ctl_out, 1, nan, numFlies_ctl_out);
        end

        %num flies & trials
        if vel == numVelocities 
            %add number of flies per bin per leg
            nFlies = height(unique(flyMatrix));
            fstr = ['flies: ' num2str(nFlies) ' exp'];
            if any(contains(vararginList.VarName, 'data_ctl_in'))
                nFlies = height(unique(flyMatrix_ctl_in));
                fstr = [fstr ', ' num2str(nFlies) ' ctlIn'];
            end
            if any(contains(vararginList.VarName, 'data_ctl_out'))
                nFlies = height(unique(flyMatrix_ctl_out));
                fstr = [fstr ', ' num2str(nFlies) ' ctlEx'];
            end
            nFliesList{laserlength} = fstr;

            %add number of trials (vids) per bin per leg
            nTrials = height(dataMatrix);
            tstr = ['trials: ' num2str(nTrials) ' exp'];
            if any(contains(vararginList.VarName, 'data_ctl_in'))
                nTrials = height(dataMatrix_ctl_in);
                tstr = [tstr ', ' num2str(nTrials) ' ctlIn'];
            end
            if any(contains(vararginList.VarName, 'data_ctl_out'))
                nTrials = height(dataMatrix_ctl_out);
                tstr = [tstr ', ' num2str(nTrials) ' ctlEx'];
            end
            nTrialsList{laserlength} = tstr;

            nDataIdxs(laserlength) = plotOrder(i);
        end


    
        %plot
        color = velColors(vel, :);
        plot(param.x, yMean, 'color', color, 'linewidth', 1.5); hold on;
        if plotSEM
            fillWeight = velWeights(vel);
            fill_data = error_fill(param.x, yMean, ySEM);
            h = fill(fill_data.X, fill_data.Y, color, 'EdgeColor','none');
            set(h, 'facealpha',fillWeight);
        end

        if any(contains(vararginList.VarName, 'data_ctl_out'))
            color = Color(param.baseColor);
            plot(param.x, yMeanCtlOut, ':', 'color', color, 'linewidth', 1.5); hold on;
            if plotSEM
                fillWeight = 0.1;
                fill_data = error_fill(param.x, yMeanCtlOut, ySEMCtlOut);
                h = fill(fill_data.X, fill_data.Y, color, 'EdgeColor','none');
                set(h, 'facealpha',fillWeight);
            end
        end
            
        if any(contains(vararginList.VarName, 'data_ctl_in'))
            color = velColors(vel, :);
            plot(param.x, yMeanCtlIn, ':', 'color', color, 'linewidth', 1.5); hold on;
            if plotSEM
                fillWeight = 0.1;
                fill_data = error_fill(param.x, yMeanCtlIn, ySEMCtlIn);
                h = fill(fill_data.X, fill_data.Y, color, 'EdgeColor','none');
                set(h, 'facealpha',fillWeight);
            end  
        end


        % laser region 
        laserLen = laser_data.stimlen(frames(1));
        light_on = 0;
        light_off =(param.fps*laserLen)/param.fps;
        if sameAxes
            %save light length for plotting after syching lasers
            light_ons(plotOrder(i)) = light_on;
            light_offs(plotOrder(i)) = light_off;
        else
            y1 = rangeLine(fig);
            pl = plot([light_on, light_off], [y1,y1],'color',Color(laserColor), 'linewidth', 5); %TODO change back to param.laserColor when param is updated for all files. 
        end


        %label
        if plotOrder(i) == 1
           if normalize; str = ['\Delta' velocityNames{vel} ' (mm/s)']; else; str = [velocityNames{vel} ' (mm/s)']; end
           ylabel(str);
           xlabel('Time (s)');
           title([num2str(lasers(laserlength)) ' sec laser']);
       elseif plotOrder(i) == 2
           title([num2str(lasers(laserlength)) ' sec laser']);
       elseif plotOrder(i) == 3
           title([num2str(lasers(laserlength)) ' sec laser']);
       elseif plotOrder(i) == 4
           title([num2str(lasers(laserlength)) ' sec laser']);
       elseif plotOrder(i) == 5
           if normalize; str = ['\Delta' velocityNames{vel} ' (mm/s)']; else; str = [velocityNames{vel} ' (mm/s)']; end
           ylabel(str);
       elseif plotOrder(i) == 9
           if normalize; str = ['\Delta' velocityNames{vel} ' (mm/s)']; else; str = [velocityNames{vel} ' (mm/s)']; end
           ylabel(str);
       end

    end
end

if sameAxes
    order = [1,4,7,10; 2,5,8,11; 3,6,9,12];
    % make all axes the same (per row)
    for v = 1:numVelocities
        allYLim = get(AX(order(v,:)), {'YLim'});
        allYLim = cat(2, allYLim{:});
        set(AX(order(v,:)), 'YLim', [min(allYLim), max(allYLim)]);
    end
    
    
    %plot lasers
    for p = 1:i  
        subplot(numVelocities, width(lasers), p); hold on
        offset_percent = 5;
        yMax = max(ylim);
        yRange = range(ylim);
        offset = (yRange/100)*offset_percent;
        y1 = yMax-(abs(offset));
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(laserColor), 'linewidth', 5);%TODO change back to param.laserColor when param is updated for all files. 
        hold off
    end
end


fig = formatFig(fig, true, [numVelocities, width(lasers)]);

%label num flies and trials 
for l = 1:width(lasers)
    subplot(numVelocities, width(lasers), nDataIdxs(l)); hold on
    title(nFliesList{l}, 'FontSize', 10, 'Color', Color(param.baseColor)); 
    subtitle(nTrialsList{l}, 'FontSize', 10, 'Color', Color(param.baseColor));
end


%save
save_figure(fig, [param.googledrivesave fig_name], param.fileType);


end