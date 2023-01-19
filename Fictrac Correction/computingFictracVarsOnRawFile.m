%% load a raw fictrac file
clear all; close all; clc;
% path = 'G:\My Drive\Tuthill Lab Shared\Evyn\Data\12.18.19\Fly 1_0\FicTrac Data\12182019_fly1_0data_out.dat';
path = 'G:\My Drive\Tuthill Lab Shared\Sarah\Data\FicTrac Raw Data\12.20.21\Fly 1_0\FicTrac Data\12202021_fly1_0data_out.dat';
% path = 'G:\My Drive\Tuthill Lab Shared\Sarah\Data\FicTrac Raw Data\2.4.21\Fly 1_0\FicTrac Data\02042021_fly1_0data_out.dat';
data = readtable(path);

%some params
ball_radius = 9.08/2; %radius in mm 
fps = 30;


% name the fictrac file columns
vars = {'frame_count', 'dr_cam_x', 'dr_cam_y', 'dr_cam_z', 'dr_error', 'dr_lab_x', 'dr_lab_y', 'dr_lab_z', ...
    'sphere_pos_cam_x', 'sphere_pos_cam_y', 'sphere_pos_cam_z', 'sphere_pos_lab_x', 'sphere_pos_lab_y', 'sphere_pos_lab_z', ...
    'int_x', 'int_y', 'heading', 'direction', 'speed', 'int_move_fwd', 'int_move_side', 'timestamp', 'seq_count', 'delta_timestamp', 'alt_timestamp'};

initial_vars = who;
%% plot delta rotation vecotors in cam and lab coordinates. 
x = 1:500;

fig = fullfig; 
subplot(2,1,1); hold on
plot(data{x, strcmpi(vars, 'dr_cam_x')});
plot(data{x, strcmpi(vars, 'dr_cam_y')});
plot(data{x, strcmpi(vars, 'dr_cam_z')});
legend({'dr cam x', 'dr cam y', 'dr cam z'}, 'Location', 'best');
ylabel('Velocity (radians/frame)');
xlabel('Time (frames)');
hold off
subplot(2,1,2); hold on
plot(data{x, strcmpi(vars, 'dr_lab_x')});
plot(data{x, strcmpi(vars, 'dr_lab_y')});
plot(data{x, strcmpi(vars, 'dr_lab_z')});
legend({'dr lab x', 'dr lab y', 'dr lab z'}, 'Location', 'best');
ylabel('Velocity (radians/frame)');
xlabel('Time (frames)');
hold off

clearvars('-except',initial_vars{:}); initial_vars = who;



%% 1)STEP ONE: transform camera to lab coordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% map cam to animal coordinates
x = 1:height(data);

camX = data{x, strcmpi(vars, 'dr_cam_x')};
camY = data{x, strcmpi(vars, 'dr_cam_y')};
camZ = data{x, strcmpi(vars, 'dr_cam_z')};

labX = data{x, strcmpi(vars, 'dr_lab_x')};
labY = data{x, strcmpi(vars, 'dr_lab_y')};
labZ = data{x, strcmpi(vars, 'dr_lab_z')};

%compute linear regression from cam to lab 
[X_coeffs, Y_coeffs, Z_coeffs] = cam2animal(camX, camY, camZ, labX, labY, labZ);

%compute predicted lab delta rotation vectors from linreg
predicted_labX = X_coeffs(1) + camX*X_coeffs(2) + camY*X_coeffs(3) + camZ*X_coeffs(4);
predicted_labY = Y_coeffs(1) + camX*Y_coeffs(2) + camY*Y_coeffs(3) + camZ*Y_coeffs(4);
predicted_labZ = Z_coeffs(1) + camX*Z_coeffs(2) + camY*Z_coeffs(3) + camZ*Z_coeffs(4);

%save predictions & coeffs
initial_vars{end+1} = 'x';
initial_vars{end+1} = 'X_coeffs';
initial_vars{end+1} = 'Y_coeffs';
initial_vars{end+1} = 'Z_coeffs';
initial_vars{end+1} = 'predicted_labX';
initial_vars{end+1} = 'predicted_labY';
initial_vars{end+1} = 'predicted_labZ';

