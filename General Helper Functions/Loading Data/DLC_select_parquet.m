function [FilePaths, version] = DLC_select_parquet()
% FilePath = DLC_select_flies();
% S Walling-Bell
% University of Washington, 2020

% % -- Select fly parquet to analyze -- % %
version = 'v3-b4'; 
% version = 'v3-b3';
% root = ['G:\My Drive\Tuthill Lab Shared\Pierre\summaries\' version '\']; %update for lastest behavior classifier version. 
% root = ['G:\.shortcut-targets-by-id\0B-MI5yeL50V0S0FvdncyaFJfSTg\Tuthill Lab Shared\Pierre\summaries\' version '\'];  
% root = ['E:\.shortcut-targets-by-id\10pxdlRXtzFB-abwDGi0jOGOFFNm3pmFK\Tuthill Lab Shared\Pierre\summaries\' version '\'];  
root = ['G:\.shortcut-targets-by-id\10pxdlRXtzFB-abwDGi0jOGOFFNm3pmFK\Tuthill Lab Shared\Pierre\summaries\' version '\'];  


%select flies by line or date 
file_types = {'lines','days'};
choice = listdlg('ListString', file_types, 'PromptString','Flies by line or date?', 'SelectionMode','single', 'ListSize', [300 300]);
path = join([root, file_types{choice}, '\']);
%select parquet
if strcmpi(file_types{choice}, 'lines')
    files3 = struct2cell(dir(join([path, 'sarah*rv3*.pq']))); %sarah's files from rig version 3
    files4 = struct2cell(dir(join([path, 'sarah*rv4*.pq']))); %sarah's files from rig version 4
    files5 = struct2cell(dir(join([path, 'sarah*rv5*.pq']))); %sarah's files from rig version 5
    files6 = struct2cell(dir(join([path, 'sarah*rv6*.pq']))); %sarah's files from rig version 5
    files7 = struct2cell(dir(join([path, 'sarah*rv7*.pq']))); %sarah's files from rig version 5
    files8 = struct2cell(dir(join([path, 'sarah*rv8*.pq']))); %sarah's files from rig version 5
    files9 = struct2cell(dir(join([path, 'sarah*rv9*.pq']))); %sarah's files from rig version 5
    files10 = struct2cell(dir(join([path, 'sarah*rv10*.pq']))); %sarah's files from rig version 5
    files11 = struct2cell(dir(join([path, 'sarah*rv11*.pq']))); %sarah's files from rig version 5
    files12 = struct2cell(dir(join([path, 'sarah*rv12*.pq']))); %sarah's files from rig version 5
    files13 = struct2cell(dir(join([path, 'sarah*rv13*.pq']))); %sarah's files from rig version 5
    files14 = struct2cell(dir(join([path, 'sarah*rv14*.pq']))); %sarah's files from rig version 5
    files15 = struct2cell(dir(join([path, 'sarah*rv15*.pq']))); %sarah's files from rig version 5
    files16 = struct2cell(dir(join([path, 'sarah*rv16*.pq']))); %sarah's files from rig version 5
    files17 = struct2cell(dir(join([path, 'sarah*rv17*.pq']))); %sarah's files from rig version 5
    files18 = struct2cell(dir(join([path, 'sarah*rv18*.pq']))); %sarah's files from rig version 5
    files19 = struct2cell(dir(join([path, 'sarah*rv19*.pq']))); %sarah's files from rig version 5
    files20 = struct2cell(dir(join([path, 'sarah*rv20*.pq']))); %sarah's files from rig version 5


    files = [files3, files4, files5, files6, files7, files8, files9, files10, files11, files12, files13, files14, files15, files16, files17, files18, files19, files20];
    
    file_names = files(1,:);
else
    files20 = struct2cell(dir(join([path, '*20.parquet']))); %data from 2020
    files21 = struct2cell(dir(join([path, '*21.parquet']))); %data from 2021
    files22 = struct2cell(dir(join([path, '*22.parquet']))); %data from 2022
    files = [files20 files21 files22];
    file_names = files(1,:);
end
choices = listdlg('ListString', file_names, 'PromptString','Select parquet', 'ListSize', [400 500]);
FilePaths = {};
for choice = 1:width(choices)
    FilePaths{choice} = join([path, file_names{choices(choice)}]);
end

end