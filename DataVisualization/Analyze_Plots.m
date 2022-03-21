%% Plots
% At this point, data should be processed
clearvars;

%% First, get data
dirFiles=dir;
processedDataFiles=cellfun(@(x) contains(x,'processedData'), {dirFiles.name});
if any(processedDataFiles)
    load(fullfile(dirFiles(processedDataFiles).folder,dirFiles(processedDataFiles).name));
    if ~isfield(ephys,'traces')
        ephys.traces = fileDatastore(dirFiles(cellfun(@(x) contains(x,'traces'),{dirFiles.name})).name,...
            'ReadFcn',@ReadRecTraces, 'FileExtensions',{'.bin','.dat'});
        %         traceFile = fopen(dirFiles(cellfun(@(x) contains(x,'traces'),{dirFiles.name})).name, 'r');
        %         ephys.traces = fread(traceFile,[ephys.recInfo.numRecChan,Inf],'single');
        %         fclose(traceFile);
    end
    %% if needed, load traces and save file here
    if ~exist('traces','var')
        traces=ephys.traces; varInfo=whos('traces');
        switch varInfo.class
            case 'matlab.io.datastore.FileDatastore' % datastore
                traces = read(traces);
            case 'memmapfile'
                traces = double(traces.Data); %memory map
        end
        traces=EphysFun.OrderTraces(traces, ephys.recInfo.numRecChan,...
            ephys.recInfo.dataPoints, ephys.recInfo.channelMap);
        traces=EphysFun.FilterTraces(traces,ephys.recInfo.samplingRate);
        save(fullfile(dirFiles(processedDataFiles).folder,dirFiles(processedDataFiles).name),...
            'traces','-append')
    else
        ephys.traces=traces;
        clearvars('traces');
    end
end

if ~exist('ephys','var')
    [ephys,behav,pulses,trials,targetDir]=Analyze_LoadData;
    cd(targetDir);
    
%     if numel(behav.whiskerTrackingData.bestWhisker)>1
%         behav.whiskerTrackingData.bestWhisker=behav.whiskerTrackingData.bestWhisker(1);
%     end
    save([ephys.recInfo.sessionName '_processedData'],'ephys','behav','pulses','-v7.3');
end

%% whisking data
% bWhisk=behav.whiskerTrackingData.keepWhiskerIDs==behav.whiskerTrackingData.bestWhisker; %best whisker
whiskers=behav.whiskers;
bWhisk=find([whiskers.bestWhisker]);