clearvars('-except',initial_vars{:}); initial_vars = who;

%% check coordinate transforms on new data file (good config). 

path2 = 'G:\My Drive\Tuthill Lab Shared\Sarah\Data\FicTrac Raw Data\12.21.21\Fly 2_0\FicTrac Data\12212021_fly2_0data_out.dat';
data2 = readtable(path2);

camX2 = data2{x, strcmpi(vars, 'dr_cam_x')};
camY2 = data2{x, strcmpi(vars, 'dr_cam_y')};
camZ2 = data2{x, strcmpi(vars, 'dr_cam_z')};

labX2 = data2{x, strcmpi(vars, 'dr_lab_x')};
labY2 = data2{x, strcmpi(vars, 'dr_lab_y')};
labZ2 = data2{x, strcmpi(vars, 'dr_lab_z')};


predicted_labX_2 = X_coeffs(1) + camX2*X_coeffs(2) + camY2*X_coeffs(3) + camZ2*X_coeffs(4);
actual_labX = labX2;
errorX = actual_labX - predicted_labX_2;
fig = fullfig; 
plot(errorX);
title('labX error');

predicted_labY_2 = Y_coeffs(1) + camX2*Y_coeffs(2) + camY2*Y_coeffs(3) + camZ2*Y_coeffs(4);
actual_labY = labY2;
errorY = actual_labY - predicted_labY_2;
fig = fullfig; 
plot(errorY);
title('labY error');

predicted_labZ_2 = Z_coeffs(1) + camX2*Z_coeffs(2) + camY2*Z_coeffs(3) + camZ2*Z_coeffs(4);
actual_labZ = labZ2;
errorZ = actual_labZ - predicted_labZ_2;
fig = fullfig; 
plot(errorZ);
title('labZ error');

%save loaded data
initial_vars{end+1} = 'path2';
initial_vars{end+1} = 'data2';
initial_vars{end+1} = 'labX2';
initial_vars{end+1} = 'labY2';
initial_vars{end+1} = 'labZ2';
clearvars('-except',initial_vars{:}); initial_vars = who;
%% predict lab coordinates for an old data file (bad config).

path3 = 'G:\My Drive\Tuthill Lab Shared\Sarah\Data\FicTrac Raw Data\2.4.21\Fly 1_0\FicTrac Data\02042021_fly1_0data_out.dat';
data3 = readtable(path3);

camX3 = data3{:, strcmpi(vars, 'dr_cam_x')};
camY3 = data3{:, strcmpi(vars, 'dr_cam_y')};
camZ3 = data3{:, strcmpi(vars, 'dr_cam_z')};

labX3 = X_coeffs(1) + camX3*X_coeffs(2) + camY3*X_coeffs(3) + camZ3*X_coeffs(4);
labY3 = Y_coeffs(1) + camX3*Y_coeffs(2) + camY3*Y_coeffs(3) + camZ3*Y_coeffs(4);
labZ3 = Z_coeffs(1) + camX3*Z_coeffs(2) + camY3*Z_coeffs(3) + camZ3*Z_coeffs(4);

%plot the cam vs transformed lab coords
x = 1:500;

fig = fullfig; 
subplot(2,1,1); hold on
plot(camX3(x));
plot(camY3(x));
plot(camZ3(x));
legend({'dr cam x', 'dr cam y', 'dr cam z'}, 'Location', 'best');
ylabel('Velocity (radians/frame)');
xlabel('Time (frames)');
hold off
subplot(2,1,2); hold on
plot(labX3(x));
plot(labY3(x));
plot(labZ3(x));
legend({'dr lab x', 'dr lab y', 'dr lab z'}, 'Location', 'best');
ylabel('Velocity (radians/frame)');
xlabel('Time (frames)');
hold off

%save predictions & data
initial_vars{end+1} = 'path3';
initial_vars{end+1} = 'data3';
initial_vars{end+1} = 'labX3';
initial_vars{end+1} = 'labY3';
initial_vars{end+1} = 'labZ3';
clearvars('-except',initial_vars{:}); initial_vars = who;



%% 2)STEP TWO: compute fictrac variables from lab coordiantes 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% compute fictrac variables

