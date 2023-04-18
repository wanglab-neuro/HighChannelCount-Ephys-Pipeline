function Export_NPX_TTL(recDir,segNames)

if ~exist("recDir","var"); recDir=cd; end
[sessionDir,recordingName]=fileparts(recDir);

% sessionDir = 'D:\Vincent\Data\sc012\sc012_0120'; 
% sessionDir = 'D:\Vincent\Data\sc014\sc014_0325\';
% sessionDir = 'D:\Vincent\Data\sc014\sc014_0324\';

% recordingName = 'sc012_0120_001'; 
% recordingName = 'sc014_0325_001';
% recordingName = 'sc014_0324_001';

session = Session(fullfile(sessionDir, recordingName));
% session.show()

%% Get raw data recording node 
node = session.recordNodes{1,1};

%% Get video TTL data
if ~exist("segNames","var"); segNames=repmat({''},numel(node.recordings),1); end
% segNames={'baseline';'pokes';'stim';'stim';'stim'}; %'stim''wheelturn'

CamTS=cell(numel(node.recordings),2);
for segNum=1:numel(node.recordings)
    DAQ_TTLs=node.recordings{1,segNum}.ttlEvents('NI-DAQmx-109.PXIe-6341');
    CamTS{segNum,1}=segNames{segNum};
    CamTS{segNum,2}=DAQ_TTLs.timestamp(DAQ_TTLs.line==2);
    CamTS{segNum,2}=CamTS{segNum,2}(DAQ_TTLs.state(DAQ_TTLs.line==2));
end
disp(['Total number of frames is ' num2str(numel(vertcat(CamTS{:,2})))])

%% Export video TTLs

fileID = fopen(fullfile(sessionDir, [recordingName '_allsegments_vSyncTTLs.dat']),'w');
fwrite(fileID,vertcat(CamTS{:,2}),'single'); %'int32' %just save one single column
fclose(fileID);
for segNum=1:numel(node.recordings)
    fileID = fopen(fullfile(sessionDir, [recordingName '_' CamTS{segNum,1} '_vSyncTTLs.dat']),'w');
    fwrite(fileID,CamTS{segNum,2},'single'); %'int32' %just save one single column
    fclose(fileID);
end

%% Timestamps sanity checks

% AP_TTLs=node.recordings{1,segNum}.ttlEvents('Neuropix-PXI-100.ProbeA-AP');
% DAQ_sync_ts=DAQ_TTLs.timestamp(DAQ_TTLs.line==1);
% AP_sync_ts=AP_TTLs.timestamp(AP_TTLs.line==1);
% figure; plot(diff([DAQ_sync_ts,AP_sync_ts]'))

% DAQ_timeStamps=readNPY(fullfile(node.directory,...
%     '\experiment1\recording1\events\NI-DAQmx-109.PXIe-6341\TTL','timestamps.npy'));
% DAQ_line=readNPY(fullfile(node.directory,...
%     '\experiment1\recording1\events\NI-DAQmx-109.PXIe-6341\TTL','states.npy'));
% AP_timeStamps=readNPY(fullfile(node.directory,...
%     '\experiment1\recording1\events\Neuropix-PXI-100.ProbeA-AP\TTL','timestamps.npy'));

%% Get other recording info
recInfo=struct('baseName',[],'sampleRate',[],'numChannels',[],'startTimestamp',[],...
    'numSamples',[],'APstartTimestamp',[]);
for segNum=1:numel(node.recordings)
    AP_Data=node.recordings{1,segNum}.continuous('Neuropix-PXI-100.ProbeA-AP');
    % APData.timestamps(1)
    % TTLs.timestamp(1)
    segMetaData=AP_Data.metadata;
    recInfo(segNum).baseName=recordingName;
    recInfo(segNum).sampleRate=segMetaData.sampleRate;
    recInfo(segNum).numChannels=segMetaData.numChannels;
    recInfo(segNum).startTimestamp=segMetaData.startTimestamp;
    recInfo(segNum).numSamples=numel(AP_Data.sampleNumbers);
    recInfo(segNum).APstartTimestamp=AP_Data.timestamps(1);
end
recInfo=jsonencode(recInfo);
fileID = fopen(fullfile(sessionDir,[recordingName '.json']),'w');
    fprintf(fileID, recInfo);
fclose(fileID);