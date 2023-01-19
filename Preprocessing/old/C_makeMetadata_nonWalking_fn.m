function C_makeMetadata_nonWalking_fn(data, dataset, datasetSummaryPath)

%metadata maker for headless and offball flies.

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

%fix anipose joint data output
data = fixAniposeJointOutput(data, param, flyList); 

%save good data and metadata
parquetwrite([param.metadatapath dataset], data, "VariableCompression", 'snappy'); %save data which has corrected anipose and fictrac output
save([param.metadatapath dataset '_metadata.mat'], "param");

%write good data path to summaryData
datasetSummary.readyDataMade{datasetIdx} = date; %today's data (date of metadata creation)
datasetSummary.readyDataPath{datasetIdx} = param.metadatapath; %path where data.pq, param and steps are saved. 
writetable(datasetSummary, datasetSummaryPath); %save updated table
