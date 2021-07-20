function BatchSpikeSort_KS_JRC(dataDir,folderName,allRecInfo)

%% generate config and channel map files. Create batch file
cd(fullfile(dataDir,'SpikeSorting'))
GenerateConfigChannelMap_KS_JRC

%% Run KiloSort on batch file
% open batch file
batchFileID = fopen([folderName '.batch'],'r');
delimiter = {''};formatSpec = '%s%[^\n\r]';
prmFiles = textscan(batchFileID, formatSpec, 'Delimiter', delimiter,...
    'TextType', 'string',  'ReturnOnError', false);
fclose(batchFileID);
prmFiles = [prmFiles{1}];
% Run KS3
for fileNum=1:size(prmFiles,1)
    try
        RunKS(prmFiles{fileNum});
    catch
        close all; continue
    end
    close all
end

%% import results into JRC
if ~exist('dataFiles','var'); load('fileInfo.mat'); end
for fileNum=1:size(dataFiles,1)
    try
        recInfo = allRecInfo{fileNum};
        cd([recInfo.recordingName])
        jrc('bootstrap',[recInfo.recordingName '_export.meta'],'-noconfirm','-advanced')
        jrc('import-ksort',cd,false);
        cd ..
    catch
        continue
    end
end

