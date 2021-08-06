function sdf=SplitPSTH(rasters,groups,conditions,options)
figure('Position',[1050 120 750 790],'Color','w');
if contains(options,'rasters')
    
    %% plot rasters
    colormap(flipud(gray));
    imagesc(logical(rasters));
    xlabel('Time (ms)');
    ylabel('Condition #');
    set(gca,'XTick',(0:1000:size(rasters,2))+0.5); %0:100:preAlignWindow+200); %'XLim',[preAlignWindow-250.5 preAlignWindow+250.5]
    set(gca,'XTickLabel',(0:size(rasters,2)/1000)); %'FontSize',10,'FontName','calibri'
    set(gca,'FontSize',10,'FontName','Calibri','TickDir','out');
    
    % draw alignment bar
    % currylim=get(gca,'YLim');
    % patch([repmat(figureOptions.alignSpecs{1},1,2) repmat(figureOptions.alignSpecs{1}+figureOptions.alignSpecs{3},1,2)], ...
    %     [[0 currylim(2)] fliplr([0 currylim(2)])], ...
    %     [0 0 0 0],figureOptions.alignSpecs{4},'EdgeColor','none','FaceAlpha',0.3);
    
    box off; % axis tight
    % title(figureOptions.legends{3});
elseif contains(options,'Bars')% bar plots
    barPlot=bar(movmean(mean(rasters),5));
    %     barPlot.FaceColor=[0.1 0.4 0.8];
    barPlot.EdgeColor='none';
    barPlot.BarWidth=1;
elseif contains(options,'PSTH')
    hold on;
    cmap=lines;
    %% plot PSTHs
    for conditionNum=1:numel(unique(groups))
        
        groupIdx=groups==conditionNum;
        %% plot sdf
        conv_sigma=20;
        [sdf, ~, rastsem]=conv_raster(rasters(groupIdx,:),conv_sigma,0);
        
        %plot sem
        %         patch([1:length(sdf),fliplr(1:length(sdf))],[sdf-rastsem,fliplr(sdf+rastsem)],...
        %             'k','EdgeColor','none','FaceAlpha',0.2);
        %plot sdfs
        plot(gca,sdf,'Color',cmap(conditionNum,:),'LineWidth',1.5);
        
        xlabel('Time (ms)');
        ylabel('Mean Firing Rate (spikes/s)');
        set(gca,'XTick',(0:1000:size(rasters,2))+0.5); %0:100:preAlignWindow+200); %'XLim',[preAlignWindow-250.5 preAlignWindow+250.5]
        set(gca,'XTickLabel',(0:size(rasters,2)/1000)); %'FontSize',10,'FontName','calibri'
        set(gca,'YTickLabel',get(gca,'YTick')*1000)
        set(gca,'FontSize',10,'FontName','Calibri','TickDir','out');
        
        box off;
              
    end
    legend(conditions)
    
elseif contains(options,'Heatmap')
    conv_sigma=20;
    sdf=nan(numel(unique(groups)),5000-(conv_sigma*6));
    for conditionNum=1:numel(unique(groups))
        groupIdx=groups==conditionNum;
        sdf(conditionNum,:)=conv_raster(rasters(groupIdx,:),conv_sigma);
    end
    colormap(hot);
    imagesc(sdf)
    xlabel('Time (s)');
    ylabel('Wall Distance (mm)');
    set(gca,'XTick',(-conv_sigma*3:1000:size(rasters,2))+0.5); %0:100:preAlignWindow+200); %'XLim',[preAlignWindow-250.5 preAlignWindow+250.5]
    set(gca,'XTickLabel',(0:size(rasters,2)/1000)); %'FontSize',10,'FontName','calibri'
    set(gca,'YTick',1:conditionNum,'YTickLabel',unique(conditions))
    set(gca,'FontSize',10,'FontName','Calibri','TickDir','out');
    cbh=colorbar;
    ylabel(cbh,'Mean Firing Rate (spikes/s)');

    % draw alignment bar
    % currylim=get(gca,'YLim');
    % patch([repmat(figureOptions.alignSpecs{1},1,2) repmat(figureOptions.alignSpecs{1}+figureOptions.alignSpecs{3},1,2)], ...
    %     [[0 currylim(2)] fliplr([0 currylim(2)])], ...
    %     [0 0 0 0],figureOptions.alignSpecs{4},'EdgeColor','none','FaceAlpha',0.3);
    
    box off; % axis tight
    
end
end

