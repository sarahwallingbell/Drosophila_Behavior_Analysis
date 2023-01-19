function Plot_AEP_PEP(varargin)
%
% Plot the anterior extreme position (AEP) and posterior extreme position
% (PEP) of walking data. 
% 
% Required params:
%     'steps' - output from steps.m
%     'param' - param struct from DLC_load_params.m
% Optional params:
%     'flies' - a subset of flies to analyze. A cell of 'flyid's. 
%     'exp_type' - 'any' = exp steps have any laser. 'all' = exp steps are fully in laser. Default is 'any'. 
% 
%
% Sarah Walling-Bell
% November 2021
%     

% TODO - add optional param for 2d (pick two position vars) or 3d (x,y,z) plotting
% TODO - add option to plot raw points
% TODO - add option to plot histograms of AEPs and PEPs
% TODO - add option to pick which joint to plot (tbd, still use tarsi tips
    % to find AEP PEP points, or use this joints position?)



    %set defaults for optional params
    flySubset = false;
    exp_type = 'any';
    % parse input params
    for ii = 1:nargin
        if ischar(varargin{ii}) && ~isempty(varargin{ii})
            if varargin{ii}(1) == '-' %find command descriptions
                switch lower(varargin{ii}(2:end))
                    case 'steps'
                        steps = varargin{ii+1};
                    case 'param'
                        param = varargin{ii+1};
                    case 'flies'
                        flies = varargin{ii+1};
                        flySubset = true;
                    case 'exp_type'
                        exp_type = varargin{ii+1};
                end
            end
        end
    end

    % make sure required inputs were given
    numRequiredParams = 2;
    if (exist('steps','var') + exist('param','var')) ~= numRequiredParams
        error('Missing required parameter(s)');
    end    
    
    %select control (no laser) & experimental (laser) steps
    ctl_idxs = {};
    exp_idxs = {};
    for leg = 1:param.numLegs
        %control steps
        if flySubset
            ctl_idxs{leg} = find(steps.leg(leg).meta.avg_stim == 0 & ismember(steps.leg(leg).meta.fly, flies));
        else
            ctl_idxs{leg} = find(steps.leg(leg).meta.avg_stim == 0);
        end
        
        %experimental steps
        if strcmpi(exp_type, 'any') %exp is any amout of stim during step
            if flySubset
                exp_idxs{leg} = find(steps.leg(leg).meta.avg_stim > 0 & ismember(steps.leg(leg).meta.fly, flies));
            else
                exp_idxs{leg} = find(steps.leg(leg).meta.avg_stim > 0);
            end
        elseif strcmpi(exp_type, 'all') %exp is step occured entirely during stim
            if flySubset
                exp_idxs{leg} = find(steps.leg(leg).meta.avg_stim == 1 & ismember(steps.leg(leg).meta.fly, flies));
            else
                exp_idxs{leg} = find(steps.leg(leg).meta.avg_stim == 1);
            end
        else 
            error('Invalid input for exp_type. Must be `any` or `all`.');
        end
    end
    
    %get AEPs and PEPs: raw points, averages, and standard devs
    %AEP = last tarsus Y position. Steps are already parsed by max y
        %positions. If I choose max here, some points will be doubled across
        %steps. So be consistent - AEP is where the leg ended up at the end of
        %swing.
    %PEP = min tarsus Y position.
    ctl_AEP = {};
    ctl_PEP = {};
    exp_AEP = {};
    exp_PEP = {};
    for leg = 1:param.numLegs
        %control 
        x_pos = steps.leg(leg).E_x(ctl_idxs{leg},:);
        y_pos = steps.leg(leg).E_y(ctl_idxs{leg},:);
        z_pos = steps.leg(leg).E_z(ctl_idxs{leg},:);
        
        %AEPs
        y_notnan = ~isnan(y_pos);
        % indices
        AEPidxs = arrayfun(@(x) find(y_notnan(x, :), 1, 'last'), 1:size(y_pos, 1));
        % values
        xVals = arrayfun(@(x,y) x_pos(x,y), 1:size(x_pos, 1), AEPidxs);
        yVals = arrayfun(@(x,y) y_pos(x,y), 1:size(y_pos, 1), AEPidxs);
        zVals = arrayfun(@(x,y) z_pos(x,y), 1:size(z_pos, 1), AEPidxs);
        %save
        ctl_AEP.leg(leg).idxs = AEPidxs;
        ctl_AEP.leg(leg).all_x = xVals; %x pos
        ctl_AEP.leg(leg).avg_x = mean(xVals, 'omitnan');
        ctl_AEP.leg(leg).std_x = std(xVals, 'omitnan');
        ctl_AEP.leg(leg).all_y = yVals; %y pos
        ctl_AEP.leg(leg).avg_y = mean(yVals, 'omitnan');
        ctl_AEP.leg(leg).std_y = std(yVals, 'omitnan');
        ctl_AEP.leg(leg).all_z = zVals; %z pos
        ctl_AEP.leg(leg).avg_z = mean(zVals, 'omitnan');
        ctl_AEP.leg(leg).std_z = std(zVals, 'omitnan');        
        
        %PEPs
        % indices and values
        [yVals,PEPidxs] = min(y_pos,[],2, 'omitnan'); %use y position peaks and torughs to find AEP and PEPs. Then index into x and z positions at these idxs. 
        xVals = arrayfun(@(x,y) x_pos(x,y), 1:size(x_pos, 1), PEPidxs');
        zVals = arrayfun(@(x,y) z_pos(x,y), 1:size(z_pos, 1), PEPidxs');
        %save
        ctl_PEP.leg(leg).idxs = PEPidxs;
        ctl_PEP.leg(leg).all_x = xVals; %x pos
        ctl_PEP.leg(leg).avg_x = mean(xVals, 'omitnan');
        ctl_PEP.leg(leg).std_x = std(xVals, 'omitnan');
        ctl_PEP.leg(leg).all_y = yVals; %y pos
        ctl_PEP.leg(leg).avg_y = mean(yVals, 'omitnan');
        ctl_PEP.leg(leg).std_y = std(yVals, 'omitnan');
        ctl_PEP.leg(leg).all_z = zVals; %z pos
        ctl_PEP.leg(leg).avg_z = mean(zVals, 'omitnan');
        ctl_PEP.leg(leg).std_z = std(zVals, 'omitnan');        
        
        %experimental 
        x_pos = steps.leg(leg).E_x(exp_idxs{leg},:);
        y_pos = steps.leg(leg).E_y(exp_idxs{leg},:);
        z_pos = steps.leg(leg).E_z(exp_idxs{leg},:);
        
        %AEPs
        y_notnan = ~isnan(y_pos);
        % indices
        AEPidxs = arrayfun(@(x) find(y_notnan(x, :), 1, 'last'), 1:size(y_pos, 1));
        % values
        xVals = arrayfun(@(x,y) x_pos(x,y), 1:size(x_pos, 1), AEPidxs);
        yVals = arrayfun(@(x,y) y_pos(x,y), 1:size(y_pos, 1), AEPidxs);
        zVals = arrayfun(@(x,y) z_pos(x,y), 1:size(z_pos, 1), AEPidxs);
        %save
        exp_AEP.leg(leg).idxs = AEPidxs;
        exp_AEP.leg(leg).all_x = xVals; %x pos
        exp_AEP.leg(leg).avg_x = mean(xVals, 'omitnan');
        exp_AEP.leg(leg).std_x = std(xVals, 'omitnan');
        exp_AEP.leg(leg).all_y = yVals; %y pos
        exp_AEP.leg(leg).avg_y = mean(yVals, 'omitnan');
        exp_AEP.leg(leg).std_y = std(yVals, 'omitnan');
        exp_AEP.leg(leg).all_z = zVals; %z pos
        exp_AEP.leg(leg).avg_z = mean(zVals, 'omitnan');
        exp_AEP.leg(leg).std_z = std(zVals, 'omitnan');        
        
        %PEPs
        % indices and values
        [yVals,PEPidxs] = min(y_pos,[],2, 'omitnan'); %use y position peaks and torughs to find AEP and PEPs. Then index into x and z positions at these idxs. 
        xVals = arrayfun(@(x,y) x_pos(x,y), 1:size(x_pos, 1), PEPidxs');
        zVals = arrayfun(@(x,y) z_pos(x,y), 1:size(z_pos, 1), PEPidxs');
        %save
        exp_PEP.leg(leg).idxs = PEPidxs;
        exp_PEP.leg(leg).all_x = xVals; %x pos
        exp_PEP.leg(leg).avg_x = mean(xVals, 'omitnan');
        exp_PEP.leg(leg).std_x = std(xVals, 'omitnan');
        exp_PEP.leg(leg).all_y = yVals; %y pos
        exp_PEP.leg(leg).avg_y = mean(yVals, 'omitnan');
        exp_PEP.leg(leg).std_y = std(yVals, 'omitnan');
        exp_PEP.leg(leg).all_z = zVals; %z pos
        exp_PEP.leg(leg).avg_z = mean(zVals, 'omitnan');
        exp_PEP.leg(leg).std_z = std(zVals, 'omitnan');  
        
    end

    %plot AEPs
    fig = fullfig; hold on
    for leg = 1:param.numLegs
       %control
       e = errorbar(ctl_AEP.leg(leg).avg_x,ctl_AEP.leg(leg).avg_y,ctl_AEP.leg(leg).std_y,ctl_AEP.leg(leg).std_y,ctl_AEP.leg(leg).std_x,ctl_AEP.leg(leg).std_x,'v');
       e.Color = Color(param.baseColor);
       %experimental
       e = errorbar(exp_AEP.leg(leg).avg_x,exp_AEP.leg(leg).avg_y,exp_AEP.leg(leg).std_y,exp_AEP.leg(leg).std_y,exp_AEP.leg(leg).std_x,exp_AEP.leg(leg).std_x,'v');
       e.Color = Color(param.leg_colors{leg});

    end
    hold off
    fig = formatFig(fig, true);
    %Save!
    fig_name = 'AEP_allLegs_tarsiTipPositions_ctl_vs_stim';
    save_figure(fig, [param.googledrivesave fig_name], param.fileType);

    
    %plot PEPs
    fig = fullfig; hold on
    for leg = 1:param.numLegs
       %control
       e = errorbar(ctl_PEP.leg(leg).avg_x,ctl_PEP.leg(leg).avg_y,ctl_PEP.leg(leg).std_y,ctl_PEP.leg(leg).std_y,ctl_PEP.leg(leg).std_x,ctl_PEP.leg(leg).std_x,'^');
       e.Color = Color(param.baseColor);

       %experimental
       e = errorbar(exp_PEP.leg(leg).avg_x,exp_PEP.leg(leg).avg_y,exp_PEP.leg(leg).std_y,exp_PEP.leg(leg).std_y,exp_PEP.leg(leg).std_x,exp_PEP.leg(leg).std_x,'^');
       e.Color = Color(param.leg_colors{leg});
    end
    hold off
    fig = formatFig(fig, true);
    %Save!
    fig_name = 'PEP_allLegs_tarsiTipPositions_ctl_vs_stim';
    save_figure(fig, [param.googledrivesave fig_name], param.fileType);
    
    
    %plot AEPs and PEPs
    fig = fullfig; hold on
    for leg = 1:param.numLegs
       %AEPs
       %control
       e = errorbar(ctl_AEP.leg(leg).avg_x,ctl_AEP.leg(leg).avg_y,ctl_AEP.leg(leg).std_y,ctl_AEP.leg(leg).std_y,ctl_AEP.leg(leg).std_x,ctl_AEP.leg(leg).std_x, ':o','LineWidth',1);
       e.Color = Color(param.baseColor);
       %experimental
       e = errorbar(exp_AEP.leg(leg).avg_x,exp_AEP.leg(leg).avg_y,exp_AEP.leg(leg).std_y,exp_AEP.leg(leg).std_y,exp_AEP.leg(leg).std_x,exp_AEP.leg(leg).std_x,'*','LineWidth',1);
       e.Color = Color(param.leg_colors{leg});
       %PEPs
       %control
       e = errorbar(ctl_PEP.leg(leg).avg_x,ctl_PEP.leg(leg).avg_y,ctl_PEP.leg(leg).std_y,ctl_PEP.leg(leg).std_y,ctl_PEP.leg(leg).std_x,ctl_PEP.leg(leg).std_x, ':o','LineWidth',1);
       e.Color = Color(param.baseColor);
       %experimental
       e = errorbar(exp_PEP.leg(leg).avg_x,exp_PEP.leg(leg).avg_y,exp_PEP.leg(leg).std_y,exp_PEP.leg(leg).std_y,exp_PEP.leg(leg).std_x,exp_PEP.leg(leg).std_x,'*','LineWidth',1);
       e.Color = Color(param.leg_colors{leg});
       
    end
    hold off
    fig = formatFig(fig, true);
    %Save!
    fig_name = 'AEP_PEP_allLegs_tarsiTipPositions_ctl_vs_stim';
    save_figure(fig, [param.googledrivesave fig_name], param.fileType);
    
    
    %plot x position histograms
    fig = fullfig; hold on
    legidx = [1,5,9,3,7,11];
    for leg = 1:param.numLegs
        subplot(3,4,legidx(leg)); hold on
        histogram(ctl_AEP.leg(leg).all_x, 'Normalization', 'pdf', 'FaceColor', Color(param.baseColor));
        histogram(exp_AEP.leg(leg).all_x, 'Normalization', 'pdf', 'FaceColor', Color(param.leg_colors{leg}));
        title([param.legs{leg} ' AEP']);
        if legidx(leg) == 1
            ylabel('pdf');
            xlabel('Tarsus x position');
        end
        hold off
        subplot(3,4,legidx(leg)+1); hold on
        histogram(ctl_PEP.leg(leg).all_x, 'Normalization', 'pdf', 'FaceColor', Color(param.baseColor));
        histogram(exp_PEP.leg(leg).all_x, 'Normalization', 'pdf', 'FaceColor', Color(param.leg_colors{leg}));
        title([param.legs{leg} ' PEP']);
        hold off;
    end
    hold off
    fig = formatFig(fig, true, [3,4]);
    %Save!
    fig_name = 'AEP_PEP_allLegs_tarsiTip_X_Positions_ctl_vs_stim_histograms';
    save_figure(fig, [param.googledrivesave fig_name], param.fileType)
    
    
    %plot y position histograms
    fig = fullfig; hold on
    legidx = [1,5,9,3,7,11];
    for leg = 1:param.numLegs
        subplot(3,4,legidx(leg)); hold on
        histogram(ctl_AEP.leg(leg).all_y, 'Normalization', 'pdf', 'FaceColor', Color(param.baseColor));
        histogram(exp_AEP.leg(leg).all_y, 'Normalization', 'pdf', 'FaceColor', Color(param.leg_colors{leg}));
        title([param.legs{leg} ' AEP']);
        if legidx(leg) == 1
            ylabel('pdf');
            xlabel('Tarsus y position');
        end
        hold off
        subplot(3,4,legidx(leg)+1); hold on
        histogram(ctl_PEP.leg(leg).all_y, 'Normalization', 'pdf', 'FaceColor', Color(param.baseColor));
        histogram(exp_PEP.leg(leg).all_y, 'Normalization', 'pdf', 'FaceColor', Color(param.leg_colors{leg}));
        title([param.legs{leg} ' PEP']);
        hold off;

    end
    hold off
    fig = formatFig(fig, true, [3,4]);
    %Save!
    fig_name = 'AEP_PEP_allLegs_tarsiTip_Y_Positions_ctl_vs_stim_histograms';
    save_figure(fig, [param.googledrivesave fig_name], param.fileType)
    
    
    %plot z position histograms
    fig = fullfig; hold on
    legidx = [1,5,9,3,7,11];
    for leg = 1:param.numLegs
        subplot(3,4,legidx(leg)); hold on
        histogram(ctl_AEP.leg(leg).all_z, 'Normalization', 'pdf', 'FaceColor', Color(param.baseColor));
        histogram(exp_AEP.leg(leg).all_z, 'Normalization', 'pdf', 'FaceColor', Color(param.leg_colors{leg}));
        title([param.legs{leg} ' AEP']);
        if legidx(leg) == 1
            ylabel('pdf');
            xlabel('Tarsus z position');
        end
        hold off
        subplot(3,4,legidx(leg)+1); hold on
        histogram(ctl_PEP.leg(leg).all_z, 'Normalization', 'pdf', 'FaceColor', Color(param.baseColor));
        histogram(exp_PEP.leg(leg).all_z, 'Normalization', 'pdf', 'FaceColor', Color(param.leg_colors{leg}));
        title([param.legs{leg} ' PEP']);
        hold off;
    end
    hold off
    fig = formatFig(fig, true, [3,4]);
    %Save!
    fig_name = 'AEP_PEP_allLegs_tarsiTip_Z_Positions_ctl_vs_stim_histograms';
    save_figure(fig, [param.googledrivesave fig_name], param.fileType)
    
    
    %plot 3d AEPs  clea
    
    
    
    
end
