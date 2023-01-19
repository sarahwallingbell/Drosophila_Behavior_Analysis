function Plot_step_metric_vs_meta_metric(varargin)

%
% Plot a step metric (e.g. step frequency) by a meta metric (e.g. speed, acceleration, temp).
% 
% Required params:
%     'steps' = a structure with all steps and assoc. metadata, output from steps.m 
%     'param' - param struct from DLC_load_params.m
%     'step_metric' - which step metric to plot. Must be a column name
%           in 'steps' struct. This will be on y axis. 
%           Options:
%               - 'step_frequency'
%               - 'step_duration'
%               - 'step_length'
%               - 'stance_duration'
%               - 'swing_duration'
% 
%     'meta_metric' - which meta metric to plot. Must be a column name
%           in 'steps' struct. This will be on x axis. 
%           Options:
%               - 'avg_speed'
%               - 'avg_acceleration'
%               - 'avg_angular_velocity'
%               - 'avg_heading_angle'
%               - 'avg_temp'
% 
% Optional params:
%     'flies' - a subset of flies to analyze. A cell of 'flyid's. 
%     'legs' - a subset of legs to analyze. {1, 2, 3, 4, 5, 6} or {1, 3, 5} etc.
%     'exp_type' - 'any' = exp steps have any laser. 'all' = exp steps are fully in laser. Default is 'any'. 
%     'color_by' - a variable to color the points by. Must be a column name
%           in 'steps' struct. 
%           Options:
%               - 'avg_speed'
%               - 'avg_acceleration'
%               - 'avg_angular_velocity'
%               - 'avg_heading_angle'
%               - 'avg_temp'
%     *FOR NOW, FILTERING ONLY WORKS FOR SELECTING DATA WITHIN A RANGE. IN FUTURE,
%     EXPAND THIS IF NEEDED TO INCLUDE SELECTING DATA OUTSIDE A RANGE*
%     'filter_speed' - array with min and max speeds (inclusive): [minSpeed, maxSpeed]
%     'filter_acceleration' - array with min and max accelerations (inclusive): [minAcceleration, maxAcceleration]
%     'filter_angular_velocity' - array with min and max angular velocities (inclusive): [minAngVel, maxAngVel]
%     'filter_heading_angle' - array with min and max heading angle (inclusive): [minHeadingAngle, maxHeadingAngle]
%     'filter_temp' - array with min and max temps (inclusive): [minTemp, maxTemp]
%     'filter_stim_on_region' - select steps where laser turned on in either swing or stance. Options are 'swing' or 'stance. 
%     'filter_stim_off_region' - select steps where laser turned off in either swing or stance. Options are 'swing' or 'stance. 
%     'filter_stim_on_phase' - array with min and max stim on phase (inclusive): [minPhase, maxPhase]
%     'filter_stim_on_phase_joint' - if 'filter_stim_on_phase' has an arg, this needs an arg. It is the joint (a column in
%           steps.leg().meta.stim_on_phase) to filter phase of. Options: 'BC', 'CF', 'FTi', 'TiTa', 'B_rot', 'E_x', 'E_y', 'E_z'
%     'filter_stim_off_phase' - array with min and max stim off phase (inclusive): [minPhase, maxPhase]
%     'filter_stim_off_phase_joint' - if 'filter_stim_off_phase' has an arg, this needs an arg. It is the joint (a column in 
%           steps.leg().meta.stim_off_phase) to filter phase of. Options: 'BC', 'CF', 'FTi', 'TiTa', 'B_rot', 'E_x', 'E_y', 'E_z'
%     'nbins' - nbins argument for density plots. One value for same num bins in each axis. Two vals for diff num bins in each axis. Ex: 20 or [10 20] for [numBinsX numBinsY];
%     'plots' - array of plot numbers to plot. Allows you to plot a subset of plots in this fn. 
%           1 = scatter plot. 2 = density plot. Default is to plot all plots. Ex: [1] -OR- [2] -OR- [1,2]
%     'lslines' - t/f for plotting least squares lines in plots. Default is true, plot the lines. 
%     'all_data' - t/f for plotting all data together, not experimental vs control. Default is false, plot exp vs control. Only applies to plot 3 for now. TODO: expand to all plots. 
%     'color_limit' - a min and max for the color variable. A way to filter the color variable (currently just for plot 1). Ex: [0, 20] - format is [min, max] for caxis(). Default is no filter and to set all color limits to the same across legs. 
%     'step_metric_limit' - a min and max for step_metric variable. A way to filter the step_metric variable (currently just for plot 1). Ex: [0, 20] - format is [min, max]. Default is no filter. 
%     'meta_metric_limit' - a min and max for meta_metric variable. A way to filter the meta_metric variable (currently just for plot 1). Ex: [0, 20] - format is [min, max]. Default is no filter. 
%     'num_bins' = the number of bins for plot 3. Default is 20. 
%     'min_num_steps' = the number of steps per bin to plot data for that bin in plot 3. Default is 1. 
%
% Example usage:
%     Plot_step_metric_vs_meta_metric('-steps', steps, '-param', param, '-step_metric', 'step_frequency', '-meta_metric', 'speed', 
%       '-flies', flyListL2.flyid, '-filter_speed', [3, 10], '-filter_stim_on_phase', [-1, 1], '-filter_stim_on_phase_joint', 'FTi');
% 
% Sarah Walling-Bell
% November 2021
%     


    %set defaults for optional params
    flySubset = false;
    colorData = false; %color data by input color_by variable
    legs = {1,2,3,4,5,6};
    exp_type = 'any';
    filtBySpeed = false;
    filtByAcceleration = false;
    filtByAngularVelocity = false;
    filtByHeadingAngle = false;
    filtByTemp = false;
    filtByStimOnRegion = false;
    filtByStimOffRegion = false;
    filtByStimOnPhase = false;
    filtByStimOffPhase = false;
    plots = [1,2];
    lslines = true;
    all_data = false;
    colorLimit = false;
    stepMetricLimit = false;
    metaMetricLimit = false;
    num_bins = 20;
    min_num_steps = 1;
    % parse input params
    for ii = 1:nargin
        if ischar(varargin{ii}) && ~isempty(varargin{ii})
            if varargin{ii}(1) == '-' %find command descriptions
                switch lower(varargin{ii}(2:end))
                    case 'steps'
                        steps = varargin{ii+1};
                    case 'param'
                        param = varargin{ii+1};
                    case 'step_metric'
                        step_metric = varargin{ii+1};
                    case 'meta_metric'
                        meta_metric = varargin{ii+1};
                    case 'flies'
                        flies = varargin{ii+1};
                        flySubset = true;
                    case 'legs'
                        legs = varargin{ii+1};
                    case 'exp_type'
                        exp_type = varargin{ii+1};
                    case 'color_by'
                        color_by = varargin{ii+1};
                        colorData = true;
                    case 'filter_speed'
                        filter_speed = varargin{ii+1};
                        filtBySpeed = true;
                    case 'filter_acceleration'
                        filter_acceleration = varargin{ii+1};
                        filtByAcceleration = true;
                    case 'filter_angular_velocity'
                        filter_angular_velocity = varargin{ii+1};
                        filtByAngularVelocity = true;
                    case 'filter_heading_angle'
                        filter_heading_angle = varargin{ii+1};
                        filtByHeadingAngle = true;
                    case 'filter_temp'
                        filter_temp = varargin{ii+1};
                        filtByTemp = true;
                    case 'filter_stim_on_region'
                        filter_stim_on_region = varargin{ii+1};
                        filtByStimOnRegion = true;
                    case 'filter_stim_off_region'
                        filter_stim_off_region = varargin{ii+1};
                        filtByStimOffRegion = true;                        
                    case 'filter_stim_on_phase'
                        filter_stim_on_phase = varargin{ii+1};
                        filtByStimOnPhase = true;
                    case 'filter_stim_off_phase'
                        filter_stim_off_phase = varargin{ii+1};
                        filtByStimOffPhase = true; 
                    case 'filter_stim_on_phase_joint'
                        filter_stim_on_phase_joint = varargin{ii+1};
                    case 'filter_stim_off_phase_joint'
                        filter_stim_off_phase_joint = varargin{ii+1};
                    case 'plots'
                        plots = varargin{ii+1};
                    case 'lslines'
                        lslines = varargin{ii+1};
                    case 'all_data'
                        all_data = varargin{ii+1};    
                    case 'color_limit'
                        color_limit = varargin{ii+1};                            
                        colorLimit = true;
                    case 'step_metric_limit'
                        step_metric_limit = varargin{ii+1};                            
                        stepMetricLimit = true;
                    case 'meta_metric_limit'
                        meta_metric_limit = varargin{ii+1};                            
                        metaMetricLimit = true;     
                    case 'num_bins'
                        num_bins = varargin{ii+1};  
                    case 'min_num_steps'
                        min_num_steps = varargin{ii+1};                           
                end
            end
        end
    end

    % make sure required inputs were given
    numRequiredParams = 4;
    if (exist('steps','var') + exist('param','var') + exist('step_metric','var') + exist('meta_metric','var')) ~= numRequiredParams
        error('Missing required parameter(s)');
    end   
    
    % fill metadata for saving with figures
    metadata.legs = legs;
    metadata.exp_type = exp_type;
    if exist('color_by', 'var'); metadata.colorBy = color_by; end
    if flySubset; metadata.flies = flies; else; metadata.flies = param.flyList.flyid; end
    if filtBySpeed; metadata.filtBySpeed = filter_speed; end
    if filtByAcceleration; metadata.filtByAcceleration = filter_acceleration; end
    if filtByAngularVelocity; metadata.filtByAngularVelocity = filter_angular_velocity; end
    if filtByHeadingAngle; metadata.filtByHeadingAngle = filter_heading_angle; end
    if filtByTemp; metadata.filtByTemp = filter_temp; end
    if filtByStimOnRegion; metadata.filtByStimOnRegion = filter_stim_on_region; end
    if filtByStimOffRegion; metadata.filtByStimOffRegion = filter_stim_off_region; end
    if filtByStimOnPhase; metadata.filtByStimOnPhase = filter_stim_on_phase; metadata.filtByStimOnPhaseJoint = filter_stim_on_phase_joint; end
    if filtByStimOffPhase; metadata.filtByStimOffPhase = filter_stim_off_phase; metadata.filtByStimOffPhaseJoint = filter_stim_off_phase_joint; end
    
    % select steps for each leg (filtering)
    filtered_steps_control = {}; % a list of row idxs for good (filtered) steps in step struct for each leg. laser off
    filtered_steps_experimental = {}; % a list of row idxs for good (filtered) steps in step struct for each leg. laser on 
    for leg = 1:width(legs) 
        step_idxs = [1:height(steps.leg(legs{leg}).meta)]';
        if flySubset; flyIdxs = find(ismember(steps.leg(legs{leg}).meta.fly, flies)); else flyIdxs = step_idxs; end
        if filtBySpeed; speedIdxs = find(steps.leg(legs{leg}).meta.avg_speed >= filter_speed(1) & steps.leg(legs{leg}).meta.avg_speed <= filter_speed(2)); else speedIdxs = step_idxs; end
        if filtByAcceleration; accelerationIdxs = find(steps.leg(legs{leg}).meta.avg_acceleration >= filter_acceleration(1) & steps.leg(legs{leg}).meta.avg_acceleration <= filter_acceleration(2)); else accelerationIdxs = step_idxs; end
        if filtByAngularVelocity; angularVelocityIdxs = find(steps.leg(legs{leg}).meta.avg_angular_velocity >= filter_angular_velocity(1) & steps.leg(legs{leg}).meta.avg_angular_velocity <= filter_angular_velocity(2)); else angularVelocityIdxs = step_idxs; end
        if filtByHeadingAngle; headingAngleIdxs = find(steps.leg(legs{leg}).meta.avg_heading_angle >= filter_heading_angle(1) & steps.leg(legs{leg}).meta.avg_heading_angle <= filter_heading_angle(2)); else headingAngleIdxs = step_idxs; end
        if filtByTemp; tempIdxs = find(steps.leg(legs{leg}).meta.avg_temp >= filter_temp(1) & steps.leg(legs{leg}).meta.avg_temp <= filter_temp(2)); else tempIdxs = step_idxs; end
        if filtByStimOnRegion; stimOnRegionIdxs = find(strcmpi(steps.leg(legs{leg}).meta.stim_on_region, filter_stim_on_region)); else stimOnRegionIdxs = step_idxs; end
        if filtByStimOffRegion; stimOffRegionIdxs = find(strcmpi(steps.leg(legs{leg}).meta.stim_off_region, filter_stim_off_region)); else stimOffRegionIdxs = step_idxs; end
        if filtByStimOnPhase; stimOnIdxs = ~cellfun(@isempty,steps.leg(legs{leg}).meta.stim_on_phase); 
            stimOnPhaseIdxs = stimOnIdxs(cellfun(@(x) (x.([param.legs{legs{leg}} '_' filter_stim_on_phase_joint])>=filter_stim_on_phase(1) & x.([param.legs{legs{leg}} '_' filter_stim_on_phase_joint])<=filter_stim_on_phase(2)),steps.leg(leg).meta.stim_on_phase(stimOnIdxs)));
        else stimOnPhaseIdxs = step_idxs; end
        if filtByStimOffPhase; stimOffIdxs = find(~cellfun(@isempty,steps.leg(legs{leg}).meta.stim_off_phase)); 
            stimOffPhaseIdxs = stimOffIdxs(cellfun(@(x) (x.([param.legs{legs{leg}} '_' filter_stim_off_phase_joint])>=filter_stim_off_phase(1) & x.([param.legs{legs{leg}} '_' filter_stim_off_phase_joint])<=filter_stim_off_phase(2)),steps.leg(leg).meta.stim_off_phase(stimOffIdxs)));
        else stimOffPhaseIdxs = step_idxs; end    
        