x = 1:500; % select a range of data to look at

% %calculate on real velocity data in lab coordinates
% deltaX = data{x, strcmpi(vars, 'dr_lab_x')};
% deltaY = data{x, strcmpi(vars, 'dr_lab_y')};
% deltaZ = data{x, strcmpi(vars, 'dr_lab_z')};
% thisData = data;

%calculate on *PREDICTED* velocity data in lab coordinates
deltaX = predicted_labX(x);
deltaY = predicted_labY(x);
deltaZ = predicted_labZ(x);
thisData = data;

% %calculate on *PREDICTED* velocity data in lab coordinates of data2 (a different new data with good config)
% deltaX = labX2(x);
% deltaY = labY2(x);
% deltaZ = labZ2(x);
% thisData = data2;

% %calculate on *PREDICTED* velocity data in lab coordinates of data3 (the old data with bad config)
% deltaX = labX3(x);
% deltaY = labY3(x);
% deltaZ = labZ3(x);
% thisData = data3;


[speed, direction, fwd, side, intx, inty, heading] = Fictrac_Variables(deltaX, deltaY, deltaZ, ball_radius, fps);


%save fictrac vars 
initial_vars{end+1} = 'speed';
initial_vars{end+1} = 'direction';
initial_vars{end+1} = 'fwd';
initial_vars{end+1} = 'side';
initial_vars{end+1} = 'intx';
initial_vars{end+1} = 'inty';
initial_vars{end+1} = 'heading';
initial_vars{end+1} = 'thisData';

clearvars('-except',initial_vars{:}); initial_vars = who;

%% speed check  

fictrac_speed = thisData{x, strcmpi(vars, 'speed')}';

fig = fullfig; 
subplot(2,1,1); hold on;
plot(fictrac_speed);
plot(speed); 
legend({'fictrac speed', 'my speed'}, 'Location', 'best');
hold off
subplot(2,1,2); hold on
plot(round(minus(fictrac_speed, speed), 4));
legend({'difference btw fictrac speed and my speed'}, 'Location', 'best');
hold off
%% direction check 

fictrac_dir = thisData{x, strcmpi(vars, 'direction')}';

fig = fullfig; 
subplot(2,1,1); hold on;
plot(fictrac_dir);
plot(direction); 
legend({'fictrac direction', 'my direction'}, 'Location', 'best');
hold off
subplot(2,1,2); hold on
plot(round(minus(fictrac_dir, direction), 4));
legend({'difference btw fictrac direction and my direction'}, 'Location', 'best');
hold off
%% Integrated Position fwd check

fictrac_fwd = thisData{x, strcmpi(vars, 'int_move_fwd')}';

fig = fullfig; 
subplot(2,1,1); hold on;
plot(fictrac_fwd);
plot(fwd);
legend({'fictrac fwd',  'my fwd'}, 'Location', 'best');
hold off
subplot(2,1,2); hold on
plot(round(minus(fictrac_fwd, fwd), 4));
legend({'difference btw fictrac fwd and my fwd'}, 'Location', 'best');
hold off
%% Integrated Position side check 

fictrac_side = thisData{x, strcmpi(vars, 'int_move_side')}';

fig = fullfig; 
subplot(2,1,1); hold on;
plot(fictrac_side);
plot(side);
legend({'fictrac side',  'my side'}, 'Location', 'best');
hold off
subplot(2,1,2); hold on
plot(round(minus(fictrac_side, side), 4));
legend({'difference btw fictrac side and my side'}, 'Location', 'best');
hold off
%% heading check 

fictrac_heading = thisData{x, strcmpi(vars, 'heading')}';

fig = fullfig; 
subplot(2,1,1); hold on;
plot(fictrac_heading);
plot(heading);
legend({'fictrac heading',  'my heading'}, 'Location', 'best');
hold off
subplot(2,1,2); hold on
plot(round(minus(fictrac_heading, heading), 4));
legend({'difference btw fictrac heading and my heading'}, 'Location', 'best');
hold off
%% 2D fictive path check intx

fictrac_intx = thisData{x, strcmpi(vars, 'int_x')}';

