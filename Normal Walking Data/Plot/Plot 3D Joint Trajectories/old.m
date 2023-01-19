function Plot_3D_Joint_Position_Trajectory(varargin)
% 
% Plot joint position data in 3D. 
% 
% Required params:
%     'data' - a parquet summary file of data
%     'param' - param struct from DLC_load_params.m
%     'indices' - a vector of row numbers in 'data' to plot
%         Ex: [1:599]
%     'joints' - a cell of leg+joint names to plot.   
%         Ex: {'L1A', 'L1B', 'L1C', 'L2E', 'R1D'}
%     'path' - a file path for saving the plot
% 
% Optional params:
%     '-plot_ball' - true/false for plotting the ball or not. Assume true - plot the ball.
%     '-color_stim' - true/false for plotting the stim region in a different color if there is a stim region. Assume true - plot stim different color.
%     '-color_time' - true/false for plotting the trajectory as a changing color to represent time. Assume False - don't plot with changing color for time.
%     '-slow_plot' - plots data slowly such that it looks like a video of the fly moving. Assume false - plot data all at once.
% Sarah Walling-Bell
% November 2021
%     

    %set defaults for optional params
    plot_ball = true;
    color_stim = true;
    color_time = false;
    slow_plot = false;
    % parse input params
    for ii = 1:nargin
        if ischar(varargin{ii}) && ~isempty(varargin{ii})
            if varargin{ii}(1) == '-' %find command descriptions
                switch lower(varargin{ii}(2:end))
                    case 'data'
                        data = varargin{ii+1};
                    case 'param'
                        param = varargin{ii+1};
                    case 'indices'
                        indices = varargin{ii+1};
                    case 'joints'
                        joints = varargin{ii+1};
                    case 'path'
                        path = varargin{ii+1};
                    case 'plot_ball'
                        plot_ball = varargin{ii+1};
                    case 'color_stim'
                        color_stim = varargin{ii+1};
                    case 'color_time'
                        color_time = varargin{ii+1};
                    case 'slow_plot'
                        slow_plot = varargin{ii+1};
                end
            end
        end
    end

    % make sure required inputs were given
    numRequiredParams = 5;
    if (exist('data','var') + exist('param','var') + exist('indices','var') + exist('joints','var') + exist('path','var')) ~= numRequiredParams
        error('Missing required parameter(s)');
    end

   %ball fit to tarsus tips in stance & formatted data (in positive space)
   [Center, Radius, BallFitData] = ball_fit(data(indices,:), param);

   %convert joints to indices in BallFitData
   BallFitFields = fieldnames(BallFitData);
   jnt_data_idxs = {}; %idxs in BallFitData to plot
   for jnt = 1:width(joints)
       this_jnt = joints{jnt};
       jnt_idx = find(strcmpi(param.jointLetters, this_jnt(3)));
       leg_idx = find(strcmpi(param.legs, this_jnt(1:2)));
       jnt_data_idxs{jnt} = [jnt_idx,leg_idx]; %plot this leg+joint combo
   end

   %plotting params
   ball_color = 'grey';       

   SZ = 10; % size of scatter plot points
   LW = 1; % line width for plots
   LW_stim = 3; %line width for stim portion of plot
   joint_alpha = 0.5;

   leg_colors = {'blue', 'yellow', 'orange', 'purple', 'white', 'cyan'}; %each leg has its own color
 % leg_colors = {'blue', 'orange', 'blue', 'orange', 'blue', 'orange'}; %each TRIPOD has its own color
   joint_saturations = [0.1, 0.3, 0.5, 0.7, 0.9]; %each joint has its own saturation of the leg color
   for leg = 1:6 %populate 'kolor' with rgb for each leg+joint combo
      this_leg_hsv = rgb2hsv(Color(leg_colors{leg}));
      for joint = 1:5
          this_joint_hsv = [this_leg_hsv(1), joint_saturations(joint), this_leg_hsv(3)]; 
          kolor(:,joint,leg) = hsv2rgb(this_joint_hsv); 
      end
   end

   if color_stim  %find indices (if any) that are during a stim 
        frames = double(data.fnum(indices));
        stim_region = zeros(height(frames), 1); %1 = stim, 0 = no stim 
        %1) find if multiple reps in these idxs, if so, throw an error
        rep = unique(data.rep(indices));
        if height(rep) > 1
           warning('Multiple stimulus reps in these indices. Cant plot stim in different color.');
           color_stim = false; 
        elseif param.allLasers(rep) == 0
           warning('FYI: this is a control video (no stimulus to plot in diff color)');
           color_stim = false; %there's no laser to plot (ex: it's a control vid)
        else
           %check that all the frames are in order, that there's not a
           %jump to another vid (i.e. another vid with the same rep type)
           if height(unique(diff(frames))) > 1
               warning('Multiple videos in these indices. Cant plot stim in different color.');
               color_stim = false;
           else 
               stim_region(frames >= param.laser_on & frames < param.laser_on+(param.allLasers(rep) * param.fps)) = 1;
               if sum(stim_region) == 0
                   warning('Warning: indices contain no stim region.');
                   color_stim = 0;
               end
           end
       end
   end
   if color_time %get colors for plotting over time 
       frame_colors = cool(height(frames)); %pick whatever colormap
   end

    %plot!

    fig = fullfig; 
    
    if ~slow_plot %plot all the data at once
    hold on
        for frame = 1:height(frames)-1
        for jnt = 1:width(joints)
            this_jnt_data = BallFitData(jnt_data_idxs{jnt}(2)).(BallFitFields{jnt_data_idxs{jnt}(1)});
            if color_stim & stim_region(frame) == 1
                    %plot this point in laser color
                    plot3(this_jnt_data(frame:frame+1,1),this_jnt_data(frame:frame+1,2),this_jnt_data(frame:frame+1,3), 'linewidth', LW_stim, 'color', [[Color(param.laserColorBright)], joint_alpha]);
            elseif color_time
                    %plot this point in frame_colors color
                    plot3(this_jnt_data(frame:frame+1,1),this_jnt_data(frame:frame+1,2),this_jnt_data(frame:frame+1,3), 'linewidth', LW, 'color', [[frame_colors(frame,:)], joint_alpha]);
            else
                    %plot this point in kolors color
                    plot3(this_jnt_data(frame:frame+1,1),this_jnt_data(frame:frame+1,2),this_jnt_data(frame:frame+1,3), 'linewidth', LW, 'color', [[kolor(:,jnt_data_idxs{jnt}(1),jnt_data_idxs{jnt}(2))]', joint_alpha]);
            end
        end
    end
    end
    
    axis tight
    box off
    set(gca,'visible','off')

    if plot_ball
        [x,y,z] = sphere;
        s = surf(Radius*x+Center(1), Radius*y+Center(2), Radius*z+Center(3));
        set(s, 'FaceColor', Color(ball_color))
        alpha 0.2
    end
    
    axis vis3d % sets the aspect ratio for 3d rotation
    ax = gca;               % get the current axis
    ax.Clipping = 'off';
    
    %change background color
    fig = formatFig(fig, true);
    
    if slow_plot %plot all the data slowly 

        for leg = 1:param.numLegs
            %get animated lines for each leg 
            animatedLines(leg) = animatedline(ax, 'Color', Color(leg_colors(leg))); 
            %get the data for each leg
            draw(leg).data = ballFitData(leg).(param.legNodes{joint})(plottingFrames,:);
        end

        %plot data on ball 
        for frame = 1:height(draw(1).data) 
            set(gca,'visible','off') %turn off axes
            %plot frame for each leg 
            for leg = 1:param.numLegs
                if frame > fadeLimit
                   %get current points, clear animation, and add all but the last data point
                   [x,y,z] = getpoints(animatedLines(leg));
                   clearpoints(animatedLines(leg));
                   addpoints(animatedLines(leg), x(2:end), y(2:end), z(2:end));
                end
                addpoints(animatedLines(leg), draw(leg).data(frame,1), draw(leg).data(frame,2), draw(leg).data(frame,3));
            end
            drawnow
        %     pause(0.1); %control plotting speed
        end
    
    end
    

    % title(['Walking bout ' num2str(bout_to_plot)], 'color', param.baseColor);
    
    
    %TODO save to path... 


end

