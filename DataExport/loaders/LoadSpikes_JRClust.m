function spikes=LoadSpikes_JRClust(fileName,traces)

try % JRC v3 and v4:
    load(fileName,'spikeTimes','spikeSites','spikeClusters','filtShape')

    %                 evtWindow = [-0.25, 0.75]; %evtWindowRaw = [-0.5, 1.5]; nSiteDir = 4;
    %                 waveformsFid=fopen('vIRt32_2019_04_24_16_48_53_5185_1_1_export_filt.jrc');
    %                 waveforms=fread(waveformsFid,...
    %                     [sum(abs(evtWindow))*30,nSiteDir,size(spikeClusters,1)],'int16');
    %                 fclose(waveformsFid);
    %                 figure; plot(mean(waveforms(1:4:120,spikeClusters==4)'))
    spikes.unitID=spikeClusters;
    spikes.times=spikeTimes;
    spikes.preferredElectrode=spikeSites; %Site with the peak spike amplitude %cviSpk_site Cell of the spike indices per site

    recInfofile=[regexp(fileName,'\w+(?=export_res)','match','once') 'recInfo.mat'];
    spikes=struct('unitID', [], 'times', [], 'preferredElectrode', [],...
        'bitResolution', [], 'samplingRate', [], 'timebase', [],...
        'waveforms', [],'templatesIdx', [], 'templates', []);
    if exist(fullfile(cd,recInfofile),'file')
        load(recInfofile);
        spikes.bitResolution=recInfo.bitResolution;
        [spikes.samplingRate,spikes.timebase]=deal(recInfo.samplingRate);
        try
            exportDirListing=dir(recInfo.export.directory);
            %         paramFileIdx=cellfun(@(fName) contains(fName,'prm'),...
            %             {exportDirListing.name});
            %         hCfg = jrclust.Config(fullfile(exportDirListing(paramFileIdx).folder,...
            %             exportDirListing(paramFileIdx).name));
            %         siteNeighbors=hCfg.siteNeighbors;

            % get filtered waveforms
            filtWFfileIdx=cellfun(@(fName) contains(fName,'_filt.jrc'),...
                {exportDirListing.name});
            filtWFfile=fullfile(exportDirListing(filtWFfileIdx).folder,exportDirListing(filtWFfileIdx).name);
            fid = fopen(filtWFfile, 'r');
            spikes.waveforms= reshape(fread(fid, inf, '*int16'), filtShape);
            fclose(fid);
            spikes.waveforms = permute(spikes.waveforms,[3 1 2]);
        catch
        end
    end
catch
    try
        % v2 updated structure:
        load(fileName,'miClu_log','P','S_clu','dimm_spk',...
            'viSite_spk','viTime_spk');%'cviSpk_site'

        spikes.unitID=S_clu.viClu;
        spikes.times=viTime_spk;
        spikes.preferredElectrode=viSite_spk; %Site with the peak spike amplitude %cviSpk_site Cell of the spike indices per site
        spikes.templatesIdx=S_clu.viSite_clu;
        spikes.templates=S_clu.tmrWav_spk_clu;
        spikes.waveforms=[];
        spikes.bitResolution=P.uV_per_bit;
        spikes.samplingRate=P.sRateHz;

    catch
        % old structure
        load(fileName,'S_clu','spikeTimes','spikeSites','P');

        spikes.unitID=S_clu.spikeClusters;
        spikes.times=spikeTimes;
        spikes.preferredElectrode=spikeSites;
        %                     spikes.templatesIdx=S_clu.clusterTemplates;
        %                     spikes.templates=S_clu.spikeTemplates;
        spikes.waveforms=S_clu.tmrWav_spk_clu; %mean waveform
        spikes.bitResolution=P.uV_per_bit;
        spikes.samplingRate=P.sampleRateHz;

        % get filtered waveforms
        dirListing=dir;
        spikeWaveFormsFile=cellfun(@(x) strfind(x,'_spkwav'),...
            {dirListing.name},'UniformOutput',false);
        if ~isempty(vertcat(spikeWaveFormsFile{:}))
            vcFile=dirListing(~cellfun('isempty',cellfun(@(x) strfind(x,'_spkwav'),...
                {dirListing.name},'UniformOutput',false))).name;
            vcDataType = 'int16';
            fid=fopen(vcFile, 'r');
            % mnWav = fread_workingresize(fid, dimm, vcDataType);
            mnWav = fread(fid, prod(dimm_spk), ['*', vcDataType]); %(nSamples_spk x nSites_spk x nSpikes: int16)
            if numel(mnWav) == prod(dimm_spk)
                mnWav = reshape(mnWav, dimm_spk);
            else
                dimm2 = floor(numel(mnWav) / dimm_spk(1));
                if dimm2 >= 1
                    mnWav = reshape(mnWav, dimm_spk(1), dimm2);
                else
                    mnWav = [];
                end
            end
            spikes.waveforms=mnWav;
            spikes.waveforms=permute(spikes.waveforms,[3 1 2]);
            spikes.waveforms=squeeze(spikes.waveforms(:,:,1)); %keep best waveform only
            if ~isempty(vcFile), fclose(fid); end
        end
    end
end
%% extract spike waveform
% see ...\JRCLUST\@JRC\loadFiles.m > binData = readBin(filename, binShape, dataType)

%             The "best" site for a spike is always the top row, but not
%             all spikes for a given unit can be assumed to have the same "best" site.
%             For a given spike you can find its best or center site in spikeSites.
%             Then you can get the list of however many neighboring sites were
%             considered from hCfg.siteNeighbors, like:
%             hCfg = jrclust.Config('/path/to/your/params.prm');
%             hCfg.siteNeighbors
%             That will give you an nNeighbors x nSites matrix, so if you want
%             the neighbors for the ith site, take the ith column of that matrix.
%             Then what you could do is embed all your spikes in a matrix that
%             spans all the neighbors of all the spikes in your unit, and for
%             those spikes who don't have traces in those sites, simply put nans.
%             Then do a nanmean on that matrix.

%             filtWFfile=[regexp(argin_fName,'\w+(?=_res)','match','once') '_filt.jrc'];
%             if exist('filtShape','var') & exist(fullfile(cd,filtWFfile),'file')
% %                 recInfofile=[regexp(argin_fName,'\w+(?=export_res)','match','once') 'recInfo.mat'];
% %                 if exist(fullfile(cd,recInfofile),'file')
% %                     load(recInfofile);
% %                     exportDirListing=dir(recInfo.export.directory);
% %                     paramFileIdx=cellfun(@(fName) contains(fName,'prm'),...
% %                         {exportDirListing.name});
% %                     hCfg = jrclust.Config(fullfile(exportDirListing(paramFileIdx).folder,...
% %                         exportDirListing(paramFileIdx).name));
% %                     siteNeighbors=hCfg.siteNeighbors;
% %                 else
% %                     % calculate it
% %                     % siteNeighbors = findSiteNeighbors(siteLoc, 2*nSiteDir + 1, ignoreSites, shankMap);
% %                 end
%                 fid = fopen(filtWFfile, 'r');
%                 spikes.waveforms= reshape(fread(fid, inf, '*int16'), filtShape);
% %                 spikes.waveforms= fread(fid, inf, '*int16');
%                 fclose(fid);
%                 spikes.waveforms = permute(spikes.waveforms,[3 1 2]);
% %                 unitIDs=unique(spikes.unitID);
% %                 for unitNum=1:numel(unitIDs)
% %                     %which sites does it occur on?
% %                     unique(spikes.preferredElectrode(spikes.unitID==unitIDs(unitNum)))
% %                 end
% %                 spikesEmbedding=nan(filtShape(3), size(siteNeighbors,2));
%
%             else
if (isempty(spikes.waveforms) || size(spikes.waveforms,1) <  size(spikes.unitID,1))...
        && (exist('traces','var') && ~isempty(traces))
    spikes.waveforms=NaN(size(spikes.times,1),50);
    electrodesId=unique(spikes.preferredElectrode);
    for electrodeNum=1:numel(electrodesId)
        if isa(traces,'memmapfile') % reading electrode data from .dat file
            spikes.waveforms(spikes.preferredElectrode==electrodeNum,:)=...
                ExtractChunks(traces.Data(electrodeNum:numel(electrodesId):max(size(traces.Data))),...
                spikes.times(spikes.preferredElectrode==electrodeNum),50,'tshifted'); %'tzero' 'tmiddle' 'tshifted'
        else
            spikes.waveforms(spikes.preferredElectrode==electrodeNum,:)=...
                ExtractChunks(traces(electrodeNum,:),...
                spikes.times(spikes.preferredElectrode==electrodeNum),50,'tshifted'); %'tzero' 'tmiddle' 'tshifted'
        end
        % scale to resolution
        %             spikes.waveforms{elNum,1}=spikes.Waveforms{elNum,1}.*bitResolution;
    end
end
% figure; hold on
% plot(mean(spikes.waveforms(spikeClusters==46,12:40))/bitResolution); % bitResolution=0.25;
% plot(mean(waveforms(spikeClusters==46,:,1)))
% refCh=mode(spikes.preferredElectrode(spikeClusters==4));
% spikeTimes=spikes.times(spikeClusters==4);
% spikeSites=spikes.preferredElectrode(spikeClusters==4);
% unitWF=waveforms(spikeClusters==4,:,:);
% unitWF_t=spikes.waveforms(spikeClusters==4,:);
% figure; hold on;
% for chNum=1:16
%     plot(traces(chNum,1:6000)+(chNum-1)*max(max(traces(:,1:6000)))*2,'k')
% end
% for spikeNum=1:15
%     for spkchNum=1:9
%         plot(spikeTimes(spikeNum)-10:spikeTimes(spikeNum)+21,unitWF(spikeNum,:,spkchNum)+int16((refCh-1)*max(max(traces(:,1:6000)))*2))
%     end
% %     plot(spikeTimes(spikeNum)-10:spikeTimes(spikeNum)+21,unitWF_t(spikeNum,:)+double((refCh-1)*max(max(traces(:,1:6000)))*2),'b')
% end
%
%     %% import info from cvs file export
%     %     clusterInfo = ImportJRClusSortInfo(fName);
%
%     %% if we want to attribute each cluster to a specific electrode:
%     %     allClusters=unique(clusterInfo.clusterNum);
%     %     for clusNum=1:length(allClusters)
%     %         bestSite=mode(clusterInfo.bestSite(clusterInfo.clusterNum==allClusters(clusNum)));
%     %         clusterInfo.bestSite(clusterInfo.clusterNum==allClusters(clusNum))=bestSite;
%     %     end
%
%     %     Spikes.Units=clusterInfo.clusterNum;
%     %     Spikes.SpikeTimes=clusterInfo.bestSite;
%
%
%
%     %% degenerate. keeping largest waveforms
%     %     keepSite=squeeze(prod(abs(mnWav)));[keepSite,~]=find(keepSite==max(keepSite));
%     %     waveForms=nan(size(mnWav,1),size(mnWav,3));
%     %     for spktTimeIdx=1:size(mnWav,3)
%     %         waveForms(:,spktTimeIdx)=squeeze(mnWav(:,keepSite(spktTimeIdx),spktTimeIdx));
%     %     end
%
%     for elNum=1:electrodes
%         try
%             units=cviSpk_site{elNum}; % if data from csv file:  clusterInfo.bestSite==elNum;
%             units=units(miClu_log(units,1)>=0);
%             Spikes.Units{elNum,1}=miClu_log(units,1); %         clusterInfo.clusterNum(units);
%             Spikes.SpikeTimes{elNum,1}=viTime_spk(units) ; %    clusterInfo.timeStamps(units)*samplingRate;
%             Spikes.Waveforms{elNum,1}=squeeze(mnWav(:,1,units));
%
%             %% proof that the first trace in mnWav's 2nd dimension is always from the center site:
%             %             miSites_clu = P.miSites(:, S_clu.viSite_clu); % which sites correspond to mnWav's 2nd dimension
%             %             rndTimeStamp=922;
%             %             figure; hold on;
%             %             for wfNum=1:9
%             %                 plot(mnWav(:,wfNum,rndTimeStamp));
%             %             end
%             %             plot(mnWav(:,miSites_clu(:,miClu_log(rndTimeStamp,1))==S_clu.viSite_clu(miClu_log(rndTimeStamp,1)),rndTimeStamp),'ko')
%
%             %% some more exploration
%             %             mode(clusterInfo.clusterNum(units))
%             %             foo=mnWav(:,:,units);
%             %             figure; plot(mean(squeeze(foo(:,1,:)),2))
%             %
%             %             foo=mnWav(:,:,clusterInfo.clusterNum==1);
%             %             subsampleIdx=round(linspace(1,24000,20));
%             %             figure; hold on;
%             %             for timestamps=1:20
%             %                 plot(foo(:,1,subsampleIdx(timestamps)));
%             %             end
%             %             plot(mean(squeeze(mnWav(:,1,:)),2),'k','linewidth',1.5);
%             %
%             %             figure; hold on;
%             %             for avwf=1:9
%             %                 plot(squeeze(mnWav(:,avwf,2)));
%             %             end
%             %             plot(squeeze(mnWav(:,1,2)),'ko');
%             %
%             %             faa=Spikes.Waveforms{elNum,1};
%             %             figure; hold on;
%             %             for timestamps=1:20
%             %                 plot(faa(timestamps,:)');
%             %             end
%             %             plot(mean(squeeze(mnWav(:,1,:)),2),'k','linewidth',1.5);
%
%             %% alternative spike extraction
%             % extract spike waveforms  traces = memmapfile('example.dat','Format','int16');
%             %             if isa(traces,'memmapfile') % reading electrode data from .dat file
%             %                 Spikes.Waveforms{elNum,1}=ExtractChunks(traces.Data(elNum:electrodes:max(size(traces.Data))),...
%             %                     Spikes.SpikeTimes{elNum,1},50,'tshifted'); %'tzero' 'tmiddle' 'tshifted'
%             %             else
%             %                 Spikes.Waveforms{elNum,1}=ExtractChunks(traces(elNum,:),...
%             %                     Spikes.SpikeTimes{elNum,1},50,'tshifted'); %'tzero' 'tmiddle' 'tshifted'
%             %             end
%
%             %% scale to resolution
%             Spikes.Waveforms{elNum,1}=Spikes.Waveforms{elNum,1}.*bitResolution;
%             Spikes.samplingRate(elNum,1)=samplingRate;
%         catch
%             [Spikes.Units{elNum,1},Spikes.SpikeTimes{elNum,1}]=deal([]);
%         end
%     end

end