fig = fullfig; 
subplot(2,1,1); hold on;
plot(fictrac_intx);
plot(intx);
legend({'fictrac intx',  'my intx'}, 'Location', 'best');
hold off
subplot(2,1,2); hold on
plot(round(minus(fictrac_intx, intx), 4));
legend({'difference btw fictrac intx and my intx'}, 'Location', 'best');
hold off
%% 2D fictive path check inty

fictrac_inty = thisData{x, strcmpi(vars, 'int_y')}';

fig = fullfig; 
subplot(2,1,1); hold on;
plot(fictrac_inty);
plot(inty); 
legend({'fictrac inty',  'my inty'}, 'Location', 'best');
hold off
subplot(2,1,2); hold on
plot(round(minus(fictrac_inty, inty), 4));
legend({'difference btw fictrac inty and my inty'}, 'Location', 'best');
hold off
%% 2D fictive path check 2D path

fictrac_intx = thisData{x, strcmpi(vars, 'int_x')}';
fictrac_inty = thisData{x, strcmpi(vars, 'int_y')}';

fig = fullfig;
plot(fictrac_intx, fictrac_inty); hold on 
plot(intx, inty); 
legend({'fictrac intx/y',  'my intx/y'}, 'Location', 'best');
hold off



%% %%%%%%%%%%% Testing %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Q1) Are the coefficients of the linreg the same when generated different data? YES!

% Loop through a bunch of fictrac files from my new (good config) data.
% Save and plot the x,y,z coefficents. 

paths = {'G:\My Drive\Tuthill Lab Shared\Sarah\Data\FicTrac Raw Data\12.20.21\Fly 1_0\FicTrac Data\12202021_fly1_0data_out.dat', ...
         'G:\My Drive\Tuthill Lab Shared\Sarah\Data\FicTrac Raw Data\12.21.21\Fly 2_0\FicTrac Data\12212021_fly2_0data_out.dat', ...
         'G:\My Drive\Tuthill Lab Shared\Sarah\Data\FicTrac Raw Data\1.11.22\Fly 1_0\FicTrac Data\01112022_fly1_0data_out.dat', ...
         'G:\My Drive\Tuthill Lab Shared\Sarah\Data\FicTrac Raw Data\1.11.22\Fly 2_0\FicTrac Data\01112022_fly2_0data_out.dat', ...
         'G:\My Drive\Tuthill Lab Shared\Sarah\Data\FicTrac Raw Data\1.11.22\Fly 2_1\FicTrac Data\01112022_fly2_1data_out.dat', ...
         'G:\My Drive\Tuthill Lab Shared\Sarah\Data\FicTrac Raw Data\1.12.22\Fly 1_0\FicTrac Data\01122022_fly1_0data_out.dat', ...
         'G:\My Drive\Tuthill Lab Shared\Sarah\Data\FicTrac Raw Data\1.12.22\Fly 1_1\FicTrac Data\01122022_fly1_1data_out.dat', ...
         };
     
% name the fictrac file columns
vars = {'frame_count', 'dr_cam_x', 'dr_cam_y', 'dr_cam_z', 'dr_error', 'dr_lab_x', 'dr_lab_y', 'dr_lab_z', ...
    'sphere_pos_cam_x', 'sphere_pos_cam_y', 'sphere_pos_cam_z', 'sphere_pos_lab_x', 'sphere_pos_lab_y', 'sphere_pos_lab_z', ...
    'int_x', 'int_y', 'heading', 'direction', 'speed', 'int_move_fwd', 'int_move_side', 'timestamp', 'seq_count', 'delta_timestamp', 'alt_timestamp'};

% coeffs = zeros(width(paths), 3);
coeffNames = {'x_intercept', 'x_coeff_b1', 'x_coeff_b2', 'x_coeff_b3', 'y_intercept', 'y_coeff_b1', 'y_coeff_b2', 'y_coeff_b3', 'z_intercept', 'z_coeff_b1', 'z_coeff_b2', 'z_coeff_b3'};
coeffs = array2table(zeros(0,12), 'VariableNames', coeffNames);

