function spikes=LoadSpikes_Spike2(fName)
data=load(fName);
flNames=fields(data);
spikes.unitID=data.(flNames{1}).codes(:,1);
spikes.times=data.(flNames{1}).times;
spikes.waveforms=data.(flNames{1}).values;
spikes.timebase=1;
spikes.samplingRate=1/data.(flNames{1}).interval;
if logical(regexp(fName,'Ch\d+.'))
    chNum=str2double(regexp(fName,'(?<=Ch)\d+(?=\.)','match','once'));
else
    chNum=1;
end
spikes.preferredElectrode=ones(numel(spikes.unitID),1)*chNum;
end
