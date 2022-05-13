function CreateBatchList

%% Generate config and channel map files. Create batch file
if ~exist('dataFiles','var'); load('fileInfo.mat'); end
% open batch file to save generated parameter files' name and directory
% assuming the parent folder is the container for all files from that subject
curDir=cd;
tempDir=regexp(curDir,['\' filesep]);
tempDir=fullfile(curDir(1:tempDir(1)),'Temp');
if ~exist(tempDir,'dir'); mkdir(tempDir); end
parentDir=regexp(curDir,['(?<=\' filesep ').+?(?=\' filesep ')'],'match');
parentDir = parentDir{end};
batchFileID = fopen([parentDir '.batch'],'w');
% loop through all session's recordings
for fileNum=1:size(dataFiles,1)
    %% get recording's info
    recInfo = allRecInfo{fileNum};
    opt.userInput=true;
    [exportFolder,~,configFName]=GenerateConfigChannelMap_KS(recInfo,opt);
    
    %% save KS config file name to batch list
    fprintf(batchFileID,'%s\r',fullfile(cd,exportFolder,configFName));
    
end
fclose(batchFileID);
