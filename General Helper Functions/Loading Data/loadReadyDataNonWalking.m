function [data, param] = loadReadyDataNonWalking(datasetName)

% Given a dataset name, load the data needed for plotting. 
% 
% Sarah Walling-Bell
% November 2022

%load datasetSummary to get path to readydata
sarah_dataset_path = 'G:\.shortcut-targets-by-id\15uXSKut68NlHyR8OywpWbt0zXFWyC-43\Sarah\Data\Datasets\sarah_datasets.xlsx'; %dataset summary file 
sarah_datasets = readtable(sarah_dataset_path); 
datasetIdx = strcmp(sarah_datasets.New_dataset_name, datasetName);
readyDataPath = sarah_datasets.Path_to_processed_data{datasetIdx};

%load the data 
data = parquetread([readyDataPath datasetName '.parquet']);
load([readyDataPath datasetName '_metadata.mat'], "param");
readtable([readyDataPath 'flyList.csv']);

end