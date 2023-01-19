% Populate fly datasets combine xlsx. The file that says which flies to put 
% in each parquet summary file. 
% 
% Sarah, November 2022


datasetFilePath = 'G:\.shortcut-targets-by-id\15uXSKut68NlHyR8OywpWbt0zXFWyC-43\Sarah\Data\Datasets\sarah_datasets.xlsx';
datasetFile = readtable(datasetFilePath); %list of each dataset to make 

%datasets to add flies to combine file. 
datasets = datasetFile.Datasets(datasetFile.Added_to_fly_datasets_combine == 0); 

%files holding which flies go in which datasets
flyFilesPath = 'G:\.shortcut-targets-by-id\15uXSKut68NlHyR8OywpWbt0zXFWyC-43\Sarah\Data\Datasets\flyFiles\'; %path to files. 

%file holding infor for datasets to make
combineFilePath = 'G:\.shortcut-targets-by-id\10pxdlRXtzFB-abwDGi0jOGOFFNm3pmFK\Tuthill Lab Shared\Pierre\summaries\fly_datasets_combine.xlsx';
combineFile = readtable(combineFilePath);

for d = 1:height(datasets)
    if isfile([flyFilesPath datasets{d} '.xlsx'])
        flyFile = readtable([flyFilesPath datasets{d} '.xlsx']);
        
        %get dataset name, expand to full name 
        datasetName = datasets{d};
        datasetName = strrep(datasetName, '_flex_', '_flexion_');
        datasetName = strrep(datasetName, '_ext_', '_extension_');
        datasetName = strrep(datasetName, '_act_', '_activation_');
        datasetName = strrep(datasetName, '_sil_', '_silencing_');
        datasetName = strrep(datasetName, '_ctl_', '_control_');
        datasetName = strrep(datasetName, '_pwr', '_laser_power');
        datasetName = strrep(datasetName, 'sh_', 'split_half_');
        datasetName = strrep(datasetName, '_175', '_JR175');
        datasetName = strrep(datasetName, '_299', '_JR299');

        DatasetName = repmat({datasetName}, size(flyFile,1), 1);
        Experimenter = repmat({'sarah'}, size(flyFile,1), 1);
        RigVersion = flyFile.RigVersion;
        FlyLine = flyFile.FlyLine;
        Head = flyFile.Head;
        Ball = flyFile.Ball;
        Date = flyFile.Date;
        Fly = flyFile.Fly_;
        Notes = repmat({''}, size(flyFile,1), 1);
        
        %save data to combine file
        temp = table(DatasetName, Experimenter, RigVersion, FlyLine, Head, Ball, Date, Fly, Notes);
        temp = unique(temp, 'rows');
        combineFile = [combineFile; temp]; 

        %save dataset made and new dataset name
        dIdx = find(strcmp(datasetFile.Datasets, datasets{d}));
        datasetFile.Added_to_fly_datasets_combine(dIdx) = 1; %made the dataset
        datasetFile.New_dataset_name{dIdx} = datasetName; %new dataset name
        datasetFile.Num_flies(dIdx) = height(temp); %num flies in this dataset
    
    end
end

%write tables 
writetable(combineFile, combineFilePath);
writetable(datasetFile, datasetFilePath);






