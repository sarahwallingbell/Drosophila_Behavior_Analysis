function [speed, direction, fwd, side, intx, inty, heading, dr_lab_x, dr_lab_y, dr_lab_z] = convert_fictrac_units(speed, direction, fwd, side, intx, inty, heading, dr_lab_x, dr_lab_y, dr_lab_z, ball_radius, fps)

% Params: 
%     Output from Fictrac_Variables.m 
%     ball_radious = radius of the ball (4.54 mm)
%     fps = fictrac fps (30)
% 
% Returns:
%      Output from Fictrac_Variables.m with units in mm, sec, and degrees
%
% Sarah Walling-Bell, January 2022



%convert variable units to milimeters, seconds, and degrees

%note: fictrac doesn't do this, but we want to have the fictrac data in
%these units anyways, so this should be run on all of the data (even the
%new data I am collecting)

dr_lab_x = dr_lab_x * ball_radius * fps; %from rad/frame to mm/s
dr_lab_y = dr_lab_y * ball_radius * fps; %from rad/frame to mm/s
dr_lab_z = dr_lab_z * ball_radius * fps; %from rad/frame to mm/s

speed = speed * ball_radius * fps; %from rad/frame to mm/s
direction = rad2deg(direction); %from radians to degrees
heading = rad2deg(heading); %from radians to degrees
fwd = fwd * ball_radius; %from radians to mm
side = side * ball_radius; %from radians to mm
intx = intx * ball_radius; %from radians to mm
inty = inty * ball_radius; %from radians to mm



end