%% compute whisking frequency (different from instantaneous frequency
for wNum=1:numel(bWhisk)
    whisksIdx = bwconncomp(diff(whiskers(bWhisk(wNum)).phase)>0);
    peakIdx = zeros(1,length(whiskers(bWhisk(wNum)).velocity));
    peakIdx(cellfun(@(whisk) whisk(1), whisksIdx.PixelIdxList))=1;
    whiskers(bWhisk(wNum)).frequency=movsum(peakIdx,behav.whiskerTrackingData.samplingRate);
end

%% other behavior data
if ~isempty(behav.breathing)
    breathing.data=double(behav.breathing');
    breathing.data=breathing.data*(range(whiskers(bWhisk(1)).setPoint)/range(breathing.data));
    breathing.ts=linspace(0,ephys.recInfo.duration_sec,numel(behav.breathing));
else
    breathing=[];
end

%% compute rasters
% aim for same length for ephys traces and behavior data
[ephys.rasters,unitList]=EphysFun.MakeRasters(ephys.spikes.times,ephys.spikes.unitID,...
    1,size(whiskers(bWhisk(1)).angle,2)); %int32(size(ephys.traces,2)/ephys.spikes.samplingRate*1000));

%% compute spike density functions
ephys.spikeRate=EphysFun.MakeSDF(ephys.rasters);

%% create timeline
ephys.timestamps = 0:0.001:ephys.recInfo.duration_sec;

%% define figure colormap
cmap=lines;cmap=[cmap(1:7,:);(lines+flipud(copper))/2;autumn];

%% make sure behavior and spike traces have same length
cropTraces = false;
if cropTraces
    if size(ephys.spikeRate,2)~=numel(whiskers(bWhisk(1)).angle)
        % check what's up
        if size(ephys.spikeRate,2)<size(whiskers(bWhisk(1)).angle,2)
            whiskers.angle=whiskers.angle(:,1:size(ephys.spikeRate,2));
            whiskers.velocity=whiskers.velocity(:,1:size(ephys.spikeRate,2));
            whiskers.phase=whiskers.phase(:,1:size(ephys.spikeRate,2));
            whiskers.amplitude=whiskers.amplitude(:,1:size(ephys.spikeRate,2));
            whiskers.frequency=whiskerFrequency(:,1:size(ephys.spikeRate,2));
            whiskers.setPoint=whiskers.setPoint(:,1:size(ephys.spikeRate,2));
        else
            ephys.spikeRate=ephys.spikeRate(:,1:length(whiskers.angle));
            ephys.rasters=ephys.rasters(:,1:length(whiskers.angle));
        end
    end
end

%% whisking epochs (based on first trace, if multiple whisker tracked)
ampThd=18; %12; %18 %amplitude threshold
freqThld=1; %frequency threshold
minBoutDur=1000; %500; % 1000 % minimum whisking bout duration: 1s
whiskingEpochs=cell(numel(bWhisk),1);
for wNum=1:numel(bWhisk)
    whiskingEpochs{wNum}=WhiskingFun.FindWhiskingEpochs(...
        whiskers(bWhisk(wNum)).amplitude,whiskers(bWhisk(wNum)).frequency,...
        ampThd, freqThld, minBoutDur);
    whiskingEpochs{wNum}(isnan(whiskingEpochs{wNum}))=false; %just in case
    whiskingEpochsList=bwconncomp(whiskingEpochs{wNum});
    [~,wBoutDurSort]=sort(cellfun(@length,whiskingEpochsList.PixelIdxList),'descend');
    whiskingEpochsList.PixelIdxListSorted=whiskingEpochsList.PixelIdxList(wBoutDurSort);
end

if false
    figure; hold on;
    for wNum=1:numel(bWhisk)
    plot(whiskers(bWhisk(1)).angle);
    plot(whiskingEpochs{wNum}*nanstd(whiskers(bWhisk(1)).angle)+nanmean(whiskers(bWhisk(1)).angle))
    end
    % plot(whisker.phase*nanstd(whisker.angle)/2+nanmean(whisker.angle));
end

%% decide which units to keep:
keepWhat = 'all';
switch keepWhat
    case 'mostFreq' %most frequent units
        % mostFrqUnits=EphysFun.FindBestUnits(ephys.spikes.unitID,1);%keep ones over x% spikes
        %most frequent units during whisking periods
        reconstrUnits=ephys.rasters(:,whiskingEpochs{wNum}).*(1:size(ephys.rasters,1))';
        reconstrUnits=reshape(reconstrUnits,[1,size(reconstrUnits,1)*size(reconstrUnits,2)]);
        reconstrUnits=reconstrUnits(reconstrUnits>0);
        mostFrqUnits=EphysFun.FindBestUnits(reconstrUnits,1);
        keepUnits=ismember(unitList,mostFrqUnits);
        keepTraces=unique(ephys.spikes.preferredElectrode(ismember(ephys.spikes.unitID,unitList(keepUnits))));
        ephys.selectedUnits=find(keepUnits);
    case 'all' %all of them
        ephys.selectedUnits=unitList; %all units
    case 'SU' % only Single units
        [unitQuality,RPVIndex]=SSQualityMetrics(ephys.spikes);
        unitQuality=[unique(double(ephys.spikes.unitID)),unitQuality];
        unitIdx=ismember(ephys.spikes.unitID,unitQuality(unitQuality(:,2)>0.6,1));
        unitQuality(unitQuality(:,2)>0.6,3)=hist(double(ephys.spikes.unitID(unitIdx)),...
            unique(double(ephys.spikes.unitID(unitIdx))))/sum(unitIdx);
        qualityUnits=unitQuality(unitQuality(:,2)>0.6 & unitQuality(:,3)>0.01,:);
        ephys.selectedUnits=qualityUnits(:,1);
    case 'handPick'
        % add manually, e.g.,
        % ephys.selectedUnits=[ephys.selectedUnits;54]; 1;2;19];
        % set numbers
        % ephys.selectedUnits= [12;15;7;11];
end

%% organize selectedUnits by depth
if size(ephys.recInfo.probeGeometry,2)>size(ephys.recInfo.probeGeometry,1)
    ephys.recInfo.probeGeometry=ephys.recInfo.probeGeometry';
