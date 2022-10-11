function [recInfo,varargout] = LoadData(fName,dName)

% Load ephys + TTL data
[recInfo,recordings,spikes,TTLdata] = LoadEphysData(fName,dName);

videoTTL=TTLdata(strcmp({TTLdata.channelType},'Camera'));
trialTTL=TTLdata(strcmp({TTLdata.channelType},'Zaber'));
laserTTL=TTLdata(strcmp({TTLdata.channelType},'Laser'));

varargout{1}=recordings;
varargout{2}=spikes;
varargout{3}=videoTTL;
varargout{4}=trialTTL;
varargout{5}=laserTTL;

%% load other data
NEVdata=openNEV(fullfile(dataFiles(fileNum).folder,[dataFiles(fileNum).name(1:end-3), 'nev']));
if isfield(NEVdata.ElectrodesInfo,'ElectrodeLabel')
    fsIdx=cellfun(@(x) contains(x','FlowSensor'),{NEVdata.ElectrodesInfo.ElectrodeLabel});
    if any(fsIdx)
        try
            fsData = openNSx(fullfile(dataFiles(fileNum).folder,[dataFiles(fileNum).name(1:end-3), 'ns4']));
            fsIdx = cellfun(@(x) contains(x,'FlowSensor'),{fsData.ElectrodesInfo.Label});
            fsData = fsData.Data(fsIdx,:);
        catch
            % empty data
        end
    end
    reIdx = cellfun(@(x) contains(x','RotaryEncoder'),{NEVdata.ElectrodesInfo.ElectrodeLabel});
    if any(reIdx)
        try
            reData = openNSx(fullfile(dataFiles(fileNum).folder,[dataFiles(fileNum).name(1:end-3), 'ns2']));
            reIdx = cellfun(@(x) contains(x,'RotaryEncoder'),{reData.ElectrodesInfo.Label});
            reData = reData.Data(reIdx,:);
        catch
            % empty data
        end
    end
end