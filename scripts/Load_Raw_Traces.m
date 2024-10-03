% Script to load traces after spikeinterface preprocessing steps

filePath = '/mnt/md0/data/Vincent/whisker_asym/sc012/sc012_0119/sc012_0119_003/preprocessed'; % Path to the folder containing the recording traces
fileName = 'traces_cached_seg0.raw'

% Open the binary.json
fid = fopen(fullfile(filePath, 'binary.json'));
raw = fread(fid, inf, '*char');
fclose(fid);
raw = jsondecode(raw');

% Get information about the recording
channels = raw.channels;
nChannels = raw.nChannels;
dataType = raw.dtype;
nSamples = raw.nSamples;

% Load the traces
mmf = memmapfile(fileName, 'Format', {dataType, [nSamples, nChannels], 'x'});

% Get the traces
traces = mmf.Data;

