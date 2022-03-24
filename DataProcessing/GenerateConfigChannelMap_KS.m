function GenerateConfigChannelMap_KS

%% generate config and channel map files. Create batch file
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
    if isempty(recInfo); continue; end
    
    %% create ChannelMap file for KiloSort
    % load probe file
    dirListing = dir(curDir);
    %     exportFolder=dirListing(~cellfun('isempty',cellfun(@(x) strfind(x,allRecInfo{fileNum}.recordingName),...
    %         {dirListing.name},'UniformOutput',false))).name;
    try
        probeFileName=dirListing(cellfun(@(x) contains(x,'Probe') ||...
            contains(x,'.prb') || contains(x,'.json'),{dirListing(:).name})).name;
    catch
        % ask where the probe file is
        filePath  = mfilename('fullpath');
        filePath = regexp(filePath,['.+(?=\' filesep '.+\' filesep '.+$)'],'match','once'); %removes filename
        [probeFileName,probePathName] = uigetfile('*.json','Select the probe file',...
            fullfile(filePath,'DataExport', 'probemaps'));
        copyfile(fullfile(probePathName,probeFileName),fullfile(curDir,probeFileName));
    end
    if contains(probeFileName,'.json') %|| contains(probeFileName,'.prb')
        probeLayout = fileread(probeFileName);
        recInfo.probeLayout = jsondecode(probeLayout);
    else
        probeLayout=load(probeFileName);
        flnm=fieldnames(probeLayout);
        recInfo.probeLayout=probeLayout.(flnm{1});
    end
    remapped=false;
    probeParams.probeFileName=probeFileName(1:end-4);
    try %non generic probe
        probeParams.probeFileName=replace(regexp(probeParams.probeFileName,'\w+(?=Probe)','match','once'),'_','');
    catch
    end
    if isempty(probeParams.probeFileName); probeParams.probeFileName=probeFileName; end
    probeParams.numChannels=numel({recInfo.probeLayout.Electrode}); %or check recInfo.signals.channelInfo.channelName %number of channels
    
    if isfield(recInfo,'probeLayout')
        if isfield(recInfo.probeLayout,'surfaceDim')
            probeParams.pads=recInfo.probeLayout.surfaceDim;
        end
        if isfield(recInfo.probeLayout,'maxSite')
            probeParams.maxSite=recInfo.probeLayout.maxSite;
        end
        % Channel map
        if remapped==true
            probeParams.chanMap=1:probeParams.numChannels;
        else
            switch recInfo.sys
                case 'OpenEphys'
                    probeParams.chanMap={recInfo.probeLayout.OEChannel};
                case 'Blackrock'
                    probeParams.chanMap={recInfo.probeLayout.BlackrockChannel};
            end
            % check for unconnected / bad channels
            if isfield(recInfo.probeLayout,'connected')
                probeParams.connected=logical(recInfo.probeLayout.connected);
                probeParams.chanMap=probeParams.chanMap{:}(probeParams.connected);
            else
                probeParams.connected=~cellfun(@isempty, probeParams.chanMap);
                probeParams.chanMap=[probeParams.chanMap{:}];
            end
        end
        probeParams.shanks=[recInfo.probeLayout.Shank];
        probeParams.shanks=probeParams.shanks(probeParams.connected);
        % probeParams.shanks=probeParams.shanks(~isnan([recInfo.probeLayout.Shank]));
        
        %now adjust
        probeParams.numChannels=sum(probeParams.connected);
        probeParams.connected=logical(probeParams.chanMap);
        
        if max(probeParams.chanMap)>probeParams.numChannels
            if  numel(probeParams.chanMap)==probeParams.numChannels
                %fine, just need adjusting channel numbers
                [~,probeParams.chanMap]=sort(probeParams.chanMap);
                [~,probeParams.chanMap]=sort(probeParams.chanMap);
            else
                disp('There''s an issue with the channel map')
            end
        end
        
        %geometry:
        %         Location of each site in micrometers. The first column corresponds
        %         to the width dimension and the second column corresponds to the depth
        %         dimension (parallel to the probe shank).
        
        
        if isfield(recInfo.probeLayout,'geometry')
            probeParams.geometry=recInfo.probeLayout.geometry;
        else
            if isfield(recInfo.probeLayout,'x_geom')
                xcoords=[recInfo.probeLayout.x_geom];
                ycoords=[recInfo.probeLayout.y_geom];
            else
                xcoords = zeros(1,probeParams.numChannels);
                ycoords = 200 * ones(1,probeParams.numChannels);
                groups=unique(probeParams.shanks);
                for elGroup=1:length(groups)
                    if isnan(groups(elGroup)) || groups(elGroup)==0
                        continue;
                    end
                    groupIdx=find(probeParams.shanks==groups(elGroup));
                    xcoords(groupIdx(2:2:end))=20;
                    xcoords(groupIdx)=xcoords(groupIdx)+(0:length(groupIdx)-1);
                    ycoords(groupIdx)=...
                        ycoords(groupIdx)*(elGroup-1);
                    ycoords(groupIdx(round(end/2)+1:end))=...
                        ycoords(groupIdx(round(end/2)+1:end))+20;
                end
            end
            probeParams.geometry=[xcoords;ycoords]';
        end
    else
        if sum(~cellfun(@isempty, cellfun(@(pattern)...
                strfind(probeParams.probeFileName,pattern),...
                {'cnt','CNT'},'UniformOutput',false)))
            probeParams.pads=[15 11]; % Dimensions of the recording pad (height by width in micrometers).
        else
            probeParams.pads=[16 10];
        end
        
        probeParams.maxSite=4; % Max number of sites to consider for merging
        
    end
    
    % define export folder and copy probe file
    exportFolder=dirListing(~cellfun('isempty',cellfun(@(x) strfind(x,allRecInfo{fileNum}.recordingName),...
        {dirListing.name},'UniformOutput',false))).name;
    copyfile(fullfile(curDir,probeFileName),fullfile(curDir,exportFolder,probeFileName));
    
    % move to export folder
    cd(exportFolder);
    probeParams.probeFileName=regexp(probeFileName,'\w+(?=\W)','match','once');
    
    % Generate KS channel map file
    [cmdout,status,chMapFName]=GenerateKSChannelMap(probeParams.probeFileName,...
        cd,probeParams,recInfo.samplingRate);
    
    if status~=1
        disp('problem generating the channel map file')
    else
        disp(cmdout)
        
        %% create configuration file for KiloSort
        userParams.chanMap = fullfile(cd,chMapFName);   % channel map path
        userParams.fs = recInfo.samplingRate;           % sample rate
        userParams.useGPU = true;                       % has to be true in KS2
        userParams.exportDir = cd;
        userParams.tempDir = tempDir;
        userParams.fproc   = fullfile(userParams.tempDir, [recInfo.recordingName '_export.dat']); % proc file on a fast SSD
        userParams.fbinary = fullfile(userParams.exportDir, [recInfo.recordingName '_export.bin']);
        userParams.NchanTOT = numel(probeParams.chanMap);
        userParams.trange = [0 Inf];
        userParams.AUCsplit = 0.99; % splitting a cluster at the end requires at least this much isolation for each sub-cluster (max = 1)
        userParams.minFR = 1/10; % minimum spike rate (Hz), if a cluster falls below this for too long it gets removed
        [status,cmdout,configFName]=GenerateKSConfigFile(recInfo.recordingName,cd,userParams);
        
        %% save KS config file name to batch list
        fprintf(batchFileID,'%s\r',fullfile(cd,configFName));
        
    end
    % go back to root dir
    cd ..
end
fclose(batchFileID);
