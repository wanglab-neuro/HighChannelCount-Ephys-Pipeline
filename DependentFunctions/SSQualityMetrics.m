function [unitQuality,RPVIndex]=SSQualityMetrics(spikeData, unitIDs)
% Quality metrics based on UltraMegaSort2000 by Hill DN, Mehta SB, & Kleinfeld D  - 07/09/2010
if nargin==1; unitIDs=unique(spikeData.unitID); end

recDur = single(max(spikeData.times))/spikeData.samplingRate; %Recording duration, in seconds
refractoryPeriod = 2.5; %Refractory period, in milliseconds
shadowPeriod = 0.75;% Period after a threshold crossing until the next spike can be detected, in milliseconds
RP = (refractoryPeriod - shadowPeriod) * .001; % actual refractory period, in seconds

unitQuality=nan(numel(unitIDs),1);
RPVIndex=cell(numel(unitIDs),1);
for unitNum=1:numel(unitIDs)
    % get spiketime data
    spikeIndex = spikeData.unitID==unitIDs(unitNum);
    spikeTimes = single(spikeData.times(spikeIndex))/spikeData.samplingRate; %in seconds
    
    % get parameters for calling rp_violations
    numSpikes = numel(find(spikeIndex)); %Number of spikes
    RPVIndex{unitNum}=[0;diff(spikeTimes)  <= (refractoryPeriod * .001)];
    totalRPV  = sum(RPVIndex{unitNum}); % refractory period violations
    
    % calculate contamination
    ev = rpv_contamination(numSpikes, recDur, RP, totalRPV);
    unitQuality(unitNum)=1-ev;
end