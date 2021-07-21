function [data,rec,spikes,TTLs]=LoadEphys_Binary(dName,fName)
wb = waitbar( 0, 'Reading Data File...' );

spikes=struct('clusters',[],'electrodes',[],'spikeTimes',[],'waveForms',[],'metadata',[]);
rec.dirName=dName;
rec.fileName=fName;

if contains(fName,'.bin')
    %% Binary file (e.g., from Intan)
    prompt = {'Enter number of recorded channels:'};
    title = 'Channel list';
    dims = [1 32];
    definput = {'1'};
    rec.numRecChan = str2double(cell2mat(inputdlg(prompt,title,dims,definput)));
    %             rec.numRecChan=1:32; % need to ask user
    traces = memmapfile(fullfile(dName,fName),'Format','int16');
    data=traces.Data;
    if ~logical(mod(length(data),8)) % 8 analog channels
        rec.dur=int32(length(data)/8);
        data=reshape(data,[8 rec.dur]);
        data=data(1:rec.numRecChan,:);
    elseif ~logical(mod(length(data),numel(rec.numRecChan))) %presumed single channel
        rec.dur=int32(length(data)/(numel(rec.numRecChan)));
        data=reshape(data,[numel(rec.numRecChan) rec.dur]);
        data=data(1:rec.numRecChan,:);
    else
        disp('unexpected number of samples. Abort')
        return
    end
    if strcmp(fName,'v.bin') && exist(fullfile(dName,'ts.bin'),'file')
        rec.sys='Intan';
        % load timestamps
        sampleTimes=memmapfile(fullfile(dName,'ts.bin'),'Format','int64');
        rec.timeStamps=sampleTimes.Data;
        rec.recordingStartTime=rec.timeStamps(1);
        rec.samplingRate=30000; % SampleRateString="30.0 kS/s" Duh
        rec.bitResolution=0.195;
        FileInfo = dir(fName);
        rec.data = FileInfo.date;
    end
    spikes=[];
    
    %%% TTLs
    waitbar( 0.5, wb, 'getting TTL times and structure');
    TTLs = memmapfile(fullfile(cd,'ttl.bin'),'Offset',14,'Format','int8');
    TTLs = TTLs.Data(TTLs.Data~=0);
    figure; plot((TTLs(1:300000)))
    figure; plot(diff(TTLs(1:300000)))
    sum(diff(TTLs)==1)
    
else
    %% dat format binary file (e.g., exported data or Open Ephys binary)
    % need to know how many channels
    try
        rec = readOpenEphysXMLSettings(['..' filesep '..' filesep ...
            '..' filesep '..' filesep 'settings.xml']);
        ephysChannelsIdx=cellfun(@(x) str2double(x), rec.signals.channelInfo.channelGain)>0.1;
        rec.numRecChan=rec.signals.channelInfo.channelNumber(ephysChannelsIdx)+1;
        if isfield(rec.signals.channelInfo,'Mapping')
            rec.channelMapping=rec.signals.channelInfo.Mapping(ephysChannelsIdx);
        else %no mapping module
            rec.channelMapping=rec.signals.channelInfo.channelNumber(ephysChannelsIdx);
        end
        rec.date=rec.setupinfo.date;
        rec.samplingRate=30000; % SampleRateString="30.0 kS/s" Duh
        rec.bitResolution=0.195; %(2.45 V)/(2^16)  =  37.4 ?V.  amplifier  gain  of  192 -> 0.195 ?V
        rec.sys='OpenEphys';
        % load timestamps
        rec.timeStamps=readNPY('timestamps.npy');
        rec.recordingStartTime=rec.timeStamps(1); % should be the same as start time in sync_messages.txt
    catch
        prompt = {'Enter number of recorded channels:'};
        title = 'Channel list';
        dims = [1 32];
        definput = {'1:32'};
        rec.numRecChan = str2double(cell2mat(inputdlg(prompt,title,dims,definput)));
        %             rec.numRecChan=1:32; % need to ask user
        rec.date='';
        rec.samplingRate=30000;
        rec.bitResolution=0.195; %assuming Intan / OpenEphys
        rec.sys='';
    end
    traces = memmapfile(fullfile(dName,fName),'Format','int16');
    data=traces.Data;
    if ~logical(mod(length(data),numel(rec.numRecChan)))
        rec.dur=int32(length(data)/(numel(rec.numRecChan)));
        data=reshape(data,[numel(rec.numRecChan) rec.dur]);
    elseif ~logical(mod(length(data),numel(rec.numRecChan)+3)) %AUX channels in data array
        rec.dur=int32(length(data)/(numel(rec.numRecChan)+3));
        data=reshape(data,[numel(rec.numRecChan)+3 rec.dur]);
    else
        disp('unexpected number of samples. Abort')
        return
    end
    if numel(rec.numRecChan)==1
        data=data(1:rec.numRecChan,:);
    else
        data=data(rec.numRecChan,:);
    end
    %% get spike data
    try
        %             cd(['..' filesep '..' filesep ])
        %             cd spikes
        spikeFiles = cellfun(@(fileFormat) dir(['..' filesep '..' filesep 'spikes'...
            filesep '**' filesep fileFormat]),...
            {'*.npy'},'UniformOutput', false);
        clusFIdx=cellfun(@(x) contains(x,'spike_clusters'), {spikeFiles{1, 1}.name});
        spikes.clusters=readNPY(fullfile(spikeFiles{1, 1}(clusFIdx).folder,...
            spikeFiles{1, 1}(clusFIdx).name));
        electrodeFIdx=cellfun(@(x) contains(x,'spike_electrode'), {spikeFiles{1, 1}.name});
        spikes.electrodes=readNPY(fullfile(spikeFiles{1, 1}(electrodeFIdx).folder,...
            spikeFiles{1, 1}(electrodeFIdx).name));
        spikeTimeFIdx=cellfun(@(x) contains(x,'spike_times'), {spikeFiles{1, 1}.name});
        spikes.spikeTimes=readNPY(fullfile(spikeFiles{1, 1}(spikeTimeFIdx).folder,...
            spikeFiles{1, 1}(spikeTimeFIdx).name));
        waveformsFIdx=cellfun(@(x) contains(x,'spike_waveforms'), {spikeFiles{1, 1}.name});
        spikes.waveForms=readNPY(fullfile(spikeFiles{1, 1}(waveformsFIdx).folder,...
            spikeFiles{1, 1}(waveformsFIdx).name));
        metadataFIdx=cellfun(@(x) contains(x,'metadata'), {spikeFiles{1, 1}.name});
        spikes.metadata=readNPY(fullfile(spikeFiles{1, 1}(metadataFIdx).folder,...
            spikeFiles{1, 1}(metadataFIdx).name));
    catch
    end
    
    %%%% TTLs ??
    TTLs=struct('start',[],'end',[],'interval',[],'sampleRate',[],'continuous',[]);
end