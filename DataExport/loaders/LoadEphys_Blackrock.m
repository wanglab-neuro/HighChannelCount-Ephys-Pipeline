function [data,rec,spikes,TTLs]=LoadEphys_Blackrock(dName,fName)

%% Blackrock data. File extension depends on sampling rate
%         500 S/s: Records at 500 samples/second. Saved as NS1 file.
%         1 kS/s: Records at 1k samples/second. Saved as NS2 file.
%         2 kS/s: Records at 2k samples/second. Saved as NS3 file.
%         10 kS/s: Records at 10k samples/second. Saved as NS4 file. e.g., TTLs
%         30 kS/s: Records at 30k samples/second. Saved as NS5 file.
%         Raw: Records the raw data at 30k samples/second. Saved as NS6 file.

wb = waitbar( 0, 'Reading Data File...' );
tic
data = openNSx(fullfile(cd,fName));

if iscell(data.Data) && size(data.Data,2)>1 %gets splitted into two cells sometimes for no reason
    data.Data=[data.Data{:}]; %remove extra data.Data=data.Data(:,1:63068290);
end

spikes=struct('clusters',[],'electrodes',[],'spikeTimes',[],'waveForms',[],'metadata',[]);

% Get channel info and spike data
eventData=openNEV([fName(1:end-3) 'nev']);
spikes.clusters=eventData.Data.Spikes.Unit;
spikes.electrodes=eventData.Data.Spikes.Electrode;
spikes.spikeTimes=eventData.Data.Spikes.TimeStamp;
spikes.waveForms=eventData.Data.Spikes.Waveform;

if ~isfield(data,'ElectrodesInfo') %depend on file format version
    data=CatStruct(data,rmfield(eventData,{'Data','MetaTags'}));
end
%     analogData = openNSxNew([fname(1:end-1) '2']);
%get basic info about recording
rec.dirName=dName;
rec.fileName=fName;
rec.duration_sec=data.MetaTags.DataDurationSec;
rec.dataPoints= data.MetaTags.DataPoints;
rec.samplingRate=data.MetaTags.SamplingFreq;
rec.bitResolution=0.25; % +/-8 mV @ 16-Bit => 16000/2^16 = 0.2441 uV
rec.chanID=data.MetaTags.ChannelID;
[~,rec.chanList]=sort(rec.chanID); [~,rec.chanList]=sort(rec.chanList);
if ~isfield(data.ElectrodesInfo,'Label') || ...
        (isfield(data.ElectrodesInfo,'Label') && ...
        ~sum(cellfun(@(x) contains(x,'ainp1'),{data.ElectrodesInfo.Label})))
    % maybe no Analog channels were recorded but caution: they may be
    % labeled as any digital channel. Check Connector banks
    analogChannels=cellfun(@(x) contains(x,'D'),{data.ElectrodesInfo.ConnectorBank});
    rec.chanID=rec.chanID(ismember(rec.chanList,find(~analogChannels)));
    data.Data=data.Data(ismember(rec.chanList,find(~analogChannels)),:);
end
rec.numRecChan=size(data.Data,1); %data.MetaTags.ChannelCount;  %number of raw data channels.
%         rec.date=[cell2mat(regexp(data.MetaTags.DateTime,'^.+\d(?= )','match'))...
%             '_' cell2mat(regexp(data.MetaTags.DateTime,'(?<= )\d.+','match'))];
%         rec.date=regexprep(rec.date,'\W','_');
rec.date=data.MetaTags.DateTime;
rec.start_time=datevec(data.MetaTags.DateTime);
if ~isempty(data.MetaTags.DateTimeRaw)
    rec.start_time=[rec.start_time(4:6),data.MetaTags.DateTimeRaw(end)];
else
    rec.start_time=[rec.start_time(4:6)];
end
% keep only raw data in data variable
data=data.Data;
disp(['took ' num2str(toc) ' seconds to load data']);
rec.sys='Blackrock';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% get TTL times and structure

