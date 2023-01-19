%% Load % orgnaize the data 
clear all; close all; clc;

datasets = {'sh_control_all_intact_onball'};
%             'claw_flexion_activation_intact_onball'}; %list of datasets to generate metadata for 

%dataset summary contains paths to datasets
datasetSummaryPath = 'G:\.shortcut-targets-by-id\15uXSKut68NlHyR8OywpWbt0zXFWyC-43\Sarah\Data\Datasets\datasetSummary.xlsx'; 
datasetSummary = readtable(datasetSummaryPath); %list of which parquet files comprise which datasets

initial_vars = who; %save these variables on each iteration below 
initial_vars{end+1} = 'dataset';

for dataset = 1:width(datasets)

    clearvars('-except',initial_vars{:}); initial_vars = who;
    
    % Select and load parquet file (the fly data)
    % [FilePaths, version] = DLC_select_parquet(); 
    datasetIdx = contains(datasetSummary.dataset, datasets{dataset});
    filePath = datasetSummary.datasetPath{datasetIdx};
    [data, columns, column_names, path] = DLC_extract_parquet({filePath});
    [numReps, numConds, flyList, flyIndices] = DLC_extract_flies(columns, data);
    param = DLC_load_params(data, version, datasets{dataset}, flyList);
    param.numReps = numReps;
    param.numConds = numConds; 
    param.stimRegions = DLC_getStimRegions(data, param);
    param.flyIndices = flyIndices;
    param.columns = columns; 
    param.column_names = column_names;  
    param.parquet = path;
    param.flyList = table2struct(param.flyList); %cannot be table for saving 
    param.flyColors = table2struct(table(param.flyColors)); %for saving 
    param.jointFillWeights = [param.jointFillWeights{:}]; %for saving 
    param.lasers = [param.lasers{:}]; %for saving 
    param.behaviorColors = table2struct(table(param.behaviorColors)); %for saving 

    %fix anipose joint data output
    data = fixAniposeJointOutput(data, param, flyList); 
    
    %save walking data 
    walkingData = data(~isnan(data.walking_bout_number),:); 
    
    %fix fictrac output
    [data, walkingData] = fixFictracOutput(data, walkingData, flyList); 
    
    %parse walking bouts and find swing stance
    % boutMap = boutMap_with_swing_stance(walkingData,param);
    clear boutMap
    boutMap = boutMap(walkingData,param); 
    
    %parse steps and step metrics
    clear steps
    steps = steps(boutMap, walkingData, param);
    
%     % Organize data for plotting 
%     joint_data = DLC_org_joint_data(data, param);
%     joint_data_byFly = DLC_org_joint_data_byFly(data, param);
    
%     % Get behaviors of each fly 
%     param.thresh = 0.1; %0.5; %thres hold for behavior prediction 
%     behavior = DLC_behavior_predictor(data, param); 
%     behavior_byBout = DLC_behavior_predictor_byBoutNum (data, param);

    %save everything
    parquetwrite([param.metadatapath datasets{dataset}], data, "VariableCompression", 'snappy'); %save data which has corrected anipose and fictrac output
    writestruct(param, [param.metadatapath 'param'], 'FileType','xml'); %param
    writetable(boutMap, [param.metadatapath 'boutMap.csv']); %boutMap
    writestruct(); %steps

    save([param.metadatapath datasets{dataset} '_metadata.mat'], "param", "boutMap", "steps", '-v7.3');
    
    %write metadata path to summaryData
    


end