for p = 1:width(paths)
    d = readtable(paths{p});
   
    camX = d{:, strcmpi(vars, 'dr_cam_x')};
    camY = d{:, strcmpi(vars, 'dr_cam_y')};
    camZ = d{:, strcmpi(vars, 'dr_cam_z')};

    labX = d{:, strcmpi(vars, 'dr_lab_x')};
    labY = d{:, strcmpi(vars, 'dr_lab_y')};
    labZ = d{:, strcmpi(vars, 'dr_lab_z')};

    %compute linear regression from cam to lab 
    [X_coeffs, Y_coeffs, Z_coeffs] = cam2animal(camX, camY, camZ, labX, labY, labZ);
    
    %save coeffs 
    new_coeffs = {X_coeffs(1), X_coeffs(2), X_coeffs(3), X_coeffs(4), Y_coeffs(1), Y_coeffs(2), Y_coeffs(3), Y_coeffs(4), Z_coeffs(1), Z_coeffs(2), Z_coeffs(3), Z_coeffs(4)};
    coeffs = [coeffs; new_coeffs];
end


%plot all the coeffs
fig = fullfig; hold on
for i = 1:height(coeffs)
   for j = 1:width(coeffs)
      scatter(j, coeffs{i,j});
   end
end
hold off
xticks(1:j);
xticklabels(strrep(coeffNames, '_', ' '));

%% Q2) How do the lab coords and new vars look in a new video... as expected qualitatively?

pq = 'G:\My Drive\Tuthill Lab Shared\Pierre\summaries\v3-b3\days\all_8.27.21.parquet';
sumdata = parquetread(pq); 

%get delta rotations in cam coords
camX = sumdata.fictrac_delta_rot_cam_x;
camY = sumdata.fictrac_delta_rot_cam_y;
camZ = sumdata.fictrac_delta_rot_cam_z;

%predict delta rotations in lab coords
predicted_labX = X_coeffs(1) + camX*X_coeffs(2) + camY*X_coeffs(3) + camZ*X_coeffs(4);
predicted_labY = Y_coeffs(1) + camX*Y_coeffs(2) + camY*Y_coeffs(3) + camZ*Y_coeffs(4);
predicted_labZ = Z_coeffs(1) + camX*Z_coeffs(2) + camY*Z_coeffs(3) + camZ*Z_coeffs(4);

%compute other fictrac variables
deltaX = predicted_labX;
deltaY = predicted_labY;
deltaZ = predicted_labZ;
thisData = sumdata;

[speed, direction, fwd, side, intx, inty, heading] = Fictrac_Variables(deltaX, deltaY, deltaZ);

%select a video to look at 
fly = '1_0';
rep = 1;
cond = 6;
idxs = find(strcmpi(sumdata.fly, fly) & sumdata.rep == rep & sumdata.condnum == cond);

ball_radius = 9.08/2; %radius in mm 
fps = 30;

%plot delta rotation vectors and speed
fig = fullfig; hold on
plot(predicted_labX(idxs) * ball_radius * fps);
plot(predicted_labY(idxs) * ball_radius * fps);
plot(predicted_labZ(idxs) * ball_radius * fps);
plot(speed(idxs) * ball_radius * fps); 
legend({'dr x lab',  'dr y lab',  'dr z lab', 'speed'}, 'Location', 'best');
ylabel('Velocity (mm/s)');
xlabel('Time (frames)');
hold off

%plot headinga and direction 
fig = fullfig; hold on
plot(rad2deg(direction(idxs)));
plot(rad2deg(heading(idxs)));
legend({'direction',  'heading'}, 'Location', 'best');
ylabel('Angle (degrees)');
xlabel('Time (frames)');
hold off

%plot 2d fictive path 
%(note that fictrac gives the view from below. invert the x axis to get a vew from above, aka with correct turning direction from above)
fig = fullfig; hold on
colors = parula(height(idxs));
for pt = 1:height(idxs)-1
    plot(intx(idxs(pt:pt+1)) * ball_radius * -1, inty(idxs(pt:pt+1)) * ball_radius, 'color', colors(pt, :));
end
legend({'2D fictive path'}, 'Location', 'best');
ylabel('Position (mm)');
xlabel('Position (mm)');
hold off



