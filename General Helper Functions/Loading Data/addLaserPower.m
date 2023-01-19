function data = addLaserPower(data)

%for laser power experiments, different combos of duty cycle and laser
%intensity create different laser powers. So add here a column for easily
%knowing which video has which laser power. 

% add pwr column to data
vidName = data.fullfile;
splitName = split(vidName, ' - ');
splitPwr = split(splitName(:,2), ' ');
data.laserPower = str2double(splitPwr(:,2));


end