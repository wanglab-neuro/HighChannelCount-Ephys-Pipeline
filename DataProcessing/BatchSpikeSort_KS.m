function BatchSpikeSort_KS(dataDir,sessionName)
% Inputs: 
% dataDir: overall session directory. Contains a 'SpikeSorting' folder where
%          recording file have been exported to their own directory for spike
%          sorting. Defaults to current directory.
% sessionName: name of that session. Defaults to session's folder name

if ~exist('dataDir','var'); dataDir=cd; end
if ~exist('sessionName','var')
    dirComps=regexp(dataDir,filesep,'split');
    sessionName=dirComps{end}; 
end
    
%% Create batch file. Generate config and channel map files. 
if ~exist('SpikeSorting','dir'); mkdir('SpikeSorting'); end
cd(fullfile(dataDir,'SpikeSorting'));
CreateBatchList;

%% Run KiloSort on batch file
% open batch file
batchFileID = fopen([sessionName '.batch'],'r');
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
