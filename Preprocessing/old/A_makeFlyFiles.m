% Make files that list the flies that should be in each dataset

% Load fly summary sarah
flySummary = readtable('G:\.shortcut-targets-by-id\15uXSKut68NlHyR8OywpWbt0zXFWyC-43\Sarah\Data\FicTrac Raw Data\Fly_Summary_Sarah_New.xlsx');
datasetSummaryPath = 'G:\.shortcut-targets-by-id\15uXSKut68NlHyR8OywpWbt0zXFWyC-43\Sarah\Data\Datasets\datasetSummary.xlsx'; 
datasetSummary = readtable(datasetSummaryPath); %has list of which flyFiles have been made

%%  Select the flies for a dataset

% fileName = 'iav_act_intact_onball';
% idxs = contains(flySummary.StimulusProcedure, 'iav_activation') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'iav_act_intact_offball';
% idxs = contains(flySummary.StimulusProcedure, 'iav_activation') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'offball');
% flyData = flySummary(idxs, :);

% fileName = 'iav_act_headless_onball';
% idxs = contains(flySummary.StimulusProcedure, 'iav_activation') & ...
%        contains(flySummary.Head, 'headless') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'iav_act_headless_offball';
% idxs = contains(flySummary.StimulusProcedure, 'iav_activation') & ...
%        contains(flySummary.Head, 'headless') & ...
%        contains(flySummary.Ball, 'offball');
% flyData = flySummary(idxs, :);

% fileName = 'iav_sil_intact_onball';
% idxs = contains(flySummary.StimulusProcedure, 'iav_silencing') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'iav_sil_intact_offball';
% idxs = contains(flySummary.StimulusProcedure, 'iav_silencing') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'offball');
% flyData = flySummary(idxs, :);

% fileName = 'iav_sil_headless_onball';
% idxs = contains(flySummary.StimulusProcedure, 'iav_silencing') & ...
%        contains(flySummary.Head, 'headless') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'iav_sil_headless_offball';
% idxs = contains(flySummary.StimulusProcedure, 'iav_silencing') & ...
%        contains(flySummary.Head, 'headless') & ...
%        contains(flySummary.Ball, 'offball');
% flyData = flySummary(idxs, :);


% fileName = 'sh_control_sil_intact_onball_pwr';
% idxs = contains(flySummary.StimulusProcedure, 'control_silencing_laser_power') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

%% MANUALLY CHECK THAT FLYDATA CONTAINS THE CORRECT DATA!!!!

%%  save flyData
savepath = 'G:\.shortcut-targets-by-id\15uXSKut68NlHyR8OywpWbt0zXFWyC-43\Sarah\Data\Datasets\flyFiles\'; 
writetable(flyData, [savepath fileName '.xlsx']);
% record flyFile making in datasetSummary 
datasetIdx = strcmp(datasetSummary.dataset, fileName);
datasetSummary.flyFileMade{datasetIdx} = date; %today's date  (date of flyFile creation)
writetable(datasetSummary, datasetSummaryPath); %save updated table


%%

% fileName = 'claw_flex_sil_intact_onball_pwr';
% idxs = contains(flySummary.StimulusProcedure, 'claw_flex_silencing_laser_power') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'claw_ext_sil_intact_onball_pwr';
% idxs = contains(flySummary.StimulusProcedure, 'claw_ext_silencing_laser_power') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'hook_flex_sil_intact_onball_pwr';
% idxs = contains(flySummary.StimulusProcedure, 'hook_flex_silencing_laser_power') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'hook_ext_sil_intact_onball_pwr';
% idxs = contains(flySummary.StimulusProcedure, 'hook_ext_silencing_laser_power') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'club_JR175_sil_intact_onball_pwr';
% idxs = contains(flySummary.StimulusProcedure, 'club_silencing_laser_power') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'club_JR299_sil_intact_onball_pwr';
% idxs = contains(flySummary.StimulusProcedure, 'club_silencing_laser_power') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'sh_control_sil_intact_onball_pwr';
% idxs = contains(flySummary.StimulusProcedure, 'control_silencing_laser_power') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'iav_sil_intact_onball_pwr';
% idxs = contains(flySummary.StimulusProcedure, 'iav_silencing_laser_power') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'club_JR299_act_intact_onball';
% idxs = contains(flySummary.StimulusProcedure, 'club_activation') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'onball') & ...
%        contains(flySummary.FlyLine, 'JR299');
% flyData = flySummary(idxs, :);

% fileName = 'club_JR299_act_intact_offball';
% idxs = contains(flySummary.StimulusProcedure, 'club_activation') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'offball') & ...
%        contains(flySummary.FlyLine, 'JR299');
% flyData = flySummary(idxs, :);

% fileName = 'club_JR299_act_headless_onball';
% idxs = contains(flySummary.StimulusProcedure, 'club_activation') & ...
%        contains(flySummary.Head, 'headless') & ...
%        contains(flySummary.Ball, 'onball') & ...
%        contains(flySummary.FlyLine, 'JR299');
% flyData = flySummary(idxs, :);

