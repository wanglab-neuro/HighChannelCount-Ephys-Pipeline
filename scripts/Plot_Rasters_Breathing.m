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
[breathingFlow, ~] = get_inspiration_epochs(breathingFlow,analog_Fs);
inspirationEpochs = breathingFlow<0;
% Get the data type of the AP data stream
dataType = class(APData.samples);
breathingFlow = cast(breathingFlow,dataType);

% Get the number of channels
nChannels = size(APData.samples,1);

% for each channel, compute rms threshold, find peaks (spikes), and return the spikes's timestamps
spikeTimestamps = cell(nChannels,1);
for channelIdx=1:nChannels
    % Get the channel data
    channelData = double(APData.samples(channelIdx,:));

    % Compute the rms threshold
    rmsThreshold = 10*median(abs(channelData));

    % Find the peaks
    [peakValues, peakIdx] = findpeaks(channelData,'MinPeakHeight',rmsThreshold,'MinPeakProminence',rmsThreshold);

    % Get the timestamps of the peaks
    spikeTimestamps{channelIdx} = APData.timestamps(peakIdx);

    %     % Plot the channel data and the detected spikes
    %     figure('Name',['Channel ' num2str(channelIdx)], 'Color', 'w', 'Position', [500 100 1000 800])
    %     hold on
    %     plot(APData.timestamps,channelData)
    %     yline(rmsThreshold)
    %     plot(spikeTimestamps{channelIdx},peakValues,'k*')
    %     xlabel('Time (s)')
    %     ylabel('Voltage (uV)')
    %     title(['Channel ' num2str(channelIdx)])
    %     legend('Channel Data','Detected Spikes','Location','Best')

end

% Find the index of channels with detected spikes (more than 1/10th the number of spikes than the channel with the most spikes)
spikeChannelsIdx = find(cellfun(@length,spikeTimestamps) > max(cellfun(@length,spikeTimestamps))/10);

% Assign indices of spike times to the rasters image array
spikeRaster = zeros(length(spikeChannelsIdx),length(breathingFlow));

for channelIdx=1:length(spikeChannelsIdx)
    % Get the channel index
    channel = spikeChannelsIdx(channelIdx);

    % Get the spike timestamps
    spikeTimestamps_channel = spikeTimestamps{channel};

    % Assign the spike timestamps to the raster array
    spikeRaster(channelIdx,ismember(APData.timestamps,spikeTimestamps_channel)) = 1;
end

% Plot the rasters for spikeChannelsIdx, each raster shifted by enough spacing not to overlap
figure('Name','Spike rasters', 'Color', 'w', 'Position', [500 100 1000 800])
splotH(1) = subplot(2,1,2); hold on
selectedChannels=find(ismember(spikeChannelsIdx,[46,95]));
% Plot 10 seconds of data of the selected channels
spikeRaster = spikeRaster(:,1:10*AP_Fs);
% Plot the rasters
plotH(1) = EphysFun.PlotRaster(spikeRaster(selectedChannels,:),APData.timestamps(1:10*AP_Fs),'lines',[],'k'); % added the function below in case this is not in the path
% EphysFun.PlotRaster(spikeRaster,APData.timestamps,'lines',[],'k'); % added the function below in case this is not in the path

% Shift yticks 0.5 down, and assign yticklabels
set(gca, 'YTick', (1:length(spikeChannelsIdx(selectedChannels)))-0.5,...
    'YTickLabel', spikeChannelsIdx(selectedChannels),'TickDir','out');
ylabel('Channel #')

% Overlay the inspiration epochs as color blocks
ylim=get(gca,'ylim');
heightDiff = diff(ylim);
areaH =  area(analogData.timestamps(1:10*analog_Fs),max(ylim)*inspirationEpochs(1:10*analog_Fs), min(ylim), ...
        'FaceColor', [1 0.8 0], 'EdgeColor', 'none', 'ShowBaseLine', 'off', 'FaceAlpha', 0.5);
xlabel('Time (s)')
% Add legend for traceH and areaH
lgdH = legend(areaH,'Inspiration Epochs','Location','Best');
lgdH.Box = 'off';

% Plot breathing flow for the same time period
splotH(2) = subplot(2,1,1); hold on

% % Create image of the inspiration epochs
% inspEpochImage = repmat(inspirationEpochs,length(spikeChannelsIdx),1);
% % plot the inspiration epochs as an image with transparency
% imagesc(inspEpochImage,'AlphaData',0.5)
% colormap(ax2,'autumn')