waitbar( 0.5, wb, 'getting TTL times and structure');
TTLs=struct('channelType',[],'timeBase',[],'start',[],'end',[],'interval',[],...
    'TTLtimes',[],'samplingRate',[],'continuous',[]);

%% check NEV file first, even if NS file is in argument
% NEV files contain records of digital pin events, where TTL should be
% eventData=openNEV([fName(1:end-3), 'nev']);

samplingRate=double(eventData.MetaTags.SampleRes);
digInEvents=eventData.Data.SerialDigitalIO.UnparsedData;
digInTimes=double(eventData.Data.SerialDigitalIO.TimeStamp); %TimeStampSec i interval in ms?

%% find TTL detection type: rising only, or rising + falling
if mode(diff(digInTimes))> samplingRate/1000 % TTL timestamp > 1ms
    TTLtype = 'rise';
else
    TTLtype = 'rise&fall'; %this is a default assumption. If output gives half expected TTL number, correct that here
end

%% load TTLs
% Given 2 inputs in Port 0 and 1
% No input              => bin2dec('00') = 0
% input on Port 0 only  => bin2dec('10') = 2
% input on Port 1 only  => bin2dec('01') = 1
% input on both ports   => bin2dec('11') = 3

TTL_ID=logical(dec2bin(digInEvents)-'0');
if ~isempty(TTL_ID)
    TTLs=rmfield(TTLs,'continuous');%     clear TTLs;
    channelIDs=strsplit(deblank(eventData.IOLabels{1, 2}),'_');
    if size(TTL_ID,2)>size(channelIDs,2)
        %not enough labels in digital channel naming
        % Option 1 -> set extra channel names
        for digCh=size(channelIDs,2)+(1:size(TTL_ID,2)-size(channelIDs,2))
            channelIDs{digCh}=['DIGIN_' num2str(digCh)];
        end
    end
    for TTLChan=size(TTL_ID,2):-1:1 %Option 2: keep only the labeled channels -> size(TTL_ID,2)-size(channelIDs,2)+1
        TTLIdx=find(TTL_ID(:,TTLChan));
        if ~isempty(TTLIdx)
            switch TTLtype
                case 'rise'
                    %then need to define TTL duration
                    TTLdur= mode(diff(digInTimes(TTLIdx)))/2; % assuming 50% cycle - this is only to have an estimate for camera TTLs - not laser or trials
                    TTLdur= min([TTLdur samplingRate/1000]); % set upper boundary to a reasonable duration (1ms)
                    % remove TTLs instance shorter than that duration
                    TTLIdx=TTLIdx(~ismember(TTLIdx, find(diff(digInTimes(TTLIdx))<TTLdur)+1));
                case 'rise&fall'
                    TTLdur= mode(diff(digInTimes([TTLIdx; find([0; diff(TTL_ID(:,TTLChan))])])));
                    if TTLIdx(end)==numel(digInEvents)
                        TTLIdx=TTLIdx(1:end-1); %spurious event
                    end
            end
            try
                chNum=size(TTL_ID,2)-TTLChan+1;
                TTLs(chNum).channelType=channelIDs{chNum};
                TTLs(chNum).start=digInTimes(TTLIdx)'/samplingRate;
                TTLs(chNum).end=digInTimes(TTLIdx)'/samplingRate + (TTLdur/samplingRate);
                TTLs(chNum).interval=mode(diff(TTLs(chNum).start));
                TTLs(chNum).timeBase='s';
                TTLs(chNum).samplingRate=samplingRate;                
                TTLs(chNum).TTLtimes=digInTimes(TTLIdx);

