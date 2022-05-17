
%Create Configuration file and Channel map
[exportFolder,~,configFName]=GenerateConfigChannelMap_KS;

%Run KiloSort
RunKS(fullfile(exportFolder,configFName));
