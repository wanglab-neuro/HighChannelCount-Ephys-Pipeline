% Load data
directory = 'D:\Jaehong\RAm_PreBotC_02\RAm_PreBotC_02_008'; 
session = Session(directory);

% Get raw data recording node 
node = session.recordNodes{1,1};
recording=node.recordings{1,1};
recording.continuous.keys();

% Get data from AP data stream
APData=recording.continuous('Neuropix-PXI-100.ProbeA-AP');

% Get sampling rate
Fs=APData.metadata.sampleRate;

% Get the data type of the AP data stream
dataType = class(APData.samples);

% Plot 10 seconds of data of the selected channels, each trace shifted by enough spacing not to overlap
selectedChannels=[44;46];
traceOffset = 0;

figure('Name','Raw AP Data', 'Color', 'w', 'Position', [500 100 1000 800])
hold on
for traceIdx=1:length(selectedChannels)
    % plot each trace then adjust offset value to shift the next trace
    traceH(traceIdx) = plot(APData.timestamps(1:10*Fs),APData.samples(selectedChannels(traceIdx),1:10*Fs)+traceOffset);
    traceOffset = traceOffset + max(APData.samples(selectedChannels(traceIdx),1:10*Fs))-min(APData.samples(selectedChannels(traceIdx),1:10*Fs));
end
% Show only Y ticks labels for traces and set to channel number
for traceIdx=1:length(selectedChannels)
    yticks(traceIdx) = traceH(traceIdx).YData(1);
    yticklabels{traceIdx} = num2str(selectedChannels(traceIdx));
end
set(gca,'YTick',yticks,'YTickLabel',yticklabels)
set(gca,'YDir','reverse')
xlabel('Time (s)')
ylabel('Channel #')
title('Raw AP Data')