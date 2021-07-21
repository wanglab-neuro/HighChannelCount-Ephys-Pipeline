function [data,rec,spikes]=LoadEphys_Blackrock(fname)
tic
data = openNSx(fullfile(cd,fname));

if iscell(data.Data) && size(data.Data,2)>1 %gets splitted into two cells sometimes for no reason
    data.Data=[data.Data{:}]; %remove extra data.Data=data.Data(:,1:63068290);
end

% Get channel info and spike data
eventData=openNEV([cd filesep fname(1:end-3) 'nev']);
spikes.clusters=eventData.Data.Spikes.Unit;
spikes.electrodes=eventData.Data.Spikes.Electrode;
spikes.spikeTimes=eventData.Data.Spikes.TimeStamp;
spikes.waveForms=eventData.Data.Spikes.Waveform;

if ~isfield(data,'ElectrodesInfo') %depend on file format version
    data=CatStruct(data,rmfield(eventData,{'Data','MetaTags'}));
end
%     analogData = openNSxNew([fname(1:end-1) '2']);
%get basic info about recording
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
