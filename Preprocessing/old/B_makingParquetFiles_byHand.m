% Preprocessing A: Make parquet summary files for specific datasets.
% 
% Load in pk file(s) and delete/combine fly data to generate one parquet file 
% with all flies in a specific dataset.  
% 
% Sarah Walling-Bell, October 2022

clear all; close all; clc;

%% Load in a pk file(s)

% Select and load parquet file(s)
[FilePathsOne, versionOne] = DLC_select_parquet(); 
dataOne = [];
for file = 1:width(FilePathsOne)
     dataOne = [dataOne; parquetread(FilePathsOne{file})]; %read in all the data. 
end


%% check which flies it contains
flies = unique(data.flyid);


%% remove flies
flies2keep =  [1,2,3,4,5];  %indices in 'flies'

newData = oldData(contains(data.flyid, flies(flies2keep)), :); %update data names as necessary

%% load another pk file
[FilePathsTwo, versionTwo] = DLC_select_parquet(); 
dataTwo = [];
for file = 1:width(FilePaths)
     dataTwo = [dataTwo; parquetread(FilePathsTwo{file})]; %read in all the data. 
end

%% combine parquet files
data = [dataOne; dataTwo]; 

%% save parquet files

path = 'G:\.shortcut-targets-by-id\15uXSKut68NlHyR8OywpWbt0zXFWyC-43\Sarah\Data\Datasets\';

filename = 'sh_control_activation_intact_onball'; %UPDATE THIS EACH TIME 
% filename = 'sh_control_silencing_intact_onball'; 
% filename = 'claw_flexion_activation_intact_onball';
% filename = 'wt_berlin_speed_intact_onball'; 




parquetwrite(filename,T)