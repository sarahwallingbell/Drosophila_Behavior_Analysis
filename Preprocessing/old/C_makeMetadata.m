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
    datasetIdx = strcmp(datasetSummary.dataset, datasets{dataset});
    filePath = datasetSummary.rawDatasetPath{datasetIdx};
    [data, path] = DLC_extract_parquet({filePath});
    [numReps, numConds, flyList, flyIndices] = DLC_extract_flies(data);
    param = DLC_load_params(data, version, datasets{dataset}, flyList);
    param.numReps = numReps;
    param.numConds = numConds; 
    param.stimRegions = DLC_getStimRegions(data, param);
    param.flyIndices = flyIndices;
    param.dataset = dataset;
    param.parquet = param.metadatapath;
    param.flyList = table2struct(param.flyList); %cannot be table for saving 
    param.flyColors = table2struct(table(param.flyColors)); %for saving 
    param.jointFillWeights = [param.jointFillWeights{:}]; %for saving 
    param.lasers = [param.lasers{:}]; %for saving 
    param.behaviorColors = table2struct(table(param.behaviorColors)); %for saving 

    %add stim regions to data
    data = addStimRegions(data, param);

    %add laser power to data for power exps
    if contains(dataset, '_pwr')
        data = addLaserPower(data);
    end

    %fix anipose joint data output
    data = fixAniposeJointOutput(data, param, flyList); 
    
    %get walking data 
    walkingData = data(~isnan(data.walking_bout_number),:); 
    
    %fix fictrac output
    [data, walkingData] = fixFictracOutput(data, walkingData, flyList); 
    
    %parse walking bouts and find swing stance
    data = parseSwingStance(data, param);

    %calculate metadata for steps
    [data, steps] = getStepMetadata(data, param);
    
%     % Organize data for plotting 
%     joint_data = DLC_org_joint_data(data, param);
%     joint_data_byFly = DLC_org_joint_data_byFly(data, param);
    
%     % Get behaviors of each fly 
%     param.thresh = 0.1; %0.5; %thres hold for behavior prediction 
%     behavior = DLC_behavior_predictor(data, param); 
%     behavior_byBout = DLC_behavior_predictor_byBoutNum (data, param);

    %save good data and metadata
    parquetwrite([param.metadatapath datasets{dataset}], data, "VariableCompression", 'snappy'); %save data which has corrected anipose and fictrac output
    save([param.metadatapath datasets{dataset} '_metadata.mat'], "param", "steps");

    %write good data path to summaryData
    datasetSummary.readyDataMade{datasetIdx} = date; %today's data (date of metadata creation)
    datasetSummary.readyDataPath{datasetIdx} = param.metadatapath; %path where data.pq, param and steps are saved. 
    writetable(datasetSummary, datasetSummaryPath); %save updated table
end