end
unitLoc=nan(numel(ephys.selectedUnits),2);
for unitNum=1:numel(ephys.selectedUnits)
    unitID=ephys.selectedUnits(unitNum);
    %     [foo,faa]=hist(double(ephys.spikes.preferredElectrode(ephys.spikes.unitID==unitID)),...
    %         double(unique(ephys.spikes.preferredElectrode(ephys.spikes.unitID==unitID))))
    prefElec=mode(ephys.spikes.preferredElectrode(ephys.spikes.unitID==unitID));
    unitLoc(unitNum,:)=ephys.recInfo.probeGeometry(prefElec,:);
end
[~,unitDepthOrder]=sort(unitLoc(:,2));
ephys.selectedUnits=ephys.selectedUnits(unitDepthOrder);
ephys.unitCoordinates=unitLoc(unitDepthOrder,:);

%% whisking mode
if false
    % Four main modes:
    % foveal: high frequency > 10Hz, medium amplitude >25 <35, high setpoint/angular values >70 at start of whisk
    % exploratory: lower frequency < 10, high amplitude >35, medium setpoint/angular values ?
    % resting: lower frequency < 10Hz, low/medium amplitude <25, low setpoint/angular values <60
    % twiches: high frequency > 25Hz, low amplitude <10, low setpoint/angular values <70 at start of whisk
    whiskingEpochs=WhiskingFun.FindWhiskingModes(whiskers(bWhisk).angle,whiskers(bWhisk).velocity,whiskers(bWhisk).amplitude,whiskerFrequency,whiskers(bWhisk).setPoint);
    figure; hold on
    plot(whiskers(bWhisk).angle)
    for wModeNum=1:numel(whiskingEpochs)
        whiskModeVals=nan(size(whiskers(bWhisk).angle));
        whiskModeVals(whiskingEpochs(wModeNum).index)=whiskers(bWhisk).angle(whiskingEpochs(wModeNum).index);
        plot(whiskModeVals);
    end
    legend('angle',whiskingEpochs.type)
end

%% Overview plot
opt.zoomin=false;
opt.saveFig=false;
opt.xpType='GFE3'; %'asymmetry' %'default'
NBC_Plots_Overview(whiskers(bWhisk),whiskingEpochs,breathing,ephys,pulses.TTLTimes,opt);

%% Check Phototagging summary
% ephys.selectedUnits=[60 23]; 10; 2; 37; %12;
if ~isfield(pulses,'duration'); pulses.duration=0.010; end %for ChRmine pulses.duration=0.1
PhotoTagPlots(ephys,pulses);
% PTunits=[12,26,37];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% WARNING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Any tuning computation has to be done outside of stimulation periods
for wNum=1:numel(bWhisk)
    pulseMask=false(1,size(whiskers(bWhisk(wNum)).angle,2));
    pulseMask((round(pulses.TTLTimes(1)*1000):round(pulses.TTLTimes(end)*1000))-round(behav.vidTimes(1)*1000))=true;
    wEpochMask.behav=whiskingEpochs{wNum};wEpochMask.behav(pulseMask)=false;
    wEpochMask.ephys=false(1,size(ephys.rasters,2));

    ephysMaskIdx=(0:numel(wEpochMask.behav)-1)+round(behav.vidTimes(1)*1000);
    wEpochMask.ephys(ephysMaskIdx)=wEpochMask.behav;

    %% Phase tuning - Individual plots
    phaseTuning=NBC_Plots_PhaseTuning(whiskers(bWhisk(wNum)).angle,whiskers(bWhisk(wNum)).phase,...
        ephys,wEpochMask,'whisking',false,false); %whiskingEpochs_m %ephys.spikeRate

    % Set point phase tuning
    setpointPhase=WhiskingFun.ComputePhase(whiskers(bWhisk(wNum)).setPoint,1000,[],'setpoint');
    NBC_Plots_PhaseTuning(whiskers(bWhisk(wNum)).setPoint,setpointPhase,ephys,wEpochMask,...
        'setpoint oscillation',false,false);
end
% Breathing phase tuning
% manual masking:
% whiskingEpochs_m = false(1,size(whiskers(bWhisk).angle,2)); whiskingEpochs_m(4*10^5:5*10^5)=true;
breathingPhase=WhiskingFun.ComputePhase(smooth(breathing.data,1000)',1000,[],'breathing');
NBC_Plots_PhaseTuning(breathing.data,breathingPhase,ephys,wEpochMask,...
    'breathing oscillation',false,false);