% Plot 10 seconds of data of the breathing flow data
plotH(2) = plot(analogData.timestamps(1:10*analog_Fs),breathingFlow(1:10*analog_Fs));
% plotH(2) = plot(analogData.timestamps,breathingFlow);
set(plotH,'Color','k','linewidth',1.5)
set(gca,'YColor','k','XTickLabel',[],'TickDir','out'); %'XTick', []
ylabel({'Breathing Flow (AU)';' Inspiration is Downward'})
box off
% xlabel('Time (s)')

% bind the time axis between subplots
linkaxes(splotH,'x')

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
% Get the second derivative of the breathing flow
breathingFlow_derivative2=[diff(breathingFlow_derivative) 0];

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

% Append to the inpiration epoch the adjoining epich where breathingFlow_phase > 0 & breathingFlow_derivative>0
for cycleIdx=1:length(inspirationEpochsIdx)
    % find the first late InspirationEpochs that is after the current cycle
    idxStart=inspirationEpochs{inspirationEpochsIdx(cycleIdx)}(end)+1;
    lateInspirationEpochsIdx=find(breathingFlow_derivative2(idxStart:end)<0,1,'first')+idxStart-1;
    
    % Append the lateInspirationEpochs to the inspirationEpochs
    inspirationEpochs{inspirationEpochsIdx(cycleIdx)}=...
        [inspirationEpochs{inspirationEpochsIdx(cycleIdx)}(1):...
        lateInspirationEpochsIdx];
end
    
% Get the inspiration phase indices
inspirationEpochs = horzcat(inspirationEpochs{inspirationEpochsIdx});

% Convert inspirationEpochs to a logical vector
inspirationEpochs=ismember(1:length(breathingFlow),inspirationEpochs);

% % Plot the breathing signal and the inspiration epochs
% figure; hold on
% plot(zscore(double(breathingFlow(1:30000))))
% plot(breathingFlow_phase(1:30000))
% % plot(breathingFlow_derivative2(1:30000)*1000)
% % plot(inspirationEpochs(1:find(inspirationEpochs<30000,1,'last')),-1,'r*')
% plot(inspirationEpochs(1:30000),'bd')
end

function lineH = PlotRaster(spikeRasters,timeStamps,plotType,plotShift,plotCmap)
% From HCCE pipeline's EphysFun
if nargin<5 || isempty(plotCmap); plotCmap='k'; end
if nargin<4 || isempty(plotShift); plotShift = 0; end
if nargin<3 || isempty(plotType); plotType='diamonds'; end
if nargin<2 || isempty(timeStamps); timeStamps=1:size(spikeRasters,2); end
switch plotType
    case 'lines'
        if size(spikeRasters,1)==1; spikeRasters=repmat(spikeRasters,2,1); end
        [indy, indx] = ind2sub(size(spikeRasters),find(spikeRasters));                          % find row and column coordinates of spikes
        indx=timeStamps(indx);
        indy=indy+plotShift;                                                                    % add placement value
        if size(indx,2) > size(indx,1); indx=permute(indx,[2 1]); indy=permute(indy,[2 1]); end % need columns
        rs_indx=reshape([indx';indx';nan(size(indx'))],1,numel(indx)*3);                        % reshape x indices double them and intersperce with nans
        rs_indy=reshape([indy'-1;indy';nan(size(indy'))],1,numel(indx)*3);                      % reshape y indices double them and intersperce with nans
        lineH = line(rs_indx,rs_indy,'color',plotCmap,'LineWidth',1.2);                                 % plot rasters
    case 'bars' %(deprecated - too heavy on memory)
        %find row and column coordinates of spikes
        [indy, indx] = ind2sub(size(spikeRasters),find(spikeRasters));
        plot([indx';indx'],[indy'-1;indy']+plotShift,'color',plotCmap,'LineStyle','-');% plot rasters
    case 'diamonds'
        plot(gca,find(spikeRasters),...
            ones(1,numel(find(spikeRasters)))*...
            plotShift,'LineStyle','none',...
            'Marker','d','MarkerEdgeColor','none',...
            'MarkerFaceColor',plotCmap,'MarkerSize',4);
    case 'image'
        imagesc(gca,0,plotShift,spikeRasters);
        colormap(gca,plotCmap);
    case 'stems' % for a single line, otherwise baseline moves every iteration
        rastH=stem(gca,find(spikeRasters),ones(1,numel(find(spikeRasters)))*plotShift,...
            'BaseValue',plotShift-1,'Color', plotCmap,'Marker','none');
        rastBaseH=rastH.BaseLine; rastBaseH.Visible = 'off';
end
end