%         %for checking that stimOnPhaseIdxs are correct. plot hist(newtable.L1_FTi) for the joint being filtered on: 
%         aa = {steps.leg(leg).meta.stim_on_phase{stimOnPhaseIdxs}};
%         newtable = [];
%         for t = 1:width(aa)
%             newtable = [newtable; aa{t}];
%         end
        
        %ctl vs stim steps 
        controlStepIdxs = find(steps.leg(legs{leg}).meta.avg_stim == 0); %no aser
        if strcmpi(exp_type, 'any') %exp is any amout of stim during step
            stimStepIdxs = find(steps.leg(legs{leg}).meta.avg_stim > 0);
        elseif strcmpi(exp_type, 'all') %exp is step occured entirely during stim
            stimStepIdxs = find(steps.leg(legs{leg}).meta.avg_stim == 1);
        end 
        
        %save indices of filtered steps
        filtered_steps_control{leg} = mintersect(flyIdxs, speedIdxs, accelerationIdxs, angularVelocityIdxs, headingAngleIdxs, tempIdxs, controlStepIdxs);
        filtered_steps_experimental{leg} = mintersect(flyIdxs, speedIdxs, accelerationIdxs, angularVelocityIdxs, headingAngleIdxs, tempIdxs, stimStepIdxs, stimOnRegionIdxs, stimOffRegionIdxs, stimOnPhaseIdxs, stimOffPhaseIdxs);

    end
    
    % plot! 
    plotNum = 1;
    
    %1) scatter plots: experimental vs control steps with least squares lines
    if ismember(plots, plotNum)
        lims = [];
        plotting = numSubplots(width(legs));
        fig = fullfig; 
        if colorData
            %get min and max values of the color_by var for each leg for unified colorbar scales across legs. 
            bottom = min(min(steps.leg(legs{1}).meta.(color_by)(filtered_steps_control{1})), min(steps.leg(legs{1}).meta.(color_by)(filtered_steps_experimental{1})));
            top = max(max(steps.leg(legs{1}).meta.(color_by)(filtered_steps_control{1})), max(steps.leg(legs{1}).meta.(color_by)(filtered_steps_experimental{1})));
            for leg = 2:width(legs)
                leg_min = min(min(steps.leg(legs{leg}).meta.(color_by)(filtered_steps_control{leg})), min(steps.leg(legs{leg}).meta.(color_by)(filtered_steps_experimental{leg})));
                leg_max = max(max(steps.leg(legs{leg}).meta.(color_by)(filtered_steps_control{leg})), max(steps.leg(legs{leg}).meta.(color_by)(filtered_steps_experimental{leg})));
                bottom = min(bottom, leg_min);
                top = max(top, leg_max);
            end
        end
        for leg = 1:width(legs)
            AX(leg) = subplot(plotting(1), plotting(2), leg); hold on
            
            %get x and y data (filter if indicated) 
            ctl_x = steps.leg(legs{leg}).meta.(meta_metric)(filtered_steps_control{leg});
            ctl_y = steps.leg(legs{leg}).meta.(step_metric)(filtered_steps_control{leg});
            exp_x = steps.leg(legs{leg}).meta.(meta_metric)(filtered_steps_experimental{leg});
            exp_y = steps.leg(legs{leg}).meta.(step_metric)(filtered_steps_experimental{leg});
            if metaMetricLimit
               ctl_meta_lim = ctl_x >= meta_metric_limit(1) & ctl_x <= meta_metric_limit(2);
               exp_meta_lim = exp_x >= meta_metric_limit(1) & exp_x <= meta_metric_limit(2);
               ctl_x = ctl_x(ctl_meta_lim); 
               ctl_y = ctl_y(ctl_meta_lim); 
               exp_x = exp_x(exp_meta_lim); 
               exp_y = exp_y(exp_meta_lim); 
            end
            if stepMetricLimit
               ctl_step_lim = ctl_y >= step_metric_limit(1) & ctl_y <= step_metric_limit(2);
               exp_step_lim = exp_y >= step_metric_limit(1) & exp_y <= step_metric_limit(2);
               ctl_x = ctl_x(ctl_step_lim); 
               ctl_y = ctl_y(ctl_step_lim); 
               exp_x = exp_x(exp_step_lim); 
               exp_y = exp_y(exp_step_lim); 
            end
                           
            %get color data
            if colorData
                %manually set limits of colorbar so subplot color scales are all the same. 
                caxis manual
                if colorLimit
                    caxis(color_limit);
                else
                    caxis([bottom top]);
                end

                %color data by color_by variable
                ctl_color = steps.leg(legs{leg}).meta.(color_by)(filtered_steps_control{leg});
                exp_color = steps.leg(legs{leg}).meta.(color_by)(filtered_steps_experimental{leg});
                
                %filter color data to match meta and step metric limits. 
                if metaMetricLimit
                    ctl_color = ctl_color(ctl_meta_lim, :); 
                    exp_color = exp_color(exp_meta_lim, :);
                end
                if stepMetricLimit
                    ctl_color = ctl_color(ctl_step_lim, :); 
                    exp_color = exp_color(exp_step_lim, :);
                end
                
                %if color var is a string variable, convert to numeric data. 
                if isa(ctl_color, 'string')
                    ctl_uniques = unique(ctl_color);
                    [ctl_tf,ctl_idx] = ismember(ctl_color,ctl_uniques);
                    ctl_color = ctl_idx(ctl_tf);
                end
                if isa(exp_color, 'string')
                    exp_uniques = unique(exp_color);
                    [exp_tf,exp_idx] = ismember(exp_color,exp_uniques);
                    exp_color = exp_idx(exp_tf);
                end
            else
                ctl_color = Color(param.baseColor);
                exp_color = Color(param.laserColor);
            end
            
            %plot data
            c = scatter(ctl_x, ctl_y, [], ctl_color);
            if lslines; h = lsline; end
            e = scatter(exp_x, exp_y, [], exp_color);
            if lslines; h = lsline; end

            if lslines
                %set colors of least squares lines 
                set(h(2),'color',Color(param.baseColor));
                set(h(2),'linewidth',2);
                set(h(1),'color',Color(param.laserColor));
                set(h(1),'linewidth',2);
            end

            if leg == 1
                xlabel(strrep(meta_metric, '_', ' '));
                if lslines; ylabel([strrep(step_metric, '_', ' ') ' with least squares line']);
                else; ylabel(strrep(step_metric, '_', ' ')); end
                if colorData
                    c = colorbar;
                    c.Color = param.baseColor;
                    c.Position(1) = .93;
                end
            end
            title(param.legs{legs{leg}});

        end
        %format fig
        if param.sameAxes
            % make all axes the same
            allYLim = get(AX, {'YLim'});
            allYLim = cat(2, allYLim{:});
            set(AX, 'YLim', [min(allYLim), max(allYLim)]);

            allXLim = get(AX, {'XLim'});
            allXLim = cat(2, allXLim{:});
            set(AX, 'XLim', [min(allXLim), max(allXLim)]);
        end
        fig = formatFig(fig, true, plotting);
        %attach metadata
        fig.UserData = metadata;
        %save
        fig_name = [step_metric '_vs_' meta_metric '_scatter'];
        save_figure(fig, [param.googledrivesave fig_name], param.fileType)
    end
    plotNum = plotNum+1;
    
    %2) density plots: experimental vs control
    if ismember(plots, plotNum)
        plotting = numSubplots(width(legs));
        plotting(2) = plotting(2)*2; %double number of columns so I can plot exp and control next to each other. 
        fig = fullfig; 
        idx = 0;
        for leg = 1:width(legs)
            idx = idx+1;
            AX(idx) = subplot(plotting(1), plotting(2), idx); hold on
            histogram2(steps.leg(legs{leg}).meta.(meta_metric)(filtered_steps_control{leg}), steps.leg(legs{leg}).meta.(step_metric)(filtered_steps_control{leg}), 'DisplayStyle', 'tile', 'Normalization', 'pdf');
            if leg == 1
                xlabel(strrep(meta_metric, '_', ' '));
                ylabel(strrep(step_metric, '_', ' '));
                c = colorbar;
                c.Color = param.baseColor;
            end
            title([param.legs{legs{leg}} ' control']);

            idx = idx+1;
            AX(idx) = subplot(plotting(1), plotting(2), idx); hold on
            histogram2(steps.leg(legs{leg}).meta.(meta_metric)(filtered_steps_experimental{leg}), steps.leg(legs{leg}).meta.(step_metric)(filtered_steps_experimental{leg}), 'DisplayStyle', 'tile', 'Normalization', 'pdf');
            title([param.legs{legs{leg}} ' stimulus']);

        end
        %format fig
        if param.sameAxes
            % make all axes the same
            allYLim = get(AX, {'YLim'});
            allYLim = cat(2, allYLim{:});
            set(AX, 'YLim', [min(allYLim), max(allYLim)]);
            
            allXLim = get(AX, {'XLim'});
            allXLim = cat(2, allXLim{:});
            set(AX, 'XLim', [min(allXLim), max(allXLim)]);
        end
        fig = formatFig(fig, true, plotting);
        %attach metadata
        fig.UserData = metadata;
        %save
        fig_name = [step_metric '_vs_' meta_metric '_density'];
        save_figure(fig, [param.googledrivesave fig_name], param.fileType)
    end
    plotNum = plotNum+1;

    %3) avg + std plots: experimental vs control - meta_variable is binned.
    if ismember(plots, plotNum)
        plotting = numSubplots(width(legs));
        fig = fullfig; 
        for leg = 1:width(legs)
            AX(leg) = subplot(plotting(1), plotting(2), leg); hold on
            
            if all_data    %plot all data together:
                %get data
                x = [steps.leg(legs{leg}).meta.(meta_metric)(filtered_steps_control{leg}); steps.leg(legs{leg}).meta.(meta_metric)(filtered_steps_experimental{leg})];
                y = [steps.leg(legs{leg}).meta.(step_metric)(filtered_steps_control{leg});steps.leg(legs{leg}).meta.(step_metric)(filtered_steps_experimental{leg})];
                
                %bin data
                [bins, edges] = discretize(x, num_bins);
                for bin = 1:num_bins
                   y_avg(bin) = mean(y(bins == bin), 1, 'omitnan');
                   y_std(bin) = std(y(bins == bin), 1, 'omitnan');
                   x_bins(bin) = mean([edges(bin), edges(bin+1)],2);
                   c_count(bin) = sum(bins == bin); %color points by number of datapoints in bin  
                end

                %plot data (only bins with min_num_steps datapoints) 
                d = errorbar(x_bins(c_count > min_num_steps), y_avg(c_count > min_num_steps), y_std(c_count > min_num_steps), 'o');
                d.Color = Color(param.baseColor);
                
            else    %plot experimental vs control:
                
                %get color data
                ctl_color = Color(param.baseColor);
                exp_color = Color(param.laserColor);

                %bin data
                ctl_x = steps.leg(legs{leg}).meta.(meta_metric)(filtered_steps_control{leg});
                ctl_y = steps.leg(legs{leg}).meta.(step_metric)(filtered_steps_control{leg});
                exp_x = steps.leg(legs{leg}).meta.(meta_metric)(filtered_steps_experimental{leg});
                exp_y = steps.leg(legs{leg}).meta.(step_metric)(filtered_steps_experimental{leg});

                [ctl_bins,ctl_edges] = discretize(ctl_x,num_bins);
                [exp_bins,exp_edges] = discretize(exp_x,ctl_edges); %ctl and exp data have same bins

                for bin = 1:num_bins
                   ctl_y_avg(bin) = mean(ctl_y(ctl_bins == bin), 1, 'omitnan');
                   ctl_y_std(bin) = std(ctl_y(ctl_bins == bin), 1, 'omitnan');
                   ctl_x_bins(bin) = mean([ctl_edges(bin), ctl_edges(bin+1)],2);
                   ctl_c_count(bin) = sum(ctl_bins == bin); %color points by number of datapoints in bin  

                   exp_y_avg(bin) = mean(exp_y(exp_bins == bin), 1, 'omitnan');
                   exp_y_std(bin) = std(exp_y(exp_bins == bin), 1, 'omitnan');
                   exp_x_bins(bin) = mean([exp_edges(bin), exp_edges(bin+1)], 2);
                   exp_c_count(bin) = sum(exp_bins == bin); %color points by number of datapoints in bin  

                end

                %plot data
                c = errorbar(ctl_x_bins, ctl_y_avg, ctl_y_std,'o');
                e = errorbar(exp_x_bins, exp_y_avg, exp_y_std,'o');

                c.Color = ctl_color;
                e.Color = exp_color;
            end

            if leg == 1
                xlabel(strrep(meta_metric, '_', ' '));
                ylabel(strrep(step_metric, '_', ' '));
            end
            title(param.legs{legs{leg}});

        end
        %format fig
        if param.sameAxes
            % make all axes the same
            allYLim = get(AX, {'YLim'});
            allYLim = cat(2, allYLim{:});
            set(AX, 'YLim', [min(allYLim), max(allYLim)]);
            
            allXLim = get(AX, {'XLim'});
            allXLim = cat(2, allXLim{:});
            set(AX, 'XLim', [min(allXLim), max(allXLim)]);
        end
        fig = formatFig(fig, true, plotting);
        %attach metadata
        fig.UserData = metadata;
        %save
        fig_name = [step_metric '_vs_' meta_metric '_binned_averages'];
        save_figure(fig, [param.googledrivesave fig_name], param.fileType)
    end
    plotNum = plotNum+1;
    
end