function BatchSpikeSort_KS(dataDir,folderName)

%% generate config and channel map files. Create batch file
cd(fullfile(dataDir,'SpikeSorting'));
GenerateConfigChannelMap_KS;

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
