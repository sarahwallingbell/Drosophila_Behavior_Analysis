function [speed, direction, fwd, side, intx, inty, heading] = Fictrac_Variables(deltaX, deltaY, deltaZ)
% 
% Given delta rotation vectors in lab (animal) coordinates, compute the remaining FicTrac variables. 
% This should be used on correct lab coordiante delta rotation data. Aka, for old (bad) fictrac data,
%     this function should be called after converting camera coordinates to lab coordinates. 
% 
% Params:
%     deltaX = fictrac_delta_rot_lab_x 
%     deltaY = fictrac_delta_rot_lab_y
%     deltaZ = fictrac_delta_rot_lab_z
%     ball_radious = radius of the ball (4.54 mm)
%     fps = fictrac fps (30)
% 
% Returns:
%     heading = Fictrac output column 17
%     direction = Fictrac output column 18
%     speed = Fictrac output column 19
%     fwd = Fictrac output column 15
%     side = Fictrac output column 16
%     intx = Fictrac output column 20
%     inty = Fictrac output column 21
% 
% Sarah Walling-Bell, December 2021/January 2022

if height(deltaX) ~= height(deltaY) | height(deltaX) ~= height(deltaZ)
    error('delta vectors must be the same length')
end


head = cumtrapz(deltaZ*-1); %for calculating 2D path, integral function is more precise than manual integration

for i = 1:height(deltaX)
    
    velX = deltaY(i); %(-ve rotation around x-axis causes y-axis translation & vice-versa!!)
    velY = -deltaX(i);
    
    %speed
    speed(i) = sqrt(velX * velX + velY * velY);  % magnitude (radians) of ball rotation excluding turning (change in heading)
    
    %direction
    direction(i) = atan2(velY, velX);
    if (direction(i) < 0); direction(i) = direction(i) + deg2rad(360); end
    
    %integrated x/y position (optical mouse style) -- aka no heading angle 
    if i == 1
        fwd(i) = 0;
        side(i) = 0;
    else
        fwd(i) = fwd(i-1) + velX; %x is forward
        side(i) = side(i-1) + velY; %y is side
    end
      
    %heading
    if i == 1
        heading(i) = 0;
    else
        heading(i) = heading(i-1) - deltaZ(i);
        while (heading(i) < 0); heading(i) = heading(i) + deg2rad(360); end  
        while (heading(i) >= deg2rad(360)); heading(i) = heading(i) - deg2rad(360); end

    end

    %intx and inty positions with heading angle 
    if i == 1
        intx(i) = 0; 
        inty(i) = 0;
    else
        %rotate these x and y components by change in direction 
        alpha = head(i); %use integral function instead of manual integral for higher precision 
        R = [cos(alpha) -sin(alpha);
             sin(alpha)  cos(alpha)];
        new_xy =  R * [velX; velY];

        %add new x and y displacement to previous location 
        intx(i) = intx(i-1) + new_xy(1);
        inty(i) = inty(i-1) + new_xy(2);
    end
    

end

end