%                 TTLs{size(TTL_ID,2)-TTLChan+1}=...
%                     struct('TTLtimes',digInTimes(TTLIdx)/sampleRate,...
%                     'samplingRate',1,...
%                     'start',digInTimes(TTLIdx)'/sampleRate,...
%                     'end',digInTimes(TTLIdx)'/sampleRate + (TTLdur/sampleRate));
                %ConvTTLtoTrials(digInTimes(TTLIdx),TTLdur,sampleRate);
            catch
                continue;
            end
        else
            continue;
        end
    end
    
elseif contains(fName,'.nev')
    %find which analog channel has inputs
    TTLChannel=cellfun(@(x) contains(x','ain'),{eventData.ElectrodesInfo.ElectrodeLabel}) & ...
        [eventData.ElectrodesInfo.DigitalFactor]>1000 & [eventData.ElectrodesInfo.HighThreshold]>0;
    if sum(TTLChannel)==0 %then assume TTL was AIN 1
        TTLChannel=cellfun(@(x) contains(x','ainp1'),{eventData.ElectrodesInfo.ElectrodeLabel}) & ...
            [eventData.ElectrodesInfo.DigitalFactor]>1000; %may be a proper label like "Camera"
    end
    
    TTLChannel=eventData.ElectrodesInfo(TTLChannel).ElectrodeID;
    TTL_times=eventData.Data.Spikes.TimeStamp(eventData.Data.Spikes.Electrode==TTLChannel);
    TTL_shapes=eventData.Data.Spikes.Waveform(:,eventData.Data.Spikes.Electrode==TTLChannel);
    artifactsIdx=median(TTL_shapes)<mean(median(TTL_shapes))/10;
    %             figure; plot(TTL_shapes(:,~artifactsIdx));
    TTLs.start=TTL_times(~artifactsIdx);
else % check analog channels in NS file
    if contains(fName,filesep)
        analogChannel = openNSx(fName);
    else
        try
            syncfName=strrep(fName,'ns6','ns4'); %'nev' ns4: analog channel recorded at 10kHz
            analogChannel = openNSx([cd filesep syncfName]);
        catch
            syncfName=strrep(fName,'ns6','ns2'); %ns2 -> TTL recorded at 1kHz (old setup)
            analogChannel = openNSx([cd filesep syncfName]);
        end
        %               analogChannel = openNEV([cd filesep syncfName]);
    end
    % openNEV returns struct('MetaTags',[], 'ElectrodesInfo', [], 'Data', []);
    % openNSx returns  struct('MetaTags',[],'Data',[], 'RawData', []);
    % in some other version, openNSx also returned 'ElectrodesInfo'
    %       %send sync TTL to AIN1, which is Channel 129. AIN2 is 130. AIN3 is 131
    TTLchannelIDs = [129, 130, 131];
    if any(ismember([analogChannel.MetaTags.ChannelID], TTLchannelIDs)) %check that it is present
        analogChannels=find(ismember([analogChannel.MetaTags.ChannelID], TTLchannelIDs));
        %         if sum(cellfun(@(x)
        %         contains(x,'ainp1'),{analogChannel.ElectrodesInfo.Label}));
        %             analogChannels=cellfun(@(x) contains(x,'ainp1'),{analogChannel.ElectrodesInfo.Label})
    elseif any(cellfun(@(x) contains(x,'D'),{analogChannel.ElectrodesInfo.ConnectorBank}))
        analogChannels=cellfun(@(x) contains(x,'D'),{analogChannel.ElectrodesInfo.ConnectorBank});
    end
    analogTTLTrace=analogChannel.Data(analogChannels,:); %send sync TTL to AINP1
    if ~isempty(analogTTLTrace) && ~iscell(analogTTLTrace)
        clear TTLs;
        for TTLChan=1:size(analogTTLTrace,1)
            [TTLtimes,TTLdur]=ContinuousToTTL(analogTTLTrace(TTLChan,:),analogChannel.MetaTags.SamplingFreq,'keepfirstonly');
            if ~isempty(TTLtimes)
                TTLs{TTLChan}=ConvTTLtoTrials(TTLtimes,TTLdur,analogChannel.MetaTags.SamplingFreq);
            end
        end
        if size(TTLs,2)==1
            TTLs=TTLs{1};
        end
    end
end

if any(cellfun(@isempty,{TTLs.channelType}))
    TTLs=AssignTTLs(TTLs);
end

close(wb);
