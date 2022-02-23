function [ephys,behav,pulses,trials,targetDir]=Analyze_LoadData
% Loads data for analysis of correlation between bursts/spike rate 
% and periodic behaviors (whisking, breathing)
%% Directory structure assumed to be:
% > Recording session   (may contain "raw" data)
%     > Spike Sorting Folder 
%         > Recording #1
%         > Recording #2
%         ...
%     > Whisker Tracking Folder (all session data processed together)
%     > Analysis Folder (current folder)

startingDir=cd; dirListing=dir(startingDir);
currentfolder=regexp(startingDir,['(?<=\' filesep ')\w+$'],'match','once');
directoryHierarchy=regexp(startingDir,['\S+?(?=\' filesep ')'],'match');
if ~strcmp(currentfolder,'Analysis') &&...
        ~strcmp(directoryHierarchy{end},[filesep 'Analysis'])
    if ~strcmp(directoryHierarchy{end},[filesep 'SpikeSorting'])
        % ask which folder to run through and move there
    end
    if ~exist(fullfile(directoryHierarchy{1:end-1},'Analysis'),'dir')
        mkdir(fullfile(directoryHierarchy{1:end-1},'Analysis'))
    end
    [allDataFiles,targetDir]=Analyze_GatherData;
    cd(targetDir) %fullfile(directoryHierarchy{1:end-1},'Analysis'))
else
    targetDir=cd;
    % load all files in current directory 
    allDataFiles=dirListing([dirListing.isdir]==0);
    allDataFiles={allDataFiles.name}';
end

%% Get some info about the recording if possible
recInfoFile=cellfun(@(flnm) contains(flnm,'Info','IgnoreCase',true) &&...
    ~contains(flnm,'trial','IgnoreCase',true),allDataFiles);
if any(recInfoFile)
    recInfo=LoadRecInfo(allDataFiles{recInfoFile});
else
    recInfo.sessionName=GetCommonString(allDataFiles);
    if ~isempty(recInfo.sessionName)
        recInfo.sessionName=regexprep(recInfo.sessionName,'[^a-zA-Z0-9]+$','');
    end
end
if ~isfield(recInfo,'baseName')
    if isfield(recInfo,'recordingName')
        recInfo.baseName=recInfo.recordingName;
    else
        recInfo.baseName=recInfo.sessionName;
    end
end

%% Try attributing a name to the files session
if ~isfield(recInfo,'sessionName')
    if ~strcmp(currentfolder,'Analysis') || ~strcmp(currentfolder,'SpikeSorting')
        %assuming to be in session's folder
        recInfo.sessionName=currentfolder;
    else
        recInfo.sessionName=cell2mat(inputdlg({'Session name'},'Enter Session ID',...
            1,{directoryHierarchy{end-1}(2:end)}));
    end
end

%% load probe file
probeFile=cellfun(@(flnm) contains(flnm,{'prb','Probe','.json'}) ,allDataFiles);
if any(probeFile)
    if sum(probeFile)>1
        probeFiles=allDataFiles(probeFile);
        probeFile=find(probeFile);
        probeFile=probeFile(cellfun(@(x) contains(x,'Adaptor'), probeFiles));
    end
    [~, ~, fExt] = fileparts(allDataFiles{probeFile});
    switch lower(fExt)
        case '.mat'
            load(allDataFiles{probeFile});
            recInfo.channelMap=chanMap;
            recInfo.probeGeometry=[xcoords';ycoords'];
        case '.json'
            probeInfo=jsondecode(fileread(allDataFiles{probeFile}));
            prbFlds=fields(probeInfo);
            recInfo.channelMap = probeInfo.(prbFlds{contains(prbFlds,'BlackrockChannel')});
            recInfo.probeGeometry = probeInfo.geometry;
            recInfo.exportedChan=probeInfo.numChannels;
        otherwise  % Under all circumstances SWITCH gets an OTHERWISE!
            fid  = fopen(allDataFiles{probeFile},'r');
            probeParams=fread(fid,'*char')';
            fclose(fid);
            recInfo.channelMap = str2num(regexp(probeParams,'(?<=channels = [).+?(?=])','match','once'));
            recInfo.probeGeometry = str2num(regexp(probeParams,'(?<=geometry = [).+?(?=])','match','once'))';
    end
end

if isfield(recInfo,'exportedChan');    numElectrodes=numel(recInfo.exportedChan);
elseif isfield(recInfo,'numRecChan');    numElectrodes=recInfo.numRecChan; 
else
    prompt = {'Enter the number of recorded channels'};
    dlg_title = 'Channel number'; num_lines = 1; defaultans = {'32'};
    numElectrodes = str2double(cell2mat(inputdlg(prompt,dlg_title,num_lines,defaultans)));
end
if numElectrodes==35; numElectrodes=32; end %Disregard eventual AUX channels

if ~isfield(recInfo,'channelMap') 
    disp({'missing channelMap' ; 'delete old probe files then reexport data'})
    return
% 
%     disp(mfilename('fullpath'));
%     disp('assuming channels have been remapped already')
%     recInfo.channelMap = 1:numElectrodes;
end

%% define sampling rate
if isfield(recInfo,'samplingRate')
    samplingRate=recInfo.samplingRate;
else
    prompt = {'Enter the recording sampling rate'};
    dlg_title = 'Define sampling rate'; num_lines = 1; defaultans = {'30000'};
    samplingRate = str2double(cell2mat(inputdlg(prompt,dlg_title,num_lines,defaultans)));
end
    
%% Load recording traces
if false % too heavy for long recordings
    recDataFile=cellfun(@(flnm) contains(flnm,'rec.'),allDataFiles);
    traces = memmapfile(allDataFiles{recDataFile},'Format','int16');
    allTraces=double(traces.Data);
    recDuration=int64(length(allTraces)/numElectrodes);
    try
        allTraces=reshape(allTraces,[numElectrodes recDuration]);
    catch
        allTraces=reshape(allTraces',[recDuration numElectrodes]);
    end
    %   %alternatively (equivalent):
    %     traceFile = fopen(allDataFiles{recDataFile}, 'r');
    %     allTraces = fread(traceFile,[numElectrodes,Inf],'int16');
    %     fclose(traceFile);
    
    % remap traces
    allTraces=allTraces(recInfo.channelMap,:);
    

    
    filterTraces=true; %Might change that in case traces have already been filtered
    %% Filter traces if needed
    if filterTraces == true
        preprocOption={'CAR','all'};
        allTraces=PreProcData(allTraces,samplingRate,preprocOption);
        % allTraces=FilterTrace(allTraces,samplingRate);
    end
% figure; hold on;
% for chNum=1:16
%     plot(allTraces(chNum,1:6000)+(chNum-1)*max(max(allTraces(:,1:6000)))*2,'k')
% end
else
    allTraces=[];
end

%% Load spike data 
spikeDataFile=cellfun(@(flnm) contains(flnm,'spikes'),allDataFiles);
sortDir=fullfile(recInfo.dirName(1:end-5),'SpikeSorting',recInfo.baseName,'kilosort3'); %if importing from KS3 directly
spikes=LoadSpikeData(allDataFiles{spikeDataFile},[],sortDir);
% check information
if isfield(spikes,'samplingRate') 
    if isempty(spikes.samplingRate)
        spikes.samplingRate=samplingRate;
    elseif spikes.samplingRate ~= samplingRate
        disp(mfilename('fullpath'));
        disp('There''s an issue with sampling rate definition');
        return
    end
end

%% waveforms 
wfDataFile=cellfun(@(flnm) contains(flnm,'_wF'),allDataFiles);
if any(wfDataFile) 
    load(allDataFiles{wfDataFile});
% figure;
% hold on 
% plot(mean(waveForms(3).spikesFilt(:,2,:),3))
% plot(mean(spikes.waveforms(spikes.unitID==3,:)))
spikes.wF=waveForms;
end

%% Add voltage scaling factor
if ~isfield(spikes,'bitResolution')
    if isfield(recInfo,'bitResolution')
        spikes.bitResolution=recInfo.bitResolution;
    elseif isfield(recInfo,'sys')
        if strcmp(recInfo.sys,'OpenEphys'); spikes.bitResolution=0.195; %for Open Ephys
        elseif strcmp(recInfo.sys,'Blackrock'); spikes.bitResolution=0.25; %for BlackRock
        end
    end
end

%% Recording start time (may not be 0, e.g., some Intan / Open-Ephys)
if exist('recInfo','var') && isfield(recInfo,'recordingStartTime')
    startTime=double(recInfo.recordingStartTime);
else
    startTime=0; %well, make sure time indices are properly aligned
end

%% Read video frame times 
videoFrameTimeFile=cellfun(@(flnm) contains(flnm,'vSyncTTLs'),allDataFiles);
if any(videoFrameTimeFile)
    syncFile = fopen(allDataFiles{videoFrameTimeFile}, 'r');
    vFrameTimes = fread(syncFile,'single');%'int32' % VideoFrameTimes: was fread(fid,[2,Inf],'double'); Adjust export
    fclose(syncFile);
else % csv file from Bonsai
    vFrameTimes=ReadVideoFrameTimes;
    vFrameTimes=vFrameTimes.TTLTimes;
end
% remove recording start clock time
vidTimes=vFrameTimes-startTime;
if spikes.times(end) > size(allTraces,2)
    spikes.times=spikes.times-startTime;
end

%% Load other TTLs
TTLFile=cellfun(@(flnm) contains(flnm,{'_TTLs','_trialTTLs','_optoTTLs'}),allDataFiles);
if any(TTLFile)
    pulseFile = fopen(allDataFiles{TTLFile}, 'r');
%     TTLTimes = fread(pulseFile,'single'); % files recorded with only
%     rising phase of TTL (<2021) 
    TTLTimes = fread(pulseFile,[2,Inf],'single'); % 
    fclose(pulseFile);
else
    TTLTimes=[];
end
if spikes.times(end) > size(allTraces,2)
    TTLTimes=TTLTimes-startTime;
end

%% Import whisker tracking data
if ~any(cellfun(@(flnm) contains(flnm,'wMeasurements'),allDataFiles))
        % run ConvertWhiskerData to get those files. Should already be
        % done at this point, though.
%         ConvertWhiskerData;
%         dirListing=dir(startingDir);
end
whiskerTrackingFiles=cellfun(@(flnm) contains(flnm,'wMeasurements'),allDataFiles);
if any(whiskerTrackingFiles)
        whiskerTrackingData=load(allDataFiles{whiskerTrackingFiles});
%     whiskerTrackingData=load(dirListing(cellfun(@(flnm) contains(flnm,'wMeasurements'),...
%         {dirListing.name})).name);
%     whiskerTrackingData.velocity=load(dirListing(cellfun(@(flnm) contains(flnm,'whiskervelocity'),...
%         {dirListing.name})).name);
%     whiskerTrackingData.phase=load(dirListing(cellfun(@(flnm) contains(flnm,'whiskerphase'),...
%         {dirListing.name})).name);
else
    whiskerTrackingData=[];
end

recInfo.SRratio=spikes.samplingRate; %/whiskerTrackingData.samplingRate;

%% Load other data
flowsensorFiles=cellfun(@(flnm) contains(flnm,'_fs.'),allDataFiles);
if any(flowsensorFiles)
    fsData = memmapfile(allDataFiles{flowsensorFiles},'Format','int16');
    if isfield(fsData,'Data')
        fsData=fsData.Data;
    else
        fsData=[];
    end
    %     fsData=smooth(single(fsData),100); %should be done already
else
    fsData=[];
end

rotaryencoderFiles=cellfun(@(flnm) contains(flnm,'_re.'),allDataFiles);
if any(rotaryencoderFiles)
    reData = memmapfile(allDataFiles{rotaryencoderFiles},'Format','int16');
    if isfield(reData,'Data')
        reData=reData.Data;
    else
        reData=[];
    end
else
    reData=[];
end

%% Load trial data
trialsFile=cellfun(@(flnm) contains(flnm,'trial'),allDataFiles);
if any(trialsFile)
    % four columns:
    % trial_idx	repetition_idx	distCondition_idx	curr_distance
    trials = readmatrix(allDataFiles{trialsFile});
    trials=table(trials(:,1),trials(:,2),trials(:,3),trials(:,4),...
        'VariableNames',{'trial_idx';'repetition_idx';'distCondition_idx';'curr_distance'});
else
    trials=[];
end

%% Data integrity checks 
% Check video frame num vs TTLs if difference seems too big here
% if isfield(recInfo,'export')
%     videoSyncFile=fullfile(recInfo.export.directory,recInfo.export.vSync);
% else
%     videoSyncFileLoc=cellfun(@(flnm) contains(flnm,'_VideoSyncFilesLoc'),allDataFiles);
%     fileID = fopen(allDataFiles{videoSyncFileLoc}, 'r');
%     delimiter = {''};formatSpec = '%s%[^\n\r]';
%     fileLoc = textscan(fileID, formatSpec, 'Delimiter', delimiter,...
%         'TextType', 'string',  'ReturnOnError', false);
%     fclose(fileID);
%     % whiskerDataFile=regexp(fileLoc{1}(1),'(?<=whiskerDataFile\s+=\s)\S+$','match','once');
%     videoSyncFile=regexp(fileLoc{1}(2),'(?<=videoSyncFile\s+=\s)\S+$','match','once');
% end
% initDirListing=dir(recInfo.dirName);
% timestampFilesIndex=find(cellfun(@(fileName) contains(fileName,'HSCamFrameTime.csv'),...
%     {initDirListing.name},'UniformOutput', true));
% timestampFile=cellfun(@(fileName) contains(fileName,recInfo.sessionName),...
%     {initDirListing(timestampFilesIndex).name},'UniformOutput', true);
% videoTimestampFile=initDirListing(timestampFilesIndex(timestampFile)).name;
% % read timestamps
% videoTimestamps=readtable(fullfile(recInfo.dirName,videoTimestampFile));
% videoFileName=fullfile(recInfo.dirName,recInfo.likelyVideoFile);
% videoData = py.cv2.VideoCapture(videoFileName);
% numFrames=videoData.get(py.cv2.CAP_PROP_FRAME_COUNT)
% numTimeStamps=size(videoTimestamps,1)
% numTTLs=numel(vFrameTimes)

% Adjust frame times to frame number
try
[whiskerTrackingData,vidTimes]=AdjustFrameNumFrameTimes(whiskerTrackingData,...
    vidTimes,whiskerTrackingData.samplingRate);
catch
    disp('whisker tracking data incorrect or missing')
    whiskerTrackingData.whiskers=[];
    whiskerTrackingData.samplingRate=[];
end
    
% keep info about video time window
recInfo.vTimeLimits = [vidTimes(1) vidTimes(end)];

%% Sync ephys and behavior (video)
syncCut=false;
if syncCut
    % Cut down ephys traces to video time window
    allTraces=allTraces(:,int32(vidTimes(1)*recInfo.SRratio:vidTimes(end)*recInfo.SRratio));
    % Same for spikes
    spikeReIndex=spikes.times>=vidTimes(1)*recInfo.SRratio &...
                 spikes.times<=vidTimes(end)*recInfo.SRratio;
    spkFld=fieldnames(spikes);
    for spkFldNum=1:numel(spkFld)
        try spikes.(spkFld{spkFldNum})=spikes.(spkFld{spkFldNum})(spikeReIndex,:,:);catch; end
    end %was spikeReIndex,:
    %same for TTLs (in s resolution)
    TTLReIndex=TTLTimes(1,:)>=vidTimes(1) &...
                TTLTimes(1,:)<=vidTimes(end);
    TTLTimes=TTLTimes(:,TTLReIndex);
    % re-set spike times. TTLs and video frame times
    spikes.times=int32(spikes.times)-vidTimes(1)*recInfo.SRratio; % spikes.times become uint32 when loaded from _spike file
    TTLTimes=TTLTimes-double(vidTimes(1));
    vidTimes=vidTimes-vidTimes(1);
end

%% convert spike times to seconds
spikes.times = single(spikes.times)/spikes.samplingRate;

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% group data in structure
ephys=struct('traces',allTraces,'spikes',spikes,'recInfo',recInfo);
behav=struct('whiskers',whiskerTrackingData.whiskers,...
    'whiskerTrackingData',rmfield(whiskerTrackingData,'whiskers'),'vidTimes',vidTimes,...
    'breathing',fsData,'wheel',reData);
pulses=struct('TTLTimes',TTLTimes);
if size(TTLTimes,1)>1; pulses.duration=mode(diff(TTLTimes)); end
cd(startingDir);

end
%% sanity check plots
% %do plot pre and post sync
% figure; hold on 
% timeLine=0:size(allTraces,2)/recInfo.SRratio;
% % plot ephys trace
% plot(timeLine,allTraces(1,1:recInfo.SRratio:numel(timeLine)*recInfo.SRratio))
% % plot spikes
% % convert spikes times (behavior traces are already in seconds)
% % spikes.times  = single(spikes.times)/spikes.samplingRate;
% spikeRasters=EphysFun.MakeRasters(spikes.times,spikes.unitID,1); %...
% %     spikes.samplingRate,int32(numel(timeLine)*recInfo.SRratio));
% EphysFun.PlotRaster(spikeRasters(2,:))
% % plot behavior trace
% wAngle=whiskerTrackingData.whiskers.angle;
% wAngle(isnan(wAngle))=nanmean(wAngle);
% timeLine=vidTimes(1)*1000:vidTimes(end)*1000;
% plot(timeLine,wAngle(1:numel(timeLine)));









































