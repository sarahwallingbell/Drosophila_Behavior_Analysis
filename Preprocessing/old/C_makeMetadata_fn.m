function C_makeMetadata_fn(data, dataset, datasetSummaryPath)


datasetSummary = readtable(datasetSummaryPath); %list of which parquet files comprise which datasets

% Select and load parquet file (the fly data)
datasetIdx = strcmp(datasetSummary.dataset, dataset);
[numReps, numConds, flyList, flyIndices] = DLC_extract_flies(data);
param = DLC_load_params(data, version, dataset, flyList);
param.numReps = numReps;
param.numConds = numConds; 
param.stimRegions = DLC_getStimRegions(data, param);
param.flyIndices = flyIndices;
param.dataset = param.metadatapath;
param.parquet = datasetSummary.readyDataPath;
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
[data, ~] = fixFictracOutput(data, walkingData, flyList); %don't need to save walkingData here

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
parquetwrite([param.metadatapath dataset], data, "VariableCompression", 'snappy'); %save data which has corrected anipose and fictrac output
save([param.metadatapath dataset '_metadata.mat'], "param", "steps");

%write good data path to summaryData
datasetSummary.readyDataMade{datasetIdx} = date; %today's data (date of metadata creation)
datasetSummary.readyDataPath{datasetIdx} = param.metadatapath; %path where data.pq, param and steps are saved. 
writetable(datasetSummary, datasetSummaryPath); %save updated table
