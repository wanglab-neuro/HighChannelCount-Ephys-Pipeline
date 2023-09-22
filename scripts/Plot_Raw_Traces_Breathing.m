% Load data
directory = 'D:\Jaehong\RAm_PreBotC_02\RAm_PreBotC_02_008';
session = Session(directory);

% Get raw data recording node
node = session.recordNodes{1,1};
recording=node.recordings{1,1};
recording.continuous.keys();

% Get data from AP data stream
APData=recording.continuous('Neuropix-PXI-100.ProbeA-AP');

% Get data from Analog channel 01
analogData=recording.continuous('NI-DAQmx-109.PXIe-6341');
breathingFlow=analogData.samples(1,:);

% Get sampling rates
AP_Fs=APData.metadata.sampleRate;
analog_Fs=analogData.metadata.sampleRate; %Should be the same

% Get the inspiration phase of the breathing signal
[breathingFlow, inspirationEpochs] = get_inspiration_epochs(breathingFlow,analog_Fs);

% Get the data type of the AP data stream
dataType = class(APData.samples);
breathingFlow = cast(breathingFlow,dataType);

% Plot 10 seconds of data of the selected channels, each trace shifted by enough spacing not to overlap
selectedChannels=[46];
traceOffset = 0;
clearvars yticklabels traceH
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
% keep only ytick that corresponds to the traces, assign labels
yticks=yticks(1:traceIdx);
yticklabels=yticklabels(1:traceIdx);
set(gca,'YTick',yticks,'YTickLabel',yticklabels)

% set(gca,'YTick',yticks,'YTickLabel',yticklabels)
set(gca,'YDir','reverse')
xlabel('Time (s)')
ylabel('Channel #')
title('Raw AP Data')

% % Overlay the inspiration epochs as color blocks
ylim=get(gca,'ylim');
heightDiff = ylim(2)-ylim(1);

areaH =  area(analogData.timestamps(1:10*Fs),ylim(1)*~inspirationEpochs(1:10*Fs), ylim(1), ...
        'FaceColor', [1 0.8 0], 'EdgeColor', 'none', 'ShowBaseLine', 'off', 'FaceAlpha', 0.5);

% set the area to the back
uistack(areaH,'bottom')

% area(analogData.timestamps(1:10*Fs),ylim(1)*inspirationPhase(1:10*Fs),'FaceColor', [1 1 0.8], 
% 'EdgeColor', 'none', 'ShowBaseLine', 'off', 'FaceAlpha', 0.5);
% set the area to the back
uistack(areaH,'bottom')

% Plot breathing flow for the same time period
yyaxis right
traceH(traceIdx+1)=plot(analogData.timestamps(1:10*Fs),breathingFlow(1:10*Fs)+traceOffset);
yticks(traceIdx+1) = traceH(traceIdx+1).YData(1);
set(traceH(traceIdx+1),'Color','k','linewidth',1.5)
% yticklabels{traceIdx+1} = 'Breathing Flow';
set(gca,'YColor','k'); %'YDir','reverse'
ylabel('Breathing Flow (AU) Inspiration Downward')

% Add legend for traceH and areaH
lgdH = legend(areaH,'Inspiration Epochs','Location','Best');
lgdH.Box = 'off';

function [breathingFlow, inspirationEpochs, breathingFlow_phase, breathingCycles] =...
    get_inspiration_epochs(breathingFlow,analog_Fs)
% Find the phase of the breathing signal

% First remove the DC component of the signal and low-pass filter below 10Hz
breathingFlow=breathingFlow-mean(breathingFlow);
[B,A]=butter(2,10/(analog_Fs/2),'low');
breathingFlow=filtfilt(B,A,double(breathingFlow));
% Then get the hilbert transform of the signal and the phase
breathingFlow_hilbert=hilbert(breathingFlow);
breathingFlow_phase=-angle(breathingFlow_hilbert);

% Find the inspiration epochs
breathingFlow_derivative=[diff(breathingFlow) 0];
inspirationEpochs=regionprops(breathingFlow_phase < 0 & breathingFlow_derivative<0,'Area','PixelIdxList');
inspirationEpochs={inspirationEpochs.PixelIdxList};
% Find the breathing cycles
breathingCycles = regionprops(breathingFlow_phase>0,'Area','PixelIdxList');
breathingCycles=cellfun(@(areaIdx) [areaIdx(1) areaIdx(end)],...
    {breathingCycles.PixelIdxList},'UniformOutput',false);
breathingCycles=vertcat(breathingCycles{:});

% Find the inspiration epochs that correspond to each breathing cycle
inspirationEpochsIdx=zeros(length(breathingCycles),1);
for cycleIdx=1:length(breathingCycles)
    % find the first inspirationEpochs that is before the current cycle
    inspirationEpochsIdx(cycleIdx)=find(cellfun(@(insIdx) insIdx(end),inspirationEpochs)...
        <breathingCycles(cycleIdx,1),1,'last');
end
% Get the inspiration phase indices
inspirationEpochs = vertcat(inspirationEpochs{inspirationEpochsIdx});

% Convert inspirationEpochs to a logical vector
inspirationEpochs=ismember(1:length(breathingFlow),inspirationEpochs);

% % Plot the breathing signal and the inspiration epochs
% figure; hold on
% plot(zscore(double(breathingFlow(1:30000))))
% plot(breathingFlow_phase(1:30000))
% % plot(breathingFlow_derivative(1:30000))
% % plot(inspirationEpochs(1:find(inspirationEpochs<30000,1,'last')),-1,'r*')
% plot(inspirationEpochs(1:30000),'bd')
end