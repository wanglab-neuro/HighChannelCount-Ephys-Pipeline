function RastersPSTH(varargin)
figure('Position',[1050 120 750 790],'Color','w');
signalData=varargin{1};

% Figure options is a structure that specifies limits, alignments, style, legends, etc
% alignment specifications is a cell with 4 parameters:
%         interval pre-alignment
%         interval post-alignment
%         alignment bar width
%         alignment bar color
% figure style is a cell with 3 parameters:
%         colormap
%         x tick spacing
%         x tick labels
% legends is a cell with 3 parameters:
%         x axis label
%         y axis label
%         title

if size(varargin,2)==1
    
    
    figureOptions=struct('alignSpecs',...
        {size(rasterData,2)/2+1;size(rasterData,2)/2+1;1;'white'},...
        'figureStyle',{'parula';1:10:size(rasterData,2)+1;-(size(rasterData,2)/2+1)/1000:(size(rasterData,2)/2+1)/1000},...
        'legends',{'Time (s)'; 'Trials'; {['Neuron # ' num2str(size(rasterData(1)))],...
        'response aligned to midpoint'}});
else
    figureOptions=varargin{2};
end

%% plot rasters

subplot(3,1,1:2)
colormap(flipud(gray));
imagesc(logical(signalData));
xlabel('Time (ms)');
ylabel('Trial#');
set(gca,'XTick',(0:1000:size(signalData,2))+0.5); %0:100:preAlignWindow+200); %'XLim',[preAlignWindow-250.5 preAlignWindow+250.5]
set(gca,'XTickLabel',(0:size(signalData,2)/1000)); %'FontSize',10,'FontName','calibri'
set(gca,'FontSize',10,'FontName','Calibri','TickDir','out');

% draw alignment bar
% currylim=get(gca,'YLim');
% patch([repmat(figureOptions.alignSpecs{1},1,2) repmat(figureOptions.alignSpecs{1}+figureOptions.alignSpecs{3},1,2)], ...
%     [[0 currylim(2)] fliplr([0 currylim(2)])], ...
%     [0 0 0 0],figureOptions.alignSpecs{4},'EdgeColor','none','FaceAlpha',0.3);

box off; % axis tight
% title(figureOptions.legends{3});

%% plot psth
subplot(3,1,3)
barPlot=bar(movmean(mean(signalData),5));
%     barPlot.FaceColor=[0.1 0.4 0.8];
barPlot.EdgeColor='none';
barPlot.BarWidth=1;
xlabel('Time (ms)');
ylabel('Mean Firing Rate (Hz)');
set(gca,'XTick',(0:1000:size(signalData,2))+0.5); %0:100:preAlignWindow+200); %'XLim',[preAlignWindow-250.5 preAlignWindow+250.5]
set(gca,'XTickLabel',(0:size(signalData,2)/1000)); %'FontSize',10,'FontName','calibri'
set(gca,'YTickLabel',get(gca,'YTick')*1000)
set(gca,'FontSize',10,'FontName','Calibri','TickDir','out');

box off;




