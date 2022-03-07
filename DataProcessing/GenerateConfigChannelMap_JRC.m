function GenerateConfigChannelMap_JRC
%% generate prb, meta files
[probeParams,allRecInfo]=GenerateProbeMap_JRC;

%% generate prm file
if ~exist('dataFiles','var'); load('fileInfo.mat'); end
% open batch file to save generated parameter files' name and directory
% assuming the parent folder is the container for all files from that subject
parentDir=regexp(cd,['(?<=\' filesep ').+?(?=\' filesep ')'],'match');
parentDir = parentDir{end};
batchFileID = fopen([parentDir '.batch'],'w');
% loop through all session's recordings
for fileNum=1:size(allRecInfo,1)

    dirListing = dir(cd);
        exportFolder=dirListing(~cellfun('isempty',cellfun(@(x) strfind(x,allRecInfo{fileNum}.recordingName),...
        {dirListing.name},'UniformOutput',false))).name;
    cd(exportFolder);
        dirListing=dir(cd);
    exportFileName=dirListing(~cellfun('isempty',cellfun(@(x) strfind(x,'export.bin'),...
        {dirListing.name},'UniformOutput',false))).name;
    exportFileName=exportFileName(1:end-4);
    
    %% make parameter file
    % set parameters (e.g., name of TTL file), to edit params file
    % #Trial (used for plotting PSTH for each unit after clustering)
    
    trialFile = cellfun(@(fileFormat) dir([cd filesep fileFormat]),...
        {'*.csv'},'UniformOutput', false);
    if isempty(trialFile{:})
        inputParams={'CARMode','''median''';...
            'qqFactor','4';};
    else
        trialFile=trialFile{:};
        if size(trialFile,1)>1
            % decide which one to use
            % keep the opto stimulation by default
            isOptoStim=contains({trialFile.name},'opto');
            if any(isOptoStim)
                trialFile=fullfile(trialFile(isOptoStim).folder,trialFile(isOptoStim).name);
            else
                trialFile=fullfile(trialFile(1).folder,trialFile(1).name);
            end
        end
        trialFile=strrep(trialFile,filesep,[filesep filesep]);
        inputParams={'CARMode','''median''';...
            'qqFactor','4';...
            'trialFile',['''' trialFile ''''];...
            'psthTimeLimits','[-0.2, 0.2]';...% [-1, 5]; % Time range to display PSTH (in seconds)
            'psthTimeBin','0.001'; ... %0.01;% Time bin for the PSTH histogram (in seconds)
            'psthXTick','0.01';... % 0.2;			% PSTH time tick mark spacing
            'nSmooth_ms_psth','10'}; % 50;			% PSTH smoothing time window (in milliseconds)
    end
    [paramFStatus,cmdout]=ModifyJRCParamFile(exportFileName,true,inputParams);
    
    %% save prm file name to batch list
    fprintf(batchFileID,'%s\r',fullfile(cd,[exportFileName '.prm']));
    
% go back to root dir
cd ..    
end

fclose(batchFileID);
