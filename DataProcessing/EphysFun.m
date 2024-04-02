classdef EphysFun
    methods(Static)
        %% Order and remap traces
        %%%%%%%%%%%%%%%%%%%%%%%%%
        function traces=OrderTraces(traces,numElectrodes,recDuration,channelMap)
            try
                traces=reshape(traces,[numElectrodes recDuration]);
            catch
                traces=reshape(traces',[recDuration numElectrodes]);
            end
            % remap traces
            traces=traces(channelMap,:);
        end

        %% Filter traces
        %%%%%%%%%%%%%%%%
        function traces=FilterTraces(traces,samplingRate,preprocOption)
            if nargin<2; samplingRate=30000; end
            if nargin<3; preprocOption={'CAR','all'}; end
            traces=PreProcData(traces,samplingRate,preprocOption);
        end

        %% FindBestUnits
        %%%%%%%%%%%%%%%%
        function bestUnits=FindBestUnits(unitIDs,pctThreshold)
            if nargin<2
                pctThreshold=5; %default 5% threshold
            end
            unitIDs=double(unitIDs);
            % find most frequent units
            [unitFreq,uniqueUnitIDs]=hist(unitIDs,unique(unitIDs));
            keepUnits=uniqueUnitIDs>0;uniqueUnitIDs=uniqueUnitIDs(keepUnits);
            [unitFreq,freqIdx]=sort(unitFreq(keepUnits),'descend');
            uniqueUnitIDs=uniqueUnitIDs(freqIdx);
            unitFreq=unitFreq./sum(unitFreq)*100;
            bestUnitsIdx=unitFreq>pctThreshold;
            bestUnits=uniqueUnitIDs(bestUnitsIdx); bestUnits=sort(bestUnits);
        end

        %% KeepBestUnits
        %%%%%%%%%%%%%%%%
        function [spikes,recordingTraces,keepTraces]=KeepBestUnits(bestUnits,spikes,allTraces)
            if isfield(spikes,'preferredElectrode')
                try
                    titularChannels = unique(spikes.preferredElectrode(ismember(spikes.unitID,bestUnits)));
                catch
                    titularChannels =find(~cellfun('isempty',spikes.preferredElectrode));
                end
            end
            % keepUnits=[1 2 3];
            % titularChannels=[10 10 10];
            keepTraces=titularChannels; %14; %[10 14 15];% keepTraces=1:16; %[10 14 15];
            % keepTraces=1:size(allTraces,1);

            %% Keep selected recording trace and spike times,
            recordingTraces=allTraces(keepTraces,:); %select the trace to keep
            try
                keepUnitsIdx=ismember(spikes.preferredElectrode,keepTraces);
                spikes.unitID=spikes.unitID(keepUnitsIdx);
                spikes.preferredElectrode=spikes.preferredElectrode(keepUnitsIdx);
                try
                    spikes.waveforms=spikes.waveforms(keepUnitsIdx,:);
                catch
                    spikes.waveforms=[];
                end
                spikes.times=spikes.times(keepUnitsIdx);
            catch
                %     unitID=spikes.unitID;
                %     spikeTimes=spikes.times;
                %     waveForms=spikes.waveforms;
                %     preferredElectrode=spikes.preferredElectrode;
            end
        end

        %% MakeRasters
        %%%%%%%%%%%%%%
        function [spikeRasters,unitList]=MakeRasters(spikeTimes,unitID,timeUnit,traceLength)
            %% Bins spike counts in 1ms bins
            binSize=1;
            if nargin<2; unitID=ones(1,numel(spikeTimes)); end
            if nargin<3; timeUnit=30000; end
            if nargin<4; traceLength=int32(double(max(spikeTimes))/timeUnit*1000); end
            unitList=unique(unitID); unitList=unitList(unitList>0);
            numUnit=numel(unitList);
            spikeRasters=nan(numUnit,ceil(traceLength));
            for unitNum=1:numUnit
                unitIdx=unitID==unitList(unitNum);
                rasters=EphysFun.BinToMilliseconds(spikeTimes(unitIdx),binSize,timeUnit);
                % Assign to raster array
                spikeRasters(unitNum,1:numel(rasters))=rasters;
            end
        end

        %% BinToMilliseconds
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        function binnedSpikeTime=BinToMilliseconds(spikeTimeArray,binSize,samplingRate)
            %% bin spike times in 1ms bins
            % Set the first spike time to 0
            spikeTimeArray=spikeTimeArray-spikeTimeArray(1);
            if length(spikeTimeArray) == 1
                binnedSpikeTime=1;
            else
                % Find the number of bins
                numBin=ceil(range(spikeTimeArray)/(samplingRate/1000)/binSize);
                % Find the edges of the bins
                binEdges=linspace(0,double(range(spikeTimeArray)),numBin+1);
                % Bin the spike times
                binnedSpikeTime = histcounts(double(spikeTimeArray), binEdges);
                % Set spike counts to max 1
                binnedSpikeTime(binnedSpikeTime>1)=1;
            end
        end

        %% AlignRasters
        %%%%%%%%%%%%%%%
        function alignedRasters=AlignRasters(binnedSpikes,eventTimes,preAlignWindow,postAlignWindow,SRratio)
            %% create event aligned rasters
            if nargin==2 %define time window limits
                preAlignWindow=100; postAlignWindow=400;
            end
            if nargin<5; SRratio=1; end %default in milliseconds;
            eventTimes=int32(eventTimes*SRratio);
            preAlignWindow=int32(preAlignWindow*SRratio);
            postAlignWindow=int32(postAlignWindow*SRratio);
            alignedRasters=cell(size(binnedSpikes,1),1);
            for cellNum=1:size(binnedSpikes,1)
                cellRasters=nan(numel(eventTimes),preAlignWindow+postAlignWindow);
                for trialNum=1:numel(eventTimes)
                    try
                        cellRasters(trialNum,:)=binnedSpikes(cellNum,...
                            int32(eventTimes(trialNum)-preAlignWindow:...
                            eventTimes(trialNum)+postAlignWindow-1));
                        %smoothed:
                        %             alignedRasters(trialNum,:)=convSpikeTime(...
                        %                 eventTimes(trialNum)-preAlignWindow:...
                        %                 eventTimes(trialNum)+postAlignWindow);
                    catch
                        continue
                    end
                end
                alignedRasters{cellNum}=cellRasters(~isnan(sum(cellRasters,2)),:);
            end
            if size(binnedSpikes,1)==1
                alignedRasters=alignedRasters{:};
            end
            %     figure; imagesc(alignedRasters)
        end



        %% MakeSDF
        %%%%%%%%%%
        function [SDFs, SEMs]=MakeSDF(spikes, sigma, causal, format, unitsIDs, timeBase)
            % Compute spike density functions (SDFs) from spike times
            % Spikes "format" can be rasters (i.e., binned binary data), or spiketimes.
            % If spiketimes, then compute rasters first.

            if nargin<2 || isempty(sigma); sigma = 5; end
            if nargin<3 || isempty(causal); causal = false; end
            if nargin<4 || isempty(format); format='rasters'; end

            if strcmp(format,'spiketimes')
                % Compute rasters
                if nargin<6 || isempty(timeBase); timeBase=30000; end
                % if nargin<6; traceLength=int32(double(max(spikes))/timeUnit*1000); end
                if ~iscell(spikes); spikes={spikes}; end
                binned_spikes=zeros(numel(spikes), max(cellfun(@(x) ceil(max([1, max(x)/timeBase*1000])), spikes)));
                for clusterNum=1:numel(spikes) 
                    if nargin<5 || isempty(unitsIDs); unitIDs=1:size(spikes{clusterNum},1); end
                    if length(unitsIDs)==1; unitIDs=ones(size(spikes{clusterNum},1),1)*unitsIDs; end
                    if isempty(spikes{clusterNum}); continue; end

                    raster = EphysFun.MakeRasters(spikes{clusterNum}, unitIDs, timeBase, max([1, range(spikes{clusterNum})/timeBase*1000]));
                    spike_range_start = ceil(spikes{clusterNum}(1)/timeBase*1000);
                    binned_spikes(clusterNum, spike_range_start:spike_range_start+numel(raster)-1) = raster;
                end
            else
                binned_spikes=spikes;
            end

            % Take care of NaNs in the data
            if any(isnan(binned_spikes(:)))
                % use fillmissing to replace NaNs with the mean of the surrounding values
                binned_spikes=fillmissing(binned_spikes,'linear',2);
            end

            %% Compute sdfs
            [SDFs, SEMs]=deal(nan(size(binned_spikes))); %length(unitNum), ceil(size(spikeRasters_ms,2)/samplingRate*1000));
            for clusterNum=1:size(SDFs,1)
                SDFs(clusterNum,:)=EphysFun.GaussConv(binned_spikes(clusterNum,:), sigma, causal)*1000;
            end

            %% Compute SEMs
            if nargout>1
                % Multiply SEM by 1.96 to get 95% confidence interval
                SEMs=std(SDFs)/sqrt(size(SDFs,1));
            end

            % Average SDFs
            SDFs = nanmean(SDFs, 1);

        end

        %% GaussConv
        %%%%%%%%%%%%
        function convTrace=GaussConv(data,sigma,causal)
            %% Convolve trace with gaussian kernel
            if nargin<2;sigma=5;end
            if nargin<3;causal=false;end

            % Create Gaussian filter
            ksize = round(6*sigma);
            width = linspace(-ksize / 2, ksize / 2, ksize);
            gaussFilter = exp(-width .^ 2 / (2 * sigma ^ 2)); %same as normpdf(width,0,sigma);
            % Normalize the filter to get the same magnitude as the original data
            gaussFilter = gaussFilter / sum (gaussFilter);

            % Make the filter causal (i.e., no negative time lags)
            if causal; gaussFilter(width<0)=0; end

            % Convolve data with gaussian filter
            convTrace = conv(data, gaussFilter, 'same');
        end

        %% FindRasterIndices
        %%%%%%%%%%%%%%%%%%%%
        function [rasterYInd_ms, rasterXInd_ms]=FindRasterIndices(spikeRasters,unitNum)
            %% Compute raster indices
            [rasterYInd_ms, rasterXInd_ms]=deal(cell(length(unitNum),1));
            for clusterNum=1:length(unitNum)
                [rasterYInd_ms{clusterNum}, rasterXInd_ms{clusterNum}] =...
                    ind2sub(size(spikeRasters(clusterNum,:)),find(spikeRasters(clusterNum,:))); %find row and column coordinates of spikes
            end
            % rasters=[indx indy;indx indy+1];
        end

        %% PlotRaster
        %%%%%%%%%%%%%
        function PlotRaster(spikeRasters,timeStamps,plotType,plotShift,plotCmap)
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
                    line(rs_indx,rs_indy,'color',plotCmap,'LineWidth',1.2);                                 % plot rasters
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

        %% PlotACG
        %%%%%%%%%%
        function PlotACG(unitsIDs,spikeTimes,selectedUnits,samplingRate,axesH,cmap)
            if nargin<5; figure; axesH=gca; end
            if ~exist('cmap','var'); cmap=parula; end
            axes(axesH); hold on; cla(axesH,'reset'); set(axesH,'Visible','on');
            binSize=1/2;
            for unitNum=numel(selectedUnits)
                unitST=spikeTimes(unitsIDs==selectedUnits(unitNum));%get unit spike times
                unitST=int32(unitST/(samplingRate/1000*binSize));% change to 1/2ms timescale
                % ISI=diff(unitST)/(samplingRate/1000);%get ISI

                %% bin spikes
                spikeTimeIdx=zeros(1,unitST(end));
                spikeTimeIdx(unitST)=1;
                numBin=ceil(size(spikeTimeIdx,2)/binSize);
                binUnits = histcounts(double(unitST), linspace(0,size(spikeTimeIdx,2),numBin));
                binUnits(binUnits>1)=1; %no more than 1 spike per bin

                %% compute autocorrelogram
                [ACG,lags]=xcorr(double(binUnits),200,'unbiased');  %'coeff'
                ACG(lags==0)=0;
                ACGh=bar(lags,ACG,'BarWidth', 1.6);
                ACGh.FaceColor = cmap(selectedUnits,:);
                ACGh.EdgeColor = cmap(selectedUnits,:); %'none';
            end
            % axis('tight');
            box off; grid('on'); %set(gca,'yscale','log','GridAlpha',0.25,'MinorGridAlpha',1);
            xlabel('Autocorrelogram (ms )');% num2str(binSize) ' ms bins)']
            set(gca,'xlim',[-25 25]/binSize,... %'ylim',[0 max([max(get(gca,'ylim')) 10^1])]
                'xtick',-25/binSize:10:25/binSize,'xticklabel',-25:10*binSize:25,...
                'Color','white','FontSize',10,'FontName','Calibri','TickDir','out');
            hold off
        end

        %% PLotISI
        %%%%%%%%%%
        function PLotISI(unitsIDs,spikeTimes,selectedUnits,samplingRate,axesH,cmap)
            if nargin<5; figure; axesH=gca; end
            if ~exist('cmap','var'); cmap=parula; end
            axes(axesH); hold on; cla(axesH,'reset'); set(axesH,'Visible','on');
            for unitNum=numel(selectedUnits)
                %spike times for that unit
                unitST=spikeTimes(unitsIDs==selectedUnits);
                % compute interspike interval
                if ~isempty(diff(unitST))
                    ISI=diff(unitST)/(samplingRate/1000);
                    ISIhist=histogram(double(ISI),logspace(0, 4, 50),'LineWidth',1.5);  %'DisplayStyle','stairs','Normalization','probability'
                    ISIhist.FaceColor = cmap(selectedUnits,:);
                    ISIhist.EdgeColor = cmap(selectedUnits,:); %'k';
                end
                xlabel('Interspike Interval (ms)') ; %axis('tight');
                box off; grid('on'); set(gca,'xscale','log','GridAlpha',0.25,'MinorGridAlpha',1);
                set(gca,'xlim',[0 10^4],... %'XTick',linspace(0,40,5),'XTickLabel',linspace(0,40,5),...
                    'TickDir','out','Color','white','FontSize',10,'FontName','Calibri');
                hold off
            end
        end
    end
end