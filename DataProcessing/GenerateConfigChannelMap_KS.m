function [exportFolder,chMapFName,configFName]=GenerateConfigChannelMap_KS(recInfo,opt)
% recInfo is a structure with info about the recording, with required fields:
    % recordingName
    % samplingRate
% opt is a structure with parameters for spike sorting. Required fields:
    % trange
    % AUCsplit
    % minFR

initDir=cd;
dirListing = dir(initDir);

% set (and create if necessary) a temp directory in the user path
% tempDir=regexp(initDir,['\' filesep]);
% tempDir=fullfile(initDir(1:tempDir(1)),'Temp');
tempDir=fullfile(userpath,'Temp');
if ~exist(tempDir,'dir'); mkdir(tempDir); end

if nargin==0 ||  isempty(recInfo)
    % For testing purposes, this code can run with default info about the recording and the probe used.
    
    %expect one .bin or .dat recording file in the current directory
    recFile = cellfun(@(fileFormat) dir(fullfile(initDir, fileFormat)),{'*.dat','*.bin'},'UniformOutput', false);
    recFile=vertcat(recFile{~cellfun('isempty',recFile)});
    [~,recInfo.ephysExportName] = fileparts(recFile.name);
    
    %specify default sampling rate
    recInfo.samplingRate=30000;
    
    %define number of channel
    recInfo.numCh=32;
else
    if ~isfield(recInfo,ephysExportName) %for backward compatibility
        recInfo.baseName=recInfo.recordingName;
        dataFile = dir([initDir filesep '**' filesep [recInfo.baseName, '*export*.bin']]);
        recInfo.ephysExportName=dataFile.name(1:end-4);
    end
end

% default user options
if ~exist('opt','var')
    opt.userInput=false;
    opt.trange = [0 Inf];
    opt.AUCsplit = 0.99;
    opt.minFR = 1/10;
end

%% create ChannelMap file for KiloSort

% load probe file (or info through recInfo)
try
    probeFileName=dirListing(cellfun(@(x) contains(x,'Probe') ||...
        contains(x,'.prb') || contains(x,'.json'),{dirListing(:).name})).name;
catch
    if opt.userInput
        % ask where the probe file is
        filePath  = mfilename('fullpath');
        filePath = regexp(filePath,['.+(?=\' filesep '.+\' filesep '.+$)'],'match','once'); %removes filename
        [probeFileName,probePathName] = uigetfile('*.json','Select the probe file',...
            fullfile(filePath,'DataExport', 'probemaps'));
        copyfile(fullfile(probePathName,probeFileName),fullfile(curDir,probeFileName));
    else
        probeFileName='generic';
        probeParams.chanMap=1:recInfo.numCh;
    end
end

if isempty(probeFileName) || strcmp(probeFileName,'generic')
%     recInfo.probeLayout = probeParams.chanMap;
    probeParams.probeFileName=probeFileName;
elseif contains(probeFileName,'.json')
    probeLayout = fileread(probeFileName);
    recInfo.probeLayout = jsondecode(probeLayout);
    probeParams.probeFileName=probeFileName(1:end-4);
else
    probeLayout=load(probeFileName);
    flnm=fieldnames(probeLayout);
    recInfo.probeLayout=probeLayout.(flnm{1});
    probeParams.probeFileName=probeFileName(1:end-4);
end



if isfield(recInfo,'probeLayout')
    remapped=false; %legacy variable
    
    try %non generic probe
        probeParams.probeFileName=replace(regexp(probeParams.probeFileName,'\w+(?=Probe)','match','once'),'_','');
    catch
    end
    if isempty(probeParams.probeFileName); probeParams.probeFileName=probeFileName; end
    probeParams.numChannels=numel({recInfo.probeLayout.Electrode}); %or check recInfo.signals.channelInfo.channelName %number of channels
    
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
    if ~isfield(probeParams,'numChannels'); probeParams.numChannels=recInfo.numCh; end
    if ~isfield(probeParams,'maxSite'); probeParams.maxSite=4; end
    if ~isfield(probeParams,'connected'); probeParams.connected=ones(1,recInfo.numCh); end
    if ~isfield(probeParams,'shanks'); probeParams.shanks=ones(1,recInfo.numCh); end
    if ~isfield(probeParams,'geometry'); probeParams.geometry=[(1:recInfo.numCh)*100;zeros(1,recInfo.numCh)]'; end

end

% define and move to export folder
if ~exist(recInfo.ephysExportName,'dir')
    exportFolder=initDir; % if not export folder specified, stay in same location
else
    exportFolder=dirListing(~cellfun('isempty',cellfun(@(x) strfind(x,recInfo.ephysExportName),...
        {dirListing.name},'UniformOutput',false))).name;
end
cd(exportFolder);

if ~isempty(probeFileName)
    
    % copy probe file
    if ~strcmp(probeFileName,'generic')
        copyfile(fullfile(initDir,probeFileName),fullfile(initDir,exportFolder,probeFileName));
        probeParams.probeFileName=regexp(probeFileName,'\w+(?=\W)','match','once'); % remove file ext
    end
    
    % generate KS channel map file
    [cmdout,status,chMapFName]=GenerateKSChannelMap(probeParams.probeFileName,...
        cd,probeParams,recInfo.samplingRate);
else
    status=1; cmdout='Probe file not found-> ChannelMap not generated';
    chMapFName=[];
end

if status~=1
    disp('problem generating the channel map file')
else
    disp(cmdout)
    
    %% create configuration file for KiloSort
    userParams.chanMap = fullfile(cd,chMapFName);   % channel map path
    userParams.fs = recInfo.samplingRate;           % sampling rate
    userParams.useGPU = true;                       % has to be true in KS2+
    userParams.exportDir = cd;
    userParams.tempDir = tempDir;
    userParams.fproc   = fullfile(userParams.tempDir, [recInfo.ephysExportName '.dat']); % process file on a fast SSD
    userParams.fbinary = fullfile(userParams.exportDir, [recInfo.ephysExportName '.bin']);
    userParams.NchanTOT = numel(probeParams.chanMap);
    userParams.trange = opt.trange;
    userParams.AUCsplit = opt.AUCsplit; % splitting a cluster at the end requires at least this much isolation for each sub-cluster (max = 1)
    userParams.minFR = opt.minFR; % minimum spike rate (Hz), if a cluster falls below this for too long it gets removed
    [~,~,configFName]=GenerateKSConfigFile(recInfo.ephysExportName,cd,userParams);
    
end

% go back to initial directory
cd(initDir)


