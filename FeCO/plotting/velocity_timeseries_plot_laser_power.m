function velocity_timeseries_plot_laser_power(data, param, normalize, sameAxes, plotSEM, laserColor, colorByLaser, fig_name)


% plot average velocities across laser lengths and powers
% 
% Sarah Walling-Bell
% November 2022



%start plotting
fig = fullfig;
plotOrder = [1,6,11, 2,7,12, 3,8,13, 4,9,14, 5,10,15];
velColors = [Color('orange'); Color('green'); Color('purple')];
velWeights = [0.2, 0.2, 0.2];
fillWeights = [0, 0.05, 0.1, 0.15, 0.2];
if colorByLaser
    hsv = rgb2hsv(Color(laserColor));
    weights = [0, 0.25, 0.5, 0.75, 1];
    laserColors{1} = Color(param.baseColor);
    for i = 2:param.numLasers
        laserColors{i} = hsv2rgb([hsv(1), weights(i), hsv(3)]);
    end
end

laserPowers = unique(data.laserPower);
numLaserPowers = height(laserPowers);

% lasers = param.lasers(2:end); 
% controlLaser = param.lasers(1);
velocities = {'fictrac_delta_rot_lab_x_mms', 'fictrac_delta_rot_lab_y_mms', 'fictrac_delta_rot_lab_z_mms'};
velocityNames = {'Sideslip velocity', 'Forward velocity', 'Rotational velocity'};
numVelocities = width(velocities); %fwd, side, rot

i = 0;
for laserlength = 1:param.numLasers
    idxs = round(data.stimlen,2) == round(param.lasers(laserlength), 2);
    laser_data = data(idxs, :); %data with this laser length
    
    %exp data
    starts = find(laser_data.fnum == 0);
    frames = starts+[0:param.vid_len_f-1]; %each row is a vid, containing idx of the vid in data
    numFlies = height(unique(laser_data.flyid(starts)));
    flyMatrix = laser_data.flyid(frames(:,1)); %for reporting n flies
   
    for vel = 1:numVelocities
        i = i+1;
        AX(i) = subplot(numVelocities, param.numLasers, plotOrder(i));

        %pool data
        dataMatrix = laser_data.(velocities{vel})(frames);

        %normalize
        if normalize
            dataMatrix = dataMatrix-dataMatrix(:,param.laser_on);
        end

        %bin
        binMatrix = NaN(size(frames(:,1)));
        for l = 1:numLaserPowers
            binMatrix(data.laserPower(frames(:,1)) == laserPowers(l)) = l;
        end

        %avg & sem
        %average
        bins = unique(binMatrix(~isnan(binMatrix)));
        numBins = height(unique(bins)); 
        for b = 1:numBins
            if height(bins) >= b
                yMean = mean(dataMatrix(binMatrix == bins(b),:), 1, 'omitnan');
                ySEM = sem(dataMatrix(binMatrix == bins(b),:), 1, nan, numFlies);
              

                %num flies & trials
                if vel == numVelocities 
                    %add number of flies per bin per leg
                    nFlies = height(unique(flyMatrix(binMatrix == bins(b),:)));
                    nFliesList(laserlength, b) = nFlies;
        
                    %add number of trials (vids) per bin per leg
                    nTrials = height(find(binMatrix == bins(b)));
                    nTrialsList(laserlength, b) = nTrials;
        
                    nDataIdxs(laserlength) = plotOrder(i);
                end

    
                %plot
                if colorByLaser; color = laserColors{b}; else; color =  velColors(vel, :); end
                plot(param.x, yMean, 'color', color, 'linewidth', 1.5); hold on;
                if plotSEM
                    fill_data = error_fill(param.x, yMean, ySEM);
                    h = fill(fill_data.X, fill_data.Y, color, 'EdgeColor','none');
                    if colorByLaser 
                        if b == 1; color = Color('white');                  fillWeight = 0.1;
                        else;      color = laserColors{b};                  fillWeight = fillWeights(b); end
                    else;          color = velColors(vel, :); fillWeight = velWeights(vel); end
                    set(h, 'facealpha',fillWeight);
                end
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
           title([num2str(param.lasers(laserlength)) ' sec laser']);
       elseif plotOrder(i) == 2
           title([num2str(param.lasers(laserlength)) ' sec laser']);
       elseif plotOrder(i) == 3
           title([num2str(param.lasers(laserlength)) ' sec laser']);
       elseif plotOrder(i) == 4
           title([num2str(param.lasers(laserlength)) ' sec laser']);
       elseif plotOrder(i) == 5
           title([num2str(param.lasers(laserlength)) ' sec laser']);
       elseif plotOrder(i) == 6
           if normalize; str = ['\Delta' velocityNames{vel} ' (mm/s)']; else; str = [velocityNames{vel} ' (mm/s)']; end
           ylabel(str);
       elseif plotOrder(i) == 11
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
        subplot(numVelocities, param.numLasers, p); hold on
        offset_percent = 5;
        yMax = max(ylim);
        yRange = range(ylim);
        offset = (yRange/100)*offset_percent;
        y1 = yMax-(abs(offset));
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(laserColor), 'linewidth', 5);%TODO change back to param.laserColor when param is updated for all files. 
        hold off
    end
end


fig = formatFig(fig, true, [numVelocities, param.numLasers]);

%label num flies and trials 
for l = 1:param.numLasers
    subplot(numVelocities, param.numLasers, nDataIdxs(l)); hold on
    fstr = ['flies: ' num2str(nFliesList(1,b))];
    tstr = ['trials: ' num2str(nTrialsList(1,b))];
    for b = 2:numBins
        fstr = [fstr ', ' num2str(nFliesList(l,b))]; 
        tstr = [tstr ', ' num2str(nTrialsList(l,b))]; 
    end
    title(fstr, 'FontSize', 10, 'Color', Color(param.baseColor)); 
    subtitle(tstr, 'FontSize', 10, 'Color', Color(param.baseColor));
end


%save
save_figure(fig, [param.googledrivesave fig_name], param.fileType);



end
