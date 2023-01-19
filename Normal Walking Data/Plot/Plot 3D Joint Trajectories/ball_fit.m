function [Center, Radius, BallFitData] = ball_fit(data, param)

% Given some data (aka a video), throw all joint data into positive space and 
% fit a ball to the tarsi tip positions during stance. Return the shifted joint
% data for plotting relative to the ball, and the center and radius of the ball 
% for plotting the ball. 
%     
% Required params:
%     'data' - a section of data from a parquet file to fit the ball to. 
%     'param' - param struct from DLC_load_params.m
% 
% Output: 
%     'Center' - [x,y,z] coordinates of the center of the ball
%     'Radius' - the radius of the ball
%     'BallFitData' - all the joint data thrown into positive space for plotting relative to the ball
%     
% Sarah Walling-Bell
% November, 2021
    
    %all joint position data
    columns = data.Properties.VariableNames;
    subData = [columns(contains(columns, '_x')), columns(contains(columns, '_y')),columns(contains(columns, '_z'))];

    %params for ball fitting 
    rMin = 1.0;     % min radius constraint
    rMax = 3.0;     % max radius constraint
    thresh = 0.01;  % percent threshold for 'ground'
    
    the_min = 0; %find min val of all the data for fitting and move all data into a positive space
    for leg = 1:param.numLegs
       %format joint data for ball fit and plotting
       for joint = 1:param.numJoints+1
          dataCols = subData(contains(subData, [param.legs{leg} param.jointLetters{joint}]));
          BallFitData(leg).(param.legNodes{joint}) = [data.(dataCols{1}), data.(dataCols{2}), data.(dataCols{3})];
          the_min = min(min(BallFitData(leg).(param.legNodes{joint})(:)), the_min);   
       end
    end
    %move all data into a positive space
    for leg = 1:param.numLegs
       for joint = 1:param.numJoints+1
          BallFitData(leg).(param.legNodes{joint}) = BallFitData(leg).(param.legNodes{joint}) + abs(the_min);
       end
    end

    %isolate stance regions and quadruple those points in the dataset for best fitting. 
    for leg = 1:param.numLegs
        BallFitData(leg).stance = BallFitData(leg).Ta(diff(BallFitData(leg).Ta(:,2)) <= 0, :);
    end

    all_stance = [BallFitData(1).stance; BallFitData(2).stance; BallFitData(3).stance; BallFitData(4).stance; BallFitData(5).stance; BallFitData(6).stance];
    cloud = [all_stance; all_stance; all_stance]; % triple up on 'good' data points

    % SPHERE FIT
    %RMSE with minimum optimization function: 
    objective = @(XX) sqrt(mean((pdist2([XX(1),XX(2),XX(3)],cloud)-XX(4)).^2,2));
    x0 = [0,0,0,1.3]; % starting guess [center-x,center-y,center-z,radius]
    [A,b,Aeq,beq] = deal([]);   %empty values
    lb = [-inf,-inf,-inf,rMin];  %lower bounds
    ub = [inf,inf, 0, rMax];     %upper bounds
    XX = fmincon(objective,x0,A,b,Aeq,beq,lb,ub);
    Center = [XX(1),XX(2),XX(3)];
    Radius = XX(4);
    disp(['Radius: ' num2str(Radius)])

    % disp number of points that hit the threshold:
    R = Radius*thresh;             % 3-percent threshold
    dist = pdist2(Center, cloud);  % find the euclidian distances
    err = (sum(dist>(Radius-R) & dist<(Radius+R),2)/length(cloud))*100; %percent of points 'on' the sphere
    disp(['Points on ball: ' num2str(err) '%'])



end