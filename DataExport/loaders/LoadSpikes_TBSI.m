function spikes=LoadSpikes_TBSI(argin_fName)

fName=regexp(argin_fName,'\S+?(?=\.\w+\.\w+$)','match','once');
    postFix='';
    if isempty(fName)
        fName=regexp(argin_fName,'\S+?(?=\.\w+\-\w+\.\w+$)','match','once'); %in case loading merged files
        if ~isempty(fName)
            postFix='-merged';
        end
    end
    % find templates and preferred electrodes
    templateToEl=h5read([fName '.clusters' postFix '.hdf5'],'/electrodes'); % this are the *preferred* electrodes for all K templates
    numTemplates=length(templateToEl); % template has equivalent meaning to cluster
    
    % get spike times, amplitudes
    resultFile = [fName '.result' postFix '.hdf5'];
    for templateNum=1:numTemplates
        spikeTimes{templateNum,1}=double(h5read(resultFile, ['/spiketimes/temp_' num2str(templateNum-1)]));
        spikeAmplitudes{templateNum,1}=double(h5read(resultFile, ['/amplitudes/temp_' ...
            num2str(templateNum-1)])); %
        spikeAmplitudes{templateNum,1}=spikeAmplitudes{templateNum,1}(1,:)';
        templatePrefElectrode{templateNum,1}=ones(size(spikeTimes{templateNum,1},1),1)*double(templateToEl(templateNum));
        unitID{templateNum,1}=ones(size(spikeTimes{templateNum,1},1),1)*templateNum;
    end
    
    % collect non-fitted ("garbage") spikes, with unit ID 0. Those are listed by electrode
    [spikeTimes{templateNum+1},templatePrefElectrode{templateNum+1}]=deal([]);
    for electrodeNum=unique(templateToEl)'
        try
            gbSpikeTimes=h5read([fName '.result' postFix '.hdf5'],['/gspikes/elec_' num2str(electrodeNum)]);
            spikeTimes{templateNum+1}=[spikeTimes{templateNum+1};gbSpikeTimes];
            templatePrefElectrode{templateNum+1}=[templatePrefElectrode{templateNum+1};...
                ones(size(gbSpikeTimes,1),1)*double(electrodeNum)];
        catch
            % no "garbage" spikes
        end
    end
    unitID{templateNum+1}=zeros(size(spikeTimes{templateNum+1},1),1);
    %     numTemplates=size(spikeTimes,1);
    % concatenate values
    spikes.unitID=uint32(vertcat(unitID{:}));
    spikes.times=vertcat(spikeTimes{:});
    spikes.amplitude=[vertcat(spikeAmplitudes{:});zeros(size(spikeTimes{end},1),1)];
    spikes.preferredElectrode=uint32(vertcat(templatePrefElectrode{:}));
    % sort times, and adjust unit orders
    [spikes.times,timeIdx]=sort(spikes.times);
    spikes.unitID=spikes.unitID(timeIdx);
    spikes.amplitude=spikes.amplitude(timeIdx);
    spikes.preferredElectrode=spikes.preferredElectrode(timeIdx);
    
    % extract spike waveforms by electrode
    %     traces=load(['../' fName '.mat']);
    %     traces = memmapfile(['../' fName '.dat'],'Format','int16');
    % gert number of electrodes
    clustersData=h5info([fName '.clusters' postFix '.hdf5']);
    clustersDatasetsNames={clustersData.Datasets.Name};
    electrodesId=clustersDatasetsNames(cellfun(@(x) contains(x,'data'),...
        clustersDatasetsNames));
    electrodesId=cellfun(@(x) str2double(regexp(x,'(?<=data_)\w+','match','once')),...
        electrodesId);
    %         unique(spikes.preferredElectrode(spikes.unitID==templateNum))
    
    if exist('traces','var')
        spikes.waveforms=NaN(size(spikes.times,1),50);
        for electrodeNum=electrodesId
            %             =templateToEl(templateNum)+1;
            if isa(traces,'memmapfile') % reading electrode data from .dat file
                spikes.waveforms(spikes.preferredElectrode==electrodeNum,:)=...
                    ExtractChunks(traces.Data(electrodeNum+1:numel(electrodesId):max(size(traces.Data))),...
                    spikes.times(spikes.preferredElectrode==electrodeNum),50,'tshifted'); %'tzero' 'tmiddle' 'tshifted'
            else
                spikes.waveforms(spikes.preferredElectrode==electrodeNum,:)=...
                    ExtractChunks(traces(electrodeNum+1,:),...
                    spikes.times(spikes.preferredElectrode==electrodeNum),50,'tshifted'); %'tzero' 'tmiddle' 'tshifted'
            end
            % scale to resolution
            %             spikes.waveforms{elNum,1}=spikes.Waveforms{elNum,1}.*bitResolution;
        end
    else
        spikes.waveforms=[];
    end
    
    %     spikes.samplingRate=samplingRate;
    
    % plots
    %             foo=traces.Data(elNum:electrodes:max(size(traces.Data)));
    %             figure; hold on
    %             plot(foo(round(size(foo,1)/2)-samplingRate:round(size(foo,1)/2)+samplingRate));
    %             axis('tight');box off;
    %             text(100,100,num2str(round(size(foo,1)/2)))
    %             text(100,50,'PrV 77 115 El 11');
    %             allunits= Spikes.Units{elNum,1};
    %             allspktimes=Spikes.SpikeTimes{elNum,1};
    %             spkTimes=allspktimes(allspktimes>=round(size(foo,1)/2)-samplingRate &...
    %                 allspktimes<round(size(foo,1)/2)+samplingRate & allunits==1);
    %             rasterHeight=ones(1,size(spkTimes,2))*(min(get(gca,'ylim'))/4*3);
    %             plot(spkTimes-(round(size(foo,1)/2)-samplingRate),...
    %                 rasterHeight,'Color','r',...
    %                 'linestyle','none','Marker','^');
    
    % Compute ISI
    % isis = diff(spikeTimes{templateNum,1}); hold on
    %     isis = double(diff(spikes.spikeTimes(spikes.unitID==templateNum)));
    %     hist(isis)
    
    % Display the amplitude
    %     figure
    % plot(spikeTimes{templateNum,1}, spikeAmplitudes{templateNum,1}, '.')
    %     plot(spikes.spikeTimes(spikes.unitID==templateNum),spikes.amplitude(spikes.unitID==templateNum), '.')

    
end