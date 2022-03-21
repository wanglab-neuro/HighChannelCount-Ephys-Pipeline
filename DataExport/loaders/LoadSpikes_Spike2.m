function spikes=LoadSpikes_Spike2(fName)
data=load(fName);
flNames=fields(data);
spikes.unitID=data.(flNames{1}).codes(:,1);
spikes.times=data.(flNames{1}).times;
spikes.waveforms=data.(flNames{1}).values;
spikes.timebase=1;
spikes.samplingRate=1/data.(flNames{1}).interval;
spikes.preferredElectrode=ones(numel(spikes.unitID),1);
end
