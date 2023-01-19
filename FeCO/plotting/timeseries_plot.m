function timeseries_plot(data, param, joints, normalize, sameAxes, laserColor, plotSEM, fig_name, varargin)

% data = subset of data for (exp) data to plot. 
% param = param struct for the data
% normalize = 1 (normalize all data by angle at stim onset) 0 (don't normalize)
% sameAxes = 1 (make y axis same for all plots) 0 (don't change axes)
% plotSEM = 1 (plot sem around avgate) 0 (don't plot sem)
% 
% '-data_ctl_in' - intrafly control data
% '-data_ctl_out' - interfly control data (usually ctl genotype)
% '-param_ctl_out' - param fir data_ctl_out (note, dataCtlIn shares param with data)
%  binning params (just bin one thing at a time):
%     '-bin_speed_x' - binEdges for sideslip velocity
%     '-bin_speed_y' - binEdges for forward velocity
%     '-bin_speed_z' - binEdges for rotational velocity
%     '-bin_phase' - binEdges for phase of 'bin_phase_jnt' 
%     '-bin_phase_jnt' - which leg node to bin phase of (joint or E_y)
%     '-bin_angle' - binEdges for angle of 'bin_angle_jnt' 
%     '-bin_angle_joint' - which leg node to bin angle of (joint or E_y)
%     '-bin_behavior' - list of behaviors to bin by
%     '-bin_flies' - y/n for binning by fly 
%     '-bin_colors' - colors for each bin
%     '-data_line_types' - type of line for exp and ctl data: '-', '--', ':'
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
            case 'bin_speed_x'
                bin_speed_x = varargin{ii+1}; idx = idx+1; vararginList.VarName{idx} = lower(varargin{ii}(2:end));
            case 'bin_speed_y'
                bin_speed_y = varargin{ii+1}; idx = idx+1; vararginList.VarName{idx} = lower(varargin{ii}(2:end));
            case 'bin_speed_z'
                bin_speed_z = varargin{ii+1}; idx = idx+1; vararginList.VarName{idx} = lower(varargin{ii}(2:end));
            case 'bin_phase'
                bin_phase = varargin{ii+1}; idx = idx+1; vararginList.VarName{idx} = lower(varargin{ii}(2:end));
            case 'bin_phase_jnt'
                bin_phase_jnt = varargin{ii+1}; idx = idx+1; vararginList.VarName{idx} = lower(varargin{ii}(2:end));
            case 'bin_angle'
                bin_angle = varargin{ii+1}; idx = idx+1; vararginList.VarName{idx} = lower(varargin{ii}(2:end));
            case 'bin_angle_joint'
                bin_angle_joint = varargin{ii+1}; idx = idx+1; vararginList.VarName{idx} = lower(varargin{ii}(2:end));
            case 'bin_behavior'
                bin_behavior = varargin{ii+1}; idx = idx+1; vararginList.VarName{idx} = lower(varargin{ii}(2:end));
            case 'bin_flies'
                bin_flies = varargin{ii+1}; idx = idx+1; vararginList.VarName{idx} = lower(varargin{ii}(2:end));
            case 'bin_colors'
                bin_colors = varargin{ii+1}; idx = idx+1; vararginList.VarName{idx} = lower(varargin{ii}(2:end));
            case 'data_line_types'
                data_line_types = varargin{ii+1}; idx = idx+1; vararginList.VarName{idx} = lower(varargin{ii}(2:end));
            end

        end
    end
end
if ~exist("vararginList", "var"); numArgs = 0; 
else; numArgs = width(vararginList.VarName); end

%find vid starts
%exp data
starts = find(data.fnum == 0);
starts(starts+param.vid_len_f-1 > height(data)) = []; %delete any ctl starts that are less than param.vid_len_f frames from the end of this data
frames = starts+[0:param.vid_len_f-1]; %each row is a vid, containing idx of the vid in data
numFlies = height(unique(data.flyid(starts)));
%ctl data
if any(contains(vararginList.VarName, 'data_ctl_in'))
    %intra-fly ctl data
    starts_ctl_in = find(data_ctl_in.fnum == 0);
    starts_ctl_in(starts_ctl_in+param.vid_len_f-1 > height(data_ctl_in)) = []; %delete any ctl starts that are less than param.vid_len_f frames from the end of this data
    frames_ctl_in = starts_ctl_in+[0:param.vid_len_f-1]; %each row is a vid, containing idx of the vid in data
    numFlies_ctl_in = height(unique(data_ctl_in.flyid(starts_ctl_in)));
end
if any(contains(vararginList.VarName, 'data_ctl_out'))
    %extra-fly ctl data
    starts_ctl_out = find(data_ctl_out.fnum == 0);
    starts_ctl_out(starts_ctl_out+param.vid_len_f-1 > height(data_ctl_out)) = []; %delete any ctl starts that are less than param.vid_len_f frames from the end of this data
    frames_ctl_out = starts_ctl_out+[0:param_ctl_out.vid_len_f-1]; %each row is a vid, containing idx of the vid in data
    numFlies_ctl_out = height(unique(data_ctl_out.flyid(starts_ctl_out)));
end

%start plotting
fig = fullfig;
plotOrder = [1,7,13,19, 2,8,14,20, 3,9,15,21, 4,10,16,22, 5,11,17,23, 6,12,18,24];

i = 0;
for leg = 1:param.numLegs
    flyMatrix = data.flyid(frames(:,1)); %for reporting n flies
    if any(contains(vararginList.VarName, 'data_ctl_in')) 
        flyMatrixCtlIn = data_ctl_in.flyid(frames_ctl_in(:,1));
    end
    if any(contains(vararginList.VarName, 'data_ctl_out'))
        flyMatrixCtlOut = data_ctl_out.flyid(frames_ctl_out(:,1));
    end

    for joint = 1:width(joints)
        i = i+1;
        AX(i) = subplot(width(joints), param.numLegs, plotOrder(i));

        %pool data
        dataMatrix = data.([param.legs{leg}, joints{joint}])(frames);
        if any(contains(vararginList.VarName, 'data_ctl_in')) 
            dataMatrixCtlIn = data_ctl_in.([param.legs{leg}, joints{joint}])(frames_ctl_in);
        end
        if any(contains(vararginList.VarName, 'data_ctl_out'))
            dataMatrixCtlOut = data_ctl_out.([param_ctl_out.legs{leg}, joints{joint}])(frames_ctl_out);
        end

        %normalize
        if normalize
            dataMatrix = dataMatrix-dataMatrix(:,param.laser_on);
            if any(contains(vararginList.VarName, 'data_ctl_in'))
                dataMatrixCtlIn = dataMatrixCtlIn-dataMatrixCtlIn(:,param.laser_on);
            end
            if any(contains(vararginList.VarName, 'data_ctl_out'))
                dataMatrixCtlOut = dataMatrixCtlOut-dataMatrixCtlOut(:,param_ctl_out.laser_on);
            end
        end

        %bin
        binMatrix = NaN(size(frames(:,1)));
        if any(contains(vararginList.VarName, 'data_ctl_in'))
            binMatrixCtlIn = NaN(size(frames_ctl_in(:,1)));
        end
        if any(contains(vararginList.VarName, 'data_ctl_out'))
            binMatrixCtlOut = NaN(size(frames_ctl_out(:,1)));
        end

        if any(contains(vararginList.VarName, 'bin_flies')) %bin by fly 
            [flies,~,binMatrix] = unique(data.flyid(frames(:,1)));
            if any(contains(vararginList.VarName, 'data_ctl_in'))
                [fliesCtlIn,~,binMatrixCtlIn] = unique(data_ctl_in.flyid(frames_ctl_in(:,1)));
            end
            if any(contains(vararginList.VarName, 'data_ctl_out'))
                [fliesCtlOut,~,binMatrixCtlOut] = unique(data_ctl_out.flyid(frames_ctl_out(:,1)));
            end
        elseif any(contains(vararginList.VarName, 'bin_behavior')) %bin by behavior
             for behavior = 1:width(bin_behavior)
                 tempMatrix = data.([bin_behavior{behavior} '_bout_number'])(frames);
                 binMatrix(~isnan(tempMatrix(:,param.laser_on)),1) = behavior;
                 if any(contains(vararginList.VarName, 'data_ctl_in'))
                    tempMatrix = data_ctl_in.([bin_behavior{behavior} '_bout_number'])(frames_ctl_in);
                    binMatrixCtlIn(~isnan(tempMatrix(:,param.laser_on)),1) = behavior;
                 end
                 if any(contains(vararginList.VarName, 'data_ctl_out'))
                    tempMatrix = data_ctl_out.([bin_behavior{behavior} '_bout_number'])(frames_ctl_out);
                    binMatrixCtlOut(~isnan(tempMatrix(:,param_ctl_out.laser_on)),1) = behavior;
                 end
             end
        else
            binMatrix = ones(size(data.flyid(frames(:,1))));
            if any(contains(vararginList.VarName, 'data_ctl_in'))
                binMatrixCtlIn = ones(size(data_ctl_in.flyid(frames_ctl_in(:,1))));
            end
            if any(contains(vararginList.VarName, 'data_ctl_out'))
                binMatrixCtlOut = ones(size(data_ctl_out.flyid(frames_ctl_out(:,1))));
            end
        end
        
        %average
        bins = unique(binMatrix(~isnan(binMatrix)));
        if any(contains(vararginList.VarName, 'data_ctl_in')); binsCtlIn = unique(binMatrixCtlIn(~isnan(binMatrixCtlIn))); end
        if any(contains(vararginList.VarName, 'data_ctl_out')); binsCtlOut = unique(binMatrixCtlOut(~isnan(binMatrixCtlOut))); end
        numBins = height(unique(bins)); 
        if any(contains(vararginList.VarName, 'data_ctl_in')); numBins = max(numBins, height(binsCtlIn)); end
        if any(contains(vararginList.VarName, 'data_ctl_out')); numBins = max(numBins, height(binsCtlOut)); end

        numFliesBin = height(unique(flyMatrix));
        if any(contains(vararginList.VarName, 'data_ctl_in')); numFliesBinCtlIn = height(unique(flyMatrixCtlIn)); end
        if any(contains(vararginList.VarName, 'data_ctl_out')); numFliesBinCtlOut = height(unique(flyMatrixCtlOut)); end


        for b = 1:numBins
            if height(bins) >= b
                yMean = mean(dataMatrix(binMatrix == bins(b),:), 1, 'omitnan');
                ySEM = sem(dataMatrix(binMatrix == bins(b),:), 1, nan, numFlies);
            end
            if any(contains(vararginList.VarName, 'data_ctl_in')) & height(binsCtlIn) >= b
                yMeanCtlIn = mean(dataMatrixCtlIn(binMatrixCtlIn == binsCtlIn(b),:), 1, 'omitnan');
                ySEMCtlIn = sem(dataMatrixCtlIn(binMatrixCtlIn == binsCtlIn(b),:), 1, nan, numFlies_ctl_in); 
            end
            if any(contains(vararginList.VarName, 'data_ctl_out')) & height(binsCtlOut) >= b
                yMeanCtlOut = mean(dataMatrixCtlOut(binMatrixCtlOut == binsCtlOut(b),:), 1, 'omitnan');
                ySEMCtlOut = sem(dataMatrixCtlOut(binMatrixCtlOut == binsCtlOut(b),:), 1, nan, numFlies_ctl_out);  
            end
            
            %plot
            if any(contains(vararginList.VarName, 'data_ctl_out')) & height(binsCtlOut) >= b
                if any(contains(vararginList.VarName, 'bin_colors')); color = bin_colors{b}; else; color = param_ctl_out.baseColor; end
                if any(contains(vararginList.VarName, 'data_line_types')); line_type = data_line_types.ctlOut; else; line_type = ':'; end
                plot(param_ctl_out.x, yMeanCtlOut, line_type, 'color', Color(color), 'linewidth', 2); hold on;
                if plotSEM
                    fill_data = error_fill(param_ctl_out.x, yMeanCtlOut, ySEMCtlOut);
                    h = fill(fill_data.X, fill_data.Y, get_color(param_ctl_out.baseColor), 'EdgeColor','none');
                    set(h, 'facealpha',param_ctl_out.jointFillWeights(2));
                end
            end
            if any(contains(vararginList.VarName, 'data_ctl_in')) & height(binsCtlIn) >= b
                if any(contains(vararginList.VarName, 'bin_colors')); color = bin_colors{b}; else; color = param.jointColors{joint}; end
                if any(contains(vararginList.VarName, 'data_line_types')); line_type = data_line_types.ctlOut; else; line_type = ':'; end
                plot(param.x, yMeanCtlIn, line_type, 'color', Color(color), 'linewidth', 2); hold on;
                if plotSEM
                    fill_data = error_fill(param.x, yMeanCtlIn, ySEMCtlIn);
                    h = fill(fill_data.X, fill_data.Y, get_color(param.jointColors{joint}), 'EdgeColor','none');
                    set(h, 'facealpha',param.jointFillWeights(2));      
                end
            end
            if height(bins) >= b
                if any(contains(vararginList.VarName, 'bin_colors')); color = bin_colors{b}; else; color = param.jointColors{joint}; end
                if any(contains(vararginList.VarName, 'data_line_types')); line_type = data_line_types.ctlOut; else; line_type = '-'; end
                plot(param.x, yMean, line_type, 'color', Color(color), 'linewidth', 1.5); hold on;
                if plotSEM
                    fill_data = error_fill(param.x, yMean, ySEM);
                    h = fill(fill_data.X, fill_data.Y, get_color(param.jointColors{joint}), 'EdgeColor','none');
                    set(h, 'facealpha',param.jointFillWeights(joint));
                end
            end
        end

        % laser region 
        laserLen = data.stimlen(frames(1));
        light_on = 0;
        light_off =(param.fps*laserLen)/param.fps;
        if sameAxes
            %save light length for plotting after syching lasers
            light_ons(i) = light_on;
            light_offs(i) = light_off;
        else
            y1 = rangeLine(fig);
            pl = plot([light_on, light_off], [y1,y1],'color',Color(laserColor), 'linewidth', 5); %TODO change back to param.laserColor when param is updated for all files. 
        end

        %label
        if joint == width(joints) 
            %add number of flies per leg
            nFlies = num2str(height(unique(flyMatrix)));
            fstr = ['flies: ' nFlies ' exp'];
            if any(contains(vararginList.VarName, 'data_ctl_in'))
                nFliesCtlIn = num2str(height(unique(flyMatrixCtlIn)));
                fstr = [fstr ', ' nFliesCtlIn ' ctlIn'];
            end
            if any(contains(vararginList.VarName, 'data_ctl_out'))
                nFliesCtlOut = num2str(height(unique(flyMatrixCtlOut)));
                fstr = [fstr ', ' nFliesCtlOut ' ctlEx'];
            end
            nFliesList{leg} = fstr;

            %add number of trials (vids) per leg
            nTrials = num2str(height(find(~isnan(binMatrix))));
            tstr = ['trials: ' nTrials ' exp'];
            if any(contains(vararginList.VarName, 'data_ctl_in'))
                nTrialsCtlIn = num2str(height(find(~isnan(binMatrixCtlIn))));
                tstr = [tstr ', ' nTrialsCtlIn ' ctlIn'];
            end
            if any(contains(vararginList.VarName, 'data_ctl_out'))
                nTrialsCtlOut = num2str(height(find(~isnan(binMatrixCtlOut))));
                tstr = [tstr ', ' nTrialsCtlOut ' ctlEx'];
            end
            nTrialsList{leg} = tstr;

            nDataIdxs(leg) = plotOrder(i);
        end


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
        plot([light_ons(p), light_offs(p)], [y1,y1],'color',Color(laserColor), 'linewidth', 5);%TODO change back to param.laserColor when param is updated for all files. 
        hold off
    end
end


fig = formatFig(fig, true, [width(joints), param.numLegs]);

%label num flies and trials 
for l = 1:param.numLegs
    subplot(width(joints), param.numLegs, nDataIdxs(l)); hold on
    title(nFliesList{l}, 'FontSize', 10, 'Color', Color(param.baseColor)); 
    subtitle(nTrialsList{l}, 'FontSize', 10, 'Color', Color(param.baseColor));
end



%save
save_figure(fig, [param.googledrivesave fig_name], param.fileType);



end