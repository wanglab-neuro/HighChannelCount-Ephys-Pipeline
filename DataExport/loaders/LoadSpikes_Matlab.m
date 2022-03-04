function spikes=LoadSpikes_Matlab(fileName)
spikes=load(fileName);
if isfield(spikes,'metadata') %was exported from OE npy files
    spikes.times=spikes.spikeTimes;
    spikes.waveforms=spikes.waveForms;
    spikes.samplingRate=30000;
    spikes.unitID=spikes.clusters;
    spikes.preferredElectrode=spikes.electrodes;
    spikes = rmfield(spikes,{'spikeTimes','waveForms','clusters','electrodes','clusters','metadata'});
else
    numUnits=numel(spikes.Offline_Sorting.Units);
    spikes.unitID=vertcat(spikes.Offline_Sorting.Units{:});
    unitIds=unique(spikes.unitID);
    spikes.preferredElectrode=...
        cellfun(@(x,y) ones(numel(x),1)*y, spikes.Offline_Sorting.Units,...
        mat2cell([1:numUnits]',ones(numUnits,1)),'UniformOutput',false);
    spikes.preferredElectrode=vertcat(spikes.preferredElectrode{:});
    for unitNUm=1:numel(unitIds)
        unitIdx=spikes.unitID==unitIds(unitNUm);
        spikes.preferredElectrode(unitIdx)=mode(spikes.preferredElectrode(unitIdx));
    end
    spikes.times=vertcat(spikes.Offline_Sorting.SpikeTimes{:});
    spikes.waveforms=vertcat(spikes.Offline_Sorting.Waveforms{:});
    spikes.samplingRate=spikes.Offline_Sorting.samplingRate;
    [spikes.times,timeIdx]=sort(spikes.times);
    spikes.unitID=spikes.unitID(timeIdx);
    spikes.waveforms=spikes.waveforms(timeIdx,:);
    spikes.preferredElectrode=spikes.preferredElectrode(timeIdx,:);
end
%     %Matlab export - all units unsorted by default
%     for elNum=1:numel(electrodes)
%         try
%             Spikes.Units{elNum,1}=zeros(1,numel(find(Spikes.data{electrodes(elNum)})));
%             Spikes.SpikeTimes{elNum,1}=find(Spikes.data{electrodes(elNum)});
%             Spikes.Waveforms{elNum,1}=ExtractChunks(traces(elNum,:),...
%                 Spikes.SpikeTimes{elNum,1},40,'tshifted'); %'tzero' 'tmiddle' 'tshifted'
%             % 0.25 bit per uV, so divide by 4 - adjust according to
%             % recording system
%             Spikes.Waveforms{elNum,1}=Spikes.Waveforms{elNum,1}./4;
%         catch
%         end
%     end
%

end