% fileName = 'club_JR299_act_headless_offball';
% idxs = contains(flySummary.StimulusProcedure, 'club_activation') & ...
%        contains(flySummary.Head, 'headless') & ...
%        contains(flySummary.Ball, 'offball') & ...
%        contains(flySummary.FlyLine, 'JR299');
% flyData = flySummary(idxs, :);

% fileName = 'club_JR299_sil_intact_onball';
% idxs = contains(flySummary.StimulusProcedure, 'club_silencing') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'onball') & ...
%        contains(flySummary.FlyLine, 'JR299');
% flyData = flySummary(idxs, :);

% fileName = 'club_JR299_sil_intact_offball';
% idxs = contains(flySummary.StimulusProcedure, 'club_silencing') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'offball') & ...
%        contains(flySummary.FlyLine, 'JR299');
% flyData = flySummary(idxs, :);

% fileName = 'club_JR299_sil_headless_onball';
% idxs = contains(flySummary.StimulusProcedure, 'club_silencing') & ...
%        contains(flySummary.Head, 'headless') & ...
%        contains(flySummary.Ball, 'onball') & ...
%        contains(flySummary.FlyLine, 'JR299');
% flyData = flySummary(idxs, :);

% fileName = 'club_JR299_sil_headless_offball';
% idxs = contains(flySummary.StimulusProcedure, 'club_silencing') & ...
%        contains(flySummary.Head, 'headless') & ...
%        contains(flySummary.Ball, 'offball') & ...
%        contains(flySummary.FlyLine, 'JR299');
% flyData = flySummary(idxs, :);

% fileName = 'hook_flex_act_intact_onball';
% idxs = contains(flySummary.StimulusProcedure, 'hook_flex_activation') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'hook_flex_act_intact_offball';
% idxs = contains(flySummary.StimulusProcedure, 'hook_flex_activation') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'offball');
% flyData = flySummary(idxs, :);

% fileName = 'hook_flex_act_headless_onball';
% idxs = contains(flySummary.StimulusProcedure, 'hook_flex_activation') & ...
%        contains(flySummary.Head, 'headless') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'hook_flex_act_headless_offball';
% idxs = contains(flySummary.StimulusProcedure, 'hook_flex_activation') & ...
%        contains(flySummary.Head, 'headless') & ...
%        contains(flySummary.Ball, 'offball');
% flyData = flySummary(idxs, :);

% fileName = 'hook_flex_sil_intact_onball';
% idxs = contains(flySummary.StimulusProcedure, 'hook_flex_silencing') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'hook_flex_sil_intact_offball';
% idxs = contains(flySummary.StimulusProcedure, 'hook_flex_silencing') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'offball');
% flyData = flySummary(idxs, :);

% fileName = 'hook_flex_sil_headless_onball';
% idxs = contains(flySummary.StimulusProcedure, 'hook_flex_silencing') & ...
%        contains(flySummary.Head, 'headless') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'hook_flex_sil_headless_offball';
% idxs = contains(flySummary.StimulusProcedure, 'hook_flex_silencing') & ...
%        contains(flySummary.Head, 'headless') & ...
%        contains(flySummary.Ball, 'offball');
% flyData = flySummary(idxs, :);

% fileName = 'sh_control_all_intact_onball';
% idxs = contains(flySummary.StimulusProcedure, 'control') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'sh_control_act_intact_onball';
% idxs = contains(flySummary.StimulusProcedure, 'control_activation') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'sh_control_act_intact_offball';
% idxs = contains(flySummary.StimulusProcedure, 'control_activation') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'offball');
% flyData = flySummary(idxs, :);

% fileName = 'sh_control_act_headless_onball';
% idxs = contains(flySummary.StimulusProcedure, 'control_activation') & ...
%        contains(flySummary.Head, 'headless') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'sh_control_act_headless_offball';
% idxs = contains(flySummary.StimulusProcedure, 'control_activation') & ...
%        contains(flySummary.Head, 'headless') & ...
%        contains(flySummary.Ball, 'offball');
% flyData = flySummary(idxs, :);

% fileName = 'sh_control_sil_intact_onball';
% idxs = contains(flySummary.StimulusProcedure, 'control_silencing') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'sh_control_sil_intact_offball';
% idxs = contains(flySummary.StimulusProcedure, 'control_silencing') & ...
%        contains(flySummary.Head, 'intact') & ...
%        contains(flySummary.Ball, 'offball');
% flyData = flySummary(idxs, :);

% fileName = 'sh_control_sil_headless_onball';
% idxs = contains(flySummary.StimulusProcedure, 'control_silencing') & ...
%        contains(flySummary.Head, 'headless') & ...
%        contains(flySummary.Ball, 'onball');
% flyData = flySummary(idxs, :);

% fileName = 'sh_control_sil_headless_offball';
% idxs = contains(flySummary.StimulusProcedure, 'control_silencing') & ...
%        contains(flySummary.Head, 'headless') & ...
%        contains(flySummary.Ball, 'offball');
% flyData = flySummary(idxs, :);