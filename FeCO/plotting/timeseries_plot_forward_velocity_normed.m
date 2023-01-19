function timeseries_plot_forward_velocity_normed(data, data_ctl, param, joints, velocityBins, normalize, sameAxes, laserColor, varargin)
% diff between stim and no stim for each forward velocity bin in exp data (and ctl data). 
% 
% Bin data by forward velocity. For every bin, take avg joint angles. 
% Subtract avg for control (no stim) from experimental vid avg (stim). Plot this difference. 
% 
% data = subset of data for (exp) data to plot. 
% data_ctl = control data for same flies as data (no stim) 
% param = param struct for the data
% joints = joints to plot: {'A_flex', 'B_flex', 'C_flex', 'D_flex'}
% velocityBins = binEdges for binning vids by forward velocity at stim onset. 
% normalize = 1 (normalize all data by angle at stim onset) 0 (don't normalize)
% sameAxes = 1 (make y axis same for all plots) 0 (don't change axes)
% plotSEM = 1 (plot sem around avgate) 0 (don't plot sem)
% 
% '-data_exp_ctl' - interfly control data (stim on)
% '-data_ctl_ctl' - interfly control data (no stim)
% '-param_ctl' - param fir data_ctl_out (note, dataCtlIn shares param with data)
% 
% Sarah Walling-Bell
% November 2022

%parse optional params    
idx = 0;
for ii = 1:width(varargin)
    if ischar(varargin{ii}) && ~isempty(varargin{ii})
        if varargin{ii}(1) == '-' %find command descriptions 
            switch lower(varargin{ii}(2:end))
            case 'data_exp_ctl'
                data_exp_ctl = varargin{ii+1}; idx = idx+1; vararginList.VarName{idx} = lower(varargin{ii}(2:end)); 
            case 'data_ctl_ctl'
                data_ctl_ctl = varargin{ii+1}; idx = idx+1; vararginList.VarName{idx} = lower(varargin{ii}(2:end)); 
            case 'param_ctl'
                param_ctl = varargin{ii+1}; idx = idx+1; vararginList.VarName{idx} = lower(varargin{ii}(2:end)); 
            end
        end
    end
end
if ~exist("vararginList", "var"); numArgs = 0; 
else; numArgs = width(vararginList.VarName); end

%find vid starts
%exp exp data
starts = find(data.fnum == 0);
frames = starts+[0:param.vid_len_f-1]; %each row is a vid, containing idx of the vid in data
numFlies = height(unique(data.flyid(starts)));
%exp ctl data
starts_ctl = find(data_ctl.fnum == 0);
frames_ctl = starts_ctl+[0:param.vid_len_f-1]; %each row is a vid, containing idx of the vid in data
numFlies_ctl = height(unique(data_ctl.flyid(starts_ctl)));
%ctl data
if any(contains(vararginList.VarName, 'data_exp_ctl'))
    %ctl exp data
    starts_exp_ctl = find(data_exp_ctl.fnum == 0);
    frames_exp_ctl = starts_exp_ctl+[0:param_ctl.vid_len_f-1]; %each row is a vid, containing idx of the vid in data
    numFlies_exp_ctl = height(unique(data_exp_ctl.flyid(starts_exp_ctl)));
end
if any(contains(vararginList.VarName, 'data_ctl_ctl'))
    %ctl ctl data
    starts_ctl_ctl = find(data_ctl_ctl.fnum == 0);
    frames_ctl_ctl = starts_ctl_ctl+[0:param_ctl.vid_len_f-1]; %each row is a vid, containing idx of the vid in data
    numFlies_ctl_ctl = height(unique(data_ctl_ctl.flyid(starts_ctl_ctl)));
end

%start plotting
fig = fullfig;
plotOrder = [1,7,13,19, 2,8,14,20, 3,9,15,21, 4,10,16,22, 5,11,17,23, 6,12,18,24];

i = 0;
for leg = 1:param.numLegs
    for joint = 1:width(joints)
        i = i+1;
        AX(i) = subplot(width(joints), param.numLegs, plotOrder(i));

        %pool data
        dataMatrix = data.([param.legs{leg}, joints{joint}])(frames);
        dataMatrixCtl = data_ctl.([param.legs{leg}, joints{joint}])(frames_ctl);
        if any(contains(vararginList.VarName, 'data_exp_ctl')) 
            dataMatrixExpCtl = data_exp_ctl.([param_ctl.legs{leg}, joints{joint}])(frames_exp_ctl);
        end
        if any(contains(vararginList.VarName, 'data_ctl_ctl'))
            dataMatrixCtlCtl = data_ctl_ctl.([param_ctl.legs{leg}, joints{joint}])(frames_ctl_ctl);
        end

        %normalize
        if normalize
            dataMatrix = dataMatrix-dataMatrix(:,param.laser_on);
            dataMatrixCtl = dataMatrixCtl-dataMatrixCtl(:,param.laser_on);
            if any(contains(vararginList.VarName, 'data_exp_ctl'))
                dataMatrixExpCtl = dataMatrixExpCtl-dataMatrixExpCtl(:,param_ctl.laser_on);
            end
            if any(contains(vararginList.VarName, 'data_ctl_ctl'))
                dataMatrixCtlCtl = dataMatrixCtlCtl-dataMatrixCtlCtl(:,param_ctl.laser_on);
            end
        end

        %bin
        speedVector = data.fictrac_delta_rot_lab_y_mms(frames(:,param.laser_on)); 
        speedVectorCtl = data_ctl.fictrac_delta_rot_lab_y_mms(frames_ctl(:,param.laser_on)); 
        if any(contains(vararginList.VarName, 'data_exp_ctl'))
            speedVectorExpCtl = data_exp_ctl.fictrac_delta_rot_lab_y_mms(frames_exp_ctl(:,param_ctl.laser_on));
        end
        if any(contains(vararginList.VarName, 'data_ctl_ctl'))
            speedVectorCtlCtl = data_ctl_ctl.fictrac_delta_rot_lab_y_mms(frames_ctl_ctl(:,param_ctl.laser_on));
        end
        binVector = discretize(speedVector, velocityBins);
        binVectorCtl = discretize(speedVectorCtl, velocityBins);
        binVectorExpCtl = discretize(speedVectorExpCtl, velocityBins);
        binVectorCtlCtl = discretize(speedVectorCtlCtl, velocityBins);
        
        %plot
        for b = 1:width(velocityBins)-1
           yMean = mean(dataMatrix(binVector == b,:), 1, 'omitnan');
           yMeanCtl = mean(dataMatrixCtl(binVectorCtl == b,:), 1, 'omitnan');
           difference = yMean-yMeanCtl; 
           plot(param.x, difference, '-', 'color', Color(param.jointColors{joint}), 'linewidth', 2); hold on;

           if any(contains(vararginList.VarName, 'data_ctl_ctl')) & any(contains(vararginList.VarName, 'data_exp_ctl'))
               yMeanExpCtl = mean(dataMatrixExpCtl(binVectorExpCtl == b,:), 1, 'omitnan');
               yMeanCtlCtl = mean(dataMatrixCtlCtl(binVectorCtlCtl == b,:), 1, 'omitnan');
               differenceCtl = yMeanExpCtl-yMeanCtlCtl; 
               plot(param.x, differenceCtl, '-', 'color', Color(param.baseColor), 'linewidth', 2); hold on;
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


end