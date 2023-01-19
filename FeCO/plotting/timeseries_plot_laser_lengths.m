function timeseries_plot_laser_lengths(data, param, joints, normalize, sameAxes, plotSEM, laserColor, colorByLaser, fig_name)

% data = subset of data for (exp) data to plot. 
% param = param struct for the data
% normalize = 1 (normalize all data by angle at stim onset) 0 (don't normalize)
% sameAxes = 1 (make y axis same for all plots) 0 (don't change axes)
% plotSEM = 1 (plot sem around avgate) 0 (don't plot sem)
% colorByLaser = 1 (color by laser) 0 (color by joint)
%
% Sarah Walling-Bell
% November 2022

%find vid starts
%exp data
starts = find(data.fnum == 0);
starts(starts+param.vid_len_f-1 > height(data)) = []; %delete any ctl starts that are less than param.vid_len_f frames from the end of this data
frames = starts+[0:param.vid_len_f-1]; %each row is a vid, containing idx of the vid in data
numFlies = height(unique(data.flyid(starts)));

%start plotting
fig = fullfig;
plotOrder = [1,7,13,19, 2,8,14,20, 3,9,15,21, 4,10,16,22, 5,11,17,23, 6,12,18,24];
fillWeights = [0, 0.05, 0.1, 0.15, 0.2];
if colorByLaser
    hsv = rgb2hsv(Color(laserColor));
    weights = [0, 0.25, 0.5, 0.75, 1];
    laserColors{1} = Color(param.baseColor);
    for i = 2:param.numLasers
        laserColors{i} = hsv2rgb([hsv(1), weights(i), hsv(3)]);
    end
end
i = 0;
for leg = 1:param.numLegs
    flyMatrix = data.flyid(frames(:,1)); %for reporting n flies
    for joint = 1:width(joints)
        i = i+1;
        AX(i) = subplot(width(joints), param.numLegs, plotOrder(i));

        %pool data
        dataMatrix = data.([param.legs{leg}, joints{joint}])(frames);

        %normalize
        if normalize
            dataMatrix = dataMatrix-dataMatrix(:,param.laser_on);
        end

        %bin
        binMatrix = NaN(size(frames(:,1)));
        
        for l = 1:param.numLasers
            binMatrix(round(data.stimlen(frames(:,1)),2) == round(param.lasers(l), 2)) = l;
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
                    nFliesList(leg, b) = nFlies;
        
                    %add number of trials (vids) per bin per leg
                    nTrials = height(find(binMatrix == bins(b)));
                    nTrialsList(leg, b) = nTrials;
        
                    nDataIdxs(leg) = plotOrder(i);
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
        if ~sameAxes
            for laser = 1:param.numLasers
                xline(param.lasers(laser), ':', 'Color', laserColors{laser}, 'LineWidth', 2);
            end
        end

        %label
        if plotOrder(i) == 1
           if normalize; jnt = ['\Delta' strrep(joints{i}, '_', ' ')]; else; jnt = strrep(joints{i}, '_', ' '); end
           ylabel([jnt ' (' char(176) ')']);
           xlabel('Time (s)');
           title(param.legs{leg});
       elseif plotOrder(i) == 2
           title(param.legs{leg});
       elseif plotOrder(i) == 3
           title(param.legs{leg});
       elseif plotOrder(i) == 4
           title(param.legs{leg});
       elseif plotOrder(i) == 5    
           title(param.legs{leg});
       elseif plotOrder(i) == 6
           title(param.legs{leg});
       elseif plotOrder(i) == 7
           if normalize; jnt = ['\Delta' strrep(joints{i}, '_', ' ')]; else; jnt = strrep(joints{i}, '_', ' '); end
           ylabel([jnt ' (' char(176) ')']);
       elseif plotOrder(i) == 13
           if normalize; jnt = ['\Delta' strrep(joints{i}, '_', ' ')]; else; jnt = strrep(joints{i}, '_', ' '); end
           ylabel([jnt ' (' char(176) ')']);
       elseif plotOrder(i) == 19
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
        subplot(width(joints), param.numLegs, p); hold on
        for laser = 1:param.numLasers
            xline(param.lasers(laser), ':', 'Color', laserColors{laser}, 'LineWidth', 2);
        end
        hold off
    end
end


fig = formatFig(fig, true, [width(joints), param.numLegs]);

%label num flies and trials 
for l = 1:param.numLegs
    subplot(width(joints), param.numLegs, nDataIdxs(l)); hold on
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