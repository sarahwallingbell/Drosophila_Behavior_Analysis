%% load a raw fictrac file that had incorrect fictrac configuration 

path = 'G:\My Drive\Tuthill Lab Shared\Sarah\Data\FicTrac Raw Data\2.4.21\Fly 1_0\FicTrac Data\02042021_fly1_0data_out.dat';
data = readtable(path);

% name the fictrac file columns
vars = {'frame_count', 'dr_cam_x', 'dr_cam_y', 'dr_cam_z', 'dr_error', 'dr_lab_x', 'dr_lab_y', 'dr_lab_z', ...
    'sphere_pos_cam_x', 'sphere_pos_cam_y', 'sphere_pos_cam_z', 'sphere_pos_lab_x', 'sphere_pos_lab_y', 'sphere_pos_lab_z', ...
    'int_x', 'int_y', 'heading', 'direction', 'speed', 'int_move_fwd', 'int_move_side', 'timestamp', 'seq_count', 'delta_timestamp', 'alt_timestamp'};

%some params
ball_radius = 9.08/2; %radius in mm 
fps = 30;

%% fix fictrac data

%get delta rotations in cam coords
camX = data{:, strcmpi(vars, 'dr_cam_x')}; %fictrac_delta_rot_cam_x
camY = data{:, strcmpi(vars, 'dr_cam_y')}; %fictrac_delta_rot_cam_y
camZ = data{:, strcmpi(vars, 'dr_cam_z')}; %fictrac_delta_rot_cam_z

%here are the coefficients from the linear regression for predicting each of the 3 variables:
%(random aside: it's cool that these coeffs mostly just swap the y and z axes and invert the y axis data like we did as a proxy!)
X_coeffs = [1.55417630179922e-19;0.998639999999997;0.0174592000000008;0.0491229999999999]; %for predicting fictrac_delta_rot_lab_x
Y_coeffs = [-2.54561126765530e-17;0.0491875999999992;-0.00328832000000049;-0.998784000000000]; %for predicting fictrac_delta_rot_lab_y
Z_coeffs = [6.79693102653525e-17;-0.0172764000000011;0.999841999999992;-0.00414261999999977]; %for predicting fictrac_delta_rot_lab_z

%predict delta rotations in lab coords
predicted_labX = X_coeffs(1) + camX*X_coeffs(2) + camY*X_coeffs(3) + camZ*X_coeffs(4); %fictrac_delta_rot_lab_x
predicted_labY = Y_coeffs(1) + camX*Y_coeffs(2) + camY*Y_coeffs(3) + camZ*Y_coeffs(4); %fictrac_delta_rot_lab_y
predicted_labZ = Z_coeffs(1) + camX*Z_coeffs(2) + camY*Z_coeffs(3) + camZ*Z_coeffs(4); %fictrac_delta_rot_lab_z

%compute other fictrac variables
[speed, direction, fwd, side, intx, inty, heading] = Fictrac_Variables(predicted_labX, predicted_labY, predicted_labZ, ball_radius, fps);

%convert variable units to milimeters, seconds, and degrees
[speed, direction, fwd, side, intx, inty, heading] = convert_fictrac_units(speed, direction, fwd, side, intx, inty, heading, ball_radius, fps);


