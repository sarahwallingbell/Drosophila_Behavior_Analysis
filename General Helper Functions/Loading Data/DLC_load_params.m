function param = DLC_load_params(data, version, dataset, flyList)
warning('off','MATLAB:table:RowsAddedExistingVars')

param.version = version;

%paths
param.googledriveroot = 'G:\.shortcut-targets-by-id\0B-MI5yeL50V0S0FvdncyaFJfSTg\Tuthill Lab Shared\Sarah\Data\Analysis\'; % type '\' name '\'];

param.metadatapath = ['G:\My Drive\Analysis\' dataset '\'];
% param.metadatapath = ['G:\.shortcut-targets-by-id\15uXSKut68NlHyR8OywpWbt0zXFWyC-43\Sarah\Data\Metadata\' dataset '\'];
param.googledrivesave = [param.metadatapath 'figs\']; 

% Get param.googledrivesave when doing analysis!
% % param.googledrivesave = uigetdir(param.googledriveroot, 'Where to save figs');
% % param.googledrivesave = [param.googledrivesave '\' param.version '\'];
if not(isfolder(param.googledrivesave))
    mkdir(param.googledrivesave)
end

%save flyList
% flyList.Properties.VariableNames = {'Date', 'Fly'};
writetable(flyList, [param.metadatapath 'flyList.csv']);
param.flyList = flyList;
param.numFlies = height(flyList);

%figs
param.fileType = '-pdf'; %'-png'; % 'svg';
param.darkFig = true;
if param.darkFig; param.baseColor = 'white'; param.backgroundColor = 'black';
else; param.baseColor = 'black'; param.backgroundColor = 'white'; end
param.baseFillWeight = 0.2; %fill weight for SEM area
param.expColor = 'LightSeaGreen';
% pcolormap = parula; pinterval = floor(length(pcolormap)/param.numFlies);
param.flyColors = parula(param.numFlies);
% for f = 1:param.numFlies; param.flyColors{f} = pcolormap(f*pinterval,:); end
% param.flyColors = {'PaleTurquoise','Aquamarine','Turquoise','MediumTurquoise','DarkTurquoise','CadetBlue','LightCyan'}; 
param.jointColors = {'DarkMagenta','DodgerBlue','LightSeaGreen','DarkSeaGreen'}; %BC, CF, FTi, TiTa
param.jointFillWeights = {0.3, 0.2, 0.2, 0.2}; %fill weight for shaded SEM area 
param.titlePosition = [0.5 1.04 0.5];
param.titleFontSize = 18;
param.xlimit = false;
param.xlim = [-0.05, 0.05];
param.ylimit = false;
param.ylim = [0, 180]; 
param.sameAxes = true; %make subplots in a figure all have same axes 

%filtering
param.filter = false; 
param.filterThresh = 1; %degrees 

%exp type
% param.headless = contains(param.googledrivesave, 'Headless');
% param.offball = contains(param.googledrivesave, 'Offball');
% param.activate = contains(param.googledrivesave, 'Activation');
% param.silence = contains(param.googledrivesave, 'Silencing');
param.headless = contains(dataset, 'headless');
param.offball = contains(dataset, 'offball');
param.activate = contains(dataset, 'activation');
param.silence = contains(dataset, 'silencing');

%vid timing
param.fps = 300;
param.basler_delay = 0.5;
param.laser_on = param.basler_delay*param.fps;
param.basler_length = 2;
param.vid_len_s = param.basler_length;
param.vid_len_f = param.vid_len_s * param.fps;
x = -(param.basler_delay):1/param.fps:param.basler_length-(param.basler_delay);
param.x = x(1:(end-1)); 

%laser
param.lasers = {0, 0.03, 0.1, 0.33, 1.0};
param.allLasers = [0, 0.03, 0.1, 0.33, 1.0, 0, 0.03, 0.1, 0.33, 1.0, 0, 0.03, 0.1, 0.33, 1.0, 0, 0.03, 0.1, 0.33, 1.0];
param.laserIdx = [1,2,3,4,5,1,2,3,4,5,1,2,3,4,5,1,2,3,4,5];
param.numLasers = width(param.lasers);
if param.activate; param.laserColor = 'red'; param.laserColorBright = 'Crimson'; end
if param.silence; param.laserColor = 'green'; param.laserColorBright = 'Lime'; end

%ball 
param.sarah_ball_d = 9.08; % 8.99; %diameter in mm
param.sarah_ball_r = param.sarah_ball_d/2; %4.495; %radius in mm 
param.evyn_ball_d = 9.56; % diameter in mm
param.evyn_ball_r = 4.78; %radius in mm

%fictrac
param.fictrac_fps = 30; 

%legs
param.legs = {'L1', 'L2', 'L3', 'R1', 'R2', 'R3'};
param.numLegs = width(param.legs);
param.leg_colors = {'blue', 'orange', 'green', 'red', 'purple', 'brown'}; %each leg has its own color


%joints
param.joints = {'BC', 'CF', 'FTi', 'TiTa'};
param.jointLetters = {'A', 'B', 'C', 'D', 'E'};
param.legNodes = {'BC', 'CF', 'FTi', 'TiTa', 'Ta'};
param.numJoints = width(param.joints);

%phase 
param.phaseStep = 65; %num steps from -pi to pi so that each value is unique to the tenths place  
param.maxPolarDot = 60; %size of largest dot in polar scatter plot


%behavior
param.behaviorColumns = find(contains(data.Properties.VariableNames, '_number')); %column number of behaviors in data
param.behaviorNames = data.Properties.VariableNames(param.behaviorColumns); %names of behavior_bout_number columns in data 
param.behaviorLabels = strrep(strrep(param.behaviorNames, '_bout_number', ''), '_', ' '); %names of behavior (without bout_number) for labelling plots
for b = 1:width(param.behaviorLabels)
    %colors corresponding with the behaviors so each behavior always has it's own color
    param.behaviorColors(b,:) = hsv2rgb(b/width(param.behaviorLabels), 0.7, 0.7);
end

end