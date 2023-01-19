function timeseries_plot_laser_powers_one_leg(data, param, leg, joints, normalize, sameAxes, plotSEM, laserColor, colorByLaser, fig_name)

% for plotting all laser powers for every laser length for a set of joints for one leg. 

% data = subset of data for (exp) data to plot. 
% param = param struct for the data
% normalize = 1 (normalize all data by angle at stim onset) 0 (don't normalize)
% sameAxes = 1 (make y axis same for all plots) 0 (don't change axes)
% plotSEM = 1 (plot sem around avgate) 0 (don't plot sem)
% colorByLaser = 1 (color by laser) 0 (color by joint)
%
% Sarah Walling-Bell
% November 2022


%start plotting
fig = fullfig;
plotOrder = [1,6,11,16, 2,7,12,17, 3,8,13,18, 4,9,14,19, 5,10,15,20];
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

i = 0;
for laserlength = 1:param.numLasers
    idxs = round(data.stimlen,2) == round(param.lasers(laserlength), 2);
    laser_data = data(idxs, :); %data with this laser length
    
    %exp data
    starts = find(laser_data.fnum == 0);
    frames = starts+[0:param.vid_len_f-1]; %each row is a vid, containing idx of the vid in data
    numFlies = height(unique(laser_data.flyid(starts)));

    flyMatrix = laser_data.flyid(frames(:,1)); %for reporting n flies
    for joint = 1:width(joints)
        i = i+1;
        AX(i) = subplot(width(joints), param.numLasers, plotOrder(i));

        %pool data
        dataMatrix = laser_data.([param.legs{leg}, joints{joint}])(frames);

        %normalize
        if normalize
            dataMatrix = dataMatrix-dataMatrix(:,param.laser_on);
        end

        %bin
        binMatrix = NaN(size(frames(:,1)));
        
        for l = 1:numLaserPowers
            binMatrix(laser_data.laserPower(frames(:,1)) == laserPowers(l)) = l;
        end
        
        
        %average
        bins = unique(binMatrix(~isnan(binMatrix)));
        numBins = height(unique(bins)); 
        for b = 1:numBins
            if height(bins) >= b
                %avg & sem
                yMean = mean(dataMatrix(binMatrix == bins(b),:), 1, 'omitnan');
                ySEM = sem(dataMatrix(binMatrix == bins(b),:), 1, nan, numFlies);

                %num flies & trials
                if joint == width(joints) 
                    %add number of flies per bin per leg
                    nFlies = height(unique(flyMatrix(binMatrix == bins(b),:)));
                    nFliesList(laserlength, b) = nFlies;
        
                    %add number of trials (vids) per bin per leg
                    nTrials = height(find(binMatrix == bins(b)));
                    nTrialsList(laserlength, b) = nTrials;
        
                    nDataIdxs(laserlength) = plotOrder(i);
                end


            
                %plot
                if colorByLaser; color = laserColors{b}; else; color = Color(param.jointColors{joint}); end
                plot(param.x, yMean, 'color', color, 'linewidth', 1.5); hold on;
                if plotSEM
                    fill_data = error_fill(param.x, yMean, ySEM);
                    if colorByLaser 
                        if b == 1; color = Color('white');                  fillWeight = 0.1;
                        else;      color = laserColor;                      fillWeight = fillWeights(b); end
                    else;          color = Color(param.jointColors{joint}); fillWeight = param.jointFillWeights(joint); end
                    h = fill(fill_data.X, fill_data.Y, color, 'EdgeColor','none');
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
           if normalize; jnt = ['\Delta' strrep(joints{i}, '_', ' ')]; else; jnt = strrep(joints{i}, '_', ' '); end
           ylabel([jnt ' (' char(176) ')']);
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
           if normalize; jnt = ['\Delta' strrep(joints{i}, '_', ' ')]; else; jnt = strrep(joints{i}, '_', ' '); end
           ylabel([jnt ' (' char(176) ')']);
       elseif plotOrder(i) == 11
           if normalize; jnt = ['\Delta' strrep(joints{i}, '_', ' ')]; else; jnt = strrep(joints{i}, '_', ' '); end
           ylabel([jnt ' (' char(176) ')']);
       elseif plotOrder(i) == 16
           if normalize; jnt = ['\Delta' strrep(joints{i}, '_', ' ')]; else; jnt = strrep(joints{i}, '_', ' '); end
           ylabel([jnt ' (' char(176) ')']);
       end

    end
end

if sameAxes
    % make all axes the same
    allYLim = get(AX, {'YLim'});
    allYLim = cat(2, allYLim{:});
    set(AX, 'YLim', [min(allYLim), max(allYLim)]);
    
    y1 = rangeLine(fig);
    
    %plot lasers
    for p = 1:i  
        subplot(width(joints), param.numLasers, p); hold on
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(laserColor), 'linewidth', 5);%TODO change back to param.laserColor when param is updated for all files. 
        hold off
    end
end



fig = formatFig(fig, true, [width(joints), param.numLasers]);

%label num flies and trials 
for l = 1:param.numLasers
    subplot(width(joints), param.numLasers, nDataIdxs(l)); hold on
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