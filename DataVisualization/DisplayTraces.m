function dataExcerpt=DisplayTraces(traces, tracesInfo, channelNum)

winIdxStart=((tracesInfo.excerptLocation-...
    double(tracesInfo.excerptSize))*tracesInfo.numChan)+1;
if mod(winIdxStart,tracesInfo.numChan)~=1 %set window index to correct point in data vector
    winIdxStart=winIdxStart-...
        mod(winIdxStart,tracesInfo.numChan)-...
        tracesInfo.numChan+1;    % set index loc to first electrode
    %             (tracesInfo.numChan - channelNum);     % set index loc to selected electrode
end
winIdxEnd=winIdxStart+...
    (2*tracesInfo.excerptSize*tracesInfo.numChan);
excerptWindow=winIdxStart:winIdxEnd-1;
if size(excerptWindow,2)>(2*tracesInfo.excerptSize*...
        tracesInfo.numChan) %for some reason
    excerptWindow=excerptWindow(1:end-(size(excerptWindow,2)-...
        (2*tracesInfo.excerptSize*tracesInfo.numChan)));
end
dataExcerpt=traces.Data(excerptWindow);
dataExcerpt=reshape(dataExcerpt,[tracesInfo.numChan...
    tracesInfo.excerptSize*2]);
%         foo=traces.Data;
%         foo=reshape(foo,[tracesInfo.numChan...
%         size(foo,1)/tracesInfo.numChan]);

if tracesInfo.preproc==0 % raw data is presumed bandpassed filtered at this point
    preprocOption={'CAR','all'};
    dataExcerpt=PreProcData(dataExcerpt,tracesInfo.samplingRate,preprocOption);
end
dataExcerpt=int32(dataExcerpt(channelNum,:));

figure('Color','white','position',[600  800  1200 200]);
plot(dataExcerpt,'k','linewidth',0.1); hold on;

if isfield(tracesInfo,'threshold')
    threshold=str2double(tracesInfo.threshold);
    plot(ones(1,size(dataExcerpt,2))*threshold*mad(single(dataExcerpt)),'--','Color',[0 0 0 0.3]);
    plot(ones(1,size(dataExcerpt,2))*-threshold*mad(single(dataExcerpt)),'--','Color',[0 0 0 0.3]);
else
    %     threshold=8;
end
hold off;
timeLabels=round(linspace(round(tracesInfo.excerptLocation-...
    tracesInfo.excerptSize)/(tracesInfo.samplingRate/1000),...
    round(tracesInfo.excerptLocation+tracesInfo.excerptSize)/...
    (tracesInfo.samplingRate/1000),4)./1000,3); % duration(X,'Format','h')
set(gca,'xtick',round(linspace(0,max(get(gca,'xtick')),4)),...
    'xticklabel',timeLabels); %,'TickDir','out');
set(gca,'ytick',[],'yticklabel',[]); %'ylim'
axis('tight');box off;
set(gca,'Color','white','FontSize',12,'FontName','calibri');
