function [X_coeffs, Y_coeffs, Z_coeffs] = cam2animal(camX, camY, camZ, labX, labY, labZ)

% Fit three linear regressions, each from all three camera coords to one of the animal coords. 
% Input: 
%     camX = delta rotation X vector in camera coords (fictrac_delta_rot_cam_x)
%     camY = delta rotation Y vector in camera coords (fictrac_delta_rot_cam_y)
%     camZ = delta rotation Z vector in camera coords (fictrac_delta_rot_cam_z)
%     labX = delta rotation X vector in animal coords (fictrac_delta_rot_lab_x)
%     labY = delta rotation Y vector in animal coords (fictrac_delta_rot_lab_y)
%     labZ = delta rotation Z vector in animal coords (fictrac_delta_rot_lab_z)
% Output: estimated delta rotation vectors in animal coords
% 
% Sarah Walling-Bell, January 2022

%select 20% of the data as a test set, never to be trained on 
c1 = cvpartition(height(camX),'Holdout',0.2);
test = find(c1.test); %idxs of test set in data
training = find(c1.training);

%train a model on the training data 
X = table(camX(training), camY(training), camZ(training), labX(training), 'VariableNames',{'camX', 'camY', 'camZ', 'labX'});
Y = table(camX(training), camY(training), camZ(training), labY(training), 'VariableNames',{'camX', 'camY', 'camZ', 'labY'});
Z = table(camX(training), camY(training), camZ(training), labZ(training), 'VariableNames',{'camX', 'camY', 'camZ', 'labZ'});

mdlX = fitlm(X); % returns a linear regression model fit to variables in the table or dataset array tbl. By default, fitlm takes the last variable as the response variable.
mdlY = fitlm(Y);
mdlZ = fitlm(Z);
% plot(mdlX);
% plot(mdlY);
% plot(mdlZ);


%check the model on the test data
X_coeffs = mdlX.Coefficients.Estimate;
predicted_labX = X_coeffs(1) + camX(test)*X_coeffs(2) + camY(test)*X_coeffs(3) + camZ(test)*X_coeffs(4);
actual_labX = labX(test);
errorX = actual_labX - predicted_labX;
% fig = fullfig; 
% plot(errorX);
% title('labX error');

Y_coeffs = mdlY.Coefficients.Estimate;
predicted_labY = Y_coeffs(1) + camX(test)*Y_coeffs(2) + camY(test)*Y_coeffs(3) + camZ(test)*Y_coeffs(4);
actual_labY = labY(test);
errorY = actual_labY - predicted_labY;
% fig = fullfig; 
% plot(errorY);
% title('labY error');

Z_coeffs = mdlZ.Coefficients.Estimate;
predicted_labZ = Z_coeffs(1) + camX(test)*Z_coeffs(2) + camY(test)*Z_coeffs(3) + camZ(test)*Z_coeffs(4);
actual_labZ = labZ(test);
errorZ = actual_labZ - predicted_labZ;
% fig = fullfig; 
% plot(errorZ);
% title('labZ error');





end