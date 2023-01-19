function make_metadata_intact_onball_fn(dataset)

dataset_path = ['G:\.shortcut-targets-by-id\10pxdlRXtzFB-abwDGi0jOGOFFNm3pmFK\Tuthill Lab Shared\Pierre\summaries\v3-b4\combined\' dataset '.pq']; %loading summary file
metadata_path = ['G:\My Drive\Analysis\' dataset '\']; %saving metadata
sarah_dataset_path = 'G:\.shortcut-targets-by-id\15uXSKut68NlHyR8OywpWbt0zXFWyC-43\Sarah\Data\Datasets\sarah_datasets.xlsx'; %dataset summary file 
parquet_path = [metadata_path dataset '.parquet']; %path to new parquet file 

% Load dataset summary file
sarah_datasets = readtable(sarah_dataset_path); 
datasetIdx = strcmp(sarah_datasets.New_dataset_name, dataset);

%if dataset name has not been added to file, add it and update datasetIdx
if sum(datasetIdx) == 0
    sarah_datasets.New_dataset_name{end+1} = dataset;
    datasetIdx = strcmp(sarah_datasets.New_dataset_name, dataset);
end

% Load parquet file (the fly data)
data = parquetread(dataset_path);

% Extract flies and generate param 
[numReps, numConds, flyList, flyIndices] = DLC_extract_flies(data);
param = DLC_load_params(data, version, dataset, flyList);
param.numReps = numReps;
param.numConds = numConds; 
% param.stimRegions = DLC_getStimRegions(data, param);
param.flyIndices = flyIndices;
param.dataset = parquet_path;
param.parquet = parquet_path;
param.flyList = table2struct(param.flyList); %cannot be table for saving 
param.flyColors = table2struct(table(param.flyColors)); %for saving 
param.jointFillWeights = [param.jointFillWeights{:}]; %for saving 
param.lasers = [param.lasers{:}]; %for saving 
param.behaviorColors = table2struct(table(param.behaviorColors)); %for saving 

% Add stim regions to data
data = addStimRegions(data, param);

% Add laser power to data for power exps
if contains(dataset, 'laser_power')
    data = addLaserPower(data);
end

% Fix anipose joint data output
data = fixAniposeJointOutput(data, param, flyList); 

% Get walking data 
walkingData = data(~isnan(data.walking_bout_number),:); 

% Fix fictrac output
[data, ~] = fixFictracOutput(data, walkingData, flyList); %don't need to save walkingData here

% Parse walking bouts and find swing stance
data = parseSwingStance(data, param);

% Calculate metadata for steps
[data, steps] = getStepMetadata(data, param);

%     % Organize data for plotting 
%     joint_data = DLC_org_joint_data(data, param);
%     joint_data_byFly = DLC_org_joint_data_byFly(data, param);

%     % Get behaviors of each fly 
%     param.thresh = 0.1; %0.5; %thres hold for behavior prediction 
%     behavior = DLC_behavior_predictor(data, param); 
%     behavior_byBout = DLC_behavior_predictor_byBoutNum (data, param);

% Save good data and metadata
parquetwrite(parquet_path, data, "VariableCompression", 'snappy'); %save data which has corrected anipose and fictrac output
save([metadata_path dataset '_metadata.mat'], "param", "steps");

% Write good data path to summaryData
sarah_datasets.Path_to_processed_data{datasetIdx} = metadata_path; %path where data.pq, param and steps are saved. 
writetable(sarah_datasets, sarah_dataset_path); %save updated table
